#include "syscall.h"
#include "proc.h"
#include "timer.h"
#include "defs.h"
#include "fsdef.h"
#include "elf.h"

extern struct timer timer;

static int (*syscalls_mapping[])(void) = {
[SYS_fork]    sys_fork,
[SYS_exit]    sys_exit,
[SYS_wait]    sys_wait,
// [SYS_pipe]    sys_pipe,
// [SYS_read]    sys_read,
// [SYS_kill]    sys_kill,
[SYS_exec]    sys_exec,
// [SYS_fstat]   sys_fstat,
// [SYS_chdir]   sys_chdir,
// [SYS_dup]     sys_dup,
[SYS_getpid]  sys_getpid,
[SYS_sbrk]    sys_sbrk,
[SYS_sleep]   sys_sleep,
[SYS_uptime]  sys_uptime,
// [SYS_open]    sys_open,
// [SYS_write]   sys_write,
// [SYS_mknod]   sys_mknod,
// [SYS_unlink]  sys_unlink,
// [SYS_link]    sys_link,
// [SYS_mkdir]   sys_mkdir,
// [SYS_close]   sys_close,
};

void
syscall(void)
{
  int num;
  struct proc *curproc = myproc();

  num = curproc->tf->eax;
  if(num > 0 && num < NELEM(syscalls_mapping) && syscalls_mapping[num]) {
    curproc->tf->eax = syscalls_mapping[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
  }
}

// get user arguments, each arguments (no matter int , pointer, or uint, is 32bits)

// get the int at addr
static int fetchuint(uint addr, uint *p) {
    struct proc *proc= myproc();

    if(addr > proc->sz - 4) return -1;

    *p = *(uint*)addr;

    return 0;
}

static int fetchint(uint addr, int *p) {
    struct proc *proc= myproc();

    if(addr > proc->sz - 4) return -1;

    *p = *(int*)addr;

    return 0;
}

int fetchstr(uint addr, char **pp) {
  char *s, *ep;
  struct proc *curproc = myproc();

  if(addr >= curproc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)curproc->sz;
  for(s = *pp; s < ep; s++){
    if(*s == 0)
      return s - *pp;
  }
  return -1;
}

// get base addr of the argument array
static uint getBaseAddr() {
    return myproc()->tf->esp + 4; // + 4 to pop the saved eip
}

// // get the n-th 32-bit data as an uint
static int arguint(int n, uint *p) {
    return fetchuint(getBaseAddr()+4*n, p);
}

static int argint(int n, int *p) {
    uint pp = 0;
    int ret = fetchuint(getBaseAddr()+4*n, &pp);
    *p = (int) pp;
    return ret;
}

static int argstr(int n, char **p) {
    uint addr;
    if(arguint(n, &addr) < 0) return -1;
    return fetchstr(addr, p);
}


int
sys_fork(void)
{
  return fork();
}

int
sys_exit(void)
{
  exit();
  return 0;
}

int
sys_wait(void)
{
  return wait();
}

int
sys_getpid(void)
{
  return myproc()->pid;
}

int
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

int
sys_sleep(void)
{
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    return -1;
  acquire(&timer.tickslock);
  ticks0 = timer.ticks;
  while(timer.ticks - ticks0 < n){
    if(myproc()->killed){
      release(&timer.tickslock);
      return -1;
    }
    sleep(&timer.ticks, &timer.tickslock);
  }
  release(&timer.tickslock);
  return 0;
}

int sys_uptime() {
  uint ret = 0;

  acquire(&timer.tickslock);
  ret = timer.ticks;
  release(&timer.tickslock);
  return ret;
}

int
exec(char *path, char **argv)
{
  char *s, *last;
  int i, off;
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();

  log_begin();

  if((ip = namei(path)) == 0){
    log_end();
    cprintf("exec: fail\n");
    return -1;
  }
  inode_lock(ip);
  pgdir = 0;

  // Check ELF header
  if(inode_read(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
    goto bad;
  if(elf.magic != ELF_MAGIC)
    goto bad;

  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(inode_read(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
    if(ph.vaddr + ph.memsz < ph.vaddr)
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
    if(ph.vaddr % PGSIZE != 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  inode_cache_release_unlock(ip);
  log_end();
  ip = 0;

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;

  ustack[0] = 0xffffffff;  // fake return PC
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
    if(*s == '/')
      last = s+1;
  safestrcpy(curproc->name, last, sizeof(curproc->name));

  // Commit to the user image.
  oldpgdir = curproc->pgdir;
  curproc->pgdir = pgdir;
  curproc->sz = sz;
  curproc->tf->eip = elf.entry;  // main
  curproc->tf->esp = sp;
  switchuvm(curproc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
    freevm(pgdir);
  if(ip){
    inode_cache_release_unlock(ip);
    log_end();
  }
  return -1;
}

int
sys_exec(void)
{
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
    if(i >= NELEM(argv))
      return -1;
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
}
#include "syscall.h"
#include "proc.h"
#include "time.h"
#include "defs.h"

extern struct timer timer;

static int (*syscalls_mapping[])(void) = {
[SYS_fork]    sys_fork,
[SYS_exit]    sys_exit,
[SYS_wait]    sys_wait,
[SYS_pipe]    sys_pipe,
[SYS_read]    sys_read,
// [SYS_kill]    sys_kill,
[SYS_exec]    sys_exec,
[SYS_fstat]   sys_fstat,
[SYS_chdir]   sys_chdir,
[SYS_dup]     sys_dup,
[SYS_getpid]  sys_getpid,
[SYS_sbrk]    sys_sbrk,
[SYS_sleep]   sys_sleep,
[SYS_uptime]  sys_uptime,
[SYS_open]    sys_open,
[SYS_write]   sys_write,
[SYS_mknod]   sys_mknod,
[SYS_unlink]  sys_unlink,
[SYS_link]    sys_link,
[SYS_mkdir]   sys_mkdir,
[SYS_close]   sys_close,
};

// get user arguments, each arguments (no matter int , pointer, or uint, is 32bits)

// get the int at addr
static int fetchuint(uint addr, uint *p) {
    struct proc *proc= myproc();

    if(addr > proc->sz - 4) return -1;

    *ip = *(uint*)addr;

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

// get the n-th 32-bit data as an uint
static int arguint(int n, uint *p) {
    return fetchint(getBaseAddr()+4*n; p);
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
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&timer.ticks, &tiemr.tickslock);
  }
  release(&tiemr.tickslock);
  return 0;
}


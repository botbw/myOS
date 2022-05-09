#include "proc.h"
#include "fsdef.h"
#include "vm.h"
#include "string.h"


struct {
  struct spinlock lk;
  struct proc procs[NPROC];
} process_table;

struct cpu cpu;
int ncpu;
static struct proc *initproc;

int max_pid = 0;

void process_table_init() {
  initlock(&process_table.lk, "process table");
}

struct cpu* mycpu() {
  return &cpu;
}

int cpuid() {
  return 0;
}

struct proc* myproc() {
  struct proc* pp;
  pushcli();
  pp = mycpu()->proc;
  popcli();
  return pp;
}

void forkret();

static struct proc* process_alloc() {
  acquire(&process_table.lk);

  for(int i = 0; i < NPROC; i++) {
    struct proc* pp = &process_table.procs[i];
    if(pp->state == UNUSED) {
      pp->state = EMBRYO;
      pp->pid = ++max_pid;
      
      release(&process_table.lk);

      if((pp->kstack = kalloc()) == 0) {
        pp->state = UNUSED;
        max_pid--;
        return 0;
      }

      char *sp = pp->kstack + KSTACKSIZE;
      sp -= sizeof(struct trapframe);
      pp->tf = (struct trapframe*) sp;
      sp -= sizeof(uint*);
      *(uint*)sp = (uint)trap_return; // *(void (*)())sp = trap_return;
      sp -= sizeof(struct context);
      pp->context = (struct context*) sp;
      memset(pp->context, 0, sizeof(struct context));
      pp->context->eip = (uint)forkret;

      return pp;
    }
  }
  release(&process_table.lk);
  return 0;
}

void user_init() {
  struct proc *p = process_alloc();

  initproc = p;

  if((p->pgdir = setupkvm()) == 0) {
    panic("user_init");
  }

  // a little bit tricky here
  // using the property of the linker ld -b binary
  extern char _binary_initcode_start[], _binary_initcode_size[];
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
  p->sz = PGSIZE; // inituvm allocates one page
  
  memset(p->tf, 0, sizeof(struct trapframe));
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
  p->tf->es = p->tf->ds;
  p->tf->ss = p->tf->ds;
  p->tf->eflags = FL_IF;
  p->tf->esp = PGSIZE;
  p->tf->eip = 0;  // beginning of initcode.S

  safestrcpy(p->name, "rootproc", sizeof(p->name));
  p->cwd = namei("/");

  acquire(&process_table.lk);

  p->state = RUNNABLE;

  release(&process_table.lk);
}

void scheduler() {
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;
  
  for(;;){
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&process_table.lk);
    for(p = process_table.procs; p < &process_table.procs[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;

      // Switch to chosen process.  It is the process's job
      // to release process_table.lk and then reacquire it
      // before jumping back to us.
      c->proc = p;
      switchuvm(p);
      p->state = RUNNING;

      swtch(&(c->scheduler), p->context);
      switchkvm();

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
    }
    release(&process_table.lk);
  }
}

void sched() {
  int intena;
  struct proc *p = myproc();

  if(!holding(&process_table.lk))
    panic("sched process_table.lock");
  if(mycpu()->ncli != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(readeflags()&FL_IF)
    panic("sched interruptible");
  intena = mycpu()->intena;
  swtch(&p->context, mycpu()->scheduler);
  mycpu()->intena = intena;
}

void yield() {
  acquire(&process_table.lk);  //DOC: yieldlock
  myproc()->state = RUNNABLE;
  sched();
  release(&process_table.lk);
}

void sleep(void *chan, struct spinlock *lk) {
  struct proc *p = myproc();
  if(p == 0 || lk == 0) panic("sleep");

  if(lk != &process_table.lk) {
    acquire(&process_table.lk);
    release(lk);
  }

  p->chan = chan;
  p->state = SLEEPING;

  sched();

  p->chan = 0;

  if(lk != &process_table.lk) {
    release(&process_table.lk);
    acquire(lk);
  }
}

static void wakeup1(void *chan) {
  struct proc *p;

  for(p = process_table.procs; p < &process_table.procs[NPROC]; p++)
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}

// Wake up all processes sleeping on chan.
void wakeup(void *chan) {
  acquire(&process_table.lk);
  wakeup1(chan);
  release(&process_table.lk);
}

int fork() {
  int i, pid;
  struct proc *np;
  struct proc *curproc = myproc();

  // Allocate process.
  if((np = process_alloc()) == 0){
    return -1;
  }

  // Copy process state from proc.
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
    kfree(np->kstack);
    np->kstack = 0;
    np->state = UNUSED;
    return -1;
  }
  np->sz = curproc->sz;
  np->parent = curproc;
  *np->tf = *curproc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
    if(curproc->ofile[i])
      np->ofile[i] = file_duplicate(curproc->ofile[i]);
  np->cwd = inode_duplicate(curproc->cwd);

  safestrcpy(np->name, curproc->name, sizeof(curproc->name));

  pid = np->pid;

  acquire(&process_table.lk);

  np->state = RUNNABLE;

  release(&process_table.lk);

  return pid;
}

void forkret() {
  static int first = 1;
  // Still holding process_table.lk from scheduler.
  release(&process_table.lk);

  if (first) {
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot
    // be run from main().
    first = 0;
    inode_init(ROOTDEV);
    log_init(ROOTDEV);
  }

  // Return to "caller", actually trap_return (see allocproc).
}

void exit() {
  struct proc *curproc = myproc();
  struct proc *p;
  int fd;

  if(curproc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
    if(curproc->ofile[fd]){
      file_close(curproc->ofile[fd]);
      curproc->ofile[fd] = 0;
    }
  }

  log_begin();
  inode_cache_release(curproc->cwd);
  log_end();
  curproc->cwd = 0;

  acquire(&process_table.lk);

  // Parent might be sleeping in wait().
  wakeup1(curproc->parent);

  // Pass abandoned children to init.
  for(p = process_table.procs; p < &process_table.procs[NPROC]; p++){
    if(p->parent == curproc){
      p->parent = initproc;
      if(p->state == ZOMBIE)
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  curproc->state = ZOMBIE;
  sched();
  panic("zombie exit");
}

int wait()
{
  struct proc *p;
  int havekids, pid;
  struct proc *curproc = myproc();
  
  acquire(&process_table.lk);
  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(p = process_table.procs; p < &process_table.procs[NPROC]; p++){
      if(p->parent != curproc)
        continue;
      havekids = 1;
      if(p->state == ZOMBIE){
        // Found one.
        pid = p->pid;
        kfree(p->kstack);
        p->kstack = 0;
        freeuvm(p->pgdir);
        p->pid = 0;
        p->parent = 0;
        p->name[0] = 0;
        p->killed = 0;
        p->state = UNUSED;
        release(&process_table.lk);
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || curproc->killed){
      release(&process_table.lk);
      return -1;
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(curproc, &process_table.lk);  //DOC: wait-sleep
  }
}

int growproc(int n) {
  uint sz;
  struct proc *curproc = myproc();

  sz = curproc->sz;
  if(n > 0){
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
      return -1;
  } else if(n < 0){
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
      return -1;
  }
  curproc->sz = sz;
  switchuvm(curproc); // ?
  return 0;
}
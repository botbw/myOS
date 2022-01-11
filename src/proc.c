#include "proc.h"
#include "fsdef.h"

struct {
  struct spinlock lk;
  struct proc procs[NPROC];
} process_table;

int max_pid = 0;

void process_table_init() {
  initlock(&process_table.lk, "process table");
}

struct cpu* mycpu() {
  return cpu;
}

struct proc* myproc() {
  struct proc* pp;
  pushcli();
  pp = mycpu()->proc;
  popcli();
  return pp;
}

void forkret(void)
{
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);

  if (first) {
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot
    // be run from main().
    first = 0;
    inode_init(ROOTDEV);
    log_init(ROOTDEV);
  }

  // Return to "caller", actually trapret (see allocproc).
}
static struct proc* process_alloc() {
  acquire(&process_table.lk);

  for(int i = 0; i < NPROC; i++) {
    struct proc* pp = &process_table.procs[i];
    if(pp->state == UNUSED) {
      pp->state = EMBRYO;
      pp->pid = ++max_pid;

      if((pp->kstack = kalloc()) == 0) {
        pp->state = UNUSED;
        max_pid--;
        return 0;
      }

      char *sp = pp->kstack + KSTACKSIZE;
      sp -= sizeof(struct trapframe);
      sp -= sizeof(uint*);
      *(uint*)sp = (uint)trapret; // *(void (*)())sp = trapret;
      sp -= sizeof(struct context);
      pp->context = sp;
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

  if(p->pgdir = setupkvm() == 0) {
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

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  acquire(&ptable.lock);

  p->state = RUNNABLE;

  release(&ptable.lock);
}

void scheduler() {
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;
  
  for(;;){
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
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
    release(&ptable.lock);
  }
}

void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&ptable.lock))
    panic("sched ptable.lock");
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

void
yield(void)
{
  acquire(&ptable.lock);  //DOC: yieldlock
  myproc()->state = RUNNABLE;
  sched();
  release(&ptable.lock);
}
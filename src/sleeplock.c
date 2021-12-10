#include "sleeplock.h"

// sleeplock will only be used in IRQs and processes
// kernel itself won't be using sleeplock so there is no deadlock issue with interrupts

void init_sleeplock(struct sleeplock *lk, const char* name) {
  lk->lk.cpu = 0;
  lk->lk.locked = 0;
  lk->lk.name = name;
  lk->lk.pcs[0] = 0;
  lk->locked = 0;
  lk->pid = 0;
}

void sleep(void *chan, struct spinlock *lk) {
  struct proc *p = myproc();
  if(p == 0 || lk == 0) panic("sleep");

  if(lk != &ptable.lock) {
    acquire(&ptable.lock);
    release(lk);
  }

  p->chan = chan;
  p->state = SLEEPING;

  sched();

  p->chan = 0;

  if(lk != &ptable.lock) {
    acquire(&ptable.lock);
    release(lk);
  }
}

static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
  acquire(&ptable.lock);
  wakeup1(chan);
  release(&ptable.lock);
}

void acquire_sleeplock(struct sleeplock *lk) {
  acquire(&lk->lk);
  while(lk->locked == 1) {
    sleep(&lk, &lk->lk);
  }
  lk->locked = 1;
  lk->locked = myproc()->pid;
  release(&lk->lk);
}

void release_sleeplock(struct sleeplock *lk) {
  acquire(&lk->lk);
  lk->locked = 0;
  lk->pid = 0;
  wakeup(lk);
  release(&lk->lk);
}

int holdingsleep(struct sleeplock *lk)
{
  int r;
  acquire(&lk->lk);
  r = lk->locked && (lk->pid == myproc()->pid);
  release(&lk->lk);
  return r;
}
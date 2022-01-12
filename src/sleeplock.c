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
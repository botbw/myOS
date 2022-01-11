#include "spinlock.h"

// we will be running on a single processor system.
// turning on/off interrupt will be enough to solve competitive condition
// but for further improving and consistent with xv6
// use lock

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
    pcs[i] = 0;
}

// Pushcli/popcli are like cli/sti except that they are matched:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.


void
pushcli(void)
{
  int eflags;

  eflags = readeflags();
  cli();
  if(mycpu()->ncli == 0)
    mycpu()->intena = eflags & FL_IF;
  mycpu()->ncli += 1;
}

void
popcli(void)
{
  if(readeflags()&FL_IF)
    panic("popcli - interruptible");
  if(--mycpu()->ncli < 0)
    panic("popcli");
  if(mycpu()->ncli == 0 && mycpu()->intena)
    sti();
}

// turn off interrupt
void acquire(struct spinlock *lk) {
  pushcli();
  while(xchg(&lk->locked, 1) != 0);
  __sync_synchronize();
  lk->cpu = mycpu(); // single-core processor should be 0
  getcallerpcs(&lk, lk->pcs);
}

// turn on interrupt
void release(struct spinlock *lk) {
  lk->pcs[0] = 0;
  lk->cpu = 0; // single-core processor
  __sync_synchronize();
  
  lk->locked = 0; // should be atomic

  popcli();
}

void initlock(struct spinlock *lk, const char* str) {
  lk->name = str;
  lk->locked = 0;
  lk->cpu = 0;
}

// Check whether this cpu is holding the lock.
int holding(struct spinlock *lock) {
  int r;
  pushcli();
  r = lock->locked && lock->cpu == mycpu();
  popcli();
  return r;
}
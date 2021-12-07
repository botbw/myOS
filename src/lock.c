#include "x86.h"
#include "lock.h"
// Since we will be running on a single processor system.
// turning on/off interrupt will be enough to solve competitive condition


// turn off interrupt
void acquire(struct lock *lk) {
  cli();
}

// turn on interrupt
void release(struct lock *lk) {
  sti();
}

void initlock(struct lock *lk, const char* str) {
  lk->name = str;
  lk->locked = 0;
  lk->cpu = 0;
}
#ifndef SLEEPLOCK_H
#define SLEEPLOCK_H

#include "spinlock.h"

struct sleeplock {
  uint locked;
  struct spinlock lk; // protect the spinlock

  // debug
  int pid;
};

extern struct {
  struct spinlock lock;
  struct proc proc[NPROC];
} ptable;

void sleep(void*, struct spinlock*);
void wakeup(void*);
void acquire_sleeplock(struct sleeplock*);
void release_sleeplock(struct sleeplock*);
void init_sleeplock(struct sleeplock*, const char*);
int holdingsleep(struct sleeplock *lk);

#endif
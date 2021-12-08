#ifndef SLEEPLOCK_H
#define SLEEPLOCK_H

#include "spinlock.h"

struct sleeplock {
  int locked;
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
void acqure_sleeplock(struct sleeplock*);
void release_sleeplock(struct sleeplock*);

#endif
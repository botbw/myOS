#ifndef SPINLOCK_H
#define SPINLOCK_H

#include "types.h"
#include "panic.h"
#include "x86.h"
#include "memlayout.h"
#include "mmu.h"

struct spinlock {
  uint locked;
  // For debugging:
  const char *name;        // Name of lock.
  struct cpu *cpu;   // The cpu holding the lock.
  uint pcs[10];      // The call stack (an array of program counters)
                     // that locked the lock.
};

void acquire(struct spinlock *);
void release(struct spinlock *);
void initlock(struct spinlock *, const char*);
void pushcli();
void popcli();
int holding(struct spinlock *lock);

#endif
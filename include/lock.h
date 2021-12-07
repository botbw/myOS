#ifndef LOCK_H
#define LOCK_H

#include "types.h"

struct lock {
  int locked;

  // For debugging:
  const char *name;        // Name of lock.
  struct cpu *cpu;   // The cpu holding the lock.
  uint pcs[10];      // The call stack (an array of program counters)
                     // that locked the lock.
};

void acquire(struct lock *);
void release(struct lock *);
void initlock(struct lock *, const char*);

#endif
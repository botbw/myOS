#include "x86.h"
#include "spinlock.h"
// Since we will be running on a single processor system.
// turning on/off interrupt will be enough to solve competitive condition

// turn off interrupt
void lock() {
  cli();
}

// turn on interrupt
void release() {
  sti();
}
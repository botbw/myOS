#include "x86.h"
#include "giantlock.h"
// Since we will be running on a single processor system.
// turning on/off interrupt will be enough to solve competitive condition


// turn off interrupt
void acquire() {
  cli();
}

// turn on interrupt
void release() {
  sti();
}
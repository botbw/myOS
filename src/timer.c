// Intel 8253/8254/82C54 Programmable Interval Timer (PIT).
// Only used on uniprocessors;
// SMP machines use the local APIC timer.

#include "types.h"
#include "defs.h"
#include "trap.h"
#include "x86.h"
#include "timer.h"
#include "picinit.h"

#define IO_TIMER1       0x040           // 8253 Timer #1

// Frequency of all three count-down timers;
// (TIMER_FREQ/freq) is the appropriate count
// to generate a frequency of freq Hz.

#define TIMER_FREQ      1193182
#define TIMER_DIV(x)    ((TIMER_FREQ+(x)/2)/(x))

#define TIMER_MODE      (IO_TIMER1 + 3) // timer mode port
#define TIMER_SEL0      0x00    // select counter 0
#define TIMER_RATEGEN   0x04    // mode 2, rate generator
#define TIMER_16BIT     0x30    // r/w counter 16 bits, LSB first

struct timer timer;

void
timerinit(int freq)
{
  // Interrupt freq times/sec.
  int divisior = TIMER_FREQ/freq;
  outb(TIMER_MODE, TIMER_SEL0 | TIMER_RATEGEN | TIMER_16BIT);
  outb(IO_TIMER1, divisior % 256); // low bits
  outb(IO_TIMER1, divisior / 256); // high bits
  picenable(IRQ_TIMER);
}

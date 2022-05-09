#include "x86.h"
#include "trap.h"
#include "uart.h"
#include "string.h"
#include "mmu.h"
#include "proc.h"
#include "defs.h"
#include "console.h"
#include "disk.h"
#include "timer.h"
#include "syscall.h"

#define PRINTLINE cprintf("***************************************\n");


extern void kbdintr();
extern struct timer timer;
extern uint ISRs[];

struct gatedesc idt[256];

void trap_all(struct trapframe *f) {
  switch(f->trapno) {
    case T_SYSCALL:
      if(myproc()->killed)
        exit();
      myproc()->tf = f;
      syscall();
      if(myproc()->killed)
        exit();
      break;
    case T_IRQ0 + IRQ_TEST:
      PRINTLINE
      cprintf("Trap test passed\n");
      PRINTLINE
      break;
    case T_IRQ0 + IRQ_KBD:
      kbdintr();
      break;
    case T_IRQ0 + IRQ_IDE:
      ideintr();
      break;
    case T_IRQ0 + IRQ_TIMER:
      break;
    default:
      panic("trap_all: no trapno catched\n");
  }
}

void
ISRs_init(void)
{
  int i;

  for(i = 0; i < 256; i++)
    SETGATE(idt[i], 0, SEG_KCODE<<3, ISRs[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, ISRs[T_SYSCALL], DPL_USER);
  lidt(idt, sizeof(idt));
}

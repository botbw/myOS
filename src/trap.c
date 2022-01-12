#include "x86.h"
#include "trap.h"
#include "uart.h"
#include "string.h"
#include "mmu.h"
#include "proc.h"
#include "defs.h"

static const char str[12] = "trap: test\n";
// static const char timer_str[14] = "timer awoken\n";
extern void kbdintr();

struct gatedesc idt[256];
extern uint ISRs[];

void trap_all(struct trapframe *f) {
  switch(f->trapno) {
    case T_IRQ0 + IRQ_TEST:
      uartwrite_string(str, 12);
      break;
    case T_IRQ0 + IRQ_KBD:
      kbdintr();
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

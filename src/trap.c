#include "x86.h"
#include "trap.h"
#include "uart.h"
#include "string.h"
#include "mmu.h"
#include "proc.h"
#include "defs.h"

static const char str[] = "trap: test\n";

struct gatedesc idt[256];
extern uint ISRs[];

void trap_all(struct trapframe *f) {
  if(f->trapno == T_IRQ0 + IRQ_TEST) {
    write_string(str, strlen(str));
  }
  panic("trap_all: no trapno catched\n");
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

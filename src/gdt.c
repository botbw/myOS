#include "gdt.h"
#include "mmu.h"
#include "x86.h"
#include "proc.h"


extern void gdt_flush();
extern struct cpu cpu;

void init_gdt() {
  struct cpu *c = &cpu;
  c->gdt[0] = SEG(0, 0, 0, 0);
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
  lgdt(c->gdt, sizeof(c->gdt));
  gdt_flush();
}
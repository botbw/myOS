#include "gdt.h"
#include "mmu.h"
#include "x86.h"

__attribute__((aligned(8))) struct segdesc gdt[NSEGS];

void gdt_flush();

void init_gdt() {
  gdt[0] = SEG(0, 0, 0, 0);
  gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
  gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
  gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
  gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
  lgdt(gdt, sizeof(gdt));
  gdt_flush();
}
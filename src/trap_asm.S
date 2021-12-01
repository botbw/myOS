#include "../include/mmu.h"

.global trap_begin
trap_begin:
  pushl %ds
  pushl %es
  pushl %fs
  pushl %gs
  pushal

  movw $(SEG_KDATA << 3), %ax
  movw %ax, %ds
  movw %ax, %es
  movw %ax, %fs
  movw %ax, %gs

  pushl %esp
  call trap_all
  
  addl $4, %esp

.global trap_return
trap_return:
  popal
  popl %gs
  popl %fs
  popl %es
  popl %ds
  addl $0x8, %esp
  iret



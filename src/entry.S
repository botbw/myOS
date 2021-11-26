#include "../include/mmu.h"
#include "../include/param.h"
#include "../include/memlayout.h"
# using macros to declare constants, $(CC) -S to to through pre-processing
#define MULTIBOOT_HEADER_FLAGS 0x00000003

# multiboot header
.p2align 2
.text
.global multiboot_header
multiboot_header:
  # magic number
  .long   MULTIBOOT_HEADER_MAGIC
  # flags
  .long   MULTIBOOT_HEADER_FLAGS
  # checksum
  .long   -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)

# the kernel begins here. Do not return in this file!
.global entry
entry:
  /* from grub multiboot */
  movl $(V2P_WO(stack+KSTACKSIZE)), %esp
  pushl $0
  popf 
  /* Push the magic value. */
  pushl   %eax
  /* Push the pointer to the Multiboot information structure. */
  pushl   %ebx

  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
  orl     $(CR4_PSE), %eax
  movl    %eax, %cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
  movl    %eax, %cr3
  # Turn on paging.
  movl    %cr0, %eax
  orl     $(CR0_PG|CR0_WP), %eax
  movl    %eax, %cr0



  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $cmain, %eax
  jmp *%eax

spin:
  nop
  jmp spin

# tell the assmbler to "allocate" a stack, this stack will be our kernel stack
# notice that x86 stack grows from high address to low address.
.p2align 4

# kernel stack: 4KB
.comm stack, KSTACKSIZE

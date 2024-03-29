#include "../include/mmu.h"
#include "../include/param.h"
#include "../include/memlayout.h"
# using macros to declare constants, $(CC) -S to to through pre-processing
#define MULTIBOOT_HEADER_FLAGS 0x00000003

# multiboot header
.p2align 2
.section .multiboot_header
  # magic number
  .long   MULTIBOOT_HEADER_MAGIC
  # flags
  .long   MULTIBOOT_HEADER_FLAGS
  # checksum
  .long   -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)

# the kernel begins here. Do not return in this file!
.text
.global entry
entry:
  cli
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %ecx
  orl     $(CR4_PSE), %ecx
  movl    %ecx, %cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %ecx
  movl    %ecx, %cr3
  # Turn on paging.
  movl    %cr0, %ecx
  orl     $(CR0_PG|CR0_WP), %ecx
  movl    %ecx, %cr0

    /* from grub multiboot */
  movl $(stack+KSTACKSIZE), %esp
  pushl $0
  popf 
  /* Push the pointer to the Multiboot information structure. */
  pushl   %ebx
  /* Push the magic value. */
  pushl   %eax
  /*
  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  */
  movl $cmain, %eax
  call *%eax
  
spin:
  nop
  jmp spin

# set up a stack
# notice that x86 stack grows from high address to low address.
.p2align 4
# kernel stack: 4KB
.comm stack, KSTACKSIZE

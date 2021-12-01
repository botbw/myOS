#include "multiboot.h"
#include "types.h"
#include "memlayout.h"
#include "mmu.h"
#include "kalloc.h"
#include "vm.h"
#include "gdt.h"
#include "string.h"
#include "trap.h"
#include "panic.h"

/* Check if the bit BIT in FLAGS is set. */
#define CHECK_FLAG(flags,bit)   ((flags) & (1 << (bit)))


// If bit 0 in the ‘flags’ word is set, then the ‘mem_*’ fields are valid.
// ‘mem_lower’ and ‘mem_upper’ indicate the amount of lower and upper memory,
// respectively, in kilobytes. Lower memory starts at address 0, 
// and upper memory starts at address 1 megabyte. 
// The maximum possible value for lower memory is 640 kilobytes. 
// The value returned for upper memory is maximally the address of 
// the first upper memory hole minus 1 megabyte. It is not guaranteed to be this value.
uint mem_lower, mem_upper, phystop; // mem_lower is not used


static char welcome_str[] = "virtual memory boot succeeds\n";

void write_string(char* c, int len);
int init_serial();


void cmain(uint magic_number, multiboot_info_t *mbi) {
  
  /* Am I booted by a Multiboot-compliant boot loader? */
  if(magic_number != MULTIBOOT_BOOTLOADER_MAGIC) return ;

  // init global descriptor table
  init_gdt();

  // initialize screen output
  if(init_serial() != 0) return ;
  
  // get memory infomation
  if(CHECK_FLAG(mbi->flags, 0)) {
    mem_lower = mbi->mem_lower;
    mem_upper = mbi->mem_upper;
    phystop = ((mem_upper+1024)*1024); // mem_upper(in KB) + 1MB(1024 KB)
    // however we are not going to use these values since this kernel simply follows the design of xv6
  } else return ;

  // init kernel memory (the first 4MB), for early use and more page tables
  kinit();

  // init virtual memory
  kvmalloc();

  // init the remnant of kernel memory
  kinit_all();

  // print welcome string
  write_string(welcome_str, strlen(welcome_str));

  // these multiprocessor drive code are copid from xv6 for further development, but this kernel is still a single-core processor one
  // mpinit();
  // lapicinit();
  // we use PIC instead of APIC
  
  // initialize interrupt service routine (soft interrupt)
  ISRs_init();

  asm volatile("int %0"::"i"(T_IRQ0 +IRQ_TEST));

  panic("kernel hasn't been finished");
}

// The boot page table used in entry.S and entryother.S.
// Page directories (and page tables) must start on page boundaries,
// hence the __aligned__ attribute.
// PTE_PS in a page directory entry enables 4Mbyte pages.

__attribute__((__aligned__(PGSIZE)))
pde_t entrypgdir[NPDENTRIES] = {
  // Map VA's [0, 4MB) to PA's [0, 4MB)
  [0] = (0) | PTE_P | PTE_W | PTE_PS,
  // Map VA's [KERNBASE, KERNBASE+4MB) to PA's [0, 4MB)
  [KERNBASE>>PDXSHIFT] = (0) | PTE_P | PTE_W | PTE_PS,
};
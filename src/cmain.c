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
#include "picinit.h"
#include "timer.h"
#include "console.h"
#include "uart.h"
#include "disk.h"
#include "buf.h"
#include "fsdef.h"
#include "proc.h"

/* Check if the bit BIT in FLAGS is set. */
#define CHECK_FLAG(flags,bit)   ((flags) & (1 << (bit)))

static void unicore_interrupt_setup();

// If bit 0 in the ‘flags’ word is set, then the ‘mem_*’ fields are valid.
// ‘mem_lower’ and ‘mem_upper’ indicate the amount of lower and upper memory,
// respectively, in kilobytes. Lower memory starts at address 0, 
// and upper memory starts at address 1 megabyte. 
// The maximum possible value for lower memory is 640 kilobytes. 
// The value returned for upper memory is maximally the address of 
// the first upper memory hole minus 1 megabyte. It is not guaranteed to be this value.
uint mem_lower, mem_upper, phystop; // mem_lower is not used



void cmain(uint magic_number, multiboot_info_t *mbi) {
  /* Am I booted by a Multiboot-compliant boot loader? */
  if(magic_number != MULTIBOOT_BOOTLOADER_MAGIC) return ;
  // init global descriptor table
  init_gdt();
  // initialize screen output
  if(uartinit() != 0) return ;
  cprintf("boot succeed\n"); 
  // get memory infomation
  if(CHECK_FLAG(mbi->flags, 0)) {
    mem_lower = mbi->mem_lower;
    mem_upper = mbi->mem_upper;
    phystop = ((mem_upper+1024)*1024); // mem_upper(in KB) + 1MB(1024 KB)
    // however we are not going to use these values since this kernel simply follows the design of xv6
  } else return ;
  cprintf("total available: %d mb (should be the same as hardware setting)\n", phystop/(1024*1024));
  // init kernel memory (the first 4MB), for early use and more page tables
  kinit();
  // init virtual memory
  kvminit();
  // init the remnant of kernel memory (actually we can finish it once)
  kinit_all();
  int tmp = freepages();
  cprintf("total pages: %d, which is %d mb (shoule be around 0x80000000 kb)\n", tmp, tmp*PGSIZE/(1024*1024));

  // these multiprocessor drive code are copid from xv6 for further development, but this kernel is still a single-core processor one
  // mpinit();
  // lapicinit();
  // we use PIC instead of APIC
  unicore_interrupt_setup();
  // initialize hard disk thru IDE, the first layer of fs
  disk_init();  
  // initialize the second layer of fs: cache, which are composed of buffers
  buffers_init();
  // file table
  file_table_init();
  // initialize console, which allows recieving keyboard signal
  consoleinit();
  // process table
  process_table_init();
  // initialize console
  consoleinit(); 
  
  
  panic("kernel hasn't been finished\n");
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

static void unicore_interrupt_setup() {
  // setup the interrupt scheme
  // initialize interrupt service routine (soft interrupt)
  ISRs_init();
  // send a test IRQ
  asm volatile("int %0"::"i"(T_IRQ0 +IRQ_TEST)); 
  // initalize the Programmable Interrupt Controller
  picinit();
  // set up UART interrupt
  picenable(IRQ_COM1);
  // interrupt 100 times/sec
  timerinit(100);
  // testing timer
  // asm volatile("sti");
  
}

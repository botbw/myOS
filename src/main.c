#include "multiboot.h"
#include "types.h"
#include "memlayout.h"
#include "mmu.h"
#include "kalloc.h"


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

extern uint magic_number, mbi_addr; // defined in entry.S

static char welcome_str[21] = "boot test succeeds";

int main() {
  /* Set MBI to the address of the Multiboot information structure. */
  multiboot_info_t *mbi = (multiboot_info_t*)mbi_addr;

  /* Am I booted by a Multiboot-compliant boot loader? */
  if(magic_number != MULTIBOOT_BOOTLOADER_MAGIC) return;

  // initialize screen output
  if(init_serial() != 0) return;
  write_string(welcome_str, 21);
  
  // get memory infomation
  if(CHECK_FLAG(mbi->flags, 0)) {
    mem_lower = mbi->mem_lower;
    mem_upper = mbi->mem_upper;
    phystop = ((mem_upper+1024)<<4); // mem_upper(in KB) + 1MB(1024 KB)
  } else return;

  // init kernel memory (the first 4MB), for page tables and early use;
  kinit();





  
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
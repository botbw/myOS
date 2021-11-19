#include "mmu.h"
#include "memlayout.h"
#include "types.h"
#include "spinlock.h"
#include "defs.h"

extern char end[]; // the end of kernel memory, defined in kernel.ld: PROVIDE(end = .);

extern uint phystop; // defined in main.c

// a page/chunk of memory
struct run {
  struct run* next;
};

// the kernel memory list, need to be locked when using it
struct {
  struct run* head;
  uint pgnum;
} kmem;

// free one page and fill it with junk, the interrupt is assumed to be turned on already;
void kfree(void *ptr) {

  if((uint)ptr % PGSIZE || (char*)ptr < end || V2P(ptr) >= phystop)
    panic("kfree");

  memset(ptr, 1, PGSIZE);
  lock();
  struct run *tmp = (struct run*)ptr;
  tmp->next = kmem.head;
  kmem.head = tmp;
  kmem.pgnum++;
  release();
}

// free a range of memory using kfree(ptr);
void freerange(void* start_addr, void* end_addr) {
  char *p;
  p = (char*)PGROUNDUP((uint)start_addr);
  for(; p + PGSIZE <= (char*)end_addr; p += PGSIZE)
    kfree(p);
}

// similar to freerange(end, phystop), but with interrupt turned off
// only the first 4MB because we only set up its memory mapping in entrypgdir[] defined in main.c
void kinit() {
  kmem.head = NULL;
  kmem.pgnum = 0;

  char *p = end;
  char *end_of_4MB = V2P(4*1024*1024);

  for(; p + PGSIZE <= end_of_4MB; p += PGSIZE) {
    struct run *tmp = (struct run*)p;
    tmp->next = kmem.head;
    kmem.head = tmp;
    kmem.pgnum++;
  }
}


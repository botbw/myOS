#include "mmu.h"
#include "memlayout.h"
#include "types.h"
#include "spinlock.h"
#include "defs.h"
#include "kalloc.h"

extern char end[]; // the end of kernel memory, defined in kernel.ld: PROVIDE(end = .);

// a page/chunk of memory
struct run {
  struct run* next;
};

// the kernel memory list, need to be locked when using it
struct {
  struct spinlock lk;
  struct run* head;
  uint pgnum;
  int use_lock;
} kmem;

// free one page and fill it with junk, the interrupt is assumed to be turned on already;
void kfree(void *ptr) {

  if((uint)ptr % PGSIZE || (char*)ptr < end || V2P(ptr) >= PHYSTOP)
    panic("kfree");

  memset(ptr, 1, PGSIZE);
  if(kmem.use_lock) acquire(&kmem.lk);
  struct run *tmp = (struct run*)ptr;
  tmp->next = kmem.head;
  kmem.head = tmp;
  kmem.pgnum++;
  if(kmem.use_lock) release(&kmem.lk);
}

// alloc one memory page filled with junk;
void *kalloc() {
  if(kmem.use_lock) acquire(&kmem.lk);
  struct run *tmp = kmem.head;
  kmem.head = kmem.head->next;
  kmem.pgnum--;
  if(kmem.use_lock) release(&kmem.lk);
  return (void*)tmp;
}

// free a range of memory using kfree(ptr);
void freerange(void* start_addr, void* end_addr) {
  char *p;
  p = (char*)PGROUNDUP((uint)start_addr);
  for(; p + PGSIZE <= (char*)end_addr; p += PGSIZE)
    kfree(p);
}

// similar to freerange(end, 4mb), but with interrupt turned off
// only the first 4MB because we only set up its memory mapping in entrypgdir[] defined in main.c
void kinit() {
  kmem.head = 0;
  kmem.pgnum = 0;
  kmem.use_lock = 0;
  initlock(&kmem.lk, "kmem");
  
  char *p = end;
  char *end_of_4MB = P2V(4*1024*1024);

  freerange(p, end_of_4MB);
}

// similar to kinit(), but map all the memory
void kinit_all() {
  kmem.head = 0;
  kmem.pgnum = 0;

  char *p = P2V(4*1024*1024);
  char *end = P2V(PHYSTOP);

  freerange(p, end);
}

int freepages() {
  return kmem.pgnum;
}


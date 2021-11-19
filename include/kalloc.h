#ifndef KALLOC_H
#define KALLOC_H

void kfree(void*);
void freerange(void*, void*);
void kinit();

#endif
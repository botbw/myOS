#ifndef KALLOC_H
#define KALLOC_H

void kinit();
void kinit_all();
void *kalloc();
void kfree(void *);
#endif
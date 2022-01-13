#ifndef DISK_H
#define DISK_H

#include "buf.h"
#include "spinlock.h"
#include "trap.h"
#include "picinit.h"

void disk_init();
void iderw(struct buf* b);
void ideintr(void);

#endif
#ifndef CONSOLE_H
#define CONSOLE_H

#include "spinlock.h"
#include "types.h"
#include "proc.h"
#include "trap.h"
#include "memlayout.h"
#include "picinit.h"
#include "file.h"
#include "defs.h"
#include "x86.h"

void consoleinit(void);

#endif
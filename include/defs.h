#ifndef DEFS_H
#define DEFS_H

#include "types.h"
#include "kalloc.h"
#include "vm.h"
#include "string.h"

void panic(char*);

// number of elements in fixed-size array
#define NELEM(x) (sizeof(x)/sizeof((x)[0]))

#endif
#include "types.h"

#include "kalloc.h"
#include "vm.h"

void *memset(void*, int, uint);

void panic(char*);

// number of elements in fixed-size array
#define NELEM(x) (sizeof(x)/sizeof((x)[0]))
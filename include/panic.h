#ifndef PANIC_H
#define PANIC_H

#include "uart.h"
#include "x86.h"

extern int strlen(const char *s);

void panic(const char*);

#endif
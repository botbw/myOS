#ifndef PANIC_H
#define PANIC_H

#include "string.h"
#include "uart.h"
#include "x86.h"

void panic(const char*);

#endif
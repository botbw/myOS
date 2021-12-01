#ifndef UART_H
#define UART_H

#include "x86.h"
#include "types.h"

#define PORT 0x3f8          // COM1

int init_serial();
void write_string(const char* c, int len);

#endif

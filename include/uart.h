#ifndef UART_H
#define UART_H

#include "x86.h"
#include "types.h"

#define PORT 0x3f8          // COM1

int uartinit();
void uartputc(char);
void uartwrite_string(const char*, int);

#endif

#include "panic.h"
#include "string.h"
#include "uart.h"

void panic(const char * a) {
  uartwrite_string(a, strlen(a));
  while(1);
}
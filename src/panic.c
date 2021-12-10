#include "panic.h"

void panic(const char * a) {
  uartwrite_string(a, strlen(a));
  cli();
  while(1);
}
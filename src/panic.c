#include "panic.h"
#include "string.h"
#include "uart.h"

void panic(const char * a) {
  write_string(a, strlen(a));
  while(1);
}
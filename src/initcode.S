# this code will be compile into an independent part and load into c code separately
#define T_SYSCALL       64      // system call
#include "syscall.h"

start:
  pushl $argv
  pushl $path
  pushl $0 # when exec returns, the code runs from 0 of user space (just like movl exec, %eax; pushl $0; ljmp *%eax)
  movl $SYS_exec, %eax
  int $T_SYSCALL

exit: 
  movl $SYS_exit, %eax
  int $T_SYSCALL
  jmp exit

path:
  .string "/init" # null-terminated

argv:
  .long path
  .long 0
#ifndef TRAP_H
#define TRAP_H

// x86 trap and interrupt constants.

// Processor-defined:
#define T_DIVIDE         0      // divide error
#define T_DEBUG          1      // debug exception
#define T_NMI            2      // non-maskable interrupt
#define T_BRKPT          3      // breakpoint
#define T_OFLOW          4      // overflow
#define T_BOUND          5      // bounds check
#define T_ILLOP          6      // illegal opcode
#define T_DEVICE         7      // device not available
#define T_DBLFLT         8      // double fault
// #define T_COPROC      9      // reserved (not used since 486)
#define T_TSS           10      // invalid task switch segment
#define T_SEGNP         11      // segment not present
#define T_STACK         12      // stack exception
#define T_GPFLT         13      // general protection fault
#define T_PGFLT         14      // page fault
// #define T_RES        15      // reserved
#define T_FPERR         16      // floating point error
#define T_ALIGN         17      // aligment check
#define T_MCHK          18      // machine check
#define T_SIMDERR       19      // SIMD floating point error

// These are arbitrarily chosen, but with care not to overlap
// processor defined exceptions or interrupt vectors.
#define T_SYSCALL       64      // system call
#define T_DEFAULT      500      // catchall

#define T_IRQ0          32      // IRQ 0 corresponds to int T_IRQ

// PIC引脚定义 https://www.codenong.com/cs110792519/
// IRQ 0 – system timer (cannot be changed)
// IRQ 1 – keyboard controller (cannot be changed)
// IRQ 2 – cascaded signals from IRQs 8–15 (any devices configured to use IRQ 2 will actually be using IRQ 9)
// IRQ 3 – serial port controller for serial port 2 (shared with serial port 4, if present)
// IRQ 4 – serial port controller for serial port 1 (shared with serial port 3, if present)
// IRQ 5 – parallel port 2 and 3 or sound card
// IRQ 6 – floppy disk controller
// IRQ 7 – parallel port 1. It is used for printers or for any parallel port if a printer is not present. It can also be potentially be shared with a secondary sound card with careful management of the port.
// Slave PIC
// IRQ 8 – real-time clock (RTC)
// IRQ 9 – Advanced Configuration and Power Interface (ACPI) system control interrupt on Intel chipsets.[2] Other chipset manufacturers might use another interrupt for this purpose, or make it available for the use of peripherals (any devices configured to use IRQ 2 will actually be using IRQ 9)
// IRQ 10 – The Interrupt is left open for the use of peripherals (open interrupt/available, SCSI or NIC)
// IRQ 11 – The Interrupt is left open for the use of peripherals (open interrupt/available, SCSI or NIC)
// IRQ 12 – mouse on PS/2 connector
// IRQ 13 – CPU co-processor or integrated floating point unit or inter-processor interrupt (use depends on OS)
// IRQ 14 – primary ATA channel (ATA interface usually serves hard disk drives and CD drives)
// IRQ 15 – secondary ATA channel

#define IRQ_TIMER        0
#define IRQ_KBD          1
#define IRQ_COM1         4
#define IRQ_IDE         14
#define IRQ_ERROR       19
#define IRQ_SPURIOUS    31
#define IRQ_TEST  100

void ISRs_init();

#endif
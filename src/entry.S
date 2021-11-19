#include "multiboot.h"
#include "mmu.h"
#include "param.h"
; using macros to declare constants, $(CC) -S to to through pre-processing

#define MULTIBOOT_HEADER_FLAGS MULTIBOOT_PAGE_ALIGN | MULTIBOOT_MEMORY_INFO | MULTIBOOT_VIDEO_MODE | AOUT_KLUDGE


; declare multiboot header, see grub multiboot doc
.p2align 2 # 32-bit aligned
.text
.global multiboot_header
multiboot_header:
  .long MULTIBOOT_HEADER_MAGIC
  .long MULTIBOOT_HEADER_FLAGS
  .long -(MULTIBOOT_HEADER_MAGIC + MULTIBOOT_HEADER_FLAGS)

  lgdt    gdtdesc ; load new gdt 
  ljmp    $(SEG_KCODE<<3), $flush_segs

.global flush_segs
  # Set up the protected-mode data segment registers
  movw    $(SEG_KDATA<<3), %ax    # Our data segment selector
  movw    %ax, %ds                # -> DS: Data Segment
  movw    %ax, %es                # -> ES: Extra Segment
  movw    %ax, %ss                # -> SS: Stack Segment
  movw    $0, %ax                 # Zero segments not ready for use
  movw    %ax, %fs                # -> FS
  movw    %ax, %gs                # -> GS


; when bootloader loads the kernel, using physical addressing, for elf file the entry point is "_start"
.global _start
_start = V2P_WO(entry) ; load from here

; the kernel begins here. Do not return in this file!
.text
.global entry
entry:
  movl $(stack+KERNEL_STACK_SIZE), %esp
  pushl $0
  popf

  ; Push the pointer to the Multiboot information structure.
  movl %ebx [magic_number]
  ; Push the magic value. 
  movl %exb mbi_addr
  
  call main ; main function should never return
  cli ; turn off interrupt

spin: hlt
  jmp spin

; tell the assmbler to "allocate" a stack, this stack will be our kernel stack
; notice that x86 stack grows from high address to low address.
.p2align 4

; kernel stack: 4KB
.comm stack, KSTACKSIZE

; the magic number we want to pass to the kernel
.global magic_number
magic_number:
.long 0
; the boot info we want to pass to the kernel
.global mbi_addr
mbi_addr:
.long 0

; gdt table configuration
//
// assembler macros to create x86 segments
//

#define SEG_NULLASM                                             \
        .word 0, 0;                                             \
        .byte 0, 0, 0, 0

// The 0xC0 means the limit is in 4096-byte units
// and (for executable segments) 32-bit mode.
#define SEG_ASM(type,base,lim)                                  \
        .word (((lim) >> 12) & 0xffff), ((base) & 0xffff);      \
        .byte (((base) >> 16) & 0xff), (0x90 | (type)),         \
                (0xC0 | (((lim) >> 28) & 0xf)), (((base) >> 24) & 0xff)

#define STA_X     0x8       // Executable segment
#define STA_W     0x2       // Writeable (non-executable segments)
#define STA_R     0x2       // Readable (executable segments)


# Bootstrap GDT
.p2align 2                                # force 4 byte alignment
gdt:
  SEG_NULLASM                             # null seg
  SEG_ASM(STA_X|STA_R, 0x0, 0xffffffff)   # code seg
  SEG_ASM(STA_W, 0x0, 0xffffffff)         # data seg

gdtdesc:
  .word   (gdtdesc - gdt - 1)             # sizeof(gdt) - 1
  .long   gdt                             # address gdt
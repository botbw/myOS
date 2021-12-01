OBJS =\
	cmain.o\
	uart.o\
	giantlock.o\
	kalloc.o\
	vm.o\
	string.o\
	panic.o\
	gdt.o\
	trap.o\
	trap_asm.o\
	ISRs.o\
# Try to infer the correct QEMU
ifndef QEMU
QEMU = $(shell if which qemu > /dev/null; \
        then echo qemu; exit; \
        elif which qemu-system-i386 > /dev/null; \
        then echo qemu-system-i386; exit; \
        elif which qemu-system-x86_64 > /dev/null; \
        then echo qemu-system-x86_64; exit; \
        else \
        qemu=/Applications/Q.app/Contents/MacOS/i386-softmmu.app/Contents/MacOS/i386-softmmu; \
        if test -x $$qemu; then echo $$qemu; exit; fi; fi; \
        echo "***" 1>&2; \
        echo "*** Error: Couldn't find a working QEMU executable." 1>&2; \
        echo "*** Is the directory containing the qemu binary in your PATH" 1>&2; \
        echo "*** or have you tried setting the QEMU variable in Makefile?" 1>&2; \
        echo "***" 1>&2; exit 1)
endif

# define toolchain
CC = gcc
LD = ld
OBJCOPY = objcopy
OBJDUMP = objdump

# define toolchain options
CFLAGS = -I../include -fno-pic -static -fno-builtin -fno-strict-aliasing -Wall -Werror -Og -ggdb -fno-omit-frame-pointer -m32
# if -fnostack-protector is allowed
CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)
ASFLAGS = -m32 -gdwarf-2 -Wa,-divide
# Disable PIE when possible (for Ubuntu 16.10 toolchain)
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]no-pie'),)
CFLAGS += -fno-pie -no-pie
endif
ifneq ($(shell $(CC) -dumpspecs 2>/dev/null | grep -e '[^f]nopie'),)
CFLAGS += -fno-pie -nopie
endif
LDFLAGS = -m elf_i386



kernel: $(OBJS) kernel.ld entry.o ISRs.S
	$(LD) $(LDFLAGS) -T kernel.ld -o kernel $(OBJS) entry.o 
	$(OBJDUMP) -S kernel > kernel.asm
	$(OBJDUMP) -t kernel | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > kernel.sym
	readelf -a kernel > elf.txt

myOS.img: kernel grub.cfg
	mkdir -p tmp/boot/grub
	cp grub.cfg tmp/boot/grub
	cp kernel tmp/boot
	grub-mkrescue /usr/lib/grub/i386-pc -o myOS.img tmp

ISRs.S: isr_generator.py
	python3 isr_generator.py > ISRs.S


CPUS = 1
QEMU = qemu-system-i386
QEMUOPTS = -drive file=myOS.img,index=0,media=disk,format=raw -smp $(CPUS) -m 512 $(QEMUEXTRA)
# try to generate a unique GDB port
GDBPORT = $(shell expr `id -u` % 5000 + 25000)
# QEMU's gdb stub command line changed in 0.11
QEMUGDB = $(shell if $(QEMU) -help | grep -q '^-gdb'; \
	then echo "-gdb tcp::$(GDBPORT)"; \
	else echo "-s -p $(GDBPORT)"; fi)

.gdbinit: .gdbinit.tmpl
	sed "s/localhost:1234/localhost:$(GDBPORT)/" < $^ > $@


qemu-gdb: myOS.img .gdbinit
	qemu-system-i386 -nographic $(QEMUOPTS) -S $(QEMUGDB)

clean:
	rm *.o *.asm *.sym gdb.txt elf.txt -rf tmp kernel myOS.img makeinfo
			

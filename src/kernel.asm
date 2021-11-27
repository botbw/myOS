
kernel:     file format elf32-i386


Disassembly of section .text:

80100000 <cmain>:

void write_string(char* c, int len);
int init_serial();


void cmain(uint magic_number, multiboot_info_t *mbi) {
80100000:	f3 0f 1e fb          	endbr32 
80100004:	55                   	push   %ebp
80100005:	89 e5                	mov    %esp,%ebp
80100007:	83 ec 08             	sub    $0x8,%esp
  
  /* Am I booted by a Multiboot-compliant boot loader? */
  if(magic_number != MULTIBOOT_BOOTLOADER_MAGIC) return ;
8010000a:	81 7d 08 02 b0 ad 2b 	cmpl   $0x2badb002,0x8(%ebp)
80100011:	74 02                	je     80100015 <cmain+0x15>
  kvmalloc();

  // init the remnant of kernel memory
  kinit_all();

}
80100013:	c9                   	leave  
80100014:	c3                   	ret    
  if(init_serial() != 0) return ;
80100015:	e8 4f 00 00 00       	call   80100069 <init_serial>
8010001a:	85 c0                	test   %eax,%eax
8010001c:	75 f5                	jne    80100013 <cmain+0x13>
  write_string(welcome_str, 34);
8010001e:	83 ec 08             	sub    $0x8,%esp
80100021:	6a 22                	push   $0x22
80100023:	68 00 20 10 80       	push   $0x80102000
80100028:	e8 20 01 00 00       	call   8010014d <write_string>
  if(CHECK_FLAG(mbi->flags, 0)) {
8010002d:	83 c4 10             	add    $0x10,%esp
80100030:	8b 45 0c             	mov    0xc(%ebp),%eax
80100033:	f6 00 01             	testb  $0x1,(%eax)
80100036:	74 db                	je     80100013 <cmain+0x13>
    mem_lower = mbi->mem_lower;
80100038:	8b 40 04             	mov    0x4(%eax),%eax
8010003b:	a3 88 20 10 80       	mov    %eax,0x80102088
    mem_upper = mbi->mem_upper;
80100040:	8b 45 0c             	mov    0xc(%ebp),%eax
80100043:	8b 40 08             	mov    0x8(%eax),%eax
80100046:	a3 84 20 10 80       	mov    %eax,0x80102084
    phystop = ((mem_upper+1024)<<4); // mem_upper(in KB) + 1MB(1024 KB)
8010004b:	05 00 04 00 00       	add    $0x400,%eax
80100050:	c1 e0 04             	shl    $0x4,%eax
80100053:	a3 80 20 10 80       	mov    %eax,0x80102080
  kinit();
80100058:	e8 3d 02 00 00       	call   8010029a <kinit>
  kvmalloc();
8010005d:	e8 b5 03 00 00       	call   80100417 <kvmalloc>
  kinit_all();
80100062:	e8 6f 02 00 00       	call   801002d6 <kinit_all>
80100067:	eb aa                	jmp    80100013 <cmain+0x13>

80100069 <init_serial>:
#include "x86.h"

#define PORT 0x3f8          // COM1

int init_serial() {
80100069:	f3 0f 1e fb          	endbr32 
8010006d:	55                   	push   %ebp
8010006e:	89 e5                	mov    %esp,%ebp
80100070:	57                   	push   %edi
80100071:	56                   	push   %esi
80100072:	53                   	push   %ebx
}

static inline void
outb(ushort port, uchar data)
{
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80100073:	be 00 00 00 00       	mov    $0x0,%esi
80100078:	bf f9 03 00 00       	mov    $0x3f9,%edi
8010007d:	89 f0                	mov    %esi,%eax
8010007f:	89 fa                	mov    %edi,%edx
80100081:	ee                   	out    %al,(%dx)
80100082:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
80100087:	ba fb 03 00 00       	mov    $0x3fb,%edx
8010008c:	ee                   	out    %al,(%dx)
8010008d:	bb 03 00 00 00       	mov    $0x3,%ebx
80100092:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
80100097:	89 d8                	mov    %ebx,%eax
80100099:	89 ca                	mov    %ecx,%edx
8010009b:	ee                   	out    %al,(%dx)
8010009c:	89 f0                	mov    %esi,%eax
8010009e:	89 fa                	mov    %edi,%edx
801000a0:	ee                   	out    %al,(%dx)
801000a1:	89 d8                	mov    %ebx,%eax
801000a3:	ba fb 03 00 00       	mov    $0x3fb,%edx
801000a8:	ee                   	out    %al,(%dx)
801000a9:	b8 c7 ff ff ff       	mov    $0xffffffc7,%eax
801000ae:	ba fa 03 00 00       	mov    $0x3fa,%edx
801000b3:	ee                   	out    %al,(%dx)
801000b4:	ba fc 03 00 00       	mov    $0x3fc,%edx
801000b9:	b8 0b 00 00 00       	mov    $0xb,%eax
801000be:	ee                   	out    %al,(%dx)
801000bf:	b8 1e 00 00 00       	mov    $0x1e,%eax
801000c4:	ee                   	out    %al,(%dx)
801000c5:	b8 ae ff ff ff       	mov    $0xffffffae,%eax
801000ca:	89 ca                	mov    %ecx,%edx
801000cc:	ee                   	out    %al,(%dx)
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801000cd:	ec                   	in     (%dx),%al
   outb(PORT + 4, 0x0B);    // IRQs enabled, RTS/DSR set
   outb(PORT + 4, 0x1E);    // Set in loopback mode, test the serial chip
   outb(PORT + 0, 0xAE);    // Test serial chip (send byte 0xAE and check if serial returns same byte)
 
   // Check if serial is faulty (i.e: not same byte as sent)
   if(inb(PORT + 0) != 0xAE) {
801000ce:	3c ae                	cmp    $0xae,%al
801000d0:	75 15                	jne    801000e7 <init_serial+0x7e>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801000d2:	b8 0f 00 00 00       	mov    $0xf,%eax
801000d7:	ba fc 03 00 00       	mov    $0x3fc,%edx
801000dc:	ee                   	out    %al,(%dx)
   }
 
   // If serial is not faulty set it in normal operation mode
   // (not-loopback with IRQs enabled and OUT#1 and OUT#2 bits enabled)
   outb(PORT + 4, 0x0F);
   return 0;
801000dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
801000e2:	5b                   	pop    %ebx
801000e3:	5e                   	pop    %esi
801000e4:	5f                   	pop    %edi
801000e5:	5d                   	pop    %ebp
801000e6:	c3                   	ret    
      return 1;
801000e7:	b8 01 00 00 00       	mov    $0x1,%eax
801000ec:	eb f4                	jmp    801000e2 <init_serial+0x79>

801000ee <serial_received>:

int serial_received() {
801000ee:	f3 0f 1e fb          	endbr32 
  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
801000f2:	ba fd 03 00 00       	mov    $0x3fd,%edx
801000f7:	ec                   	in     (%dx),%al
   return inb(PORT + 5) & 1;
801000f8:	83 e0 01             	and    $0x1,%eax
}
801000fb:	c3                   	ret    

801000fc <read_serial>:
 
char read_serial() {
801000fc:	f3 0f 1e fb          	endbr32 
80100100:	55                   	push   %ebp
80100101:	89 e5                	mov    %esp,%ebp
80100103:	83 ec 08             	sub    $0x8,%esp
   while (serial_received() == 0);
80100106:	e8 e3 ff ff ff       	call   801000ee <serial_received>
8010010b:	85 c0                	test   %eax,%eax
8010010d:	74 f7                	je     80100106 <read_serial+0xa>
8010010f:	ba f8 03 00 00       	mov    $0x3f8,%edx
80100114:	ec                   	in     (%dx),%al
 
   return inb(PORT);
}
80100115:	c9                   	leave  
80100116:	c3                   	ret    

80100117 <is_transmit_empty>:

int is_transmit_empty() {
80100117:	f3 0f 1e fb          	endbr32 
8010011b:	ba fd 03 00 00       	mov    $0x3fd,%edx
80100120:	ec                   	in     (%dx),%al
   return inb(PORT + 5) & 0x20;
80100121:	83 e0 20             	and    $0x20,%eax
80100124:	0f b6 c0             	movzbl %al,%eax
}
80100127:	c3                   	ret    

80100128 <write_serial>:
 
void write_serial(char a) {
80100128:	f3 0f 1e fb          	endbr32 
8010012c:	55                   	push   %ebp
8010012d:	89 e5                	mov    %esp,%ebp
8010012f:	53                   	push   %ebx
80100130:	83 ec 04             	sub    $0x4,%esp
80100133:	8b 5d 08             	mov    0x8(%ebp),%ebx
   while (is_transmit_empty() == 0);
80100136:	e8 dc ff ff ff       	call   80100117 <is_transmit_empty>
8010013b:	85 c0                	test   %eax,%eax
8010013d:	74 f7                	je     80100136 <write_serial+0xe>
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010013f:	ba f8 03 00 00       	mov    $0x3f8,%edx
80100144:	89 d8                	mov    %ebx,%eax
80100146:	ee                   	out    %al,(%dx)
 
   outb(PORT,a);
}
80100147:	83 c4 04             	add    $0x4,%esp
8010014a:	5b                   	pop    %ebx
8010014b:	5d                   	pop    %ebp
8010014c:	c3                   	ret    

8010014d <write_string>:

void write_string(char* c, int len) {
8010014d:	f3 0f 1e fb          	endbr32 
80100151:	55                   	push   %ebp
80100152:	89 e5                	mov    %esp,%ebp
80100154:	57                   	push   %edi
80100155:	56                   	push   %esi
80100156:	53                   	push   %ebx
80100157:	83 ec 0c             	sub    $0xc,%esp
8010015a:	8b 7d 08             	mov    0x8(%ebp),%edi
8010015d:	8b 75 0c             	mov    0xc(%ebp),%esi
  for(int i = 0; i < len; i++)
80100160:	bb 00 00 00 00       	mov    $0x0,%ebx
80100165:	39 f3                	cmp    %esi,%ebx
80100167:	7d 15                	jge    8010017e <write_string+0x31>
    write_serial(c[i]);
80100169:	83 ec 0c             	sub    $0xc,%esp
8010016c:	0f be 04 1f          	movsbl (%edi,%ebx,1),%eax
80100170:	50                   	push   %eax
80100171:	e8 b2 ff ff ff       	call   80100128 <write_serial>
  for(int i = 0; i < len; i++)
80100176:	83 c3 01             	add    $0x1,%ebx
80100179:	83 c4 10             	add    $0x10,%esp
8010017c:	eb e7                	jmp    80100165 <write_string+0x18>
}
8010017e:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100181:	5b                   	pop    %ebx
80100182:	5e                   	pop    %esi
80100183:	5f                   	pop    %edi
80100184:	5d                   	pop    %ebp
80100185:	c3                   	ret    

80100186 <acquire>:
// Since we will be running on a single processor system.
// turning on/off interrupt will be enough to solve competitive condition


// turn off interrupt
void acquire() {
80100186:	f3 0f 1e fb          	endbr32 
}

static inline void
cli(void)
{
  asm volatile("cli");
8010018a:	fa                   	cli    
  cli();
}
8010018b:	c3                   	ret    

8010018c <release>:

// turn on interrupt
void release() {
8010018c:	f3 0f 1e fb          	endbr32 
}

static inline void
sti(void)
{
  asm volatile("sti");
80100190:	fb                   	sti    
  sti();
80100191:	c3                   	ret    

80100192 <kfree>:
  uint pgnum;
  int use_lock;
} kmem;

// free one page and fill it with junk, the interrupt is assumed to be turned on already;
void kfree(void *ptr) {
80100192:	f3 0f 1e fb          	endbr32 
80100196:	55                   	push   %ebp
80100197:	89 e5                	mov    %esp,%ebp
80100199:	53                   	push   %ebx
8010019a:	83 ec 04             	sub    $0x4,%esp
8010019d:	8b 5d 08             	mov    0x8(%ebp),%ebx

  if((uint)ptr % PGSIZE || (char*)ptr < end || V2P(ptr) >= phystop)
801001a0:	f7 c3 ff 0f 00 00    	test   $0xfff,%ebx
801001a6:	75 16                	jne    801001be <kfree+0x2c>
801001a8:	81 fb a0 30 10 80    	cmp    $0x801030a0,%ebx
801001ae:	72 0e                	jb     801001be <kfree+0x2c>
801001b0:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801001b6:	3b 05 80 20 10 80    	cmp    0x80102080,%eax
801001bc:	72 10                	jb     801001ce <kfree+0x3c>
    panic("kfree");
801001be:	83 ec 0c             	sub    $0xc,%esp
801001c1:	68 8c 0a 10 80       	push   $0x80100a8c
801001c6:	e8 a7 04 00 00       	call   80100672 <panic>
801001cb:	83 c4 10             	add    $0x10,%esp

  memset(ptr, 1, PGSIZE);
801001ce:	83 ec 04             	sub    $0x4,%esp
801001d1:	68 00 10 00 00       	push   $0x1000
801001d6:	6a 01                	push   $0x1
801001d8:	53                   	push   %ebx
801001d9:	e8 b7 02 00 00       	call   80100495 <memset>
  if(kmem.use_lock) acquire();
801001de:	83 c4 10             	add    $0x10,%esp
801001e1:	83 3d 94 20 10 80 00 	cmpl   $0x0,0x80102094
801001e8:	75 28                	jne    80100212 <kfree+0x80>
  struct run *tmp = (struct run*)ptr;
  tmp->next = kmem.head;
801001ea:	a1 8c 20 10 80       	mov    0x8010208c,%eax
801001ef:	89 03                	mov    %eax,(%ebx)
  kmem.head = tmp;
801001f1:	89 1d 8c 20 10 80    	mov    %ebx,0x8010208c
  kmem.pgnum++;
801001f7:	a1 90 20 10 80       	mov    0x80102090,%eax
801001fc:	83 c0 01             	add    $0x1,%eax
801001ff:	a3 90 20 10 80       	mov    %eax,0x80102090
  if(kmem.use_lock) release();
80100204:	83 3d 94 20 10 80 00 	cmpl   $0x0,0x80102094
8010020b:	75 0c                	jne    80100219 <kfree+0x87>
}
8010020d:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100210:	c9                   	leave  
80100211:	c3                   	ret    
  if(kmem.use_lock) acquire();
80100212:	e8 6f ff ff ff       	call   80100186 <acquire>
80100217:	eb d1                	jmp    801001ea <kfree+0x58>
  if(kmem.use_lock) release();
80100219:	e8 6e ff ff ff       	call   8010018c <release>
}
8010021e:	eb ed                	jmp    8010020d <kfree+0x7b>

80100220 <kalloc>:

// alloc one memory page filled with junk;
void *kalloc() {
80100220:	f3 0f 1e fb          	endbr32 
80100224:	55                   	push   %ebp
80100225:	89 e5                	mov    %esp,%ebp
80100227:	53                   	push   %ebx
80100228:	83 ec 04             	sub    $0x4,%esp
  if(kmem.use_lock) acquire();
8010022b:	83 3d 94 20 10 80 00 	cmpl   $0x0,0x80102094
80100232:	75 1e                	jne    80100252 <kalloc+0x32>
  struct run *tmp = kmem.head;
80100234:	8b 1d 8c 20 10 80    	mov    0x8010208c,%ebx
  kmem.head = kmem.head->next;
8010023a:	8b 03                	mov    (%ebx),%eax
8010023c:	a3 8c 20 10 80       	mov    %eax,0x8010208c
  if(kmem.use_lock) release();
80100241:	83 3d 94 20 10 80 00 	cmpl   $0x0,0x80102094
80100248:	75 0f                	jne    80100259 <kalloc+0x39>
  return (void*)tmp;
}
8010024a:	89 d8                	mov    %ebx,%eax
8010024c:	83 c4 04             	add    $0x4,%esp
8010024f:	5b                   	pop    %ebx
80100250:	5d                   	pop    %ebp
80100251:	c3                   	ret    
  if(kmem.use_lock) acquire();
80100252:	e8 2f ff ff ff       	call   80100186 <acquire>
80100257:	eb db                	jmp    80100234 <kalloc+0x14>
  if(kmem.use_lock) release();
80100259:	e8 2e ff ff ff       	call   8010018c <release>
  return (void*)tmp;
8010025e:	eb ea                	jmp    8010024a <kalloc+0x2a>

80100260 <freerange>:

// free a range of memory using kfree(ptr);
void freerange(void* start_addr, void* end_addr) {
80100260:	f3 0f 1e fb          	endbr32 
80100264:	55                   	push   %ebp
80100265:	89 e5                	mov    %esp,%ebp
80100267:	56                   	push   %esi
80100268:	53                   	push   %ebx
80100269:	8b 5d 0c             	mov    0xc(%ebp),%ebx
  char *p;
  p = (char*)PGROUNDUP((uint)start_addr);
8010026c:	8b 45 08             	mov    0x8(%ebp),%eax
8010026f:	05 ff 0f 00 00       	add    $0xfff,%eax
80100274:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  for(; p + PGSIZE <= (char*)end_addr; p += PGSIZE)
80100279:	8d b0 00 10 00 00    	lea    0x1000(%eax),%esi
8010027f:	39 de                	cmp    %ebx,%esi
80100281:	77 10                	ja     80100293 <freerange+0x33>
    kfree(p);
80100283:	83 ec 0c             	sub    $0xc,%esp
80100286:	50                   	push   %eax
80100287:	e8 06 ff ff ff       	call   80100192 <kfree>
8010028c:	83 c4 10             	add    $0x10,%esp
  for(; p + PGSIZE <= (char*)end_addr; p += PGSIZE)
8010028f:	89 f0                	mov    %esi,%eax
80100291:	eb e6                	jmp    80100279 <freerange+0x19>
}
80100293:	8d 65 f8             	lea    -0x8(%ebp),%esp
80100296:	5b                   	pop    %ebx
80100297:	5e                   	pop    %esi
80100298:	5d                   	pop    %ebp
80100299:	c3                   	ret    

8010029a <kinit>:

// similar to freerange(end, 4mb), but with interrupt turned off
// only the first 4MB because we only set up its memory mapping in entrypgdir[] defined in main.c
void kinit() {
8010029a:	f3 0f 1e fb          	endbr32 
8010029e:	55                   	push   %ebp
8010029f:	89 e5                	mov    %esp,%ebp
801002a1:	83 ec 10             	sub    $0x10,%esp
  kmem.head = 0;
801002a4:	c7 05 8c 20 10 80 00 	movl   $0x0,0x8010208c
801002ab:	00 00 00 
  kmem.pgnum = 0;
801002ae:	c7 05 90 20 10 80 00 	movl   $0x0,0x80102090
801002b5:	00 00 00 
  kmem.use_lock = 0;
801002b8:	c7 05 94 20 10 80 00 	movl   $0x0,0x80102094
801002bf:	00 00 00 

  char *p = end;
  char *end_of_4MB = P2V(4*1024*1024);

  freerange(p, end_of_4MB);
801002c2:	68 00 00 40 80       	push   $0x80400000
801002c7:	68 a0 30 10 80       	push   $0x801030a0
801002cc:	e8 8f ff ff ff       	call   80100260 <freerange>
}
801002d1:	83 c4 10             	add    $0x10,%esp
801002d4:	c9                   	leave  
801002d5:	c3                   	ret    

801002d6 <kinit_all>:

// similar to kinit(), but map all the memory
void kinit_all() {
801002d6:	f3 0f 1e fb          	endbr32 
801002da:	55                   	push   %ebp
801002db:	89 e5                	mov    %esp,%ebp
801002dd:	83 ec 10             	sub    $0x10,%esp
  kmem.head = 0;
801002e0:	c7 05 8c 20 10 80 00 	movl   $0x0,0x8010208c
801002e7:	00 00 00 
  kmem.pgnum = 0;
801002ea:	c7 05 90 20 10 80 00 	movl   $0x0,0x80102090
801002f1:	00 00 00 

  char *p = P2V(4*1024*1024);
  char *end = P2V(PHYSTOP);

  freerange(p, end);
801002f4:	68 00 00 00 8e       	push   $0x8e000000
801002f9:	68 00 00 40 80       	push   $0x80400000
801002fe:	e8 5d ff ff ff       	call   80100260 <freerange>
}
80100303:	83 c4 10             	add    $0x10,%esp
80100306:	c9                   	leave  
80100307:	c3                   	ret    

80100308 <switchkvm>:
// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
static void
switchkvm(void)
{
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80100308:	a1 98 20 10 80       	mov    0x80102098,%eax
8010030d:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80100312:	0f 22 d8             	mov    %eax,%cr3
}
80100315:	c3                   	ret    

80100316 <walkpgdir>:

// go through the page directories using virtual address, page allocation is optional
pte_t *walkpgdir(pde_t *pgdir, const void* va, int alloc) {
80100316:	f3 0f 1e fb          	endbr32 
8010031a:	55                   	push   %ebp
8010031b:	89 e5                	mov    %esp,%ebp
8010031d:	57                   	push   %edi
8010031e:	56                   	push   %esi
8010031f:	53                   	push   %ebx
80100320:	83 ec 0c             	sub    $0xc,%esp
80100323:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pde_t *pde = &pgdir[PDX(va)];
80100326:	89 fe                	mov    %edi,%esi
80100328:	c1 ee 16             	shr    $0x16,%esi
8010032b:	c1 e6 02             	shl    $0x2,%esi
8010032e:	03 75 08             	add    0x8(%ebp),%esi
  pte_t *pgtbl;
  if(*pde & PTE_P) {
80100331:	8b 1e                	mov    (%esi),%ebx
80100333:	f6 c3 01             	test   $0x1,%bl
80100336:	74 20                	je     80100358 <walkpgdir+0x42>
    pgtbl = (pte_t*)P2V(PTE_ADDR(*pde)); // noticed that the address in the pgdir is physical address
80100338:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
8010033e:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    if(!alloc || (pgtbl = (pte_t*)kalloc()) == 0) return 0;
    // Make sure all those PTE_P bits are zero.
    memset(pgtbl, 0, PGSIZE);
    *pde = V2P(pgtbl) | PTE_P | PTE_W | PTE_U; // since we did page alignment in kfree, the address of pgtbl is alredy 4KB aligned (which means the 12 lower bits are 0).
  }
  return &pgtbl[PTX(va)];
80100344:	c1 ef 0c             	shr    $0xc,%edi
80100347:	81 e7 ff 03 00 00    	and    $0x3ff,%edi
8010034d:	8d 04 bb             	lea    (%ebx,%edi,4),%eax
}
80100350:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100353:	5b                   	pop    %ebx
80100354:	5e                   	pop    %esi
80100355:	5f                   	pop    %edi
80100356:	5d                   	pop    %ebp
80100357:	c3                   	ret    
    if(!alloc || (pgtbl = (pte_t*)kalloc()) == 0) return 0;
80100358:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010035c:	74 2b                	je     80100389 <walkpgdir+0x73>
8010035e:	e8 bd fe ff ff       	call   80100220 <kalloc>
80100363:	89 c3                	mov    %eax,%ebx
80100365:	85 c0                	test   %eax,%eax
80100367:	74 20                	je     80100389 <walkpgdir+0x73>
    memset(pgtbl, 0, PGSIZE);
80100369:	83 ec 04             	sub    $0x4,%esp
8010036c:	68 00 10 00 00       	push   $0x1000
80100371:	6a 00                	push   $0x0
80100373:	50                   	push   %eax
80100374:	e8 1c 01 00 00       	call   80100495 <memset>
    *pde = V2P(pgtbl) | PTE_P | PTE_W | PTE_U; // since we did page alignment in kfree, the address of pgtbl is alredy 4KB aligned (which means the 12 lower bits are 0).
80100379:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
8010037f:	83 c8 07             	or     $0x7,%eax
80100382:	89 06                	mov    %eax,(%esi)
80100384:	83 c4 10             	add    $0x10,%esp
80100387:	eb bb                	jmp    80100344 <walkpgdir+0x2e>
    if(!alloc || (pgtbl = (pte_t*)kalloc()) == 0) return 0;
80100389:	b8 00 00 00 00       	mov    $0x0,%eax
8010038e:	eb c0                	jmp    80100350 <walkpgdir+0x3a>

80100390 <mappages>:

int mappages(pde_t* pgdir, void* va, uint sz, uint pa, int perm) {
80100390:	f3 0f 1e fb          	endbr32 
80100394:	55                   	push   %ebp
80100395:	89 e5                	mov    %esp,%ebp
80100397:	57                   	push   %edi
80100398:	56                   	push   %esi
80100399:	53                   	push   %ebx
8010039a:	83 ec 1c             	sub    $0x1c,%esp
8010039d:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *p = (char*)PGROUNDDOWN((uint)va);                 // mapping is by pages
801003a0:	8b 45 0c             	mov    0xc(%ebp),%eax
801003a3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801003a8:	89 c6                	mov    %eax,%esi
  char *end = (char*)PGROUNDDOWN((uint)p+sz-1);           
801003aa:	03 45 10             	add    0x10(%ebp),%eax
801003ad:	83 e8 01             	sub    $0x1,%eax
801003b0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801003b5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  for(; p != end; pa += PGSIZE, p += PGSIZE) {
801003b8:	eb 26                	jmp    801003e0 <mappages+0x50>
    pte_t *pte = walkpgdir(pgdir, p, 1);                  // find the corresponding pagetable or create a new one
    if(pte == 0) return -1;
    if((*pte) & PTE_P) panic("mappages");
801003ba:	83 ec 0c             	sub    $0xc,%esp
801003bd:	68 92 0a 10 80       	push   $0x80100a92
801003c2:	e8 ab 02 00 00       	call   80100672 <panic>
801003c7:	83 c4 10             	add    $0x10,%esp
    *pte = pa | PTE_P | perm;
801003ca:	89 f8                	mov    %edi,%eax
801003cc:	0b 45 18             	or     0x18(%ebp),%eax
801003cf:	83 c8 01             	or     $0x1,%eax
801003d2:	89 03                	mov    %eax,(%ebx)
  for(; p != end; pa += PGSIZE, p += PGSIZE) {
801003d4:	81 c7 00 10 00 00    	add    $0x1000,%edi
801003da:	81 c6 00 10 00 00    	add    $0x1000,%esi
801003e0:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
801003e3:	74 1e                	je     80100403 <mappages+0x73>
    pte_t *pte = walkpgdir(pgdir, p, 1);                  // find the corresponding pagetable or create a new one
801003e5:	83 ec 04             	sub    $0x4,%esp
801003e8:	6a 01                	push   $0x1
801003ea:	56                   	push   %esi
801003eb:	ff 75 08             	pushl  0x8(%ebp)
801003ee:	e8 23 ff ff ff       	call   80100316 <walkpgdir>
801003f3:	89 c3                	mov    %eax,%ebx
    if(pte == 0) return -1;
801003f5:	83 c4 10             	add    $0x10,%esp
801003f8:	85 c0                	test   %eax,%eax
801003fa:	74 14                	je     80100410 <mappages+0x80>
    if((*pte) & PTE_P) panic("mappages");
801003fc:	f6 00 01             	testb  $0x1,(%eax)
801003ff:	74 c9                	je     801003ca <mappages+0x3a>
80100401:	eb b7                	jmp    801003ba <mappages+0x2a>
  }
  return 0;
80100403:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100408:	8d 65 f4             	lea    -0xc(%ebp),%esp
8010040b:	5b                   	pop    %ebx
8010040c:	5e                   	pop    %esi
8010040d:	5f                   	pop    %edi
8010040e:	5d                   	pop    %ebp
8010040f:	c3                   	ret    
    if(pte == 0) return -1;
80100410:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100415:	eb f1                	jmp    80100408 <mappages+0x78>

80100417 <kvmalloc>:



void kvmalloc() {
80100417:	f3 0f 1e fb          	endbr32 
8010041b:	55                   	push   %ebp
8010041c:	89 e5                	mov    %esp,%ebp
8010041e:	53                   	push   %ebx
8010041f:	83 ec 04             	sub    $0x4,%esp
  kpgdir = (pde_t*)kalloc();
80100422:	e8 f9 fd ff ff       	call   80100220 <kalloc>
80100427:	a3 98 20 10 80       	mov    %eax,0x80102098
  if(!kpgdir) return;
8010042c:	85 c0                	test   %eax,%eax
8010042e:	74 60                	je     80100490 <kvmalloc+0x79>
  // make sure all those PDE_P/PTE_P bits are clear
  memset(kpgdir, 0, PGSIZE);
80100430:	83 ec 04             	sub    $0x4,%esp
80100433:	68 00 10 00 00       	push   $0x1000
80100438:	6a 00                	push   $0x0
8010043a:	50                   	push   %eax
8010043b:	e8 55 00 00 00       	call   80100495 <memset>
  struct kmap_t *k;
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++) {
80100440:	83 c4 10             	add    $0x10,%esp
80100443:	bb 40 20 10 80       	mov    $0x80102040,%ebx
80100448:	eb 03                	jmp    8010044d <kvmalloc+0x36>
8010044a:	83 c3 10             	add    $0x10,%ebx
8010044d:	81 fb 80 20 10 80    	cmp    $0x80102080,%ebx
80100453:	73 36                	jae    8010048b <kvmalloc+0x74>
    if(mappages(kpgdir, k->virt, k->phys_end - k->phys_start,
                (uint)k->phys_start, k->perm) < 0) {
80100455:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(kpgdir, k->virt, k->phys_end - k->phys_start,
80100458:	83 ec 0c             	sub    $0xc,%esp
8010045b:	ff 73 0c             	pushl  0xc(%ebx)
8010045e:	50                   	push   %eax
8010045f:	8b 53 08             	mov    0x8(%ebx),%edx
80100462:	29 c2                	sub    %eax,%edx
80100464:	52                   	push   %edx
80100465:	ff 33                	pushl  (%ebx)
80100467:	ff 35 98 20 10 80    	pushl  0x80102098
8010046d:	e8 1e ff ff ff       	call   80100390 <mappages>
80100472:	83 c4 20             	add    $0x20,%esp
80100475:	85 c0                	test   %eax,%eax
80100477:	79 d1                	jns    8010044a <kvmalloc+0x33>
      panic("kvmalloc");
80100479:	83 ec 0c             	sub    $0xc,%esp
8010047c:	68 9b 0a 10 80       	push   $0x80100a9b
80100481:	e8 ec 01 00 00       	call   80100672 <panic>
80100486:	83 c4 10             	add    $0x10,%esp
80100489:	eb bf                	jmp    8010044a <kvmalloc+0x33>
    }
  }
  switchkvm();
8010048b:	e8 78 fe ff ff       	call   80100308 <switchkvm>
}
80100490:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80100493:	c9                   	leave  
80100494:	c3                   	ret    

80100495 <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
80100495:	f3 0f 1e fb          	endbr32 
80100499:	55                   	push   %ebp
8010049a:	89 e5                	mov    %esp,%ebp
8010049c:	57                   	push   %edi
8010049d:	53                   	push   %ebx
8010049e:	8b 55 08             	mov    0x8(%ebp),%edx
801004a1:	8b 45 0c             	mov    0xc(%ebp),%eax
801004a4:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
801004a7:	f6 c2 03             	test   $0x3,%dl
801004aa:	75 25                	jne    801004d1 <memset+0x3c>
801004ac:	f6 c1 03             	test   $0x3,%cl
801004af:	75 20                	jne    801004d1 <memset+0x3c>
    c &= 0xFF;
801004b1:	0f b6 f8             	movzbl %al,%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801004b4:	c1 e9 02             	shr    $0x2,%ecx
801004b7:	c1 e0 18             	shl    $0x18,%eax
801004ba:	89 fb                	mov    %edi,%ebx
801004bc:	c1 e3 10             	shl    $0x10,%ebx
801004bf:	09 d8                	or     %ebx,%eax
801004c1:	89 fb                	mov    %edi,%ebx
801004c3:	c1 e3 08             	shl    $0x8,%ebx
801004c6:	09 d8                	or     %ebx,%eax
801004c8:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
801004ca:	89 d7                	mov    %edx,%edi
801004cc:	fc                   	cld    
801004cd:	f3 ab                	rep stos %eax,%es:(%edi)
}
801004cf:	eb 05                	jmp    801004d6 <memset+0x41>
  asm volatile("cld; rep stosb" :
801004d1:	89 d7                	mov    %edx,%edi
801004d3:	fc                   	cld    
801004d4:	f3 aa                	rep stos %al,%es:(%edi)
  } else
    stosb(dst, c, n);
  return dst;
}
801004d6:	89 d0                	mov    %edx,%eax
801004d8:	5b                   	pop    %ebx
801004d9:	5f                   	pop    %edi
801004da:	5d                   	pop    %ebp
801004db:	c3                   	ret    

801004dc <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
801004dc:	f3 0f 1e fb          	endbr32 
801004e0:	55                   	push   %ebp
801004e1:	89 e5                	mov    %esp,%ebp
801004e3:	56                   	push   %esi
801004e4:	53                   	push   %ebx
801004e5:	8b 4d 08             	mov    0x8(%ebp),%ecx
801004e8:	8b 55 0c             	mov    0xc(%ebp),%edx
801004eb:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
801004ee:	8d 70 ff             	lea    -0x1(%eax),%esi
801004f1:	85 c0                	test   %eax,%eax
801004f3:	74 1c                	je     80100511 <memcmp+0x35>
    if(*s1 != *s2)
801004f5:	0f b6 01             	movzbl (%ecx),%eax
801004f8:	0f b6 1a             	movzbl (%edx),%ebx
801004fb:	38 d8                	cmp    %bl,%al
801004fd:	75 0a                	jne    80100509 <memcmp+0x2d>
      return *s1 - *s2;
    s1++, s2++;
801004ff:	83 c1 01             	add    $0x1,%ecx
80100502:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
80100505:	89 f0                	mov    %esi,%eax
80100507:	eb e5                	jmp    801004ee <memcmp+0x12>
      return *s1 - *s2;
80100509:	0f b6 c0             	movzbl %al,%eax
8010050c:	0f b6 db             	movzbl %bl,%ebx
8010050f:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
80100511:	5b                   	pop    %ebx
80100512:	5e                   	pop    %esi
80100513:	5d                   	pop    %ebp
80100514:	c3                   	ret    

80100515 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
80100515:	f3 0f 1e fb          	endbr32 
80100519:	55                   	push   %ebp
8010051a:	89 e5                	mov    %esp,%ebp
8010051c:	56                   	push   %esi
8010051d:	53                   	push   %ebx
8010051e:	8b 75 08             	mov    0x8(%ebp),%esi
80100521:	8b 55 0c             	mov    0xc(%ebp),%edx
80100524:	8b 45 10             	mov    0x10(%ebp),%eax
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80100527:	39 f2                	cmp    %esi,%edx
80100529:	73 3a                	jae    80100565 <memmove+0x50>
8010052b:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
8010052e:	39 f1                	cmp    %esi,%ecx
80100530:	76 37                	jbe    80100569 <memmove+0x54>
    s += n;
    d += n;
80100532:	8d 14 06             	lea    (%esi,%eax,1),%edx
    while(n-- > 0)
80100535:	8d 58 ff             	lea    -0x1(%eax),%ebx
80100538:	85 c0                	test   %eax,%eax
8010053a:	74 23                	je     8010055f <memmove+0x4a>
      *--d = *--s;
8010053c:	83 e9 01             	sub    $0x1,%ecx
8010053f:	83 ea 01             	sub    $0x1,%edx
80100542:	0f b6 01             	movzbl (%ecx),%eax
80100545:	88 02                	mov    %al,(%edx)
    while(n-- > 0)
80100547:	89 d8                	mov    %ebx,%eax
80100549:	eb ea                	jmp    80100535 <memmove+0x20>
  } else
    while(n-- > 0)
      *d++ = *s++;
8010054b:	0f b6 02             	movzbl (%edx),%eax
8010054e:	88 01                	mov    %al,(%ecx)
80100550:	8d 49 01             	lea    0x1(%ecx),%ecx
80100553:	8d 52 01             	lea    0x1(%edx),%edx
    while(n-- > 0)
80100556:	89 d8                	mov    %ebx,%eax
80100558:	8d 58 ff             	lea    -0x1(%eax),%ebx
8010055b:	85 c0                	test   %eax,%eax
8010055d:	75 ec                	jne    8010054b <memmove+0x36>

  return dst;
}
8010055f:	89 f0                	mov    %esi,%eax
80100561:	5b                   	pop    %ebx
80100562:	5e                   	pop    %esi
80100563:	5d                   	pop    %ebp
80100564:	c3                   	ret    
80100565:	89 f1                	mov    %esi,%ecx
80100567:	eb ef                	jmp    80100558 <memmove+0x43>
80100569:	89 f1                	mov    %esi,%ecx
8010056b:	eb eb                	jmp    80100558 <memmove+0x43>

8010056d <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
8010056d:	f3 0f 1e fb          	endbr32 
80100571:	55                   	push   %ebp
80100572:	89 e5                	mov    %esp,%ebp
80100574:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
80100577:	ff 75 10             	pushl  0x10(%ebp)
8010057a:	ff 75 0c             	pushl  0xc(%ebp)
8010057d:	ff 75 08             	pushl  0x8(%ebp)
80100580:	e8 90 ff ff ff       	call   80100515 <memmove>
}
80100585:	c9                   	leave  
80100586:	c3                   	ret    

80100587 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80100587:	f3 0f 1e fb          	endbr32 
8010058b:	55                   	push   %ebp
8010058c:	89 e5                	mov    %esp,%ebp
8010058e:	53                   	push   %ebx
8010058f:	8b 55 08             	mov    0x8(%ebp),%edx
80100592:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100595:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
80100598:	eb 09                	jmp    801005a3 <strncmp+0x1c>
    n--, p++, q++;
8010059a:	83 e8 01             	sub    $0x1,%eax
8010059d:	83 c2 01             	add    $0x1,%edx
801005a0:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
801005a3:	85 c0                	test   %eax,%eax
801005a5:	74 0b                	je     801005b2 <strncmp+0x2b>
801005a7:	0f b6 1a             	movzbl (%edx),%ebx
801005aa:	84 db                	test   %bl,%bl
801005ac:	74 04                	je     801005b2 <strncmp+0x2b>
801005ae:	3a 19                	cmp    (%ecx),%bl
801005b0:	74 e8                	je     8010059a <strncmp+0x13>
  if(n == 0)
801005b2:	85 c0                	test   %eax,%eax
801005b4:	74 0b                	je     801005c1 <strncmp+0x3a>
    return 0;
  return (uchar)*p - (uchar)*q;
801005b6:	0f b6 02             	movzbl (%edx),%eax
801005b9:	0f b6 11             	movzbl (%ecx),%edx
801005bc:	29 d0                	sub    %edx,%eax
}
801005be:	5b                   	pop    %ebx
801005bf:	5d                   	pop    %ebp
801005c0:	c3                   	ret    
    return 0;
801005c1:	b8 00 00 00 00       	mov    $0x0,%eax
801005c6:	eb f6                	jmp    801005be <strncmp+0x37>

801005c8 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
801005c8:	f3 0f 1e fb          	endbr32 
801005cc:	55                   	push   %ebp
801005cd:	89 e5                	mov    %esp,%ebp
801005cf:	57                   	push   %edi
801005d0:	56                   	push   %esi
801005d1:	53                   	push   %ebx
801005d2:	8b 7d 08             	mov    0x8(%ebp),%edi
801005d5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801005d8:	8b 45 10             	mov    0x10(%ebp),%eax
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
801005db:	89 fa                	mov    %edi,%edx
801005dd:	eb 04                	jmp    801005e3 <strncpy+0x1b>
801005df:	89 f1                	mov    %esi,%ecx
801005e1:	89 da                	mov    %ebx,%edx
801005e3:	89 c3                	mov    %eax,%ebx
801005e5:	83 e8 01             	sub    $0x1,%eax
801005e8:	85 db                	test   %ebx,%ebx
801005ea:	7e 1b                	jle    80100607 <strncpy+0x3f>
801005ec:	8d 71 01             	lea    0x1(%ecx),%esi
801005ef:	8d 5a 01             	lea    0x1(%edx),%ebx
801005f2:	0f b6 09             	movzbl (%ecx),%ecx
801005f5:	88 0a                	mov    %cl,(%edx)
801005f7:	84 c9                	test   %cl,%cl
801005f9:	75 e4                	jne    801005df <strncpy+0x17>
801005fb:	89 da                	mov    %ebx,%edx
801005fd:	eb 08                	jmp    80100607 <strncpy+0x3f>
    ;
  while(n-- > 0)
    *s++ = 0;
801005ff:	c6 02 00             	movb   $0x0,(%edx)
  while(n-- > 0)
80100602:	89 c8                	mov    %ecx,%eax
    *s++ = 0;
80100604:	8d 52 01             	lea    0x1(%edx),%edx
  while(n-- > 0)
80100607:	8d 48 ff             	lea    -0x1(%eax),%ecx
8010060a:	85 c0                	test   %eax,%eax
8010060c:	7f f1                	jg     801005ff <strncpy+0x37>
  return os;
}
8010060e:	89 f8                	mov    %edi,%eax
80100610:	5b                   	pop    %ebx
80100611:	5e                   	pop    %esi
80100612:	5f                   	pop    %edi
80100613:	5d                   	pop    %ebp
80100614:	c3                   	ret    

80100615 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
80100615:	f3 0f 1e fb          	endbr32 
80100619:	55                   	push   %ebp
8010061a:	89 e5                	mov    %esp,%ebp
8010061c:	57                   	push   %edi
8010061d:	56                   	push   %esi
8010061e:	53                   	push   %ebx
8010061f:	8b 7d 08             	mov    0x8(%ebp),%edi
80100622:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100625:	8b 45 10             	mov    0x10(%ebp),%eax
  char *os;

  os = s;
  if(n <= 0)
80100628:	85 c0                	test   %eax,%eax
8010062a:	7e 23                	jle    8010064f <safestrcpy+0x3a>
8010062c:	89 fa                	mov    %edi,%edx
8010062e:	eb 04                	jmp    80100634 <safestrcpy+0x1f>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80100630:	89 f1                	mov    %esi,%ecx
80100632:	89 da                	mov    %ebx,%edx
80100634:	83 e8 01             	sub    $0x1,%eax
80100637:	85 c0                	test   %eax,%eax
80100639:	7e 11                	jle    8010064c <safestrcpy+0x37>
8010063b:	8d 71 01             	lea    0x1(%ecx),%esi
8010063e:	8d 5a 01             	lea    0x1(%edx),%ebx
80100641:	0f b6 09             	movzbl (%ecx),%ecx
80100644:	88 0a                	mov    %cl,(%edx)
80100646:	84 c9                	test   %cl,%cl
80100648:	75 e6                	jne    80100630 <safestrcpy+0x1b>
8010064a:	89 da                	mov    %ebx,%edx
    ;
  *s = 0;
8010064c:	c6 02 00             	movb   $0x0,(%edx)
  return os;
}
8010064f:	89 f8                	mov    %edi,%eax
80100651:	5b                   	pop    %ebx
80100652:	5e                   	pop    %esi
80100653:	5f                   	pop    %edi
80100654:	5d                   	pop    %ebp
80100655:	c3                   	ret    

80100656 <strlen>:

int
strlen(const char *s)
{
80100656:	f3 0f 1e fb          	endbr32 
8010065a:	55                   	push   %ebp
8010065b:	89 e5                	mov    %esp,%ebp
8010065d:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80100660:	b8 00 00 00 00       	mov    $0x0,%eax
80100665:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80100669:	74 05                	je     80100670 <strlen+0x1a>
8010066b:	83 c0 01             	add    $0x1,%eax
8010066e:	eb f5                	jmp    80100665 <strlen+0xf>
    ;
  return n;
}
80100670:	5d                   	pop    %ebp
80100671:	c3                   	ret    

80100672 <panic>:
void panic(char * a) {
80100672:	f3 0f 1e fb          	endbr32 
  while(1);
80100676:	eb fe                	jmp    80100676 <panic+0x4>
80100678:	66 90                	xchg   %ax,%ax
8010067a:	66 90                	xchg   %ax,%ax
8010067c:	66 90                	xchg   %ax,%ax
8010067e:	66 90                	xchg   %ax,%ax

80100680 <multiboot_header>:
80100680:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
80100686:	00 00                	add    %al,(%eax)
80100688:	fb                   	sti    
80100689:	4f                   	dec    %edi
8010068a:	52                   	push   %edx
8010068b:	e4                   	.byte 0xe4

8010068c <entry>:

# the kernel begins here. Do not return in this file!
.global entry
entry:
  /* from grub multiboot */
  movl $(V2P_WO(stack+KSTACKSIZE)), %esp
8010068c:	bc a0 30 10 00       	mov    $0x1030a0,%esp
  pushl $0
80100691:	6a 00                	push   $0x0
  popf 
80100693:	9d                   	popf   
  /* Push the pointer to the Multiboot information structure. */
  pushl   %ebx
80100694:	53                   	push   %ebx
  /* Push the magic value. */
  pushl   %eax
80100695:	50                   	push   %eax
  push $2
80100696:	6a 02                	push   $0x2


  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
80100698:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010069b:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
8010069e:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
801006a1:	b8 00 10 10 00       	mov    $0x101000,%eax
  movl    %eax, %cr3
801006a6:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
801006a9:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
801006ac:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
801006b1:	0f 22 c0             	mov    %eax,%cr0

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $cmain, %eax
801006b4:	b8 00 00 10 80       	mov    $0x80100000,%eax
  jmp *%eax
801006b9:	ff e0                	jmp    *%eax

801006bb <spin>:

spin:
  nop
801006bb:	90                   	nop
  jmp spin
801006bc:	eb fd                	jmp    801006bb <spin>
801006be:	66 90                	xchg   %ax,%ax

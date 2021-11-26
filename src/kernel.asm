
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
8010005d:	e8 de 03 00 00       	call   80100440 <kvmalloc>
  kinit_all();
80100062:	e8 87 02 00 00       	call   801002ee <kinit_all>
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
801001c1:	68 a4 0a 10 80       	push   $0x80100aa4
801001c6:	e8 d0 04 00 00       	call   8010069b <panic>
801001cb:	83 c4 10             	add    $0x10,%esp

  memset(ptr, 1, PGSIZE);
801001ce:	83 ec 04             	sub    $0x4,%esp
801001d1:	68 00 10 00 00       	push   $0x1000
801001d6:	6a 01                	push   $0x1
801001d8:	53                   	push   %ebx
801001d9:	e8 e0 02 00 00       	call   801004be <memset>
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
  kmem.head = 0;
8010029e:	c7 05 8c 20 10 80 00 	movl   $0x0,0x8010208c
801002a5:	00 00 00 
  kmem.pgnum = 0;
801002a8:	c7 05 90 20 10 80 00 	movl   $0x0,0x80102090
801002af:	00 00 00 
  kmem.use_lock = 0;
801002b2:	c7 05 94 20 10 80 00 	movl   $0x0,0x80102094
801002b9:	00 00 00 

  char *p = end;
801002bc:	b8 a0 30 10 80       	mov    $0x801030a0,%eax
  char *end_of_4MB = P2V(4*1024*1024);

  for(; p + PGSIZE <= end_of_4MB; p += PGSIZE) {
801002c1:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
801002c7:	81 fa 00 00 40 80    	cmp    $0x80400000,%edx
801002cd:	77 1e                	ja     801002ed <kinit+0x53>
    struct run *tmp = (struct run*)p;
    tmp->next = kmem.head;
801002cf:	8b 0d 8c 20 10 80    	mov    0x8010208c,%ecx
801002d5:	89 08                	mov    %ecx,(%eax)
    kmem.head = tmp;
801002d7:	a3 8c 20 10 80       	mov    %eax,0x8010208c
    kmem.pgnum++;
801002dc:	a1 90 20 10 80       	mov    0x80102090,%eax
801002e1:	83 c0 01             	add    $0x1,%eax
801002e4:	a3 90 20 10 80       	mov    %eax,0x80102090
  for(; p + PGSIZE <= end_of_4MB; p += PGSIZE) {
801002e9:	89 d0                	mov    %edx,%eax
801002eb:	eb d4                	jmp    801002c1 <kinit+0x27>
  }
}
801002ed:	c3                   	ret    

801002ee <kinit_all>:

// similar to kinit(), but map all the memory
void kinit_all() {
801002ee:	f3 0f 1e fb          	endbr32 
  kmem.head = 0;
801002f2:	c7 05 8c 20 10 80 00 	movl   $0x0,0x8010208c
801002f9:	00 00 00 
  kmem.pgnum = 0;
801002fc:	c7 05 90 20 10 80 00 	movl   $0x0,0x80102090
80100303:	00 00 00 

  char *p = P2V(4*1024*1024);
80100306:	b8 00 00 40 80       	mov    $0x80400000,%eax
  char *end = P2V(PHYSTOP);

  for(; p + PGSIZE <= end; p += PGSIZE) {
8010030b:	8d 90 00 10 00 00    	lea    0x1000(%eax),%edx
80100311:	81 fa 00 00 00 8e    	cmp    $0x8e000000,%edx
80100317:	77 1e                	ja     80100337 <kinit_all+0x49>
    struct run *tmp = (struct run*)p;
    tmp->next = kmem.head;
80100319:	8b 0d 8c 20 10 80    	mov    0x8010208c,%ecx
8010031f:	89 08                	mov    %ecx,(%eax)
    kmem.head = tmp;
80100321:	a3 8c 20 10 80       	mov    %eax,0x8010208c
    kmem.pgnum++;
80100326:	a1 90 20 10 80       	mov    0x80102090,%eax
8010032b:	83 c0 01             	add    $0x1,%eax
8010032e:	a3 90 20 10 80       	mov    %eax,0x80102090
  for(; p + PGSIZE <= end; p += PGSIZE) {
80100333:	89 d0                	mov    %edx,%eax
80100335:	eb d4                	jmp    8010030b <kinit_all+0x1d>
  }
}
80100337:	c3                   	ret    

80100338 <switchkvm>:
// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
static void
switchkvm(void)
{
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80100338:	a1 98 20 10 80       	mov    0x80102098,%eax
8010033d:	05 00 00 00 80       	add    $0x80000000,%eax
}

static inline void
lcr3(uint val)
{
  asm volatile("movl %0,%%cr3" : : "r" (val));
80100342:	0f 22 d8             	mov    %eax,%cr3
}
80100345:	c3                   	ret    

80100346 <walkpgdir>:

// go through the page directories using virtual address, page allocation is optional
pte_t *walkpgdir(pde_t *pgdir, const void* va, int alloc) {
80100346:	f3 0f 1e fb          	endbr32 
8010034a:	55                   	push   %ebp
8010034b:	89 e5                	mov    %esp,%ebp
8010034d:	57                   	push   %edi
8010034e:	56                   	push   %esi
8010034f:	53                   	push   %ebx
80100350:	83 ec 0c             	sub    $0xc,%esp
80100353:	8b 7d 0c             	mov    0xc(%ebp),%edi
  pde_t *pde = &pgdir[PDX(va)];
80100356:	89 fe                	mov    %edi,%esi
80100358:	c1 ee 16             	shr    $0x16,%esi
8010035b:	c1 e6 02             	shl    $0x2,%esi
8010035e:	03 75 08             	add    0x8(%ebp),%esi
  pte_t *pgtbl;
  if(*pde & PTE_P) {
80100361:	8b 1e                	mov    (%esi),%ebx
80100363:	f6 c3 01             	test   $0x1,%bl
80100366:	74 20                	je     80100388 <walkpgdir+0x42>
    pgtbl = (pte_t*)P2V(PTE_ADDR(*pde)); // noticed that the address in the pgdir is physical address
80100368:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
8010036e:	81 c3 00 00 00 80    	add    $0x80000000,%ebx
    if(!alloc || (pgtbl = (pte_t*)kalloc()) == 0) return 0;
    // Make sure all those PTE_P bits are zero.
    memset(pgtbl, 0, PGSIZE);
    *pde = V2P(pgtbl) | PTE_P | PTE_W | PTE_U; // since we did page alignment in kfree, the address of pgtbl is alredy 4KB aligned (which means the 12 lower bits are 0).
  }
  return &pgtbl[PTX(va)];
80100374:	c1 ef 0c             	shr    $0xc,%edi
80100377:	81 e7 ff 03 00 00    	and    $0x3ff,%edi
8010037d:	8d 04 bb             	lea    (%ebx,%edi,4),%eax
}
80100380:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100383:	5b                   	pop    %ebx
80100384:	5e                   	pop    %esi
80100385:	5f                   	pop    %edi
80100386:	5d                   	pop    %ebp
80100387:	c3                   	ret    
    if(!alloc || (pgtbl = (pte_t*)kalloc()) == 0) return 0;
80100388:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010038c:	74 2b                	je     801003b9 <walkpgdir+0x73>
8010038e:	e8 8d fe ff ff       	call   80100220 <kalloc>
80100393:	89 c3                	mov    %eax,%ebx
80100395:	85 c0                	test   %eax,%eax
80100397:	74 20                	je     801003b9 <walkpgdir+0x73>
    memset(pgtbl, 0, PGSIZE);
80100399:	83 ec 04             	sub    $0x4,%esp
8010039c:	68 00 10 00 00       	push   $0x1000
801003a1:	6a 00                	push   $0x0
801003a3:	50                   	push   %eax
801003a4:	e8 15 01 00 00       	call   801004be <memset>
    *pde = V2P(pgtbl) | PTE_P | PTE_W | PTE_U; // since we did page alignment in kfree, the address of pgtbl is alredy 4KB aligned (which means the 12 lower bits are 0).
801003a9:	8d 83 00 00 00 80    	lea    -0x80000000(%ebx),%eax
801003af:	83 c8 07             	or     $0x7,%eax
801003b2:	89 06                	mov    %eax,(%esi)
801003b4:	83 c4 10             	add    $0x10,%esp
801003b7:	eb bb                	jmp    80100374 <walkpgdir+0x2e>
    if(!alloc || (pgtbl = (pte_t*)kalloc()) == 0) return 0;
801003b9:	b8 00 00 00 00       	mov    $0x0,%eax
801003be:	eb c0                	jmp    80100380 <walkpgdir+0x3a>

801003c0 <mappages>:

int mappages(pde_t* pgdir, void* va, uint sz, uint pa, int perm) {
801003c0:	f3 0f 1e fb          	endbr32 
801003c4:	55                   	push   %ebp
801003c5:	89 e5                	mov    %esp,%ebp
801003c7:	57                   	push   %edi
801003c8:	56                   	push   %esi
801003c9:	53                   	push   %ebx
801003ca:	83 ec 1c             	sub    $0x1c,%esp
801003cd:	8b 7d 14             	mov    0x14(%ebp),%edi
  char *p = (char*)PGROUNDDOWN((uint)va);                 // mapping is by pages
801003d0:	8b 45 0c             	mov    0xc(%ebp),%eax
801003d3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801003d8:	89 c6                	mov    %eax,%esi
  char *end = (char*)PGROUNDDOWN((uint)p+sz-1);           
801003da:	03 45 10             	add    0x10(%ebp),%eax
801003dd:	83 e8 01             	sub    $0x1,%eax
801003e0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801003e5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  for(; p <= end; pa += PGSIZE, p += PGSIZE) {
801003e8:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
801003eb:	77 3f                	ja     8010042c <mappages+0x6c>
    pte_t *pte = walkpgdir(pgdir, p, 1);                  // find the corresponding pagetable or create a new one
801003ed:	83 ec 04             	sub    $0x4,%esp
801003f0:	6a 01                	push   $0x1
801003f2:	56                   	push   %esi
801003f3:	ff 75 08             	pushl  0x8(%ebp)
801003f6:	e8 4b ff ff ff       	call   80100346 <walkpgdir>
801003fb:	89 c3                	mov    %eax,%ebx
    if(pte == 0) return -1;
801003fd:	83 c4 10             	add    $0x10,%esp
80100400:	85 c0                	test   %eax,%eax
80100402:	74 35                	je     80100439 <mappages+0x79>
    if((*pte) | PTE_P) panic("mappages");
80100404:	83 ec 0c             	sub    $0xc,%esp
80100407:	68 aa 0a 10 80       	push   $0x80100aaa
8010040c:	e8 8a 02 00 00       	call   8010069b <panic>
    *pte = pa | PTE_P | perm;
80100411:	89 f8                	mov    %edi,%eax
80100413:	0b 45 18             	or     0x18(%ebp),%eax
80100416:	83 c8 01             	or     $0x1,%eax
80100419:	89 03                	mov    %eax,(%ebx)
  for(; p <= end; pa += PGSIZE, p += PGSIZE) {
8010041b:	81 c7 00 10 00 00    	add    $0x1000,%edi
80100421:	81 c6 00 10 00 00    	add    $0x1000,%esi
80100427:	83 c4 10             	add    $0x10,%esp
8010042a:	eb bc                	jmp    801003e8 <mappages+0x28>
  }
  return 0;
8010042c:	b8 00 00 00 00       	mov    $0x0,%eax
}
80100431:	8d 65 f4             	lea    -0xc(%ebp),%esp
80100434:	5b                   	pop    %ebx
80100435:	5e                   	pop    %esi
80100436:	5f                   	pop    %edi
80100437:	5d                   	pop    %ebp
80100438:	c3                   	ret    
    if(pte == 0) return -1;
80100439:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010043e:	eb f1                	jmp    80100431 <mappages+0x71>

80100440 <kvmalloc>:



void kvmalloc() {
80100440:	f3 0f 1e fb          	endbr32 
80100444:	55                   	push   %ebp
80100445:	89 e5                	mov    %esp,%ebp
80100447:	53                   	push   %ebx
80100448:	83 ec 04             	sub    $0x4,%esp
  kpgdir = (pde_t*)kalloc();
8010044b:	e8 d0 fd ff ff       	call   80100220 <kalloc>
80100450:	a3 98 20 10 80       	mov    %eax,0x80102098
  if(!kpgdir) return;
80100455:	85 c0                	test   %eax,%eax
80100457:	74 60                	je     801004b9 <kvmalloc+0x79>
  // make sure all those PDE_P/PTE_P bits are clear
  memset(kpgdir, 0, PGSIZE);
80100459:	83 ec 04             	sub    $0x4,%esp
8010045c:	68 00 10 00 00       	push   $0x1000
80100461:	6a 00                	push   $0x0
80100463:	50                   	push   %eax
80100464:	e8 55 00 00 00       	call   801004be <memset>
  struct kmap_t *k;
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++) {
80100469:	83 c4 10             	add    $0x10,%esp
8010046c:	bb 40 20 10 80       	mov    $0x80102040,%ebx
80100471:	eb 03                	jmp    80100476 <kvmalloc+0x36>
80100473:	83 c3 10             	add    $0x10,%ebx
80100476:	81 fb 80 20 10 80    	cmp    $0x80102080,%ebx
8010047c:	73 36                	jae    801004b4 <kvmalloc+0x74>
    if(mappages(kpgdir, k->virt, k->phys_end - k->phys_start,
                (uint)k->phys_start, k->perm) < 0) {
8010047e:	8b 43 04             	mov    0x4(%ebx),%eax
    if(mappages(kpgdir, k->virt, k->phys_end - k->phys_start,
80100481:	83 ec 0c             	sub    $0xc,%esp
80100484:	ff 73 0c             	pushl  0xc(%ebx)
80100487:	50                   	push   %eax
80100488:	8b 53 08             	mov    0x8(%ebx),%edx
8010048b:	29 c2                	sub    %eax,%edx
8010048d:	52                   	push   %edx
8010048e:	ff 33                	pushl  (%ebx)
80100490:	ff 35 98 20 10 80    	pushl  0x80102098
80100496:	e8 25 ff ff ff       	call   801003c0 <mappages>
8010049b:	83 c4 20             	add    $0x20,%esp
8010049e:	85 c0                	test   %eax,%eax
801004a0:	79 d1                	jns    80100473 <kvmalloc+0x33>
      panic("kvmalloc");
801004a2:	83 ec 0c             	sub    $0xc,%esp
801004a5:	68 b3 0a 10 80       	push   $0x80100ab3
801004aa:	e8 ec 01 00 00       	call   8010069b <panic>
801004af:	83 c4 10             	add    $0x10,%esp
801004b2:	eb bf                	jmp    80100473 <kvmalloc+0x33>
    }
  }
  switchkvm();
801004b4:	e8 7f fe ff ff       	call   80100338 <switchkvm>
}
801004b9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801004bc:	c9                   	leave  
801004bd:	c3                   	ret    

801004be <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
801004be:	f3 0f 1e fb          	endbr32 
801004c2:	55                   	push   %ebp
801004c3:	89 e5                	mov    %esp,%ebp
801004c5:	57                   	push   %edi
801004c6:	53                   	push   %ebx
801004c7:	8b 55 08             	mov    0x8(%ebp),%edx
801004ca:	8b 45 0c             	mov    0xc(%ebp),%eax
801004cd:	8b 4d 10             	mov    0x10(%ebp),%ecx
  if ((int)dst%4 == 0 && n%4 == 0){
801004d0:	f6 c2 03             	test   $0x3,%dl
801004d3:	75 25                	jne    801004fa <memset+0x3c>
801004d5:	f6 c1 03             	test   $0x3,%cl
801004d8:	75 20                	jne    801004fa <memset+0x3c>
    c &= 0xFF;
801004da:	0f b6 f8             	movzbl %al,%edi
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801004dd:	c1 e9 02             	shr    $0x2,%ecx
801004e0:	c1 e0 18             	shl    $0x18,%eax
801004e3:	89 fb                	mov    %edi,%ebx
801004e5:	c1 e3 10             	shl    $0x10,%ebx
801004e8:	09 d8                	or     %ebx,%eax
801004ea:	89 fb                	mov    %edi,%ebx
801004ec:	c1 e3 08             	shl    $0x8,%ebx
801004ef:	09 d8                	or     %ebx,%eax
801004f1:	09 f8                	or     %edi,%eax
  asm volatile("cld; rep stosl" :
801004f3:	89 d7                	mov    %edx,%edi
801004f5:	fc                   	cld    
801004f6:	f3 ab                	rep stos %eax,%es:(%edi)
}
801004f8:	eb 05                	jmp    801004ff <memset+0x41>
  asm volatile("cld; rep stosb" :
801004fa:	89 d7                	mov    %edx,%edi
801004fc:	fc                   	cld    
801004fd:	f3 aa                	rep stos %al,%es:(%edi)
  } else
    stosb(dst, c, n);
  return dst;
}
801004ff:	89 d0                	mov    %edx,%eax
80100501:	5b                   	pop    %ebx
80100502:	5f                   	pop    %edi
80100503:	5d                   	pop    %ebp
80100504:	c3                   	ret    

80100505 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80100505:	f3 0f 1e fb          	endbr32 
80100509:	55                   	push   %ebp
8010050a:	89 e5                	mov    %esp,%ebp
8010050c:	56                   	push   %esi
8010050d:	53                   	push   %ebx
8010050e:	8b 4d 08             	mov    0x8(%ebp),%ecx
80100511:	8b 55 0c             	mov    0xc(%ebp),%edx
80100514:	8b 45 10             	mov    0x10(%ebp),%eax
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80100517:	8d 70 ff             	lea    -0x1(%eax),%esi
8010051a:	85 c0                	test   %eax,%eax
8010051c:	74 1c                	je     8010053a <memcmp+0x35>
    if(*s1 != *s2)
8010051e:	0f b6 01             	movzbl (%ecx),%eax
80100521:	0f b6 1a             	movzbl (%edx),%ebx
80100524:	38 d8                	cmp    %bl,%al
80100526:	75 0a                	jne    80100532 <memcmp+0x2d>
      return *s1 - *s2;
    s1++, s2++;
80100528:	83 c1 01             	add    $0x1,%ecx
8010052b:	83 c2 01             	add    $0x1,%edx
  while(n-- > 0){
8010052e:	89 f0                	mov    %esi,%eax
80100530:	eb e5                	jmp    80100517 <memcmp+0x12>
      return *s1 - *s2;
80100532:	0f b6 c0             	movzbl %al,%eax
80100535:	0f b6 db             	movzbl %bl,%ebx
80100538:	29 d8                	sub    %ebx,%eax
  }

  return 0;
}
8010053a:	5b                   	pop    %ebx
8010053b:	5e                   	pop    %esi
8010053c:	5d                   	pop    %ebp
8010053d:	c3                   	ret    

8010053e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
8010053e:	f3 0f 1e fb          	endbr32 
80100542:	55                   	push   %ebp
80100543:	89 e5                	mov    %esp,%ebp
80100545:	56                   	push   %esi
80100546:	53                   	push   %ebx
80100547:	8b 75 08             	mov    0x8(%ebp),%esi
8010054a:	8b 55 0c             	mov    0xc(%ebp),%edx
8010054d:	8b 45 10             	mov    0x10(%ebp),%eax
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
80100550:	39 f2                	cmp    %esi,%edx
80100552:	73 3a                	jae    8010058e <memmove+0x50>
80100554:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
80100557:	39 f1                	cmp    %esi,%ecx
80100559:	76 37                	jbe    80100592 <memmove+0x54>
    s += n;
    d += n;
8010055b:	8d 14 06             	lea    (%esi,%eax,1),%edx
    while(n-- > 0)
8010055e:	8d 58 ff             	lea    -0x1(%eax),%ebx
80100561:	85 c0                	test   %eax,%eax
80100563:	74 23                	je     80100588 <memmove+0x4a>
      *--d = *--s;
80100565:	83 e9 01             	sub    $0x1,%ecx
80100568:	83 ea 01             	sub    $0x1,%edx
8010056b:	0f b6 01             	movzbl (%ecx),%eax
8010056e:	88 02                	mov    %al,(%edx)
    while(n-- > 0)
80100570:	89 d8                	mov    %ebx,%eax
80100572:	eb ea                	jmp    8010055e <memmove+0x20>
  } else
    while(n-- > 0)
      *d++ = *s++;
80100574:	0f b6 02             	movzbl (%edx),%eax
80100577:	88 01                	mov    %al,(%ecx)
80100579:	8d 49 01             	lea    0x1(%ecx),%ecx
8010057c:	8d 52 01             	lea    0x1(%edx),%edx
    while(n-- > 0)
8010057f:	89 d8                	mov    %ebx,%eax
80100581:	8d 58 ff             	lea    -0x1(%eax),%ebx
80100584:	85 c0                	test   %eax,%eax
80100586:	75 ec                	jne    80100574 <memmove+0x36>

  return dst;
}
80100588:	89 f0                	mov    %esi,%eax
8010058a:	5b                   	pop    %ebx
8010058b:	5e                   	pop    %esi
8010058c:	5d                   	pop    %ebp
8010058d:	c3                   	ret    
8010058e:	89 f1                	mov    %esi,%ecx
80100590:	eb ef                	jmp    80100581 <memmove+0x43>
80100592:	89 f1                	mov    %esi,%ecx
80100594:	eb eb                	jmp    80100581 <memmove+0x43>

80100596 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
80100596:	f3 0f 1e fb          	endbr32 
8010059a:	55                   	push   %ebp
8010059b:	89 e5                	mov    %esp,%ebp
8010059d:	83 ec 0c             	sub    $0xc,%esp
  return memmove(dst, src, n);
801005a0:	ff 75 10             	pushl  0x10(%ebp)
801005a3:	ff 75 0c             	pushl  0xc(%ebp)
801005a6:	ff 75 08             	pushl  0x8(%ebp)
801005a9:	e8 90 ff ff ff       	call   8010053e <memmove>
}
801005ae:	c9                   	leave  
801005af:	c3                   	ret    

801005b0 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
801005b0:	f3 0f 1e fb          	endbr32 
801005b4:	55                   	push   %ebp
801005b5:	89 e5                	mov    %esp,%ebp
801005b7:	53                   	push   %ebx
801005b8:	8b 55 08             	mov    0x8(%ebp),%edx
801005bb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801005be:	8b 45 10             	mov    0x10(%ebp),%eax
  while(n > 0 && *p && *p == *q)
801005c1:	eb 09                	jmp    801005cc <strncmp+0x1c>
    n--, p++, q++;
801005c3:	83 e8 01             	sub    $0x1,%eax
801005c6:	83 c2 01             	add    $0x1,%edx
801005c9:	83 c1 01             	add    $0x1,%ecx
  while(n > 0 && *p && *p == *q)
801005cc:	85 c0                	test   %eax,%eax
801005ce:	74 0b                	je     801005db <strncmp+0x2b>
801005d0:	0f b6 1a             	movzbl (%edx),%ebx
801005d3:	84 db                	test   %bl,%bl
801005d5:	74 04                	je     801005db <strncmp+0x2b>
801005d7:	3a 19                	cmp    (%ecx),%bl
801005d9:	74 e8                	je     801005c3 <strncmp+0x13>
  if(n == 0)
801005db:	85 c0                	test   %eax,%eax
801005dd:	74 0b                	je     801005ea <strncmp+0x3a>
    return 0;
  return (uchar)*p - (uchar)*q;
801005df:	0f b6 02             	movzbl (%edx),%eax
801005e2:	0f b6 11             	movzbl (%ecx),%edx
801005e5:	29 d0                	sub    %edx,%eax
}
801005e7:	5b                   	pop    %ebx
801005e8:	5d                   	pop    %ebp
801005e9:	c3                   	ret    
    return 0;
801005ea:	b8 00 00 00 00       	mov    $0x0,%eax
801005ef:	eb f6                	jmp    801005e7 <strncmp+0x37>

801005f1 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
801005f1:	f3 0f 1e fb          	endbr32 
801005f5:	55                   	push   %ebp
801005f6:	89 e5                	mov    %esp,%ebp
801005f8:	57                   	push   %edi
801005f9:	56                   	push   %esi
801005fa:	53                   	push   %ebx
801005fb:	8b 7d 08             	mov    0x8(%ebp),%edi
801005fe:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80100601:	8b 45 10             	mov    0x10(%ebp),%eax
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
80100604:	89 fa                	mov    %edi,%edx
80100606:	eb 04                	jmp    8010060c <strncpy+0x1b>
80100608:	89 f1                	mov    %esi,%ecx
8010060a:	89 da                	mov    %ebx,%edx
8010060c:	89 c3                	mov    %eax,%ebx
8010060e:	83 e8 01             	sub    $0x1,%eax
80100611:	85 db                	test   %ebx,%ebx
80100613:	7e 1b                	jle    80100630 <strncpy+0x3f>
80100615:	8d 71 01             	lea    0x1(%ecx),%esi
80100618:	8d 5a 01             	lea    0x1(%edx),%ebx
8010061b:	0f b6 09             	movzbl (%ecx),%ecx
8010061e:	88 0a                	mov    %cl,(%edx)
80100620:	84 c9                	test   %cl,%cl
80100622:	75 e4                	jne    80100608 <strncpy+0x17>
80100624:	89 da                	mov    %ebx,%edx
80100626:	eb 08                	jmp    80100630 <strncpy+0x3f>
    ;
  while(n-- > 0)
    *s++ = 0;
80100628:	c6 02 00             	movb   $0x0,(%edx)
  while(n-- > 0)
8010062b:	89 c8                	mov    %ecx,%eax
    *s++ = 0;
8010062d:	8d 52 01             	lea    0x1(%edx),%edx
  while(n-- > 0)
80100630:	8d 48 ff             	lea    -0x1(%eax),%ecx
80100633:	85 c0                	test   %eax,%eax
80100635:	7f f1                	jg     80100628 <strncpy+0x37>
  return os;
}
80100637:	89 f8                	mov    %edi,%eax
80100639:	5b                   	pop    %ebx
8010063a:	5e                   	pop    %esi
8010063b:	5f                   	pop    %edi
8010063c:	5d                   	pop    %ebp
8010063d:	c3                   	ret    

8010063e <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
8010063e:	f3 0f 1e fb          	endbr32 
80100642:	55                   	push   %ebp
80100643:	89 e5                	mov    %esp,%ebp
80100645:	57                   	push   %edi
80100646:	56                   	push   %esi
80100647:	53                   	push   %ebx
80100648:	8b 7d 08             	mov    0x8(%ebp),%edi
8010064b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
8010064e:	8b 45 10             	mov    0x10(%ebp),%eax
  char *os;

  os = s;
  if(n <= 0)
80100651:	85 c0                	test   %eax,%eax
80100653:	7e 23                	jle    80100678 <safestrcpy+0x3a>
80100655:	89 fa                	mov    %edi,%edx
80100657:	eb 04                	jmp    8010065d <safestrcpy+0x1f>
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
80100659:	89 f1                	mov    %esi,%ecx
8010065b:	89 da                	mov    %ebx,%edx
8010065d:	83 e8 01             	sub    $0x1,%eax
80100660:	85 c0                	test   %eax,%eax
80100662:	7e 11                	jle    80100675 <safestrcpy+0x37>
80100664:	8d 71 01             	lea    0x1(%ecx),%esi
80100667:	8d 5a 01             	lea    0x1(%edx),%ebx
8010066a:	0f b6 09             	movzbl (%ecx),%ecx
8010066d:	88 0a                	mov    %cl,(%edx)
8010066f:	84 c9                	test   %cl,%cl
80100671:	75 e6                	jne    80100659 <safestrcpy+0x1b>
80100673:	89 da                	mov    %ebx,%edx
    ;
  *s = 0;
80100675:	c6 02 00             	movb   $0x0,(%edx)
  return os;
}
80100678:	89 f8                	mov    %edi,%eax
8010067a:	5b                   	pop    %ebx
8010067b:	5e                   	pop    %esi
8010067c:	5f                   	pop    %edi
8010067d:	5d                   	pop    %ebp
8010067e:	c3                   	ret    

8010067f <strlen>:

int
strlen(const char *s)
{
8010067f:	f3 0f 1e fb          	endbr32 
80100683:	55                   	push   %ebp
80100684:	89 e5                	mov    %esp,%ebp
80100686:	8b 55 08             	mov    0x8(%ebp),%edx
  int n;

  for(n = 0; s[n]; n++)
80100689:	b8 00 00 00 00       	mov    $0x0,%eax
8010068e:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
80100692:	74 05                	je     80100699 <strlen+0x1a>
80100694:	83 c0 01             	add    $0x1,%eax
80100697:	eb f5                	jmp    8010068e <strlen+0xf>
    ;
  return n;
}
80100699:	5d                   	pop    %ebp
8010069a:	c3                   	ret    

8010069b <panic>:
void panic(char * a) {
8010069b:	f3 0f 1e fb          	endbr32 
  while(1);
8010069f:	eb fe                	jmp    8010069f <panic+0x4>
801006a1:	66 90                	xchg   %ax,%ax
801006a3:	66 90                	xchg   %ax,%ax
801006a5:	66 90                	xchg   %ax,%ax
801006a7:	66 90                	xchg   %ax,%ax
801006a9:	66 90                	xchg   %ax,%ax
801006ab:	66 90                	xchg   %ax,%ax
801006ad:	66 90                	xchg   %ax,%ax
801006af:	90                   	nop

801006b0 <multiboot_header>:
801006b0:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
801006b6:	00 00                	add    %al,(%eax)
801006b8:	fb                   	sti    
801006b9:	4f                   	dec    %edi
801006ba:	52                   	push   %edx
801006bb:	e4                   	.byte 0xe4

801006bc <entry>:

# the kernel begins here. Do not return in this file!
.global entry
entry:
  /* from grub multiboot */
  movl $(V2P_WO(stack+KSTACKSIZE)), %esp
801006bc:	bc a0 30 10 00       	mov    $0x1030a0,%esp
  pushl $0
801006c1:	6a 00                	push   $0x0
  popf 
801006c3:	9d                   	popf   
  /* Push the magic value. */
  pushl   %eax
801006c4:	50                   	push   %eax
  /* Push the pointer to the Multiboot information structure. */
  pushl   %ebx
801006c5:	53                   	push   %ebx

  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
801006c6:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
801006c9:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
801006cc:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
801006cf:	b8 00 10 10 00       	mov    $0x101000,%eax
  movl    %eax, %cr3
801006d4:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
801006d7:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
801006da:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
801006df:	0f 22 c0             	mov    %eax,%cr0

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $cmain, %eax
801006e2:	b8 00 00 10 80       	mov    $0x80100000,%eax
  jmp *%eax
801006e7:	ff e0                	jmp    *%eax

801006e9 <spin>:

spin:
  nop
801006e9:	90                   	nop
  jmp spin
801006ea:	eb fd                	jmp    801006e9 <spin>
801006ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi

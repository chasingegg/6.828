
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 20 11 f0       	mov    $0xf0112000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 0c             	sub    $0xc,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 50 49 11 f0       	mov    $0xf0114950,%eax
f010004b:	2d 00 43 11 f0       	sub    $0xf0114300,%eax
f0100050:	50                   	push   %eax
f0100051:	6a 00                	push   $0x0
f0100053:	68 00 43 11 f0       	push   $0xf0114300
f0100058:	e8 a1 1f 00 00       	call   f0101ffe <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010005d:	e8 96 04 00 00       	call   f01004f8 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100062:	83 c4 08             	add    $0x8,%esp
f0100065:	68 ac 1a 00 00       	push   $0x1aac
f010006a:	68 a0 24 10 f0       	push   $0xf01024a0
f010006f:	e8 c8 14 00 00       	call   f010153c <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100074:	e8 f0 0d 00 00       	call   f0100e69 <mem_init>
f0100079:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f010007c:	83 ec 0c             	sub    $0xc,%esp
f010007f:	6a 00                	push   $0x0
f0100081:	e8 36 07 00 00       	call   f01007bc <monitor>
f0100086:	83 c4 10             	add    $0x10,%esp
f0100089:	eb f1                	jmp    f010007c <i386_init+0x3c>

f010008b <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f010008b:	55                   	push   %ebp
f010008c:	89 e5                	mov    %esp,%ebp
f010008e:	56                   	push   %esi
f010008f:	53                   	push   %ebx
f0100090:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100093:	83 3d 40 49 11 f0 00 	cmpl   $0x0,0xf0114940
f010009a:	75 37                	jne    f01000d3 <_panic+0x48>
		goto dead;
	panicstr = fmt;
f010009c:	89 35 40 49 11 f0    	mov    %esi,0xf0114940

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000a2:	fa                   	cli    
f01000a3:	fc                   	cld    

	va_start(ap, fmt);
f01000a4:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000a7:	83 ec 04             	sub    $0x4,%esp
f01000aa:	ff 75 0c             	pushl  0xc(%ebp)
f01000ad:	ff 75 08             	pushl  0x8(%ebp)
f01000b0:	68 bb 24 10 f0       	push   $0xf01024bb
f01000b5:	e8 82 14 00 00       	call   f010153c <cprintf>
	vcprintf(fmt, ap);
f01000ba:	83 c4 08             	add    $0x8,%esp
f01000bd:	53                   	push   %ebx
f01000be:	56                   	push   %esi
f01000bf:	e8 52 14 00 00       	call   f0101516 <vcprintf>
	cprintf("\n");
f01000c4:	c7 04 24 f7 24 10 f0 	movl   $0xf01024f7,(%esp)
f01000cb:	e8 6c 14 00 00       	call   f010153c <cprintf>
	va_end(ap);
f01000d0:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 df 06 00 00       	call   f01007bc <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x48>

f01000e2 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000e2:	55                   	push   %ebp
f01000e3:	89 e5                	mov    %esp,%ebp
f01000e5:	53                   	push   %ebx
f01000e6:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f01000e9:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	68 d3 24 10 f0       	push   $0xf01024d3
f01000f7:	e8 40 14 00 00       	call   f010153c <cprintf>
	vcprintf(fmt, ap);
f01000fc:	83 c4 08             	add    $0x8,%esp
f01000ff:	53                   	push   %ebx
f0100100:	ff 75 10             	pushl  0x10(%ebp)
f0100103:	e8 0e 14 00 00       	call   f0101516 <vcprintf>
	cprintf("\n");
f0100108:	c7 04 24 f7 24 10 f0 	movl   $0xf01024f7,(%esp)
f010010f:	e8 28 14 00 00       	call   f010153c <cprintf>
	va_end(ap);
}
f0100114:	83 c4 10             	add    $0x10,%esp
f0100117:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010011a:	c9                   	leave  
f010011b:	c3                   	ret    

f010011c <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010011c:	55                   	push   %ebp
f010011d:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010011f:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100124:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100125:	a8 01                	test   $0x1,%al
f0100127:	74 0b                	je     f0100134 <serial_proc_data+0x18>
f0100129:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010012e:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010012f:	0f b6 c0             	movzbl %al,%eax
f0100132:	eb 05                	jmp    f0100139 <serial_proc_data+0x1d>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100134:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100139:	5d                   	pop    %ebp
f010013a:	c3                   	ret    

f010013b <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010013b:	55                   	push   %ebp
f010013c:	89 e5                	mov    %esp,%ebp
f010013e:	53                   	push   %ebx
f010013f:	83 ec 04             	sub    $0x4,%esp
f0100142:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100144:	eb 2b                	jmp    f0100171 <cons_intr+0x36>
		if (c == 0)
f0100146:	85 c0                	test   %eax,%eax
f0100148:	74 27                	je     f0100171 <cons_intr+0x36>
			continue;
		cons.buf[cons.wpos++] = c;
f010014a:	8b 0d 24 45 11 f0    	mov    0xf0114524,%ecx
f0100150:	8d 51 01             	lea    0x1(%ecx),%edx
f0100153:	89 15 24 45 11 f0    	mov    %edx,0xf0114524
f0100159:	88 81 20 43 11 f0    	mov    %al,-0xfeebce0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f010015f:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100165:	75 0a                	jne    f0100171 <cons_intr+0x36>
			cons.wpos = 0;
f0100167:	c7 05 24 45 11 f0 00 	movl   $0x0,0xf0114524
f010016e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100171:	ff d3                	call   *%ebx
f0100173:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100176:	75 ce                	jne    f0100146 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100178:	83 c4 04             	add    $0x4,%esp
f010017b:	5b                   	pop    %ebx
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <kbd_proc_data>:
f010017e:	ba 64 00 00 00       	mov    $0x64,%edx
f0100183:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f0100184:	a8 01                	test   $0x1,%al
f0100186:	0f 84 f8 00 00 00    	je     f0100284 <kbd_proc_data+0x106>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f010018c:	a8 20                	test   $0x20,%al
f010018e:	0f 85 f6 00 00 00    	jne    f010028a <kbd_proc_data+0x10c>
f0100194:	ba 60 00 00 00       	mov    $0x60,%edx
f0100199:	ec                   	in     (%dx),%al
f010019a:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010019c:	3c e0                	cmp    $0xe0,%al
f010019e:	75 0d                	jne    f01001ad <kbd_proc_data+0x2f>
		// E0 escape character
		shift |= E0ESC;
f01001a0:	83 0d 00 43 11 f0 40 	orl    $0x40,0xf0114300
		return 0;
f01001a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01001ac:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001ad:	55                   	push   %ebp
f01001ae:	89 e5                	mov    %esp,%ebp
f01001b0:	53                   	push   %ebx
f01001b1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001b4:	84 c0                	test   %al,%al
f01001b6:	79 36                	jns    f01001ee <kbd_proc_data+0x70>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001b8:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001be:	89 cb                	mov    %ecx,%ebx
f01001c0:	83 e3 40             	and    $0x40,%ebx
f01001c3:	83 e0 7f             	and    $0x7f,%eax
f01001c6:	85 db                	test   %ebx,%ebx
f01001c8:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001cb:	0f b6 d2             	movzbl %dl,%edx
f01001ce:	0f b6 82 40 26 10 f0 	movzbl -0xfefd9c0(%edx),%eax
f01001d5:	83 c8 40             	or     $0x40,%eax
f01001d8:	0f b6 c0             	movzbl %al,%eax
f01001db:	f7 d0                	not    %eax
f01001dd:	21 c8                	and    %ecx,%eax
f01001df:	a3 00 43 11 f0       	mov    %eax,0xf0114300
		return 0;
f01001e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01001e9:	e9 a4 00 00 00       	jmp    f0100292 <kbd_proc_data+0x114>
	} else if (shift & E0ESC) {
f01001ee:	8b 0d 00 43 11 f0    	mov    0xf0114300,%ecx
f01001f4:	f6 c1 40             	test   $0x40,%cl
f01001f7:	74 0e                	je     f0100207 <kbd_proc_data+0x89>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01001f9:	83 c8 80             	or     $0xffffff80,%eax
f01001fc:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01001fe:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100201:	89 0d 00 43 11 f0    	mov    %ecx,0xf0114300
	}

	shift |= shiftcode[data];
f0100207:	0f b6 d2             	movzbl %dl,%edx
	shift ^= togglecode[data];
f010020a:	0f b6 82 40 26 10 f0 	movzbl -0xfefd9c0(%edx),%eax
f0100211:	0b 05 00 43 11 f0    	or     0xf0114300,%eax
f0100217:	0f b6 8a 40 25 10 f0 	movzbl -0xfefdac0(%edx),%ecx
f010021e:	31 c8                	xor    %ecx,%eax
f0100220:	a3 00 43 11 f0       	mov    %eax,0xf0114300

	c = charcode[shift & (CTL | SHIFT)][data];
f0100225:	89 c1                	mov    %eax,%ecx
f0100227:	83 e1 03             	and    $0x3,%ecx
f010022a:	8b 0c 8d 20 25 10 f0 	mov    -0xfefdae0(,%ecx,4),%ecx
f0100231:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100235:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100238:	a8 08                	test   $0x8,%al
f010023a:	74 1b                	je     f0100257 <kbd_proc_data+0xd9>
		if ('a' <= c && c <= 'z')
f010023c:	89 da                	mov    %ebx,%edx
f010023e:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100241:	83 f9 19             	cmp    $0x19,%ecx
f0100244:	77 05                	ja     f010024b <kbd_proc_data+0xcd>
			c += 'A' - 'a';
f0100246:	83 eb 20             	sub    $0x20,%ebx
f0100249:	eb 0c                	jmp    f0100257 <kbd_proc_data+0xd9>
		else if ('A' <= c && c <= 'Z')
f010024b:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010024e:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100251:	83 fa 19             	cmp    $0x19,%edx
f0100254:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100257:	f7 d0                	not    %eax
f0100259:	a8 06                	test   $0x6,%al
f010025b:	75 33                	jne    f0100290 <kbd_proc_data+0x112>
f010025d:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100263:	75 2b                	jne    f0100290 <kbd_proc_data+0x112>
		cprintf("Rebooting!\n");
f0100265:	83 ec 0c             	sub    $0xc,%esp
f0100268:	68 ed 24 10 f0       	push   $0xf01024ed
f010026d:	e8 ca 12 00 00       	call   f010153c <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100272:	ba 92 00 00 00       	mov    $0x92,%edx
f0100277:	b8 03 00 00 00       	mov    $0x3,%eax
f010027c:	ee                   	out    %al,(%dx)
f010027d:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100280:	89 d8                	mov    %ebx,%eax
f0100282:	eb 0e                	jmp    f0100292 <kbd_proc_data+0x114>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100284:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100289:	c3                   	ret    
	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010028a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010028f:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100290:	89 d8                	mov    %ebx,%eax
}
f0100292:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100295:	c9                   	leave  
f0100296:	c3                   	ret    

f0100297 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100297:	55                   	push   %ebp
f0100298:	89 e5                	mov    %esp,%ebp
f010029a:	57                   	push   %edi
f010029b:	56                   	push   %esi
f010029c:	53                   	push   %ebx
f010029d:	83 ec 1c             	sub    $0x1c,%esp
f01002a0:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002a2:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a7:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002ac:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002b1:	eb 09                	jmp    f01002bc <cons_putc+0x25>
f01002b3:	89 ca                	mov    %ecx,%edx
f01002b5:	ec                   	in     (%dx),%al
f01002b6:	ec                   	in     (%dx),%al
f01002b7:	ec                   	in     (%dx),%al
f01002b8:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01002b9:	83 c3 01             	add    $0x1,%ebx
f01002bc:	89 f2                	mov    %esi,%edx
f01002be:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002bf:	a8 20                	test   $0x20,%al
f01002c1:	75 08                	jne    f01002cb <cons_putc+0x34>
f01002c3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002c9:	7e e8                	jle    f01002b3 <cons_putc+0x1c>
f01002cb:	89 f8                	mov    %edi,%eax
f01002cd:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01002d5:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01002d6:	bb 00 00 00 00       	mov    $0x0,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002db:	be 79 03 00 00       	mov    $0x379,%esi
f01002e0:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e5:	eb 09                	jmp    f01002f0 <cons_putc+0x59>
f01002e7:	89 ca                	mov    %ecx,%edx
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	ec                   	in     (%dx),%al
f01002ec:	ec                   	in     (%dx),%al
f01002ed:	83 c3 01             	add    $0x1,%ebx
f01002f0:	89 f2                	mov    %esi,%edx
f01002f2:	ec                   	in     (%dx),%al
f01002f3:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f01002f9:	7f 04                	jg     f01002ff <cons_putc+0x68>
f01002fb:	84 c0                	test   %al,%al
f01002fd:	79 e8                	jns    f01002e7 <cons_putc+0x50>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba 78 03 00 00       	mov    $0x378,%edx
f0100304:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100308:	ee                   	out    %al,(%dx)
f0100309:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010030e:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100313:	ee                   	out    %al,(%dx)
f0100314:	b8 08 00 00 00       	mov    $0x8,%eax
f0100319:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010031a:	89 fa                	mov    %edi,%edx
f010031c:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100322:	89 f8                	mov    %edi,%eax
f0100324:	80 cc 07             	or     $0x7,%ah
f0100327:	85 d2                	test   %edx,%edx
f0100329:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f010032c:	89 f8                	mov    %edi,%eax
f010032e:	0f b6 c0             	movzbl %al,%eax
f0100331:	83 f8 09             	cmp    $0x9,%eax
f0100334:	74 74                	je     f01003aa <cons_putc+0x113>
f0100336:	83 f8 09             	cmp    $0x9,%eax
f0100339:	7f 0a                	jg     f0100345 <cons_putc+0xae>
f010033b:	83 f8 08             	cmp    $0x8,%eax
f010033e:	74 14                	je     f0100354 <cons_putc+0xbd>
f0100340:	e9 99 00 00 00       	jmp    f01003de <cons_putc+0x147>
f0100345:	83 f8 0a             	cmp    $0xa,%eax
f0100348:	74 3a                	je     f0100384 <cons_putc+0xed>
f010034a:	83 f8 0d             	cmp    $0xd,%eax
f010034d:	74 3d                	je     f010038c <cons_putc+0xf5>
f010034f:	e9 8a 00 00 00       	jmp    f01003de <cons_putc+0x147>
	case '\b':
		if (crt_pos > 0) {
f0100354:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f010035b:	66 85 c0             	test   %ax,%ax
f010035e:	0f 84 e6 00 00 00    	je     f010044a <cons_putc+0x1b3>
			crt_pos--;
f0100364:	83 e8 01             	sub    $0x1,%eax
f0100367:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010036d:	0f b7 c0             	movzwl %ax,%eax
f0100370:	66 81 e7 00 ff       	and    $0xff00,%di
f0100375:	83 cf 20             	or     $0x20,%edi
f0100378:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f010037e:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100382:	eb 78                	jmp    f01003fc <cons_putc+0x165>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100384:	66 83 05 28 45 11 f0 	addw   $0x50,0xf0114528
f010038b:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010038c:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f0100393:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100399:	c1 e8 16             	shr    $0x16,%eax
f010039c:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010039f:	c1 e0 04             	shl    $0x4,%eax
f01003a2:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
f01003a8:	eb 52                	jmp    f01003fc <cons_putc+0x165>
		break;
	case '\t':
		cons_putc(' ');
f01003aa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003af:	e8 e3 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003b4:	b8 20 00 00 00       	mov    $0x20,%eax
f01003b9:	e8 d9 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003be:	b8 20 00 00 00       	mov    $0x20,%eax
f01003c3:	e8 cf fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003c8:	b8 20 00 00 00       	mov    $0x20,%eax
f01003cd:	e8 c5 fe ff ff       	call   f0100297 <cons_putc>
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 bb fe ff ff       	call   f0100297 <cons_putc>
f01003dc:	eb 1e                	jmp    f01003fc <cons_putc+0x165>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01003de:	0f b7 05 28 45 11 f0 	movzwl 0xf0114528,%eax
f01003e5:	8d 50 01             	lea    0x1(%eax),%edx
f01003e8:	66 89 15 28 45 11 f0 	mov    %dx,0xf0114528
f01003ef:	0f b7 c0             	movzwl %ax,%eax
f01003f2:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f01003f8:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01003fc:	66 81 3d 28 45 11 f0 	cmpw   $0x7cf,0xf0114528
f0100403:	cf 07 
f0100405:	76 43                	jbe    f010044a <cons_putc+0x1b3>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100407:	a1 2c 45 11 f0       	mov    0xf011452c,%eax
f010040c:	83 ec 04             	sub    $0x4,%esp
f010040f:	68 00 0f 00 00       	push   $0xf00
f0100414:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010041a:	52                   	push   %edx
f010041b:	50                   	push   %eax
f010041c:	e8 2a 1c 00 00       	call   f010204b <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100421:	8b 15 2c 45 11 f0    	mov    0xf011452c,%edx
f0100427:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010042d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100433:	83 c4 10             	add    $0x10,%esp
f0100436:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010043b:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010043e:	39 d0                	cmp    %edx,%eax
f0100440:	75 f4                	jne    f0100436 <cons_putc+0x19f>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100442:	66 83 2d 28 45 11 f0 	subw   $0x50,0xf0114528
f0100449:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010044a:	8b 0d 30 45 11 f0    	mov    0xf0114530,%ecx
f0100450:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100455:	89 ca                	mov    %ecx,%edx
f0100457:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100458:	0f b7 1d 28 45 11 f0 	movzwl 0xf0114528,%ebx
f010045f:	8d 71 01             	lea    0x1(%ecx),%esi
f0100462:	89 d8                	mov    %ebx,%eax
f0100464:	66 c1 e8 08          	shr    $0x8,%ax
f0100468:	89 f2                	mov    %esi,%edx
f010046a:	ee                   	out    %al,(%dx)
f010046b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100470:	89 ca                	mov    %ecx,%edx
f0100472:	ee                   	out    %al,(%dx)
f0100473:	89 d8                	mov    %ebx,%eax
f0100475:	89 f2                	mov    %esi,%edx
f0100477:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100478:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010047b:	5b                   	pop    %ebx
f010047c:	5e                   	pop    %esi
f010047d:	5f                   	pop    %edi
f010047e:	5d                   	pop    %ebp
f010047f:	c3                   	ret    

f0100480 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100480:	80 3d 34 45 11 f0 00 	cmpb   $0x0,0xf0114534
f0100487:	74 11                	je     f010049a <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100489:	55                   	push   %ebp
f010048a:	89 e5                	mov    %esp,%ebp
f010048c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f010048f:	b8 1c 01 10 f0       	mov    $0xf010011c,%eax
f0100494:	e8 a2 fc ff ff       	call   f010013b <cons_intr>
}
f0100499:	c9                   	leave  
f010049a:	f3 c3                	repz ret 

f010049c <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010049c:	55                   	push   %ebp
f010049d:	89 e5                	mov    %esp,%ebp
f010049f:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004a2:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004a7:	e8 8f fc ff ff       	call   f010013b <cons_intr>
}
f01004ac:	c9                   	leave  
f01004ad:	c3                   	ret    

f01004ae <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004ae:	55                   	push   %ebp
f01004af:	89 e5                	mov    %esp,%ebp
f01004b1:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004b4:	e8 c7 ff ff ff       	call   f0100480 <serial_intr>
	kbd_intr();
f01004b9:	e8 de ff ff ff       	call   f010049c <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004be:	a1 20 45 11 f0       	mov    0xf0114520,%eax
f01004c3:	3b 05 24 45 11 f0    	cmp    0xf0114524,%eax
f01004c9:	74 26                	je     f01004f1 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004cb:	8d 50 01             	lea    0x1(%eax),%edx
f01004ce:	89 15 20 45 11 f0    	mov    %edx,0xf0114520
f01004d4:	0f b6 88 20 43 11 f0 	movzbl -0xfeebce0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f01004db:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f01004dd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004e3:	75 11                	jne    f01004f6 <cons_getc+0x48>
			cons.rpos = 0;
f01004e5:	c7 05 20 45 11 f0 00 	movl   $0x0,0xf0114520
f01004ec:	00 00 00 
f01004ef:	eb 05                	jmp    f01004f6 <cons_getc+0x48>
		return c;
	}
	return 0;
f01004f1:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004f6:	c9                   	leave  
f01004f7:	c3                   	ret    

f01004f8 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004f8:	55                   	push   %ebp
f01004f9:	89 e5                	mov    %esp,%ebp
f01004fb:	57                   	push   %edi
f01004fc:	56                   	push   %esi
f01004fd:	53                   	push   %ebx
f01004fe:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100501:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100508:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010050f:	5a a5 
	if (*cp != 0xA55A) {
f0100511:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100518:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010051c:	74 11                	je     f010052f <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010051e:	c7 05 30 45 11 f0 b4 	movl   $0x3b4,0xf0114530
f0100525:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100528:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f010052d:	eb 16                	jmp    f0100545 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010052f:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100536:	c7 05 30 45 11 f0 d4 	movl   $0x3d4,0xf0114530
f010053d:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100540:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100545:	8b 3d 30 45 11 f0    	mov    0xf0114530,%edi
f010054b:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100550:	89 fa                	mov    %edi,%edx
f0100552:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100553:	8d 5f 01             	lea    0x1(%edi),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100556:	89 da                	mov    %ebx,%edx
f0100558:	ec                   	in     (%dx),%al
f0100559:	0f b6 c8             	movzbl %al,%ecx
f010055c:	c1 e1 08             	shl    $0x8,%ecx
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055f:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100564:	89 fa                	mov    %edi,%edx
f0100566:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100567:	89 da                	mov    %ebx,%edx
f0100569:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056a:	89 35 2c 45 11 f0    	mov    %esi,0xf011452c
	crt_pos = pos;
f0100570:	0f b6 c0             	movzbl %al,%eax
f0100573:	09 c8                	or     %ecx,%eax
f0100575:	66 a3 28 45 11 f0    	mov    %ax,0xf0114528
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010057b:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100580:	b8 00 00 00 00       	mov    $0x0,%eax
f0100585:	89 f2                	mov    %esi,%edx
f0100587:	ee                   	out    %al,(%dx)
f0100588:	ba fb 03 00 00       	mov    $0x3fb,%edx
f010058d:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100592:	ee                   	out    %al,(%dx)
f0100593:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100598:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059d:	89 da                	mov    %ebx,%edx
f010059f:	ee                   	out    %al,(%dx)
f01005a0:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005aa:	ee                   	out    %al,(%dx)
f01005ab:	ba fb 03 00 00       	mov    $0x3fb,%edx
f01005b0:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b5:	ee                   	out    %al,(%dx)
f01005b6:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01005bb:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c0:	ee                   	out    %al,(%dx)
f01005c1:	ba f9 03 00 00       	mov    $0x3f9,%edx
f01005c6:	b8 01 00 00 00       	mov    $0x1,%eax
f01005cb:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01005d1:	ec                   	in     (%dx),%al
f01005d2:	89 c1                	mov    %eax,%ecx
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005d4:	3c ff                	cmp    $0xff,%al
f01005d6:	0f 95 05 34 45 11 f0 	setne  0xf0114534
f01005dd:	89 f2                	mov    %esi,%edx
f01005df:	ec                   	in     (%dx),%al
f01005e0:	89 da                	mov    %ebx,%edx
f01005e2:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005e3:	80 f9 ff             	cmp    $0xff,%cl
f01005e6:	75 10                	jne    f01005f8 <cons_init+0x100>
		cprintf("Serial port does not exist!\n");
f01005e8:	83 ec 0c             	sub    $0xc,%esp
f01005eb:	68 f9 24 10 f0       	push   $0xf01024f9
f01005f0:	e8 47 0f 00 00       	call   f010153c <cprintf>
f01005f5:	83 c4 10             	add    $0x10,%esp
}
f01005f8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005fb:	5b                   	pop    %ebx
f01005fc:	5e                   	pop    %esi
f01005fd:	5f                   	pop    %edi
f01005fe:	5d                   	pop    %ebp
f01005ff:	c3                   	ret    

f0100600 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100600:	55                   	push   %ebp
f0100601:	89 e5                	mov    %esp,%ebp
f0100603:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100606:	8b 45 08             	mov    0x8(%ebp),%eax
f0100609:	e8 89 fc ff ff       	call   f0100297 <cons_putc>
}
f010060e:	c9                   	leave  
f010060f:	c3                   	ret    

f0100610 <getchar>:

int
getchar(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100616:	e8 93 fe ff ff       	call   f01004ae <cons_getc>
f010061b:	85 c0                	test   %eax,%eax
f010061d:	74 f7                	je     f0100616 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <iscons>:

int
iscons(int fdnum)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	5d                   	pop    %ebp
f010062a:	c3                   	ret    

f010062b <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010062b:	55                   	push   %ebp
f010062c:	89 e5                	mov    %esp,%ebp
f010062e:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100631:	68 40 27 10 f0       	push   $0xf0102740
f0100636:	68 5e 27 10 f0       	push   $0xf010275e
f010063b:	68 63 27 10 f0       	push   $0xf0102763
f0100640:	e8 f7 0e 00 00       	call   f010153c <cprintf>
f0100645:	83 c4 0c             	add    $0xc,%esp
f0100648:	68 2c 28 10 f0       	push   $0xf010282c
f010064d:	68 6c 27 10 f0       	push   $0xf010276c
f0100652:	68 63 27 10 f0       	push   $0xf0102763
f0100657:	e8 e0 0e 00 00       	call   f010153c <cprintf>
f010065c:	83 c4 0c             	add    $0xc,%esp
f010065f:	68 75 27 10 f0       	push   $0xf0102775
f0100664:	68 83 27 10 f0       	push   $0xf0102783
f0100669:	68 63 27 10 f0       	push   $0xf0102763
f010066e:	e8 c9 0e 00 00       	call   f010153c <cprintf>
	return 0;
}
f0100673:	b8 00 00 00 00       	mov    $0x0,%eax
f0100678:	c9                   	leave  
f0100679:	c3                   	ret    

f010067a <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010067a:	55                   	push   %ebp
f010067b:	89 e5                	mov    %esp,%ebp
f010067d:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100680:	68 8d 27 10 f0       	push   $0xf010278d
f0100685:	e8 b2 0e 00 00       	call   f010153c <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010068a:	83 c4 08             	add    $0x8,%esp
f010068d:	68 0c 00 10 00       	push   $0x10000c
f0100692:	68 54 28 10 f0       	push   $0xf0102854
f0100697:	e8 a0 0e 00 00       	call   f010153c <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010069c:	83 c4 0c             	add    $0xc,%esp
f010069f:	68 0c 00 10 00       	push   $0x10000c
f01006a4:	68 0c 00 10 f0       	push   $0xf010000c
f01006a9:	68 7c 28 10 f0       	push   $0xf010287c
f01006ae:	e8 89 0e 00 00       	call   f010153c <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006b3:	83 c4 0c             	add    $0xc,%esp
f01006b6:	68 81 24 10 00       	push   $0x102481
f01006bb:	68 81 24 10 f0       	push   $0xf0102481
f01006c0:	68 a0 28 10 f0       	push   $0xf01028a0
f01006c5:	e8 72 0e 00 00       	call   f010153c <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ca:	83 c4 0c             	add    $0xc,%esp
f01006cd:	68 00 43 11 00       	push   $0x114300
f01006d2:	68 00 43 11 f0       	push   $0xf0114300
f01006d7:	68 c4 28 10 f0       	push   $0xf01028c4
f01006dc:	e8 5b 0e 00 00       	call   f010153c <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e1:	83 c4 0c             	add    $0xc,%esp
f01006e4:	68 50 49 11 00       	push   $0x114950
f01006e9:	68 50 49 11 f0       	push   $0xf0114950
f01006ee:	68 e8 28 10 f0       	push   $0xf01028e8
f01006f3:	e8 44 0e 00 00       	call   f010153c <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006f8:	b8 4f 4d 11 f0       	mov    $0xf0114d4f,%eax
f01006fd:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100702:	83 c4 08             	add    $0x8,%esp
f0100705:	25 00 fc ff ff       	and    $0xfffffc00,%eax
f010070a:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100710:	85 c0                	test   %eax,%eax
f0100712:	0f 48 c2             	cmovs  %edx,%eax
f0100715:	c1 f8 0a             	sar    $0xa,%eax
f0100718:	50                   	push   %eax
f0100719:	68 0c 29 10 f0       	push   $0xf010290c
f010071e:	e8 19 0e 00 00       	call   f010153c <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100723:	b8 00 00 00 00       	mov    $0x0,%eax
f0100728:	c9                   	leave  
f0100729:	c3                   	ret    

f010072a <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010072a:	55                   	push   %ebp
f010072b:	89 e5                	mov    %esp,%ebp
f010072d:	57                   	push   %edi
f010072e:	56                   	push   %esi
f010072f:	53                   	push   %ebx
f0100730:	83 ec 38             	sub    $0x38,%esp

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100733:	89 ee                	mov    %ebp,%esi
	// Your code here.
	struct Eipdebuginfo info;
	uint32_t *ebp = (uint32_t *)read_ebp();
	cprintf("Stack backtrace:\n");
f0100735:	68 a6 27 10 f0       	push   $0xf01027a6
f010073a:	e8 fd 0d 00 00       	call   f010153c <cprintf>
	while(ebp)
f010073f:	83 c4 10             	add    $0x10,%esp
f0100742:	eb 67                	jmp    f01007ab <mon_backtrace+0x81>
	{
		cprintf(" ebp %08x eip %08x args ", ebp, ebp[1]);
f0100744:	83 ec 04             	sub    $0x4,%esp
f0100747:	ff 76 04             	pushl  0x4(%esi)
f010074a:	56                   	push   %esi
f010074b:	68 b8 27 10 f0       	push   $0xf01027b8
f0100750:	e8 e7 0d 00 00       	call   f010153c <cprintf>
f0100755:	8d 5e 08             	lea    0x8(%esi),%ebx
f0100758:	8d 7e 1c             	lea    0x1c(%esi),%edi
f010075b:	83 c4 10             	add    $0x10,%esp
		for(int i = 2; i < 7; ++i) 
		{
			cprintf(" %08x", ebp[i]);
f010075e:	83 ec 08             	sub    $0x8,%esp
f0100761:	ff 33                	pushl  (%ebx)
f0100763:	68 d1 27 10 f0       	push   $0xf01027d1
f0100768:	e8 cf 0d 00 00       	call   f010153c <cprintf>
f010076d:	83 c3 04             	add    $0x4,%ebx
	uint32_t *ebp = (uint32_t *)read_ebp();
	cprintf("Stack backtrace:\n");
	while(ebp)
	{
		cprintf(" ebp %08x eip %08x args ", ebp, ebp[1]);
		for(int i = 2; i < 7; ++i) 
f0100770:	83 c4 10             	add    $0x10,%esp
f0100773:	39 fb                	cmp    %edi,%ebx
f0100775:	75 e7                	jne    f010075e <mon_backtrace+0x34>
		{
			cprintf(" %08x", ebp[i]);
		}
		debuginfo_eip(ebp[1], &info);
f0100777:	83 ec 08             	sub    $0x8,%esp
f010077a:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010077d:	50                   	push   %eax
f010077e:	ff 76 04             	pushl  0x4(%esi)
f0100781:	e8 c0 0e 00 00       	call   f0101646 <debuginfo_eip>
		cprintf("\n     %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1] - info.eip_fn_addr);
f0100786:	83 c4 08             	add    $0x8,%esp
f0100789:	8b 46 04             	mov    0x4(%esi),%eax
f010078c:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010078f:	50                   	push   %eax
f0100790:	ff 75 d8             	pushl  -0x28(%ebp)
f0100793:	ff 75 dc             	pushl  -0x24(%ebp)
f0100796:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100799:	ff 75 d0             	pushl  -0x30(%ebp)
f010079c:	68 d7 27 10 f0       	push   $0xf01027d7
f01007a1:	e8 96 0d 00 00       	call   f010153c <cprintf>
		ebp = (uint32_t *)(*ebp);
f01007a6:	8b 36                	mov    (%esi),%esi
f01007a8:	83 c4 20             	add    $0x20,%esp
{
	// Your code here.
	struct Eipdebuginfo info;
	uint32_t *ebp = (uint32_t *)read_ebp();
	cprintf("Stack backtrace:\n");
	while(ebp)
f01007ab:	85 f6                	test   %esi,%esi
f01007ad:	75 95                	jne    f0100744 <mon_backtrace+0x1a>
		debuginfo_eip(ebp[1], &info);
		cprintf("\n     %s:%d: %.*s+%d\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1] - info.eip_fn_addr);
		ebp = (uint32_t *)(*ebp);
	}
	return 0;
}
f01007af:	b8 00 00 00 00       	mov    $0x0,%eax
f01007b4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01007b7:	5b                   	pop    %ebx
f01007b8:	5e                   	pop    %esi
f01007b9:	5f                   	pop    %edi
f01007ba:	5d                   	pop    %ebp
f01007bb:	c3                   	ret    

f01007bc <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007bc:	55                   	push   %ebp
f01007bd:	89 e5                	mov    %esp,%ebp
f01007bf:	57                   	push   %edi
f01007c0:	56                   	push   %esi
f01007c1:	53                   	push   %ebx
f01007c2:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007c5:	68 38 29 10 f0       	push   $0xf0102938
f01007ca:	e8 6d 0d 00 00       	call   f010153c <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007cf:	c7 04 24 5c 29 10 f0 	movl   $0xf010295c,(%esp)
f01007d6:	e8 61 0d 00 00       	call   f010153c <cprintf>
f01007db:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01007de:	83 ec 0c             	sub    $0xc,%esp
f01007e1:	68 ed 27 10 f0       	push   $0xf01027ed
f01007e6:	e8 bc 15 00 00       	call   f0101da7 <readline>
f01007eb:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007ed:	83 c4 10             	add    $0x10,%esp
f01007f0:	85 c0                	test   %eax,%eax
f01007f2:	74 ea                	je     f01007de <monitor+0x22>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007f4:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007fb:	be 00 00 00 00       	mov    $0x0,%esi
f0100800:	eb 0a                	jmp    f010080c <monitor+0x50>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100802:	c6 03 00             	movb   $0x0,(%ebx)
f0100805:	89 f7                	mov    %esi,%edi
f0100807:	8d 5b 01             	lea    0x1(%ebx),%ebx
f010080a:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010080c:	0f b6 03             	movzbl (%ebx),%eax
f010080f:	84 c0                	test   %al,%al
f0100811:	74 63                	je     f0100876 <monitor+0xba>
f0100813:	83 ec 08             	sub    $0x8,%esp
f0100816:	0f be c0             	movsbl %al,%eax
f0100819:	50                   	push   %eax
f010081a:	68 f1 27 10 f0       	push   $0xf01027f1
f010081f:	e8 9d 17 00 00       	call   f0101fc1 <strchr>
f0100824:	83 c4 10             	add    $0x10,%esp
f0100827:	85 c0                	test   %eax,%eax
f0100829:	75 d7                	jne    f0100802 <monitor+0x46>
			*buf++ = 0;
		if (*buf == 0)
f010082b:	80 3b 00             	cmpb   $0x0,(%ebx)
f010082e:	74 46                	je     f0100876 <monitor+0xba>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100830:	83 fe 0f             	cmp    $0xf,%esi
f0100833:	75 14                	jne    f0100849 <monitor+0x8d>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100835:	83 ec 08             	sub    $0x8,%esp
f0100838:	6a 10                	push   $0x10
f010083a:	68 f6 27 10 f0       	push   $0xf01027f6
f010083f:	e8 f8 0c 00 00       	call   f010153c <cprintf>
f0100844:	83 c4 10             	add    $0x10,%esp
f0100847:	eb 95                	jmp    f01007de <monitor+0x22>
			return 0;
		}
		argv[argc++] = buf;
f0100849:	8d 7e 01             	lea    0x1(%esi),%edi
f010084c:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100850:	eb 03                	jmp    f0100855 <monitor+0x99>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100852:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100855:	0f b6 03             	movzbl (%ebx),%eax
f0100858:	84 c0                	test   %al,%al
f010085a:	74 ae                	je     f010080a <monitor+0x4e>
f010085c:	83 ec 08             	sub    $0x8,%esp
f010085f:	0f be c0             	movsbl %al,%eax
f0100862:	50                   	push   %eax
f0100863:	68 f1 27 10 f0       	push   $0xf01027f1
f0100868:	e8 54 17 00 00       	call   f0101fc1 <strchr>
f010086d:	83 c4 10             	add    $0x10,%esp
f0100870:	85 c0                	test   %eax,%eax
f0100872:	74 de                	je     f0100852 <monitor+0x96>
f0100874:	eb 94                	jmp    f010080a <monitor+0x4e>
			buf++;
	}
	argv[argc] = 0;
f0100876:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010087d:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010087e:	85 f6                	test   %esi,%esi
f0100880:	0f 84 58 ff ff ff    	je     f01007de <monitor+0x22>
f0100886:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010088b:	83 ec 08             	sub    $0x8,%esp
f010088e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100891:	ff 34 85 a0 29 10 f0 	pushl  -0xfefd660(,%eax,4)
f0100898:	ff 75 a8             	pushl  -0x58(%ebp)
f010089b:	e8 c3 16 00 00       	call   f0101f63 <strcmp>
f01008a0:	83 c4 10             	add    $0x10,%esp
f01008a3:	85 c0                	test   %eax,%eax
f01008a5:	75 21                	jne    f01008c8 <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f01008a7:	83 ec 04             	sub    $0x4,%esp
f01008aa:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01008ad:	ff 75 08             	pushl  0x8(%ebp)
f01008b0:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008b3:	52                   	push   %edx
f01008b4:	56                   	push   %esi
f01008b5:	ff 14 85 a8 29 10 f0 	call   *-0xfefd658(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008bc:	83 c4 10             	add    $0x10,%esp
f01008bf:	85 c0                	test   %eax,%eax
f01008c1:	78 25                	js     f01008e8 <monitor+0x12c>
f01008c3:	e9 16 ff ff ff       	jmp    f01007de <monitor+0x22>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01008c8:	83 c3 01             	add    $0x1,%ebx
f01008cb:	83 fb 03             	cmp    $0x3,%ebx
f01008ce:	75 bb                	jne    f010088b <monitor+0xcf>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008d0:	83 ec 08             	sub    $0x8,%esp
f01008d3:	ff 75 a8             	pushl  -0x58(%ebp)
f01008d6:	68 13 28 10 f0       	push   $0xf0102813
f01008db:	e8 5c 0c 00 00       	call   f010153c <cprintf>
f01008e0:	83 c4 10             	add    $0x10,%esp
f01008e3:	e9 f6 fe ff ff       	jmp    f01007de <monitor+0x22>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008e8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008eb:	5b                   	pop    %ebx
f01008ec:	5e                   	pop    %esi
f01008ed:	5f                   	pop    %edi
f01008ee:	5d                   	pop    %ebp
f01008ef:	c3                   	ret    

f01008f0 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01008f0:	55                   	push   %ebp
f01008f1:	89 e5                	mov    %esp,%ebp
f01008f3:	56                   	push   %esi
f01008f4:	53                   	push   %ebx
f01008f5:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01008f7:	83 ec 0c             	sub    $0xc,%esp
f01008fa:	50                   	push   %eax
f01008fb:	e8 d5 0b 00 00       	call   f01014d5 <mc146818_read>
f0100900:	89 c6                	mov    %eax,%esi
f0100902:	83 c3 01             	add    $0x1,%ebx
f0100905:	89 1c 24             	mov    %ebx,(%esp)
f0100908:	e8 c8 0b 00 00       	call   f01014d5 <mc146818_read>
f010090d:	c1 e0 08             	shl    $0x8,%eax
f0100910:	09 f0                	or     %esi,%eax
}
f0100912:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100915:	5b                   	pop    %ebx
f0100916:	5e                   	pop    %esi
f0100917:	5d                   	pop    %ebp
f0100918:	c3                   	ret    

f0100919 <check_va2pa>:
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100919:	89 d1                	mov    %edx,%ecx
f010091b:	c1 e9 16             	shr    $0x16,%ecx
f010091e:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100921:	a8 01                	test   $0x1,%al
f0100923:	74 52                	je     f0100977 <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100925:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010092a:	89 c1                	mov    %eax,%ecx
f010092c:	c1 e9 0c             	shr    $0xc,%ecx
f010092f:	3b 0d 44 49 11 f0    	cmp    0xf0114944,%ecx
f0100935:	72 1b                	jb     f0100952 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100937:	55                   	push   %ebp
f0100938:	89 e5                	mov    %esp,%ebp
f010093a:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010093d:	50                   	push   %eax
f010093e:	68 c4 29 10 f0       	push   $0xf01029c4
f0100943:	68 a6 02 00 00       	push   $0x2a6
f0100948:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010094d:	e8 39 f7 ff ff       	call   f010008b <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100952:	c1 ea 0c             	shr    $0xc,%edx
f0100955:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010095b:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100962:	89 c2                	mov    %eax,%edx
f0100964:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100967:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010096c:	85 d2                	test   %edx,%edx
f010096e:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100973:	0f 44 c2             	cmove  %edx,%eax
f0100976:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100977:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f010097c:	c3                   	ret    

f010097d <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f010097d:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010097f:	83 3d 38 45 11 f0 00 	cmpl   $0x0,0xf0114538
f0100986:	75 0f                	jne    f0100997 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100988:	b8 4f 59 11 f0       	mov    $0xf011594f,%eax
f010098d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100992:	a3 38 45 11 f0       	mov    %eax,0xf0114538
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f0100997:	a1 38 45 11 f0       	mov    0xf0114538,%eax
	if (n > 0) {
f010099c:	85 d2                	test   %edx,%edx
f010099e:	74 5f                	je     f01009ff <boot_alloc+0x82>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009a0:	55                   	push   %ebp
f01009a1:	89 e5                	mov    %esp,%ebp
f01009a3:	53                   	push   %ebx
f01009a4:	83 ec 04             	sub    $0x4,%esp
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01009a7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01009ac:	77 12                	ja     f01009c0 <boot_alloc+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01009ae:	50                   	push   %eax
f01009af:	68 e8 29 10 f0       	push   $0xf01029e8
f01009b4:	6a 6b                	push   $0x6b
f01009b6:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01009bb:	e8 cb f6 ff ff       	call   f010008b <_panic>
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
	if (n > 0) {
		if (PADDR(nextfree) + n > npages * PGSIZE) {
f01009c0:	8d 9c 10 00 00 00 10 	lea    0x10000000(%eax,%edx,1),%ebx
f01009c7:	8b 0d 44 49 11 f0    	mov    0xf0114944,%ecx
f01009cd:	c1 e1 0c             	shl    $0xc,%ecx
f01009d0:	39 cb                	cmp    %ecx,%ebx
f01009d2:	76 14                	jbe    f01009e8 <boot_alloc+0x6b>
			panic("out of memory!\n");
f01009d4:	83 ec 04             	sub    $0x4,%esp
f01009d7:	68 88 2b 10 f0       	push   $0xf0102b88
f01009dc:	6a 6c                	push   $0x6c
f01009de:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01009e3:	e8 a3 f6 ff ff       	call   f010008b <_panic>
		} 
		else
			nextfree = ROUNDUP((char *) nextfree + n, PGSIZE);
f01009e8:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f01009ef:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009f5:	89 15 38 45 11 f0    	mov    %edx,0xf0114538
	}
	return result;
}
f01009fb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01009fe:	c9                   	leave  
f01009ff:	f3 c3                	repz ret 

f0100a01 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a01:	55                   	push   %ebp
f0100a02:	89 e5                	mov    %esp,%ebp
f0100a04:	57                   	push   %edi
f0100a05:	56                   	push   %esi
f0100a06:	53                   	push   %ebx
f0100a07:	83 ec 2c             	sub    $0x2c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a0a:	84 c0                	test   %al,%al
f0100a0c:	0f 85 72 02 00 00    	jne    f0100c84 <check_page_free_list+0x283>
f0100a12:	e9 7f 02 00 00       	jmp    f0100c96 <check_page_free_list+0x295>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100a17:	83 ec 04             	sub    $0x4,%esp
f0100a1a:	68 0c 2a 10 f0       	push   $0xf0102a0c
f0100a1f:	68 e9 01 00 00       	push   $0x1e9
f0100a24:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100a29:	e8 5d f6 ff ff       	call   f010008b <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100a2e:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100a31:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100a34:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100a37:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a3a:	89 c2                	mov    %eax,%edx
f0100a3c:	2b 15 4c 49 11 f0    	sub    0xf011494c,%edx
f0100a42:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100a48:	0f 95 c2             	setne  %dl
f0100a4b:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100a4e:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100a52:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100a54:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a58:	8b 00                	mov    (%eax),%eax
f0100a5a:	85 c0                	test   %eax,%eax
f0100a5c:	75 dc                	jne    f0100a3a <check_page_free_list+0x39>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a5e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a61:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a67:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a6a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a6d:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100a6f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a72:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a77:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a7c:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
f0100a82:	eb 53                	jmp    f0100ad7 <check_page_free_list+0xd6>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a84:	89 d8                	mov    %ebx,%eax
f0100a86:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f0100a8c:	c1 f8 03             	sar    $0x3,%eax
f0100a8f:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100a92:	89 c2                	mov    %eax,%edx
f0100a94:	c1 ea 16             	shr    $0x16,%edx
f0100a97:	39 f2                	cmp    %esi,%edx
f0100a99:	73 3a                	jae    f0100ad5 <check_page_free_list+0xd4>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a9b:	89 c2                	mov    %eax,%edx
f0100a9d:	c1 ea 0c             	shr    $0xc,%edx
f0100aa0:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f0100aa6:	72 12                	jb     f0100aba <check_page_free_list+0xb9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100aa8:	50                   	push   %eax
f0100aa9:	68 c4 29 10 f0       	push   $0xf01029c4
f0100aae:	6a 52                	push   $0x52
f0100ab0:	68 98 2b 10 f0       	push   $0xf0102b98
f0100ab5:	e8 d1 f5 ff ff       	call   f010008b <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100aba:	83 ec 04             	sub    $0x4,%esp
f0100abd:	68 80 00 00 00       	push   $0x80
f0100ac2:	68 97 00 00 00       	push   $0x97
f0100ac7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100acc:	50                   	push   %eax
f0100acd:	e8 2c 15 00 00       	call   f0101ffe <memset>
f0100ad2:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ad5:	8b 1b                	mov    (%ebx),%ebx
f0100ad7:	85 db                	test   %ebx,%ebx
f0100ad9:	75 a9                	jne    f0100a84 <check_page_free_list+0x83>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100adb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ae0:	e8 98 fe ff ff       	call   f010097d <boot_alloc>
f0100ae5:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ae8:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100aee:	8b 0d 4c 49 11 f0    	mov    0xf011494c,%ecx
		assert(pp < pages + npages);
f0100af4:	a1 44 49 11 f0       	mov    0xf0114944,%eax
f0100af9:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100afc:	8d 3c c1             	lea    (%ecx,%eax,8),%edi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100aff:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b02:	be 00 00 00 00       	mov    $0x0,%esi
f0100b07:	89 5d d0             	mov    %ebx,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b0a:	e9 30 01 00 00       	jmp    f0100c3f <check_page_free_list+0x23e>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b0f:	39 ca                	cmp    %ecx,%edx
f0100b11:	73 19                	jae    f0100b2c <check_page_free_list+0x12b>
f0100b13:	68 a6 2b 10 f0       	push   $0xf0102ba6
f0100b18:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100b1d:	68 03 02 00 00       	push   $0x203
f0100b22:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100b27:	e8 5f f5 ff ff       	call   f010008b <_panic>
		assert(pp < pages + npages);
f0100b2c:	39 fa                	cmp    %edi,%edx
f0100b2e:	72 19                	jb     f0100b49 <check_page_free_list+0x148>
f0100b30:	68 c7 2b 10 f0       	push   $0xf0102bc7
f0100b35:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100b3a:	68 04 02 00 00       	push   $0x204
f0100b3f:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100b44:	e8 42 f5 ff ff       	call   f010008b <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b49:	89 d0                	mov    %edx,%eax
f0100b4b:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100b4e:	a8 07                	test   $0x7,%al
f0100b50:	74 19                	je     f0100b6b <check_page_free_list+0x16a>
f0100b52:	68 30 2a 10 f0       	push   $0xf0102a30
f0100b57:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100b5c:	68 05 02 00 00       	push   $0x205
f0100b61:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100b66:	e8 20 f5 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b6b:	c1 f8 03             	sar    $0x3,%eax
f0100b6e:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b71:	85 c0                	test   %eax,%eax
f0100b73:	75 19                	jne    f0100b8e <check_page_free_list+0x18d>
f0100b75:	68 db 2b 10 f0       	push   $0xf0102bdb
f0100b7a:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100b7f:	68 08 02 00 00       	push   $0x208
f0100b84:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100b89:	e8 fd f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b8e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b93:	75 19                	jne    f0100bae <check_page_free_list+0x1ad>
f0100b95:	68 ec 2b 10 f0       	push   $0xf0102bec
f0100b9a:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100b9f:	68 09 02 00 00       	push   $0x209
f0100ba4:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100ba9:	e8 dd f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100bae:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100bb3:	75 19                	jne    f0100bce <check_page_free_list+0x1cd>
f0100bb5:	68 64 2a 10 f0       	push   $0xf0102a64
f0100bba:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100bbf:	68 0a 02 00 00       	push   $0x20a
f0100bc4:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100bc9:	e8 bd f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100bce:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100bd3:	75 19                	jne    f0100bee <check_page_free_list+0x1ed>
f0100bd5:	68 05 2c 10 f0       	push   $0xf0102c05
f0100bda:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100bdf:	68 0b 02 00 00       	push   $0x20b
f0100be4:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100be9:	e8 9d f4 ff ff       	call   f010008b <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100bee:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100bf3:	76 3f                	jbe    f0100c34 <check_page_free_list+0x233>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bf5:	89 c3                	mov    %eax,%ebx
f0100bf7:	c1 eb 0c             	shr    $0xc,%ebx
f0100bfa:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100bfd:	77 12                	ja     f0100c11 <check_page_free_list+0x210>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bff:	50                   	push   %eax
f0100c00:	68 c4 29 10 f0       	push   $0xf01029c4
f0100c05:	6a 52                	push   $0x52
f0100c07:	68 98 2b 10 f0       	push   $0xf0102b98
f0100c0c:	e8 7a f4 ff ff       	call   f010008b <_panic>
f0100c11:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c16:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100c19:	76 1e                	jbe    f0100c39 <check_page_free_list+0x238>
f0100c1b:	68 88 2a 10 f0       	push   $0xf0102a88
f0100c20:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100c25:	68 0c 02 00 00       	push   $0x20c
f0100c2a:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100c2f:	e8 57 f4 ff ff       	call   f010008b <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100c34:	83 c6 01             	add    $0x1,%esi
f0100c37:	eb 04                	jmp    f0100c3d <check_page_free_list+0x23c>
		else
			++nfree_extmem;
f0100c39:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c3d:	8b 12                	mov    (%edx),%edx
f0100c3f:	85 d2                	test   %edx,%edx
f0100c41:	0f 85 c8 fe ff ff    	jne    f0100b0f <check_page_free_list+0x10e>
f0100c47:	8b 5d d0             	mov    -0x30(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100c4a:	85 f6                	test   %esi,%esi
f0100c4c:	7f 19                	jg     f0100c67 <check_page_free_list+0x266>
f0100c4e:	68 1f 2c 10 f0       	push   $0xf0102c1f
f0100c53:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100c58:	68 14 02 00 00       	push   $0x214
f0100c5d:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100c62:	e8 24 f4 ff ff       	call   f010008b <_panic>
	assert(nfree_extmem > 0);
f0100c67:	85 db                	test   %ebx,%ebx
f0100c69:	7f 42                	jg     f0100cad <check_page_free_list+0x2ac>
f0100c6b:	68 31 2c 10 f0       	push   $0xf0102c31
f0100c70:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100c75:	68 15 02 00 00       	push   $0x215
f0100c7a:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100c7f:	e8 07 f4 ff ff       	call   f010008b <_panic>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100c84:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100c89:	85 c0                	test   %eax,%eax
f0100c8b:	0f 85 9d fd ff ff    	jne    f0100a2e <check_page_free_list+0x2d>
f0100c91:	e9 81 fd ff ff       	jmp    f0100a17 <check_page_free_list+0x16>
f0100c96:	83 3d 3c 45 11 f0 00 	cmpl   $0x0,0xf011453c
f0100c9d:	0f 84 74 fd ff ff    	je     f0100a17 <check_page_free_list+0x16>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ca3:	be 00 04 00 00       	mov    $0x400,%esi
f0100ca8:	e9 cf fd ff ff       	jmp    f0100a7c <check_page_free_list+0x7b>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100cad:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100cb0:	5b                   	pop    %ebx
f0100cb1:	5e                   	pop    %esi
f0100cb2:	5f                   	pop    %edi
f0100cb3:	5d                   	pop    %ebp
f0100cb4:	c3                   	ret    

f0100cb5 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100cb5:	55                   	push   %ebp
f0100cb6:	89 e5                	mov    %esp,%ebp
f0100cb8:	53                   	push   %ebx
f0100cb9:	83 ec 04             	sub    $0x4,%esp
f0100cbc:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {  // first set all free
f0100cc2:	ba 00 00 00 00       	mov    $0x0,%edx
f0100cc7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ccc:	eb 27                	jmp    f0100cf5 <page_init+0x40>
f0100cce:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100cd5:	89 d1                	mov    %edx,%ecx
f0100cd7:	03 0d 4c 49 11 f0    	add    0xf011494c,%ecx
f0100cdd:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100ce3:	89 19                	mov    %ebx,(%ecx)
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {  // first set all free
f0100ce5:	83 c0 01             	add    $0x1,%eax
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
f0100ce8:	89 d3                	mov    %edx,%ebx
f0100cea:	03 1d 4c 49 11 f0    	add    0xf011494c,%ebx
f0100cf0:	ba 01 00 00 00       	mov    $0x1,%edx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i, io_page_i, ext_page_i, free_top;
	for (i = 0; i < npages; i++) {  // first set all free
f0100cf5:	3b 05 44 49 11 f0    	cmp    0xf0114944,%eax
f0100cfb:	72 d1                	jb     f0100cce <page_init+0x19>
f0100cfd:	84 d2                	test   %dl,%dl
f0100cff:	74 06                	je     f0100d07 <page_init+0x52>
f0100d01:	89 1d 3c 45 11 f0    	mov    %ebx,0xf011453c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

	pages[0].pp_link = pages[1].pp_link = NULL;
f0100d07:	a1 4c 49 11 f0       	mov    0xf011494c,%eax
f0100d0c:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
f0100d13:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	io_page_i = PGNUM(IOPHYSMEM);  // get page number
	ext_page_i = PGNUM(EXTPHYSMEM);
	free_top = PGNUM(PADDR(boot_alloc(0)));
f0100d19:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d1e:	e8 5a fc ff ff       	call   f010097d <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d23:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100d28:	77 15                	ja     f0100d3f <page_init+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100d2a:	50                   	push   %eax
f0100d2b:	68 e8 29 10 f0       	push   $0xf01029e8
f0100d30:	68 15 01 00 00       	push   $0x115
f0100d35:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100d3a:	e8 4c f3 ff ff       	call   f010008b <_panic>
f0100d3f:	8d 88 00 00 00 10    	lea    0x10000000(%eax),%ecx
f0100d45:	c1 e9 0c             	shr    $0xc,%ecx

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
f0100d48:	a1 4c 49 11 f0       	mov    0xf011494c,%eax
f0100d4d:	8b 90 00 05 00 00    	mov    0x500(%eax),%edx
f0100d53:	89 90 00 08 00 00    	mov    %edx,0x800(%eax)
f0100d59:	b8 00 05 00 00       	mov    $0x500,%eax
	for (i = io_page_i; i < ext_page_i; i++)
		pages[i].pp_link = NULL;
f0100d5e:	8b 15 4c 49 11 f0    	mov    0xf011494c,%edx
f0100d64:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f0100d6b:	83 c0 08             	add    $0x8,%eax
	io_page_i = PGNUM(IOPHYSMEM);  // get page number
	ext_page_i = PGNUM(EXTPHYSMEM);
	free_top = PGNUM(PADDR(boot_alloc(0)));

	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
	for (i = io_page_i; i < ext_page_i; i++)
f0100d6e:	3d 00 08 00 00       	cmp    $0x800,%eax
f0100d73:	75 e9                	jne    f0100d5e <page_init+0xa9>
		pages[i].pp_link = NULL;
	
	pages[free_top].pp_link = pages[ext_page_i].pp_link;
f0100d75:	a1 4c 49 11 f0       	mov    0xf011494c,%eax
f0100d7a:	8b 90 00 08 00 00    	mov    0x800(%eax),%edx
f0100d80:	89 14 c8             	mov    %edx,(%eax,%ecx,8)
	for (i = ext_page_i; i < free_top; i++) 
f0100d83:	b8 00 01 00 00       	mov    $0x100,%eax
f0100d88:	eb 10                	jmp    f0100d9a <page_init+0xe5>
		pages[i].pp_link = NULL;
f0100d8a:	8b 15 4c 49 11 f0    	mov    0xf011494c,%edx
f0100d90:	c7 04 c2 00 00 00 00 	movl   $0x0,(%edx,%eax,8)
	pages[ext_page_i].pp_link = pages[io_page_i].pp_link;
	for (i = io_page_i; i < ext_page_i; i++)
		pages[i].pp_link = NULL;
	
	pages[free_top].pp_link = pages[ext_page_i].pp_link;
	for (i = ext_page_i; i < free_top; i++) 
f0100d97:	83 c0 01             	add    $0x1,%eax
f0100d9a:	39 c8                	cmp    %ecx,%eax
f0100d9c:	72 ec                	jb     f0100d8a <page_init+0xd5>
		pages[i].pp_link = NULL;
}
f0100d9e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100da1:	c9                   	leave  
f0100da2:	c3                   	ret    

f0100da3 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100da3:	55                   	push   %ebp
f0100da4:	89 e5                	mov    %esp,%ebp
f0100da6:	53                   	push   %ebx
f0100da7:	83 ec 04             	sub    $0x4,%esp
	// Fill this function in
	struct PageInfo* alloc_page = page_free_list;
f0100daa:	8b 1d 3c 45 11 f0    	mov    0xf011453c,%ebx
	if (alloc_page) {
f0100db0:	85 db                	test   %ebx,%ebx
f0100db2:	74 58                	je     f0100e0c <page_alloc+0x69>
		page_free_list = alloc_page -> pp_link;
f0100db4:	8b 03                	mov    (%ebx),%eax
f0100db6:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
		alloc_page -> pp_link = NULL;
f0100dbb:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
		if (alloc_flags & ALLOC_ZERO) {
f0100dc1:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100dc5:	74 45                	je     f0100e0c <page_alloc+0x69>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dc7:	89 d8                	mov    %ebx,%eax
f0100dc9:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f0100dcf:	c1 f8 03             	sar    $0x3,%eax
f0100dd2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dd5:	89 c2                	mov    %eax,%edx
f0100dd7:	c1 ea 0c             	shr    $0xc,%edx
f0100dda:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f0100de0:	72 12                	jb     f0100df4 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100de2:	50                   	push   %eax
f0100de3:	68 c4 29 10 f0       	push   $0xf01029c4
f0100de8:	6a 52                	push   $0x52
f0100dea:	68 98 2b 10 f0       	push   $0xf0102b98
f0100def:	e8 97 f2 ff ff       	call   f010008b <_panic>
			memset(page2kva(alloc_page), 0, PGSIZE);
f0100df4:	83 ec 04             	sub    $0x4,%esp
f0100df7:	68 00 10 00 00       	push   $0x1000
f0100dfc:	6a 00                	push   $0x0
f0100dfe:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100e03:	50                   	push   %eax
f0100e04:	e8 f5 11 00 00       	call   f0101ffe <memset>
f0100e09:	83 c4 10             	add    $0x10,%esp
		} 
	}
	return alloc_page;
}
f0100e0c:	89 d8                	mov    %ebx,%eax
f0100e0e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100e11:	c9                   	leave  
f0100e12:	c3                   	ret    

f0100e13 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100e13:	55                   	push   %ebp
f0100e14:	89 e5                	mov    %esp,%ebp
f0100e16:	83 ec 08             	sub    $0x8,%esp
f0100e19:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	assert(pp -> pp_ref == 0);   // JUST assert
f0100e1c:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100e21:	74 19                	je     f0100e3c <page_free+0x29>
f0100e23:	68 42 2c 10 f0       	push   $0xf0102c42
f0100e28:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100e2d:	68 45 01 00 00       	push   $0x145
f0100e32:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100e37:	e8 4f f2 ff ff       	call   f010008b <_panic>
	assert(pp -> pp_link == NULL);
f0100e3c:	83 38 00             	cmpl   $0x0,(%eax)
f0100e3f:	74 19                	je     f0100e5a <page_free+0x47>
f0100e41:	68 54 2c 10 f0       	push   $0xf0102c54
f0100e46:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100e4b:	68 46 01 00 00       	push   $0x146
f0100e50:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100e55:	e8 31 f2 ff ff       	call   f010008b <_panic>

	pp -> pp_link = page_free_list;
f0100e5a:	8b 15 3c 45 11 f0    	mov    0xf011453c,%edx
f0100e60:	89 10                	mov    %edx,(%eax)
	page_free_list = pp; 
f0100e62:	a3 3c 45 11 f0       	mov    %eax,0xf011453c
}
f0100e67:	c9                   	leave  
f0100e68:	c3                   	ret    

f0100e69 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100e69:	55                   	push   %ebp
f0100e6a:	89 e5                	mov    %esp,%ebp
f0100e6c:	57                   	push   %edi
f0100e6d:	56                   	push   %esi
f0100e6e:	53                   	push   %ebx
f0100e6f:	83 ec 1c             	sub    $0x1c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0100e72:	b8 15 00 00 00       	mov    $0x15,%eax
f0100e77:	e8 74 fa ff ff       	call   f01008f0 <nvram_read>
f0100e7c:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0100e7e:	b8 17 00 00 00       	mov    $0x17,%eax
f0100e83:	e8 68 fa ff ff       	call   f01008f0 <nvram_read>
f0100e88:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0100e8a:	b8 34 00 00 00       	mov    $0x34,%eax
f0100e8f:	e8 5c fa ff ff       	call   f01008f0 <nvram_read>
f0100e94:	c1 e0 06             	shl    $0x6,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0100e97:	85 c0                	test   %eax,%eax
f0100e99:	74 07                	je     f0100ea2 <mem_init+0x39>
		totalmem = 16 * 1024 + ext16mem;
f0100e9b:	05 00 40 00 00       	add    $0x4000,%eax
f0100ea0:	eb 0b                	jmp    f0100ead <mem_init+0x44>
	else if (extmem)
		totalmem = 1 * 1024 + extmem;
f0100ea2:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f0100ea8:	85 f6                	test   %esi,%esi
f0100eaa:	0f 44 c3             	cmove  %ebx,%eax
	else
		totalmem = basemem;

	npages = totalmem / (PGSIZE / 1024);
f0100ead:	89 c2                	mov    %eax,%edx
f0100eaf:	c1 ea 02             	shr    $0x2,%edx
f0100eb2:	89 15 44 49 11 f0    	mov    %edx,0xf0114944
	npages_basemem = basemem / (PGSIZE / 1024);

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100eb8:	89 c2                	mov    %eax,%edx
f0100eba:	29 da                	sub    %ebx,%edx
f0100ebc:	52                   	push   %edx
f0100ebd:	53                   	push   %ebx
f0100ebe:	50                   	push   %eax
f0100ebf:	68 d0 2a 10 f0       	push   $0xf0102ad0
f0100ec4:	e8 73 06 00 00       	call   f010153c <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0100ec9:	b8 00 10 00 00       	mov    $0x1000,%eax
f0100ece:	e8 aa fa ff ff       	call   f010097d <boot_alloc>
f0100ed3:	a3 48 49 11 f0       	mov    %eax,0xf0114948
	memset(kern_pgdir, 0, PGSIZE);
f0100ed8:	83 c4 0c             	add    $0xc,%esp
f0100edb:	68 00 10 00 00       	push   $0x1000
f0100ee0:	6a 00                	push   $0x0
f0100ee2:	50                   	push   %eax
f0100ee3:	e8 16 11 00 00       	call   f0101ffe <memset>

	size_t PageInfo_size = sizeof(struct PageInfo);
	pages = (struct PageInfo*) boot_alloc(npages * PageInfo_size);
f0100ee8:	a1 44 49 11 f0       	mov    0xf0114944,%eax
f0100eed:	c1 e0 03             	shl    $0x3,%eax
f0100ef0:	e8 88 fa ff ff       	call   f010097d <boot_alloc>
f0100ef5:	a3 4c 49 11 f0       	mov    %eax,0xf011494c
	memset(pages, 0, npages * PageInfo_size);
f0100efa:	83 c4 0c             	add    $0xc,%esp
f0100efd:	8b 0d 44 49 11 f0    	mov    0xf0114944,%ecx
f0100f03:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f0100f0a:	52                   	push   %edx
f0100f0b:	6a 00                	push   $0x0
f0100f0d:	50                   	push   %eax
f0100f0e:	e8 eb 10 00 00       	call   f0101ffe <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0100f13:	a1 48 49 11 f0       	mov    0xf0114948,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100f18:	83 c4 10             	add    $0x10,%esp
f0100f1b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f20:	77 15                	ja     f0100f37 <mem_init+0xce>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f22:	50                   	push   %eax
f0100f23:	68 e8 29 10 f0       	push   $0xf01029e8
f0100f28:	68 9a 00 00 00       	push   $0x9a
f0100f2d:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100f32:	e8 54 f1 ff ff       	call   f010008b <_panic>
f0100f37:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100f3d:	83 ca 05             	or     $0x5,%edx
f0100f40:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0100f46:	e8 6a fd ff ff       	call   f0100cb5 <page_init>

	check_page_free_list(1);
f0100f4b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100f50:	e8 ac fa ff ff       	call   f0100a01 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0100f55:	83 3d 4c 49 11 f0 00 	cmpl   $0x0,0xf011494c
f0100f5c:	75 17                	jne    f0100f75 <mem_init+0x10c>
		panic("'pages' is a null pointer!");
f0100f5e:	83 ec 04             	sub    $0x4,%esp
f0100f61:	68 6a 2c 10 f0       	push   $0xf0102c6a
f0100f66:	68 26 02 00 00       	push   $0x226
f0100f6b:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100f70:	e8 16 f1 ff ff       	call   f010008b <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f75:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0100f7a:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100f7f:	eb 05                	jmp    f0100f86 <mem_init+0x11d>
		++nfree;
f0100f81:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0100f84:	8b 00                	mov    (%eax),%eax
f0100f86:	85 c0                	test   %eax,%eax
f0100f88:	75 f7                	jne    f0100f81 <mem_init+0x118>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0100f8a:	83 ec 0c             	sub    $0xc,%esp
f0100f8d:	6a 00                	push   $0x0
f0100f8f:	e8 0f fe ff ff       	call   f0100da3 <page_alloc>
f0100f94:	89 c7                	mov    %eax,%edi
f0100f96:	83 c4 10             	add    $0x10,%esp
f0100f99:	85 c0                	test   %eax,%eax
f0100f9b:	75 19                	jne    f0100fb6 <mem_init+0x14d>
f0100f9d:	68 85 2c 10 f0       	push   $0xf0102c85
f0100fa2:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100fa7:	68 2e 02 00 00       	push   $0x22e
f0100fac:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100fb1:	e8 d5 f0 ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f0100fb6:	83 ec 0c             	sub    $0xc,%esp
f0100fb9:	6a 00                	push   $0x0
f0100fbb:	e8 e3 fd ff ff       	call   f0100da3 <page_alloc>
f0100fc0:	89 c6                	mov    %eax,%esi
f0100fc2:	83 c4 10             	add    $0x10,%esp
f0100fc5:	85 c0                	test   %eax,%eax
f0100fc7:	75 19                	jne    f0100fe2 <mem_init+0x179>
f0100fc9:	68 9b 2c 10 f0       	push   $0xf0102c9b
f0100fce:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0100fd3:	68 2f 02 00 00       	push   $0x22f
f0100fd8:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0100fdd:	e8 a9 f0 ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0100fe2:	83 ec 0c             	sub    $0xc,%esp
f0100fe5:	6a 00                	push   $0x0
f0100fe7:	e8 b7 fd ff ff       	call   f0100da3 <page_alloc>
f0100fec:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fef:	83 c4 10             	add    $0x10,%esp
f0100ff2:	85 c0                	test   %eax,%eax
f0100ff4:	75 19                	jne    f010100f <mem_init+0x1a6>
f0100ff6:	68 b1 2c 10 f0       	push   $0xf0102cb1
f0100ffb:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0101000:	68 30 02 00 00       	push   $0x230
f0101005:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010100a:	e8 7c f0 ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010100f:	39 f7                	cmp    %esi,%edi
f0101011:	75 19                	jne    f010102c <mem_init+0x1c3>
f0101013:	68 c7 2c 10 f0       	push   $0xf0102cc7
f0101018:	68 b2 2b 10 f0       	push   $0xf0102bb2
f010101d:	68 33 02 00 00       	push   $0x233
f0101022:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101027:	e8 5f f0 ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010102c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010102f:	39 c7                	cmp    %eax,%edi
f0101031:	74 04                	je     f0101037 <mem_init+0x1ce>
f0101033:	39 c6                	cmp    %eax,%esi
f0101035:	75 19                	jne    f0101050 <mem_init+0x1e7>
f0101037:	68 0c 2b 10 f0       	push   $0xf0102b0c
f010103c:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0101041:	68 34 02 00 00       	push   $0x234
f0101046:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010104b:	e8 3b f0 ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101050:	8b 0d 4c 49 11 f0    	mov    0xf011494c,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101056:	8b 15 44 49 11 f0    	mov    0xf0114944,%edx
f010105c:	c1 e2 0c             	shl    $0xc,%edx
f010105f:	89 f8                	mov    %edi,%eax
f0101061:	29 c8                	sub    %ecx,%eax
f0101063:	c1 f8 03             	sar    $0x3,%eax
f0101066:	c1 e0 0c             	shl    $0xc,%eax
f0101069:	39 d0                	cmp    %edx,%eax
f010106b:	72 19                	jb     f0101086 <mem_init+0x21d>
f010106d:	68 d9 2c 10 f0       	push   $0xf0102cd9
f0101072:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0101077:	68 35 02 00 00       	push   $0x235
f010107c:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101081:	e8 05 f0 ff ff       	call   f010008b <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101086:	89 f0                	mov    %esi,%eax
f0101088:	29 c8                	sub    %ecx,%eax
f010108a:	c1 f8 03             	sar    $0x3,%eax
f010108d:	c1 e0 0c             	shl    $0xc,%eax
f0101090:	39 c2                	cmp    %eax,%edx
f0101092:	77 19                	ja     f01010ad <mem_init+0x244>
f0101094:	68 f6 2c 10 f0       	push   $0xf0102cf6
f0101099:	68 b2 2b 10 f0       	push   $0xf0102bb2
f010109e:	68 36 02 00 00       	push   $0x236
f01010a3:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01010a8:	e8 de ef ff ff       	call   f010008b <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01010ad:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010b0:	29 c8                	sub    %ecx,%eax
f01010b2:	c1 f8 03             	sar    $0x3,%eax
f01010b5:	c1 e0 0c             	shl    $0xc,%eax
f01010b8:	39 c2                	cmp    %eax,%edx
f01010ba:	77 19                	ja     f01010d5 <mem_init+0x26c>
f01010bc:	68 13 2d 10 f0       	push   $0xf0102d13
f01010c1:	68 b2 2b 10 f0       	push   $0xf0102bb2
f01010c6:	68 37 02 00 00       	push   $0x237
f01010cb:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01010d0:	e8 b6 ef ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01010d5:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f01010da:	89 45 e0             	mov    %eax,-0x20(%ebp)
	page_free_list = 0;
f01010dd:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f01010e4:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01010e7:	83 ec 0c             	sub    $0xc,%esp
f01010ea:	6a 00                	push   $0x0
f01010ec:	e8 b2 fc ff ff       	call   f0100da3 <page_alloc>
f01010f1:	83 c4 10             	add    $0x10,%esp
f01010f4:	85 c0                	test   %eax,%eax
f01010f6:	74 19                	je     f0101111 <mem_init+0x2a8>
f01010f8:	68 30 2d 10 f0       	push   $0xf0102d30
f01010fd:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0101102:	68 3e 02 00 00       	push   $0x23e
f0101107:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010110c:	e8 7a ef ff ff       	call   f010008b <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101111:	83 ec 0c             	sub    $0xc,%esp
f0101114:	57                   	push   %edi
f0101115:	e8 f9 fc ff ff       	call   f0100e13 <page_free>
	page_free(pp1);
f010111a:	89 34 24             	mov    %esi,(%esp)
f010111d:	e8 f1 fc ff ff       	call   f0100e13 <page_free>
	page_free(pp2);
f0101122:	83 c4 04             	add    $0x4,%esp
f0101125:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101128:	e8 e6 fc ff ff       	call   f0100e13 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010112d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101134:	e8 6a fc ff ff       	call   f0100da3 <page_alloc>
f0101139:	89 c6                	mov    %eax,%esi
f010113b:	83 c4 10             	add    $0x10,%esp
f010113e:	85 c0                	test   %eax,%eax
f0101140:	75 19                	jne    f010115b <mem_init+0x2f2>
f0101142:	68 85 2c 10 f0       	push   $0xf0102c85
f0101147:	68 b2 2b 10 f0       	push   $0xf0102bb2
f010114c:	68 45 02 00 00       	push   $0x245
f0101151:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101156:	e8 30 ef ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010115b:	83 ec 0c             	sub    $0xc,%esp
f010115e:	6a 00                	push   $0x0
f0101160:	e8 3e fc ff ff       	call   f0100da3 <page_alloc>
f0101165:	89 c7                	mov    %eax,%edi
f0101167:	83 c4 10             	add    $0x10,%esp
f010116a:	85 c0                	test   %eax,%eax
f010116c:	75 19                	jne    f0101187 <mem_init+0x31e>
f010116e:	68 9b 2c 10 f0       	push   $0xf0102c9b
f0101173:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0101178:	68 46 02 00 00       	push   $0x246
f010117d:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101182:	e8 04 ef ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f0101187:	83 ec 0c             	sub    $0xc,%esp
f010118a:	6a 00                	push   $0x0
f010118c:	e8 12 fc ff ff       	call   f0100da3 <page_alloc>
f0101191:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101194:	83 c4 10             	add    $0x10,%esp
f0101197:	85 c0                	test   %eax,%eax
f0101199:	75 19                	jne    f01011b4 <mem_init+0x34b>
f010119b:	68 b1 2c 10 f0       	push   $0xf0102cb1
f01011a0:	68 b2 2b 10 f0       	push   $0xf0102bb2
f01011a5:	68 47 02 00 00       	push   $0x247
f01011aa:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01011af:	e8 d7 ee ff ff       	call   f010008b <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01011b4:	39 fe                	cmp    %edi,%esi
f01011b6:	75 19                	jne    f01011d1 <mem_init+0x368>
f01011b8:	68 c7 2c 10 f0       	push   $0xf0102cc7
f01011bd:	68 b2 2b 10 f0       	push   $0xf0102bb2
f01011c2:	68 49 02 00 00       	push   $0x249
f01011c7:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01011cc:	e8 ba ee ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01011d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01011d4:	39 c6                	cmp    %eax,%esi
f01011d6:	74 04                	je     f01011dc <mem_init+0x373>
f01011d8:	39 c7                	cmp    %eax,%edi
f01011da:	75 19                	jne    f01011f5 <mem_init+0x38c>
f01011dc:	68 0c 2b 10 f0       	push   $0xf0102b0c
f01011e1:	68 b2 2b 10 f0       	push   $0xf0102bb2
f01011e6:	68 4a 02 00 00       	push   $0x24a
f01011eb:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01011f0:	e8 96 ee ff ff       	call   f010008b <_panic>
	assert(!page_alloc(0));
f01011f5:	83 ec 0c             	sub    $0xc,%esp
f01011f8:	6a 00                	push   $0x0
f01011fa:	e8 a4 fb ff ff       	call   f0100da3 <page_alloc>
f01011ff:	83 c4 10             	add    $0x10,%esp
f0101202:	85 c0                	test   %eax,%eax
f0101204:	74 19                	je     f010121f <mem_init+0x3b6>
f0101206:	68 30 2d 10 f0       	push   $0xf0102d30
f010120b:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0101210:	68 4b 02 00 00       	push   $0x24b
f0101215:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010121a:	e8 6c ee ff ff       	call   f010008b <_panic>
f010121f:	89 f0                	mov    %esi,%eax
f0101221:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f0101227:	c1 f8 03             	sar    $0x3,%eax
f010122a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010122d:	89 c2                	mov    %eax,%edx
f010122f:	c1 ea 0c             	shr    $0xc,%edx
f0101232:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f0101238:	72 12                	jb     f010124c <mem_init+0x3e3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010123a:	50                   	push   %eax
f010123b:	68 c4 29 10 f0       	push   $0xf01029c4
f0101240:	6a 52                	push   $0x52
f0101242:	68 98 2b 10 f0       	push   $0xf0102b98
f0101247:	e8 3f ee ff ff       	call   f010008b <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010124c:	83 ec 04             	sub    $0x4,%esp
f010124f:	68 00 10 00 00       	push   $0x1000
f0101254:	6a 01                	push   $0x1
f0101256:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010125b:	50                   	push   %eax
f010125c:	e8 9d 0d 00 00       	call   f0101ffe <memset>
	page_free(pp0);
f0101261:	89 34 24             	mov    %esi,(%esp)
f0101264:	e8 aa fb ff ff       	call   f0100e13 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101269:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101270:	e8 2e fb ff ff       	call   f0100da3 <page_alloc>
f0101275:	83 c4 10             	add    $0x10,%esp
f0101278:	85 c0                	test   %eax,%eax
f010127a:	75 19                	jne    f0101295 <mem_init+0x42c>
f010127c:	68 3f 2d 10 f0       	push   $0xf0102d3f
f0101281:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0101286:	68 50 02 00 00       	push   $0x250
f010128b:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101290:	e8 f6 ed ff ff       	call   f010008b <_panic>
	assert(pp && pp0 == pp);
f0101295:	39 c6                	cmp    %eax,%esi
f0101297:	74 19                	je     f01012b2 <mem_init+0x449>
f0101299:	68 5d 2d 10 f0       	push   $0xf0102d5d
f010129e:	68 b2 2b 10 f0       	push   $0xf0102bb2
f01012a3:	68 51 02 00 00       	push   $0x251
f01012a8:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01012ad:	e8 d9 ed ff ff       	call   f010008b <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012b2:	89 f0                	mov    %esi,%eax
f01012b4:	2b 05 4c 49 11 f0    	sub    0xf011494c,%eax
f01012ba:	c1 f8 03             	sar    $0x3,%eax
f01012bd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012c0:	89 c2                	mov    %eax,%edx
f01012c2:	c1 ea 0c             	shr    $0xc,%edx
f01012c5:	3b 15 44 49 11 f0    	cmp    0xf0114944,%edx
f01012cb:	72 12                	jb     f01012df <mem_init+0x476>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012cd:	50                   	push   %eax
f01012ce:	68 c4 29 10 f0       	push   $0xf01029c4
f01012d3:	6a 52                	push   $0x52
f01012d5:	68 98 2b 10 f0       	push   $0xf0102b98
f01012da:	e8 ac ed ff ff       	call   f010008b <_panic>
f01012df:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01012e5:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01012eb:	80 38 00             	cmpb   $0x0,(%eax)
f01012ee:	74 19                	je     f0101309 <mem_init+0x4a0>
f01012f0:	68 6d 2d 10 f0       	push   $0xf0102d6d
f01012f5:	68 b2 2b 10 f0       	push   $0xf0102bb2
f01012fa:	68 54 02 00 00       	push   $0x254
f01012ff:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101304:	e8 82 ed ff ff       	call   f010008b <_panic>
f0101309:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010130c:	39 d0                	cmp    %edx,%eax
f010130e:	75 db                	jne    f01012eb <mem_init+0x482>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101310:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101313:	a3 3c 45 11 f0       	mov    %eax,0xf011453c

	// free the pages we took
	page_free(pp0);
f0101318:	83 ec 0c             	sub    $0xc,%esp
f010131b:	56                   	push   %esi
f010131c:	e8 f2 fa ff ff       	call   f0100e13 <page_free>
	page_free(pp1);
f0101321:	89 3c 24             	mov    %edi,(%esp)
f0101324:	e8 ea fa ff ff       	call   f0100e13 <page_free>
	page_free(pp2);
f0101329:	83 c4 04             	add    $0x4,%esp
f010132c:	ff 75 e4             	pushl  -0x1c(%ebp)
f010132f:	e8 df fa ff ff       	call   f0100e13 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101334:	a1 3c 45 11 f0       	mov    0xf011453c,%eax
f0101339:	83 c4 10             	add    $0x10,%esp
f010133c:	eb 05                	jmp    f0101343 <mem_init+0x4da>
		--nfree;
f010133e:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101341:	8b 00                	mov    (%eax),%eax
f0101343:	85 c0                	test   %eax,%eax
f0101345:	75 f7                	jne    f010133e <mem_init+0x4d5>
		--nfree;
	assert(nfree == 0);
f0101347:	85 db                	test   %ebx,%ebx
f0101349:	74 19                	je     f0101364 <mem_init+0x4fb>
f010134b:	68 77 2d 10 f0       	push   $0xf0102d77
f0101350:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0101355:	68 61 02 00 00       	push   $0x261
f010135a:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010135f:	e8 27 ed ff ff       	call   f010008b <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101364:	83 ec 0c             	sub    $0xc,%esp
f0101367:	68 2c 2b 10 f0       	push   $0xf0102b2c
f010136c:	e8 cb 01 00 00       	call   f010153c <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101371:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101378:	e8 26 fa ff ff       	call   f0100da3 <page_alloc>
f010137d:	89 c3                	mov    %eax,%ebx
f010137f:	83 c4 10             	add    $0x10,%esp
f0101382:	85 c0                	test   %eax,%eax
f0101384:	75 19                	jne    f010139f <mem_init+0x536>
f0101386:	68 85 2c 10 f0       	push   $0xf0102c85
f010138b:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0101390:	68 ba 02 00 00       	push   $0x2ba
f0101395:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010139a:	e8 ec ec ff ff       	call   f010008b <_panic>
	assert((pp1 = page_alloc(0)));
f010139f:	83 ec 0c             	sub    $0xc,%esp
f01013a2:	6a 00                	push   $0x0
f01013a4:	e8 fa f9 ff ff       	call   f0100da3 <page_alloc>
f01013a9:	89 c6                	mov    %eax,%esi
f01013ab:	83 c4 10             	add    $0x10,%esp
f01013ae:	85 c0                	test   %eax,%eax
f01013b0:	75 19                	jne    f01013cb <mem_init+0x562>
f01013b2:	68 9b 2c 10 f0       	push   $0xf0102c9b
f01013b7:	68 b2 2b 10 f0       	push   $0xf0102bb2
f01013bc:	68 bb 02 00 00       	push   $0x2bb
f01013c1:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01013c6:	e8 c0 ec ff ff       	call   f010008b <_panic>
	assert((pp2 = page_alloc(0)));
f01013cb:	83 ec 0c             	sub    $0xc,%esp
f01013ce:	6a 00                	push   $0x0
f01013d0:	e8 ce f9 ff ff       	call   f0100da3 <page_alloc>
f01013d5:	83 c4 10             	add    $0x10,%esp
f01013d8:	85 c0                	test   %eax,%eax
f01013da:	75 19                	jne    f01013f5 <mem_init+0x58c>
f01013dc:	68 b1 2c 10 f0       	push   $0xf0102cb1
f01013e1:	68 b2 2b 10 f0       	push   $0xf0102bb2
f01013e6:	68 bc 02 00 00       	push   $0x2bc
f01013eb:	68 7c 2b 10 f0       	push   $0xf0102b7c
f01013f0:	e8 96 ec ff ff       	call   f010008b <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013f5:	39 f3                	cmp    %esi,%ebx
f01013f7:	75 19                	jne    f0101412 <mem_init+0x5a9>
f01013f9:	68 c7 2c 10 f0       	push   $0xf0102cc7
f01013fe:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0101403:	68 bf 02 00 00       	push   $0x2bf
f0101408:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010140d:	e8 79 ec ff ff       	call   f010008b <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101412:	39 c6                	cmp    %eax,%esi
f0101414:	74 04                	je     f010141a <mem_init+0x5b1>
f0101416:	39 c3                	cmp    %eax,%ebx
f0101418:	75 19                	jne    f0101433 <mem_init+0x5ca>
f010141a:	68 0c 2b 10 f0       	push   $0xf0102b0c
f010141f:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0101424:	68 c0 02 00 00       	push   $0x2c0
f0101429:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010142e:	e8 58 ec ff ff       	call   f010008b <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f0101433:	c7 05 3c 45 11 f0 00 	movl   $0x0,0xf011453c
f010143a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010143d:	83 ec 0c             	sub    $0xc,%esp
f0101440:	6a 00                	push   $0x0
f0101442:	e8 5c f9 ff ff       	call   f0100da3 <page_alloc>
f0101447:	83 c4 10             	add    $0x10,%esp
f010144a:	85 c0                	test   %eax,%eax
f010144c:	74 19                	je     f0101467 <mem_init+0x5fe>
f010144e:	68 30 2d 10 f0       	push   $0xf0102d30
f0101453:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0101458:	68 c7 02 00 00       	push   $0x2c7
f010145d:	68 7c 2b 10 f0       	push   $0xf0102b7c
f0101462:	e8 24 ec ff ff       	call   f010008b <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101467:	68 4c 2b 10 f0       	push   $0xf0102b4c
f010146c:	68 b2 2b 10 f0       	push   $0xf0102bb2
f0101471:	68 cd 02 00 00       	push   $0x2cd
f0101476:	68 7c 2b 10 f0       	push   $0xf0102b7c
f010147b:	e8 0b ec ff ff       	call   f010008b <_panic>

f0101480 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101480:	55                   	push   %ebp
f0101481:	89 e5                	mov    %esp,%ebp
f0101483:	83 ec 08             	sub    $0x8,%esp
f0101486:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101489:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010148d:	83 e8 01             	sub    $0x1,%eax
f0101490:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101494:	66 85 c0             	test   %ax,%ax
f0101497:	75 0c                	jne    f01014a5 <page_decref+0x25>
		page_free(pp);
f0101499:	83 ec 0c             	sub    $0xc,%esp
f010149c:	52                   	push   %edx
f010149d:	e8 71 f9 ff ff       	call   f0100e13 <page_free>
f01014a2:	83 c4 10             	add    $0x10,%esp
}
f01014a5:	c9                   	leave  
f01014a6:	c3                   	ret    

f01014a7 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01014a7:	55                   	push   %ebp
f01014a8:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01014aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01014af:	5d                   	pop    %ebp
f01014b0:	c3                   	ret    

f01014b1 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01014b1:	55                   	push   %ebp
f01014b2:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f01014b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01014b9:	5d                   	pop    %ebp
f01014ba:	c3                   	ret    

f01014bb <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01014bb:	55                   	push   %ebp
f01014bc:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01014be:	b8 00 00 00 00       	mov    $0x0,%eax
f01014c3:	5d                   	pop    %ebp
f01014c4:	c3                   	ret    

f01014c5 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01014c5:	55                   	push   %ebp
f01014c6:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f01014c8:	5d                   	pop    %ebp
f01014c9:	c3                   	ret    

f01014ca <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f01014ca:	55                   	push   %ebp
f01014cb:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01014cd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01014d0:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f01014d3:	5d                   	pop    %ebp
f01014d4:	c3                   	ret    

f01014d5 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01014d5:	55                   	push   %ebp
f01014d6:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01014d8:	ba 70 00 00 00       	mov    $0x70,%edx
f01014dd:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e0:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01014e1:	ba 71 00 00 00       	mov    $0x71,%edx
f01014e6:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01014e7:	0f b6 c0             	movzbl %al,%eax
}
f01014ea:	5d                   	pop    %ebp
f01014eb:	c3                   	ret    

f01014ec <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01014ec:	55                   	push   %ebp
f01014ed:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01014ef:	ba 70 00 00 00       	mov    $0x70,%edx
f01014f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f7:	ee                   	out    %al,(%dx)
f01014f8:	ba 71 00 00 00       	mov    $0x71,%edx
f01014fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101500:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0101501:	5d                   	pop    %ebp
f0101502:	c3                   	ret    

f0101503 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0101503:	55                   	push   %ebp
f0101504:	89 e5                	mov    %esp,%ebp
f0101506:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0101509:	ff 75 08             	pushl  0x8(%ebp)
f010150c:	e8 ef f0 ff ff       	call   f0100600 <cputchar>
	*cnt++;
}
f0101511:	83 c4 10             	add    $0x10,%esp
f0101514:	c9                   	leave  
f0101515:	c3                   	ret    

f0101516 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101516:	55                   	push   %ebp
f0101517:	89 e5                	mov    %esp,%ebp
f0101519:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f010151c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0101523:	ff 75 0c             	pushl  0xc(%ebp)
f0101526:	ff 75 08             	pushl  0x8(%ebp)
f0101529:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010152c:	50                   	push   %eax
f010152d:	68 03 15 10 f0       	push   $0xf0101503
f0101532:	e8 5b 04 00 00       	call   f0101992 <vprintfmt>
	return cnt;
}
f0101537:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010153a:	c9                   	leave  
f010153b:	c3                   	ret    

f010153c <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010153c:	55                   	push   %ebp
f010153d:	89 e5                	mov    %esp,%ebp
f010153f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0101542:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101545:	50                   	push   %eax
f0101546:	ff 75 08             	pushl  0x8(%ebp)
f0101549:	e8 c8 ff ff ff       	call   f0101516 <vcprintf>
	va_end(ap);

	return cnt;
}
f010154e:	c9                   	leave  
f010154f:	c3                   	ret    

f0101550 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0101550:	55                   	push   %ebp
f0101551:	89 e5                	mov    %esp,%ebp
f0101553:	57                   	push   %edi
f0101554:	56                   	push   %esi
f0101555:	53                   	push   %ebx
f0101556:	83 ec 14             	sub    $0x14,%esp
f0101559:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010155c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010155f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101562:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101565:	8b 1a                	mov    (%edx),%ebx
f0101567:	8b 01                	mov    (%ecx),%eax
f0101569:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010156c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0101573:	eb 7f                	jmp    f01015f4 <stab_binsearch+0xa4>
		int true_m = (l + r) / 2, m = true_m;
f0101575:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101578:	01 d8                	add    %ebx,%eax
f010157a:	89 c6                	mov    %eax,%esi
f010157c:	c1 ee 1f             	shr    $0x1f,%esi
f010157f:	01 c6                	add    %eax,%esi
f0101581:	d1 fe                	sar    %esi
f0101583:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0101586:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0101589:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010158c:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010158e:	eb 03                	jmp    f0101593 <stab_binsearch+0x43>
			m--;
f0101590:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101593:	39 c3                	cmp    %eax,%ebx
f0101595:	7f 0d                	jg     f01015a4 <stab_binsearch+0x54>
f0101597:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010159b:	83 ea 0c             	sub    $0xc,%edx
f010159e:	39 f9                	cmp    %edi,%ecx
f01015a0:	75 ee                	jne    f0101590 <stab_binsearch+0x40>
f01015a2:	eb 05                	jmp    f01015a9 <stab_binsearch+0x59>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01015a4:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01015a7:	eb 4b                	jmp    f01015f4 <stab_binsearch+0xa4>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01015a9:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01015ac:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01015af:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01015b3:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01015b6:	76 11                	jbe    f01015c9 <stab_binsearch+0x79>
			*region_left = m;
f01015b8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01015bb:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01015bd:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015c0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01015c7:	eb 2b                	jmp    f01015f4 <stab_binsearch+0xa4>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01015c9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01015cc:	73 14                	jae    f01015e2 <stab_binsearch+0x92>
			*region_right = m - 1;
f01015ce:	83 e8 01             	sub    $0x1,%eax
f01015d1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01015d4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01015d7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015d9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01015e0:	eb 12                	jmp    f01015f4 <stab_binsearch+0xa4>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01015e2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01015e5:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01015e7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01015eb:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01015ed:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01015f4:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01015f7:	0f 8e 78 ff ff ff    	jle    f0101575 <stab_binsearch+0x25>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01015fd:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0101601:	75 0f                	jne    f0101612 <stab_binsearch+0xc2>
		*region_right = *region_left - 1;
f0101603:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101606:	8b 00                	mov    (%eax),%eax
f0101608:	83 e8 01             	sub    $0x1,%eax
f010160b:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010160e:	89 06                	mov    %eax,(%esi)
f0101610:	eb 2c                	jmp    f010163e <stab_binsearch+0xee>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101612:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101615:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0101617:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010161a:	8b 0e                	mov    (%esi),%ecx
f010161c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010161f:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0101622:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0101625:	eb 03                	jmp    f010162a <stab_binsearch+0xda>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0101627:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010162a:	39 c8                	cmp    %ecx,%eax
f010162c:	7e 0b                	jle    f0101639 <stab_binsearch+0xe9>
		     l > *region_left && stabs[l].n_type != type;
f010162e:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0101632:	83 ea 0c             	sub    $0xc,%edx
f0101635:	39 df                	cmp    %ebx,%edi
f0101637:	75 ee                	jne    f0101627 <stab_binsearch+0xd7>
		     l--)
			/* do nothing */;
		*region_left = l;
f0101639:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010163c:	89 06                	mov    %eax,(%esi)
	}
}
f010163e:	83 c4 14             	add    $0x14,%esp
f0101641:	5b                   	pop    %ebx
f0101642:	5e                   	pop    %esi
f0101643:	5f                   	pop    %edi
f0101644:	5d                   	pop    %ebp
f0101645:	c3                   	ret    

f0101646 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0101646:	55                   	push   %ebp
f0101647:	89 e5                	mov    %esp,%ebp
f0101649:	57                   	push   %edi
f010164a:	56                   	push   %esi
f010164b:	53                   	push   %ebx
f010164c:	83 ec 3c             	sub    $0x3c,%esp
f010164f:	8b 75 08             	mov    0x8(%ebp),%esi
f0101652:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0101655:	c7 03 82 2d 10 f0    	movl   $0xf0102d82,(%ebx)
	info->eip_line = 0;
f010165b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0101662:	c7 43 08 82 2d 10 f0 	movl   $0xf0102d82,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0101669:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0101670:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0101673:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010167a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0101680:	76 11                	jbe    f0101693 <debuginfo_eip+0x4d>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0101682:	b8 b0 98 10 f0       	mov    $0xf01098b0,%eax
f0101687:	3d 85 7b 10 f0       	cmp    $0xf0107b85,%eax
f010168c:	77 19                	ja     f01016a7 <debuginfo_eip+0x61>
f010168e:	e9 ba 01 00 00       	jmp    f010184d <debuginfo_eip+0x207>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0101693:	83 ec 04             	sub    $0x4,%esp
f0101696:	68 8c 2d 10 f0       	push   $0xf0102d8c
f010169b:	6a 7f                	push   $0x7f
f010169d:	68 99 2d 10 f0       	push   $0xf0102d99
f01016a2:	e8 e4 e9 ff ff       	call   f010008b <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01016a7:	80 3d af 98 10 f0 00 	cmpb   $0x0,0xf01098af
f01016ae:	0f 85 a0 01 00 00    	jne    f0101854 <debuginfo_eip+0x20e>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01016b4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01016bb:	b8 84 7b 10 f0       	mov    $0xf0107b84,%eax
f01016c0:	2d b8 2f 10 f0       	sub    $0xf0102fb8,%eax
f01016c5:	c1 f8 02             	sar    $0x2,%eax
f01016c8:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01016ce:	83 e8 01             	sub    $0x1,%eax
f01016d1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01016d4:	83 ec 08             	sub    $0x8,%esp
f01016d7:	56                   	push   %esi
f01016d8:	6a 64                	push   $0x64
f01016da:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01016dd:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01016e0:	b8 b8 2f 10 f0       	mov    $0xf0102fb8,%eax
f01016e5:	e8 66 fe ff ff       	call   f0101550 <stab_binsearch>
	if (lfile == 0)
f01016ea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01016ed:	83 c4 10             	add    $0x10,%esp
f01016f0:	85 c0                	test   %eax,%eax
f01016f2:	0f 84 63 01 00 00    	je     f010185b <debuginfo_eip+0x215>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01016f8:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01016fb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01016fe:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101701:	83 ec 08             	sub    $0x8,%esp
f0101704:	56                   	push   %esi
f0101705:	6a 24                	push   $0x24
f0101707:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010170a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010170d:	b8 b8 2f 10 f0       	mov    $0xf0102fb8,%eax
f0101712:	e8 39 fe ff ff       	call   f0101550 <stab_binsearch>

	if (lfun <= rfun) {
f0101717:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010171a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010171d:	83 c4 10             	add    $0x10,%esp
f0101720:	39 d0                	cmp    %edx,%eax
f0101722:	7f 40                	jg     f0101764 <debuginfo_eip+0x11e>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0101724:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0101727:	c1 e1 02             	shl    $0x2,%ecx
f010172a:	8d b9 b8 2f 10 f0    	lea    -0xfefd048(%ecx),%edi
f0101730:	89 7d c4             	mov    %edi,-0x3c(%ebp)
f0101733:	8b b9 b8 2f 10 f0    	mov    -0xfefd048(%ecx),%edi
f0101739:	b9 b0 98 10 f0       	mov    $0xf01098b0,%ecx
f010173e:	81 e9 85 7b 10 f0    	sub    $0xf0107b85,%ecx
f0101744:	39 cf                	cmp    %ecx,%edi
f0101746:	73 09                	jae    f0101751 <debuginfo_eip+0x10b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101748:	81 c7 85 7b 10 f0    	add    $0xf0107b85,%edi
f010174e:	89 7b 08             	mov    %edi,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101751:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0101754:	8b 4f 08             	mov    0x8(%edi),%ecx
f0101757:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010175a:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010175c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010175f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101762:	eb 0f                	jmp    f0101773 <debuginfo_eip+0x12d>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101764:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0101767:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010176a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010176d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101770:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101773:	83 ec 08             	sub    $0x8,%esp
f0101776:	6a 3a                	push   $0x3a
f0101778:	ff 73 08             	pushl  0x8(%ebx)
f010177b:	e8 62 08 00 00       	call   f0101fe2 <strfind>
f0101780:	2b 43 08             	sub    0x8(%ebx),%eax
f0101783:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0101786:	83 c4 08             	add    $0x8,%esp
f0101789:	56                   	push   %esi
f010178a:	6a 44                	push   $0x44
f010178c:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f010178f:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0101792:	b8 b8 2f 10 f0       	mov    $0xf0102fb8,%eax
f0101797:	e8 b4 fd ff ff       	call   f0101550 <stab_binsearch>
	if(lline <= rline)
f010179c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010179f:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01017a2:	83 c4 10             	add    $0x10,%esp
f01017a5:	39 d0                	cmp    %edx,%eax
f01017a7:	7f 10                	jg     f01017b9 <debuginfo_eip+0x173>
	{
		info -> eip_line = stabs[rline].n_desc;
f01017a9:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01017ac:	0f b7 14 95 be 2f 10 	movzwl -0xfefd042(,%edx,4),%edx
f01017b3:	f0 
f01017b4:	89 53 04             	mov    %edx,0x4(%ebx)
f01017b7:	eb 07                	jmp    f01017c0 <debuginfo_eip+0x17a>
	}
	else
		info -> eip_line = -1;
f01017b9:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01017c0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01017c3:	89 c2                	mov    %eax,%edx
f01017c5:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01017c8:	8d 04 85 b8 2f 10 f0 	lea    -0xfefd048(,%eax,4),%eax
f01017cf:	eb 06                	jmp    f01017d7 <debuginfo_eip+0x191>
f01017d1:	83 ea 01             	sub    $0x1,%edx
f01017d4:	83 e8 0c             	sub    $0xc,%eax
f01017d7:	39 d7                	cmp    %edx,%edi
f01017d9:	7f 34                	jg     f010180f <debuginfo_eip+0x1c9>
	       && stabs[lline].n_type != N_SOL
f01017db:	0f b6 48 04          	movzbl 0x4(%eax),%ecx
f01017df:	80 f9 84             	cmp    $0x84,%cl
f01017e2:	74 0b                	je     f01017ef <debuginfo_eip+0x1a9>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01017e4:	80 f9 64             	cmp    $0x64,%cl
f01017e7:	75 e8                	jne    f01017d1 <debuginfo_eip+0x18b>
f01017e9:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01017ed:	74 e2                	je     f01017d1 <debuginfo_eip+0x18b>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01017ef:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01017f2:	8b 14 85 b8 2f 10 f0 	mov    -0xfefd048(,%eax,4),%edx
f01017f9:	b8 b0 98 10 f0       	mov    $0xf01098b0,%eax
f01017fe:	2d 85 7b 10 f0       	sub    $0xf0107b85,%eax
f0101803:	39 c2                	cmp    %eax,%edx
f0101805:	73 08                	jae    f010180f <debuginfo_eip+0x1c9>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101807:	81 c2 85 7b 10 f0    	add    $0xf0107b85,%edx
f010180d:	89 13                	mov    %edx,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010180f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101812:	8b 75 d8             	mov    -0x28(%ebp),%esi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101815:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010181a:	39 f2                	cmp    %esi,%edx
f010181c:	7d 49                	jge    f0101867 <debuginfo_eip+0x221>
		for (lline = lfun + 1;
f010181e:	83 c2 01             	add    $0x1,%edx
f0101821:	89 d0                	mov    %edx,%eax
f0101823:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0101826:	8d 14 95 b8 2f 10 f0 	lea    -0xfefd048(,%edx,4),%edx
f010182d:	eb 04                	jmp    f0101833 <debuginfo_eip+0x1ed>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f010182f:	83 43 14 01          	addl   $0x1,0x14(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0101833:	39 c6                	cmp    %eax,%esi
f0101835:	7e 2b                	jle    f0101862 <debuginfo_eip+0x21c>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101837:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010183b:	83 c0 01             	add    $0x1,%eax
f010183e:	83 c2 0c             	add    $0xc,%edx
f0101841:	80 f9 a0             	cmp    $0xa0,%cl
f0101844:	74 e9                	je     f010182f <debuginfo_eip+0x1e9>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101846:	b8 00 00 00 00       	mov    $0x0,%eax
f010184b:	eb 1a                	jmp    f0101867 <debuginfo_eip+0x221>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010184d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101852:	eb 13                	jmp    f0101867 <debuginfo_eip+0x221>
f0101854:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101859:	eb 0c                	jmp    f0101867 <debuginfo_eip+0x221>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f010185b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101860:	eb 05                	jmp    f0101867 <debuginfo_eip+0x221>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101862:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101867:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010186a:	5b                   	pop    %ebx
f010186b:	5e                   	pop    %esi
f010186c:	5f                   	pop    %edi
f010186d:	5d                   	pop    %ebp
f010186e:	c3                   	ret    

f010186f <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f010186f:	55                   	push   %ebp
f0101870:	89 e5                	mov    %esp,%ebp
f0101872:	57                   	push   %edi
f0101873:	56                   	push   %esi
f0101874:	53                   	push   %ebx
f0101875:	83 ec 1c             	sub    $0x1c,%esp
f0101878:	89 c7                	mov    %eax,%edi
f010187a:	89 d6                	mov    %edx,%esi
f010187c:	8b 45 08             	mov    0x8(%ebp),%eax
f010187f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101882:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101885:	89 55 dc             	mov    %edx,-0x24(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101888:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010188b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101890:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0101893:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f0101896:	39 d3                	cmp    %edx,%ebx
f0101898:	72 05                	jb     f010189f <printnum+0x30>
f010189a:	39 45 10             	cmp    %eax,0x10(%ebp)
f010189d:	77 45                	ja     f01018e4 <printnum+0x75>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010189f:	83 ec 0c             	sub    $0xc,%esp
f01018a2:	ff 75 18             	pushl  0x18(%ebp)
f01018a5:	8b 45 14             	mov    0x14(%ebp),%eax
f01018a8:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01018ab:	53                   	push   %ebx
f01018ac:	ff 75 10             	pushl  0x10(%ebp)
f01018af:	83 ec 08             	sub    $0x8,%esp
f01018b2:	ff 75 e4             	pushl  -0x1c(%ebp)
f01018b5:	ff 75 e0             	pushl  -0x20(%ebp)
f01018b8:	ff 75 dc             	pushl  -0x24(%ebp)
f01018bb:	ff 75 d8             	pushl  -0x28(%ebp)
f01018be:	e8 3d 09 00 00       	call   f0102200 <__udivdi3>
f01018c3:	83 c4 18             	add    $0x18,%esp
f01018c6:	52                   	push   %edx
f01018c7:	50                   	push   %eax
f01018c8:	89 f2                	mov    %esi,%edx
f01018ca:	89 f8                	mov    %edi,%eax
f01018cc:	e8 9e ff ff ff       	call   f010186f <printnum>
f01018d1:	83 c4 20             	add    $0x20,%esp
f01018d4:	eb 18                	jmp    f01018ee <printnum+0x7f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01018d6:	83 ec 08             	sub    $0x8,%esp
f01018d9:	56                   	push   %esi
f01018da:	ff 75 18             	pushl  0x18(%ebp)
f01018dd:	ff d7                	call   *%edi
f01018df:	83 c4 10             	add    $0x10,%esp
f01018e2:	eb 03                	jmp    f01018e7 <printnum+0x78>
f01018e4:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01018e7:	83 eb 01             	sub    $0x1,%ebx
f01018ea:	85 db                	test   %ebx,%ebx
f01018ec:	7f e8                	jg     f01018d6 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01018ee:	83 ec 08             	sub    $0x8,%esp
f01018f1:	56                   	push   %esi
f01018f2:	83 ec 04             	sub    $0x4,%esp
f01018f5:	ff 75 e4             	pushl  -0x1c(%ebp)
f01018f8:	ff 75 e0             	pushl  -0x20(%ebp)
f01018fb:	ff 75 dc             	pushl  -0x24(%ebp)
f01018fe:	ff 75 d8             	pushl  -0x28(%ebp)
f0101901:	e8 2a 0a 00 00       	call   f0102330 <__umoddi3>
f0101906:	83 c4 14             	add    $0x14,%esp
f0101909:	0f be 80 a7 2d 10 f0 	movsbl -0xfefd259(%eax),%eax
f0101910:	50                   	push   %eax
f0101911:	ff d7                	call   *%edi
}
f0101913:	83 c4 10             	add    $0x10,%esp
f0101916:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101919:	5b                   	pop    %ebx
f010191a:	5e                   	pop    %esi
f010191b:	5f                   	pop    %edi
f010191c:	5d                   	pop    %ebp
f010191d:	c3                   	ret    

f010191e <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010191e:	55                   	push   %ebp
f010191f:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0101921:	83 fa 01             	cmp    $0x1,%edx
f0101924:	7e 0e                	jle    f0101934 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0101926:	8b 10                	mov    (%eax),%edx
f0101928:	8d 4a 08             	lea    0x8(%edx),%ecx
f010192b:	89 08                	mov    %ecx,(%eax)
f010192d:	8b 02                	mov    (%edx),%eax
f010192f:	8b 52 04             	mov    0x4(%edx),%edx
f0101932:	eb 22                	jmp    f0101956 <getuint+0x38>
	else if (lflag)
f0101934:	85 d2                	test   %edx,%edx
f0101936:	74 10                	je     f0101948 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0101938:	8b 10                	mov    (%eax),%edx
f010193a:	8d 4a 04             	lea    0x4(%edx),%ecx
f010193d:	89 08                	mov    %ecx,(%eax)
f010193f:	8b 02                	mov    (%edx),%eax
f0101941:	ba 00 00 00 00       	mov    $0x0,%edx
f0101946:	eb 0e                	jmp    f0101956 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0101948:	8b 10                	mov    (%eax),%edx
f010194a:	8d 4a 04             	lea    0x4(%edx),%ecx
f010194d:	89 08                	mov    %ecx,(%eax)
f010194f:	8b 02                	mov    (%edx),%eax
f0101951:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0101956:	5d                   	pop    %ebp
f0101957:	c3                   	ret    

f0101958 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101958:	55                   	push   %ebp
f0101959:	89 e5                	mov    %esp,%ebp
f010195b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010195e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0101962:	8b 10                	mov    (%eax),%edx
f0101964:	3b 50 04             	cmp    0x4(%eax),%edx
f0101967:	73 0a                	jae    f0101973 <sprintputch+0x1b>
		*b->buf++ = ch;
f0101969:	8d 4a 01             	lea    0x1(%edx),%ecx
f010196c:	89 08                	mov    %ecx,(%eax)
f010196e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101971:	88 02                	mov    %al,(%edx)
}
f0101973:	5d                   	pop    %ebp
f0101974:	c3                   	ret    

f0101975 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101975:	55                   	push   %ebp
f0101976:	89 e5                	mov    %esp,%ebp
f0101978:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f010197b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010197e:	50                   	push   %eax
f010197f:	ff 75 10             	pushl  0x10(%ebp)
f0101982:	ff 75 0c             	pushl  0xc(%ebp)
f0101985:	ff 75 08             	pushl  0x8(%ebp)
f0101988:	e8 05 00 00 00       	call   f0101992 <vprintfmt>
	va_end(ap);
}
f010198d:	83 c4 10             	add    $0x10,%esp
f0101990:	c9                   	leave  
f0101991:	c3                   	ret    

f0101992 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0101992:	55                   	push   %ebp
f0101993:	89 e5                	mov    %esp,%ebp
f0101995:	57                   	push   %edi
f0101996:	56                   	push   %esi
f0101997:	53                   	push   %ebx
f0101998:	83 ec 2c             	sub    $0x2c,%esp
f010199b:	8b 75 08             	mov    0x8(%ebp),%esi
f010199e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01019a1:	8b 7d 10             	mov    0x10(%ebp),%edi
f01019a4:	eb 12                	jmp    f01019b8 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01019a6:	85 c0                	test   %eax,%eax
f01019a8:	0f 84 89 03 00 00    	je     f0101d37 <vprintfmt+0x3a5>
				return;
			putch(ch, putdat);
f01019ae:	83 ec 08             	sub    $0x8,%esp
f01019b1:	53                   	push   %ebx
f01019b2:	50                   	push   %eax
f01019b3:	ff d6                	call   *%esi
f01019b5:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01019b8:	83 c7 01             	add    $0x1,%edi
f01019bb:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01019bf:	83 f8 25             	cmp    $0x25,%eax
f01019c2:	75 e2                	jne    f01019a6 <vprintfmt+0x14>
f01019c4:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f01019c8:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f01019cf:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01019d6:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f01019dd:	ba 00 00 00 00       	mov    $0x0,%edx
f01019e2:	eb 07                	jmp    f01019eb <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019e4:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f01019e7:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01019eb:	8d 47 01             	lea    0x1(%edi),%eax
f01019ee:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01019f1:	0f b6 07             	movzbl (%edi),%eax
f01019f4:	0f b6 c8             	movzbl %al,%ecx
f01019f7:	83 e8 23             	sub    $0x23,%eax
f01019fa:	3c 55                	cmp    $0x55,%al
f01019fc:	0f 87 1a 03 00 00    	ja     f0101d1c <vprintfmt+0x38a>
f0101a02:	0f b6 c0             	movzbl %al,%eax
f0101a05:	ff 24 85 34 2e 10 f0 	jmp    *-0xfefd1cc(,%eax,4)
f0101a0c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101a0f:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0101a13:	eb d6                	jmp    f01019eb <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a15:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a18:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a1d:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101a20:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0101a23:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0101a27:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0101a2a:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0101a2d:	83 fa 09             	cmp    $0x9,%edx
f0101a30:	77 39                	ja     f0101a6b <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0101a32:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0101a35:	eb e9                	jmp    f0101a20 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101a37:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a3a:	8d 48 04             	lea    0x4(%eax),%ecx
f0101a3d:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101a40:	8b 00                	mov    (%eax),%eax
f0101a42:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a45:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101a48:	eb 27                	jmp    f0101a71 <vprintfmt+0xdf>
f0101a4a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101a4d:	85 c0                	test   %eax,%eax
f0101a4f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101a54:	0f 49 c8             	cmovns %eax,%ecx
f0101a57:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a5a:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101a5d:	eb 8c                	jmp    f01019eb <vprintfmt+0x59>
f0101a5f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0101a62:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101a69:	eb 80                	jmp    f01019eb <vprintfmt+0x59>
f0101a6b:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101a6e:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0101a71:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101a75:	0f 89 70 ff ff ff    	jns    f01019eb <vprintfmt+0x59>
				width = precision, precision = -1;
f0101a7b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a7e:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101a81:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0101a88:	e9 5e ff ff ff       	jmp    f01019eb <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101a8d:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101a90:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101a93:	e9 53 ff ff ff       	jmp    f01019eb <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0101a98:	8b 45 14             	mov    0x14(%ebp),%eax
f0101a9b:	8d 50 04             	lea    0x4(%eax),%edx
f0101a9e:	89 55 14             	mov    %edx,0x14(%ebp)
f0101aa1:	83 ec 08             	sub    $0x8,%esp
f0101aa4:	53                   	push   %ebx
f0101aa5:	ff 30                	pushl  (%eax)
f0101aa7:	ff d6                	call   *%esi
			break;
f0101aa9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101aac:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101aaf:	e9 04 ff ff ff       	jmp    f01019b8 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0101ab4:	8b 45 14             	mov    0x14(%ebp),%eax
f0101ab7:	8d 50 04             	lea    0x4(%eax),%edx
f0101aba:	89 55 14             	mov    %edx,0x14(%ebp)
f0101abd:	8b 00                	mov    (%eax),%eax
f0101abf:	99                   	cltd   
f0101ac0:	31 d0                	xor    %edx,%eax
f0101ac2:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101ac4:	83 f8 06             	cmp    $0x6,%eax
f0101ac7:	7f 0b                	jg     f0101ad4 <vprintfmt+0x142>
f0101ac9:	8b 14 85 8c 2f 10 f0 	mov    -0xfefd074(,%eax,4),%edx
f0101ad0:	85 d2                	test   %edx,%edx
f0101ad2:	75 18                	jne    f0101aec <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0101ad4:	50                   	push   %eax
f0101ad5:	68 bf 2d 10 f0       	push   $0xf0102dbf
f0101ada:	53                   	push   %ebx
f0101adb:	56                   	push   %esi
f0101adc:	e8 94 fe ff ff       	call   f0101975 <printfmt>
f0101ae1:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101ae4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0101ae7:	e9 cc fe ff ff       	jmp    f01019b8 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0101aec:	52                   	push   %edx
f0101aed:	68 c4 2b 10 f0       	push   $0xf0102bc4
f0101af2:	53                   	push   %ebx
f0101af3:	56                   	push   %esi
f0101af4:	e8 7c fe ff ff       	call   f0101975 <printfmt>
f0101af9:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101afc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101aff:	e9 b4 fe ff ff       	jmp    f01019b8 <vprintfmt+0x26>
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0101b04:	8b 45 14             	mov    0x14(%ebp),%eax
f0101b07:	8d 50 04             	lea    0x4(%eax),%edx
f0101b0a:	89 55 14             	mov    %edx,0x14(%ebp)
f0101b0d:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101b0f:	85 ff                	test   %edi,%edi
f0101b11:	b8 b8 2d 10 f0       	mov    $0xf0102db8,%eax
f0101b16:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101b19:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101b1d:	0f 8e 94 00 00 00    	jle    f0101bb7 <vprintfmt+0x225>
f0101b23:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0101b27:	0f 84 98 00 00 00    	je     f0101bc5 <vprintfmt+0x233>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101b2d:	83 ec 08             	sub    $0x8,%esp
f0101b30:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b33:	57                   	push   %edi
f0101b34:	e8 5f 03 00 00       	call   f0101e98 <strnlen>
f0101b39:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101b3c:	29 c1                	sub    %eax,%ecx
f0101b3e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101b41:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0101b44:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101b48:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101b4b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101b4e:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101b50:	eb 0f                	jmp    f0101b61 <vprintfmt+0x1cf>
					putch(padc, putdat);
f0101b52:	83 ec 08             	sub    $0x8,%esp
f0101b55:	53                   	push   %ebx
f0101b56:	ff 75 e0             	pushl  -0x20(%ebp)
f0101b59:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0101b5b:	83 ef 01             	sub    $0x1,%edi
f0101b5e:	83 c4 10             	add    $0x10,%esp
f0101b61:	85 ff                	test   %edi,%edi
f0101b63:	7f ed                	jg     f0101b52 <vprintfmt+0x1c0>
f0101b65:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101b68:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0101b6b:	85 c9                	test   %ecx,%ecx
f0101b6d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b72:	0f 49 c1             	cmovns %ecx,%eax
f0101b75:	29 c1                	sub    %eax,%ecx
f0101b77:	89 75 08             	mov    %esi,0x8(%ebp)
f0101b7a:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101b7d:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101b80:	89 cb                	mov    %ecx,%ebx
f0101b82:	eb 4d                	jmp    f0101bd1 <vprintfmt+0x23f>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0101b84:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101b88:	74 1b                	je     f0101ba5 <vprintfmt+0x213>
f0101b8a:	0f be c0             	movsbl %al,%eax
f0101b8d:	83 e8 20             	sub    $0x20,%eax
f0101b90:	83 f8 5e             	cmp    $0x5e,%eax
f0101b93:	76 10                	jbe    f0101ba5 <vprintfmt+0x213>
					putch('?', putdat);
f0101b95:	83 ec 08             	sub    $0x8,%esp
f0101b98:	ff 75 0c             	pushl  0xc(%ebp)
f0101b9b:	6a 3f                	push   $0x3f
f0101b9d:	ff 55 08             	call   *0x8(%ebp)
f0101ba0:	83 c4 10             	add    $0x10,%esp
f0101ba3:	eb 0d                	jmp    f0101bb2 <vprintfmt+0x220>
				else
					putch(ch, putdat);
f0101ba5:	83 ec 08             	sub    $0x8,%esp
f0101ba8:	ff 75 0c             	pushl  0xc(%ebp)
f0101bab:	52                   	push   %edx
f0101bac:	ff 55 08             	call   *0x8(%ebp)
f0101baf:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101bb2:	83 eb 01             	sub    $0x1,%ebx
f0101bb5:	eb 1a                	jmp    f0101bd1 <vprintfmt+0x23f>
f0101bb7:	89 75 08             	mov    %esi,0x8(%ebp)
f0101bba:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101bbd:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101bc0:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101bc3:	eb 0c                	jmp    f0101bd1 <vprintfmt+0x23f>
f0101bc5:	89 75 08             	mov    %esi,0x8(%ebp)
f0101bc8:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0101bcb:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0101bce:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101bd1:	83 c7 01             	add    $0x1,%edi
f0101bd4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101bd8:	0f be d0             	movsbl %al,%edx
f0101bdb:	85 d2                	test   %edx,%edx
f0101bdd:	74 23                	je     f0101c02 <vprintfmt+0x270>
f0101bdf:	85 f6                	test   %esi,%esi
f0101be1:	78 a1                	js     f0101b84 <vprintfmt+0x1f2>
f0101be3:	83 ee 01             	sub    $0x1,%esi
f0101be6:	79 9c                	jns    f0101b84 <vprintfmt+0x1f2>
f0101be8:	89 df                	mov    %ebx,%edi
f0101bea:	8b 75 08             	mov    0x8(%ebp),%esi
f0101bed:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101bf0:	eb 18                	jmp    f0101c0a <vprintfmt+0x278>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0101bf2:	83 ec 08             	sub    $0x8,%esp
f0101bf5:	53                   	push   %ebx
f0101bf6:	6a 20                	push   $0x20
f0101bf8:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101bfa:	83 ef 01             	sub    $0x1,%edi
f0101bfd:	83 c4 10             	add    $0x10,%esp
f0101c00:	eb 08                	jmp    f0101c0a <vprintfmt+0x278>
f0101c02:	89 df                	mov    %ebx,%edi
f0101c04:	8b 75 08             	mov    0x8(%ebp),%esi
f0101c07:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101c0a:	85 ff                	test   %edi,%edi
f0101c0c:	7f e4                	jg     f0101bf2 <vprintfmt+0x260>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101c0e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101c11:	e9 a2 fd ff ff       	jmp    f01019b8 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101c16:	83 fa 01             	cmp    $0x1,%edx
f0101c19:	7e 16                	jle    f0101c31 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101c1b:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c1e:	8d 50 08             	lea    0x8(%eax),%edx
f0101c21:	89 55 14             	mov    %edx,0x14(%ebp)
f0101c24:	8b 50 04             	mov    0x4(%eax),%edx
f0101c27:	8b 00                	mov    (%eax),%eax
f0101c29:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c2c:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101c2f:	eb 32                	jmp    f0101c63 <vprintfmt+0x2d1>
	else if (lflag)
f0101c31:	85 d2                	test   %edx,%edx
f0101c33:	74 18                	je     f0101c4d <vprintfmt+0x2bb>
		return va_arg(*ap, long);
f0101c35:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c38:	8d 50 04             	lea    0x4(%eax),%edx
f0101c3b:	89 55 14             	mov    %edx,0x14(%ebp)
f0101c3e:	8b 00                	mov    (%eax),%eax
f0101c40:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c43:	89 c1                	mov    %eax,%ecx
f0101c45:	c1 f9 1f             	sar    $0x1f,%ecx
f0101c48:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0101c4b:	eb 16                	jmp    f0101c63 <vprintfmt+0x2d1>
	else
		return va_arg(*ap, int);
f0101c4d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101c50:	8d 50 04             	lea    0x4(%eax),%edx
f0101c53:	89 55 14             	mov    %edx,0x14(%ebp)
f0101c56:	8b 00                	mov    (%eax),%eax
f0101c58:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101c5b:	89 c1                	mov    %eax,%ecx
f0101c5d:	c1 f9 1f             	sar    $0x1f,%ecx
f0101c60:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0101c63:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101c66:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0101c69:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101c6e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101c72:	79 74                	jns    f0101ce8 <vprintfmt+0x356>
				putch('-', putdat);
f0101c74:	83 ec 08             	sub    $0x8,%esp
f0101c77:	53                   	push   %ebx
f0101c78:	6a 2d                	push   $0x2d
f0101c7a:	ff d6                	call   *%esi
				num = -(long long) num;
f0101c7c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101c7f:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101c82:	f7 d8                	neg    %eax
f0101c84:	83 d2 00             	adc    $0x0,%edx
f0101c87:	f7 da                	neg    %edx
f0101c89:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0101c8c:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101c91:	eb 55                	jmp    f0101ce8 <vprintfmt+0x356>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101c93:	8d 45 14             	lea    0x14(%ebp),%eax
f0101c96:	e8 83 fc ff ff       	call   f010191e <getuint>
			base = 10;
f0101c9b:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0101ca0:	eb 46                	jmp    f0101ce8 <vprintfmt+0x356>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0101ca2:	8d 45 14             	lea    0x14(%ebp),%eax
f0101ca5:	e8 74 fc ff ff       	call   f010191e <getuint>
			base = 8;
f0101caa:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0101caf:	eb 37                	jmp    f0101ce8 <vprintfmt+0x356>
			//break;

		// pointer
		case 'p':
			putch('0', putdat);
f0101cb1:	83 ec 08             	sub    $0x8,%esp
f0101cb4:	53                   	push   %ebx
f0101cb5:	6a 30                	push   $0x30
f0101cb7:	ff d6                	call   *%esi
			putch('x', putdat);
f0101cb9:	83 c4 08             	add    $0x8,%esp
f0101cbc:	53                   	push   %ebx
f0101cbd:	6a 78                	push   $0x78
f0101cbf:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0101cc1:	8b 45 14             	mov    0x14(%ebp),%eax
f0101cc4:	8d 50 04             	lea    0x4(%eax),%edx
f0101cc7:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101cca:	8b 00                	mov    (%eax),%eax
f0101ccc:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0101cd1:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0101cd4:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0101cd9:	eb 0d                	jmp    f0101ce8 <vprintfmt+0x356>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101cdb:	8d 45 14             	lea    0x14(%ebp),%eax
f0101cde:	e8 3b fc ff ff       	call   f010191e <getuint>
			base = 16;
f0101ce3:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101ce8:	83 ec 0c             	sub    $0xc,%esp
f0101ceb:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101cef:	57                   	push   %edi
f0101cf0:	ff 75 e0             	pushl  -0x20(%ebp)
f0101cf3:	51                   	push   %ecx
f0101cf4:	52                   	push   %edx
f0101cf5:	50                   	push   %eax
f0101cf6:	89 da                	mov    %ebx,%edx
f0101cf8:	89 f0                	mov    %esi,%eax
f0101cfa:	e8 70 fb ff ff       	call   f010186f <printnum>
			break;
f0101cff:	83 c4 20             	add    $0x20,%esp
f0101d02:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101d05:	e9 ae fc ff ff       	jmp    f01019b8 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101d0a:	83 ec 08             	sub    $0x8,%esp
f0101d0d:	53                   	push   %ebx
f0101d0e:	51                   	push   %ecx
f0101d0f:	ff d6                	call   *%esi
			break;
f0101d11:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101d14:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101d17:	e9 9c fc ff ff       	jmp    f01019b8 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101d1c:	83 ec 08             	sub    $0x8,%esp
f0101d1f:	53                   	push   %ebx
f0101d20:	6a 25                	push   $0x25
f0101d22:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101d24:	83 c4 10             	add    $0x10,%esp
f0101d27:	eb 03                	jmp    f0101d2c <vprintfmt+0x39a>
f0101d29:	83 ef 01             	sub    $0x1,%edi
f0101d2c:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101d30:	75 f7                	jne    f0101d29 <vprintfmt+0x397>
f0101d32:	e9 81 fc ff ff       	jmp    f01019b8 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0101d37:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101d3a:	5b                   	pop    %ebx
f0101d3b:	5e                   	pop    %esi
f0101d3c:	5f                   	pop    %edi
f0101d3d:	5d                   	pop    %ebp
f0101d3e:	c3                   	ret    

f0101d3f <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101d3f:	55                   	push   %ebp
f0101d40:	89 e5                	mov    %esp,%ebp
f0101d42:	83 ec 18             	sub    $0x18,%esp
f0101d45:	8b 45 08             	mov    0x8(%ebp),%eax
f0101d48:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101d4b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101d4e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101d52:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101d55:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101d5c:	85 c0                	test   %eax,%eax
f0101d5e:	74 26                	je     f0101d86 <vsnprintf+0x47>
f0101d60:	85 d2                	test   %edx,%edx
f0101d62:	7e 22                	jle    f0101d86 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101d64:	ff 75 14             	pushl  0x14(%ebp)
f0101d67:	ff 75 10             	pushl  0x10(%ebp)
f0101d6a:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0101d6d:	50                   	push   %eax
f0101d6e:	68 58 19 10 f0       	push   $0xf0101958
f0101d73:	e8 1a fc ff ff       	call   f0101992 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101d78:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0101d7b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101d7e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101d81:	83 c4 10             	add    $0x10,%esp
f0101d84:	eb 05                	jmp    f0101d8b <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101d86:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0101d8b:	c9                   	leave  
f0101d8c:	c3                   	ret    

f0101d8d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101d8d:	55                   	push   %ebp
f0101d8e:	89 e5                	mov    %esp,%ebp
f0101d90:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101d93:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101d96:	50                   	push   %eax
f0101d97:	ff 75 10             	pushl  0x10(%ebp)
f0101d9a:	ff 75 0c             	pushl  0xc(%ebp)
f0101d9d:	ff 75 08             	pushl  0x8(%ebp)
f0101da0:	e8 9a ff ff ff       	call   f0101d3f <vsnprintf>
	va_end(ap);

	return rc;
}
f0101da5:	c9                   	leave  
f0101da6:	c3                   	ret    

f0101da7 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101da7:	55                   	push   %ebp
f0101da8:	89 e5                	mov    %esp,%ebp
f0101daa:	57                   	push   %edi
f0101dab:	56                   	push   %esi
f0101dac:	53                   	push   %ebx
f0101dad:	83 ec 0c             	sub    $0xc,%esp
f0101db0:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101db3:	85 c0                	test   %eax,%eax
f0101db5:	74 11                	je     f0101dc8 <readline+0x21>
		cprintf("%s", prompt);
f0101db7:	83 ec 08             	sub    $0x8,%esp
f0101dba:	50                   	push   %eax
f0101dbb:	68 c4 2b 10 f0       	push   $0xf0102bc4
f0101dc0:	e8 77 f7 ff ff       	call   f010153c <cprintf>
f0101dc5:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101dc8:	83 ec 0c             	sub    $0xc,%esp
f0101dcb:	6a 00                	push   $0x0
f0101dcd:	e8 4f e8 ff ff       	call   f0100621 <iscons>
f0101dd2:	89 c7                	mov    %eax,%edi
f0101dd4:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0101dd7:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101ddc:	e8 2f e8 ff ff       	call   f0100610 <getchar>
f0101de1:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0101de3:	85 c0                	test   %eax,%eax
f0101de5:	79 18                	jns    f0101dff <readline+0x58>
			cprintf("read error: %e\n", c);
f0101de7:	83 ec 08             	sub    $0x8,%esp
f0101dea:	50                   	push   %eax
f0101deb:	68 a8 2f 10 f0       	push   $0xf0102fa8
f0101df0:	e8 47 f7 ff ff       	call   f010153c <cprintf>
			return NULL;
f0101df5:	83 c4 10             	add    $0x10,%esp
f0101df8:	b8 00 00 00 00       	mov    $0x0,%eax
f0101dfd:	eb 79                	jmp    f0101e78 <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101dff:	83 f8 08             	cmp    $0x8,%eax
f0101e02:	0f 94 c2             	sete   %dl
f0101e05:	83 f8 7f             	cmp    $0x7f,%eax
f0101e08:	0f 94 c0             	sete   %al
f0101e0b:	08 c2                	or     %al,%dl
f0101e0d:	74 1a                	je     f0101e29 <readline+0x82>
f0101e0f:	85 f6                	test   %esi,%esi
f0101e11:	7e 16                	jle    f0101e29 <readline+0x82>
			if (echoing)
f0101e13:	85 ff                	test   %edi,%edi
f0101e15:	74 0d                	je     f0101e24 <readline+0x7d>
				cputchar('\b');
f0101e17:	83 ec 0c             	sub    $0xc,%esp
f0101e1a:	6a 08                	push   $0x8
f0101e1c:	e8 df e7 ff ff       	call   f0100600 <cputchar>
f0101e21:	83 c4 10             	add    $0x10,%esp
			i--;
f0101e24:	83 ee 01             	sub    $0x1,%esi
f0101e27:	eb b3                	jmp    f0101ddc <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101e29:	83 fb 1f             	cmp    $0x1f,%ebx
f0101e2c:	7e 23                	jle    f0101e51 <readline+0xaa>
f0101e2e:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101e34:	7f 1b                	jg     f0101e51 <readline+0xaa>
			if (echoing)
f0101e36:	85 ff                	test   %edi,%edi
f0101e38:	74 0c                	je     f0101e46 <readline+0x9f>
				cputchar(c);
f0101e3a:	83 ec 0c             	sub    $0xc,%esp
f0101e3d:	53                   	push   %ebx
f0101e3e:	e8 bd e7 ff ff       	call   f0100600 <cputchar>
f0101e43:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0101e46:	88 9e 40 45 11 f0    	mov    %bl,-0xfeebac0(%esi)
f0101e4c:	8d 76 01             	lea    0x1(%esi),%esi
f0101e4f:	eb 8b                	jmp    f0101ddc <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0101e51:	83 fb 0a             	cmp    $0xa,%ebx
f0101e54:	74 05                	je     f0101e5b <readline+0xb4>
f0101e56:	83 fb 0d             	cmp    $0xd,%ebx
f0101e59:	75 81                	jne    f0101ddc <readline+0x35>
			if (echoing)
f0101e5b:	85 ff                	test   %edi,%edi
f0101e5d:	74 0d                	je     f0101e6c <readline+0xc5>
				cputchar('\n');
f0101e5f:	83 ec 0c             	sub    $0xc,%esp
f0101e62:	6a 0a                	push   $0xa
f0101e64:	e8 97 e7 ff ff       	call   f0100600 <cputchar>
f0101e69:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0101e6c:	c6 86 40 45 11 f0 00 	movb   $0x0,-0xfeebac0(%esi)
			return buf;
f0101e73:	b8 40 45 11 f0       	mov    $0xf0114540,%eax
		}
	}
}
f0101e78:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101e7b:	5b                   	pop    %ebx
f0101e7c:	5e                   	pop    %esi
f0101e7d:	5f                   	pop    %edi
f0101e7e:	5d                   	pop    %ebp
f0101e7f:	c3                   	ret    

f0101e80 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101e80:	55                   	push   %ebp
f0101e81:	89 e5                	mov    %esp,%ebp
f0101e83:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101e86:	b8 00 00 00 00       	mov    $0x0,%eax
f0101e8b:	eb 03                	jmp    f0101e90 <strlen+0x10>
		n++;
f0101e8d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101e90:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101e94:	75 f7                	jne    f0101e8d <strlen+0xd>
		n++;
	return n;
}
f0101e96:	5d                   	pop    %ebp
f0101e97:	c3                   	ret    

f0101e98 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101e98:	55                   	push   %ebp
f0101e99:	89 e5                	mov    %esp,%ebp
f0101e9b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101e9e:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101ea1:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ea6:	eb 03                	jmp    f0101eab <strnlen+0x13>
		n++;
f0101ea8:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101eab:	39 c2                	cmp    %eax,%edx
f0101ead:	74 08                	je     f0101eb7 <strnlen+0x1f>
f0101eaf:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0101eb3:	75 f3                	jne    f0101ea8 <strnlen+0x10>
f0101eb5:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0101eb7:	5d                   	pop    %ebp
f0101eb8:	c3                   	ret    

f0101eb9 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101eb9:	55                   	push   %ebp
f0101eba:	89 e5                	mov    %esp,%ebp
f0101ebc:	53                   	push   %ebx
f0101ebd:	8b 45 08             	mov    0x8(%ebp),%eax
f0101ec0:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101ec3:	89 c2                	mov    %eax,%edx
f0101ec5:	83 c2 01             	add    $0x1,%edx
f0101ec8:	83 c1 01             	add    $0x1,%ecx
f0101ecb:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101ecf:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101ed2:	84 db                	test   %bl,%bl
f0101ed4:	75 ef                	jne    f0101ec5 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101ed6:	5b                   	pop    %ebx
f0101ed7:	5d                   	pop    %ebp
f0101ed8:	c3                   	ret    

f0101ed9 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101ed9:	55                   	push   %ebp
f0101eda:	89 e5                	mov    %esp,%ebp
f0101edc:	53                   	push   %ebx
f0101edd:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101ee0:	53                   	push   %ebx
f0101ee1:	e8 9a ff ff ff       	call   f0101e80 <strlen>
f0101ee6:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0101ee9:	ff 75 0c             	pushl  0xc(%ebp)
f0101eec:	01 d8                	add    %ebx,%eax
f0101eee:	50                   	push   %eax
f0101eef:	e8 c5 ff ff ff       	call   f0101eb9 <strcpy>
	return dst;
}
f0101ef4:	89 d8                	mov    %ebx,%eax
f0101ef6:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101ef9:	c9                   	leave  
f0101efa:	c3                   	ret    

f0101efb <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101efb:	55                   	push   %ebp
f0101efc:	89 e5                	mov    %esp,%ebp
f0101efe:	56                   	push   %esi
f0101eff:	53                   	push   %ebx
f0101f00:	8b 75 08             	mov    0x8(%ebp),%esi
f0101f03:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101f06:	89 f3                	mov    %esi,%ebx
f0101f08:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101f0b:	89 f2                	mov    %esi,%edx
f0101f0d:	eb 0f                	jmp    f0101f1e <strncpy+0x23>
		*dst++ = *src;
f0101f0f:	83 c2 01             	add    $0x1,%edx
f0101f12:	0f b6 01             	movzbl (%ecx),%eax
f0101f15:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101f18:	80 39 01             	cmpb   $0x1,(%ecx)
f0101f1b:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101f1e:	39 da                	cmp    %ebx,%edx
f0101f20:	75 ed                	jne    f0101f0f <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101f22:	89 f0                	mov    %esi,%eax
f0101f24:	5b                   	pop    %ebx
f0101f25:	5e                   	pop    %esi
f0101f26:	5d                   	pop    %ebp
f0101f27:	c3                   	ret    

f0101f28 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101f28:	55                   	push   %ebp
f0101f29:	89 e5                	mov    %esp,%ebp
f0101f2b:	56                   	push   %esi
f0101f2c:	53                   	push   %ebx
f0101f2d:	8b 75 08             	mov    0x8(%ebp),%esi
f0101f30:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101f33:	8b 55 10             	mov    0x10(%ebp),%edx
f0101f36:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101f38:	85 d2                	test   %edx,%edx
f0101f3a:	74 21                	je     f0101f5d <strlcpy+0x35>
f0101f3c:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0101f40:	89 f2                	mov    %esi,%edx
f0101f42:	eb 09                	jmp    f0101f4d <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101f44:	83 c2 01             	add    $0x1,%edx
f0101f47:	83 c1 01             	add    $0x1,%ecx
f0101f4a:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101f4d:	39 c2                	cmp    %eax,%edx
f0101f4f:	74 09                	je     f0101f5a <strlcpy+0x32>
f0101f51:	0f b6 19             	movzbl (%ecx),%ebx
f0101f54:	84 db                	test   %bl,%bl
f0101f56:	75 ec                	jne    f0101f44 <strlcpy+0x1c>
f0101f58:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101f5a:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101f5d:	29 f0                	sub    %esi,%eax
}
f0101f5f:	5b                   	pop    %ebx
f0101f60:	5e                   	pop    %esi
f0101f61:	5d                   	pop    %ebp
f0101f62:	c3                   	ret    

f0101f63 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101f63:	55                   	push   %ebp
f0101f64:	89 e5                	mov    %esp,%ebp
f0101f66:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101f69:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101f6c:	eb 06                	jmp    f0101f74 <strcmp+0x11>
		p++, q++;
f0101f6e:	83 c1 01             	add    $0x1,%ecx
f0101f71:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101f74:	0f b6 01             	movzbl (%ecx),%eax
f0101f77:	84 c0                	test   %al,%al
f0101f79:	74 04                	je     f0101f7f <strcmp+0x1c>
f0101f7b:	3a 02                	cmp    (%edx),%al
f0101f7d:	74 ef                	je     f0101f6e <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101f7f:	0f b6 c0             	movzbl %al,%eax
f0101f82:	0f b6 12             	movzbl (%edx),%edx
f0101f85:	29 d0                	sub    %edx,%eax
}
f0101f87:	5d                   	pop    %ebp
f0101f88:	c3                   	ret    

f0101f89 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101f89:	55                   	push   %ebp
f0101f8a:	89 e5                	mov    %esp,%ebp
f0101f8c:	53                   	push   %ebx
f0101f8d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f90:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101f93:	89 c3                	mov    %eax,%ebx
f0101f95:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101f98:	eb 06                	jmp    f0101fa0 <strncmp+0x17>
		n--, p++, q++;
f0101f9a:	83 c0 01             	add    $0x1,%eax
f0101f9d:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101fa0:	39 d8                	cmp    %ebx,%eax
f0101fa2:	74 15                	je     f0101fb9 <strncmp+0x30>
f0101fa4:	0f b6 08             	movzbl (%eax),%ecx
f0101fa7:	84 c9                	test   %cl,%cl
f0101fa9:	74 04                	je     f0101faf <strncmp+0x26>
f0101fab:	3a 0a                	cmp    (%edx),%cl
f0101fad:	74 eb                	je     f0101f9a <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101faf:	0f b6 00             	movzbl (%eax),%eax
f0101fb2:	0f b6 12             	movzbl (%edx),%edx
f0101fb5:	29 d0                	sub    %edx,%eax
f0101fb7:	eb 05                	jmp    f0101fbe <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101fb9:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101fbe:	5b                   	pop    %ebx
f0101fbf:	5d                   	pop    %ebp
f0101fc0:	c3                   	ret    

f0101fc1 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101fc1:	55                   	push   %ebp
f0101fc2:	89 e5                	mov    %esp,%ebp
f0101fc4:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fc7:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101fcb:	eb 07                	jmp    f0101fd4 <strchr+0x13>
		if (*s == c)
f0101fcd:	38 ca                	cmp    %cl,%dl
f0101fcf:	74 0f                	je     f0101fe0 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101fd1:	83 c0 01             	add    $0x1,%eax
f0101fd4:	0f b6 10             	movzbl (%eax),%edx
f0101fd7:	84 d2                	test   %dl,%dl
f0101fd9:	75 f2                	jne    f0101fcd <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0101fdb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101fe0:	5d                   	pop    %ebp
f0101fe1:	c3                   	ret    

f0101fe2 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101fe2:	55                   	push   %ebp
f0101fe3:	89 e5                	mov    %esp,%ebp
f0101fe5:	8b 45 08             	mov    0x8(%ebp),%eax
f0101fe8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101fec:	eb 03                	jmp    f0101ff1 <strfind+0xf>
f0101fee:	83 c0 01             	add    $0x1,%eax
f0101ff1:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101ff4:	38 ca                	cmp    %cl,%dl
f0101ff6:	74 04                	je     f0101ffc <strfind+0x1a>
f0101ff8:	84 d2                	test   %dl,%dl
f0101ffa:	75 f2                	jne    f0101fee <strfind+0xc>
			break;
	return (char *) s;
}
f0101ffc:	5d                   	pop    %ebp
f0101ffd:	c3                   	ret    

f0101ffe <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101ffe:	55                   	push   %ebp
f0101fff:	89 e5                	mov    %esp,%ebp
f0102001:	57                   	push   %edi
f0102002:	56                   	push   %esi
f0102003:	53                   	push   %ebx
f0102004:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102007:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010200a:	85 c9                	test   %ecx,%ecx
f010200c:	74 36                	je     f0102044 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010200e:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0102014:	75 28                	jne    f010203e <memset+0x40>
f0102016:	f6 c1 03             	test   $0x3,%cl
f0102019:	75 23                	jne    f010203e <memset+0x40>
		c &= 0xFF;
f010201b:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010201f:	89 d3                	mov    %edx,%ebx
f0102021:	c1 e3 08             	shl    $0x8,%ebx
f0102024:	89 d6                	mov    %edx,%esi
f0102026:	c1 e6 18             	shl    $0x18,%esi
f0102029:	89 d0                	mov    %edx,%eax
f010202b:	c1 e0 10             	shl    $0x10,%eax
f010202e:	09 f0                	or     %esi,%eax
f0102030:	09 c2                	or     %eax,%edx
		asm volatile("cld; rep stosl\n"
f0102032:	89 d8                	mov    %ebx,%eax
f0102034:	09 d0                	or     %edx,%eax
f0102036:	c1 e9 02             	shr    $0x2,%ecx
f0102039:	fc                   	cld    
f010203a:	f3 ab                	rep stos %eax,%es:(%edi)
f010203c:	eb 06                	jmp    f0102044 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010203e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102041:	fc                   	cld    
f0102042:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0102044:	89 f8                	mov    %edi,%eax
f0102046:	5b                   	pop    %ebx
f0102047:	5e                   	pop    %esi
f0102048:	5f                   	pop    %edi
f0102049:	5d                   	pop    %ebp
f010204a:	c3                   	ret    

f010204b <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010204b:	55                   	push   %ebp
f010204c:	89 e5                	mov    %esp,%ebp
f010204e:	57                   	push   %edi
f010204f:	56                   	push   %esi
f0102050:	8b 45 08             	mov    0x8(%ebp),%eax
f0102053:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102056:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0102059:	39 c6                	cmp    %eax,%esi
f010205b:	73 35                	jae    f0102092 <memmove+0x47>
f010205d:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102060:	39 d0                	cmp    %edx,%eax
f0102062:	73 2e                	jae    f0102092 <memmove+0x47>
		s += n;
		d += n;
f0102064:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102067:	89 d6                	mov    %edx,%esi
f0102069:	09 fe                	or     %edi,%esi
f010206b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0102071:	75 13                	jne    f0102086 <memmove+0x3b>
f0102073:	f6 c1 03             	test   $0x3,%cl
f0102076:	75 0e                	jne    f0102086 <memmove+0x3b>
			asm volatile("std; rep movsl\n"
f0102078:	83 ef 04             	sub    $0x4,%edi
f010207b:	8d 72 fc             	lea    -0x4(%edx),%esi
f010207e:	c1 e9 02             	shr    $0x2,%ecx
f0102081:	fd                   	std    
f0102082:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102084:	eb 09                	jmp    f010208f <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0102086:	83 ef 01             	sub    $0x1,%edi
f0102089:	8d 72 ff             	lea    -0x1(%edx),%esi
f010208c:	fd                   	std    
f010208d:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010208f:	fc                   	cld    
f0102090:	eb 1d                	jmp    f01020af <memmove+0x64>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102092:	89 f2                	mov    %esi,%edx
f0102094:	09 c2                	or     %eax,%edx
f0102096:	f6 c2 03             	test   $0x3,%dl
f0102099:	75 0f                	jne    f01020aa <memmove+0x5f>
f010209b:	f6 c1 03             	test   $0x3,%cl
f010209e:	75 0a                	jne    f01020aa <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
f01020a0:	c1 e9 02             	shr    $0x2,%ecx
f01020a3:	89 c7                	mov    %eax,%edi
f01020a5:	fc                   	cld    
f01020a6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01020a8:	eb 05                	jmp    f01020af <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01020aa:	89 c7                	mov    %eax,%edi
f01020ac:	fc                   	cld    
f01020ad:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01020af:	5e                   	pop    %esi
f01020b0:	5f                   	pop    %edi
f01020b1:	5d                   	pop    %ebp
f01020b2:	c3                   	ret    

f01020b3 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01020b3:	55                   	push   %ebp
f01020b4:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01020b6:	ff 75 10             	pushl  0x10(%ebp)
f01020b9:	ff 75 0c             	pushl  0xc(%ebp)
f01020bc:	ff 75 08             	pushl  0x8(%ebp)
f01020bf:	e8 87 ff ff ff       	call   f010204b <memmove>
}
f01020c4:	c9                   	leave  
f01020c5:	c3                   	ret    

f01020c6 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01020c6:	55                   	push   %ebp
f01020c7:	89 e5                	mov    %esp,%ebp
f01020c9:	56                   	push   %esi
f01020ca:	53                   	push   %ebx
f01020cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01020ce:	8b 55 0c             	mov    0xc(%ebp),%edx
f01020d1:	89 c6                	mov    %eax,%esi
f01020d3:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01020d6:	eb 1a                	jmp    f01020f2 <memcmp+0x2c>
		if (*s1 != *s2)
f01020d8:	0f b6 08             	movzbl (%eax),%ecx
f01020db:	0f b6 1a             	movzbl (%edx),%ebx
f01020de:	38 d9                	cmp    %bl,%cl
f01020e0:	74 0a                	je     f01020ec <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01020e2:	0f b6 c1             	movzbl %cl,%eax
f01020e5:	0f b6 db             	movzbl %bl,%ebx
f01020e8:	29 d8                	sub    %ebx,%eax
f01020ea:	eb 0f                	jmp    f01020fb <memcmp+0x35>
		s1++, s2++;
f01020ec:	83 c0 01             	add    $0x1,%eax
f01020ef:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01020f2:	39 f0                	cmp    %esi,%eax
f01020f4:	75 e2                	jne    f01020d8 <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01020f6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01020fb:	5b                   	pop    %ebx
f01020fc:	5e                   	pop    %esi
f01020fd:	5d                   	pop    %ebp
f01020fe:	c3                   	ret    

f01020ff <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01020ff:	55                   	push   %ebp
f0102100:	89 e5                	mov    %esp,%ebp
f0102102:	53                   	push   %ebx
f0102103:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0102106:	89 c1                	mov    %eax,%ecx
f0102108:	03 4d 10             	add    0x10(%ebp),%ecx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f010210b:	0f b6 5d 0c          	movzbl 0xc(%ebp),%ebx

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010210f:	eb 0a                	jmp    f010211b <memfind+0x1c>
		if (*(const unsigned char *) s == (unsigned char) c)
f0102111:	0f b6 10             	movzbl (%eax),%edx
f0102114:	39 da                	cmp    %ebx,%edx
f0102116:	74 07                	je     f010211f <memfind+0x20>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0102118:	83 c0 01             	add    $0x1,%eax
f010211b:	39 c8                	cmp    %ecx,%eax
f010211d:	72 f2                	jb     f0102111 <memfind+0x12>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010211f:	5b                   	pop    %ebx
f0102120:	5d                   	pop    %ebp
f0102121:	c3                   	ret    

f0102122 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0102122:	55                   	push   %ebp
f0102123:	89 e5                	mov    %esp,%ebp
f0102125:	57                   	push   %edi
f0102126:	56                   	push   %esi
f0102127:	53                   	push   %ebx
f0102128:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010212b:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010212e:	eb 03                	jmp    f0102133 <strtol+0x11>
		s++;
f0102130:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102133:	0f b6 01             	movzbl (%ecx),%eax
f0102136:	3c 20                	cmp    $0x20,%al
f0102138:	74 f6                	je     f0102130 <strtol+0xe>
f010213a:	3c 09                	cmp    $0x9,%al
f010213c:	74 f2                	je     f0102130 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010213e:	3c 2b                	cmp    $0x2b,%al
f0102140:	75 0a                	jne    f010214c <strtol+0x2a>
		s++;
f0102142:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0102145:	bf 00 00 00 00       	mov    $0x0,%edi
f010214a:	eb 11                	jmp    f010215d <strtol+0x3b>
f010214c:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0102151:	3c 2d                	cmp    $0x2d,%al
f0102153:	75 08                	jne    f010215d <strtol+0x3b>
		s++, neg = 1;
f0102155:	83 c1 01             	add    $0x1,%ecx
f0102158:	bf 01 00 00 00       	mov    $0x1,%edi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010215d:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0102163:	75 15                	jne    f010217a <strtol+0x58>
f0102165:	80 39 30             	cmpb   $0x30,(%ecx)
f0102168:	75 10                	jne    f010217a <strtol+0x58>
f010216a:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f010216e:	75 7c                	jne    f01021ec <strtol+0xca>
		s += 2, base = 16;
f0102170:	83 c1 02             	add    $0x2,%ecx
f0102173:	bb 10 00 00 00       	mov    $0x10,%ebx
f0102178:	eb 16                	jmp    f0102190 <strtol+0x6e>
	else if (base == 0 && s[0] == '0')
f010217a:	85 db                	test   %ebx,%ebx
f010217c:	75 12                	jne    f0102190 <strtol+0x6e>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010217e:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102183:	80 39 30             	cmpb   $0x30,(%ecx)
f0102186:	75 08                	jne    f0102190 <strtol+0x6e>
		s++, base = 8;
f0102188:	83 c1 01             	add    $0x1,%ecx
f010218b:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0102190:	b8 00 00 00 00       	mov    $0x0,%eax
f0102195:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0102198:	0f b6 11             	movzbl (%ecx),%edx
f010219b:	8d 72 d0             	lea    -0x30(%edx),%esi
f010219e:	89 f3                	mov    %esi,%ebx
f01021a0:	80 fb 09             	cmp    $0x9,%bl
f01021a3:	77 08                	ja     f01021ad <strtol+0x8b>
			dig = *s - '0';
f01021a5:	0f be d2             	movsbl %dl,%edx
f01021a8:	83 ea 30             	sub    $0x30,%edx
f01021ab:	eb 22                	jmp    f01021cf <strtol+0xad>
		else if (*s >= 'a' && *s <= 'z')
f01021ad:	8d 72 9f             	lea    -0x61(%edx),%esi
f01021b0:	89 f3                	mov    %esi,%ebx
f01021b2:	80 fb 19             	cmp    $0x19,%bl
f01021b5:	77 08                	ja     f01021bf <strtol+0x9d>
			dig = *s - 'a' + 10;
f01021b7:	0f be d2             	movsbl %dl,%edx
f01021ba:	83 ea 57             	sub    $0x57,%edx
f01021bd:	eb 10                	jmp    f01021cf <strtol+0xad>
		else if (*s >= 'A' && *s <= 'Z')
f01021bf:	8d 72 bf             	lea    -0x41(%edx),%esi
f01021c2:	89 f3                	mov    %esi,%ebx
f01021c4:	80 fb 19             	cmp    $0x19,%bl
f01021c7:	77 16                	ja     f01021df <strtol+0xbd>
			dig = *s - 'A' + 10;
f01021c9:	0f be d2             	movsbl %dl,%edx
f01021cc:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01021cf:	3b 55 10             	cmp    0x10(%ebp),%edx
f01021d2:	7d 0b                	jge    f01021df <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f01021d4:	83 c1 01             	add    $0x1,%ecx
f01021d7:	0f af 45 10          	imul   0x10(%ebp),%eax
f01021db:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f01021dd:	eb b9                	jmp    f0102198 <strtol+0x76>

	if (endptr)
f01021df:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01021e3:	74 0d                	je     f01021f2 <strtol+0xd0>
		*endptr = (char *) s;
f01021e5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01021e8:	89 0e                	mov    %ecx,(%esi)
f01021ea:	eb 06                	jmp    f01021f2 <strtol+0xd0>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01021ec:	85 db                	test   %ebx,%ebx
f01021ee:	74 98                	je     f0102188 <strtol+0x66>
f01021f0:	eb 9e                	jmp    f0102190 <strtol+0x6e>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f01021f2:	89 c2                	mov    %eax,%edx
f01021f4:	f7 da                	neg    %edx
f01021f6:	85 ff                	test   %edi,%edi
f01021f8:	0f 45 c2             	cmovne %edx,%eax
}
f01021fb:	5b                   	pop    %ebx
f01021fc:	5e                   	pop    %esi
f01021fd:	5f                   	pop    %edi
f01021fe:	5d                   	pop    %ebp
f01021ff:	c3                   	ret    

f0102200 <__udivdi3>:
f0102200:	55                   	push   %ebp
f0102201:	57                   	push   %edi
f0102202:	56                   	push   %esi
f0102203:	53                   	push   %ebx
f0102204:	83 ec 1c             	sub    $0x1c,%esp
f0102207:	8b 74 24 3c          	mov    0x3c(%esp),%esi
f010220b:	8b 5c 24 30          	mov    0x30(%esp),%ebx
f010220f:	8b 4c 24 34          	mov    0x34(%esp),%ecx
f0102213:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102217:	85 f6                	test   %esi,%esi
f0102219:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010221d:	89 ca                	mov    %ecx,%edx
f010221f:	89 f8                	mov    %edi,%eax
f0102221:	75 3d                	jne    f0102260 <__udivdi3+0x60>
f0102223:	39 cf                	cmp    %ecx,%edi
f0102225:	0f 87 c5 00 00 00    	ja     f01022f0 <__udivdi3+0xf0>
f010222b:	85 ff                	test   %edi,%edi
f010222d:	89 fd                	mov    %edi,%ebp
f010222f:	75 0b                	jne    f010223c <__udivdi3+0x3c>
f0102231:	b8 01 00 00 00       	mov    $0x1,%eax
f0102236:	31 d2                	xor    %edx,%edx
f0102238:	f7 f7                	div    %edi
f010223a:	89 c5                	mov    %eax,%ebp
f010223c:	89 c8                	mov    %ecx,%eax
f010223e:	31 d2                	xor    %edx,%edx
f0102240:	f7 f5                	div    %ebp
f0102242:	89 c1                	mov    %eax,%ecx
f0102244:	89 d8                	mov    %ebx,%eax
f0102246:	89 cf                	mov    %ecx,%edi
f0102248:	f7 f5                	div    %ebp
f010224a:	89 c3                	mov    %eax,%ebx
f010224c:	89 d8                	mov    %ebx,%eax
f010224e:	89 fa                	mov    %edi,%edx
f0102250:	83 c4 1c             	add    $0x1c,%esp
f0102253:	5b                   	pop    %ebx
f0102254:	5e                   	pop    %esi
f0102255:	5f                   	pop    %edi
f0102256:	5d                   	pop    %ebp
f0102257:	c3                   	ret    
f0102258:	90                   	nop
f0102259:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102260:	39 ce                	cmp    %ecx,%esi
f0102262:	77 74                	ja     f01022d8 <__udivdi3+0xd8>
f0102264:	0f bd fe             	bsr    %esi,%edi
f0102267:	83 f7 1f             	xor    $0x1f,%edi
f010226a:	0f 84 98 00 00 00    	je     f0102308 <__udivdi3+0x108>
f0102270:	bb 20 00 00 00       	mov    $0x20,%ebx
f0102275:	89 f9                	mov    %edi,%ecx
f0102277:	89 c5                	mov    %eax,%ebp
f0102279:	29 fb                	sub    %edi,%ebx
f010227b:	d3 e6                	shl    %cl,%esi
f010227d:	89 d9                	mov    %ebx,%ecx
f010227f:	d3 ed                	shr    %cl,%ebp
f0102281:	89 f9                	mov    %edi,%ecx
f0102283:	d3 e0                	shl    %cl,%eax
f0102285:	09 ee                	or     %ebp,%esi
f0102287:	89 d9                	mov    %ebx,%ecx
f0102289:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010228d:	89 d5                	mov    %edx,%ebp
f010228f:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102293:	d3 ed                	shr    %cl,%ebp
f0102295:	89 f9                	mov    %edi,%ecx
f0102297:	d3 e2                	shl    %cl,%edx
f0102299:	89 d9                	mov    %ebx,%ecx
f010229b:	d3 e8                	shr    %cl,%eax
f010229d:	09 c2                	or     %eax,%edx
f010229f:	89 d0                	mov    %edx,%eax
f01022a1:	89 ea                	mov    %ebp,%edx
f01022a3:	f7 f6                	div    %esi
f01022a5:	89 d5                	mov    %edx,%ebp
f01022a7:	89 c3                	mov    %eax,%ebx
f01022a9:	f7 64 24 0c          	mull   0xc(%esp)
f01022ad:	39 d5                	cmp    %edx,%ebp
f01022af:	72 10                	jb     f01022c1 <__udivdi3+0xc1>
f01022b1:	8b 74 24 08          	mov    0x8(%esp),%esi
f01022b5:	89 f9                	mov    %edi,%ecx
f01022b7:	d3 e6                	shl    %cl,%esi
f01022b9:	39 c6                	cmp    %eax,%esi
f01022bb:	73 07                	jae    f01022c4 <__udivdi3+0xc4>
f01022bd:	39 d5                	cmp    %edx,%ebp
f01022bf:	75 03                	jne    f01022c4 <__udivdi3+0xc4>
f01022c1:	83 eb 01             	sub    $0x1,%ebx
f01022c4:	31 ff                	xor    %edi,%edi
f01022c6:	89 d8                	mov    %ebx,%eax
f01022c8:	89 fa                	mov    %edi,%edx
f01022ca:	83 c4 1c             	add    $0x1c,%esp
f01022cd:	5b                   	pop    %ebx
f01022ce:	5e                   	pop    %esi
f01022cf:	5f                   	pop    %edi
f01022d0:	5d                   	pop    %ebp
f01022d1:	c3                   	ret    
f01022d2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01022d8:	31 ff                	xor    %edi,%edi
f01022da:	31 db                	xor    %ebx,%ebx
f01022dc:	89 d8                	mov    %ebx,%eax
f01022de:	89 fa                	mov    %edi,%edx
f01022e0:	83 c4 1c             	add    $0x1c,%esp
f01022e3:	5b                   	pop    %ebx
f01022e4:	5e                   	pop    %esi
f01022e5:	5f                   	pop    %edi
f01022e6:	5d                   	pop    %ebp
f01022e7:	c3                   	ret    
f01022e8:	90                   	nop
f01022e9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01022f0:	89 d8                	mov    %ebx,%eax
f01022f2:	f7 f7                	div    %edi
f01022f4:	31 ff                	xor    %edi,%edi
f01022f6:	89 c3                	mov    %eax,%ebx
f01022f8:	89 d8                	mov    %ebx,%eax
f01022fa:	89 fa                	mov    %edi,%edx
f01022fc:	83 c4 1c             	add    $0x1c,%esp
f01022ff:	5b                   	pop    %ebx
f0102300:	5e                   	pop    %esi
f0102301:	5f                   	pop    %edi
f0102302:	5d                   	pop    %ebp
f0102303:	c3                   	ret    
f0102304:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102308:	39 ce                	cmp    %ecx,%esi
f010230a:	72 0c                	jb     f0102318 <__udivdi3+0x118>
f010230c:	31 db                	xor    %ebx,%ebx
f010230e:	3b 44 24 08          	cmp    0x8(%esp),%eax
f0102312:	0f 87 34 ff ff ff    	ja     f010224c <__udivdi3+0x4c>
f0102318:	bb 01 00 00 00       	mov    $0x1,%ebx
f010231d:	e9 2a ff ff ff       	jmp    f010224c <__udivdi3+0x4c>
f0102322:	66 90                	xchg   %ax,%ax
f0102324:	66 90                	xchg   %ax,%ax
f0102326:	66 90                	xchg   %ax,%ax
f0102328:	66 90                	xchg   %ax,%ax
f010232a:	66 90                	xchg   %ax,%ax
f010232c:	66 90                	xchg   %ax,%ax
f010232e:	66 90                	xchg   %ax,%ax

f0102330 <__umoddi3>:
f0102330:	55                   	push   %ebp
f0102331:	57                   	push   %edi
f0102332:	56                   	push   %esi
f0102333:	53                   	push   %ebx
f0102334:	83 ec 1c             	sub    $0x1c,%esp
f0102337:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010233b:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f010233f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0102343:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0102347:	85 d2                	test   %edx,%edx
f0102349:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010234d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0102351:	89 f3                	mov    %esi,%ebx
f0102353:	89 3c 24             	mov    %edi,(%esp)
f0102356:	89 74 24 04          	mov    %esi,0x4(%esp)
f010235a:	75 1c                	jne    f0102378 <__umoddi3+0x48>
f010235c:	39 f7                	cmp    %esi,%edi
f010235e:	76 50                	jbe    f01023b0 <__umoddi3+0x80>
f0102360:	89 c8                	mov    %ecx,%eax
f0102362:	89 f2                	mov    %esi,%edx
f0102364:	f7 f7                	div    %edi
f0102366:	89 d0                	mov    %edx,%eax
f0102368:	31 d2                	xor    %edx,%edx
f010236a:	83 c4 1c             	add    $0x1c,%esp
f010236d:	5b                   	pop    %ebx
f010236e:	5e                   	pop    %esi
f010236f:	5f                   	pop    %edi
f0102370:	5d                   	pop    %ebp
f0102371:	c3                   	ret    
f0102372:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102378:	39 f2                	cmp    %esi,%edx
f010237a:	89 d0                	mov    %edx,%eax
f010237c:	77 52                	ja     f01023d0 <__umoddi3+0xa0>
f010237e:	0f bd ea             	bsr    %edx,%ebp
f0102381:	83 f5 1f             	xor    $0x1f,%ebp
f0102384:	75 5a                	jne    f01023e0 <__umoddi3+0xb0>
f0102386:	3b 54 24 04          	cmp    0x4(%esp),%edx
f010238a:	0f 82 e0 00 00 00    	jb     f0102470 <__umoddi3+0x140>
f0102390:	39 0c 24             	cmp    %ecx,(%esp)
f0102393:	0f 86 d7 00 00 00    	jbe    f0102470 <__umoddi3+0x140>
f0102399:	8b 44 24 08          	mov    0x8(%esp),%eax
f010239d:	8b 54 24 04          	mov    0x4(%esp),%edx
f01023a1:	83 c4 1c             	add    $0x1c,%esp
f01023a4:	5b                   	pop    %ebx
f01023a5:	5e                   	pop    %esi
f01023a6:	5f                   	pop    %edi
f01023a7:	5d                   	pop    %ebp
f01023a8:	c3                   	ret    
f01023a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01023b0:	85 ff                	test   %edi,%edi
f01023b2:	89 fd                	mov    %edi,%ebp
f01023b4:	75 0b                	jne    f01023c1 <__umoddi3+0x91>
f01023b6:	b8 01 00 00 00       	mov    $0x1,%eax
f01023bb:	31 d2                	xor    %edx,%edx
f01023bd:	f7 f7                	div    %edi
f01023bf:	89 c5                	mov    %eax,%ebp
f01023c1:	89 f0                	mov    %esi,%eax
f01023c3:	31 d2                	xor    %edx,%edx
f01023c5:	f7 f5                	div    %ebp
f01023c7:	89 c8                	mov    %ecx,%eax
f01023c9:	f7 f5                	div    %ebp
f01023cb:	89 d0                	mov    %edx,%eax
f01023cd:	eb 99                	jmp    f0102368 <__umoddi3+0x38>
f01023cf:	90                   	nop
f01023d0:	89 c8                	mov    %ecx,%eax
f01023d2:	89 f2                	mov    %esi,%edx
f01023d4:	83 c4 1c             	add    $0x1c,%esp
f01023d7:	5b                   	pop    %ebx
f01023d8:	5e                   	pop    %esi
f01023d9:	5f                   	pop    %edi
f01023da:	5d                   	pop    %ebp
f01023db:	c3                   	ret    
f01023dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01023e0:	8b 34 24             	mov    (%esp),%esi
f01023e3:	bf 20 00 00 00       	mov    $0x20,%edi
f01023e8:	89 e9                	mov    %ebp,%ecx
f01023ea:	29 ef                	sub    %ebp,%edi
f01023ec:	d3 e0                	shl    %cl,%eax
f01023ee:	89 f9                	mov    %edi,%ecx
f01023f0:	89 f2                	mov    %esi,%edx
f01023f2:	d3 ea                	shr    %cl,%edx
f01023f4:	89 e9                	mov    %ebp,%ecx
f01023f6:	09 c2                	or     %eax,%edx
f01023f8:	89 d8                	mov    %ebx,%eax
f01023fa:	89 14 24             	mov    %edx,(%esp)
f01023fd:	89 f2                	mov    %esi,%edx
f01023ff:	d3 e2                	shl    %cl,%edx
f0102401:	89 f9                	mov    %edi,%ecx
f0102403:	89 54 24 04          	mov    %edx,0x4(%esp)
f0102407:	8b 54 24 0c          	mov    0xc(%esp),%edx
f010240b:	d3 e8                	shr    %cl,%eax
f010240d:	89 e9                	mov    %ebp,%ecx
f010240f:	89 c6                	mov    %eax,%esi
f0102411:	d3 e3                	shl    %cl,%ebx
f0102413:	89 f9                	mov    %edi,%ecx
f0102415:	89 d0                	mov    %edx,%eax
f0102417:	d3 e8                	shr    %cl,%eax
f0102419:	89 e9                	mov    %ebp,%ecx
f010241b:	09 d8                	or     %ebx,%eax
f010241d:	89 d3                	mov    %edx,%ebx
f010241f:	89 f2                	mov    %esi,%edx
f0102421:	f7 34 24             	divl   (%esp)
f0102424:	89 d6                	mov    %edx,%esi
f0102426:	d3 e3                	shl    %cl,%ebx
f0102428:	f7 64 24 04          	mull   0x4(%esp)
f010242c:	39 d6                	cmp    %edx,%esi
f010242e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102432:	89 d1                	mov    %edx,%ecx
f0102434:	89 c3                	mov    %eax,%ebx
f0102436:	72 08                	jb     f0102440 <__umoddi3+0x110>
f0102438:	75 11                	jne    f010244b <__umoddi3+0x11b>
f010243a:	39 44 24 08          	cmp    %eax,0x8(%esp)
f010243e:	73 0b                	jae    f010244b <__umoddi3+0x11b>
f0102440:	2b 44 24 04          	sub    0x4(%esp),%eax
f0102444:	1b 14 24             	sbb    (%esp),%edx
f0102447:	89 d1                	mov    %edx,%ecx
f0102449:	89 c3                	mov    %eax,%ebx
f010244b:	8b 54 24 08          	mov    0x8(%esp),%edx
f010244f:	29 da                	sub    %ebx,%edx
f0102451:	19 ce                	sbb    %ecx,%esi
f0102453:	89 f9                	mov    %edi,%ecx
f0102455:	89 f0                	mov    %esi,%eax
f0102457:	d3 e0                	shl    %cl,%eax
f0102459:	89 e9                	mov    %ebp,%ecx
f010245b:	d3 ea                	shr    %cl,%edx
f010245d:	89 e9                	mov    %ebp,%ecx
f010245f:	d3 ee                	shr    %cl,%esi
f0102461:	09 d0                	or     %edx,%eax
f0102463:	89 f2                	mov    %esi,%edx
f0102465:	83 c4 1c             	add    $0x1c,%esp
f0102468:	5b                   	pop    %ebx
f0102469:	5e                   	pop    %esi
f010246a:	5f                   	pop    %edi
f010246b:	5d                   	pop    %ebp
f010246c:	c3                   	ret    
f010246d:	8d 76 00             	lea    0x0(%esi),%esi
f0102470:	29 f9                	sub    %edi,%ecx
f0102472:	19 d6                	sbb    %edx,%esi
f0102474:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102478:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010247c:	e9 18 ff ff ff       	jmp    f0102399 <__umoddi3+0x69>

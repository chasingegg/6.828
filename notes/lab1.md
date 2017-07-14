# Lab1: Booting a PC

This lab is split into three parts.

- familiar with x86 assembly language
- examine the boot loader for our 6.828 kernel.
- delve into the initial template for our 6.828 kernel itself

## PC's physical address space

```
+------------------+  <- 0xFFFFFFFF (4GB)
|      32-bit      |
|  memory mapped   |
|     devices      |
|                  |
/\/\/\/\/\/\/\/\/\/\

/\/\/\/\/\/\/\/\/\/\
|                  |
|      Unused      |
|                  |
+------------------+  <- depends on amount of RAM
|                  |
|                  |
| Extended Memory  |
|                  |
|                  |
+------------------+  <- 0x00100000 (1MB)
|     BIOS ROM     |
+------------------+  <- 0x000F0000 (960KB)
|  16-bit devices, |
|  expansion ROMs  |
+------------------+  <- 0x000C0000 (768KB)
|   VGA Display    |
+------------------+  <- 0x000A0000 (640KB)
|                  |
|    Low Memory    |
|                  |
+------------------+  <- 0x00000000
```

最初用在IBM PC上的16位的Intel 8088处理器只有1MB的寻址空间(20位地址总线), 所以物理地址从0x00000000到0x000FFFFF. 最低的640KB的内存作为RAM 剩下的384KB空间比较重要的就是BIOS了(0x000F0000到0x000FFFFF), BIOS负责一些系统初始化的工作比如开启显卡 检查系统内存大小等工作，初始化完成后加载操作系统。最初BIOS是在ROM上的固件，现在的PC stores BIOS in updateable flash memory.

随着处理器的发展，内存空间早就突破1MB，但是仍然把1MB空间的结构保存下来to ensure backwards compatibility. 老处理器上的PC也能运行在新处理器上。

## The ROM BIOS

开始实验，第一条命令便是

```assembly
[f000:fff0]  0xffff0: ljmp  $0xf000, $0xe05b
```

提一下物理地址的计算  0xf000 * 16 + 0xfff0 = 0xffff0. 这里16是段的大小，因为16位的寄存器要表示20位的寻址空间，用了分段的方法。这里指的是最早的intel 8088处理器。

IBM PC执行的起始物理地址为0x000ffff0, 第一条命令是执行跳转到较低的地址开始执行BIOS。所以启动电源以后BIOS是第一个执行的软件，之后处理器进入实模式。BIOS先做自检工作和初始化工作，如果一切正常加载主引导记录(MBR)并移交控制权。

## The Boot Loader

磁盘被划分为512B的区域，称为扇区(sector)。第一个扇区称为引导扇区(boot sector), 存放的是boot loader code. BIOS加载boot loader到内存```0x7c00```，现在boot loader已经获取了控制权。

boot loader主要做了这两个工作

- 从实模式到保护模式 (实模式只能访问1MB以下的内存空间，只有16位的寻址空间，保护模式下有32位的寻址空间，所以在翻译物理地址的时候乘16还是乘32有区别。)
- 把内核从硬盘加载到内存

### Exercise 3

*At what point does the processor start executing 32-bit code?*

```assembly
  # Jump to next instruction, but in 32-bit code segment.
  # Switches processor into 32-bit mode.
  ljmp    $PROT_MODE_CSEG, $protcseg
```

*The last instruction of the boot loader executed. The first instruction of the kernel  it just loaded?*

```main.c```中最后一句```((void (*)(void)) (ELFHDR->e_entry))();```， 准备读取ELF头，在```boot.asm```中找到对应的汇编指令```7d6b:	ff 15 18 00 01 00    	call   *0x10018```。

kernel start address是```0x0010000c```

![img](../pic/3.png?lastModify=1499012483)然后设置断点可以看到相应的指令，```movw $0x1234, 0x472```.也可以直接在kern/entry.S中找到第一条命令。

*how does the boot loader decide how many sectors it must read in order to fetch the entire kernel from disk? Where does it find this information?*

找到bootmain函数

```assembly
// load each program segment (ignores ph flags)
	ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff);
	eph = ph + ELFHDR->e_phnum;
	for (; ph < eph; ph++)
		// p_pa is the load address of this segment (as well
		// as the physical address)
		readseg(ph->p_pa, ph->p_memsz, ph->p_offset);
```

循环读块。接着看readseg函数，有三个参数，第一个是物理地址，第二个是页的大小，第三个是偏移量。由于ELF header中包含了program header table的位置信息，而program header table包含了操作系统一共有多少段，每个段包含多少扇区等关键信息。所以先加载ELF header获取到program header table，然后根据其中的信息确定内核将占用多少扇区。

简单总结一下引导程序的具体流程。

第一条命令是```cli```关闭中断，避免意外发生使boot失败。然后初始化一些段寄存器DS, ES, SS. 之后使能A20地址线(第21根地址线)，因为8088/8066使用分段方式表示1MB的内存空间，而FFFF:FFFF=0xFFFF << 4 + 0xFFFF=0x10FFEF有一个第21位，禁用A20(自动将这种情况下的21位置为0)可以保证1MB的内存访问空间。而后来的地址线增加了，内存寻址范围增大，为了实现兼容，默认关掉这一位保持和之前的机器一样，但需要更多寻址空间时使能A20。这样一来，内核就可以开始进入保护模式了。先初始化全局描述符表(GDT), 关于GDT表的一些重要信息存放到GDTR寄存器中，GDTR是一个48位寄存器，前16位表示GDT大小，后32位表示GDT的起始地址。修改CR0寄存器的保护模式启动位，然后执行跳转指令(之前问题中有回答)由此切换成32位地址模式。然后重新加载段寄存器的值，接下来跳转到bootmain函数，此时就要进行加载内核的工作了。

将内核的第一个页读进来，即把image文件的ELF header放进内存中。(内核映像就是一个ELF格式的文件，其包含定长的ELF header， 变长的program header，以及program section(text, rodata, data))。重点关注.text段的VMA(link address)和LMA(load address)VMA是内核在编译链接时需要的地址，LMA是程序实际运行时加载到内存中的地址，由于boot sector被加载到地址0x7c00，这也是其开始执行的地址，所以这时候这两个地址应当是相同的。 ```ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff); ```获取program header table的表头地址， which 存放着所有段的信息。```eph = ph + ELFHDR->e_phnum;```phnum表示表项的个数，所以eph指向表的末尾，接下来的for循环```for (; ph < eph; ph++) readseg(ph->p_pa, ph->p_memsz, ph->p_offset);```加载所有段到内存中，所以内核就加载到了内存中，最后boot loader移交控制权给kernel.

### Exercise 6

*Examine the 8 words of memory at 0x00100000 at the point the BIOS enters the boot loader, and then again at the point the boot loader enters the kernel. Why are they different? What is there at the second breakpoint?*

刚进入引导程序内容为0, 后来刚进入kernel以后被填充了内容，因为bootmain函数最后将各个程序段送入地址0x100000处。

## The kernel

在运行bootloader时链接地址和加载地址是一样的，而进入到kernel以后这两个地址就不再一样了。kernel通常会被链接到一个高虚拟地址比如0xf0100000,然而一般物理内存不会有这么多，所以要将该虚拟地址利用分页机制映射到一个比较低的物理地址。 

把页表的物理地址存储到cr3寄存器中，并开启cr0中的页表选项。这里也有一个exercise，通过gdb追踪地址0x00100000和0xf0100000中的内容，可以看到运行```movl %eax, %cr0```之后，两个地址指向了同一个地址。说明开启页表的任务已经完成。

然后有关I/O的函数如printf也是在内核中实现的。这里主要考察一下 kern/printf.c, kern/console.c, lib/printfmt.c 这三个文件。其中console.c是最底层的，其他两个文件都依赖它。

console.c包含三个主要函数，```serial_putc```将一个字符输出到串口，```lpt_putc```将一个字符给并口设备，```cga_putc```将字符显示到cga设备上(计算机显示屏)。

printfmt.c中最重要的函数是```vprintfmt```. 包含4个输入参数。

- void (*putch)(int, void *) 输出的字符值， void *表示存储输出位置的地址的地址(这里有点绕。。)
- void *putdat 同上void *
- const char *fmt 格式化字符串 如"This is the %d party"
- va_list ap 多个输入参数

这里也有个练习输出八进制数，很简单。

## The stack

在kern/entry.S中，内核初始化栈的内容

```assembly
movl	$0x0,%ebp			# nuke frame pointer

# Set the stack pointer
movl	$(bootstacktop),%esp
```

esp(栈指针寄存器)指向栈中正在被使用的最低地址。在32位模式下，每一次对栈的操作都是以32位为单位的，所以esp中的值永远可以被4整除。

ebp寄存器是记录每一个程序栈帧相关信息的寄存器。每一个程序在运行时都会分配到一个栈帧用于存放一些临时变量等。当进入某个子程序时，先将ebp寄存器的值压入栈中保存起来，然后把ebp寄存器的值更新为esp寄存器的值。所以我们可以通过保存在栈中的一系列ebp寄存器的值来进行回溯。

单步调试可知bookstacktop(栈的初始值)为0xf0110000  栈的大小为KSTKSIZE(32KB).

接下来专门有一个exercise让我们来熟悉这个堆栈的操作，```test_backtrace```是一个递归函数，会被重复调用。

```c
void
test_backtrace(int x)
{
	cprintf("entering test_backtrace %d\n", x);
	if (x > 0)
		test_backtrace(x-1);
	else
		mon_backtrace(0, 0, 0);
	cprintf("leaving test_backtrace %d\n", x);
}
```

在调用子程序之前，调用者会先将参数压栈，然后call function, call操作包含两个步骤，将函数结束后返回地址eip先压栈(这里的返回地址是下一条指令)，然后跳转到函数位置。将ebp压栈，然后将esp值赋给ebp，作为子程序栈帧的高地址边界。压入ebx保存临时变量，然后```sub $0x14, %esp```将esp值减小即为该子程序预留一定空间栈帧以供存储一些临时变量。


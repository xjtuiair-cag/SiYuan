
build_src/ddr.elf：     文件格式 elf64-littleriscv
build_src/ddr.elf
体系结构：riscv:rv64，标志 0x00000112：
EXEC_P, HAS_SYMS, D_PAGED
起始地址 0x0000000080000000

程序头：
    LOAD off    0x0000000000001000 vaddr 0x0000000080000000 paddr 0x0000000080000000 align 2**12
         filesz 0x00000000000007e6 memsz 0x00000000000007e6 flags r-x
    LOAD off    0x0000000000002000 vaddr 0x0000000080001000 paddr 0x0000000080001000 align 2**12
         filesz 0x0000000000002000 memsz 0x0000000000002000 flags rw-

节：
Idx Name          Size      VMA               LMA               File off  Algn
  0 .text.boot    00000084  0000000080000000  0000000080000000  00001000  2**0
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .text         000006d8  0000000080000084  0000000080000084  00001084  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  2 .rodata       00000086  0000000080000760  0000000080000760  00001760  2**3
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  3 .data         00002000  0000000080001000  0000000080001000  00002000  2**12
                  CONTENTS, ALLOC, LOAD, DATA
  4 .debug_info   00000736  0000000000000000  0000000000000000  00004000  2**0
                  CONTENTS, READONLY, DEBUGGING
  5 .debug_abbrev 0000028e  0000000000000000  0000000000000000  00004736  2**0
                  CONTENTS, READONLY, DEBUGGING
  6 .debug_aranges 000000c0  0000000000000000  0000000000000000  000049d0  2**4
                  CONTENTS, READONLY, DEBUGGING
  7 .debug_line   00000611  0000000000000000  0000000000000000  00004a90  2**0
                  CONTENTS, READONLY, DEBUGGING
  8 .debug_str    00000260  0000000000000000  0000000000000000  000050a1  2**0
                  CONTENTS, READONLY, DEBUGGING
  9 .comment      00000011  0000000000000000  0000000000000000  00005301  2**0
                  CONTENTS, READONLY
 10 .debug_frame  00000318  0000000000000000  0000000000000000  00005318  2**3
                  CONTENTS, READONLY, DEBUGGING
SYMBOL TABLE:
0000000080000000 l    d  .text.boot	0000000000000000 .text.boot
0000000080000084 l    d  .text	0000000000000000 .text
0000000080000760 l    d  .rodata	0000000000000000 .rodata
0000000080001000 l    d  .data	0000000000000000 .data
0000000000000000 l    d  .debug_info	0000000000000000 .debug_info
0000000000000000 l    d  .debug_abbrev	0000000000000000 .debug_abbrev
0000000000000000 l    d  .debug_aranges	0000000000000000 .debug_aranges
0000000000000000 l    d  .debug_line	0000000000000000 .debug_line
0000000000000000 l    d  .debug_str	0000000000000000 .debug_str
0000000000000000 l    d  .comment	0000000000000000 .comment
0000000000000000 l    d  .debug_frame	0000000000000000 .debug_frame
0000000000000000 l    df *ABS*	0000000000000000 uart.c
0000000000000000 l    df *ABS*	0000000000000000 npu.c
00000000800004d8 l     F .text	0000000000000074 clr_reg
000000008000054c l     F .text	000000000000006c set_reg
0000000000000000 l    df *ABS*	0000000000000000 main.c
0000000080000108 g     F .text	0000000000000040 write_serial
0000000080000368 g     F .text	0000000000000088 print_uart_addr
00000000800005f4 g     F .text	0000000000000060 start_npu
0000000080000148 g     F .text	00000000000000c8 init_uart
00000000800002d8 g     F .text	0000000000000090 print_uart_int
00000000800003f0 g     F .text	000000000000004c print_uart_byte
0000000080000468 g     F .text	0000000000000030 write_reg_u32
0000000080000000 g       .text.boot	0000000000000000 _start
0000000080000498 g     F .text	0000000000000040 sleep_us
0000000080003000 g       .data	0000000000000000 bss_end
0000000080000084 g     F .text	0000000000000030 write_reg_u8
0000000080000260 g     F .text	0000000000000078 bin_to_hex
00000000800006a4 g     F .text	0000000000000070 wait_npu_done
00000000800000d4 g     F .text	0000000000000034 is_transmit_empty
0000000080000714 g     F .text	0000000000000048 main
0000000080000654 g     F .text	0000000000000050 start_conv
0000000080002000 g       .data	0000000000000000 stacks_start
0000000080000210 g     F .text	0000000000000050 print_uart
000000008000043c g     F .text	000000000000002c write_reg_u64
0000000080003000 g       .data	0000000000000000 bss_begin
0000000080001000 g     O .data	0000000000000010 bin_to_hex_table
00000000800000b4 g     F .text	0000000000000020 read_reg_u8
00000000800005b8 g     F .text	000000000000003c init_npu



Disassembly of section .text.boot:

0000000080000000 <_start>:
#include <smp.h>

  .section .text.boot
  .globl _start
_start:
  	smp_pause(s1, s2)
    80000000:	00800913          	li	s2,8
    80000004:	30491073          	csrw	mie,s2
    80000008:	00000493          	li	s1,0
    8000000c:	f1402973          	csrr	s2,mhartid
    80000010:	03249c63          	bne	s1,s2,80000048 <_start+0x48>
	/* Mask all interrupts */
	csrw sie, zero
    80000014:	10401073          	csrw	sie,zero

	/* set the stack of SP, size 4KB */
	la sp, stacks_start
    80000018:	00002117          	auipc	sp,0x2
    8000001c:	fe810113          	addi	sp,sp,-24 # 80002000 <stacks_start>
	li t0, 4096
    80000020:	000012b7          	lui	t0,0x1
	add sp, sp, t0
    80000024:	00510133          	add	sp,sp,t0

	/* goto C */
	tail main 
    80000028:	6ec0006f          	j	80000714 <main>

	smp_resume(s1, s2)
    8000002c:	020004b7          	lui	s1,0x2000
    80000030:	00100913          	li	s2,1
    80000034:	0124a023          	sw	s2,0(s1) # 2000000 <_start-0x7e000000>
    80000038:	00448493          	addi	s1,s1,4
    8000003c:	02000937          	lui	s2,0x2000
    80000040:	0109091b          	addiw	s2,s2,16
    80000044:	ff24c6e3          	blt	s1,s2,80000030 <_start+0x30>
    80000048:	10500073          	wfi
    8000004c:	34402973          	csrr	s2,mip
    80000050:	00897913          	andi	s2,s2,8
    80000054:	fe090ae3          	beqz	s2,80000048 <_start+0x48>
    80000058:	020004b7          	lui	s1,0x2000
    8000005c:	f1402973          	csrr	s2,mhartid
    80000060:	00291913          	slli	s2,s2,0x2
    80000064:	00990933          	add	s2,s2,s1
    80000068:	00092023          	sw	zero,0(s2) # 2000000 <_start-0x7e000000>
    8000006c:	0004a903          	lw	s2,0(s1) # 2000000 <_start-0x7e000000>
    80000070:	fe091ee3          	bnez	s2,8000006c <_start+0x6c>
    80000074:	00448493          	addi	s1,s1,4
    80000078:	02000937          	lui	s2,0x2000
    8000007c:	0109091b          	addiw	s2,s2,16
    80000080:	ff24c6e3          	blt	s1,s2,8000006c <_start+0x6c>

Disassembly of section .text:

0000000080000084 <write_reg_u8>:
#include "uart.h"

void write_reg_u8(uintptr_t addr, uint8_t value)
{
    80000084:	fe010113          	addi	sp,sp,-32
    80000088:	00a13423          	sd	a0,8(sp)
    8000008c:	00058793          	mv	a5,a1
    80000090:	00f103a3          	sb	a5,7(sp)
    volatile uint8_t *loc_addr = (volatile uint8_t *)addr;
    80000094:	00813783          	ld	a5,8(sp)
    80000098:	00f13c23          	sd	a5,24(sp)
    *loc_addr = value;
    8000009c:	01813783          	ld	a5,24(sp)
    800000a0:	00714703          	lbu	a4,7(sp)
    800000a4:	00e78023          	sb	a4,0(a5)
}
    800000a8:	00000013          	nop
    800000ac:	02010113          	addi	sp,sp,32
    800000b0:	00008067          	ret

00000000800000b4 <read_reg_u8>:

uint8_t read_reg_u8(uintptr_t addr)
{
    800000b4:	ff010113          	addi	sp,sp,-16
    800000b8:	00a13423          	sd	a0,8(sp)
    return *(volatile uint8_t *)addr;
    800000bc:	00813783          	ld	a5,8(sp)
    800000c0:	0007c783          	lbu	a5,0(a5)
    800000c4:	0ff7f793          	andi	a5,a5,255
}
    800000c8:	00078513          	mv	a0,a5
    800000cc:	01010113          	addi	sp,sp,16
    800000d0:	00008067          	ret

00000000800000d4 <is_transmit_empty>:

int is_transmit_empty()
{
    800000d4:	ff010113          	addi	sp,sp,-16
    800000d8:	00113423          	sd	ra,8(sp)
    return read_reg_u8(UART_LINE_STATUS) & 0x20;
    800000dc:	100007b7          	lui	a5,0x10000
    800000e0:	01478513          	addi	a0,a5,20 # 10000014 <_start-0x6fffffec>
    800000e4:	fd1ff0ef          	jal	ra,800000b4 <read_reg_u8>
    800000e8:	00050793          	mv	a5,a0
    800000ec:	0007879b          	sext.w	a5,a5
    800000f0:	0207f793          	andi	a5,a5,32
    800000f4:	0007879b          	sext.w	a5,a5
}
    800000f8:	00078513          	mv	a0,a5
    800000fc:	00813083          	ld	ra,8(sp)
    80000100:	01010113          	addi	sp,sp,16
    80000104:	00008067          	ret

0000000080000108 <write_serial>:

void write_serial(char a)
{
    80000108:	fe010113          	addi	sp,sp,-32
    8000010c:	00113c23          	sd	ra,24(sp)
    80000110:	00050793          	mv	a5,a0
    80000114:	00f107a3          	sb	a5,15(sp)
    while (is_transmit_empty() == 0) {};
    80000118:	00000013          	nop
    8000011c:	fb9ff0ef          	jal	ra,800000d4 <is_transmit_empty>
    80000120:	00050793          	mv	a5,a0
    80000124:	fe078ce3          	beqz	a5,8000011c <write_serial+0x14>

    write_reg_u8(UART_THR, a);
    80000128:	00f14783          	lbu	a5,15(sp)
    8000012c:	00078593          	mv	a1,a5
    80000130:	10000537          	lui	a0,0x10000
    80000134:	f51ff0ef          	jal	ra,80000084 <write_reg_u8>
}
    80000138:	00000013          	nop
    8000013c:	01813083          	ld	ra,24(sp)
    80000140:	02010113          	addi	sp,sp,32
    80000144:	00008067          	ret

0000000080000148 <init_uart>:

void init_uart(uint32_t freq, uint32_t baud)
{
    80000148:	fd010113          	addi	sp,sp,-48
    8000014c:	02113423          	sd	ra,40(sp)
    80000150:	00050793          	mv	a5,a0
    80000154:	00058713          	mv	a4,a1
    80000158:	00f12623          	sw	a5,12(sp)
    8000015c:	00070793          	mv	a5,a4
    80000160:	00f12423          	sw	a5,8(sp)
    uint32_t divisor = freq / (baud << 4);
    80000164:	00812783          	lw	a5,8(sp)
    80000168:	0047979b          	slliw	a5,a5,0x4
    8000016c:	0007879b          	sext.w	a5,a5
    80000170:	00c12703          	lw	a4,12(sp)
    80000174:	02f757bb          	divuw	a5,a4,a5
    80000178:	00f12e23          	sw	a5,28(sp)

    write_reg_u8(UART_INTERRUPT_ENABLE, 0x00); // Disable all interrupts
    8000017c:	00000593          	li	a1,0
    80000180:	100007b7          	lui	a5,0x10000
    80000184:	00478513          	addi	a0,a5,4 # 10000004 <_start-0x6ffffffc>
    80000188:	efdff0ef          	jal	ra,80000084 <write_reg_u8>
    write_reg_u8(UART_LINE_CONTROL, 0x80);     // Enable DLAB (set baud rate divisor)
    8000018c:	08000593          	li	a1,128
    80000190:	100007b7          	lui	a5,0x10000
    80000194:	00c78513          	addi	a0,a5,12 # 1000000c <_start-0x6ffffff4>
    80000198:	eedff0ef          	jal	ra,80000084 <write_reg_u8>
    write_reg_u8(UART_DLAB_LSB, divisor);         // divisor (lo byte)
    8000019c:	01c12783          	lw	a5,28(sp)
    800001a0:	0ff7f793          	andi	a5,a5,255
    800001a4:	00078593          	mv	a1,a5
    800001a8:	10000537          	lui	a0,0x10000
    800001ac:	ed9ff0ef          	jal	ra,80000084 <write_reg_u8>
    write_reg_u8(UART_DLAB_MSB, (divisor >> 8) & 0xFF);  // divisor (hi byte)
    800001b0:	01c12783          	lw	a5,28(sp)
    800001b4:	0087d79b          	srliw	a5,a5,0x8
    800001b8:	0007879b          	sext.w	a5,a5
    800001bc:	0ff7f793          	andi	a5,a5,255
    800001c0:	00078593          	mv	a1,a5
    800001c4:	100007b7          	lui	a5,0x10000
    800001c8:	00478513          	addi	a0,a5,4 # 10000004 <_start-0x6ffffffc>
    800001cc:	eb9ff0ef          	jal	ra,80000084 <write_reg_u8>
    write_reg_u8(UART_LINE_CONTROL, 0x03);     // 8 bits, no parity, one stop bit
    800001d0:	00300593          	li	a1,3
    800001d4:	100007b7          	lui	a5,0x10000
    800001d8:	00c78513          	addi	a0,a5,12 # 1000000c <_start-0x6ffffff4>
    800001dc:	ea9ff0ef          	jal	ra,80000084 <write_reg_u8>
    write_reg_u8(UART_FIFO_CONTROL, 0xC7);     // Enable FIFO, clear them, with 14-byte threshold
    800001e0:	0c700593          	li	a1,199
    800001e4:	100007b7          	lui	a5,0x10000
    800001e8:	00878513          	addi	a0,a5,8 # 10000008 <_start-0x6ffffff8>
    800001ec:	e99ff0ef          	jal	ra,80000084 <write_reg_u8>
    write_reg_u8(UART_MODEM_CONTROL, 0x20);    // Autoflow mode
    800001f0:	02000593          	li	a1,32
    800001f4:	100007b7          	lui	a5,0x10000
    800001f8:	01078513          	addi	a0,a5,16 # 10000010 <_start-0x6ffffff0>
    800001fc:	e89ff0ef          	jal	ra,80000084 <write_reg_u8>
}
    80000200:	00000013          	nop
    80000204:	02813083          	ld	ra,40(sp)
    80000208:	03010113          	addi	sp,sp,48
    8000020c:	00008067          	ret

0000000080000210 <print_uart>:

void print_uart(const char *str)
{
    80000210:	fd010113          	addi	sp,sp,-48
    80000214:	02113423          	sd	ra,40(sp)
    80000218:	00a13423          	sd	a0,8(sp)
    const char *cur = &str[0];
    8000021c:	00813783          	ld	a5,8(sp)
    80000220:	00f13c23          	sd	a5,24(sp)
    while (*cur != '\0')
    80000224:	0200006f          	j	80000244 <print_uart+0x34>
    {
        write_serial((uint8_t)*cur);
    80000228:	01813783          	ld	a5,24(sp)
    8000022c:	0007c783          	lbu	a5,0(a5)
    80000230:	00078513          	mv	a0,a5
    80000234:	ed5ff0ef          	jal	ra,80000108 <write_serial>
        ++cur;
    80000238:	01813783          	ld	a5,24(sp)
    8000023c:	00178793          	addi	a5,a5,1
    80000240:	00f13c23          	sd	a5,24(sp)
    while (*cur != '\0')
    80000244:	01813783          	ld	a5,24(sp)
    80000248:	0007c783          	lbu	a5,0(a5)
    8000024c:	fc079ee3          	bnez	a5,80000228 <print_uart+0x18>
    }
}
    80000250:	00000013          	nop
    80000254:	02813083          	ld	ra,40(sp)
    80000258:	03010113          	addi	sp,sp,48
    8000025c:	00008067          	ret

0000000080000260 <bin_to_hex>:

uint8_t bin_to_hex_table[16] = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

void bin_to_hex(uint8_t inp, uint8_t res[2])
{
    80000260:	ff010113          	addi	sp,sp,-16
    80000264:	00050793          	mv	a5,a0
    80000268:	00b13023          	sd	a1,0(sp)
    8000026c:	00f107a3          	sb	a5,15(sp)
    res[1] = bin_to_hex_table[inp & 0xf];
    80000270:	00f14783          	lbu	a5,15(sp)
    80000274:	0007879b          	sext.w	a5,a5
    80000278:	00f7f793          	andi	a5,a5,15
    8000027c:	0007871b          	sext.w	a4,a5
    80000280:	00013783          	ld	a5,0(sp)
    80000284:	00178793          	addi	a5,a5,1
    80000288:	00001697          	auipc	a3,0x1
    8000028c:	d7868693          	addi	a3,a3,-648 # 80001000 <bin_to_hex_table>
    80000290:	00e68733          	add	a4,a3,a4
    80000294:	00074703          	lbu	a4,0(a4)
    80000298:	00e78023          	sb	a4,0(a5)
    res[0] = bin_to_hex_table[(inp >> 4) & 0xf];
    8000029c:	00f14783          	lbu	a5,15(sp)
    800002a0:	0047d79b          	srliw	a5,a5,0x4
    800002a4:	0ff7f793          	andi	a5,a5,255
    800002a8:	0007879b          	sext.w	a5,a5
    800002ac:	00f7f793          	andi	a5,a5,15
    800002b0:	0007879b          	sext.w	a5,a5
    800002b4:	00001717          	auipc	a4,0x1
    800002b8:	d4c70713          	addi	a4,a4,-692 # 80001000 <bin_to_hex_table>
    800002bc:	00f707b3          	add	a5,a4,a5
    800002c0:	0007c703          	lbu	a4,0(a5)
    800002c4:	00013783          	ld	a5,0(sp)
    800002c8:	00e78023          	sb	a4,0(a5)
    return;
    800002cc:	00000013          	nop
}
    800002d0:	01010113          	addi	sp,sp,16
    800002d4:	00008067          	ret

00000000800002d8 <print_uart_int>:

void print_uart_int(uint32_t addr)
{
    800002d8:	fd010113          	addi	sp,sp,-48
    800002dc:	02113423          	sd	ra,40(sp)
    800002e0:	00050793          	mv	a5,a0
    800002e4:	00f12623          	sw	a5,12(sp)
    int i;
    for (i = 3; i > -1; i--)
    800002e8:	00300793          	li	a5,3
    800002ec:	00f12e23          	sw	a5,28(sp)
    800002f0:	05c0006f          	j	8000034c <print_uart_int+0x74>
    {
        uint8_t cur = (addr >> (i * 8)) & 0xff;
    800002f4:	01c12783          	lw	a5,28(sp)
    800002f8:	0037979b          	slliw	a5,a5,0x3
    800002fc:	0007879b          	sext.w	a5,a5
    80000300:	00078713          	mv	a4,a5
    80000304:	00c12783          	lw	a5,12(sp)
    80000308:	00e7d7bb          	srlw	a5,a5,a4
    8000030c:	0007879b          	sext.w	a5,a5
    80000310:	00f10da3          	sb	a5,27(sp)
        uint8_t hex[2];
        bin_to_hex(cur, hex);
    80000314:	01810713          	addi	a4,sp,24
    80000318:	01b14783          	lbu	a5,27(sp)
    8000031c:	00070593          	mv	a1,a4
    80000320:	00078513          	mv	a0,a5
    80000324:	f3dff0ef          	jal	ra,80000260 <bin_to_hex>
        write_serial(hex[0]);
    80000328:	01814783          	lbu	a5,24(sp)
    8000032c:	00078513          	mv	a0,a5
    80000330:	dd9ff0ef          	jal	ra,80000108 <write_serial>
        write_serial(hex[1]);
    80000334:	01914783          	lbu	a5,25(sp)
    80000338:	00078513          	mv	a0,a5
    8000033c:	dcdff0ef          	jal	ra,80000108 <write_serial>
    for (i = 3; i > -1; i--)
    80000340:	01c12783          	lw	a5,28(sp)
    80000344:	fff7879b          	addiw	a5,a5,-1
    80000348:	00f12e23          	sw	a5,28(sp)
    8000034c:	01c12783          	lw	a5,28(sp)
    80000350:	0007879b          	sext.w	a5,a5
    80000354:	fa07d0e3          	bgez	a5,800002f4 <print_uart_int+0x1c>
    }
}
    80000358:	00000013          	nop
    8000035c:	02813083          	ld	ra,40(sp)
    80000360:	03010113          	addi	sp,sp,48
    80000364:	00008067          	ret

0000000080000368 <print_uart_addr>:

void print_uart_addr(uint64_t addr)
{
    80000368:	fd010113          	addi	sp,sp,-48
    8000036c:	02113423          	sd	ra,40(sp)
    80000370:	00a13423          	sd	a0,8(sp)
    int i;
    for (i = 7; i > -1; i--)
    80000374:	00700793          	li	a5,7
    80000378:	00f12e23          	sw	a5,28(sp)
    8000037c:	0580006f          	j	800003d4 <print_uart_addr+0x6c>
    {
        uint8_t cur = (addr >> (i * 8)) & 0xff;
    80000380:	01c12783          	lw	a5,28(sp)
    80000384:	0037979b          	slliw	a5,a5,0x3
    80000388:	0007879b          	sext.w	a5,a5
    8000038c:	00078713          	mv	a4,a5
    80000390:	00813783          	ld	a5,8(sp)
    80000394:	00e7d7b3          	srl	a5,a5,a4
    80000398:	00f10da3          	sb	a5,27(sp)
        uint8_t hex[2];
        bin_to_hex(cur, hex);
    8000039c:	01810713          	addi	a4,sp,24
    800003a0:	01b14783          	lbu	a5,27(sp)
    800003a4:	00070593          	mv	a1,a4
    800003a8:	00078513          	mv	a0,a5
    800003ac:	eb5ff0ef          	jal	ra,80000260 <bin_to_hex>
        write_serial(hex[0]);
    800003b0:	01814783          	lbu	a5,24(sp)
    800003b4:	00078513          	mv	a0,a5
    800003b8:	d51ff0ef          	jal	ra,80000108 <write_serial>
        write_serial(hex[1]);
    800003bc:	01914783          	lbu	a5,25(sp)
    800003c0:	00078513          	mv	a0,a5
    800003c4:	d45ff0ef          	jal	ra,80000108 <write_serial>
    for (i = 7; i > -1; i--)
    800003c8:	01c12783          	lw	a5,28(sp)
    800003cc:	fff7879b          	addiw	a5,a5,-1
    800003d0:	00f12e23          	sw	a5,28(sp)
    800003d4:	01c12783          	lw	a5,28(sp)
    800003d8:	0007879b          	sext.w	a5,a5
    800003dc:	fa07d2e3          	bgez	a5,80000380 <print_uart_addr+0x18>
    }
}
    800003e0:	00000013          	nop
    800003e4:	02813083          	ld	ra,40(sp)
    800003e8:	03010113          	addi	sp,sp,48
    800003ec:	00008067          	ret

00000000800003f0 <print_uart_byte>:

void print_uart_byte(uint8_t byte)
{
    800003f0:	fd010113          	addi	sp,sp,-48
    800003f4:	02113423          	sd	ra,40(sp)
    800003f8:	00050793          	mv	a5,a0
    800003fc:	00f107a3          	sb	a5,15(sp)
    uint8_t hex[2];
    bin_to_hex(byte, hex);
    80000400:	01810713          	addi	a4,sp,24
    80000404:	00f14783          	lbu	a5,15(sp)
    80000408:	00070593          	mv	a1,a4
    8000040c:	00078513          	mv	a0,a5
    80000410:	e51ff0ef          	jal	ra,80000260 <bin_to_hex>
    write_serial(hex[0]);
    80000414:	01814783          	lbu	a5,24(sp)
    80000418:	00078513          	mv	a0,a5
    8000041c:	cedff0ef          	jal	ra,80000108 <write_serial>
    write_serial(hex[1]);
    80000420:	01914783          	lbu	a5,25(sp)
    80000424:	00078513          	mv	a0,a5
    80000428:	ce1ff0ef          	jal	ra,80000108 <write_serial>
    8000042c:	00000013          	nop
    80000430:	02813083          	ld	ra,40(sp)
    80000434:	03010113          	addi	sp,sp,48
    80000438:	00008067          	ret

000000008000043c <write_reg_u64>:
#include "npu.h"
#include "uart.h"

void write_reg_u64(uintptr_t addr, uint64_t value)
{
    8000043c:	fe010113          	addi	sp,sp,-32
    80000440:	00a13423          	sd	a0,8(sp)
    80000444:	00b13023          	sd	a1,0(sp)
    volatile uint64_t *loc_addr = (volatile uint64_t *)addr;
    80000448:	00813783          	ld	a5,8(sp)
    8000044c:	00f13c23          	sd	a5,24(sp)
    *loc_addr = value;
    80000450:	01813783          	ld	a5,24(sp)
    80000454:	00013703          	ld	a4,0(sp)
    80000458:	00e7b023          	sd	a4,0(a5)
}
    8000045c:	00000013          	nop
    80000460:	02010113          	addi	sp,sp,32
    80000464:	00008067          	ret

0000000080000468 <write_reg_u32>:
void write_reg_u32(uintptr_t addr, uint32_t value)
{
    80000468:	fe010113          	addi	sp,sp,-32
    8000046c:	00a13423          	sd	a0,8(sp)
    80000470:	00058793          	mv	a5,a1
    80000474:	00f12223          	sw	a5,4(sp)
    volatile uint32_t *loc_addr = (volatile uint32_t *)addr;
    80000478:	00813783          	ld	a5,8(sp)
    8000047c:	00f13c23          	sd	a5,24(sp)
    *loc_addr = value;
    80000480:	01813783          	ld	a5,24(sp)
    80000484:	00412703          	lw	a4,4(sp)
    80000488:	00e7a023          	sw	a4,0(a5)
}
    8000048c:	00000013          	nop
    80000490:	02010113          	addi	sp,sp,32
    80000494:	00008067          	ret

0000000080000498 <sleep_us>:

void sleep_us(int us)
{
    80000498:	fe010113          	addi	sp,sp,-32
    8000049c:	00050793          	mv	a5,a0
    800004a0:	00f12623          	sw	a5,12(sp)
    for (int i=0;i<us;i++) {} 
    800004a4:	00012e23          	sw	zero,28(sp)
    800004a8:	0100006f          	j	800004b8 <sleep_us+0x20>
    800004ac:	01c12783          	lw	a5,28(sp)
    800004b0:	0017879b          	addiw	a5,a5,1
    800004b4:	00f12e23          	sw	a5,28(sp)
    800004b8:	01c12703          	lw	a4,28(sp)
    800004bc:	00c12783          	lw	a5,12(sp)
    800004c0:	0007071b          	sext.w	a4,a4
    800004c4:	0007879b          	sext.w	a5,a5
    800004c8:	fef742e3          	blt	a4,a5,800004ac <sleep_us+0x14>
}
    800004cc:	00000013          	nop
    800004d0:	02010113          	addi	sp,sp,32
    800004d4:	00008067          	ret

00000000800004d8 <clr_reg>:

static inline void clr_reg(uint32_t addr, int loc){
    800004d8:	fd010113          	addi	sp,sp,-48
    800004dc:	02113423          	sd	ra,40(sp)
    800004e0:	00050793          	mv	a5,a0
    800004e4:	00058713          	mv	a4,a1
    800004e8:	00f12623          	sw	a5,12(sp)
    800004ec:	00070793          	mv	a5,a4
    800004f0:	00f12423          	sw	a5,8(sp)
    uint32_t mask = 0x1 << loc;
    800004f4:	00812783          	lw	a5,8(sp)
    800004f8:	00100713          	li	a4,1
    800004fc:	00f717bb          	sllw	a5,a4,a5
    80000500:	0007879b          	sext.w	a5,a5
    80000504:	00f12e23          	sw	a5,28(sp)
    uint32_t val = *(volatile uint32_t *)addr;
    80000508:	00c16783          	lwu	a5,12(sp)
    8000050c:	0007a783          	lw	a5,0(a5)
    80000510:	00f12c23          	sw	a5,24(sp)
    write_reg_u32(addr, val & (~mask));   
    80000514:	00c16703          	lwu	a4,12(sp)
    80000518:	01c12783          	lw	a5,28(sp)
    8000051c:	fff7c793          	not	a5,a5
    80000520:	0007869b          	sext.w	a3,a5
    80000524:	01812783          	lw	a5,24(sp)
    80000528:	00d7f7b3          	and	a5,a5,a3
    8000052c:	0007879b          	sext.w	a5,a5
    80000530:	00078593          	mv	a1,a5
    80000534:	00070513          	mv	a0,a4
    80000538:	f31ff0ef          	jal	ra,80000468 <write_reg_u32>
}
    8000053c:	00000013          	nop
    80000540:	02813083          	ld	ra,40(sp)
    80000544:	03010113          	addi	sp,sp,48
    80000548:	00008067          	ret

000000008000054c <set_reg>:

static inline void set_reg(uint32_t addr, int loc){
    8000054c:	fd010113          	addi	sp,sp,-48
    80000550:	02113423          	sd	ra,40(sp)
    80000554:	00050793          	mv	a5,a0
    80000558:	00058713          	mv	a4,a1
    8000055c:	00f12623          	sw	a5,12(sp)
    80000560:	00070793          	mv	a5,a4
    80000564:	00f12423          	sw	a5,8(sp)
    uint32_t mask = 0x1 << loc;
    80000568:	00812783          	lw	a5,8(sp)
    8000056c:	00100713          	li	a4,1
    80000570:	00f717bb          	sllw	a5,a4,a5
    80000574:	0007879b          	sext.w	a5,a5
    80000578:	00f12e23          	sw	a5,28(sp)
    uint32_t val = *(volatile uint32_t *)addr;
    8000057c:	00c16783          	lwu	a5,12(sp)
    80000580:	0007a783          	lw	a5,0(a5)
    80000584:	00f12c23          	sw	a5,24(sp)
    write_reg_u32(addr, val | mask);   
    80000588:	00c16683          	lwu	a3,12(sp)
    8000058c:	01812703          	lw	a4,24(sp)
    80000590:	01c12783          	lw	a5,28(sp)
    80000594:	00f767b3          	or	a5,a4,a5
    80000598:	0007879b          	sext.w	a5,a5
    8000059c:	00078593          	mv	a1,a5
    800005a0:	00068513          	mv	a0,a3
    800005a4:	ec5ff0ef          	jal	ra,80000468 <write_reg_u32>
}
    800005a8:	00000013          	nop
    800005ac:	02813083          	ld	ra,40(sp)
    800005b0:	03010113          	addi	sp,sp,48
    800005b4:	00008067          	ret

00000000800005b8 <init_npu>:
int init_npu(){
    800005b8:	ff010113          	addi	sp,sp,-16
    800005bc:	00113423          	sd	ra,8(sp)
    write_reg_u64(NPU_BASE_ADDR, 0xA0000000);
    800005c0:	00500793          	li	a5,5
    800005c4:	01d79593          	slli	a1,a5,0x1d
    800005c8:	000027b7          	lui	a5,0x2
    800005cc:	03078513          	addi	a0,a5,48 # 2030 <_start-0x7fffdfd0>
    800005d0:	e6dff0ef          	jal	ra,8000043c <write_reg_u64>
    print_uart("[INFO]: init npu success\n");
    800005d4:	00000517          	auipc	a0,0x0
    800005d8:	18c50513          	addi	a0,a0,396 # 80000760 <main+0x4c>
    800005dc:	c35ff0ef          	jal	ra,80000210 <print_uart>
    return 0;
    800005e0:	00000793          	li	a5,0
}
    800005e4:	00078513          	mv	a0,a5
    800005e8:	00813083          	ld	ra,8(sp)
    800005ec:	01010113          	addi	sp,sp,16
    800005f0:	00008067          	ret

00000000800005f4 <start_npu>:

int start_npu(int fd){
    800005f4:	fe010113          	addi	sp,sp,-32
    800005f8:	00113c23          	sd	ra,24(sp)
    800005fc:	00050793          	mv	a5,a0
    80000600:	00f12623          	sw	a5,12(sp)
    clr_reg(NPU_CTRL, START_OFFSET);
    80000604:	00000593          	li	a1,0
    80000608:	000027b7          	lui	a5,0x2
    8000060c:	02078513          	addi	a0,a5,32 # 2020 <_start-0x7fffdfe0>
    80000610:	ec9ff0ef          	jal	ra,800004d8 <clr_reg>
    clr_reg(NPU_CTRL, FETCH_EN_OFFSET);
    80000614:	00300593          	li	a1,3
    80000618:	000027b7          	lui	a5,0x2
    8000061c:	02078513          	addi	a0,a5,32 # 2020 <_start-0x7fffdfe0>
    80000620:	eb9ff0ef          	jal	ra,800004d8 <clr_reg>
    set_reg(NPU_CTRL, FETCH_EN_OFFSET);
    80000624:	00300593          	li	a1,3
    80000628:	000027b7          	lui	a5,0x2
    8000062c:	02078513          	addi	a0,a5,32 # 2020 <_start-0x7fffdfe0>
    80000630:	f1dff0ef          	jal	ra,8000054c <set_reg>
    print_uart("[INFO]: start npu success\n");
    80000634:	00000517          	auipc	a0,0x0
    80000638:	14c50513          	addi	a0,a0,332 # 80000780 <main+0x6c>
    8000063c:	bd5ff0ef          	jal	ra,80000210 <print_uart>
    return 0;
    80000640:	00000793          	li	a5,0

}
    80000644:	00078513          	mv	a0,a5
    80000648:	01813083          	ld	ra,24(sp)
    8000064c:	02010113          	addi	sp,sp,32
    80000650:	00008067          	ret

0000000080000654 <start_conv>:
int start_conv(int fd){
    80000654:	fe010113          	addi	sp,sp,-32
    80000658:	00113c23          	sd	ra,24(sp)
    8000065c:	00050793          	mv	a5,a0
    80000660:	00f12623          	sw	a5,12(sp)
    set_reg(NPU_CTRL, START_OFFSET);
    80000664:	00000593          	li	a1,0
    80000668:	000027b7          	lui	a5,0x2
    8000066c:	02078513          	addi	a0,a5,32 # 2020 <_start-0x7fffdfe0>
    80000670:	eddff0ef          	jal	ra,8000054c <set_reg>
    clr_reg(NPU_CTRL, START_OFFSET);
    80000674:	00000593          	li	a1,0
    80000678:	000027b7          	lui	a5,0x2
    8000067c:	02078513          	addi	a0,a5,32 # 2020 <_start-0x7fffdfe0>
    80000680:	e59ff0ef          	jal	ra,800004d8 <clr_reg>
    print_uart("[INFO]: start conv success\n");
    80000684:	00000517          	auipc	a0,0x0
    80000688:	11c50513          	addi	a0,a0,284 # 800007a0 <main+0x8c>
    8000068c:	b85ff0ef          	jal	ra,80000210 <print_uart>
    return 0;
    80000690:	00000793          	li	a5,0
}
    80000694:	00078513          	mv	a0,a5
    80000698:	01813083          	ld	ra,24(sp)
    8000069c:	02010113          	addi	sp,sp,32
    800006a0:	00008067          	ret

00000000800006a4 <wait_npu_done>:

int wait_npu_done(int fd){
    800006a4:	fd010113          	addi	sp,sp,-48
    800006a8:	02113423          	sd	ra,40(sp)
    800006ac:	00050793          	mv	a5,a0
    800006b0:	00f12623          	sw	a5,12(sp)
    uint32_t state;
    uint32_t addr = NPU_DONE;
    800006b4:	000027b7          	lui	a5,0x2
    800006b8:	0507879b          	addiw	a5,a5,80
    800006bc:	00f12c23          	sw	a5,24(sp)
    state = *(volatile uint32_t *)addr;
    800006c0:	01816783          	lwu	a5,24(sp)
    800006c4:	0007a783          	lw	a5,0(a5) # 2000 <_start-0x7fffe000>
    800006c8:	00f12e23          	sw	a5,28(sp)
    while (state == 0){
    800006cc:	0180006f          	j	800006e4 <wait_npu_done+0x40>
        sleep_us(2000);
    800006d0:	7d000513          	li	a0,2000
    800006d4:	dc5ff0ef          	jal	ra,80000498 <sleep_us>
        state = *(volatile uint32_t *)addr;
    800006d8:	01816783          	lwu	a5,24(sp)
    800006dc:	0007a783          	lw	a5,0(a5)
    800006e0:	00f12e23          	sw	a5,28(sp)
    while (state == 0){
    800006e4:	01c12783          	lw	a5,28(sp)
    800006e8:	0007879b          	sext.w	a5,a5
    800006ec:	fe0782e3          	beqz	a5,800006d0 <wait_npu_done+0x2c>
    }
    // clear done state
    write_reg_u32(NPU_DONE, 0x0);
    800006f0:	00000593          	li	a1,0
    800006f4:	000027b7          	lui	a5,0x2
    800006f8:	05078513          	addi	a0,a5,80 # 2050 <_start-0x7fffdfb0>
    800006fc:	d6dff0ef          	jal	ra,80000468 <write_reg_u32>
    return 0;
    80000700:	00000793          	li	a5,0
    80000704:	00078513          	mv	a0,a5
    80000708:	02813083          	ld	ra,40(sp)
    8000070c:	03010113          	addi	sp,sp,48
    80000710:	00008067          	ret

0000000080000714 <main>:
#include "uart.h"
#include "npu.h"


int main()
{
    80000714:	ff010113          	addi	sp,sp,-16
    80000718:	00113423          	sd	ra,8(sp)
    init_uart(50000000, 115200);
    8000071c:	0001c7b7          	lui	a5,0x1c
    80000720:	20078593          	addi	a1,a5,512 # 1c200 <_start-0x7ffe3e00>
    80000724:	02faf7b7          	lui	a5,0x2faf
    80000728:	08078513          	addi	a0,a5,128 # 2faf080 <_start-0x7d050f80>
    8000072c:	a1dff0ef          	jal	ra,80000148 <init_uart>
    print_uart("Hello World!\r\n");
    80000730:	00000517          	auipc	a0,0x0
    80000734:	09050513          	addi	a0,a0,144 # 800007c0 <main+0xac>
    80000738:	ad9ff0ef          	jal	ra,80000210 <print_uart>
    
    init_npu();
    8000073c:	e7dff0ef          	jal	ra,800005b8 <init_npu>
    start_npu();
    80000740:	eb5ff0ef          	jal	ra,800005f4 <start_npu>
    start_conv();
    80000744:	f11ff0ef          	jal	ra,80000654 <start_conv>
    wait_npu_done();
    80000748:	f5dff0ef          	jal	ra,800006a4 <wait_npu_done>
    print_uart("Convolution Finish!\r\n");
    8000074c:	00000517          	auipc	a0,0x0
    80000750:	08450513          	addi	a0,a0,132 # 800007d0 <main+0xbc>
    80000754:	abdff0ef          	jal	ra,80000210 <print_uart>

    while (1);  // do nothing
    80000758:	0000006f          	j	80000758 <main+0x44>

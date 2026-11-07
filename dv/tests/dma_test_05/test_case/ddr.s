
build_src/ddr.elf:     file format elf64-littleriscv
build_src/ddr.elf
architecture: riscv:rv64, flags 0x00000112:
EXEC_P, HAS_SYMS, D_PAGED
start address 0x0000000080000000

Program Header:
    LOAD off    0x0000000000001000 vaddr 0x0000000080000000 paddr 0x0000000080000000 align 2**12
         filesz 0x0000000000000620 memsz 0x0000000000000620 flags r-x
    LOAD off    0x0000000000002000 vaddr 0x0000000080001000 paddr 0x0000000080001000 align 2**12
         filesz 0x0000000000002020 memsz 0x0000000000002020 flags rw-

Sections:
Idx Name          Size      VMA               LMA               File off  Algn
  0 .text.boot    00000084  0000000080000000  0000000080000000  00001000  2**0
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .text         000004b0  0000000080000084  0000000080000084  00001084  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  2 .text.startup 000000d0  0000000080000534  0000000080000534  00001534  2**2
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  3 .rodata.str1.8 00000018  0000000080000608  0000000080000608  00001608  2**3
                  CONTENTS, ALLOC, LOAD, READONLY, DATA
  4 .data         00002000  0000000080001000  0000000080001000  00002000  2**12
                  CONTENTS, ALLOC, LOAD, DATA
  5 .sdata        00000020  0000000080003000  0000000080003000  00004000  2**3
                  CONTENTS, ALLOC, LOAD, DATA
  6 .debug_info   00000f57  0000000000000000  0000000000000000  00004020  2**0
                  CONTENTS, READONLY, DEBUGGING
  7 .debug_abbrev 00000555  0000000000000000  0000000000000000  00004f77  2**0
                  CONTENTS, READONLY, DEBUGGING
  8 .debug_loc    000006a7  0000000000000000  0000000000000000  000054cc  2**0
                  CONTENTS, READONLY, DEBUGGING
  9 .debug_aranges 00000100  0000000000000000  0000000000000000  00005b80  2**4
                  CONTENTS, READONLY, DEBUGGING
 10 .debug_line   00000c84  0000000000000000  0000000000000000  00005c80  2**0
                  CONTENTS, READONLY, DEBUGGING
 11 .debug_str    0000038b  0000000000000000  0000000000000000  00006904  2**0
                  CONTENTS, READONLY, DEBUGGING
 12 .comment      00000011  0000000000000000  0000000000000000  00006c8f  2**0
                  CONTENTS, READONLY
 13 .debug_frame  000003b8  0000000000000000  0000000000000000  00006ca0  2**3
                  CONTENTS, READONLY, DEBUGGING
 14 .debug_ranges 000000c0  0000000000000000  0000000000000000  00007058  2**0
                  CONTENTS, READONLY, DEBUGGING
SYMBOL TABLE:
0000000080000000 l    d  .text.boot	0000000000000000 .text.boot
0000000080000084 l    d  .text	0000000000000000 .text
0000000080000534 l    d  .text.startup	0000000000000000 .text.startup
0000000080000608 l    d  .rodata.str1.8	0000000000000000 .rodata.str1.8
0000000080001000 l    d  .data	0000000000000000 .data
0000000080003000 l    d  .sdata	0000000000000000 .sdata
0000000000000000 l    d  .debug_info	0000000000000000 .debug_info
0000000000000000 l    d  .debug_abbrev	0000000000000000 .debug_abbrev
0000000000000000 l    d  .debug_loc	0000000000000000 .debug_loc
0000000000000000 l    d  .debug_aranges	0000000000000000 .debug_aranges
0000000000000000 l    d  .debug_line	0000000000000000 .debug_line
0000000000000000 l    d  .debug_str	0000000000000000 .debug_str
0000000000000000 l    d  .comment	0000000000000000 .comment
0000000000000000 l    d  .debug_frame	0000000000000000 .debug_frame
0000000000000000 l    d  .debug_ranges	0000000000000000 .debug_ranges
0000000000000000 l    df *ABS*	0000000000000000 uart.c
0000000000000000 l    df *ABS*	0000000000000000 main.c
0000000000000000 l    df *ABS*	0000000000000000 dma.c
0000000000000000 l    df *ABS*	0000000000000000 utils.c
00000000800000a8 g     F .text	000000000000002c write_serial
0000000080003010 g     O .sdata	0000000000000008 ref_arr
0000000080000220 g     F .text	0000000000000060 print_uart_addr
0000000080000464 g     F .text	0000000000000010 Dma_start
00000000800000d4 g     F .text	000000000000008c init_uart
000000008000033c g     F .text	0000000000000060 Dma_init
00000000800001c0 g     F .text	0000000000000060 print_uart_int
0000000080000280 g     F .text	000000000000002c print_uart_byte
0000000080003000 g     O .sdata	0000000000000004 trans_size
0000000080000474 g     F .text	0000000000000024 is_read_pending
0000000080000524 g     F .text	0000000000000008 write_reg_u32
0000000080000000 g       .text.boot	0000000000000000 _start
0000000080003020 g       .sdata	0000000000000000 bss_end
000000008000052c g     F .text	0000000000000008 write_reg_u8
0000000080000194 g     F .text	000000000000002c bin_to_hex
0000000080003008 g     O .sdata	0000000000000008 dst_arr
0000000080003018 g     O .sdata	0000000000000008 src_arr
0000000080000338 g     F .text	0000000000000004 delay_us
0000000080000084 g     F .text	0000000000000024 is_transmit_empty
0000000080000534 g     F .text.startup	00000000000000d0 main
0000000080002000 g       .data	0000000000000000 stacks_start
0000000080000160 g     F .text	0000000000000034 print_uart
000000008000039c g     F .text	00000000000000c8 Dma_trans_cfg
00000000800002ac g     F .text	000000000000008c dma_check
000000008000051c g     F .text	0000000000000008 write_reg_u64
00000000800004f0 g     F .text	0000000000000010 flush_done
0000000080000500 g     F .text	0000000000000008 write_reg
0000000080003020 g       .sdata	0000000000000000 bss_begin
0000000080000508 g     F .text	000000000000000c read_reg
0000000080001000 g     O .data	0000000000000010 bin_to_hex_table
0000000080000498 g     F .text	0000000000000034 clear_read_pending
0000000080000514 g     F .text	0000000000000008 read_reg_u8
00000000800004cc g     F .text	0000000000000024 is_Dma_done



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
    80000028:	50c0006f          	j	80000534 <main>

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

0000000080000084 <is_transmit_empty>:
#include "uart.h"
#include "utils.h"

int is_transmit_empty()
{
    return read_reg_u8(UART_LINE_STATUS) & 0x20;
    80000084:	41810537          	lui	a0,0x41810
{
    80000088:	ff010113          	addi	sp,sp,-16
    return read_reg_u8(UART_LINE_STATUS) & 0x20;
    8000008c:	01450513          	addi	a0,a0,20 # 41810014 <_start-0x3e7effec>
{
    80000090:	00113423          	sd	ra,8(sp)
    return read_reg_u8(UART_LINE_STATUS) & 0x20;
    80000094:	480000ef          	jal	ra,80000514 <read_reg_u8>
}
    80000098:	00813083          	ld	ra,8(sp)
    8000009c:	02057513          	andi	a0,a0,32
    800000a0:	01010113          	addi	sp,sp,16
    800000a4:	00008067          	ret

00000000800000a8 <write_serial>:

void write_serial(char a)
{
    800000a8:	fe010113          	addi	sp,sp,-32
    800000ac:	00113c23          	sd	ra,24(sp)
    800000b0:	00050593          	mv	a1,a0
    while (is_transmit_empty() == 0) {};
    800000b4:	00b13423          	sd	a1,8(sp)
    800000b8:	fcdff0ef          	jal	ra,80000084 <is_transmit_empty>
    800000bc:	00813583          	ld	a1,8(sp)
    800000c0:	fe050ae3          	beqz	a0,800000b4 <write_serial+0xc>

    write_reg_u8(UART_THR, a);
}
    800000c4:	01813083          	ld	ra,24(sp)
    write_reg_u8(UART_THR, a);
    800000c8:	41810537          	lui	a0,0x41810
}
    800000cc:	02010113          	addi	sp,sp,32
    write_reg_u8(UART_THR, a);
    800000d0:	45c0006f          	j	8000052c <write_reg_u8>

00000000800000d4 <init_uart>:

void init_uart(uint32_t freq, uint32_t baud)
{
    800000d4:	fe010113          	addi	sp,sp,-32
    uint32_t divisor = freq / (baud << 4);
    800000d8:	0045959b          	slliw	a1,a1,0x4
{
    800000dc:	01213023          	sd	s2,0(sp)
    uint32_t divisor = freq / (baud << 4);
    800000e0:	02b5593b          	divuw	s2,a0,a1
{
    800000e4:	00813823          	sd	s0,16(sp)

    write_reg_u8(UART_INTERRUPT_ENABLE, 0x00); // Disable all interrupts
    800000e8:	41810437          	lui	s0,0x41810
    800000ec:	00440513          	addi	a0,s0,4 # 41810004 <_start-0x3e7efffc>
    800000f0:	00000593          	li	a1,0
{
    800000f4:	00113c23          	sd	ra,24(sp)
    800000f8:	00913423          	sd	s1,8(sp)
    write_reg_u8(UART_INTERRUPT_ENABLE, 0x00); // Disable all interrupts
    800000fc:	430000ef          	jal	ra,8000052c <write_reg_u8>
    write_reg_u8(UART_LINE_CONTROL, 0x80);     // Enable DLAB (set baud rate divisor)
    80000100:	00c40513          	addi	a0,s0,12
    80000104:	08000593          	li	a1,128
    80000108:	424000ef          	jal	ra,8000052c <write_reg_u8>
    write_reg_u8(UART_DLAB_LSB, divisor);         // divisor (lo byte)
    8000010c:	41810537          	lui	a0,0x41810
    80000110:	0ff97593          	andi	a1,s2,255
    80000114:	418000ef          	jal	ra,8000052c <write_reg_u8>
    write_reg_u8(UART_DLAB_MSB, (divisor >> 8) & 0xFF);  // divisor (hi byte)
    80000118:	0089559b          	srliw	a1,s2,0x8
    8000011c:	00440513          	addi	a0,s0,4
    80000120:	0ff5f593          	andi	a1,a1,255
    80000124:	408000ef          	jal	ra,8000052c <write_reg_u8>
    write_reg_u8(UART_LINE_CONTROL, 0x03);     // 8 bits, no parity, one stop bit
    80000128:	00c40513          	addi	a0,s0,12
    8000012c:	00300593          	li	a1,3
    80000130:	3fc000ef          	jal	ra,8000052c <write_reg_u8>
    write_reg_u8(UART_FIFO_CONTROL, 0xC7);     // Enable FIFO, clear them, with 14-byte threshold
    80000134:	00840513          	addi	a0,s0,8
    80000138:	0c700593          	li	a1,199
    8000013c:	3f0000ef          	jal	ra,8000052c <write_reg_u8>
    write_reg_u8(UART_MODEM_CONTROL, 0x20);    // Autoflow mode
    80000140:	01040513          	addi	a0,s0,16
}
    80000144:	01013403          	ld	s0,16(sp)
    80000148:	01813083          	ld	ra,24(sp)
    8000014c:	00813483          	ld	s1,8(sp)
    80000150:	00013903          	ld	s2,0(sp)
    write_reg_u8(UART_MODEM_CONTROL, 0x20);    // Autoflow mode
    80000154:	02000593          	li	a1,32
}
    80000158:	02010113          	addi	sp,sp,32
    write_reg_u8(UART_MODEM_CONTROL, 0x20);    // Autoflow mode
    8000015c:	3d00006f          	j	8000052c <write_reg_u8>

0000000080000160 <print_uart>:

void print_uart(const char *str)
{
    80000160:	ff010113          	addi	sp,sp,-16
    80000164:	00813023          	sd	s0,0(sp)
    80000168:	00113423          	sd	ra,8(sp)
    8000016c:	00050413          	mv	s0,a0
    const char *cur = &str[0];
    while (*cur != '\0')
    80000170:	00044503          	lbu	a0,0(s0)
    80000174:	00051a63          	bnez	a0,80000188 <print_uart+0x28>
    {
        write_serial((uint8_t)*cur);
        ++cur;
    }
}
    80000178:	00813083          	ld	ra,8(sp)
    8000017c:	00013403          	ld	s0,0(sp)
    80000180:	01010113          	addi	sp,sp,16
    80000184:	00008067          	ret
        write_serial((uint8_t)*cur);
    80000188:	f21ff0ef          	jal	ra,800000a8 <write_serial>
        ++cur;
    8000018c:	00140413          	addi	s0,s0,1
    80000190:	fe1ff06f          	j	80000170 <print_uart+0x10>

0000000080000194 <bin_to_hex>:
uint8_t bin_to_hex_table[16] = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

void bin_to_hex(uint8_t inp, uint8_t res[2])
{
    res[1] = bin_to_hex_table[inp & 0xf];
    80000194:	00001797          	auipc	a5,0x1
    80000198:	e6c78793          	addi	a5,a5,-404 # 80001000 <bin_to_hex_table>
    8000019c:	00f57713          	andi	a4,a0,15
    800001a0:	00e78733          	add	a4,a5,a4
    800001a4:	00074703          	lbu	a4,0(a4)
    res[0] = bin_to_hex_table[(inp >> 4) & 0xf];
    800001a8:	00455513          	srli	a0,a0,0x4
    800001ac:	00a787b3          	add	a5,a5,a0
    res[1] = bin_to_hex_table[inp & 0xf];
    800001b0:	00e580a3          	sb	a4,1(a1)
    res[0] = bin_to_hex_table[(inp >> 4) & 0xf];
    800001b4:	0007c783          	lbu	a5,0(a5)
    800001b8:	00f58023          	sb	a5,0(a1)
    return;
}
    800001bc:	00008067          	ret

00000000800001c0 <print_uart_int>:

void print_uart_int(uint32_t addr)
{
    800001c0:	fd010113          	addi	sp,sp,-48
    800001c4:	02813023          	sd	s0,32(sp)
    800001c8:	00913c23          	sd	s1,24(sp)
    800001cc:	01213823          	sd	s2,16(sp)
    800001d0:	02113423          	sd	ra,40(sp)
    800001d4:	00050913          	mv	s2,a0
    800001d8:	01800413          	li	s0,24
    int i;
    for (i = 3; i > -1; i--)
    800001dc:	ff800493          	li	s1,-8
    {
        uint8_t cur = (addr >> (i * 8)) & 0xff;
    800001e0:	0089553b          	srlw	a0,s2,s0
        uint8_t hex[2];
        bin_to_hex(cur, hex);
    800001e4:	00810593          	addi	a1,sp,8
    800001e8:	0ff57513          	andi	a0,a0,255
    800001ec:	fa9ff0ef          	jal	ra,80000194 <bin_to_hex>
        write_serial(hex[0]);
    800001f0:	00814503          	lbu	a0,8(sp)
    800001f4:	ff84041b          	addiw	s0,s0,-8
    800001f8:	eb1ff0ef          	jal	ra,800000a8 <write_serial>
        write_serial(hex[1]);
    800001fc:	00914503          	lbu	a0,9(sp)
    80000200:	ea9ff0ef          	jal	ra,800000a8 <write_serial>
    for (i = 3; i > -1; i--)
    80000204:	fc941ee3          	bne	s0,s1,800001e0 <print_uart_int+0x20>
    }
}
    80000208:	02813083          	ld	ra,40(sp)
    8000020c:	02013403          	ld	s0,32(sp)
    80000210:	01813483          	ld	s1,24(sp)
    80000214:	01013903          	ld	s2,16(sp)
    80000218:	03010113          	addi	sp,sp,48
    8000021c:	00008067          	ret

0000000080000220 <print_uart_addr>:

void print_uart_addr(uint64_t addr)
{
    80000220:	fd010113          	addi	sp,sp,-48
    80000224:	02813023          	sd	s0,32(sp)
    80000228:	00913c23          	sd	s1,24(sp)
    8000022c:	01213823          	sd	s2,16(sp)
    80000230:	02113423          	sd	ra,40(sp)
    80000234:	00050913          	mv	s2,a0
    80000238:	03800413          	li	s0,56
    int i;
    for (i = 7; i > -1; i--)
    8000023c:	ff800493          	li	s1,-8
    {
        uint8_t cur = (addr >> (i * 8)) & 0xff;
    80000240:	00895533          	srl	a0,s2,s0
        uint8_t hex[2];
        bin_to_hex(cur, hex);
    80000244:	00810593          	addi	a1,sp,8
    80000248:	0ff57513          	andi	a0,a0,255
    8000024c:	f49ff0ef          	jal	ra,80000194 <bin_to_hex>
        write_serial(hex[0]);
    80000250:	00814503          	lbu	a0,8(sp)
    80000254:	ff84041b          	addiw	s0,s0,-8
    80000258:	e51ff0ef          	jal	ra,800000a8 <write_serial>
        write_serial(hex[1]);
    8000025c:	00914503          	lbu	a0,9(sp)
    80000260:	e49ff0ef          	jal	ra,800000a8 <write_serial>
    for (i = 7; i > -1; i--)
    80000264:	fc941ee3          	bne	s0,s1,80000240 <print_uart_addr+0x20>
    }
}
    80000268:	02813083          	ld	ra,40(sp)
    8000026c:	02013403          	ld	s0,32(sp)
    80000270:	01813483          	ld	s1,24(sp)
    80000274:	01013903          	ld	s2,16(sp)
    80000278:	03010113          	addi	sp,sp,48
    8000027c:	00008067          	ret

0000000080000280 <print_uart_byte>:

void print_uart_byte(uint8_t byte)
{
    80000280:	fe010113          	addi	sp,sp,-32
    uint8_t hex[2];
    bin_to_hex(byte, hex);
    80000284:	00810593          	addi	a1,sp,8
{
    80000288:	00113c23          	sd	ra,24(sp)
    bin_to_hex(byte, hex);
    8000028c:	f09ff0ef          	jal	ra,80000194 <bin_to_hex>
    write_serial(hex[0]);
    80000290:	00814503          	lbu	a0,8(sp)
    80000294:	e15ff0ef          	jal	ra,800000a8 <write_serial>
    write_serial(hex[1]);
    80000298:	00914503          	lbu	a0,9(sp)
    8000029c:	e0dff0ef          	jal	ra,800000a8 <write_serial>
    800002a0:	01813083          	ld	ra,24(sp)
    800002a4:	02010113          	addi	sp,sp,32
    800002a8:	00008067          	ret

00000000800002ac <dma_check>:

int dma_check(uint64_t * src, uint64_t * ref, int len){
    uint64_t src_data;
    uint64_t ref_data;
    uint8_t error = 0;
    for (int i=0;i<(len>>3);i++){
    800002ac:	00000713          	li	a4,0
    800002b0:	4036561b          	sraiw	a2,a2,0x3
    800002b4:	0007079b          	sext.w	a5,a4
    800002b8:	00c7ce63          	blt	a5,a2,800002d4 <dma_check+0x28>
    uint8_t error = 0;
    800002bc:	00000513          	li	a0,0
            error = -1;
            break;
        }
    }
    return error;
}
    800002c0:	00008067          	ret
    for (int i=0;i<(len>>3);i++){
    800002c4:	0007079b          	sext.w	a5,a4
    800002c8:	00c7cc63          	blt	a5,a2,800002e0 <dma_check+0x34>
    uint8_t error = 0;
    800002cc:	00000513          	li	a0,0
    800002d0:	0580006f          	j	80000328 <dma_check+0x7c>
int dma_check(uint64_t * src, uint64_t * ref, int len){
    800002d4:	ff010113          	addi	sp,sp,-16
    800002d8:	00113423          	sd	ra,8(sp)
    800002dc:	00813023          	sd	s0,0(sp)
        src_data = src[i];
    800002e0:	00371793          	slli	a5,a4,0x3
    800002e4:	00f506b3          	add	a3,a0,a5
        ref_data = ref[i];
    800002e8:	00878793          	addi	a5,a5,8
    800002ec:	00f587b3          	add	a5,a1,a5
        if (src_data != ref_data) {
    800002f0:	0006b683          	ld	a3,0(a3)
    800002f4:	ff87b783          	ld	a5,-8(a5)
        src_data = src[i];
    800002f8:	00070413          	mv	s0,a4
    800002fc:	00170713          	addi	a4,a4,1
        if (src_data != ref_data) {
    80000300:	fcf682e3          	beq	a3,a5,800002c4 <dma_check+0x18>
            print_uart("Wrong Address: ");
    80000304:	00000517          	auipc	a0,0x0
    80000308:	30450513          	addi	a0,a0,772 # 80000608 <main+0xd4>
    8000030c:	e55ff0ef          	jal	ra,80000160 <print_uart>
            print_uart_addr(i);
    80000310:	00040513          	mv	a0,s0
    80000314:	f0dff0ef          	jal	ra,80000220 <print_uart_addr>
            print_uart("\r\n");
    80000318:	00000517          	auipc	a0,0x0
    8000031c:	30050513          	addi	a0,a0,768 # 80000618 <main+0xe4>
    80000320:	e41ff0ef          	jal	ra,80000160 <print_uart>
            error = -1;
    80000324:	0ff00513          	li	a0,255
}
    80000328:	00813083          	ld	ra,8(sp)
    8000032c:	00013403          	ld	s0,0(sp)
    80000330:	01010113          	addi	sp,sp,16
    80000334:	00008067          	ret

0000000080000338 <delay_us>:

void delay_us (int us) {
    for (int i=0;i<us;i++){

    }
}
    80000338:	00008067          	ret

000000008000033c <Dma_init>:
#include "dma.h"
#include "utils.h"

void Dma_init(){
    8000033c:	fe010113          	addi	sp,sp,-32
    // Reset DMA
    write_reg_u32(TRANS_CTRL, (1 << RD_RESET_LOC) |  (1 << WR_RESET_LOC));
    80000340:	41820537          	lui	a0,0x41820
void Dma_init(){
    80000344:	00813823          	sd	s0,16(sp)
    write_reg_u32(TRANS_CTRL, (1 << RD_RESET_LOC) |  (1 << WR_RESET_LOC));
    80000348:	00600593          	li	a1,6
    8000034c:	01850513          	addi	a0,a0,24 # 41820018 <_start-0x3e7dffe8>
    // whether DMA reset Done
    uint32_t ctrl;
    while(1){
        ctrl = read_reg(TRANS_CTRL);
    80000350:	41820437          	lui	s0,0x41820
void Dma_init(){
    80000354:	00913423          	sd	s1,8(sp)
    80000358:	00113c23          	sd	ra,24(sp)
        ctrl = read_reg(TRANS_CTRL);
    8000035c:	01840493          	addi	s1,s0,24 # 41820018 <_start-0x3e7dffe8>
    write_reg_u32(TRANS_CTRL, (1 << RD_RESET_LOC) |  (1 << WR_RESET_LOC));
    80000360:	1c4000ef          	jal	ra,80000524 <write_reg_u32>
        ctrl = read_reg(TRANS_CTRL);
    80000364:	00048513          	mv	a0,s1
    80000368:	1a0000ef          	jal	ra,80000508 <read_reg>
        if (((ctrl & (1 << RD_RESET_LOC)) | (ctrl & (1 << WR_RESET_LOC))) == 0)
    8000036c:	00657513          	andi	a0,a0,6
    80000370:	fe051ae3          	bnez	a0,80000364 <Dma_init+0x28>
            break;
    };
    // Clear CTRL reg and STATUS reg
    write_reg_u32(TRANS_CTRL, 0);
    80000374:	01840513          	addi	a0,s0,24
    80000378:	00000593          	li	a1,0
    8000037c:	1a8000ef          	jal	ra,80000524 <write_reg_u32>
    write_reg_u32(STATUS, 0);
    80000380:	02040513          	addi	a0,s0,32
}
    80000384:	01013403          	ld	s0,16(sp)
    80000388:	01813083          	ld	ra,24(sp)
    8000038c:	00813483          	ld	s1,8(sp)
    write_reg_u32(STATUS, 0);
    80000390:	00000593          	li	a1,0
}
    80000394:	02010113          	addi	sp,sp,32
    write_reg_u32(STATUS, 0);
    80000398:	18c0006f          	j	80000524 <write_reg_u32>

000000008000039c <Dma_trans_cfg>:

void Dma_trans_cfg(dma_trans_t * trans_cfg, uint32_t rd_single_step, uint32_t wr_single_step){
    8000039c:	fd010113          	addi	sp,sp,-48
    800003a0:	01313423          	sd	s3,8(sp)
    800003a4:	00058993          	mv	s3,a1
    write_reg_u32(SRC_BASE_ADDR, trans_cfg->src_addr);
    800003a8:	00052583          	lw	a1,0(a0)
void Dma_trans_cfg(dma_trans_t * trans_cfg, uint32_t rd_single_step, uint32_t wr_single_step){
    800003ac:	02813023          	sd	s0,32(sp)
    800003b0:	00050413          	mv	s0,a0
    write_reg_u32(SRC_BASE_ADDR, trans_cfg->src_addr);
    800003b4:	41820537          	lui	a0,0x41820
void Dma_trans_cfg(dma_trans_t * trans_cfg, uint32_t rd_single_step, uint32_t wr_single_step){
    800003b8:	02113423          	sd	ra,40(sp)
    800003bc:	00913c23          	sd	s1,24(sp)
    800003c0:	01213823          	sd	s2,16(sp)
    800003c4:	00060913          	mv	s2,a2
    write_reg_u32(SRC_BASE_ADDR, trans_cfg->src_addr);
    800003c8:	15c000ef          	jal	ra,80000524 <write_reg_u32>
    write_reg_u32(DES_BASE_ADDR, trans_cfg->des_addr);
    800003cc:	00442583          	lw	a1,4(s0)
    800003d0:	418204b7          	lui	s1,0x41820
    800003d4:	00848513          	addi	a0,s1,8 # 41820008 <_start-0x3e7dfff8>
    800003d8:	14c000ef          	jal	ra,80000524 <write_reg_u32>
    write_reg_u32(DATA_VOLUME, trans_cfg->data_volume);
    800003dc:	00842583          	lw	a1,8(s0)
    800003e0:	01048513          	addi	a0,s1,16
    800003e4:	140000ef          	jal	ra,80000524 <write_reg_u32>
    write_reg_u32(TRANS_MODE, trans_cfg->mode);
    800003e8:	00c42583          	lw	a1,12(s0)
    800003ec:	01c48513          	addi	a0,s1,28
    800003f0:	134000ef          	jal	ra,80000524 <write_reg_u32>
    write_reg_u32(BURST_LEN, trans_cfg->rd_burst_len | (trans_cfg->wr_burst_len << 8));
    800003f4:	01845583          	lhu	a1,24(s0)
    800003f8:	01448513          	addi	a0,s1,20
    800003fc:	128000ef          	jal	ra,80000524 <write_reg_u32>
    write_reg_u32(BURST_LEN, trans_cfg->rd_burst_len | (trans_cfg->wr_burst_len << 8));
    80000400:	01845583          	lhu	a1,24(s0)
    80000404:	01448513          	addi	a0,s1,20
    80000408:	11c000ef          	jal	ra,80000524 <write_reg_u32>
    if (rd_single_step) {
    8000040c:	00098863          	beqz	s3,8000041c <Dma_trans_cfg+0x80>
        write_reg_u32(RD_PENDING_VOLUME, trans_cfg->rd_pending_volume);
    80000410:	01042583          	lw	a1,16(s0)
    80000414:	02448513          	addi	a0,s1,36
    80000418:	10c000ef          	jal	ra,80000524 <write_reg_u32>
    }
    if (wr_single_step) {
    8000041c:	02090663          	beqz	s2,80000448 <Dma_trans_cfg+0xac>
        write_reg_u32(WR_PENDING_VOLUME, trans_cfg->wr_pending_volume);
    80000420:	01442583          	lw	a1,20(s0)
    }
}
    80000424:	02013403          	ld	s0,32(sp)
    80000428:	02813083          	ld	ra,40(sp)
    8000042c:	01813483          	ld	s1,24(sp)
    80000430:	01013903          	ld	s2,16(sp)
    80000434:	00813983          	ld	s3,8(sp)
        write_reg_u32(WR_PENDING_VOLUME, trans_cfg->wr_pending_volume);
    80000438:	41820537          	lui	a0,0x41820
    8000043c:	02850513          	addi	a0,a0,40 # 41820028 <_start-0x3e7dffd8>
}
    80000440:	03010113          	addi	sp,sp,48
        write_reg_u32(WR_PENDING_VOLUME, trans_cfg->wr_pending_volume);
    80000444:	0e00006f          	j	80000524 <write_reg_u32>
}
    80000448:	02813083          	ld	ra,40(sp)
    8000044c:	02013403          	ld	s0,32(sp)
    80000450:	01813483          	ld	s1,24(sp)
    80000454:	01013903          	ld	s2,16(sp)
    80000458:	00813983          	ld	s3,8(sp)
    8000045c:	03010113          	addi	sp,sp,48
    80000460:	00008067          	ret

0000000080000464 <Dma_start>:
void Dma_start() {
    write_reg_u32(TRANS_CTRL, (1 << START_LOC));
    80000464:	41820537          	lui	a0,0x41820
    80000468:	00100593          	li	a1,1
    8000046c:	01850513          	addi	a0,a0,24 # 41820018 <_start-0x3e7dffe8>
    80000470:	0b40006f          	j	80000524 <write_reg_u32>

0000000080000474 <is_read_pending>:
}

uint8_t is_read_pending(){
    return read_reg(STATUS) & (1 << RD_PENDING_LOC);
    80000474:	41820537          	lui	a0,0x41820
uint8_t is_read_pending(){
    80000478:	ff010113          	addi	sp,sp,-16
    return read_reg(STATUS) & (1 << RD_PENDING_LOC);
    8000047c:	02050513          	addi	a0,a0,32 # 41820020 <_start-0x3e7dffe0>
uint8_t is_read_pending(){
    80000480:	00113423          	sd	ra,8(sp)
    return read_reg(STATUS) & (1 << RD_PENDING_LOC);
    80000484:	084000ef          	jal	ra,80000508 <read_reg>
}
    80000488:	00813083          	ld	ra,8(sp)
    8000048c:	00857513          	andi	a0,a0,8
    80000490:	01010113          	addi	sp,sp,16
    80000494:	00008067          	ret

0000000080000498 <clear_read_pending>:

void clear_read_pending(){
    80000498:	ff010113          	addi	sp,sp,-16
    8000049c:	00813023          	sd	s0,0(sp)
    uint32_t status = read_reg(STATUS);
    800004a0:	41820437          	lui	s0,0x41820
    800004a4:	02040513          	addi	a0,s0,32 # 41820020 <_start-0x3e7dffe0>
void clear_read_pending(){
    800004a8:	00113423          	sd	ra,8(sp)
    uint32_t status = read_reg(STATUS);
    800004ac:	05c000ef          	jal	ra,80000508 <read_reg>
    800004b0:	0005059b          	sext.w	a1,a0
    write_reg_u32(STATUS, status & (~(1 << RD_PENDING_LOC)));
    800004b4:	02040513          	addi	a0,s0,32
}
    800004b8:	00013403          	ld	s0,0(sp)
    800004bc:	00813083          	ld	ra,8(sp)
    write_reg_u32(STATUS, status & (~(1 << RD_PENDING_LOC)));
    800004c0:	ff75f593          	andi	a1,a1,-9
}
    800004c4:	01010113          	addi	sp,sp,16
    write_reg_u32(STATUS, status & (~(1 << RD_PENDING_LOC)));
    800004c8:	05c0006f          	j	80000524 <write_reg_u32>

00000000800004cc <is_Dma_done>:

uint8_t is_Dma_done() {
    return read_reg(STATUS) & (1 << WR_DONE_LOC);
    800004cc:	41820537          	lui	a0,0x41820
uint8_t is_Dma_done() {
    800004d0:	ff010113          	addi	sp,sp,-16
    return read_reg(STATUS) & (1 << WR_DONE_LOC);
    800004d4:	02050513          	addi	a0,a0,32 # 41820020 <_start-0x3e7dffe0>
uint8_t is_Dma_done() {
    800004d8:	00113423          	sd	ra,8(sp)
    return read_reg(STATUS) & (1 << WR_DONE_LOC);
    800004dc:	02c000ef          	jal	ra,80000508 <read_reg>
}
    800004e0:	00813083          	ld	ra,8(sp)
    800004e4:	00257513          	andi	a0,a0,2
    800004e8:	01010113          	addi	sp,sp,16
    800004ec:	00008067          	ret

00000000800004f0 <flush_done>:
void flush_done () {
    write_reg_u32(STATUS,0);
    800004f0:	41820537          	lui	a0,0x41820
    800004f4:	00000593          	li	a1,0
    800004f8:	02050513          	addi	a0,a0,32 # 41820020 <_start-0x3e7dffe0>
    800004fc:	0280006f          	j	80000524 <write_reg_u32>

0000000080000500 <write_reg>:
#include "utils.h"

void write_reg(uintptr_t addr, uint32_t value)
{
    volatile uint32_t *loc_addr = (volatile uint32_t *)addr;
    *loc_addr = value;
    80000500:	00b52023          	sw	a1,0(a0)
}
    80000504:	00008067          	ret

0000000080000508 <read_reg>:

uint32_t read_reg(uintptr_t addr)
{
    return *(volatile uint32_t *)addr;
    80000508:	00052503          	lw	a0,0(a0)
}
    8000050c:	0005051b          	sext.w	a0,a0
    80000510:	00008067          	ret

0000000080000514 <read_reg_u8>:

uint8_t read_reg_u8(uintptr_t addr)
{
    return *(volatile uint8_t *)addr;
    80000514:	00054503          	lbu	a0,0(a0)
}
    80000518:	00008067          	ret

000000008000051c <write_reg_u64>:

void write_reg_u64(uintptr_t addr, uint64_t value)
{
    volatile uint64_t *loc_addr = (volatile uint64_t *)addr;
    *loc_addr = value;
    8000051c:	00b53023          	sd	a1,0(a0)
}
    80000520:	00008067          	ret

0000000080000524 <write_reg_u32>:
    80000524:	00b52023          	sw	a1,0(a0)
    80000528:	00008067          	ret

000000008000052c <write_reg_u8>:
}

void write_reg_u8(uintptr_t addr, uint8_t value)
{
    volatile uint8_t *loc_addr = (volatile uint8_t *)addr;
    *loc_addr = value;
    8000052c:	00b50023          	sb	a1,0(a0)
    80000530:	00008067          	ret

Disassembly of section .text.startup:

0000000080000534 <main>:

int main()
{
    init_uart(50000000, 115200);
    80000534:	0001c5b7          	lui	a1,0x1c
    80000538:	02faf537          	lui	a0,0x2faf
{
    8000053c:	fd010113          	addi	sp,sp,-48
    init_uart(50000000, 115200);
    80000540:	20058593          	addi	a1,a1,512 # 1c200 <_start-0x7ffe3e00>
    80000544:	08050513          	addi	a0,a0,128 # 2faf080 <_start-0x7d050f80>
{
    80000548:	02113423          	sd	ra,40(sp)
    8000054c:	02813023          	sd	s0,32(sp)
    init_uart(50000000, 115200);
    80000550:	b85ff0ef          	jal	ra,800000d4 <init_uart>
    // DMA test case 7 : TEST Trans between DDR and DDR ,TEST size : 16 KB 
    // print_uart("---------DMA TEST CASE 7: test Trans between DDR and DDR--------!\r\n");
    // init DMA
    Dma_init();
    80000554:	de9ff0ef          	jal	ra,8000033c <Dma_init>
    // read  burst len : 16
    // write burst len : 16
    // trans size : 2KB
    // trans mode : rd single step mode
    dma_trans_t trans_cfg;
    trans_cfg.src_addr = (uint32_t)src_arr;
    80000558:	00003797          	auipc	a5,0x3
    8000055c:	ac07b783          	ld	a5,-1344(a5) # 80003018 <src_arr>
    trans_cfg.wr_burst_len = 16;
    trans_cfg.data_volume = trans_size;
    trans_cfg.mode = SINGLE_RD_TRANS_MODE;
    trans_cfg.rd_pending_volume = 1024*4; // when read 4KB, dma will pending uintil cpu clear pending bit
    trans_cfg.wr_pending_volume = 0;
    Dma_trans_cfg(&trans_cfg,1,0);
    80000560:	00000613          	li	a2,0
    80000564:	00100593          	li	a1,1
    trans_cfg.src_addr = (uint32_t)src_arr;
    80000568:	00f12023          	sw	a5,0(sp)
    trans_cfg.des_addr = (uint32_t)dst_arr;
    8000056c:	00003797          	auipc	a5,0x3
    80000570:	a9c7b783          	ld	a5,-1380(a5) # 80003008 <dst_arr>
    Dma_trans_cfg(&trans_cfg,1,0);
    80000574:	00010513          	mv	a0,sp
    Dma_start();
    for (int i=0;i<(trans_size/(1024*4));i++) {
    80000578:	00000413          	li	s0,0
    trans_cfg.des_addr = (uint32_t)dst_arr;
    8000057c:	00f12223          	sw	a5,4(sp)
    trans_cfg.data_volume = trans_size;
    80000580:	00003797          	auipc	a5,0x3
    80000584:	a807a783          	lw	a5,-1408(a5) # 80003000 <trans_size>
    80000588:	00f12423          	sw	a5,8(sp)
    trans_cfg.mode = SINGLE_RD_TRANS_MODE;
    8000058c:	00400793          	li	a5,4
    80000590:	00f12623          	sw	a5,12(sp)
    trans_cfg.rd_pending_volume = 1024*4; // when read 4KB, dma will pending uintil cpu clear pending bit
    80000594:	000017b7          	lui	a5,0x1
    80000598:	00f13823          	sd	a5,16(sp)
    trans_cfg.rd_burst_len = 16;
    8000059c:	0107879b          	addiw	a5,a5,16
    800005a0:	00f11c23          	sh	a5,24(sp)
    Dma_trans_cfg(&trans_cfg,1,0);
    800005a4:	df9ff0ef          	jal	ra,8000039c <Dma_trans_cfg>
    Dma_start();
    800005a8:	ebdff0ef          	jal	ra,80000464 <Dma_start>
    for (int i=0;i<(trans_size/(1024*4));i++) {
    800005ac:	00003797          	auipc	a5,0x3
    800005b0:	a547a783          	lw	a5,-1452(a5) # 80003000 <trans_size>
    800005b4:	00c7d79b          	srliw	a5,a5,0xc
    800005b8:	02f46c63          	bltu	s0,a5,800005f0 <main+0xbc>
        delay_us(100); // do something here : such as read sd block
        clear_read_pending();
    }
    // check if dma trans is done
    while(1) {
        if (is_Dma_done()){
    800005bc:	f11ff0ef          	jal	ra,800004cc <is_Dma_done>
    800005c0:	fe050ee3          	beqz	a0,800005bc <main+0x88>
            break;
        }
    }
    // print_uart("Transaction Done!\r\n");

    uint32_t error = dma_check((uint64_t*)dst_arr, (uint64_t*)ref_arr, trans_size);
    800005c4:	00003797          	auipc	a5,0x3
    800005c8:	a3c7a603          	lw	a2,-1476(a5) # 80003000 <trans_size>
    800005cc:	00003797          	auipc	a5,0x3
    800005d0:	a447b583          	ld	a1,-1468(a5) # 80003010 <ref_arr>
    800005d4:	00003797          	auipc	a5,0x3
    800005d8:	a347b503          	ld	a0,-1484(a5) # 80003008 <dst_arr>
    800005dc:	cd1ff0ef          	jal	ra,800002ac <dma_check>
    800005e0:	0005051b          	sext.w	a0,a0
    // finish 
    volatile uint32_t * done_addr = (uint32_t *)0x42000000;
	*done_addr = error; // if error = 0, TEST pass, othewise TEST fail
    800005e4:	420007b7          	lui	a5,0x42000
    800005e8:	00a7a023          	sw	a0,0(a5) # 42000000 <_start-0x3e000000>

    while (1);  // do nothing
    800005ec:	0000006f          	j	800005ec <main+0xb8>
        while (is_read_pending() == 0);
    800005f0:	e85ff0ef          	jal	ra,80000474 <is_read_pending>
    800005f4:	fe050ee3          	beqz	a0,800005f0 <main+0xbc>
        clear_read_pending();
    800005f8:	ea1ff0ef          	jal	ra,80000498 <clear_read_pending>
    for (int i=0;i<(trans_size/(1024*4));i++) {
    800005fc:	0014041b          	addiw	s0,s0,1
    80000600:	fadff06f          	j	800005ac <main+0x78>

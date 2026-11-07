
build_src/boot0.elf:     file format elf64-littleriscv
build_src/boot0.elf
architecture: riscv:rv64, flags 0x00000112:
EXEC_P, HAS_SYMS, D_PAGED
start address 0x0000000041000000

Program Header:
    LOAD off    0x0000000000001000 vaddr 0x0000000041000000 paddr 0x0000000041000000 align 2**12
         filesz 0x000000000000000c memsz 0x000000000000000c flags r-x

Sections:
Idx Name          Size      VMA               LMA               File off  Algn
  0 .text.boot    0000000c  0000000041000000  0000000041000000  00001000  2**0
                  CONTENTS, ALLOC, LOAD, READONLY, CODE
  1 .debug_line   00000044  0000000000000000  0000000000000000  0000100c  2**0
                  CONTENTS, READONLY, DEBUGGING
  2 .debug_info   0000002e  0000000000000000  0000000000000000  00001050  2**0
                  CONTENTS, READONLY, DEBUGGING
  3 .debug_abbrev 00000014  0000000000000000  0000000000000000  0000107e  2**0
                  CONTENTS, READONLY, DEBUGGING
  4 .debug_aranges 00000030  0000000000000000  0000000000000000  000010a0  2**4
                  CONTENTS, READONLY, DEBUGGING
  5 .debug_str    00000058  0000000000000000  0000000000000000  000010d0  2**0
                  CONTENTS, READONLY, DEBUGGING
SYMBOL TABLE:
0000000041000000 l    d  .text.boot	0000000000000000 .text.boot
0000000000000000 l    d  .debug_line	0000000000000000 .debug_line
0000000000000000 l    d  .debug_info	0000000000000000 .debug_info
0000000000000000 l    d  .debug_abbrev	0000000000000000 .debug_abbrev
0000000000000000 l    d  .debug_aranges	0000000000000000 .debug_aranges
0000000000000000 l    d  .debug_str	0000000000000000 .debug_str
0000000041000000 g       .text.boot	0000000000000000 _start
0000000041000010 g       .text.boot	0000000000000000 bss_end
0000000041000010 g       .text.boot	0000000000000000 bss_begin



Disassembly of section .text.boot:

0000000041000000 <_start>:
#define DRAM_BASE 0x80000000

.section .text.boot
.globl _start
_start:
	li a0, DRAM_BASE
    41000000:	0010051b          	addiw	a0,zero,1
    41000004:	01f51513          	slli	a0,a0,0x1f
    41000008:	00050067          	jr	a0

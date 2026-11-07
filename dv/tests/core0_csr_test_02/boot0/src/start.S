#define DRAM_BASE 0x80000000

.section .text.boot
.globl _start
_start:
	li a0, DRAM_BASE
	jr a0
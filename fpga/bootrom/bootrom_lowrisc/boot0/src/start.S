#define PROG_BASE 0x58000080
#define PROG_SIZE 0x8000
#define DRAM_BASE 0x87fe0000
#define REGMAP_ARG01 0x41840014

.section .text.boot
.globl _start
_start:
	csrr t0, mhartid
	bnez t0, _wait
	li a0, PROG_BASE
	li a1, PROG_SIZE
	add a1, a0, a1
	li a2, DRAM_BASE
	li a3, REGMAP_ARG01
_copy:
	ld a4, 0(a0)
	sd a4, 0(a2)
	addi a0, a0, 8
	addi a2, a2, 8
	blt a0, a1, _copy
	fence.i
	li t0, 1
	sw t0, 0(a3)
	li a0, DRAM_BASE
	j _jump
_wait: 
	li a3, REGMAP_ARG01 
	lw a4, 0(a3) 
	beqz a4, _wait
	li a0, DRAM_BASE
_jump:
	jalr a0
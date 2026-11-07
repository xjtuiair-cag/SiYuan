# start sequence of the bootloader
#
#
#define RET_ADDR 0xA0000000
  .section .text.boot
  .globl _start
_start:
	/* Mask all interrupts */
	csrw sie, zero

	/* set the stack of SP, size 4KB */
	la sp, stacks_start
	li t0, 4096
	add sp, sp, t0

	/* goto C */
	call main 

	// return 
	li a0, RET_ADDR
	jr a0

.section .data
.align  12
.global stacks_start
stacks_start:
	.skip 4096
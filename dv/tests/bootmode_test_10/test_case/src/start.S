# start sequence of the bootloader
#
#
#define STACK_START 0x80100000
#define RET_ADDR 0xA0000000
  .section .text.boot
  .globl _start
_start:
	/* Mask all interrupts */
	csrw sie, zero
	csrr t0, mhartid
	mv a0, t0
	addi t0, t0, 1
	/* set the stack of SP, size 4KB */
	li sp, STACK_START
	sll t0, t0, 12
	add sp, sp, t0

	li a1, 4
	fence
	/* goto C */
	call main 

	// return 
	li a0, RET_ADDR
	jr a0
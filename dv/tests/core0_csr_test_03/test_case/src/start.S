# start sequence of the bootloader
#
#
#include <smp.h>
#define DONE_ADDR 0x42000000

  .section .text.boot
  .globl _start
_start:
  	smp_pause(s1, s2)
	/* Mask all interrupts */
	csrw sie, zero

	/* set the stack of SP, size 4KB */
	la sp, stacks_start
	li t0, 4096
	add sp, sp, t0

	la t0, _trap_handle
	csrw mtvec, t0
	// expect exception
	csrr t0, fcsr
	la t0, DONE_ADDR
	li t1, 0x1
	sw t1, (t0)
	smp_resume(s1, s2)

_trap_handle:
	la t0, DONE_ADDR
	sw zero, (t0)
	nop
	nop
	nop
	nop
	nop


.section .data
.align  12
.global stacks_start
stacks_start:
	.skip 4096
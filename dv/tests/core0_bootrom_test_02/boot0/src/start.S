# start sequence of the bootloader
#
#
#include <smp.h>

  .section .text.boot
  .globl _start
_start:
  	smp_pause(s1, s2)
	/* Mask all interrupts */
	csrw sie, zero

	/* set the stack of SP, size 4KB */
  	li sp, 0x81000000
	/* goto C */
	tail main 

	smp_resume(s1, s2)

.section .data
.align  12
.global stacks_start
stacks_start:
	.skip 4096
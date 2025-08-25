.section ".text.boot"

.globl _start
_start:
//	/* test c ompression*/
//	nop
//	add a0, a1, a2 
//	c.addi a0, 10 
//	li a1, 0x80000002
//	jalr a1
	/* 关闭M模式的中断*/
	csrw mie, zero

	/* 设置栈, 栈的大小为4KB */
	la sp, stacks_start
	li t0, 4096
	add sp, sp, t0
	/* 
	   把M模式的SP设置到mscratch寄存器，
	   下次陷入到M模式可以获取SP
	 */
	csrw mscratch, sp

	/* 跳转到C语言 */
	tail sbi_main



_c_test:
	







.section .data
.align  12
.global stacks_start
stacks_start:
	.skip 4096

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
	// read csr in s mode
	csrr t0, sip
	bnez t0, _trap_handle
	csrr t0, stvec
	bnez t0, _trap_handle
	csrr t0, sie
	bnez t0, _trap_handle
	csrr t0, scounteren
	bnez t0, _trap_handle
	csrr t0, sscratch
	bnez t0, _trap_handle
	csrr t0, sepc
	bnez t0, _trap_handle
	csrr t0, scause
	bnez t0, _trap_handle
	csrr t0, stval
	bnez t0, _trap_handle
	csrr t0, satp
	bnez t0, _trap_handle
	// write csr in s mode
	li t1, 0x1
	csrw sip, t1
	csrw stvec, t1
	csrw sie, t1
	csrw scounteren, t1
	csrw sscratch, t1
	csrw sepc, t1
	csrw scause, t1
	csrw stval, t1
	csrw satp, t1

	// read csr in m mode
	csrr t0, misa
	li t1, 0x800000000014112d
	bne t0, t1, _trap_handle
	csrr t0, mcounteren
	bnez t0, _trap_handle
	csrr t0, mtval
	bnez t0, _trap_handle
	csrr t0, mvendorid
	bnez t0, _trap_handle
	csrr t0, marchid
	li t1, 0x610
	bne t0, t1, _trap_handle
	csrr t0, mimpid
	bnez t0, _trap_handle
	// write csr in m mode
	li t1, 0x1
	csrw misa, t1
	csrw mcounteren, t1
	csrw mtvec, t1
	csrw mcause, t1
	csrw mtval, t1
	csrw mcycle, t1

	// PASS
	la t0, DONE_ADDR
	li t1, 0x0
	sw t1, (t0)
	smp_resume(s1, s2)

_trap_handle:
	// FAILED
	la t0, DONE_ADDR
	li t1, 0x1
	sw t1, (t0)
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
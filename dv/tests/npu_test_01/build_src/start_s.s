# 1 "src/start.S"
# 1 "/home/shenghuan/Projects/github/SiYuan/dv/tests/npu_test_01//"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "src/start.S"
# start sequence of the bootloader


# 1 "include/smp.h" 1
# 5 "src/start.S" 2

  .section .text.boot
  .globl _start
_start:
   li s2, 0x8; csrw mie, s2; li s1, 0; csrr s2, mhartid; bne s1, s2, 42f

 csrw sie, zero


 la sp, stacks_start
 li t0, 4096
 add sp, sp, t0


 tail main

 li s1, 0x2000000; 41:; li s2, 1; sw s2, 0(s1); addi s1, s1, 4; li s2, 0x2000000 + (4 * 4); blt s1, s2, 41b; 42:; wfi; csrr s2, mip; andi s2, s2, 0x8; beqz s2, 42b; li s1, 0x2000000; csrr s2, mhartid; slli s2, s2, 2; add s2, s2, s1; sw zero, 0(s2); 41:; lw s2, 0(s1); bnez s2, 41b; addi s1, s1, 4; li s2, 0x2000000 + (4 * 4); blt s1, s2, 41b

.section .data
.align 12
.global stacks_start
stacks_start:
 .skip 4096

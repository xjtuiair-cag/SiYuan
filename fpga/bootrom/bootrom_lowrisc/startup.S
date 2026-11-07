# start sequence of the bootloader
# 
# 
#include <smp.h>
#define DRAM_BASE 0x87FE0000
#define DRAM_END  0x87FFFFF8
#define DRAM_START 0x80000000

  .section .text.init
  .option norvc
  .globl _prog_start
_prog_start:
  smp_pause(s1,s2)
  li sp, DRAM_END
  la a5, trap_entry
  csrw mtvec, a5  
  call main
  smp_resume(s1,s2)

  csrr a0, mhartid
  la a1, _dtb
  li s1, DRAM_START
  jr s1

trap_entry:
  csrr t0, mcause
  csrr t1, mepc
  la a0, trap_msg
  # call hid_send_string
  mv a0, t1
  li a1, 8
  # call puthex
  la a0, cause_msg
  # call hid_send_string        
  mv a0, t0
  li a1, 2
  # call puthex
  la a0, stars
  # call hid_send_string        
1:      
  wfi
  j 1b
trap_msg:
  .ascii "Trapped to machine mode, PC = \000"
cause_msg:
  .ascii ", Cause = \000"
stars:
  .ascii " ********                     \000"

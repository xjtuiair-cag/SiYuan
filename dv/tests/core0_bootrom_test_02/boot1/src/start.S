# start sequence of the bootloader
#
#
  .section .text.boot
  .globl _start
_start:
    j _start
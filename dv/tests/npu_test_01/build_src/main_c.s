	.file	"main.c"
	.option nopic
	.text
.Ltext0:
	.cfi_sections	.debug_frame
	.section	.rodata
	.align	3
.LC0:
	.string	"Hello World!\r\n"
	.align	3
.LC1:
	.string	"Convolution Finish!\r\n"
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
.LFB0:
	.file 1 "src/main.c"
	.loc 1 19 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sd	ra,8(sp)
	.cfi_offset 1, -8
	.loc 1 20 5
	li	a5,114688
	addi	a1,a5,512
	li	a5,49999872
	addi	a0,a5,128
	call	init_uart
	.loc 1 21 5
	lla	a0,.LC0
	call	print_uart
	.loc 1 23 5
	call	init_npu
	.loc 1 24 5
	call	start_npu
	.loc 1 25 5
	call	start_conv
	.loc 1 26 5
	call	wait_npu_done
	.loc 1 27 5
	lla	a0,.LC1
	call	print_uart
.L2:
	.loc 1 29 11 discriminator 1
	j	.L2
	.cfi_endproc
.LFE0:
	.size	main, .-main
.Letext0:
	.section	.debug_info,"",@progbits
.Ldebug_info0:
	.4byte	0x79
	.2byte	0x4
	.4byte	.Ldebug_abbrev0
	.byte	0x8
	.byte	0x1
	.4byte	.LASF6
	.byte	0xc
	.4byte	.LASF7
	.4byte	.LASF8
	.8byte	.Ltext0
	.8byte	.Letext0-.Ltext0
	.4byte	.Ldebug_line0
	.byte	0x2
	.byte	0x1
	.byte	0x6
	.4byte	.LASF0
	.byte	0x2
	.byte	0x2
	.byte	0x5
	.4byte	.LASF1
	.byte	0x3
	.byte	0x4
	.byte	0x5
	.string	"int"
	.byte	0x2
	.byte	0x1
	.byte	0x8
	.4byte	.LASF2
	.byte	0x2
	.byte	0x2
	.byte	0x7
	.4byte	.LASF3
	.byte	0x2
	.byte	0x4
	.byte	0x7
	.4byte	.LASF4
	.byte	0x2
	.byte	0x8
	.byte	0x7
	.4byte	.LASF5
	.byte	0x4
	.4byte	.LASF9
	.byte	0x1
	.byte	0x12
	.byte	0x5
	.4byte	0x3b
	.8byte	.LFB0
	.8byte	.LFE0-.LFB0
	.byte	0x1
	.byte	0x9c
	.byte	0
	.section	.debug_abbrev,"",@progbits
.Ldebug_abbrev0:
	.byte	0x1
	.byte	0x11
	.byte	0x1
	.byte	0x25
	.byte	0xe
	.byte	0x13
	.byte	0xb
	.byte	0x3
	.byte	0xe
	.byte	0x1b
	.byte	0xe
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x7
	.byte	0x10
	.byte	0x17
	.byte	0
	.byte	0
	.byte	0x2
	.byte	0x24
	.byte	0
	.byte	0xb
	.byte	0xb
	.byte	0x3e
	.byte	0xb
	.byte	0x3
	.byte	0xe
	.byte	0
	.byte	0
	.byte	0x3
	.byte	0x24
	.byte	0
	.byte	0xb
	.byte	0xb
	.byte	0x3e
	.byte	0xb
	.byte	0x3
	.byte	0x8
	.byte	0
	.byte	0
	.byte	0x4
	.byte	0x2e
	.byte	0
	.byte	0x3f
	.byte	0x19
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x7
	.byte	0x40
	.byte	0x18
	.byte	0x96,0x42
	.byte	0x19
	.byte	0
	.byte	0
	.byte	0
	.section	.debug_aranges,"",@progbits
	.4byte	0x2c
	.2byte	0x2
	.4byte	.Ldebug_info0
	.byte	0x8
	.byte	0
	.2byte	0
	.2byte	0
	.8byte	.Ltext0
	.8byte	.Letext0-.Ltext0
	.8byte	0
	.8byte	0
	.section	.debug_line,"",@progbits
.Ldebug_line0:
	.section	.debug_str,"MS",@progbits,1
.LASF4:
	.string	"unsigned int"
.LASF5:
	.string	"long unsigned int"
.LASF2:
	.string	"unsigned char"
.LASF0:
	.string	"signed char"
.LASF1:
	.string	"short int"
.LASF6:
	.string	"GNU C17 8.2.0 -mcmodel=medany -mabi=lp64 -march=rv64imafd -g -O0 -fno-PIE -fomit-frame-pointer"
.LASF8:
	.string	"/home/shenghuan/Projects/github/SiYuan/dv/tests/npu_test_01"
.LASF7:
	.string	"src/main.c"
.LASF9:
	.string	"main"
.LASF3:
	.string	"short unsigned int"
	.ident	"GCC: (GNU) 8.2.0"

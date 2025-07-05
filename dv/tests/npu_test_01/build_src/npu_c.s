	.file	"npu.c"
	.option nopic
	.text
.Ltext0:
	.cfi_sections	.debug_frame
	.align	2
	.globl	write_reg_u64
	.type	write_reg_u64, @function
write_reg_u64:
.LFB0:
	.file 1 "src/npu.c"
	.loc 1 5 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sd	a0,8(sp)
	sd	a1,0(sp)
	.loc 1 6 24
	ld	a5,8(sp)
	sd	a5,24(sp)
	.loc 1 7 15
	ld	a5,24(sp)
	ld	a4,0(sp)
	sd	a4,0(a5)
	.loc 1 8 1
	nop
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE0:
	.size	write_reg_u64, .-write_reg_u64
	.align	2
	.globl	write_reg_u32
	.type	write_reg_u32, @function
write_reg_u32:
.LFB1:
	.loc 1 10 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sd	a0,8(sp)
	mv	a5,a1
	sw	a5,4(sp)
	.loc 1 11 24
	ld	a5,8(sp)
	sd	a5,24(sp)
	.loc 1 12 15
	ld	a5,24(sp)
	lw	a4,4(sp)
	sw	a4,0(a5)
	.loc 1 13 1
	nop
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE1:
	.size	write_reg_u32, .-write_reg_u32
	.align	2
	.globl	sleep_us
	.type	sleep_us, @function
sleep_us:
.LFB2:
	.loc 1 16 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	mv	a5,a0
	sw	a5,12(sp)
.LBB2:
	.loc 1 17 14
	sw	zero,28(sp)
	.loc 1 17 5
	j	.L4
.L5:
	.loc 1 17 24 discriminator 3
	lw	a5,28(sp)
	addiw	a5,a5,1
	sw	a5,28(sp)
.L4:
	.loc 1 17 5 discriminator 1
	lw	a4,28(sp)
	lw	a5,12(sp)
	sext.w	a4,a4
	sext.w	a5,a5
	blt	a4,a5,.L5
.LBE2:
	.loc 1 18 1
	nop
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE2:
	.size	sleep_us, .-sleep_us
	.align	2
	.type	clr_reg, @function
clr_reg:
.LFB3:
	.loc 1 20 51
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sd	ra,40(sp)
	.cfi_offset 1, -8
	mv	a5,a0
	mv	a4,a1
	sw	a5,12(sp)
	mv	a5,a4
	sw	a5,8(sp)
	.loc 1 21 25
	lw	a5,8(sp)
	li	a4,1
	sllw	a5,a4,a5
	sext.w	a5,a5
	.loc 1 21 14
	sw	a5,28(sp)
	.loc 1 22 21
	lwu	a5,12(sp)
	.loc 1 22 14
	lw	a5,0(a5)
	sw	a5,24(sp)
	.loc 1 23 5
	lwu	a4,12(sp)
	.loc 1 23 32
	lw	a5,28(sp)
	not	a5,a5
	sext.w	a3,a5
	.loc 1 23 5
	lw	a5,24(sp)
	and	a5,a5,a3
	sext.w	a5,a5
	mv	a1,a5
	mv	a0,a4
	call	write_reg_u32
	.loc 1 24 1
	nop
	ld	ra,40(sp)
	.cfi_restore 1
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE3:
	.size	clr_reg, .-clr_reg
	.align	2
	.type	set_reg, @function
set_reg:
.LFB4:
	.loc 1 26 51
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sd	ra,40(sp)
	.cfi_offset 1, -8
	mv	a5,a0
	mv	a4,a1
	sw	a5,12(sp)
	mv	a5,a4
	sw	a5,8(sp)
	.loc 1 27 25
	lw	a5,8(sp)
	li	a4,1
	sllw	a5,a4,a5
	sext.w	a5,a5
	.loc 1 27 14
	sw	a5,28(sp)
	.loc 1 28 21
	lwu	a5,12(sp)
	.loc 1 28 14
	lw	a5,0(a5)
	sw	a5,24(sp)
	.loc 1 29 5
	lwu	a3,12(sp)
	lw	a4,24(sp)
	lw	a5,28(sp)
	or	a5,a4,a5
	sext.w	a5,a5
	mv	a1,a5
	mv	a0,a3
	call	write_reg_u32
	.loc 1 30 1
	nop
	ld	ra,40(sp)
	.cfi_restore 1
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE4:
	.size	set_reg, .-set_reg
	.section	.rodata
	.align	3
.LC0:
	.string	"[INFO]: init npu success\n"
	.text
	.align	2
	.globl	init_npu
	.type	init_npu, @function
init_npu:
.LFB5:
	.loc 1 31 15
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sd	ra,8(sp)
	.cfi_offset 1, -8
	.loc 1 32 5
	li	a5,5
	slli	a1,a5,29
	li	a5,8192
	addi	a0,a5,48
	call	write_reg_u64
	.loc 1 33 5
	lla	a0,.LC0
	call	print_uart
	.loc 1 34 12
	li	a5,0
	.loc 1 35 1
	mv	a0,a5
	ld	ra,8(sp)
	.cfi_restore 1
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE5:
	.size	init_npu, .-init_npu
	.section	.rodata
	.align	3
.LC1:
	.string	"[INFO]: start npu success\n"
	.text
	.align	2
	.globl	start_npu
	.type	start_npu, @function
start_npu:
.LFB6:
	.loc 1 37 22
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sd	ra,24(sp)
	.cfi_offset 1, -8
	mv	a5,a0
	sw	a5,12(sp)
	.loc 1 38 5
	li	a1,0
	li	a5,8192
	addi	a0,a5,32
	call	clr_reg
	.loc 1 39 5
	li	a1,3
	li	a5,8192
	addi	a0,a5,32
	call	clr_reg
	.loc 1 40 5
	li	a1,3
	li	a5,8192
	addi	a0,a5,32
	call	set_reg
	.loc 1 41 5
	lla	a0,.LC1
	call	print_uart
	.loc 1 42 12
	li	a5,0
	.loc 1 44 1
	mv	a0,a5
	ld	ra,24(sp)
	.cfi_restore 1
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE6:
	.size	start_npu, .-start_npu
	.section	.rodata
	.align	3
.LC2:
	.string	"[INFO]: start conv success\n"
	.text
	.align	2
	.globl	start_conv
	.type	start_conv, @function
start_conv:
.LFB7:
	.loc 1 45 23
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sd	ra,24(sp)
	.cfi_offset 1, -8
	mv	a5,a0
	sw	a5,12(sp)
	.loc 1 46 5
	li	a1,0
	li	a5,8192
	addi	a0,a5,32
	call	set_reg
	.loc 1 47 5
	li	a1,0
	li	a5,8192
	addi	a0,a5,32
	call	clr_reg
	.loc 1 48 5
	lla	a0,.LC2
	call	print_uart
	.loc 1 49 12
	li	a5,0
	.loc 1 50 1
	mv	a0,a5
	ld	ra,24(sp)
	.cfi_restore 1
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE7:
	.size	start_conv, .-start_conv
	.align	2
	.globl	wait_npu_done
	.type	wait_npu_done, @function
wait_npu_done:
.LFB8:
	.loc 1 52 26
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sd	ra,40(sp)
	.cfi_offset 1, -8
	mv	a5,a0
	sw	a5,12(sp)
	.loc 1 54 14
	li	a5,8192
	addiw	a5,a5,80
	sw	a5,24(sp)
	.loc 1 55 14
	lwu	a5,24(sp)
	.loc 1 55 11
	lw	a5,0(a5)
	sw	a5,28(sp)
	.loc 1 56 11
	j	.L15
.L16:
	.loc 1 57 9
	li	a0,2000
	call	sleep_us
	.loc 1 58 18
	lwu	a5,24(sp)
	.loc 1 58 15
	lw	a5,0(a5)
	sw	a5,28(sp)
.L15:
	.loc 1 56 11
	lw	a5,28(sp)
	sext.w	a5,a5
	beqz	a5,.L16
	.loc 1 61 5
	li	a1,0
	li	a5,8192
	addi	a0,a5,80
	call	write_reg_u32
	.loc 1 62 12
	li	a5,0
	.loc 1 63 1
	mv	a0,a5
	ld	ra,40(sp)
	.cfi_restore 1
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE8:
	.size	wait_npu_done, .-wait_npu_done
.Letext0:
	.file 2 "include/npu.h"
	.section	.debug_info,"",@progbits
.Ldebug_info0:
	.4byte	0x2fe
	.2byte	0x4
	.4byte	.Ldebug_abbrev0
	.byte	0x8
	.byte	0x1
	.4byte	.LASF22
	.byte	0xc
	.4byte	.LASF23
	.4byte	.LASF24
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
	.byte	0x4
	.4byte	.LASF5
	.byte	0x2
	.byte	0xb
	.byte	0x16
	.4byte	0x61
	.byte	0x5
	.4byte	0x50
	.byte	0x2
	.byte	0x4
	.byte	0x7
	.4byte	.LASF4
	.byte	0x4
	.4byte	.LASF6
	.byte	0x2
	.byte	0xc
	.byte	0x1b
	.4byte	0x79
	.byte	0x5
	.4byte	0x68
	.byte	0x2
	.byte	0x8
	.byte	0x7
	.4byte	.LASF7
	.byte	0x4
	.4byte	.LASF8
	.byte	0x2
	.byte	0xe
	.byte	0x1b
	.4byte	0x79
	.byte	0x6
	.4byte	.LASF11
	.byte	0x1
	.byte	0x34
	.byte	0x5
	.4byte	0x3b
	.8byte	.LFB8
	.8byte	.LFE8-.LFB8
	.byte	0x1
	.byte	0x9c
	.4byte	0xdb
	.byte	0x7
	.string	"fd"
	.byte	0x1
	.byte	0x34
	.byte	0x17
	.4byte	0x3b
	.byte	0x2
	.byte	0x91
	.byte	0x5c
	.byte	0x8
	.4byte	.LASF9
	.byte	0x1
	.byte	0x35
	.byte	0xe
	.4byte	0x50
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0x8
	.4byte	.LASF10
	.byte	0x1
	.byte	0x36
	.byte	0xe
	.4byte	0x50
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0
	.byte	0x6
	.4byte	.LASF12
	.byte	0x1
	.byte	0x2d
	.byte	0x5
	.4byte	0x3b
	.8byte	.LFB7
	.8byte	.LFE7-.LFB7
	.byte	0x1
	.byte	0x9c
	.4byte	0x10c
	.byte	0x7
	.string	"fd"
	.byte	0x1
	.byte	0x2d
	.byte	0x14
	.4byte	0x3b
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0
	.byte	0x6
	.4byte	.LASF13
	.byte	0x1
	.byte	0x25
	.byte	0x5
	.4byte	0x3b
	.8byte	.LFB6
	.8byte	.LFE6-.LFB6
	.byte	0x1
	.byte	0x9c
	.4byte	0x13d
	.byte	0x7
	.string	"fd"
	.byte	0x1
	.byte	0x25
	.byte	0x13
	.4byte	0x3b
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0
	.byte	0x9
	.4byte	.LASF25
	.byte	0x1
	.byte	0x1f
	.byte	0x5
	.4byte	0x3b
	.8byte	.LFB5
	.8byte	.LFE5-.LFB5
	.byte	0x1
	.byte	0x9c
	.byte	0xa
	.4byte	.LASF15
	.byte	0x1
	.byte	0x1a
	.byte	0x14
	.8byte	.LFB4
	.8byte	.LFE4-.LFB4
	.byte	0x1
	.byte	0x9c
	.4byte	0x1b6
	.byte	0xb
	.4byte	.LASF10
	.byte	0x1
	.byte	0x1a
	.byte	0x25
	.4byte	0x50
	.byte	0x2
	.byte	0x91
	.byte	0x5c
	.byte	0x7
	.string	"loc"
	.byte	0x1
	.byte	0x1a
	.byte	0x2f
	.4byte	0x3b
	.byte	0x2
	.byte	0x91
	.byte	0x58
	.byte	0x8
	.4byte	.LASF14
	.byte	0x1
	.byte	0x1b
	.byte	0xe
	.4byte	0x50
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0xc
	.string	"val"
	.byte	0x1
	.byte	0x1c
	.byte	0xe
	.4byte	0x50
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0
	.byte	0xa
	.4byte	.LASF16
	.byte	0x1
	.byte	0x14
	.byte	0x14
	.8byte	.LFB3
	.8byte	.LFE3-.LFB3
	.byte	0x1
	.byte	0x9c
	.4byte	0x211
	.byte	0xb
	.4byte	.LASF10
	.byte	0x1
	.byte	0x14
	.byte	0x25
	.4byte	0x50
	.byte	0x2
	.byte	0x91
	.byte	0x5c
	.byte	0x7
	.string	"loc"
	.byte	0x1
	.byte	0x14
	.byte	0x2f
	.4byte	0x3b
	.byte	0x2
	.byte	0x91
	.byte	0x58
	.byte	0x8
	.4byte	.LASF14
	.byte	0x1
	.byte	0x15
	.byte	0xe
	.4byte	0x50
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0xc
	.string	"val"
	.byte	0x1
	.byte	0x16
	.byte	0xe
	.4byte	0x50
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0
	.byte	0xd
	.4byte	.LASF17
	.byte	0x1
	.byte	0xf
	.byte	0x6
	.8byte	.LFB2
	.8byte	.LFE2-.LFB2
	.byte	0x1
	.byte	0x9c
	.4byte	0x25d
	.byte	0x7
	.string	"us"
	.byte	0x1
	.byte	0xf
	.byte	0x13
	.4byte	0x3b
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0xe
	.8byte	.LBB2
	.8byte	.LBE2-.LBB2
	.byte	0xc
	.string	"i"
	.byte	0x1
	.byte	0x11
	.byte	0xe
	.4byte	0x3b
	.byte	0x2
	.byte	0x91
	.byte	0x7c
	.byte	0
	.byte	0
	.byte	0xd
	.4byte	.LASF18
	.byte	0x1
	.byte	0x9
	.byte	0x6
	.8byte	.LFB1
	.8byte	.LFE1-.LFB1
	.byte	0x1
	.byte	0x9c
	.4byte	0x2a9
	.byte	0xb
	.4byte	.LASF10
	.byte	0x1
	.byte	0x9
	.byte	0x1e
	.4byte	0x80
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0xb
	.4byte	.LASF19
	.byte	0x1
	.byte	0x9
	.byte	0x2d
	.4byte	0x50
	.byte	0x2
	.byte	0x91
	.byte	0x64
	.byte	0x8
	.4byte	.LASF20
	.byte	0x1
	.byte	0xb
	.byte	0x18
	.4byte	0x2a9
	.byte	0x2
	.byte	0x91
	.byte	0x78
	.byte	0
	.byte	0xf
	.byte	0x8
	.4byte	0x5c
	.byte	0xd
	.4byte	.LASF21
	.byte	0x1
	.byte	0x4
	.byte	0x6
	.8byte	.LFB0
	.8byte	.LFE0-.LFB0
	.byte	0x1
	.byte	0x9c
	.4byte	0x2fb
	.byte	0xb
	.4byte	.LASF10
	.byte	0x1
	.byte	0x4
	.byte	0x1e
	.4byte	0x80
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0xb
	.4byte	.LASF19
	.byte	0x1
	.byte	0x4
	.byte	0x2d
	.4byte	0x68
	.byte	0x2
	.byte	0x91
	.byte	0x60
	.byte	0x8
	.4byte	.LASF20
	.byte	0x1
	.byte	0x6
	.byte	0x18
	.4byte	0x2fb
	.byte	0x2
	.byte	0x91
	.byte	0x78
	.byte	0
	.byte	0xf
	.byte	0x8
	.4byte	0x74
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
	.byte	0x16
	.byte	0
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
	.byte	0
	.byte	0
	.byte	0x5
	.byte	0x35
	.byte	0
	.byte	0x49
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x6
	.byte	0x2e
	.byte	0x1
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
	.byte	0x27
	.byte	0x19
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
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x7
	.byte	0x5
	.byte	0
	.byte	0x3
	.byte	0x8
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x2
	.byte	0x18
	.byte	0
	.byte	0
	.byte	0x8
	.byte	0x34
	.byte	0
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
	.byte	0x2
	.byte	0x18
	.byte	0
	.byte	0
	.byte	0x9
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
	.byte	0xa
	.byte	0x2e
	.byte	0x1
	.byte	0x3
	.byte	0xe
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x27
	.byte	0x19
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x7
	.byte	0x40
	.byte	0x18
	.byte	0x96,0x42
	.byte	0x19
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0xb
	.byte	0x5
	.byte	0
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
	.byte	0x2
	.byte	0x18
	.byte	0
	.byte	0
	.byte	0xc
	.byte	0x34
	.byte	0
	.byte	0x3
	.byte	0x8
	.byte	0x3a
	.byte	0xb
	.byte	0x3b
	.byte	0xb
	.byte	0x39
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0x2
	.byte	0x18
	.byte	0
	.byte	0
	.byte	0xd
	.byte	0x2e
	.byte	0x1
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
	.byte	0x27
	.byte	0x19
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x7
	.byte	0x40
	.byte	0x18
	.byte	0x97,0x42
	.byte	0x19
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0xe
	.byte	0xb
	.byte	0x1
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x7
	.byte	0
	.byte	0
	.byte	0xf
	.byte	0xf
	.byte	0
	.byte	0xb
	.byte	0xb
	.byte	0x49
	.byte	0x13
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
.LASF21:
	.string	"write_reg_u64"
.LASF16:
	.string	"clr_reg"
.LASF22:
	.string	"GNU C17 8.2.0 -mcmodel=medany -mabi=lp64 -march=rv64imafd -g -O0 -fno-PIE -fomit-frame-pointer"
.LASF8:
	.string	"uintptr_t"
.LASF7:
	.string	"long unsigned int"
.LASF18:
	.string	"write_reg_u32"
.LASF12:
	.string	"start_conv"
.LASF6:
	.string	"uint64_t"
.LASF10:
	.string	"addr"
.LASF25:
	.string	"init_npu"
.LASF20:
	.string	"loc_addr"
.LASF14:
	.string	"mask"
.LASF2:
	.string	"unsigned char"
.LASF17:
	.string	"sleep_us"
.LASF9:
	.string	"state"
.LASF5:
	.string	"uint32_t"
.LASF13:
	.string	"start_npu"
.LASF23:
	.string	"src/npu.c"
.LASF3:
	.string	"short unsigned int"
.LASF0:
	.string	"signed char"
.LASF15:
	.string	"set_reg"
.LASF24:
	.string	"/home/shenghuan/Projects/github/SiYuan/dv/tests/npu_test_01"
.LASF19:
	.string	"value"
.LASF1:
	.string	"short int"
.LASF11:
	.string	"wait_npu_done"
	.ident	"GCC: (GNU) 8.2.0"

	.file	"uart.c"
	.option nopic
	.text
.Ltext0:
	.cfi_sections	.debug_frame
	.align	2
	.globl	write_reg_u8
	.type	write_reg_u8, @function
write_reg_u8:
.LFB0:
	.file 1 "src/uart.c"
	.loc 1 4 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sd	a0,8(sp)
	mv	a5,a1
	sb	a5,7(sp)
	.loc 1 5 23
	ld	a5,8(sp)
	sd	a5,24(sp)
	.loc 1 6 15
	ld	a5,24(sp)
	lbu	a4,7(sp)
	sb	a4,0(a5)
	.loc 1 7 1
	nop
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE0:
	.size	write_reg_u8, .-write_reg_u8
	.align	2
	.globl	read_reg_u8
	.type	read_reg_u8, @function
read_reg_u8:
.LFB1:
	.loc 1 10 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sd	a0,8(sp)
	.loc 1 11 13
	ld	a5,8(sp)
	.loc 1 11 12
	lbu	a5,0(a5)
	andi	a5,a5,0xff
	.loc 1 12 1
	mv	a0,a5
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE1:
	.size	read_reg_u8, .-read_reg_u8
	.align	2
	.globl	is_transmit_empty
	.type	is_transmit_empty, @function
is_transmit_empty:
.LFB2:
	.loc 1 15 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	sd	ra,8(sp)
	.cfi_offset 1, -8
	.loc 1 16 12
	li	a5,268435456
	addi	a0,a5,20
	call	read_reg_u8
	mv	a5,a0
	.loc 1 16 41
	sext.w	a5,a5
	andi	a5,a5,32
	sext.w	a5,a5
	.loc 1 17 1
	mv	a0,a5
	ld	ra,8(sp)
	.cfi_restore 1
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE2:
	.size	is_transmit_empty, .-is_transmit_empty
	.align	2
	.globl	write_serial
	.type	write_serial, @function
write_serial:
.LFB3:
	.loc 1 20 1
	.cfi_startproc
	addi	sp,sp,-32
	.cfi_def_cfa_offset 32
	sd	ra,24(sp)
	.cfi_offset 1, -8
	mv	a5,a0
	sb	a5,15(sp)
	.loc 1 21 11
	nop
.L7:
	.loc 1 21 12 discriminator 1
	call	is_transmit_empty
	mv	a5,a0
	.loc 1 21 11 discriminator 1
	beqz	a5,.L7
	.loc 1 23 5
	lbu	a5,15(sp)
	mv	a1,a5
	li	a0,268435456
	call	write_reg_u8
	.loc 1 24 1
	nop
	ld	ra,24(sp)
	.cfi_restore 1
	addi	sp,sp,32
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE3:
	.size	write_serial, .-write_serial
	.align	2
	.globl	init_uart
	.type	init_uart, @function
init_uart:
.LFB4:
	.loc 1 27 1
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
	.loc 1 28 37
	lw	a5,8(sp)
	slliw	a5,a5,4
	sext.w	a5,a5
	.loc 1 28 14
	lw	a4,12(sp)
	divuw	a5,a4,a5
	sw	a5,28(sp)
	.loc 1 30 5
	li	a1,0
	li	a5,268435456
	addi	a0,a5,4
	call	write_reg_u8
	.loc 1 31 5
	li	a1,128
	li	a5,268435456
	addi	a0,a5,12
	call	write_reg_u8
	.loc 1 32 5
	lw	a5,28(sp)
	andi	a5,a5,0xff
	mv	a1,a5
	li	a0,268435456
	call	write_reg_u8
	.loc 1 33 43
	lw	a5,28(sp)
	srliw	a5,a5,8
	sext.w	a5,a5
	.loc 1 33 5
	andi	a5,a5,0xff
	mv	a1,a5
	li	a5,268435456
	addi	a0,a5,4
	call	write_reg_u8
	.loc 1 34 5
	li	a1,3
	li	a5,268435456
	addi	a0,a5,12
	call	write_reg_u8
	.loc 1 35 5
	li	a1,199
	li	a5,268435456
	addi	a0,a5,8
	call	write_reg_u8
	.loc 1 36 5
	li	a1,32
	li	a5,268435456
	addi	a0,a5,16
	call	write_reg_u8
	.loc 1 37 1
	nop
	ld	ra,40(sp)
	.cfi_restore 1
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE4:
	.size	init_uart, .-init_uart
	.align	2
	.globl	print_uart
	.type	print_uart, @function
print_uart:
.LFB5:
	.loc 1 40 1
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sd	ra,40(sp)
	.cfi_offset 1, -8
	sd	a0,8(sp)
	.loc 1 41 17
	ld	a5,8(sp)
	sd	a5,24(sp)
	.loc 1 42 11
	j	.L10
.L11:
	.loc 1 44 9
	ld	a5,24(sp)
	lbu	a5,0(a5)
	mv	a0,a5
	call	write_serial
	.loc 1 45 9
	ld	a5,24(sp)
	addi	a5,a5,1
	sd	a5,24(sp)
.L10:
	.loc 1 42 12
	ld	a5,24(sp)
	lbu	a5,0(a5)
	.loc 1 42 11
	bnez	a5,.L11
	.loc 1 47 1
	nop
	ld	ra,40(sp)
	.cfi_restore 1
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE5:
	.size	print_uart, .-print_uart
	.globl	bin_to_hex_table
	.data
	.align	3
	.type	bin_to_hex_table, @object
	.size	bin_to_hex_table, 16
bin_to_hex_table:
	.byte	48
	.byte	49
	.byte	50
	.byte	51
	.byte	52
	.byte	53
	.byte	54
	.byte	55
	.byte	56
	.byte	57
	.byte	65
	.byte	66
	.byte	67
	.byte	68
	.byte	69
	.byte	70
	.text
	.align	2
	.globl	bin_to_hex
	.type	bin_to_hex, @function
bin_to_hex:
.LFB6:
	.loc 1 53 1
	.cfi_startproc
	addi	sp,sp,-16
	.cfi_def_cfa_offset 16
	mv	a5,a0
	sd	a1,0(sp)
	sb	a5,15(sp)
	.loc 1 54 35
	lbu	a5,15(sp)
	sext.w	a5,a5
	andi	a5,a5,15
	sext.w	a4,a5
	.loc 1 54 8
	ld	a5,0(sp)
	addi	a5,a5,1
	.loc 1 54 30
	lla	a3,bin_to_hex_table
	add	a4,a3,a4
	lbu	a4,0(a4)
	.loc 1 54 12
	sb	a4,0(a5)
	.loc 1 55 42
	lbu	a5,15(sp)
	srliw	a5,a5,4
	andi	a5,a5,0xff
	sext.w	a5,a5
	andi	a5,a5,15
	sext.w	a5,a5
	.loc 1 55 30
	lla	a4,bin_to_hex_table
	add	a5,a4,a5
	lbu	a4,0(a5)
	.loc 1 55 12
	ld	a5,0(sp)
	sb	a4,0(a5)
	.loc 1 56 5
	nop
	.loc 1 57 1
	addi	sp,sp,16
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE6:
	.size	bin_to_hex, .-bin_to_hex
	.align	2
	.globl	print_uart_int
	.type	print_uart_int, @function
print_uart_int:
.LFB7:
	.loc 1 60 1
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sd	ra,40(sp)
	.cfi_offset 1, -8
	mv	a5,a0
	sw	a5,12(sp)
	.loc 1 62 12
	li	a5,3
	sw	a5,28(sp)
	.loc 1 62 5
	j	.L15
.L16:
.LBB2:
	.loc 1 64 35 discriminator 3
	lw	a5,28(sp)
	slliw	a5,a5,3
	sext.w	a5,a5
	.loc 1 64 29 discriminator 3
	mv	a4,a5
	lw	a5,12(sp)
	srlw	a5,a5,a4
	sext.w	a5,a5
	.loc 1 64 17 discriminator 3
	sb	a5,27(sp)
	.loc 1 66 9 discriminator 3
	addi	a4,sp,24
	lbu	a5,27(sp)
	mv	a1,a4
	mv	a0,a5
	call	bin_to_hex
	.loc 1 67 25 discriminator 3
	lbu	a5,24(sp)
	.loc 1 67 9 discriminator 3
	mv	a0,a5
	call	write_serial
	.loc 1 68 25 discriminator 3
	lbu	a5,25(sp)
	.loc 1 68 9 discriminator 3
	mv	a0,a5
	call	write_serial
.LBE2:
	.loc 1 62 26 discriminator 3
	lw	a5,28(sp)
	addiw	a5,a5,-1
	sw	a5,28(sp)
.L15:
	.loc 1 62 5 discriminator 1
	lw	a5,28(sp)
	sext.w	a5,a5
	bgez	a5,.L16
	.loc 1 70 1
	nop
	ld	ra,40(sp)
	.cfi_restore 1
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE7:
	.size	print_uart_int, .-print_uart_int
	.align	2
	.globl	print_uart_addr
	.type	print_uart_addr, @function
print_uart_addr:
.LFB8:
	.loc 1 73 1
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sd	ra,40(sp)
	.cfi_offset 1, -8
	sd	a0,8(sp)
	.loc 1 75 12
	li	a5,7
	sw	a5,28(sp)
	.loc 1 75 5
	j	.L18
.L19:
.LBB3:
	.loc 1 77 35 discriminator 3
	lw	a5,28(sp)
	slliw	a5,a5,3
	sext.w	a5,a5
	.loc 1 77 29 discriminator 3
	mv	a4,a5
	ld	a5,8(sp)
	srl	a5,a5,a4
	.loc 1 77 17 discriminator 3
	sb	a5,27(sp)
	.loc 1 79 9 discriminator 3
	addi	a4,sp,24
	lbu	a5,27(sp)
	mv	a1,a4
	mv	a0,a5
	call	bin_to_hex
	.loc 1 80 25 discriminator 3
	lbu	a5,24(sp)
	.loc 1 80 9 discriminator 3
	mv	a0,a5
	call	write_serial
	.loc 1 81 25 discriminator 3
	lbu	a5,25(sp)
	.loc 1 81 9 discriminator 3
	mv	a0,a5
	call	write_serial
.LBE3:
	.loc 1 75 26 discriminator 3
	lw	a5,28(sp)
	addiw	a5,a5,-1
	sw	a5,28(sp)
.L18:
	.loc 1 75 5 discriminator 1
	lw	a5,28(sp)
	sext.w	a5,a5
	bgez	a5,.L19
	.loc 1 83 1
	nop
	ld	ra,40(sp)
	.cfi_restore 1
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE8:
	.size	print_uart_addr, .-print_uart_addr
	.align	2
	.globl	print_uart_byte
	.type	print_uart_byte, @function
print_uart_byte:
.LFB9:
	.loc 1 86 1
	.cfi_startproc
	addi	sp,sp,-48
	.cfi_def_cfa_offset 48
	sd	ra,40(sp)
	.cfi_offset 1, -8
	mv	a5,a0
	sb	a5,15(sp)
	.loc 1 88 5
	addi	a4,sp,24
	lbu	a5,15(sp)
	mv	a1,a4
	mv	a0,a5
	call	bin_to_hex
	.loc 1 89 21
	lbu	a5,24(sp)
	.loc 1 89 5
	mv	a0,a5
	call	write_serial
	.loc 1 90 21
	lbu	a5,25(sp)
	.loc 1 90 5
	mv	a0,a5
	call	write_serial
	.loc 1 91 1
	nop
	ld	ra,40(sp)
	.cfi_restore 1
	addi	sp,sp,48
	.cfi_def_cfa_offset 0
	jr	ra
	.cfi_endproc
.LFE9:
	.size	print_uart_byte, .-print_uart_byte
.Letext0:
	.file 2 "include/uart.h"
	.section	.debug_info,"",@progbits
.Ldebug_info0:
	.4byte	0x385
	.2byte	0x4
	.4byte	.Ldebug_abbrev0
	.byte	0x8
	.byte	0x1
	.4byte	.LASF26
	.byte	0xc
	.4byte	.LASF27
	.4byte	.LASF28
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
	.byte	0x4
	.4byte	.LASF4
	.byte	0x2
	.byte	0x9
	.byte	0x17
	.4byte	0x53
	.byte	0x5
	.4byte	0x42
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
	.4byte	0x6d
	.byte	0x2
	.byte	0x4
	.byte	0x7
	.4byte	.LASF6
	.byte	0x4
	.4byte	.LASF7
	.byte	0x2
	.byte	0xc
	.byte	0x1b
	.4byte	0x80
	.byte	0x2
	.byte	0x8
	.byte	0x7
	.4byte	.LASF8
	.byte	0x4
	.4byte	.LASF9
	.byte	0x2
	.byte	0xe
	.byte	0x1b
	.4byte	0x80
	.byte	0x6
	.4byte	0x42
	.4byte	0xa3
	.byte	0x7
	.4byte	0x80
	.byte	0xf
	.byte	0
	.byte	0x8
	.4byte	.LASF29
	.byte	0x1
	.byte	0x31
	.byte	0x9
	.4byte	0x93
	.byte	0x9
	.byte	0x3
	.8byte	bin_to_hex_table
	.byte	0x9
	.4byte	.LASF10
	.byte	0x1
	.byte	0x55
	.byte	0x6
	.8byte	.LFB9
	.8byte	.LFE9-.LFB9
	.byte	0x1
	.byte	0x9c
	.4byte	0xf6
	.byte	0xa
	.4byte	.LASF12
	.byte	0x1
	.byte	0x55
	.byte	0x1e
	.4byte	0x42
	.byte	0x2
	.byte	0x91
	.byte	0x5f
	.byte	0xb
	.string	"hex"
	.byte	0x1
	.byte	0x57
	.byte	0xd
	.4byte	0xf6
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0
	.byte	0x6
	.4byte	0x42
	.4byte	0x106
	.byte	0x7
	.4byte	0x80
	.byte	0x1
	.byte	0
	.byte	0x9
	.4byte	.LASF11
	.byte	0x1
	.byte	0x48
	.byte	0x6
	.8byte	.LFB8
	.8byte	.LFE8-.LFB8
	.byte	0x1
	.byte	0x9c
	.4byte	0x171
	.byte	0xa
	.4byte	.LASF13
	.byte	0x1
	.byte	0x48
	.byte	0x1f
	.4byte	0x74
	.byte	0x2
	.byte	0x91
	.byte	0x58
	.byte	0xb
	.string	"i"
	.byte	0x1
	.byte	0x4a
	.byte	0x9
	.4byte	0x3b
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0xc
	.8byte	.LBB3
	.8byte	.LBE3-.LBB3
	.byte	0xb
	.string	"cur"
	.byte	0x1
	.byte	0x4d
	.byte	0x11
	.4byte	0x42
	.byte	0x2
	.byte	0x91
	.byte	0x6b
	.byte	0xb
	.string	"hex"
	.byte	0x1
	.byte	0x4e
	.byte	0x11
	.4byte	0xf6
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0
	.byte	0
	.byte	0x9
	.4byte	.LASF14
	.byte	0x1
	.byte	0x3b
	.byte	0x6
	.8byte	.LFB7
	.8byte	.LFE7-.LFB7
	.byte	0x1
	.byte	0x9c
	.4byte	0x1dc
	.byte	0xa
	.4byte	.LASF13
	.byte	0x1
	.byte	0x3b
	.byte	0x1e
	.4byte	0x61
	.byte	0x2
	.byte	0x91
	.byte	0x5c
	.byte	0xb
	.string	"i"
	.byte	0x1
	.byte	0x3d
	.byte	0x9
	.4byte	0x3b
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0xc
	.8byte	.LBB2
	.8byte	.LBE2-.LBB2
	.byte	0xb
	.string	"cur"
	.byte	0x1
	.byte	0x40
	.byte	0x11
	.4byte	0x42
	.byte	0x2
	.byte	0x91
	.byte	0x6b
	.byte	0xb
	.string	"hex"
	.byte	0x1
	.byte	0x41
	.byte	0x11
	.4byte	0xf6
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0
	.byte	0
	.byte	0xd
	.4byte	.LASF15
	.byte	0x1
	.byte	0x34
	.byte	0x6
	.8byte	.LFB6
	.8byte	.LFE6-.LFB6
	.byte	0x1
	.byte	0x9c
	.4byte	0x219
	.byte	0xe
	.string	"inp"
	.byte	0x1
	.byte	0x34
	.byte	0x19
	.4byte	0x42
	.byte	0x2
	.byte	0x91
	.byte	0x7f
	.byte	0xe
	.string	"res"
	.byte	0x1
	.byte	0x34
	.byte	0x26
	.4byte	0x219
	.byte	0x2
	.byte	0x91
	.byte	0x70
	.byte	0
	.byte	0xf
	.byte	0x8
	.4byte	0x42
	.byte	0x9
	.4byte	.LASF16
	.byte	0x1
	.byte	0x27
	.byte	0x6
	.8byte	.LFB5
	.8byte	.LFE5-.LFB5
	.byte	0x1
	.byte	0x9c
	.4byte	0x25c
	.byte	0xe
	.string	"str"
	.byte	0x1
	.byte	0x27
	.byte	0x1d
	.4byte	0x25c
	.byte	0x2
	.byte	0x91
	.byte	0x58
	.byte	0xb
	.string	"cur"
	.byte	0x1
	.byte	0x29
	.byte	0x11
	.4byte	0x25c
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0
	.byte	0xf
	.byte	0x8
	.4byte	0x269
	.byte	0x2
	.byte	0x1
	.byte	0x8
	.4byte	.LASF17
	.byte	0x10
	.4byte	0x262
	.byte	0x9
	.4byte	.LASF18
	.byte	0x1
	.byte	0x1a
	.byte	0x6
	.8byte	.LFB4
	.8byte	.LFE4-.LFB4
	.byte	0x1
	.byte	0x9c
	.4byte	0x2ba
	.byte	0xa
	.4byte	.LASF19
	.byte	0x1
	.byte	0x1a
	.byte	0x19
	.4byte	0x61
	.byte	0x2
	.byte	0x91
	.byte	0x5c
	.byte	0xa
	.4byte	.LASF20
	.byte	0x1
	.byte	0x1a
	.byte	0x28
	.4byte	0x61
	.byte	0x2
	.byte	0x91
	.byte	0x58
	.byte	0x11
	.4byte	.LASF21
	.byte	0x1
	.byte	0x1c
	.byte	0xe
	.4byte	0x61
	.byte	0x2
	.byte	0x91
	.byte	0x6c
	.byte	0
	.byte	0x9
	.4byte	.LASF22
	.byte	0x1
	.byte	0x13
	.byte	0x6
	.8byte	.LFB3
	.8byte	.LFE3-.LFB3
	.byte	0x1
	.byte	0x9c
	.4byte	0x2e6
	.byte	0xe
	.string	"a"
	.byte	0x1
	.byte	0x13
	.byte	0x18
	.4byte	0x262
	.byte	0x2
	.byte	0x91
	.byte	0x6f
	.byte	0
	.byte	0x12
	.4byte	.LASF30
	.byte	0x1
	.byte	0xe
	.byte	0x5
	.4byte	0x3b
	.8byte	.LFB2
	.8byte	.LFE2-.LFB2
	.byte	0x1
	.byte	0x9c
	.byte	0x13
	.4byte	.LASF31
	.byte	0x1
	.byte	0x9
	.byte	0x9
	.4byte	0x42
	.8byte	.LFB1
	.8byte	.LFE1-.LFB1
	.byte	0x1
	.byte	0x9c
	.4byte	0x336
	.byte	0xa
	.4byte	.LASF13
	.byte	0x1
	.byte	0x9
	.byte	0x1f
	.4byte	0x87
	.byte	0x2
	.byte	0x91
	.byte	0x78
	.byte	0
	.byte	0xd
	.4byte	.LASF23
	.byte	0x1
	.byte	0x3
	.byte	0x6
	.8byte	.LFB0
	.8byte	.LFE0-.LFB0
	.byte	0x1
	.byte	0x9c
	.4byte	0x382
	.byte	0xa
	.4byte	.LASF13
	.byte	0x1
	.byte	0x3
	.byte	0x1d
	.4byte	0x87
	.byte	0x2
	.byte	0x91
	.byte	0x68
	.byte	0xa
	.4byte	.LASF24
	.byte	0x1
	.byte	0x3
	.byte	0x2b
	.4byte	0x42
	.byte	0x2
	.byte	0x91
	.byte	0x67
	.byte	0x11
	.4byte	.LASF25
	.byte	0x1
	.byte	0x5
	.byte	0x17
	.4byte	0x382
	.byte	0x2
	.byte	0x91
	.byte	0x78
	.byte	0
	.byte	0xf
	.byte	0x8
	.4byte	0x4e
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
	.byte	0x1
	.byte	0x1
	.byte	0x49
	.byte	0x13
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x7
	.byte	0x21
	.byte	0
	.byte	0x49
	.byte	0x13
	.byte	0x2f
	.byte	0xb
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
	.byte	0x3f
	.byte	0x19
	.byte	0x2
	.byte	0x18
	.byte	0
	.byte	0
	.byte	0x9
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
	.byte	0x96,0x42
	.byte	0x19
	.byte	0x1
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0xa
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
	.byte	0xb
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
	.byte	0xc
	.byte	0xb
	.byte	0x1
	.byte	0x11
	.byte	0x1
	.byte	0x12
	.byte	0x7
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
	.byte	0xf
	.byte	0xf
	.byte	0
	.byte	0xb
	.byte	0xb
	.byte	0x49
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x10
	.byte	0x26
	.byte	0
	.byte	0x49
	.byte	0x13
	.byte	0
	.byte	0
	.byte	0x11
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
	.byte	0x12
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
	.byte	0x13
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
	.byte	0x97,0x42
	.byte	0x19
	.byte	0x1
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
.LASF24:
	.string	"value"
.LASF21:
	.string	"divisor"
.LASF6:
	.string	"unsigned int"
.LASF14:
	.string	"print_uart_int"
.LASF30:
	.string	"is_transmit_empty"
.LASF16:
	.string	"print_uart"
.LASF20:
	.string	"baud"
.LASF26:
	.string	"GNU C17 8.2.0 -mcmodel=medany -mabi=lp64 -march=rv64imafd -g -O0 -fno-PIE -fomit-frame-pointer"
.LASF9:
	.string	"uintptr_t"
.LASF8:
	.string	"long unsigned int"
.LASF25:
	.string	"loc_addr"
.LASF7:
	.string	"uint64_t"
.LASF13:
	.string	"addr"
.LASF19:
	.string	"freq"
.LASF11:
	.string	"print_uart_addr"
.LASF15:
	.string	"bin_to_hex"
.LASF4:
	.string	"uint8_t"
.LASF2:
	.string	"unsigned char"
.LASF5:
	.string	"uint32_t"
.LASF31:
	.string	"read_reg_u8"
.LASF12:
	.string	"byte"
.LASF3:
	.string	"short unsigned int"
.LASF27:
	.string	"src/uart.c"
.LASF18:
	.string	"init_uart"
.LASF29:
	.string	"bin_to_hex_table"
.LASF28:
	.string	"/home/shenghuan/Projects/github/SiYuan/dv/tests/npu_test_01"
.LASF17:
	.string	"char"
.LASF22:
	.string	"write_serial"
.LASF10:
	.string	"print_uart_byte"
.LASF1:
	.string	"short int"
.LASF23:
	.string	"write_reg_u8"
.LASF0:
	.string	"signed char"
	.ident	"GCC: (GNU) 8.2.0"

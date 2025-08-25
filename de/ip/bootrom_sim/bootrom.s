
bootrom.elf：     文件格式 elf64-littleriscv


Disassembly of section .text.init:

0000000000010000 <_prog_start>:
   10000:	00800913          	li	s2,8
   10004:	30491073          	csrw	mie,s2
   10008:	00000493          	li	s1,0
   1000c:	f1402973          	csrr	s2,mhartid
   10010:	03249663          	bne	s1,s2,1003c <_prog_start+0x3c>
   10014:	0210011b          	addiw	sp,zero,33
   10018:	01a11113          	slli	sp,sp,0x1a
   1001c:	2b0000ef          	jal	ra,102cc <_TEXT_END_>
   10020:	020004b7          	lui	s1,0x2000
   10024:	00100913          	li	s2,1
   10028:	0124a023          	sw	s2,0(s1) # 2000000 <_RODATA_END_+0x1feec20>
   1002c:	00448493          	addi	s1,s1,4
   10030:	02000937          	lui	s2,0x2000
   10034:	0109091b          	addiw	s2,s2,16
   10038:	ff24c6e3          	blt	s1,s2,10024 <_prog_start+0x24>
   1003c:	10500073          	wfi
   10040:	34402973          	csrr	s2,mip
   10044:	00897913          	andi	s2,s2,8
   10048:	fe090ae3          	beqz	s2,1003c <_prog_start+0x3c>
   1004c:	020004b7          	lui	s1,0x2000
   10050:	f1402973          	csrr	s2,mhartid
   10054:	00291913          	slli	s2,s2,0x2
   10058:	00990933          	add	s2,s2,s1
   1005c:	00092023          	sw	zero,0(s2) # 2000000 <_RODATA_END_+0x1feec20>
   10060:	0004a903          	lw	s2,0(s1) # 2000000 <_RODATA_END_+0x1feec20>
   10064:	fe091ee3          	bnez	s2,10060 <_prog_start+0x60>
   10068:	00448493          	addi	s1,s1,4
   1006c:	02000937          	lui	s2,0x2000
   10070:	0109091b          	addiw	s2,s2,16
   10074:	ff24c6e3          	blt	s1,s2,10060 <_prog_start+0x60>
   10078:	f1402573          	csrr	a0,mhartid
   1007c:	00000597          	auipc	a1,0x0
   10080:	48458593          	addi	a1,a1,1156 # 10500 <_BSS_END_>
   10084:	0010049b          	addiw	s1,zero,1
   10088:	01f49493          	slli	s1,s1,0x1f
   1008c:	00048067          	jr	s1

Disassembly of section .text:

0000000000010100 <write_reg_u8>:
   10100:	00b50023          	sb	a1,0(a0)
   10104:	00008067          	ret

0000000000010108 <read_reg_u8>:
   10108:	00054503          	lbu	a0,0(a0)
   1010c:	00008067          	ret

0000000000010110 <is_transmit_empty>:
   10110:	100007b7          	lui	a5,0x10000
   10114:	0147c503          	lbu	a0,20(a5) # 10000014 <_RODATA_END_+0xffeec34>
   10118:	02057513          	andi	a0,a0,32
   1011c:	00008067          	ret

0000000000010120 <write_serial>:
   10120:	10000737          	lui	a4,0x10000
   10124:	01474783          	lbu	a5,20(a4) # 10000014 <_RODATA_END_+0xffeec34>
   10128:	0207f793          	andi	a5,a5,32
   1012c:	fe078ce3          	beqz	a5,10124 <write_serial+0x4>
   10130:	00a70023          	sb	a0,0(a4)
   10134:	00008067          	ret

0000000000010138 <init_uart>:
   10138:	0045959b          	slliw	a1,a1,0x4
   1013c:	02b5553b          	divuw	a0,a0,a1
   10140:	100007b7          	lui	a5,0x10000
   10144:	00078223          	sb	zero,4(a5) # 10000004 <_RODATA_END_+0xffeec24>
   10148:	f8000713          	li	a4,-128
   1014c:	00e78623          	sb	a4,12(a5)
   10150:	0ff57713          	andi	a4,a0,255
   10154:	0085551b          	srliw	a0,a0,0x8
   10158:	00e78023          	sb	a4,0(a5)
   1015c:	0ff57513          	andi	a0,a0,255
   10160:	00a78223          	sb	a0,4(a5)
   10164:	00300713          	li	a4,3
   10168:	00e78623          	sb	a4,12(a5)
   1016c:	fc700713          	li	a4,-57
   10170:	00e78423          	sb	a4,8(a5)
   10174:	02000713          	li	a4,32
   10178:	00e78823          	sb	a4,16(a5)
   1017c:	00008067          	ret

0000000000010180 <print_uart>:
   10180:	ff010113          	addi	sp,sp,-16
   10184:	00813023          	sd	s0,0(sp)
   10188:	00113423          	sd	ra,8(sp)
   1018c:	00050413          	mv	s0,a0
   10190:	00044503          	lbu	a0,0(s0)
   10194:	00051a63          	bnez	a0,101a8 <print_uart+0x28>
   10198:	00813083          	ld	ra,8(sp)
   1019c:	00013403          	ld	s0,0(sp)
   101a0:	01010113          	addi	sp,sp,16
   101a4:	00008067          	ret
   101a8:	f79ff0ef          	jal	ra,10120 <write_serial>
   101ac:	00140413          	addi	s0,s0,1
   101b0:	fe1ff06f          	j	10190 <print_uart+0x10>

00000000000101b4 <bin_to_hex>:
   101b4:	00000797          	auipc	a5,0x0
   101b8:	24c78793          	addi	a5,a5,588 # 10400 <bin_to_hex_table>
   101bc:	00f57713          	andi	a4,a0,15
   101c0:	00e78733          	add	a4,a5,a4
   101c4:	00074703          	lbu	a4,0(a4)
   101c8:	00455513          	srli	a0,a0,0x4
   101cc:	00a787b3          	add	a5,a5,a0
   101d0:	00e580a3          	sb	a4,1(a1)
   101d4:	0007c783          	lbu	a5,0(a5)
   101d8:	00f58023          	sb	a5,0(a1)
   101dc:	00008067          	ret

00000000000101e0 <print_uart_int>:
   101e0:	fd010113          	addi	sp,sp,-48
   101e4:	02813023          	sd	s0,32(sp)
   101e8:	00913c23          	sd	s1,24(sp)
   101ec:	01213823          	sd	s2,16(sp)
   101f0:	02113423          	sd	ra,40(sp)
   101f4:	00050913          	mv	s2,a0
   101f8:	01800413          	li	s0,24
   101fc:	ff800493          	li	s1,-8
   10200:	0089553b          	srlw	a0,s2,s0
   10204:	00810593          	addi	a1,sp,8
   10208:	0ff57513          	andi	a0,a0,255
   1020c:	fa9ff0ef          	jal	ra,101b4 <bin_to_hex>
   10210:	00814503          	lbu	a0,8(sp)
   10214:	ff84041b          	addiw	s0,s0,-8
   10218:	f09ff0ef          	jal	ra,10120 <write_serial>
   1021c:	00914503          	lbu	a0,9(sp)
   10220:	f01ff0ef          	jal	ra,10120 <write_serial>
   10224:	fc941ee3          	bne	s0,s1,10200 <print_uart_int+0x20>
   10228:	02813083          	ld	ra,40(sp)
   1022c:	02013403          	ld	s0,32(sp)
   10230:	01813483          	ld	s1,24(sp)
   10234:	01013903          	ld	s2,16(sp)
   10238:	03010113          	addi	sp,sp,48
   1023c:	00008067          	ret

0000000000010240 <print_uart_addr>:
   10240:	fd010113          	addi	sp,sp,-48
   10244:	02813023          	sd	s0,32(sp)
   10248:	00913c23          	sd	s1,24(sp)
   1024c:	01213823          	sd	s2,16(sp)
   10250:	02113423          	sd	ra,40(sp)
   10254:	00050913          	mv	s2,a0
   10258:	03800413          	li	s0,56
   1025c:	ff800493          	li	s1,-8
   10260:	00895533          	srl	a0,s2,s0
   10264:	00810593          	addi	a1,sp,8
   10268:	0ff57513          	andi	a0,a0,255
   1026c:	f49ff0ef          	jal	ra,101b4 <bin_to_hex>
   10270:	00814503          	lbu	a0,8(sp)
   10274:	ff84041b          	addiw	s0,s0,-8
   10278:	ea9ff0ef          	jal	ra,10120 <write_serial>
   1027c:	00914503          	lbu	a0,9(sp)
   10280:	ea1ff0ef          	jal	ra,10120 <write_serial>
   10284:	fc941ee3          	bne	s0,s1,10260 <print_uart_addr+0x20>
   10288:	02813083          	ld	ra,40(sp)
   1028c:	02013403          	ld	s0,32(sp)
   10290:	01813483          	ld	s1,24(sp)
   10294:	01013903          	ld	s2,16(sp)
   10298:	03010113          	addi	sp,sp,48
   1029c:	00008067          	ret

00000000000102a0 <print_uart_byte>:
   102a0:	fe010113          	addi	sp,sp,-32
   102a4:	00810593          	addi	a1,sp,8
   102a8:	00113c23          	sd	ra,24(sp)
   102ac:	f09ff0ef          	jal	ra,101b4 <bin_to_hex>
   102b0:	00814503          	lbu	a0,8(sp)
   102b4:	e6dff0ef          	jal	ra,10120 <write_serial>
   102b8:	00914503          	lbu	a0,9(sp)
   102bc:	e65ff0ef          	jal	ra,10120 <write_serial>
   102c0:	01813083          	ld	ra,24(sp)
   102c4:	02010113          	addi	sp,sp,32
   102c8:	00008067          	ret

Disassembly of section .text.startup:

00000000000102cc <main>:
   102cc:	0001c5b7          	lui	a1,0x1c
   102d0:	02faf537          	lui	a0,0x2faf
   102d4:	ff010113          	addi	sp,sp,-16
   102d8:	20058593          	addi	a1,a1,512 # 1c200 <_RODATA_END_+0xae20>
   102dc:	08050513          	addi	a0,a0,128 # 2faf080 <_RODATA_END_+0x2f9dca0>
   102e0:	00113423          	sd	ra,8(sp)
   102e4:	e55ff0ef          	jal	ra,10138 <init_uart>
   102e8:	00001517          	auipc	a0,0x1
   102ec:	0e850513          	addi	a0,a0,232 # 113d0 <_BSS_END_+0xed0>
   102f0:	e91ff0ef          	jal	ra,10180 <print_uart>
   102f4:	00813083          	ld	ra,8(sp)
   102f8:	00000513          	li	a0,0
   102fc:	01010113          	addi	sp,sp,16
   10300:	00008067          	ret

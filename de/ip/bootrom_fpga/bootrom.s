
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
   1001c:	1d9000ef          	jal	ra,109f4 <_TEXT_END_>
   10020:	020004b7          	lui	s1,0x2000
   10024:	00100913          	li	s2,1
   10028:	0124a023          	sw	s2,0(s1) # 2000000 <_RODATA_END_+0x1fee9d8>
   1002c:	00448493          	addi	s1,s1,4
   10030:	02000937          	lui	s2,0x2000
   10034:	0209091b          	addiw	s2,s2,32
   10038:	ff24c6e3          	blt	s1,s2,10024 <_prog_start+0x24>
   1003c:	10500073          	wfi
   10040:	34402973          	csrr	s2,mip
   10044:	00897913          	andi	s2,s2,8
   10048:	fe090ae3          	beqz	s2,1003c <_prog_start+0x3c>
   1004c:	020004b7          	lui	s1,0x2000
   10050:	f1402973          	csrr	s2,mhartid
   10054:	00291913          	slli	s2,s2,0x2
   10058:	00990933          	add	s2,s2,s1
   1005c:	00092023          	sw	zero,0(s2) # 2000000 <_RODATA_END_+0x1fee9d8>
   10060:	0004a903          	lw	s2,0(s1) # 2000000 <_RODATA_END_+0x1fee9d8>
   10064:	fe091ee3          	bnez	s2,10060 <_prog_start+0x60>
   10068:	00448493          	addi	s1,s1,4
   1006c:	02000937          	lui	s2,0x2000
   10070:	0209091b          	addiw	s2,s2,32
   10074:	ff24c6e3          	blt	s1,s2,10060 <_prog_start+0x60>
   10078:	f1402573          	csrr	a0,mhartid
   1007c:	00001597          	auipc	a1,0x1
   10080:	b8458593          	addi	a1,a1,-1148 # 10c00 <_BSS_END_>
   10084:	0010049b          	addiw	s1,zero,1
   10088:	01f49493          	slli	s1,s1,0x1f
   1008c:	00048067          	jr	s1

Disassembly of section .text:

0000000000010100 <copy>:
   10100:	ff010113          	addi	sp,sp,-16
   10104:	00113423          	sd	ra,8(sp)
   10108:	00813023          	sd	s0,0(sp)
   1010c:	6e4000ef          	jal	ra,107f0 <init_sd>
   10110:	02050463          	beqz	a0,10138 <copy+0x38>
   10114:	00001517          	auipc	a0,0x1
   10118:	3c450513          	addi	a0,a0,964 # 114d8 <_BSS_END_+0x8d8>
   1011c:	10c000ef          	jal	ra,10228 <print_uart>
   10120:	fff00413          	li	s0,-1
   10124:	00040513          	mv	a0,s0
   10128:	00813083          	ld	ra,8(sp)
   1012c:	00013403          	ld	s0,0(sp)
   10130:	01010113          	addi	sp,sp,16
   10134:	00008067          	ret
   10138:	00001517          	auipc	a0,0x1
   1013c:	3c850513          	addi	a0,a0,968 # 11500 <_BSS_END_+0x900>
   10140:	0e8000ef          	jal	ra,10228 <print_uart>
   10144:	000015b7          	lui	a1,0x1
   10148:	00100513          	li	a0,1
   1014c:	00008637          	lui	a2,0x8
   10150:	80058593          	addi	a1,a1,-2048 # 800 <ROM_BASE-0xf800>
   10154:	01f51513          	slli	a0,a0,0x1f
   10158:	780000ef          	jal	ra,108d8 <sd_read_data>
   1015c:	00050413          	mv	s0,a0
   10160:	02050c63          	beqz	a0,10198 <copy+0x98>
   10164:	00001517          	auipc	a0,0x1
   10168:	3b450513          	addi	a0,a0,948 # 11518 <_BSS_END_+0x918>
   1016c:	0bc000ef          	jal	ra,10228 <print_uart>
   10170:	00001517          	auipc	a0,0x1
   10174:	3c050513          	addi	a0,a0,960 # 11530 <_BSS_END_+0x930>
   10178:	0b0000ef          	jal	ra,10228 <print_uart>
   1017c:	00040513          	mv	a0,s0
   10180:	168000ef          	jal	ra,102e8 <print_uart_addr>
   10184:	00001517          	auipc	a0,0x1
   10188:	42450513          	addi	a0,a0,1060 # 115a8 <_BSS_END_+0x9a8>
   1018c:	09c000ef          	jal	ra,10228 <print_uart>
   10190:	ffe00413          	li	s0,-2
   10194:	f91ff06f          	j	10124 <copy+0x24>
   10198:	00001517          	auipc	a0,0x1
   1019c:	3b050513          	addi	a0,a0,944 # 11548 <_BSS_END_+0x948>
   101a0:	088000ef          	jal	ra,10228 <print_uart>
   101a4:	f81ff06f          	j	10124 <copy+0x24>

00000000000101a8 <write_reg_u8>:
   101a8:	00b50023          	sb	a1,0(a0)
   101ac:	00008067          	ret

00000000000101b0 <read_reg_u8>:
   101b0:	00054503          	lbu	a0,0(a0)
   101b4:	00008067          	ret

00000000000101b8 <is_transmit_empty>:
   101b8:	100007b7          	lui	a5,0x10000
   101bc:	0147c503          	lbu	a0,20(a5) # 10000014 <_RODATA_END_+0xffee9ec>
   101c0:	02057513          	andi	a0,a0,32
   101c4:	00008067          	ret

00000000000101c8 <write_serial>:
   101c8:	10000737          	lui	a4,0x10000
   101cc:	01474783          	lbu	a5,20(a4) # 10000014 <_RODATA_END_+0xffee9ec>
   101d0:	0207f793          	andi	a5,a5,32
   101d4:	fe078ce3          	beqz	a5,101cc <write_serial+0x4>
   101d8:	00a70023          	sb	a0,0(a4)
   101dc:	00008067          	ret

00000000000101e0 <init_uart>:
   101e0:	0045959b          	slliw	a1,a1,0x4
   101e4:	02b5553b          	divuw	a0,a0,a1
   101e8:	100007b7          	lui	a5,0x10000
   101ec:	00078223          	sb	zero,4(a5) # 10000004 <_RODATA_END_+0xffee9dc>
   101f0:	f8000713          	li	a4,-128
   101f4:	00e78623          	sb	a4,12(a5)
   101f8:	0ff57713          	andi	a4,a0,255
   101fc:	0085551b          	srliw	a0,a0,0x8
   10200:	00e78023          	sb	a4,0(a5)
   10204:	0ff57513          	andi	a0,a0,255
   10208:	00a78223          	sb	a0,4(a5)
   1020c:	00300713          	li	a4,3
   10210:	00e78623          	sb	a4,12(a5)
   10214:	fc700713          	li	a4,-57
   10218:	00e78423          	sb	a4,8(a5)
   1021c:	02000713          	li	a4,32
   10220:	00e78823          	sb	a4,16(a5)
   10224:	00008067          	ret

0000000000010228 <print_uart>:
   10228:	ff010113          	addi	sp,sp,-16
   1022c:	00813023          	sd	s0,0(sp)
   10230:	00113423          	sd	ra,8(sp)
   10234:	00050413          	mv	s0,a0
   10238:	00044503          	lbu	a0,0(s0)
   1023c:	00051a63          	bnez	a0,10250 <print_uart+0x28>
   10240:	00813083          	ld	ra,8(sp)
   10244:	00013403          	ld	s0,0(sp)
   10248:	01010113          	addi	sp,sp,16
   1024c:	00008067          	ret
   10250:	f79ff0ef          	jal	ra,101c8 <write_serial>
   10254:	00140413          	addi	s0,s0,1
   10258:	fe1ff06f          	j	10238 <print_uart+0x10>

000000000001025c <bin_to_hex>:
   1025c:	00001797          	auipc	a5,0x1
   10260:	8a478793          	addi	a5,a5,-1884 # 10b00 <bin_to_hex_table>
   10264:	00f57713          	andi	a4,a0,15
   10268:	00e78733          	add	a4,a5,a4
   1026c:	00074703          	lbu	a4,0(a4)
   10270:	00455513          	srli	a0,a0,0x4
   10274:	00a787b3          	add	a5,a5,a0
   10278:	00e580a3          	sb	a4,1(a1)
   1027c:	0007c783          	lbu	a5,0(a5)
   10280:	00f58023          	sb	a5,0(a1)
   10284:	00008067          	ret

0000000000010288 <print_uart_int>:
   10288:	fd010113          	addi	sp,sp,-48
   1028c:	02813023          	sd	s0,32(sp)
   10290:	00913c23          	sd	s1,24(sp)
   10294:	01213823          	sd	s2,16(sp)
   10298:	02113423          	sd	ra,40(sp)
   1029c:	00050913          	mv	s2,a0
   102a0:	01800413          	li	s0,24
   102a4:	ff800493          	li	s1,-8
   102a8:	0089553b          	srlw	a0,s2,s0
   102ac:	00810593          	addi	a1,sp,8
   102b0:	0ff57513          	andi	a0,a0,255
   102b4:	fa9ff0ef          	jal	ra,1025c <bin_to_hex>
   102b8:	00814503          	lbu	a0,8(sp)
   102bc:	ff84041b          	addiw	s0,s0,-8
   102c0:	f09ff0ef          	jal	ra,101c8 <write_serial>
   102c4:	00914503          	lbu	a0,9(sp)
   102c8:	f01ff0ef          	jal	ra,101c8 <write_serial>
   102cc:	fc941ee3          	bne	s0,s1,102a8 <print_uart_int+0x20>
   102d0:	02813083          	ld	ra,40(sp)
   102d4:	02013403          	ld	s0,32(sp)
   102d8:	01813483          	ld	s1,24(sp)
   102dc:	01013903          	ld	s2,16(sp)
   102e0:	03010113          	addi	sp,sp,48
   102e4:	00008067          	ret

00000000000102e8 <print_uart_addr>:
   102e8:	fd010113          	addi	sp,sp,-48
   102ec:	02813023          	sd	s0,32(sp)
   102f0:	00913c23          	sd	s1,24(sp)
   102f4:	01213823          	sd	s2,16(sp)
   102f8:	02113423          	sd	ra,40(sp)
   102fc:	00050913          	mv	s2,a0
   10300:	03800413          	li	s0,56
   10304:	ff800493          	li	s1,-8
   10308:	00895533          	srl	a0,s2,s0
   1030c:	00810593          	addi	a1,sp,8
   10310:	0ff57513          	andi	a0,a0,255
   10314:	f49ff0ef          	jal	ra,1025c <bin_to_hex>
   10318:	00814503          	lbu	a0,8(sp)
   1031c:	ff84041b          	addiw	s0,s0,-8
   10320:	ea9ff0ef          	jal	ra,101c8 <write_serial>
   10324:	00914503          	lbu	a0,9(sp)
   10328:	ea1ff0ef          	jal	ra,101c8 <write_serial>
   1032c:	fc941ee3          	bne	s0,s1,10308 <print_uart_addr+0x20>
   10330:	02813083          	ld	ra,40(sp)
   10334:	02013403          	ld	s0,32(sp)
   10338:	01813483          	ld	s1,24(sp)
   1033c:	01013903          	ld	s2,16(sp)
   10340:	03010113          	addi	sp,sp,48
   10344:	00008067          	ret

0000000000010348 <print_uart_byte>:
   10348:	fe010113          	addi	sp,sp,-32
   1034c:	00810593          	addi	a1,sp,8
   10350:	00113c23          	sd	ra,24(sp)
   10354:	f09ff0ef          	jal	ra,1025c <bin_to_hex>
   10358:	00814503          	lbu	a0,8(sp)
   1035c:	e6dff0ef          	jal	ra,101c8 <write_serial>
   10360:	00914503          	lbu	a0,9(sp)
   10364:	e65ff0ef          	jal	ra,101c8 <write_serial>
   10368:	01813083          	ld	ra,24(sp)
   1036c:	02010113          	addi	sp,sp,32
   10370:	00008067          	ret

0000000000010374 <write_reg_u32>:
   10374:	00b52023          	sw	a1,0(a0)
   10378:	00008067          	ret

000000000001037c <Dma_trans>:
   1037c:	000307b7          	lui	a5,0x30
   10380:	00a7a023          	sw	a0,0(a5) # 30000 <_RODATA_END_+0x1e9d8>
   10384:	00b7a423          	sw	a1,8(a5)
   10388:	00d7a823          	sw	a3,16(a5)
   1038c:	00c7ac23          	sw	a2,24(a5)
   10390:	02e7a023          	sw	a4,32(a5)
   10394:	00008067          	ret

0000000000010398 <Dma_start>:
   10398:	000307b7          	lui	a5,0x30
   1039c:	00100713          	li	a4,1
   103a0:	00e7ae23          	sw	a4,28(a5) # 3001c <_RODATA_END_+0x1e9f4>
   103a4:	00008067          	ret

00000000000103a8 <is_Dma_done>:
   103a8:	000307b7          	lui	a5,0x30
   103ac:	01c7a503          	lw	a0,28(a5) # 3001c <_RODATA_END_+0x1e9f4>
   103b0:	00257513          	andi	a0,a0,2
   103b4:	00008067          	ret

00000000000103b8 <flush_done>:
   103b8:	000307b7          	lui	a5,0x30
   103bc:	0007ae23          	sw	zero,28(a5) # 3001c <_RODATA_END_+0x1e9f4>
   103c0:	00008067          	ret

00000000000103c4 <write_reg>:
   103c4:	00b52023          	sw	a1,0(a0)
   103c8:	00008067          	ret

00000000000103cc <read_reg>:
   103cc:	00052503          	lw	a0,0(a0)
   103d0:	0005051b          	sext.w	a0,a0
   103d4:	00008067          	ret

00000000000103d8 <spi_init>:
   103d8:	00001517          	auipc	a0,0x1
   103dc:	ff010113          	addi	sp,sp,-16
   103e0:	1a050513          	addi	a0,a0,416 # 11578 <_BSS_END_+0x978>
   103e4:	00113423          	sd	ra,8(sp)
   103e8:	00813023          	sd	s0,0(sp)
   103ec:	e3dff0ef          	jal	ra,10228 <print_uart>
   103f0:	200007b7          	lui	a5,0x20000
   103f4:	01000713          	li	a4,16
   103f8:	00e7a023          	sw	a4,0(a5) # 20000000 <_RODATA_END_+0x1ffee9d8>
   103fc:	00400713          	li	a4,4
   10400:	00e7a223          	sw	a4,4(a5)
   10404:	0007a403          	lw	s0,0(a5)
   10408:	00001517          	auipc	a0,0x1
   1040c:	18050513          	addi	a0,a0,384 # 11588 <_BSS_END_+0x988>
   10410:	e19ff0ef          	jal	ra,10228 <print_uart>
   10414:	0004041b          	sext.w	s0,s0
   10418:	02041513          	slli	a0,s0,0x20
   1041c:	02055513          	srli	a0,a0,0x20
   10420:	ec9ff0ef          	jal	ra,102e8 <print_uart_addr>
   10424:	00001517          	auipc	a0,0x1
   10428:	18450513          	addi	a0,a0,388 # 115a8 <_BSS_END_+0x9a8>
   1042c:	dfdff0ef          	jal	ra,10228 <print_uart>
   10430:	00013403          	ld	s0,0(sp)
   10434:	00813083          	ld	ra,8(sp)
   10438:	00001517          	auipc	a0,0x1
   1043c:	16050513          	addi	a0,a0,352 # 11598 <_BSS_END_+0x998>
   10440:	01010113          	addi	sp,sp,16
   10444:	de5ff06f          	j	10228 <print_uart>

0000000000010448 <spi_tx>:
   10448:	200007b7          	lui	a5,0x20000
   1044c:	10000713          	li	a4,256
   10450:	00e7a023          	sw	a4,0(a5) # 20000000 <_RODATA_END_+0x1ffee9d8>
   10454:	00080737          	lui	a4,0x80
   10458:	00e7a823          	sw	a4,16(a5)
   1045c:	0185151b          	slliw	a0,a0,0x18
   10460:	02a7a023          	sw	a0,32(a5)
   10464:	10200713          	li	a4,258
   10468:	0007aa23          	sw	zero,20(a5)
   1046c:	00e7a023          	sw	a4,0(a5)
   10470:	20000737          	lui	a4,0x20000
   10474:	00072783          	lw	a5,0(a4) # 20000000 <_RODATA_END_+0x1ffee9d8>
   10478:	0017f793          	andi	a5,a5,1
   1047c:	fe078ce3          	beqz	a5,10474 <spi_tx+0x2c>
   10480:	00072023          	sw	zero,0(a4)
   10484:	00008067          	ret

0000000000010488 <spi_rx>:
   10488:	200007b7          	lui	a5,0x20000
   1048c:	10000713          	li	a4,256
   10490:	00e7a023          	sw	a4,0(a5) # 20000000 <_RODATA_END_+0x1ffee9d8>
   10494:	00080737          	lui	a4,0x80
   10498:	00e7a823          	sw	a4,16(a5)
   1049c:	0007aa23          	sw	zero,20(a5)
   104a0:	10100713          	li	a4,257
   104a4:	00e7a023          	sw	a4,0(a5)
   104a8:	0007a703          	lw	a4,0(a5)
   104ac:	00177713          	andi	a4,a4,1
   104b0:	fe070ce3          	beqz	a4,104a8 <spi_rx+0x20>
   104b4:	0407a503          	lw	a0,64(a5)
   104b8:	0007a023          	sw	zero,0(a5)
   104bc:	0ff57513          	andi	a0,a0,255
   104c0:	00008067          	ret

00000000000104c4 <spi_txrx>:
   104c4:	200007b7          	lui	a5,0x20000
   104c8:	10000713          	li	a4,256
   104cc:	00e7a023          	sw	a4,0(a5) # 20000000 <_RODATA_END_+0x1ffee9d8>
   104d0:	00080737          	lui	a4,0x80
   104d4:	00e7a823          	sw	a4,16(a5)
   104d8:	0185151b          	slliw	a0,a0,0x18
   104dc:	02a7a023          	sw	a0,32(a5)
   104e0:	0007aa23          	sw	zero,20(a5)
   104e4:	10300713          	li	a4,259
   104e8:	00e7a023          	sw	a4,0(a5)
   104ec:	0007a703          	lw	a4,0(a5)
   104f0:	00177713          	andi	a4,a4,1
   104f4:	fe070ce3          	beqz	a4,104ec <spi_txrx+0x28>
   104f8:	0407a503          	lw	a0,64(a5)
   104fc:	0007a023          	sw	zero,0(a5)
   10500:	0ff57513          	andi	a0,a0,255
   10504:	00008067          	ret

0000000000010508 <spi_read_block>:
   10508:	200007b7          	lui	a5,0x20000
   1050c:	10000713          	li	a4,256
   10510:	00e7a023          	sw	a4,0(a5) # 20000000 <_RODATA_END_+0x1ffee9d8>
   10514:	00200737          	lui	a4,0x200
   10518:	00e7a823          	sw	a4,16(a5)
   1051c:	0007aa23          	sw	zero,20(a5)
   10520:	20050693          	addi	a3,a0,512
   10524:	02078613          	addi	a2,a5,32
   10528:	fff00813          	li	a6,-1
   1052c:	10300593          	li	a1,259
   10530:	01062023          	sw	a6,0(a2) # 8000 <ROM_BASE-0x8000>
   10534:	00b7a023          	sw	a1,0(a5)
   10538:	0007a703          	lw	a4,0(a5)
   1053c:	00177713          	andi	a4,a4,1
   10540:	fe070ce3          	beqz	a4,10538 <spi_read_block+0x30>
   10544:	0407a703          	lw	a4,64(a5)
   10548:	00450513          	addi	a0,a0,4
   1054c:	fee52e23          	sw	a4,-4(a0)
   10550:	fed510e3          	bne	a0,a3,10530 <spi_read_block+0x28>
   10554:	0007a023          	sw	zero,0(a5)
   10558:	00008067          	ret

000000000001055c <sd_dummy>:
   1055c:	0ff00513          	li	a0,255
   10560:	f65ff06f          	j	104c4 <spi_txrx>

0000000000010564 <sd_cmd>:
   10564:	fd010113          	addi	sp,sp,-48
   10568:	02113423          	sd	ra,40(sp)
   1056c:	00c13423          	sd	a2,8(sp)
   10570:	02813023          	sd	s0,32(sp)
   10574:	00913c23          	sd	s1,24(sp)
   10578:	00058413          	mv	s0,a1
   1057c:	00050493          	mv	s1,a0
   10580:	fddff0ef          	jal	ra,1055c <sd_dummy>
   10584:	0404e513          	ori	a0,s1,64
   10588:	f3dff0ef          	jal	ra,104c4 <spi_txrx>
   1058c:	0184551b          	srliw	a0,s0,0x18
   10590:	f35ff0ef          	jal	ra,104c4 <spi_txrx>
   10594:	0104551b          	srliw	a0,s0,0x10
   10598:	0ff57513          	andi	a0,a0,255
   1059c:	f29ff0ef          	jal	ra,104c4 <spi_txrx>
   105a0:	0084551b          	srliw	a0,s0,0x8
   105a4:	0ff57513          	andi	a0,a0,255
   105a8:	f1dff0ef          	jal	ra,104c4 <spi_txrx>
   105ac:	0ff47513          	andi	a0,s0,255
   105b0:	f15ff0ef          	jal	ra,104c4 <spi_txrx>
   105b4:	00813603          	ld	a2,8(sp)
   105b8:	06400413          	li	s0,100
   105bc:	00060513          	mv	a0,a2
   105c0:	f05ff0ef          	jal	ra,104c4 <spi_txrx>
   105c4:	f99ff0ef          	jal	ra,1055c <sd_dummy>
   105c8:	0185179b          	slliw	a5,a0,0x18
   105cc:	4187d79b          	sraiw	a5,a5,0x18
   105d0:	0007d663          	bgez	a5,105dc <sd_cmd+0x78>
   105d4:	fff40413          	addi	s0,s0,-1
   105d8:	fe0416e3          	bnez	s0,105c4 <sd_cmd+0x60>
   105dc:	02813083          	ld	ra,40(sp)
   105e0:	02013403          	ld	s0,32(sp)
   105e4:	01813483          	ld	s1,24(sp)
   105e8:	03010113          	addi	sp,sp,48
   105ec:	00008067          	ret

00000000000105f0 <print_status>:
   105f0:	fe010113          	addi	sp,sp,-32
   105f4:	00813823          	sd	s0,16(sp)
   105f8:	00050413          	mv	s0,a0
   105fc:	00001517          	auipc	a0,0x1
   10600:	fb450513          	addi	a0,a0,-76 # 115b0 <_BSS_END_+0x9b0>
   10604:	00113c23          	sd	ra,24(sp)
   10608:	00b13423          	sd	a1,8(sp)
   1060c:	c1dff0ef          	jal	ra,10228 <print_uart>
   10610:	00040513          	mv	a0,s0
   10614:	c15ff0ef          	jal	ra,10228 <print_uart>
   10618:	00001517          	auipc	a0,0x1
   1061c:	fa850513          	addi	a0,a0,-88 # 115c0 <_BSS_END_+0x9c0>
   10620:	c09ff0ef          	jal	ra,10228 <print_uart>
   10624:	00813583          	ld	a1,8(sp)
   10628:	00058513          	mv	a0,a1
   1062c:	d1dff0ef          	jal	ra,10348 <print_uart_byte>
   10630:	01013403          	ld	s0,16(sp)
   10634:	01813083          	ld	ra,24(sp)
   10638:	00001517          	auipc	a0,0x1
   1063c:	f7050513          	addi	a0,a0,-144 # 115a8 <_BSS_END_+0x9a8>
   10640:	02010113          	addi	sp,sp,32
   10644:	be5ff06f          	j	10228 <print_uart>

0000000000010648 <sd_cmd0>:
   10648:	fe010113          	addi	sp,sp,-32
   1064c:	00813823          	sd	s0,16(sp)
   10650:	00002437          	lui	s0,0x2
   10654:	00913423          	sd	s1,8(sp)
   10658:	00113c23          	sd	ra,24(sp)
   1065c:	01213023          	sd	s2,0(sp)
   10660:	71040413          	addi	s0,s0,1808 # 2710 <ROM_BASE-0xd8f0>
   10664:	00100493          	li	s1,1
   10668:	09500613          	li	a2,149
   1066c:	00000593          	li	a1,0
   10670:	00000513          	li	a0,0
   10674:	ef1ff0ef          	jal	ra,10564 <sd_cmd>
   10678:	fff4041b          	addiw	s0,s0,-1
   1067c:	00050913          	mv	s2,a0
   10680:	eddff0ef          	jal	ra,1055c <sd_dummy>
   10684:	02040a63          	beqz	s0,106b8 <sd_cmd0+0x70>
   10688:	fe9910e3          	bne	s2,s1,10668 <sd_cmd0+0x20>
   1068c:	00001517          	auipc	a0,0x1
   10690:	f4450513          	addi	a0,a0,-188 # 115d0 <_BSS_END_+0x9d0>
   10694:	00100593          	li	a1,1
   10698:	f59ff0ef          	jal	ra,105f0 <print_status>
   1069c:	00100513          	li	a0,1
   106a0:	01813083          	ld	ra,24(sp)
   106a4:	01013403          	ld	s0,16(sp)
   106a8:	00813483          	ld	s1,8(sp)
   106ac:	00013903          	ld	s2,0(sp)
   106b0:	02010113          	addi	sp,sp,32
   106b4:	00008067          	ret
   106b8:	00000513          	li	a0,0
   106bc:	fe5ff06f          	j	106a0 <sd_cmd0+0x58>

00000000000106c0 <sd_cmd8>:
   106c0:	fe010113          	addi	sp,sp,-32
   106c4:	08700613          	li	a2,135
   106c8:	1aa00593          	li	a1,426
   106cc:	00800513          	li	a0,8
   106d0:	00113c23          	sd	ra,24(sp)
   106d4:	00813823          	sd	s0,16(sp)
   106d8:	00913423          	sd	s1,8(sp)
   106dc:	01213023          	sd	s2,0(sp)
   106e0:	e85ff0ef          	jal	ra,10564 <sd_cmd>
   106e4:	00050913          	mv	s2,a0
   106e8:	e75ff0ef          	jal	ra,1055c <sd_dummy>
   106ec:	e71ff0ef          	jal	ra,1055c <sd_dummy>
   106f0:	e6dff0ef          	jal	ra,1055c <sd_dummy>
   106f4:	00050493          	mv	s1,a0
   106f8:	e65ff0ef          	jal	ra,1055c <sd_dummy>
   106fc:	00050413          	mv	s0,a0
   10700:	e5dff0ef          	jal	ra,1055c <sd_dummy>
   10704:	e59ff0ef          	jal	ra,1055c <sd_dummy>
   10708:	00100793          	li	a5,1
   1070c:	00000513          	li	a0,0
   10710:	00f91c63          	bne	s2,a5,10728 <sd_cmd8+0x68>
   10714:	00f4f493          	andi	s1,s1,15
   10718:	01249863          	bne	s1,s2,10728 <sd_cmd8+0x68>
   1071c:	0004051b          	sext.w	a0,s0
   10720:	f5650513          	addi	a0,a0,-170
   10724:	00153513          	seqz	a0,a0
   10728:	01813083          	ld	ra,24(sp)
   1072c:	01013403          	ld	s0,16(sp)
   10730:	00813483          	ld	s1,8(sp)
   10734:	00013903          	ld	s2,0(sp)
   10738:	02010113          	addi	sp,sp,32
   1073c:	00008067          	ret

0000000000010740 <sd_cmd55>:
   10740:	ff010113          	addi	sp,sp,-16
   10744:	06500613          	li	a2,101
   10748:	00000593          	li	a1,0
   1074c:	03700513          	li	a0,55
   10750:	00113423          	sd	ra,8(sp)
   10754:	00813023          	sd	s0,0(sp)
   10758:	e0dff0ef          	jal	ra,10564 <sd_cmd>
   1075c:	00050413          	mv	s0,a0
   10760:	dfdff0ef          	jal	ra,1055c <sd_dummy>
   10764:	00001517          	auipc	a0,0x1
   10768:	00040593          	mv	a1,s0
   1076c:	e7450513          	addi	a0,a0,-396 # 115d8 <_BSS_END_+0x9d8>
   10770:	e81ff0ef          	jal	ra,105f0 <print_status>
   10774:	0004051b          	sext.w	a0,s0
   10778:	00813083          	ld	ra,8(sp)
   1077c:	00013403          	ld	s0,0(sp)
   10780:	fff50513          	addi	a0,a0,-1
   10784:	00153513          	seqz	a0,a0
   10788:	01010113          	addi	sp,sp,16
   1078c:	00008067          	ret

0000000000010790 <sd_acmd41>:
   10790:	fe010113          	addi	sp,sp,-32
   10794:	00913423          	sd	s1,8(sp)
   10798:	00113c23          	sd	ra,24(sp)
   1079c:	00813823          	sd	s0,16(sp)
   107a0:	00100493          	li	s1,1
   107a4:	f9dff0ef          	jal	ra,10740 <sd_cmd55>
   107a8:	07700613          	li	a2,119
   107ac:	400005b7          	lui	a1,0x40000
   107b0:	02900513          	li	a0,41
   107b4:	db1ff0ef          	jal	ra,10564 <sd_cmd>
   107b8:	00050413          	mv	s0,a0
   107bc:	00050593          	mv	a1,a0
   107c0:	00001517          	auipc	a0,0x1
   107c4:	e2050513          	addi	a0,a0,-480 # 115e0 <_BSS_END_+0x9e0>
   107c8:	e29ff0ef          	jal	ra,105f0 <print_status>
   107cc:	d91ff0ef          	jal	ra,1055c <sd_dummy>
   107d0:	fc940ae3          	beq	s0,s1,107a4 <sd_acmd41+0x14>
   107d4:	0004051b          	sext.w	a0,s0
   107d8:	01813083          	ld	ra,24(sp)
   107dc:	01013403          	ld	s0,16(sp)
   107e0:	00813483          	ld	s1,8(sp)
   107e4:	00153513          	seqz	a0,a0
   107e8:	02010113          	addi	sp,sp,32
   107ec:	00008067          	ret

00000000000107f0 <init_sd>:
   107f0:	ff010113          	addi	sp,sp,-16
   107f4:	00113423          	sd	ra,8(sp)
   107f8:	00813023          	sd	s0,0(sp)
   107fc:	bddff0ef          	jal	ra,103d8 <spi_init>
   10800:	00001517          	auipc	a0,0x1
   10804:	de850513          	addi	a0,a0,-536 # 115e8 <_BSS_END_+0x9e8>
   10808:	a21ff0ef          	jal	ra,10228 <print_uart>
   1080c:	00a00413          	li	s0,10
   10810:	fff4041b          	addiw	s0,s0,-1
   10814:	d49ff0ef          	jal	ra,1055c <sd_dummy>
   10818:	fe041ce3          	bnez	s0,10810 <init_sd+0x20>
   1081c:	e2dff0ef          	jal	ra,10648 <sd_cmd0>
   10820:	fff00793          	li	a5,-1
   10824:	02050063          	beqz	a0,10844 <init_sd+0x54>
   10828:	e99ff0ef          	jal	ra,106c0 <sd_cmd8>
   1082c:	ffe00793          	li	a5,-2
   10830:	00050a63          	beqz	a0,10844 <init_sd+0x54>
   10834:	f5dff0ef          	jal	ra,10790 <sd_acmd41>
   10838:	00000793          	li	a5,0
   1083c:	00051463          	bnez	a0,10844 <init_sd+0x54>
   10840:	ffd00793          	li	a5,-3
   10844:	00813083          	ld	ra,8(sp)
   10848:	00013403          	ld	s0,0(sp)
   1084c:	00078513          	mv	a0,a5
   10850:	01010113          	addi	sp,sp,16
   10854:	00008067          	ret

0000000000010858 <crc7>:
   10858:	00b575b3          	and	a1,a0,a1
   1085c:	0075d79b          	srliw	a5,a1,0x7
   10860:	0045d51b          	srliw	a0,a1,0x4
   10864:	00f54533          	xor	a0,a0,a5
   10868:	00b54533          	xor	a0,a0,a1
   1086c:	00451593          	slli	a1,a0,0x4
   10870:	00b54533          	xor	a0,a0,a1
   10874:	07f57513          	andi	a0,a0,127
   10878:	00008067          	ret

000000000001087c <crc16>:
   1087c:	0085579b          	srliw	a5,a0,0x8
   10880:	00851513          	slli	a0,a0,0x8
   10884:	00f56533          	or	a0,a0,a5
   10888:	03051513          	slli	a0,a0,0x30
   1088c:	03055513          	srli	a0,a0,0x30
   10890:	00b545b3          	xor	a1,a0,a1
   10894:	0045d51b          	srliw	a0,a1,0x4
   10898:	00f57513          	andi	a0,a0,15
   1089c:	00b545b3          	xor	a1,a0,a1
   108a0:	00c59513          	slli	a0,a1,0xc
   108a4:	00a5c533          	xor	a0,a1,a0
   108a8:	0105151b          	slliw	a0,a0,0x10
   108ac:	4105551b          	sraiw	a0,a0,0x10
   108b0:	0105179b          	slliw	a5,a0,0x10
   108b4:	0107d79b          	srliw	a5,a5,0x10
   108b8:	00002737          	lui	a4,0x2
   108bc:	fe070713          	addi	a4,a4,-32 # 1fe0 <ROM_BASE-0xe020>
   108c0:	0057979b          	slliw	a5,a5,0x5
   108c4:	00e7f7b3          	and	a5,a5,a4
   108c8:	00f54533          	xor	a0,a0,a5
   108cc:	03051513          	slli	a0,a0,0x30
   108d0:	03055513          	srli	a0,a0,0x30
   108d4:	00008067          	ret

00000000000108d8 <sd_read_data>:
   108d8:	fd010113          	addi	sp,sp,-48
   108dc:	02813023          	sd	s0,32(sp)
   108e0:	01213823          	sd	s2,16(sp)
   108e4:	00058413          	mv	s0,a1
   108e8:	00050913          	mv	s2,a0
   108ec:	0185d59b          	srliw	a1,a1,0x18
   108f0:	00000513          	li	a0,0
   108f4:	02113423          	sd	ra,40(sp)
   108f8:	00913c23          	sd	s1,24(sp)
   108fc:	01313423          	sd	s3,8(sp)
   10900:	02061493          	slli	s1,a2,0x20
   10904:	f55ff0ef          	jal	ra,10858 <crc7>
   10908:	0104559b          	srliw	a1,s0,0x10
   1090c:	0ff5f593          	andi	a1,a1,255
   10910:	f49ff0ef          	jal	ra,10858 <crc7>
   10914:	0084559b          	srliw	a1,s0,0x8
   10918:	0ff5f593          	andi	a1,a1,255
   1091c:	f3dff0ef          	jal	ra,10858 <crc7>
   10920:	0ff47593          	andi	a1,s0,255
   10924:	f35ff0ef          	jal	ra,10858 <crc7>
   10928:	0015161b          	slliw	a2,a0,0x1
   1092c:	00166613          	ori	a2,a2,1
   10930:	0ff67613          	andi	a2,a2,255
   10934:	00040593          	mv	a1,s0
   10938:	01200513          	li	a0,18
   1093c:	c29ff0ef          	jal	ra,10564 <sd_cmd>
   10940:	06051463          	bnez	a0,109a8 <sd_read_data+0xd0>
   10944:	0204d493          	srli	s1,s1,0x20
   10948:	0fe00413          	li	s0,254
   1094c:	3e800993          	li	s3,1000
   10950:	c0dff0ef          	jal	ra,1055c <sd_dummy>
   10954:	fe851ee3          	bne	a0,s0,10950 <sd_read_data+0x78>
   10958:	00090513          	mv	a0,s2
   1095c:	badff0ef          	jal	ra,10508 <spi_read_block>
   10960:	bfdff0ef          	jal	ra,1055c <sd_dummy>
   10964:	bf9ff0ef          	jal	ra,1055c <sd_dummy>
   10968:	0334e7b3          	rem	a5,s1,s3
   1096c:	20090913          	addi	s2,s2,512 # 2000200 <_RODATA_END_+0x1feebd8>
   10970:	00079863          	bnez	a5,10980 <sd_read_data+0xa8>
   10974:	00001517          	auipc	a0,0x1
   10978:	cac50513          	addi	a0,a0,-852 # 11620 <_BSS_END_+0xa20>
   1097c:	8adff0ef          	jal	ra,10228 <print_uart>
   10980:	fff48493          	addi	s1,s1,-1
   10984:	fc9046e3          	bgtz	s1,10950 <sd_read_data+0x78>
   10988:	00100613          	li	a2,1
   1098c:	00000593          	li	a1,0
   10990:	00c00513          	li	a0,12
   10994:	bd1ff0ef          	jal	ra,10564 <sd_cmd>
   10998:	bc5ff0ef          	jal	ra,1055c <sd_dummy>
   1099c:	0000100f          	fence.i
   109a0:	00000513          	li	a0,0
   109a4:	0340006f          	j	109d8 <sd_read_data+0x100>
   109a8:	bb5ff0ef          	jal	ra,1055c <sd_dummy>
   109ac:	bb1ff0ef          	jal	ra,1055c <sd_dummy>
   109b0:	badff0ef          	jal	ra,1055c <sd_dummy>
   109b4:	ba9ff0ef          	jal	ra,1055c <sd_dummy>
   109b8:	ba5ff0ef          	jal	ra,1055c <sd_dummy>
   109bc:	ba1ff0ef          	jal	ra,1055c <sd_dummy>
   109c0:	b9dff0ef          	jal	ra,1055c <sd_dummy>
   109c4:	b99ff0ef          	jal	ra,1055c <sd_dummy>
   109c8:	00001517          	auipc	a0,0x1
   109cc:	c3850513          	addi	a0,a0,-968 # 11600 <_BSS_END_+0xa00>
   109d0:	859ff0ef          	jal	ra,10228 <print_uart>
   109d4:	fff00513          	li	a0,-1
   109d8:	02813083          	ld	ra,40(sp)
   109dc:	02013403          	ld	s0,32(sp)
   109e0:	01813483          	ld	s1,24(sp)
   109e4:	01013903          	ld	s2,16(sp)
   109e8:	00813983          	ld	s3,8(sp)
   109ec:	03010113          	addi	sp,sp,48
   109f0:	00008067          	ret

Disassembly of section .text.startup:

00000000000109f4 <main>:
   109f4:	0001c5b7          	lui	a1,0x1c
   109f8:	02faf537          	lui	a0,0x2faf
   109fc:	ff010113          	addi	sp,sp,-16
   10a00:	20058593          	addi	a1,a1,512 # 1c200 <_RODATA_END_+0xabd8>
   10a04:	08050513          	addi	a0,a0,128 # 2faf080 <_RODATA_END_+0x2f9da58>
   10a08:	00113423          	sd	ra,8(sp)
   10a0c:	fd4ff0ef          	jal	ra,101e0 <init_uart>
   10a10:	00001517          	auipc	a0,0x1
   10a14:	b5050513          	addi	a0,a0,-1200 # 11560 <_BSS_END_+0x960>
   10a18:	811ff0ef          	jal	ra,10228 <print_uart>
   10a1c:	ee4ff0ef          	jal	ra,10100 <copy>
   10a20:	00813083          	ld	ra,8(sp)
   10a24:	00000513          	li	a0,0
   10a28:	01010113          	addi	sp,sp,16
   10a2c:	00008067          	ret

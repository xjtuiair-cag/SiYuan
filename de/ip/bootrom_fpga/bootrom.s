
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
   1001c:	1e9000ef          	jal	ra,10a04 <_TEXT_END_>
   10020:	020004b7          	lui	s1,0x2000
   10024:	00100913          	li	s2,1
   10028:	0124a023          	sw	s2,0(s1) # 2000000 <_RODATA_END_+0x1fee7d0>
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
   1005c:	00092023          	sw	zero,0(s2) # 2000000 <_RODATA_END_+0x1fee7d0>
   10060:	0004a903          	lw	s2,0(s1) # 2000000 <_RODATA_END_+0x1fee7d0>
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
   1010c:	738000ef          	jal	ra,10844 <init_sd>
   10110:	02050463          	beqz	a0,10138 <copy+0x38>
   10114:	00001517          	auipc	a0,0x1
   10118:	5b450513          	addi	a0,a0,1460 # 116c8 <_BSS_END_+0xac8>
   1011c:	108000ef          	jal	ra,10224 <print_uart>
   10120:	fff00413          	li	s0,-1
   10124:	00040513          	mv	a0,s0
   10128:	00813083          	ld	ra,8(sp)
   1012c:	00013403          	ld	s0,0(sp)
   10130:	01010113          	addi	sp,sp,16
   10134:	00008067          	ret
   10138:	00001517          	auipc	a0,0x1
   1013c:	5b850513          	addi	a0,a0,1464 # 116f0 <_BSS_END_+0xaf0>
   10140:	0e4000ef          	jal	ra,10224 <print_uart>
   10144:	00001537          	lui	a0,0x1
   10148:	01000637          	lui	a2,0x1000
   1014c:	800005b7          	lui	a1,0x80000
   10150:	80050513          	addi	a0,a0,-2048 # 800 <ROM_BASE-0xf800>
   10154:	7d8000ef          	jal	ra,1092c <sd_copy>
   10158:	00050413          	mv	s0,a0
   1015c:	02050c63          	beqz	a0,10194 <copy+0x94>
   10160:	00001517          	auipc	a0,0x1
   10164:	5a850513          	addi	a0,a0,1448 # 11708 <_BSS_END_+0xb08>
   10168:	0bc000ef          	jal	ra,10224 <print_uart>
   1016c:	00001517          	auipc	a0,0x1
   10170:	5b450513          	addi	a0,a0,1460 # 11720 <_BSS_END_+0xb20>
   10174:	0b0000ef          	jal	ra,10224 <print_uart>
   10178:	00040513          	mv	a0,s0
   1017c:	168000ef          	jal	ra,102e4 <print_uart_addr>
   10180:	00001517          	auipc	a0,0x1
   10184:	61850513          	addi	a0,a0,1560 # 11798 <_BSS_END_+0xb98>
   10188:	09c000ef          	jal	ra,10224 <print_uart>
   1018c:	ffe00413          	li	s0,-2
   10190:	f95ff06f          	j	10124 <copy+0x24>
   10194:	00001517          	auipc	a0,0x1
   10198:	5a450513          	addi	a0,a0,1444 # 11738 <_BSS_END_+0xb38>
   1019c:	088000ef          	jal	ra,10224 <print_uart>
   101a0:	f85ff06f          	j	10124 <copy+0x24>

00000000000101a4 <write_reg_u8>:
   101a4:	00b50023          	sb	a1,0(a0)
   101a8:	00008067          	ret

00000000000101ac <read_reg_u8>:
   101ac:	00054503          	lbu	a0,0(a0)
   101b0:	00008067          	ret

00000000000101b4 <is_transmit_empty>:
   101b4:	100007b7          	lui	a5,0x10000
   101b8:	0147c503          	lbu	a0,20(a5) # 10000014 <_RODATA_END_+0xffee7e4>
   101bc:	02057513          	andi	a0,a0,32
   101c0:	00008067          	ret

00000000000101c4 <write_serial>:
   101c4:	10000737          	lui	a4,0x10000
   101c8:	01474783          	lbu	a5,20(a4) # 10000014 <_RODATA_END_+0xffee7e4>
   101cc:	0207f793          	andi	a5,a5,32
   101d0:	fe078ce3          	beqz	a5,101c8 <write_serial+0x4>
   101d4:	00a70023          	sb	a0,0(a4)
   101d8:	00008067          	ret

00000000000101dc <init_uart>:
   101dc:	0045959b          	slliw	a1,a1,0x4
   101e0:	02b5553b          	divuw	a0,a0,a1
   101e4:	100007b7          	lui	a5,0x10000
   101e8:	00078223          	sb	zero,4(a5) # 10000004 <_RODATA_END_+0xffee7d4>
   101ec:	f8000713          	li	a4,-128
   101f0:	00e78623          	sb	a4,12(a5)
   101f4:	0ff57713          	andi	a4,a0,255
   101f8:	0085551b          	srliw	a0,a0,0x8
   101fc:	00e78023          	sb	a4,0(a5)
   10200:	0ff57513          	andi	a0,a0,255
   10204:	00a78223          	sb	a0,4(a5)
   10208:	00300713          	li	a4,3
   1020c:	00e78623          	sb	a4,12(a5)
   10210:	fc700713          	li	a4,-57
   10214:	00e78423          	sb	a4,8(a5)
   10218:	02000713          	li	a4,32
   1021c:	00e78823          	sb	a4,16(a5)
   10220:	00008067          	ret

0000000000010224 <print_uart>:
   10224:	ff010113          	addi	sp,sp,-16
   10228:	00813023          	sd	s0,0(sp)
   1022c:	00113423          	sd	ra,8(sp)
   10230:	00050413          	mv	s0,a0
   10234:	00044503          	lbu	a0,0(s0)
   10238:	00051a63          	bnez	a0,1024c <print_uart+0x28>
   1023c:	00813083          	ld	ra,8(sp)
   10240:	00013403          	ld	s0,0(sp)
   10244:	01010113          	addi	sp,sp,16
   10248:	00008067          	ret
   1024c:	f79ff0ef          	jal	ra,101c4 <write_serial>
   10250:	00140413          	addi	s0,s0,1
   10254:	fe1ff06f          	j	10234 <print_uart+0x10>

0000000000010258 <bin_to_hex>:
   10258:	00001797          	auipc	a5,0x1
   1025c:	8a878793          	addi	a5,a5,-1880 # 10b00 <bin_to_hex_table>
   10260:	00f57713          	andi	a4,a0,15
   10264:	00e78733          	add	a4,a5,a4
   10268:	00074703          	lbu	a4,0(a4)
   1026c:	00455513          	srli	a0,a0,0x4
   10270:	00a787b3          	add	a5,a5,a0
   10274:	00e580a3          	sb	a4,1(a1) # ffffffff80000001 <_RODATA_END_+0xffffffff7ffee7d1>
   10278:	0007c783          	lbu	a5,0(a5)
   1027c:	00f58023          	sb	a5,0(a1)
   10280:	00008067          	ret

0000000000010284 <print_uart_int>:
   10284:	fd010113          	addi	sp,sp,-48
   10288:	02813023          	sd	s0,32(sp)
   1028c:	00913c23          	sd	s1,24(sp)
   10290:	01213823          	sd	s2,16(sp)
   10294:	02113423          	sd	ra,40(sp)
   10298:	00050913          	mv	s2,a0
   1029c:	01800413          	li	s0,24
   102a0:	ff800493          	li	s1,-8
   102a4:	0089553b          	srlw	a0,s2,s0
   102a8:	00810593          	addi	a1,sp,8
   102ac:	0ff57513          	andi	a0,a0,255
   102b0:	fa9ff0ef          	jal	ra,10258 <bin_to_hex>
   102b4:	00814503          	lbu	a0,8(sp)
   102b8:	ff84041b          	addiw	s0,s0,-8
   102bc:	f09ff0ef          	jal	ra,101c4 <write_serial>
   102c0:	00914503          	lbu	a0,9(sp)
   102c4:	f01ff0ef          	jal	ra,101c4 <write_serial>
   102c8:	fc941ee3          	bne	s0,s1,102a4 <print_uart_int+0x20>
   102cc:	02813083          	ld	ra,40(sp)
   102d0:	02013403          	ld	s0,32(sp)
   102d4:	01813483          	ld	s1,24(sp)
   102d8:	01013903          	ld	s2,16(sp)
   102dc:	03010113          	addi	sp,sp,48
   102e0:	00008067          	ret

00000000000102e4 <print_uart_addr>:
   102e4:	fd010113          	addi	sp,sp,-48
   102e8:	02813023          	sd	s0,32(sp)
   102ec:	00913c23          	sd	s1,24(sp)
   102f0:	01213823          	sd	s2,16(sp)
   102f4:	02113423          	sd	ra,40(sp)
   102f8:	00050913          	mv	s2,a0
   102fc:	03800413          	li	s0,56
   10300:	ff800493          	li	s1,-8
   10304:	00895533          	srl	a0,s2,s0
   10308:	00810593          	addi	a1,sp,8
   1030c:	0ff57513          	andi	a0,a0,255
   10310:	f49ff0ef          	jal	ra,10258 <bin_to_hex>
   10314:	00814503          	lbu	a0,8(sp)
   10318:	ff84041b          	addiw	s0,s0,-8
   1031c:	ea9ff0ef          	jal	ra,101c4 <write_serial>
   10320:	00914503          	lbu	a0,9(sp)
   10324:	ea1ff0ef          	jal	ra,101c4 <write_serial>
   10328:	fc941ee3          	bne	s0,s1,10304 <print_uart_addr+0x20>
   1032c:	02813083          	ld	ra,40(sp)
   10330:	02013403          	ld	s0,32(sp)
   10334:	01813483          	ld	s1,24(sp)
   10338:	01013903          	ld	s2,16(sp)
   1033c:	03010113          	addi	sp,sp,48
   10340:	00008067          	ret

0000000000010344 <print_uart_byte>:
   10344:	fe010113          	addi	sp,sp,-32
   10348:	00810593          	addi	a1,sp,8
   1034c:	00113c23          	sd	ra,24(sp)
   10350:	f09ff0ef          	jal	ra,10258 <bin_to_hex>
   10354:	00814503          	lbu	a0,8(sp)
   10358:	e6dff0ef          	jal	ra,101c4 <write_serial>
   1035c:	00914503          	lbu	a0,9(sp)
   10360:	e65ff0ef          	jal	ra,101c4 <write_serial>
   10364:	01813083          	ld	ra,24(sp)
   10368:	02010113          	addi	sp,sp,32
   1036c:	00008067          	ret

0000000000010370 <write_reg_u32>:
   10370:	00b52023          	sw	a1,0(a0)
   10374:	00008067          	ret

0000000000010378 <Dma_trans>:
   10378:	000307b7          	lui	a5,0x30
   1037c:	00a7a023          	sw	a0,0(a5) # 30000 <_RODATA_END_+0x1e7d0>
   10380:	00b7a423          	sw	a1,8(a5)
   10384:	00d7a823          	sw	a3,16(a5)
   10388:	00c7ac23          	sw	a2,24(a5)
   1038c:	02e7a023          	sw	a4,32(a5)
   10390:	00008067          	ret

0000000000010394 <Dma_start>:
   10394:	000307b7          	lui	a5,0x30
   10398:	00100713          	li	a4,1
   1039c:	00e7ae23          	sw	a4,28(a5) # 3001c <_RODATA_END_+0x1e7ec>
   103a0:	00008067          	ret

00000000000103a4 <is_Dma_done>:
   103a4:	000307b7          	lui	a5,0x30
   103a8:	01c7a503          	lw	a0,28(a5) # 3001c <_RODATA_END_+0x1e7ec>
   103ac:	00257513          	andi	a0,a0,2
   103b0:	00008067          	ret

00000000000103b4 <flush_done>:
   103b4:	000307b7          	lui	a5,0x30
   103b8:	0007ae23          	sw	zero,28(a5) # 3001c <_RODATA_END_+0x1e7ec>
   103bc:	00008067          	ret

00000000000103c0 <write_reg>:
   103c0:	00b52023          	sw	a1,0(a0)
   103c4:	00008067          	ret

00000000000103c8 <read_reg>:
   103c8:	00052503          	lw	a0,0(a0)
   103cc:	0005051b          	sext.w	a0,a0
   103d0:	00008067          	ret

00000000000103d4 <spi_init>:
   103d4:	00001517          	auipc	a0,0x1
   103d8:	fe010113          	addi	sp,sp,-32
   103dc:	39450513          	addi	a0,a0,916 # 11768 <_BSS_END_+0xb68>
   103e0:	00113c23          	sd	ra,24(sp)
   103e4:	00813823          	sd	s0,16(sp)
   103e8:	00913423          	sd	s1,8(sp)
   103ec:	e39ff0ef          	jal	ra,10224 <print_uart>
   103f0:	200007b7          	lui	a5,0x20000
   103f4:	00a00713          	li	a4,10
   103f8:	04e7a023          	sw	a4,64(a5) # 20000040 <_RODATA_END_+0x1ffee810>
   103fc:	00a00793          	li	a5,10
   10400:	00000013          	nop
   10404:	fff7879b          	addiw	a5,a5,-1
   10408:	fe079ce3          	bnez	a5,10400 <spi_init+0x2c>
   1040c:	20000437          	lui	s0,0x20000
   10410:	10400793          	li	a5,260
   10414:	06f42023          	sw	a5,96(s0) # 20000060 <_RODATA_END_+0x1ffee830>
   10418:	06442483          	lw	s1,100(s0)
   1041c:	00001517          	auipc	a0,0x1
   10420:	35c50513          	addi	a0,a0,860 # 11778 <_BSS_END_+0xb78>
   10424:	e01ff0ef          	jal	ra,10224 <print_uart>
   10428:	0004849b          	sext.w	s1,s1
   1042c:	02049513          	slli	a0,s1,0x20
   10430:	02055513          	srli	a0,a0,0x20
   10434:	eb1ff0ef          	jal	ra,102e4 <print_uart_addr>
   10438:	00001517          	auipc	a0,0x1
   1043c:	36050513          	addi	a0,a0,864 # 11798 <_BSS_END_+0xb98>
   10440:	de5ff0ef          	jal	ra,10224 <print_uart>
   10444:	16600793          	li	a5,358
   10448:	06f42023          	sw	a5,96(s0)
   1044c:	06442483          	lw	s1,100(s0)
   10450:	00001517          	auipc	a0,0x1
   10454:	32850513          	addi	a0,a0,808 # 11778 <_BSS_END_+0xb78>
   10458:	dcdff0ef          	jal	ra,10224 <print_uart>
   1045c:	0004849b          	sext.w	s1,s1
   10460:	02049513          	slli	a0,s1,0x20
   10464:	02055513          	srli	a0,a0,0x20
   10468:	e7dff0ef          	jal	ra,102e4 <print_uart_addr>
   1046c:	00001517          	auipc	a0,0x1
   10470:	32c50513          	addi	a0,a0,812 # 11798 <_BSS_END_+0xb98>
   10474:	db1ff0ef          	jal	ra,10224 <print_uart>
   10478:	00600793          	li	a5,6
   1047c:	06f42023          	sw	a5,96(s0)
   10480:	01013403          	ld	s0,16(sp)
   10484:	01813083          	ld	ra,24(sp)
   10488:	00813483          	ld	s1,8(sp)
   1048c:	00001517          	auipc	a0,0x1
   10490:	2fc50513          	addi	a0,a0,764 # 11788 <_BSS_END_+0xb88>
   10494:	02010113          	addi	sp,sp,32
   10498:	d8dff06f          	j	10224 <print_uart>

000000000001049c <spi_txrx>:
   1049c:	200007b7          	lui	a5,0x20000
   104a0:	ffe00713          	li	a4,-2
   104a4:	06e7a823          	sw	a4,112(a5) # 20000070 <_RODATA_END_+0x1ffee840>
   104a8:	06a7a423          	sw	a0,104(a5)
   104ac:	06400793          	li	a5,100
   104b0:	00000013          	nop
   104b4:	fff7879b          	addiw	a5,a5,-1
   104b8:	fe079ce3          	bnez	a5,104b0 <spi_txrx+0x14>
   104bc:	200007b7          	lui	a5,0x20000
   104c0:	10600713          	li	a4,262
   104c4:	06e7a023          	sw	a4,96(a5) # 20000060 <_RODATA_END_+0x1ffee830>
   104c8:	0647a703          	lw	a4,100(a5)
   104cc:	00177713          	andi	a4,a4,1
   104d0:	fe071ce3          	bnez	a4,104c8 <spi_txrx+0x2c>
   104d4:	06c7a503          	lw	a0,108(a5)
   104d8:	fff00713          	li	a4,-1
   104dc:	06e7a823          	sw	a4,112(a5)
   104e0:	00600713          	li	a4,6
   104e4:	06e7a023          	sw	a4,96(a5)
   104e8:	0ff57513          	andi	a0,a0,255
   104ec:	00008067          	ret

00000000000104f0 <spi_trans_with_dma>:
   104f0:	fe010113          	addi	sp,sp,-32
   104f4:	00113c23          	sd	ra,24(sp)
   104f8:	00813823          	sd	s0,16(sp)
   104fc:	00913423          	sd	s1,8(sp)
   10500:	200007b7          	lui	a5,0x20000
   10504:	ffe00713          	li	a4,-2
   10508:	00058693          	mv	a3,a1
   1050c:	06e7a823          	sw	a4,112(a5) # 20000070 <_RODATA_END_+0x1ffee840>
   10510:	0000100f          	fence.i
   10514:	00100713          	li	a4,1
   10518:	00050593          	mv	a1,a0
   1051c:	01000613          	li	a2,16
   10520:	06c78513          	addi	a0,a5,108
   10524:	e55ff0ef          	jal	ra,10378 <Dma_trans>
   10528:	e6dff0ef          	jal	ra,10394 <Dma_start>
   1052c:	00001517          	auipc	a0,0x1
   10530:	27450513          	addi	a0,a0,628 # 117a0 <_BSS_END_+0xba0>
   10534:	00008437          	lui	s0,0x8
   10538:	cedff0ef          	jal	ra,10224 <print_uart>
   1053c:	00000493          	li	s1,0
   10540:	fff40413          	addi	s0,s0,-1 # 7fff <ROM_BASE-0x8001>
   10544:	e61ff0ef          	jal	ra,103a4 <is_Dma_done>
   10548:	0005051b          	sext.w	a0,a0
   1054c:	02051463          	bnez	a0,10574 <spi_trans_with_dma+0x84>
   10550:	0014879b          	addiw	a5,s1,1
   10554:	0007849b          	sext.w	s1,a5
   10558:	00f477b3          	and	a5,s0,a5
   1055c:	0007879b          	sext.w	a5,a5
   10560:	fe0792e3          	bnez	a5,10544 <spi_trans_with_dma+0x54>
   10564:	00001517          	auipc	a0,0x1
   10568:	24c50513          	addi	a0,a0,588 # 117b0 <_BSS_END_+0xbb0>
   1056c:	cb9ff0ef          	jal	ra,10224 <print_uart>
   10570:	fd5ff06f          	j	10544 <spi_trans_with_dma+0x54>
   10574:	00001517          	auipc	a0,0x1
   10578:	24450513          	addi	a0,a0,580 # 117b8 <_BSS_END_+0xbb8>
   1057c:	ca9ff0ef          	jal	ra,10224 <print_uart>
   10580:	e35ff0ef          	jal	ra,103b4 <flush_done>
   10584:	200007b7          	lui	a5,0x20000
   10588:	fff00713          	li	a4,-1
   1058c:	01813083          	ld	ra,24(sp)
   10590:	01013403          	ld	s0,16(sp)
   10594:	06e7a823          	sw	a4,112(a5) # 20000070 <_RODATA_END_+0x1ffee840>
   10598:	00600713          	li	a4,6
   1059c:	06e7a023          	sw	a4,96(a5)
   105a0:	00813483          	ld	s1,8(sp)
   105a4:	00000513          	li	a0,0
   105a8:	02010113          	addi	sp,sp,32
   105ac:	00008067          	ret

00000000000105b0 <sd_dummy>:
   105b0:	0ff00513          	li	a0,255
   105b4:	ee9ff06f          	j	1049c <spi_txrx>

00000000000105b8 <sd_cmd>:
   105b8:	fd010113          	addi	sp,sp,-48
   105bc:	02113423          	sd	ra,40(sp)
   105c0:	00c13423          	sd	a2,8(sp)
   105c4:	02813023          	sd	s0,32(sp)
   105c8:	00913c23          	sd	s1,24(sp)
   105cc:	00058413          	mv	s0,a1
   105d0:	00050493          	mv	s1,a0
   105d4:	fddff0ef          	jal	ra,105b0 <sd_dummy>
   105d8:	0404e513          	ori	a0,s1,64
   105dc:	ec1ff0ef          	jal	ra,1049c <spi_txrx>
   105e0:	0184551b          	srliw	a0,s0,0x18
   105e4:	eb9ff0ef          	jal	ra,1049c <spi_txrx>
   105e8:	0104551b          	srliw	a0,s0,0x10
   105ec:	0ff57513          	andi	a0,a0,255
   105f0:	eadff0ef          	jal	ra,1049c <spi_txrx>
   105f4:	0084551b          	srliw	a0,s0,0x8
   105f8:	0ff57513          	andi	a0,a0,255
   105fc:	ea1ff0ef          	jal	ra,1049c <spi_txrx>
   10600:	0ff47513          	andi	a0,s0,255
   10604:	e99ff0ef          	jal	ra,1049c <spi_txrx>
   10608:	00813603          	ld	a2,8(sp)
   1060c:	06400413          	li	s0,100
   10610:	00060513          	mv	a0,a2
   10614:	e89ff0ef          	jal	ra,1049c <spi_txrx>
   10618:	f99ff0ef          	jal	ra,105b0 <sd_dummy>
   1061c:	0185179b          	slliw	a5,a0,0x18
   10620:	4187d79b          	sraiw	a5,a5,0x18
   10624:	0007d663          	bgez	a5,10630 <sd_cmd+0x78>
   10628:	fff40413          	addi	s0,s0,-1
   1062c:	fe0416e3          	bnez	s0,10618 <sd_cmd+0x60>
   10630:	02813083          	ld	ra,40(sp)
   10634:	02013403          	ld	s0,32(sp)
   10638:	01813483          	ld	s1,24(sp)
   1063c:	03010113          	addi	sp,sp,48
   10640:	00008067          	ret

0000000000010644 <print_status>:
   10644:	fe010113          	addi	sp,sp,-32
   10648:	00813823          	sd	s0,16(sp)
   1064c:	00050413          	mv	s0,a0
   10650:	00001517          	auipc	a0,0x1
   10654:	17050513          	addi	a0,a0,368 # 117c0 <_BSS_END_+0xbc0>
   10658:	00113c23          	sd	ra,24(sp)
   1065c:	00b13423          	sd	a1,8(sp)
   10660:	bc5ff0ef          	jal	ra,10224 <print_uart>
   10664:	00040513          	mv	a0,s0
   10668:	bbdff0ef          	jal	ra,10224 <print_uart>
   1066c:	00001517          	auipc	a0,0x1
   10670:	16450513          	addi	a0,a0,356 # 117d0 <_BSS_END_+0xbd0>
   10674:	bb1ff0ef          	jal	ra,10224 <print_uart>
   10678:	00813583          	ld	a1,8(sp)
   1067c:	00058513          	mv	a0,a1
   10680:	cc5ff0ef          	jal	ra,10344 <print_uart_byte>
   10684:	01013403          	ld	s0,16(sp)
   10688:	01813083          	ld	ra,24(sp)
   1068c:	00001517          	auipc	a0,0x1
   10690:	10c50513          	addi	a0,a0,268 # 11798 <_BSS_END_+0xb98>
   10694:	02010113          	addi	sp,sp,32
   10698:	b8dff06f          	j	10224 <print_uart>

000000000001069c <sd_cmd0>:
   1069c:	fe010113          	addi	sp,sp,-32
   106a0:	00813823          	sd	s0,16(sp)
   106a4:	00002437          	lui	s0,0x2
   106a8:	00913423          	sd	s1,8(sp)
   106ac:	00113c23          	sd	ra,24(sp)
   106b0:	01213023          	sd	s2,0(sp)
   106b4:	71040413          	addi	s0,s0,1808 # 2710 <ROM_BASE-0xd8f0>
   106b8:	00100493          	li	s1,1
   106bc:	09500613          	li	a2,149
   106c0:	00000593          	li	a1,0
   106c4:	00000513          	li	a0,0
   106c8:	ef1ff0ef          	jal	ra,105b8 <sd_cmd>
   106cc:	fff4041b          	addiw	s0,s0,-1
   106d0:	00050913          	mv	s2,a0
   106d4:	eddff0ef          	jal	ra,105b0 <sd_dummy>
   106d8:	02040a63          	beqz	s0,1070c <sd_cmd0+0x70>
   106dc:	fe9910e3          	bne	s2,s1,106bc <sd_cmd0+0x20>
   106e0:	00001517          	auipc	a0,0x1
   106e4:	10050513          	addi	a0,a0,256 # 117e0 <_BSS_END_+0xbe0>
   106e8:	00100593          	li	a1,1
   106ec:	f59ff0ef          	jal	ra,10644 <print_status>
   106f0:	00100513          	li	a0,1
   106f4:	01813083          	ld	ra,24(sp)
   106f8:	01013403          	ld	s0,16(sp)
   106fc:	00813483          	ld	s1,8(sp)
   10700:	00013903          	ld	s2,0(sp)
   10704:	02010113          	addi	sp,sp,32
   10708:	00008067          	ret
   1070c:	00000513          	li	a0,0
   10710:	fe5ff06f          	j	106f4 <sd_cmd0+0x58>

0000000000010714 <sd_cmd8>:
   10714:	fe010113          	addi	sp,sp,-32
   10718:	08700613          	li	a2,135
   1071c:	1aa00593          	li	a1,426
   10720:	00800513          	li	a0,8
   10724:	00113c23          	sd	ra,24(sp)
   10728:	00813823          	sd	s0,16(sp)
   1072c:	00913423          	sd	s1,8(sp)
   10730:	01213023          	sd	s2,0(sp)
   10734:	e85ff0ef          	jal	ra,105b8 <sd_cmd>
   10738:	00050913          	mv	s2,a0
   1073c:	e75ff0ef          	jal	ra,105b0 <sd_dummy>
   10740:	e71ff0ef          	jal	ra,105b0 <sd_dummy>
   10744:	e6dff0ef          	jal	ra,105b0 <sd_dummy>
   10748:	00050493          	mv	s1,a0
   1074c:	e65ff0ef          	jal	ra,105b0 <sd_dummy>
   10750:	00050413          	mv	s0,a0
   10754:	e5dff0ef          	jal	ra,105b0 <sd_dummy>
   10758:	e59ff0ef          	jal	ra,105b0 <sd_dummy>
   1075c:	00100793          	li	a5,1
   10760:	00000513          	li	a0,0
   10764:	00f91c63          	bne	s2,a5,1077c <sd_cmd8+0x68>
   10768:	00f4f493          	andi	s1,s1,15
   1076c:	01249863          	bne	s1,s2,1077c <sd_cmd8+0x68>
   10770:	0004051b          	sext.w	a0,s0
   10774:	f5650513          	addi	a0,a0,-170
   10778:	00153513          	seqz	a0,a0
   1077c:	01813083          	ld	ra,24(sp)
   10780:	01013403          	ld	s0,16(sp)
   10784:	00813483          	ld	s1,8(sp)
   10788:	00013903          	ld	s2,0(sp)
   1078c:	02010113          	addi	sp,sp,32
   10790:	00008067          	ret

0000000000010794 <sd_cmd55>:
   10794:	ff010113          	addi	sp,sp,-16
   10798:	06500613          	li	a2,101
   1079c:	00000593          	li	a1,0
   107a0:	03700513          	li	a0,55
   107a4:	00113423          	sd	ra,8(sp)
   107a8:	00813023          	sd	s0,0(sp)
   107ac:	e0dff0ef          	jal	ra,105b8 <sd_cmd>
   107b0:	00050413          	mv	s0,a0
   107b4:	dfdff0ef          	jal	ra,105b0 <sd_dummy>
   107b8:	00001517          	auipc	a0,0x1
   107bc:	00040593          	mv	a1,s0
   107c0:	03050513          	addi	a0,a0,48 # 117e8 <_BSS_END_+0xbe8>
   107c4:	e81ff0ef          	jal	ra,10644 <print_status>
   107c8:	0004051b          	sext.w	a0,s0
   107cc:	00813083          	ld	ra,8(sp)
   107d0:	00013403          	ld	s0,0(sp)
   107d4:	fff50513          	addi	a0,a0,-1
   107d8:	00153513          	seqz	a0,a0
   107dc:	01010113          	addi	sp,sp,16
   107e0:	00008067          	ret

00000000000107e4 <sd_acmd41>:
   107e4:	fe010113          	addi	sp,sp,-32
   107e8:	00913423          	sd	s1,8(sp)
   107ec:	00113c23          	sd	ra,24(sp)
   107f0:	00813823          	sd	s0,16(sp)
   107f4:	00100493          	li	s1,1
   107f8:	f9dff0ef          	jal	ra,10794 <sd_cmd55>
   107fc:	07700613          	li	a2,119
   10800:	400005b7          	lui	a1,0x40000
   10804:	02900513          	li	a0,41
   10808:	db1ff0ef          	jal	ra,105b8 <sd_cmd>
   1080c:	00050413          	mv	s0,a0
   10810:	00050593          	mv	a1,a0
   10814:	00001517          	auipc	a0,0x1
   10818:	fdc50513          	addi	a0,a0,-36 # 117f0 <_BSS_END_+0xbf0>
   1081c:	e29ff0ef          	jal	ra,10644 <print_status>
   10820:	d91ff0ef          	jal	ra,105b0 <sd_dummy>
   10824:	fc940ae3          	beq	s0,s1,107f8 <sd_acmd41+0x14>
   10828:	0004051b          	sext.w	a0,s0
   1082c:	01813083          	ld	ra,24(sp)
   10830:	01013403          	ld	s0,16(sp)
   10834:	00813483          	ld	s1,8(sp)
   10838:	00153513          	seqz	a0,a0
   1083c:	02010113          	addi	sp,sp,32
   10840:	00008067          	ret

0000000000010844 <init_sd>:
   10844:	ff010113          	addi	sp,sp,-16
   10848:	00113423          	sd	ra,8(sp)
   1084c:	00813023          	sd	s0,0(sp)
   10850:	b85ff0ef          	jal	ra,103d4 <spi_init>
   10854:	00001517          	auipc	a0,0x1
   10858:	fa450513          	addi	a0,a0,-92 # 117f8 <_BSS_END_+0xbf8>
   1085c:	9c9ff0ef          	jal	ra,10224 <print_uart>
   10860:	00a00413          	li	s0,10
   10864:	fff4041b          	addiw	s0,s0,-1
   10868:	d49ff0ef          	jal	ra,105b0 <sd_dummy>
   1086c:	fe041ce3          	bnez	s0,10864 <init_sd+0x20>
   10870:	e2dff0ef          	jal	ra,1069c <sd_cmd0>
   10874:	fff00793          	li	a5,-1
   10878:	02050063          	beqz	a0,10898 <init_sd+0x54>
   1087c:	e99ff0ef          	jal	ra,10714 <sd_cmd8>
   10880:	ffe00793          	li	a5,-2
   10884:	00050a63          	beqz	a0,10898 <init_sd+0x54>
   10888:	f5dff0ef          	jal	ra,107e4 <sd_acmd41>
   1088c:	00000793          	li	a5,0
   10890:	00051463          	bnez	a0,10898 <init_sd+0x54>
   10894:	ffd00793          	li	a5,-3
   10898:	00813083          	ld	ra,8(sp)
   1089c:	00013403          	ld	s0,0(sp)
   108a0:	00078513          	mv	a0,a5
   108a4:	01010113          	addi	sp,sp,16
   108a8:	00008067          	ret

00000000000108ac <crc7>:
   108ac:	00b575b3          	and	a1,a0,a1
   108b0:	0075d79b          	srliw	a5,a1,0x7
   108b4:	0045d51b          	srliw	a0,a1,0x4
   108b8:	00f54533          	xor	a0,a0,a5
   108bc:	00b54533          	xor	a0,a0,a1
   108c0:	00451593          	slli	a1,a0,0x4
   108c4:	00b54533          	xor	a0,a0,a1
   108c8:	07f57513          	andi	a0,a0,127
   108cc:	00008067          	ret

00000000000108d0 <crc16>:
   108d0:	0085579b          	srliw	a5,a0,0x8
   108d4:	00851513          	slli	a0,a0,0x8
   108d8:	00f56533          	or	a0,a0,a5
   108dc:	03051513          	slli	a0,a0,0x30
   108e0:	03055513          	srli	a0,a0,0x30
   108e4:	00b545b3          	xor	a1,a0,a1
   108e8:	0045d51b          	srliw	a0,a1,0x4
   108ec:	00f57513          	andi	a0,a0,15
   108f0:	00b545b3          	xor	a1,a0,a1
   108f4:	00c59513          	slli	a0,a1,0xc
   108f8:	00a5c533          	xor	a0,a1,a0
   108fc:	0105151b          	slliw	a0,a0,0x10
   10900:	4105551b          	sraiw	a0,a0,0x10
   10904:	0105179b          	slliw	a5,a0,0x10
   10908:	0107d79b          	srliw	a5,a5,0x10
   1090c:	00002737          	lui	a4,0x2
   10910:	fe070713          	addi	a4,a4,-32 # 1fe0 <ROM_BASE-0xe020>
   10914:	0057979b          	slliw	a5,a5,0x5
   10918:	00e7f7b3          	and	a5,a5,a4
   1091c:	00f54533          	xor	a0,a0,a5
   10920:	03051513          	slli	a0,a0,0x30
   10924:	03055513          	srli	a0,a0,0x30
   10928:	00008067          	ret

000000000001092c <sd_copy>:
   1092c:	fe010113          	addi	sp,sp,-32
   10930:	00813823          	sd	s0,16(sp)
   10934:	00913423          	sd	s1,8(sp)
   10938:	00050413          	mv	s0,a0
   1093c:	00058493          	mv	s1,a1
   10940:	0185559b          	srliw	a1,a0,0x18
   10944:	00000513          	li	a0,0
   10948:	00113c23          	sd	ra,24(sp)
   1094c:	01213023          	sd	s2,0(sp)
   10950:	00060913          	mv	s2,a2
   10954:	f59ff0ef          	jal	ra,108ac <crc7>
   10958:	0104559b          	srliw	a1,s0,0x10
   1095c:	0ff5f593          	andi	a1,a1,255
   10960:	f4dff0ef          	jal	ra,108ac <crc7>
   10964:	0084559b          	srliw	a1,s0,0x8
   10968:	0ff5f593          	andi	a1,a1,255
   1096c:	f41ff0ef          	jal	ra,108ac <crc7>
   10970:	0ff47593          	andi	a1,s0,255
   10974:	f39ff0ef          	jal	ra,108ac <crc7>
   10978:	0015161b          	slliw	a2,a0,0x1
   1097c:	00166613          	ori	a2,a2,1
   10980:	0ff67613          	andi	a2,a2,255
   10984:	00040593          	mv	a1,s0
   10988:	01200513          	li	a0,18
   1098c:	c2dff0ef          	jal	ra,105b8 <sd_cmd>
   10990:	04050663          	beqz	a0,109dc <sd_copy+0xb0>
   10994:	c1dff0ef          	jal	ra,105b0 <sd_dummy>
   10998:	c19ff0ef          	jal	ra,105b0 <sd_dummy>
   1099c:	c15ff0ef          	jal	ra,105b0 <sd_dummy>
   109a0:	c11ff0ef          	jal	ra,105b0 <sd_dummy>
   109a4:	c0dff0ef          	jal	ra,105b0 <sd_dummy>
   109a8:	c09ff0ef          	jal	ra,105b0 <sd_dummy>
   109ac:	c05ff0ef          	jal	ra,105b0 <sd_dummy>
   109b0:	c01ff0ef          	jal	ra,105b0 <sd_dummy>
   109b4:	00001517          	auipc	a0,0x1
   109b8:	e5c50513          	addi	a0,a0,-420 # 11810 <_BSS_END_+0xc10>
   109bc:	869ff0ef          	jal	ra,10224 <print_uart>
   109c0:	fff00513          	li	a0,-1
   109c4:	01813083          	ld	ra,24(sp)
   109c8:	01013403          	ld	s0,16(sp)
   109cc:	00813483          	ld	s1,8(sp)
   109d0:	00013903          	ld	s2,0(sp)
   109d4:	02010113          	addi	sp,sp,32
   109d8:	00008067          	ret
   109dc:	00090593          	mv	a1,s2
   109e0:	00048513          	mv	a0,s1
   109e4:	b0dff0ef          	jal	ra,104f0 <spi_trans_with_dma>
   109e8:	00100613          	li	a2,1
   109ec:	00000593          	li	a1,0
   109f0:	00c00513          	li	a0,12
   109f4:	bc5ff0ef          	jal	ra,105b8 <sd_cmd>
   109f8:	bb9ff0ef          	jal	ra,105b0 <sd_dummy>
   109fc:	00000513          	li	a0,0
   10a00:	fc5ff06f          	j	109c4 <sd_copy+0x98>

Disassembly of section .text.startup:

0000000000010a04 <main>:
   10a04:	0001c5b7          	lui	a1,0x1c
   10a08:	02faf537          	lui	a0,0x2faf
   10a0c:	ff010113          	addi	sp,sp,-16
   10a10:	20058593          	addi	a1,a1,512 # 1c200 <_RODATA_END_+0xa9d0>
   10a14:	08050513          	addi	a0,a0,128 # 2faf080 <_RODATA_END_+0x2f9d850>
   10a18:	00113423          	sd	ra,8(sp)
   10a1c:	fc0ff0ef          	jal	ra,101dc <init_uart>
   10a20:	00001517          	auipc	a0,0x1
   10a24:	d3050513          	addi	a0,a0,-720 # 11750 <_BSS_END_+0xb50>
   10a28:	ffcff0ef          	jal	ra,10224 <print_uart>
   10a2c:	ed4ff0ef          	jal	ra,10100 <copy>
   10a30:	00813083          	ld	ra,8(sp)
   10a34:	00000513          	li	a0,0
   10a38:	01010113          	addi	sp,sp,16
   10a3c:	00008067          	ret

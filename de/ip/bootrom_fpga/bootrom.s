
bootrom.elf:     file format elf64-littleriscv


Disassembly of section .text.init:

0000000000010000 <_prog_start>:
   10000:	00800913          	li	s2,8
   10004:	30491073          	csrw	mie,s2
   10008:	00000493          	li	s1,0
   1000c:	f1402973          	csrr	s2,mhartid
   10010:	03249663          	bne	s1,s2,1003c <_prog_start+0x3c>
   10014:	0210011b          	addw	sp,zero,33
   10018:	01a11113          	sll	sp,sp,0x1a
   1001c:	2c1000ef          	jal	10adc <main>
   10020:	020004b7          	lui	s1,0x2000
   10024:	00100913          	li	s2,1
   10028:	0124a023          	sw	s2,0(s1) # 2000000 <spinner+0x1fee728>
   1002c:	00448493          	add	s1,s1,4
   10030:	02000937          	lui	s2,0x2000
   10034:	0209091b          	addw	s2,s2,32 # 2000020 <spinner+0x1fee748>
   10038:	ff24c6e3          	blt	s1,s2,10024 <_prog_start+0x24>
   1003c:	10500073          	wfi
   10040:	34402973          	csrr	s2,mip
   10044:	00897913          	and	s2,s2,8
   10048:	fe090ae3          	beqz	s2,1003c <_prog_start+0x3c>
   1004c:	020004b7          	lui	s1,0x2000
   10050:	f1402973          	csrr	s2,mhartid
   10054:	00291913          	sll	s2,s2,0x2
   10058:	00990933          	add	s2,s2,s1
   1005c:	00092023          	sw	zero,0(s2)
   10060:	0004a903          	lw	s2,0(s1) # 2000000 <spinner+0x1fee728>
   10064:	fe091ee3          	bnez	s2,10060 <_prog_start+0x60>
   10068:	00448493          	add	s1,s1,4
   1006c:	02000937          	lui	s2,0x2000
   10070:	0209091b          	addw	s2,s2,32 # 2000020 <spinner+0x1fee748>
   10074:	ff24c6e3          	blt	s1,s2,10060 <_prog_start+0x60>
   10078:	f1402573          	csrr	a0,mhartid
   1007c:	00001597          	auipc	a1,0x1
   10080:	c8458593          	add	a1,a1,-892 # 10d00 <_BSS_END_>
   10084:	0010049b          	addw	s1,zero,1
   10088:	01f49493          	sll	s1,s1,0x1f
   1008c:	00048067          	jr	s1

Disassembly of section .text:

0000000000010100 <copy>:
   10100:	fe010113          	add	sp,sp,-32
   10104:	00813823          	sd	s0,16(sp)
   10108:	00113c23          	sd	ra,24(sp)
   1010c:	00913423          	sd	s1,8(sp)
   10110:	02010413          	add	s0,sp,32
   10114:	7e8000ef          	jal	108fc <init_sd>
   10118:	e0010113          	add	sp,sp,-512
   1011c:	02050863          	beqz	a0,1014c <copy+0x4c>
   10120:	00001517          	auipc	a0,0x1
   10124:	64050513          	add	a0,a0,1600 # 11760 <_BSS_END_+0xa60>
   10128:	128000ef          	jal	10250 <print_uart>
   1012c:	fff00493          	li	s1,-1
   10130:	fe040113          	add	sp,s0,-32
   10134:	01813083          	ld	ra,24(sp)
   10138:	00048513          	mv	a0,s1
   1013c:	01013403          	ld	s0,16(sp)
   10140:	00813483          	ld	s1,8(sp)
   10144:	02010113          	add	sp,sp,32
   10148:	00008067          	ret
   1014c:	00001517          	auipc	a0,0x1
   10150:	63c50513          	add	a0,a0,1596 # 11788 <_BSS_END_+0xa88>
   10154:	0fc000ef          	jal	10250 <print_uart>
   10158:	000015b7          	lui	a1,0x1
   1015c:	00008637          	lui	a2,0x8
   10160:	80058593          	add	a1,a1,-2048 # 800 <ROM_BASE-0xf800>
   10164:	00010513          	mv	a0,sp
   10168:	085000ef          	jal	109ec <sd_copy>
   1016c:	00050493          	mv	s1,a0
   10170:	02050c63          	beqz	a0,101a8 <copy+0xa8>
   10174:	00001517          	auipc	a0,0x1
   10178:	62c50513          	add	a0,a0,1580 # 117a0 <_BSS_END_+0xaa0>
   1017c:	0d4000ef          	jal	10250 <print_uart>
   10180:	00001517          	auipc	a0,0x1
   10184:	63850513          	add	a0,a0,1592 # 117b8 <_BSS_END_+0xab8>
   10188:	0c8000ef          	jal	10250 <print_uart>
   1018c:	00048513          	mv	a0,s1
   10190:	180000ef          	jal	10310 <print_uart_addr>
   10194:	00001517          	auipc	a0,0x1
   10198:	6ac50513          	add	a0,a0,1708 # 11840 <_BSS_END_+0xb40>
   1019c:	0b4000ef          	jal	10250 <print_uart>
   101a0:	ffe00493          	li	s1,-2
   101a4:	f8dff06f          	j	10130 <copy+0x30>
   101a8:	00001517          	auipc	a0,0x1
   101ac:	62850513          	add	a0,a0,1576 # 117d0 <_BSS_END_+0xad0>
   101b0:	0a0000ef          	jal	10250 <print_uart>
   101b4:	f7dff06f          	j	10130 <copy+0x30>

00000000000101b8 <write_reg_u8>:
   101b8:	00b50023          	sb	a1,0(a0)
   101bc:	00008067          	ret

00000000000101c0 <read_reg_u8>:
   101c0:	00054503          	lbu	a0,0(a0)
   101c4:	00008067          	ret

00000000000101c8 <is_transmit_empty>:
   101c8:	100007b7          	lui	a5,0x10000
   101cc:	0147c503          	lbu	a0,20(a5) # 10000014 <spinner+0xffee73c>
   101d0:	02057513          	and	a0,a0,32
   101d4:	00008067          	ret

00000000000101d8 <write_serial>:
   101d8:	10000737          	lui	a4,0x10000
   101dc:	01470713          	add	a4,a4,20 # 10000014 <spinner+0xffee73c>
   101e0:	00074783          	lbu	a5,0(a4)
   101e4:	0207f793          	and	a5,a5,32
   101e8:	fe078ce3          	beqz	a5,101e0 <write_serial+0x8>
   101ec:	100007b7          	lui	a5,0x10000
   101f0:	00a78023          	sb	a0,0(a5) # 10000000 <spinner+0xffee728>
   101f4:	00008067          	ret

00000000000101f8 <init_uart>:
   101f8:	0045959b          	sllw	a1,a1,0x4
   101fc:	02b5553b          	divuw	a0,a0,a1
   10200:	10000737          	lui	a4,0x10000
   10204:	00070223          	sb	zero,4(a4) # 10000004 <spinner+0xffee72c>
   10208:	100007b7          	lui	a5,0x10000
   1020c:	f8000693          	li	a3,-128
   10210:	00d78623          	sb	a3,12(a5) # 1000000c <spinner+0xffee734>
   10214:	100006b7          	lui	a3,0x10000
   10218:	0ff57613          	zext.b	a2,a0
   1021c:	0085551b          	srlw	a0,a0,0x8
   10220:	00c68023          	sb	a2,0(a3) # 10000000 <spinner+0xffee728>
   10224:	0ff57513          	zext.b	a0,a0
   10228:	00a70223          	sb	a0,4(a4)
   1022c:	00300713          	li	a4,3
   10230:	00e78623          	sb	a4,12(a5)
   10234:	100007b7          	lui	a5,0x10000
   10238:	fc700713          	li	a4,-57
   1023c:	00e78423          	sb	a4,8(a5) # 10000008 <spinner+0xffee730>
   10240:	100007b7          	lui	a5,0x10000
   10244:	02000713          	li	a4,32
   10248:	00e78823          	sb	a4,16(a5) # 10000010 <spinner+0xffee738>
   1024c:	00008067          	ret

0000000000010250 <print_uart>:
   10250:	ff010113          	add	sp,sp,-16
   10254:	00813023          	sd	s0,0(sp)
   10258:	00113423          	sd	ra,8(sp)
   1025c:	00050413          	mv	s0,a0
   10260:	00044503          	lbu	a0,0(s0)
   10264:	00051a63          	bnez	a0,10278 <print_uart+0x28>
   10268:	00813083          	ld	ra,8(sp)
   1026c:	00013403          	ld	s0,0(sp)
   10270:	01010113          	add	sp,sp,16
   10274:	00008067          	ret
   10278:	f61ff0ef          	jal	101d8 <write_serial>
   1027c:	00140413          	add	s0,s0,1
   10280:	fe1ff06f          	j	10260 <print_uart+0x10>

0000000000010284 <bin_to_hex>:
   10284:	00001797          	auipc	a5,0x1
   10288:	97c78793          	add	a5,a5,-1668 # 10c00 <bin_to_hex_table>
   1028c:	00f57713          	and	a4,a0,15
   10290:	00e78733          	add	a4,a5,a4
   10294:	00074703          	lbu	a4,0(a4)
   10298:	00455513          	srl	a0,a0,0x4
   1029c:	00a787b3          	add	a5,a5,a0
   102a0:	00e580a3          	sb	a4,1(a1)
   102a4:	0007c783          	lbu	a5,0(a5)
   102a8:	00f58023          	sb	a5,0(a1)
   102ac:	00008067          	ret

00000000000102b0 <print_uart_int>:
   102b0:	fd010113          	add	sp,sp,-48
   102b4:	02813023          	sd	s0,32(sp)
   102b8:	00913c23          	sd	s1,24(sp)
   102bc:	01213823          	sd	s2,16(sp)
   102c0:	02113423          	sd	ra,40(sp)
   102c4:	00050493          	mv	s1,a0
   102c8:	01800413          	li	s0,24
   102cc:	ff800913          	li	s2,-8
   102d0:	0084d53b          	srlw	a0,s1,s0
   102d4:	00810593          	add	a1,sp,8
   102d8:	0ff57513          	zext.b	a0,a0
   102dc:	fa9ff0ef          	jal	10284 <bin_to_hex>
   102e0:	00814503          	lbu	a0,8(sp)
   102e4:	ff84041b          	addw	s0,s0,-8
   102e8:	ef1ff0ef          	jal	101d8 <write_serial>
   102ec:	00914503          	lbu	a0,9(sp)
   102f0:	ee9ff0ef          	jal	101d8 <write_serial>
   102f4:	fd241ee3          	bne	s0,s2,102d0 <print_uart_int+0x20>
   102f8:	02813083          	ld	ra,40(sp)
   102fc:	02013403          	ld	s0,32(sp)
   10300:	01813483          	ld	s1,24(sp)
   10304:	01013903          	ld	s2,16(sp)
   10308:	03010113          	add	sp,sp,48
   1030c:	00008067          	ret

0000000000010310 <print_uart_addr>:
   10310:	fd010113          	add	sp,sp,-48
   10314:	02813023          	sd	s0,32(sp)
   10318:	00913c23          	sd	s1,24(sp)
   1031c:	01213823          	sd	s2,16(sp)
   10320:	02113423          	sd	ra,40(sp)
   10324:	00050493          	mv	s1,a0
   10328:	03800413          	li	s0,56
   1032c:	ff800913          	li	s2,-8
   10330:	0084d533          	srl	a0,s1,s0
   10334:	00810593          	add	a1,sp,8
   10338:	0ff57513          	zext.b	a0,a0
   1033c:	f49ff0ef          	jal	10284 <bin_to_hex>
   10340:	00814503          	lbu	a0,8(sp)
   10344:	ff84041b          	addw	s0,s0,-8
   10348:	e91ff0ef          	jal	101d8 <write_serial>
   1034c:	00914503          	lbu	a0,9(sp)
   10350:	e89ff0ef          	jal	101d8 <write_serial>
   10354:	fd241ee3          	bne	s0,s2,10330 <print_uart_addr+0x20>
   10358:	02813083          	ld	ra,40(sp)
   1035c:	02013403          	ld	s0,32(sp)
   10360:	01813483          	ld	s1,24(sp)
   10364:	01013903          	ld	s2,16(sp)
   10368:	03010113          	add	sp,sp,48
   1036c:	00008067          	ret

0000000000010370 <print_uart_byte>:
   10370:	fe010113          	add	sp,sp,-32
   10374:	00810593          	add	a1,sp,8
   10378:	00113c23          	sd	ra,24(sp)
   1037c:	f09ff0ef          	jal	10284 <bin_to_hex>
   10380:	00814503          	lbu	a0,8(sp)
   10384:	e55ff0ef          	jal	101d8 <write_serial>
   10388:	00914503          	lbu	a0,9(sp)
   1038c:	01813083          	ld	ra,24(sp)
   10390:	02010113          	add	sp,sp,32
   10394:	e45ff06f          	j	101d8 <write_serial>

0000000000010398 <write_reg_u32>:
   10398:	00b52023          	sw	a1,0(a0)
   1039c:	00008067          	ret

00000000000103a0 <Dma_trans>:
   103a0:	000307b7          	lui	a5,0x30
   103a4:	00a7a023          	sw	a0,0(a5) # 30000 <spinner+0x1e728>
   103a8:	00b7a423          	sw	a1,8(a5)
   103ac:	000307b7          	lui	a5,0x30
   103b0:	00d7a823          	sw	a3,16(a5) # 30010 <spinner+0x1e738>
   103b4:	000307b7          	lui	a5,0x30
   103b8:	00c7ac23          	sw	a2,24(a5) # 30018 <spinner+0x1e740>
   103bc:	000307b7          	lui	a5,0x30
   103c0:	02e7a023          	sw	a4,32(a5) # 30020 <spinner+0x1e748>
   103c4:	00008067          	ret

00000000000103c8 <Dma_start>:
   103c8:	000307b7          	lui	a5,0x30
   103cc:	00100713          	li	a4,1
   103d0:	00e7ae23          	sw	a4,28(a5) # 3001c <spinner+0x1e744>
   103d4:	00008067          	ret

00000000000103d8 <is_Dma_done>:
   103d8:	000307b7          	lui	a5,0x30
   103dc:	01c7a503          	lw	a0,28(a5) # 3001c <spinner+0x1e744>
   103e0:	00257513          	and	a0,a0,2
   103e4:	00008067          	ret

00000000000103e8 <flush_done>:
   103e8:	000307b7          	lui	a5,0x30
   103ec:	0007ae23          	sw	zero,28(a5) # 3001c <spinner+0x1e744>
   103f0:	00008067          	ret

00000000000103f4 <write_reg>:
   103f4:	00b52023          	sw	a1,0(a0)
   103f8:	00008067          	ret

00000000000103fc <read_reg>:
   103fc:	00052503          	lw	a0,0(a0)
   10400:	00008067          	ret

0000000000010404 <spi_init>:
   10404:	00001517          	auipc	a0,0x1
   10408:	fe010113          	add	sp,sp,-32
   1040c:	40c50513          	add	a0,a0,1036 # 11810 <_BSS_END_+0xb10>
   10410:	00113c23          	sd	ra,24(sp)
   10414:	00813823          	sd	s0,16(sp)
   10418:	00913423          	sd	s1,8(sp)
   1041c:	01213023          	sd	s2,0(sp)
   10420:	e31ff0ef          	jal	10250 <print_uart>
   10424:	200007b7          	lui	a5,0x20000
   10428:	00a00713          	li	a4,10
   1042c:	04e7a023          	sw	a4,64(a5) # 20000040 <spinner+0x1ffee768>
   10430:	00a00793          	li	a5,10
   10434:	00000013          	nop
   10438:	fff7879b          	addw	a5,a5,-1
   1043c:	fe079ce3          	bnez	a5,10434 <spi_init+0x30>
   10440:	10400793          	li	a5,260
   10444:	20000437          	lui	s0,0x20000
   10448:	06f42023          	sw	a5,96(s0) # 20000060 <spinner+0x1ffee788>
   1044c:	200004b7          	lui	s1,0x20000
   10450:	0644a903          	lw	s2,100(s1) # 20000064 <spinner+0x1ffee78c>
   10454:	00001517          	auipc	a0,0x1
   10458:	3cc50513          	add	a0,a0,972 # 11820 <_BSS_END_+0xb20>
   1045c:	df5ff0ef          	jal	10250 <print_uart>
   10460:	0009091b          	sext.w	s2,s2
   10464:	02091513          	sll	a0,s2,0x20
   10468:	02055513          	srl	a0,a0,0x20
   1046c:	ea5ff0ef          	jal	10310 <print_uart_addr>
   10470:	00001517          	auipc	a0,0x1
   10474:	3d050513          	add	a0,a0,976 # 11840 <_BSS_END_+0xb40>
   10478:	dd9ff0ef          	jal	10250 <print_uart>
   1047c:	16600793          	li	a5,358
   10480:	06f42023          	sw	a5,96(s0)
   10484:	06448493          	add	s1,s1,100
   10488:	0004a483          	lw	s1,0(s1)
   1048c:	00001517          	auipc	a0,0x1
   10490:	39450513          	add	a0,a0,916 # 11820 <_BSS_END_+0xb20>
   10494:	dbdff0ef          	jal	10250 <print_uart>
   10498:	0004849b          	sext.w	s1,s1
   1049c:	02049513          	sll	a0,s1,0x20
   104a0:	02055513          	srl	a0,a0,0x20
   104a4:	e6dff0ef          	jal	10310 <print_uart_addr>
   104a8:	00001517          	auipc	a0,0x1
   104ac:	39850513          	add	a0,a0,920 # 11840 <_BSS_END_+0xb40>
   104b0:	da1ff0ef          	jal	10250 <print_uart>
   104b4:	00600793          	li	a5,6
   104b8:	06f42023          	sw	a5,96(s0)
   104bc:	01013403          	ld	s0,16(sp)
   104c0:	01813083          	ld	ra,24(sp)
   104c4:	00813483          	ld	s1,8(sp)
   104c8:	00013903          	ld	s2,0(sp)
   104cc:	00001517          	auipc	a0,0x1
   104d0:	36450513          	add	a0,a0,868 # 11830 <_BSS_END_+0xb30>
   104d4:	02010113          	add	sp,sp,32
   104d8:	d79ff06f          	j	10250 <print_uart>

00000000000104dc <spi_txrx>:
   104dc:	fe010113          	add	sp,sp,-32
   104e0:	00113c23          	sd	ra,24(sp)
   104e4:	00813823          	sd	s0,16(sp)
   104e8:	00913423          	sd	s1,8(sp)
   104ec:	200007b7          	lui	a5,0x20000
   104f0:	ffe00713          	li	a4,-2
   104f4:	06e7a823          	sw	a4,112(a5) # 20000070 <spinner+0x1ffee798>
   104f8:	200007b7          	lui	a5,0x20000
   104fc:	06a7a423          	sw	a0,104(a5) # 20000068 <spinner+0x1ffee790>
   10500:	06400793          	li	a5,100
   10504:	00000013          	nop
   10508:	fff7879b          	addw	a5,a5,-1
   1050c:	fe079ce3          	bnez	a5,10504 <spi_txrx+0x28>
   10510:	200007b7          	lui	a5,0x20000
   10514:	10600713          	li	a4,262
   10518:	20000437          	lui	s0,0x20000
   1051c:	06e7a023          	sw	a4,96(a5) # 20000060 <spinner+0x1ffee788>
   10520:	06440413          	add	s0,s0,100 # 20000064 <spinner+0x1ffee78c>
   10524:	00042783          	lw	a5,0(s0)
   10528:	0017f793          	and	a5,a5,1
   1052c:	fe079ce3          	bnez	a5,10524 <spi_txrx+0x48>
   10530:	200007b7          	lui	a5,0x20000
   10534:	06c7a483          	lw	s1,108(a5) # 2000006c <spinner+0x1ffee794>
   10538:	00042783          	lw	a5,0(s0)
   1053c:	0004849b          	sext.w	s1,s1
   10540:	0017f793          	and	a5,a5,1
   10544:	02079663          	bnez	a5,10570 <spi_txrx+0x94>
   10548:	00001517          	auipc	a0,0x1
   1054c:	30050513          	add	a0,a0,768 # 11848 <_BSS_END_+0xb48>
   10550:	d01ff0ef          	jal	10250 <print_uart>
   10554:	00042503          	lw	a0,0(s0)
   10558:	02051513          	sll	a0,a0,0x20
   1055c:	02055513          	srl	a0,a0,0x20
   10560:	db1ff0ef          	jal	10310 <print_uart_addr>
   10564:	00001517          	auipc	a0,0x1
   10568:	2dc50513          	add	a0,a0,732 # 11840 <_BSS_END_+0xb40>
   1056c:	ce5ff0ef          	jal	10250 <print_uart>
   10570:	01813083          	ld	ra,24(sp)
   10574:	01013403          	ld	s0,16(sp)
   10578:	200007b7          	lui	a5,0x20000
   1057c:	fff00713          	li	a4,-1
   10580:	06e7a823          	sw	a4,112(a5) # 20000070 <spinner+0x1ffee798>
   10584:	200007b7          	lui	a5,0x20000
   10588:	00600713          	li	a4,6
   1058c:	06e7a023          	sw	a4,96(a5) # 20000060 <spinner+0x1ffee788>
   10590:	0ff4f513          	zext.b	a0,s1
   10594:	00813483          	ld	s1,8(sp)
   10598:	02010113          	add	sp,sp,32
   1059c:	00008067          	ret

00000000000105a0 <spi_write_bytes>:
   105a0:	fe010113          	add	sp,sp,-32
   105a4:	00113c23          	sd	ra,24(sp)
   105a8:	00813823          	sd	s0,16(sp)
   105ac:	00913423          	sd	s1,8(sp)
   105b0:	200007b7          	lui	a5,0x20000
   105b4:	ffe00713          	li	a4,-2
   105b8:	00068593          	mv	a1,a3
   105bc:	06e7a823          	sw	a4,112(a5) # 20000070 <spinner+0x1ffee798>
   105c0:	0000100f          	fence.i
   105c4:	20000537          	lui	a0,0x20000
   105c8:	00100713          	li	a4,1
   105cc:	010006b7          	lui	a3,0x1000
   105d0:	01000613          	li	a2,16
   105d4:	06c50513          	add	a0,a0,108 # 2000006c <spinner+0x1ffee794>
   105d8:	dc9ff0ef          	jal	103a0 <Dma_trans>
   105dc:	00000493          	li	s1,0
   105e0:	de9ff0ef          	jal	103c8 <Dma_start>
   105e4:	df5ff0ef          	jal	103d8 <is_Dma_done>
   105e8:	0005051b          	sext.w	a0,a0
   105ec:	04051063          	bnez	a0,1062c <spi_write_bytes+0x8c>
   105f0:	0014841b          	addw	s0,s1,1
   105f4:	3ff47793          	and	a5,s0,1023
   105f8:	0004049b          	sext.w	s1,s0
   105fc:	fe0794e3          	bnez	a5,105e4 <spi_write_bytes+0x44>
   10600:	00001517          	auipc	a0,0x1
   10604:	26050513          	add	a0,a0,608 # 11860 <_BSS_END_+0xb60>
   10608:	c49ff0ef          	jal	10250 <print_uart>
   1060c:	00001797          	auipc	a5,0x1
   10610:	00a4541b          	srlw	s0,s0,0xa
   10614:	00347413          	and	s0,s0,3
   10618:	2cc78793          	add	a5,a5,716 # 118d8 <spinner>
   1061c:	008787b3          	add	a5,a5,s0
   10620:	0007c503          	lbu	a0,0(a5)
   10624:	bb5ff0ef          	jal	101d8 <write_serial>
   10628:	fbdff06f          	j	105e4 <spi_write_bytes+0x44>
   1062c:	dbdff0ef          	jal	103e8 <flush_done>
   10630:	01813083          	ld	ra,24(sp)
   10634:	01013403          	ld	s0,16(sp)
   10638:	200007b7          	lui	a5,0x20000
   1063c:	fff00713          	li	a4,-1
   10640:	06e7a823          	sw	a4,112(a5) # 20000070 <spinner+0x1ffee798>
   10644:	200007b7          	lui	a5,0x20000
   10648:	00600713          	li	a4,6
   1064c:	06e7a023          	sw	a4,96(a5) # 20000060 <spinner+0x1ffee788>
   10650:	00813483          	ld	s1,8(sp)
   10654:	00000513          	li	a0,0
   10658:	02010113          	add	sp,sp,32
   1065c:	00008067          	ret

0000000000010660 <sd_dummy>:
   10660:	0ff00513          	li	a0,255
   10664:	e79ff06f          	j	104dc <spi_txrx>

0000000000010668 <sd_cmd>:
   10668:	fe010113          	add	sp,sp,-32
   1066c:	00113c23          	sd	ra,24(sp)
   10670:	00813823          	sd	s0,16(sp)
   10674:	00913423          	sd	s1,8(sp)
   10678:	00058413          	mv	s0,a1
   1067c:	00060493          	mv	s1,a2
   10680:	01213023          	sd	s2,0(sp)
   10684:	00050913          	mv	s2,a0
   10688:	fd9ff0ef          	jal	10660 <sd_dummy>
   1068c:	04096513          	or	a0,s2,64
   10690:	e4dff0ef          	jal	104dc <spi_txrx>
   10694:	0184551b          	srlw	a0,s0,0x18
   10698:	e45ff0ef          	jal	104dc <spi_txrx>
   1069c:	0104551b          	srlw	a0,s0,0x10
   106a0:	0ff57513          	zext.b	a0,a0
   106a4:	e39ff0ef          	jal	104dc <spi_txrx>
   106a8:	0084551b          	srlw	a0,s0,0x8
   106ac:	0ff57513          	zext.b	a0,a0
   106b0:	e2dff0ef          	jal	104dc <spi_txrx>
   106b4:	0ff47513          	zext.b	a0,s0
   106b8:	e25ff0ef          	jal	104dc <spi_txrx>
   106bc:	00048513          	mv	a0,s1
   106c0:	e1dff0ef          	jal	104dc <spi_txrx>
   106c4:	06400413          	li	s0,100
   106c8:	f99ff0ef          	jal	10660 <sd_dummy>
   106cc:	0185179b          	sllw	a5,a0,0x18
   106d0:	4187d79b          	sraw	a5,a5,0x18
   106d4:	0007d663          	bgez	a5,106e0 <sd_cmd+0x78>
   106d8:	fff40413          	add	s0,s0,-1
   106dc:	fe0416e3          	bnez	s0,106c8 <sd_cmd+0x60>
   106e0:	01813083          	ld	ra,24(sp)
   106e4:	01013403          	ld	s0,16(sp)
   106e8:	00813483          	ld	s1,8(sp)
   106ec:	00013903          	ld	s2,0(sp)
   106f0:	02010113          	add	sp,sp,32
   106f4:	00008067          	ret

00000000000106f8 <print_status>:
   106f8:	fe010113          	add	sp,sp,-32
   106fc:	00913423          	sd	s1,8(sp)
   10700:	00050493          	mv	s1,a0
   10704:	00001517          	auipc	a0,0x1
   10708:	16450513          	add	a0,a0,356 # 11868 <_BSS_END_+0xb68>
   1070c:	00113c23          	sd	ra,24(sp)
   10710:	00813823          	sd	s0,16(sp)
   10714:	00058413          	mv	s0,a1
   10718:	b39ff0ef          	jal	10250 <print_uart>
   1071c:	00048513          	mv	a0,s1
   10720:	b31ff0ef          	jal	10250 <print_uart>
   10724:	00001517          	auipc	a0,0x1
   10728:	15450513          	add	a0,a0,340 # 11878 <_BSS_END_+0xb78>
   1072c:	b25ff0ef          	jal	10250 <print_uart>
   10730:	00040513          	mv	a0,s0
   10734:	c3dff0ef          	jal	10370 <print_uart_byte>
   10738:	01013403          	ld	s0,16(sp)
   1073c:	01813083          	ld	ra,24(sp)
   10740:	00813483          	ld	s1,8(sp)
   10744:	00001517          	auipc	a0,0x1
   10748:	0fc50513          	add	a0,a0,252 # 11840 <_BSS_END_+0xb40>
   1074c:	02010113          	add	sp,sp,32
   10750:	b01ff06f          	j	10250 <print_uart>

0000000000010754 <sd_cmd0>:
   10754:	fe010113          	add	sp,sp,-32
   10758:	00813823          	sd	s0,16(sp)
   1075c:	00002437          	lui	s0,0x2
   10760:	01213023          	sd	s2,0(sp)
   10764:	00113c23          	sd	ra,24(sp)
   10768:	00913423          	sd	s1,8(sp)
   1076c:	71040413          	add	s0,s0,1808 # 2710 <ROM_BASE-0xd8f0>
   10770:	00100913          	li	s2,1
   10774:	09500613          	li	a2,149
   10778:	00000593          	li	a1,0
   1077c:	00000513          	li	a0,0
   10780:	ee9ff0ef          	jal	10668 <sd_cmd>
   10784:	fff4041b          	addw	s0,s0,-1
   10788:	00050493          	mv	s1,a0
   1078c:	ed5ff0ef          	jal	10660 <sd_dummy>
   10790:	02040a63          	beqz	s0,107c4 <sd_cmd0+0x70>
   10794:	ff2490e3          	bne	s1,s2,10774 <sd_cmd0+0x20>
   10798:	00001517          	auipc	a0,0x1
   1079c:	0f050513          	add	a0,a0,240 # 11888 <_BSS_END_+0xb88>
   107a0:	00100593          	li	a1,1
   107a4:	f55ff0ef          	jal	106f8 <print_status>
   107a8:	00100513          	li	a0,1
   107ac:	01813083          	ld	ra,24(sp)
   107b0:	01013403          	ld	s0,16(sp)
   107b4:	00813483          	ld	s1,8(sp)
   107b8:	00013903          	ld	s2,0(sp)
   107bc:	02010113          	add	sp,sp,32
   107c0:	00008067          	ret
   107c4:	00000513          	li	a0,0
   107c8:	fe5ff06f          	j	107ac <sd_cmd0+0x58>

00000000000107cc <sd_cmd8>:
   107cc:	fe010113          	add	sp,sp,-32
   107d0:	08700613          	li	a2,135
   107d4:	1aa00593          	li	a1,426
   107d8:	00800513          	li	a0,8
   107dc:	00113c23          	sd	ra,24(sp)
   107e0:	00813823          	sd	s0,16(sp)
   107e4:	00913423          	sd	s1,8(sp)
   107e8:	01213023          	sd	s2,0(sp)
   107ec:	e7dff0ef          	jal	10668 <sd_cmd>
   107f0:	00050913          	mv	s2,a0
   107f4:	e6dff0ef          	jal	10660 <sd_dummy>
   107f8:	e69ff0ef          	jal	10660 <sd_dummy>
   107fc:	e65ff0ef          	jal	10660 <sd_dummy>
   10800:	00050493          	mv	s1,a0
   10804:	e5dff0ef          	jal	10660 <sd_dummy>
   10808:	00050413          	mv	s0,a0
   1080c:	e55ff0ef          	jal	10660 <sd_dummy>
   10810:	e51ff0ef          	jal	10660 <sd_dummy>
   10814:	00100793          	li	a5,1
   10818:	00000513          	li	a0,0
   1081c:	00f91c63          	bne	s2,a5,10834 <sd_cmd8+0x68>
   10820:	00f4f493          	and	s1,s1,15
   10824:	01249863          	bne	s1,s2,10834 <sd_cmd8+0x68>
   10828:	0004041b          	sext.w	s0,s0
   1082c:	f5640413          	add	s0,s0,-170
   10830:	00143513          	seqz	a0,s0
   10834:	01813083          	ld	ra,24(sp)
   10838:	01013403          	ld	s0,16(sp)
   1083c:	00813483          	ld	s1,8(sp)
   10840:	00013903          	ld	s2,0(sp)
   10844:	02010113          	add	sp,sp,32
   10848:	00008067          	ret

000000000001084c <sd_cmd55>:
   1084c:	ff010113          	add	sp,sp,-16
   10850:	06500613          	li	a2,101
   10854:	00000593          	li	a1,0
   10858:	03700513          	li	a0,55
   1085c:	00113423          	sd	ra,8(sp)
   10860:	00813023          	sd	s0,0(sp)
   10864:	e05ff0ef          	jal	10668 <sd_cmd>
   10868:	00050413          	mv	s0,a0
   1086c:	df5ff0ef          	jal	10660 <sd_dummy>
   10870:	00001517          	auipc	a0,0x1
   10874:	00040593          	mv	a1,s0
   10878:	02050513          	add	a0,a0,32 # 11890 <_BSS_END_+0xb90>
   1087c:	e7dff0ef          	jal	106f8 <print_status>
   10880:	00813083          	ld	ra,8(sp)
   10884:	0004051b          	sext.w	a0,s0
   10888:	00013403          	ld	s0,0(sp)
   1088c:	fff50513          	add	a0,a0,-1
   10890:	00153513          	seqz	a0,a0
   10894:	01010113          	add	sp,sp,16
   10898:	00008067          	ret

000000000001089c <sd_acmd41>:
   1089c:	fe010113          	add	sp,sp,-32
   108a0:	00913423          	sd	s1,8(sp)
   108a4:	00113c23          	sd	ra,24(sp)
   108a8:	00813823          	sd	s0,16(sp)
   108ac:	00100493          	li	s1,1
   108b0:	f9dff0ef          	jal	1084c <sd_cmd55>
   108b4:	07700613          	li	a2,119
   108b8:	400005b7          	lui	a1,0x40000
   108bc:	02900513          	li	a0,41
   108c0:	da9ff0ef          	jal	10668 <sd_cmd>
   108c4:	00050413          	mv	s0,a0
   108c8:	00050593          	mv	a1,a0
   108cc:	00001517          	auipc	a0,0x1
   108d0:	fcc50513          	add	a0,a0,-52 # 11898 <_BSS_END_+0xb98>
   108d4:	e25ff0ef          	jal	106f8 <print_status>
   108d8:	d89ff0ef          	jal	10660 <sd_dummy>
   108dc:	fc940ae3          	beq	s0,s1,108b0 <sd_acmd41+0x14>
   108e0:	01813083          	ld	ra,24(sp)
   108e4:	0004051b          	sext.w	a0,s0
   108e8:	01013403          	ld	s0,16(sp)
   108ec:	00813483          	ld	s1,8(sp)
   108f0:	00153513          	seqz	a0,a0
   108f4:	02010113          	add	sp,sp,32
   108f8:	00008067          	ret

00000000000108fc <init_sd>:
   108fc:	ff010113          	add	sp,sp,-16
   10900:	00113423          	sd	ra,8(sp)
   10904:	00813023          	sd	s0,0(sp)
   10908:	afdff0ef          	jal	10404 <spi_init>
   1090c:	00001517          	auipc	a0,0x1
   10910:	f9450513          	add	a0,a0,-108 # 118a0 <_BSS_END_+0xba0>
   10914:	93dff0ef          	jal	10250 <print_uart>
   10918:	00a00413          	li	s0,10
   1091c:	fff4041b          	addw	s0,s0,-1
   10920:	d41ff0ef          	jal	10660 <sd_dummy>
   10924:	fe041ce3          	bnez	s0,1091c <init_sd+0x20>
   10928:	e2dff0ef          	jal	10754 <sd_cmd0>
   1092c:	fff00793          	li	a5,-1
   10930:	02050063          	beqz	a0,10950 <init_sd+0x54>
   10934:	e99ff0ef          	jal	107cc <sd_cmd8>
   10938:	ffe00793          	li	a5,-2
   1093c:	00050a63          	beqz	a0,10950 <init_sd+0x54>
   10940:	f5dff0ef          	jal	1089c <sd_acmd41>
   10944:	ffd00793          	li	a5,-3
   10948:	00050463          	beqz	a0,10950 <init_sd+0x54>
   1094c:	00000793          	li	a5,0
   10950:	00813083          	ld	ra,8(sp)
   10954:	00013403          	ld	s0,0(sp)
   10958:	00078513          	mv	a0,a5
   1095c:	01010113          	add	sp,sp,16
   10960:	00008067          	ret

0000000000010964 <crc7>:
   10964:	00b575b3          	and	a1,a0,a1
   10968:	0075d79b          	srlw	a5,a1,0x7
   1096c:	0045d51b          	srlw	a0,a1,0x4
   10970:	00f54533          	xor	a0,a0,a5
   10974:	0ff57513          	zext.b	a0,a0
   10978:	00b54533          	xor	a0,a0,a1
   1097c:	0045179b          	sllw	a5,a0,0x4
   10980:	0ff7f793          	zext.b	a5,a5
   10984:	00f54533          	xor	a0,a0,a5
   10988:	07f57513          	and	a0,a0,127
   1098c:	00008067          	ret

0000000000010990 <crc16>:
   10990:	0085179b          	sllw	a5,a0,0x8
   10994:	0085551b          	srlw	a0,a0,0x8
   10998:	00a7e7b3          	or	a5,a5,a0
   1099c:	03079793          	sll	a5,a5,0x30
   109a0:	0307d793          	srl	a5,a5,0x30
   109a4:	00f5c5b3          	xor	a1,a1,a5
   109a8:	0045d79b          	srlw	a5,a1,0x4
   109ac:	00f7f793          	and	a5,a5,15
   109b0:	00f5c533          	xor	a0,a1,a5
   109b4:	0105151b          	sllw	a0,a0,0x10
   109b8:	4105551b          	sraw	a0,a0,0x10
   109bc:	00c5179b          	sllw	a5,a0,0xc
   109c0:	00f54533          	xor	a0,a0,a5
   109c4:	0105151b          	sllw	a0,a0,0x10
   109c8:	4105551b          	sraw	a0,a0,0x10
   109cc:	000027b7          	lui	a5,0x2
   109d0:	0055171b          	sllw	a4,a0,0x5
   109d4:	fe078793          	add	a5,a5,-32 # 1fe0 <ROM_BASE-0xe020>
   109d8:	00e7f7b3          	and	a5,a5,a4
   109dc:	00f54533          	xor	a0,a0,a5
   109e0:	03051513          	sll	a0,a0,0x30
   109e4:	03055513          	srl	a0,a0,0x30
   109e8:	00008067          	ret

00000000000109ec <sd_copy>:
   109ec:	f6010113          	add	sp,sp,-160
   109f0:	08813823          	sd	s0,144(sp)
   109f4:	08913423          	sd	s1,136(sp)
   109f8:	08113c23          	sd	ra,152(sp)
   109fc:	00050493          	mv	s1,a0
   10a00:	00058413          	mv	s0,a1
   10a04:	00000793          	li	a5,0
   10a08:	fff00613          	li	a2,-1
   10a0c:	08000713          	li	a4,128
   10a10:	00f106b3          	add	a3,sp,a5
   10a14:	00c68023          	sb	a2,0(a3) # 1000000 <spinner+0xfee728>
   10a18:	00178793          	add	a5,a5,1
   10a1c:	fee79ae3          	bne	a5,a4,10a10 <sd_copy+0x24>
   10a20:	0184559b          	srlw	a1,s0,0x18
   10a24:	00000513          	li	a0,0
   10a28:	f3dff0ef          	jal	10964 <crc7>
   10a2c:	0104559b          	srlw	a1,s0,0x10
   10a30:	0ff5f593          	zext.b	a1,a1
   10a34:	f31ff0ef          	jal	10964 <crc7>
   10a38:	0084559b          	srlw	a1,s0,0x8
   10a3c:	0ff5f593          	zext.b	a1,a1
   10a40:	f25ff0ef          	jal	10964 <crc7>
   10a44:	0ff47593          	zext.b	a1,s0
   10a48:	f1dff0ef          	jal	10964 <crc7>
   10a4c:	0015161b          	sllw	a2,a0,0x1
   10a50:	00166613          	or	a2,a2,1
   10a54:	0ff67613          	zext.b	a2,a2
   10a58:	00040593          	mv	a1,s0
   10a5c:	01200513          	li	a0,18
   10a60:	c09ff0ef          	jal	10668 <sd_cmd>
   10a64:	04050463          	beqz	a0,10aac <sd_copy+0xc0>
   10a68:	bf9ff0ef          	jal	10660 <sd_dummy>
   10a6c:	bf5ff0ef          	jal	10660 <sd_dummy>
   10a70:	bf1ff0ef          	jal	10660 <sd_dummy>
   10a74:	bedff0ef          	jal	10660 <sd_dummy>
   10a78:	be9ff0ef          	jal	10660 <sd_dummy>
   10a7c:	be5ff0ef          	jal	10660 <sd_dummy>
   10a80:	be1ff0ef          	jal	10660 <sd_dummy>
   10a84:	bddff0ef          	jal	10660 <sd_dummy>
   10a88:	00001517          	auipc	a0,0x1
   10a8c:	e3050513          	add	a0,a0,-464 # 118b8 <_BSS_END_+0xbb8>
   10a90:	fc0ff0ef          	jal	10250 <print_uart>
   10a94:	fff00513          	li	a0,-1
   10a98:	09813083          	ld	ra,152(sp)
   10a9c:	09013403          	ld	s0,144(sp)
   10aa0:	08813483          	ld	s1,136(sp)
   10aa4:	0a010113          	add	sp,sp,160
   10aa8:	00008067          	ret
   10aac:	800006b7          	lui	a3,0x80000
   10ab0:	00048613          	mv	a2,s1
   10ab4:	04000593          	li	a1,64
   10ab8:	00010513          	mv	a0,sp
   10abc:	ae5ff0ef          	jal	105a0 <spi_write_bytes>
   10ac0:	00100613          	li	a2,1
   10ac4:	00000593          	li	a1,0
   10ac8:	00c00513          	li	a0,12
   10acc:	b9dff0ef          	jal	10668 <sd_cmd>
   10ad0:	b91ff0ef          	jal	10660 <sd_dummy>
   10ad4:	00000513          	li	a0,0
   10ad8:	fc1ff06f          	j	10a98 <sd_copy+0xac>

Disassembly of section .text.startup:

0000000000010adc <main>:
   10adc:	0001c5b7          	lui	a1,0x1c
   10ae0:	02faf537          	lui	a0,0x2faf
   10ae4:	ff010113          	add	sp,sp,-16
   10ae8:	20058593          	add	a1,a1,512 # 1c200 <spinner+0xa928>
   10aec:	08050513          	add	a0,a0,128 # 2faf080 <spinner+0x2f9d7a8>
   10af0:	00113423          	sd	ra,8(sp)
   10af4:	f04ff0ef          	jal	101f8 <init_uart>
   10af8:	00001517          	auipc	a0,0x1
   10afc:	ce850513          	add	a0,a0,-792 # 117e0 <_BSS_END_+0xae0>
   10b00:	f50ff0ef          	jal	10250 <print_uart>
   10b04:	00001517          	auipc	a0,0x1
   10b08:	cec50513          	add	a0,a0,-788 # 117f0 <_BSS_END_+0xaf0>
   10b0c:	f44ff0ef          	jal	10250 <print_uart>
   10b10:	df0ff0ef          	jal	10100 <copy>
   10b14:	00001517          	auipc	a0,0x1
   10b18:	cec50513          	add	a0,a0,-788 # 11800 <_BSS_END_+0xb00>
   10b1c:	f34ff0ef          	jal	10250 <print_uart>
   10b20:	0010041b          	addw	s0,zero,1
   10b24:	01f41413          	sll	s0,s0,0x1f
   10b28:	00000597          	auipc	a1,0x0
   10b2c:	1d858593          	add	a1,a1,472 # 10d00 <_BSS_END_>
   10b30:	00040067          	jr	s0
   10b34:	00813083          	ld	ra,8(sp)
   10b38:	00000513          	li	a0,0
   10b3c:	01010113          	add	sp,sp,16
   10b40:	00008067          	ret

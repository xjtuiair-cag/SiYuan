
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
   1001c:	5e1000ef          	jal	ra,10dfc <_TEXT_END_>
   10020:	020004b7          	lui	s1,0x2000
   10024:	00100913          	li	s2,1
   10028:	0124a023          	sw	s2,0(s1) # 2000000 <_RODATA_END_+0x1fee09f>
   1002c:	00448493          	addi	s1,s1,4
   10030:	02000937          	lui	s2,0x2000
   10034:	4009091b          	addiw	s2,s2,1024
   10038:	ff24c6e3          	blt	s1,s2,10024 <_prog_start+0x24>
   1003c:	10500073          	wfi
   10040:	34402973          	csrr	s2,mip
   10044:	00897913          	andi	s2,s2,8
   10048:	fe090ae3          	beqz	s2,1003c <_prog_start+0x3c>
   1004c:	020004b7          	lui	s1,0x2000
   10050:	f1402973          	csrr	s2,mhartid
   10054:	00291913          	slli	s2,s2,0x2
   10058:	00990933          	add	s2,s2,s1
   1005c:	00092023          	sw	zero,0(s2) # 2000000 <_RODATA_END_+0x1fee09f>
   10060:	0004a903          	lw	s2,0(s1) # 2000000 <_RODATA_END_+0x1fee09f>
   10064:	fe091ee3          	bnez	s2,10060 <_prog_start+0x60>
   10068:	00448493          	addi	s1,s1,4
   1006c:	02000937          	lui	s2,0x2000
   10070:	4009091b          	addiw	s2,s2,1024
   10074:	ff24c6e3          	blt	s1,s2,10060 <_prog_start+0x60>
   10078:	f1402573          	csrr	a0,mhartid
   1007c:	00001597          	auipc	a1,0x1
   10080:	f8458593          	addi	a1,a1,-124 # 11000 <_BSS_END_>
   10084:	0010049b          	addiw	s1,zero,1
   10088:	01f49493          	slli	s1,s1,0x1f
   1008c:	00048067          	jr	s1

Disassembly of section .text:

0000000000010100 <handle_trap>:
   10100:	00008067          	ret

0000000000010104 <write_reg_u8>:
   10104:	00b50023          	sb	a1,0(a0)
   10108:	00008067          	ret

000000000001010c <read_reg_u8>:
   1010c:	00054503          	lbu	a0,0(a0)
   10110:	00008067          	ret

0000000000010114 <is_transmit_empty>:
   10114:	100007b7          	lui	a5,0x10000
   10118:	0147c503          	lbu	a0,20(a5) # 10000014 <_RODATA_END_+0xffee0b3>
   1011c:	02057513          	andi	a0,a0,32
   10120:	00008067          	ret

0000000000010124 <write_serial>:
   10124:	10000737          	lui	a4,0x10000
   10128:	01470713          	addi	a4,a4,20 # 10000014 <_RODATA_END_+0xffee0b3>
   1012c:	00074783          	lbu	a5,0(a4)
   10130:	0207f793          	andi	a5,a5,32
   10134:	fe078ce3          	beqz	a5,1012c <write_serial+0x8>
   10138:	100007b7          	lui	a5,0x10000
   1013c:	00a78023          	sb	a0,0(a5) # 10000000 <_RODATA_END_+0xffee09f>
   10140:	00008067          	ret

0000000000010144 <init_uart>:
   10144:	0045959b          	slliw	a1,a1,0x4
   10148:	02b5553b          	divuw	a0,a0,a1
   1014c:	10000737          	lui	a4,0x10000
   10150:	00070223          	sb	zero,4(a4) # 10000004 <_RODATA_END_+0xffee0a3>
   10154:	100007b7          	lui	a5,0x10000
   10158:	f8000693          	li	a3,-128
   1015c:	00d78623          	sb	a3,12(a5) # 1000000c <_RODATA_END_+0xffee0ab>
   10160:	100006b7          	lui	a3,0x10000
   10164:	0ff57613          	andi	a2,a0,255
   10168:	0085551b          	srliw	a0,a0,0x8
   1016c:	00c68023          	sb	a2,0(a3) # 10000000 <_RODATA_END_+0xffee09f>
   10170:	0ff57513          	andi	a0,a0,255
   10174:	00a70223          	sb	a0,4(a4)
   10178:	00300713          	li	a4,3
   1017c:	00e78623          	sb	a4,12(a5)
   10180:	100007b7          	lui	a5,0x10000
   10184:	fc700713          	li	a4,-57
   10188:	00e78423          	sb	a4,8(a5) # 10000008 <_RODATA_END_+0xffee0a7>
   1018c:	100007b7          	lui	a5,0x10000
   10190:	02000713          	li	a4,32
   10194:	00e78823          	sb	a4,16(a5) # 10000010 <_RODATA_END_+0xffee0af>
   10198:	00008067          	ret

000000000001019c <print_uart>:
   1019c:	ff010113          	addi	sp,sp,-16
   101a0:	00813023          	sd	s0,0(sp)
   101a4:	00113423          	sd	ra,8(sp)
   101a8:	00050413          	mv	s0,a0
   101ac:	00044503          	lbu	a0,0(s0)
   101b0:	00051a63          	bnez	a0,101c4 <print_uart+0x28>
   101b4:	00813083          	ld	ra,8(sp)
   101b8:	00013403          	ld	s0,0(sp)
   101bc:	01010113          	addi	sp,sp,16
   101c0:	00008067          	ret
   101c4:	f61ff0ef          	jal	ra,10124 <write_serial>
   101c8:	00140413          	addi	s0,s0,1
   101cc:	fe1ff06f          	j	101ac <print_uart+0x10>

00000000000101d0 <bin_to_hex>:
   101d0:	00001797          	auipc	a5,0x1
   101d4:	d3078793          	addi	a5,a5,-720 # 10f00 <bin_to_hex_table>
   101d8:	00f57713          	andi	a4,a0,15
   101dc:	00e78733          	add	a4,a5,a4
   101e0:	00074703          	lbu	a4,0(a4)
   101e4:	00455513          	srli	a0,a0,0x4
   101e8:	00a787b3          	add	a5,a5,a0
   101ec:	00e580a3          	sb	a4,1(a1)
   101f0:	0007c783          	lbu	a5,0(a5)
   101f4:	00f58023          	sb	a5,0(a1)
   101f8:	00008067          	ret

00000000000101fc <print_uart_int>:
   101fc:	fd010113          	addi	sp,sp,-48
   10200:	02813023          	sd	s0,32(sp)
   10204:	00913c23          	sd	s1,24(sp)
   10208:	01213823          	sd	s2,16(sp)
   1020c:	02113423          	sd	ra,40(sp)
   10210:	00050493          	mv	s1,a0
   10214:	01800413          	li	s0,24
   10218:	ff800913          	li	s2,-8
   1021c:	0084d53b          	srlw	a0,s1,s0
   10220:	00810593          	addi	a1,sp,8
   10224:	0ff57513          	andi	a0,a0,255
   10228:	fa9ff0ef          	jal	ra,101d0 <bin_to_hex>
   1022c:	00814503          	lbu	a0,8(sp)
   10230:	ff84041b          	addiw	s0,s0,-8
   10234:	ef1ff0ef          	jal	ra,10124 <write_serial>
   10238:	00914503          	lbu	a0,9(sp)
   1023c:	ee9ff0ef          	jal	ra,10124 <write_serial>
   10240:	fd241ee3          	bne	s0,s2,1021c <print_uart_int+0x20>
   10244:	02813083          	ld	ra,40(sp)
   10248:	02013403          	ld	s0,32(sp)
   1024c:	01813483          	ld	s1,24(sp)
   10250:	01013903          	ld	s2,16(sp)
   10254:	03010113          	addi	sp,sp,48
   10258:	00008067          	ret

000000000001025c <print_uart_addr>:
   1025c:	fd010113          	addi	sp,sp,-48
   10260:	02813023          	sd	s0,32(sp)
   10264:	00913c23          	sd	s1,24(sp)
   10268:	01213823          	sd	s2,16(sp)
   1026c:	02113423          	sd	ra,40(sp)
   10270:	00050493          	mv	s1,a0
   10274:	03800413          	li	s0,56
   10278:	ff800913          	li	s2,-8
   1027c:	0084d533          	srl	a0,s1,s0
   10280:	00810593          	addi	a1,sp,8
   10284:	0ff57513          	andi	a0,a0,255
   10288:	f49ff0ef          	jal	ra,101d0 <bin_to_hex>
   1028c:	00814503          	lbu	a0,8(sp)
   10290:	ff84041b          	addiw	s0,s0,-8
   10294:	e91ff0ef          	jal	ra,10124 <write_serial>
   10298:	00914503          	lbu	a0,9(sp)
   1029c:	e89ff0ef          	jal	ra,10124 <write_serial>
   102a0:	fd241ee3          	bne	s0,s2,1027c <print_uart_addr+0x20>
   102a4:	02813083          	ld	ra,40(sp)
   102a8:	02013403          	ld	s0,32(sp)
   102ac:	01813483          	ld	s1,24(sp)
   102b0:	01013903          	ld	s2,16(sp)
   102b4:	03010113          	addi	sp,sp,48
   102b8:	00008067          	ret

00000000000102bc <print_uart_byte>:
   102bc:	fe010113          	addi	sp,sp,-32
   102c0:	00810593          	addi	a1,sp,8
   102c4:	00113c23          	sd	ra,24(sp)
   102c8:	f09ff0ef          	jal	ra,101d0 <bin_to_hex>
   102cc:	00814503          	lbu	a0,8(sp)
   102d0:	e55ff0ef          	jal	ra,10124 <write_serial>
   102d4:	00914503          	lbu	a0,9(sp)
   102d8:	01813083          	ld	ra,24(sp)
   102dc:	02010113          	addi	sp,sp,32
   102e0:	e45ff06f          	j	10124 <write_serial>

00000000000102e4 <write_reg>:
   102e4:	00b52023          	sw	a1,0(a0)
   102e8:	00008067          	ret

00000000000102ec <read_reg>:
   102ec:	00052503          	lw	a0,0(a0)
   102f0:	00008067          	ret

00000000000102f4 <spi_init>:
   102f4:	00002517          	auipc	a0,0x2
   102f8:	fe010113          	addi	sp,sp,-32
   102fc:	98450513          	addi	a0,a0,-1660 # 11c78 <_BSS_END_+0xc78>
   10300:	00113c23          	sd	ra,24(sp)
   10304:	00813823          	sd	s0,16(sp)
   10308:	00913423          	sd	s1,8(sp)
   1030c:	01213023          	sd	s2,0(sp)
   10310:	e8dff0ef          	jal	ra,1019c <print_uart>
   10314:	200007b7          	lui	a5,0x20000
   10318:	00a00713          	li	a4,10
   1031c:	04e7a023          	sw	a4,64(a5) # 20000040 <_RODATA_END_+0x1ffee0df>
   10320:	00a00793          	li	a5,10
   10324:	00000013          	nop
   10328:	fff7879b          	addiw	a5,a5,-1
   1032c:	fe079ce3          	bnez	a5,10324 <spi_init+0x30>
   10330:	10400793          	li	a5,260
   10334:	20000437          	lui	s0,0x20000
   10338:	06f42023          	sw	a5,96(s0) # 20000060 <_RODATA_END_+0x1ffee0ff>
   1033c:	200004b7          	lui	s1,0x20000
   10340:	0644a903          	lw	s2,100(s1) # 20000064 <_RODATA_END_+0x1ffee103>
   10344:	00002517          	auipc	a0,0x2
   10348:	94450513          	addi	a0,a0,-1724 # 11c88 <_BSS_END_+0xc88>
   1034c:	e51ff0ef          	jal	ra,1019c <print_uart>
   10350:	0009091b          	sext.w	s2,s2
   10354:	02091513          	slli	a0,s2,0x20
   10358:	02055513          	srli	a0,a0,0x20
   1035c:	f01ff0ef          	jal	ra,1025c <print_uart_addr>
   10360:	00002517          	auipc	a0,0x2
   10364:	94850513          	addi	a0,a0,-1720 # 11ca8 <_BSS_END_+0xca8>
   10368:	e35ff0ef          	jal	ra,1019c <print_uart>
   1036c:	16600793          	li	a5,358
   10370:	06f42023          	sw	a5,96(s0)
   10374:	06448493          	addi	s1,s1,100
   10378:	0004a483          	lw	s1,0(s1)
   1037c:	00002517          	auipc	a0,0x2
   10380:	90c50513          	addi	a0,a0,-1780 # 11c88 <_BSS_END_+0xc88>
   10384:	e19ff0ef          	jal	ra,1019c <print_uart>
   10388:	0004849b          	sext.w	s1,s1
   1038c:	02049513          	slli	a0,s1,0x20
   10390:	02055513          	srli	a0,a0,0x20
   10394:	ec9ff0ef          	jal	ra,1025c <print_uart_addr>
   10398:	00002517          	auipc	a0,0x2
   1039c:	91050513          	addi	a0,a0,-1776 # 11ca8 <_BSS_END_+0xca8>
   103a0:	dfdff0ef          	jal	ra,1019c <print_uart>
   103a4:	00600793          	li	a5,6
   103a8:	06f42023          	sw	a5,96(s0)
   103ac:	01013403          	ld	s0,16(sp)
   103b0:	01813083          	ld	ra,24(sp)
   103b4:	00813483          	ld	s1,8(sp)
   103b8:	00013903          	ld	s2,0(sp)
   103bc:	00002517          	auipc	a0,0x2
   103c0:	8dc50513          	addi	a0,a0,-1828 # 11c98 <_BSS_END_+0xc98>
   103c4:	02010113          	addi	sp,sp,32
   103c8:	dd5ff06f          	j	1019c <print_uart>

00000000000103cc <spi_txrx>:
   103cc:	fe010113          	addi	sp,sp,-32
   103d0:	00113c23          	sd	ra,24(sp)
   103d4:	00813823          	sd	s0,16(sp)
   103d8:	00913423          	sd	s1,8(sp)
   103dc:	200007b7          	lui	a5,0x20000
   103e0:	ffe00713          	li	a4,-2
   103e4:	06e7a823          	sw	a4,112(a5) # 20000070 <_RODATA_END_+0x1ffee10f>
   103e8:	200007b7          	lui	a5,0x20000
   103ec:	06a7a423          	sw	a0,104(a5) # 20000068 <_RODATA_END_+0x1ffee107>
   103f0:	06400793          	li	a5,100
   103f4:	00000013          	nop
   103f8:	fff7879b          	addiw	a5,a5,-1
   103fc:	fe079ce3          	bnez	a5,103f4 <spi_txrx+0x28>
   10400:	200007b7          	lui	a5,0x20000
   10404:	10600713          	li	a4,262
   10408:	20000437          	lui	s0,0x20000
   1040c:	06e7a023          	sw	a4,96(a5) # 20000060 <_RODATA_END_+0x1ffee0ff>
   10410:	06440413          	addi	s0,s0,100 # 20000064 <_RODATA_END_+0x1ffee103>
   10414:	00042783          	lw	a5,0(s0)
   10418:	0017f793          	andi	a5,a5,1
   1041c:	fe079ce3          	bnez	a5,10414 <spi_txrx+0x48>
   10420:	200007b7          	lui	a5,0x20000
   10424:	06c7a483          	lw	s1,108(a5) # 2000006c <_RODATA_END_+0x1ffee10b>
   10428:	00042783          	lw	a5,0(s0)
   1042c:	0004849b          	sext.w	s1,s1
   10430:	0017f793          	andi	a5,a5,1
   10434:	02079663          	bnez	a5,10460 <spi_txrx+0x94>
   10438:	00002517          	auipc	a0,0x2
   1043c:	87850513          	addi	a0,a0,-1928 # 11cb0 <_BSS_END_+0xcb0>
   10440:	d5dff0ef          	jal	ra,1019c <print_uart>
   10444:	00042503          	lw	a0,0(s0)
   10448:	02051513          	slli	a0,a0,0x20
   1044c:	02055513          	srli	a0,a0,0x20
   10450:	e0dff0ef          	jal	ra,1025c <print_uart_addr>
   10454:	00002517          	auipc	a0,0x2
   10458:	85450513          	addi	a0,a0,-1964 # 11ca8 <_BSS_END_+0xca8>
   1045c:	d41ff0ef          	jal	ra,1019c <print_uart>
   10460:	01813083          	ld	ra,24(sp)
   10464:	01013403          	ld	s0,16(sp)
   10468:	200007b7          	lui	a5,0x20000
   1046c:	fff00713          	li	a4,-1
   10470:	06e7a823          	sw	a4,112(a5) # 20000070 <_RODATA_END_+0x1ffee10f>
   10474:	200007b7          	lui	a5,0x20000
   10478:	00600713          	li	a4,6
   1047c:	06e7a023          	sw	a4,96(a5) # 20000060 <_RODATA_END_+0x1ffee0ff>
   10480:	0ff4f513          	andi	a0,s1,255
   10484:	00813483          	ld	s1,8(sp)
   10488:	02010113          	addi	sp,sp,32
   1048c:	00008067          	ret

0000000000010490 <spi_write_bytes>:
   10490:	10000793          	li	a5,256
   10494:	0ab7ee63          	bltu	a5,a1,10550 <spi_write_bytes+0xc0>
   10498:	200007b7          	lui	a5,0x20000
   1049c:	ffe00713          	li	a4,-2
   104a0:	06e7a823          	sw	a4,112(a5) # 20000070 <_RODATA_END_+0x1ffee10f>
   104a4:	20000737          	lui	a4,0x20000
   104a8:	00000793          	li	a5,0
   104ac:	06870713          	addi	a4,a4,104 # 20000068 <_RODATA_END_+0x1ffee107>
   104b0:	0007869b          	sext.w	a3,a5
   104b4:	06b6e263          	bltu	a3,a1,10518 <spi_write_bytes+0x88>
   104b8:	03200793          	li	a5,50
   104bc:	00000013          	nop
   104c0:	fff7879b          	addiw	a5,a5,-1
   104c4:	fe079ce3          	bnez	a5,104bc <spi_write_bytes+0x2c>
   104c8:	10600713          	li	a4,262
   104cc:	200007b7          	lui	a5,0x20000
   104d0:	06e7a023          	sw	a4,96(a5) # 20000060 <_RODATA_END_+0x1ffee0ff>
   104d4:	20000737          	lui	a4,0x20000
   104d8:	06470713          	addi	a4,a4,100 # 20000064 <_RODATA_END_+0x1ffee103>
   104dc:	00072783          	lw	a5,0(a4)
   104e0:	0017f793          	andi	a5,a5,1
   104e4:	fe079ce3          	bnez	a5,104dc <spi_write_bytes+0x4c>
   104e8:	20000737          	lui	a4,0x20000
   104ec:	06470713          	addi	a4,a4,100 # 20000064 <_RODATA_END_+0x1ffee103>
   104f0:	0007851b          	sext.w	a0,a5
   104f4:	02b56c63          	bltu	a0,a1,1052c <spi_write_bytes+0x9c>
   104f8:	200007b7          	lui	a5,0x20000
   104fc:	fff00713          	li	a4,-1
   10500:	06e7a823          	sw	a4,112(a5) # 20000070 <_RODATA_END_+0x1ffee10f>
   10504:	200007b7          	lui	a5,0x20000
   10508:	00600713          	li	a4,6
   1050c:	06e7a023          	sw	a4,96(a5) # 20000060 <_RODATA_END_+0x1ffee0ff>
   10510:	00000513          	li	a0,0
   10514:	00008067          	ret
   10518:	00f506b3          	add	a3,a0,a5
   1051c:	0006c683          	lbu	a3,0(a3)
   10520:	00178793          	addi	a5,a5,1
   10524:	00d72023          	sw	a3,0(a4)
   10528:	f89ff06f          	j	104b0 <spi_write_bytes+0x20>
   1052c:	00072683          	lw	a3,0(a4)
   10530:	0016f693          	andi	a3,a3,1
   10534:	fc0690e3          	bnez	a3,104f4 <spi_write_bytes+0x64>
   10538:	200006b7          	lui	a3,0x20000
   1053c:	06c6a503          	lw	a0,108(a3) # 2000006c <_RODATA_END_+0x1ffee10b>
   10540:	00f606b3          	add	a3,a2,a5
   10544:	00178793          	addi	a5,a5,1
   10548:	00a68023          	sb	a0,0(a3)
   1054c:	fa5ff06f          	j	104f0 <spi_write_bytes+0x60>
   10550:	fff00513          	li	a0,-1
   10554:	00008067          	ret

0000000000010558 <sd_dummy>:
   10558:	0ff00513          	li	a0,255
   1055c:	e71ff06f          	j	103cc <spi_txrx>

0000000000010560 <sd_cmd>:
   10560:	fe010113          	addi	sp,sp,-32
   10564:	00113c23          	sd	ra,24(sp)
   10568:	00813823          	sd	s0,16(sp)
   1056c:	00913423          	sd	s1,8(sp)
   10570:	00058413          	mv	s0,a1
   10574:	00060493          	mv	s1,a2
   10578:	01213023          	sd	s2,0(sp)
   1057c:	00050913          	mv	s2,a0
   10580:	fd9ff0ef          	jal	ra,10558 <sd_dummy>
   10584:	04096513          	ori	a0,s2,64
   10588:	e45ff0ef          	jal	ra,103cc <spi_txrx>
   1058c:	0184551b          	srliw	a0,s0,0x18
   10590:	e3dff0ef          	jal	ra,103cc <spi_txrx>
   10594:	0104551b          	srliw	a0,s0,0x10
   10598:	0ff57513          	andi	a0,a0,255
   1059c:	e31ff0ef          	jal	ra,103cc <spi_txrx>
   105a0:	0084551b          	srliw	a0,s0,0x8
   105a4:	0ff57513          	andi	a0,a0,255
   105a8:	e25ff0ef          	jal	ra,103cc <spi_txrx>
   105ac:	0ff47513          	andi	a0,s0,255
   105b0:	e1dff0ef          	jal	ra,103cc <spi_txrx>
   105b4:	00048513          	mv	a0,s1
   105b8:	e15ff0ef          	jal	ra,103cc <spi_txrx>
   105bc:	06400413          	li	s0,100
   105c0:	f99ff0ef          	jal	ra,10558 <sd_dummy>
   105c4:	0185179b          	slliw	a5,a0,0x18
   105c8:	4187d79b          	sraiw	a5,a5,0x18
   105cc:	0007d663          	bgez	a5,105d8 <sd_cmd+0x78>
   105d0:	fff40413          	addi	s0,s0,-1
   105d4:	fe0416e3          	bnez	s0,105c0 <sd_cmd+0x60>
   105d8:	01813083          	ld	ra,24(sp)
   105dc:	01013403          	ld	s0,16(sp)
   105e0:	00813483          	ld	s1,8(sp)
   105e4:	00013903          	ld	s2,0(sp)
   105e8:	02010113          	addi	sp,sp,32
   105ec:	00008067          	ret

00000000000105f0 <print_status>:
   105f0:	fe010113          	addi	sp,sp,-32
   105f4:	00913423          	sd	s1,8(sp)
   105f8:	00050493          	mv	s1,a0
   105fc:	00001517          	auipc	a0,0x1
   10600:	6cc50513          	addi	a0,a0,1740 # 11cc8 <_BSS_END_+0xcc8>
   10604:	00113c23          	sd	ra,24(sp)
   10608:	00813823          	sd	s0,16(sp)
   1060c:	00058413          	mv	s0,a1
   10610:	b8dff0ef          	jal	ra,1019c <print_uart>
   10614:	00048513          	mv	a0,s1
   10618:	b85ff0ef          	jal	ra,1019c <print_uart>
   1061c:	00001517          	auipc	a0,0x1
   10620:	6bc50513          	addi	a0,a0,1724 # 11cd8 <_BSS_END_+0xcd8>
   10624:	b79ff0ef          	jal	ra,1019c <print_uart>
   10628:	00040513          	mv	a0,s0
   1062c:	c91ff0ef          	jal	ra,102bc <print_uart_byte>
   10630:	01013403          	ld	s0,16(sp)
   10634:	01813083          	ld	ra,24(sp)
   10638:	00813483          	ld	s1,8(sp)
   1063c:	00001517          	auipc	a0,0x1
   10640:	66c50513          	addi	a0,a0,1644 # 11ca8 <_BSS_END_+0xca8>
   10644:	02010113          	addi	sp,sp,32
   10648:	b55ff06f          	j	1019c <print_uart>

000000000001064c <sd_cmd0>:
   1064c:	fe010113          	addi	sp,sp,-32
   10650:	00813823          	sd	s0,16(sp)
   10654:	00002437          	lui	s0,0x2
   10658:	01213023          	sd	s2,0(sp)
   1065c:	00113c23          	sd	ra,24(sp)
   10660:	00913423          	sd	s1,8(sp)
   10664:	71040413          	addi	s0,s0,1808 # 2710 <ROM_BASE-0xd8f0>
   10668:	00100913          	li	s2,1
   1066c:	09500613          	li	a2,149
   10670:	00000593          	li	a1,0
   10674:	00000513          	li	a0,0
   10678:	ee9ff0ef          	jal	ra,10560 <sd_cmd>
   1067c:	fff4041b          	addiw	s0,s0,-1
   10680:	00050493          	mv	s1,a0
   10684:	ed5ff0ef          	jal	ra,10558 <sd_dummy>
   10688:	02040a63          	beqz	s0,106bc <sd_cmd0+0x70>
   1068c:	ff2490e3          	bne	s1,s2,1066c <sd_cmd0+0x20>
   10690:	00001517          	auipc	a0,0x1
   10694:	65850513          	addi	a0,a0,1624 # 11ce8 <_BSS_END_+0xce8>
   10698:	00100593          	li	a1,1
   1069c:	f55ff0ef          	jal	ra,105f0 <print_status>
   106a0:	00100513          	li	a0,1
   106a4:	01813083          	ld	ra,24(sp)
   106a8:	01013403          	ld	s0,16(sp)
   106ac:	00813483          	ld	s1,8(sp)
   106b0:	00013903          	ld	s2,0(sp)
   106b4:	02010113          	addi	sp,sp,32
   106b8:	00008067          	ret
   106bc:	00000513          	li	a0,0
   106c0:	fe5ff06f          	j	106a4 <sd_cmd0+0x58>

00000000000106c4 <sd_cmd8>:
   106c4:	fe010113          	addi	sp,sp,-32
   106c8:	08700613          	li	a2,135
   106cc:	1aa00593          	li	a1,426
   106d0:	00800513          	li	a0,8
   106d4:	00113c23          	sd	ra,24(sp)
   106d8:	00813823          	sd	s0,16(sp)
   106dc:	00913423          	sd	s1,8(sp)
   106e0:	01213023          	sd	s2,0(sp)
   106e4:	e7dff0ef          	jal	ra,10560 <sd_cmd>
   106e8:	00050913          	mv	s2,a0
   106ec:	e6dff0ef          	jal	ra,10558 <sd_dummy>
   106f0:	e69ff0ef          	jal	ra,10558 <sd_dummy>
   106f4:	e65ff0ef          	jal	ra,10558 <sd_dummy>
   106f8:	00050493          	mv	s1,a0
   106fc:	e5dff0ef          	jal	ra,10558 <sd_dummy>
   10700:	00050413          	mv	s0,a0
   10704:	e55ff0ef          	jal	ra,10558 <sd_dummy>
   10708:	e51ff0ef          	jal	ra,10558 <sd_dummy>
   1070c:	00100793          	li	a5,1
   10710:	00000513          	li	a0,0
   10714:	00f91c63          	bne	s2,a5,1072c <sd_cmd8+0x68>
   10718:	00f4f493          	andi	s1,s1,15
   1071c:	01249863          	bne	s1,s2,1072c <sd_cmd8+0x68>
   10720:	0004041b          	sext.w	s0,s0
   10724:	f5640413          	addi	s0,s0,-170
   10728:	00143513          	seqz	a0,s0
   1072c:	01813083          	ld	ra,24(sp)
   10730:	01013403          	ld	s0,16(sp)
   10734:	00813483          	ld	s1,8(sp)
   10738:	00013903          	ld	s2,0(sp)
   1073c:	02010113          	addi	sp,sp,32
   10740:	00008067          	ret

0000000000010744 <sd_cmd55>:
   10744:	ff010113          	addi	sp,sp,-16
   10748:	06500613          	li	a2,101
   1074c:	00000593          	li	a1,0
   10750:	03700513          	li	a0,55
   10754:	00113423          	sd	ra,8(sp)
   10758:	00813023          	sd	s0,0(sp)
   1075c:	e05ff0ef          	jal	ra,10560 <sd_cmd>
   10760:	00050413          	mv	s0,a0
   10764:	df5ff0ef          	jal	ra,10558 <sd_dummy>
   10768:	00001517          	auipc	a0,0x1
   1076c:	00040593          	mv	a1,s0
   10770:	58850513          	addi	a0,a0,1416 # 11cf0 <_BSS_END_+0xcf0>
   10774:	e7dff0ef          	jal	ra,105f0 <print_status>
   10778:	00813083          	ld	ra,8(sp)
   1077c:	0004051b          	sext.w	a0,s0
   10780:	00013403          	ld	s0,0(sp)
   10784:	fff50513          	addi	a0,a0,-1
   10788:	00153513          	seqz	a0,a0
   1078c:	01010113          	addi	sp,sp,16
   10790:	00008067          	ret

0000000000010794 <sd_acmd41>:
   10794:	fe010113          	addi	sp,sp,-32
   10798:	00913423          	sd	s1,8(sp)
   1079c:	00113c23          	sd	ra,24(sp)
   107a0:	00813823          	sd	s0,16(sp)
   107a4:	00100493          	li	s1,1
   107a8:	f9dff0ef          	jal	ra,10744 <sd_cmd55>
   107ac:	07700613          	li	a2,119
   107b0:	400005b7          	lui	a1,0x40000
   107b4:	02900513          	li	a0,41
   107b8:	da9ff0ef          	jal	ra,10560 <sd_cmd>
   107bc:	00050413          	mv	s0,a0
   107c0:	00050593          	mv	a1,a0
   107c4:	00001517          	auipc	a0,0x1
   107c8:	53450513          	addi	a0,a0,1332 # 11cf8 <_BSS_END_+0xcf8>
   107cc:	e25ff0ef          	jal	ra,105f0 <print_status>
   107d0:	d89ff0ef          	jal	ra,10558 <sd_dummy>
   107d4:	fc940ae3          	beq	s0,s1,107a8 <sd_acmd41+0x14>
   107d8:	01813083          	ld	ra,24(sp)
   107dc:	0004051b          	sext.w	a0,s0
   107e0:	01013403          	ld	s0,16(sp)
   107e4:	00813483          	ld	s1,8(sp)
   107e8:	00153513          	seqz	a0,a0
   107ec:	02010113          	addi	sp,sp,32
   107f0:	00008067          	ret

00000000000107f4 <init_sd>:
   107f4:	ff010113          	addi	sp,sp,-16
   107f8:	00113423          	sd	ra,8(sp)
   107fc:	00813023          	sd	s0,0(sp)
   10800:	af5ff0ef          	jal	ra,102f4 <spi_init>
   10804:	00001517          	auipc	a0,0x1
   10808:	4fc50513          	addi	a0,a0,1276 # 11d00 <_BSS_END_+0xd00>
   1080c:	991ff0ef          	jal	ra,1019c <print_uart>
   10810:	00a00413          	li	s0,10
   10814:	fff4041b          	addiw	s0,s0,-1
   10818:	d41ff0ef          	jal	ra,10558 <sd_dummy>
   1081c:	fe041ce3          	bnez	s0,10814 <init_sd+0x20>
   10820:	e2dff0ef          	jal	ra,1064c <sd_cmd0>
   10824:	fff00793          	li	a5,-1
   10828:	02050063          	beqz	a0,10848 <init_sd+0x54>
   1082c:	e99ff0ef          	jal	ra,106c4 <sd_cmd8>
   10830:	ffe00793          	li	a5,-2
   10834:	00050a63          	beqz	a0,10848 <init_sd+0x54>
   10838:	f5dff0ef          	jal	ra,10794 <sd_acmd41>
   1083c:	ffd00793          	li	a5,-3
   10840:	00050463          	beqz	a0,10848 <init_sd+0x54>
   10844:	00000793          	li	a5,0
   10848:	00813083          	ld	ra,8(sp)
   1084c:	00013403          	ld	s0,0(sp)
   10850:	00078513          	mv	a0,a5
   10854:	01010113          	addi	sp,sp,16
   10858:	00008067          	ret

000000000001085c <crc7>:
   1085c:	00b575b3          	and	a1,a0,a1
   10860:	0075d79b          	srliw	a5,a1,0x7
   10864:	0045d51b          	srliw	a0,a1,0x4
   10868:	00f54533          	xor	a0,a0,a5
   1086c:	0ff57513          	andi	a0,a0,255
   10870:	00b54533          	xor	a0,a0,a1
   10874:	0045179b          	slliw	a5,a0,0x4
   10878:	0ff7f793          	andi	a5,a5,255
   1087c:	00f54533          	xor	a0,a0,a5
   10880:	07f57513          	andi	a0,a0,127
   10884:	00008067          	ret

0000000000010888 <crc16>:
   10888:	0085179b          	slliw	a5,a0,0x8
   1088c:	0085551b          	srliw	a0,a0,0x8
   10890:	00a7e7b3          	or	a5,a5,a0
   10894:	03079793          	slli	a5,a5,0x30
   10898:	0307d793          	srli	a5,a5,0x30
   1089c:	00f5c5b3          	xor	a1,a1,a5
   108a0:	0045d79b          	srliw	a5,a1,0x4
   108a4:	00f7f793          	andi	a5,a5,15
   108a8:	00f5c533          	xor	a0,a1,a5
   108ac:	0105151b          	slliw	a0,a0,0x10
   108b0:	4105551b          	sraiw	a0,a0,0x10
   108b4:	00c5179b          	slliw	a5,a0,0xc
   108b8:	00f54533          	xor	a0,a0,a5
   108bc:	0105151b          	slliw	a0,a0,0x10
   108c0:	4105551b          	sraiw	a0,a0,0x10
   108c4:	000027b7          	lui	a5,0x2
   108c8:	0055171b          	slliw	a4,a0,0x5
   108cc:	fe078793          	addi	a5,a5,-32 # 1fe0 <ROM_BASE-0xe020>
   108d0:	00e7f7b3          	and	a5,a5,a4
   108d4:	00f54533          	xor	a0,a0,a5
   108d8:	03051513          	slli	a0,a0,0x30
   108dc:	03055513          	srli	a0,a0,0x30
   108e0:	00008067          	ret

00000000000108e4 <sd_copy>:
   108e4:	f3010113          	addi	sp,sp,-208
   108e8:	0b213823          	sd	s2,176(sp)
   108ec:	02061913          	slli	s2,a2,0x20
   108f0:	0c813023          	sd	s0,192(sp)
   108f4:	0a913c23          	sd	s1,184(sp)
   108f8:	0c113423          	sd	ra,200(sp)
   108fc:	0b313423          	sd	s3,168(sp)
   10900:	0b413023          	sd	s4,160(sp)
   10904:	09513c23          	sd	s5,152(sp)
   10908:	09613823          	sd	s6,144(sp)
   1090c:	09713423          	sd	s7,136(sp)
   10910:	00050493          	mv	s1,a0
   10914:	00058413          	mv	s0,a1
   10918:	02095913          	srli	s2,s2,0x20
   1091c:	00000793          	li	a5,0
   10920:	fff00613          	li	a2,-1
   10924:	08000713          	li	a4,128
   10928:	00f106b3          	add	a3,sp,a5
   1092c:	00c68023          	sb	a2,0(a3)
   10930:	00178793          	addi	a5,a5,1
   10934:	fee79ae3          	bne	a5,a4,10928 <sd_copy+0x44>
   10938:	0184559b          	srliw	a1,s0,0x18
   1093c:	00000513          	li	a0,0
   10940:	f1dff0ef          	jal	ra,1085c <crc7>
   10944:	0104559b          	srliw	a1,s0,0x10
   10948:	0ff5f593          	andi	a1,a1,255
   1094c:	f11ff0ef          	jal	ra,1085c <crc7>
   10950:	0084559b          	srliw	a1,s0,0x8
   10954:	0ff5f593          	andi	a1,a1,255
   10958:	f05ff0ef          	jal	ra,1085c <crc7>
   1095c:	0ff47593          	andi	a1,s0,255
   10960:	efdff0ef          	jal	ra,1085c <crc7>
   10964:	0015161b          	slliw	a2,a0,0x1
   10968:	00166613          	ori	a2,a2,1
   1096c:	0ff67613          	andi	a2,a2,255
   10970:	00040593          	mv	a1,s0
   10974:	01200513          	li	a0,18
   10978:	be9ff0ef          	jal	ra,10560 <sd_cmd>
   1097c:	0a051c63          	bnez	a0,10a34 <sd_copy+0x150>
   10980:	0fe00a13          	li	s4,254
   10984:	3e800a93          	li	s5,1000
   10988:	bd1ff0ef          	jal	ra,10558 <sd_dummy>
   1098c:	ff451ee3          	bne	a0,s4,10988 <sd_copy+0xa4>
   10990:	00000413          	li	s0,0
   10994:	20048b13          	addi	s6,s1,512
   10998:	00048613          	mv	a2,s1
   1099c:	04000593          	li	a1,64
   109a0:	00010513          	mv	a0,sp
   109a4:	aedff0ef          	jal	ra,10490 <spi_write_bytes>
   109a8:	00000993          	li	s3,0
   109ac:	04000b93          	li	s7,64
   109b0:	013487b3          	add	a5,s1,s3
   109b4:	0007c583          	lbu	a1,0(a5)
   109b8:	00040513          	mv	a0,s0
   109bc:	00198993          	addi	s3,s3,1
   109c0:	ec9ff0ef          	jal	ra,10888 <crc16>
   109c4:	00050413          	mv	s0,a0
   109c8:	ff7994e3          	bne	s3,s7,109b0 <sd_copy+0xcc>
   109cc:	04048493          	addi	s1,s1,64
   109d0:	fd6494e3          	bne	s1,s6,10998 <sd_copy+0xb4>
   109d4:	b85ff0ef          	jal	ra,10558 <sd_dummy>
   109d8:	0085199b          	slliw	s3,a0,0x8
   109dc:	03099993          	slli	s3,s3,0x30
   109e0:	0309d993          	srli	s3,s3,0x30
   109e4:	b75ff0ef          	jal	ra,10558 <sd_dummy>
   109e8:	01356533          	or	a0,a0,s3
   109ec:	03051513          	slli	a0,a0,0x30
   109f0:	03055513          	srli	a0,a0,0x30
   109f4:	0004041b          	sext.w	s0,s0
   109f8:	08851e63          	bne	a0,s0,10a94 <sd_copy+0x1b0>
   109fc:	035967b3          	rem	a5,s2,s5
   10a00:	00079863          	bnez	a5,10a10 <sd_copy+0x12c>
   10a04:	00001517          	auipc	a0,0x1
   10a08:	33450513          	addi	a0,a0,820 # 11d38 <_BSS_END_+0xd38>
   10a0c:	f90ff0ef          	jal	ra,1019c <print_uart>
   10a10:	fff90913          	addi	s2,s2,-1 # 1ffffff <_RODATA_END_+0x1fee09e>
   10a14:	f7204ae3          	bgtz	s2,10988 <sd_copy+0xa4>
   10a18:	00000413          	li	s0,0
   10a1c:	00100613          	li	a2,1
   10a20:	00000593          	li	a1,0
   10a24:	00c00513          	li	a0,12
   10a28:	b39ff0ef          	jal	ra,10560 <sd_cmd>
   10a2c:	b2dff0ef          	jal	ra,10558 <sd_dummy>
   10a30:	0340006f          	j	10a64 <sd_copy+0x180>
   10a34:	b25ff0ef          	jal	ra,10558 <sd_dummy>
   10a38:	b21ff0ef          	jal	ra,10558 <sd_dummy>
   10a3c:	b1dff0ef          	jal	ra,10558 <sd_dummy>
   10a40:	b19ff0ef          	jal	ra,10558 <sd_dummy>
   10a44:	b15ff0ef          	jal	ra,10558 <sd_dummy>
   10a48:	b11ff0ef          	jal	ra,10558 <sd_dummy>
   10a4c:	b0dff0ef          	jal	ra,10558 <sd_dummy>
   10a50:	b09ff0ef          	jal	ra,10558 <sd_dummy>
   10a54:	00001517          	auipc	a0,0x1
   10a58:	2c450513          	addi	a0,a0,708 # 11d18 <_BSS_END_+0xd18>
   10a5c:	f40ff0ef          	jal	ra,1019c <print_uart>
   10a60:	fff00413          	li	s0,-1
   10a64:	0c813083          	ld	ra,200(sp)
   10a68:	00040513          	mv	a0,s0
   10a6c:	0c013403          	ld	s0,192(sp)
   10a70:	0b813483          	ld	s1,184(sp)
   10a74:	0b013903          	ld	s2,176(sp)
   10a78:	0a813983          	ld	s3,168(sp)
   10a7c:	0a013a03          	ld	s4,160(sp)
   10a80:	09813a83          	ld	s5,152(sp)
   10a84:	09013b03          	ld	s6,144(sp)
   10a88:	08813b83          	ld	s7,136(sp)
   10a8c:	0d010113          	addi	sp,sp,208
   10a90:	00008067          	ret
   10a94:	ffe00413          	li	s0,-2
   10a98:	f85ff06f          	j	10a1c <sd_copy+0x138>

0000000000010a9c <gpt_find_boot_partition>:
   10a9c:	fa010113          	addi	sp,sp,-96
   10aa0:	04813823          	sd	s0,80(sp)
   10aa4:	03413823          	sd	s4,48(sp)
   10aa8:	03513423          	sd	s5,40(sp)
   10aac:	04113c23          	sd	ra,88(sp)
   10ab0:	04913423          	sd	s1,72(sp)
   10ab4:	05213023          	sd	s2,64(sp)
   10ab8:	03313c23          	sd	s3,56(sp)
   10abc:	03613023          	sd	s6,32(sp)
   10ac0:	01713c23          	sd	s7,24(sp)
   10ac4:	01813823          	sd	s8,16(sp)
   10ac8:	01913423          	sd	s9,8(sp)
   10acc:	06010413          	addi	s0,sp,96
   10ad0:	00050a13          	mv	s4,a0
   10ad4:	00058a93          	mv	s5,a1
   10ad8:	d1dff0ef          	jal	ra,107f4 <init_sd>
   10adc:	04050863          	beqz	a0,10b2c <gpt_find_boot_partition+0x90>
   10ae0:	00001517          	auipc	a0,0x1
   10ae4:	26050513          	addi	a0,a0,608 # 11d40 <_BSS_END_+0xd40>
   10ae8:	eb4ff0ef          	jal	ra,1019c <print_uart>
   10aec:	fff00493          	li	s1,-1
   10af0:	fa040113          	addi	sp,s0,-96
   10af4:	05813083          	ld	ra,88(sp)
   10af8:	00048513          	mv	a0,s1
   10afc:	05013403          	ld	s0,80(sp)
   10b00:	04813483          	ld	s1,72(sp)
   10b04:	04013903          	ld	s2,64(sp)
   10b08:	03813983          	ld	s3,56(sp)
   10b0c:	03013a03          	ld	s4,48(sp)
   10b10:	02813a83          	ld	s5,40(sp)
   10b14:	02013b03          	ld	s6,32(sp)
   10b18:	01813b83          	ld	s7,24(sp)
   10b1c:	01013c03          	ld	s8,16(sp)
   10b20:	00813c83          	ld	s9,8(sp)
   10b24:	06010113          	addi	sp,sp,96
   10b28:	00008067          	ret
   10b2c:	00001517          	auipc	a0,0x1
   10b30:	23c50513          	addi	a0,a0,572 # 11d68 <_BSS_END_+0xd68>
   10b34:	e68ff0ef          	jal	ra,1019c <print_uart>
   10b38:	e0010113          	addi	sp,sp,-512
   10b3c:	00100613          	li	a2,1
   10b40:	00100593          	li	a1,1
   10b44:	00010513          	mv	a0,sp
   10b48:	d9dff0ef          	jal	ra,108e4 <sd_copy>
   10b4c:	00010913          	mv	s2,sp
   10b50:	00050493          	mv	s1,a0
   10b54:	02050c63          	beqz	a0,10b8c <gpt_find_boot_partition+0xf0>
   10b58:	00001517          	auipc	a0,0x1
   10b5c:	22850513          	addi	a0,a0,552 # 11d80 <_BSS_END_+0xd80>
   10b60:	e3cff0ef          	jal	ra,1019c <print_uart>
   10b64:	00001517          	auipc	a0,0x1
   10b68:	23450513          	addi	a0,a0,564 # 11d98 <_BSS_END_+0xd98>
   10b6c:	e30ff0ef          	jal	ra,1019c <print_uart>
   10b70:	00048513          	mv	a0,s1
   10b74:	ee8ff0ef          	jal	ra,1025c <print_uart_addr>
   10b78:	00001517          	auipc	a0,0x1
   10b7c:	13050513          	addi	a0,a0,304 # 11ca8 <_BSS_END_+0xca8>
   10b80:	e1cff0ef          	jal	ra,1019c <print_uart>
   10b84:	ffe00493          	li	s1,-2
   10b88:	f69ff06f          	j	10af0 <gpt_find_boot_partition+0x54>
   10b8c:	00001517          	auipc	a0,0x1
   10b90:	22450513          	addi	a0,a0,548 # 11db0 <_BSS_END_+0xdb0>
   10b94:	e08ff0ef          	jal	ra,1019c <print_uart>
   10b98:	00001517          	auipc	a0,0x1
   10b9c:	23850513          	addi	a0,a0,568 # 11dd0 <_BSS_END_+0xdd0>
   10ba0:	dfcff0ef          	jal	ra,1019c <print_uart>
   10ba4:	00013503          	ld	a0,0(sp)
   10ba8:	eb4ff0ef          	jal	ra,1025c <print_uart_addr>
   10bac:	00001517          	auipc	a0,0x1
   10bb0:	23450513          	addi	a0,a0,564 # 11de0 <_BSS_END_+0xde0>
   10bb4:	de8ff0ef          	jal	ra,1019c <print_uart>
   10bb8:	00812503          	lw	a0,8(sp)
   10bbc:	e40ff0ef          	jal	ra,101fc <print_uart_int>
   10bc0:	00001517          	auipc	a0,0x1
   10bc4:	23050513          	addi	a0,a0,560 # 11df0 <_BSS_END_+0xdf0>
   10bc8:	dd4ff0ef          	jal	ra,1019c <print_uart>
   10bcc:	00c12503          	lw	a0,12(sp)
   10bd0:	e2cff0ef          	jal	ra,101fc <print_uart_int>
   10bd4:	00001517          	auipc	a0,0x1
   10bd8:	22c50513          	addi	a0,a0,556 # 11e00 <_BSS_END_+0xe00>
   10bdc:	dc0ff0ef          	jal	ra,1019c <print_uart>
   10be0:	01012503          	lw	a0,16(sp)
   10be4:	e18ff0ef          	jal	ra,101fc <print_uart_int>
   10be8:	00001517          	auipc	a0,0x1
   10bec:	22850513          	addi	a0,a0,552 # 11e10 <_BSS_END_+0xe10>
   10bf0:	dacff0ef          	jal	ra,1019c <print_uart>
   10bf4:	01412503          	lw	a0,20(sp)
   10bf8:	e04ff0ef          	jal	ra,101fc <print_uart_int>
   10bfc:	00001517          	auipc	a0,0x1
   10c00:	22450513          	addi	a0,a0,548 # 11e20 <_BSS_END_+0xe20>
   10c04:	d98ff0ef          	jal	ra,1019c <print_uart>
   10c08:	01813503          	ld	a0,24(sp)
   10c0c:	e50ff0ef          	jal	ra,1025c <print_uart_addr>
   10c10:	00001517          	auipc	a0,0x1
   10c14:	22850513          	addi	a0,a0,552 # 11e38 <_BSS_END_+0xe38>
   10c18:	d84ff0ef          	jal	ra,1019c <print_uart>
   10c1c:	02013503          	ld	a0,32(sp)
   10c20:	e3cff0ef          	jal	ra,1025c <print_uart_addr>
   10c24:	00001517          	auipc	a0,0x1
   10c28:	22450513          	addi	a0,a0,548 # 11e48 <_BSS_END_+0xe48>
   10c2c:	d70ff0ef          	jal	ra,1019c <print_uart>
   10c30:	04813503          	ld	a0,72(sp)
   10c34:	e28ff0ef          	jal	ra,1025c <print_uart_addr>
   10c38:	00001517          	auipc	a0,0x1
   10c3c:	23050513          	addi	a0,a0,560 # 11e68 <_BSS_END_+0xe68>
   10c40:	d5cff0ef          	jal	ra,1019c <print_uart>
   10c44:	05012503          	lw	a0,80(sp)
   10c48:	db4ff0ef          	jal	ra,101fc <print_uart_int>
   10c4c:	00001517          	auipc	a0,0x1
   10c50:	23c50513          	addi	a0,a0,572 # 11e88 <_BSS_END_+0xe88>
   10c54:	d48ff0ef          	jal	ra,1019c <print_uart>
   10c58:	05412503          	lw	a0,84(sp)
   10c5c:	da0ff0ef          	jal	ra,101fc <print_uart_int>
   10c60:	00001517          	auipc	a0,0x1
   10c64:	04850513          	addi	a0,a0,72 # 11ca8 <_BSS_END_+0xca8>
   10c68:	d34ff0ef          	jal	ra,1019c <print_uart>
   10c6c:	04892583          	lw	a1,72(s2)
   10c70:	e0010113          	addi	sp,sp,-512
   10c74:	00100613          	li	a2,1
   10c78:	00010513          	mv	a0,sp
   10c7c:	c69ff0ef          	jal	ra,108e4 <sd_copy>
   10c80:	00010b13          	mv	s6,sp
   10c84:	00050913          	mv	s2,a0
   10c88:	02010493          	addi	s1,sp,32
   10c8c:	12051863          	bnez	a0,10dbc <gpt_find_boot_partition+0x320>
   10c90:	01000c13          	li	s8,16
   10c94:	00400b93          	li	s7,4
   10c98:	00001517          	auipc	a0,0x1
   10c9c:	21050513          	addi	a0,a0,528 # 11ea8 <_BSS_END_+0xea8>
   10ca0:	cfcff0ef          	jal	ra,1019c <print_uart>
   10ca4:	0ff97513          	andi	a0,s2,255
   10ca8:	e14ff0ef          	jal	ra,102bc <print_uart_byte>
   10cac:	00001517          	auipc	a0,0x1
   10cb0:	21450513          	addi	a0,a0,532 # 11ec0 <_BSS_END_+0xec0>
   10cb4:	fe048c93          	addi	s9,s1,-32
   10cb8:	ce4ff0ef          	jal	ra,1019c <print_uart>
   10cbc:	00000993          	li	s3,0
   10cc0:	013c87b3          	add	a5,s9,s3
   10cc4:	0007c503          	lbu	a0,0(a5)
   10cc8:	00198993          	addi	s3,s3,1
   10ccc:	df0ff0ef          	jal	ra,102bc <print_uart_byte>
   10cd0:	ff8998e3          	bne	s3,s8,10cc0 <gpt_find_boot_partition+0x224>
   10cd4:	00001517          	auipc	a0,0x1
   10cd8:	20c50513          	addi	a0,a0,524 # 11ee0 <_BSS_END_+0xee0>
   10cdc:	cc0ff0ef          	jal	ra,1019c <print_uart>
   10ce0:	ff048993          	addi	s3,s1,-16
   10ce4:	0009c503          	lbu	a0,0(s3)
   10ce8:	00198993          	addi	s3,s3,1
   10cec:	dd0ff0ef          	jal	ra,102bc <print_uart_byte>
   10cf0:	fe999ae3          	bne	s3,s1,10ce4 <gpt_find_boot_partition+0x248>
   10cf4:	00001517          	auipc	a0,0x1
   10cf8:	20c50513          	addi	a0,a0,524 # 11f00 <_BSS_END_+0xf00>
   10cfc:	ca0ff0ef          	jal	ra,1019c <print_uart>
   10d00:	0004b503          	ld	a0,0(s1)
   10d04:	01848993          	addi	s3,s1,24
   10d08:	06048c93          	addi	s9,s1,96
   10d0c:	d50ff0ef          	jal	ra,1025c <print_uart_addr>
   10d10:	00001517          	auipc	a0,0x1
   10d14:	20050513          	addi	a0,a0,512 # 11f10 <_BSS_END_+0xf10>
   10d18:	c84ff0ef          	jal	ra,1019c <print_uart>
   10d1c:	0084b503          	ld	a0,8(s1)
   10d20:	d3cff0ef          	jal	ra,1025c <print_uart_addr>
   10d24:	00001517          	auipc	a0,0x1
   10d28:	1fc50513          	addi	a0,a0,508 # 11f20 <_BSS_END_+0xf20>
   10d2c:	c70ff0ef          	jal	ra,1019c <print_uart>
   10d30:	0104b503          	ld	a0,16(s1)
   10d34:	d28ff0ef          	jal	ra,1025c <print_uart_addr>
   10d38:	00001517          	auipc	a0,0x1
   10d3c:	1f850513          	addi	a0,a0,504 # 11f30 <_BSS_END_+0xf30>
   10d40:	c5cff0ef          	jal	ra,1019c <print_uart>
   10d44:	0009c503          	lbu	a0,0(s3)
   10d48:	00198993          	addi	s3,s3,1
   10d4c:	d70ff0ef          	jal	ra,102bc <print_uart_byte>
   10d50:	ff999ae3          	bne	s3,s9,10d44 <gpt_find_boot_partition+0x2a8>
   10d54:	00001517          	auipc	a0,0x1
   10d58:	f5450513          	addi	a0,a0,-172 # 11ca8 <_BSS_END_+0xca8>
   10d5c:	0019091b          	addiw	s2,s2,1
   10d60:	c3cff0ef          	jal	ra,1019c <print_uart>
   10d64:	08048493          	addi	s1,s1,128
   10d68:	f37918e3          	bne	s2,s7,10c98 <gpt_find_boot_partition+0x1fc>
   10d6c:	00001517          	auipc	a0,0x1
   10d70:	1d450513          	addi	a0,a0,468 # 11f40 <_BSS_END_+0xf40>
   10d74:	c28ff0ef          	jal	ra,1019c <print_uart>
   10d78:	020b2583          	lw	a1,32(s6)
   10d7c:	000a8613          	mv	a2,s5
   10d80:	000a0513          	mv	a0,s4
   10d84:	b61ff0ef          	jal	ra,108e4 <sd_copy>
   10d88:	00050493          	mv	s1,a0
   10d8c:	04050e63          	beqz	a0,10de8 <gpt_find_boot_partition+0x34c>
   10d90:	00001517          	auipc	a0,0x1
   10d94:	ff050513          	addi	a0,a0,-16 # 11d80 <_BSS_END_+0xd80>
   10d98:	c04ff0ef          	jal	ra,1019c <print_uart>
   10d9c:	00001517          	auipc	a0,0x1
   10da0:	ffc50513          	addi	a0,a0,-4 # 11d98 <_BSS_END_+0xd98>
   10da4:	bf8ff0ef          	jal	ra,1019c <print_uart>
   10da8:	00048513          	mv	a0,s1
   10dac:	cb0ff0ef          	jal	ra,1025c <print_uart_addr>
   10db0:	00001517          	auipc	a0,0x1
   10db4:	ef850513          	addi	a0,a0,-264 # 11ca8 <_BSS_END_+0xca8>
   10db8:	dc9ff06f          	j	10b80 <gpt_find_boot_partition+0xe4>
   10dbc:	00001517          	auipc	a0,0x1
   10dc0:	fc450513          	addi	a0,a0,-60 # 11d80 <_BSS_END_+0xd80>
   10dc4:	bd8ff0ef          	jal	ra,1019c <print_uart>
   10dc8:	00001517          	auipc	a0,0x1
   10dcc:	fd050513          	addi	a0,a0,-48 # 11d98 <_BSS_END_+0xd98>
   10dd0:	bccff0ef          	jal	ra,1019c <print_uart>
   10dd4:	00090513          	mv	a0,s2
   10dd8:	c84ff0ef          	jal	ra,1025c <print_uart_addr>
   10ddc:	00001517          	auipc	a0,0x1
   10de0:	ecc50513          	addi	a0,a0,-308 # 11ca8 <_BSS_END_+0xca8>
   10de4:	d9dff06f          	j	10b80 <gpt_find_boot_partition+0xe4>
   10de8:	00001517          	auipc	a0,0x1
   10dec:	17050513          	addi	a0,a0,368 # 11f58 <_BSS_END_+0xf58>
   10df0:	bacff0ef          	jal	ra,1019c <print_uart>
   10df4:	0000100f          	fence.i
   10df8:	cf9ff06f          	j	10af0 <gpt_find_boot_partition+0x54>

Disassembly of section .text.startup:

0000000000010dfc <main>:
   10dfc:	0001c5b7          	lui	a1,0x1c
   10e00:	02faf537          	lui	a0,0x2faf
   10e04:	ff010113          	addi	sp,sp,-16
   10e08:	20058593          	addi	a1,a1,512 # 1c200 <_RODATA_END_+0xa29f>
   10e0c:	08050513          	addi	a0,a0,128 # 2faf080 <_RODATA_END_+0x2f9d11f>
   10e10:	00113423          	sd	ra,8(sp)
   10e14:	b30ff0ef          	jal	ra,10144 <init_uart>
   10e18:	00001517          	auipc	a0,0x1
   10e1c:	e5050513          	addi	a0,a0,-432 # 11c68 <_BSS_END_+0xc68>
   10e20:	b7cff0ef          	jal	ra,1019c <print_uart>
   10e24:	00100513          	li	a0,1
   10e28:	000085b7          	lui	a1,0x8
   10e2c:	01f51513          	slli	a0,a0,0x1f
   10e30:	c6dff0ef          	jal	ra,10a9c <gpt_find_boot_partition>
   10e34:	00813083          	ld	ra,8(sp)
   10e38:	00000513          	li	a0,0
   10e3c:	01010113          	addi	sp,sp,16
   10e40:	00008067          	ret

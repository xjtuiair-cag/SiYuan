// +FHDR------------------------------------------------------------------------
// Copyright ownership belongs to CAG laboratory, Institute of Artificial
// Intelligence and Robotics, Xi'an Jiaotong University, shall not be used in
// commercial ways without permission.
// -----------------------------------------------------------------------------
// FILE NAME  : main.c
// DEPARTMENT : CAG of IAIR
// AUTHOR     : XXXX
// AUTHOR'S EMAIL :XXXX@mail.xjtu.edu.cn
// -----------------------------------------------------------------------------
// Ver 1.0  2019--01--01 initial version.
// -----------------------------------------------------------------------------

#include "uart.h"
#include "dma.h"
#include "regmap.h"


int perfcnt_test(){
    uint64_t rd_val;
    uint64_t wr_val;
    uint64_t tmp_val;
    wr_val = 0;
    // read retired instr
    asm volatile ("csrr %0, instret" : "=r"(rd_val));
    if (rd_val == 0) {
        return -1;
    }
    asm volatile ("csrw instret, %0" :: "r"(wr_val));
    tmp_val = rd_val;
    asm volatile ("csrr %0, instret" : "=r"(rd_val));
    if (rd_val > tmp_val) {
        return -1;
    }
    // read retired branch instr
    asm volatile ("csrr %0, hpmcounter3" : "=r"(rd_val));
    if (rd_val == 0) {
        return -1;
    }
    asm volatile ("csrw hpmcounter3, %0" :: "r"(wr_val));
    tmp_val = rd_val;
    asm volatile ("csrr %0, hpmcounter3" : "=r"(rd_val));
    if (rd_val > tmp_val) {
        return -1;
    }
    // read retired mispred branch 
    asm volatile ("csrr %0, hpmcounter4" : "=r"(rd_val));
    if (rd_val == 0) {
        return -1;
    }
    asm volatile ("csrw hpmcounter4, %0" :: "r"(wr_val));
    tmp_val = rd_val;
    asm volatile ("csrr %0, hpmcounter4" : "=r"(rd_val));
    if (rd_val > tmp_val) {
        return -1;
    }
    // read icache access num
    asm volatile ("csrr %0, hpmcounter5" : "=r"(rd_val));
    if (rd_val == 0) {
        return -1;
    }
    asm volatile ("csrw hpmcounter5, %0" :: "r"(wr_val));
    tmp_val = rd_val;
    asm volatile ("csrr %0, hpmcounter5" : "=r"(rd_val));
    if (rd_val > tmp_val) {
        return -1;
    }
    // read dcache access num
    asm volatile ("csrr %0, hpmcounter6" : "=r"(rd_val));
    if (rd_val == 0) {
        return -1;
    }
    asm volatile ("csrw hpmcounter6, %0" :: "r"(wr_val));
    tmp_val = rd_val;
    asm volatile ("csrr %0, hpmcounter6" : "=r"(rd_val));
    if (rd_val > tmp_val) {
        return -1;
    }
    // read icache miss
    asm volatile ("csrr %0, hpmcounter7" : "=r"(rd_val));
    if (rd_val == 0) {
        return -1;
    }
    asm volatile ("csrw hpmcounter7, %0" :: "r"(wr_val));
    tmp_val = rd_val;
    asm volatile ("csrr %0, hpmcounter7" : "=r"(rd_val));
    if (rd_val > tmp_val) {
        return -1;
    }
    // read icache miss
    asm volatile ("csrr %0, hpmcounter8" : "=r"(rd_val));
    if (rd_val == 0) {
        return -1;
    }
    asm volatile ("csrw hpmcounter8, %0" :: "r"(wr_val));
    tmp_val = rd_val;
    asm volatile ("csrr %0, hpmcounter8" : "=r"(rd_val));
    if (rd_val > tmp_val) {
        return -1;
    }
    asm volatile ("csrr %0, hpmcounter9" : "=r"(rd_val));
    if (rd_val != 0) {
        return -1;
    }
    return 0;
}

int main()
{
    init_uart(50000000, 115200);
    // L2 cache test case 1 : TEST L2 cache flush
    // print_uart("---------L2 cache TEST CASE 1: test L2 cache flush--------!\r\n");
    // init src array

    uint32_t error = perfcnt_test();
    // finish 
    volatile uint32_t * done_addr = (uint32_t *)0x42000000;
	*done_addr = error; // if error = 0, TEST pass, othewise TEST fail

    while (1);  // do nothing
}

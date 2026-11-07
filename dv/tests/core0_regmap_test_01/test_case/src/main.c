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

int regmap_test(){
    uint32_t tmp_data;
    volatile uint32_t * addr;
    // -------------- test status reg (read only) ---------------------
    addr = REGMAP_STATUS;
    tmp_data = *addr;
    // check 
    if (tmp_data != 0x4000000) {
        return -1;
    }
    *addr = 0xffff; // test write 
    tmp_data = *addr; // data must be not changed
    if (tmp_data != 0x4000000) {
        return -1;
    }
    // -------------- test info reg (read only) ---------------------
    addr = REGMAP_INF;
    tmp_data = *addr;
    // check 
    if (tmp_data != 0x610A) {
        return -1;
    }
    *addr = 0; // test write 
    tmp_data = *addr; // data must be not changed
    if (tmp_data != 0x610A) {
        return -1;
    }
    // -------------- test arg reg (read/write) from arg00 to arg1f ---------------------
    addr = REGMAP_ARG01;
    for (int i=0; i<31;i++) {
        *addr = i;
        tmp_data = *addr;
        if (tmp_data != i) {
            return -1;
        }
        addr++;
    }
    // -------------- test init pc reg(read/write)---------------------
    addr = REGMAP_INIT_PC;
    tmp_data = *addr;
    if (tmp_data != 0x58000000){
        return -1;
    }
    *addr = 0x10;
    tmp_data = *addr;
    if (tmp_data != 0x10) {
        return -1;
    }
    addr = REGMAP_INIT_PCH;
    tmp_data = *addr;
    if (tmp_data != 0x0) {
        return -1;
    }
    *addr = 0x20;
    tmp_data = *addr;
    if (tmp_data != 0x20) {
        return -1;
    }
    // -------------- test return addr reg(read/write)---------------------
    addr = REGMAP_RET_ADDR;
    tmp_data = *addr;
    if (tmp_data != 0x0){
        return -1;
    }
    *addr = 0x30;
    tmp_data = *addr;
    if (tmp_data != 0x30) {
        return -1;
    }
    addr = REGMAP_RET_ADDRH;
    tmp_data = *addr;
    if (tmp_data != 0x0) {
        return -1;
    }
    *addr = 0x40;
    tmp_data = *addr;
    if (tmp_data != 0x40) {
        return -1;
    }
    // -------------- test soft irq en reg(read/write)---------------------
    addr = REGMAP_SIE;
    *addr = 0x1;
    tmp_data = *addr;
    if (tmp_data != 0x1) {
        return -1;
    }
    // -------------- test soft irq set reg(read/write)---------------------
    addr = REGMAP_SIS;
    *addr = 0x1; // set irq
    addr = REGMAP_SI;
    tmp_data = *addr;
    if (tmp_data != 0x1) {
        return -1;
    }
    // -------------- test soft irq mask reg(read/write)---------------------
    addr = REGMAP_SIM;
    *addr = 0x1;
    tmp_data = *addr;
    if (tmp_data != 0x1) {
        return -1;
    }
    addr = REGMAP_SI;
    if (*addr != 0x0) {
        return -1;
    }
    // clear mask
    addr = REGMAP_SIM;
    *addr = 0x0;
    // -------------- test soft irq clear (read/write)---------------------
    addr = REGMAP_SIC;
    *addr = 0x1;
    addr = REGMAP_SI;
    if (*addr != 0x0) {
        return -1;
    }

    return 0;
}

int main()
{
    init_uart(50000000, 115200);
    // print_uart("---------DMA TEST CASE 1: test Trans between DDR and DDR--------!\r\n");

    uint32_t error = regmap_test();
    // finish 
    volatile uint32_t * done_addr = (uint32_t *)0x42000000;
	*done_addr = error; // if error = 0, TEST pass, othewise TEST fail

    while (1);  // do nothing
}

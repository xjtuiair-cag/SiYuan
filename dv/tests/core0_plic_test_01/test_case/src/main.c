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
#include "plic.h"

int plic_test(){
    uint32_t tmp_data;
    uint32_t * addr;
    // -------------- test priority register ---------------------
    addr = (uint32_t*) PRIO_REG_BASE;
    for (int i=0;i<SOURCE_NUM;i++) {
        *addr = 0x3; // set priority
        tmp_data = *addr;
        if (i==0){      // priority of source 0 always be  0
            if (tmp_data != 0x0) {
                return -1;
            }
        } else {
            if (tmp_data != 0x3) {  // read priority
                return -1;
            }
        }
        addr++;
    }
    // -------------- test interrupt pending bit (read only)---------------------
    addr = (uint32_t*) IP_REG_BASE;
    for (int i=0;i<SOURCE_NUM/32;i++) {
        tmp_data = *addr;
        if (tmp_data != 0) {
            return -1;
        }
        *addr = 0xFFFFFFFF;
        tmp_data = *addr;
        if (tmp_data != 0) {
            return -1;
        }
        addr++;
    }
    // -------------- test enable bits register ---------------------
    addr = (uint32_t*) EN_BITS_REG_BASE;
    for (int i=0;i<TARGET_NUM;i++) {
        addr = (uint32_t*) (EN_BITS_REG_BASE + i * 0x80);
        for (int j=0;j<SOURCE_NUM/32;j++){
            tmp_data = *addr;
            if (tmp_data != 0) {
                return -1;
            }
            *addr = 0xFFFFFFFF;   
            tmp_data = *addr;
            if (j==0){
                if (tmp_data != 0xFFFFFFFE) { // source 0 always be 0
                    return -1;
                }
            } else {
                if (tmp_data != 0xFFFFFFFF) { 
                    return -1;
                }
            }
            addr++;
        }
    }
    // -------------- test priority threshold registre---------------------
    for (int i=0;i<TARGET_NUM;i++) {
        addr = (uint32_t*) (PRIO_THRESH_BASE + i * 0x1000);
        tmp_data = *addr;
        if (tmp_data != 0) {
            return -1;
        }
        *addr = 0x3;   
        tmp_data = *addr;
        if (tmp_data != 0x3) {
            return -1;
        }
    }
    // -------------- test claim registre---------------------
    for (int i=0;i<TARGET_NUM;i++) {
        addr = (uint32_t*) (PRIO_THRESH_BASE + i * 0x1000 + 0x4);
        tmp_data = *addr;
        if (tmp_data != 0) {
            return -1;
        }
        *addr = 0x3;   
        tmp_data = *addr;
        if (tmp_data != 0x0) {
            return -1;
        }
    }

    return 0;
}

int main()
{
    init_uart(50000000, 115200);
    // print_uart("---------DMA TEST CASE 1: test Trans between DDR and DDR--------!\r\n");

    uint32_t error = plic_test();
    // finish 
    volatile uint32_t * done_addr = (uint32_t *)0x42000000;
	*done_addr = error; // if error = 0, TEST pass, othewise TEST fail

    while (1);  // do nothing
}

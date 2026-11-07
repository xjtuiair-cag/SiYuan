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
int main()
{
    init_uart(50000000, 115200);
    // boot stage 1 address : 0x80000000
    print_uart("---------Boot TEST CASE 0: test boot stage0 and boot stage1 --------!\r\n");
    print_uart("Welcome to SiYuan!\r\n");   

    // finish 
    volatile uint32_t * done_addr = (uint32_t *)0x42000000;
	*done_addr = 0; // if error = 0, TEST pass, othewise TEST fail

    while (1);  // do nothing
}

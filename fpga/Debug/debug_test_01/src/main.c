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
    volatile uint32_t * reg_arg01 = (uint32_t *)REGMAP_ARG01;
    volatile uint32_t * reg_arg02 = (uint32_t *)REGMAP_ARG02;
    *reg_arg01 = 0x12345678;    
    *reg_arg02 = 0xFFFFFFFF;    

    init_uart(50000000, 115200);
    print_uart("\n");
    print_uart("---------DEBUG TEST case 0: test Uart--------!\r\n");
    print_uart("---------Welcome to SiYuan!!!--------!\r\n");

    while (1);  // do nothing

    return 0;
}

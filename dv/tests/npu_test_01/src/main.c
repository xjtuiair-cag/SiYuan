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
#include "npu.h"


int main()
{
    init_uart(50000000, 115200);
    print_uart("Hello World!\r\n");
    
    init_npu();
    start_npu();
    start_conv();
    wait_npu_done();
    print_uart("Convolution Finish!\r\n");

    while (1);  // do nothing
}

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

uint32_t *src_arr = (uint32_t *)0x80100000;
uint32_t size = 0x200;

int main()
{
    init_uart(50000000, 115200);
    // print_uart("---------AXIL32 MASTER TEST CASE 0--------!\r\n");

    int error = 0;
    // memset
    for (int i=0;i<size;i++) {
        src_arr[i] = i;
    }
    // check
    for (int i=0;i<size;i++) {
        if (src_arr[i] != i) {
            error = 1;
        }
    }

    // finish 
	uint32_t * done_addr = REGMAP_ARG00;
	*done_addr = error; // if error = 0, TEST pass, othewise TEST fail

    return 0;
}

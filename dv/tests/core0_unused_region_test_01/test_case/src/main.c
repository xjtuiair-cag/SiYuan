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
    // access unused region
    volatile uint32_t * done_addr = (uint32_t *)0x20000000;
    uint32_t val = *done_addr;
    // finish 
    done_addr = (uint32_t *)0x42000000;
	*done_addr = 0; // if error = 0, TEST pass, othewise TEST fail

    while (1);  // do nothing
}

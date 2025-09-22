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
#include "spi.h"
#include "sd.h"


uint8_t *data_arr = (uint8_t *)0x80100000UL;
uint8_t *ref_arr  = (uint8_t *)0x9a200000UL;

void check(uint64_t * src, uint64_t * ref, int len){
    uint64_t src_data;
    uint64_t ref_data;
    for (int i=0;i<(len>>3);i++){
        src_data = src[i];
        ref_data = ref[i];
        if (src_data != ref_data) {
            print_uart("Wrong!!!\n");
            break;
        }
    }
}

int main()
{
    init_uart(50000000, 115200);
    print_uart("---------SPI TEST CASE 0: test SD card normal read--------!\r\n");

    init_sd();
    // read 2 blocks (1024B)
    sd_read_data(data_arr, 0x0, 0x2);
    // check 1024 Byte
    check((uint64_t*)data_arr, (uint64_t*)ref_arr, 1024);
    print_uart("---------SPI TEST CASE 0 DONE!!--------!\r\n");
    while (1);  // do nothing
}

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

int check(uint64_t * src, uint64_t * ref, int len){
    uint64_t src_data;
    uint64_t ref_data;
    uint8_t error = 0;
    for (int i=0;i<(len>>3);i++){
        src_data = src[i];
        ref_data = ref[i];
        if (src_data != ref_data) {
            print_uart("Wrong Address: ");
            print_uart_addr(i);
            error = -1;
            break;
        }
    }
    return error;
}

int main()
{
    init_uart(50000000, 115200);
    print_uart("---------SPI TEST CASE 1: test SD card normal write--------!\r\n");

    init_sd();
    uint32_t * src_data = (uint32_t *)data_arr;
    for (int i=0;i<256;i++) {
        src_data[i] = i;
    }
    // write 2 blocks to SD card
    sd_write_data_singel_blk(data_arr,0x0); 
    sd_write_data_singel_blk(data_arr+512,0x1);
    // read 2 blocks (1024B)
    sd_read_data(ref_arr, 0x0, 0x2);
    // check 1024 Byte
    if(check((uint64_t*)data_arr, (uint64_t*)ref_arr, 1024) < 0){
        print_uart("---------SPI TEST CASE 1 FAILED--------\r\n");
    }  else {
        print_uart("---------SPI TEST CASE 1 SUCCESS--------\r\n");
    }

    while (1);  // do nothing
}

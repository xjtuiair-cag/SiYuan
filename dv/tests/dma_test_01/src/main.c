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

uint8_t *data_arr = (uint8_t *)0x80100000UL;
uint8_t *ref_arr  = (uint8_t *)0x9a200000UL;

int dma_check(uint64_t * src, uint64_t * ref, int len){
    uint64_t src_data;
    uint64_t ref_data;
    uint8_t error = 0;
    for (int i=0;i<(len>>3);i++){
        src_data = src[i];
        ref_data = ref[i];
        if (src_data != ref_data) {
            print_uart("Wrong Address: ");
            print_uart_addr(i);
            print_uart("\r\n");
            error = -1;
            break;
        }
    }
    return error;
}

int main()
{
    init_uart(50000000, 115200);
    print_uart("---------DMA TEST CASE 0: test Trans between DDR and DDR --------!\r\n");

    Dma_init();
    // Trans data between DDR and DDR
    Dma_trans_cfg(0x9a200000,0x80100000,16,16,1024*16,NORMAL_TRANS_MODE);
    Dma_start();
    // check if dma trans is done
    while(1) {
        if (is_Dma_done()){
            break;
        }
    }
    flush_done();
    print_uart("Transaction Done!\r\n");

    // check if dma trans is right
    if(dma_check((uint64_t*)data_arr, (uint64_t*)ref_arr, 1024 * 16) < 0){
        print_uart("---------SPI TEST CASE 2 FAILED--------\r\n");
    }  else {
        print_uart("---------SPI TEST CASE 2 SUCCESS--------\r\n");
    }

    while (1);  // do nothing
}

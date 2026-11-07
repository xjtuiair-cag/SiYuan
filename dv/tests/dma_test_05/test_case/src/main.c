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

uint8_t *src_arr = (uint8_t *)0x80100000UL;
uint8_t *ref_arr = (uint8_t *)0x80200000UL;
uint8_t *dst_arr = (uint8_t *)0x80300000UL;
uint32_t trans_size = 1024 * 16; // 16KB

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

void delay_us (int us) {
    for (int i=0;i<us;i++){

    }
}

int main()
{
    init_uart(50000000, 115200);
    // DMA test case 7 : TEST Trans between DDR and DDR ,TEST size : 16 KB 
    // print_uart("---------DMA TEST CASE 7: test Trans between DDR and DDR--------!\r\n");
    // init DMA
    Dma_init();
    // Trans data from DDR to DDR
    // src addr : 0x80100000
    // dst addr : 0x80300000
    // read  burst len : 16
    // write burst len : 16
    // trans size : 2KB
    // trans mode : rd single step mode
    dma_trans_t trans_cfg;
    trans_cfg.src_addr = (uint32_t)src_arr;
    trans_cfg.des_addr = (uint32_t)dst_arr;
    trans_cfg.rd_burst_len = 16;
    trans_cfg.wr_burst_len = 16;
    trans_cfg.data_volume = trans_size;
    trans_cfg.mode = SINGLE_RD_TRANS_MODE;
    trans_cfg.rd_pending_volume = 1024*4; // when read 4KB, dma will pending uintil cpu clear pending bit
    trans_cfg.wr_pending_volume = 0;
    Dma_trans_cfg(&trans_cfg,1,0);
    Dma_start();
    for (int i=0;i<(trans_size/(1024*4));i++) {
        while (is_read_pending() == 0);
        delay_us(100); // do something here : such as read sd block
        clear_read_pending();
    }
    // check if dma trans is done
    while(1) {
        if (is_Dma_done()){
            break;
        }
    }
    // print_uart("Transaction Done!\r\n");

    uint32_t error = dma_check((uint64_t*)dst_arr, (uint64_t*)ref_arr, trans_size);
    // finish 
    volatile uint32_t * done_addr = (uint32_t *)0x42000000;
	*done_addr = error; // if error = 0, TEST pass, othewise TEST fail

    while (1);  // do nothing
}

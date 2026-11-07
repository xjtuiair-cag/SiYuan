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
uint8_t *axil32_dst0_arr = (uint8_t *)0x41000000UL; // in shared sram
uint8_t *dst_arr = (uint8_t *)0x80300000UL; // in shared sram
uint32_t trans_size = 16 * 1024;
volatile uint32_t * done_addr = (uint32_t *)0x42000000;
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
    // test case 2 : TEST burst read and write on axi-lite32 interface : each read/write is 8B
    print_uart("---------AXIL32 MASTER TEST CASE 3--------!\r\n");
    // init DMA
    Dma_init();
    // Trans data from DDR to AXI-lite 32 interface (test burst write)
    // src addr : 0x80100000
    // dst addr : 0x41000000
    // read  burst len : 16
    // write burst len : 16
    // trans size : 16KB
    // trans mode : normal mode
    dma_trans_t trans_cfg;
    trans_cfg.src_addr = (uint32_t)src_arr;
    trans_cfg.des_addr = (uint32_t)axil32_dst0_arr;
    trans_cfg.rd_burst_len = 16;
    trans_cfg.wr_burst_len = 16;
    trans_cfg.data_volume = trans_size;
    trans_cfg.mode = NORMAL_TRANS_MODE;
    trans_cfg.rd_pending_volume = 0; // when write 256B, dma will pending uintil cpu clear pending bit
    trans_cfg.wr_pending_volume = 0;
    Dma_trans_cfg(&trans_cfg,0,0);
    Dma_start();
    // check if dma trans is done
    while(1) {
        if (is_Dma_done()){
            break;
        }
    }
    // flush done signel
    flush_done();
    // Trans data from AXI-lite 32 interface to DDR (test burst read)
    // src addr : 0x80100000
    // dst addr : 0x41000000
    // read  burst len : 16
    // write burst len : 16
    // trans size : 16KB
    // trans mode : normal mode
    trans_cfg.src_addr = (uint32_t)axil32_dst0_arr;
    trans_cfg.des_addr = (uint32_t)dst_arr;
    Dma_trans_cfg(&trans_cfg,0,0);
    Dma_start();
    // check if dma trans is done
    while(1) {
        if (is_Dma_done()){
            break;
        }
    }
    // flush done signel
    flush_done();
    uint32_t error = dma_check((uint64_t*)dst_arr, (uint64_t*)ref_arr, trans_size);

    // finish 
	*done_addr = error; // if error = 0, TEST pass, othewise TEST fail

    while (1);  // do nothing
}

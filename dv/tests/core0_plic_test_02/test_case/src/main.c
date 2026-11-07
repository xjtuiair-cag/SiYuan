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
#include "plic.h"

#define DMA_INTR_LOC    (2 + 1)

uint8_t *src_arr = (uint8_t *)0x80100000UL;
uint8_t *ref_arr = (uint8_t *)0x80200000UL;
uint8_t *dst_arr = (uint8_t *)0x80300000UL;
uint32_t trans_size = 1024 * 16;

int main()
{
    init_uart(50000000, 115200);
    // write plic to enable interrupt
    uint32_t dma_intr_off = (DMA_INTR_LOC / 32) * 4;
    volatile uint32_t * plic_en_bits_addr = EN_BITS_REG_BASE + dma_intr_off;
    *plic_en_bits_addr = 0x1 << (DMA_INTR_LOC % 32); // Enable DMA interrupt 
    // write priority
    dma_intr_off = DMA_INTR_LOC * 4;
    volatile uint32_t * plic_prio_addr = PRIO_REG_BASE + dma_intr_off;
    *plic_prio_addr = 0x7; // max priority

    // DMA test case 1 : TEST Trans between DDR and DDR ,TEST size : 2KB
    // print_uart("---------DMA TEST CASE 1: test Trans between DDR and DDR--------!\r\n");
    // init DMA
    Dma_init();
    Dma_intr_en();
    // Trans data from DDR to DDR
    // src addr : 0x80100000
    // dst addr : 0x80300000
    // read  burst len : 16
    // write burst len : 16
    // trans size : 16KB
    // trans mode : normal mode
    dma_trans_t trans_cfg;
    trans_cfg.src_addr = (uint32_t)src_arr;
    trans_cfg.des_addr = (uint32_t)dst_arr;
    trans_cfg.rd_burst_len = 16;
    trans_cfg.wr_burst_len = 16;
    trans_cfg.data_volume = trans_size;
    trans_cfg.mode = NORMAL_TRANS_MODE;
    trans_cfg.rd_pending_volume = 0;
    trans_cfg.wr_pending_volume = 0;
    Dma_trans_cfg(&trans_cfg,0,0);
    Dma_start();
    // check if dma trans is done
    while(1) {
        if (is_Dma_done()){
            break;
        }
    }
    uint32_t error = 0;
    // read plic interrupt pending bit to see if there is any DMA interrupt 
    dma_intr_off = (DMA_INTR_LOC / 32) * 4;
    volatile uint32_t * plic_pending_addr = IP_REG_BASE + dma_intr_off;
    uint32_t ip = *plic_pending_addr;
    volatile uint32_t * claim_addr = PRIO_THRESH_BASE + 0x4;
    if ((ip & (0x1 << (DMA_INTR_LOC%32))) == 0) {
        error = 1; // TEST FAIL
    } else {
        Dma_intr_clr();
        // flush pending bit
        *claim_addr = DMA_INTR_LOC;
        // read claim
        uint32_t claim = *claim_addr;
        if (claim != DMA_INTR_LOC) {
            error = 1; // TEST FAIL
        }
    }

    // print_uart("Transaction Done!\r\n");

    // finish 
    volatile uint32_t * done_addr = (uint32_t *)0x42000000;
	*done_addr = error; // if error = 0, TEST pass, othewise TEST fail

    while (1);  // do nothing
}

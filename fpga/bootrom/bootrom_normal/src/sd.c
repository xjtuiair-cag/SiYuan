#include "sd.h"
#include "dma.h"
#include "utils.h"

volatile uint64_t *const sd_base = (volatile uint64_t *)SD_BASE;
volatile uint64_t *const sd_bram = (volatile uint64_t *)(SD_BASE+ 0x8000);
void sd_init(uint64_t frequency) {
    int old_init_state = -1;
    uint64_t fast_clk_div;
    uint64_t slow_clk_div;   
    uint64_t clk_div;
    uint64_t power_stable_cnt;
    uint64_t acm41_reissue_cnt;   
    uint64_t init_cnt;

    fast_clk_div = (frequency / 12500000 / 2) - 1;
    slow_clk_div = (frequency / 200000 / 2) - 1;
    clk_div = (fast_clk_div << 32) | slow_clk_div;

    power_stable_cnt = (frequency / 10);
    acm41_reissue_cnt = (frequency / 2);
    init_cnt = (acm41_reissue_cnt << 32) | power_stable_cnt;
    /* SD clock divider*/
    sd_base[ _piton_sd_WR_CLK_DIV]  = clk_div;
    sd_base[ _piton_sd_INIT_CNT]  = init_cnt;
    /* SD sector address */
    sd_base[ _piton_sd_ADDR_SD ]    = 0;
    /* always start at beginning of DMA buffer */
    sd_base[ _piton_sd_ADDR_DMA ]   = 0;
    /* set sector count */
    sd_base[ _piton_sd_BLKCNT ]     = 0;
    sd_base[ _piton_sd_REQ_RD ]     = 0;
    sd_base[ _piton_sd_REQ_WR ]     = 0;
    sd_base[ _piton_sd_IRQ_EN ]     = 0;
    sd_base[ _piton_sd_SYS_RST ]    = 0;

    /* reset HW state machine */
    sd_base[ _piton_sd_SYS_RST ]    = 1;
    // fence_io();
    do {
        int init_state = sd_base[_piton_sd_INIT_STATE];
        old_init_state = init_state;
    } while (old_init_state != 0xf0);

}
int sd_read_with_no_trans (uint32_t sector, uint32_t count){
    uint64_t vec;
    uint64_t stat = 0xDEADBEEF;
    uint64_t mask = (1 << count) - 1;
    /* SD sector address */
    sd_base[ _piton_sd_ADDR_SD ] = sector;
    /* always start at beginning of DMA buffer */
    sd_base[ _piton_sd_ADDR_DMA ] = 0;
    /* set sector count */
    sd_base[ _piton_sd_BLKCNT ] = count;
    sd_base[ _piton_sd_REQ_RD ] = 1;
    //   fence_io();
    do {
        stat = sd_base[_piton_sd_STATUS];
    } while (_piton_sd_STATUS_REQ_RDY & ~stat);

    sd_base[ _piton_sd_REQ_RD ] = 0;
    vec = sd_base[ _piton_sd_ERROR ] & mask;

    // memcpy(buff, (void *)sd_bram, count*512);
    // uint64_t * sd_bram_u8 = (uint64_t *) sd_bram;
    // for (int i=0;i<count*512/8;i++){
    //     buff[i] = sd_bram_u8[i];
    // }

    if (vec == mask)
      return 0;

    return 1;
}

int sd_read (uint64_t *buff, uint32_t sector, uint32_t count){
    uint64_t vec;
    uint64_t stat = 0xDEADBEEF;
    uint64_t mask = (1 << count) - 1;
    /* SD sector address */
    sd_base[ _piton_sd_ADDR_SD ] = sector;
    /* always start at beginning of DMA buffer */
    sd_base[ _piton_sd_ADDR_DMA ] = 0;
    /* set sector count */
    sd_base[ _piton_sd_BLKCNT ] = count;
    sd_base[ _piton_sd_REQ_RD ] = 1;
    //   fence_io();
    do {
        stat = sd_base[_piton_sd_STATUS];
    } while (_piton_sd_STATUS_REQ_RDY & ~stat);

    sd_base[ _piton_sd_REQ_RD ] = 0;
    vec = sd_base[ _piton_sd_ERROR ] & mask;

    // memcpy(buff, (void *)sd_bram, count*512);
    uint64_t * sd_bram_u8 = (uint64_t *) sd_bram;
    for (int i=0;i<count*512/8;i++){
        buff[i] = sd_bram_u8[i];
    }

    if (vec == mask)
      return 0;

    return 1;
}

int sd_read_with_dma (dma_trans_t * dma_cfg, uint32_t sector, uint32_t count){
    uint64_t vec;
    uint64_t stat = 0xDEADBEEF;
    uint64_t mask = (1 << count) - 1;
    /* SD sector address */
    sd_base[ _piton_sd_ADDR_SD ] = sector;
    /* always start at beginning of DMA buffer */
    sd_base[ _piton_sd_ADDR_DMA ] = 0;
    /* set sector count */
    sd_base[ _piton_sd_BLKCNT ] = count;
    sd_base[ _piton_sd_REQ_RD ] = 1;
    //   fence_io();
    do {
        stat = sd_base[_piton_sd_STATUS];
    } while (_piton_sd_STATUS_REQ_RDY & ~stat);

    sd_base[ _piton_sd_REQ_RD ] = 0;
    vec = sd_base[ _piton_sd_ERROR ] & mask;

    // memcpy(buff, (void *)sd_bram, count*512);
    // uint64_t * sd_bram_u8 = (uint64_t *) sd_bram;
    // for (int i=0;i<count*512/8;i++){
    //     buff[i] = sd_bram_u8[i];
    // }

    Dma_trans_cfg(dma_cfg, 0, 0);
    Dma_start();
    // check if dma trans is done
    while(1) {
        if (is_Dma_done()){
            break;
        }
    }
    flush_done(); 

    if (vec == mask)
      return 0;

    return 1;
}
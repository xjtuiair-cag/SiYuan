#ifndef	_DMA_H
#define	_DMA_H

#include <stdint.h>

#define DMA_BASE 0x41820000

#define SRC_BASE_ADDR       DMA_BASE + 0x0
#define DES_BASE_ADDR       DMA_BASE + 0x8
#define DATA_VOLUME         DMA_BASE + 0x10 
#define BURST_LEN           DMA_BASE + 0x14
#define TRANS_CTRL          DMA_BASE + 0x18
#define TRANS_MODE          DMA_BASE + 0x1C
#define STATUS              DMA_BASE + 0x20
#define RD_PENDING_VOLUME   DMA_BASE + 0x24
#define WR_PENDING_VOLUME   DMA_BASE + 0x28

#define START_LOC       0
#define RD_RESET_LOC    1
#define WR_RESET_LOC    2
#define RD_DONE_LOC     0
#define WR_DONE_LOC     1
#define BUSY_LOC        2
#define RD_PENDING_LOC  3
#define WR_PENDING_LOC  4

#define RD_BURST_TYPE_LOC   0
#define WR_BURST_TYPE_LOC   1
#define RD_SINGLE_STEP_LOC  2
#define WR_SINGLE_STEP_LOC  3
#define RD_WR_SEQ           4

#define NORMAL_TRANS_MODE    0
#define SINGLE_RD_TRANS_MODE    (1 << RD_SINGLE_STEP_LOC)
#define SINGLE_WR_TRANS_MODE    (1 << WR_SINGLE_STEP_LOC)
#define RD_WR_SEQ_MODE          (1 << RD_WR_SEQ)

typedef struct {
    uint32_t src_addr;
    uint32_t des_addr;
    uint32_t data_volume;
    uint32_t mode;
    uint32_t rd_pending_volume;
    uint32_t wr_pending_volume;
    uint8_t rd_burst_len;
    uint8_t wr_burst_len;
} dma_trans_t;

void Dma_init();
void Dma_trans_cfg(dma_trans_t * trans_cfg, uint32_t rd_single_step, uint32_t wr_single_step);
void Dma_start();
uint8_t is_Dma_done();
uint8_t is_read_pending();
void clear_read_pending();
void flush_done();  


#endif  /*_DMA_H_*/
#ifndef	_DMA_H
#define	_DMA_H

#include <stdint.h>

#define DMA_BASE 0x30000 

#define SRC_BASE_ADDR   DMA_BASE + 0
#define DES_BASE_ADDR   DMA_BASE + 8
#define DATA_VOLUME     DMA_BASE + 16  
#define BURST_LEN       DMA_BASE + 24
#define TRANS_CTRL      DMA_BASE + 28
#define TRANS_MODE      DMA_BASE + 32 
#define STATUS          DMA_BASE + 36

#define START_LOC       0
#define RD_RESET_LOC    1
#define WR_RESET_LOC    2
#define DONE_LOC        0
#define BUSY_LOC        1
#define RD_PENDING_LOC  2
#define WR_PENDING_LOC  3
#define RD_REALIGN_LOC  0
#define WR_REALIGN_LOC  1
#define RD_BURST_TYPE_LOC  2
#define WR_BURST_TYPE_LOC  3
#define RD_SINGLE_STEP_LOC  4
#define WR_SINGLE_STEP_LOC  5

#define SPI_RD_TRANS_MODE       ((1 << RD_REALIGN_LOC) | (1 << RD_BURST_TYPE_LOC) | (1 << RD_SINGLE_STEP_LOC))
#define SPI_WR_TRANS_MODE       ((1 << WR_REALIGN_LOC) | (1 << WR_BURST_TYPE_LOC) | (1 << WR_SINGLE_STEP_LOC))
#define NORMAL_RD_TRANS_MODE    0
#define NORMAL_WR_TRANS_MODE    0

void Dma_init();
void Dma_trans_cfg(uint32_t src, uint32_t des, uint32_t rd_burst_len, uint32_t wr_burst_len,uint32_t volume, uint32_t mode);
void Dma_start();
uint8_t is_Dma_done();
uint8_t is_read_pending();
void clear_read_pending();
void flush_done();  


#endif  /*_DMA_H_*/
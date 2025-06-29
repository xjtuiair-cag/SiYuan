#ifndef	_DMA_H
#define	_DMA_H
#include <stdint.h>

#define DMA_BASE 0x30000

#define SRC_BASE_ADDR   DMA_BASE + 0x0
#define DES_BASE_ADDR   DMA_BASE + 0x8
#define DATA_VOLUME     DMA_BASE + 0x10
#define BURST_LEN       DMA_BASE + 0x18
#define TRANS_CTRL      DMA_BASE + 0x1c
#define TRANS_MODE      DMA_BASE + 0x20

#define START_LOC       0
#define DONE_LOC        1
#define BUSY_LOC        2

#define SPI_MODE 1
#define NORMAL_MODE 0

void Dma_trans(uint32_t src, uint32_t des, uint32_t burst_len, uint32_t volume,uint32_t mode);
void Dma_start();
uint32_t is_Dma_done();
void flush_done();  


#endif  /*_DMA_H_*/
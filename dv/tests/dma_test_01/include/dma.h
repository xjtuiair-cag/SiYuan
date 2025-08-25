#ifndef	_DMA_H
#define	_DMA_H


typedef signed char             int8_t;   
typedef short int               int16_t;  
typedef int                     int32_t;  
  
typedef unsigned char           uint8_t;  
typedef unsigned short int      uint16_t;  
typedef unsigned int            uint32_t;  
typedef unsigned long int       uint64_t; 

typedef unsigned long int	    uintptr_t;
 

#define DMA_BASE 0x0

#define SRC_BASE_ADDR   DMA_BASE + 0
#define DES_BASE_ADDR   DMA_BASE + 8
#define DATA_VOLUME     DMA_BASE + 16  
#define BURST_LEN       DMA_BASE + 24
#define TRANS_CTRL      DMA_BASE + 28

#define START_LOC       0
#define DONE_LOC        1
#define BUSY_LOC        2

void Dma_trans(uint64_t src, uint64_t des, uint32_t burst_len, uint64_t volume);
void Dma_start();
uint8_t is_Dma_done();
void flush_done();  


#endif  /*_DMA_H_*/
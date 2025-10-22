#ifndef	_SD_H
#define	_SD_H

#include <stdint.h>

#define SD_CMD_STOP_TRANSMISSION 12
#define SD_CMD_READ_BLOCK_MULTIPLE 18
#define SD_CMD_WRITE_BLOCK_MULTIPLE 25
#define SD_DATA_TOKEN 0xfe
#define SD_COPY_ERROR_CMD18 -1
#define SD_COPY_ERROR_CMD18_CRC -2

// errors
#define SD_INIT_ERROR_CMD0 -1
#define SD_INIT_ERROR_CMD8 -2
#define SD_INIT_ERROR_ACMD41 -3

int init_sd();

int sd_read_data(uint8_t * dst, uint32_t sd_addr, uint32_t size);
int sd_write_data_singel_blk(uint8_t * src, uint32_t sd_addr );
int sd_read_data_with_dma(uint8_t * dst, uint32_t sd_addr, uint32_t size);

#endif
#pragma once

#include <stdint.h>

#define SPI_BASE 0x20000000

#define SPI_STATUS_REG          SPI_BASE + 0x0
#define SPI_CLK_DIV_REG         SPI_BASE + 0x4
#define SPI_CMD_REG             SPI_BASE + 0x8
#define SPI_ADR_REG             SPI_BASE + 0xC
#define SPI_LEN_REG             SPI_BASE + 0x10
#define SPI_DUM_REG             SPI_BASE + 0x14
#define SPI_RX_FIFO_REG         SPI_BASE + 0x40
#define SPI_TX_FIFO_REG         SPI_BASE + 0x20

#define SPI_FIFO_DEPTH          16
#define SPI_FIFO_SIZE           (SPI_FIFO_DEPTH * 4)

void spi_init();

void spi_tx(uint8_t byte);
uint8_t spi_rx();
uint8_t spi_txrx(uint8_t byte);
void spi_read_block(uint32_t * data_arr);
void spi_write_block(uint32_t * data_arr);
void spi_read_block_with_dma(uint32_t * data_arr);
void SPI_trans_cfg(uint32_t len_reg, uint32_t dummy_reg);
void SPI_rd_start();
void wait_spi_trans_done();

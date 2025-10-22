#include "spi.h"
#include "dma.h"
#include "uart.h"
#include "utils.h"

void spi_init()
{
    print_uart("init SPI\r\n");

    // clear fifo
    write_reg(SPI_STATUS_REG, 0x10);

    // set spi clock divider
    write_reg(SPI_CLK_DIV_REG, 0x01);

    uint32_t status = read_reg(SPI_STATUS_REG);
    print_uart("status: 0x");
    print_uart_addr(status);
    print_uart("\r\n");

    print_uart("SPI initialized!\r\n");
}

void spi_tx(uint8_t byte)
{
    // enable slave select
    write_reg(SPI_STATUS_REG, 0x100);
    // write data length (length = 8)
    write_reg(SPI_LEN_REG, (0x8 << 16));
    // write data
    write_reg(SPI_TX_FIFO_REG, byte << 24);
    // write dummy data to zero
    write_reg(SPI_DUM_REG,0x0);
    // start spi transcation
    write_reg(SPI_STATUS_REG, 0x2 | 0x100);

    // wait transcation done
    while ((read_reg(SPI_STATUS_REG) & 0x1) != 0x1);

    // disable slave select
    write_reg(SPI_STATUS_REG, 0x0);
}

uint8_t spi_rx()
{
    // enable slave select
    write_reg(SPI_STATUS_REG, 0x100);
    // write cmd length (length = 8)
    write_reg(SPI_LEN_REG, (0x8 << 16));
    // write dummy data to zero
    write_reg(SPI_DUM_REG,0x0);
    // start spi transcation
    write_reg(SPI_STATUS_REG, 0x1 | 0x100);

    // wait transcation done
    while ((read_reg(SPI_STATUS_REG) & 0x1) != 0x1);

    uint32_t result = read_reg(SPI_RX_FIFO_REG);

    // disable slave select
    write_reg(SPI_STATUS_REG, 0x0);

    return result;
}
uint8_t spi_txrx(uint8_t byte)
{
    // enable slave select
    write_reg(SPI_STATUS_REG, 0x100);
    // write cmd length (length = 8)
    write_reg(SPI_LEN_REG, (0x8 << 16));
    // write cmd data
    write_reg(SPI_TX_FIFO_REG, byte << 24);
    // write dummy data to zero
    write_reg(SPI_DUM_REG,0x0);
    // start spi transcation
    write_reg(SPI_STATUS_REG, 0x1 | 0x2 | 0x100);

    // wait transcation done
    while ((read_reg(SPI_STATUS_REG) & 0x1) != 0x1);

    uint32_t result = read_reg(SPI_RX_FIFO_REG);

    // disable slave select
    write_reg(SPI_STATUS_REG, 0x0);

    return result & 0xff; // make sure least 8 bit are valid
}

// each block has 512B data
void spi_read_block(uint32_t * data_arr)
{
    // enable slave select
    write_reg(SPI_STATUS_REG, 0x100);
    // write cmd length (length = 32)
    write_reg(SPI_LEN_REG, (0x20 << 16));
    // write dummy data to zero
    write_reg(SPI_DUM_REG,0x0);

    uint32_t result;
    for (int i=0;i<128;i++) {
        // write cmd data
        write_reg(SPI_TX_FIFO_REG, 0xFFFFFFFF);
        // start spi transcation
        write_reg(SPI_STATUS_REG, 0x1 | 0x2 | 0x100);
        // wait transcation done
        while ((read_reg(SPI_STATUS_REG) & 0x1) != 0x1);

        result = read_reg(SPI_RX_FIFO_REG);
        data_arr[i] = ((result & 0xFF000000) >> 24) |
                      ((result & 0x00FF0000) >> 8 ) |
                      ((result & 0x0000FF00) << 8 ) |
                      ((result & 0x000000FF) << 24);
    }

    // disable slave select
    write_reg(SPI_STATUS_REG, 0x0);
}


void SPI_trans_cfg(uint32_t len_reg, uint32_t dummy_reg){
    write_reg(SPI_STATUS_REG, 0x100);
    // write cmd length 
    write_reg(SPI_LEN_REG, len_reg);
    // write dummy data 
    write_reg(SPI_DUM_REG,dummy_reg);
}

void SPI_rd_start(){
    write_reg(SPI_STATUS_REG, 0x1 | 0x100);
}

void wait_spi_trans_done(){
    while ((read_reg(SPI_STATUS_REG) & 0x1) != 0x1);
}

// each block has 512B data
// void spi_read_block_with_dma(uint32_t * data_arr)
// {   
//     uint8_t * des = (uint8_t *) data_arr;
//     // enable slave select
//     write_reg(SPI_STATUS_REG, 0x100);
//     // write cmd length (length = 32)
//     write_reg(SPI_LEN_REG, (0x20 << 16));
//     // write dummy data to 32 
//     write_reg(SPI_DUM_REG,0x20);

//     for (int i=0;i<512;i+=SPI_FIFO_SIZE) {
//         // start spi transcation
//         write_reg(SPI_STATUS_REG, 0x1 | 0x100);
//         // wait transcation done
//         while ((read_reg(SPI_STATUS_REG) & 0x1) != 0x1);

//         // start dma to read data in SPI FIFO
//         Dma_trans(SPI_RX_FIFO_REG,(uint32_t)(des+i),(SPI_FIFO_DEPTH<<1),SPI_FIFO_SIZE,SPI_RD_TRANS_MODE);      
//         Dma_start();
//         while (!is_Dma_done());
//         flush_done();
//     }

//     // disable slave select
//     write_reg(SPI_STATUS_REG, 0x0);
// }

void spi_write_block(uint32_t * data_arr)
{
    // enable slave select
    write_reg(SPI_STATUS_REG, 0x100);
    // write cmd length (length = 32)
    write_reg(SPI_LEN_REG, (0x20 << 16));
    // write dummy data to zero
    write_reg(SPI_DUM_REG,0x0);

    uint32_t wdata;
    for (int i=0;i<128;i++) {
        // write cmd data
        wdata = ((data_arr[i] & 0xFF000000) >> 24) |
                ((data_arr[i] & 0x00FF0000) >> 8 ) |
                ((data_arr[i] & 0x0000FF00) << 8 ) |
                ((data_arr[i] & 0x000000FF) << 24);
        write_reg(SPI_TX_FIFO_REG, wdata);
        // start spi transcation
        write_reg(SPI_STATUS_REG, 0x2 | 0x100);
        // wait transcation done
        while ((read_reg(SPI_STATUS_REG) & 0x1) != 0x1);
    }

    // disable slave select
    write_reg(SPI_STATUS_REG, 0x0);
}
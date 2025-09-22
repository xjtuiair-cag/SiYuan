#include "spi.h"
#include "uart.h"

void write_reg(uintptr_t addr, uint32_t value)
{
    volatile uint32_t *loc_addr = (volatile uint32_t *)addr;
    *loc_addr = value;
}

uint32_t read_reg(uintptr_t addr)
{
    return *(volatile uint32_t *)addr;
}

void spi_init()
{
    print_uart("init SPI\r\n");

    // clear fifo
    write_reg(SPI_STATUS_REG, 0x10);

    // set spi clock divider
    write_reg(SPI_CLK_DIV_REG, 0x04);

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
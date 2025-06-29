#include "spi.h"
#include "dma.h"
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

    // reset the axi quadspi core
    write_reg(SPI_RESET_REG, 0x0a);

    for (int i = 0; i < 10; i++)
    {
        __asm__ volatile(
            "nop");
    }

    write_reg(SPI_CONTROL_REG, 0x104);

    uint32_t status = read_reg(SPI_STATUS_REG);
    print_uart("status: 0x");
    print_uart_addr(status);
    print_uart("\r\n");

    // clear all fifos
    write_reg(SPI_CONTROL_REG, 0x166);

    status = read_reg(SPI_STATUS_REG);
    print_uart("status: 0x");
    print_uart_addr(status);
    print_uart("\r\n");

    write_reg(SPI_CONTROL_REG, 0x06);

    print_uart("SPI initialized!\r\n");
}

uint8_t spi_txrx(uint8_t byte)
{
    // enable slave select
    write_reg(SPI_SLAVE_SELECT_REG, 0xfffffffe);

    write_reg(SPI_TRANSMIT_REG, byte);

    for (int i = 0; i < 100; i++)
    {
        __asm__ volatile(
            "nop");
    }

    // enable spi control master flag
    write_reg(SPI_CONTROL_REG, 0x106);

    while ((read_reg(SPI_STATUS_REG) & 0x1) == 0x1)
        ;

    uint32_t result = read_reg(SPI_RECEIVE_REG);

    // disable slave select
    write_reg(SPI_SLAVE_SELECT_REG, 0xffffffff);

    // disable spi control master flag
    write_reg(SPI_CONTROL_REG, 0x06);

    return result;
}

#define SPIN_SHIFT 15
#define SPIN_UPDATE(i)	(!((i) & ((1 << SPIN_SHIFT)-1)))
#define SPIN_INDEX(i)	(((i) >> SPIN_SHIFT) & 0x3)

int spi_trans_with_dma(uint32_t ddr_addr,uint32_t size)
{
    // uint32_t status;
    uint32_t i = 0;

    // enable slave select
    write_reg(SPI_SLAVE_SELECT_REG, 0xfffffffe);
    // flush D cache
    __asm__ volatile("fence.i");

    // enable dma trans
    Dma_trans(SPI_RECEIVE_REG,ddr_addr,16,size,SPI_MODE);
    Dma_start();
    // check if dma trans is done
    print_uart("START LOADING [");
    while(1) {
        if (is_Dma_done()){
            break;
        }
        i++;
		if (SPIN_UPDATE(i)) {
            print_uart(">");
		}
    }
    print_uart("]\r\n");
    flush_done();


    // disable slave select
    write_reg(SPI_SLAVE_SELECT_REG, 0xffffffff);

    // disable spi control master flag
    write_reg(SPI_CONTROL_REG, 0x06);

    return 0;
}
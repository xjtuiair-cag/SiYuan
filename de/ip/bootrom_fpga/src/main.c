#include "uart.h"
#include "spi.h"
#include "sd.h"
#include "dma.h"

int copy(){
    // init sd card
    int ret = init_sd();
    if (ret != 0) {
        print_uart("could not initialize sd... exiting\r\n");
        return -1;
    }
    // flush D cache
    __asm__ volatile("fence.i"); 
    // copy 16M data from sd to ddr
    int res = sd_read_data_with_dma(0x80000000, 0x800, 2 * 16384);

    if (res != 0)
    {
        print_uart("SD card failed!\r\n");
        print_uart("sd copy return value: ");
        print_uart_addr(res);
        print_uart("\r\n");
        return -2;
    }

    print_uart("Copy Linux image from SD card to DDR successful!\r\n");
    return 0;            
}

int main()
{
    init_uart(50000000, 115200);
    print_uart("Welcome to SiYuan!\r\n");
    // copy linux image from SD card to DDR 
    Dma_init();
    copy();

    return 0;
}
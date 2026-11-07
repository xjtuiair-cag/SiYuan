#include "uart.h"
#include "sd.h"
#include "dma.h"

// int copy(){
//     // init sd card
//     int ret = init_sd();
//     if (ret != 0) {
//         print_uart("could not initialize sd... exiting\r\n");
//         return -1;
//     }
//     // flush D cache
//     __asm__ volatile("fence.i"); 
//     // copy 16M data from sd to ddr
//     int res = sd_read_data_with_dma(0x80000000, 0x800, 2 * 16384 + 8192);

//     if (res != 0)
//     {
//         print_uart("SD card failed!\r\n");
//         print_uart("sd copy return value: ");
//         print_uart_addr(res);
//         print_uart("\r\n");
//         return -2;
//     }

//     print_uart("Copy Linux image from SD card to DDR successful!\r\n");
//     return 0;            
// }

int main()
{
    init_uart(50000000, 115200);
    print_uart("Welcome to SiYuan!\r\n");
    // copy linux image from SD card to DDR 
    Dma_init();
    sd_init(50000000);
    print_uart("SD card init Done!\r\n");
    // DMA config
    uint32_t trans_size = 1024 * 1024 * 20; // 20M
    dma_trans_t trans_cfg;
    trans_cfg.src_addr = SD_BASE + 0x8000;
    trans_cfg.des_addr = 0x80000000;
    trans_cfg.rd_burst_len = 16;
    trans_cfg.wr_burst_len = 16;
    trans_cfg.data_volume = trans_size;   
    trans_cfg.mode = SINGLE_RD_TRANS_FIX_ADDR_MODE;
    trans_cfg.rd_pending_volume = 1024*4; // when read 4KB, dma will pending uintil cpu clear pending bit
    trans_cfg.wr_pending_volume = 0;
    __asm__ volatile("fence.i"); 
    print_uart("START LOADING [");
    // int tot_trans = 256 * 20; // 256 * 20 * 4Kb = 20M
    int sector = 0x800;
    int size_per_trans = 8; // 512 * 8 = 4Kb
    // sector
    // copy linux image from SD card to DDR
    // for (int i = 0; i < tot_trans; i++) {
    //     sd_read_with_dma(&trans_cfg, sector, size_per_trans);   
    //     sector += 8; 
    //     trans_cfg.des_addr += size_per_trans * 512;
    //     if ((i % 32) == 0)
    //     {
    //         print_uart(">");
    //     } 
    // }

    Dma_trans_cfg(&trans_cfg,1,0);
    Dma_start();
    for (int i=0;i<(trans_size/(1024*4));i++) {
        while (is_read_pending() == 0);
        // start SD controller to trans data from SD card to buffer in SD controller
        sd_read_with_no_trans(sector,size_per_trans);
        clear_read_pending();
        sector += 8;
        if ((i % 32) == 0)
        {
            print_uart(">");
        } 
    }
    // check if dma trans is done
    while(1) {
        if (is_Dma_done()){
            break;
        }
    }

    print_uart("]\r\n"); 
    __asm__ volatile("fence.i"); 
    print_uart("Copy Linux image from SD card to DDR successful!\r\n");

    return 0;
}
// +FHDR------------------------------------------------------------------------
// Copyright ownership belongs to CAG laboratory, Institute of Artificial
// Intelligence and Robotics, Xi'an Jiaotong University, shall not be used in
// commercial ways without permission.
// -----------------------------------------------------------------------------
// FILE NAME  : main.c
// DEPARTMENT : CAG of IAIR
// AUTHOR     : XXXX
// AUTHOR'S EMAIL :XXXX@mail.xjtu.edu.cn
// -----------------------------------------------------------------------------
// Ver 1.0  2019--01--01 initial version.
// -----------------------------------------------------------------------------

#include "uart.h"
#include "dma.h"
#include "sd.h"
#include "regmap.h"

uint8_t *ref_arr = (uint8_t *)0x80100000UL;
uint8_t *dst_arr = (uint8_t *)0x80300000UL; // in shared sram

uint32_t src_sector = 0;
uint32_t sd_count = 2; // 512B*2

int sd_check(uint64_t * src, uint64_t * ref, int len){
    uint64_t src_data;
    uint64_t ref_data;
    uint8_t error = 0;
    for (int i=0;i<(len>>3);i++){
        src_data = src[i];
        ref_data = ref[i];
        if (src_data != ref_data) {
            print_uart("Wrong Address: ");
            print_uart_addr(i);
            print_uart("\r\n");
            error = -1;
            break;
        }
    }
    return error;
}

int main()
{
    // ----------------- SD card controller test case 0 -------------------
    // test SD card read
    // read length : 1KB
    // source : sd card setcor : 0
    // destnation : DDR : 0x80300000 
    init_uart(50000000, 115200);
    // init SD card
    sd_init(50000000);
    uint64_t * buf = (uint64_t *) dst_arr;
    // init buffer
    for (int i=0;i<512;i++) {
        buf[i] = i;
    }
    // read 
    sd_write(dst_arr,src_sector,sd_count);
    sd_read(ref_arr,src_sector,sd_count);

    uint32_t error = sd_check((uint64_t*)dst_arr, (uint64_t*)ref_arr, sd_count*512);
    // finish 
    volatile uint32_t * done_addr = (uint32_t *)0x42000000;
	*done_addr = error; // if error = 0, TEST pass, othewise TEST fail

    while (1);  // do nothing
}

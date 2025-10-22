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
#include "fft.h"


uint8_t *data_arr = (uint8_t *)0x81100000UL;
uint8_t *ref_arr  = (uint8_t *)0x82000000UL;

int check(uint64_t * src, uint64_t * ref, int len){
    uint64_t src_data;
    uint64_t ref_data;
    uint8_t error = 0;
    for (int i=0;i<(len>>3);i++){
        src_data = src[i];
        ref_data = ref[i];
        if (src_data != ref_data) {
            print_uart("Wrong Address: ");
            print_uart_addr(i);
            error = -1;
            break;
        }
    }
    return error;
}

int main()
{
    init_uart(50000000, 115200);
    // print_uart("---------FFT TEST CASE 0: fft length 16--------!\r\n");

    uint32_t N = 16;
    uint32_t tot_level = 4;
    uint64_t input_base = 0x81000000; 
    uint64_t output_base = 0x81100000;
    // each element 8 Byte
    uint64_t weight_base = input_base + N*8; 

    // fft_init();
    fft_load_wt(weight_base, 0x1, tot_level);
    fft_load(input_base, 0x1, tot_level, LD_REV_MODE, 0x1, 0x0);
    // | total level | cur level | rd ocm addr | wr ocm addr | mode
    uint32_t last_level = 0;
    for (int i=0; i<tot_level; i++) {
        last_level = (i == tot_level-1) ? 1 : 0;
        fft_exe(tot_level, i, 0x0, 0x0, last_level);
    }
    // store
    fft_store(output_base, N >> 1, tot_level, 0x0);
    // wait fft done
    while (!fft_idle());

    uint8_t error = check((uint64_t*)data_arr, (uint64_t*)ref_arr, N << 3);
    // check 1024 Byte
    if(error < 0){
        print_uart("---------FFT TEST CASE 0 FAILED--------\r\n");
    }  else {
        print_uart("---------FFT TEST CASE 0 SUCCESS--------\r\n");
    }
    while (1);  // do nothing
}

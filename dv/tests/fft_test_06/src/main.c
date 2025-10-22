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
    // print_uart("---------FFT TEST CASE 0: fft length 8192--------!\r\n");

    uint32_t N = 16384;
    uint32_t tot_level = 14;
    uint64_t input_base = 0x81000000; 
    uint64_t output_base = 0x81100000;

    uint8_t *data_arr = (uint8_t *)(0x81100000UL + N*(tot_level-10)*8);
    uint8_t *ref_arr  = (uint8_t *)0x82000000UL;

    // each element 8 Byte
    uint64_t weight_base = input_base + N*8; 

    uint32_t reverse_base = 0x0;
    uint32_t weight_stride = N / 2 / 512;
    uint32_t output_addr = output_base;
    // fft_init();
    // ---------------compute phase : 0----------------------------
    fft_load_wt(weight_base, weight_stride, tot_level, 0x1); 
    for (int p = 0; p < (N / 1024); p++) {
        fft_load(input_base, 0x1, tot_level, LD_REV_MODE, 0x1, 0x0, reverse_base);
        // | total level | cur level | rd ocm addr | wr ocm addr | mode
        uint32_t last_level = 0;
        for (int i=0; i<FFT_MAX_LEVEL; i++) {
            last_level = (i == FFT_MAX_LEVEL-1) ? 1 : 0;
            fft_exe(tot_level, i, 0x0, 0x0, last_level);
        }
        // store
        fft_store(output_addr, 512, tot_level, 0x0);
        output_addr += 1024*8;
        reverse_base += 1024;
    }
    weight_stride = weight_stride / 2;
    // fence 
    fft_fence();

    uint32_t load_wt_cnt;
    uint32_t load_wt_tot_cnt;
    uint32_t load_wt_cnt_stride;
    uint32_t weight_addr = weight_base;
    uint32_t cur_level = 10;
    uint32_t inner_addr = 0;
    // ---------------compute phase : 1----------------------------   
    for (int p = 0; p < (tot_level - 10); p++) {
        output_addr = output_base + p*N*8;
        weight_addr = weight_base;
        load_wt_cnt = 0;
        load_wt_cnt_stride = N / (1 << (cur_level+1));  
        load_wt_tot_cnt = 1 << (cur_level-9);
        weight_stride = N / (1 << (cur_level+1));

        for (int i = 0; i < (N / 1024); i++) {
            if (i == load_wt_cnt) {
                fft_load_wt(weight_addr, weight_stride, tot_level, 0x1); 
                load_wt_cnt += load_wt_cnt_stride;
                weight_addr += N * 8 / 2 / load_wt_tot_cnt;
                inner_addr = output_addr + 512 * 8 * (i / load_wt_cnt_stride);
            }
            fft_load(inner_addr, 1024 * (1 << p), tot_level, LD_INCR_MODE, 0x1, 0x0, 0x0);   
            fft_exe(tot_level, cur_level, 0x0, 0x0, 1);
            fft_store(inner_addr+N*8,1024 * (1 << p), tot_level, 0x0);
            inner_addr += 2048 * 8 * (1 << p);
        }
        cur_level++;
    }

    // wait fft done
    while (!fft_idle());

    uint8_t error = check((uint64_t*)data_arr, (uint64_t*)ref_arr, N << 3);
    if(error < 0){
        print_uart("---------FFT TEST CASE 0 FAILED--------\r\n");
    }  else {
        print_uart("---------FFT TEST CASE 0 SUCCESS--------\r\n");
    }
    while (1);  // do nothing
}

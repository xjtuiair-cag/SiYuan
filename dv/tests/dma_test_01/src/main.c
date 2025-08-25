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

void dma_check(unsigned long src, unsigned long des, int len){
    unsigned long * src_loc = (unsigned long*) src;
    unsigned long * des_loc = (unsigned long*) des;
    unsigned long src_data;
    unsigned long des_data;
    for (int i=0;i<(len<<2);i++){
        src_data = *src_loc;
        des_data = *des_loc;
        print_uart_addr((unsigned long)src_loc);
        print_uart("--");
        print_uart_addr((unsigned long)des_loc);
        print_uart(":  ");
        if (src_data == des_data) {
            print_uart("Right!\n");
        } else {
            print_uart("Wrong!!!\n");
        }

        src_loc += 8;
        des_loc += 8;
    }
}

int main()
{
    init_uart(50000000, 115200);
    print_uart("Hello World!\r\n");
    // Trans data from CPU Mem to NPU Mem
    Dma_trans(0x9a200000,0xA0000000,16,1024);
    Dma_start();
    // check if dma trans is done
    while(1) {
        if (is_Dma_done()){
            break;
        }
    }
    flush_done();
    print_uart("Transaction from CPU to NPU Done!\r\n");
    // Trans data from NPU Mem to CPU Mem
    Dma_trans(0xA0000000,0x9a200000,16,1024);
    Dma_start();
    // check if dma trans is done
    while(1) {
        if (is_Dma_done()){
            break;
        }
    }
    flush_done();
    print_uart("Transaction from NPU to CPU Done!\r\n");
    // check if dma trans is right
    dma_check(0x80200000,0x80400000,1024);
    while (1);  // do nothing
}

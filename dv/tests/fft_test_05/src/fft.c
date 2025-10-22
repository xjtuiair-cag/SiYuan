#include "fft.h"
#include "uart.h"
#include "utils.h"
void fft_init()
{
    print_uart("init FFT\r\n");
    // flush entire fft
    write_reg(FFT_CTRL_REG, 0x2);
    uint32_t status = read_reg(FFT_STATUS_REG); 
    print_uart("status: 0x");
    print_uart_addr(status);
    print_uart("\r\n");
    print_uart("FFT initialized!\r\n");
}

int fft_idle()
{
    uint32_t status = read_reg(FFT_STATUS_REG);
    uint8_t iq_empty = (status & STATUS_IQ_EMPTY_MASK) != 0;
    uint8_t lsu_idle = (status & STATUS_LSU_IDLE_MASK) != 0;
    uint8_t exe_idle = (status & STATUS_EXE_IDLE_MASK) != 0;
    uint32_t fft_idle = iq_empty & lsu_idle & exe_idle;
    // fft_idle != 0 means fft is idle and previous work is done
    return fft_idle;
}

void fft_fence(){
    // check if fft issue queue is full
    uint32_t status = read_reg(FFT_STATUS_REG);
    // issue queue full
    while ((status & 0x1) == 0x1) {
        status = read_reg(FFT_STATUS_REG);
    };
    // write flag
    write_reg(FFT_DATA3_REG, FENCE_FLAG);
    // insert instr to issue queue
    write_reg(FFT_CTRL_REG,0x1);
}

void fft_load_wt(uint64_t base_addr, uint32_t stride, uint32_t tot_level, uint32_t lds){
    // check if fft issue queue is full
    uint32_t status = read_reg(FFT_STATUS_REG);
    // issue queue full
    while ((status & 0x1) == 0x1) {
        status = read_reg(FFT_STATUS_REG);
    };
    write_reg(FFT_DATA0_REG, (uint32_t) base_addr);         // low 32 bit
    write_reg(FFT_DATA1_REG, (uint32_t)(base_addr >> 32));  // high 32 bit
    write_reg(FFT_DATA2_REG, stride);
    // write flag
    write_reg(FFT_DATA3_REG, LOAD_WT_FLAG | (tot_level << TOT_LEVEL_LOC) | (lds << LDS_LOC));
    // insert instr to issue queue
    write_reg(FFT_CTRL_REG,0x1);
}

void fft_load(uint64_t base_addr, uint32_t stride, uint32_t tot_level, uint32_t mode, uint32_t lds, uint32_t ocm_addr,uint16_t reverse_base){
    // check if fft issue queue is full
    uint32_t status = read_reg(FFT_STATUS_REG);
    // issue queue full
    while ((status & 0x1) == 0x1) {
        status = read_reg(FFT_STATUS_REG);
    };
    write_reg(FFT_DATA0_REG, (uint32_t) base_addr);         // low 32 bit
    write_reg(FFT_DATA1_REG, (uint32_t)((base_addr >> 32) | (reverse_base << 16)));  // high 32 bit
    write_reg(FFT_DATA2_REG, stride);
    // write flag
    uint32_t flag = LOAD_DATA_FLAG | (tot_level << TOT_LEVEL_LOC) | (mode << MODE_LOC) | (lds << LDS_LOC) | (ocm_addr << WR_OCM_LOC);
    write_reg(FFT_DATA3_REG, flag);
    // insert instr to issue queue
    write_reg(FFT_CTRL_REG,0x1);
}

void fft_exe(uint32_t tot_level, uint32_t cur_level, uint32_t rd_ocm_addr, uint32_t wr_ocm_addr, uint32_t mode){
    // check if fft issue queue is full
    uint32_t status = read_reg(FFT_STATUS_REG);
    // issue queue full
    while ((status & 0x1) == 0x1) {
        status = read_reg(FFT_STATUS_REG);
    };
    // write flag
    uint32_t flag = EXE_FLAG | (tot_level << TOT_LEVEL_LOC) | (cur_level << CUR_LEVEL_LOC) | (rd_ocm_addr << RD_OCM_LOC) | (wr_ocm_addr << WR_OCM_LOC) | (mode << MODE_LOC);
    write_reg(FFT_DATA3_REG, flag);
    // insert instr to issue queue
    write_reg(FFT_CTRL_REG,0x1);
}

void fft_store(uint64_t base_addr,uint32_t stride, uint32_t tot_level, uint32_t ocm_addr){
    // check if fft issue queue is full
    uint32_t status = read_reg(FFT_STATUS_REG);
    // issue queue full
    while ((status & 0x1) == 0x1) {
        status = read_reg(FFT_STATUS_REG);
    };   
    write_reg(FFT_DATA0_REG, (uint32_t) base_addr);         // low 32 bit
    write_reg(FFT_DATA1_REG, (uint32_t)(base_addr >> 32));  // high 32 bit
    write_reg(FFT_DATA2_REG, stride);
    // write flag
    uint32_t flag = STORE_DATA_FLAG | (tot_level << TOT_LEVEL_LOC) | (ocm_addr << RD_OCM_LOC);
    write_reg(FFT_DATA3_REG, flag);
    // insert instr to issue queue
    write_reg(FFT_CTRL_REG,0x1);
}


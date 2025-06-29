#include "dma.h"

void write_reg_u32(uintptr_t addr, uint32_t value)
{
    volatile uint32_t *loc_addr = (volatile uint32_t *)addr;
    *loc_addr = value;
}


void Dma_trans(uint32_t src, uint32_t des, uint32_t burst_len, uint32_t volume, uint32_t mode){
    write_reg_u32(SRC_BASE_ADDR, src);
    write_reg_u32(DES_BASE_ADDR, des);
    write_reg_u32(DATA_VOLUME, volume);
    write_reg_u32(BURST_LEN, burst_len);
    write_reg_u32(TRANS_MODE, mode);
}
void Dma_start() {
    uint32_t ctrl = 0;
    ctrl |= (1 << START_LOC);
    write_reg_u32(TRANS_CTRL, ctrl);
}

uint32_t is_Dma_done() {
    uintptr_t addr = TRANS_CTRL;
    uint32_t ctrl = *(volatile uint32_t *)addr;
    return ctrl & (1 << DONE_LOC);
}
void flush_done () {
    write_reg_u32(TRANS_CTRL,0);
}
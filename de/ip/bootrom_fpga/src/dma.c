#include "dma.h"

void write_reg_u64(uintptr_t addr, uint64_t value)
{
    volatile uint64_t *loc_addr = (volatile uint64_t *)addr;
    *loc_addr = value;
}
void write_reg_u32(uintptr_t addr, uint32_t value)
{
    volatile uint32_t *loc_addr = (volatile uint32_t *)addr;
    *loc_addr = value;
}

void Dma_trans(uint64_t src, uint64_t des, uint32_t burst_len, uint64_t volume){
    write_reg_u64(SRC_BASE_ADDR, src);
    write_reg_u64(DES_BASE_ADDR, des);
    write_reg_u64(DATA_VOLUME, volume);
    write_reg_u32(BURST_LEN, burst_len);
}
void Dma_start() {
    write_reg_u32(TRANS_START, 1);
}

uint8_t is_Dma_done() {
    uintptr_t addr = TRANS_DONE;
    return *(volatile uint8_t *)addr;
}
void flush_done () {
    write_reg_u32(TRANS_DONE,0);
}
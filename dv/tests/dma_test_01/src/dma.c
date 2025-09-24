#include "dma.h"
#include "utils.h"

void Dma_init(){
    // Reset DMA
    write_reg_u32(TRANS_CTRL, (1 << RD_RESET_LOC) |  (1 << WR_RESET_LOC));
    // whether DMA reset Done
    uint32_t ctrl;
    while(1){
        ctrl = read_reg(TRANS_CTRL);
        if (((ctrl & (1 << RD_RESET_LOC)) | (ctrl & (1 << WR_RESET_LOC))) == 0)
            break;
    };
    // Clear CTRL reg and STATUS reg
    write_reg_u32(TRANS_CTRL, 0);
    write_reg_u32(STATUS, 0);
}

void Dma_trans_cfg(uint32_t src, uint32_t des, uint32_t rd_burst_len, uint32_t wr_burst_len, uint32_t volume, uint32_t mode){
    write_reg_u32(SRC_BASE_ADDR, src);
    write_reg_u32(DES_BASE_ADDR, des);
    write_reg_u32(DATA_VOLUME, volume);
    write_reg_u32(TRANS_MODE, mode);
    write_reg_u32(BURST_LEN, rd_burst_len | (wr_burst_len << 8));
}
void Dma_start() {
    write_reg_u32(TRANS_CTRL, (1 << START_LOC));
}

uint8_t is_read_pending(){
    return read_reg(STATUS) & (1 << RD_PENDING_LOC);
}

void clear_read_pending(){
    uint32_t status = read_reg(STATUS);
    write_reg_u32(STATUS, status & (~(1 << RD_PENDING_LOC)));
}

uint8_t is_Dma_done() {
    return read_reg(STATUS) & (1 << DONE_LOC);
}
void flush_done () {
    write_reg_u32(STATUS,0);
}
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

void Dma_trans_cfg(dma_trans_t * trans_cfg, uint32_t rd_single_step, uint32_t wr_single_step){
    write_reg_u32(SRC_BASE_ADDR, trans_cfg->src_addr);
    write_reg_u32(DES_BASE_ADDR, trans_cfg->des_addr);
    write_reg_u32(DATA_VOLUME, trans_cfg->data_volume);
    write_reg_u32(TRANS_MODE, trans_cfg->mode);
    write_reg_u32(BURST_LEN, trans_cfg->rd_burst_len | (trans_cfg->wr_burst_len << 8));
    write_reg_u32(BURST_LEN, trans_cfg->rd_burst_len | (trans_cfg->wr_burst_len << 8));
    if (rd_single_step) {
        write_reg_u32(RD_PENDING_VOLUME, trans_cfg->rd_pending_volume);
    }
    if (wr_single_step) {
        write_reg_u32(WR_PENDING_VOLUME, trans_cfg->wr_pending_volume);
    }
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

uint8_t is_write_pending(){
    return read_reg(STATUS) & (1 << WR_PENDING_LOC);
}

void clear_write_pending(){
    uint32_t status = read_reg(STATUS);
    write_reg_u32(STATUS, status & (~(1 << WR_PENDING_LOC)));
}

uint8_t is_Dma_done() {
    return read_reg(STATUS) & (1 << WR_DONE_LOC);
}
void flush_done () {
    write_reg_u32(STATUS,0);
}
#ifndef	_FFT_H
#define	_FFT_H

#include <stdint.h>

#define FFT_MAX_LEVEL   10
#define FFT_BASE 0x40000

#define FFT_CTRL_REG            FFT_BASE + 0x0
#define FFT_DATA0_REG           FFT_BASE + 0x4
#define FFT_DATA1_REG           FFT_BASE + 0x8
#define FFT_DATA2_REG           FFT_BASE + 0xC
#define FFT_DATA3_REG           FFT_BASE + 0x10
#define FFT_STATUS_REG          FFT_BASE + 0x14

#define LOAD_OP_FLAG            0x0
#define STORE_OP_FLAG           0x1
#define EXE_OP_FLAG             0x2
#define FENCE_OP_FLAG           0x3
#define LOAD_WT_EN              (0x1 << 3)

#define TOT_LEVEL_LOC           0x5
#define CUR_LEVEL_LOC           0x9
#define MODE_LOC                0x2
#define LDS_LOC                 0x4
#define RD_OCM_LOC              0xD
#define WR_OCM_LOC              0x15

#define IQ_LEN                  0x16
#define IQ_WTH                  0x4
#define STATUS_IQ_FULL_LOC      0x0
#define STATUS_IQ_EMPTY_LOC     0x1
#define STATUS_IQ_CNT_LOC       0x2
#define STATUS_LSU_IDLE_LOC     (STATUS_IQ_CNT_LOC + IQ_WTH)
#define STATUS_EXE_IDLE_LOC     (STATUS_LSU_IDLE_LOC + 0x1)  

#define STATUS_IQ_FULL_MASK     (0x1 << STATUS_IQ_FULL_LOC) 
#define STATUS_IQ_EMPTY_MASK    (0x1 << STATUS_IQ_EMPTY_LOC) 
#define STATUS_LSU_IDLE_MASK    (0x1 << STATUS_LSU_IDLE_LOC)
#define STATUS_EXE_IDLE_MASK    (0x1 << STATUS_EXE_IDLE_LOC)  

#define LOAD_WT_FLAG            LOAD_OP_FLAG | LOAD_WT_EN 
#define LOAD_DATA_FLAG          LOAD_OP_FLAG 
#define STORE_DATA_FLAG         STORE_OP_FLAG
#define EXE_FLAG                EXE_OP_FLAG 
#define FENCE_FLAG              FENCE_OP_FLAG

#define LD_REV_MODE             0x0
#define LD_INCR_MODE            0x1

void fft_init();

int fft_idle();

void fft_load_wt(uint64_t base_addr,uint32_t stride, uint32_t tot_level, uint32_t lds);

void fft_load(uint64_t base_addr,uint32_t stride, uint32_t tot_level, uint32_t mode, uint32_t lds, uint32_t ocm_addr,uint16_t reverse_base);

void fft_exe(uint32_t tot_level, uint32_t cur_level, uint32_t rd_ocm_addr, uint32_t wr_ocm_addr, uint32_t mode);

void fft_store(uint64_t base_addr,uint32_t stride, uint32_t tot_level, uint32_t ocm_addr);

void fft_fence();

#endif  /*_FFT_H_*/
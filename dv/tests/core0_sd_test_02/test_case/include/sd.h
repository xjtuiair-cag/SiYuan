#ifndef	_SD_H
#define	_SD_H

#include <stdint.h>

#define SD_BASE 0x41850000

#define SD_WR_ADDR_SD      SD_BASE + 0x0
#define SD_WR_ADDR_DMA     SD_BASE + 0x8
#define SD_WR_BLKCNT       SD_BASE + 0x10 
#define SD_WR_REQ_RD       SD_BASE + 0x18
#define SD_WR_REQ_WR       SD_BASE + 0x20
#define SD_WR_IRQ_EN       SD_BASE + 0x28
#define SD_WR_SYS_RST      SD_BASE + 0x30

#define SD_RD_ADDR_SD_F    SD_BASE + 0x0
#define SD_RD_ADDR_DMA_F   SD_BASE + 0x8
#define SD_RD_STATUS       SD_BASE + 0x10 
#define SD_RD_ERROR        SD_BASE + 0x18
#define SD_RD_INIT_STATE   SD_BASE + 0x20
#define SD_RD_COUNTER      SD_BASE + 0x28
#define SD_RD_INIT_FSM     SD_BASE + 0x30
#define SD_RD_TRAN_STATE   SD_BASE + 0x38
#define SD_RD_TRAN_FSM     SD_BASE + 0x40

#define SD_STATUS_REQ_RD        0x00000001
#define SD_STATUS_REQ_WR        0x00000002
#define SD_STATUS_IRQ_EN        0x00000004
#define SD_STATUS_SD_IRQ        0x00000008
#define SD_STATUS_REQ_RDY       0x00000010
#define SD_STATUS_INIT_DONE     0x00000020
#define SD_STATUS_HCXC          0x00000040
#define SD_STATUS_SD_DETECT     0x00000080

enum {
  _piton_sd_ADDR_SD     ,
  _piton_sd_ADDR_DMA    ,
  _piton_sd_BLKCNT      ,
  _piton_sd_REQ_RD      ,
  _piton_sd_REQ_WR      ,
  _piton_sd_IRQ_EN      ,
  _piton_sd_SYS_RST     ,
  _piton_sd_WR_CLK_DIV  ,    
  _piton_sd_INIT_CNT
};

enum {
  _piton_sd_ADDR_SD_F   ,
  _piton_sd_ADDR_DMA_F  ,
  _piton_sd_STATUS      ,
  _piton_sd_ERROR       ,
  _piton_sd_INIT_STATE  ,
  _piton_sd_COUNTER     ,
  _piton_sd_INIT_FSM    ,
  _piton_sd_TRAN_STATE  ,
  _piton_sd_TRAN_FSM    ,
  _piton_sd_RD_CLK_DIV  ,
  _piton_sd_RD_INIT_CNT
};

enum {
  _piton_sd_STATUS_REQ_RD       = (0x00000001),
  _piton_sd_STATUS_REQ_WR       = (0x00000002),
  _piton_sd_STATUS_IRQ_EN       = (0x00000004),
  _piton_sd_STATUS_SD_IRQ       = (0x00000008),
  _piton_sd_STATUS_REQ_RDY      = (0x00000010),
  _piton_sd_STATUS_INIT_DONE    = (0x00000020),
  _piton_sd_STATUS_HCXC         = (0x00000040),
  _piton_sd_STATUS_SD_DETECT    = (0x00000080)
};

enum { _piton_sd_NUM_MINORS = 16 };

void sd_init(); 
int sd_read (uint8_t *buff, uint32_t sector, uint32_t count);
int sd_write(uint8_t *buff, uint32_t sector, uint32_t count);
#endif  /*_SD_H_*/
package sy_soc_pkg;
//----------------------------------------------------------------------------------------------------------------------
// SOC parameters
//----------------------------------------------------------------------------------------------------------------------
parameter integer CORE_NUM = 4;
parameter integer ADDR_WIDTH = 64;

parameter DBGBase        = 64'h0000_0000;
parameter DBGLength      = 64'h1000;
parameter DRAMBase       = 64'h8000_0000;
parameter DRAMLength     = 64'hF_8000_0000; 
parameter PLICBase       = 64'h0C00_0000;
parameter PLICLength     = 64'h0400_0000;
parameter CLINTBase      = 64'h0200_0000;
parameter CLINTLength    = 64'hC0000;

parameter UARTBase       = 64'h4181_0000;
parameter UARTLength     = 64'h1_0000;
parameter DMABase        = 64'h4182_0000;
parameter DMALength      = 64'h1_0000;
parameter REGMAPBase     = 64'h4184_0000;
parameter REGMAPLength   = 64'h1_0000;
parameter SDBase        = 64'h4185_0000;
parameter SDLength      = 64'h7B_0000;

parameter BOOTROMBase    = 64'h4200_0000;
parameter BOOTROMLength  = 64'h3E00_0000;

parameter ReservedBase   = {64{1'b1}};
parameter ReservedLength = 1;

parameter logic [ADDR_WIDTH-1:0] DEBUG_START  = DBGBase;
parameter logic [ADDR_WIDTH-1:0] DEBUG_END    = DBGBase + DBGLength - 1;

parameter logic [ADDR_WIDTH-1:0] REGMAP_START  = REGMAPBase;
parameter logic [ADDR_WIDTH-1:0] REGMAP_END    = REGMAPBase + REGMAPLength - 1;

parameter logic [ADDR_WIDTH-1:0] DRAM_START  = DRAMBase;
parameter logic [ADDR_WIDTH-1:0] DRAM_END    = DRAMBase + DRAMLength - 1;

parameter logic [ADDR_WIDTH-1:0] PLIC_START  = PLICBase;
parameter logic [ADDR_WIDTH-1:0] PLIC_END    = PLICBase + PLICLength - 1;

parameter logic [ADDR_WIDTH-1:0] CLINT_START = CLINTBase;
parameter logic [ADDR_WIDTH-1:0] CLINT_END   = CLINTBase + CLINTLength - 1;

parameter logic [ADDR_WIDTH-1:0] UART_START  = UARTBase;
parameter logic [ADDR_WIDTH-1:0] UART_END    = UARTBase + UARTLength - 1;

parameter logic [ADDR_WIDTH-1:0] DMA_START   = DMABase;
parameter logic [ADDR_WIDTH-1:0] DMA_END     = DMABase + DMALength - 1;

parameter logic [ADDR_WIDTH-1:0] SD_START   = SDBase;
parameter logic [ADDR_WIDTH-1:0] SD_END     = SDBase + SDLength - 1;

parameter logic [ADDR_WIDTH-1:0] BOOTROM_START  = BOOTROMBase;
parameter logic [ADDR_WIDTH-1:0] BOOTROM_END    = BOOTROMBase + BOOTROMLength - 1;

parameter logic [ADDR_WIDTH-1:0] RESERVED_START   = ReservedBase;
parameter logic [ADDR_WIDTH-1:0] RESERVED_END     = ReservedBase+ ReservedLength - 1;
    
// location in each bus
parameter DMEM      = 0;
parameter CTRL_BUS  = 1;
parameter PHRI_BUS  = 2;
parameter DMA_BUS   = 3;
// control bus
parameter REGMAP = 0;
parameter PLIC   = 1;
parameter CLINT  = 2;
// peripheral bus
parameter UART      = 0;
parameter SPI       = 1;
parameter AXIL32    = 2;
// FFT bus
parameter DEBUG     = 0;
parameter DMA       = 1;
// system bus
parameter SYS_BUS_REGION     = 3;
parameter SYS_BUS_SLAVE_NUM  = 4;
parameter SYS_BUS_SRC_LSB    = 2;
parameter SYS_BUS_SRC_MSB    = SYS_BUS_SRC_LSB + $clog2($clog2(CORE_NUM)+2);
// control bus
parameter CTRL_BUS_REGION    = 1;
parameter CTRL_BUS_SLAVE_NUM = 3;
parameter CTRL_BUS_SRC_LSB   = SYS_BUS_SRC_MSB;
parameter CTRL_BUS_SRC_MSB   = CTRL_BUS_SRC_LSB + 1;
// peripheral bus
parameter PHRI_BUS_REGION    = 1;     
parameter PHRI_BUS_SLAVE_NUM = 3;
parameter PHRI_BUS_SRC_LSB   = SYS_BUS_SRC_MSB;
parameter PHRI_BUS_SRC_MSB   = PHRI_BUS_SRC_LSB + 1;
// dma bus
parameter DMA_BUS_REGION    = 1;     
parameter DMA_BUS_SLAVE_NUM = 2;
parameter DMA_BUS_SRC_LSB   = SYS_BUS_SRC_MSB;
parameter DMA_BUS_SRC_MSB   = DMA_BUS_SRC_LSB + 1;
// mem bus
parameter MEM_BUS_REGION    = 1;     
parameter MEM_BUS_SLAVE_NUM = 1;
parameter MEM_BUS_MASTER_NUM= 2;
parameter MEM_BUS_SRC_LSB   = DMA_BUS_SRC_MSB;
parameter MEM_BUS_SRC_MSB   = MEM_BUS_SRC_LSB + $clog2(MEM_BUS_MASTER_NUM);
// debug ID 
parameter DEBUG_SOURCE_ID = {3'b000,2'b00,(MEM_BUS_SRC_LSB-2)'($clog2(CORE_NUM))};
parameter DMA_SOURCE_ID   = {3'b000,2'b01,(MEM_BUS_SRC_LSB-2)'($clog2(CORE_NUM))};

// system bus addr
parameter logic [SYS_BUS_SLAVE_NUM-1:0][SYS_BUS_REGION-1:0][ADDR_WIDTH-1:0]sys_bus_start_addr = {
    {RESERVED_START ,DEBUG_START,    DMA_START},
    {BOOTROM_START  ,UART_START,     SD_START},
    {REGMAP_START,   PLIC_START,     CLINT_START},
    {RESERVED_START, RESERVED_START, DRAM_START}
};
parameter logic [SYS_BUS_SLAVE_NUM-1:0][SYS_BUS_REGION-1:0][ADDR_WIDTH-1:0]sys_bus_end_addr = {
    {RESERVED_END ,DEBUG_END,    DMA_END},
    {BOOTROM_END  ,UART_END,     SD_END},
    {REGMAP_END   ,PLIC_END,     CLINT_END},
    {RESERVED_END ,RESERVED_END, DRAM_END}
};
parameter logic [SYS_BUS_SLAVE_NUM-1:0][SYS_BUS_REGION-1:0]sys_bus_region_en = {
    {1'b0,1'b1,1'b1},
    {1'b1,1'b1,1'b1},
    {1'b1,1'b1,1'b1},
    {1'b0,1'b0,1'b1}
};
// control bus addr   
parameter logic  [CTRL_BUS_SLAVE_NUM-1:0][CTRL_BUS_REGION-1:0][ADDR_WIDTH-1:0]ctrl_bus_start_addr = {
    {CLINT_START,       PLIC_START,     REGMAP_START}      
};
parameter logic [CTRL_BUS_SLAVE_NUM-1:0][CTRL_BUS_REGION-1:0][ADDR_WIDTH-1:0]ctrl_bus_end_addr = {
    {CLINT_END,         PLIC_END,       REGMAP_END}      
};
parameter logic [CTRL_BUS_SLAVE_NUM-1:0][CTRL_BUS_REGION-1:0]ctrl_bus_region_en = {
    {1'b1, 1'b1, 1'b1}
};
// peripheral bus addr
parameter logic [PHRI_BUS_SLAVE_NUM-1:0][PHRI_BUS_REGION-1:0][ADDR_WIDTH-1:0]phri_bus_start_addr = {
    {BOOTROM_START,     SD_START,       UART_START}
};
parameter logic [PHRI_BUS_SLAVE_NUM-1:0][PHRI_BUS_REGION-1:0][ADDR_WIDTH-1:0]phri_bus_end_addr = {
    {BOOTROM_END,     SD_END,       UART_END}
};
parameter logic [PHRI_BUS_SLAVE_NUM-1:0][PHRI_BUS_REGION-1:0]phri_bus_region_en = {
    {1'b1, 1'b1, 1'b1}
};
// dma bus addr
parameter logic [DMA_BUS_SLAVE_NUM-1:0][DMA_BUS_REGION-1:0][ADDR_WIDTH-1:0]dma_bus_start_addr = {
    {DMA_START,DEBUG_START}
};
parameter logic [DMA_BUS_SLAVE_NUM-1:0][DMA_BUS_REGION-1:0][ADDR_WIDTH-1:0]dma_bus_end_addr = {
    {DMA_END,DEBUG_END}
};
parameter logic [DMA_BUS_SLAVE_NUM-1:0][DMA_BUS_REGION-1:0]dma_bus_region_en = {
    {1'b1,1'b1}
};

// mem bus addr
parameter logic [MEM_BUS_SLAVE_NUM-1:0][MEM_BUS_REGION-1:0][ADDR_WIDTH-1:0]mem_bus_start_addr = {{
    64'b0
}};
parameter logic [MEM_BUS_SLAVE_NUM-1:0][MEM_BUS_REGION-1:0][ADDR_WIDTH-1:0]mem_bus_end_addr = {{
    RESERVED_END
}};
parameter logic [MEM_BUS_SLAVE_NUM-1:0][MEM_BUS_REGION-1:0]mem_bus_region_en = {{
    1'b1
}};

endpackage

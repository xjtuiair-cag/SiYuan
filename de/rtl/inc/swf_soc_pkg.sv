// Auto Generated, don't modify!!!
package swf_soc;
parameter integer CORE_NUM = 2;

    parameter UART_EN = 1;
    parameter SPI_EN = 1;
    parameter GPIO_EN = 1;
    parameter DMA_EN = 1;
    parameter ETHERNET_EN = 0;
    
    parameter integer ADDR_WIDTH = 64;
    parameter UARTBase       = 64'h1000_0000;
    parameter UARTLength     = 64'h1000;
    parameter DRAMBase       = 64'h8000_0000;
    parameter DRAMLength     = 64'h4000_0000; 
    parameter PLICBase       = 64'h0C00_0000;
    parameter PLICLength     = 64'h3FF_FFFF;
    parameter CLINTBase      = 64'h0200_0000;
    parameter CLINTLength    = 64'hC0000;
    parameter ROMBase        = 64'h0001_0000;
    parameter ROMLength      = 64'h10000;
    parameter DMABase        = 64'h0;
    parameter DMALength      = 64'h1000;
    parameter SPIBase        = 64'h2000_0000;
    parameter SPILength      = 64'h800000;
    parameter GPIOBase       = 64'h4000_0000;
    parameter GPIOLength     = 64'h1000;
    parameter EthernetBase   = 64'h3000_0000;
    parameter EthernetLength = 64'h1_0000;
    parameter ReservedBase   = {64{1'b1}};
    parameter ReservedLength = 1;
    parameter logic [ADDR_WIDTH-1:0] DRAM_START  = DRAMBase;
    parameter logic [ADDR_WIDTH-1:0] DRAM_END    = DRAMBase + DRAMLength - 1;

    parameter logic [ADDR_WIDTH-1:0] PLIC_START  = PLICBase;
    parameter logic [ADDR_WIDTH-1:0] PLIC_END    = PLICBase + PLICLength - 1;

    parameter logic [ADDR_WIDTH-1:0] CLINT_START = CLINTBase;
    parameter logic [ADDR_WIDTH-1:0] CLINT_END   = CLINTBase + CLINTLength - 1;

    parameter logic [ADDR_WIDTH-1:0] ROM_START   = ROMBase;
    parameter logic [ADDR_WIDTH-1:0] ROM_END     = ROMBase + ROMLength - 1;

    parameter logic [ADDR_WIDTH-1:0] UART_START  = UARTBase;
    parameter logic [ADDR_WIDTH-1:0] UART_END    = UARTBase + UARTLength - 1;

    parameter logic [ADDR_WIDTH-1:0] DMA_START   = DMABase;
    parameter logic [ADDR_WIDTH-1:0] DMA_END     = DMABase + DMALength - 1;

    parameter logic [ADDR_WIDTH-1:0] GPIO_START  = GPIOBase;
    parameter logic [ADDR_WIDTH-1:0] GPIO_END    = GPIOBase + GPIOLength - 1;

    parameter logic [ADDR_WIDTH-1:0] ETH_START   = EthernetBase;
    parameter logic [ADDR_WIDTH-1:0] ETH_END     = EthernetBase + EthernetLength - 1;

    parameter logic [ADDR_WIDTH-1:0] SPI_START   = SPIBase;
    parameter logic [ADDR_WIDTH-1:0] SPI_END     = SPIBase + SPILength - 1;

    parameter logic [ADDR_WIDTH-1:0] RESERVED_START   = ReservedBase;
    parameter logic [ADDR_WIDTH-1:0] RESERVED_END     = ReservedBase+ ReservedLength - 1;
    
    // location in each bus
    parameter DMEM  = 0;
    parameter CTRL_BUS = 1;
    parameter PHRI_BUS = 2;
    // control bus
    parameter ROM   = 0;
    parameter PLIC  = 1;
    parameter CLINT = 2;
    
    // peripheral bus
    parameter UART  = 0;
    parameter SPI   = 1;
    parameter GPIO  = 2;
    parameter DMA   = 3;
    parameter ETHERNET = 0;   
    
    parameter SYS_BUS_REGION     = 4;
    parameter SYS_BUS_SLAVE_NUM  = 3;
    parameter SYS_BUS_SRC_LSB    = 1;
    parameter SYS_BUS_SRC_MSB    = SYS_BUS_SRC_LSB + $clog2(CORE_NUM+1);
    
    parameter CTRL_BUS_REGION    = 1;
    parameter CTRL_BUS_SLAVE_NUM = 3;
    parameter CTRL_BUS_SRC_LSB   = SYS_BUS_SRC_MSB;
    parameter CTRL_BUS_SRC_MSB   = CTRL_BUS_SRC_LSB + 1;
    
    parameter PHRI_BUS_REGION    = 1;     
    parameter PHRI_BUS_SLAVE_NUM = 4;
    parameter PHRI_BUS_SRC_LSB   = SYS_BUS_SRC_MSB;
    parameter PHRI_BUS_SRC_MSB   = PHRI_BUS_SRC_LSB + 1;
    
    parameter logic [SYS_BUS_SLAVE_NUM-1:0][SYS_BUS_REGION-1:0][ADDR_WIDTH-1:0]sys_bus_start_addr = {
    {UART_START,SPI_START,GPIO_START,DMA_START},
{RESERVED_START,ROM_START,PLIC_START,CLINT_START},
{RESERVED_START,RESERVED_START,RESERVED_START,DRAM_START}

    };
    
    parameter logic [SYS_BUS_SLAVE_NUM-1:0][SYS_BUS_REGION-1:0][ADDR_WIDTH-1:0]sys_bus_end_addr = {
    {UART_END,SPI_END,GPIO_END,DMA_END},
{RESERVED_END,ROM_END,PLIC_END,CLINT_END},
{RESERVED_END,RESERVED_END,RESERVED_END,DRAM_END}

    };
    
    parameter logic [SYS_BUS_SLAVE_NUM-1:0][SYS_BUS_REGION-1:0]sys_bus_region_en = {
    {1'b1,1'b1,1'b1,1'b1},
{1'b0,1'b1,1'b1,1'b1},
{1'b0,1'b0,1'b0,1'b1}

    };
    
    parameter logic  [CTRL_BUS_SLAVE_NUM-1:0][CTRL_BUS_REGION-1:0][ADDR_WIDTH-1:0]ctrl_bus_start_addr = {
       {CLINT_START,       PLIC_START,     ROM_START}      
     };
     parameter logic [CTRL_BUS_SLAVE_NUM-1:0][CTRL_BUS_REGION-1:0][ADDR_WIDTH-1:0]ctrl_bus_end_addr = {
       {CLINT_END,         PLIC_END,       ROM_END}      
     };
     parameter logic [CTRL_BUS_SLAVE_NUM-1:0][CTRL_BUS_REGION-1:0]ctrl_bus_region_en = {
       {1'b1, 1'b1, 1'b1}
     };
    
    parameter logic [PHRI_BUS_SLAVE_NUM-1:0][PHRI_BUS_REGION-1:0][ADDR_WIDTH-1:0]phri_bus_start_addr = {
    {DMA_START,GPIO_START,SPI_START,UART_START}

    };
    parameter logic [PHRI_BUS_SLAVE_NUM-1:0][PHRI_BUS_REGION-1:0][ADDR_WIDTH-1:0]phri_bus_end_addr = {
    {DMA_END,GPIO_END,SPI_END,UART_END}

    };
    parameter logic [PHRI_BUS_SLAVE_NUM-1:0][PHRI_BUS_REGION-1:0]phri_bus_region_en = {
    {1'b1,1'b1,1'b1,1'b1}

    };
    
endpackage

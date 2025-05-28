import yaml
import argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--file_path", help="config file path")
    parser.add_argument("-o", "--output", help="output file name")
    args = parser.parse_args()

    file_path = args.file_path
    # Read YAML file
    with open(file_path, "r", encoding="utf-8") as file:
        cfg = yaml.safe_load(file)

    core_num = cfg["Core_num"]
    phri_slave_num = 0
    npu_slave_num = 1
    ctrl_slave_num = 3 # clint/plic/bootrom

    uart_loc     = 0
    spi_loc      = 1
    gpio_loc     = 2
    ethernet_loc = 3

    npu_dram_loc = 0
    dma_loc      = 1
    npu_loc     = 2

    uart_en     = 0 
    spi_en      = 0 
    gpio_en     = 0 
    dma_en      = 0 
    npu_en      = 0
    ethernet_en = 0 

    if cfg["Uart"]: 
        phri_slave_num += 1
        uart_en = 1
    if cfg["SPI"]:
        phri_slave_num += 1
        spi_en = 1
    else:
        gpio_loc = spi_loc
        spi_loc = 0
    if cfg["GPIO"]:
        phri_slave_num += 1
        gpio_en = 1
    else: 
        ethernet_loc = gpio_loc
        gpio_loc = 0
    if cfg["Ethernet"]:
        phri_slave_num += 1
        ethernet_en = 1
    else: 
        ethernet_loc = 0 

    if cfg["DMA"]:
        npu_slave_num += 1
        dma_en = 1
    else: 
        npu_loc = dma_loc
        dma_loc = 0
    if cfg["NPU"]:
        npu_slave_num += 1
        npu_en = 1
    else: 
        npu_loc = 0

    sys_bus_region = max(max(phri_slave_num, ctrl_slave_num),npu_slave_num)
    output = "// Auto Generated, don't modify!!!\npackage sy_soc;\n"
    # add core num
    output += "parameter integer CORE_NUM = {};\n".format(core_num)
    output += '''
    parameter UART_EN = {};
    parameter SPI_EN = {};
    parameter GPIO_EN = {};
    parameter DMA_EN = {};
    parameter NPU_EN = {};
    parameter ETHERNET_EN = {};
    '''.format(uart_en, spi_en, gpio_en, dma_en, npu_en, ethernet_en)
    # add Address Range of each peripheral (don't modified)
    output += '''
    parameter integer ADDR_WIDTH = 64;
    parameter UARTBase       = 64'h1000_0000;
    parameter UARTLength     = 64'h1000;
    parameter DRAMBase       = 64'h8000_0000;
    parameter DRAMLength     = 64'h2000_0000; 
    parameter NPU_DRAMBase   = 64'hA000_0000;
    parameter NPU_DRAMLength = 64'h2000_0000; 
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
    parameter NPUBase        = 64'h2000;
    parameter NPULength      = 64'h1000;
    parameter EthernetBase   = 64'h3000_0000;
    parameter EthernetLength = 64'h1_0000;
    parameter ReservedBase   = {64{1'b1}};
    parameter ReservedLength = 1;
    parameter logic [ADDR_WIDTH-1:0] DRAM_START  = DRAMBase;
    parameter logic [ADDR_WIDTH-1:0] DRAM_END    = DRAMBase + DRAMLength - 1;

    parameter logic [ADDR_WIDTH-1:0] NPU_DRAM_START  = NPU_DRAMBase;
    parameter logic [ADDR_WIDTH-1:0] NPU_DRAM_END    = NPU_DRAMBase + NPU_DRAMLength - 1;

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

    parameter logic [ADDR_WIDTH-1:0] NPU_START   = NPUBase;
    parameter logic [ADDR_WIDTH-1:0] NPU_END     = NPUBase + NPULength - 1;

    parameter logic [ADDR_WIDTH-1:0] GPIO_START  = GPIOBase;
    parameter logic [ADDR_WIDTH-1:0] GPIO_END    = GPIOBase + GPIOLength - 1;

    parameter logic [ADDR_WIDTH-1:0] ETH_START   = EthernetBase;
    parameter logic [ADDR_WIDTH-1:0] ETH_END     = EthernetBase + EthernetLength - 1;

    parameter logic [ADDR_WIDTH-1:0] SPI_START   = SPIBase;
    parameter logic [ADDR_WIDTH-1:0] SPI_END     = SPIBase + SPILength - 1;

    parameter logic [ADDR_WIDTH-1:0] RESERVED_START   = ReservedBase;
    parameter logic [ADDR_WIDTH-1:0] RESERVED_END     = ReservedBase+ ReservedLength - 1;
    '''
    output += '''
    // location in each bus
    parameter DMEM  = 0;
    parameter CTRL_BUS = 1;
    parameter PHRI_BUS = 2;
    parameter NPU_BUS = 3;
    // control bus
    parameter ROM   = 0;
    parameter PLIC  = 1;
    parameter CLINT = 2;
    '''
    output += '''
    // peripheral bus
    parameter UART  = {};
    parameter SPI   = {};
    parameter GPIO  = {};
    parameter ETHERNET = {};   
    '''.format(uart_loc, spi_loc, gpio_loc , ethernet_loc)

    output += '''
    // NPU bus
    parameter NPU_DRAM  = {};
    parameter DMA   = {};
    parameter NPU = {};
    '''.format(npu_dram_loc,dma_loc,npu_loc)

    # System Bus config
    output += '''
    parameter SYS_BUS_REGION     = {};
    parameter SYS_BUS_SLAVE_NUM  = 4;
    parameter SYS_BUS_SRC_LSB    = 1;
    parameter SYS_BUS_SRC_MSB    = SYS_BUS_SRC_LSB + $clog2(CORE_NUM+1);
    '''.format(sys_bus_region)
    
    # Control Bus config
    # control bus region always set to 1, so don't modify it
    # control bus slave num always set to 3 (clint/plic/bootrom), so don't modify it
    output += '''
    parameter CTRL_BUS_REGION    = 1;
    parameter CTRL_BUS_SLAVE_NUM = 3;
    parameter CTRL_BUS_SRC_LSB   = SYS_BUS_SRC_MSB;
    parameter CTRL_BUS_SRC_MSB   = CTRL_BUS_SRC_LSB + 1;
    '''
    # peripherals bus config
    # peripherals bus region always set to 1, so don't modify it
    output += '''
    parameter PHRI_BUS_REGION    = 1;     
    parameter PHRI_BUS_SLAVE_NUM = {};
    parameter PHRI_BUS_SRC_LSB   = SYS_BUS_SRC_MSB;
    parameter PHRI_BUS_SRC_MSB   = PHRI_BUS_SRC_LSB + 1;
    '''.format(phri_slave_num)
    output += '''
    parameter NPU_BUS_REGION    = 1;     
    parameter NPU_BUS_SLAVE_NUM = {};
    parameter NPU_BUS_SRC_LSB   = SYS_BUS_SRC_MSB;
    parameter NPU_BUS_SRC_MSB   = NPU_BUS_SRC_LSB + 1;
    '''.format(npu_slave_num)

    # system bus
    phri_region_start = "{"
    phri_region_en    = "{"
    if phri_slave_num < 3: 
        for i in range(3-phri_slave_num):
            phri_region_start += "RESERVED_START,"
            phri_region_en    += "1'b0,"
    if cfg["Uart"]: 
        phri_region_start += "UART_START"
        phri_region_en    += "1'b1"
    if cfg["SPI"]:
        phri_region_start += ",SPI_START"
        phri_region_en    += ",1'b1"
    if cfg["GPIO"]:
        phri_region_start += ",GPIO_START"
        phri_region_en    += ",1'b1"
    if cfg["Ethernet"]:
        phri_region_start += ",ETH_START"
        phri_region_en    += ",1'b1"

    phri_region_start += "},\n"
    phri_region_en    += "},\n"
    phri_region_end = phri_region_start.replace("START","END")


    npu_region_start = "{"
    npu_region_en    = "{"
    if npu_slave_num < sys_bus_region: 
        for i in range(sys_bus_region-npu_slave_num):
            npu_region_start += "RESERVED_START,"
            npu_region_en    += "1'b0,"
    # NPU DMEM
    npu_region_start += "NPU_DRAM_START"
    npu_region_en    += "1'b1"
    if cfg["DMA"]:
        npu_region_start += ",DMA_START"
        npu_region_en    += ",1'b1"
    if cfg["NPU"]:
        npu_region_start += ",NPU_START"
        npu_region_en    += ",1'b1"

    npu_region_start += "},\n"
    npu_region_en    += "},\n"
    npu_region_end = npu_region_start.replace("START","END")


    ctrl_region_start = "{"
    ctrl_region_en    = "{"
    for i in range(sys_bus_region-3):
        ctrl_region_start += "RESERVED_START,"
        ctrl_region_en    += "1'b0,"
    ctrl_region_start += "ROM_START,PLIC_START,CLINT_START},\n"
    ctrl_region_en    += "1'b1,1'b1,1'b1},\n"
    ctrl_region_end = ctrl_region_start.replace("START","END")

    ddr_region_start = "{"
    ddr_region_en    = "{"
    for i in range(sys_bus_region-1):
        ddr_region_start += "RESERVED_START,"
        ddr_region_en    += "1'b0,"
    ddr_region_start += "DRAM_START}\n"
    ddr_region_en    += "1'b1}\n"
    ddr_region_end = ddr_region_start.replace("START","END")

    output += '''
    parameter logic [SYS_BUS_SLAVE_NUM-1:0][SYS_BUS_REGION-1:0][ADDR_WIDTH-1:0]sys_bus_start_addr = {{
    {}{}{}{}
    }};
    '''.format(npu_region_start,phri_region_start,ctrl_region_start,ddr_region_start)
    output += '''
    parameter logic [SYS_BUS_SLAVE_NUM-1:0][SYS_BUS_REGION-1:0][ADDR_WIDTH-1:0]sys_bus_end_addr = {{
    {}{}{}{}
    }};
    '''.format(npu_region_end,phri_region_end,ctrl_region_end,ddr_region_end)
    output += '''
    parameter logic [SYS_BUS_SLAVE_NUM-1:0][SYS_BUS_REGION-1:0]sys_bus_region_en = {{
    {}{}{}{}
    }};
    '''.format(npu_region_en,phri_region_en,ctrl_region_en,ddr_region_en)
    # control bus
    output += '''
    parameter logic  [CTRL_BUS_SLAVE_NUM-1:0][CTRL_BUS_REGION-1:0][ADDR_WIDTH-1:0]ctrl_bus_start_addr = {
       {CLINT_START,       PLIC_START,     ROM_START}      
     };
     parameter logic [CTRL_BUS_SLAVE_NUM-1:0][CTRL_BUS_REGION-1:0][ADDR_WIDTH-1:0]ctrl_bus_end_addr = {
       {CLINT_END,         PLIC_END,       ROM_END}      
     };
     parameter logic [CTRL_BUS_SLAVE_NUM-1:0][CTRL_BUS_REGION-1:0]ctrl_bus_region_en = {
       {1'b1, 1'b1, 1'b1}
     };
    '''
    # phri bus
    phri_bus_start = "}\n"
    phri_bus_en = "}\n"
    phri_slave = ["UART","SPI","GPIO","ETH"]
    for i in range(phri_slave_num):
        if i==0:
            phri_bus_start = phri_slave[i] + "_START" + phri_bus_start
            phri_bus_en    = "1'b1" + phri_bus_en
        else:
            phri_bus_start = phri_slave[i] + "_START," + phri_bus_start
            phri_bus_en    = "1'b1," + phri_bus_en
    phri_bus_start = "{" + phri_bus_start
    phri_bus_en    = "{" + phri_bus_en
    phri_bus_end = phri_bus_start.replace("START","END")

    output += '''
    parameter logic [PHRI_BUS_SLAVE_NUM-1:0][PHRI_BUS_REGION-1:0][ADDR_WIDTH-1:0]phri_bus_start_addr = {{
    {}
    }};
    parameter logic [PHRI_BUS_SLAVE_NUM-1:0][PHRI_BUS_REGION-1:0][ADDR_WIDTH-1:0]phri_bus_end_addr = {{
    {}
    }};
    parameter logic [PHRI_BUS_SLAVE_NUM-1:0][PHRI_BUS_REGION-1:0]phri_bus_region_en = {{
    {}
    }};
    '''.format(phri_bus_start,phri_bus_end,phri_bus_en)
    # NPU bus
    npu_bus_start = "}\n"
    npu_bus_en = "}\n"
    npu_slave = ["NPU_DRAM","DMA","NPU"]
    for i in range(npu_slave_num):
        if i==0:
            npu_bus_start = npu_slave[i] + "_START" + npu_bus_start
            npu_bus_en    = "1'b1" + npu_bus_en
        else:
            npu_bus_start = npu_slave[i] + "_START," + npu_bus_start
            npu_bus_en    = "1'b1," + npu_bus_en
    npu_bus_start = "{" + npu_bus_start
    npu_bus_en    = "{" + npu_bus_en
    npu_bus_end = npu_bus_start.replace("START","END")

    output += '''
    parameter logic [NPU_BUS_SLAVE_NUM-1:0][NPU_BUS_REGION-1:0][ADDR_WIDTH-1:0]npu_bus_start_addr = {{
    {}
    }};
    parameter logic [NPU_BUS_SLAVE_NUM-1:0][NPU_BUS_REGION-1:0][ADDR_WIDTH-1:0]npu_bus_end_addr = {{
    {}
    }};
    parameter logic [NPU_BUS_SLAVE_NUM-1:0][NPU_BUS_REGION-1:0]npu_bus_region_en = {{
    {}
    }};
    '''.format(npu_bus_start,npu_bus_end,npu_bus_en)

    output += "\nendpackage\n"

    with open(args.output, "w") as file:
        file.writelines(output)
    # print(output)

// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_soc_fpga.v
// DEPARTMENT : CAG of IAIR
// AUTHOR     : shenghuanliu
// AUTHOR'S EMAIL :liushenghuan2002@gmail.com
// -----------------------------------------------------------------------------
// Ver 1.0  2025--01--01 initial version.
// -----------------------------------------------------------------------------
// KEYWORDS   : 
// -----------------------------------------------------------------------------
// PURPOSE    :
// -----------------------------------------------------------------------------
// PARAMETERS :
// -----------------------------------------------------------------------------
// REUSE ISSUES
// Reset Strategy   :
// Clock Domains    :
// Critical Timing  :
// Test Features    :
// Asynchronous I/F :
// Scan Methodology : N
// Instantiations   : N
// Synthesizable    : Y
// Other :
// -FHDR------------------------------------------------------------------------

module sy_soc_fpga
    import sy_soc::*;
(
    input  logic         sys_clk_p   ,
    input  logic         sys_clk_n   ,
    input  logic         cpu_reset   ,
    inout  wire  [63:0]  ddr3_dq     ,
    inout  wire  [ 7:0]  ddr3_dqs_n  ,
    inout  wire  [ 7:0]  ddr3_dqs_p  ,
    output logic [13:0]  ddr3_addr   ,
    output logic [ 2:0]  ddr3_ba     ,
    output logic         ddr3_ras_n  ,
    output logic         ddr3_cas_n  ,
    output logic         ddr3_we_n   ,
    output logic         ddr3_reset_n,
    output logic [ 0:0]  ddr3_ck_p   ,
    output logic [ 0:0]  ddr3_ck_n   ,
    output logic [ 0:0]  ddr3_cke    ,
    output logic [ 0:0]  ddr3_cs_n   ,
    output logic [ 7:0]  ddr3_dm     ,
    output logic [ 0:0]  ddr3_odt    ,
    // led
    output logic [ 7:0]  led         ,
    input  logic [ 7:0]  sw          ,
    output logic         fan_pwm     ,
    // SPI
    output logic         spi_mosi    ,
    input  logic         spi_miso    ,
    output logic         spi_ss      ,
    output logic         spi_clk_o   ,
    // Ethernet clk
    input  wire          clk_125M_p,
    input  wire          clk_125M_n,
    // SGMII interface
    output wire          txp,                   // Differential +ve of serial transmission from PMA to PMD.
    output wire          txn,                   // Differential -ve of serial transmission from PMA to PMD.
    input  wire          rxp,                   // Differential +ve for serial reception from PMD to PMA.
    input  wire          rxn,                   // Differential -ve for serial reception from PMD to PMA.

    output wire          eth_rst_n   ,
    inout  wire          eth_mdio    ,
    output logic         eth_mdc     ,
    // Uart
    input  logic         rx          ,
    output logic         tx
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam int unsigned SOURCE_NUM = 30;
    localparam int unsigned TARGET_NUM = CORE_NUM * 2;

    localparam HART_ID_WTH = $clog2(CORE_NUM+1);
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic [CORE_NUM-1:0]    timer_irq;
    logic [CORE_NUM-1:0]    ipi;

    TL_BUS sys_bus_master   [CORE_NUM:0](); // Core + DMA
    TL_BUS sys_bus_slave    [SYS_BUS_SLAVE_NUM-1:0]();

    TL_BUS ctrl_bus_master  [0:0]();
    TL_BUS ctrl_bus_slave   [CTRL_BUS_SLAVE_NUM-1:0]();

    TL_BUS phri_bus_master  [0:0]();
    TL_BUS phri_bus_slave   [PHRI_BUS_SLAVE_NUM-1:0]();

    logic [SOURCE_NUM-1:0]          irq_sources;
    logic [TARGET_NUM-1:0]          irq_target;
    logic                           pll_locked;
    logic                           ndmreset;
    logic                           ddr_clock_out;
    logic                           ddr_sync_reset;
    logic                           clk;
    logic                           clk_125M;            
    logic                           clk_125M_90;            
    logic                           clk_125M_buf_p;            
    logic                           clk_125M_buf_n;            
    logic                           clk_200M;
    logic                           rst_n;
    logic                           rst;
    logic                           rst_i;
    logic                           clk_i;
    logic                           cpu_resetn;
    logic                           clk_d;
//======================================================================================================================
// Clock Generator
//======================================================================================================================
    xlnx_clk_gen i_xlnx_clk_gen (
      .clk_out1 ( clk           ), // 50 MHz
      .clk_out2 ( clk_125M      ), // 125 MHz clock
      .clk_out3 ( clk_125M_90   ), // 125 MHz clock, 90 degree phase
      .reset    ( cpu_reset     ),
      .locked   ( pll_locked    ),
      .clk_in1  ( ddr_clock_out )
    );
    assign clk_i = clk;
//======================================================================================================================
// reset generate
//======================================================================================================================
    assign rst_n = ~ddr_sync_reset;
    assign rst = ddr_sync_reset;
    assign cpu_resetn  = ~cpu_reset;
    rstgen i_rstgen_main (
        .clk_i        ( clk                      ),
        .rst_ni       ( pll_locked               ),
        .test_mode_i  ( 1'b0                     ),
        .rst_no       ( ndmreset_n               ),
        .init_no      (                          ) // keep open
    );
    assign rst_i = ndmreset_n;
//======================================================================================================================
// Hart 
//======================================================================================================================
    generate 
        genvar i;
        for (i=0;i<CORE_NUM;i++) begin : gen_hart
            localparam int unsigned LSB = 2*i;
            localparam int unsigned MSB = 2*(i+1)-1;
            sy_core # (
                .HART_ID_WTH    (HART_ID_WTH),
                .HART_ID        (i)
            ) u_sy_inst(
                .clk_i                      (clk_i      ),                          
                .rst_i                      (rst_i      ),                          
                .boot_addr_i                (ROMBase),          
                .irq_i                      (irq_target[MSB:LSB]),    
                .ipi_i                      (ipi[i]),    
                .debug_req_i                (1'b0),          
                .time_irq_i                 (timer_irq[i]),         
                .master                     (sys_bus_master[i])
            );       
        end
    endgenerate
//======================================================================================================================
// System Bus
//======================================================================================================================
    // ---------------
    // TileLink Xbar
    // ---------------
    sy_tl_xbar #(
        .MASTER_NUM            (CORE_NUM + 1),
        .SLAVE_NUM             (SYS_BUS_SLAVE_NUM),
        .REGION_NUM            (SYS_BUS_REGION),
        .SOURCE_LSB            (SYS_BUS_SRC_LSB),
        .SOURCE_MSB            (SYS_BUS_SRC_MSB),
        .SINK_LSB              (1),
        .SINK_MSB              (4),
        .TL_ADDR_WIDTH         (64),
        .MASTER_BUF_DEPTH      (1),
        .SLAVE_BUF_DEPTH       (1)
    ) system_bus(
        .clk_i                 (clk_i),
        .rst_i                 (rst_i),
        .master                (sys_bus_master),
        .slave                 (sys_bus_slave),
        .start_addr_i          (sys_bus_start_addr ),
        .end_addr_i            (sys_bus_end_addr   ),
        .region_en_i           (sys_bus_region_en)
    );
//======================================================================================================================
// Control Bus
//======================================================================================================================
    // ---------------
    // TileLink Xbar
    // ---------------
    tl_xbar #(
        .MASTER_NUM       (1),
        .SLAVE_NUM        (CTRL_BUS_SLAVE_NUM),
        .REGION_NUM       (CTRL_BUS_REGION),
        .SOURCE_LSB       (CTRL_BUS_SRC_LSB),
        .SOURCE_MSB       (CTRL_BUS_SRC_MSB),
        .SINK_LSB         (1),
        .SINK_MSB         (4),
        .TL_ADDR_WIDTH    (64)
    ) ctrl_bus(
        .clk_i            ( clk_i         ),
        .rst_i            ( rst_i         ),
        .master           ( ctrl_bus_master),
        .slave            ( ctrl_bus_slave),
        .start_addr_i     ( ctrl_bus_start_addr),
        .end_addr_i       ( ctrl_bus_end_addr),
        .region_en_i      ( ctrl_bus_region_en)
    );
    tl_slave2master ctrl_bus_trans(.slave(sys_bus_slave[CTRL_BUS]), .master(ctrl_bus_master[0]));
//======================================================================================================================
// Phripheral Bus
//======================================================================================================================
    // ---------------
    // TileLink Xbar
    // ---------------
    tl_xbar #(
        .MASTER_NUM       (1),
        .SLAVE_NUM        (PHRI_BUS_SLAVE_NUM),
        .REGION_NUM       (PHRI_BUS_REGION),
        .SOURCE_LSB       (PHRI_BUS_SRC_LSB),
        .SOURCE_MSB       (PHRI_BUS_SRC_MSB),
        .SINK_LSB         (1),
        .SINK_MSB         (4),
        .TL_ADDR_WIDTH    (64)
    ) phri_bus(
        .clk_i            ( clk_i         ),
        .rst_i            ( rst_i         ),
        .master           ( phri_bus_master),
        .slave            ( phri_bus_slave),
        .start_addr_i     ( phri_bus_start_addr),
        .end_addr_i       ( phri_bus_end_addr),
        .region_en_i      ( phri_bus_region_en)
    );
    tl_slave2master phri_bus_trans(.slave(sys_bus_slave[PHRI_BUS]), .master(phri_bus_master[0]));
//======================================================================================================================
// Main Memory
//======================================================================================================================
    sy_main_mem #(
        .HART_NUM       (CORE_NUM),
        .HART_ID_WTH    (HART_ID_WTH + 1),
        .HART_ID_LSB    (1)
    ) main_mem(
        .clk_i            (clk_i),
        .rst_i            (rst_i),
    `ifdef PLATFORM_XILINX
        .ddr_clock_out    (ddr_clock_out),                     
        .fan_pwm          (fan_pwm      ),                          
        .sys_clk_p        (sys_clk_p   ),                    
        .sys_clk_n        (sys_clk_n   ),                    
        .cpu_resetn       (cpu_resetn  ),                    
        .ddr3_dq          (ddr3_dq     ),                    
        .ddr3_dqs_n       (ddr3_dqs_n  ),                    
        .ddr3_dqs_p       (ddr3_dqs_p  ),                    
        .ddr3_addr        (ddr3_addr   ),                    
        .ddr3_ba          (ddr3_ba     ),                    
        .ddr3_ras_n       (ddr3_ras_n  ),                    
        .ddr3_cas_n       (ddr3_cas_n  ),                    
        .ddr3_we_n        (ddr3_we_n   ),                    
        .ddr3_reset_n     (ddr3_reset_n),                    
        .ddr3_ck_p        (ddr3_ck_p   ),                    
        .ddr3_ck_n        (ddr3_ck_n   ),                    
        .ddr3_cke         (ddr3_cke    ),                    
        .ddr3_cs_n        (ddr3_cs_n   ),                    
        .ddr3_dm          (ddr3_dm     ),                    
        .ddr3_odt         (ddr3_odt    ),                    
        .ddr_sync_reset   (ddr_sync_reset),                             
    `endif 
        .master           (sys_bus_slave[DMEM])
    );
//======================================================================================================================
// BootRom
//======================================================================================================================
    sy_bootrom bootrom_inst(
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .master      (ctrl_bus_slave[ROM])
    );
//======================================================================================================================
// DMA
//======================================================================================================================
    if (DMA_EN) begin
        sy_dma # (
            .BASE_ADDR  (DMABase),
            .ADDR_WIDTH (64),
            .DATA_WIDTH (64),
            .SOURCE     (CORE_NUM) 
        ) dma_inst(
            .clk_i          (clk_i),       
            .rst_i          (rst_i),      
            .master         (phri_bus_slave[DMA]), 
            .slave          (sys_bus_master[CORE_NUM]) 
        );
    end
//======================================================================================================================
// Clint    
//======================================================================================================================
    logic rtc;
    always_ff @(posedge clk_i or negedge rst_i) begin
      if (~rst_i) begin
        rtc <= 0;
      end else begin
        rtc <= rtc ^ 1'b1;
      end
    end

    sy_clint #(
        .ADDR_WIDTH   (64),
        .DATA_WIDTH   (64),
        .CORES_NUM    (CORE_NUM) 
    ) clint(
        .clk_i          (clk_i),                 
        .rst_i          (rst_i),                
        .testmode_i     ('0),               
        .rtc_i          (rtc),                 
        .timer_irq_o    (timer_irq),                 
        .ipi_o          (ipi),                 
        .master         (ctrl_bus_slave[CLINT])
    ); 
//======================================================================================================================
// Plic    
//======================================================================================================================
    sy_plic #(
        .ADDR_WIDTH   (32),
        .DATA_WIDTH   (32),
        .MAX_PRI      (7),
        .SOURCE_NUM   (SOURCE_NUM),
        .TARGET_NUM   (TARGET_NUM)
    ) plic(
        .clk_i          (clk_i),              
        .rst_i          (rst_i),             

        .irq_sources_i  (irq_sources),               
        .irq_target_o   (irq_target),              

        .master         (ctrl_bus_slave[PLIC])
    );
//======================================================================================================================
// Uart   
//======================================================================================================================
    if (UART_EN) begin
        sy_uart uart(
            .clk_i          (clk_i),         
            .rst_i          (rst_i),         
            .rx_i           (rx),        
            .tx_o           (tx),        
            .irq_o          (irq_sources[0]),     
            .master         (phri_bus_slave[UART])
        );
    end else begin
        assign tx = '0;
    end
//======================================================================================================================
// SPI
//======================================================================================================================
    if (SPI_EN) begin
        sy_spi spi(
            .clk_i          (clk_i),    
            .rst_i          (rst_i),    
    
            .irq_o          (irq_sources[1]),    
    
            .spi_clk_o      (spi_clk_o),         
            .spi_mosi       (spi_mosi),         
            .spi_miso       (spi_miso),         
            .spi_ss         (spi_ss),         
    
            .master         (phri_bus_slave[SPI])
        );       
    end else begin
        assign spi_mosi     = '0;
        assign spi_ss       = '0;
        assign spi_clk_o    = '0;
    end

//======================================================================================================================
// GPIO
//======================================================================================================================
    if (GPIO_EN) begin
        sy_gpio gpio(
            .clk_i              (clk_i),       
            .rst_i              (rst_i),     

            .leds_o             (led),      
            .dip_switches_i     (sw),              

            .master             (phri_bus_slave[GPIO])
        );
    end else begin
        assign led = '0;
    end
//======================================================================================================================
// Ethernet
//======================================================================================================================
    assign clk_200M = ddr_clock_out;
    if (ETHERNET_EN) begin
        sy_ethernet eth(
            .clk_i              (clk_i),                  
            .clk_125M_p         (clk_125M_p),                
            .clk_125M_n         (clk_125M_n),                   
            .clk_200M_i         (clk_200M),                
            .rst_ni             (rst_i),                       
            .eth_rstn_o         (eth_rst_n),                
            .eth_txp_o          (txp),                 
            .eth_txn_o          (txn),                   
            .eth_rxp_i          (rxp),               
            .eth_rxn_i          (rxn),               
            .eth_mdio           (eth_mdio),              
            .eth_mdc            (eth_mdc),                 
            .eth_irq_o          (irq_sources[2]),               
            .master             (phri_bus_slave[ETHERNET])
        );       
    end else begin
        assign txp = '0;
        assign txn = '0;
        assign eth_rst_n = '0;
        assign eth_mdc = '0;
    end

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on
endmodule : sy_soc_fpga
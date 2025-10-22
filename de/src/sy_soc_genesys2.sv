// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_soc_genesys2.v
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
    import sy_soc_pkg::*;
(
    input  logic         sys_clk_p   ,
    input  logic         sys_clk_n   ,
    input  logic         cpu_resetn  ,
    inout  wire  [31:0]  ddr3_dq     ,
    inout  wire  [ 3:0]  ddr3_dqs_n  ,
    inout  wire  [ 3:0]  ddr3_dqs_p  ,
    output logic [14:0]  ddr3_addr   ,
    output logic [ 2:0]  ddr3_ba     ,
    output logic         ddr3_ras_n  ,
    output logic         ddr3_cas_n  ,
    output logic         ddr3_we_n   ,
    output logic         ddr3_reset_n,
    output logic [ 0:0]  ddr3_ck_p   ,
    output logic [ 0:0]  ddr3_ck_n   ,
    output logic [ 0:0]  ddr3_cke    ,
    output logic [ 0:0]  ddr3_cs_n   ,
    output logic [ 3:0]  ddr3_dm     ,
    output logic [ 0:0]  ddr3_odt    ,
    output wire          eth_rst_n   ,
    input  wire          eth_rxck    ,
    input  wire          eth_rxctl   ,
    input  wire [3:0]    eth_rxd     ,
    output wire          eth_txck    ,
    output wire          eth_txctl   ,
    output wire [3:0]    eth_txd     ,
    inout  wire          eth_mdio    ,
    output logic         eth_mdc     ,
    output logic [ 7:0]  led         ,
    input  logic [ 7:0]  sw          ,
    output logic         fan_pwm     ,
    // JTAG 
    input  logic         tck         ,
    input  logic         tms         ,
    input  logic         trst_n      ,
    input  logic         tdi         ,
    output wire          tdo         ,
    // SPI
    output logic        spi_mosi    ,
    input  logic        spi_miso    ,
    output logic        spi_ss      ,
    output logic        spi_clk_o   ,
    // common part
    input  logic        rx          ,
    output logic        tx

);

//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam int unsigned SOURCE_NUM = 30;
    localparam int unsigned TARGET_NUM = CORE_NUM * 2;

    localparam HART_ID_WTH = $clog2(CORE_NUM+1);
    localparam PORT_NUM    = 2;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic [CORE_NUM-1:0]    timer_irq;
    logic [CORE_NUM-1:0]    ipi;
    logic                   flush_L2_cache_en;
    logic                   flush_L2_cache_done;
    logic [CORE_NUM-1:0]    debug_req_irq;
    logic                   cpu_rst_n;

    TL_BUS sys_bus_master   [CORE_NUM:0](); // Core + DMA
    TL_BUS sys_bus_slave    [SYS_BUS_SLAVE_NUM-1:0]();

    TL_BUS ctrl_bus_master  [0:0]();
    TL_BUS ctrl_bus_slave   [CTRL_BUS_SLAVE_NUM-1:0]();

    TL_BUS phri_bus_master  [0:0]();
    TL_BUS phri_bus_slave   [PHRI_BUS_SLAVE_NUM-1:0]();

    TL_BUS npu_bus_master   [0:0]();
    TL_BUS npu_bus_slave    [NPU_BUS_SLAVE_NUM-1:0]();

    TL_BUS mem_bus_master   [NPU_BUS_SLAVE_NUM-1:0]();
    TL_BUS mem_bus_slave    [0:0]();

    logic [SOURCE_NUM-1:0]          irq_sources;
    logic [TARGET_NUM-1:0]          irq_target;
    logic                           pll_locked;
    logic                           ndmreset;
    logic                           ddr_clock_out;
    logic                           ddr_sync_reset;
    logic                           flush_L2_cache_en;
    logic                           flush_L2_cache_done;
    logic                           clk;
    logic                           rst_n;
    logic                           rst;
    logic                           rst_i;
    logic                           clk_i;
    logic                           clk_d;
    logic                           clk_125M;
    logic                           clk_125M_90;
    logic                           clk_200M;

    logic             [PORT_NUM-1:0]  ddr_axi_aw_valid;
    logic             [PORT_NUM-1:0]  ddr_axi_aw_ready;         
    axi_pkg::aw_chan_t[PORT_NUM-1:0]  ddr_axi_aw_bits;
    logic             [PORT_NUM-1:0]  ddr_axi_ar_valid;
    logic             [PORT_NUM-1:0]  ddr_axi_ar_ready;         
    axi_pkg::ar_chan_t[PORT_NUM-1:0]  ddr_axi_ar_bits;
    logic             [PORT_NUM-1:0]  ddr_axi_w_valid;
    logic             [PORT_NUM-1:0]  ddr_axi_w_ready;         
    axi_pkg::w_chan_t [PORT_NUM-1:0]  ddr_axi_w_bits;
    logic             [PORT_NUM-1:0]  ddr_axi_r_valid;
    logic             [PORT_NUM-1:0]  ddr_axi_r_ready;
    axi_pkg::r_chan_t [PORT_NUM-1:0]  ddr_axi_r_bits; 
    logic             [PORT_NUM-1:0]  ddr_axi_b_valid;
    logic             [PORT_NUM-1:0]  ddr_axi_b_ready;
    axi_pkg::b_chan_t [PORT_NUM-1:0]  ddr_axi_b_bits;

//======================================================================================================================
// Clock Generator
//======================================================================================================================
    xlnx_clk_gen i_xlnx_clk_gen (
      .clk_out1 ( clk           ), // 50 MHz
      .clk_out2 ( clk_125M     ), // 125 MHz
      .clk_out3 ( clk_125M_90   ), // 125 MHz
      .reset    ( cpu_reset     ),
      .locked   ( pll_locked    ),
      .clk_in1  ( ddr_clock_out )
    );
    assign clk_i = clk;
//======================================================================================================================
// reset generate
//======================================================================================================================
    logic  cpu_reset;
    assign cpu_reset  = ~cpu_resetn;

    assign rst_n = ~ddr_sync_reset;
    assign rst = ddr_sync_reset;
    rstgen i_rstgen_main (
        .clk_i        ( clk                      ),
        .rst_ni       ( pll_locked & (~ndmreset) ), // 
        .test_mode_i  ( 1'b0                     ),
        .rst_no       ( ndmreset_n               ),
        .init_no      (                          ) // keep open
    );
    assign cpu_rst_n = ndmreset_n;
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
                .rst_i                      (cpu_rst_n  ),                          
                .boot_addr_i                (ROMBase),          
                .irq_i                      (irq_target[MSB:LSB]),    
                .ipi_i                      (ipi[i]),    
                .debug_req_i                (debug_req_irq[i]),          
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
        .rst_i                 (cpu_rst_n),
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
    sy_tl_xbar #(
        .MASTER_NUM       (1),
        .SLAVE_NUM        (CTRL_BUS_SLAVE_NUM),
        .REGION_NUM       (CTRL_BUS_REGION),
        .SOURCE_LSB       (CTRL_BUS_SRC_LSB),
        .SOURCE_MSB       (CTRL_BUS_SRC_MSB),
        .SINK_LSB         (1),
        .SINK_MSB         (4),
        .TL_ADDR_WIDTH    (64),
        .MASTER_BUF_DEPTH (1),
        .SLAVE_BUF_DEPTH  (1)
    ) ctrl_bus(
        .clk_i            ( clk_i         ),
        .rst_i            ( cpu_rst_n     ),
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
    sy_tl_xbar #(
        .MASTER_NUM       (1),
        .SLAVE_NUM        (PHRI_BUS_SLAVE_NUM),
        .REGION_NUM       (PHRI_BUS_REGION),
        .SOURCE_LSB       (PHRI_BUS_SRC_LSB),
        .SOURCE_MSB       (PHRI_BUS_SRC_MSB),
        .SINK_LSB         (1),
        .SINK_MSB         (4),
        .TL_ADDR_WIDTH    (64),
        .MASTER_BUF_DEPTH (1),
        .SLAVE_BUF_DEPTH  (1)
    ) phri_bus(
        .clk_i            ( clk_i         ),
        .rst_i            ( cpu_rst_n     ),
        .master           ( phri_bus_master),
        .slave            ( phri_bus_slave),
        .start_addr_i     ( phri_bus_start_addr),
        .end_addr_i       ( phri_bus_end_addr),
        .region_en_i      ( phri_bus_region_en)
    );
    tl_slave2master phri_bus_trans(.slave(sys_bus_slave[PHRI_BUS]), .master(phri_bus_master[0]));
//======================================================================================================================
// NPU Bus
//======================================================================================================================
    // ---------------
    // TileLink Xbar
    // ---------------
    sy_tl_xbar #(
        .MASTER_NUM       (1),
        .SLAVE_NUM        (NPU_BUS_SLAVE_NUM),
        .REGION_NUM       (NPU_BUS_REGION),
        .SOURCE_LSB       (NPU_BUS_SRC_LSB),
        .SOURCE_MSB       (NPU_BUS_SRC_MSB),
        .SINK_LSB         (1),
        .SINK_MSB         (4),
        .TL_ADDR_WIDTH    (64),
        .MASTER_BUF_DEPTH (1),
        .SLAVE_BUF_DEPTH  (1)
    ) npu_bus(
        .clk_i            ( clk_i         ),
        .rst_i            ( cpu_rst_n     ),
        .master           ( npu_bus_master),
        .slave            ( npu_bus_slave),
        .start_addr_i     ( npu_bus_start_addr),
        .end_addr_i       ( npu_bus_end_addr),
        .region_en_i      ( npu_bus_region_en)
    );
    tl_slave2master npu_bus_trans(.slave(sys_bus_slave[NPU_BUS]), .master(npu_bus_master[0]));
//======================================================================================================================
// Main Memory
//======================================================================================================================
    sy_main_mem #(
        .HART_NUM       (CORE_NUM),
        .HART_ID_WTH    (HART_ID_WTH),
        .HART_ID_LSB    (1)
    ) main_mem(
        .clk_i            (clk_i),
        .rst_i            (cpu_rst_n),
        .master           (sys_bus_slave[DMEM]),
        .flush_L2_cache_en_i (flush_L2_cache_en),
        .flush_L2_cache_done_o (flush_L2_cache_done),
        // AXI4 interface
        .oup_axi_aw_valid_o           (ddr_axi_aw_valid[0]),            
        .oup_axi_aw_ready_i           (ddr_axi_aw_ready[0]),                     
        .oup_axi_aw_bits_o            (ddr_axi_aw_bits [0]),           
        .oup_axi_ar_valid_o           (ddr_axi_ar_valid[0]),            
        .oup_axi_ar_ready_i           (ddr_axi_ar_ready[0]),                     
        .oup_axi_ar_bits_o            (ddr_axi_ar_bits [0]),           
        .oup_axi_w_valid_o            (ddr_axi_w_valid [0]),           
        .oup_axi_w_ready_i            (ddr_axi_w_ready [0]),                    
        .oup_axi_w_bits_o             (ddr_axi_w_bits  [0]),          
        .oup_axi_r_valid_i            (ddr_axi_r_valid [0]),           
        .oup_axi_r_ready_o            (ddr_axi_r_ready [0]),           
        .oup_axi_r_bits_i             (ddr_axi_r_bits  [0]),           
        .oup_axi_b_valid_i            (ddr_axi_b_valid [0]),           
        .oup_axi_b_ready_o            (ddr_axi_b_ready [0]),           
        .oup_axi_b_bits_i             (ddr_axi_b_bits  [0])
    );
//======================================================================================================================
// DDR
//======================================================================================================================
    sy_ddr #(
        .PORT_NUM (2)
    ) ddr_inst(
        .clk_i            (clk_i),
        .rst_i            (cpu_rst_n),
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
      // AXI4 in 
      .inp_axi_aw_valid_i  (ddr_axi_aw_valid),                       
      .inp_axi_aw_ready_o  (ddr_axi_aw_ready),                                
      .inp_axi_aw_bits_i   (ddr_axi_aw_bits ),                      
      .inp_axi_ar_valid_i  (ddr_axi_ar_valid),                       
      .inp_axi_ar_ready_o  (ddr_axi_ar_ready),                                
      .inp_axi_ar_bits_i   (ddr_axi_ar_bits ),                      
      .inp_axi_w_valid_i   (ddr_axi_w_valid ),                      
      .inp_axi_w_ready_o   (ddr_axi_w_ready ),                               
      .inp_axi_w_bits_i    (ddr_axi_w_bits  ),                     
      .inp_axi_r_valid_o   (ddr_axi_r_valid ),                      
      .inp_axi_r_ready_i   (ddr_axi_r_ready ),                      
      .inp_axi_r_bits_o    (ddr_axi_r_bits  ),                      
      .inp_axi_b_valid_o   (ddr_axi_b_valid ),                      
      .inp_axi_b_ready_i   (ddr_axi_b_ready ),                      
      .inp_axi_b_bits_o    (ddr_axi_b_bits  )
    );
//======================================================================================================================
// RegMap (ctrl bus)
//======================================================================================================================
    sy_regmap #(
        .BASE_ADDR  (REGMAPBase),
        .ADDR_WIDTH (32),
        .DATA_WIDTH (32),
        .SOURCE     (0)
    ) regmap_inst(
        .clk_i                  (clk_i),       
        .rst_i                  (cpu_rst_n),      

        .master                 (ctrl_bus_slave[REGMAP]),

        .flush_L2_cache_en_o    (flush_L2_cache_en  ),                       
        .flush_L2_cache_done_i  (flush_L2_cache_done)
    );
//======================================================================================================================
// Clint (ctrl bus)
//======================================================================================================================
    logic rtc;
    always_ff @(posedge clk_i or negedge cpu_rst_n) begin
      if (~cpu_rst_n) begin
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
        .rst_i          (cpu_rst_n),                
        .testmode_i     ('0),               
        .rtc_i          (rtc),                 
        .timer_irq_o    (timer_irq),                 
        .ipi_o          (ipi),                 
        .master         (ctrl_bus_slave[CLINT])
    ); 
//======================================================================================================================
// Plic (ctrl_bus) 
//======================================================================================================================
    sy_plic #(
        .ADDR_WIDTH   (32),
        .DATA_WIDTH   (32),
        .MAX_PRI      (7),
        .SOURCE_NUM   (SOURCE_NUM),
        .TARGET_NUM   (TARGET_NUM)
    ) plic(
        .clk_i          (clk_i),              
        .rst_i          (cpu_rst_n),             

        .irq_sources_i  (irq_sources),               
        .irq_target_o   (irq_target),              

        .master         (ctrl_bus_slave[PLIC])
    );
//======================================================================================================================
// BootRom (phri bus)
//======================================================================================================================
    sy_bootrom bootrom_inst(
        .clk_i       (clk_i),
        .rst_i       (cpu_rst_n),
        .master      (phri_bus_slave[ROM])
    );
//======================================================================================================================
// Uart (phri bus) 
//======================================================================================================================
    sy_uart uart(
        .clk_i          (clk_i),         
        .rst_i          (cpu_rst_n),         
        .rx_i           (rx),        
        .tx_o           (tx),        
        .irq_o          (irq_sources[0]),     
        .master         (phri_bus_slave[UART])
    );
//======================================================================================================================
// SPI (phri bus)
//======================================================================================================================
    sy_spi spi(
        .clk_i          (clk_i),    
        .rst_i          (cpu_rst_n),    
    
        .irq_o          (irq_sources[1]),    
    
        .spi_clk_o      (spi_clk_o),         
        .spi_mosi       (spi_mosi),         
        .spi_miso       (spi_miso),         
        .spi_ss         (spi_ss),         
    
        .master         (phri_bus_slave[SPI])
    );       
//======================================================================================================================
// GPIO (phri bus)
//======================================================================================================================
    if (GPIO_EN) begin
        sy_gpio gpio(
            .clk_i              (clk_i),       
            .rst_i              (cpu_rst_n),     

            .leds_o             (led),      
            .dip_switches_i     (sw),              

            .master             (phri_bus_slave[GPIO])
        );
    end else begin
        assign led = '0;
    end
//======================================================================================================================
// Debug (npu bus)
//======================================================================================================================
    sy_debug # (
        .HART_NUM        (CORE_NUM),
        .SOURCE          ({2'b0,(MEM_BUS_SRC_LSB-1)'(CORE_NUM)}) // TODO
    ) debug_inst(
        .clk_i          (clk_i),       
        .rst_i          (~ddr_sync_reset),      
        .cpu_rst_n      (cpu_rst_n),
        // JTAG interface
        .tck            (tck   ),
        .tms            (tms   ),
        .trst_n         (trst_n),
        .tdi            (tdi   ),
        .tdo            (tdo   ),        
        // reset
        .ndmreset       (ndmreset),
        .debug_req_irq  (debug_req_irq),
        // used to read/write register
        .master         (npu_bus_slave[DEBUG]), 
        // used to access system bus
        .slave          (mem_bus_master[0]) 
    );
//======================================================================================================================
// DMA (npu bus)
//======================================================================================================================
    sy_dma # (
        .BASE_ADDR  (DMABase),
        .ADDR_WIDTH (64),
        .DATA_WIDTH (64),
        .SOURCE     ({2'b1,(MEM_BUS_SRC_LSB-1)'(CORE_NUM)}) // 
    ) dma_inst(
        .clk_i          (clk_i),       
        .rst_i          (cpu_rst_n),      
        .master         (npu_bus_slave[DMA]), 
        .slave          (mem_bus_master[1]) 
    );
//======================================================================================================================
// FFT (npu bus)
//======================================================================================================================
    sy_fft #(
        .SOURCE         ({2'b10,(MEM_BUS_SRC_LSB-1)'(CORE_NUM)}),
        .BASE_ADDR      (FFTBase),
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (32)
    ) fft_inst(
        .clk_i            (clk_i),           
        .rst_i            (cpu_rst_n),           
        // TL bus, used to read/write regs
        .master           (npu_bus_slave[FFT]),
        // Access Mem
        .slave            (mem_bus_master[FFT])
    );
//======================================================================================================================
// Mem bus (used by FFT/DMA/Debug to access system bus)
//======================================================================================================================
    tl_xbar #(
        .MASTER_NUM       (NPU_BUS_SLAVE_NUM),
        .SLAVE_NUM        (1),
        .REGION_NUM       (1),
        .SOURCE_LSB       (MEM_BUS_SRC_LSB),
        .SOURCE_MSB       (MEM_BUS_SRC_MSB),
        .SINK_LSB         (1),
        .SINK_MSB         (4),
        .TL_ADDR_WIDTH    (64)
    ) mem_bus(
        .clk_i            ( clk_i         ),
        .rst_i            ( cpu_rst_n     ),
        .master           ( mem_bus_master),
        .slave            ( mem_bus_slave ),
        .start_addr_i     ( mem_bus_start_addr),
        .end_addr_i       ( mem_bus_end_addr),
        .region_en_i      ( mem_bus_region_en)
    );
    tl_master2slave mem_bus_trans(.master(mem_bus_slave[0]), .slave(sys_bus_master[CORE_NUM]));
//======================================================================================================================
// Ethernet (phri bus)
//======================================================================================================================
    assign clk_200M = ddr_clock_out;
    if (ETHERNET_EN) begin
        sy_ethernet eth_inst(
           .clk_i               (clk_i),               
           .clk_200M_i          (clk_200M),             
           .rst_ni              (cpu_rst_n),                    

           .eth_clk_i           (clk_125M_90),                   
           .eth_rxck            (eth_rxck),                   
           .eth_rxctl           (eth_rxctl),                   
           .eth_rxd             (eth_rxd),                   
           .eth_txck            (eth_txck),                   
           .eth_txctl           (eth_txctl),                   
           .eth_txd             (eth_txd),                   
           .eth_rst_n           (eth_rst_n),                   
           .phy_tx_clk_i        (clk_125M),                    

           .eth_mdio            (eth_mdio),           
           .eth_mdc             (eth_mdc),              

           .eth_irq_o           (irq_sources[2]),            

           .master              (phri_bus_slave[ETHERNET])
        );       
    end else begin
        assign eth_rst_n = 1'b0;
        assign eth_txck = 1'b0;
        assign eth_txctl = 1'b0;
        assign eth_txd = '0;
        assign eth_mdc = 1'b0;
    end
//======================================================================================================================
// NPU 
//======================================================================================================================
//    if (NPU_EN) begin
//        sy_npu npu(
//            .clk_i              (clk_i),       
//            .rst_i              (rst_i),     

//            .axi_aw_valid_o     (ddr_axi_aw_valid[1]),        
//            .axi_aw_ready_i     (ddr_axi_aw_ready[1]),                 
//            .axi_aw_bits_o      (ddr_axi_aw_bits [1]),       
//            .axi_ar_valid_o     (ddr_axi_ar_valid[1]),        
//            .axi_ar_ready_i     (ddr_axi_ar_ready[1]),                 
//            .axi_ar_bits_o      (ddr_axi_ar_bits [1]),       
//            .axi_w_valid_o      (ddr_axi_w_valid [1]),       
//            .axi_w_ready_i      (ddr_axi_w_ready [1]),                
//            .axi_w_bits_o       (ddr_axi_w_bits  [1]),      
//            .axi_r_valid_i      (ddr_axi_r_valid [1]),       
//            .axi_r_ready_o      (ddr_axi_r_ready [1]),       
//            .axi_r_bits_i       (ddr_axi_r_bits  [1]),       
//            .axi_b_valid_i      (ddr_axi_b_valid [1]),       
//            .axi_b_ready_o      (ddr_axi_b_ready [1]),       
//            .axi_b_bits_i       (ddr_axi_b_bits  [1]),      

//            .npu_mem             (npu_bus_slave[NPU_DRAM]),
//            .npu_reg             (npu_bus_slave[NPU])
//        );
//    end 
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on

(* mark_debug = "true" *) logic         prb_sys_bus_D_valid;
(* mark_debug = "true" *) logic         prb_sys_bus_D_ready;
(* mark_debug = "true" *) logic[9:0]    prb_sys_bus_D_source;

assign prb_sys_bus_D_valid  = sys_bus_master[CORE_NUM].d_valid;
assign prb_sys_bus_D_ready  = sys_bus_master[CORE_NUM].d_ready;
assign prb_sys_bus_D_source = sys_bus_master[CORE_NUM].d_bits.source;

endmodule : sy_soc_fpga

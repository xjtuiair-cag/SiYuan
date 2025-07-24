// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_soc_sim.v
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

module sy_soc_sim
    import sy_soc_pkg::*;
(
    // =====================================
    
    // -- <clock>
    input   logic                           clk_i,                      
    // -- <reset>
    input   logic                           rst_i,                      
    // =====================================
    // [ctrl & status]
    input   logic[AWTH-1:0]                 boot_addr_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam int unsigned SOURCE_NUM = 30;
    localparam int unsigned TARGET_NUM = CORE_NUM * 2;

    localparam HART_ID_WTH = $clog2(CORE_NUM+1);
    localparam DDR_PORT    = 2;
    localparam PORT_NUM    = 2;
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

    TL_BUS npu_bus_master   [0:0]();
    TL_BUS npu_bus_slave    [NPU_BUS_SLAVE_NUM-1:0]();

    logic [SOURCE_NUM-1:0]          irq_sources;
    logic [TARGET_NUM-1:0]          irq_target;
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
// Hart 
//======================================================================================================================
    // generate 
    //     genvar i;
    //     for (i=0;i<CORE_NUM;i++) begin : gen_hart
    //         localparam int unsigned LSB = 2*i;
    //         localparam int unsigned MSB = 2*(i+1)-1;
    //         sy_core # (
    //             .HART_ID_WTH    (HART_ID_WTH),
    //             .HART_ID        (i)
    //         ) u_sy_inst(
    //             .clk_i                      (clk_i      ),                          
    //             .rst_i                      (rst_i      ),                          
    //             .boot_addr_i                (boot_addr_i),          
    //             .irq_i                      (irq_target[MSB:LSB]),    
    //             .ipi_i                      (ipi[i]),    
    //             .debug_req_i                (1'b0),          
    //             .time_irq_i                 (timer_irq[i]),         
    //             .master                     (sys_bus_master[i])
    //         );       
    //     end
    // endgenerate
    sy_core # (
        .HART_ID_WTH    (HART_ID_WTH),
        .HART_ID        (0)
    ) u_sy_inst(
        .clk_i                      (clk_i      ),                          
        .rst_i                      (rst_i      ),                          
        .boot_addr_i                (boot_addr_i),          
        .irq_i                      (irq_target[1:0]),    
        .ipi_i                      (ipi[0]),    
        .debug_req_i                (1'b0),          
        .time_irq_i                 (timer_irq[0]),         
        .master                     (sys_bus_master[0])
    ); 

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
// NPU Bus
//======================================================================================================================
    // ---------------
    // TileLink Xbar
    // ---------------
    tl_xbar #(
        .MASTER_NUM       (1),
        .SLAVE_NUM        (NPU_BUS_SLAVE_NUM),
        .REGION_NUM       (NPU_BUS_REGION),
        .SOURCE_LSB       (NPU_BUS_SRC_LSB),
        .SOURCE_MSB       (NPU_BUS_SRC_MSB),
        .SINK_LSB         (1),
        .SINK_MSB         (4),
        .TL_ADDR_WIDTH    (64)
    ) npu_bus(
        .clk_i            ( clk_i         ),
        .rst_i            ( rst_i         ),
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
        .HART_ID_WTH    (HART_ID_WTH + 1),
        .HART_ID_LSB    (1)
    ) main_mem(
        .clk_i            (clk_i),
        .rst_i            (rst_i),
        .master           (sys_bus_slave[DMEM]),
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
      .rst_i            (rst_i),
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
            .master         (npu_bus_slave[DMA]), 
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
    logic rx,tx;
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

    `ifdef PLATFORM_SIM
        logic rx_done;
        logic [7:0] rx_data;

        // uart module
        UART_rec #(
            .BPS            (115200),
            .CLK_fre        (50000000),
            .DATA_WIDTH     (8)
        ) u_uart_rec(
            .clk          (clk_i        ) ,
            .rstn         (rst_i        ) , 
            .uart_rx      (tx           ) ,    
            .rx_done      (rx_done      ) ,    
            .rece_data    (rx_data      )  
        );
        logic   rx_done_dly0;
        logic   rx_done_dly1;
        logic   done;
        // generate done singal in clk domain
        always_ff @(posedge clk_i) begin 
            rx_done_dly0 <= rx_done;
            rx_done_dly1 <= rx_done_dly0;
        end
        assign done = ~rx_done_dly1 && rx_done_dly0;

        always@(posedge clk_i) begin : print_uart_data 
            if(done) begin
                $write("%c", rx_data);
            end 
        end
    `endif 

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
// NPU 
//======================================================================================================================
        if (NPU_EN) begin
            sy_npu npu(
                .clk_i              (clk_i),       
                .rst_i              (rst_i),     

                .axi_aw_valid_o     (ddr_axi_aw_valid[1]),        
                .axi_aw_ready_i     (ddr_axi_aw_ready[1]),                 
                .axi_aw_bits_o      (ddr_axi_aw_bits [1]),       
                .axi_ar_valid_o     (ddr_axi_ar_valid[1]),        
                .axi_ar_ready_i     (ddr_axi_ar_ready[1]),                 
                .axi_ar_bits_o      (ddr_axi_ar_bits [1]),       
                .axi_w_valid_o      (ddr_axi_w_valid [1]),       
                .axi_w_ready_i      (ddr_axi_w_ready [1]),                
                .axi_w_bits_o       (ddr_axi_w_bits  [1]),      
                .axi_r_valid_i      (ddr_axi_r_valid [1]),       
                .axi_r_ready_o      (ddr_axi_r_ready [1]),       
                .axi_r_bits_i       (ddr_axi_r_bits  [1]),       
                .axi_b_valid_i      (ddr_axi_b_valid [1]),       
                .axi_b_ready_o      (ddr_axi_b_ready [1]),       
                .axi_b_bits_i       (ddr_axi_b_bits  [1]),      

                .npu_mem             (npu_bus_slave[NPU_DRAM]),
                .npu_reg             (npu_bus_slave[NPU])
            );           
        end else begin
            assign ddr_axi_aw_valid[1] = '0;
            assign ddr_axi_ar_valid[1] = '0;
            assign ddr_axi_w_valid[1] = '0;
            assign ddr_axi_r_ready[1] = '0;
            assign ddr_axi_b_ready[1] = '0;
        end

//======================================================================================================================
// Ethernet (TODO)
//======================================================================================================================

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on
endmodule : sy_soc_sim
// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ctrl_bus.v
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


module sy_ctrl_bus
    import sy_soc_pkg::*;
#(
    parameter MASTER_NUM            = 1,
    parameter SLAVE_NUM             = 4,
    parameter REGION_NUM            = 1,
    parameter SOURCE_LSB            = 0,
    parameter SOURCE_MSB            = 1,
    parameter SINK_LSB              = 0,
    parameter SINK_MSB              = 1,
    parameter TL_ADDR_WIDTH         = 64,
    parameter MASTER_BUF_DEPTH      = 1,
    parameter SLAVE_BUF_DEPTH       = 1,
    parameter SOURCE_NUM            = 30,
    parameter TARGET_NUM            = CORE_NUM * 2
)(
    input   logic                                   clk_i,
    input   logic                                   rst_i,
    TL_BUS.Master                                   master,
    // irq 
    input   logic                                   uart_irq_i,
    input   logic                                   spi_irq_i,
    input   logic                                   dma_irq_i,
    output  logic [TARGET_NUM-1:0]                  irq_target_o,    
    output  logic [CORE_NUM-1:0]                    timer_irq_o,
    output  logic [CORE_NUM-1:0]                    ipi_o,
    // ctrl signel
    output  logic                                   flush_L2_cache_en_o,
    input   logic                                   flush_L2_cache_done_i
);
//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    TL_BUS ctrl_bus_master  [0:0]();
    TL_BUS ctrl_bus_slave   [CTRL_BUS_SLAVE_NUM-1:0]();
    logic [SOURCE_NUM-1:0]          irq_sources;

//======================================================================================================================
// ctrl bus xbar
//======================================================================================================================
    tl_slave2master ctrl_bus_trans(.slave(master), .master(ctrl_bus_master[0]));

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
        .rst_i            ( rst_i         ),
        .master           ( ctrl_bus_master),
        .slave            ( ctrl_bus_slave),
        .start_addr_i     ( ctrl_bus_start_addr),
        .end_addr_i       ( ctrl_bus_end_addr),
        .region_en_i      ( ctrl_bus_region_en)
    );
//======================================================================================================================
// REGMAP
//======================================================================================================================
    sy_regmap #(
        .BASE_ADDR  (REGMAPBase),
        .ADDR_WIDTH (32),
        .DATA_WIDTH (32),
        .SOURCE     (0)
    ) regmap_inst(
        .clk_i                  (clk_i),       
        .rst_i                  (rst_i),      

        .master                 (ctrl_bus_slave[REGMAP]),

        .flush_L2_cache_en_o    (flush_L2_cache_en_o  ),                       
        .flush_L2_cache_done_i  (flush_L2_cache_done_i)
    );
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
        .timer_irq_o    (timer_irq_o),                 
        .ipi_o          (ipi_o),                 
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
        .irq_target_o   (irq_target_o),              

        .master         (ctrl_bus_slave[PLIC])
    );
    assign irq_sources[0] = uart_irq_i;
    assign irq_sources[1] = spi_irq_i;
    assign irq_sources[2] = dma_irq_i;

endmodule
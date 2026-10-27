// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy.v
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

module sy
    import sy_pkg::*;
    import sy_soc_pkg::*;
# (
    parameter integer IRQ_NUM = 1    
)(
    input   logic                           clk_sys_i,
    input   logic                           clk_rtc_i,
    input   logic                           rst_sys_i,
    input   logic                           rst_i,
    output  logic                           ndmreset_o,

    output  logic[31:0]                     ddr_base_addr_o,
    input   logic                           boot_mode_i,
    // -------------------------------------
    // [Config]
    // -- AXI Lite 32
    // -- write channel
    input   logic[63:0]                     cfg_awaddr_i,               // -- 16bit, write address
    input   logic                           cfg_awvalid_i,              // -- valid
    output  logic                           cfg_awready_o,              // -- ready
    input   logic[31:0]                     cfg_wdata_i,                // -- 32bit, write data
    input   logic                           cfg_wvalid_i,               // -- valid
    output  logic                           cfg_wready_o,               // -- ready
    output  logic[1:0]                      cfg_bresp_o,                // -- 2bit, responce
    output  logic                           cfg_bvalid_o,               // -- valid
    input   logic                           cfg_bready_i,               // -- ready
    // -- read channel
    input   logic[63:0]                     cfg_araddr_i,               // -- 16bit, read address
    input   logic                           cfg_arvalid_i,              // -- valid
    output  logic                           cfg_arready_o,              // -- ready
    output  logic[31:0]                     cfg_rdata_o,                // -- 32bit, read data
    output  logic[1:0]                      cfg_rresp_o,                // -- 2bit, responce
    output  logic                           cfg_rvalid_o,               // -- valid
    input   logic                           cfg_rready_i,               // -- ready
    // -------------------------------------
    // [32bit AXI lite bus master]
    // -- write
    output  logic[31:0]                     axilm32_awaddr_o,             // -- 40bit, write address
    output  logic                           axilm32_awvalid_o,            // -- valid
    input   logic                           axilm32_awready_i,            // -- ready
    output  logic[31:0]                     axilm32_wdata_o,              // -- 64bit, write data
    output  logic[3:0]                      axilm32_wstrb_o,              // -- 64/8bit, write data strobe
    output  logic                           axilm32_wvalid_o,             // -- valid
    input   logic                           axilm32_wready_i,             // -- ready
    input   logic[1:0]                      axilm32_bresp_i,              // -- 2bit, responce
    input   logic                           axilm32_bvalid_i,             // -- valid
    output  logic                           axilm32_bready_o,             // -- ready
    // -- read
    output  logic[31:0]                     axilm32_araddr_o,             // -- 40bit, read address
    output  logic                           axilm32_arvalid_o,            // -- valid
    input   logic                           axilm32_arready_i,            // -- ready
    input   logic[31:0]                     axilm32_rdata_i,              // -- 64bit, read data
    input   logic[1:0]                      axilm32_rresp_i,              // -- 2bit, responce
    input   logic                           axilm32_rvalid_i,             // -- valid
    output  logic                           axilm32_rready_o,             // -- ready
    // -------------------------------------
    // [L2 cache (instr/data)]
    output  logic                           ddr_axi_aw_valid_o,
    input   logic                           ddr_axi_aw_ready_i,         
    output  axi_pkg::aw_chan_t              ddr_axi_aw_bits_o,
    output  logic                           ddr_axi_ar_valid_o,
    input   logic                           ddr_axi_ar_ready_i,         
    output  axi_pkg::ar_chan_t              ddr_axi_ar_bits_o,
    output  logic                           ddr_axi_w_valid_o,
    input   logic                           ddr_axi_w_ready_i,         
    output  axi_pkg::w_chan_t               ddr_axi_w_bits_o,
    input   logic                           ddr_axi_r_valid_i,
    output  logic                           ddr_axi_r_ready_o,
    input   axi_pkg::r_chan_t               ddr_axi_r_bits_i, 
    input   logic                           ddr_axi_b_valid_i,
    output  logic                           ddr_axi_b_ready_o,
    input   axi_pkg::b_chan_t               ddr_axi_b_bits_i,
    // JTAG 
    input  logic                            tck   ,
    input  logic                            tms   ,
    input  logic                            trst_n,
    input  logic                            tdi   ,
    output wire                             tdo   ,
    // SD
    input  logic                            sd_detect,
    output logic                            sd_clk,
    output logic                            sd_reset,
    input  logic [3:0]                      sd_dat_i,
    output logic [3:0]                      sd_dat_o,
    output logic                            sd_dat_oe_o,
    input  logic                            sd_cmd_i,
    output logic                            sd_cmd_o,
    output logic                            sd_cmd_oe_o,
    // common part
    input  logic                            rx,
    output logic                            tx          
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam int unsigned SOURCE_NUM = 63;
    localparam int unsigned TARGET_NUM = CORE_NUM * 2;

    // localparam HART_ID_WTH = $clog2(CORE_NUM);
    localparam HART_ID_WTH = (CORE_NUM==1) ? 1 : $clog2(CORE_NUM);
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_A_valid; 
    logic                  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_A_ready; 
    tl_pkg::A_chan_bits_t  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_A_bits ;
    logic                  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_B_valid; 
    logic                  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_B_ready; 
    tl_pkg::B_chan_bits_t  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_B_bits ;
    logic                  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_C_valid; 
    logic                  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_C_ready; 
    tl_pkg::C_chan_bits_t  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_C_bits ;
    logic                  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_D_valid; 
    logic                  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_D_ready; 
    tl_pkg::D_chan_bits_t  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_D_bits ;
    logic                  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_E_valid; 
    logic                  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_E_ready; 
    tl_pkg::E_chan_bits_t  [$clog2(CORE_NUM)-1:0][1:0]          cluster_bus_master_E_bits ;

    logic                  [$clog2(CORE_NUM)+1:0]               sys_bus_master_A_valid; 
    logic                  [$clog2(CORE_NUM)+1:0]               sys_bus_master_A_ready; 
    tl_pkg::A_chan_bits_t  [$clog2(CORE_NUM)+1:0]               sys_bus_master_A_bits ;
    logic                  [$clog2(CORE_NUM)+1:0]               sys_bus_master_B_valid; 
    logic                  [$clog2(CORE_NUM)+1:0]               sys_bus_master_B_ready; 
    tl_pkg::B_chan_bits_t  [$clog2(CORE_NUM)+1:0]               sys_bus_master_B_bits ;
    logic                  [$clog2(CORE_NUM)+1:0]               sys_bus_master_C_valid; 
    logic                  [$clog2(CORE_NUM)+1:0]               sys_bus_master_C_ready; 
    tl_pkg::C_chan_bits_t  [$clog2(CORE_NUM)+1:0]               sys_bus_master_C_bits ;
    logic                  [$clog2(CORE_NUM)+1:0]               sys_bus_master_D_valid; 
    logic                  [$clog2(CORE_NUM)+1:0]               sys_bus_master_D_ready; 
    tl_pkg::D_chan_bits_t  [$clog2(CORE_NUM)+1:0]               sys_bus_master_D_bits ;
    logic                  [$clog2(CORE_NUM)+1:0]               sys_bus_master_E_valid; 
    logic                  [$clog2(CORE_NUM)+1:0]               sys_bus_master_E_ready; 
    tl_pkg::E_chan_bits_t  [$clog2(CORE_NUM)+1:0]               sys_bus_master_E_bits ;
    logic                  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_A_valid; 
    logic                  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_A_ready; 
    tl_pkg::A_chan_bits_t  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_A_bits ;
    logic                  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_B_valid; 
    logic                  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_B_ready; 
    tl_pkg::B_chan_bits_t  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_B_bits ;
    logic                  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_C_valid; 
    logic                  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_C_ready; 
    tl_pkg::C_chan_bits_t  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_C_bits ;
    logic                  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_D_valid; 
    logic                  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_D_ready; 
    tl_pkg::D_chan_bits_t  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_D_bits ;
    logic                  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_E_valid; 
    logic                  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_E_ready; 
    tl_pkg::E_chan_bits_t  [SYS_BUS_SLAVE_NUM-1:0]              sys_bus_slave_E_bits ;

    logic                  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_A_valid; 
    logic                  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_A_ready; 
    tl_pkg::A_chan_bits_t  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_A_bits ;
    logic                  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_B_valid; 
    logic                  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_B_ready; 
    tl_pkg::B_chan_bits_t  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_B_bits ;
    logic                  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_C_valid; 
    logic                  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_C_ready; 
    tl_pkg::C_chan_bits_t  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_C_bits ;
    logic                  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_D_valid; 
    logic                  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_D_ready; 
    tl_pkg::D_chan_bits_t  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_D_bits ;
    logic                  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_E_valid; 
    logic                  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_E_ready; 
    tl_pkg::E_chan_bits_t  [CTRL_BUS_SLAVE_NUM-1:0]             ctrl_bus_slave_E_bits ;

    logic                  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_A_valid; 
    logic                  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_A_ready; 
    tl_pkg::A_chan_bits_t  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_A_bits ;
    logic                  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_B_valid; 
    logic                  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_B_ready; 
    tl_pkg::B_chan_bits_t  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_B_bits ;
    logic                  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_C_valid; 
    logic                  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_C_ready; 
    tl_pkg::C_chan_bits_t  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_C_bits ;
    logic                  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_D_valid; 
    logic                  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_D_ready; 
    tl_pkg::D_chan_bits_t  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_D_bits ;
    logic                  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_E_valid; 
    logic                  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_E_ready; 
    tl_pkg::E_chan_bits_t  [PHRI_BUS_SLAVE_NUM-1:0]             phri_bus_slave_E_bits ;

    logic                  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_A_valid; 
    logic                  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_A_ready; 
    tl_pkg::A_chan_bits_t  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_A_bits ;
    logic                  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_B_valid; 
    logic                  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_B_ready; 
    tl_pkg::B_chan_bits_t  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_B_bits ;
    logic                  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_C_valid; 
    logic                  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_C_ready; 
    tl_pkg::C_chan_bits_t  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_C_bits ;
    logic                  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_D_valid; 
    logic                  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_D_ready; 
    tl_pkg::D_chan_bits_t  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_D_bits ;
    logic                  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_E_valid; 
    logic                  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_E_ready; 
    tl_pkg::E_chan_bits_t  [DMA_BUS_SLAVE_NUM-1:0]              dma_bus_slave_E_bits ;

    logic                  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_A_valid; 
    logic                  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_A_ready; 
    tl_pkg::A_chan_bits_t  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_A_bits ;
    logic                  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_B_valid; 
    logic                  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_B_ready; 
    tl_pkg::B_chan_bits_t  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_B_bits ;
    logic                  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_C_valid; 
    logic                  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_C_ready; 
    tl_pkg::C_chan_bits_t  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_C_bits ;
    logic                  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_D_valid; 
    logic                  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_D_ready; 
    tl_pkg::D_chan_bits_t  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_D_bits ;
    logic                  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_E_valid; 
    logic                  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_E_ready; 
    tl_pkg::E_chan_bits_t  [MEM_BUS_MASTER_NUM-1:0]             mem_bus_master_E_bits ;

    logic [SOURCE_NUM-1:0]                                      irq_sources;
    logic [TARGET_NUM-1:0]                                      irq_target;
    logic                                                       ndmreset;
    logic [CORE_NUM-1:0]                                        timer_irq;
    logic [CORE_NUM-1:0]                                        ipi;
    logic [CORE_NUM-1:0]                                        debug_req_irq;
    logic [CORE_NUM-1:0]                                        siyuan_call;
    logic [CORE_NUM-1:0]                                        siyuan_invdc;
    logic [CORE_NUM-1:0]                                        siyuan_invic;
    logic [CORE_NUM-1:0]                                        siyuan_kill;
    logic [CORE_NUM-1:0]                                        siyuan_call_busy;
    logic [CORE_NUM-1:0]                                        siyuan_invdc_busy;
    logic [CORE_NUM-1:0]                                        siyuan_invic_busy;
    logic [CORE_NUM-1:0]                                        siyuan_kill_busy;
    logic [CORE_NUM-1:0]                                        siyuan_fence_state;
    logic [CORE_NUM-1:0]                                        siyuan_forbid_br_pred;
    logic [CORE_NUM-1:0]                                        siyuan_avail_cores;
    logic                                                       exe_region_ex_en;
    logic                                                       flush_L2_cache_en;                       
    logic                                                       flush_L2_cache_busy;
    logic                                                       inv_L2_cache_en;                       
    logic                                                       inv_L2_cache_busy;
    logic [63:0]                                                siyuan_init_pc;
    logic [63:0]                                                siyuan_ret_addr;
    logic                                                       clk_fpu;
//======================================================================================================================
// Hart 
//======================================================================================================================
    always_ff @(`DFF_CR(clk_sys_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            clk_fpu <= `TCQ 1'b0;
        end else begin
            clk_fpu <= `TCQ ~clk_fpu;
        end
    end

    generate 
        genvar i,j;
        for (i=0;i<$clog2(CORE_NUM);i++) begin : gen_cluster
            for (j=0;j<2;j++) begin : gen_hart
                localparam int unsigned HID = i*2 + j;
                localparam int unsigned LSB = 2*HID;
                localparam int unsigned MSB = 2*(HID+1)-1;
                sy_core # (
                    .HART_ID_WTH    (HART_ID_WTH),
                    .HART_ID        (HID)
                ) u_sy_inst(
                    .clk_i                      (clk_sys_i      ),                          
                    .clk_fpu_i                  (clk_fpu    ),
                    .rst_i                      (rst_i      ),                          
                    // boot config 
                    .boot_addr_i                (siyuan_init_pc),          
                    .boot_mode_i                (boot_mode_i),
                    // remote call
                    .remote_call_i              (siyuan_call[HID]),
                    .remote_invdc_i             (siyuan_invdc[HID]),
                    .remote_invic_i             (siyuan_invic[HID]),
                    .remote_kill_i              (siyuan_kill[HID]),
                    .remote_call_busy_o         (siyuan_call_busy[HID]),
                    .remote_invdc_busy_o        (siyuan_invdc_busy[HID]),
                    .remote_invic_busy_o        (siyuan_invic_busy[HID]),
                    .remote_kill_busy_o         (siyuan_kill_busy[HID]),
                    .remote_ret_addr_i          (siyuan_ret_addr),
                    .fence_state_i              (siyuan_fence_state[HID]),
                    .forbid_br_pred_i           (siyuan_forbid_br_pred[HID]),
                    .exe_region_ex_en_i         (exe_region_ex_en),
                    .is_avail_i                 (siyuan_avail_cores[HID]),
                    // irq and debug req
                    .irq_i                      (irq_target[MSB:LSB]),    
                    .ipi_i                      (ipi[HID]),    
                    .debug_req_i                (debug_req_irq[HID]),          
                    .time_irq_i                 (timer_irq[HID]),         
                    // TL 
                    .L1_tl_A_valid_o            (cluster_bus_master_A_valid[i][j]), 
                    .L1_tl_A_ready_i            (cluster_bus_master_A_ready[i][j]), 
                    .L1_tl_A_bits_o             (cluster_bus_master_A_bits [i][j]),
                    .L1_tl_B_valid_i            (cluster_bus_master_B_valid[i][j]), 
                    .L1_tl_B_ready_o            (cluster_bus_master_B_ready[i][j]), 
                    .L1_tl_B_bits_i             (cluster_bus_master_B_bits [i][j]),
                    .L1_tl_C_valid_o            (cluster_bus_master_C_valid[i][j]), 
                    .L1_tl_C_ready_i            (cluster_bus_master_C_ready[i][j]), 
                    .L1_tl_C_bits_o             (cluster_bus_master_C_bits [i][j]),
                    .L1_tl_D_valid_i            (cluster_bus_master_D_valid[i][j]), 
                    .L1_tl_D_ready_o            (cluster_bus_master_D_ready[i][j]), 
                    .L1_tl_D_bits_i             (cluster_bus_master_D_bits [i][j]),
                    .L1_tl_E_valid_o            (cluster_bus_master_E_valid[i][j]), 
                    .L1_tl_E_ready_i            (cluster_bus_master_E_ready[i][j]), 
                    .L1_tl_E_bits_o             (cluster_bus_master_E_bits [i][j])
                );       
            end
            // cluster bus, two cores use one cluster bus
            tl_xbar #(
                .MASTER_NUM       (2),
                .SLAVE_NUM        (1),
                .REGION_NUM       (1),
                .SOURCE_LSB       (1),
                .SOURCE_MSB       (2),
                .SINK_LSB         (1),
                .SINK_MSB         (2),
                .TL_ADDR_WIDTH    (64)
            ) ClusterBus(
                .clk_i            ( clk_sys_i         ),
                .rst_i            ( rst_i         ),

                .master_A_valid_i (cluster_bus_master_A_valid[i]),
                .master_A_ready_o (cluster_bus_master_A_ready[i]),
                .master_A_bits_i  (cluster_bus_master_A_bits [i]),
                .master_B_valid_o (cluster_bus_master_B_valid[i]),
                .master_B_ready_i (cluster_bus_master_B_ready[i]),
                .master_B_bits_o  (cluster_bus_master_B_bits [i]),
                .master_C_valid_i (cluster_bus_master_C_valid[i]),
                .master_C_ready_o (cluster_bus_master_C_ready[i]),
                .master_C_bits_i  (cluster_bus_master_C_bits [i]),
                .master_D_valid_o (cluster_bus_master_D_valid[i]),
                .master_D_ready_i (cluster_bus_master_D_ready[i]),
                .master_D_bits_o  (cluster_bus_master_D_bits [i]),
                .master_E_valid_i (cluster_bus_master_E_valid[i]),
                .master_E_ready_o (cluster_bus_master_E_ready[i]),
                .master_E_bits_i  (cluster_bus_master_E_bits [i]),

                .slave_A_valid_o  (sys_bus_master_A_valid[i]),
                .slave_A_ready_i  (sys_bus_master_A_ready[i]),
                .slave_A_bits_o   (sys_bus_master_A_bits [i]),
                .slave_B_valid_i  (sys_bus_master_B_valid[i]),
                .slave_B_ready_o  (sys_bus_master_B_ready[i]),
                .slave_B_bits_i   (sys_bus_master_B_bits [i]),
                .slave_C_valid_o  (sys_bus_master_C_valid[i]),
                .slave_C_ready_i  (sys_bus_master_C_ready[i]),
                .slave_C_bits_o   (sys_bus_master_C_bits [i]),
                .slave_D_valid_i  (sys_bus_master_D_valid[i]),
                .slave_D_ready_o  (sys_bus_master_D_ready[i]),
                .slave_D_bits_i   (sys_bus_master_D_bits [i]),
                .slave_E_valid_o  (sys_bus_master_E_valid[i]),
                .slave_E_ready_i  (sys_bus_master_E_ready[i]),
                .slave_E_bits_o   (sys_bus_master_E_bits [i]),

                .start_addr_i     ( '0            ),
                .end_addr_i       ({64{1'b1}}),
                .region_en_i      (1'b1)
            );
        end
    endgenerate
//======================================================================================================================
// Config Bus from outside
//======================================================================================================================
    AXI_lite32_to_TL #(
        .SOURCE     ({2'b1,(MEM_BUS_SRC_LSB-1)'($clog2(CORE_NUM)+1)}) // source ID 
    ) axil32_to_tl_inst(
        .clk_i                          (clk_sys_i),
        .rst_i                          (rst_i),
        // =====================================
        // [AXI_lite32 bus]
        .axi_awaddr_i                   (cfg_awaddr_i ),                              
        .axi_awvalid_i                  (cfg_awvalid_i),                              
        .axi_awready_o                  (cfg_awready_o),                              
        .axi_wdata_i                    (cfg_wdata_i  ),                              
        .axi_wvalid_i                   (cfg_wvalid_i ),                              
        .axi_wready_o                   (cfg_wready_o ),                              
        .axi_bresp_o                    (cfg_bresp_o  ),                              
        .axi_bvalid_o                   (cfg_bvalid_o ),                              
        .axi_bready_i                   (cfg_bready_i ),                              
        // -- read channel
        .axi_araddr_i                   (cfg_araddr_i ),                    
        .axi_arvalid_i                  (cfg_arvalid_i),                    
        .axi_arready_o                  (cfg_arready_o),                    
        .axi_rdata_o                    (cfg_rdata_o  ),                    
        .axi_rresp_o                    (cfg_rresp_o  ),                    
        .axi_rvalid_o                   (cfg_rvalid_o ),                    
        .axi_rready_i                   (cfg_rready_i ),                    
        // =====================================
        // [TL bus]
        .tl_A_valid_o                   (sys_bus_master_A_valid[$clog2(CORE_NUM)+1]),
        .tl_A_ready_i                   (sys_bus_master_A_ready[$clog2(CORE_NUM)+1]),
        .tl_A_bits_o                    (sys_bus_master_A_bits [$clog2(CORE_NUM)+1]),
        .tl_B_valid_i                   (sys_bus_master_B_valid[$clog2(CORE_NUM)+1]),
        .tl_B_ready_o                   (sys_bus_master_B_ready[$clog2(CORE_NUM)+1]),
        .tl_B_bits_i                    (sys_bus_master_B_bits [$clog2(CORE_NUM)+1]),
        .tl_C_valid_o                   (sys_bus_master_C_valid[$clog2(CORE_NUM)+1]),
        .tl_C_ready_i                   (sys_bus_master_C_ready[$clog2(CORE_NUM)+1]),
        .tl_C_bits_o                    (sys_bus_master_C_bits [$clog2(CORE_NUM)+1]),
        .tl_D_valid_i                   (sys_bus_master_D_valid[$clog2(CORE_NUM)+1]),
        .tl_D_ready_o                   (sys_bus_master_D_ready[$clog2(CORE_NUM)+1]),
        .tl_D_bits_i                    (sys_bus_master_D_bits [$clog2(CORE_NUM)+1]),
        .tl_E_valid_o                   (sys_bus_master_E_valid[$clog2(CORE_NUM)+1]),
        .tl_E_ready_i                   (sys_bus_master_E_ready[$clog2(CORE_NUM)+1]),
        .tl_E_bits_o                    (sys_bus_master_E_bits [$clog2(CORE_NUM)+1])
    );
//======================================================================================================================
// AXI-lite32 bus to bootrom
//======================================================================================================================
    TL2AXI_lite32 tl2axil_32_inst (
        .clk_i                          (clk_sys_i), 
        .rst_i                          (rst_i), 

        .tl_A_valid_i                   (phri_bus_slave_A_valid[AXIL32]),        
        .tl_A_ready_o                   (phri_bus_slave_A_ready[AXIL32]),        
        .tl_A_bits_i                    (phri_bus_slave_A_bits [AXIL32]),       
        .tl_B_valid_o                   (phri_bus_slave_B_valid[AXIL32]),        
        .tl_B_ready_i                   (phri_bus_slave_B_ready[AXIL32]),        
        .tl_B_bits_o                    (phri_bus_slave_B_bits [AXIL32]),       
        .tl_C_valid_i                   (phri_bus_slave_C_valid[AXIL32]),        
        .tl_C_ready_o                   (phri_bus_slave_C_ready[AXIL32]),        
        .tl_C_bits_i                    (phri_bus_slave_C_bits [AXIL32]),       
        .tl_D_valid_o                   (phri_bus_slave_D_valid[AXIL32]),        
        .tl_D_ready_i                   (phri_bus_slave_D_ready[AXIL32]),        
        .tl_D_bits_o                    (phri_bus_slave_D_bits [AXIL32]),       
        .tl_E_valid_i                   (phri_bus_slave_E_valid[AXIL32]),        
        .tl_E_ready_o                   (phri_bus_slave_E_ready[AXIL32]),        
        .tl_E_bits_i                    (phri_bus_slave_E_bits [AXIL32]),       

        .axi_awaddr_o                   (axilm32_awaddr_o ),                       
        .axi_awvalid_o                  (axilm32_awvalid_o),                       
        .axi_awready_i                  (axilm32_awready_i),                       
        .axi_wdata_o                    (axilm32_wdata_o  ),                       
        .axi_wstrb_o                    (axilm32_wstrb_o  ),
        .axi_wvalid_o                   (axilm32_wvalid_o ),                       
        .axi_wready_i                   (axilm32_wready_i ),                       
        .axi_bresp_i                    (axilm32_bresp_i  ),                       
        .axi_bvalid_i                   (axilm32_bvalid_i ),                       
        .axi_bready_o                   (axilm32_bready_o ),                       
        .axi_araddr_o                   (axilm32_araddr_o ),                       
        .axi_arvalid_o                  (axilm32_arvalid_o),                       
        .axi_arready_i                  (axilm32_arready_i),                       
        .axi_rdata_i                    (axilm32_rdata_i  ),                       
        .axi_rresp_i                    (axilm32_rresp_i  ),                       
        .axi_rvalid_i                   (axilm32_rvalid_i ),                       
        .axi_rready_o                   (axilm32_rready_o )           
    ); 
//======================================================================================================================
// System Bus
//======================================================================================================================
    // ---------------
    // TileLink Xbar
    // ---------------
    sy_tl_xbar #(
        .MASTER_NUM            ($clog2(CORE_NUM) + 2),
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
        .clk_i                  (clk_sys_i),
        .rst_i                  (rst_i),
        .master_A_valid_i       (sys_bus_master_A_valid),
        .master_A_ready_o       (sys_bus_master_A_ready),
        .master_A_bits_i        (sys_bus_master_A_bits ),
        .master_B_valid_o       (sys_bus_master_B_valid),
        .master_B_ready_i       (sys_bus_master_B_ready),
        .master_B_bits_o        (sys_bus_master_B_bits ),
        .master_C_valid_i       (sys_bus_master_C_valid),
        .master_C_ready_o       (sys_bus_master_C_ready),
        .master_C_bits_i        (sys_bus_master_C_bits ),
        .master_D_valid_o       (sys_bus_master_D_valid),
        .master_D_ready_i       (sys_bus_master_D_ready),
        .master_D_bits_o        (sys_bus_master_D_bits ),
        .master_E_valid_i       (sys_bus_master_E_valid),
        .master_E_ready_o       (sys_bus_master_E_ready),
        .master_E_bits_i        (sys_bus_master_E_bits ),

        .slave_A_valid_o        (sys_bus_slave_A_valid),
        .slave_A_ready_i        (sys_bus_slave_A_ready),
        .slave_A_bits_o         (sys_bus_slave_A_bits ),
        .slave_B_valid_i        (sys_bus_slave_B_valid),
        .slave_B_ready_o        (sys_bus_slave_B_ready),
        .slave_B_bits_i         (sys_bus_slave_B_bits ),
        .slave_C_valid_o        (sys_bus_slave_C_valid),
        .slave_C_ready_i        (sys_bus_slave_C_ready),
        .slave_C_bits_o         (sys_bus_slave_C_bits ),
        .slave_D_valid_i        (sys_bus_slave_D_valid),
        .slave_D_ready_o        (sys_bus_slave_D_ready),
        .slave_D_bits_i         (sys_bus_slave_D_bits ),
        .slave_E_valid_o        (sys_bus_slave_E_valid),
        .slave_E_ready_i        (sys_bus_slave_E_ready),
        .slave_E_bits_o         (sys_bus_slave_E_bits ),

        .start_addr_i           (sys_bus_start_addr ),
        .end_addr_i             (sys_bus_end_addr   ),
        .region_en_i            (sys_bus_region_en)
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
        .clk_i            ( clk_sys_i         ),
        .rst_i            ( rst_i         ),

        .master_A_valid_i       (sys_bus_slave_A_valid[CTRL_BUS]),
        .master_A_ready_o       (sys_bus_slave_A_ready[CTRL_BUS]),
        .master_A_bits_i        (sys_bus_slave_A_bits [CTRL_BUS]),
        .master_B_valid_o       (sys_bus_slave_B_valid[CTRL_BUS]),
        .master_B_ready_i       (sys_bus_slave_B_ready[CTRL_BUS]),
        .master_B_bits_o        (sys_bus_slave_B_bits [CTRL_BUS]),
        .master_C_valid_i       (sys_bus_slave_C_valid[CTRL_BUS]),
        .master_C_ready_o       (sys_bus_slave_C_ready[CTRL_BUS]),
        .master_C_bits_i        (sys_bus_slave_C_bits [CTRL_BUS]),
        .master_D_valid_o       (sys_bus_slave_D_valid[CTRL_BUS]),
        .master_D_ready_i       (sys_bus_slave_D_ready[CTRL_BUS]),
        .master_D_bits_o        (sys_bus_slave_D_bits [CTRL_BUS]),
        .master_E_valid_i       (sys_bus_slave_E_valid[CTRL_BUS]),
        .master_E_ready_o       (sys_bus_slave_E_ready[CTRL_BUS]),
        .master_E_bits_i        (sys_bus_slave_E_bits [CTRL_BUS]),

        .slave_A_valid_o        (ctrl_bus_slave_A_valid),
        .slave_A_ready_i        (ctrl_bus_slave_A_ready),
        .slave_A_bits_o         (ctrl_bus_slave_A_bits ),
        .slave_B_valid_i        (ctrl_bus_slave_B_valid),
        .slave_B_ready_o        (ctrl_bus_slave_B_ready),
        .slave_B_bits_i         (ctrl_bus_slave_B_bits ),
        .slave_C_valid_o        (ctrl_bus_slave_C_valid),
        .slave_C_ready_i        (ctrl_bus_slave_C_ready),
        .slave_C_bits_o         (ctrl_bus_slave_C_bits ),
        .slave_D_valid_i        (ctrl_bus_slave_D_valid),
        .slave_D_ready_o        (ctrl_bus_slave_D_ready),
        .slave_D_bits_i         (ctrl_bus_slave_D_bits ),
        .slave_E_valid_o        (ctrl_bus_slave_E_valid),
        .slave_E_ready_i        (ctrl_bus_slave_E_ready),
        .slave_E_bits_o         (ctrl_bus_slave_E_bits ),

        .start_addr_i     ( ctrl_bus_start_addr),
        .end_addr_i       ( ctrl_bus_end_addr),
        .region_en_i      ( ctrl_bus_region_en)
    );
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
        .clk_i                  ( clk_sys_i         ),
        .rst_i                  ( rst_i         ),
        .master_A_valid_i       (sys_bus_slave_A_valid[PHRI_BUS]),
        .master_A_ready_o       (sys_bus_slave_A_ready[PHRI_BUS]),
        .master_A_bits_i        (sys_bus_slave_A_bits [PHRI_BUS]),
        .master_B_valid_o       (sys_bus_slave_B_valid[PHRI_BUS]),
        .master_B_ready_i       (sys_bus_slave_B_ready[PHRI_BUS]),
        .master_B_bits_o        (sys_bus_slave_B_bits [PHRI_BUS]),
        .master_C_valid_i       (sys_bus_slave_C_valid[PHRI_BUS]),
        .master_C_ready_o       (sys_bus_slave_C_ready[PHRI_BUS]),
        .master_C_bits_i        (sys_bus_slave_C_bits [PHRI_BUS]),
        .master_D_valid_o       (sys_bus_slave_D_valid[PHRI_BUS]),
        .master_D_ready_i       (sys_bus_slave_D_ready[PHRI_BUS]),
        .master_D_bits_o        (sys_bus_slave_D_bits [PHRI_BUS]),
        .master_E_valid_i       (sys_bus_slave_E_valid[PHRI_BUS]),
        .master_E_ready_o       (sys_bus_slave_E_ready[PHRI_BUS]),
        .master_E_bits_i        (sys_bus_slave_E_bits [PHRI_BUS]),

        .slave_A_valid_o        (phri_bus_slave_A_valid),
        .slave_A_ready_i        (phri_bus_slave_A_ready),
        .slave_A_bits_o         (phri_bus_slave_A_bits ),
        .slave_B_valid_i        (phri_bus_slave_B_valid),
        .slave_B_ready_o        (phri_bus_slave_B_ready),
        .slave_B_bits_i         (phri_bus_slave_B_bits ),
        .slave_C_valid_o        (phri_bus_slave_C_valid),
        .slave_C_ready_i        (phri_bus_slave_C_ready),
        .slave_C_bits_o         (phri_bus_slave_C_bits ),
        .slave_D_valid_i        (phri_bus_slave_D_valid),
        .slave_D_ready_o        (phri_bus_slave_D_ready),
        .slave_D_bits_i         (phri_bus_slave_D_bits ),
        .slave_E_valid_o        (phri_bus_slave_E_valid),
        .slave_E_ready_i        (phri_bus_slave_E_ready),
        .slave_E_bits_o         (phri_bus_slave_E_bits ),

        .start_addr_i     ( phri_bus_start_addr),
        .end_addr_i       ( phri_bus_end_addr),
        .region_en_i      ( phri_bus_region_en)
    );
//======================================================================================================================
// DMA Bus
//======================================================================================================================
    // ---------------
    // TileLink Xbar
    // ---------------
    sy_tl_xbar #(
        .MASTER_NUM       (1),
        .SLAVE_NUM        (DMA_BUS_SLAVE_NUM),
        .REGION_NUM       (DMA_BUS_REGION),
        .SOURCE_LSB       (DMA_BUS_SRC_LSB),
        .SOURCE_MSB       (DMA_BUS_SRC_MSB),
        .SINK_LSB         (1),
        .SINK_MSB         (4),
        .TL_ADDR_WIDTH    (64),
        .MASTER_BUF_DEPTH (1),
        .SLAVE_BUF_DEPTH  (1)
    ) dma_bus(
        .clk_i                  ( clk_sys_i         ),
        .rst_i                  ( rst_i         ),
        .master_A_valid_i       (sys_bus_slave_A_valid[DMA_BUS]),
        .master_A_ready_o       (sys_bus_slave_A_ready[DMA_BUS]),
        .master_A_bits_i        (sys_bus_slave_A_bits [DMA_BUS]),
        .master_B_valid_o       (sys_bus_slave_B_valid[DMA_BUS]),
        .master_B_ready_i       (sys_bus_slave_B_ready[DMA_BUS]),
        .master_B_bits_o        (sys_bus_slave_B_bits [DMA_BUS]),
        .master_C_valid_i       (sys_bus_slave_C_valid[DMA_BUS]),
        .master_C_ready_o       (sys_bus_slave_C_ready[DMA_BUS]),
        .master_C_bits_i        (sys_bus_slave_C_bits [DMA_BUS]),
        .master_D_valid_o       (sys_bus_slave_D_valid[DMA_BUS]),
        .master_D_ready_i       (sys_bus_slave_D_ready[DMA_BUS]),
        .master_D_bits_o        (sys_bus_slave_D_bits [DMA_BUS]),
        .master_E_valid_i       (sys_bus_slave_E_valid[DMA_BUS]),
        .master_E_ready_o       (sys_bus_slave_E_ready[DMA_BUS]),
        .master_E_bits_i        (sys_bus_slave_E_bits [DMA_BUS]),

        .slave_A_valid_o        (dma_bus_slave_A_valid),
        .slave_A_ready_i        (dma_bus_slave_A_ready),
        .slave_A_bits_o         (dma_bus_slave_A_bits ),
        .slave_B_valid_i        (dma_bus_slave_B_valid),
        .slave_B_ready_o        (dma_bus_slave_B_ready),
        .slave_B_bits_i         (dma_bus_slave_B_bits ),
        .slave_C_valid_o        (dma_bus_slave_C_valid),
        .slave_C_ready_i        (dma_bus_slave_C_ready),
        .slave_C_bits_o         (dma_bus_slave_C_bits ),
        .slave_D_valid_i        (dma_bus_slave_D_valid),
        .slave_D_ready_o        (dma_bus_slave_D_ready),
        .slave_D_bits_i         (dma_bus_slave_D_bits ),
        .slave_E_valid_o        (dma_bus_slave_E_valid),
        .slave_E_ready_i        (dma_bus_slave_E_ready),
        .slave_E_bits_o         (dma_bus_slave_E_bits ),

        .start_addr_i     ( dma_bus_start_addr),
        .end_addr_i       ( dma_bus_end_addr),
        .region_en_i      ( dma_bus_region_en)
    );
//======================================================================================================================
// Main Memory
//======================================================================================================================
    sy_main_mem #(
        .HART_NUM       (CORE_NUM),
        .HART_ID_WTH    (HART_ID_WTH),
        .HART_ID_LSB    (1)
    ) main_mem(
        .clk_i                          (clk_sys_i),
        .rst_i                          (rst_i),
        .inp_tl_A_valid_i               (sys_bus_slave_A_valid[DMEM]),
        .inp_tl_A_ready_o               (sys_bus_slave_A_ready[DMEM]),
        .inp_tl_A_bits_i                (sys_bus_slave_A_bits [DMEM]),
        .inp_tl_B_valid_o               (sys_bus_slave_B_valid[DMEM]),
        .inp_tl_B_ready_i               (sys_bus_slave_B_ready[DMEM]),
        .inp_tl_B_bits_o                (sys_bus_slave_B_bits [DMEM]),
        .inp_tl_C_valid_i               (sys_bus_slave_C_valid[DMEM]),
        .inp_tl_C_ready_o               (sys_bus_slave_C_ready[DMEM]),
        .inp_tl_C_bits_i                (sys_bus_slave_C_bits [DMEM]),
        .inp_tl_D_valid_o               (sys_bus_slave_D_valid[DMEM]),
        .inp_tl_D_ready_i               (sys_bus_slave_D_ready[DMEM]),
        .inp_tl_D_bits_o                (sys_bus_slave_D_bits [DMEM]),
        .inp_tl_E_valid_i               (sys_bus_slave_E_valid[DMEM]),
        .inp_tl_E_ready_o               (sys_bus_slave_E_ready[DMEM]),
        .inp_tl_E_bits_i                (sys_bus_slave_E_bits [DMEM]),

        .flush_L2_cache_en_i            (flush_L2_cache_en),
        .flush_L2_cache_busy_o          (flush_L2_cache_busy),
        .inv_L2_cache_en_i              (inv_L2_cache_en),
        .inv_L2_cache_busy_o            (inv_L2_cache_busy),
        // AXI4 interface
        .oup_axi_aw_valid_o             (ddr_axi_aw_valid_o),            
        .oup_axi_aw_ready_i             (ddr_axi_aw_ready_i),                     
        .oup_axi_aw_bits_o              (ddr_axi_aw_bits_o ),           
        .oup_axi_ar_valid_o             (ddr_axi_ar_valid_o),            
        .oup_axi_ar_ready_i             (ddr_axi_ar_ready_i),                     
        .oup_axi_ar_bits_o              (ddr_axi_ar_bits_o ),           
        .oup_axi_w_valid_o              (ddr_axi_w_valid_o ),           
        .oup_axi_w_ready_i              (ddr_axi_w_ready_i ),                    
        .oup_axi_w_bits_o               (ddr_axi_w_bits_o  ),          
        .oup_axi_r_valid_i              (ddr_axi_r_valid_i ),           
        .oup_axi_r_ready_o              (ddr_axi_r_ready_o ),           
        .oup_axi_r_bits_i               (ddr_axi_r_bits_i  ),           
        .oup_axi_b_valid_i              (ddr_axi_b_valid_i ),           
        .oup_axi_b_ready_o              (ddr_axi_b_ready_o ),           
        .oup_axi_b_bits_i               (ddr_axi_b_bits_i  )
    );

//======================================================================================================================
// RegMap (ctrl bus)
//======================================================================================================================
    sy_regmap #(
        .BASE_ADDR  (REGMAPBase),
        .ADDR_WIDTH (32),
        .DATA_WIDTH (32),
        .IRQ_NUM    (IRQ_NUM),
        .SOURCE     (0)
    ) regmap_inst(
        .clk_i                  (clk_sys_i),       
        .rst_i                  (rst_sys_i),      

        .inp_tl_A_valid_i       (ctrl_bus_slave_A_valid[REGMAP]),
        .inp_tl_A_ready_o       (ctrl_bus_slave_A_ready[REGMAP]),
        .inp_tl_A_bits_i        (ctrl_bus_slave_A_bits [REGMAP]),
        .inp_tl_B_valid_o       (ctrl_bus_slave_B_valid[REGMAP]),
        .inp_tl_B_ready_i       (ctrl_bus_slave_B_ready[REGMAP]),
        .inp_tl_B_bits_o        (ctrl_bus_slave_B_bits [REGMAP]),
        .inp_tl_C_valid_i       (ctrl_bus_slave_C_valid[REGMAP]),
        .inp_tl_C_ready_o       (ctrl_bus_slave_C_ready[REGMAP]),
        .inp_tl_C_bits_i        (ctrl_bus_slave_C_bits [REGMAP]),
        .inp_tl_D_valid_o       (ctrl_bus_slave_D_valid[REGMAP]),
        .inp_tl_D_ready_i       (ctrl_bus_slave_D_ready[REGMAP]),
        .inp_tl_D_bits_o        (ctrl_bus_slave_D_bits [REGMAP]),
        .inp_tl_E_valid_i       (ctrl_bus_slave_E_valid[REGMAP]),
        .inp_tl_E_ready_o       (ctrl_bus_slave_E_ready[REGMAP]),
        .inp_tl_E_bits_i        (ctrl_bus_slave_E_bits [REGMAP]),

        .siyuan_call_o          (siyuan_call        ),
        .siyuan_invdc_o         (siyuan_invdc       ),
        .siyuan_invic_o         (siyuan_invic       ),
        .siyuan_kill_o          (siyuan_kill        ),
        .siyuan_call_busy_i     (siyuan_call_busy   ),
        .siyuan_invdc_busy_i    (siyuan_invdc_busy  ),
        .siyuan_invic_busy_i    (siyuan_invic_busy  ),
        .siyuan_kill_busy_i     (siyuan_kill_busy   ),
        .siyuan_fence_state_o   (siyuan_fence_state ),
        .exe_region_ex_en_o     (exe_region_ex_en   ),                       
        .siyuan_forbid_br_pred_o(siyuan_forbid_br_pred),
        .siyuan_avail_cores_o   (siyuan_avail_cores ),
        .flush_L2_cache_en_o    (flush_L2_cache_en  ),                       
        .flush_L2_cache_busy_i  (flush_L2_cache_busy),
        .inv_L2_cache_en_o      (inv_L2_cache_en  ),                       
        .inv_L2_cache_busy_i    (inv_L2_cache_busy),
        .siyuan_init_pc_o       (siyuan_init_pc     ),
        .siyuan_ret_addr_o      (siyuan_ret_addr    ),

        .siyuan_irq_o           (siyuan_irq_o       ),

        .ddr_base_addr_o        (ddr_base_addr_o    )
    );
//======================================================================================================================
// Clint (ctrl bus)
//======================================================================================================================
    sy_clint #(
        .ADDR_WIDTH   (64),
        .DATA_WIDTH   (64),
        .CORES_NUM    (CORE_NUM) 
    ) clint(
        .clk_i          (clk_sys_i),                 
        .rst_i          (rst_i),                
        .rtc_i          (clk_rtc_i),                 
        .timer_irq_o    (timer_irq),                 
        .ipi_o          (ipi),                 

        .tl_A_valid_i   (ctrl_bus_slave_A_valid[CLINT]),
        .tl_A_ready_o   (ctrl_bus_slave_A_ready[CLINT]),
        .tl_A_bits_i    (ctrl_bus_slave_A_bits [CLINT]),
        .tl_B_valid_o   (ctrl_bus_slave_B_valid[CLINT]),
        .tl_B_ready_i   (ctrl_bus_slave_B_ready[CLINT]),
        .tl_B_bits_o    (ctrl_bus_slave_B_bits [CLINT]),
        .tl_C_valid_i   (ctrl_bus_slave_C_valid[CLINT]),
        .tl_C_ready_o   (ctrl_bus_slave_C_ready[CLINT]),
        .tl_C_bits_i    (ctrl_bus_slave_C_bits [CLINT]),
        .tl_D_valid_o   (ctrl_bus_slave_D_valid[CLINT]),
        .tl_D_ready_i   (ctrl_bus_slave_D_ready[CLINT]),
        .tl_D_bits_o    (ctrl_bus_slave_D_bits [CLINT]),
        .tl_E_valid_i   (ctrl_bus_slave_E_valid[CLINT]),
        .tl_E_ready_o   (ctrl_bus_slave_E_ready[CLINT]),
        .tl_E_bits_i    (ctrl_bus_slave_E_bits [CLINT])
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
        .clk_i          (clk_sys_i),              
        .rst_i          (rst_i),             

        .irq_sources_i  (irq_sources),               
        .irq_target_o   (irq_target),              

        .inp_tl_A_valid_i   (ctrl_bus_slave_A_valid[PLIC]),
        .inp_tl_A_ready_o   (ctrl_bus_slave_A_ready[PLIC]),
        .inp_tl_A_bits_i    (ctrl_bus_slave_A_bits [PLIC]),
        .inp_tl_B_valid_o   (ctrl_bus_slave_B_valid[PLIC]),
        .inp_tl_B_ready_i   (ctrl_bus_slave_B_ready[PLIC]),
        .inp_tl_B_bits_o    (ctrl_bus_slave_B_bits [PLIC]),
        .inp_tl_C_valid_i   (ctrl_bus_slave_C_valid[PLIC]),
        .inp_tl_C_ready_o   (ctrl_bus_slave_C_ready[PLIC]),
        .inp_tl_C_bits_i    (ctrl_bus_slave_C_bits [PLIC]),
        .inp_tl_D_valid_o   (ctrl_bus_slave_D_valid[PLIC]),
        .inp_tl_D_ready_i   (ctrl_bus_slave_D_ready[PLIC]),
        .inp_tl_D_bits_o    (ctrl_bus_slave_D_bits [PLIC]),
        .inp_tl_E_valid_i   (ctrl_bus_slave_E_valid[PLIC]),
        .inp_tl_E_ready_o   (ctrl_bus_slave_E_ready[PLIC]),
        .inp_tl_E_bits_i    (ctrl_bus_slave_E_bits [PLIC])
    );
//======================================================================================================================
// Uart (phri bus) 
//======================================================================================================================
    sy_uart uart(
        .clk_i          (clk_sys_i),         
        .rst_i          (rst_i),         
        .rx_i           (rx),        
        .tx_o           (tx),        

        .irq_o          (irq_sources[0]),     

        .inp_tl_A_valid_i   (phri_bus_slave_A_valid[UART]),
        .inp_tl_A_ready_o   (phri_bus_slave_A_ready[UART]),
        .inp_tl_A_bits_i    (phri_bus_slave_A_bits [UART]),
        .inp_tl_B_valid_o   (phri_bus_slave_B_valid[UART]),
        .inp_tl_B_ready_i   (phri_bus_slave_B_ready[UART]),
        .inp_tl_B_bits_o    (phri_bus_slave_B_bits [UART]),
        .inp_tl_C_valid_i   (phri_bus_slave_C_valid[UART]),
        .inp_tl_C_ready_o   (phri_bus_slave_C_ready[UART]),
        .inp_tl_C_bits_i    (phri_bus_slave_C_bits [UART]),
        .inp_tl_D_valid_o   (phri_bus_slave_D_valid[UART]),
        .inp_tl_D_ready_i   (phri_bus_slave_D_ready[UART]),
        .inp_tl_D_bits_o    (phri_bus_slave_D_bits [UART]),
        .inp_tl_E_valid_i   (phri_bus_slave_E_valid[UART]),
        .inp_tl_E_ready_o   (phri_bus_slave_E_ready[UART]),
        .inp_tl_E_bits_i    (phri_bus_slave_E_bits [UART])
    );
//======================================================================================================================
// SD (phri bus)
//======================================================================================================================
    sy_sd sd_inst(
        .clk_i          (clk_sys_i),    
        .rst_i          (rst_i),    
    
        .irq_o          (irq_sources[1]),    

        .sd_detect      (sd_detect  ),
        .sd_clk         (sd_clk     ),
        .sd_reset       (sd_reset   ),
        .sd_dat_i       (sd_dat_i   ),
        .sd_dat_o       (sd_dat_o   ),
        .sd_dat_oe_o    (sd_dat_oe_o),
        .sd_cmd_i       (sd_cmd_i   ),
        .sd_cmd_o       (sd_cmd_o   ),
        .sd_cmd_oe_o    (sd_cmd_oe_o),
    
        .inp_tl_A_valid_i   (phri_bus_slave_A_valid[SPI]),
        .inp_tl_A_ready_o   (phri_bus_slave_A_ready[SPI]),
        .inp_tl_A_bits_i    (phri_bus_slave_A_bits [SPI]),
        .inp_tl_B_valid_o   (phri_bus_slave_B_valid[SPI]),
        .inp_tl_B_ready_i   (phri_bus_slave_B_ready[SPI]),
        .inp_tl_B_bits_o    (phri_bus_slave_B_bits [SPI]),
        .inp_tl_C_valid_i   (phri_bus_slave_C_valid[SPI]),
        .inp_tl_C_ready_o   (phri_bus_slave_C_ready[SPI]),
        .inp_tl_C_bits_i    (phri_bus_slave_C_bits [SPI]),
        .inp_tl_D_valid_o   (phri_bus_slave_D_valid[SPI]),
        .inp_tl_D_ready_i   (phri_bus_slave_D_ready[SPI]),
        .inp_tl_D_bits_o    (phri_bus_slave_D_bits [SPI]),
        .inp_tl_E_valid_i   (phri_bus_slave_E_valid[SPI]),
        .inp_tl_E_ready_o   (phri_bus_slave_E_ready[SPI]),
        .inp_tl_E_bits_i    (phri_bus_slave_E_bits [SPI])
    );       
//======================================================================================================================
// Debug (DMA bus)
//======================================================================================================================
    sy_debug # (
        .HART_NUM        (CORE_NUM),
        .SOURCE          (DEBUG_SOURCE_ID)
    ) debug_inst(
        .clk_i          (clk_sys_i),       
        .rst_i          (rst_sys_i),      
        .cpu_rst_n      (rst_i),
        // JTAG interface
        .tck            (tck   ),
        .tms            (tms   ),
        .trst_n         (trst_n),
        .tdi            (tdi   ),
        .tdo            (tdo   ),        
        // reset
        .ndmreset       (ndmreset_o),
        .debug_req_irq  (debug_req_irq),

        .inp_tl_A_valid_i   (dma_bus_slave_A_valid[DEBUG]),
        .inp_tl_A_ready_o   (dma_bus_slave_A_ready[DEBUG]),
        .inp_tl_A_bits_i    (dma_bus_slave_A_bits [DEBUG]),
        .inp_tl_B_valid_o   (dma_bus_slave_B_valid[DEBUG]),
        .inp_tl_B_ready_i   (dma_bus_slave_B_ready[DEBUG]),
        .inp_tl_B_bits_o    (dma_bus_slave_B_bits [DEBUG]),
        .inp_tl_C_valid_i   (dma_bus_slave_C_valid[DEBUG]),
        .inp_tl_C_ready_o   (dma_bus_slave_C_ready[DEBUG]),
        .inp_tl_C_bits_i    (dma_bus_slave_C_bits [DEBUG]),
        .inp_tl_D_valid_o   (dma_bus_slave_D_valid[DEBUG]),
        .inp_tl_D_ready_i   (dma_bus_slave_D_ready[DEBUG]),
        .inp_tl_D_bits_o    (dma_bus_slave_D_bits [DEBUG]),
        .inp_tl_E_valid_i   (dma_bus_slave_E_valid[DEBUG]),
        .inp_tl_E_ready_o   (dma_bus_slave_E_ready[DEBUG]),
        .inp_tl_E_bits_i    (dma_bus_slave_E_bits [DEBUG]),

        .oup_tl_A_valid_o   (mem_bus_master_A_valid[DEBUG]),
        .oup_tl_A_ready_i   (mem_bus_master_A_ready[DEBUG]),
        .oup_tl_A_bits_o    (mem_bus_master_A_bits [DEBUG]),
        .oup_tl_B_valid_i   (mem_bus_master_B_valid[DEBUG]),
        .oup_tl_B_ready_o   (mem_bus_master_B_ready[DEBUG]),
        .oup_tl_B_bits_i    (mem_bus_master_B_bits [DEBUG]),
        .oup_tl_C_valid_o   (mem_bus_master_C_valid[DEBUG]),
        .oup_tl_C_ready_i   (mem_bus_master_C_ready[DEBUG]),
        .oup_tl_C_bits_o    (mem_bus_master_C_bits [DEBUG]),
        .oup_tl_D_valid_i   (mem_bus_master_D_valid[DEBUG]),
        .oup_tl_D_ready_o   (mem_bus_master_D_ready[DEBUG]),
        .oup_tl_D_bits_i    (mem_bus_master_D_bits [DEBUG]),
        .oup_tl_E_valid_o   (mem_bus_master_E_valid[DEBUG]),
        .oup_tl_E_ready_i   (mem_bus_master_E_ready[DEBUG]),
        .oup_tl_E_bits_o    (mem_bus_master_E_bits [DEBUG])

    );
//======================================================================================================================
// DMA (DMA bus)
//======================================================================================================================
    sy_dma # (
        .BASE_ADDR  (DMABase),
        .ADDR_WIDTH (32),
        .DATA_WIDTH (32),
        .SOURCE     (DMA_SOURCE_ID) 
    ) dma_inst(
        .clk_i          (clk_sys_i),       
        .rst_i          (rst_i),      

        .irq_o              (irq_sources[2]),
        .inp_tl_A_valid_i   (dma_bus_slave_A_valid[DMA]),
        .inp_tl_A_ready_o   (dma_bus_slave_A_ready[DMA]),
        .inp_tl_A_bits_i    (dma_bus_slave_A_bits [DMA]),
        .inp_tl_B_valid_o   (dma_bus_slave_B_valid[DMA]),
        .inp_tl_B_ready_i   (dma_bus_slave_B_ready[DMA]),
        .inp_tl_B_bits_o    (dma_bus_slave_B_bits [DMA]),
        .inp_tl_C_valid_i   (dma_bus_slave_C_valid[DMA]),
        .inp_tl_C_ready_o   (dma_bus_slave_C_ready[DMA]),
        .inp_tl_C_bits_i    (dma_bus_slave_C_bits [DMA]),
        .inp_tl_D_valid_o   (dma_bus_slave_D_valid[DMA]),
        .inp_tl_D_ready_i   (dma_bus_slave_D_ready[DMA]),
        .inp_tl_D_bits_o    (dma_bus_slave_D_bits [DMA]),
        .inp_tl_E_valid_i   (dma_bus_slave_E_valid[DMA]),
        .inp_tl_E_ready_o   (dma_bus_slave_E_ready[DMA]),
        .inp_tl_E_bits_i    (dma_bus_slave_E_bits [DMA]),

        .oup_tl_A_valid_o   (mem_bus_master_A_valid[DMA]),
        .oup_tl_A_ready_i   (mem_bus_master_A_ready[DMA]),
        .oup_tl_A_bits_o    (mem_bus_master_A_bits [DMA]),
        .oup_tl_B_valid_i   (mem_bus_master_B_valid[DMA]),
        .oup_tl_B_ready_o   (mem_bus_master_B_ready[DMA]),
        .oup_tl_B_bits_i    (mem_bus_master_B_bits [DMA]),
        .oup_tl_C_valid_o   (mem_bus_master_C_valid[DMA]),
        .oup_tl_C_ready_i   (mem_bus_master_C_ready[DMA]),
        .oup_tl_C_bits_o    (mem_bus_master_C_bits [DMA]),
        .oup_tl_D_valid_i   (mem_bus_master_D_valid[DMA]),
        .oup_tl_D_ready_o   (mem_bus_master_D_ready[DMA]),
        .oup_tl_D_bits_i    (mem_bus_master_D_bits [DMA]),
        .oup_tl_E_valid_o   (mem_bus_master_E_valid[DMA]),
        .oup_tl_E_ready_i   (mem_bus_master_E_ready[DMA]),
        .oup_tl_E_bits_o    (mem_bus_master_E_bits [DMA])
    );
//======================================================================================================================
// Mem bus (used by DMA/Debug to access system bus)
//======================================================================================================================
    sy_tl_xbar #(
        .MASTER_NUM            (MEM_BUS_MASTER_NUM),
        .SLAVE_NUM             (1),
        .REGION_NUM            (1),
        .SOURCE_LSB            (MEM_BUS_SRC_LSB),
        .SOURCE_MSB            (MEM_BUS_SRC_MSB),
        .SINK_LSB              (1),
        .SINK_MSB              (4),
        .TL_ADDR_WIDTH         (64),
        .MASTER_BUF_DEPTH      (1),
        .SLAVE_BUF_DEPTH       (1)
    ) mem_bus(
        .clk_i            ( clk_sys_i     ),
        .rst_i            ( rst_i         ),

        .master_A_valid_i       (mem_bus_master_A_valid),
        .master_A_ready_o       (mem_bus_master_A_ready),
        .master_A_bits_i        (mem_bus_master_A_bits ),
        .master_B_valid_o       (mem_bus_master_B_valid),
        .master_B_ready_i       (mem_bus_master_B_ready),
        .master_B_bits_o        (mem_bus_master_B_bits ),
        .master_C_valid_i       (mem_bus_master_C_valid),
        .master_C_ready_o       (mem_bus_master_C_ready),
        .master_C_bits_i        (mem_bus_master_C_bits ),
        .master_D_valid_o       (mem_bus_master_D_valid),
        .master_D_ready_i       (mem_bus_master_D_ready),
        .master_D_bits_o        (mem_bus_master_D_bits ),
        .master_E_valid_i       (mem_bus_master_E_valid),
        .master_E_ready_o       (mem_bus_master_E_ready),
        .master_E_bits_i        (mem_bus_master_E_bits ),

        .slave_A_valid_o        (sys_bus_master_A_valid[$clog2(CORE_NUM)]),
        .slave_A_ready_i        (sys_bus_master_A_ready[$clog2(CORE_NUM)]),
        .slave_A_bits_o         (sys_bus_master_A_bits [$clog2(CORE_NUM)]),
        .slave_B_valid_i        (sys_bus_master_B_valid[$clog2(CORE_NUM)]),
        .slave_B_ready_o        (sys_bus_master_B_ready[$clog2(CORE_NUM)]),
        .slave_B_bits_i         (sys_bus_master_B_bits [$clog2(CORE_NUM)]),
        .slave_C_valid_o        (sys_bus_master_C_valid[$clog2(CORE_NUM)]),
        .slave_C_ready_i        (sys_bus_master_C_ready[$clog2(CORE_NUM)]),
        .slave_C_bits_o         (sys_bus_master_C_bits [$clog2(CORE_NUM)]),
        .slave_D_valid_i        (sys_bus_master_D_valid[$clog2(CORE_NUM)]),
        .slave_D_ready_o        (sys_bus_master_D_ready[$clog2(CORE_NUM)]),
        .slave_D_bits_i         (sys_bus_master_D_bits [$clog2(CORE_NUM)]),
        .slave_E_valid_o        (sys_bus_master_E_valid[$clog2(CORE_NUM)]),
        .slave_E_ready_i        (sys_bus_master_E_ready[$clog2(CORE_NUM)]),
        .slave_E_bits_o         (sys_bus_master_E_bits [$clog2(CORE_NUM)]),
 
        .start_addr_i     ( mem_bus_start_addr),
        .end_addr_i       ( mem_bus_end_addr),
        .region_en_i      ( mem_bus_region_en)
    );
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on

endmodule 

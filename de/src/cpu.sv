// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : cpu.sv
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
// MODULE DESCRIPTION:
// Siyuan CPU Top-Level Module

// The Siyuan CPU is a 64-bit RISC-V processor implementing the IMAFDC instruction set architecture. It features a
// 4-core configuration with cache coherency support.

// Key Features:
// - RISC-V IMAFDC(GC) 64-bit instruction set support
// - 4-core CPU with cache coherence
// - JTAG debug interface compatible with official 0.13.2 protocol
// - Configuration bus using AXI-Lite protocol for initial PC configuration and CPU control (start/stop)
// - Split L1 cache architecture with unified L2 cache
// - L2 cache connected to external DDR memory via AXI4 protocol
// - Bypass data bus using AXI-Lite protocol for accessing shared on-chip memory and HPU configuration bus
// - Independent peripheral interfaces including UART and SD card controller

// Siyuan CPU top

module cpu
    import sy_pkg::*;
    import sy_soc_pkg::*;
# (
    // cpu core number
    parameter CPU_NUM = 4,                  // cpu core number
    // Bus configuration
    parameter CFGBUS_AWTH = 16,             // configure bus address width
    parameter CFGBUS_DWTH = 32,             // configure bus data width
    parameter AXIBUS_IDWTH = 4,             // AXI bus ID width
    parameter AXIBUS_AWTH = 40,             // AXI bus address width
    parameter AXIBUS_DWTH = 64,             // AXI bus data width
    parameter AXIBUS_OUTSTD = 8,            // outstanding of AXI transactions
    parameter AXIBUS_BLEN = 64              // typical burst length of AXI transactions
) (
    // -------------------------------------
    // [clock & reset]
    input   logic                           clk_sys_i,                  // power on system clock
    input   logic                           clk_rtc_i,                  // 32.768K crystal
    input   logic                           rst_sys_i,                  // power on system reset
    input   logic                           rst_i,                      // HPU reset
    output  logic                           ndmreset_o,                 // Debug module sends reset request
    // [JTAG debug]
    input   logic                           jtag_tck_i,                 // JTAG test clock pad
    input   logic                           jtag_trst_n_i,              // JTAG test reset pad
    input   logic                           jtag_tms_i,                 // JTAG test mode select pad
    input   logic                           jtag_tdi_i,                 // JTAG test data input pad
    output  logic                           jtag_tdo_o,                 // JTAG test data output pad
    // -------------------------------------
    // [Config]
    // -- AXI Lite
    // -- write channel
    input   logic[CFGBUS_AWTH-1:0]          cfg_awaddr_i,               // -- 16bit, write address
    input   logic                           cfg_awvalid_i,              // -- valid
    output  logic                           cfg_awready_o,              // -- ready
    input   logic[CFGBUS_DWTH-1:0]          cfg_wdata_i,                // -- 32bit, write data
    input   logic                           cfg_wvalid_i,               // -- valid
    output  logic                           cfg_wready_o,               // -- ready
    output  logic[1:0]                      cfg_bresp_o,                // -- 2bit, responce
    output  logic                           cfg_bvalid_o,               // -- valid
    input   logic                           cfg_bready_i,               // -- ready
    // -- read channel
    input   logic[CFGBUS_AWTH-1:0]          cfg_araddr_i,               // -- 16bit, read address
    input   logic                           cfg_arvalid_i,              // -- valid
    output  logic                           cfg_arready_o,              // -- ready
    output  logic[CFGBUS_DWTH-1:0]          cfg_rdata_o,                // -- 32bit, read data
    output  logic[1:0]                      cfg_rresp_o,                // -- 2bit, responce
    output  logic                           cfg_rvalid_o,               // -- valid
    input   logic                           cfg_rready_i,               // -- ready
    // -- Boot mode
    input   logic                           boot_mode_i,                // 1'h0: idle; 1'h1: boot ROM;
    // -------------------------------------
    // [L1 cache (instr/data)]
    // -- <write channel>
    output  logic[AXIBUS_IDWTH-1:0]         cpu_awid_o,                 // AW channel of AXI3/4
    output  logic[AXIBUS_AWTH-1:0]          cpu_awaddr_o,               // -- DDR_AW, write address
    output  logic[7:0]                      cpu_awlen_o,                // -- 8bit, write length (for AXI3)
    output  logic[2:0]                      cpu_awsize_o,               // -- 3bit, write size
    output  logic[1:0]                      cpu_awburst_o,              // -- 2bit, burst type
    output  logic                           cpu_awvalid_o,              // -- valid
    input   logic                           cpu_awready_i,              // -- ready
    output  logic[AXIBUS_DWTH-1:0]          cpu_wdata_o,                // -- DDR_DW, write data
    output  logic[AXIBUS_DWTH/8-1:0]        cpu_wstrb_o,                // -- DDR_DW, write data
    output  logic                           cpu_wlast_o,                // -- 1bit, write data last
    output  logic                           cpu_wvalid_o,               // -- valid
    input   logic                           cpu_wready_i,               // -- ready
    input   logic[AXIBUS_IDWTH-1:0]         cpu_bid_i,                  // B channel of AXI3/4
    input   logic[1:0]                      cpu_bresp_i,                // -- 2bit, responce
    input   logic                           cpu_bvalid_i,               // -- valid
    output  logic                           cpu_bready_o,               // -- ready
    // -- <read channel>
    output  logic[AXIBUS_IDWTH-1:0]         cpu_arid_o,                 // AR channel of AXI3/4
    output  logic[AXIBUS_AWTH-1:0]          cpu_araddr_o,               // -- DDR_AW, read address
    output  logic[7:0]                      cpu_arlen_o,                // -- 8bit, read length (for AXI3)
    output  logic[2:0]                      cpu_arsize_o,               // -- 3bit, read size
    output  logic[1:0]                      cpu_arburst_o,              // -- 2bit, burst type
    output  logic                           cpu_arvalid_o,              // -- valid
    input   logic                           cpu_arready_i,              // -- ready
    input   logic[AXIBUS_IDWTH-1:0]         cpu_rid_i,                  // RD channdl for AXI3/4
    input   logic[AXIBUS_DWTH-1:0]          cpu_rdata_i,                // -- DDR_DW, read data
    input   logic                           cpu_rlast_i,                // -- 1bit, read data last
    input   logic[1:0]                      cpu_rresp_i,                // -- 2bit, responce
    input   logic                           cpu_rvalid_i,               // -- valid
    output  logic                           cpu_rready_o,               // -- ready
    // -------------------------------------
    // [32bit AXI lite bus master]
    // -- write
    output  logic[31:0]                     axil32_awaddr_o,            // -- 32bit, write address
    output  logic                           axil32_awvalid_o,           // -- valid
    input   logic                           axil32_awready_i,           // -- ready
    output  logic[31:0]                     axil32_wdata_o,             // -- 32bit, write data
    output  logic[3:0]                      axil32_wstrb_o,             // -- 32/8bit, write data strobe
    output  logic                           axil32_wvalid_o,            // -- valid
    input   logic                           axil32_wready_i,            // -- ready
    input   logic[1:0]                      axil32_bresp_i,             // -- 2bit, responce
    input   logic                           axil32_bvalid_i,            // -- valid
    output  logic                           axil32_bready_o,            // -- ready
    // -- read
    output  logic[31:0]                     axil32_araddr_o,            // -- 32bit, read address
    output  logic                           axil32_arvalid_o,           // -- valid
    input   logic                           axil32_arready_i,           // -- ready
    input   logic[31:0]                     axil32_rdata_i,             // -- 32bit, read data
    input   logic[1:0]                      axil32_rresp_i,             // -- 2bit, responce
    input   logic                           axil32_rvalid_i,            // -- valid
    output  logic                           axil32_rready_o,            // -- ready
    // -------------------------------------
    // [UART]
    output  logic                           uart_txd_o,                 // UART TXD
    input   logic                           uart_rxd_i,                 // UART RXD
    // -------------------------------------
    // [SD card]
    input   logic                           sd_detect,
    output  logic                           sd_clk,
    output  logic                           sd_reset,
    input   logic [3:0]                     sd_dat_i,
    output  logic [3:0]                     sd_dat_o,
    output  logic                           sd_dat_oe_o,
    input   logic                           sd_cmd_i,
    output  logic                           sd_cmd_o,
    output  logic                           sd_cmd_oe_o
);

// =====================================================================================================================
// Local parameters

// =====================================================================================================================
// Local variables
    logic                           ddr_axi_aw_valid;
    logic                           ddr_axi_aw_ready;
    axi_pkg::aw_chan_t              ddr_axi_aw_bits;
    logic                           ddr_axi_ar_valid;
    logic                           ddr_axi_ar_ready;
    axi_pkg::ar_chan_t              ddr_axi_ar_bits;
    logic                           ddr_axi_w_valid;
    logic                           ddr_axi_w_ready;
    axi_pkg::w_chan_t               ddr_axi_w_bits;
    logic                           ddr_axi_r_valid;
    logic                           ddr_axi_r_ready;
    axi_pkg::r_chan_t               ddr_axi_r_bits;
    logic                           ddr_axi_b_valid;
    logic                           ddr_axi_b_ready;
    axi_pkg::b_chan_t               ddr_axi_b_bits;
    logic[31:0]                     ddr_base_addr;

    logic[63:0]                     cfg_awaddr;
    logic[63:0]                     cfg_araddr;
// =====================================================================================================================
// Instances
// =====================================================================================================================
    assign cfg_awaddr = {REGMAP_START[63:16],cfg_awaddr_i};
    assign cfg_araddr = {REGMAP_START[63:16],cfg_araddr_i};
    sy # (
        .IRQ_NUM        (1)
    ) SiYuan_top_inst(
        .clk_sys_i          (clk_sys_i),
        .clk_rtc_i          (clk_rtc_i),
        .rst_sys_i          (rst_sys_i),
        .rst_i              (rst_i    ),
        .ndmreset_o         (ndmreset_o),

        .ddr_base_addr_o    (ddr_base_addr),
        .boot_mode_i        (boot_mode_i),
        // -------------------------------------
        // [Config]
        // -- AXI Lite 32
        // -- write channel
        .cfg_awaddr_i       (cfg_awaddr  ),              // -- 16bit, write address
        .cfg_awvalid_i      (cfg_awvalid_i),              // -- valid
        .cfg_awready_o      (cfg_awready_o),              // -- ready
        .cfg_wdata_i        (cfg_wdata_i ),              // -- 32bit, write data
        .cfg_wvalid_i       (cfg_wvalid_i),              // -- valid
        .cfg_wready_o       (cfg_wready_o),              // -- ready
        .cfg_bresp_o        (cfg_bresp_o ),              // -- 2bit, responce
        .cfg_bvalid_o       (cfg_bvalid_o),              // -- valid
        .cfg_bready_i       (cfg_bready_i),              // -- ready

        .cfg_araddr_i       (cfg_araddr    ),            // -- 16bit, read address
        .cfg_arvalid_i      (cfg_arvalid_i ),            // -- valid
        .cfg_arready_o      (cfg_arready_o ),            // -- ready
        .cfg_rdata_o        (cfg_rdata_o   ),            // -- 32bit, read data
        .cfg_rresp_o        (cfg_rresp_o   ),            // -- 2bit, responce
        .cfg_rvalid_o       (cfg_rvalid_o  ),            // -- valid
        .cfg_rready_i       (cfg_rready_i  ),            // -- ready
        // -------------------------------------
        // [32bit AXI lite bus master]
        // -- write
        .axilm32_awaddr_o   (axil32_awaddr_o ),             // -- 40bit, write address
        .axilm32_awvalid_o  (axil32_awvalid_o),            // -- valid
        .axilm32_awready_i  (axil32_awready_i),            // -- ready
        .axilm32_wdata_o    (axil32_wdata_o  ),              // -- 64bit, write data
        .axilm32_wstrb_o    (axil32_wstrb_o  ),              // -- 64/8bit, write data strobe
        .axilm32_wvalid_o   (axil32_wvalid_o ),             // -- valid
        .axilm32_wready_i   (axil32_wready_i ),             // -- ready
        .axilm32_bresp_i    (axil32_bresp_i  ),              // -- 2bit, responce
        .axilm32_bvalid_i   (axil32_bvalid_i ),             // -- valid
        .axilm32_bready_o   (axil32_bready_o ),             // -- ready

        .axilm32_araddr_o   (axil32_araddr_o ),             // -- 40bit, read address
        .axilm32_arvalid_o  (axil32_arvalid_o),            // -- valid
        .axilm32_arready_i  (axil32_arready_i),            // -- ready
        .axilm32_rdata_i    (axil32_rdata_i  ),              // -- 64bit, read data
        .axilm32_rresp_i    (axil32_rresp_i  ),              // -- 2bit, responce
        .axilm32_rvalid_i   (axil32_rvalid_i ),             // -- valid
        .axilm32_rready_o   (axil32_rready_o ),             // -- ready
        // -------------------------------------
        // [L2 cache (instr/data)]
        .ddr_axi_aw_valid_o (ddr_axi_aw_valid),
        .ddr_axi_aw_ready_i (ddr_axi_aw_ready),
        .ddr_axi_aw_bits_o  (ddr_axi_aw_bits ),
        .ddr_axi_ar_valid_o (ddr_axi_ar_valid),
        .ddr_axi_ar_ready_i (ddr_axi_ar_ready),
        .ddr_axi_ar_bits_o  (ddr_axi_ar_bits ),
        .ddr_axi_w_valid_o  (ddr_axi_w_valid ),
        .ddr_axi_w_ready_i  (ddr_axi_w_ready ),
        .ddr_axi_w_bits_o   (ddr_axi_w_bits  ),
        .ddr_axi_r_valid_i  (ddr_axi_r_valid ),
        .ddr_axi_r_ready_o  (ddr_axi_r_ready ),
        .ddr_axi_r_bits_i   (ddr_axi_r_bits  ),
        .ddr_axi_b_valid_i  (ddr_axi_b_valid ),
        .ddr_axi_b_ready_o  (ddr_axi_b_ready ),
        .ddr_axi_b_bits_i   (ddr_axi_b_bits  ),
        // JTAG
        .tck                (jtag_tck_i),
        .tms                (jtag_tms_i),
        .trst_n             (jtag_trst_n_i),
        .tdi                (jtag_tdi_i),
        .tdo                (jtag_tdo_o),
        // SD
        .sd_detect          (sd_detect   ),
        .sd_clk             (sd_clk      ),
        .sd_reset           (sd_reset    ),
        .sd_dat_i           (sd_dat_i    ),
        .sd_dat_o           (sd_dat_o    ),
        .sd_dat_oe_o        (sd_dat_oe_o ),
        .sd_cmd_i           (sd_cmd_i    ),
        .sd_cmd_o           (sd_cmd_o    ),
        .sd_cmd_oe_o        (sd_cmd_oe_o ),
        // common part
        .rx                 (uart_rxd_i),
        .tx                 (uart_txd_o)
    );

    assign cpu_awid_o   = ddr_axi_aw_bits.id;
    assign cpu_awaddr_o = ddr_axi_aw_bits.addr + {ddr_base_addr,12'h0};
    assign cpu_awlen_o  = ddr_axi_aw_bits.len;
    assign cpu_awsize_o = ddr_axi_aw_bits.size;
    assign cpu_awburst_o= ddr_axi_aw_bits.burst;
    assign cpu_awvalid_o= ddr_axi_aw_valid;
    assign ddr_axi_aw_ready = cpu_awready_i;

    // assign cpu_wid_o   = ddr_axi_w_bits.id;
    assign cpu_wdata_o = ddr_axi_w_bits.data;
    assign cpu_wstrb_o = ddr_axi_w_bits.strb;
    assign cpu_wlast_o = ddr_axi_w_bits.last;
    assign cpu_wvalid_o= ddr_axi_w_valid;
    assign ddr_axi_w_ready = cpu_wready_i;

    assign ddr_axi_b_valid      = cpu_bvalid_i;
    assign ddr_axi_b_bits.id    = cpu_bid_i;
    assign ddr_axi_b_bits.resp  = cpu_bresp_i;
    assign cpu_bready_o         = ddr_axi_b_ready;

    assign cpu_arid_o       = ddr_axi_ar_bits.id;
    assign cpu_araddr_o     = ddr_axi_ar_bits.addr + {ddr_base_addr,12'h0};
    assign cpu_arlen_o      = ddr_axi_ar_bits.len;
    assign cpu_arsize_o     = ddr_axi_ar_bits.size;
    assign cpu_arburst_o    = ddr_axi_ar_bits.burst;
    assign cpu_arvalid_o    = ddr_axi_ar_valid;

    assign ddr_axi_ar_ready     = cpu_arready_i;
    assign ddr_axi_r_bits.id    = cpu_rid_i;
    assign ddr_axi_r_bits.data  = cpu_rdata_i;
    assign ddr_axi_r_bits.last  = cpu_rlast_i;
    assign ddr_axi_r_bits.resp  = cpu_rresp_i;
    assign ddr_axi_r_valid      = cpu_rvalid_i;
    assign cpu_rready_o         = ddr_axi_r_ready;
// =====================================================================================================================
// Assertions
// =====================================================================================================================

// =====================================================================================================================
// Probes
// =====================================================================================================================

// synopsys translate_off

// synopsys translate_on

endmodule : cpu

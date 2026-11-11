// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : cpu_genesys2_top.v
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

module cpu_genesys2_top
(
    input  logic         sys_clk_p   ,
    input  logic         sys_clk_n   ,
    // DDR 
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
    // JTAG 
    input  logic         trst_n,
    input  logic         tck         ,
    input  logic         tms         ,
    input  logic         tdi         ,
    output wire          tdo         ,
    // SD
    output wire          sd_sclk     ,
    input  wire          sd_detect   ,
    inout  wire [3:0]    sd_dat      ,
    inout  wire          sd_cmd      ,
    output reg           sd_reset    ,
    // Uart
    input  logic         rx          ,
    output logic         tx
);

//======================================================================================================================
// Parameters
//======================================================================================================================
localparam AxiAddrWidth = 64;
localparam AxiDataWidth = 64;
localparam AxiIdWidthMaster = 4;
localparam AxiIdWidthSlaves = 5; // 5
localparam AxiUserWidth = 1;
localparam int DIV = 763;    // 50M
// localparam int DIV = 152; // 10M
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
logic                                   clk_sys;
logic                                   clk_sd;
logic                                   rst_sys;
logic                                   rst;
logic                                   pll_locked0;
logic                                   pll_locked1;
logic                                   ddr_clock_out;
logic                                   ndmreset;
logic                                   ndmreset_n;
logic                                   ddr_sync_reset;
logic                                   sd_clk_slow;                  
logic                                   sd_clk_fast;           
logic                                   sd_clk_true;
logic                                   sd_clk_sel;
logic                                   sd_cmd_in;            
logic                                   sd_cmd_out;           
logic                                   sd_cmd_oe;
logic[3:0]                              sd_dat_in;            
logic[3:0]                              sd_dat_out;           
logic                                   sd_dat_oe;
logic                                   sd_clk_out_internal;
logic                                   sd_clk_out;
// DDR interface
logic[3:0]                              cpu_awid;    
logic[39:0]                             cpu_awaddr;  
logic[7:0]                              cpu_awlen;   
logic[2:0]                              cpu_awsize;  
logic[1:0]                              cpu_awburst; 
logic                                   cpu_awvalid; 
logic                                   cpu_awready; 
// logic[3:0]                           cpu_wid;     
logic[63:0]                             cpu_wdata;   
logic[7:0]                              cpu_wstrb;   
logic                                   cpu_wlast;   
logic                                   cpu_wvalid;  
logic                                   cpu_wready;  
logic[3:0]                              cpu_bid;     
logic[1:0]                              cpu_bresp;   
logic                                   cpu_bvalid;  
logic                                   cpu_bready;  
logic[3:0]                              cpu_arid;   
logic[39:0]                             cpu_araddr; 
logic[7:0]                              cpu_arlen;  
logic[2:0]                              cpu_arsize; 
logic[1:0]                              cpu_arburst;
logic                                   cpu_arvalid;
logic                                   cpu_arready;
logic[3:0]                              cpu_rid;    
logic[63:0]                             cpu_rdata;  
logic                                   cpu_rlast;  
logic[1:0]                              cpu_rresp;  
logic                                   cpu_rvalid; 
logic                                   cpu_rready; 
 
logic [AxiIdWidthSlaves-1:0]            s_axi_awid;
logic [AxiAddrWidth-1:0]                s_axi_awaddr;
logic [7:0]                             s_axi_awlen;
logic [2:0]                             s_axi_awsize;
logic [1:0]                             s_axi_awburst;
logic [0:0]                             s_axi_awlock;
logic [3:0]                             s_axi_awcache;
logic [2:0]                             s_axi_awprot;
logic [3:0]                             s_axi_awregion;
logic [3:0]                             s_axi_awqos;
logic                                   s_axi_awvalid;
logic                                   s_axi_awready;
logic [AxiDataWidth-1:0]                s_axi_wdata;
logic [AxiDataWidth/8-1:0]              s_axi_wstrb;
logic                                   s_axi_wlast;
logic                                   s_axi_wvalid;
logic                                   s_axi_wready;
logic [AxiIdWidthSlaves-1:0]            s_axi_bid;
logic [1:0]                             s_axi_bresp;
logic                                   s_axi_bvalid;
logic                                   s_axi_bready;
logic [AxiIdWidthSlaves-1:0]            s_axi_arid;
logic [AxiAddrWidth-1:0]                s_axi_araddr;
logic [7:0]                             s_axi_arlen;
logic [2:0]                             s_axi_arsize;
logic [1:0]                             s_axi_arburst;
logic [0:0]                             s_axi_arlock;
logic [3:0]                             s_axi_arcache;
logic [2:0]                             s_axi_arprot;
logic [3:0]                             s_axi_arregion;
logic [3:0]                             s_axi_arqos;
logic                                   s_axi_arvalid;
logic                                   s_axi_arready;
logic [AxiIdWidthSlaves-1:0]            s_axi_rid;
logic [AxiDataWidth-1:0]                s_axi_rdata;
logic [1:0]                             s_axi_rresp;
logic                                   s_axi_rlast;
logic                                   s_axi_rvalid;
logic                                   s_axi_rready;
logic[31:0]                             axil32_awaddr;
logic                                   axil32_awvalid;
logic                                   axil32_awready;
logic[31:0]                             axil32_wdata;
logic[3:0]                              axil32_wstrb;
logic                                   axil32_wvalid;
logic                                   axil32_wready;
logic                                   axil32_bvalid;
logic                                   axil32_bready;
logic[1:0]                              axil32_bresp;
logic[31:0]                             axil32_araddr;
logic                                   axil32_arvalid;
logic                                   axil32_arready;
logic[31:0]                             axil32_rdata;
logic                                   axil32_rvalid;
logic                                   axil32_rready;
logic[1:0]                              axil32_rresp;
logic[$clog2(DIV)-1:0]                  cnt;
logic                                   clk_rtc;
logic                                   cpu_reset;
//======================================================================================================================
// Clock generator
//======================================================================================================================
assign cpu_reset = ~cpu_resetn;
xlnx_clk_gen i_xlnx_clk_gen0 (
  .clk_out1 ( clk_sys       ), // 50MHz
  .reset    ( cpu_reset     ),
  .locked   ( pll_locked0   ),
  .clk_in1  ( ddr_clock_out )
);

rstgen i_rstgen_main (
    .clk_i        ( clk_sys                  ),
    .rst_ni       ( pll_locked0 & (~ndmreset) ), // 
    .test_mode_i  ( 1'b0                     ),
    .rst_no       ( ndmreset_n               ),
    .init_no      (                          ) // keep open
);

assign rst_sys = ~ddr_sync_reset;
assign rst = ndmreset_n;

// 50 MHz / 1526  ≈ 32.759 kHz（误差 0.027%）
always_ff @(posedge clk_sys or negedge rst_sys) begin
    if (!rst_sys) begin
        clk_rtc <= 1'b0;
        cnt <= 0;
    end else begin
        if (cnt == DIV-1) begin
            cnt <= 0;
            clk_rtc <= ~clk_rtc;
        end else begin
            cnt <= cnt + 1;
        end
    end
end
// sd cmd/dat tri state
assign  sd_cmd      =   sd_cmd_oe ? sd_cmd_out : 1'bz;
assign  sd_dat      =   sd_dat_oe ? sd_dat_out : 4'bzzzz;
assign  sd_cmd_in   =   sd_cmd;
assign  sd_dat_in   =   sd_dat;

ODDR sd_clk_oddr (
    .Q(sd_clk_out),
    .C(sd_clk_out_internal),
    .CE(1),
    .D1(1),
    .D2(0),
    .R(0),
    .S(0)
);
assign sd_sclk = sd_clk_out;
//======================================================================================================================
// Bootrom
//======================================================================================================================
cpu_bootrom bootrom_inst(
    .clk_i              (clk_sys),
    // AXI-lite 32
    .axil32_awaddr_i    (axil32_awaddr  ),
    .axil32_awvalid_i   (axil32_awvalid ),
    .axil32_awready_o   (axil32_awready ),
    .axil32_wdata_i     (axil32_wdata   ),
    .axil32_wstrb_i     (axil32_wstrb   ),
    .axil32_wvalid_i    (axil32_wvalid  ),
    .axil32_wready_o    (axil32_wready  ),
    .axil32_bvalid_o    (axil32_bvalid  ),
    .axil32_bready_i    (axil32_bready  ),
    .axil32_bresp_o     (axil32_bresp   ),

    .axil32_araddr_i    (axil32_araddr ),
    .axil32_arvalid_i   (axil32_arvalid),
    .axil32_arready_o   (axil32_arready),
    .axil32_rdata_o     (axil32_rdata  ),
    .axil32_rvalid_o    (axil32_rvalid ),
    .axil32_rready_i    (axil32_rready ),
    .axil32_rresp_o     (axil32_rresp  )
);

//======================================================================================================================
// CPU top
//======================================================================================================================

cpu #(
    // Bus configuration
    .CFGBUS_AWTH    (16),             // configure bus address width
    .CFGBUS_DWTH    (32),             // configure bus data width
    .AXIBUS_IDWTH   (4),              // AXI bus ID width
    .AXIBUS_AWTH    (40),             // AXI bus address width
    .AXIBUS_DWTH    (64),             // AXI bus data width
    .AXIBUS_OUTSTD  (8),              // outstanding of AXI transactions
    .AXIBUS_BLEN    (64)              // typical burst length of AXI transactions
) cpu_inst(
    // -------------------------------------
    // [clock & reset]
    .clk_sys_i      (clk_sys),                  // power on system clock
    .clk_rtc_i      (clk_rtc),                  // 32.768K crystal
    .rst_sys_i      (rst_sys),                  // power on system reset
    .rst_i          (rst),                      // HPU reset
    .ndmreset_o     (ndmreset),                 // Debug module sends reset request
    // -------------------------------------
    // [JTAG debug]
    .jtag_tck_i     (tck),                  // JTAG test clock pad
    .jtag_trst_n_i  (trst_n),               // JTAG test reset pad
    .jtag_tms_i     (tms),                  // JTAG test mode select pad
    .jtag_tdi_i     (tdi),                  // JTAG test data input pad
    .jtag_tdo_o     (tdo),                  // JTAG test data output pad
    // -------------------------------------
    // [Config]
    // -- AXI Lite
    // -- write channel
    .cfg_awaddr_i   ('0),                   // -- 16bit, write address
    .cfg_awvalid_i  ('0),                   // -- valid
    .cfg_awready_o  (),                     // -- ready
    .cfg_wdata_i    ('0),                   // -- 32bit, write data
    .cfg_wvalid_i   ('0),                   // -- valid
    .cfg_wready_o   (),                     // -- ready
    .cfg_bresp_o    (),                     // -- 2bit, responce
    .cfg_bvalid_o   (),                     // -- valid
    .cfg_bready_i   ('0),                   // -- ready
    // -- read channel
    .cfg_araddr_i   ('0),                   // -- 16bit, read address
    .cfg_arvalid_i  ('0),                   // -- valid
    .cfg_arready_o  (),                     // -- ready
    .cfg_rdata_o    (),                     // -- 32bit, read data
    .cfg_rresp_o    (),                     // -- 2bit, responce
    .cfg_rvalid_o   (),                     // -- valid
    .cfg_rready_i   ('0),                   // -- ready
    // -- Boot mode
    .boot_mode_i    (1'b1),                 // 1'h0: idle; 1'h1: boot ROM;
    // -------------------------------------
    // [L1 cache (instr/data)]
    // -- <write channel>
    .cpu_awid_o     (cpu_awid   ),                 // AW channel of AXI3/4
    .cpu_awaddr_o   (cpu_awaddr ),                 // -- DDR_AW, write address
    .cpu_awlen_o    (cpu_awlen  ),                 // -- 8bit, write length (for AXI3)
    .cpu_awsize_o   (cpu_awsize ),                 // -- 3bit, write size
    .cpu_awburst_o  (cpu_awburst),                 // -- 2bit, burst type
    .cpu_awvalid_o  (cpu_awvalid),                 // -- valid
    .cpu_awready_i  (cpu_awready),                 // -- ready
    .cpu_wdata_o    (cpu_wdata ),                 // -- DDR_DW, write data
    .cpu_wstrb_o    (cpu_wstrb ),                 // -- DDR_DW, write data
    .cpu_wlast_o    (cpu_wlast ),                 // -- 1bit, write data last
    .cpu_wvalid_o   (cpu_wvalid),                 // -- valid
    .cpu_wready_i   (cpu_wready),                 // -- ready
    .cpu_bid_i      (cpu_bid   ),                 // B channel of AXI3/4
    .cpu_bresp_i    (cpu_bresp ),                 // -- 2bit, responce
    .cpu_bvalid_i   (cpu_bvalid),                 // -- valid
    .cpu_bready_o   (cpu_bready),                 // -- ready
    // -- <read channel>
    .cpu_arid_o     (cpu_arid   ),                 // AR channel of AXI3/4
    .cpu_araddr_o   (cpu_araddr ),                 // -- DDR_AW, read address
    .cpu_arlen_o    (cpu_arlen  ),                 // -- 8bit, read length (for AXI3)
    .cpu_arsize_o   (cpu_arsize ),                 // -- 3bit, read size
    .cpu_arburst_o  (cpu_arburst),                 // -- 2bit, burst type
    .cpu_arvalid_o  (cpu_arvalid),                 // -- valid
    .cpu_arready_i  (cpu_arready),                 // -- ready
    .cpu_rid_i      (cpu_rid    ),                 // RD channdl for AXI3/4
    .cpu_rdata_i    (cpu_rdata  ),                 // -- DDR_DW, read data
    .cpu_rlast_i    (cpu_rlast  ),                 // -- 1bit, read data last
    .cpu_rresp_i    (cpu_rresp  ),                 // -- 2bit, responce
    .cpu_rvalid_i   (cpu_rvalid ),                 // -- valid
    .cpu_rready_o   (cpu_rready ),                 // -- ready
    // -------------------------------------
    // [32bit AXI lite bus master]
    // -- write
    .axil32_awaddr_o    (axil32_awaddr ),            // -- 32bit, write address
    .axil32_awvalid_o   (axil32_awvalid),            // -- valid
    .axil32_awready_i   (axil32_awready),            // -- ready
    .axil32_wdata_o     (axil32_wdata  ),            // -- 32bit, write data
    .axil32_wstrb_o     (axil32_wstrb  ),            // -- 32/8bit, write data strobe
    .axil32_wvalid_o    (axil32_wvalid ),            // -- valid
    .axil32_wready_i    (axil32_wready ),            // -- ready
    .axil32_bresp_i     (axil32_bresp  ),            // -- 2bit, responce
    .axil32_bvalid_i    (axil32_bvalid ),            // -- valid
    .axil32_bready_o    (axil32_bready ),            // -- ready
    // -- read
    .axil32_araddr_o    (axil32_araddr ),             // -- 32bit, read address
    .axil32_arvalid_o   (axil32_arvalid),             // -- valid
    .axil32_arready_i   (axil32_arready),             // -- ready
    .axil32_rdata_i     (axil32_rdata  ),             // -- 32bit, read data
    .axil32_rresp_i     (axil32_rresp  ),             // -- 2bit, responce
    .axil32_rvalid_i    (axil32_rvalid ),             // -- valid
    .axil32_rready_o    (axil32_rready ),             // -- ready
    // -------------------------------------
    // [UART]
    .uart_txd_o         (tx),             // UART TXD
    .uart_rxd_i         (rx),             // UART RXD
    // -------------------------------------
    // [SD]
    .sd_detect          (sd_detect  ),
    .sd_clk             (sd_clk_out_internal),
    .sd_reset           (sd_reset   ),
    .sd_dat_i           (sd_dat_in  ),
    .sd_dat_o           (sd_dat_out ),
    .sd_dat_oe_o        (sd_dat_oe  ),
    .sd_cmd_i           (sd_cmd_in  ),
    .sd_cmd_o           (sd_cmd_out ),
    .sd_cmd_oe_o        (sd_cmd_oe  )
);
//======================================================================================================================
// DDR 
//======================================================================================================================
xlnx_axi_clock_converter i_xlnx_axi_clock_converter_ddr (
  .s_axi_aclk     ( clk_sys         ),
  .s_axi_aresetn  ( rst             ),
  // address write
  .s_axi_awid     ( cpu_awid        ),
  .s_axi_awaddr   ( cpu_awaddr      ),
  .s_axi_awlen    ( cpu_awlen       ),
  .s_axi_awsize   ( cpu_awsize      ),
  .s_axi_awburst  ( cpu_awburst     ),
  .s_axi_awlock   ( '0              ),
  .s_axi_awcache  ( '0              ),
  .s_axi_awprot   ( 3'b1            ),
  .s_axi_awregion ( '0              ),  // not use
  .s_axi_awqos    ( '0              ),
  .s_axi_awvalid  ( cpu_awvalid     ),
  .s_axi_awready  ( cpu_awready     ),

  .s_axi_wdata    ( cpu_wdata       ),
  .s_axi_wstrb    ( cpu_wstrb       ),
  .s_axi_wlast    ( cpu_wlast       ),
  .s_axi_wvalid   ( cpu_wvalid      ),
  .s_axi_wready   ( cpu_wready      ),

  .s_axi_bid      ( cpu_bid         ),
  .s_axi_bresp    ( cpu_bresp       ),
  .s_axi_bvalid   ( cpu_bvalid      ),
  .s_axi_bready   ( cpu_bready      ),

  .s_axi_arid     ( cpu_arid        ),
  .s_axi_araddr   ( cpu_araddr      ),
  .s_axi_arlen    ( cpu_arlen       ),
  .s_axi_arsize   ( cpu_arsize      ),
  .s_axi_arburst  ( cpu_arburst     ),
  .s_axi_arlock   ( '0              ),
  .s_axi_arcache  ( '0              ),
  .s_axi_arprot   ( 3'b1            ),
  .s_axi_arregion ( '0              ), // not use
  .s_axi_arqos    ( '0              ),
  .s_axi_arvalid  ( cpu_arvalid     ),
  .s_axi_arready  ( cpu_arready     ),

  .s_axi_rid      ( cpu_rid         ),
  .s_axi_rdata    ( cpu_rdata       ),
  .s_axi_rresp    ( cpu_rresp       ),
  .s_axi_rlast    ( cpu_rlast       ),
  .s_axi_rvalid   ( cpu_rvalid      ),
  .s_axi_rready   ( cpu_rready      ),
  // to size converter
  .m_axi_aclk     ( ddr_clock_out    ),
  .m_axi_aresetn  ( rst              ),
  .m_axi_awid     ( s_axi_awid       ),
  .m_axi_awaddr   ( s_axi_awaddr     ),
  .m_axi_awlen    ( s_axi_awlen      ),
  .m_axi_awsize   ( s_axi_awsize     ),
  .m_axi_awburst  ( s_axi_awburst    ),
  .m_axi_awlock   ( s_axi_awlock     ),
  .m_axi_awcache  ( s_axi_awcache    ),
  .m_axi_awprot   ( s_axi_awprot     ),
  .m_axi_awregion ( s_axi_awregion   ),
  .m_axi_awqos    ( s_axi_awqos      ),
  .m_axi_awvalid  ( s_axi_awvalid    ),
  .m_axi_awready  ( s_axi_awready    ),
  .m_axi_wdata    ( s_axi_wdata      ),
  .m_axi_wstrb    ( s_axi_wstrb      ),
  .m_axi_wlast    ( s_axi_wlast      ),
  .m_axi_wvalid   ( s_axi_wvalid     ),
  .m_axi_wready   ( s_axi_wready     ),
  .m_axi_bid      ( s_axi_bid        ),
  .m_axi_bresp    ( s_axi_bresp      ),
  .m_axi_bvalid   ( s_axi_bvalid     ),
  .m_axi_bready   ( s_axi_bready     ),
  .m_axi_arid     ( s_axi_arid       ),
  .m_axi_araddr   ( s_axi_araddr     ),
  .m_axi_arlen    ( s_axi_arlen      ),
  .m_axi_arsize   ( s_axi_arsize     ),
  .m_axi_arburst  ( s_axi_arburst    ),
  .m_axi_arlock   ( s_axi_arlock     ),
  .m_axi_arcache  ( s_axi_arcache    ),
  .m_axi_arprot   ( s_axi_arprot     ),
  .m_axi_arregion ( s_axi_arregion   ),
  .m_axi_arqos    ( s_axi_arqos      ),
  .m_axi_arvalid  ( s_axi_arvalid    ),
  .m_axi_arready  ( s_axi_arready    ),
  .m_axi_rid      ( s_axi_rid        ),
  .m_axi_rdata    ( s_axi_rdata      ),
  .m_axi_rresp    ( s_axi_rresp      ),
  .m_axi_rlast    ( s_axi_rlast      ),
  .m_axi_rvalid   ( s_axi_rvalid     ),
  .m_axi_rready   ( s_axi_rready     )
);

xlnx_mig_7_ddr3 i_ddr (
    .sys_clk_p,
    .sys_clk_n,
    .ddr3_dq,
    .ddr3_dqs_n,
    .ddr3_dqs_p,
    .ddr3_addr,
    .ddr3_ba,
    .ddr3_ras_n,
    .ddr3_cas_n,
    .ddr3_we_n,
    .ddr3_reset_n,
    .ddr3_ck_p,
    .ddr3_ck_n,
    .ddr3_cke,
    .ddr3_cs_n,
    .ddr3_dm,
    .ddr3_odt,
    .mmcm_locked     (                ), // keep open
    .app_sr_req      ( '0             ),
    .app_ref_req     ( '0             ),
    .app_zq_req      ( '0             ),
    .app_sr_active   (                ), // keep open
    .app_ref_ack     (                ), // keep open
    .app_zq_ack      (                ), // keep open
    .ui_clk          ( ddr_clock_out  ),
    .ui_clk_sync_rst ( ddr_sync_reset ),
    .aresetn         ( rst            ),
    .s_axi_awid,
    .s_axi_awaddr    ( s_axi_awaddr[29:0] ),
    .s_axi_awlen,
    .s_axi_awsize,
    .s_axi_awburst,
    .s_axi_awlock,
    .s_axi_awcache,
    .s_axi_awprot,
    .s_axi_awqos,
    .s_axi_awvalid,
    .s_axi_awready,
    .s_axi_wdata,
    .s_axi_wstrb,
    .s_axi_wlast,
    .s_axi_wvalid,
    .s_axi_wready,
    .s_axi_bready,
    .s_axi_bid,
    .s_axi_bresp,
    .s_axi_bvalid,
    .s_axi_arid,
    .s_axi_araddr     ( s_axi_araddr[29:0] ),
    .s_axi_arlen,
    .s_axi_arsize,
    .s_axi_arburst,
    .s_axi_arlock,
    .s_axi_arcache,
    .s_axi_arprot,
    .s_axi_arqos,
    .s_axi_arvalid,
    .s_axi_arready,
    .s_axi_rready,
    .s_axi_rid,
    .s_axi_rdata,
    .s_axi_rresp,
    .s_axi_rlast,
    .s_axi_rvalid,
    .init_calib_complete (            ), // keep open
    .device_temp         (            ), // keep open
    .sys_rst             ( ~cpu_reset )
);

// synopsys translate_off
// synopsys translate_on


endmodule : cpu_genesys2_top
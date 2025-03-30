// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_main_mem.v
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

module sy_main_mem
  import sy_pkg::*;
# (
        parameter HART_NUM = 2,
        parameter HART_ID_WTH = 1,
        parameter HART_ID_LSB = 1
) (
  input  logic                            clk_i,
  input  logic                            rst_i,
`ifdef PLATFORM_XILINX
  output logic                            ddr_clock_out,
  output logic                            fan_pwm,   
  input  logic                            sys_clk_p   ,
  input  logic                            sys_clk_n   ,
  input  logic                            cpu_resetn  ,
  inout  wire  [63:0]                     ddr3_dq     ,
  inout  wire  [ 7:0]                     ddr3_dqs_n  ,
  inout  wire  [ 7:0]                     ddr3_dqs_p  ,
  output logic [13:0]                     ddr3_addr   ,
  output logic [ 2:0]                     ddr3_ba     ,
  output logic                            ddr3_ras_n  ,
  output logic                            ddr3_cas_n  ,
  output logic                            ddr3_we_n   ,
  output logic                            ddr3_reset_n,
  output logic [ 0:0]                     ddr3_ck_p   ,
  output logic [ 0:0]                     ddr3_ck_n   ,
  output logic [ 0:0]                     ddr3_cke    ,
  output logic [ 0:0]                     ddr3_cs_n   ,
  output logic [ 7:0]                     ddr3_dm     ,
  output logic [ 0:0]                     ddr3_odt    ,
  output logic                            ddr_sync_reset,       
`endif 
  TL_BUS.Master                           master
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                                 inp_A_valid;
    logic                                 inp_A_ready;
    tl_pkg::A_chan_bits_t                 inp_A_bits;
    logic                                 inp_B_valid;
    logic                                 inp_B_ready;
    tl_pkg::B_chan_bits_t                 inp_B_bits;
    logic                                 inp_C_valid;
    logic                                 inp_C_ready;
    tl_pkg::C_chan_bits_t                 inp_C_bits;
    logic                                 inp_D_valid;
    logic                                 inp_D_ready;
    tl_pkg::D_chan_bits_t                 inp_D_bits;
    logic                                 inp_E_valid;
    logic                                 inp_E_ready;
    tl_pkg::E_chan_bits_t                 inp_E_bits;

    logic                                 oup_A_valid;
    logic                                 oup_A_ready;
    tl_pkg::A_chan_bits_t                 oup_A_bits;
    logic                                 oup_D_valid;
    logic                                 oup_D_ready;
    tl_pkg::D_chan_bits_t                 oup_D_bits;

    logic                                 axi_aw_valid;
    logic                                 axi_aw_ready;         
    axi_pkg::aw_chan_t                    axi_aw_bits;
    logic                                 axi_ar_valid;
    logic                                 axi_ar_ready;         
    axi_pkg::ar_chan_t                    axi_ar_bits;
    logic                                 axi_w_valid;
    logic                                 axi_w_ready;         
    axi_pkg::w_chan_t                     axi_w_bits;
    logic                                 axi_r_valid;
    logic                                 axi_r_ready;
    axi_pkg::r_chan_t                     axi_r_bits; 
    logic                                 axi_b_valid;
    logic                                 axi_b_ready;
    axi_pkg::b_chan_t                     axi_b_bits;
  `ifdef  PLATFORM_XILINX 
    localparam AxiAddrWidth = 64;
    localparam AxiDataWidth = 64;
    localparam AxiIdWidthMaster = 4;
    localparam AxiIdWidthSlaves = 5; // 5
    localparam AxiUserWidth = 1;

    logic [AxiIdWidthSlaves-1:0]          s_axi_awid;
    logic [AxiAddrWidth-1:0]              s_axi_awaddr;
    logic [7:0]                           s_axi_awlen;
    logic [2:0]                           s_axi_awsize;
    logic [1:0]                           s_axi_awburst;
    logic [0:0]                           s_axi_awlock;
    logic [3:0]                           s_axi_awcache;
    logic [2:0]                           s_axi_awprot;
    logic [3:0]                           s_axi_awregion;
    logic [3:0]                           s_axi_awqos;
    logic                                 s_axi_awvalid;
    logic                                 s_axi_awready;
    logic [AxiDataWidth-1:0]              s_axi_wdata;
    logic [AxiDataWidth/8-1:0]            s_axi_wstrb;
    logic                                 s_axi_wlast;
    logic                                 s_axi_wvalid;
    logic                                 s_axi_wready;
    logic [AxiIdWidthSlaves-1:0]          s_axi_bid;
    logic [1:0]                           s_axi_bresp;
    logic                                 s_axi_bvalid;
    logic                                 s_axi_bready;
    logic [AxiIdWidthSlaves-1:0]          s_axi_arid;
    logic [AxiAddrWidth-1:0]              s_axi_araddr;
    logic [7:0]                           s_axi_arlen;
    logic [2:0]                           s_axi_arsize;
    logic [1:0]                           s_axi_arburst;
    logic [0:0]                           s_axi_arlock;
    logic [3:0]                           s_axi_arcache;
    logic [2:0]                           s_axi_arprot;
    logic [3:0]                           s_axi_arregion;
    logic [3:0]                           s_axi_arqos;
    logic                                 s_axi_arvalid;
    logic                                 s_axi_arready;
    logic [AxiIdWidthSlaves-1:0]          s_axi_rid;
    logic [AxiDataWidth-1:0]              s_axi_rdata;
    logic [1:0]                           s_axi_rresp;
    logic                                 s_axi_rlast;
    logic                                 s_axi_rvalid;
    logic                                 s_axi_rready;
  `endif 

//======================================================================================================================
// Instance
//======================================================================================================================
  tl_slave_connect trans(
        .slave                (master),
        .A_valid_o            (inp_A_valid),            
        .A_ready_i            (inp_A_ready),            
        .A_bits_o             (inp_A_bits ),           
        .B_valid_i            (inp_B_valid),            
        .B_ready_o            (inp_B_ready),            
        .B_bits_i             (inp_B_bits ),           
        .C_valid_o            (inp_C_valid),            
        .C_ready_i            (inp_C_ready),            
        .C_bits_o             (inp_C_bits ),           
        .D_valid_i            (inp_D_valid),            
        .D_ready_o            (inp_D_ready),            
        .D_bits_i             (inp_D_bits ),                      
        .E_valid_o            (inp_E_valid),            
        .E_ready_i            (inp_E_ready),            
        .E_bits_o             (inp_E_bits )         
  );

  tl_probe_ctrl #(
    .HART_NUM              (HART_NUM),
    .HART_ID_WTH           (HART_ID_WTH),
    .HART_ID_LSB           (HART_ID_LSB),
    .SINK_LSB              (1),
    .SINK_ID               (0),
    .SINK_ID_WTH           (1),
    .ADDR_WTH              (64)
  ) probe_ctrl_inst (
        .clk_i                       (clk_i),
        .rst_i                       (rst_i),
        .inp_A_valid_i               (inp_A_valid),       
        .inp_A_ready_o               (inp_A_ready),       
        .inp_A_bits_i                (inp_A_bits ),      
        .inp_B_valid_o               (inp_B_valid),       
        .inp_B_ready_i               (inp_B_ready),       
        .inp_B_bits_o                (inp_B_bits ),      
        .inp_C_valid_i               (inp_C_valid),       
        .inp_C_ready_o               (inp_C_ready),       
        .inp_C_bits_i                (inp_C_bits ),      
        .inp_D_valid_o               (inp_D_valid),       
        .inp_D_ready_i               (inp_D_ready),       
        .inp_D_bits_o                (inp_D_bits ),                 
        .inp_E_valid_i               (inp_E_valid),       
        .inp_E_ready_o               (inp_E_ready),       
        .inp_E_bits_i                (inp_E_bits ),      
  
        .oup_A_valid_o               (oup_A_valid),       
        .oup_A_ready_i               (oup_A_ready),       
        .oup_A_bits_o                (oup_A_bits ),      
        .oup_D_valid_i               (oup_D_valid),       
        .oup_D_ready_o               (oup_D_ready),       
        .oup_D_bits_i                (oup_D_bits )
  );

  TL2AXI4 #(
      .AXI_ID (0)
  ) tl2axi_inst(
        .clk_i                        (clk_i), 
        .rst_i                        (rst_i),         
        .TL_A_valid_i                 (oup_A_valid),                 
        .TL_A_ready_o                 (oup_A_ready),                 
        .TL_A_bits_i                  (oup_A_bits ),               
        .TL_D_valid_o                 (oup_D_valid),                 
        .TL_D_ready_i                 (oup_D_ready),                 
        .TL_D_bits_o                  (oup_D_bits ),               

        .AXI_AW_valid_o               (axi_aw_valid),                  
        .AXI_AW_ready_i               (axi_aw_ready),                           
        .AXI_AW_bits_o                (axi_aw_bits ),                 
        .AXI_AR_valid_o               (axi_ar_valid),                  
        .AXI_AR_ready_i               (axi_ar_ready),                           
        .AXI_AR_bits_o                (axi_ar_bits ),                 
        .AXI_W_valid_o                (axi_w_valid ),                 
        .AXI_W_ready_i                (axi_w_ready ),                          
        .AXI_W_bits_o                 (axi_w_bits  ),                
        .AXI_R_valid_i                (axi_r_valid ),                 
        .AXI_R_ready_o                (axi_r_ready ),                 
        .AXI_R_bits_i                 (axi_r_bits  ),                 
        .AXI_B_valid_i                (axi_b_valid ),                 
        .AXI_B_ready_o                (axi_b_ready ),                 
        .AXI_B_bits_i                 (axi_b_bits  )                 
  );
  //======================================================================================================================
  // DDR
  //======================================================================================================================
    xlnx_axi_clock_converter i_xlnx_axi_clock_converter_ddr (
      .s_axi_aclk     ( clk_i            ),
      .s_axi_aresetn  ( rst_i            ),
      // address write
      .s_axi_awid     ( axi_aw_bits.id       ),
      .s_axi_awaddr   ( axi_aw_bits.addr     ),
      .s_axi_awlen    ( axi_aw_bits.len      ),
      .s_axi_awsize   ( axi_aw_bits.size     ),
      .s_axi_awburst  ( axi_aw_bits.burst    ),
      .s_axi_awlock   ( axi_aw_bits.lock     ),
      .s_axi_awcache  ( axi_aw_bits.cache    ),
      .s_axi_awprot   ( axi_aw_bits.prot     ),
      .s_axi_awregion ( '0),  // not use
      .s_axi_awqos    ( axi_aw_bits.qos      ),
      .s_axi_awvalid  ( axi_aw_valid         ),
      .s_axi_awready  ( axi_aw_ready         ),

      .s_axi_wdata    ( axi_w_bits.data      ),
      .s_axi_wstrb    ( axi_w_bits.strb      ),
      .s_axi_wlast    ( axi_w_bits.last      ),
      .s_axi_wvalid   ( axi_w_valid     ),
      .s_axi_wready   ( axi_w_ready     ),

      .s_axi_bid      ( axi_b_bits.id        ),
      .s_axi_bresp    ( axi_b_bits.resp      ),
      .s_axi_bvalid   ( axi_b_valid     ),
      .s_axi_bready   ( axi_b_ready     ),

      .s_axi_arid     ( axi_ar_bits.id       ),
      .s_axi_araddr   ( axi_ar_bits.addr     ),
      .s_axi_arlen    ( axi_ar_bits.len      ),
      .s_axi_arsize   ( axi_ar_bits.size     ),
      .s_axi_arburst  ( axi_ar_bits.burst    ),
      .s_axi_arlock   ( axi_ar_bits.lock     ),
      .s_axi_arcache  ( axi_ar_bits.cache    ),
      .s_axi_arprot   ( axi_ar_bits.prot     ),
      .s_axi_arregion ( '0), // not use
      .s_axi_arqos    ( axi_ar_bits.qos      ),
      .s_axi_arvalid  ( axi_ar_valid    ),
      .s_axi_arready  ( axi_ar_ready    ),

      .s_axi_rid      ( axi_r_bits.id        ),
      .s_axi_rdata    ( axi_r_bits.data      ),
      .s_axi_rresp    ( axi_r_bits.resp      ),
      .s_axi_rlast    ( axi_r_bits.last      ),
      .s_axi_rvalid   ( axi_r_valid     ),
      .s_axi_rready   ( axi_r_ready     ),
      // to size converter
      .m_axi_aclk     ( ddr_clock_out    ),
      .m_axi_aresetn  ( rst_i            ),
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

    fan_ctrl i_fan_ctrl (
        .clk_i         ( clk_i      ),
        .rst_ni        ( rst_i      ),
        .pwm_setting_i ( '1         ),
        .fan_pwm_o     ( fan_pwm    )
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
        .aresetn         ( rst_i          ),
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
        .sys_rst             ( cpu_resetn )
    );
endmodule
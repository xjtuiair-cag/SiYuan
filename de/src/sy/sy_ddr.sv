// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ddr.v
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

module sy_ddr
  import sy_pkg::*;
# (
    parameter PORT_NUM = 2
) (
  input  logic                            clk_i,
  input  logic                            rst_i,
`ifdef PLATFORM_XILINX
  output logic                            ddr_clock_out,
  output logic                            fan_pwm,   
  input  logic                            sys_clk_p   ,
  input  logic                            sys_clk_n   ,
  input  logic                            cpu_resetn  ,
  `ifdef VC707
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
  `elsif GENESYS2
    inout  wire  [31:0]                     ddr3_dq     ,
    inout  wire  [ 3:0]                     ddr3_dqs_n  ,
    inout  wire  [ 3:0]                     ddr3_dqs_p  ,
    output logic [14:0]                     ddr3_addr   ,
    output logic [ 2:0]                     ddr3_ba     ,
    output logic                            ddr3_ras_n  ,
    output logic                            ddr3_cas_n  ,
    output logic                            ddr3_we_n   ,
    output logic                            ddr3_reset_n,
    output logic [ 0:0]                     ddr3_ck_p   ,
    output logic [ 0:0]                     ddr3_ck_n   ,
    output logic [ 0:0]                     ddr3_cke    ,
    output logic [ 0:0]                     ddr3_cs_n   ,
    output logic [ 3:0]                     ddr3_dm     ,
    output logic [ 0:0]                     ddr3_odt    ,
    output logic                            ddr_sync_reset,       
  `endif 
`endif 
  // AXI4 in 
  input   logic             [PORT_NUM-1:0]  inp_axi_aw_valid_i,
  output  logic             [PORT_NUM-1:0]  inp_axi_aw_ready_o,         
  input   axi_pkg::aw_chan_t[PORT_NUM-1:0]  inp_axi_aw_bits_i,
  input   logic             [PORT_NUM-1:0]  inp_axi_ar_valid_i,
  output  logic             [PORT_NUM-1:0]  inp_axi_ar_ready_o,         
  input   axi_pkg::ar_chan_t[PORT_NUM-1:0]  inp_axi_ar_bits_i,
  input   logic             [PORT_NUM-1:0]  inp_axi_w_valid_i,
  output  logic             [PORT_NUM-1:0]  inp_axi_w_ready_o,         
  input   axi_pkg::w_chan_t [PORT_NUM-1:0]  inp_axi_w_bits_i,
  output  logic             [PORT_NUM-1:0]  inp_axi_r_valid_o,
  input   logic             [PORT_NUM-1:0]  inp_axi_r_ready_i,
  output  axi_pkg::r_chan_t [PORT_NUM-1:0]  inp_axi_r_bits_o, 
  output  logic             [PORT_NUM-1:0]  inp_axi_b_valid_o,
  input   logic             [PORT_NUM-1:0]  inp_axi_b_ready_i,
  output  axi_pkg::b_chan_t [PORT_NUM-1:0]  inp_axi_b_bits_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
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
    sy_axi4_arbiter #(
        .PORT_NUM (PORT_NUM)
    ) u_sy_axi4_arbiter (
        .clk_i                            (clk_i),   
        .rst_i                            (rst_i),   

        .inp_axi_aw_valid_i               (inp_axi_aw_valid_i),                
        .inp_axi_aw_ready_o               (inp_axi_aw_ready_o),                         
        .inp_axi_aw_bits_i                (inp_axi_aw_bits_i ),               
        .inp_axi_ar_valid_i               (inp_axi_ar_valid_i),                
        .inp_axi_ar_ready_o               (inp_axi_ar_ready_o),                         
        .inp_axi_ar_bits_i                (inp_axi_ar_bits_i ),               
        .inp_axi_w_valid_i                (inp_axi_w_valid_i ),               
        .inp_axi_w_ready_o                (inp_axi_w_ready_o ),                        
        .inp_axi_w_bits_i                 (inp_axi_w_bits_i  ),              
        .inp_axi_r_valid_o                (inp_axi_r_valid_o ),               
        .inp_axi_r_ready_i                (inp_axi_r_ready_i ),               
        .inp_axi_r_bits_o                 (inp_axi_r_bits_o  ),               
        .inp_axi_b_valid_o                (inp_axi_b_valid_o ),               
        .inp_axi_b_ready_i                (inp_axi_b_ready_i ),               
        .inp_axi_b_bits_o                 (inp_axi_b_bits_o  ),              

        .oup_axi_aw_valid_o               (axi_aw_valid),                
        .oup_axi_aw_ready_i               (axi_aw_ready),                         
        .oup_axi_aw_bits_o                (axi_aw_bits),               
        .oup_axi_ar_valid_o               (axi_ar_valid),                
        .oup_axi_ar_ready_i               (axi_ar_ready),                         
        .oup_axi_ar_bits_o                (axi_ar_bits),               
        .oup_axi_w_valid_o                (axi_w_valid),               
        .oup_axi_w_ready_i                (axi_w_ready),                        
        .oup_axi_w_bits_o                 (axi_w_bits ),              
        .oup_axi_r_valid_i                (axi_r_valid),               
        .oup_axi_r_ready_o                (axi_r_ready),               
        .oup_axi_r_bits_i                 (axi_r_bits ),               
        .oup_axi_b_valid_i                (axi_b_valid),               
        .oup_axi_b_ready_o                (axi_b_ready),            
        .oup_axi_b_bits_i                 (axi_b_bits )               
    );
//======================================================================================================================
// DDR
//======================================================================================================================
`ifdef PLATFORM_XILINX
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
`elsif PLATFORM_SIM
    axi_mem_sim # (
      .ADDR_WTH  (64),
      .DATA_WTH  (64),
      .MEM_SIZE  (64*1024*1024)
    ) ddr_sim(
        .clk_i                (clk_i),          
        .rst_i                (rst_i),          

        .awaddr               (axi_aw_bits.addr),           
        .awburst              (axi_aw_bits.burst),            
        .awcache              (axi_aw_bits.cache),            
        .awlen                (axi_aw_bits.len),          
        .awid                 (axi_aw_bits.id),         
        .awlock               (axi_aw_bits.lock),           
        .awprot               (axi_aw_bits.prot),           
        .awqos                (axi_aw_bits.qos),          
        .awregion             ('0),
        .awsize               (axi_aw_bits.size),           
        .awvalid              (axi_aw_valid),            
        .awready              (axi_aw_ready),            

        .wdata                (axi_w_bits.data),          
        .wlast                (axi_w_bits.last),          
        .wstrb                (axi_w_bits.strb),          
        .wvalid               (axi_w_valid),           
        .wready               (axi_w_ready),           

        .bresp                (axi_b_bits.resp),          
        .bid                  (axi_b_bits.id),            
        .bvalid               (axi_b_valid),           
        .bready               (axi_b_ready),           

        .araddr               (axi_ar_bits.addr  ),           
        .arburst              (axi_ar_bits.burst ),            
        .arcache              (axi_ar_bits.cache ),            
        .arlen                (axi_ar_bits.len   ),          
        .arid                 (axi_ar_bits.id    ),         
        .arlock               (axi_ar_bits.lock  ),           
        .arprot               (axi_ar_bits.prot  ),           
        .arqos                (axi_ar_bits.qos   ),          
        .arsize               (axi_ar_bits.size   ),           
        .arregion             ('0),             
        .arready              (axi_ar_ready),            
        .arvalid              (axi_ar_valid),            

        .rdata                (axi_r_bits.data),          
        .rlast                (axi_r_bits.last),          
        .rready               (axi_r_ready),           
        .rresp                (axi_r_bits.resp),          
        .rid                  (axi_r_bits.id),        
        .rvalid               (axi_r_valid)
    );
`endif 

endmodule
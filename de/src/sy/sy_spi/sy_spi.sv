// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_spi.v
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

module sy_spi
    import sy_pkg::*;
(
  input  logic                            clk_i,
  input  logic                            rst_i,

  output logic                            irq_o,

  output logic                            spi_clk_o ,
  output logic                            spi_mosi  ,
  input  logic                            spi_miso  ,
  output logic                            spi_ss    ,

  TL_BUS.Master                           master
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic [31:0] s_axi_spi_awaddr;
    logic [0:0]  s_axi_spi_awuser;
    logic [3:0]  s_axi_spi_awid;
    logic [7:0]  s_axi_spi_awlen;
    logic [2:0]  s_axi_spi_awsize;
    logic [1:0]  s_axi_spi_awburst;
    logic [0:0]  s_axi_spi_awlock;
    logic [3:0]  s_axi_spi_awcache;
    logic [2:0]  s_axi_spi_awprot;
    logic [3:0]  s_axi_spi_awregion;
    logic [3:0]  s_axi_spi_awqos;
    logic        s_axi_spi_awvalid;
    logic        s_axi_spi_awready;
    logic [31:0] s_axi_spi_wdata;
    logic [3:0]  s_axi_spi_wstrb;
    logic        s_axi_spi_wlast;
    logic        s_axi_spi_wvalid;
    logic        s_axi_spi_wready;
    logic [0:0]  s_axi_spi_wuser;
    logic [1:0]  s_axi_spi_bresp;
    logic        s_axi_spi_bvalid;
    logic        s_axi_spi_bready;
    logic [3:0]  s_axi_spi_bid;
    logic [0:0]  s_axi_spi_buser;
    logic [31:0] s_axi_spi_araddr;
    logic [7:0]  s_axi_spi_arlen;
    logic [2:0]  s_axi_spi_arsize;
    logic [1:0]  s_axi_spi_arburst;
    logic [0:0]  s_axi_spi_arlock;
    logic [3:0]  s_axi_spi_arcache;
    logic [2:0]  s_axi_spi_arprot;
    logic [3:0]  s_axi_spi_arregion;
    logic [3:0]  s_axi_spi_arqos;
    logic        s_axi_spi_arvalid;
    logic        s_axi_spi_arready;
    logic [0:0]  s_axi_spi_aruser;
    logic [3:0]  s_axi_spi_arid;

    logic [31:0] s_axi_spi_rdata;
    logic [1:0]  s_axi_spi_rresp;
    logic        s_axi_spi_rlast;
    logic        s_axi_spi_rvalid;
    logic        s_axi_spi_rready;
    logic [3:0]  s_axi_spi_rid;
    logic [0:0]  s_axi_spi_ruser;


//======================================================================================================================
// Instance
//======================================================================================================================
    TL2AXI4_32 tl2axi32_inst
    (
        .clk_i                          (clk_i), 
        .rst_i                          (rst_i),         
        .TL_A_valid_i                   (master.a_valid),                 
        .TL_A_ready_o                   (master.a_ready),                 
        .TL_A_bits_i                    (master.a_bits),               
        .TL_D_valid_o                   (master.d_valid),                 
        .TL_D_ready_i                   (master.d_ready),                 
        .TL_D_bits_o                    (master.d_bits),               

        .AXI_AW_valid_o                 (s_axi_spi_awvalid),          
        .AXI_AW_ready_i                 (s_axi_spi_awready),                   
        .AXI_AW_len_o                   (s_axi_spi_awlen),                    
        .AXI_AW_addr_o                  (s_axi_spi_awaddr),                     
        .AXI_AW_user_o                  (s_axi_spi_awuser),                     
        .AXI_AW_id_o                    (s_axi_spi_awid),                   

        .AXI_AR_valid_o                 (s_axi_spi_arvalid),          
        .AXI_AR_ready_i                 (s_axi_spi_arready),                   
        .AXI_AR_len_o                   (s_axi_spi_arlen),                    
        .AXI_AR_addr_o                  (s_axi_spi_araddr),                     
        .AXI_AR_user_o                  (s_axi_spi_aruser),                     
        .AXI_AR_id_o                    (s_axi_spi_arid),            

        .AXI_W_valid_o                  (s_axi_spi_wvalid),         
        .AXI_W_ready_i                  (s_axi_spi_wready),                  
        .AXI_W_wdata_o                  (s_axi_spi_wdata),         
        .AXI_W_wstrb_o                  (s_axi_spi_wstrb),         
        .AXI_W_user_o                   (s_axi_spi_wuser),                    
        .AXI_W_last_o                   (s_axi_spi_wlast),                    

        .AXI_R_valid_i                  (s_axi_spi_rvalid),         
        .AXI_R_ready_o                  (s_axi_spi_rready),         
        .AXI_R_rdata_i                  (s_axi_spi_rdata),         
        .AXI_R_user_i                   (s_axi_spi_ruser),        
        .AXI_R_id_i                     (s_axi_spi_rid),      
        .AXI_R_resp_i                   (s_axi_spi_rresp),        
        .AXI_R_last_i                   (s_axi_spi_rlast),        

        .AXI_B_valid_i                  (s_axi_spi_bvalid),         
        .AXI_B_ready_o                  (s_axi_spi_bready),         
        .AXI_B_id_i                     (s_axi_spi_bid),      
        .AXI_B_resp_i                   (s_axi_spi_bresp),        
        .AXI_B_user_i                   (s_axi_spi_buser) 
    );


    // TODO : IRQ
    assign irq_o = 1'b0;
    axi_spi_master #(
        .AXI4_ADDRESS_WIDTH  (32),
        .AXI4_RDATA_WIDTH    (32),
        .AXI4_WDATA_WIDTH    (32),
        .AXI4_USER_WIDTH     (1),
        .AXI4_ID_WIDTH       (4),
        .BUFFER_DEPTH        (16)
    ) spi_controller(
        .s_axi_aclk                     (clk_i),           
        .s_axi_aresetn                  (rst_i),              

        .s_axi_awvalid                  (s_axi_spi_awvalid),              
        .s_axi_awid                     (s_axi_spi_awid),           
        .s_axi_awlen                    (s_axi_spi_awlen),            
        .s_axi_awaddr                   (s_axi_spi_awaddr),             
        .s_axi_awuser                   (s_axi_spi_awuser),             
        .s_axi_awready                  (s_axi_spi_awready),              

        .s_axi_wvalid                   (s_axi_spi_wvalid),             
        .s_axi_wdata                    (s_axi_spi_wdata ),            
        .s_axi_wstrb                    (s_axi_spi_wstrb ),            
        .s_axi_wlast                    (s_axi_spi_wlast ),            
        .s_axi_wuser                    (s_axi_spi_wuser ),            
        .s_axi_wready                   (s_axi_spi_wready),             

        .s_axi_bvalid                   (s_axi_spi_bvalid),             
        .s_axi_bid                      (s_axi_spi_bid   ),          
        .s_axi_bresp                    (s_axi_spi_bresp ),            
        .s_axi_buser                    (s_axi_spi_buser ),            
        .s_axi_bready                   (s_axi_spi_bready),             

        .s_axi_arvalid                  (s_axi_spi_arvalid),              
        .s_axi_arid                     (s_axi_spi_arid   ),           
        .s_axi_arlen                    (s_axi_spi_arlen  ),            
        .s_axi_araddr                   (s_axi_spi_araddr ),             
        .s_axi_aruser                   (s_axi_spi_aruser ),             
        .s_axi_arready                  (s_axi_spi_arready),              

        .s_axi_rvalid                   (s_axi_spi_rvalid),             
        .s_axi_rid                      (s_axi_spi_rid   ),          
        .s_axi_rdata                    (s_axi_spi_rdata ),            
        .s_axi_rresp                    (s_axi_spi_rresp ),            
        .s_axi_rlast                    (s_axi_spi_rlast ),            
        .s_axi_ruser                    (s_axi_spi_ruser ),            
        .s_axi_rready                   (s_axi_spi_rready),             

        .events_o                       (),      // TODO

        .spi_clk                        (spi_clk_o),        
        .spi_csn0                       (spi_ss),         
        .spi_csn1                       (),         
        .spi_csn2                       (),         
        .spi_csn3                       (),         
        .spi_mode                       (),         
        .spi_sdo0                       (spi_mosi),         
        .spi_sdo1                       (),         
        .spi_sdo2                       (),         
        .spi_sdo3                       (),         
        .spi_sdi0                       (),         
        .spi_sdi1                       (spi_miso),         
        .spi_sdi2                       (),         
        .spi_sdi3                       ()
    );

    // `ifdef PLATFORM_XILINX
    // xlnx_axi_dwidth_converter i_xlnx_axi_dwidth_converter_spi (
    //     .s_axi_aclk     ( clk_i              ),
    //     .s_axi_aresetn  ( rst_i              ),

    //     .s_axi_awid     ( axi_aw_bits.id          ),
    //     .s_axi_awaddr   ( axi_aw_bits.addr[31:0]  ),
    //     .s_axi_awlen    ( axi_aw_bits.len         ),
    //     .s_axi_awsize   ( axi_aw_bits.size        ),
    //     .s_axi_awburst  ( axi_aw_bits.burst       ),
    //     .s_axi_awlock   ( axi_aw_bits.lock        ),
    //     .s_axi_awcache  ( axi_aw_bits.cache       ),
    //     .s_axi_awprot   ( axi_aw_bits.prot        ),
    //     .s_axi_awregion ( '0),    // not use
    //     .s_axi_awqos    ( axi_aw_bits.qos         ),
    //     .s_axi_awvalid  ( axi_aw_valid       ),
    //     .s_axi_awready  ( axi_aw_ready       ),

    //     .s_axi_wdata    ( axi_w_bits.data         ),
    //     .s_axi_wstrb    ( axi_w_bits.strb         ),
    //     .s_axi_wlast    ( axi_w_bits.last         ),
    //     .s_axi_wvalid   ( axi_w_valid        ),
    //     .s_axi_wready   ( axi_w_ready        ),

    //     .s_axi_bid      ( axi_b_bits.id           ),
    //     .s_axi_bresp    ( axi_b_bits.resp         ),
    //     .s_axi_bvalid   ( axi_b_valid        ),
    //     .s_axi_bready   ( axi_b_ready        ),

    //     .s_axi_arid     ( axi_ar_bits.id          ),
    //     .s_axi_araddr   ( axi_ar_bits.addr[31:0]  ),
    //     .s_axi_arlen    ( axi_ar_bits.len         ),
    //     .s_axi_arsize   ( axi_ar_bits.size        ),
    //     .s_axi_arburst  ( axi_ar_bits.burst       ),
    //     .s_axi_arlock   ( axi_ar_bits.lock        ),
    //     .s_axi_arcache  ( axi_ar_bits.cache       ),
    //     .s_axi_arprot   ( axi_ar_bits.prot        ),
    //     .s_axi_arregion ( '0), // not use
    //     .s_axi_arqos    ( axi_ar_bits.qos         ),
    //     .s_axi_arvalid  ( axi_ar_valid       ),
    //     .s_axi_arready  ( axi_ar_ready       ),

    //     .s_axi_rid      ( axi_r_bits.id           ),
    //     .s_axi_rdata    ( axi_r_bits.data         ),
    //     .s_axi_rresp    ( axi_r_bits.resp         ),
    //     .s_axi_rlast    ( axi_r_bits.last         ),
    //     .s_axi_rvalid   ( axi_r_valid        ),
    //     .s_axi_rready   ( axi_r_ready        ),

    //     .m_axi_awaddr   ( s_axi_spi_awaddr   ),
    //     .m_axi_awlen    ( s_axi_spi_awlen    ),
    //     .m_axi_awsize   ( s_axi_spi_awsize   ),
    //     .m_axi_awburst  ( s_axi_spi_awburst  ),
    //     .m_axi_awlock   ( s_axi_spi_awlock   ),
    //     .m_axi_awcache  ( s_axi_spi_awcache  ),
    //     .m_axi_awprot   ( s_axi_spi_awprot   ),
    //     .m_axi_awregion ( s_axi_spi_awregion ),
    //     .m_axi_awqos    ( s_axi_spi_awqos    ),
    //     .m_axi_awvalid  ( s_axi_spi_awvalid  ),
    //     .m_axi_awready  ( s_axi_spi_awready  ),
    //     .m_axi_wdata    ( s_axi_spi_wdata    ),
    //     .m_axi_wstrb    ( s_axi_spi_wstrb    ),
    //     .m_axi_wlast    ( s_axi_spi_wlast    ),
    //     .m_axi_wvalid   ( s_axi_spi_wvalid   ),
    //     .m_axi_wready   ( s_axi_spi_wready   ),
    //     .m_axi_bresp    ( s_axi_spi_bresp    ),
    //     .m_axi_bvalid   ( s_axi_spi_bvalid   ),
    //     .m_axi_bready   ( s_axi_spi_bready   ),
    //     .m_axi_araddr   ( s_axi_spi_araddr   ),
    //     .m_axi_arlen    ( s_axi_spi_arlen    ),
    //     .m_axi_arsize   ( s_axi_spi_arsize   ),
    //     .m_axi_arburst  ( s_axi_spi_arburst  ),
    //     .m_axi_arlock   ( s_axi_spi_arlock   ),
    //     .m_axi_arcache  ( s_axi_spi_arcache  ),
    //     .m_axi_arprot   ( s_axi_spi_arprot   ),
    //     .m_axi_arregion ( s_axi_spi_arregion ),
    //     .m_axi_arqos    ( s_axi_spi_arqos    ),
    //     .m_axi_arvalid  ( s_axi_spi_arvalid  ),
    //     .m_axi_arready  ( s_axi_spi_arready  ),
    //     .m_axi_rdata    ( s_axi_spi_rdata    ),
    //     .m_axi_rresp    ( s_axi_spi_rresp    ),
    //     .m_axi_rlast    ( s_axi_spi_rlast    ),
    //     .m_axi_rvalid   ( s_axi_spi_rvalid   ),
    //     .m_axi_rready   ( s_axi_spi_rready   )
    // );

    // xlnx_axi_quad_spi i_xlnx_axi_quad_spi (
    //     .ext_spi_clk    ( clk_i                  ),
    //     .s_axi4_aclk    ( clk_i                  ),
    //     .s_axi4_aresetn ( rst_i                  ),
    //     .s_axi4_awaddr  ( s_axi_spi_awaddr[23:0] ),
    //     .s_axi4_awlen   ( s_axi_spi_awlen        ),
    //     .s_axi4_awsize  ( s_axi_spi_awsize       ),
    //     .s_axi4_awburst ( s_axi_spi_awburst      ),
    //     .s_axi4_awlock  ( s_axi_spi_awlock       ),
    //     .s_axi4_awcache ( s_axi_spi_awcache      ),
    //     .s_axi4_awprot  ( s_axi_spi_awprot       ),
    //     .s_axi4_awvalid ( s_axi_spi_awvalid      ),
    //     .s_axi4_awready ( s_axi_spi_awready      ),
    //     .s_axi4_wdata   ( s_axi_spi_wdata        ),
    //     .s_axi4_wstrb   ( s_axi_spi_wstrb        ),
    //     .s_axi4_wlast   ( s_axi_spi_wlast        ),
    //     .s_axi4_wvalid  ( s_axi_spi_wvalid       ),
    //     .s_axi4_wready  ( s_axi_spi_wready       ),
    //     .s_axi4_bresp   ( s_axi_spi_bresp        ),
    //     .s_axi4_bvalid  ( s_axi_spi_bvalid       ),
    //     .s_axi4_bready  ( s_axi_spi_bready       ),
    //     .s_axi4_araddr  ( s_axi_spi_araddr[23:0] ),
    //     .s_axi4_arlen   ( s_axi_spi_arlen        ),
    //     .s_axi4_arsize  ( s_axi_spi_arsize       ),
    //     .s_axi4_arburst ( s_axi_spi_arburst      ),
    //     .s_axi4_arlock  ( s_axi_spi_arlock       ),
    //     .s_axi4_arcache ( s_axi_spi_arcache      ),
    //     .s_axi4_arprot  ( s_axi_spi_arprot       ),
    //     .s_axi4_arvalid ( s_axi_spi_arvalid      ),
    //     .s_axi4_arready ( s_axi_spi_arready      ),
    //     .s_axi4_rdata   ( s_axi_spi_rdata        ),
    //     .s_axi4_rresp   ( s_axi_spi_rresp        ),
    //     .s_axi4_rlast   ( s_axi_spi_rlast        ),
    //     .s_axi4_rvalid  ( s_axi_spi_rvalid       ),
    //     .s_axi4_rready  ( s_axi_spi_rready       ),
    //     .io0_i          ( '0                     ),
    //     .io0_o          ( spi_mosi               ),
    //     .io0_t          (                        ),
    //     .io1_i          ( spi_miso               ),
    //     .io1_o          (                        ),
    //     .io1_t          (                        ),
    //     .ss_i           ( '0                     ),
    //     .ss_o           ( spi_ss                 ),
    //     .ss_t           (                        ),
    //     .sck_o          ( spi_clk_o              ),
    //     .sck_i          ( '0                     ),
    //     .sck_t          (                        ),
    //     .ip2intc_irpt   ( irq_o                  )
    // );
    // `endif 

endmodule
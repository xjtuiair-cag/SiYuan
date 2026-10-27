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
    input  logic                        clk_i,
    input  logic                        rst_i,

    output logic                        irq_o,

    output logic                        spi_clk_o ,
    output logic[3:0]                   spi_mosi  ,
    input  logic[3:0]                   spi_miso  ,
    output logic                        spi_ss    ,
    // used to read/write register
    // A Channel
    input  logic                        inp_tl_A_valid_i,
    output logic                        inp_tl_A_ready_o,
    input  tl_pkg::A_chan_bits_t        inp_tl_A_bits_i,
    // B Channel
    output logic                        inp_tl_B_valid_o,
    input  logic                        inp_tl_B_ready_i,
    output tl_pkg::B_chan_bits_t        inp_tl_B_bits_o,
    // C Channel
    input  logic                        inp_tl_C_valid_i,
    output logic                        inp_tl_C_ready_o,
    input  tl_pkg::C_chan_bits_t        inp_tl_C_bits_i,
    // D Channel
    output logic                        inp_tl_D_valid_o,
    input  logic                        inp_tl_D_ready_i,
    output tl_pkg::D_chan_bits_t        inp_tl_D_bits_o,
    // E Channel
    input  logic                        inp_tl_E_valid_i,
    output logic                        inp_tl_E_ready_o,
    input  tl_pkg::E_chan_bits_t        inp_tl_E_bits_i
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
    assign inp_tl_B_valid_o = 1'b0;
    assign inp_tl_B_bits_o  = tl_pkg::B_chan_bits_t'(0);
    assign inp_tl_E_ready_o = 1'b1;
    assign inp_tl_C_ready_o = 1'b1;
    TL2AXI4_32 tl2axi32_inst
    (
        .clk_i                          (clk_i), 
        .rst_i                          (rst_i),         
        .TL_A_valid_i                   (inp_tl_A_valid_i),                 
        .TL_A_ready_o                   (inp_tl_A_ready_o),                 
        .TL_A_bits_i                    (inp_tl_A_bits_i ),               
        .TL_D_valid_o                   (inp_tl_D_valid_o),                 
        .TL_D_ready_i                   (inp_tl_D_ready_i),                 
        .TL_D_bits_o                    (inp_tl_D_bits_o ),               

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
        .spi_sdo0                       (spi_mosi[0]),         
        .spi_sdo1                       (spi_mosi[1]),         
        .spi_sdo2                       (spi_mosi[2]),         
        .spi_sdo3                       (spi_mosi[3]),         
        .spi_sdi0                       (spi_miso[0]),         
        .spi_sdi1                       (spi_miso[1]),         
        .spi_sdi2                       (spi_miso[2]),         
        .spi_sdi3                       (spi_miso[3])
    );

endmodule
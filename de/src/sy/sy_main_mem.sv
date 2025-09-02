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
  // TileLink Interface
  TL_BUS.Master                           master,
  // AXI4 interface
  output  logic                             oup_axi_aw_valid_o,
  input   logic                             oup_axi_aw_ready_i,         
  output  axi_pkg::aw_chan_t                oup_axi_aw_bits_o,
  output  logic                             oup_axi_ar_valid_o,
  input   logic                             oup_axi_ar_ready_i,         
  output  axi_pkg::ar_chan_t                oup_axi_ar_bits_o,
  output  logic                             oup_axi_w_valid_o,
  input   logic                             oup_axi_w_ready_i,         
  output  axi_pkg::w_chan_t                 oup_axi_w_bits_o,
  input   logic                             oup_axi_r_valid_i,
  output  logic                             oup_axi_r_ready_o,
  input   axi_pkg::r_chan_t                 oup_axi_r_bits_i, 
  input   logic                             oup_axi_b_valid_i,
  output  logic                             oup_axi_b_ready_o,
  input   axi_pkg::b_chan_t                 oup_axi_b_bits_i
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

  sy_L2_cache L2_cache_inst (
    .clk_i                   (clk_i),        
    .rst_i                   (rst_i),        

    .TL_A_valid_i            (oup_A_valid),               
    .TL_A_ready_o            (oup_A_ready),               
    .TL_A_bits_i             (oup_A_bits ),              

    .TL_D_valid_o            (oup_D_valid),               
    .TL_D_ready_i            (oup_D_ready),               
    .TL_D_bits_o             (oup_D_bits ),              

    .AXI_AW_valid_o          (oup_axi_aw_valid_o),                 
    .AXI_AW_ready_i          (oup_axi_aw_ready_i),                          
    .AXI_AW_bits_o           (oup_axi_aw_bits_o ),                

    .AXI_AR_valid_o          (oup_axi_ar_valid_o),                 
    .AXI_AR_ready_i          (oup_axi_ar_ready_i),                          
    .AXI_AR_bits_o           (oup_axi_ar_bits_o ),                

    .AXI_W_valid_o           (oup_axi_w_valid_o),                
    .AXI_W_ready_i           (oup_axi_w_ready_i),                         
    .AXI_W_bits_o            (oup_axi_w_bits_o ),               

    .AXI_R_valid_i           (oup_axi_r_valid_i),                
    .AXI_R_ready_o           (oup_axi_r_ready_o),                
    .AXI_R_bits_i            (oup_axi_r_bits_i ),                

    .AXI_B_valid_i           (oup_axi_b_valid_i),                
    .AXI_B_ready_o           (oup_axi_b_ready_o),                
    .AXI_B_bits_i            (oup_axi_b_bits_i )
  ); 
  // TL2AXI4 #(
  //     .AXI_ID (0)
  // ) tl2axi_inst(
  //       .clk_i                        (clk_i), 
  //       .rst_i                        (rst_i),         
  //       .TL_A_valid_i                 (oup_A_valid),                 
  //       .TL_A_ready_o                 (oup_A_ready),                 
  //       .TL_A_bits_i                  (oup_A_bits ),               
  //       .TL_D_valid_o                 (oup_D_valid),                 
  //       .TL_D_ready_i                 (oup_D_ready),                 
  //       .TL_D_bits_o                  (oup_D_bits ),               

  //       .AXI_AW_valid_o               (oup_axi_aw_valid_o),                  
  //       .AXI_AW_ready_i               (oup_axi_aw_ready_i),                           
  //       .AXI_AW_bits_o                (oup_axi_aw_bits_o ),                 
  //       .AXI_AR_valid_o               (oup_axi_ar_valid_o),                  
  //       .AXI_AR_ready_i               (oup_axi_ar_ready_i),                           
  //       .AXI_AR_bits_o                (oup_axi_ar_bits_o ),                 
  //       .AXI_W_valid_o                (oup_axi_w_valid_o ),                 
  //       .AXI_W_ready_i                (oup_axi_w_ready_i ),                          
  //       .AXI_W_bits_o                 (oup_axi_w_bits_o  ),                
  //       .AXI_R_valid_i                (oup_axi_r_valid_i ),                 
  //       .AXI_R_ready_o                (oup_axi_r_ready_o ),                 
  //       .AXI_R_bits_i                 (oup_axi_r_bits_i  ),                 
  //       .AXI_B_valid_i                (oup_axi_b_valid_i ),                 
  //       .AXI_B_ready_o                (oup_axi_b_ready_o ),                 
  //       .AXI_B_bits_i                 (oup_axi_b_bits_i  )                 
  // );

endmodule
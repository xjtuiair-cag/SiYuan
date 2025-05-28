// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_npu_mem.v
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

module sy_npu_mem
  import sy_pkg::*;
(
    input   logic                           clk_i,
    input   logic                           rst_i,
    // AXI4 TO DDR 
    output  logic                           axi_aw_valid_o,
    input   logic                           axi_aw_ready_i,         
    output  axi_pkg::aw_chan_t              axi_aw_bits_o,
    output  logic                           axi_ar_valid_o,
    input   logic                           axi_ar_ready_i,         
    output  axi_pkg::ar_chan_t              axi_ar_bits_o,
    output  logic                           axi_w_valid_o,
    input   logic                           axi_w_ready_i,         
    output  axi_pkg::w_chan_t               axi_w_bits_o,
    input   logic                           axi_r_valid_i,
    output  logic                           axi_r_ready_o,
    input   axi_pkg::r_chan_t               axi_r_bits_i, 
    input   logic                           axi_b_valid_i,
    output  logic                           axi_b_ready_o,
    input   axi_pkg::b_chan_t               axi_b_bits_i,

    // From NPU BUS
    TL_BUS.Master                           master
);
  
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================

//======================================================================================================================
// Instance
//======================================================================================================================
    assign master.b_valid = 1'b0;

    TL2AXI4 #(
      .AXI_ID (0)
    ) tl2axi_inst(
          .clk_i                        (clk_i), 
          .rst_i                        (rst_i),         
          .TL_A_valid_i                 (master.a_valid),                 
          .TL_A_ready_o                 (master.a_ready),                 
          .TL_A_bits_i                  (master.a_bits),               
          .TL_D_valid_o                 (master.d_valid),                 
          .TL_D_ready_i                 (master.d_ready),                 
          .TL_D_bits_o                  (master.d_bits),               

          .AXI_AW_valid_o               (axi_aw_valid_o),                  
          .AXI_AW_ready_i               (axi_aw_ready_i),                           
          .AXI_AW_bits_o                (axi_aw_bits_o ),                 
          .AXI_AR_valid_o               (axi_ar_valid_o),                  
          .AXI_AR_ready_i               (axi_ar_ready_i),                           
          .AXI_AR_bits_o                (axi_ar_bits_o ),                 
          .AXI_W_valid_o                (axi_w_valid_o ),                 
          .AXI_W_ready_i                (axi_w_ready_i ),                          
          .AXI_W_bits_o                 (axi_w_bits_o  ),                
          .AXI_R_valid_i                (axi_r_valid_i ),                 
          .AXI_R_ready_o                (axi_r_ready_o ),                 
          .AXI_R_bits_i                 (axi_r_bits_i  ),                 
          .AXI_B_valid_i                (axi_b_valid_i ),                 
          .AXI_B_ready_o                (axi_b_ready_o ),                 
          .AXI_B_bits_i                 (axi_b_bits_i  )                 
    );
endmodule
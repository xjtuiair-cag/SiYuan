// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_L2_cache.v
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

module sy_L2_cache  
  import sy_pkg::*;
(
  input  logic                               clk_i,
  input  logic                               rst_i,
  // =====================================
  // [TileLink Interface between L2 cache and Probe Ctrl]
  input  logic                            TL_A_valid_i,
  output logic                            TL_A_ready_o,
  input  tl_pkg::A_chan_bits_t            TL_A_bits_i,

  output logic                            TL_D_valid_o,
  input  logic                            TL_D_ready_i,
  output tl_pkg::D_chan_bits_t            TL_D_bits_o,
  // =====================================
  // [AXI4 Interface between L2 cache and DDR]
  output logic                            AXI_AW_valid_o,
  input  logic                            AXI_AW_ready_i,         
  output axi_pkg::aw_chan_t               AXI_AW_bits_o,

  output logic                            AXI_AR_valid_o,
  input  logic                            AXI_AR_ready_i,         
  output axi_pkg::ar_chan_t               AXI_AR_bits_o,

  output logic                            AXI_W_valid_o,
  input  logic                            AXI_W_ready_i,         
  output axi_pkg::w_chan_t                AXI_W_bits_o,

  input  logic                            AXI_R_valid_i,
  output logic                            AXI_R_ready_o,
  input  axi_pkg::r_chan_t                AXI_R_bits_i, 

  input  logic                            AXI_B_valid_i,
  output logic                            AXI_B_ready_o,
  input  axi_pkg::b_chan_t                AXI_B_bits_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
  logic                            data_req;
  L2_data_req_t                    data_req_bits;
  L2_data_rsp_t                    data_rsp_bits;

  logic                            tag_req;
  L2_tag_req_t                     tag_req_bits;
  L2_tag_rsp_t                     tag_rsp_bits;
//======================================================================================================================
// Instance
//======================================================================================================================
sy_L2_cache_ctrl L2_cache_ctrl_inst(
    .clk_i              (clk_i),            
    .rst_i              (rst_i),            

    .TL_A_valid_i       (TL_A_valid_i),                   
    .TL_A_ready_o       (TL_A_ready_o),                   
    .TL_A_bits_i        (TL_A_bits_i ),                  
                         
    .TL_D_valid_o       (TL_D_valid_o),                   
    .TL_D_ready_i       (TL_D_ready_i),                   
    .TL_D_bits_o        (TL_D_bits_o ),                  

    .AXI_AW_valid_o     (AXI_AW_valid_o),                     
    .AXI_AW_ready_i     (AXI_AW_ready_i),                              
    .AXI_AW_bits_o      (AXI_AW_bits_o),                    
                         
    .AXI_AR_valid_o     (AXI_AR_valid_o),                     
    .AXI_AR_ready_i     (AXI_AR_ready_i),                              
    .AXI_AR_bits_o      (AXI_AR_bits_o),                    
                         
    .AXI_W_valid_o      (AXI_W_valid_o),                    
    .AXI_W_ready_i      (AXI_W_ready_i),                             
    .AXI_W_bits_o       (AXI_W_bits_o ),                   
                         
    .AXI_R_valid_i      (AXI_R_valid_i),                    
    .AXI_R_ready_o      (AXI_R_ready_o),                    
    .AXI_R_bits_i       (AXI_R_bits_i ),                    
                         
    .AXI_B_valid_i      (AXI_B_valid_i),                    
    .AXI_B_ready_o      (AXI_B_ready_o),                    
    .AXI_B_bits_i       (AXI_B_bits_i ),                   

    .data_req_o         (data_req     ),                 
    .data_req_bits_o    (data_req_bits),                      
    .data_rsp_bits_i    (data_rsp_bits),                      

    .tag_req_o          (tag_req     ),                
    .tag_req_bits_o     (tag_req_bits),                     
    .tag_rsp_bits_i     (tag_rsp_bits)
);

sy_L2_cache_mem L2_cache_mem_inst(
  .clk_i              (clk_i),
  .rst_i              (rst_i),

  .flush_i            (1'b0), // TODO              
  
  .tag_req_i          (tag_req     ),
  .tag_req_bits_i     (tag_req_bits),
  .tag_rsp_bits_o     (tag_rsp_bits),
  
  .data_req_i         (data_req     ),
  .data_req_bits_i    (data_req_bits),
  .data_rsp_bits_o    (data_rsp_bits)
);

endmodule
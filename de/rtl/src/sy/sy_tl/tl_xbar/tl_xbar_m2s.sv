// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_xbar_m2s.v
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
 
module tl_xbar_m2s
  import tl_pkg::*;
#(
    parameter int unsigned      ADDR_WIDTH     = 32,
    parameter                   REGION_NUM     = 2,
    parameter                   SLAVE_NUM      = 8,
    parameter                   SOURCE_LSB     = 4,
    parameter                   SOURCE_MSB     = 5,
    parameter                   SINK_LSB       = 2,
    parameter                   SINK_MSB       = 4 
) (
  input logic                                                           clk_i,
  input logic                                                           rst_i,
  // -----------------------------------------------------------------------------------//
  //                           INTERNAL (N_TARGET PORT )                                //
  // -----------------------------------------------------------------------------------//
  //TL A channel bus --------------------------------------------------------------//
  input  logic                                                          a_valid_i,  
  output logic                                                          a_ready_o,  
  input  logic [ADDR_WIDTH-1:0]                                         a_addr_i,    

  output logic [SLAVE_NUM-1:0]                                          a_valid_o,          
  input  logic [SLAVE_NUM-1:0]                                          a_ready_i,
  //TL C channel bus --------------------------------------------------------------//
  input  logic                                                          c_valid_i,  
  output logic                                                          c_ready_o,  
  input  logic [ADDR_WIDTH-1:0]                                         c_addr_i,    

  output logic [SLAVE_NUM-1:0]                                          c_valid_o,          
  input  logic [SLAVE_NUM-1:0]                                          c_ready_i,
  //TL E channel bus --------------------------------------------------------------//
  input  logic                                                          e_valid_i,  
  output logic                                                          e_ready_o,  
  input  E_chan_bits_t                                                  e_bits_i,    

  output logic [SLAVE_NUM-1:0]                                          e_valid_o,          
  input  logic [SLAVE_NUM-1:0]                                          e_ready_i,
  // ------------------------------------------------------------------------------------//
  //                           SLAVE SIDE (ONE PORT ONLY)                                //
  // ------------------------------------------------------------------------------------//
  //TL B channel bus --------------------------------------------------------------//
  input  logic [SLAVE_NUM-1:0]                                          b_valid_i,  
  output logic [SLAVE_NUM-1:0]                                          b_ready_o,  
  input  B_chan_bits_t [SLAVE_NUM-1:0]                                  b_bits_i,

  output logic                                                          b_valid_o, 
  input  logic                                                          b_ready_i,
  output B_chan_bits_t                                                  b_bits_o,
  //TL D channel bus --------------------------------------------------------------//
  input  logic [SLAVE_NUM-1:0]                                          d_valid_i,  
  output logic [SLAVE_NUM-1:0]                                          d_ready_o,  
  input  D_chan_bits_t [SLAVE_NUM-1:0]                                  d_bits_i,

  output logic                                                          d_valid_o, 
  input  logic                                                          d_ready_i,
  output D_chan_bits_t                                                  d_bits_o,

  // FROM CFG REGS
  input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0][ADDR_WIDTH-1:0]          start_addr_i,
  input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0][ADDR_WIDTH-1:0]          end_addr_i,
  input  logic [SLAVE_NUM-1:0][REGION_NUM-1:0]                          enable_region_i,
  input  logic [SLAVE_NUM-1:0]                                          connectivity_map_i
);

  // TL B channel 
  tl_arbiter_B #(
    .SLAVE_NUM     (SLAVE_NUM),
    .DATA_T        (B_chan_bits_t)
  ) B_arbiter(
    .clk_i                  (clk_i      ),         
    .rst_i                  (rst_i      ),         

    .inp_bits_i             (b_bits_i   ),               
    .inp_valid_i            (b_valid_i  ),               
    .inp_ready_o            (b_ready_o  ),               

    .oup_valid_o            (b_valid_o  ),               
    .oup_bits_o             (b_bits_o   ),              
    .oup_ready_i            (b_ready_i  )
  );

  // TL D channel 
  tl_arbiter_D #(
    .SLAVE_NUM     (SLAVE_NUM),
    .DATA_T        (D_chan_bits_t)
  ) D_aribter(
    .clk_i                  (clk_i      ),         
    .rst_i                  (rst_i      ),         

    .inp_bits_i             (d_bits_i   ),               
    .inp_valid_i            (d_valid_i  ),               
    .inp_ready_o            (d_ready_o  ),               

    .oup_valid_o            (d_valid_o  ),               
    .oup_bits_o             (d_bits_o   ),              
    .oup_ready_i            (d_ready_i  )
  );

  tl_addr_router_A #(
      .ADDR_WIDTH     (ADDR_WIDTH),
      .SLAVE_NUM      (SLAVE_NUM),
      .REGION_NUM     (REGION_NUM),
      .DATA_T         (A_chan_bits_t)
  ) A_router(
    .clk_i                    (clk_i),        
    .rst_i                    (rst_i),        
  
    .inp_valid_i              (a_valid_i),              
    .inp_ready_o              (a_ready_o),              
    .inp_addr_i               (a_addr_i),             
  
    .oup_valid_o              (a_valid_o),              
    .oup_ready_i              (a_ready_i),              
  
    .start_addr_i             (start_addr_i),               
    .end_addr_i               (end_addr_i),             
    .enable_region_i          (enable_region_i),                  
    .connectivity_map_i       (connectivity_map_i)
  );

  tl_addr_router_C #(
      .ADDR_WIDTH     (ADDR_WIDTH),
      .SLAVE_NUM      (SLAVE_NUM),
      .REGION_NUM     (REGION_NUM),
      .DATA_T         (C_chan_bits_t)
  ) C_router(
    .clk_i                    (clk_i),        
    .rst_i                    (rst_i),        
  
    .inp_valid_i              (c_valid_i),              
    .inp_ready_o              (c_ready_o),              
    .inp_addr_i               (c_addr_i),             
  
    .oup_valid_o              (c_valid_o),              
    .oup_ready_i              (c_ready_i),              
  
    .start_addr_i             (start_addr_i),               
    .end_addr_i               (end_addr_i),             
    .enable_region_i          (enable_region_i),                  
    .connectivity_map_i       (connectivity_map_i)
  );

  tl_addr_router_E #(
      .SLAVE_NUM      (SLAVE_NUM),
      .SINK_LSB       (SINK_LSB),
      .SINK_MSB       (SINK_MSB),
      .DATA_T         (E_chan_bits_t)
  ) E_router(
    .clk_i                    (clk_i),        
    .rst_i                    (rst_i),        
  
    .e_valid_i                (e_valid_i),              
    .e_ready_o                (e_ready_o),              
    .e_bits_i                 (e_bits_i),             
  
    .e_valid_o                (e_valid_o),              
    .e_ready_i                (e_ready_i)              
  );


endmodule
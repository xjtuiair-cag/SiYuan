// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_xbar_s2m.v
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


module tl_xbar_s2m
  import tl_pkg::*;
#(
    parameter                   MASTER_NUM     = 0,
    parameter                   SOURCE_LSB     = 0,
    parameter                   SOURCE_MSB     = 0,
    parameter                   SINK_LSB       = 0,
    parameter                   SINK_MSB       = 0
) (
  input logic                                                           clk_i,
  input logic                                                           rst_i,
  // -----------------------------------------------------------------------------------//
  //                           INTERNAL (N_TARGET PORT )                                //
  // -----------------------------------------------------------------------------------//
  //TL A channel bus --------------------------------------------------------------//
  input  logic [MASTER_NUM-1:0]                                        a_valid_i,  
  output logic [MASTER_NUM-1:0]                                        a_ready_o,  
  input  A_chan_bits_t [MASTER_NUM-1:0]                                a_bits_i,    

  output logic                                                         a_valid_o,
  input  logic                                                         a_ready_i,      
  output A_chan_bits_t                                                 a_bits_o,
  //TL C channel bus --------------------------------------------------------------//
  input  logic [MASTER_NUM-1:0]                                        c_valid_i,  
  output logic [MASTER_NUM-1:0]                                        c_ready_o,  
  input  C_chan_bits_t [MASTER_NUM-1:0]                                c_bits_i,    

  output logic                                                         c_valid_o,
  input  logic                                                         c_ready_i,      
  output C_chan_bits_t                                                 c_bits_o,
  //TL E channel bus --------------------------------------------------------------//
  input  logic [MASTER_NUM-1:0]                                        e_valid_i,  
  output logic [MASTER_NUM-1:0]                                        e_ready_o,  
  input  E_chan_bits_t [MASTER_NUM-1:0]                                e_bits_i,    

  output logic                                                         e_valid_o,
  input  logic                                                         e_ready_i,      
  output E_chan_bits_t                                                 e_bits_o,
  // ------------------------------------------------------------------------------------//
  //                           SLAVE SIDE (ONE PORT ONLY)                                //
  // ------------------------------------------------------------------------------------//
  //TL B channel bus --------------------------------------------------------------//
  input  logic                                                         b_valid_i,  
  output logic                                                         b_ready_o,  
  input  source_t                                                      b_source_i,

  output logic [MASTER_NUM-1:0]                                        b_valid_o, 
  input  logic [MASTER_NUM-1:0]                                        b_ready_i,
  //TL D channel bus --------------------------------------------------------------//
  input  logic                                                         d_valid_i,  
  output logic                                                         d_ready_o,  
  input  source_t                                                      d_source_i,

  output logic [MASTER_NUM-1:0]                                        d_valid_o, 
  input  logic [MASTER_NUM-1:0]                                        d_ready_i
);

  // TL A channel 
  tl_arbiter_A #(
    .MASTER_NUM     (MASTER_NUM),
    .DATA_T         (A_chan_bits_t)
  ) A_arbiter(
    .clk_i                  (clk_i      ),         
    .rst_i                  (rst_i      ),         

    .inp_bits_i             (a_bits_i   ),               
    .inp_valid_i            (a_valid_i  ),               
    .inp_ready_o            (a_ready_o  ),               

    .oup_valid_o            (a_valid_o  ),               
    .oup_bits_o             (a_bits_o   ),              
    .oup_ready_i            (a_ready_i  )
  );

  // TL C channel 
  tl_arbiter_C #(
    .MASTER_NUM   (MASTER_NUM),
    .DATA_T        (C_chan_bits_t)
  ) C_aribter(
    .clk_i                  (clk_i      ),         
    .rst_i                  (rst_i      ),         

    .inp_bits_i             (c_bits_i   ),               
    .inp_valid_i            (c_valid_i  ),               
    .inp_ready_o            (c_ready_o  ),               

    .oup_valid_o            (c_valid_o  ),               
    .oup_bits_o             (c_bits_o   ),              
    .oup_ready_i            (c_ready_i  )
  );


  tl_addr_router_B #(
     .MASTER_NUM       (MASTER_NUM),
     .SOURCE_LSB       (SOURCE_LSB),
     .SOURCE_MSB       (SOURCE_MSB)
  ) B_router (
      .inp_valid_i          (b_valid_i  ),       
      .inp_ready_o          (b_ready_o  ),       
      .inp_source_i         (b_source_i ),      

      .oup_valid_o          (b_valid_o  ),       
      .oup_ready_i          (b_ready_i  )       
  );

  tl_addr_router_D #(
     .MASTER_NUM       (MASTER_NUM),
     .SOURCE_LSB       (SOURCE_LSB),
     .SOURCE_MSB       (SOURCE_MSB)
  ) D_router (
      .inp_valid_i          (d_valid_i  ),       
      .inp_ready_o          (d_ready_o  ),       
      .inp_source_i         (d_source_i ),      

      .oup_valid_o          (d_valid_o  ),       
      .oup_ready_i          (d_ready_i  )       
  );

  // for E channel
  tl_arbiter #(
    .DATA_T     (E_chan_bits_t),
    .N_MASTER   (MASTER_NUM)
  ) E_arbiter (
    .clk_i        (clk_i),
    .rst_i        (rst_i),

    .inp_data_i   (e_bits_i),
    .inp_valid_i  (e_valid_i),
    .inp_ready_o  (e_ready_o),

    .oup_data_o   (e_bits_o),
    .oup_valid_o  (e_valid_o),
    .oup_ready_i  (e_ready_i)
  );


endmodule
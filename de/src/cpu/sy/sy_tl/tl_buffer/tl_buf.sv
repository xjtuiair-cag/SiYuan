// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_buf.v
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

module tl_buf 
  import tl_pkg::*;
(
    input logic                         clk_i  ,
    input logic                         rst_i  ,
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
    input  tl_pkg::E_chan_bits_t        inp_tl_E_bits_i,
    // A Channel
    output logic                        oup_tl_A_valid_o,
    input  logic                        oup_tl_A_ready_i,
    output tl_pkg::A_chan_bits_t        oup_tl_A_bits_o,
    // B Channel
    input  logic                        oup_tl_B_valid_i,
    output logic                        oup_tl_B_ready_o,
    input  tl_pkg::B_chan_bits_t        oup_tl_B_bits_i,
    // C Channel
    output logic                        oup_tl_C_valid_o,
    input  logic                        oup_tl_C_ready_i,
    output tl_pkg::C_chan_bits_t        oup_tl_C_bits_o,
    // D Channel
    input  logic                        oup_tl_D_valid_i,
    output logic                        oup_tl_D_ready_o,
    input  tl_pkg::D_chan_bits_t        oup_tl_D_bits_i,
    // E Channel
    output logic                        oup_tl_E_valid_o,
    input  logic                        oup_tl_E_ready_i,
    output tl_pkg::E_chan_bits_t        oup_tl_E_bits_o
);

  spill_register #(.T(A_chan_bits_t)) i_reg_a (
    .clk_i   ( clk_i        ),
    .rst_ni  ( rst_i        ),
    .valid_i ( inp_tl_A_valid_i ),
    .ready_o ( inp_tl_A_ready_o ),
    .data_i  ( inp_tl_A_bits_i  ),
    .valid_o ( oup_tl_A_valid_o ),
    .ready_i ( oup_tl_A_ready_i ),
    .data_o  ( oup_tl_A_bits_o  )
  );

  spill_register #(.T(B_chan_bits_t)) i_reg_b (
    .clk_i   ( clk_i        ),
    .rst_ni  ( rst_i        ),
    .valid_i ( oup_tl_B_valid_i),
    .ready_o ( oup_tl_B_ready_o),
    .data_i  ( oup_tl_B_bits_i ),
    .valid_o ( inp_tl_B_valid_o),
    .ready_i ( inp_tl_B_ready_i),
    .data_o  ( inp_tl_B_bits_o )
  );

  spill_register #(.T(C_chan_bits_t)) i_reg_c (
    .clk_i   ( clk_i        ),
    .rst_ni  ( rst_i        ),
    .valid_i ( inp_tl_C_valid_i ),
    .ready_o ( inp_tl_C_ready_o ),
    .data_i  ( inp_tl_C_bits_i  ),
    .valid_o ( oup_tl_C_valid_o ),
    .ready_i ( oup_tl_C_ready_i ),
    .data_o  ( oup_tl_C_bits_o  )
  );

  spill_register #(.T(D_chan_bits_t)) i_reg_d (
    .clk_i   ( clk_i        ),
    .rst_ni  ( rst_i        ),
    .valid_i ( oup_tl_D_valid_i),
    .ready_o ( oup_tl_D_ready_o),
    .data_i  ( oup_tl_D_bits_i ),
    .valid_o ( inp_tl_D_valid_o),
    .ready_i ( inp_tl_D_ready_i),
    .data_o  ( inp_tl_D_bits_o )
  );

  spill_register #(.T(E_chan_bits_t)) i_reg_e (
    .clk_i   ( clk_i        ),
    .rst_ni  ( rst_i        ),
    .valid_i ( inp_tl_E_valid_i),
    .ready_o ( inp_tl_E_ready_o),
    .data_i  ( inp_tl_E_bits_i ),
    .valid_o ( oup_tl_E_valid_o),
    .ready_i ( oup_tl_E_ready_i),
    .data_o  ( oup_tl_E_bits_o )
  );

endmodule
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

// mostly come from cva6 :https://github.com/openhwgroup/cva6 

module tl_buf 
  import tl_pkg::*;
(
  input logic       clk_i  ,
  input logic       rst_i  ,
  TL_BUS.Master     in     ,
  TL_BUS.Slave      out
);

  A_chan_bits_t a_in, a_out;
  assign a_in = in.a_bits;
  assign out.a_bits = a_out;
  spill_register #(.T(A_chan_bits_t)) i_reg_a (
    .clk_i   ( clk_i        ),
    .rst_ni  ( rst_i        ),
    .valid_i ( in.a_valid   ),
    .ready_o ( in.a_ready   ),
    .data_i  ( a_in         ),
    .valid_o ( out.a_valid  ),
    .ready_i ( out.a_ready  ),
    .data_o  ( a_out        )
  );

  B_chan_bits_t b_in, b_out;
  assign b_in = out.b_bits;
  assign in.b_bits = b_out;
  spill_register #(.T(B_chan_bits_t)) i_reg_b (
    .clk_i   ( clk_i        ),
    .rst_ni  ( rst_i        ),
    .valid_i ( out.b_valid  ),
    .ready_o ( out.b_ready  ),
    .data_i  ( b_in         ),
    .valid_o ( in.b_valid   ),
    .ready_i ( in.b_ready   ),
    .data_o  ( b_out        )
  );

  C_chan_bits_t c_in, c_out;
  assign c_in = in.c_bits;
  assign out.c_bits = c_out;
  spill_register #(.T(C_chan_bits_t)) i_reg_c (
    .clk_i   ( clk_i        ),
    .rst_ni  ( rst_i        ),
    .valid_i ( in.c_valid   ),
    .ready_o ( in.c_ready   ),
    .data_i  ( c_in         ),
    .valid_o ( out.c_valid  ),
    .ready_i ( out.c_ready  ),
    .data_o  ( c_out        )
  );

  D_chan_bits_t d_in, d_out;
  assign d_in = out.d_bits;
  assign in.d_bits = d_out;
  spill_register #(.T(D_chan_bits_t)) i_reg_d (
    .clk_i   ( clk_i        ),
    .rst_ni  ( rst_i        ),
    .valid_i ( out.d_valid  ),
    .ready_o ( out.d_ready  ),
    .data_i  ( d_in         ),
    .valid_o ( in.d_valid   ),
    .ready_i ( in.d_ready   ),
    .data_o  ( d_out        )
  );

  E_chan_bits_t e_in, e_out;
  assign e_in = in.e_bits;
  assign out.e_bits = e_out;
  spill_register #(.T(E_chan_bits_t)) i_reg_e (
    .clk_i   ( clk_i        ),
    .rst_ni  ( rst_i        ),
    .valid_i ( in.e_valid   ),
    .ready_o ( in.e_ready   ),
    .data_i  ( e_in         ),
    .valid_o ( out.e_valid  ),
    .ready_i ( out.e_ready  ),
    .data_o  ( e_out        )
  );

endmodule
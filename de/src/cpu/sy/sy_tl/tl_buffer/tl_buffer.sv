// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_buffer.v
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

module tl_buffer
  import tl_pkg::*;
#(
  parameter int BUF_DEPTH   = 0
)(
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

  if (BUF_DEPTH == 0) begin : no_buf
    tl_identity i_identity(
      .inp_tl_A_valid_i         (inp_tl_A_valid_i), 
      .inp_tl_A_ready_o         (inp_tl_A_ready_o), 
      .inp_tl_A_bits_i          (inp_tl_A_bits_i ),
      .inp_tl_B_valid_o         (inp_tl_B_valid_o), 
      .inp_tl_B_ready_i         (inp_tl_B_ready_i), 
      .inp_tl_B_bits_o          (inp_tl_B_bits_o ),
      .inp_tl_C_valid_i         (inp_tl_C_valid_i), 
      .inp_tl_C_ready_o         (inp_tl_C_ready_o), 
      .inp_tl_C_bits_i          (inp_tl_C_bits_i ),
      .inp_tl_D_valid_o         (inp_tl_D_valid_o), 
      .inp_tl_D_ready_i         (inp_tl_D_ready_i), 
      .inp_tl_D_bits_o          (inp_tl_D_bits_o ),
      .inp_tl_E_valid_i         (inp_tl_E_valid_i), 
      .inp_tl_E_ready_o         (inp_tl_E_ready_o), 
      .inp_tl_E_bits_i          (inp_tl_E_bits_i ),
      .oup_tl_A_valid_o         (oup_tl_A_valid_o), 
      .oup_tl_A_ready_i         (oup_tl_A_ready_i), 
      .oup_tl_A_bits_o          (oup_tl_A_bits_o ),
      .oup_tl_B_valid_i         (oup_tl_B_valid_i), 
      .oup_tl_B_ready_o         (oup_tl_B_ready_o), 
      .oup_tl_B_bits_i          (oup_tl_B_bits_i ),
      .oup_tl_C_valid_o         (oup_tl_C_valid_o), 
      .oup_tl_C_ready_i         (oup_tl_C_ready_i), 
      .oup_tl_C_bits_o          (oup_tl_C_bits_o ),
      .oup_tl_D_valid_i         (oup_tl_D_valid_i), 
      .oup_tl_D_ready_o         (oup_tl_D_ready_o), 
      .oup_tl_D_bits_i          (oup_tl_D_bits_i ),
      .oup_tl_E_valid_o         (oup_tl_E_valid_o), 
      .oup_tl_E_ready_i         (oup_tl_E_ready_i), 
      .oup_tl_E_bits_o          (oup_tl_E_bits_o )
    );
  end

  // Handle the special case of one cut.
  else if (BUF_DEPTH == 1) begin : only_buf_1
    tl_buf i_buf (
      .clk_i                    ( clk_i  ),
      .rst_i                    ( rst_i  ),
      .inp_tl_A_valid_i         (inp_tl_A_valid_i), 
      .inp_tl_A_ready_o         (inp_tl_A_ready_o), 
      .inp_tl_A_bits_i          (inp_tl_A_bits_i ),
      .inp_tl_B_valid_o         (inp_tl_B_valid_o), 
      .inp_tl_B_ready_i         (inp_tl_B_ready_i), 
      .inp_tl_B_bits_o          (inp_tl_B_bits_o ),
      .inp_tl_C_valid_i         (inp_tl_C_valid_i), 
      .inp_tl_C_ready_o         (inp_tl_C_ready_o), 
      .inp_tl_C_bits_i          (inp_tl_C_bits_i ),
      .inp_tl_D_valid_o         (inp_tl_D_valid_o), 
      .inp_tl_D_ready_i         (inp_tl_D_ready_i), 
      .inp_tl_D_bits_o          (inp_tl_D_bits_o ),
      .inp_tl_E_valid_i         (inp_tl_E_valid_i), 
      .inp_tl_E_ready_o         (inp_tl_E_ready_o), 
      .inp_tl_E_bits_i          (inp_tl_E_bits_i ),
      .oup_tl_A_valid_o         (oup_tl_A_valid_o), 
      .oup_tl_A_ready_i         (oup_tl_A_ready_i), 
      .oup_tl_A_bits_o          (oup_tl_A_bits_o ),
      .oup_tl_B_valid_i         (oup_tl_B_valid_i), 
      .oup_tl_B_ready_o         (oup_tl_B_ready_o), 
      .oup_tl_B_bits_i          (oup_tl_B_bits_i ),
      .oup_tl_C_valid_o         (oup_tl_C_valid_o), 
      .oup_tl_C_ready_i         (oup_tl_C_ready_i), 
      .oup_tl_C_bits_o          (oup_tl_C_bits_o ),
      .oup_tl_D_valid_i         (oup_tl_D_valid_i), 
      .oup_tl_D_ready_o         (oup_tl_D_ready_o), 
      .oup_tl_D_bits_i          (oup_tl_D_bits_i ),
      .oup_tl_E_valid_o         (oup_tl_E_valid_o), 
      .oup_tl_E_ready_i         (oup_tl_E_ready_i), 
      .oup_tl_E_bits_o          (oup_tl_E_bits_o )
    );
  end

  // Handle the cases of two or more cuts.
  else begin : buffer
    // A Channel
    logic                        tl_A_valid[BUF_DEPTH-1:0];
    logic                        tl_A_ready[BUF_DEPTH-1:0];
    tl_pkg::A_chan_bits_t        tl_A_bits [BUF_DEPTH-1:0];
    // B Channel
    logic                        tl_B_valid[BUF_DEPTH-1:0];
    logic                        tl_B_ready[BUF_DEPTH-1:0];
    tl_pkg::B_chan_bits_t        tl_B_bits [BUF_DEPTH-1:0];
    // C Channel
    logic                        tl_C_valid[BUF_DEPTH-1:0];
    logic                        tl_C_ready[BUF_DEPTH-1:0];
    tl_pkg::C_chan_bits_t        tl_C_bits [BUF_DEPTH-1:0];
    // D Channel
    logic                        tl_D_valid[BUF_DEPTH-1:0];
    logic                        tl_D_ready[BUF_DEPTH-1:0];
    tl_pkg::D_chan_bits_t        tl_D_bits [BUF_DEPTH-1:0];
    // E Channel
    logic                        tl_E_valid[BUF_DEPTH-1:0];
    logic                        tl_E_ready[BUF_DEPTH-1:0];
    tl_pkg::E_chan_bits_t        tl_E_bits [BUF_DEPTH-1:0];


    tl_buf i_first (
      .clk_i                    ( clk_i  ),
      .rst_i                    ( rst_i  ),
      .inp_tl_A_valid_i         (inp_tl_A_valid_i), 
      .inp_tl_A_ready_o         (inp_tl_A_ready_o), 
      .inp_tl_A_bits_i          (inp_tl_A_bits_i ),
      .inp_tl_B_valid_o         (inp_tl_B_valid_o), 
      .inp_tl_B_ready_i         (inp_tl_B_ready_i), 
      .inp_tl_B_bits_o          (inp_tl_B_bits_o ),
      .inp_tl_C_valid_i         (inp_tl_C_valid_i), 
      .inp_tl_C_ready_o         (inp_tl_C_ready_o), 
      .inp_tl_C_bits_i          (inp_tl_C_bits_i ),
      .inp_tl_D_valid_o         (inp_tl_D_valid_o), 
      .inp_tl_D_ready_i         (inp_tl_D_ready_i), 
      .inp_tl_D_bits_o          (inp_tl_D_bits_o ),
      .inp_tl_E_valid_i         (inp_tl_E_valid_i), 
      .inp_tl_E_ready_o         (inp_tl_E_ready_o), 
      .inp_tl_E_bits_i          (inp_tl_E_bits_i ),
      .oup_tl_A_valid_o         (tl_A_valid[0]), 
      .oup_tl_A_ready_i         (tl_A_ready[0]), 
      .oup_tl_A_bits_o          (tl_A_bits [0]),
      .oup_tl_B_valid_i         (tl_B_valid[0]), 
      .oup_tl_B_ready_o         (tl_B_ready[0]), 
      .oup_tl_B_bits_i          (tl_B_bits [0]),
      .oup_tl_C_valid_o         (tl_C_valid[0]), 
      .oup_tl_C_ready_i         (tl_C_ready[0]), 
      .oup_tl_C_bits_o          (tl_C_bits [0]),
      .oup_tl_D_valid_i         (tl_D_valid[0]), 
      .oup_tl_D_ready_o         (tl_D_ready[0]), 
      .oup_tl_D_bits_i          (tl_D_bits [0]),
      .oup_tl_E_valid_o         (tl_E_valid[0]), 
      .oup_tl_E_ready_i         (tl_E_ready[0]), 
      .oup_tl_E_bits_o          (tl_E_bits [0])

    );

    for (genvar i = 1; i < BUF_DEPTH-1; i++) begin
      tl_buf i_middle (
        .inp_tl_A_valid_i         (tl_A_valid[i-1]), 
        .inp_tl_A_ready_o         (tl_A_ready[i-1]), 
        .inp_tl_A_bits_i          (tl_A_bits [i-1]),
        .inp_tl_B_valid_o         (tl_B_valid[i-1]), 
        .inp_tl_B_ready_i         (tl_B_ready[i-1]), 
        .inp_tl_B_bits_o          (tl_B_bits [i-1]),
        .inp_tl_C_valid_i         (tl_C_valid[i-1]), 
        .inp_tl_C_ready_o         (tl_C_ready[i-1]), 
        .inp_tl_C_bits_i          (tl_C_bits [i-1]),
        .inp_tl_D_valid_o         (tl_D_valid[i-1]), 
        .inp_tl_D_ready_i         (tl_D_ready[i-1]), 
        .inp_tl_D_bits_o          (tl_D_bits [i-1]),
        .inp_tl_E_valid_i         (tl_E_valid[i-1]), 
        .inp_tl_E_ready_o         (tl_E_ready[i-1]), 
        .inp_tl_E_bits_i          (tl_E_bits [i-1]),
        .oup_tl_A_valid_o         (tl_A_valid[i]), 
        .oup_tl_A_ready_i         (tl_A_ready[i]), 
        .oup_tl_A_bits_o          (tl_A_bits [i]),
        .oup_tl_B_valid_i         (tl_B_valid[i]), 
        .oup_tl_B_ready_o         (tl_B_ready[i]), 
        .oup_tl_B_bits_i          (tl_B_bits [i]),
        .oup_tl_C_valid_o         (tl_C_valid[i]), 
        .oup_tl_C_ready_i         (tl_C_ready[i]), 
        .oup_tl_C_bits_o          (tl_C_bits [i]),
        .oup_tl_D_valid_i         (tl_D_valid[i]), 
        .oup_tl_D_ready_o         (tl_D_ready[i]), 
        .oup_tl_D_bits_i          (tl_D_bits [i]),
        .oup_tl_E_valid_o         (tl_E_valid[i]), 
        .oup_tl_E_ready_i         (tl_E_ready[i]), 
        .oup_tl_E_bits_o          (tl_E_bits [i])
      );
    end

    tl_buf i_last (
      .inp_tl_A_valid_i         (tl_A_valid[BUF_DEPTH-2]), 
      .inp_tl_A_ready_o         (tl_A_ready[BUF_DEPTH-2]), 
      .inp_tl_A_bits_i          (tl_A_bits [BUF_DEPTH-2]),
      .inp_tl_B_valid_o         (tl_B_valid[BUF_DEPTH-2]), 
      .inp_tl_B_ready_i         (tl_B_ready[BUF_DEPTH-2]), 
      .inp_tl_B_bits_o          (tl_B_bits [BUF_DEPTH-2]),
      .inp_tl_C_valid_i         (tl_C_valid[BUF_DEPTH-2]), 
      .inp_tl_C_ready_o         (tl_C_ready[BUF_DEPTH-2]), 
      .inp_tl_C_bits_i          (tl_C_bits [BUF_DEPTH-2]),
      .inp_tl_D_valid_o         (tl_D_valid[BUF_DEPTH-2]), 
      .inp_tl_D_ready_i         (tl_D_ready[BUF_DEPTH-2]), 
      .inp_tl_D_bits_o          (tl_D_bits [BUF_DEPTH-2]),
      .inp_tl_E_valid_i         (tl_E_valid[BUF_DEPTH-2]), 
      .inp_tl_E_ready_o         (tl_E_ready[BUF_DEPTH-2]), 
      .inp_tl_E_bits_i          (tl_E_bits [BUF_DEPTH-2]),
      .oup_tl_A_valid_o         (oup_tl_A_valid_o), 
      .oup_tl_A_ready_i         (oup_tl_A_ready_i), 
      .oup_tl_A_bits_o          (oup_tl_A_bits_o ),
      .oup_tl_B_valid_i         (oup_tl_B_valid_i), 
      .oup_tl_B_ready_o         (oup_tl_B_ready_o), 
      .oup_tl_B_bits_i          (oup_tl_B_bits_i ),
      .oup_tl_C_valid_o         (oup_tl_C_valid_o), 
      .oup_tl_C_ready_i         (oup_tl_C_ready_i), 
      .oup_tl_C_bits_o          (oup_tl_C_bits_o ),
      .oup_tl_D_valid_i         (oup_tl_D_valid_i), 
      .oup_tl_D_ready_o         (oup_tl_D_ready_o), 
      .oup_tl_D_bits_i          (oup_tl_D_bits_i ),
      .oup_tl_E_valid_o         (oup_tl_E_valid_o), 
      .oup_tl_E_ready_i         (oup_tl_E_ready_i), 
      .oup_tl_E_bits_o          (oup_tl_E_bits_o )
    );
  end

endmodule
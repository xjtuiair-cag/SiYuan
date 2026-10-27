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

module tl_identity(
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
    
    assign oup_tl_A_valid_o  = inp_tl_A_valid_i;
    assign oup_tl_C_valid_o  = inp_tl_C_valid_i;
    assign oup_tl_E_valid_o  = inp_tl_E_valid_i;
    assign oup_tl_A_bits_o   = inp_tl_A_bits_i;
    assign oup_tl_C_bits_o   = inp_tl_C_bits_i;
    assign oup_tl_E_bits_o   = inp_tl_E_bits_i;

    assign oup_tl_B_ready_o  = inp_tl_B_ready_i;
    assign oup_tl_D_ready_o  = inp_tl_D_ready_i;

    assign inp_tl_A_ready_o   = oup_tl_A_ready_i;
    assign inp_tl_C_ready_o   = oup_tl_C_ready_i;
    assign inp_tl_E_ready_o   = oup_tl_E_ready_i;
    assign inp_tl_B_valid_o   = oup_tl_B_valid_i;
    assign inp_tl_B_bits_o    = oup_tl_B_bits_i;
    assign inp_tl_D_valid_o   = oup_tl_D_valid_i;
    assign inp_tl_D_bits_o    = oup_tl_D_bits_i;

endmodule

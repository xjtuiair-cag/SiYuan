// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : TL_C2A.v
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

module TL_C2A(
    // input 
    input  logic                            inp_tl_A_valid_i,
    output logic                            inp_tl_A_ready_o,
    input  tl_pkg::A_chan_bits_t            inp_tl_A_bits_i,
    output logic                            inp_tl_B_valid_o,
    input  logic                            inp_tl_B_ready_i,
    output tl_pkg::B_chan_bits_t            inp_tl_B_bits_o,
    input  logic                            inp_tl_C_valid_i,
    output logic                            inp_tl_C_ready_o,
    input  tl_pkg::C_chan_bits_t            inp_tl_C_bits_i,
    output logic                            inp_tl_D_valid_o,
    input  logic                            inp_tl_D_ready_i,
    output tl_pkg::D_chan_bits_t            inp_tl_D_bits_o,
    input  logic                            inp_tl_E_valid_i,
    output logic                            inp_tl_E_ready_o,
    input  tl_pkg::E_chan_bits_t            inp_tl_E_bits_i,
    // output 
    output logic                            oup_tl_A_valid_o,
    input  logic                            oup_tl_A_ready_i,
    output tl_pkg::A_chan_bits_t            oup_tl_A_bits_o,
    input  logic                            oup_tl_B_valid_i,
    output logic                            oup_tl_B_ready_o,
    input  tl_pkg::B_chan_bits_t            oup_tl_B_bits_i,
    output logic                            oup_tl_C_valid_o,
    input  logic                            oup_tl_C_ready_i,
    output tl_pkg::C_chan_bits_t            oup_tl_C_bits_o,
    input  logic                            oup_tl_D_valid_i,
    output logic                            oup_tl_D_ready_o,
    input  tl_pkg::D_chan_bits_t            oup_tl_D_bits_i,
    output logic                            oup_tl_E_valid_o,
    input  logic                            oup_tl_E_ready_i,
    output tl_pkg::E_chan_bits_t            oup_tl_E_bits_o
);
    // don't change B/D/E channel
    assign inp_tl_B_valid_o = oup_tl_B_valid_i;
    assign inp_tl_B_bits_o = oup_tl_B_bits_i;
    assign oup_tl_B_ready_o = inp_tl_B_ready_i;

    assign oup_tl_E_valid_o = inp_tl_E_valid_i;
    assign oup_tl_E_bits_o = inp_tl_E_bits_i;
    assign inp_tl_E_ready_o = oup_tl_E_ready_i;

    assign inp_tl_D_valid_o = oup_tl_D_valid_i;
    assign oup_tl_D_ready_o = inp_tl_D_ready_i;
    assign inp_tl_D_bits_o  = oup_tl_D_bits_i;

    // if c channle is valid, trans it to A channel
    // if a channel is valid, pass it to A channel
    assign oup_tl_A_valid_o = inp_tl_A_valid_i || inp_tl_C_valid_i;
    assign inp_tl_C_ready_o = oup_tl_A_ready_i && !inp_tl_A_valid_i;
    assign inp_tl_A_ready_o = oup_tl_A_ready_i;

    assign oup_tl_A_bits_o.opcode    = inp_tl_A_valid_i ? inp_tl_A_bits_i.opcode : inp_tl_C_bits_i.opcode;
    assign oup_tl_A_bits_o.param     = inp_tl_A_valid_i ? inp_tl_A_bits_i.param  : inp_tl_C_bits_i.param;
    assign oup_tl_A_bits_o.size      = inp_tl_A_valid_i ? inp_tl_A_bits_i.size   : inp_tl_C_bits_i.size;
    assign oup_tl_A_bits_o.source    = inp_tl_A_valid_i ? inp_tl_A_bits_i.source : inp_tl_C_bits_i.source;
    assign oup_tl_A_bits_o.address   = inp_tl_A_valid_i ? inp_tl_A_bits_i.address: inp_tl_C_bits_i.address;
    assign oup_tl_A_bits_o.data      = inp_tl_A_valid_i ? inp_tl_A_bits_i.data   : inp_tl_C_bits_i.data;
    assign oup_tl_A_bits_o.corrupt   = inp_tl_A_valid_i ? inp_tl_A_bits_i.corrupt: inp_tl_C_bits_i.corrupt;
    assign oup_tl_A_bits_o.mask      = inp_tl_A_valid_i ? inp_tl_A_bits_i.mask   : {tl_pkg::MASK_WTH{1'b1}};
endmodule
// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_slave_connect.v
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

module tl_slave_connect (
    TL_BUS.Master                            slave,
    // A channel
    output  logic                            A_valid_o,
    input   logic                            A_ready_i,
    output  tl_pkg::A_chan_bits_t            A_bits_o,
    // B channel
    input   logic                            B_valid_i,
    output  logic                            B_ready_o,
    input   tl_pkg::B_chan_bits_t            B_bits_i,
    // C channel
    output  logic                            C_valid_o,
    input   logic                            C_ready_i,
    output  tl_pkg::C_chan_bits_t            C_bits_o,
    // D channel
    input   logic                            D_valid_i,
    output  logic                            D_ready_o,
    input   tl_pkg::D_chan_bits_t            D_bits_i,           
    // E channel
    output  logic                            E_valid_o,
    input   logic                            E_ready_i,
    output  tl_pkg::E_chan_bits_t            E_bits_o
);

    assign                 slave.b_valid        = B_valid_i;
    assign                 slave.b_bits         = B_bits_i;
    assign B_ready_o     = slave.b_ready;

    assign                 slave.d_valid        = D_valid_i;
    assign                 slave.d_bits         = D_bits_i;
    assign D_ready_o     = slave.d_ready;

    assign A_valid_o     = slave.a_valid;
    assign A_bits_o      = slave.a_bits;
    assign                 slave.a_ready       = A_ready_i;

    assign C_valid_o     = slave.c_valid;
    assign C_bits_o      = slave.c_bits;
    assign                 slave.c_ready       = C_ready_i;

    assign E_valid_o     = slave.e_valid;
    assign E_bits_o      = slave.e_bits;
    assign                 slave.e_ready       = E_ready_i;


endmodule
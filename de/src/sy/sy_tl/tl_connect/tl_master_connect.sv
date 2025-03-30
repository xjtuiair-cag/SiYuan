// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_master_connect.v
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


module tl_master_connect (
    // A channel
    input  logic                            A_valid_i,
    output logic                            A_ready_o,
    input  tl_pkg::A_chan_bits_t            A_bits_i,
    // B channel
    output logic                            B_valid_o,
    input  logic                            B_ready_i,
    output tl_pkg::B_chan_bits_t            B_bits_o,
    // C channel
    input  logic                            C_valid_i,
    output logic                            C_ready_o,
    input  tl_pkg::C_chan_bits_t            C_bits_i,
    // D channel
    output logic                            D_valid_o,
    input  logic                            D_ready_i,
    output tl_pkg::D_chan_bits_t            D_bits_o,           
    // E channel
    input  logic                            E_valid_i,
    output logic                            E_ready_o,
    input  tl_pkg::E_chan_bits_t            E_bits_i,

    TL_BUS.Slave                            master
);

    assign                 master.a_valid       = A_valid_i;
    assign                 master.a_bits        = A_bits_i;
    assign A_ready_o     = master.a_ready;

    assign                 master.c_valid       = C_valid_i;
    assign                 master.c_bits        = C_bits_i;
    assign C_ready_o     = master.c_ready;

    assign                 master.e_valid       = E_valid_i;
    assign                 master.e_bits        = E_bits_i;
    assign E_ready_o     = master.e_ready;

    assign B_valid_o     = master.b_valid;
    assign B_bits_o      = master.b_bits;
    assign                 master.b_ready       = B_ready_i;

    assign D_valid_o     = master.d_valid;
    assign D_bits_o      = master.d_bits;
    assign                 master.d_ready       = D_ready_i;

endmodule
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
    TL_BUS.Master in,
    TL_BUS.Slave  out
);

    assign out.a_valid  = in.a_valid;
    assign out.c_valid  = in.c_valid;
    assign out.e_valid  = in.e_valid;
    assign out.a_bits   = in.a_bits;
    assign out.c_bits   = in.c_bits;
    assign out.e_bits   = in.e_bits;

    assign out.b_ready  = in.b_ready;
    assign out.d_ready  = in.d_ready;

    assign in.a_ready   = out.a_ready;
    assign in.c_ready   = out.c_ready;
    assign in.e_ready   = out.e_ready;
    assign in.b_valid   = out.b_valid;
    assign in.b_bits    = out.b_bits;
    assign in.d_valid   = out.d_valid;
    assign in.d_bits    = out.d_bits;

endmodule

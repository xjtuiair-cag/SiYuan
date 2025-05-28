// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_c_trans_a.v
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

module tl_c_trans_a(
    TL_BUS.Master                            in,

    TL_BUS.Slave                             out
);

    // if c channle is valid, trans it to A channel
    // if a channel is valid, pass it to A channel
    assign out.a_valid      = in.a_valid ? in.a_valid : in.c_valid;
    assign in.c_ready       = out.a_ready;
    assign in.a_ready       = out.a_ready;

    assign out.a_bits.opcode    = in.a_valid ? in.a_bits.opcode : in.c_bits.opcode;
    assign out.a_bits.param     = in.a_valid ? in.a_bits.param  : in.c_bits.param;
    assign out.a_bits.size      = in.a_valid ? in.a_bits.size   : in.c_bits.size;
    assign out.a_bits.source    = in.a_valid ? in.a_bits.source : in.c_bits.source;
    assign out.a_bits.address   = in.a_valid ? in.a_bits.address: in.c_bits.address;
    assign out.a_bits.data      = in.a_valid ? in.a_bits.data   : in.c_bits.data;
    assign out.a_bits.corrupt   = in.a_valid ? in.a_bits.corrupt: in.c_bits.corrupt;
    assign out.a_bits.mask      = in.a_valid ? in.a_bits.mask   : {tl_pkg::MASK_WTH{1'b1}};

    // Pass D channle
    assign in.d_valid           = out.d_valid;
    assign out.d_ready          = in.d_ready;
    assign in.d_bits            = out.d_bits;

endmodule
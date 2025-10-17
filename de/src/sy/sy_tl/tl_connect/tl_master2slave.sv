// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_master2slave.v
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

module tl_master2slave(
    TL_BUS.Slave                             slave,
    TL_BUS.Master                            master 
);

    assign                  master.b_valid        = slave.b_valid;
    assign                  master.b_bits         = slave.b_bits;
    assign slave.b_ready  = master.b_ready;

    assign                  master.d_valid        = slave.d_valid;
    assign                  master.d_bits         = slave.d_bits;
    assign slave.d_ready  = master.d_ready;

    assign slave.a_valid  = master.a_valid;
    assign slave.a_bits   = master.a_bits;
    assign                  master.a_ready       = slave.a_ready;

    assign slave.c_valid  = master.c_valid;
    assign slave.c_bits   = master.c_bits;
    assign                  master.c_ready       = slave.c_ready;

    assign slave.e_valid  = master.e_valid;
    assign slave.e_bits   = master.e_bits;
    assign                  master.e_ready       = slave.e_ready;

endmodule
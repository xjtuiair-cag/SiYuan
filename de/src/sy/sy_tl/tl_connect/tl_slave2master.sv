// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_slave2master.v
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

module tl_slave2master(
    TL_BUS.Master                            slave,
    TL_BUS.Slave                             master
);

    assign                  slave.b_valid        = master.b_valid;
    assign                  slave.b_bits         = master.b_bits;
    assign master.b_ready = slave.b_ready;

    assign                  slave.d_valid        = master.d_valid;
    assign                  slave.d_bits         = master.d_bits;
    assign master.d_ready = slave.d_ready;

    assign master.a_valid = slave.a_valid;
    assign master.a_bits  = slave.a_bits;
    assign                  slave.a_ready       = master.a_ready;

    assign master.c_valid = slave.c_valid;
    assign master.c_bits  = slave.c_bits;
    assign                  slave.c_ready       = master.c_ready;

    assign master.e_valid = slave.e_valid;
    assign master.e_bits  = slave.e_bits;
    assign                  slave.e_ready       = master.e_ready;

endmodule
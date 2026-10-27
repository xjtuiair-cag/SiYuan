// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sync_r2w.v
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

module sync_r2w
    import sy_pkg::*;
#(
    parameter ASIZE = 4
)(
    input  logic              wclk,
    input  logic              wrst,
    input  logic [ASIZE:0] rptr,
    output logic [ASIZE:0] wq2_rptr
);

    logic [ASIZE:0] wq1_rptr;

    always @(`DFF_CR(wclk,wrst)) begin
        if (`DFF_IS_R(wrst)) begin
            {wq2_rptr,wq1_rptr} <= 0;
        end else begin
            {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};
        end
    end

endmodule
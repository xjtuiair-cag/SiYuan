// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sync_w2r.v
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

module sync_w2r
    import sy_pkg::*;
#(
    parameter ASIZE = 4
)(
    input  logic           rclk,
    input  logic           rrst,
    output logic [ASIZE:0] rq2_wptr,
    input  logic [ASIZE:0] wptr
);

    logic [ASIZE:0] rq1_wptr;

    always @(`DFF_CR(rclk,rrst)) begin
        if (`DFF_IS_R(rrst)) begin
            {rq2_wptr,rq1_wptr} <= 0;
        end else begin
            {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};
        end
    end

endmodule
// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : byte_en_reg.v
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

module byte_en_reg 
    import sy_pkg::*;
#(
    parameter DATA_W = 32,
    parameter INIT_VAL = {DATA_W{1'b0}}
)(
    input   logic                   clk,
    input   logic                   rst,
    input   logic                   we,
    input   logic[(DATA_W-1)/8:0]   en,
    input   logic[DATA_W-1:0]       d,
    output  logic[DATA_W-1:0]       q
);

integer i;
always @(`DFF_CR(clk,rst)) begin
    if (`DFF_IS_R(rst))
        q <= INIT_VAL;
    else begin
        for (i = 0; i < DATA_W; i = i + 1) begin
            if (we && en[i/8]) begin
                q[i] <= d[i];
            end
        end
    end
end

endmodule

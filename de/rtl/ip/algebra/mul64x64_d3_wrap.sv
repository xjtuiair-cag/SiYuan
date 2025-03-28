// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : mul64x64_d3_wrap.v
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

module mul64x64_d3_wrap(
    input   logic                        clk_i,
    input   logic                        rst_ni,
    input   logic [63:0]                 a_i,
    input   logic                        sign_a_i,
    input   logic [63:0]                 b_i,
    input   logic                        sign_b_i,
    output  logic [127:0]                prod_o
);

logic[63:0] a_q, b_q;
logic   sign_a_q, sign_b_q;

logic [127:0] mult_result_d, mult_result_dly1, mult_result_dly2;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
        a_q <= '0;
        b_q <= '0;
        sign_a_q <= '0;
        sign_b_q <= '0;
     end else begin
        a_q <= a_i;
        b_q <= b_i;
        sign_a_q <= sign_a_i;
        sign_b_q <= sign_b_i;
     end
end

assign mult_result_d = $signed({a_q[63] & sign_a_q, a_q}) *
                       $signed({b_q[63] & sign_b_q, b_q});


always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
        mult_result_dly1 <= '0;
        mult_result_dly2 <= '0;
     end else begin
        mult_result_dly1 <= mult_result_d;
        mult_result_dly2 <= mult_result_dly1;
     end
end

assign prod_o = mult_result_dly2;

endmodule : mul64x64_d3_wrap

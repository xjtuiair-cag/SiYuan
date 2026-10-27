// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sd_clock_divider.v
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

module sd_clock_divider 
    import sy_pkg::*;
(
    input   logic         clk,  // 100M
    input   logic         rst,
    input   logic[7:0]    divider,
    output  logic         sd_clk,
    output  logic         sd_clk_rise,
    output  logic         sd_clk_fall
);

    logic [7:0] counter;
    logic div_clk;  

    always_ff @(`DFF_CR(clk,rst)) begin
        if (`DFF_IS_R(rst)) begin
            counter      <=  8'd0;
            div_clk      <=  1'b0;
        end else begin
            if (counter ==  divider) begin
                counter     <=  8'd0;
                div_clk     <=  ~div_clk;
            end else begin
                counter     <=  counter +   1;
            end
        end
    end
    assign sd_clk_rise = (counter ==  divider) && (div_clk == 1'b0);
    assign sd_clk_fall = (counter ==  divider) && (div_clk == 1'b1);
    assign sd_clk      = div_clk;
endmodule



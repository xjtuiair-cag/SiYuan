// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_wb_sel_ctrl.v
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

module sd_wb_sel_ctrl
    import sy_pkg::*;
(
    input   logic             wb_clk,
    input   logic             rst,
    input   logic             ena,
    input   logic[31:0]       base_adr_i,
    input   logic[31:0]       wbm_adr_i,
    input   logic[`BLKSIZE_W+`BLKCNT_W-1:0] xfersize,
    output  logic[3:0]         wbm_sel_o
);

function [3:0] get_first_sel;
    input [1:0] byte_addr;
    begin
        case (byte_addr)
            2'b00: get_first_sel = 4'b1111;
            2'b01: get_first_sel = 4'b0111;
            2'b10: get_first_sel = 4'b0011;
            2'b11: get_first_sel = 4'b0001;
        endcase
    end
endfunction

function [3:0] get_last_sel;
    input [1:0] byte_addr;
    begin
        case (byte_addr)
            2'b00: get_last_sel = 4'b1111;
            2'b01: get_last_sel = 4'b1000;
            2'b10: get_last_sel = 4'b1100;
            2'b11: get_last_sel = 4'b1110;
        endcase
    end
endfunction

logic [31:0] base_adr_reg;
logic [`BLKSIZE_W+`BLKCNT_W-1:0] xfersize_reg;
logic [31:0] base_adr_plus_xfersize;

logic [3:0] first_mask;
logic [3:0] second_mask;

assign base_adr_plus_xfersize = base_adr_reg + xfersize_reg;
assign first_mask = base_adr_reg[31:2] == wbm_adr_i[31:2] ? get_first_sel(base_adr_reg[1:0]) : 4'b1111;
assign second_mask = base_adr_plus_xfersize[31:2] == wbm_adr_i[31:2] ? get_last_sel(base_adr_plus_xfersize[1:0]) : 4'b1111;
assign wbm_sel_o = first_mask & second_mask;

always_ff @(`DFF_CR(wb_clk,rst)) begin
    if (`DFF_IS_R(rst)) begin
        base_adr_reg <= 32'h0;
        xfersize_reg <= 0;
    end else begin
        if (ena) begin
            base_adr_reg <= base_adr_i;
            xfersize_reg <= xfersize;
        end
    end
end

endmodule

    

// ---------------------------------------------------------------------------------------------------------------------
// Copyright (c) 1986 - 2020, CAG team, Institute of AI and Robotics, Xi'an Jiaotong University
// All Rights Reserved. You may not use this file in commerce unless acquired the permmission of CAG team.
// ---------------------------------------------------------------------------------------------------------------------
// FILE NAME  : sdp_sram_with_strobe.v
// DEPARTMENT : Architecture
// AUTHOR     : wenzhe
// AUTHOR'S EMAIL : venturezhao@gmail.com
// ---------------------------------------------------------------------------------------------------------------------
// Ver 1.0  2019--07--01 initial version.
// ---------------------------------------------------------------------------------------------------------------------
`timescale 1ns / 1ps

module sdp_sram_with_strobe #(
    parameter WR_ADDR_WTH = 10,
    parameter WR_DATA_WTH = 32,
    parameter RD_ADDR_WTH = 10,
    parameter RD_DATA_WTH = 32,
    parameter RD_DELAY = 2
) (
    input                               wr_clk_i,
    input                               we_i,
    input [WR_ADDR_WTH-1 : 0]           waddr_i,
    input [WR_DATA_WTH-1 : 0]           wdata_i,
    input [WR_DATA_WTH/8-1 : 0]         wstrb_i,
    input                               rd_clk_i,
    input                               re_i,
    input [RD_ADDR_WTH-1 : 0]           raddr_i,
    output[RD_DATA_WTH-1 : 0]           rdata_o
);

    localparam MEM_SIZE = (1<<WR_ADDR_WTH) * WR_DATA_WTH/8;

    reg   [7 : 0]                       mem[0 : MEM_SIZE-1];
    reg   [RD_ADDR_WTH-1 : 0]           raddr;
    reg   [RD_DATA_WTH-1 : 0]           rdata_dlychain[0 : RD_DELAY];
    reg   [RD_DATA_WTH-1 : 0]           rdata_comb;

    integer i;

    // write logic
    always @(posedge wr_clk_i) begin
        for(i=0; i<WR_DATA_WTH/8; i=i+1) begin
            mem[waddr_i*WR_DATA_WTH/8 + i] <= (we_i && wstrb_i[i]) ? wdata_i[i*8 +: 8]
                                                                   : mem[waddr_i*WR_DATA_WTH/8 + i];
        end
        raddr <= raddr_i;
    end

    // read logic
    always @(*) begin
        for(i=0; i<RD_DATA_WTH/8; i=i+1) begin
            rdata_dlychain[0][i*8 +: 8] = mem[raddr*RD_DATA_WTH/8 + i];
            rdata_comb[i*8 +: 8] = mem[raddr_i*RD_DATA_WTH/8 + i];
        end
    end

    // delay
    always @(posedge rd_clk_i) begin
        for(i=0; i<RD_DELAY; i=i+1) begin
            rdata_dlychain[i+1] <= rdata_dlychain[i];
        end
    end

    generate
        if(RD_DELAY == 0) begin
            assign rdata_o = rdata_comb;
        end else begin
            assign rdata_o = rdata_dlychain[RD_DELAY-1];
        end
    endgenerate

endmodule : sdp_sram_with_strobe


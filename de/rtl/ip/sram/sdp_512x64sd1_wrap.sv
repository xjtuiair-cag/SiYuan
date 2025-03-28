// ---------------------------------------------------------------------------------------------------------------------
// Copyright (c) 1986 - 2020, CAG team, Institute of AI and Robotics, Xi'an Jiaotong University
// ---------------------------------------------------------------------------------------------------------------------
// FILE NAME  : sdp_512x64sd1_wrap.sv
// DEPARTMENT : Architecture
// AUTHOR     : wenzhe
// AUTHOR'S EMAIL : venturezhao@gmail.com
// ---------------------------------------------------------------------------------------------------------------------
// Ver 1.0  2019--07--01 initial version.
// ---------------------------------------------------------------------------------------------------------------------
`timescale 1ns/1ps

`include "glb_def.svh"

module sdp_512x64sd1_wrap (
    input           wr_clk_i,
    input           we_i,
    input [8:0]     waddr_i,
    input [63:0]    wdata_i,
    input [7:0]     wstrb_i,
    input           rd_clk_i,
    input           re_i,
    input [8:0]     raddr_i,
    output[63:0]    rdata_o
);

`ifdef PLATFORM_XILINX
    sdp_512x64sd1 sdp_512x64sd1_inst (
        .clka           (wr_clk_i),
        .ena            (1'b1),
        .wea            ({8{we_i}} & wstrb_i),
        .addra          (waddr_i),
        .dina           (wdata_i),
        .clkb           (rd_clk_i),
        .enb            (1'b1),
        .addrb          (raddr_i),
        .doutb          (rdata_o)
    );
`endif

endmodule : sdp_512x64sd1_wrap

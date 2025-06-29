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
`ifdef PLATFORM_SIM
    sdp_sram_with_strobe #(
        .WR_ADDR_WTH    (9),
        .WR_DATA_WTH    (64),
        .RD_ADDR_WTH    (9),
        .RD_DATA_WTH    (64),
        .RD_DELAY       (1)
    ) sdp_512x64sd1_inst (
        .wr_clk_i       (wr_clk_i),
        .we_i           (we_i),
        .waddr_i        (waddr_i),
        .wdata_i        (wdata_i),
        .wstrb_i        (wstrb_i),
        .rd_clk_i       (rd_clk_i),
        .re_i           (re_i),
        .raddr_i        (raddr_i),
        .rdata_o        (rdata_o)
    );
`endif

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

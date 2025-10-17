module sp_256x64sd1_wrap (
    input           clk_i,
    input           vld_i,
    input           we_i,
    input [7:0]     addr_i,
    input [63:0]    wdata_i,
    input [7:0]     wstrb_i,
    output[63:0]    rdata_o
);

`ifdef PLATFORM_SIM
    sdp_sram_with_strobe #(
        .WR_ADDR_WTH    (8),
        .WR_DATA_WTH    (64),
        .RD_ADDR_WTH    (8),
        .RD_DATA_WTH    (64),
        .RD_DELAY       (1)
    ) sp_512x64sd1_inst (
        .wr_clk_i       (clk_i),
        .we_i           (vld_i && we_i),
        .waddr_i        (addr_i),
        .wdata_i        (wdata_i),
        .wstrb_i        (wstrb_i),
        .rd_clk_i       (clk_i),
        .re_i           (vld_i && !we_i),
        .raddr_i        (addr_i),
        .rdata_o        (rdata_o)
    );
`endif

`ifdef PLATFORM_XILINX
    sp_256x64sd1 sp_256x64sd1_inst (
        .clka           (clk_i), // IN STD_LOGIC;
        .ena            (vld_i), // IN STD_LOGIC;
        .wea            (we_i & wstrb_i), // IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        .addra          (addr_i), // IN STD_LOGIC_VECTOR(8 DOWNTO 0);
        .dina           (wdata_i), // IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        .douta          (rdata_o)  // OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
    );
`endif

endmodule : sp_256x64sd1_wrap

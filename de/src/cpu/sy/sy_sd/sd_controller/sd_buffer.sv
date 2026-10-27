// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sd_buffer.v
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

module sd_buffer
    import sy_pkg::*;
(
    // Shared SYSCON signals.
    input  logic                clk,
    input  logic                rst,

    // Wishbone Interface to SD card controller IP core.
    input  logic[31:0]          s_wb_dat_i, // Buffer reads from SD
    output logic[31:0]          s_wb_dat_o, // Buffer writes to SD
    input  logic[31:0]          s_wb_adr_i, // only [8:2] are used.
    input  logic[3:0]           s_wb_sel_i, // Actually not used.
    input  logic                s_wb_we_i,  // write enable.
    input  logic                s_wb_cyc_i, // cycle enable.
    input  logic                s_wb_stb_i, // strobing.
    output logic                s_wb_ack_o, // acknowledgement.

    // Buffer read/write for SD card bridge.
    input  logic[31:0]              buf_addr_i, // address of the 8-byte
    input  logic[`NOC_DATA_BITS]    buf_data_i, // 8-byte per data input
    // unit in the 512-byte block
    input  logic                    buf_ce_i,   // request enable
    input  logic                    buf_we_i,   // write enable
    input  logic[1:0]               buf_data_sz,
    output logic[`NOC_DATA_BITS]    buf_data_o
);

    // ------ Signals Declaration ------ //
    logic            bram_ena;
    logic [0:7]      bram_wea;
    logic [8:0]      bram_addr;
    logic [0:63]     bram_din;
    logic [0:63]     bram_dout;

    logic            buf_rd_f;
    logic            wb_rd_f;
    logic            wb_wsel_f;
  
    // ------ Submodule Instantiation ------ //  
    // 1 cycle read latency.
    sp_512x64sd1_wrap sd_cache_bram(
        .clk_i      (clk),
        .vld_i      (bram_ena),
        .we_i       (|bram_wea),
        .addr_i     (bram_addr),
        .wdata_i    (bram_din),
        .wstrb_i    (bram_wea),
        .rdata_o    (bram_dout)
    );

    // ------ Combinational Logic ------ //
    always_comb begin 
        bram_ena    =   1'b0;
        bram_addr   =   0;
        bram_wea    =   8'h0;
        bram_din    =   64'h0;

        s_wb_ack_o  =   wb_rd_f;
        s_wb_dat_o  =   bram_dout[{wb_wsel_f,   5'b0}   +:  32];
        buf_data_o  =   bram_dout;

        if (buf_ce_i) begin
            bram_ena    =   ~buf_addr_i[12];
            bram_addr   =   buf_addr_i[11:3];
            if (buf_we_i) begin
                case (buf_data_sz)
                    2'd0:   begin
                        bram_wea[buf_addr_i[2:0]]                   =   1'h1;
                        bram_din[{buf_addr_i[2:0],  3'b0}   +:  8]  =   buf_data_i[7:0];
                    end
                    2'd1:   begin
                        bram_wea[{buf_addr_i[2:1],  1'b0}   +:  2]  =   2'h3;
                        bram_din[{buf_addr_i[2:1],  4'b0}   +:  16] =   buf_data_i[15:0];
                    end
                    2'd2:   begin
                        bram_wea[{buf_addr_i[2],    2'b0}   +:  4]  =   4'hf;
                        bram_din[{buf_addr_i[2],    5'b0}   +:  32] =   buf_data_i[31:0];
                    end
                    2'd3:   begin
                        bram_wea                                    =   8'hff;
                        bram_din                                    =   buf_data_i;
                    end
                endcase
            end
        end else if (s_wb_cyc_i && s_wb_stb_i && ~wb_rd_f) begin
            bram_ena    =   1'b1;
            bram_addr   =   s_wb_adr_i[11:3];
            if (s_wb_we_i) begin
                bram_wea[{s_wb_adr_i[2],    2'b0}   +:  4]  =   4'hf;
                bram_din[{s_wb_adr_i[2],    5'b0}   +:  32] =   s_wb_dat_i;
            end
        end
    end

    // ------ Sequential Logic ------ //
    always @(`DFF_CR(clk,rst)) begin
        if (`DFF_IS_R(rst)) begin
            buf_rd_f    <=  1'b0;
            wb_rd_f     <=  1'b0;
            wb_wsel_f   <=  1'b0;
        end else begin
            if (buf_ce_i)   begin
                buf_rd_f    <=  1'b1;
                wb_rd_f     <=  1'b0;
            end else if (s_wb_cyc_i && s_wb_stb_i && ~wb_rd_f) begin
                buf_rd_f    <=  1'b0;
                wb_rd_f     <=  1'b1;
                wb_wsel_f   <=  s_wb_adr_i[2];
            end else begin
                buf_rd_f    <=  1'b0;
                wb_rd_f     <=  1'b0;
            end
        end
    end

endmodule

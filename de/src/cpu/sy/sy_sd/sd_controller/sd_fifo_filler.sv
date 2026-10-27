// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sd_fifo_filler.sv
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

module sd_fifo_filler
    import sy_pkg::*;
(
    input   logic           wb_clk,
    input   logic           wb_rst,
    //WB Signals
    output  logic [31:0]    wbm_adr_o,
    output  logic           wbm_we_o,
    output  logic [31:0]    wbm_dat_o,
    input   logic [31:0]    wbm_dat_i,
    output  logic           wbm_cyc_o,
    output  logic           wbm_stb_o,
    input   logic           wbm_ack_i,
    //Data Master Control signals
    input   logic           en_rx_i,
    input   logic           en_tx_i,
    input   logic [31:0]    adr_i,
    input   logic [`BLKSIZE_W+`BLKCNT_W-1:0] xfersize,
    //Data Serial signals
    input   logic [31:0]    dat_i,
    output  logic [31:0]    dat_o,
    input   logic           wr_i,
    input   logic           rd_i,
    output  logic           sd_full_o,
    output  logic           sd_empty_o
);
//======================================================================================================================
// Parameters
//======================================================================================================================
`define FIFO_MEM_ADR_SIZE 4
`define MEM_OFFSET 4

localparam SD2WB_STATE_IDLE = 2'd0;
localparam SD2WB_STATE_READ_PENDING = 2'd1;
localparam SD2WB_STATE_WRITE_PENDING = 2'd2;

localparam WB2SD_STATE_IDLE = 2'd0;
localparam WB2SD_STATE_READ_PENDING = 2'd1;
localparam WB2SD_STATE_WRITE_PENDING = 2'd2;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
logic [`BLKSIZE_W+`BLKCNT_W-1:0]    xfersize_f;
logic                               wb2sd_wr_en;

logic           sd2wb_rd_en;
logic           sd2wb_wb_cyc_o;
logic           sd2wb_empty;
logic [1:0]     sd2wb_state;

logic           wb2sd_wb_cyc_o;
logic [31:0]    wb2sd_din_f;
logic           wb2sd_full;
logic [1:0]     wb2sd_state;
//======================================================================================================================
// Instance
//======================================================================================================================
always_ff @(`DFF_CR(wb_clk,wb_rst)) begin
    if (`DFF_IS_R(wb_rst)) begin
        wbm_adr_o       <=  32'h0;
        wbm_we_o        <=  1'b0;
        xfersize_f      <=  (`BLKSIZE_W+`BLKCNT_W)'(0);
    end else begin
        if (en_rx_i) begin  // RX is reading from SD and writing to wishbone
            wbm_we_o    <=  1'b1;
        end else if (en_tx_i) begin
            wbm_we_o    <=  1'b0;
        end

        if (en_rx_i || en_tx_i) begin
            wbm_adr_o   <=  adr_i;
            xfersize_f  <=  xfersize[`BLKSIZE_W+`BLKCNT_W-1:2] - ((xfersize[1:0] == 2'b0) ? 1 : 0);
        end else if ((wbm_we_o && wbm_cyc_o && wbm_ack_i) || (~wbm_we_o && wb2sd_wr_en)) begin
            wbm_adr_o   <=  wbm_adr_o + `MEM_OFFSET;
            xfersize_f  <=  xfersize_f - 1;
        end
    end
end

sync_fifo # (
    .FIFO_LEN       (32),
    .DATA_WTH       (32),
    .ADDR_WTH       (5),
    .FIFO_RD_TYPE   ("STANDARD") 
) sd2wb_fifo(
    // clock & reset
    .clk_i          (wb_clk),
    .rst_i          (wb_rst),
    // clear
    .clr_i          (1'b0),
    // write interface
    .wr_data_i      (dat_i),
    .wr_en_i        (wr_i),
    .full_o         (sd_full_o),
    .a_full_o       (),
    // read interface
    .rd_data_o      (wbm_dat_o),
    .rd_en_i        (sd2wb_rd_en),
    .empty_o        (sd2wb_empty),
    .a_empty_o      ()
);

always_ff @(`DFF_CR(wb_clk,wb_rst)) begin
    if (`DFF_IS_R(wb_rst)) begin
        sd2wb_state     <=  SD2WB_STATE_IDLE;
    end else begin
        case (sd2wb_state)
            SD2WB_STATE_IDLE: begin
                if (en_rx_i) begin
                    sd2wb_state     <=  SD2WB_STATE_READ_PENDING;
                end
            end
            SD2WB_STATE_READ_PENDING: begin
                if (sd2wb_rd_en) begin
                    sd2wb_state     <=  SD2WB_STATE_WRITE_PENDING;
                end
            end
            SD2WB_STATE_WRITE_PENDING: begin
                if (wbm_cyc_o & wbm_ack_i) begin
                    if (xfersize_f == 0) begin
                        sd2wb_state <=  SD2WB_STATE_IDLE;
                    end else begin
                        sd2wb_state <=  SD2WB_STATE_READ_PENDING;
                    end
                end
            end
        endcase
    end
end

// TODO
always_comb begin
    sd2wb_rd_en     = 1'b0;
    sd2wb_wb_cyc_o  = 1'b0;

    case (sd2wb_state)
        SD2WB_STATE_READ_PENDING: begin
            sd2wb_rd_en = !sd2wb_empty;
        end
        SD2WB_STATE_WRITE_PENDING: begin
            sd2wb_wb_cyc_o = !en_rx_i && !en_tx_i;
        end
    endcase
end

sync_fifo # (
    .FIFO_LEN       (32),
    .DATA_WTH       (32),
    .ADDR_WTH       (5),
    .FIFO_RD_TYPE   ("STANDARD") 
) wb2sd_fifo(
    // clock & reset
    .clk_i          (wb_clk),
    .rst_i          (wb_rst),
    // clear
    .clr_i          (1'b0),
    // write interface
    .wr_data_i      (wb2sd_din_f),
    .wr_en_i        (wb2sd_wr_en),
    .full_o         (wb2sd_full),
    .a_full_o       (),
    // read interface
    .rd_data_o      (dat_o),
    .rd_en_i        (rd_i),
    .empty_o        (sd_empty_o),
    .a_empty_o      ()
);

always_ff @(`DFF_CR(wb_clk,wb_rst)) begin
    if (`DFF_IS_R(wb_rst)) begin
        wb2sd_din_f     <=  32'h0;
        wb2sd_state     <=  WB2SD_STATE_IDLE;
    end else begin
        if (wbm_cyc_o & wbm_ack_i) begin
            wb2sd_din_f <=  wbm_dat_i;
        end

        case (wb2sd_state)
            WB2SD_STATE_IDLE: begin
                if (en_tx_i) begin
                    wb2sd_state     <=  WB2SD_STATE_READ_PENDING;
                end
            end
            WB2SD_STATE_READ_PENDING: begin
                if (wbm_cyc_o & wbm_ack_i) begin
                    wb2sd_state     <=  WB2SD_STATE_WRITE_PENDING;
                end
            end
            WB2SD_STATE_WRITE_PENDING: begin
                if (wb2sd_wr_en) begin
                    if (xfersize_f == 0) begin
                        wb2sd_state <=  WB2SD_STATE_IDLE;
                    end else begin
                        wb2sd_state <=  WB2SD_STATE_READ_PENDING;
                    end
                end
            end
        endcase
    end
end

always_comb begin
    wb2sd_wr_en     = 1'b0;
    wb2sd_wb_cyc_o  = 1'b0;

    case (wb2sd_state)
        WB2SD_STATE_READ_PENDING: begin
            wb2sd_wb_cyc_o = !en_rx_i && !en_tx_i;
        end
        WB2SD_STATE_WRITE_PENDING: begin
            wb2sd_wr_en = !wb2sd_full;
        end
    endcase
end

assign wbm_cyc_o = wbm_we_o ? sd2wb_wb_cyc_o : wb2sd_wb_cyc_o;
assign wbm_stb_o = wbm_cyc_o;

// (* mark_debug = "true" *) logic         prb_sd2wb_wr_en; 
// (* mark_debug = "true" *) logic[31:0]   prb_sd2wb_wr_data; 
// (* mark_debug = "true" *) logic         prb_sd2wb_wr_full; 

// assign prb_sd2wb_wr_en   = wr_i; 
// assign prb_sd2wb_wr_data = dat_i; 
// assign prb_sd2wb_wr_full = sd_full_o; 


endmodule

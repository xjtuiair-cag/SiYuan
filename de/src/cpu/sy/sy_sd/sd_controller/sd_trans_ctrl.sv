// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sd_trans_ctrl.v
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

module sd_trans_ctrl
    import sy_pkg::*;
(
    // WISHBONE common
    input   logic           wb_clk_i,
    input   logic           wb_rst_i,
    // WISHBONE slave
    input   logic[31:0]     wb_dat_i,
    output  logic[31:0]     wb_dat_o,
    input   logic[7:0]      wb_adr_i,
    input   logic[3:0]      wb_sel_i,
    input   logic           wb_we_i,
    input   logic           wb_cyc_i,
    input   logic           wb_stb_i,
    output  logic           wb_ack_o,
    // WISHBONE master
    output  logic[31:0]     m_wb_adr_o,
    output  logic[3:0]      m_wb_sel_o,
    output  logic           m_wb_we_o,
    input   logic[31:0]     m_wb_dat_i,
    output  logic[31:0]     m_wb_dat_o,
    output  logic           m_wb_cyc_o,
    output  logic           m_wb_stb_o,
    input   logic           m_wb_ack_i,
    output  logic[2:0]      m_wb_cti_o,
    output  logic[1:0]      m_wb_bte_o,
    //SD BUS
    input   logic [3:0]     sd_dat_dat_i,
    output  logic [3:0]     sd_dat_out_o,
    output  logic           sd_dat_oe_o,
    input   logic           sd_cmd_dat_i,
    output  logic           sd_cmd_out_o,
    output  logic           sd_cmd_oe_o,
    output  logic           sd_clk_o,

    output  logic           int_cmd,
    output  logic           int_data
);

//======================================================================================================================
// Parameters
//======================================================================================================================
localparam SD2WB_STATE_IDLE     = 3'd0;
localparam SD2WB_STATE_RESP0    = 3'd1;
localparam SD2WB_STATE_RESP1    = 3'd2;
localparam SD2WB_STATE_RESP2    = 3'd3;
localparam SD2WB_STATE_RESP3    = 3'd4;
localparam SD2WB_STATE_CMD_ISR  = 3'd5;
localparam SD2WB_STATE_DATA_ISR = 3'd6;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
//SD clock
logic [3:0]                         wr_wbm_sel;
logic [`BLKSIZE_W+`BLKCNT_W-1:0]    xfersize;
logic [31:0]                        wbm_adr;

logic                               go_idle;
logic                               cmd_start_wb_clk;
logic                               cmd_start_sd_clk;
logic [1:0]                         cmd_setting;
logic                               cmd_start_tx;
logic [39:0]                        cmd;
logic [119:0]                       cmd_response;
logic                               cmd_crc_ok;
logic                               cmd_index_ok;
logic                               cmd_finish;
logic                               d_write;
logic                               d_read;
logic [31:0]                        data_in_rx_fifo;
logic [31:0]                        data_out_tx_fifo;
logic                               tx_fifo_empty;
logic                               rx_fifo_full;
logic                               sd_data_busy;
logic                               data_busy;
logic                               data_crc_ok;
logic                               rd_fifo;
logic                               we_fifo;
logic                               data_start_rx;
logic                               data_start_tx;
logic                               cmd_int_rst_sd_clk;
logic                               cmd_int_rst;
logic                               data_int_rst_sd_clk;
logic                               data_int_rst;

logic                               wb2sd_fifo_wr_en;
logic                               wb2sd_fifo_rd_en;
logic                               wb2sd_fifo_rd_en_f;
logic                               wb2sd_fifo_full;
logic                               wb2sd_fifo_empty;
logic [39:0]                        wb2sd_fifo_din;
logic [39:0]                        wb2sd_fifo_dout;

logic                               sd2wb_fifo_wr_en;
logic                               sd2wb_fifo_rd_en;
logic                               sd2wb_fifo_rd_en_f;
logic                               sd2wb_fifo_full;
logic                               sd2wb_fifo_empty;
logic [39:0]                        sd2wb_fifo_din;
logic [39:0]                        sd2wb_fifo_dout;

//wb accessible registers
logic [31:0]                        argument_reg_wb_clk;
logic [`CMD_REG_SIZE-1:0]           command_reg_wb_clk;
logic [`CMD_TIMEOUT_W-1:0]          cmd_timeout_reg_wb_clk;
logic [`DATA_TIMEOUT_W-1:0]         data_timeout_reg_wb_clk;
logic [0:0]                         software_reset_reg_wb_clk;
logic [31:0]                        response_0_reg_wb_clk;
logic [31:0]                        response_1_reg_wb_clk;
logic [31:0]                        response_2_reg_wb_clk;
logic [31:0]                        response_3_reg_wb_clk;
logic [`BLKSIZE_W-1:0]              block_size_reg_wb_clk;
logic [0:0]                         controll_setting_reg_wb_clk;
logic [`INT_CMD_SIZE-1:0]           cmd_int_status_reg_wb_clk;
logic [`INT_DATA_SIZE-1:0]          data_int_status_reg_wb_clk;
logic [`INT_CMD_SIZE-1:0]           cmd_int_enable_reg_wb_clk;
logic [`INT_DATA_SIZE-1:0]          data_int_enable_reg_wb_clk;
logic [`BLKCNT_W-1:0]               block_count_reg_wb_clk;
logic [31:0]                        dma_addr_reg_wb_clk;
logic [7:0]                         clock_divider_reg_wb_clk;

logic [31:0]                        argument_reg_sd_clk;
logic [`CMD_REG_SIZE-1:0]           command_reg_sd_clk;
logic [`CMD_TIMEOUT_W-1:0]          cmd_timeout_reg_sd_clk;
logic [`DATA_TIMEOUT_W-1:0]         data_timeout_reg_sd_clk;
logic [0:0]                         software_reset_reg_sd_clk;
logic [31:0]                        response_0_reg_sd_clk;
logic [31:0]                        response_1_reg_sd_clk;
logic [31:0]                        response_2_reg_sd_clk;
logic [31:0]                        response_3_reg_sd_clk;
logic [`BLKSIZE_W-1:0]              block_size_reg_sd_clk;
logic [0:0]                         controll_setting_reg_sd_clk;
logic [`INT_CMD_SIZE-1:0]           cmd_int_status_reg_sd_clk;
logic [`INT_CMD_SIZE-1:0]           cmd_int_status_reg_sd_clk_f;
logic [`INT_DATA_SIZE-1:0]          data_int_status_reg_sd_clk;
logic [`INT_DATA_SIZE-1:0]          data_int_status_reg_sd_clk_f;
logic [`BLKCNT_W-1:0]               block_count_reg_sd_clk;
logic [1:0]                         dma_addr_reg_sd_clk;
logic [7:0]                         clock_divider_reg_sd_clk;
logic                               sd_soft_rst;        
logic                               wb_soft_rst;        
logic                               sd_cmd_master_rst;        
logic                               sd_clk_rise;
logic                               sd_clk_fall;
logic                               cmd_serial_host_rst;
//======================================================================================================================
// clock divider
//======================================================================================================================
sd_clock_divider clock_divider(
    .clk            (wb_clk_i),
    .rst            (wb_rst_i),
    .divider        (clock_divider_reg_sd_clk),
    .sd_clk         (sd_clk_o),
    .sd_clk_rise    (sd_clk_rise),
    .sd_clk_fall    (sd_clk_fall)
);

sync_rstgen #(
    .RESET_VALUE ("LOW")
) soft_reset(
    .clk_i      (wb_clk_i),
    .rst_i      (wb_rst_i & ~software_reset_reg_wb_clk[0]),
    .rst_o      (wb_soft_rst)
);

sync_rstgen #(
    .RESET_VALUE ("LOW")
) cmd_reset(
    .clk_i      (wb_clk_i),
    .rst_i      (wb_soft_rst & ~go_idle),
    .rst_o      (cmd_serial_host_rst)
);
//======================================================================================================================
// command  trans
//======================================================================================================================
sd_cmd_master sd_cmd_master0(
    .sys_clk            (wb_clk_i),
    .sys_rst            (wb_soft_rst),
    .sd_clk_rise        (sd_clk_rise),
    .start_i            (cmd_start_sd_clk),
    .int_status_rst_i   (cmd_int_rst_sd_clk),
    .setting_o          (cmd_setting),
    .start_xfr_o        (cmd_start_tx),
    .go_idle_o          (go_idle),
    .cmd_o              (cmd),
    .response_i         (cmd_response),
    .crc_ok_i           (cmd_crc_ok),
    .index_ok_i         (cmd_index_ok),
    .busy_i             (sd_data_busy),
    .finish_i           (cmd_finish),
    .argument_i         (argument_reg_sd_clk),
    .command_i          (command_reg_sd_clk),
    .timeout_i          (cmd_timeout_reg_sd_clk),
    .int_status_o       (cmd_int_status_reg_sd_clk),

    .response_0_o       (response_0_reg_sd_clk),
    .response_1_o       (response_1_reg_sd_clk),
    .response_2_o       (response_2_reg_sd_clk),
    .response_3_o       (response_3_reg_sd_clk)
);

sd_cmd_serial_host cmd_serial_host0(
    .sys_clk        (wb_clk_i),
    .sys_rst        (cmd_serial_host_rst),
    .sd_clk_rise    (sd_clk_rise),
    .sd_clk_fall    (sd_clk_fall),

    .setting_i      (cmd_setting),
    .cmd_i          (cmd),
    .start_i        (cmd_start_tx),
    .finish_o       (cmd_finish),
    .response_o     (cmd_response),
    .crc_ok_o       (cmd_crc_ok),
    .index_ok_o     (cmd_index_ok),
    .cmd_dat_i      (sd_cmd_dat_i),
    .cmd_out_o      (sd_cmd_out_o),
    .cmd_oe_o       (sd_cmd_oe_o)
);
//======================================================================================================================
// data trans
//======================================================================================================================
sd_data_master sd_data_master0(
    .sys_clk          (wb_clk_i),
    .sys_rst          (wb_soft_rst),
    .sd_clk_rise      (sd_clk_rise),
    .start_tx_i       (data_start_tx),
    .start_rx_i       (data_start_rx),
    .timeout_i		  (data_timeout_reg_sd_clk),
    .d_write_o        (d_write),
    .d_read_o         (d_read),
    .tx_fifo_rd_en_i  (rd_fifo),
    .tx_fifo_empty_i  (tx_fifo_empty),
    .rx_fifo_wr_en_i  (we_fifo),
    .rx_fifo_full_i   (rx_fifo_full),
    .xfr_complete_i   (!data_busy),
    .crc_ok_i         (data_crc_ok),
    .int_status_o     (data_int_status_reg_sd_clk),
    .int_status_rst_i (data_int_rst_sd_clk)
);

sd_data_serial_host sd_data_serial_host0(
    .sys_clk        (wb_clk_i),
    .sys_rst        (wb_soft_rst),
    .sd_clk_rise    (sd_clk_rise),
    .sd_clk_fall    (sd_clk_fall),

    .rd_data_in     (data_out_tx_fifo),
    .rd_fifo        (rd_fifo),
    .wr_data_out    (data_in_rx_fifo),
    .wr_fifo        (we_fifo),

    .DAT_oe_o       (sd_dat_oe_o),
    .DAT_dat_o      (sd_dat_out_o),
    .DAT_dat_i      (sd_dat_dat_i),

    .blksize        (block_size_reg_sd_clk),
    .bus_4bit       (controll_setting_reg_sd_clk[0]),
    .blkcnt         (block_count_reg_sd_clk),
    .start          ({d_read, d_write}),
    .byte_alignment (dma_addr_reg_sd_clk),
    .sd_data_busy   (sd_data_busy),
    .busy           (data_busy),
    .crc_ok         (data_crc_ok)
);
//======================================================================================================================
// ctrl
//======================================================================================================================
logic en_rx,en_tx;
assign en_rx = cmd_start_wb_clk & (command_reg_wb_clk[`CMD_WITH_DATA] == 2'b01);
assign en_tx = cmd_start_wb_clk & (command_reg_wb_clk[`CMD_WITH_DATA] == 2'b10);

sd_fifo_filler sd_fifo_filler0(
    .wb_clk         (wb_clk_i),
    .wb_rst         (wb_soft_rst),

    .wbm_adr_o      (wbm_adr),
    .wbm_we_o       (m_wb_we_o),
    .wbm_dat_o      (m_wb_dat_o),
    .wbm_dat_i      (m_wb_dat_i),
    .wbm_cyc_o      (m_wb_cyc_o),
    .wbm_stb_o      (m_wb_stb_o),
    .wbm_ack_i      (m_wb_ack_i),

    .en_rx_i        (en_rx),
    .en_tx_i        (en_tx),
    .adr_i          (dma_addr_reg_wb_clk),
    .xfersize       (xfersize),

    .dat_i          (data_in_rx_fifo),
    .dat_o          (data_out_tx_fifo),
    .wr_i           (we_fifo),
    .rd_i           (rd_fifo),
    .sd_empty_o     (tx_fifo_empty),
    .sd_full_o      (rx_fifo_full)
);

// block_size_reg_wb_clk always be 511, so we left shift 9 bit to avoid use multiplier
// assign xfersize = (block_size_reg_wb_clk + 1'b1) * (block_count_reg_wb_clk + 1'b1);
assign xfersize = (block_count_reg_wb_clk + 1'b1) << 9;

logic wb_sel_ctrl_en;
assign wb_sel_ctrl_en = cmd_start_wb_clk & (command_reg_wb_clk[`CMD_WITH_DATA] == 2'b01);
sd_wb_sel_ctrl sd_wb_sel_ctrl0(
    .wb_clk         (wb_clk_i),
    .rst            (wb_soft_rst),
    .ena            (wb_sel_ctrl_en),
    .base_adr_i     (dma_addr_reg_wb_clk),
    .wbm_adr_i      (wbm_adr),
    .xfersize       (xfersize),
    .wbm_sel_o      (wr_wbm_sel)
);

logic cmd_with_data_start;
logic r_w;
assign cmd_with_data_start = cmd_start_sd_clk & (command_reg_sd_clk[`CMD_WITH_DATA] != 2'b00);
assign r_w = command_reg_sd_clk[`CMD_WITH_DATA] == 2'b01;

sd_data_xfer_trig sd_data_xfer_trig0 (
    .sys_clk               (wb_clk_i),
    .sys_rst               (wb_soft_rst),
    .sd_clk_rise           (sd_clk_rise),
    .cmd_with_data_start_i (cmd_with_data_start),
    .r_w_i                 (r_w),
    .cmd_int_status_i      (cmd_int_status_reg_sd_clk),
    .start_tx_o            (data_start_tx),
    .start_rx_o            (data_start_rx)
);

sd_controller_wb sd_controller_wb0(
    .wb_clk_i                       (wb_clk_i),
    .wb_rst_i                       (wb_rst_i),
    .wb_dat_i                       (wb_dat_i),
    .wb_dat_o                       (wb_dat_o),
    .wb_adr_i                       (wb_adr_i),
    .wb_sel_i                       (wb_sel_i),
    .wb_we_i                        (wb_we_i),
    .wb_stb_i                       (wb_stb_i),
    .wb_cyc_i                       (wb_cyc_i),
    .wb_ack_o                       (wb_ack_o),
    .cmd_start                      (cmd_start_wb_clk),

    .data_int_rst                   (data_int_rst),
    .cmd_int_rst                    (cmd_int_rst),
    .argument_reg                   (argument_reg_wb_clk),
    .command_reg                    (command_reg_wb_clk),
    .response_0_reg                 (response_0_reg_wb_clk),
    .response_1_reg                 (response_1_reg_wb_clk),
    .response_2_reg                 (response_2_reg_wb_clk),
    .response_3_reg                 (response_3_reg_wb_clk),
    .software_reset_reg             (software_reset_reg_wb_clk),
    .cmd_timeout_reg                (cmd_timeout_reg_wb_clk),
    .data_timeout_reg               (data_timeout_reg_wb_clk),
    .block_size_reg                 (block_size_reg_wb_clk),
    .controll_setting_reg           (controll_setting_reg_wb_clk),
    .cmd_int_status_reg             (cmd_int_status_reg_wb_clk),
    .cmd_int_enable_reg             (cmd_int_enable_reg_wb_clk),
    .clock_divider_reg              (clock_divider_reg_wb_clk),
    .block_count_reg                (block_count_reg_wb_clk),
    .dma_addr_reg                   (dma_addr_reg_wb_clk),
    .data_int_status_reg            (data_int_status_reg_wb_clk),
    .data_int_enable_reg            (data_int_enable_reg_wb_clk),
    .wb2sd_fifo_full                (wb2sd_fifo_full),
    .wb2sd_fifo_wr_en               (wb2sd_fifo_wr_en),
    .wb2sd_fifo_din                 (wb2sd_fifo_din)
    );

// wb -> sd interruptions
// cdc_pulse data_int_rst_cross(wb_rst_i, wb_clk_i, data_int_rst, sd_clk_o, data_int_rst_sd_clk);
// cdc_pulse cmd_int_rst_cross (wb_rst_i, wb_clk_i, cmd_int_rst,  sd_clk_o, cmd_int_rst_sd_clk);

assign data_int_rst_sd_clk = data_int_rst;
assign cmd_int_rst_sd_clk  = cmd_int_rst;

// sync fifo
// wb -> sd register synchronization
sync_fifo # (
    .FIFO_LEN       (32),
    .DATA_WTH       (40),
    .ADDR_WTH       (5),
    .FIFO_RD_TYPE   ("STANDARD") 
) wb2sd_fifo(
    // clock & reset
    .clk_i          (wb_clk_i),
    .rst_i          (wb_rst_i),
    // clear
    .clr_i          (1'b0),
    // write interface
    .wr_data_i      (wb2sd_fifo_din),
    .wr_en_i        (wb2sd_fifo_wr_en),
    .full_o         (wb2sd_fifo_full),
    .a_full_o       (),
    // read interface
    .rd_data_o      (wb2sd_fifo_dout),
    .rd_en_i        (wb2sd_fifo_rd_en),
    .empty_o        (wb2sd_fifo_empty),
    .a_empty_o      ()
);

// assign wb2sd_fifo_rd_en = !wb2sd_fifo_empty & sd_clk_rise;
assign wb2sd_fifo_rd_en = !wb2sd_fifo_empty;
always_ff @(`DFF_CR(wb_clk_i,wb_rst_i)) begin
    if (`DFF_IS_R(wb_rst_i)) begin
        argument_reg_sd_clk         <= 32'd0;
        command_reg_sd_clk          <= {`CMD_REG_SIZE{1'b0}};
        software_reset_reg_sd_clk   <= 1'b0;
        cmd_timeout_reg_sd_clk      <= {`CMD_TIMEOUT_W{1'b0}};
        data_timeout_reg_sd_clk     <= {`DATA_TIMEOUT_W{1'b0}};
        block_size_reg_sd_clk       <= `RESET_BLOCK_SIZE;
        controll_setting_reg_sd_clk <= 1'b0;
        clock_divider_reg_sd_clk    <= 8'd99;
        block_count_reg_sd_clk      <= {`BLKCNT_W{1'b0}};
        dma_addr_reg_sd_clk         <= 32'd0;
        wb2sd_fifo_rd_en_f          <= 1'b0;
        cmd_start_sd_clk            <= 1'b0;
    end else begin
        wb2sd_fifo_rd_en_f <= wb2sd_fifo_rd_en;

        if (wb2sd_fifo_rd_en_f) begin
            if (wb2sd_fifo_dout[39:32] == `argument) begin
                cmd_start_sd_clk <= 1'b1;
            end else begin
                cmd_start_sd_clk <= 1'b0;
            end
            case (wb2sd_fifo_dout[39:32])
                `argument:      argument_reg_sd_clk         <= wb2sd_fifo_dout[31:0];
                `command:       command_reg_sd_clk          <= wb2sd_fifo_dout[`CMD_REG_SIZE-1:0];
                `reset:         software_reset_reg_sd_clk   <= wb2sd_fifo_dout[0];
                `cmd_timeout:   cmd_timeout_reg_sd_clk      <= wb2sd_fifo_dout[`CMD_TIMEOUT_W-1:0];
                `data_timeout:  data_timeout_reg_sd_clk     <= wb2sd_fifo_dout[`DATA_TIMEOUT_W-1:0];
                `blksize:       block_size_reg_sd_clk       <= wb2sd_fifo_dout[`BLKSIZE_W-1:0];
                `controller:    controll_setting_reg_sd_clk <= wb2sd_fifo_dout[0];
                `clock_d:       clock_divider_reg_sd_clk    <= wb2sd_fifo_dout[7:0];
                `blkcnt:        block_count_reg_sd_clk      <= wb2sd_fifo_dout[`BLKCNT_W-1:0];
                `dst_src_addr:  dma_addr_reg_sd_clk         <= wb2sd_fifo_dout[31:0];
            endcase
        end else begin
            cmd_start_sd_clk <= 1'b0;
        end
    end
end

// sync fifo
// wb -> sd register synchronization
sync_fifo # (
    .FIFO_LEN       (32),
    .DATA_WTH       (40),
    .ADDR_WTH       (5),
    .FIFO_RD_TYPE   ("STANDARD") 
) sd2wb_fifo(
    // clock & reset
    .clk_i          (wb_clk_i),
    .rst_i          (wb_rst_i),
    // clear
    .clr_i          (1'b0),
    // write interface
    .wr_data_i      (sd2wb_fifo_din),
    .wr_en_i        (sd2wb_fifo_wr_en),
    .full_o         (sd2wb_fifo_full),
    .a_full_o       (),
    // read interface
    .rd_data_o      (sd2wb_fifo_dout),
    .rd_en_i        (sd2wb_fifo_rd_en),
    .empty_o        (sd2wb_fifo_empty),
    .a_empty_o      ()
);
assign sd2wb_fifo_rd_en = !sd2wb_fifo_empty;
always_ff @(`DFF_CR(wb_clk_i,wb_rst_i)) begin
    if (`DFF_IS_R(wb_rst_i)) begin
        response_0_reg_wb_clk <= 32'd0;
        response_1_reg_wb_clk <= 32'd0;
        response_2_reg_wb_clk <= 32'd0;
        response_3_reg_wb_clk <= 32'd0;
        cmd_int_status_reg_wb_clk <= {`INT_CMD_SIZE{1'b0}};
        data_int_status_reg_wb_clk <= {`INT_DATA_SIZE{1'b0}};
        sd2wb_fifo_rd_en_f <= 1'b0;
    end else begin
        sd2wb_fifo_rd_en_f <= sd2wb_fifo_rd_en;

        if (sd2wb_fifo_rd_en_f) begin
            case (sd2wb_fifo_dout[39:32])
                `resp0:     response_0_reg_wb_clk <= sd2wb_fifo_dout[31:0];
                `resp1:     response_1_reg_wb_clk <= sd2wb_fifo_dout[31:0];
                `resp2:     response_2_reg_wb_clk <= sd2wb_fifo_dout[31:0];
                `resp3:     response_3_reg_wb_clk <= sd2wb_fifo_dout[31:0];
                `cmd_isr:   cmd_int_status_reg_wb_clk <= sd2wb_fifo_dout[`INT_CMD_SIZE-1:0];
                `data_isr:  data_int_status_reg_wb_clk <= sd2wb_fifo_dout[`INT_DATA_SIZE-1:0];
            endcase
        end
    end
end


logic [2:0] sd2wb_state;

always_ff @(`DFF_CR(wb_clk_i,wb_rst_i)) begin
    if (`DFF_IS_R(wb_rst_i)) begin
        sd2wb_state <= SD2WB_STATE_IDLE;
        cmd_int_status_reg_sd_clk_f <= {`INT_CMD_SIZE{1'b0}};
        data_int_status_reg_sd_clk_f <= {`INT_DATA_SIZE{1'b0}};
    end else begin
        case (sd2wb_state)
            SD2WB_STATE_IDLE: begin
                if (sd_clk_rise) begin
                    if (cmd_int_status_reg_sd_clk != cmd_int_status_reg_sd_clk_f) begin
                        if (cmd_int_status_reg_sd_clk == {`INT_CMD_SIZE{1'b0}}) begin
                            sd2wb_state <= SD2WB_STATE_CMD_ISR;
                        end else begin
                            sd2wb_state <= SD2WB_STATE_RESP0;
                        end
                    end else if (data_int_status_reg_sd_clk != data_int_status_reg_sd_clk_f) begin
                        sd2wb_state <= SD2WB_STATE_DATA_ISR;
                    end
                end
            end
            SD2WB_STATE_RESP0: begin
                if (sd_clk_rise) begin
                    if (sd2wb_fifo_wr_en) begin
                        sd2wb_state <= SD2WB_STATE_RESP1;
                    end
                end
            end
            SD2WB_STATE_RESP1: begin
                if (sd_clk_rise) begin
                    if (sd2wb_fifo_wr_en) begin
                        sd2wb_state <= SD2WB_STATE_RESP2;
                    end
                end
            end
            SD2WB_STATE_RESP2: begin
                if (sd_clk_rise) begin
                    if (sd2wb_fifo_wr_en) begin
                        sd2wb_state <= SD2WB_STATE_RESP3;
                    end
                end
            end
            SD2WB_STATE_RESP3: begin
                if (sd_clk_rise) begin
                    if (sd2wb_fifo_wr_en) begin
                        sd2wb_state <= SD2WB_STATE_CMD_ISR;
                    end
                end
            end
            SD2WB_STATE_CMD_ISR: begin
                if (sd_clk_rise) begin
                    if (sd2wb_fifo_wr_en) begin
                        cmd_int_status_reg_sd_clk_f <= cmd_int_status_reg_sd_clk;
                        sd2wb_state <= SD2WB_STATE_IDLE;
                    end
                end
            end
            SD2WB_STATE_DATA_ISR: begin
                if (sd_clk_rise) begin
                    if (sd2wb_fifo_wr_en) begin
                        data_int_status_reg_sd_clk_f <= data_int_status_reg_sd_clk;
                        sd2wb_state <= SD2WB_STATE_IDLE;
                    end
                end
            end
        endcase
    end
end

always_comb begin
    case (sd2wb_state)
        SD2WB_STATE_RESP0: begin
            sd2wb_fifo_din = {`resp0, response_0_reg_sd_clk};
            sd2wb_fifo_wr_en = ~sd2wb_fifo_full & sd_clk_rise;
        end
        SD2WB_STATE_RESP1: begin
            sd2wb_fifo_din = {`resp1, response_1_reg_sd_clk};
            sd2wb_fifo_wr_en = ~sd2wb_fifo_full & sd_clk_rise;
        end
        SD2WB_STATE_RESP2: begin
            sd2wb_fifo_din = {`resp2, response_2_reg_sd_clk};
            sd2wb_fifo_wr_en = ~sd2wb_fifo_full & sd_clk_rise;
        end
        SD2WB_STATE_RESP3: begin
            sd2wb_fifo_din = {`resp3, response_3_reg_sd_clk};
            sd2wb_fifo_wr_en = ~sd2wb_fifo_full & sd_clk_rise;
        end
        SD2WB_STATE_CMD_ISR: begin
            sd2wb_fifo_din = {`cmd_isr, {(32 - `INT_CMD_SIZE){1'b0}}, cmd_int_status_reg_sd_clk};
            sd2wb_fifo_wr_en = ~sd2wb_fifo_full & sd_clk_rise;
        end
        SD2WB_STATE_DATA_ISR: begin
            sd2wb_fifo_din = {`data_isr, {(32 - `INT_DATA_SIZE){1'b0}}, data_int_status_reg_sd_clk};
            sd2wb_fifo_wr_en = ~sd2wb_fifo_full & sd_clk_rise;
        end
        default: begin
            sd2wb_fifo_din = 40'd0;
            sd2wb_fifo_wr_en = 1'b0;
        end
    endcase
end

assign m_wb_cti_o = 3'b000;
assign m_wb_bte_o = 2'b00;

assign int_cmd  =  |(cmd_int_status_reg_wb_clk & cmd_int_enable_reg_wb_clk);
assign int_data =  |(data_int_status_reg_wb_clk & data_int_enable_reg_wb_clk);

assign m_wb_sel_o = m_wb_cyc_o & m_wb_we_o ? wr_wbm_sel : 4'b1111;
assign m_wb_adr_o = {wbm_adr[31:2], 2'b00};

endmodule

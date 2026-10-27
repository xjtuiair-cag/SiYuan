// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_controller_wb.v
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

module sd_controller_wb
    import sy_pkg::*;
(
    // WISHBONE common
    input   logic                           wb_clk_i,     // WISHBONE clock
    input   logic                           wb_rst_i,     // WISHBONE reset
    input   logic[31:0]                     wb_dat_i,     // WISHBONE data input
    output  logic[31:0]                     wb_dat_o,     // WISHBONE data output

    // WISHBONE slave
    input   logic[7:0]                      wb_adr_i,     // WISHBONE address input
    input   logic[3:0]                      wb_sel_i,     // WISHBONE byte select input
    input   logic                           wb_we_i,      // WISHBONE write enable input
    input   logic                           wb_cyc_i,     // WISHBONE cycle input
    input   logic                           wb_stb_i,     // WISHBONE strobe input
    output  logic                           wb_ack_o,     // WISHBONE acknowledge output
    //Buss accessible registers
    output  logic[31:0]                     argument_reg,
    output  logic[`CMD_REG_SIZE-1:0]        command_reg,
    input   logic[31:0]                     response_0_reg,
    input   logic[31:0]                     response_1_reg,
    input   logic[31:0]                     response_2_reg,
    input   logic[31:0]                     response_3_reg,
    output  logic[0:0]                      software_reset_reg,
    output  logic[`CMD_TIMEOUT_W-1:0]       cmd_timeout_reg,
    output  logic[`DATA_TIMEOUT_W-1:0]      data_timeout_reg,
    output  logic[`BLKSIZE_W-1:0]           block_size_reg,
    output  logic[0:0]                      controll_setting_reg,
    input   logic[`INT_CMD_SIZE-1:0]        cmd_int_status_reg,
    output  logic[`INT_CMD_SIZE-1:0]        cmd_int_enable_reg,
    output  logic[7:0]                      clock_divider_reg,
    input   logic[`INT_DATA_SIZE-1:0]       data_int_status_reg,
    output  logic[`INT_DATA_SIZE-1:0]       data_int_enable_reg,
    output  logic[`BLKCNT_W-1:0]            block_count_reg,
    output  logic[31:0]                     dma_addr_reg,
    //Register Controll
    output  logic                           cmd_start,
    output  logic                           data_int_rst,
    output  logic                           cmd_int_rst,

    input   logic                           wb2sd_fifo_full,
    output  logic                           wb2sd_fifo_wr_en,
    output  logic[39:0]                     wb2sd_fifo_din
);
//======================================================================================================================
// Parameters
//======================================================================================================================
parameter voltage_controll_reg  = `SUPPLY_VOLTAGE_mV;
parameter capabilies_reg = 16'b0000_0000_0000_0000;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
logic we;

//======================================================================================================================
// Instance
//======================================================================================================================
assign we = wb_we_i && wb_stb_i && wb_cyc_i && wb_ack_o;
assign wb2sd_fifo_wr_en = we && (wb_adr_i == `argument     ||
                                 wb_adr_i == `reset        ||
                                 wb_adr_i == `command      ||
                                 wb_adr_i == `cmd_timeout  ||
                                 wb_adr_i == `data_timeout ||
                                 wb_adr_i == `blksize      ||
                                 wb_adr_i == `controller   ||
                                 wb_adr_i == `clock_d      ||
                                 wb_adr_i == `blkcnt       ||
                                 wb_adr_i == `dst_src_addr);
assign wb2sd_fifo_din = {wb_adr_i, wb_dat_i};

byte_en_reg #(32) argument_r(wb_clk_i, wb_rst_i, we && wb_adr_i == `argument, wb_sel_i, wb_dat_i, argument_reg);
byte_en_reg #(`CMD_REG_SIZE) command_r(wb_clk_i, wb_rst_i, we && wb_adr_i == `command, wb_sel_i[(`CMD_REG_SIZE-1)/8:0], wb_dat_i[`CMD_REG_SIZE-1:0], command_reg);
byte_en_reg #(1) reset_r(wb_clk_i, wb_rst_i, we && wb_adr_i == `reset, wb_sel_i[0], wb_dat_i[0], software_reset_reg);
byte_en_reg #(`CMD_TIMEOUT_W) cmd_timeout_r(wb_clk_i, wb_rst_i, we && wb_adr_i == `cmd_timeout, wb_sel_i[(`CMD_TIMEOUT_W-1)/8:0], wb_dat_i[`CMD_TIMEOUT_W-1:0], cmd_timeout_reg);
byte_en_reg #(`DATA_TIMEOUT_W) data_timeout_r(wb_clk_i, wb_rst_i, we && wb_adr_i == `data_timeout, wb_sel_i[(`DATA_TIMEOUT_W-1)/8:0], wb_dat_i[`DATA_TIMEOUT_W-1:0], data_timeout_reg);
byte_en_reg #(`BLKSIZE_W, `RESET_BLOCK_SIZE) block_size_r(wb_clk_i, wb_rst_i, we && wb_adr_i == `blksize, wb_sel_i[(`BLKSIZE_W-1)/8:0], wb_dat_i[`BLKSIZE_W-1:0], block_size_reg);
byte_en_reg #(1) controll_r(wb_clk_i, wb_rst_i, we && wb_adr_i == `controller, wb_sel_i[0], wb_dat_i[0], controll_setting_reg);
byte_en_reg #(`INT_CMD_SIZE) cmd_int_r(wb_clk_i, wb_rst_i, we && wb_adr_i == `cmd_iser, wb_sel_i[(`INT_CMD_SIZE-1)/8:0], wb_dat_i[`INT_CMD_SIZE-1:0], cmd_int_enable_reg);
byte_en_reg #(8) clock_d_r(wb_clk_i, wb_rst_i, we && wb_adr_i == `clock_d, wb_sel_i[0], wb_dat_i[7:0], clock_divider_reg);
byte_en_reg #(`INT_DATA_SIZE) data_int_r(wb_clk_i, wb_rst_i, we && wb_adr_i == `data_iser, wb_sel_i[(`INT_DATA_SIZE-1)/8:0], wb_dat_i[`INT_DATA_SIZE-1:0], data_int_enable_reg);
byte_en_reg #(`BLKCNT_W) block_count_r(wb_clk_i, wb_rst_i, we && wb_adr_i == `blkcnt, wb_sel_i[(`BLKCNT_W-1)/8:0], wb_dat_i[`BLKCNT_W-1:0], block_count_reg);
byte_en_reg #(32) dma_addr_r(wb_clk_i, wb_rst_i, we && wb_adr_i == `dst_src_addr, wb_sel_i[3:0], wb_dat_i, dma_addr_reg);

always_ff @(`DFF_CR(wb_clk_i,wb_rst_i)) begin
    if (`DFF_IS_R(wb_rst_i))begin
        wb_ack_o     <= 0;
        cmd_start    <= 0;
        data_int_rst <= 0;
        cmd_int_rst  <= 0;
    end else begin
        if (wb_stb_i & wb_cyc_i && wb_ack_o & wb_we_i) begin
            case (wb_adr_i)
                `argument: begin
                    cmd_start    <= 1;//only msb triggers xfer
                    cmd_int_rst  <= 0;
                    data_int_rst <= 0;
                end
                `cmd_isr: begin
                    cmd_start    <= 0;
                    cmd_int_rst  <= 1;
                    data_int_rst <= 0;
                end
                `data_isr: begin
                    cmd_start    <= 0;
                    cmd_int_rst  <= 0;
                    data_int_rst <= 1;
                end
                default: begin
                    cmd_start    <= 0;
                    cmd_int_rst  <= 0;
                    data_int_rst <= 0;
                end
            endcase
        end else begin
            cmd_start    <= 0;
            data_int_rst <= 0;
            cmd_int_rst  <= 0;
        end

        if (wb_stb_i & wb_cyc_i & ~wb_ack_o & ~wb2sd_fifo_full) begin
            wb_ack_o <= 1'b1;
        end else begin
            wb_ack_o <= 1'b0;
        end
    end
end

always_ff @(`DFF_CR(wb_clk_i,wb_rst_i))begin
    if (`DFF_IS_R(wb_rst_i)) begin
        wb_dat_o <= 0;
    end else begin
        if (wb_stb_i & wb_cyc_i) begin //CS
            case (wb_adr_i)
                `argument:      wb_dat_o <= argument_reg;
                `command:       wb_dat_o <= command_reg;
                `resp0:         wb_dat_o <= response_0_reg;
                `resp1:         wb_dat_o <= response_1_reg;
                `resp2:         wb_dat_o <= response_2_reg;
                `resp3:         wb_dat_o <= response_3_reg;
                `controller:    wb_dat_o <= controll_setting_reg;
                `blksize:       wb_dat_o <= block_size_reg;
                `voltage:       wb_dat_o <= voltage_controll_reg;
                `reset:         wb_dat_o <= software_reset_reg;
                `cmd_timeout:   wb_dat_o <= cmd_timeout_reg;
                `data_timeout:  wb_dat_o <= data_timeout_reg;
                `cmd_isr:       wb_dat_o <= cmd_int_status_reg;
                `cmd_iser:      wb_dat_o <= cmd_int_enable_reg;
                `clock_d:       wb_dat_o <= clock_divider_reg;
                `capa:          wb_dat_o <= capabilies_reg;
                `data_isr:      wb_dat_o <= data_int_status_reg;
                `blkcnt:        wb_dat_o <= block_count_reg;
                `data_iser:     wb_dat_o <= data_int_enable_reg;
                `dst_src_addr:  wb_dat_o <= dma_addr_reg;
            endcase
        end
    end
end

endmodule

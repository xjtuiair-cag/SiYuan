// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sd_data_master.v
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

module sd_data_master 
    import sy_pkg::*;
(
    // clk
    input   logic                       sys_clk,
    input   logic                       sys_rst,

    input   logic                       sd_clk_rise,
    // cmd
    input   logic                       start_tx_i,
    input   logic                       start_rx_i,
    input   logic[`DATA_TIMEOUT_W-1:0]  timeout_i,
    //Output to SD-Host Reg
    output  logic                       d_write_o,
    output  logic                       d_read_o,
    //From fifo filler
    input   logic                       tx_fifo_rd_en_i,
    input   logic                       tx_fifo_empty_i,
    input   logic                       rx_fifo_wr_en_i,
    input   logic                       rx_fifo_full_i,
    //SD-DATA_Host
    input   logic                       xfr_complete_i,
    input   logic                       crc_ok_i,
    //status output
    output  logic[`INT_DATA_SIZE-1:0]   int_status_o,
    input   logic                       int_status_rst_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================
parameter SIZE = 3;
parameter IDLE          = 3'b000;
parameter START_TX_FIFO = 3'b001;
parameter START_RX_FIFO = 3'b010;
parameter DATA_TRANSFER = 3'b100;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
logic [`DATA_TIMEOUT_W-1:0] timeout_reg;
logic [`DATA_TIMEOUT_W-1:0] watchdog;
logic                       tx_cycle;
logic [SIZE-1:0]            state;
logic [SIZE-1:0]            next_state;
logic                       trans_done;
//======================================================================================================================
// FSM
//======================================================================================================================
always_comb begin: FSM_COMBO
    case(state)
        IDLE: begin
            if (start_tx_i == 1'b1) begin
                next_state = START_TX_FIFO;
            end else if (start_rx_i == 1'b1) begin
                next_state = START_RX_FIFO;
            end else begin
                next_state = IDLE;
            end
        end
        START_TX_FIFO: begin
            if (!tx_fifo_empty_i && xfr_complete_i == 1'b0) begin
                next_state = DATA_TRANSFER;
            end else begin
                next_state = START_TX_FIFO;
            end
        end
        START_RX_FIFO: begin
            if (xfr_complete_i == 1'b0) begin
                next_state = DATA_TRANSFER;
            end else begin
                next_state = START_RX_FIFO;
            end
        end
        DATA_TRANSFER: begin
            if (trans_done) begin
                next_state = IDLE;
            end else begin
                next_state = DATA_TRANSFER;
            end
        end
        default: next_state = IDLE;
    endcase
end

always_ff @(`DFF_CR(sys_clk,sys_rst)) begin: FSM_SEQ
    if (`DFF_IS_R(sys_rst)) begin
        state <= IDLE;
    end else begin
        if (sd_clk_rise) begin
            state <= next_state;
        end
    end
end

//Output logic-----------------
always_ff @(`DFF_CR(sys_clk,sys_rst)) begin
    if (`DFF_IS_R(sys_rst)) begin
        d_write_o    <= 1'b0;
        d_read_o     <= 1'b0;
        trans_done   <= 1'b0;
        tx_cycle     <= 1'b0;
        int_status_o <= `INT_DATA_SIZE'h0;
        timeout_reg  <= `DATA_TIMEOUT_W'h0;
        watchdog     <= `DATA_TIMEOUT_W'h0;
    end else begin
        case(state)
            IDLE: begin
                if (sd_clk_rise) begin
                    d_write_o   <= 1'b0;
                    d_read_o    <= 1'b0;
                    trans_done  <= 1'b0;
                    tx_cycle    <= 1'b0;
                    timeout_reg <= timeout_i;
                    watchdog    <= `DATA_TIMEOUT_W'h0;
                end
            end
            START_RX_FIFO: begin
                if (sd_clk_rise) begin
                    tx_cycle <= 1'b0;
                    d_read_o <= 1'b1;
                end
            end
            START_TX_FIFO:  begin
                if (sd_clk_rise) begin
                    tx_cycle <= 1'b1;
                    if (!tx_fifo_empty_i) begin
                        d_write_o <= 1'b1;
                    end
                end
            end
            DATA_TRANSFER: begin
                if (sd_clk_rise) begin
                    d_read_o  <= 1'b0;
                    d_write_o <= 1'b0;
                    watchdog <= watchdog + `DATA_TIMEOUT_W'd1;
                    if ((!tx_cycle && rx_fifo_wr_en_i && rx_fifo_full_i) ||
                         (tx_cycle && tx_fifo_rd_en_i && tx_fifo_empty_i)) begin
                        if (!trans_done) begin
                            int_status_o[`INT_DATA_CFE] <= 1'b1;
                            int_status_o[`INT_DATA_EI]  <= 1'b1;
                        end
                        trans_done <= 1'b1;
                        //stop sd_data_serial_host
                        d_write_o <= 1'b1;
                        d_read_o  <= 1'b1;
                    end
                    if (timeout_reg && watchdog >= timeout_reg) begin
                        int_status_o[`INT_DATA_CTE] <= 1'b1;
                        int_status_o[`INT_DATA_EI]  <= 1'b1;
                        trans_done <= 1'b1;
                        //stop sd_data_serial_host
                        d_write_o <= 1'b1;
                        d_read_o  <= 1'b1;
                    end else if (xfr_complete_i) begin //Transfer complete
                        d_write_o  <= 1'b0;
                        d_read_o   <= 1'b0;
                        trans_done <= 1'b1;
                        if (!crc_ok_i)  begin //Wrong CRC and Data line free.
                            if (!trans_done) begin
                                int_status_o[`INT_DATA_CCRCE] <= 1'b1;
                                int_status_o[`INT_DATA_EI]    <= 1'b1;
                            end
                        end else if (crc_ok_i) begin //Data Line free
                            if (!trans_done) begin
                                int_status_o[`INT_DATA_CC] <= 1'b1;
                            end
                        end
                    end
                end
            end
        endcase
        if (int_status_rst_i) begin
            int_status_o <= `INT_DATA_SIZE'h0;
        end
    end
end

endmodule

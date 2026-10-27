// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sd_data_xfer_trig.v
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

module sd_data_xfer_trig 
    import sy_pkg::*;
(
    input   logic           sys_clk,
    input   logic           sys_rst,
    input   logic           sd_clk_rise,

    input   logic           cmd_with_data_start_i,
    input   logic           r_w_i,
    input   logic[`INT_CMD_SIZE-1:0] cmd_int_status_i,
    output  logic           start_tx_o,
    output  logic           start_rx_o
);
//======================================================================================================================
// Parameters
//======================================================================================================================
parameter SIZE = 2;
parameter IDLE             = 2'b00;
parameter WAIT_FOR_CMD_INT = 2'b01;
parameter TRIGGER_XFER     = 2'b10;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
logic               r_w_reg;
logic [SIZE-1:0]    state;
logic [SIZE-1:0]    next_state;

logic start_sd_clk;
always_ff @(`DFF_CR(sys_clk,sys_rst)) begin
    if (`DFF_IS_R(sys_rst)) begin
        start_sd_clk <= 1'b0;
    end else begin
        if (cmd_with_data_start_i) begin
            start_sd_clk <= 1'b1;
        end else if (sd_clk_rise) begin
            start_sd_clk <= 1'b0;
        end
    end
end

always_comb begin: FSM_COMBO
    case(state)
        IDLE: begin
            if (start_sd_clk & r_w_i) begin
                next_state <= TRIGGER_XFER;
            end else if (start_sd_clk) begin
                next_state <= WAIT_FOR_CMD_INT;
            end else begin
                next_state <= IDLE;
            end
        end
        WAIT_FOR_CMD_INT: begin
            if (cmd_int_status_i[`INT_CMD_CC]) begin
                next_state <= TRIGGER_XFER;
            end else if (cmd_int_status_i[`INT_CMD_EI]) begin
                next_state <= IDLE;
            end else begin
                next_state <= WAIT_FOR_CMD_INT;
            end
        end
        TRIGGER_XFER: begin
            next_state <= IDLE;
        end
        default: next_state <= IDLE;
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

always_ff @(`DFF_CR(sys_clk,sys_rst)) begin
    if (`DFF_IS_R(sys_rst)) begin
        start_tx_o <= 0;
        start_rx_o <= 0;
        r_w_reg <= 0;
    end else begin
        case(state)
            IDLE: begin
                if (sd_clk_rise) begin
                    start_tx_o <= 0;
                    start_rx_o <= 0;
                    r_w_reg <= r_w_i;
                end
            end
            WAIT_FOR_CMD_INT: begin
                if (sd_clk_rise) begin
                    start_tx_o <= 0;
                    start_rx_o <= 0;
                end
            end
            TRIGGER_XFER: begin
                if (sd_clk_rise) begin
                    start_tx_o <= ~r_w_reg;
                    start_rx_o <= r_w_reg;
                end
            end
            default:;
        endcase
    end
end

endmodule
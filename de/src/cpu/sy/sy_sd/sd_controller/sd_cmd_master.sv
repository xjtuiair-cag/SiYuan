// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sd_cmd_master.v
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

module sd_cmd_master
    import sy_pkg::*;
(
    // clock
    input   logic           sys_clk,
    input   logic           sys_rst,

    input   logic           sd_clk_rise,
    // cmd
    input   logic           start_i,
    input   logic           int_status_rst_i,
    output  logic[1:0]      setting_o,
    output  logic           start_xfr_o,
    output  logic           go_idle_o,
    output  logic[39:0]     cmd_o,
    input   logic[119:0]    response_i,
    input   logic           crc_ok_i,
    input   logic           index_ok_i,
    input   logic           finish_i,
    input   logic           busy_i, //direct signal from data sd data input (data[0])

    input   logic[31:0]                 argument_i,
    input   logic[`CMD_REG_SIZE-1:0]    command_i,
    input   logic[`CMD_TIMEOUT_W-1:0]   timeout_i,
    output  logic[`INT_CMD_SIZE-1:0]    int_status_o,
    output  logic[31:0] response_0_o,
    output  logic[31:0] response_1_o,
    output  logic[31:0] response_2_o,
    output  logic[31:0] response_3_o
);
//======================================================================================================================
// Parameters
//======================================================================================================================
parameter SIZE = 2;
parameter IDLE       = 2'b00;
parameter EXECUTE    = 2'b01;
parameter BUSY_CHECK = 2'b10;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
logic [`CMD_TIMEOUT_W-1:0]  timeout_reg;
logic                       crc_check;
logic                       index_check;
logic                       busy_check;
logic                       expect_response;
logic                       long_response;
logic [`INT_CMD_SIZE-1:0]   int_status_reg;
//reg card_present;
//reg [3:0]debounce;
logic [`CMD_TIMEOUT_W-1:0]  watchdog;
logic [SIZE-1:0]            state;
logic [SIZE-1:0]            next_state;

assign setting_o[1:0] = {long_response, expect_response};
assign int_status_o = state == IDLE ? int_status_reg : 5'h0;


logic start_sd_clk;
always_ff @(`DFF_CR(sys_clk,sys_rst)) begin
    if (`DFF_IS_R(sys_rst)) begin
        start_sd_clk <= 1'b0;
    end else begin
        if (start_i) begin
            start_sd_clk <= 1'b1;
        end else if (sd_clk_rise) begin
            start_sd_clk <= 1'b0;
        end
    end
end
//---------------Input ports---------------
always_comb begin
    case(state)
        IDLE: begin
            if (start_sd_clk) begin
                next_state = EXECUTE;
            end else begin
                next_state = IDLE;
            end
        end
        EXECUTE: begin
            if ((finish_i && !busy_check) || go_idle_o) begin
                next_state = IDLE;
            end else if (finish_i && busy_check) begin
                next_state = BUSY_CHECK;
            end else begin
                next_state = EXECUTE;
            end
        end
        BUSY_CHECK: begin
            if (!busy_i) begin
                next_state = IDLE;
            end else begin
                next_state = BUSY_CHECK;
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

always_ff @(`DFF_CR(sys_clk,sys_rst)) begin
    if (`DFF_IS_R(sys_rst)) begin
        crc_check       <= 1'b0;
        response_0_o    <= 32'h0;
        response_1_o    <= 32'h0;
        response_2_o    <= 32'h0;
        response_3_o    <= 32'h0;
        int_status_reg  <= `INT_CMD_SIZE'h0;
        expect_response <= 1'b0;
        long_response   <= 1'b0;
        cmd_o           <= 40'h0;
        start_xfr_o     <= 1'b0;
        index_check     <= 1'b0;
        busy_check      <= 1'b0;
        watchdog        <= `CMD_TIMEOUT_W'h0;
        timeout_reg     <= `CMD_TIMEOUT_W'h0;
        go_idle_o       <= 1'b0;
    end else begin
        case(state)
            IDLE: begin
                if (sd_clk_rise) begin
                    go_idle_o   <= 1'b0;
                    index_check <= command_i[`CMD_IDX_CHECK];
                    crc_check   <= command_i[`CMD_CRC_CHECK];
                    busy_check  <= command_i[`CMD_BUSY_CHECK];
                    if (command_i[`CMD_RESPONSE_CHECK]  == 2'b10 || command_i[`CMD_RESPONSE_CHECK] == 2'b11) begin
                        expect_response <=  1'b1;
                        long_response <= 1'b1;
                    end else if (command_i[`CMD_RESPONSE_CHECK] == 2'b01) begin
                        expect_response <= 1'b1;
                        long_response <= 1'b0;
                    end else begin
                        expect_response <= 1'b0;
                        long_response <= 1'b0;
                    end
                    cmd_o[39:38] <= 2'b01;
                    cmd_o[37:32] <= command_i[`CMD_INDEX];  //CMD_INDEX
                    cmd_o[31:0] <= argument_i; //CMD_Argument
                    timeout_reg <= timeout_i;
                    watchdog <= 0;
                    if (start_sd_clk) begin
                        start_xfr_o <= 1'b1;
                        int_status_reg <= `INT_CMD_SIZE'h0;
                    end
                end
            end
            EXECUTE: begin
                if (sd_clk_rise) begin
                    start_xfr_o <= 1'b0;
                    watchdog <= watchdog + `CMD_TIMEOUT_W'd1;
                    if (timeout_reg && watchdog >= timeout_reg) begin
                        int_status_reg[`INT_CMD_CTE] <= 1'b1;
                        int_status_reg[`INT_CMD_EI] <= 1'b1;
                        go_idle_o <= 1'b1;
                    end else begin //if ( req_in_int == 1) begin
                        //Incoming New Status
                        if (finish_i) begin //Data avaible
                            if (crc_check & !crc_ok_i) begin
                                int_status_reg[`INT_CMD_CCRCE] <= 1'b1;
                                int_status_reg[`INT_CMD_EI] <= 1'b1;
                            end
                            if (index_check & !index_ok_i) begin
                                int_status_reg[`INT_CMD_CIE] <= 1'b1;
                                int_status_reg[`INT_CMD_EI] <= 1'b1;
                            end
                            int_status_reg[`INT_CMD_CC] <= 1'b1;
                            if (expect_response != 0) begin
                                response_0_o <= response_i[119:88];
                                response_1_o <= response_i[87:56];
                                response_2_o <= response_i[55:24];
                                response_3_o <= {response_i[23:0], 8'h00};
                            end
                            // end
                        end ////Data avaible
                    end //Status change
                end
            end //EXECUTE state
            BUSY_CHECK: begin
                if (sd_clk_rise) begin
                    start_xfr_o <= 1'b0;
                    go_idle_o <= 1'b0;
                end
            end
        endcase
        if (int_status_rst_i) begin
            int_status_reg <= `INT_CMD_SIZE'h0;
        end
    end
end

endmodule

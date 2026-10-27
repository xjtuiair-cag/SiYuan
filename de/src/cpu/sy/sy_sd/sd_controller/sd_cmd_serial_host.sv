// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sd_cmd_serial_host.v
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

module sd_cmd_serial_host 
    import sy_pkg::*;
(
    // clock
    input   logic           sys_clk,
    input   logic           sys_rst,
    input   logic           sd_clk_rise, 
    input   logic           sd_clk_fall, 
    // cmd
    input   logic[1:0]      setting_i,
    input   logic[39:0]     cmd_i,
    input   logic           start_i,
    output  logic[119:0]    response_o,
    output  logic           finish_o,
    output  logic           crc_ok_o,
    output  logic           index_ok_o,
    // to SD card
    input   logic           cmd_dat_i,
    output  logic           cmd_oe_o,
    output  logic           cmd_out_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================
parameter INIT_DELAY = 4;
parameter BITS_TO_SEND = 48;
parameter CMD_SIZE = 40;
parameter RESP_SIZE = 128;

//-State Machine
parameter STATE_SIZE = 10;
typedef enum reg [STATE_SIZE-1:0] {
    INIT        = 10'h00,
    IDLE        = 10'h01,
    SETUP_CRC   = 10'h02,
    WRITE       = 10'h04,
    READ_WAIT   = 10'h08,
    READ        = 10'h10,
    FINISH_WR   = 10'h20,
    FINISH_WO   = 10'h40
} state_t;
state_t state, next_state;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
//---------------Internal variable-----------
// (* iob="true" *) reg cmd_dat_reg;
logic       cmd_dat_reg;
logic       cmd_out_o_reg;
logic       cmd_oe_o_reg;
logic [7:0] resp_len;
logic       with_response;
logic [CMD_SIZE-1:0] cmd_buff;
logic [RESP_SIZE-1:0] resp_buff;
logic [6:0] resp_idx;
//CRC
logic           crc_rst;
logic [6:0]     crc_in;
logic [6:0]     crc_val;
logic           crc_enable;
logic           crc_bit;
logic           crc_ok;
//-Internal Counterns
logic [7:0]     counter;
// integer         counter;

//Misc
`define cmd_idx  (CMD_SIZE-1-counter)

//======================================================================================================================
// Instance
//======================================================================================================================
//sd cmd input pad register
// always @(posedge sd_clk) begin
//     cmd_dat_reg <= cmd_dat_i;
// end

always @(posedge sys_clk) begin
    if (sd_clk_rise) begin
        cmd_dat_reg <= cmd_dat_i;
    end 
end


//launch on falling edge
always @(posedge sys_clk) begin
    if (sd_clk_fall) begin
        cmd_oe_o    <= cmd_oe_o_reg;
        cmd_out_o   <= cmd_out_o_reg;
    end 
end

sd_crc_7 crc7(
   .CLK     (sys_clk),                            
   .RST     (sys_rst),                            
   .BITVAL  (crc_bit),                            
   .ENABLE  (crc_enable & sd_clk_rise),                         
   .CLEAR   (crc_rst),                            
   .CRC     (crc_val)
);             
//------------------------------------------
always_comb begin: FSM_COMBO
    case(state)
        INIT: begin
            if (counter >= INIT_DELAY) begin
                next_state <= IDLE;
            end else begin
                next_state <= INIT;
            end
        end
        IDLE: begin
            if (start_i) begin
                next_state <= SETUP_CRC;
            end else begin
                next_state <= IDLE;
            end
        end
        SETUP_CRC: begin
            next_state <= WRITE;
        end
        WRITE: begin
            if (counter >= BITS_TO_SEND && with_response) begin
                next_state <= READ_WAIT;
            end else if (counter >= BITS_TO_SEND) begin
                next_state <= FINISH_WO;
            end else begin
                next_state <= WRITE;
            end
        end
        READ_WAIT: begin
            if (!cmd_dat_reg) begin
                next_state <= READ;
            end else begin
                next_state <= READ_WAIT;
            end
        end
        FINISH_WO: begin
            next_state <= IDLE;
        end
        READ: begin
            if (counter >= resp_len+8) begin
                next_state <= FINISH_WR;
            end else begin
                next_state <= READ;
            end
        end
        FINISH_WR: begin
            next_state <= IDLE;
        end
        default:
            next_state <= INIT;
    endcase
end

always_ff @(`DFF_CR(sys_clk,sys_rst)) begin: COMMAND_DECODER
    if (`DFF_IS_R(sys_rst)) begin
        resp_len        <= 8'h0;
        with_response   <= 1'b0;
        cmd_buff        <= CMD_SIZE'(0);
    end else begin
        if (start_i & sd_clk_rise) begin
            resp_len        <= setting_i[1] ? 127 : 39;
            with_response   <= setting_i[0];
            cmd_buff        <= cmd_i;
        end
    end
end

always_ff @(`DFF_CR(sys_clk,sys_rst)) begin: FSM_SEQ
    if (`DFF_IS_R(sys_rst)) begin
        state <= INIT;
    end else begin
        if (sd_clk_rise) begin
            state <= next_state;
        end
    end
end

//-------------OUTPUT_LOGIC-------
always_ff @(`DFF_CR(sys_clk,sys_rst)) begin: FSM_OUT
    if (`DFF_IS_R(sys_rst)) begin
        crc_enable      <= 1'b0;
        resp_idx        <= 7'h0;
        counter         <= 8'h0;
        cmd_oe_o_reg    <= 1'b1;
        cmd_out_o_reg   <= 1'b1;
        resp_buff       <= RESP_SIZE'(0);
        finish_o        <= 1'b0;
        crc_rst         <= 1'b1;
        crc_bit         <= 1'b0;
        crc_in          <= 7'h0;
        response_o      <= 120'h0;
        index_ok_o      <= 1'b0;
        crc_ok_o        <= 1'b0;
        crc_ok          <= 1'b0;
    end else begin
        case(state)
            INIT: begin
                if (sd_clk_rise) begin
                    counter         <= counter + 1'b1;
                    cmd_oe_o_reg    <= 1'b1;
                    cmd_out_o_reg   <= 1'b1;
                end
            end
            IDLE: begin
                if (sd_clk_rise) begin
                    cmd_oe_o_reg <= 1'b0;      //Put CMD to Z
                    counter      <= 8'h0;
                    crc_rst      <= 1'b1;
                    crc_enable   <= 1'b0;
                    response_o   <= 120'h0;
                    resp_idx     <= 7'h0;
                    crc_ok_o     <= 1'b0;
                    index_ok_o   <= 1'b0;
                    finish_o     <= 1'b0;
                end
            end
            SETUP_CRC: begin
                if (sd_clk_rise) begin
                    crc_rst     <= 1'b0;
                    crc_enable  <= 1'b1;
                    crc_bit     <= cmd_buff[`cmd_idx];
                end
            end
            WRITE: begin
                if (sd_clk_rise) begin
                    if (counter < BITS_TO_SEND-8) begin  // 1->40 CMD, (41 >= CNT && CNT <=47) CRC, 48 stop_bit
                        cmd_oe_o_reg    <= 1'b1;
                        cmd_out_o_reg   <= cmd_buff[`cmd_idx];
                        if (counter < BITS_TO_SEND-9) begin //1 step ahead
                            crc_bit <= cmd_buff[`cmd_idx-1];
                        end else begin
                            crc_enable <= 1'b0;
                        end
                    end else if (counter < BITS_TO_SEND-1) begin
                        cmd_oe_o_reg  <= 1'b1;
                        crc_enable    <= 1'b0;
                        cmd_out_o_reg <= crc_val[BITS_TO_SEND-counter-2];
                    end else if (counter == BITS_TO_SEND-1) begin
                        cmd_oe_o_reg  <= 1'b1;
                        cmd_out_o_reg <= 1'b1;
                    end else begin
                        cmd_oe_o_reg  <= 1'b0;
                        cmd_out_o_reg <= 1'b1;
                    end
                    // incr counter
                    counter <= counter + 1'b1;
                end
            end
            READ_WAIT: begin
                if (sd_clk_rise) begin
                    crc_enable  <= 1'b0;
                    crc_rst     <= 1'b1;
                    counter     <= 8'h1;
                    cmd_oe_o_reg <= 1'b0;
                    resp_buff[RESP_SIZE-1] <= cmd_dat_reg;
                end
            end
            FINISH_WO: begin
                if (sd_clk_rise) begin
                    finish_o    <= 1'b1;
                    crc_enable  <= 1'b0;
                    crc_rst     <= 1'b1;
                    counter     <= 8'h0;
                    cmd_oe_o_reg <= 1'b0;
                end
            end
            READ: begin
                if (sd_clk_rise) begin
                    crc_rst <= 1'b0;
                    crc_enable <= (resp_len != RESP_SIZE-1 || counter > 7);
                    cmd_oe_o_reg <= 1'b0;
                    if (counter <= resp_len) begin
                        if (counter < 8) //1+1+6 (S,T,Index)
                            resp_buff[RESP_SIZE-1-counter] <= cmd_dat_reg;
                        else begin
                            resp_idx <= resp_idx + 1;
                            resp_buff[RESP_SIZE-9-resp_idx] <= cmd_dat_reg;
                        end
                        crc_bit <= cmd_dat_reg;
                    end else if (counter-resp_len <= 7) begin
                        crc_in[(resp_len+7)-(counter)] <= cmd_dat_reg;
                        crc_enable <= 1'b0;
                    end else begin
                        crc_enable <= 1'b0;
                        if (crc_in == crc_val) begin
                            crc_ok <= 1'b1;
                        end else begin 
                            crc_ok <= 1'b0;
                        end
                    end
                    counter <= counter + 1'b1;
                end
            end
            FINISH_WR: begin
                if (sd_clk_rise) begin
                    if (cmd_buff[37:32] == resp_buff[125:120]) begin
                        index_ok_o <= 1'b1;
                    end else begin
                        index_ok_o <= 1'b0;
                    end
                    crc_ok_o    <= crc_ok;
                    finish_o    <= 1'b1;
                    crc_enable  <= 1'b0;
                    crc_rst     <= 1'b1;
                    counter     <= 8'h0;
                    cmd_oe_o_reg <= 1'b0;
                    response_o <= resp_buff[119:0];
                end
            end
        endcase
    end
end

endmodule



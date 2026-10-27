// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sd_data_serial_host.v
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

module sd_data_serial_host
    import sy_pkg::*;
(
    input   logic                   sys_clk,
    input   logic                   sys_rst,
    input   logic                   sd_clk_rise,
    input   logic                   sd_clk_fall,
    //Tx Fifo
    input   logic[31:0]             rd_data_in,
    output  logic                   rd_fifo,
    //Rx Fifo
    output  logic[31:0]             wr_data_out,
    output  logic                   wr_fifo,
    //tristate data
    // (* iob="true" *) output reg DAT_oe_o,
    // (* iob="true" *) output reg[3:0] DAT_dat_o,
    output  logic                   DAT_oe_o,
    output  logic[3:0]              DAT_dat_o,
    input   logic[3:0]              DAT_dat_i,
    //Controll signals
    input   logic[`BLKSIZE_W-1:0]   blksize,
    input   logic                   bus_4bit,
    input   logic[`BLKCNT_W-1:0]    blkcnt,
    input   logic[1:0]              start,
    input   logic[1:0]              byte_alignment,
    output  logic                   sd_data_busy,
    output  logic                   busy,
    output  logic                   crc_ok
);
//======================================================================================================================
// Parameters
//======================================================================================================================
parameter  SIZE = 6;
localparam IDLE       = 6'b000001;
localparam WRITE_DAT  = 6'b000010;
localparam WRITE_PREP = 6'b000011;
localparam WRITE_CRC  = 6'b000100;
localparam WRITE_BUSY = 6'b001000;
localparam READ_WAIT  = 6'b010000;
localparam READ_DAT   = 6'b100000;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
// (* iob="true" *) reg [3:0] DAT_dat_reg;
logic [3:0]                 DAT_dat_reg;
logic [3:0]                 DAT_dat_o_reg;
logic                       DAT_oe_o_reg;
logic [`BLKSIZE_W-1+3:0]    data_cycles;
logic                       bus_4bit_reg;
//CRC16
logic [3:0]                 crc_in;
logic                       crc_en;
logic                       crc_rst;
logic [15:0]                crc_out [3:0];
logic [`BLKSIZE_W-1+4:0]    transf_cnt;
logic [SIZE-1:0]            state;
logic [SIZE-1:0]            next_state;
logic [2:0]                 crc_status;
logic                       busy_int;
logic [`BLKCNT_W-1:0]       blkcnt_reg;
logic [1:0]                 byte_alignment_reg;
logic [`BLKSIZE_W-1:0]      blksize_reg;
logic                       next_block;
logic                       start_bit;
logic [4:0]                 crc_c;
logic [3:0]                 last_din;
logic [2:0]                 crc_s;
logic [4:0]                 data_index;
logic                       rd;
logic                       we;
logic [31:0]                data_out;
logic [31:0]                data_in;
//======================================================================================================================
// Instance
//======================================================================================================================
//sd data input pad register
always_ff @(posedge sys_clk) begin
    if (sd_clk_rise) begin
        DAT_dat_reg <= DAT_dat_i;
    end
end

// launch on falling edge
always_ff @(posedge sys_clk) begin
    if (sd_clk_fall) begin
        DAT_oe_o    <= DAT_oe_o_reg;
        DAT_dat_o   <= DAT_dat_o_reg;
    end
end

genvar i;
generate
    for(i=0; i<4; i=i+1) begin: CRC_16_gen
        sd_crc_16 crc16(
           .CLK         (sys_clk),
           .RST         (sys_rst),

           .BITVAL      (crc_in[i]),            
           .ENABLE      (crc_en & sd_clk_rise),               
           .CLEAR       (crc_rst),              
           .CRC         (crc_out[i])           
        );
    end
endgenerate

assign busy = (state != IDLE);
assign start_bit    = !DAT_dat_reg[0];
assign sd_data_busy = !DAT_dat_reg[0];

always_comb begin: FSM_COMBO
    case(state)
        IDLE: begin
            if (start == 2'b01) begin
                next_state = WRITE_PREP;
            end else if  (start == 2'b10) begin
                next_state = READ_WAIT;
            end else begin
                next_state = IDLE;
            end
        end
        WRITE_PREP: begin
            next_state = WRITE_DAT;    // assuming 1-cycle FIFO read delay, non-first-word-fall-through FIFO
        end
        WRITE_DAT: begin
            if (transf_cnt >= data_cycles+21 && start_bit) begin
                next_state = WRITE_CRC;
            end else begin
                next_state = WRITE_DAT;
            end
        end
        WRITE_CRC: begin
            if (crc_status == 3) begin
                next_state = WRITE_BUSY;
            end else begin
                next_state = WRITE_CRC;
            end
        end
        WRITE_BUSY: begin
            if (!busy_int && next_block && crc_ok) begin
                next_state = WRITE_DAT;
            end else if (!busy_int) begin
                next_state = IDLE;
            end else begin
                next_state = WRITE_BUSY;
            end
        end
        READ_WAIT: begin
            if (start_bit) begin
                next_state = READ_DAT;
            end else begin
                next_state = READ_WAIT;
            end
        end
        READ_DAT: begin
            if (transf_cnt == data_cycles+17 && next_block && crc_ok) begin
                next_state = READ_WAIT;
            end else if (transf_cnt == data_cycles+17) begin
                next_state = IDLE;
            end else begin
                next_state = READ_DAT;
            end
        end
        default: next_state = IDLE;
    endcase
    //abort
    if (start == 2'b11) begin
        next_state = IDLE;
    end
end

assign rd_fifo = rd && sd_clk_rise;
assign wr_fifo = we && sd_clk_rise;

logic rd_fifo_dly;
always_ff @(posedge sys_clk) begin
    rd_fifo_dly <= rd_fifo;
end
 
always_ff @(`DFF_CR(sys_clk,sys_rst)) begin
    if (`DFF_IS_R(sys_rst)) begin
        data_in <= 32'b0;
    end else begin
        if (rd_fifo_dly) begin
            data_in <= rd_data_in;
        end
    end
end
assign wr_data_out = data_out;
 
always_ff @(`DFF_CR(sys_clk,sys_rst)) begin: FSM_OUT
    if (`DFF_IS_R(sys_rst)) begin
        state           <= IDLE;
        DAT_oe_o_reg    <= 1'b0;
        crc_en          <= 1'b0;
        crc_rst         <= 1'b1;
        transf_cnt      <= (`BLKSIZE_W+4)'(0);
        crc_c           <= 5'd15;
        rd              <= 1'b0;
        last_din        <= 4'h0;
        crc_c           <= 5'h0;
        crc_in          <= 4'h0;
        DAT_dat_o_reg   <= 4'h0;
        crc_status      <= 3'h0;
        crc_s           <= 3'h0;
        we              <= 1'b0;
        data_out        <= 32'h0;
        crc_ok          <= 1'b0;
        busy_int        <= 1'b0;
        data_index      <= 5'h0;
        next_block      <= 1'b0;
        blkcnt_reg      <= `BLKCNT_W'd0;
        byte_alignment_reg <= 2'h0;
        blksize_reg     <= `BLKSIZE_W'd0;
        data_cycles     <= (`BLKSIZE_W+3)'(0);
        bus_4bit_reg    <= 1'b0;
    end else begin
        if (sd_clk_rise) begin
            state <= next_state;
        end
        case(state)
            IDLE: begin
                if (sd_clk_rise) begin
                    DAT_oe_o_reg    <= 1'b0;
                    DAT_dat_o_reg   <= 4'b1111;
                    crc_en          <= 1'b0;
                    crc_rst         <= 1'b1;
                    transf_cnt      <= (`BLKSIZE_W+4)'(0);
                    crc_c           <= 5'd16;
                    crc_status      <= 3'h0;
                    crc_s           <= 3'h0;
                    we              <= 1'b0;
                    rd              <= 1'b0;
                    data_index      <= 5'h0;
                    next_block      <= 1'b0;
                    blkcnt_reg      <= blkcnt;
                    byte_alignment_reg <= byte_alignment;
                    blksize_reg     <= blksize;
                    data_cycles     <= (bus_4bit ? (blksize << 1) + `BLKSIZE_W'd2 : (blksize << 3) + `BLKSIZE_W'd8);
                    bus_4bit_reg    <= bus_4bit;
                end
            end
            WRITE_PREP: begin
                if (sd_clk_rise) begin
                    DAT_oe_o_reg    <= 1'b0;
                    DAT_dat_o_reg   <= 4'b1111;
                    crc_en          <= 1'b0;
                    crc_rst         <= 1'b1;
                    transf_cnt      <= (`BLKSIZE_W+4)'(0);
                    crc_c           <= 5'd16;
                    crc_status      <= 3'h0;
                    crc_s           <= 3'h0;
                    we              <= 1'b0;
                    data_index      <= 5'h0;
                    next_block      <= 1'b0;
                    rd              <= 1'b1;
                end
            end
            WRITE_DAT: begin
                if (sd_clk_rise) begin
                    crc_ok      <= 1'b0;
                    next_block  <= 1'b0;
                    rd          <= 1'b0;
                    // incr trans cnt
                    transf_cnt  <= transf_cnt + 16'h1;
                    //special case
                    if (transf_cnt == 0 && byte_alignment_reg == 2'b11 && bus_4bit_reg) begin
                        rd <= 1'b1;
                    end else if (transf_cnt == 1) begin
                        crc_rst <= 1'b0;
                        crc_en  <= 1'b1;
                        if (bus_4bit_reg) begin
                            last_din <= {
                                data_in[31-(byte_alignment_reg << 3)],
                                data_in[30-(byte_alignment_reg << 3)],
                                data_in[29-(byte_alignment_reg << 3)],
                                data_in[28-(byte_alignment_reg << 3)]
                                };
                            crc_in <= {
                                data_in[31-(byte_alignment_reg << 3)],
                                data_in[30-(byte_alignment_reg << 3)],
                                data_in[29-(byte_alignment_reg << 3)],
                                data_in[28-(byte_alignment_reg << 3)]
                                };
                        end else begin
                            last_din <= {3'h7, data_in[31-(byte_alignment_reg << 3)]};
                            crc_in   <= {3'h7, data_in[31-(byte_alignment_reg << 3)]};
                        end
                        DAT_oe_o_reg <= 1'b1;
                        DAT_dat_o_reg <= bus_4bit_reg ? 4'h0 : 4'he;
                        data_index <= bus_4bit_reg ? {2'b00, byte_alignment_reg, 1'b1} : {byte_alignment_reg, 3'b001};
                    end else if ((transf_cnt >= 2) && (transf_cnt <= data_cycles+1)) begin
                        DAT_oe_o_reg <= 1'b1;
                        if (bus_4bit_reg) begin
                            last_din <= {
                                data_in[31-(data_index[2:0]<<2)],
                                data_in[30-(data_index[2:0]<<2)],
                                data_in[29-(data_index[2:0]<<2)],
                                data_in[28-(data_index[2:0]<<2)]
                                };
                            crc_in <= {
                                data_in[31-(data_index[2:0]<<2)],
                                data_in[30-(data_index[2:0]<<2)],
                                data_in[29-(data_index[2:0]<<2)],
                                data_in[28-(data_index[2:0]<<2)]
                                };
                            if (data_index[2:0] == 3'h6/*not 7 - read delay !!!*/ && transf_cnt <= data_cycles-8) begin
                                rd <= 1'b1;
                            end
                        end else begin
                            last_din <= {3'h7, data_in[31-data_index]};
                            crc_in   <= {3'h7, data_in[31-data_index]};
                            if (data_index == 30/*not 31 - read delay !!!*/) begin
                                rd <= 1'b1;
                            end
                        end
                        data_index    <= data_index + 5'h1;
                        DAT_dat_o_reg <= last_din;
                        if (transf_cnt == data_cycles+1) begin
                            crc_en <= 1'b0;
                        end
                    end else if (transf_cnt > data_cycles+1 & crc_c!=0) begin
                        crc_en <= 1'b0;
                        crc_c  <= crc_c - 5'h1;
                        DAT_oe_o_reg <= 1'b1;
                        DAT_dat_o_reg[0] <= crc_out[0][crc_c-1];
                        if (bus_4bit_reg) begin
                            DAT_dat_o_reg[3:1] <= {crc_out[3][crc_c-1], crc_out[2][crc_c-1], crc_out[1][crc_c-1]};
                        end else begin
                            DAT_dat_o_reg[3:1] <= {3'h7};
                        end
                    end else if (transf_cnt == data_cycles+18) begin
                        DAT_oe_o_reg <= 1'b1;
                        DAT_dat_o_reg <= 4'hf;
                    end else if (transf_cnt >= data_cycles+19) begin
                        DAT_oe_o_reg <= 1'b0;
                    end
                end
            end
            WRITE_CRC: begin
                if (sd_clk_rise) begin
                    DAT_oe_o_reg <= 1'b0;
                    if (crc_status < 3) begin
                        crc_s[crc_status] <= DAT_dat_reg[0];
                    end
                    crc_status <= crc_status + 3'h1;
                    busy_int <= 1'b1;
                end
            end
            WRITE_BUSY: begin
                if (sd_clk_rise) begin
                    if (crc_s == 3'b010) begin
                        crc_ok <= 1'b1;
                    end else begin
                        crc_ok <= 1'b0;
                    end
                    busy_int   <= !DAT_dat_reg[0];
                    next_block <= (blkcnt_reg != 0);
                    if (next_state != WRITE_BUSY) begin
                        blkcnt_reg <= blkcnt_reg - `BLKCNT_W'h1;
                        byte_alignment_reg <= byte_alignment_reg + blksize_reg[1:0] + 2'b1;
                        crc_rst <= 1'b1;
                        crc_c <= 5'd16;
                        crc_status <= 3'h0;
                    end
                    transf_cnt <= (`BLKSIZE_W+4)'(0);
                end
            end
            READ_WAIT: begin
                if (sd_clk_rise) begin
                    DAT_oe_o_reg <= 1'b0;
                    crc_rst <= 1'b0;
                    crc_en <= 1'b1;
                    crc_in <= 4'h0;
                    crc_c <= 5'd15;// end
                    next_block <= 1'b0;
                    transf_cnt <= (`BLKSIZE_W+4)'(0);
                    data_index <= bus_4bit_reg ? (byte_alignment_reg << 1) : (byte_alignment_reg << 3);
                end
            end
            READ_DAT: begin
                if (sd_clk_rise) begin
                    if (transf_cnt < data_cycles) begin
                        if (bus_4bit_reg) begin
                            we <= (data_index[2:0] == 7 || (transf_cnt == data_cycles-1  && !blkcnt_reg));
                            data_out[31-(data_index[2:0]<<2)] <= DAT_dat_reg[3];
                            data_out[30-(data_index[2:0]<<2)] <= DAT_dat_reg[2];
                            data_out[29-(data_index[2:0]<<2)] <= DAT_dat_reg[1];
                            data_out[28-(data_index[2:0]<<2)] <= DAT_dat_reg[0];
                        end else begin
                            we <= (data_index == 31 || (transf_cnt == data_cycles-1  && !blkcnt_reg));
                            data_out[31-data_index] <= DAT_dat_reg[0];
                        end
                        crc_in <= DAT_dat_reg;
                        crc_ok <= 1'b1;

                        transf_cnt <= transf_cnt + 16'h1;
                        data_index <= data_index + 5'h1;
                    end else if (transf_cnt <= data_cycles+16) begin
                        transf_cnt <= transf_cnt + 16'h1;
                        crc_en <= 1'b0;
                        last_din <= DAT_dat_reg;
                        we <= 1'b0;
                        if (transf_cnt > data_cycles) begin
                            crc_c <= crc_c - 5'h1;
                            if  (crc_out[0][crc_c] != last_din[0]) begin
                                crc_ok <= 1'b0;
                            end
                            if  (crc_out[1][crc_c] != last_din[1] && bus_4bit_reg) begin
                                crc_ok <= 1'b0;
                            end
                            if  (crc_out[2][crc_c] != last_din[2] && bus_4bit_reg) begin
                                crc_ok <= 1'b0;
                            end
                            if  (crc_out[3][crc_c] != last_din[3] && bus_4bit_reg) begin
                                crc_ok <= 1'b0;
                            end
                            if (crc_c == 0 ) begin
                                next_block <= (blkcnt_reg != 0);
                                blkcnt_reg <= blkcnt_reg - `BLKCNT_W'h1;
                                byte_alignment_reg <= byte_alignment_reg + blksize_reg[1:0] + 2'b1;
                                crc_rst <= 1'b1;
                            end
                        end
                    end
                end
            end
        endcase
    end
end

endmodule
// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sd_trans_manager.v
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

module sd_trans_manager
    import sy_pkg::*;
(
    input   logic                       clk,
    input   logic                       rst,

    // Request Slave
    input   logic [`SD_ADDR_WIDTH-1:0]  req_addr_sd, // addr in SD 
    input   logic [`SD_ADDR_WIDTH-1:0]  req_addr_dma, // addr in fake memory
    input   logic [`SD_ADDR_WIDTH-10:0] req_blkcnt,
    input   logic                       req_wr, // HIGH write; LOW read.
    input   logic                       req_val,
    output  logic                       req_rdy,
    output  logic [`SD_ADDR_WIDTH-1:0]  req_addr_sd_f,
    output  logic [`SD_ADDR_WIDTH-1:0]  req_addr_dma_f,
    // Response Master
    output  logic                       resp_ok, // HIGH ok; LOW err.
    output  logic                       resp_val,
    input   logic                       resp_rdy,
    // Wishbone Master Channels         
    output  logic [31:0]                m_wb_dat_o,
    input   logic [31:0]                m_wb_dat_i,
    output  logic [7:0]                 m_wb_adr_o,
    output  logic [3:0]                 m_wb_sel_o,
    output  logic                       m_wb_we_o,
    output  logic                       m_wb_cyc_o,
    output  logic                       m_wb_stb_o,
    input   logic                       m_wb_ack_i,
    // SD controller interrupt  engine
    input   logic                       sd_int_cmd,
    input   logic                       sd_int_data,
    // debug
    output  logic [5:0]                 tran_state,
    // compact FSM output
    output  logic [41:0]                fsm // {adr, dat, we, stb}
);

    // ------ Common Local Parameters ------ //
    localparam  y   =   1'b1;
    localparam  n   =   1'b0;

    localparam  dat_no  =   2'h0;
    localparam  dat_rd  =   2'h1;
    localparam  dat_wr  =   2'h2;

    localparam  resp_no =   2'h0;
    localparam  resp_sh =   2'h1;   // wait for 48-bits response.
    localparam  resp_lg =   2'h2;   // wait for 136-bits response.

    // ------ Local Parameters ------ //
    typedef enum logic [5:0] {  
        ST_RST                  =   6'h3f,

        ST_IDLE                 =   6'h00,
        ST_OK_RESP_PENDING      =   6'h01,
        ST_ERR_RESP_PENDING     =   6'h02,
        ST_CLR_CMD_ISR          =   6'h03,
        ST_CLR_DAT_ISR          =   6'h04,

        ST_CMD17_DMA            =   6'h10,
        ST_CMD17_CMD            =   6'h11,
        ST_CMD17_WAIT_CLR       =   6'h12,
        ST_CMD17_ARG            =   6'h13,
        ST_CMD17_WAIT_CMD_INT   =   6'h14,
        ST_CMD17_RD_CMD_ISR     =   6'h15,
        ST_CMD17_RD_RESP0       =   6'h16,
        ST_CMD17_WAIT_DATA_INT  =   6'h17,
        ST_CMD17_RD_DATA_ISR    =   6'h18,

        ST_CMD24_DMA            =   6'h20,
        ST_CMD24_CMD            =   6'h21,
        ST_CMD24_WAIT_CLR       =   6'h22,
        ST_CMD24_ARG            =   6'h23,
        ST_CMD24_WAIT_CMD_INT   =   6'h24,
        ST_CMD24_RD_CMD_ISR     =   6'h25,
        ST_CMD24_RD_RESP0       =   6'h26,
        ST_CMD24_WAIT_DATA_INT  =   6'h27,
        ST_CMD24_RD_DATA_ISR    =   6'h28
    } st_t;

    // ------ Signals Declaration ------ //
    // TODO
    (* dont_touch="true" *) st_t state;
    st_t state_next;

    logic [`SD_ADDR_WIDTH-1:0]    nxt_req_addr_sd_f;
    logic [`SD_ADDR_WIDTH-1:0]    nxt_req_addr_dma_f;
    logic [`SD_ADDR_WIDTH-10:0]   blkcnt, nxtblkcnt;

    // ------ Static Logic ------ //
    assign  req_rdy     = state == ST_IDLE;
    assign  resp_ok     = state == ST_OK_RESP_PENDING;
    assign  resp_val    = (state == ST_OK_RESP_PENDING) ||
                          (state == ST_ERR_RESP_PENDING);
    assign  m_wb_sel_o  = 4'hf;
    assign  m_wb_cyc_o  = 1'b1;
    assign  m_wb_adr_o  = fsm[41:34];
    assign  m_wb_dat_o  = fsm[33:2];
    assign  m_wb_we_o   = fsm[1];
    assign  m_wb_stb_o  = fsm[0];
    assign  tran_state  = state;
    
    // ------ Sequential Logic ------ //
    always_ff @(`DFF_CR(clk,rst)) begin
        if (`DFF_IS_R(rst)) begin
            state   <=  ST_RST;
            req_addr_sd_f <= 0;
            req_addr_dma_f <= 0;
        end else begin
            state   <=  state_next;
            blkcnt  <=  nxtblkcnt;
            
            if (req_rdy && req_val) begin
                blkcnt          <=  req_blkcnt;
                req_addr_sd_f   <=  req_addr_sd;
                req_addr_dma_f  <=  req_addr_dma;
            end else begin
                req_addr_sd_f   <=  nxt_req_addr_sd_f;
                req_addr_dma_f  <=  nxt_req_addr_dma_f;
            end
        end
    end

    // ------ FSM Transition ------ //
    always_comb begin //{{{
        state_next  =   state;
        nxtblkcnt   =   blkcnt;
        nxt_req_addr_sd_f = req_addr_sd_f;
        nxt_req_addr_dma_f = req_addr_dma_f;
       
        case (state)
            ST_RST: begin
                state_next  =   ST_IDLE;
            end
            ST_IDLE: begin
                if (req_val) begin
                    if (req_wr) begin
                        state_next  =   ST_CMD24_DMA;
                    end else begin
                        state_next  =   ST_CMD17_DMA;
                    end
                end
            end
            ST_OK_RESP_PENDING,
            ST_ERR_RESP_PENDING: begin
                if (resp_rdy) begin
                    state_next  =   ST_CLR_CMD_ISR;
                end
            end
            ST_CLR_CMD_ISR: begin
                if (m_wb_ack_i) state_next  =   ST_CLR_DAT_ISR;
            end
            ST_CLR_DAT_ISR: begin
               if (m_wb_ack_i) begin
                  nxt_req_addr_sd_f = req_addr_sd_f + 1;
                  nxt_req_addr_dma_f = req_addr_dma_f + 512;
                  if (blkcnt > 1) begin
                     nxtblkcnt = blkcnt-1;
                     if (req_wr) begin
                        state_next  =   ST_CMD24_DMA;
                     end else begin
                        state_next  =   ST_CMD17_DMA;
                     end
                  end else
                    state_next  =   ST_IDLE;
                end
            end
            ST_CMD17_DMA: begin
                if (m_wb_ack_i) state_next  =   ST_CMD17_CMD;
            end
            ST_CMD17_CMD: begin
                if (m_wb_ack_i) state_next  =   ST_CMD17_WAIT_CLR;
            end
            ST_CMD17_WAIT_CLR: begin
                if (~sd_int_cmd && ~sd_int_data) begin
                    state_next  =   ST_CMD17_ARG;
                end
            end
            ST_CMD17_ARG: begin
                if (m_wb_ack_i) state_next  =   ST_CMD17_WAIT_CMD_INT;
            end
            ST_CMD17_WAIT_CMD_INT: begin
                if (sd_int_cmd) state_next  =   ST_CMD17_RD_CMD_ISR;
            end
            ST_CMD17_RD_CMD_ISR: begin
                if (m_wb_ack_i) begin
                    if (m_wb_dat_i[`INT_CMD_CC]) begin
                        state_next  =   ST_CMD17_RD_RESP0;
                    end else begin
                        state_next  =   ST_ERR_RESP_PENDING;
                    end
                end
            end
            ST_CMD17_RD_RESP0: begin
                if (m_wb_ack_i) begin
                    if (~(|m_wb_dat_i[31:19]) & ~(|m_wb_dat_i[16:13])) begin
                        state_next  =   ST_CMD17_WAIT_DATA_INT;
                    end else begin
                        state_next  =   ST_ERR_RESP_PENDING;
                    end
                end
            end
            ST_CMD17_WAIT_DATA_INT: begin
                if (sd_int_data)    state_next  =   ST_CMD17_RD_DATA_ISR;
            end
            ST_CMD17_RD_DATA_ISR: begin
                if (m_wb_ack_i) begin
                    if (m_wb_dat_i[`INT_DATA_CC]) begin
                        state_next  =   ST_OK_RESP_PENDING;
                    end else begin
                        state_next  =   ST_ERR_RESP_PENDING;
                    end
                end
            end
            ST_CMD24_DMA: begin
                if (m_wb_ack_i) state_next  =   ST_CMD24_CMD;
            end
            ST_CMD24_CMD: begin
                if (m_wb_ack_i) state_next  =   ST_CMD24_WAIT_CLR;
            end
            ST_CMD24_WAIT_CLR: begin
                if (~sd_int_cmd && ~sd_int_data) begin
                    state_next  =   ST_CMD24_ARG;
                end
            end
            ST_CMD24_ARG: begin
                if (m_wb_ack_i) state_next  =   ST_CMD24_WAIT_CMD_INT;
            end
            ST_CMD24_WAIT_CMD_INT: begin
                if (sd_int_cmd) state_next  =   ST_CMD24_RD_CMD_ISR;
            end
            ST_CMD24_RD_CMD_ISR: begin
                if (m_wb_ack_i) begin
                    if (m_wb_dat_i[`INT_CMD_CC]) begin
                        state_next  =   ST_CMD24_RD_RESP0;
                    end else begin
                        state_next  =   ST_ERR_RESP_PENDING;
                    end
                end
            end
            ST_CMD24_RD_RESP0: begin
                if (m_wb_ack_i) begin
                    if (~(|m_wb_dat_i[31:19]) & ~(|m_wb_dat_i[16:13])) begin
                        state_next  =   ST_CMD24_WAIT_DATA_INT;
                    end else begin
                        state_next  =   ST_ERR_RESP_PENDING;
                    end
                end
            end
            ST_CMD24_WAIT_DATA_INT: begin
                if (sd_int_data)    state_next  =   ST_CMD24_RD_DATA_ISR;
            end
            ST_CMD24_RD_DATA_ISR: begin
                if (m_wb_ack_i) begin
                    if (m_wb_dat_i[`INT_DATA_CC]) begin
                        state_next  =   ST_OK_RESP_PENDING;
                    end else begin
                        state_next  =   ST_ERR_RESP_PENDING;
                    end
                end
            end
            default: begin
                state_next  =   ST_IDLE;
            end
        endcase
    end //}}}

    // ------ FSM Output ------ //
    always_comb begin
        case (state)
            ST_CMD17_DMA:           fsm = {`dst_src_addr,   req_addr_dma_f,                                 y, y};
            ST_CMD17_CMD:           fsm = {`command,        18'b0, 6'd17, 1'b0, dat_rd, y, y, n, resp_sh,   y, y};
            ST_CMD17_WAIT_CLR:      fsm = {8'bx,            32'bx,                                          n, n};
            ST_CMD17_ARG:           fsm = {`argument,       req_addr_sd_f,                                  y, y};
            ST_CMD17_WAIT_CMD_INT:  fsm = {8'bx,            32'bx,                                          n, n};
            ST_CMD17_RD_CMD_ISR:    fsm = {`cmd_isr,        32'bx,                                          n, y};
            ST_CMD17_RD_RESP0:      fsm = {`resp0,          32'bx,                                          n, y};
            ST_CMD17_WAIT_DATA_INT: fsm = {8'bx,            32'bx,                                          n, n};
            ST_CMD17_RD_DATA_ISR:   fsm = {`data_isr,       32'bx,                                          n, y};

            ST_CMD24_DMA:           fsm = {`dst_src_addr,   req_addr_dma_f,                                 y, y};
            ST_CMD24_CMD:           fsm = {`command,        18'b0, 6'd24, 1'b0, dat_wr, y, y, n, resp_sh,   y, y};
            ST_CMD24_WAIT_CLR:      fsm = {8'bx,            32'bx,                                          n, n};
            ST_CMD24_ARG:           fsm = {`argument,       req_addr_sd_f,                                  y, y};
            ST_CMD24_WAIT_CMD_INT:  fsm = {8'bx,            32'bx,                                          n, n};
            ST_CMD24_RD_CMD_ISR:    fsm = {`cmd_isr,        32'bx,                                          n, y};
            ST_CMD24_RD_RESP0:      fsm = {`resp0,          32'bx,                                          n, y};
            ST_CMD24_WAIT_DATA_INT: fsm = {8'bx,            32'bx,                                          n, n};
            ST_CMD24_RD_DATA_ISR:   fsm = {`data_isr,       32'bx,                                          n, y};

            ST_CLR_CMD_ISR:         fsm = {`cmd_isr,        32'b0,                                          y, y};
            ST_CLR_DAT_ISR:         fsm = {`data_isr,       32'b0,                                          y, y};

            default:                fsm = {8'bx,            32'bx,                                          n, n};
        endcase
    end

endmodule

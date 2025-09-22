// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : TL2AXI4_32.v
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

module TL2AXI4_32 
    import sy_pkg::*;
(
    input  logic                            clk_i,
    input  logic                            rst_i,
    // =====================================
    // [TileLink bus]
    input  logic                            TL_A_valid_i, 
    output logic                            TL_A_ready_o, 
    input  tl_pkg::A_chan_bits_t            TL_A_bits_i,

    output logic                            TL_D_valid_o, 
    input  logic                            TL_D_ready_i, 
    output tl_pkg::D_chan_bits_t            TL_D_bits_o,
    // =====================================
    // [AXI4 bus]
    // Address write channel
    output logic                            AXI_AW_valid_o,
    input  logic                            AXI_AW_ready_i,         
    output logic [7:0]                      AXI_AW_len_o,            
    output logic [31:0]                     AXI_AW_addr_o,            
    output logic [0:0]                      AXI_AW_user_o,            
    output logic [3:0]                      AXI_AW_id_o,            
    // Address read channel
    output logic                            AXI_AR_valid_o,
    input  logic                            AXI_AR_ready_i,         
    output logic [7:0]                      AXI_AR_len_o,            
    output logic [31:0]                     AXI_AR_addr_o,            
    output logic [0:0]                      AXI_AR_user_o,            
    output logic [3:0]                      AXI_AR_id_o,     
    // write channel
    output logic                            AXI_W_valid_o,
    input  logic                            AXI_W_ready_i,         
    output logic [31:0]                     AXI_W_wdata_o,
    output logic [3:0]                      AXI_W_wstrb_o,
    output logic [0:0]                      AXI_W_user_o,            
    output logic                            AXI_W_last_o,            
    // read channel
    input  logic                            AXI_R_valid_i,
    output logic                            AXI_R_ready_o,
    input  logic [31:0]                     AXI_R_rdata_i,
    input  logic [0:0]                      AXI_R_user_i,
    input  logic [3:0]                      AXI_R_id_i,
    input  logic [1:0]                      AXI_R_resp_i,
    input  logic                            AXI_R_last_i,
    // write response channel
    input  logic                            AXI_B_valid_i,
    output logic                            AXI_B_ready_o,
    input  logic [3:0]                      AXI_B_id_i,
    input  logic [1:0]                      AXI_B_resp_i,
    input  logic [0:0]                      AXI_B_user_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    typedef enum logic[2:0] {IDLE,SINGLE_WRITE,WRITE_FIRST,WRITE_LAST,WRITE_RESP,SINGLE_READ,READ_FIRST,READ_LAST} state_e;
    state_e state_d, state_q;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic [63:0]            tl_data_d, tl_data_q;
    logic [7:0]             tl_trans_len_d, tl_trans_len_q;
    logic [7:0]             trans_cnt_d, trans_cnt_q;
    logic [7:0]             trans_len_d, trans_len_q;
    logic [7:0]             tl_mask_d, tl_mask_q;
    tl_pkg::source_t        tl_source_d, tl_source_q;
    logic                   tl_wr;
    logic                   tl_rd;
    logic                   first_write;
    logic                   reg_wr_rd;
    logic [7:0]             tl_trans_len_32;
    logic                   is_low_32bit;
    logic                   first_half_data;
    logic                   last_half_data;
    logic [31:0]            tl_rd_data_first_d,tl_rd_data_first_q;
    logic [31:0]            tl_rd_data_last;
//======================================================================================================================
// FSM 
//======================================================================================================================
    assign tl_wr = TL_A_bits_i.opcode == tl_pkg::PutFullData || TL_A_bits_i.opcode == tl_pkg::PutPartialData;
    assign tl_rd = TL_A_bits_i.opcode == tl_pkg::Get;

    assign first_write = trans_cnt_q == 0;

    assign tl_trans_len_32  = (TL_A_bits_i.size << 1) + 1; // len * 2 + 1
    assign is_low_32bit = TL_A_bits_i.mask[3:0] != '0;
    assign reg_wr_rd = TL_A_bits_i.mask != 8'hFF && TL_A_bits_i.size == '0;

    assign AXI_AW_len_o     = reg_wr_rd ? '0 : tl_trans_len_32;           
    assign AXI_AW_addr_o    = is_low_32bit ? TL_A_bits_i.address : TL_A_bits_i.address + 4'h4;           
    assign AXI_AW_user_o    = '0;            
    assign AXI_AW_id_o      = '0;           

    assign AXI_AR_len_o     = reg_wr_rd ? '0 : tl_trans_len_32;            
    assign AXI_AR_addr_o    = AXI_AW_addr_o;            
    assign AXI_AR_user_o    = '0;            
    assign AXI_AR_id_o      = '0;     
 
    assign AXI_W_wdata_o    = first_half_data ? tl_data_d[31:0] : tl_data_d[63:32];
    assign AXI_W_wstrb_o    = first_half_data ? tl_mask_q[3:0]  : tl_mask_q[7:4];
    assign AXI_W_user_o     = '0;            

    assign TL_D_bits_o.param  = tl_pkg::toN;
    assign TL_D_bits_o.size   = tl_trans_len_q;
    assign TL_D_bits_o.source = tl_source_q;
    assign TL_D_bits_o.sink   = '0;
    assign TL_D_bits_o.denied = '0;
    assign TL_D_bits_o.data   = {tl_rd_data_last, tl_rd_data_first_d};
    assign TL_D_bits_o.corrupt= '0;

    always_comb begin : FSM 
        state_d = state_q;

        tl_data_d       = tl_data_q;
        tl_trans_len_d  = tl_trans_len_q;
        tl_source_d     = tl_source_q;
        tl_mask_d       = tl_mask_q;
        trans_cnt_d     = trans_cnt_q;
        trans_len_d     = trans_len_q;

        tl_rd_data_first_d = tl_rd_data_first_q;
        tl_rd_data_last = AXI_R_rdata_i;

        TL_A_ready_o = 1'b0;
        TL_D_valid_o = 1'b0;
        TL_D_bits_o.opcode = tl_pkg::AccessAck;

        AXI_AW_valid_o = 1'b0;
        AXI_AR_valid_o = 1'b0;
        AXI_W_valid_o  = 1'b0;
        AXI_W_last_o   = 1'b0;
        AXI_R_ready_o  = 1'b0;
        AXI_B_ready_o  = 1'b0;

        first_half_data = 1'b0;
        last_half_data  = 1'b0;

        unique case(state_q)
            IDLE : begin 
                TL_A_ready_o = tl_wr && AXI_AW_ready_i || tl_rd && AXI_AR_ready_i;
                AXI_AW_valid_o = TL_A_valid_i && tl_wr;
                AXI_AR_valid_o = TL_A_valid_i && tl_rd;
                if (TL_A_valid_i && TL_A_ready_o) begin
                      tl_data_d = TL_A_bits_i.data;
                      tl_trans_len_d = TL_A_bits_i.size;
                      tl_source_d = TL_A_bits_i.source;
                      tl_mask_d = TL_A_bits_i.mask;
                      trans_cnt_d = '0;
                      trans_len_d = reg_wr_rd ? '0 : tl_trans_len_32;
                      state_d = tl_wr ? (reg_wr_rd ? SINGLE_WRITE : WRITE_FIRST) : (reg_wr_rd ? SINGLE_READ : READ_FIRST);
                end
            end
            SINGLE_WRITE: begin
                first_half_data = tl_mask_q[3:0] != '0;    
                last_half_data  = !first_half_data;
                AXI_W_valid_o = 1'b1;    
                AXI_W_last_o = 1'b1;
                if (AXI_W_ready_i) begin
                    state_d = WRITE_RESP;
                end
            end
            WRITE_FIRST: begin
                first_half_data = 1'b1;
                AXI_W_valid_o = first_write ? 1'b1 : TL_A_valid_i;
                TL_A_ready_o  = first_write ? 1'b0 : AXI_W_ready_i;
                if (AXI_W_valid_o && AXI_W_ready_i) begin
                    tl_data_d = first_write ? tl_data_q : TL_A_bits_i.data;
                    trans_cnt_d = trans_cnt_q + 1;
                    state_d = WRITE_LAST;
                end
            end
            WRITE_LAST: begin
                last_half_data  = 1'b1;
                AXI_W_valid_o = 1'b1 ;
                AXI_W_last_o  = trans_cnt_q == trans_len_q;
                if (AXI_AW_ready_i) begin
                    if (trans_cnt_q == trans_len_q) begin
                        state_d = WRITE_RESP;
                    end else begin // burst write done
                        trans_cnt_d = trans_cnt_q + 1;
                        state_d = WRITE_FIRST;
                    end
                end
            end
            WRITE_RESP: begin
                // trans AXI response to TL response
                AXI_B_ready_o = TL_D_ready_i;
                TL_D_valid_o  = AXI_B_valid_i;
                TL_D_bits_o.opcode = tl_pkg::AccessAck;
                if (AXI_B_valid_i && AXI_B_ready_o) begin
                    state_d = IDLE;
                end
            end
            SINGLE_READ: begin
                AXI_R_ready_o = TL_D_ready_i;
                TL_D_valid_o = AXI_R_valid_i;
                TL_D_bits_o.opcode = tl_pkg::AccessAckData;
                tl_rd_data_first_d = AXI_R_rdata_i;
                if (AXI_R_valid_i && AXI_R_ready_o) begin
                    state_d = IDLE;
                end
            end
            READ_FIRST: begin
                AXI_R_ready_o = 1'b1;
                tl_rd_data_first_d = AXI_R_rdata_i;
                if (AXI_R_valid_i && AXI_R_ready_o) begin
                    trans_cnt_d = trans_cnt_q + 1;
                    state_d = READ_LAST;
                end
            end
            READ_LAST: begin
                AXI_R_ready_o = TL_D_ready_i;
                TL_D_valid_o = AXI_R_valid_i;
                TL_D_bits_o.opcode = tl_pkg::AccessAckData;
                if (AXI_R_valid_i && AXI_R_ready_o) begin
                    if (trans_cnt_q == trans_len_q) begin
                        state_d = IDLE;
                    end else begin
                        trans_cnt_d = trans_cnt_q + 1;
                        state_d = READ_FIRST;
                    end
                end
            end
          default : state_d = IDLE;
        endcase
    end
//======================================================================================================================
// Register
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i,rst_i)) begin : p_regs
        if(`DFF_IS_R(rst_i)) begin
            state_q <= `TCQ IDLE;
            tl_data_q       <= `TCQ '0;
            tl_trans_len_q  <= `TCQ '0;
            trans_cnt_q     <= `TCQ '0;
            trans_len_q     <= `TCQ '0;
            tl_mask_q       <= `TCQ '0;
            tl_source_q     <= `TCQ '0;
            tl_rd_data_first_q <= `TCQ '0;
        end else begin
            state_q <= `TCQ state_d;
            tl_data_q       <= `TCQ tl_data_d;
            tl_trans_len_q  <= `TCQ tl_trans_len_d;
            trans_cnt_q     <= `TCQ trans_cnt_d;
            trans_len_q     <= `TCQ trans_len_d;
            tl_mask_q       <= `TCQ tl_mask_d;
            tl_source_q     <= `TCQ tl_source_d;
            tl_rd_data_first_q <= `TCQ tl_rd_data_first_d;
        end
    end
endmodule
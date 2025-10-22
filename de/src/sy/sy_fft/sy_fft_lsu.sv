// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_fft_lsu.v
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

module sy_fft_lsu
    import fft_pkg::*;
#(
    parameter SOURCE     = 0
)(
    // clk rst and flush
    input  logic                                clk_i,           
    input  logic                                rst_i,          
    input  logic                                flush_i,
    // =====================================
    // [instr from issue queue]
    input  logic                                iq_lsu__vld_i,
    output logic                                lsu_iq__rdy_o,
    input  lsu_data_t                           iq_lsu__data_i,

    output logic                                lsu_iq__awake_en_o,          
    output logic                                lsu_iq__awake_rs2_en_o,
    output logic                                lsu_iq__awake_rs1_idx_o,
    output logic                                lsu_iq__awake_rs2_idx_o,
    output logic [7:0]                          lsu_iq__awake_instr_idx_o,
    // =====================================
    // [TileLink Interface]
    // A channel
    output logic                                lsu_A_valid_o,
    input  logic                                lsu_A_ready_i,
    output tl_pkg::A_chan_bits_t                lsu_A_bits_o,
    // C channel
    output logic                                lsu_C_valid_o,
    input  logic                                lsu_C_ready_i,
    output tl_pkg::C_chan_bits_t                lsu_C_bits_o,
    // D channel
    output logic                                lsu_D_ready_o,
    input  logic                                lsu_D_valid_i,
    input  tl_pkg::D_chan_bits_t                lsu_D_bits_i,           
    // =====================================
    // [Interface with weight ram]
    output logic                                lsu_wt_wr_en_o,
    output logic[LM_ADDR_WTH-1:0]               lsu_wt_addr_o,
    output logic[63:0]                          lsu_wt_wr_data_o,            
    // =====================================
    // [Interface with local mem]
    output logic                                lsu_lm_wr_en_o,        
    output logic                                lsu_lm_rd_en_o,        
    output logic[LM_ADDR_WTH-1:0]               lsu_lm_addr_o,         
    output logic[1:0][63:0]                     lsu_lm_wr_data_o,      
    input  logic[1:0][63:0]                     lsu_lm_rd_data_i       
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam  SOURCE_ID       = {SOURCE, 1'b0};

    typedef enum logic[1:0] {IDLE,LOAD,STORE_REQ,STORE} state_e;
    state_e state_d,state_q;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic [31:0]                                stride_d,stride_q;
    logic [63:0]                                base_addr_d,base_addr_q;
    logic [LM_AWTH-1:0]                         ocm_addr_d,ocm_addr_q;
    logic [10:0]                                len_d,len_q;
    logic                                       mode_d,mode_q;     
    logic [3:0]                                 tot_level_d,tot_level_q;    
    logic [15:0]                                req_cnt_d,req_cnt_q;
    logic [31:0]                                req_off_d,req_off_q;
    logic [15:0]                                rsp_cnt_d,rsp_cnt_q;
    logic [63:0]                                rsp_addr_d,rsp_addr_q;
    logic                                       buf_idx_d,buf_idx_q;
    logic                                       wt_buf_idx_d,wt_buf_idx_q;
    logic                                       bank_idx_d,bank_idx_q;
    logic                                       load_wt_d,load_wt_q; 
    logic [7:0]                                 instr_idx_d,instr_idx_q;
    logic [LM_ADDR_WTH-1:0]                     lm_addr;
    logic [LM_ADDR_WTH-1:0]                     wt_addr;

    logic [15:0]                                reverse_base_d,reverse_base_q;   
    logic [15:0]                                reverse_off;
    logic [1:0][63:0]                           lm_rd_data_d,lm_rd_data_q;

    logic                                       load_en;  
    logic                                       store_en;  
    logic [1:0][63:0]                           lm_wr_data;
    logic                                       lm_wr_en;
    logic                                       lm_wr_en_dly;
    logic                                       lm_rd_en_dly;
    logic [63:0]                                lsu_st_data;                     
//======================================================================================================================
// Instance
//======================================================================================================================
    // reverse addr
    always_comb begin
        reverse_off = reverse_base_d;  // default value
        for (integer i = 0; i < 15; i = i + 1) begin
            if (i < tot_level_q) begin
                reverse_off[i] = reverse_base_d[tot_level_q - 1 - i];
            end else begin
                reverse_off[i] = reverse_base_d[i];
            end
        end
    end
    // TileLink A (used to read data from mem)
    assign lsu_A_valid_o = (req_cnt_q < len_q) && load_en;

    assign lsu_A_bits_o.opcode  = tl_pkg::Get;
    assign lsu_A_bits_o.param   = tl_pkg::NtoB;
    assign lsu_A_bits_o.size    = '0; // trans length always be 0 (len = 1)
    assign lsu_A_bits_o.source  = SOURCE_ID;
    // align with 8 byte
    // assign lsu_A_bits_o.address = base_addr_q + {(load_wt_q ? req_cnt_q : req_off_q),3'b0};
    assign lsu_A_bits_o.address = base_addr_q + {req_off_q,3'b0};
    assign lsu_A_bits_o.mask    = 8'hFF;
    assign lsu_A_bits_o.data    = '0;
    assign lsu_A_bits_o.corrupt = '0;
    // TileLink C (used to write data to mem)
    assign lsu_C_bits_o.opcode  = tl_pkg::ReleaseData;
    assign lsu_C_bits_o.param   = tl_pkg::TtoB; //default value
    assign lsu_C_bits_o.size    = '0; 
    assign lsu_C_bits_o.source  = SOURCE_ID;
    // align with 8 byte
    assign lsu_C_bits_o.address = base_addr_q + {req_off_q,3'b0};
    assign lsu_C_bits_o.data    = lm_rd_data_d[req_cnt_q[0]];
    assign lsu_C_bits_o.corrupt = '0;
    // calculate lm and wt address
    assign lm_addr = {buf_idx_q,bank_idx_q,ocm_addr_q,3'b0};
    assign wt_addr = {wt_buf_idx_q,ocm_addr_q,3'b0};
    // assign wt_addr = {ocm_addr_q,3'b0};
    // lm interface
    assign lsu_lm_wr_en_o   = lm_wr_en_dly && !load_wt_q;        
    // assign lsu_lm_rd_en_o   = ;        
    assign lsu_lm_addr_o    = lm_addr;         
    assign lsu_lm_wr_data_o = lm_wr_data;      
    // wt interface
    assign lsu_wt_wr_en_o   = lsu_D_valid_i && lsu_D_ready_o && load_wt_q;
    assign lsu_wt_addr_o    = wt_addr;
    assign lsu_wt_wr_data_o = lsu_D_bits_i.data;            

    always_ff @(`DFF_CR(clk_i,rst_i)) begin 
        if(`DFF_IS_R(rst_i)) begin
            lm_wr_data <= '0;
            lm_wr_en_dly <= 1'b0;
            lm_rd_en_dly <= 1'b0;
            // lm_rd_data_q <= '0;
        end else begin
            if (lsu_D_valid_i && lsu_D_ready_o) begin
                lm_wr_data <= {lsu_D_bits_i.data,lm_wr_data[1]};
            end
            lm_wr_en_dly <= lm_wr_en;
            lm_rd_en_dly <= lsu_lm_rd_en_o;
            // if (lm_rd_en_dly) begin
            //     lm_rd_data_q <= lsu_lm_rd_data_i;
            // end
        end
    end
    
    assign lsu_iq__awake_rs2_en_o = load_wt_q;
    assign lsu_iq__awake_rs1_idx_o = buf_idx_q;
    assign lsu_iq__awake_rs2_idx_o = wt_buf_idx_q;
    assign lsu_iq__awake_instr_idx_o = instr_idx_q;
    // ctrl FSM
    always_comb begin
        state_d = state_q;
        stride_d = stride_q;
        base_addr_d = base_addr_q;
        ocm_addr_d = ocm_addr_q;
        len_d = len_q;
        mode_d = mode_q;
        tot_level_d = tot_level_q;
        buf_idx_d = buf_idx_q;
        wt_buf_idx_d = wt_buf_idx_q;
        bank_idx_d = bank_idx_q;
        load_wt_d = load_wt_q;
        req_cnt_d = req_cnt_q;
        rsp_cnt_d = rsp_cnt_q;
        req_off_d = req_off_q;
        lm_rd_data_d = lm_rd_data_q;
        instr_idx_d = instr_idx_q;
        reverse_base_d = reverse_base_q;

        load_en = 1'b0;
        store_en = 1'b0;
        lm_wr_en = 1'b0;
        lsu_st_data = '0;

        lsu_D_ready_o = 1'b1;
        lsu_C_valid_o = 1'b0;
        lsu_lm_rd_en_o = 1'b0;

        lsu_iq__rdy_o = 1'b0;
        lsu_iq__awake_en_o = 1'b0;
        unique case(state_q)
            IDLE: begin
                lsu_iq__rdy_o = 1'b1;
                lsu_D_ready_o = 1'b1;
                if (iq_lsu__vld_i) begin
                    // save lsu data info
                    base_addr_d     = iq_lsu__data_i.base_addr;
                    ocm_addr_d      = iq_lsu__data_i.is_load ? iq_lsu__data_i.wr_ocm_addr : iq_lsu__data_i.rd_ocm_addr;
                    stride_d        = iq_lsu__data_i.stride;
                    len_d           = iq_lsu__data_i.load_wt ? (iq_lsu__data_i.len >> 1) : iq_lsu__data_i.len;
                    tot_level_d     = iq_lsu__data_i.tot_level;
                    mode_d          = iq_lsu__data_i.mode;
                    buf_idx_d       = iq_lsu__data_i.buf_idx;
                    wt_buf_idx_d    = iq_lsu__data_i.wt_buf_idx;
                    bank_idx_d      = iq_lsu__data_i.bank_idx;
                    load_wt_d       = iq_lsu__data_i.load_wt;
                    instr_idx_d     = iq_lsu__data_i.instr_idx;
                    reverse_base_d  = iq_lsu__data_i.reverse_base;

                    req_cnt_d = '0;
                    req_off_d = iq_lsu__data_i.mode ? '0 : reverse_off;
                    rsp_cnt_d = '0;
                    state_d = iq_lsu__data_i.is_load ? LOAD : STORE_REQ;
                end
            end
            LOAD: begin
                load_en = 1'b1;   
                lsu_D_ready_o = 1'b1;
                if (lsu_A_valid_o && lsu_A_ready_i) begin
                    req_cnt_d = req_cnt_q + 1'b1;
                    reverse_base_d = reverse_base_q + 1'b1;
                    if (load_wt_q) begin
                        req_off_d = req_off_q + stride_q;
                    // first load address calculation
                    end else if (req_cnt_q[0] == 1'b1) begin
                        req_off_d = mode_q ? req_cnt_d[15:1] : reverse_off;
                    // second load address calculation
                    end else begin
                        req_off_d = mode_q ? (req_cnt_d[15:1] + stride_q) : reverse_off;
                    end
                end
                if (lsu_D_valid_i && lsu_D_ready_o) begin
                    rsp_cnt_d = rsp_cnt_q + 1'b1;
                    if (rsp_cnt_q[0] == 1'b1) begin
                        lm_wr_en = 1'b1;   
                    end
                    // finish
                    if (rsp_cnt_q == (len_q - 1)) begin
                        lsu_iq__awake_en_o = 1'b1;
                        state_d = IDLE;
                    end
                end
                // increment write address
                if (lsu_lm_wr_en_o || lsu_wt_wr_en_o) begin
                    ocm_addr_d = ocm_addr_q + 1;
                end
            end
            STORE_REQ: begin
                store_en = 1'b1;
                lsu_D_ready_o = 1'b1;
                if (req_cnt_q < len_q) begin
                    lsu_lm_rd_en_o = 1'b1; 
                    state_d = STORE;
                end
                if (lsu_D_valid_i) begin
                    rsp_cnt_d = rsp_cnt_q + 1'b1;
                    // finish
                    if (rsp_cnt_q == (len_q - 1)) begin
                        lsu_iq__awake_en_o = 1'b1;
                        state_d = IDLE;
                    end
                end
            end
            STORE: begin
                lm_rd_data_d = lm_rd_en_dly ? lsu_lm_rd_data_i : lm_rd_data_q;
                lsu_C_valid_o = 1'b1;
                lsu_D_ready_o = 1'b1;
                // lsu_st_data = lm_rd_data_d;
                if (lsu_C_ready_i) begin
                    req_cnt_d = req_cnt_q + 1'b1;
                    if (req_cnt_q[0] == 1'b1) begin
                        req_off_d = req_cnt_d[15:1];
                    end else begin
                        req_off_d = req_cnt_d[15:1] + stride_q;
                    end
                    if (req_cnt_q[0] == 1'b1) begin
                        state_d = STORE_REQ;
                        ocm_addr_d = ocm_addr_q + 1;
                    end
                end
                if (lsu_D_valid_i) begin
                    rsp_cnt_d = rsp_cnt_q + 1'b1;
                end
            end
            default:;
        endcase
        // flush lsu 
        if (flush_i) begin
            state_d = IDLE;
        end
    end
//======================================================================================================================
// Registers
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i,rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            state_q         <= IDLE;
            stride_q        <= '0;
            base_addr_q     <= '0;
            ocm_addr_q      <= '0;
            len_q           <= '0;
            mode_q          <= '0;     
            tot_level_q     <= '0;    
            req_cnt_q       <= '0;
            req_off_q       <= '0;
            rsp_cnt_q       <= '0;
            rsp_addr_q      <= '0;
            buf_idx_q       <= '0;
            wt_buf_idx_q    <= '0;
            bank_idx_q      <= '0;
            load_wt_q       <= '0; 
            lm_rd_data_q    <= '0;
            instr_idx_q     <= '0;
            reverse_base_q  <= '0;
        end else begin
            state_q         <= state_d;
            stride_q        <= stride_d;
            base_addr_q     <= base_addr_d;
            ocm_addr_q      <= ocm_addr_d;
            len_q           <= len_d;
            mode_q          <= mode_d;     
            tot_level_q     <= tot_level_d;    
            req_cnt_q       <= req_cnt_d;
            req_off_q       <= req_off_d;
            rsp_cnt_q       <= rsp_cnt_d;
            rsp_addr_q      <= rsp_addr_d;
            buf_idx_q       <= buf_idx_d;
            wt_buf_idx_q    <= wt_buf_idx_d;
            bank_idx_q      <= bank_idx_d;
            load_wt_q       <= load_wt_d; 
            lm_rd_data_q    <= lm_rd_data_d;
            instr_idx_q     <= instr_idx_d;
            reverse_base_q  <= reverse_base_d;
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

endmodule 
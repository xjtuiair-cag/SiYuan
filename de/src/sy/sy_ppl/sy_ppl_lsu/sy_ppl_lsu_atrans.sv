// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_lsu_atrans.v
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

module sy_ppl_lsu_atrans
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset & flush_i]
    // -- <clock>
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    // =====================================
    // [From LSU Issue Queue]
    input   logic                           atrans_vld_i,
    output  logic                           atrans_rdy_o,
    input   logic[LSU_IQ_WTH-1:0]           atrans_iq_idx_i,
    input   logic[ROB_WTH-1:0]              atrans_rob_idx_i,
    input   logic[PHY_REG_WTH-1:0]          atrans_rs1_idx_i,
    input   logic[PHY_REG_WTH-1:0]          atrans_rs2_idx_i,
    input   logic                           atrans_rs2_is_fp_i,
    input   logic[DWTH-1:0]                 atrans_imm_i,
    input   mem_opcode_e                    atrans_mem_op_i, 
    input   size_e                          atrans_size_i,

    output logic                            atrans_done_o,
    output logic[LSU_IQ_WTH-1:0]            atrans_done_idx_o,
    output logic[DWTH-1:0]                  atrans_wdata_o,
    output logic[AWTH-1:0]                  atrans_paddr_o,
    // =====================================
    // [To MMU]
    output  logic                           lsu_mmu__req_o,
    output  logic[63:0]                     lsu_mmu__vaddr_o,
    output  logic                           lsu_mmu__is_store_o,
    input   logic                           mmu_lsu__hit_i,
    input   logic                           mmu_lsu__valid_i,
    input   logic[63:0]                     mmu_lsu__paddr_i,
    input   excp_t                          mmu_lsu__ex_i,
    // =====================================
    // [Read GPR Register]
    output  logic[PHY_REG_WTH-1:0]          gpr_rs1_idx_o,
    output  logic[PHY_REG_WTH-1:0]          gpr_rs2_idx_o,
    input   logic[DWTH-1:0]                 gpr_rs1_data_i,
    input   logic[DWTH-1:0]                 gpr_rs2_data_i,
    // =====================================
    // [Read FP Register]
    output  logic[PHY_REG_WTH-1:0]          fpr_rs2_idx_o,
    input   logic[DWTH-1:0]                 fpr_rs2_data_i,
    // =====================================
    // [Commit to ROB] 
    output  logic                           atrans_excp_en_o,
    output  logic[DWTH-1:0]                 atrans_excp_tval_o,
    output  excp_e                          atrans_excp_cause_o,
    output  logic[ROB_WTH-1:0]              atrans_rob_idx_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================

    typedef enum logic[0:0] {IDLE,READ_MMU} state_e;
    state_e state_d, state_q;

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                                   reg_rd_stall;
    logic                                   reg_rd_act_unkilled;
    logic                                   reg_rd_act;
    logic                                   reg_rd_avail;
    logic                                   reg_rd_accpt;
    logic[DWTH-1:0]                         rs1_reg_byp;
    logic[DWTH-1:0]                         rs2_reg_byp;

    logic[LSU_IQ_WTH-1:0]                   atrans_iq_idx_st1;
    logic[ROB_WTH-1:0]                      atrans_rob_idx_st1;
    logic[PHY_REG_WTH-1:0]                  atrans_rs1_idx_st1;
    logic[PHY_REG_WTH-1:0]                  atrans_rs2_idx_st1;
    logic                                   atrans_rs2_is_fp_st1;
    logic[DWTH-1:0]                         atrans_imm_st1;
    mem_opcode_e                            atrans_mem_op_st1; 
    size_e                                  atrans_size_st1;

    logic[DWTH-1:0]                         wdata_st1,wdata_st2,wdata_st3;
    logic[AWTH-1:0]                         vaddr_st1,vaddr_st2,vaddr_st3;                
    logic                                   is_store_st1,is_amo_st1;          
    logic                                   is_store_st2,is_amo_st2;          
    logic                                   is_store_st3;          
    logic[LSU_IQ_WTH-1:0]                   atrans_iq_idx_st2,atrans_iq_idx_st3;
    logic[ROB_WTH-1:0]                      atrans_rob_idx_st2,atrans_rob_idx_st3;
    size_e                                  atrans_size_st2;
    logic                                   misaligned,misaligned_st3;

    logic                                   atrans_ready;    
    logic                                   atrans_act;    
//======================================================================================================================
// Stage1 : Read GPR/FPR reg
//======================================================================================================================
    // Stage 1 : Read Register
    assign reg_rd_stall = 1'b0; // TODO
    assign reg_rd_kill  = flush_i;

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            reg_rd_act_unkilled <= `TCQ 1'b0;
        end else begin
            reg_rd_act_unkilled <= `TCQ reg_rd_accpt ? atrans_vld_i : reg_rd_act;
        end
    end

    assign reg_rd_act   = reg_rd_act_unkilled && !reg_rd_kill;
    assign reg_rd_avail = reg_rd_act && !reg_rd_stall && atrans_ready;
    assign reg_rd_accpt = !reg_rd_act || reg_rd_avail;
    assign atrans_rdy_o = reg_rd_accpt;

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            atrans_iq_idx_st1    <= `TCQ '0;        
            atrans_rob_idx_st1   <= `TCQ '0;         
            atrans_rs1_idx_st1   <= `TCQ '0;         
            atrans_rs2_idx_st1   <= `TCQ '0;         
            atrans_rs2_is_fp_st1 <= `TCQ 1'b0;
            atrans_imm_st1       <= `TCQ '0;     
            atrans_mem_op_st1    <= `TCQ mem_opcode_e'(0);         
            atrans_size_st1      <= `TCQ size_e'(0);
        end else begin
            if (reg_rd_accpt) begin
                atrans_iq_idx_st1    <= `TCQ atrans_iq_idx_i;        
                atrans_rob_idx_st1   <= `TCQ atrans_rob_idx_i;         
                atrans_rs1_idx_st1   <= `TCQ atrans_rs1_idx_i;         
                atrans_rs2_idx_st1   <= `TCQ atrans_rs2_idx_i;         
                atrans_rs2_is_fp_st1 <= `TCQ atrans_rs2_is_fp_i;
                atrans_imm_st1       <= `TCQ atrans_imm_i;     
                atrans_mem_op_st1    <= `TCQ atrans_mem_op_i;         
                atrans_size_st1      <= `TCQ atrans_size_i;
            end
        end
    end
    assign gpr_rs1_idx_o = atrans_rs1_idx_st1;
    assign gpr_rs2_idx_o = atrans_rs2_idx_st1;
    assign fpr_rs2_idx_o = atrans_rs2_idx_st1;

    // TODO : add bypass network
    assign rs1_reg_byp = gpr_rs1_data_i;
    assign rs2_reg_byp = atrans_rs2_is_fp_st1 ? fpr_rs2_data_i : gpr_rs2_data_i;

    assign is_amo_st1   = (atrans_mem_op_st1 == MEM_OP_LR) || (atrans_mem_op_st1 == MEM_OP_SC) || (atrans_mem_op_st1 == MEM_OP_AMO);
    assign is_store_st1 = (atrans_mem_op_st1 == MEM_OP_STORE) || (atrans_mem_op_st1 == MEM_OP_ST_FP) || 
                          (atrans_mem_op_st1 == MEM_OP_AMO)   || (atrans_mem_op_st1 == MEM_OP_SC) ;
    assign vaddr_st1 = rs1_reg_byp + (is_amo_st1 ? '0 : atrans_imm_st1);
    assign wdata_st1 = rs2_reg_byp;
//======================================================================================================================
// Stage 2 : Translate Address
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            atrans_act      <= `TCQ 1'b0;
            state_q         <= `TCQ IDLE;
            vaddr_st2       <= `TCQ '0;
            wdata_st2       <= `TCQ '0;
            is_store_st2    <= `TCQ 1'b0;
            atrans_size_st2 <= `TCQ size_e'(0);
            atrans_iq_idx_st2   <= `TCQ '0;
            atrans_rob_idx_st2  <= `TCQ '0;
        end else begin
            atrans_act      <= `TCQ atrans_ready ? reg_rd_avail : atrans_act; // indicate this stage is active
            state_q         <= state_d;
            if (atrans_ready) begin
                vaddr_st2       <= `TCQ vaddr_st1;
                wdata_st2       <= `TCQ wdata_st1;
                is_store_st2    <= `TCQ is_store_st1;
                atrans_size_st2 <= `TCQ atrans_size_st1;
                atrans_iq_idx_st2   <= `TCQ atrans_iq_idx_st1 ;
                atrans_rob_idx_st2  <= `TCQ atrans_rob_idx_st1;
            end 
        end
    end

    assign atrans_ready = (state_d == IDLE);
    // is access address is misaligned ?
    assign misaligned = (atrans_size_st2 == SIZE_HALF) ? (vaddr_st2[0]   != 1'h0): 
                        (atrans_size_st2 == SIZE_WORD) ? (vaddr_st2[1:0] != 2'h0): 
                        (atrans_size_st2 == SIZE_DWORD)? (vaddr_st2[2:0] != 3'h0) : 1'b0;

    assign lsu_mmu__vaddr_o = {vaddr_st2 >> 2, 2'h0};
    assign lsu_mmu__is_store_o = is_store_st2;
    // FSM to translate address
    always_comb begin: p_fsm
        state_d = state_q;
        // mmu interface
        lsu_mmu__req_o = 1'b0; 
        // rob interface
        unique case (state_q)
            IDLE: begin
                if (!flush_i && atrans_act) begin
                    if (misaligned) begin
                        state_d = IDLE;
                    end else begin
                        lsu_mmu__req_o = 1'b1;
                        if (mmu_lsu__hit_i) begin
                            state_d = IDLE;
                        end else begin
                            state_d = READ_MMU;
                        end
                    end
                end
            end
            READ_MMU: begin
                if (flush_i) begin
                    state_d = IDLE;
                end else begin
                    lsu_mmu__req_o = 1'b1;
                    if (mmu_lsu__valid_i) begin
                        state_d = IDLE;
                    end
                end
            end
            default: state_d = IDLE;
        endcase
    end
//======================================================================================================================
// Stage 3 : Write back physical address or excpetion happens
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            vaddr_st3           <= `TCQ '0;
            wdata_st3           <= `TCQ '0;
            atrans_iq_idx_st3   <= `TCQ '0;
            atrans_rob_idx_st3  <= `TCQ '0;
            misaligned_st3      <= `TCQ 1'b0;
            is_store_st3        <= `TCQ 1'b0;   
        end else begin
            vaddr_st3           <= `TCQ vaddr_st2;
            wdata_st3           <= `TCQ wdata_st2;
            atrans_iq_idx_st3   <= `TCQ atrans_iq_idx_st2 ;
            atrans_rob_idx_st3  <= `TCQ atrans_rob_idx_st2;
            misaligned_st3      <= `TCQ misaligned && atrans_act;
            is_store_st3        <= `TCQ is_store_st2;
        end
    end

    assign atrans_excp_en_o        = misaligned_st3 || (mmu_lsu__valid_i && mmu_lsu__ex_i.valid);
    assign atrans_excp_tval_o      = vaddr_st3;
    assign atrans_excp_cause_o     = mmu_lsu__ex_i.valid ? mmu_lsu__ex_i.cause.excp : 
                                     (is_store_st3 ? ST_AMO_ADDR_MISALIGNED : LD_ADDR_MISALIGNED);
    assign atrans_rob_idx_o        = atrans_rob_idx_st3;

    assign atrans_done_o           = mmu_lsu__valid_i && !mmu_lsu__ex_i.valid;
    assign atrans_done_idx_o       = atrans_iq_idx_st3;
    assign atrans_wdata_o          = wdata_st3;
    assign atrans_paddr_o          = {mmu_lsu__paddr_i >> 7, vaddr_st3[6:0]};
//======================================================================================================================
// just for simulation
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on
//======================================================================================================================
// probe signals
//======================================================================================================================
(* mark_debug = "true" *) logic              prb_lsu_atrans_done;
(* mark_debug = "true" *) logic[ROB_WTH-1:0] prb_lsu_atrans_rob_idx;
(* mark_debug = "true" *) logic[63:0]        prb_lsu_atrans_vaddr;

assign prb_lsu_atrans_done      = atrans_done_o;
assign prb_lsu_atrans_rob_idx   = atrans_rob_idx_o;
assign prb_lsu_atrans_vaddr     = vaddr_st3;

endmodule : sy_ppl_lsu_atrans

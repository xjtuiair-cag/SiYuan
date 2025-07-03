// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_dis.v
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

module sy_ppl_dis
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset & flush]
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    // ====================================
    // [From Decode]
    input   logic                           dec_dis__vld_i,
    output  logic                           dis_dec__rdy_o,
    input   dispatch_t                      dec_dis__data_i,
    // ====================================
    // [To EXU]
    output  logic                           dis_exu__vld_o,
    input   logic                           exu_dis__rdy_i,
    output  exu_packet_t                    dis_exu__packet_o,    
    // ====================================
    // [To CSR]
    output  logic                           dis_csr__vld_o,
    input   logic                           csr_dis__rdy_i,
    output  csr_packet_t                    dis_csr__packet_o,    
    // ====================================
    // [To LSU]
    output  logic                           dis_lsu__vld_o,
    input   logic                           lsu_dis__rdy_i,
    output  lsu_packet_t                    dis_lsu__packet_o,    
    // ====================================
    // [To ROB]
    output  logic                           dis_rob__vld_o,
    input   logic                           rob_dis__rdy_i,
    output  rob_t                           dis_rob__packet_o,    
    input   logic[ROB_WTH-1:0]              rob_dis_idx_i,
    // ====================================
    // [Update Reg state]
    // ALU
    input   logic                           alu_update_en_i,
    input   logic[PHY_REG_WTH-1:0]          alu_update_idx_i,
    // CSR 
    input   logic                           csr_update_en_i,
    input   logic[PHY_REG_WTH-1:0]          csr_update_idx_i,
    // LSU
    input   logic                           lsu_update_en_i,
    input   logic                           lsu_update_is_fp_i,
    input   logic[PHY_REG_WTH-1:0]          lsu_update_idx_i,
    // MDU
    input   logic                           mdu_update_en_i,
    input   logic[PHY_REG_WTH-1:0]          mdu_update_idx_i,
    // FPU
    input   logic                           fpu_update_en_i,
    input   logic                           fpu_update_is_fp_i,
    input   logic[PHY_REG_WTH-1:0]          fpu_update_idx_i
);
//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                           rs1_en;
    logic                           rs2_en;
    logic                           rs3_en;
    logic                           rdst_en;
    logic                           rs1_state;      
    logic                           rs2_state;      
    logic                           rs3_state;      
    instr_cls_e                     instr_cls;
    mem_opcode_e                    mem_op;
    amo_opcode_e                    amo_op;

    logic                           dis_stall;
    logic                           dis_act_unkilled;
    logic                           dis_act;
    logic                           dis_avail;
    logic                           dis_accpt;
    dispatch_t                      dispatch_data;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign dis_stall = !exu_dis__rdy_i || !rob_dis__rdy_i || !lsu_dis__rdy_i || !csr_dis__rdy_i;
    assign dis_kill  = flush_i;

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            dis_act_unkilled <= `TCQ 1'b0;
        end else begin
            dis_act_unkilled <= `TCQ dis_accpt ? dec_dis__vld_i : dis_act;
        end
    end

    assign dis_act   = dis_act_unkilled && !dis_kill;
    assign dis_avail = dis_act && !dis_stall;
    assign dis_accpt = !dis_act || dis_avail;

    assign dis_dec__rdy_o = dis_accpt;

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            dispatch_data <= `TCQ dispatch_t'(0);
        end else begin
            if (dis_dec__rdy_o) begin
                dispatch_data <= `TCQ dec_dis__data_i;
            end
        end
    end

    assign dis_exu__vld_o = dis_avail && (dispatch_data.issue_type == TO_EXU);
    assign dis_lsu__vld_o = dis_avail && (dispatch_data.issue_type == TO_LSU);
    assign dis_csr__vld_o = dis_avail && (dispatch_data.issue_type == TO_CSR);
    assign dis_rob__vld_o = dis_avail;

    assign rs1_en   = dispatch_data.rs1_en;
    assign rs2_en   = dispatch_data.rs2_en;
    assign rs3_en   = dispatch_data.rs3_en;
    assign rdst_en  = dispatch_data.rdst_en;

    // TO EXU
    assign dis_exu__packet_o.instr_cls    = dispatch_data.instr_cls;
    assign dis_exu__packet_o.exu_cmd      = dispatch_data.exu_cmd;
    assign dis_exu__packet_o.phy_rs1_idx  = dispatch_data.phy_rs1_idx;
    assign dis_exu__packet_o.phy_rs2_idx  = dispatch_data.phy_rs2_idx;
    assign dis_exu__packet_o.phy_rs3_idx  = dispatch_data.phy_rs3_idx;
    assign dis_exu__packet_o.phy_rdst_idx = dispatch_data.phy_rdst_idx;
    assign dis_exu__packet_o.rs1_is_fp    = dispatch_data.rs1_is_fp;   
    assign dis_exu__packet_o.rs2_is_fp    = dispatch_data.rs2_is_fp;   
    assign dis_exu__packet_o.rdst_en      = dispatch_data.rdst_en;
    assign dis_exu__packet_o.rdst_is_fp   = dispatch_data.rdst_is_fp;
    assign dis_exu__packet_o.rob_idx      = rob_dis_idx_i;
    assign dis_exu__packet_o.pc           = dispatch_data.pc;
    assign dis_exu__packet_o.is_c         = dispatch_data.is_c;
    assign dis_exu__packet_o.rs1_state    = rs1_en ? rs1_state : 1'b1;
    assign dis_exu__packet_o.rs2_state    = rs2_en ? rs2_state : 1'b1;
    assign dis_exu__packet_o.rs3_state    = rs3_en ? rs3_state : 1'b1;
    // TO CSR
    assign dis_csr__packet_o.csr_cmd      = dispatch_data.csr_cmd;
    assign dis_csr__packet_o.phy_rs1_idx  = dispatch_data.phy_rs1_idx;
    assign dis_csr__packet_o.phy_rdst_idx = dispatch_data.phy_rdst_idx;
    assign dis_csr__packet_o.rs1_state    = rs1_en ? rs1_state : 1'b1;
    assign dis_csr__packet_o.rdst_en      = dispatch_data.rdst_en;
    assign dis_csr__packet_o.rob_idx      = rob_dis_idx_i;
    // TO LSU
    assign dis_lsu__packet_o.lsu_cmd      = dispatch_data.lsu_cmd;
    assign dis_lsu__packet_o.phy_rs1_idx  = dispatch_data.phy_rs1_idx;
    assign dis_lsu__packet_o.phy_rs2_idx  = dispatch_data.phy_rs2_idx;
    assign dis_lsu__packet_o.phy_rdst_idx = dispatch_data.phy_rdst_idx;
    assign dis_lsu__packet_o.rdst_en      = dispatch_data.rdst_en;
    assign dis_lsu__packet_o.rdst_is_fp   = dispatch_data.rdst_is_fp;
    assign dis_lsu__packet_o.rs2_is_fp    = dispatch_data.rs2_is_fp;
    assign dis_lsu__packet_o.rob_idx      = rob_dis_idx_i;
    assign dis_lsu__packet_o.rs1_state    = rs1_en ? rs1_state : 1'b1;
    assign dis_lsu__packet_o.rs2_state    = rs2_en ? rs2_state : 1'b1;
    // TO ROB
    assign dis_rob__packet_o.instr_cls        = dispatch_data.instr_cls;
    assign dis_rob__packet_o.phy_rdst_idx     = dispatch_data.phy_rdst_idx;
    assign dis_rob__packet_o.phy_old_rdst_idx = dispatch_data.phy_old_rdst_idx;
    assign dis_rob__packet_o.arc_rdst_idx     = dispatch_data.arc_rdst_idx;
    assign dis_rob__packet_o.rdst_en          = dispatch_data.rdst_en;
    assign dis_rob__packet_o.rdst_is_fp       = dispatch_data.rdst_is_fp;
    assign dis_rob__packet_o.sys_op           = dispatch_data.sys_cmd.sys_op;
    assign dis_rob__packet_o.excp             = dispatch_data.excp;
    assign dis_rob__packet_o.cur_pc           = dispatch_data.pc;
    assign dis_rob__packet_o.pred_npc         = dispatch_data.npc;
    assign dis_rob__packet_o.true_npc         = '0;
    assign dis_rob__packet_o.completed        = dispatch_data.completed;
    assign dis_rob__packet_o.need_flush       = 1'b0;
    assign dis_rob__packet_o.fpu_status       = '0;
    assign dis_rob__packet_o.is_intr          = dispatch_data.is_intr;
    assign dis_rob__packet_o.is_c             = dispatch_data.is_c;
    assign dis_rob__packet_o.is_jalr          = (instr_cls == INSTR_CLS_JBR && dispatch_data.exu_cmd.jbr_op == JBR_OP_JALR);
    assign dis_rob__packet_o.is_branch        = (instr_cls == INSTR_CLS_JBR && dispatch_data.exu_cmd.jbr_op == JBR_OP_BRANCH);
    assign dis_rob__packet_o.br_taken         = 1'b0;   
    assign dis_rob__packet_o.instr            = dispatch_data.instr;

    assign instr_cls = dispatch_data.instr_cls;
    assign mem_op = dispatch_data.lsu_cmd.mem_op;
    assign amo_op = dispatch_data.lsu_cmd.amo_op;
    always_comb begin
        dis_rob__packet_o.need_reitre_write = 1'b0;
        dis_rob__packet_o.is_csr = 1'b0;
        if (instr_cls == INSTR_CLS_MEM) begin
            case (mem_op)
                // MEM_OP_STORE,MEM_OP_ST_FP,MEM_OP_AMO,MEM_OP_LR,MEM_OP_SC: begin
                MEM_OP_STORE,MEM_OP_ST_FP,MEM_OP_AMO,MEM_OP_SC: begin
                    dis_rob__packet_o.need_reitre_write = 1'b1;
                end 
                default: begin
                    dis_rob__packet_o.need_reitre_write = 1'b0;
                end
            endcase           
        end else if (instr_cls == INSTR_CLS_CSR) begin
            dis_rob__packet_o.need_reitre_write = 1'b1;
            dis_rob__packet_o.is_csr = 1'b1;
        end
    end

    always_comb begin
        dis_rob__packet_o.is_fp = 1'b0;
        if (instr_cls == INSTR_CLS_MEM) begin
            case (mem_op)
                MEM_OP_ST_FP,MEM_OP_LD_FP: begin
                    dis_rob__packet_o.is_fp = 1'b1;
                end 
                default: begin
                    dis_rob__packet_o.is_fp = 1'b0;
                end
            endcase           
        end else if (instr_cls == INSTR_CLS_FPU) begin
            dis_rob__packet_o.is_fp = 1'b1;
        end
    end

    // lookup state of physical register (READY or not READY)
    sy_ppl_reg_state reg_state_inst(
        .clk_i                      (clk_i),                            
        .rst_i                      (rst_i),                            
        .flush_i                    (flush_i),        
        .dispatch_avail_i           (dis_avail),                 
        .phy_rs1_idx_i              (dispatch_data.phy_rs1_idx),              
        .phy_rs2_idx_i              (dispatch_data.phy_rs2_idx),              
        .phy_rs3_idx_i              (dispatch_data.phy_rs3_idx),              
        .phy_rdst_idx_i             (dispatch_data.phy_rdst_idx),               
        .rs1_is_fp_i                (dispatch_data.rs1_is_fp),            
        .rs2_is_fp_i                (dispatch_data.rs2_is_fp),            
        .rdst_is_en_i               (dispatch_data.rdst_en),             
        .rdst_is_fp_i               (dispatch_data.rdst_is_fp),             
    
        .rs1_state_o                (rs1_state),            
        .rs2_state_o                (rs2_state),            
        .rs3_state_o                (rs3_state),            
    
        .alu_update_en_i            (alu_update_en_i    ),                
        .alu_update_idx_i           (alu_update_idx_i   ),                 
                                     
        .csr_update_en_i            (csr_update_en_i    ),                
        .csr_update_idx_i           (csr_update_idx_i   ),                 

        .lsu_update_en_i            (lsu_update_en_i    ),                
        .lsu_update_is_fp_i         (lsu_update_is_fp_i ),                   
        .lsu_update_idx_i           (lsu_update_idx_i   ),                 
                                     
        .mdu_update_en_i            (mdu_update_en_i    ),                
        .mdu_update_idx_i           (mdu_update_idx_i   ),                 
                                     
        .fpu_update_en_i            (fpu_update_en_i    ),                
        .fpu_update_is_fp_i         (fpu_update_is_fp_i ),                   
        .fpu_update_idx_i           (fpu_update_idx_i   )
    );

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_dis

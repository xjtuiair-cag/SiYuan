// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_rob.v
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

module sy_ppl_rob
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset & flush_i]
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    // =====================================
    // [package from dispatch]
    input   logic                           dis_rob__vld_i,
    output  logic                           rob_dis__rdy_o,
    input   rob_t                           dis_rob__packet_i,
    output  logic[ROB_WTH-1:0]              rob_dis__idx_o,
    // =====================================
    // [Commit]
    input   alu_commit_t                    alu_rob__commit_i,   
    input   csr_commit_t                    csr_rob__commit_i,   
    input   lsu_commit_t                    lsu_rob__commit_i,   
    input   mdu_commit_t                    mdu_rob__commit_i,   
    input   fpu_commit_t                    fpu_rob__commit_i,   
    // =====================================
    // [To ctrl module]
    output  logic                           rob_ctrl__fencei_o,
    output  logic                           rob_ctrl__sfence_vma_o,
    output  logic                           rob_ctrl__uret_o,
    output  logic                           rob_ctrl__sret_o,
    output  logic                           rob_ctrl__mret_o,
    output  logic                           rob_ctrl__ex_valid_o,
    output  logic                           rob_ctrl__need_flush_o,
    output  logic                           rob_ctrl__mispred_o,
    output  logic                           rob_ctrl__wfi_o,  
    output  ecode_t                         rob_ctrl__ecode_o,
    output  logic                           rob_ctrl__is_intr_o,
    output  logic[AWTH-1:0]                 rob_ctrl__pc_o,
    output  logic[DWTH-1:0]                 rob_ctrl__excp_tval_o,
    // =====================================
    // [Update Physical Register]
    output  logic                           rob_update_arat_en_o,
    output  logic                           rob_update_fp_reg_o,
    output  logic[4:0]                      rob_update_arat_arc_idx_o,
    output  logic[PHY_REG_WTH-1:0]          rob_update_arat_phy_idx_o,
    output  logic[PHY_REG_WTH-1:0]          rob_update_arat_old_phy_idx_o,
    // =====================================
    // [Allow lsu write]
    output  logic                           rob_lsu__retire_en_o,          
    output  logic                           rob_csr__retire_en_o,          
    // =====================================
    // [To CSR]
    output  logic                           rob_csr__write_fflags_o,
    output  logic[4:0]                      rob_csr__fflags_o,
    output  logic                           rob_csr__dirty_fp_o,
    // =====================================
    // [To Fronted]
    output  bht_update_t                    rob_fet__bht_update_o,
    output  btb_update_t                    rob_fet__btb_update_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    rob_t   [ROB_LEN-1:0]                   rob_packet_d,rob_packet_q;
    logic   [ROB_WTH-1:0]                   rob_ins_idx_d,rob_ins_idx_q;
    logic   [ROB_WTH-1:0]                   rob_del_idx_d,rob_del_idx_q;
    logic   [ROB_WTH:0]                     rob_cnt_d,rob_cnt_q;    
    logic                                   retire_en;
    logic                                   allow_retire;
    rob_t                                   retire_packet;                
    logic                                   is_fencei;
    logic                                   is_sfence_vma;  
    logic                                   is_uret;                    
    logic                                   is_sret;                    
    logic                                   is_mret;                    
    logic                                   is_wfi;         
    logic                                   rob_empty;                    
    logic                                   rob_full;                    
    logic                                   retire_stall;
    logic                                   will_stall;
    logic                                   is_jbr;                  
    logic                                   is_fp;   

//======================================================================================================================
// ROB
//======================================================================================================================
    always_comb begin
        for (integer i=0;i<ROB_LEN;i++) begin
            rob_packet_d[i] = rob_packet_q[i];
            // insert new packet to ROB
            if (dis_rob__vld_i && rob_dis__rdy_o && (rob_ins_idx_q == i)) begin
                rob_packet_d[i] = dis_rob__packet_i;
            end else begin  
                // commit
                if (alu_rob__commit_i.vld && (alu_rob__commit_i.rob_idx == i) || 
                    csr_rob__commit_i.vld && (csr_rob__commit_i.rob_idx == i) || 
                    mdu_rob__commit_i.vld && (mdu_rob__commit_i.rob_idx == i) || 
                    lsu_rob__commit_i.vld && (lsu_rob__commit_i.rob_idx == i) || 
                    lsu_rob__commit_i.excp_en && (lsu_rob__commit_i.excp_rob_idx == i) || 
                    fpu_rob__commit_i.vld && (fpu_rob__commit_i.rob_idx == i)
                   ) begin
                    rob_packet_d[i].completed = 1'b1;
                end
                if (alu_rob__commit_i && (alu_rob__commit_i.rob_idx == i)) begin
                    rob_packet_d[i].true_npc = alu_rob__commit_i.true_npc;       
                    rob_packet_d[i].br_taken = alu_rob__commit_i.br_taken;       
                end
                if (lsu_rob__commit_i.excp_en && (lsu_rob__commit_i.excp_rob_idx == i)) begin
                    rob_packet_d[i].excp.valid      = lsu_rob__commit_i.excp_en;
                    rob_packet_d[i].excp.cause.excp = lsu_rob__commit_i.excp_code;
                    rob_packet_d[i].excp.tval       = lsu_rob__commit_i.excp_tval;
                end
                if (csr_rob__commit_i.vld && (csr_rob__commit_i.rob_idx == i)) begin
                    rob_packet_d[i].excp.valid      = csr_rob__commit_i.excp_en;
                    rob_packet_d[i].excp.cause.excp = ILLEGAL_INST;
                    rob_packet_d[i].need_flush      = csr_rob__commit_i.flush_en;
                end
                if (fpu_rob__commit_i.vld && (fpu_rob__commit_i.rob_idx == i)) begin
                    rob_packet_d[i].fpu_status = fpu_rob__commit_i.status;
                    rob_packet_d[i].need_flush = fpu_rob__commit_i.flush_en;
                end
            end
        end
    end

    assign rob_full = rob_cnt_q[ROB_WTH];
    assign rob_empty = (rob_cnt_q == '0);

    assign rob_dis__rdy_o = !rob_full;
    assign rob_dis__idx_o = rob_ins_idx_q;
    // pointer
    always_comb begin
        rob_ins_idx_d = rob_ins_idx_q;
        rob_del_idx_d = rob_del_idx_q;
        rob_cnt_d = rob_cnt_q;
        // insert
        if (flush_i) begin
            rob_ins_idx_d = '0;
            rob_del_idx_d = '0;
            rob_cnt_d = '0;
        end else if (dis_rob__vld_i && rob_dis__rdy_o && allow_retire && rob_packet_q[rob_del_idx_q].completed) begin
            rob_cnt_d = rob_cnt_q;
            rob_ins_idx_d = rob_ins_idx_q + 1;
            rob_del_idx_d = rob_del_idx_q + 1;
        end else if (dis_rob__vld_i && rob_dis__rdy_o) begin
            rob_ins_idx_d = rob_ins_idx_q + 1;
            rob_cnt_d = rob_cnt_q + 1;
        end else if (allow_retire && rob_packet_q[rob_del_idx_q].completed) begin 
            rob_del_idx_d = rob_del_idx_q + 1;
            rob_cnt_d = rob_cnt_q - 1;
        end
    end
//======================================================================================================================
// Retire Stage
//======================================================================================================================
    assign allow_retire = !rob_empty && !retire_stall;   
    // to reduce resource, we save rob packet for one cycle
    // select one instr to retire
    always_ff @(`DFF_CR(clk_i,rst_i)) begin
       if(`DFF_IS_R(rst_i)) begin
            retire_packet <= `TCQ '0;
            retire_en     <= `TCQ 1'b0;
            retire_stall  <= `TCQ 1'b0;
        end else begin
            retire_packet <= `TCQ rob_packet_q[rob_del_idx_q];
            retire_en     <= `TCQ rob_packet_q[rob_del_idx_q].completed && allow_retire && !will_stall;
            if (will_stall) begin
                retire_stall <= `TCQ 1'b1;
            end else if (flush_i) begin
                retire_stall <= `TCQ 1'b0;
            end
        end
    end 
    // system op
    assign is_fencei     = retire_packet.instr_cls == INSTR_CLS_SYS && retire_packet.sys_op == SYS_OP_FENCEI;
    assign is_sfence_vma = retire_packet.instr_cls == INSTR_CLS_SYS && retire_packet.sys_op == SYS_OP_SFENCE_VMA;
    assign is_uret       = retire_packet.instr_cls == INSTR_CLS_SYS && retire_packet.sys_op == SYS_OP_URET;
    assign is_sret       = retire_packet.instr_cls == INSTR_CLS_SYS && retire_packet.sys_op == SYS_OP_SRET;
    assign is_mret       = retire_packet.instr_cls == INSTR_CLS_SYS && retire_packet.sys_op == SYS_OP_MRET;
    assign is_wfi        = retire_packet.instr_cls == INSTR_CLS_SYS && retire_packet.sys_op == SYS_OP_WFI;

    assign rob_ctrl__fencei_o       = retire_en && is_fencei;
    assign rob_ctrl__sfence_vma_o   = retire_en && is_sfence_vma;
    assign rob_ctrl__uret_o         = retire_en && is_uret;  
    assign rob_ctrl__sret_o         = retire_en && is_sret; 
    assign rob_ctrl__mret_o         = retire_en && is_mret;  
    assign rob_ctrl__wfi_o          = retire_en && is_wfi;

    assign rob_ctrl__ex_valid_o   = retire_en && retire_packet.excp.valid ;
    assign rob_ctrl__need_flush_o = retire_en && retire_packet.need_flush;
    // misprediction
    assign is_jbr = retire_packet.instr_cls == INSTR_CLS_JBR;
    assign rob_ctrl__mispred_o = retire_en && (retire_packet.pred_npc != retire_packet.true_npc) && is_jbr;

    // update architecture RAT
    assign rob_update_arat_en_o = retire_en && retire_packet.rdst_en 
                                  && (retire_packet.arc_rdst_idx != 0 || retire_packet.rdst_is_fp) 
                                  && !rob_ctrl__ex_valid_o;
    assign rob_update_fp_reg_o  = retire_packet.rdst_is_fp;
    assign rob_update_arat_arc_idx_o = retire_packet.arc_rdst_idx;
    assign rob_update_arat_phy_idx_o = retire_packet.phy_rdst_idx;
    assign rob_update_arat_old_phy_idx_o = retire_packet.phy_old_rdst_idx;
    // retire store instr 
    assign rob_lsu__retire_en_o = retire_en && retire_packet.need_reitre_write && !rob_ctrl__ex_valid_o && !retire_packet.is_csr;
    assign rob_csr__retire_en_o = retire_en && retire_packet.need_reitre_write && !rob_ctrl__ex_valid_o &&  retire_packet.is_csr;

    assign will_stall = (retire_packet.instr_cls == INSTR_CLS_SYS) && retire_en || 
                        rob_ctrl__ex_valid_o || rob_ctrl__need_flush_o || rob_ctrl__mispred_o;

    assign rob_ctrl__ecode_o = retire_packet.excp.cause;
    assign rob_ctrl__is_intr_o = retire_packet.is_intr;
    assign rob_ctrl__excp_tval_o = (rob_ctrl__ecode_o.excp == ILLEGAL_INST) ? retire_packet.instr : retire_packet.excp.tval;

    always_comb begin : gen_next_pc
        if (rob_ctrl__ex_valid_o) begin
            rob_ctrl__pc_o = retire_packet.cur_pc;
        end else if (rob_ctrl__mispred_o) begin
            rob_ctrl__pc_o = retire_packet.true_npc;
        end else begin
            rob_ctrl__pc_o = retire_packet.cur_pc + (retire_packet.is_c ? 4'd2 : 4'd4);
        end
    end

    // FPU
    assign rob_csr__write_fflags_o = retire_en && retire_packet.instr_cls == INSTR_CLS_FPU;
    assign rob_csr__fflags_o       = retire_packet.fpu_status;
    assign rob_csr__dirty_fp_o     = retire_en && retire_packet.is_fp;

    // update bht and btb
    assign rob_fet__bht_update_o.vld    = retire_en && retire_packet.is_branch;
    assign rob_fet__bht_update_o.pc     = retire_packet.cur_pc;
    assign rob_fet__bht_update_o.taken  = retire_packet.br_taken;

    assign rob_fet__btb_update_o.vld    = retire_packet.is_jalr && rob_ctrl__mispred_o;
    assign rob_fet__btb_update_o.pc     = retire_packet.cur_pc;
    assign rob_fet__btb_update_o.target_address = retire_packet.true_npc;

    // assign rob_fet__bht_update_o.vld    = '0;
    // assign rob_fet__bht_update_o.pc     = '0;
    // assign rob_fet__bht_update_o.taken  = '0;

    // assign rob_fet__btb_update_o.vld    = '0; 
    // assign rob_fet__btb_update_o.pc     = '0; 
    // assign rob_fet__btb_update_o.target_address = '0;
//======================================================================================================================
// Registers
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0;i<ROB_LEN;i++) begin
                rob_packet_q[i]        <= `TCQ rob_t'(0);
            end
            rob_ins_idx_q       <= `TCQ '0;
            rob_del_idx_q       <= `TCQ '0;
            rob_cnt_q           <= `TCQ '0;    
        end else begin
            for (integer i=0;i<ROB_LEN;i++) begin
                rob_packet_q[i]        <= `TCQ rob_packet_d[i];
            end
            rob_ins_idx_q       <= `TCQ rob_ins_idx_d;
            rob_del_idx_q       <= `TCQ rob_del_idx_d;
            rob_cnt_q           <= `TCQ rob_cnt_d    ;    
        end
    end
    logic [63:0]    retire_br;
    logic [63:0]    mispred_br;
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            retire_br     <= `TCQ '0;
            mispred_br    <= `TCQ '0;
        end else begin
            if (retire_en && retire_packet.instr_cls == INSTR_CLS_JBR) begin
                retire_br   <= `TCQ retire_br + 1;
                if (rob_ctrl__mispred_o) begin
                    mispred_br <= `TCQ mispred_br + 1;
                end
            end
        end
    end

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on

(* mark_debug = "true" *) logic         prb_rob_retire_en;
(* mark_debug = "true" *) logic         prb_rob_allow_retire;
(* mark_debug = "true" *) logic         prb_rob_retire_stall;
(* mark_debug = "true" *) logic[63:0]   prb_rob_retire_pc;
(* mark_debug = "true" *) logic[ROB_WTH:0]  prb_rob_cnt;
(* mark_debug = "true" *) logic[ROB_WTH-1:0]  prb_rob_ins_idx;
(* mark_debug = "true" *) logic[ROB_WTH-1:0]  prb_rob_del_idx;
(* mark_debug = "true" *) instr_cls_e   prb_rob_instr_cls;
(* mark_debug = "true" *) logic         prb_rob_completed;
(* mark_debug = "true" *) logic         prb_rob_excp_en;
(* mark_debug = "true" *) excp_e        prb_rob_excp_cause;
(* mark_debug = "true" *) logic         prb_rob_excp_is_intr;
(* mark_debug = "true" *) logic[63:0]   prb_rob_excp_tval;

(* mark_debug = "true" *) logic[63:0]   prb_rob_br_all;
(* mark_debug = "true" *) logic[63:0]   prb_rob_br_mispred;
// (* mark_debug = "true" *) logic         prb_dis_rob_vld;
// (* mark_debug = "true" *) logic         prb_dis_rob_rdy;
// (* mark_debug = "true" *) logic[63:0]   prb_dis_rob_pc;
// (* mark_debug = "true" *) logic[ROB_WTH-1:0] prb_dis_rob_idx;

assign prb_rob_retire_en         = retire_en;
assign prb_rob_allow_retire      = allow_retire;
assign prb_rob_retire_stall      = retire_stall;
assign prb_rob_retire_pc         = retire_packet.cur_pc;
assign prb_rob_cnt               = rob_cnt_q;
assign prb_rob_ins_idx           = rob_ins_idx_q;
assign prb_rob_del_idx           = rob_del_idx_q;
assign prb_rob_instr_cls         = retire_packet.instr_cls;
assign prb_rob_completed         = retire_packet.completed;
assign prb_rob_excp_en           = rob_ctrl__ex_valid_o;
assign prb_rob_excp_cause        = rob_ctrl__ecode_o.excp;
assign prb_rob_excp_is_intr      = rob_ctrl__is_intr_o;
assign prb_rob_excp_tval         = rob_ctrl__excp_tval_o;

assign prb_rob_br_all            = retire_br;
assign prb_rob_br_mispred        = mispred_br;

// assign prb_dis_rob_vld           = dis_rob__vld_i;
// assign prb_dis_rob_rdy           = rob_dis__rdy_o;
// assign prb_dis_rob_pc            = dis_rob__packet_i.cur_pc;
// assign prb_dis_rob_idx           = rob_dis__idx_o;

(* mark_debug = "true" *) logic              prb_lsu_commit_vld;
(* mark_debug = "true" *) logic              prb_lsu_commit_excp_en;
(* mark_debug = "true" *) excp_e             prb_lsu_commit_excp_cause;
(* mark_debug = "true" *) logic[63:0]        prb_lsu_commit_excp_tval;
(* mark_debug = "true" *) logic[ROB_WTH-1:0] prb_lsu_commit_idx;

assign prb_lsu_commit_vld        = lsu_rob__commit_i.vld;
assign prb_lsu_commit_excp_en    = lsu_rob__commit_i.excp_en;
assign prb_lsu_commit_excp_cause = lsu_rob__commit_i.excp_code;
assign prb_lsu_commit_excp_tval  = lsu_rob__commit_i.excp_tval;
assign prb_lsu_commit_idx        = lsu_rob__commit_i.rob_idx;
endmodule : sy_ppl_rob

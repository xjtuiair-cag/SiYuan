// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_alu.v
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

module sy_ppl_alu
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      
    // -- <reset>
    input   logic                           rst_i,                      
    // =====================================
    // [block control]
    //! hazard logic
    output  logic                           alu_dec__mem_accpt_o,
    //! If ALU module finds current instruction is branch or jump, and the prediction is missed, it should send correct
    //! NPC to FETCH module.
    output  logic                           alu_x__mispred_en_o,
    output  logic[AWTH-1:0]                 alu_x__mispred_pc_o,
    output  logic[AWTH-1:0]                 alu_x__mispred_npc_o,
    // =====================================
    // [From alu]
    output  bht_update_t                    bht_update_o,
    output  btb_update_t                    btb_update_o,
    //! If CTRL module sends kill command, current instruction should be set as invalid.
    //! This kill instruction can disable all phases's signals except phase[BASE].
    input   logic                           ctrl_x__mem_kill_i,
    input   logic                           ctrl_x__wb_kill_i,    
    // =====================================
    // [to ppl_ctrl]
    // =====================================
    // [csr regfile interface]
    output  logic                           alu_csr__valid_o,
    output  lb_cmd_e                        alu_csr__cmd_o,
    output  logic[DWTH-1:0]                 alu_csr__wdata_o,
    output  logic[11:0]                     alu_csr__addr_o,
    input   logic[DWTH-1:0]                 csr_alu__rdata_i,
    output  exception_t                     alu_csr__ex_o,   
    output  logic[AWTH-1:0]                 alu_csr__pc_o,
    output  logic[AWTH-1:0]                 alu_csr__npc_o,
    output  logic[31:0]                     alu_csr__instr_o,
    output  logic                           alu_csr__write_fflags_o,
    output  logic                           alu_csr__dirty_fp_state_o,
    output  logic[4:0]                      alu_csr__fflags_o,

    output  logic                           alu_csr__mret_o,
    output  logic                           alu_csr__sret_o,
    output  logic                           alu_csr__dret_o,
    //! If current insruction is WFI, send sleep command to csr module.
    // output  logic                           alu_ctrl__wfi_en_o,
    output  logic                           alu_csr__wfi_o,
    //! If current instruction is Fence.I, send clear I$ and continue launch next instruction cmmand.
    output  logic                           alu_ctrl__fencei_en_o,
    output  logic                           alu_ctrl__fence_en_o,
    //! If current instruction is MRET or DRET, send this command to CTRL module.
    output  logic                           alu_ctrl__sfence_vma_o,
    // status of MEM and WB stages
    output  logic                           alu_ctrl__mem_act_o,
    output  logic                           alu_ctrl__wb_act_o,
    output  logic[63:0]                     alu_ctrl__wb_npc_o,
    // =====================================
    // [to ppl_dec]
    //! -----
    //! DEC module send decoded instruction to ALU module if current instruction belongs to algebra, logic, branch, and
    //! load/store class.
    input   logic                           dec_alu__ex0_avail_i,
    input   instr_cls_e                     dec_alu__instr_cls_i,
    input   logic[1:0]                      dec_alu__stage_act_i,
    input   logic[AWTH-1:0]                 dec_alu__npc_i,
    input   logic[AWTH-1:0]                 dec_alu__pc_i,
    input   logic[IWTH-1:0]                 dec_alu__instr_i,
    input   als_opcode_e                    dec_alu__als_opcode_i,
    input   jbr_opcode_e                    dec_alu__jbr_opcode_i,
    input   mem_opcode_e                    dec_alu__mem_opcode_i,
    input   amo_t                           dec_alu__amo_opcode_i,
    input   sys_opcode_e                    dec_alu__sys_opcode_i,
    input   logic                           dec_alu__sign_ext_i,
    input   lrsc_cmd_e                      dec_alu__lrsc_cmd_i,
    input   logic                           dec_alu__rls_i,
    input   logic                           dec_alu__acq_i,
    input   csr_cmd_e                       dec_alu__csr_cmd_i,
    input   logic[11:0]                     dec_alu__csr_addr_i,
    input   logic                           dec_alu__csr_imm_sel_i,
    input   logic[4:0]                      dec_alu__rs1_idx_i,
    input   logic[DWTH-1:0]                 dec_alu__rs1_data_i,
    input   logic[4:0]                      dec_alu__rs2_idx_i,
    input   logic[DWTH-1:0]                 dec_alu__rs2_data_i,
    input   logic                           dec_alu__rdst_en_i,
    input   rdst_src_e                      dec_alu__rdst_src_sel_i,
    input   logic[4:0]                      dec_alu__rdst_idx_i,
    input   logic[DWTH-1:0]                 dec_alu__jbr_base_i,
    input   logic[DWTH-1:0]                 dec_alu__st_data_i,
    input   logic[AWTH-1:0]                 dec_alu__imm_i,
    input   size_e                          dec_alu__size_i,
    input   logic                           dec_alu__fp_rdst_en_i,
    input   logic[4:0]                      dec_alu__fp_rdst_idx_i,
    input   logic[FLEN-1:0]                 dec_alu__fp_result_i,
    input   logic[4:0]                      dec_alu__fp_status_i, 

    //modified by liushenghuan
    input   exception_t                     dec_alu__exceptions_i,
    input   logic                           dec_alu__only_word_i,
    input   logic                           dec_alu__is_compressed_i,
    // block mgr
    output  logic                           alu_dec__mem_blk_en_o,
    output  logic[4:0]                      alu_dec__mem_blk_idx_o,
    output  logic                           alu_dec__mem_blk_f_or_x_o,
    //! bypass signals from ALU module
    output  bp_bus_t                        alu_dec__bp0_rdst_o,
    output  bp_bus_t                        alu_dec__bp1_rdst_o,
    output  logic                           alu_dec__bp0_f_or_x_o,
    output  logic                           alu_dec__bp1_f_or_x_o,
    // =====================================
    // [to ppl_mdu]
    // status of MDU
    input   logic                           mdu_alu__mul_wb_busy_i,
    input   logic                           mdu_alu__div_wb_busy_i,
    // =====================================
    // [to ppl_reg]
    output  logic                           alu_reg__rdst_en_o,
    output  logic[4:0]                      alu_reg__rdst_idx_o,
    output  logic[DWTH-1:0]                 alu_reg__rdst_data_o,
    // =====================================
    // [to ppl_fp_reg]
    output  logic                           alu_fp_reg__rdst_en_o,
    output  logic[4:0]                      alu_fp_reg__rdst_idx_o,
    output  logic[DWTH-1:0]                 alu_fp_reg__rdst_data_o,
    // =====================================
    // [to LSU]
    output  logic                           ppl_dmem__vld_o,
    output  logic[AWTH-1:0]                 ppl_dmem__addr_o,
    output  logic[DWTH-1:0]                 ppl_dmem__wdata_o,
    output  size_e                          ppl_dmem__size_o,
    output  mem_opcode_e                    ppl_dmem__opcode_o,
    output  amo_t                           ppl_dmem__amo_opcode_o,
    output  logic                           ppl_dmem__kill_o,
    input   logic                           dmem_ppl__hit_i,
    input   logic[DWTH-1:0]                 dmem_ppl__rdata_i,
    input   exception_t                     dmem_ppl__exception_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================


//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================

logic[5:0]                          shamt;
logic[DWTH-1:0]                     als_out;
logic[31:0]                         als_out32;
logic[DWTH-1:0]                     ex0_true_npc;
logic                               dmem_misaligned;
logic[7:0]                          dmem_strb;
logic                               ex0_dmem_vld;
logic                               ex0_dmem_we;
logic[AWTH-1:0]                     ex0_dmem_addr;
logic[DWTH-1:0]                     ex0_dmem_wdata;
size_e                              ex0_dmem_size;  
amo_t                               ex0_dmem_amo_opcode;   
logic[DWTH-1:0]                     ex0_dmem_operand;
mem_opcode_e                        ex0_dmem_opcode;
logic[DWTH/8-1:0]                   ex0_dmem_wstrb;
logic[DWTH-1:0]                     ex0_rdst_from_alsc;
logic                               sys_instr_avail;
logic                               mem_stall;
logic                               mem_kill;
logic                               mem_act_unkilled;
logic                               mem_act;
logic                               mem_avail;
logic                               mem_accpt;
logic[1:0]                          mem_stage_act;
logic[AWTH-1:0]                     mem_pc;
logic[AWTH-1:0]                     mem_npc;
logic[IWTH-1:0]                     mem_instr;
logic                               mem_rdst_en;
rdst_src_e                          mem_rdst_src_sel;
logic[4:0]                          mem_rdst_idx;
logic[4:0]                          mem_fp_rdst_idx; 
logic[4:0]                          mem_fp_status;
logic[DWTH-1:0]                     mem_rdst_from_alsc;
logic                               mem_sign_ext;
logic                               mem_dmem_vld;
logic                               mem_dmem_we;
logic[AWTH-1:0]                     mem_dmem_addr;
logic[DWTH-1:0]                     mem_dmem_wdata;
logic[DWTH/8-1:0]                   mem_dmem_wstrb;
logic[2:0]                          mem_dmem_offset;
logic[DWTH-1:0]                     mem_dmem_operand;
amo_t                               mem_dmem_amo_opcode;
size_e                              mem_dmem_size;
instr_cls_e                         mem_instr_cls;
sys_opcode_e                        mem_sys_opcode;
mem_opcode_e                        mem_mem_opcode;
csr_cmd_e                           mem_csr_cmd;
logic[11:0]                         mem_csr_addr;
logic[4:0]                          mem_rs1_idx;
logic                               mem_csr_imm_sel;
logic[DWTH-1:0]                     mem_rs1_data;
logic                               mem_fp_rdst_en;
logic                               mem_csr_blk_en;
logic                               mem_lsu_blk_en;

exception_t                         mem_exceptions;
exception_t                         mem_ex_from_alu;
mem_opcode_e                        mem_dmem_opcode;
// logic[DWTH-1:0]                     mem_rdst_from_alsc;
logic                               ppl_dmem__vld_dly1;
logic                               dmem_miss;
logic                               dmem_recall_dly;
logic                               dmem_recall;
logic[DWTH-1:0]                     dmem_rdata_dly1;
logic[DWTH-1:0]                     dmem_rdata;
logic                               dmem_hit_dly1;
logic                               wb_stall;
logic                               wb_kill;
logic                               wb_act_unkilled;
logic                               wb_act;
logic                               wb_avail;
logic                               wb_accpt;
logic[AWTH-1:0]                     wb_pc;
logic[AWTH-1:0]                     wb_npc;
logic[IWTH-1:0]                     wb_instr;
logic[1:0]                          wb_stage_act;
logic                               wb_rdst_en;
rdst_src_e                          wb_rdst_src_sel;
logic[4:0]                          wb_rdst_idx;
logic                               wb_fp_rdst_en;
logic[4:0]                          wb_fp_rdst_idx;
logic[4:0]                          wb_fp_status;
logic[DWTH-1:0]                     wb_rdst_from_alsc;
logic[2:0]                          wb_dmem_offset;
size_e                              wb_dmem_size;
mem_opcode_e                        wb_dmem_opcode;
logic                               wb_sign_ext;
logic[DWTH-1:0]                     dmem_rdata_sr;
logic[DWTH-1:0]                     wb_dmem_rdata;
instr_cls_e                         wb_instr_cls;
sys_opcode_e                        wb_sys_opcode;
csr_cmd_e                           wb_csr_cmd;
logic[11:0]                         wb_csr_addr;
logic[4:0]                          wb_rs1_idx;
logic                               wb_csr_imm_sel;
logic[DWTH-1:0]                     wb_rs1_data;
logic                               wb_fp_op;
exception_t                         wb_exceptions;

logic                               bp0_alu_en;
logic                               bp1_alu_en;
logic                               bp0_fpu_en;
logic                               bp1_fpu_en;
logic                               mem_single_prec;
logic                               wb_single_prec;
//======================================================================================================================
// Instance
//======================================================================================================================

// -----
// [Phase: EX0]

// Process the algebra, logic, shift operation according to decoded content.
assign shamt = dec_alu__rs2_data_i[5:0];
always_comb begin
    als_out32 = 32'b0;
    case (dec_alu__als_opcode_i)
        ALS_OP_ADD : begin
            als_out32 = dec_alu__rs1_data_i[31:0] + dec_alu__rs2_data_i[31:0]; 
            if(dec_alu__only_word_i)
                als_out = {{32{als_out32[31]}},als_out32};
            else
                als_out = dec_alu__rs1_data_i + dec_alu__rs2_data_i;
        end
        ALS_OP_SLL : begin 
            als_out32 = dec_alu__rs1_data_i[31:0] << shamt[4:0];  
            if(dec_alu__only_word_i)
                als_out = {{32{als_out32[31]}},als_out32};
            else
                als_out = dec_alu__rs1_data_i << shamt;
        end
        ALS_OP_XOR : als_out = dec_alu__rs1_data_i ^ dec_alu__rs2_data_i;
        ALS_OP_SRL : begin
            als_out32 = dec_alu__rs1_data_i[31:0] >> shamt[4:0];  
            if(dec_alu__only_word_i)
                als_out = {{32{als_out32[31]}},als_out32};
            else
                als_out = dec_alu__rs1_data_i >> shamt;
        end
        ALS_OP_OR : als_out = dec_alu__rs1_data_i | dec_alu__rs2_data_i;
        ALS_OP_AND : als_out = dec_alu__rs1_data_i & dec_alu__rs2_data_i;
        ALS_OP_SEQ : als_out = {63'b0, dec_alu__rs1_data_i == dec_alu__rs2_data_i};
        ALS_OP_SNE : als_out = {63'b0, dec_alu__rs1_data_i != dec_alu__rs2_data_i};
        ALS_OP_SUB : begin
            als_out32 = dec_alu__rs1_data_i[31:0] - dec_alu__rs2_data_i[31:0];
            if(dec_alu__only_word_i)
                als_out = {{32{als_out32[31]}},als_out32};
            else
                als_out = dec_alu__rs1_data_i - dec_alu__rs2_data_i;
        end
        ALS_OP_SRA : begin
            als_out32 = $signed(dec_alu__rs1_data_i[31:0]) >>> shamt[4:0];
            if(dec_alu__only_word_i)
                als_out = {{32{als_out32[31]}},als_out32};
            else
                als_out = $signed(dec_alu__rs1_data_i) >>> shamt;
        end
        ALS_OP_SLT : als_out = {63'b0, $signed(dec_alu__rs1_data_i) < $signed(dec_alu__rs2_data_i)};
        ALS_OP_SGE : als_out = {63'b0, $signed(dec_alu__rs1_data_i) >= $signed(dec_alu__rs2_data_i)};
        ALS_OP_SLTU : als_out = {63'b0, dec_alu__rs1_data_i < dec_alu__rs2_data_i};
        ALS_OP_SGEU : als_out = {63'b0, dec_alu__rs1_data_i >= dec_alu__rs2_data_i};
        default : als_out = 64'h0;
    endcase
end


always_comb begin
    if(dec_alu__instr_cls_i == INSTR_CLS_JBR && !(dec_alu__jbr_opcode_i == JBR_OP_BRANCH && !als_out[0])) begin
        ex0_true_npc = dec_alu__jbr_base_i + dec_alu__imm_i;
    end else begin
        ex0_true_npc = dec_alu__pc_i + (dec_alu__is_compressed_i ? 'd2 : 'd4);
    end
end

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        alu_x__mispred_en_o <= `TCQ 1'b0;
    end else begin
        alu_x__mispred_en_o <= `TCQ dec_alu__ex0_avail_i && (dec_alu__npc_i != ex0_true_npc);
    end
end

always_ff @(posedge clk_i) begin
    alu_x__mispred_npc_o <= `TCQ ex0_true_npc;
    alu_x__mispred_pc_o <= `TCQ dec_alu__pc_i;
end

logic is_branch,is_jalr;
assign is_branch = dec_alu__instr_cls_i == INSTR_CLS_JBR && dec_alu__jbr_opcode_i == JBR_OP_BRANCH; 
assign is_jalr   = dec_alu__instr_cls_i == INSTR_CLS_JBR && dec_alu__jbr_opcode_i == JBR_OP_JALR; 

assign bht_update_o.vld    = dec_alu__ex0_avail_i && is_branch;
assign bht_update_o.pc     = dec_alu__pc_i;
assign bht_update_o.taken  = als_out[0];

assign btb_update_o.vld    = dec_alu__ex0_avail_i && (dec_alu__npc_i != ex0_true_npc) && is_jalr;
assign btb_update_o.pc     = dec_alu__pc_i;
assign btb_update_o.target_address = ex0_true_npc;

assign ex0_rdst_from_alsc = (dec_alu__rdst_src_sel_i == RDST_SRC_FPU) ? dec_alu__fp_result_i : als_out; 

// suppose when mdu send wb busy signal, at the moment lsu send hit signal
// we must guarantee that we won't send valid signal to lsu until mdu deassert busy signal
assign ex0_dmem_vld = dec_alu__ex0_avail_i && (dec_alu__instr_cls_i == INSTR_CLS_MEM) && (dec_alu__mem_opcode_i != MEM_OP_FENCE);

assign ex0_dmem_addr = als_out;
assign ex0_dmem_wdata = dec_alu__st_data_i;
assign ex0_dmem_size  = dec_alu__size_i;
assign ex0_dmem_amo_opcode = dec_alu__amo_opcode_i;
assign ex0_dmem_opcode = dec_alu__mem_opcode_i;

// access the DMEM.
assign ppl_dmem__vld_o = (dmem_recall) ? mem_dmem_vld : ex0_dmem_vld;
assign ppl_dmem__addr_o = (dmem_recall) ? mem_dmem_addr: ex0_dmem_addr;
assign ppl_dmem__wdata_o = (dmem_recall) ? mem_dmem_wdata : ex0_dmem_wdata;
assign ppl_dmem__size_o = (dmem_recall) ? mem_dmem_size: ex0_dmem_size;
assign ppl_dmem__opcode_o = (dmem_recall) ? mem_dmem_opcode : ex0_dmem_opcode;
assign ppl_dmem__amo_opcode_o = (dmem_recall) ? mem_dmem_amo_opcode : ex0_dmem_amo_opcode;
assign ppl_dmem__kill_o = ctrl_x__mem_kill_i;
// -----
// [Phase: MEM]
assign mem_stall = dmem_miss || mdu_alu__mul_wb_busy_i || mdu_alu__div_wb_busy_i;
assign mem_kill = ctrl_x__mem_kill_i || !mem_stage_act[0];

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        mem_act_unkilled <= `TCQ 1'b0;
    end else begin
        mem_act_unkilled <= `TCQ mem_accpt ? dec_alu__ex0_avail_i : mem_act;
    end
end
assign mem_act = mem_act_unkilled && !mem_kill;
assign mem_avail = mem_act && !mem_stall && wb_accpt; //TODO: wb_accpt
assign mem_accpt = !mem_act || mem_avail;

assign alu_ctrl__mem_act_o = mem_act;
assign alu_dec__mem_accpt_o = mem_accpt;

always_ff @(posedge clk_i) begin
    if(dec_alu__ex0_avail_i) begin
        mem_stage_act[0] <= `TCQ dec_alu__stage_act_i[0];
        mem_stage_act[1] <= `TCQ dec_alu__stage_act_i[1];
        mem_pc <= `TCQ dec_alu__pc_i;
        mem_npc <= `TCQ dec_alu__npc_i;
        mem_instr <= `TCQ dec_alu__instr_i;
        mem_rdst_en <= `TCQ dec_alu__rdst_en_i;
        mem_rdst_src_sel <= `TCQ dec_alu__rdst_src_sel_i;
        mem_rdst_idx <= `TCQ dec_alu__rdst_idx_i;
        mem_rdst_from_alsc <= `TCQ ex0_rdst_from_alsc;
        mem_sign_ext <= `TCQ dec_alu__sign_ext_i;
        mem_dmem_vld <= `TCQ ex0_dmem_vld;
        mem_dmem_we <= `TCQ ex0_dmem_we;
        mem_dmem_addr <= `TCQ ex0_dmem_addr;
        mem_dmem_wdata <= `TCQ ex0_dmem_wdata;
        mem_dmem_wstrb <= `TCQ ex0_dmem_wstrb;
        mem_dmem_size <= `TCQ ex0_dmem_size;
        mem_dmem_offset <= `TCQ als_out[2:0];
        mem_ex_from_alu <= `TCQ dec_alu__exceptions_i;
        mem_dmem_opcode <= `TCQ ex0_dmem_opcode;
        mem_dmem_amo_opcode <= `TCQ ex0_dmem_amo_opcode;

        // for system instr and csr operation
        mem_instr_cls <= dec_alu__instr_cls_i;
        mem_sys_opcode <= dec_alu__sys_opcode_i;
        mem_mem_opcode <= dec_alu__mem_opcode_i;
        mem_csr_cmd <= dec_alu__csr_cmd_i;
        mem_csr_addr <= dec_alu__csr_addr_i;
        mem_rs1_idx <= dec_alu__rs1_idx_i;
        mem_csr_imm_sel <= dec_alu__csr_imm_sel_i;
        mem_rs1_data <= dec_alu__rs1_data_i;

        mem_fp_rdst_en <= dec_alu__fp_rdst_en_i;
        mem_fp_rdst_idx <= dec_alu__fp_rdst_idx_i;
        mem_fp_status <= dec_alu__fp_status_i;
    end
end

assign mem_single_prec = (mem_dmem_opcode == MEM_OP_LD_FP) && (mem_dmem_size == SIZE_WORD);
// Generate the data memory access recall signal
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        ppl_dmem__vld_dly1 <= `TCQ 1'b0;
    end else begin
        ppl_dmem__vld_dly1 <= `TCQ ppl_dmem__vld_o;
    end
end
assign dmem_miss = ppl_dmem__vld_dly1 && !dmem_ppl__hit_i;

always_ff @(posedge clk_i) begin
    if(dec_alu__ex0_avail_i) begin
        dmem_recall_dly <= `TCQ 1'b1;
    end else begin
        dmem_recall_dly <= `TCQ dmem_recall;
    end
end
assign dmem_recall = dmem_recall_dly && dmem_miss && (!mem_kill);

// read data from D cache
always_ff @(posedge clk_i) begin
    if(`DFF_IS_R(rst_i)) begin
        dmem_rdata <= '0;
    end else begin 
        if(dmem_ppl__hit_i && ppl_dmem__vld_dly1) begin
            dmem_rdata <= `TCQ dmem_ppl__rdata_i;
        end else begin
            dmem_rdata <= `TCQ dmem_rdata;
        end
    end
end

// exception from D cache
always_comb begin: gen_mem_ex
    mem_exceptions = '0;
    if(mem_ex_from_alu.valid) begin
        mem_exceptions =  mem_ex_from_alu;
    end else if(dmem_ppl__hit_i && ppl_dmem__vld_dly1 && dmem_ppl__exception_i.valid) begin
        mem_exceptions =  dmem_ppl__exception_i;
    end
end

// output the rdst status to help hazard judgement logic
assign mem_csr_blk_en = mem_act && (mem_rdst_src_sel == RDST_SRC_CSR) && mem_rdst_en; 
assign mem_lsu_blk_en = mem_act && (mem_rdst_src_sel == RDST_SRC_MEM) && (mem_rdst_en || mem_fp_rdst_en); 
assign alu_dec__mem_blk_en_o = mem_lsu_blk_en || mem_csr_blk_en; 
assign alu_dec__mem_blk_f_or_x_o = mem_rdst_en;
assign alu_dec__mem_blk_idx_o = mem_rdst_en ? mem_rdst_idx : mem_fp_rdst_idx;

// -----
// [Phase: WB]
assign wb_stall = 1'b0;
assign wb_kill = !wb_stage_act[1] || ctrl_x__wb_kill_i;

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        wb_act_unkilled <= `TCQ 1'b0;
    end else begin
        wb_act_unkilled <= `TCQ mem_avail; //wb_accpt ? mem_avail : wb_act;
    end
end
assign wb_act = wb_act_unkilled && !wb_kill;
assign wb_avail = wb_act && !wb_exceptions.valid; //wb_act && !wb_stall;
assign wb_accpt = 1'b1;

assign alu_ctrl__wb_act_o = wb_act;
assign alu_ctrl__wb_npc_o = wb_npc;

always_ff @(posedge clk_i) begin
    if(mem_avail) begin
        wb_pc <= `TCQ mem_pc;
        wb_npc <= `TCQ mem_npc;
        wb_instr <= `TCQ mem_instr;
        wb_stage_act[0] <= mem_stage_act[0];
        wb_stage_act[1] <= mem_stage_act[1];
        wb_rdst_en <= `TCQ mem_rdst_en;
        wb_rdst_src_sel <= `TCQ mem_rdst_src_sel;
        wb_rdst_idx <= `TCQ mem_rdst_idx;
        wb_rdst_from_alsc <= `TCQ mem_rdst_from_alsc;
        wb_dmem_offset <= `TCQ mem_dmem_offset;
        wb_dmem_size <= `TCQ mem_dmem_size;
        wb_dmem_opcode <= `TCQ mem_dmem_opcode;
        wb_single_prec <= mem_single_prec;
        wb_sign_ext <= `TCQ mem_sign_ext;
        wb_fp_rdst_en <= mem_fp_rdst_en;
        wb_fp_rdst_idx <= mem_fp_rdst_idx;
        wb_fp_status <= mem_fp_status;

        //for system instr
        wb_instr_cls <= mem_instr_cls;
        wb_sys_opcode <= mem_sys_opcode;
        wb_csr_cmd <= mem_csr_cmd;
        wb_csr_addr <= mem_csr_addr;
        wb_rs1_idx <= mem_rs1_idx;
        wb_csr_imm_sel <= mem_csr_imm_sel;
        wb_rs1_data <= mem_rs1_data;

        wb_exceptions <= mem_exceptions;
    end
end

//======================================================================================================================
// generate write back data
//======================================================================================================================
always_comb begin
    dmem_rdata_sr = dmem_rdata >> (8*wb_dmem_offset);
    case(wb_dmem_size)
        SIZE_BYTE: begin wb_dmem_rdata = {wb_sign_ext ? {56{dmem_rdata_sr[7]}}  : 56'h0, dmem_rdata_sr[7:0]}; end
        SIZE_HALF: begin wb_dmem_rdata = {wb_sign_ext ? {48{dmem_rdata_sr[15]}} : 48'h0, dmem_rdata_sr[15:0]}; end
        SIZE_WORD: begin wb_dmem_rdata = {wb_sign_ext ? (wb_single_prec ? {32{1'b1}} : {32{dmem_rdata_sr[31]}}) : 32'h0, dmem_rdata_sr[31:0]}; end
        default: begin wb_dmem_rdata = dmem_rdata; end
    endcase
end

always_comb begin: gen_wb
    alu_reg__rdst_data_o = '0;
    alu_fp_reg__rdst_data_o = '0;
    if(wb_rdst_src_sel == RDST_SRC_MEM) begin
        alu_reg__rdst_data_o = wb_dmem_rdata;
        alu_fp_reg__rdst_data_o = wb_dmem_rdata;
    end else if(wb_rdst_src_sel == RDST_SRC_CSR) begin
        alu_reg__rdst_data_o = csr_alu__rdata_i;
    end else begin
        alu_reg__rdst_data_o = wb_rdst_from_alsc;
        alu_fp_reg__rdst_data_o = wb_rdst_from_alsc;
    end
end
assign alu_reg__rdst_en_o = wb_avail && wb_rdst_en;
assign alu_reg__rdst_idx_o = wb_rdst_idx;

assign alu_fp_reg__rdst_en_o = wb_avail && wb_fp_rdst_en;
assign alu_fp_reg__rdst_idx_o = wb_fp_rdst_idx;
//======================================================================================================================
// commit exceptions to ctrl module
//======================================================================================================================
always_comb begin
    alu_csr__ex_o = '0;
    // If there exists exception at phase[IF0], throw out this exception.
    if(wb_act) begin
        alu_csr__ex_o = wb_exceptions;
    end
end

assign alu_csr__pc_o = wb_pc; 
assign alu_csr__npc_o = wb_npc;
assign alu_csr__instr_o = wb_instr;
//======================================================================================================================
// system instruction interface 
//======================================================================================================================
assign sys_instr_avail = wb_act && wb_instr_cls == INSTR_CLS_SYS;

// assign alu_ctrl__wfi_en_o = sys_instr_avail && wb_sys_opcode== SYS_OP_WFI;
assign alu_csr__wfi_o = sys_instr_avail && wb_sys_opcode== SYS_OP_WFI;
assign alu_csr__mret_o = sys_instr_avail && wb_sys_opcode== SYS_OP_MRET;
assign alu_csr__sret_o = sys_instr_avail && wb_sys_opcode == SYS_OP_SRET;
assign alu_csr__dret_o = sys_instr_avail && wb_sys_opcode== SYS_OP_DRET;
assign alu_ctrl__sfence_vma_o = sys_instr_avail && wb_sys_opcode== SYS_OP_SFENCE_VMA;
assign alu_ctrl__fencei_en_o = sys_instr_avail && wb_sys_opcode == SYS_OP_FENCEI;
assign alu_ctrl__fence_en_o = (wb_act && wb_instr_cls == INSTR_CLS_MEM) && (wb_dmem_opcode == MEM_OP_FENCE);
// assign alu_ctrl__fence_en_o = 1'b0; 
//======================================================================================================================
// FPU interface 
//======================================================================================================================
assign wb_fp_op = (wb_instr_cls == INSTR_CLS_FPU) || 
        (wb_instr_cls == INSTR_CLS_MEM && (wb_dmem_opcode == MEM_OP_ST_FP || wb_dmem_opcode == MEM_OP_LD_FP));
assign alu_csr__dirty_fp_state_o = wb_act && wb_fp_op;
assign alu_csr__write_fflags_o = wb_act && (wb_instr_cls == INSTR_CLS_FPU); 
assign alu_csr__fflags_o = wb_fp_status;
//======================================================================================================================
// CSR interface 
//======================================================================================================================
assign alu_csr__valid_o = wb_act && (wb_instr_cls == INSTR_CLS_SYS) &&(wb_sys_opcode== SYS_OP_CSR);
assign alu_csr__addr_o = wb_csr_addr; 
assign alu_csr__cmd_o = (wb_csr_cmd == CSR_RW) ? LB_CMD_WR
                           : (wb_csr_cmd == CSR_RS && wb_rs1_idx!= 5'h0) ? LB_CMD_SET
                           : (wb_csr_cmd == CSR_RC && wb_rs1_idx!= 5'h0) ? LB_CMD_CLR
                           : LB_CMD_READ;
assign alu_csr__wdata_o = wb_csr_imm_sel ? {59'h0, wb_rs1_idx} : wb_rs1_data;
//======================================================================================================================
// forward data from exe and mem stage to decode stage
//======================================================================================================================
// generate forward signal in EX0
assign bp0_alu_en = dec_alu__rdst_en_i && (dec_alu__rdst_idx_i != 5'h0) && (dec_alu__rdst_src_sel_i == RDST_SRC_ALU || dec_alu__rdst_src_sel_i == RDST_SRC_FPU);
assign bp0_fpu_en = dec_alu__fp_rdst_en_i && (dec_alu__rdst_src_sel_i == RDST_SRC_FPU);

assign alu_dec__bp0_rdst_o.en = dec_alu__ex0_avail_i && (bp0_alu_en || bp0_fpu_en);
assign alu_dec__bp0_rdst_o.idx = bp0_fpu_en ? dec_alu__fp_rdst_idx_i : dec_alu__rdst_idx_i;
// Attention: all bypass data is 1 cycle delay than its enable and index signal.
// assign alu_dec__bp0_rdst_o.data = mem_rdst_from_alsc;
assign alu_dec__bp0_rdst_o.data = ex0_rdst_from_alsc;
assign alu_dec__bp0_f_or_x_o = bp0_alu_en;

// generate forwardsignal in MEM
assign bp1_alu_en = mem_rdst_en && (mem_rdst_idx!= 5'h0) && (mem_rdst_src_sel == RDST_SRC_ALU || mem_rdst_src_sel == RDST_SRC_FPU);
assign bp1_fpu_en = mem_fp_rdst_en && (mem_rdst_src_sel == RDST_SRC_FPU);

assign alu_dec__bp1_rdst_o.en = mem_act && (bp1_alu_en || bp1_fpu_en);
assign alu_dec__bp1_rdst_o.idx = bp1_fpu_en ? mem_fp_rdst_idx : mem_rdst_idx;
// Attention: all bypass data is 1 cycle delay than its enable and index signal.
// assign alu_dec__bp1_rdst_o.data = rdst_src_sel_wb == RDST_SRC_MEM ? dmem_ppl__rdata_i : rdst_from_alsc_wb;
assign alu_dec__bp1_rdst_o.data = mem_rdst_from_alsc;
assign alu_dec__bp1_f_or_x_o = bp1_alu_en;
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_alu

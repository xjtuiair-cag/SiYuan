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

    input   logic[63:0]                     ret_addr_i,
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
    output  logic[31:0]                     alu_csr__instr_o,
    output  logic                           alu_csr__write_fflags_o,
    output  logic                           alu_csr__dirty_fp_state_o,
    output  logic[4:0]                      alu_csr__fflags_o,
    // retire instruction at write back stage
    output  logic                           alu_csr__retire_en_o,
    output  logic[AWTH-1:0]                 alu_csr__retire_npc_o,
    output  logic                           alu_csr__retire_is_jbr_o,
    output  logic                           alu_csr__mispred_o,
    output  logic                           alu_csr__dc_access_o,
    output  logic                           alu_csr__dc_miss_o,

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
    output  logic                           alu_ctrl__ret_addr_match_o,
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
    input   logic                           dec_alu__ex0_act_i,
    input   instr_cls_e                     dec_alu__instr_cls_i,
    input   logic[1:0]                      dec_alu__stage_act_i,
    // input   logic[AWTH-1:0]                 dec_alu__npc_i,
    input   logic[AWTH-1:0]                 dec_alu__ras_addr_i,
    input   logic[AWTH-1:0]                 dec_alu__btb_addr_i,
    input   npc_type_e                      dec_alu__npc_type_i,
    input   logic[AWTH-1:0]                 dec_alu__pc_i,
    input   logic[IWTH-1:0]                 dec_alu__instr_i,
    input   als_opcode_e                    dec_alu__als_opcode_i,
    input   jbr_opcode_e                    dec_alu__jbr_opcode_i,
    input   mem_opcode_e                    dec_alu__mem_opcode_i,
    input   amo_t                           dec_alu__amo_opcode_i,
    input   sys_opcode_e                    dec_alu__sys_opcode_i,
    input   logic                           dec_alu__sign_ext_i,
    input   csr_cmd_e                       dec_alu__csr_cmd_i,
    input   logic[11:0]                     dec_alu__csr_addr_i,
    input   logic                           dec_alu__csr_imm_sel_i,
    input   logic[4:0]                      dec_alu__rs1_idx_i,
    input   logic[DWTH-1:0]                 dec_alu__rs1_data_i,
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

    input   exception_t                     dec_alu__exceptions_i,
    input   logic                           dec_alu__only_word_i,
    input   logic                           dec_alu__is_compressed_i,
    input   logic                           dec_alu__waw_stall_i,
    input   logic                           dec_alu__ex0_stall_i,

    output  logic                           alu_dec__tlb_miss_block_o,           
    output  logic                           alu_dec__dc_rsp_block_o,
    // block mgr
    output  logic                           alu_dec__mem0_blk_en_o,
    output  logic[4:0]                      alu_dec__mem0_blk_idx_o,
    output  logic                           alu_dec__mem0_blk_f_or_x_o,
    output  logic                           alu_dec__mem1_blk_en_o,
    output  logic[4:0]                      alu_dec__mem1_blk_idx_o,
    output  logic                           alu_dec__mem1_blk_f_or_x_o,
    //! bypass signals from ALU module
    output  bp_bus_t                        alu_dec__bp0_rdst_o,
    output  bp_bus_t                        alu_dec__bp1_rdst_o,
    output  bp_bus_t                        alu_dec__bp2_rdst_o,
    output  logic                           alu_dec__bp0_f_or_x_o,
    output  logic                           alu_dec__bp1_f_or_x_o,
    output  logic                           alu_dec__bp2_f_or_x_o,
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
    // [address translation request]
    output  logic                           ppl_mmu__req_o,
    output  logic[63:0]                     ppl_mmu__vaddr_o,
    output  logic                           ppl_mmu__is_store_o,
    input   logic                           mmu_ppl__dtlb_hit_i,
    input   logic                           mmu_ppl__valid_i,
    input   logic[63:0]                     mmu_ppl__paddr_i,
    input   exception_t                     mmu_ppl__ex_i,
    // =====================================
    // [to D Cache]
    output  logic                           ppl_dmem__req_o,
    input   logic                           dmem_ppl__rsp_i,
    output  dcache_req_t                    ppl_dmem__req_bits_o,
    input   dcache_rsp_t                    dmem_ppl__rsp_bits_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================


//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
logic[5:0]                          shamt;
logic                               br_out;
logic[DWTH-1:0]                     als_out;
logic[31:0]                         als_out32;
logic[DWTH-1:0]                     ex0_true_npc;
logic                               dmem_misaligned;
logic[7:0]                          dmem_strb;
logic                               ex0_dmem_vld;
logic[AWTH-1:0]                     ex0_dmem_addr;
logic[DWTH-1:0]                     ex0_dmem_wdata;
size_e                              ex0_dmem_size;  
amo_t                               ex0_dmem_amo_opcode;   
logic[DWTH-1:0]                     ex0_dmem_operand;
mem_opcode_e                        ex0_dmem_opcode;
logic[DWTH-1:0]                     ex0_rdst_from_alsc;
exception_t                         ex0_exception; 
logic[AWTH-1:0]                     ex0_pred_npc;
logic                               sys_instr_avail;
logic                               mem0_stall;
logic                               mem0_kill;
logic                               mem0_act_unkilled;
logic                               mem0_act;
logic                               mem0_avail;
logic                               mem0_accpt;
logic[1:0]                          mem0_stage_act;
logic[AWTH-1:0]                     mem0_pc;
logic                               mem0_access_dc;
logic                               mem0_access_dc_done;  
logic                               mem0_dc_hit_dly;
logic                               mem0_first_cycle;
logic[DWTH-1:0]                     mem0_rd_data_temp;    
logic[AWTH-1:0]                     mem0_npc;
logic[AWTH-1:0]                     mem0_true_npc;
logic[IWTH-1:0]                     mem0_instr;
logic                               mem0_rdst_en;
rdst_src_e                          mem0_rdst_src_sel;
logic[4:0]                          mem0_rdst_idx;
logic[4:0]                          mem0_fp_rdst_idx; 
logic[4:0]                          mem0_fp_status;
logic[DWTH-1:0]                     mem0_rdst_from_alsc;
logic                               mem0_sign_ext;
logic                               mem0_dmem_vld;
logic                               mem0_dmem_we;
logic[AWTH-1:0]                     mem0_dmem_addr;
logic[DWTH-1:0]                     mem0_dmem_wdata;
logic[2:0]                          mem0_dmem_offset;
logic[DWTH-1:0]                     mem0_dmem_operand;
amo_t                               mem0_dmem_amo_opcode;
size_e                              mem0_dmem_size;
instr_cls_e                         mem0_instr_cls;
sys_opcode_e                        mem0_sys_opcode;
mem_opcode_e                        mem0_mem_opcode;
csr_cmd_e                           mem0_csr_cmd;
logic[11:0]                         mem0_csr_addr;
logic[4:0]                          mem0_rs1_idx;
logic                               mem0_csr_imm_sel;
logic[DWTH-1:0]                     mem0_rs1_data;
logic                               mem0_fp_rdst_en;
logic                               mem0_csr_blk_en;
logic                               mem0_lsu_blk_en;
exception_t                         mem0_exceptions,mem0_exceptions_q;
exception_t                         mem0_ex_from_alu;
mem_opcode_e                        mem0_dmem_opcode;
logic                               mem0_tlb_miss_block;
logic                               mem0_dc_rsp_block;
logic                               mem0_mispred;

logic                               mem1_stall;
logic                               mem1_kill;
logic                               mem1_act_unkilled;
logic                               mem1_act;
logic                               mem1_avail;
logic                               mem1_accpt;
logic[1:0]                          mem1_stage_act;
logic[AWTH-1:0]                     mem1_pc;
logic                               mem1_access_dc;
logic                               mem1_access_dc_done;  
logic                               mem1_dc_hit_dly;
logic                               mem1_first_cycle;
logic[DWTH-1:0]                     mem1_rd_data_temp;    
logic[AWTH-1:0]                     mem1_npc;
logic[AWTH-1:0]                     mem1_true_npc;
logic[IWTH-1:0]                     mem1_instr;
logic                               mem1_rdst_en;
rdst_src_e                          mem1_rdst_src_sel;
logic[4:0]                          mem1_rdst_idx;
logic[4:0]                          mem1_fp_rdst_idx; 
logic[4:0]                          mem1_fp_status;
logic[DWTH-1:0]                     mem1_rdst_from_alsc;
logic                               mem1_sign_ext;
logic                               mem1_dmem_vld;
logic                               mem1_dmem_we;
logic[AWTH-1:0]                     mem1_dmem_addr;
logic[DWTH-1:0]                     mem1_dmem_wdata;
logic[2:0]                          mem1_dmem_offset;
logic[DWTH-1:0]                     mem1_dmem_operand;
amo_t                               mem1_dmem_amo_opcode;
size_e                              mem1_dmem_size;
instr_cls_e                         mem1_instr_cls;
sys_opcode_e                        mem1_sys_opcode;
mem_opcode_e                        mem1_mem_opcode;
csr_cmd_e                           mem1_csr_cmd;
logic[11:0]                         mem1_csr_addr;
logic[4:0]                          mem1_rs1_idx;
logic                               mem1_csr_imm_sel;
logic[DWTH-1:0]                     mem1_rs1_data;
logic                               mem1_fp_rdst_en;
logic                               mem1_csr_blk_en;
logic                               mem1_lsu_blk_en;
exception_t                         mem1_exceptions,mem1_exceptions_q;
exception_t                         mem1_ex_from_mem0;
mem_opcode_e                        mem1_dmem_opcode;
logic                               mem1_mispred;
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
logic[AWTH-1:0]                     wb_true_npc;
logic[IWTH-1:0]                     wb_instr;
logic                               wb_dc_hit;
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
logic                               wb_mispred;

logic                               bp0_alu_en;
logic                               bp1_alu_en;
logic                               bp2_alu_en;
logic                               bp0_fpu_en;
logic                               bp1_fpu_en;
logic                               bp2_fpu_en;

logic                               mem1_single_prec;
logic                               wb_single_prec;

logic [2:0]                         offset;
logic                               is_store;
logic                               is_amo;
logic                               is_load;
logic                               misaligned;
logic                               no_mdu_block;        
logic                               dmem_ppl_req_cancel;
//======================================================================================================================
// Instance
//======================================================================================================================

// -----
// [Phase: EX0]

// Process the algebra, logic, shift operation according to decoded content.
assign shamt = dec_alu__rs2_data_i[5:0];
always_comb begin
    als_out32 = 32'b0;
    unique case (dec_alu__als_opcode_i)
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
        ALS_OP_SLT :  als_out = {63'b0, $signed(dec_alu__rs1_data_i) < $signed(dec_alu__rs2_data_i)};
        ALS_OP_SLTU : als_out = {63'b0, dec_alu__rs1_data_i < dec_alu__rs2_data_i};
        default : als_out = 64'h0;
    endcase
end

always_comb begin
    unique case (dec_alu__als_opcode_i)
        ALS_OP_SEQ  : br_out = dec_alu__rs1_data_i == dec_alu__rs2_data_i;
        ALS_OP_SNE  : br_out = dec_alu__rs1_data_i != dec_alu__rs2_data_i;
        ALS_OP_SLT  : br_out = $signed(dec_alu__rs1_data_i) < $signed(dec_alu__rs2_data_i);
        ALS_OP_SGE  : br_out = $signed(dec_alu__rs1_data_i) >= $signed(dec_alu__rs2_data_i);
        ALS_OP_SLTU : br_out = dec_alu__rs1_data_i < dec_alu__rs2_data_i;
        ALS_OP_SGEU : br_out = dec_alu__rs1_data_i >= dec_alu__rs2_data_i;
        default :     br_out = 1'b0;
    endcase
end

// predict address at if2 stage
always_comb begin
    unique case(dec_alu__npc_type_i) 
        NORMAL_ADDR: begin ex0_pred_npc = dec_alu__pc_i + (dec_alu__is_compressed_i ? 4'd2 : 4'd4); end
        BTB_ADDR:    begin ex0_pred_npc = dec_alu__btb_addr_i; end
        RAS_ADDR:    begin ex0_pred_npc = dec_alu__ras_addr_i; end
        JUMP_ADDR:   begin ex0_pred_npc = dec_alu__jbr_base_i + dec_alu__imm_i; end
        default:;
    endcase
end

always_comb begin
    if(dec_alu__instr_cls_i == INSTR_CLS_JBR && !(dec_alu__jbr_opcode_i == JBR_OP_BRANCH && !br_out)) begin
        ex0_true_npc = dec_alu__jbr_base_i + dec_alu__imm_i;
    end else begin
        ex0_true_npc = dec_alu__pc_i + (dec_alu__is_compressed_i ? 4'd2 : 4'd4);
    end
end

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        alu_x__mispred_en_o <= `TCQ 1'b0;
    end else begin
        alu_x__mispred_en_o <= `TCQ dec_alu__ex0_avail_i && (ex0_pred_npc != ex0_true_npc);
    end
end


always_ff @(posedge clk_i) begin
    alu_x__mispred_npc_o <= `TCQ ex0_true_npc;
    alu_x__mispred_pc_o <= `TCQ dec_alu__pc_i;
end

logic is_branch,is_jalr;
assign is_branch = dec_alu__instr_cls_i == INSTR_CLS_JBR && dec_alu__jbr_opcode_i == JBR_OP_BRANCH; 
assign is_jalr   = dec_alu__instr_cls_i == INSTR_CLS_JBR && dec_alu__jbr_opcode_i == JBR_OP_JALR; 
// assign ret_addr_match_o = dec_alu__ex0_avail_i && is_jalr && (ret_addr_i == ex0_true_npc);
// assign alu_ctrl__ret_addr_match_o = alu_x__mispred_en_o && (alu_x__mispred_npc_o == ret_addr_i);
always_ff @(posedge clk_i) begin
    alu_ctrl__ret_addr_match_o <= `TCQ dec_alu__ex0_avail_i && is_jalr && (ret_addr_i == ex0_true_npc);
end

always_ff @(posedge clk_i) begin
    bht_update_o.vld    <= `TCQ dec_alu__ex0_avail_i && is_branch;
    bht_update_o.pc     <= `TCQ dec_alu__pc_i;
    bht_update_o.taken  <= `TCQ br_out;
    btb_update_o.vld    <= `TCQ dec_alu__ex0_avail_i && (ex0_pred_npc != ex0_true_npc) && is_jalr;
    btb_update_o.pc     <= `TCQ dec_alu__pc_i;
    btb_update_o.target_address <= `TCQ ex0_true_npc;
end

assign ex0_rdst_from_alsc = (dec_alu__rdst_src_sel_i == RDST_SRC_FPU) ? dec_alu__fp_result_i : als_out; 
// if dtlb is miss, wait until ptw is done or exception is happen
assign alu_dec__tlb_miss_block_o = 1'b0; // TODO
// request to dcache could be refused 
assign alu_dec__dc_rsp_block_o = 1'b0;

assign ex0_exception = dec_alu__exceptions_i;

// -----
// [Phase: MEM0]
assign mem0_stall = mem0_tlb_miss_block || mem0_dc_rsp_block;
assign mem0_kill = ctrl_x__mem_kill_i || !mem0_stage_act[0];

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        mem0_act_unkilled <= `TCQ 1'b0;
    end else begin
        mem0_act_unkilled <= `TCQ mem0_accpt ? dec_alu__ex0_avail_i : mem0_act;
    end
end
assign mem0_act   = mem0_act_unkilled && !mem0_kill;
assign mem0_avail = mem0_act && !mem0_stall && mem1_accpt; 
assign mem0_accpt = !mem0_act || mem0_avail;

assign alu_dec__mem_accpt_o = mem0_accpt;

always_ff @(posedge clk_i) begin
    if(dec_alu__ex0_avail_i) begin
        mem0_stage_act[0] <= `TCQ dec_alu__stage_act_i[0];
        mem0_stage_act[1] <= `TCQ dec_alu__stage_act_i[1];
        mem0_pc           <= `TCQ dec_alu__pc_i;
        mem0_npc          <= `TCQ ex0_pred_npc;
        mem0_true_npc     <= `TCQ ex0_true_npc;
        mem0_instr        <= `TCQ dec_alu__instr_i;
        mem0_rdst_en      <= `TCQ dec_alu__rdst_en_i;
        mem0_rdst_src_sel <= `TCQ dec_alu__rdst_src_sel_i;
        mem0_rdst_idx     <= `TCQ dec_alu__rdst_idx_i;
        mem0_rdst_from_alsc <= `TCQ ex0_rdst_from_alsc;
        mem0_sign_ext     <= `TCQ dec_alu__sign_ext_i;

        mem0_dmem_addr    <= `TCQ als_out;
        mem0_dmem_wdata   <= `TCQ dec_alu__st_data_i;
        mem0_dmem_size    <= `TCQ dec_alu__size_i;
        mem0_dmem_offset  <= `TCQ als_out[2:0];
        mem0_ex_from_alu  <= `TCQ ex0_exception;
        mem0_dmem_opcode  <= `TCQ dec_alu__mem_opcode_i;
        mem0_dmem_amo_opcode <= `TCQ dec_alu__amo_opcode_i;
        // for system instr and csr operation
        mem0_instr_cls    <= `TCQ dec_alu__instr_cls_i;
        mem0_sys_opcode   <= `TCQ dec_alu__sys_opcode_i;
        mem0_mem_opcode   <= `TCQ dec_alu__mem_opcode_i;
        mem0_csr_cmd      <= `TCQ dec_alu__csr_cmd_i;
        mem0_csr_addr     <= `TCQ dec_alu__csr_addr_i;
        mem0_rs1_idx      <= `TCQ dec_alu__rs1_idx_i;
        mem0_csr_imm_sel  <= `TCQ dec_alu__csr_imm_sel_i;
        mem0_rs1_data     <= `TCQ dec_alu__rs1_data_i;
        mem0_fp_rdst_en   <= `TCQ dec_alu__fp_rdst_en_i;
        mem0_fp_rdst_idx  <= `TCQ dec_alu__fp_rdst_idx_i;
        mem0_fp_status    <= `TCQ dec_alu__fp_status_i;
        mem0_mispred      <= `TCQ dec_alu__ex0_avail_i && (ex0_pred_npc != ex0_true_npc);
    end
end
// send address translation request to MMU 
// if TLB hit, hit siganl will be back at the same clock cycle
assign no_mdu_block = !((mdu_alu__mul_wb_busy_i || mdu_alu__div_wb_busy_i) && mem1_act);
assign ppl_mmu__req_o = mem0_act && no_mdu_block && (mem0_instr_cls == INSTR_CLS_MEM) && (mem0_mem_opcode != MEM_OP_FENCE);
assign ppl_mmu__vaddr_o = {mem0_dmem_addr >> 2, 2'h0};
assign ppl_mmu__is_store_o = (mem0_dmem_opcode == MEM_OP_STORE) 
                          || (mem0_dmem_opcode == MEM_OP_ST_FP) 
                          || (mem0_dmem_opcode == MEM_OP_SC) 
                          || (mem0_dmem_opcode == MEM_OP_AMO);

// if dtlb is miss, wait until ptw is done or exception is happen
assign mem0_tlb_miss_block = ppl_mmu__req_o && !mmu_ppl__dtlb_hit_i && !(mmu_ppl__valid_i && mmu_ppl__ex_i.valid) && !misaligned;
// request to dcache could be refused 
assign mem0_dc_rsp_block   = ppl_dmem__req_o && !dmem_ppl__rsp_i && !(mmu_ppl__valid_i && mmu_ppl__ex_i.valid) && !misaligned;

// exception in ex0 stage
always_comb begin
    // exception from MMU 
    mem0_exceptions = mmu_ppl__ex_i; 
    if (mem0_ex_from_alu.valid) begin
        // exception from decode stage
        mem0_exceptions = mem0_ex_from_alu;
    // misaligned access
    end else if (ppl_mmu__req_o && misaligned) begin
        mem0_exceptions.valid = 1'b1;
        mem0_exceptions.cause = is_store ? ST_ADDR_MISALIGNED : LD_ADDR_MISALIGNED;
        mem0_exceptions.tval  = mem0_dmem_addr;
    end
end
// suppose when mdu send wb busy signal, at the moment lsu send hit signal
// we must guarantee that we won't send valid signal to lsu until mdu deassert busy signal
// assign ex0_dmem_addr = als_out;
assign offset = mem0_dmem_addr[2:0]; 
assign is_store = (mem0_dmem_opcode == MEM_OP_STORE || mem0_dmem_opcode == MEM_OP_ST_FP); 
assign is_load  = (mem0_dmem_opcode == MEM_OP_LOAD  || mem0_dmem_opcode == MEM_OP_LD_FP);
assign is_amo   = (mem0_dmem_opcode == MEM_OP_SC    || mem0_dmem_opcode == MEM_OP_AMO || mem0_dmem_opcode == MEM_OP_LR);
assign misaligned = (mem0_dmem_size == SIZE_HALF)  ? (mem0_dmem_addr[0]   != 1'h0): 
                    (mem0_dmem_size == SIZE_WORD)  ? (mem0_dmem_addr[1:0] != 2'h0): 
                    (mem0_dmem_size == SIZE_DWORD) ? (mem0_dmem_addr[2:0] != 3'h0) : 1'b0;

// access the DMEM.
// assign ppl_dmem__req_o      = ppl_mmu__req_o && mmu_ppl__dtlb_hit_i && !ex0_exception.valid;
assign ppl_dmem__req_o               = ppl_mmu__req_o;

assign ppl_dmem__req_bits_o.addr_inx = mem0_dmem_addr[DCACHE_TAG_LSB-1:0];
assign ppl_dmem__req_bits_o.addr_tag = mmu_ppl__paddr_i[DCACHE_TAG_MSB-1:DCACHE_TAG_LSB];
assign ppl_dmem__req_bits_o.wdata    = mem0_dmem_wdata << (8*offset);
assign ppl_dmem__req_bits_o.size     = mem0_dmem_size;
assign ppl_dmem__req_bits_o.we       = is_store || (is_amo && mem0_dmem_opcode != MEM_OP_LR);
assign ppl_dmem__req_bits_o.be       = (mem0_dmem_size == SIZE_BYTE) ? (8'h1 << offset) : 
                                       (mem0_dmem_size == SIZE_HALF) ? (8'h3 << offset) : 
                                       (mem0_dmem_size == SIZE_WORD) ? (8'hF << offset) : 8'hFF;
assign ppl_dmem__req_bits_o.amo_op   = mem0_dmem_amo_opcode;
// kill if address translate occur exception
assign ppl_dmem__req_bits_o.kill     = mmu_ppl__ex_i.valid && mem1_first_cycle || dmem_ppl_req_cancel; 

always_ff @ (posedge clk_i) begin
    // dmem_ppl_req_cancel <= ppl_dmem__req_o && dmem_ppl__rsp_i && dec_alu__ex0_stall_i;
    dmem_ppl_req_cancel <= `TCQ ppl_dmem__req_o && dmem_ppl__rsp_i && (!mem0_avail || mem0_exceptions.valid);
end

// output the rdst status to help hazard judgement logic
assign mem0_csr_blk_en = mem0_act && (mem0_rdst_src_sel == RDST_SRC_CSR) && mem0_rdst_en; 
assign mem0_lsu_blk_en = mem0_act && (mem0_rdst_src_sel == RDST_SRC_MEM) && (mem0_rdst_en || mem0_fp_rdst_en); 
assign alu_dec__mem0_blk_en_o = mem0_lsu_blk_en || mem0_csr_blk_en; 
assign alu_dec__mem0_blk_f_or_x_o = mem0_rdst_en;
assign alu_dec__mem0_blk_idx_o = mem0_rdst_en ? mem0_rdst_idx : mem0_fp_rdst_idx;
// -----
// [Phase: MEM1]
assign mem1_stall = dmem_miss || mdu_alu__mul_wb_busy_i || mdu_alu__div_wb_busy_i;
assign mem1_kill = ctrl_x__mem_kill_i || !mem1_stage_act[0];

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        mem1_act_unkilled <= `TCQ 1'b0;
    end else begin
        mem1_act_unkilled <= `TCQ mem1_accpt ? mem0_avail : mem1_act;
    end
end
assign mem1_act   = mem1_act_unkilled && !mem1_kill;
assign mem1_avail = mem1_act && !mem1_stall && wb_accpt; 
assign mem1_accpt = !mem1_act || mem1_avail;

assign alu_ctrl__mem_act_o = mem1_act;

always_ff @(posedge clk_i) begin
    if(mem0_avail) begin
        mem1_stage_act[0] <= `TCQ mem0_stage_act[0];
        mem1_stage_act[1] <= `TCQ mem0_stage_act[1];
        mem1_pc           <= `TCQ mem0_pc;
        mem1_npc          <= `TCQ mem0_npc;
        mem1_true_npc     <= `TCQ mem0_true_npc;
        mem1_access_dc    <= `TCQ ppl_dmem__req_o && dmem_ppl__rsp_i;
        mem1_instr        <= `TCQ mem0_instr;
        mem1_rdst_en      <= `TCQ mem0_rdst_en;
        mem1_rdst_src_sel <= `TCQ mem0_rdst_src_sel;
        mem1_rdst_idx     <= `TCQ mem0_rdst_idx;
        mem1_rdst_from_alsc <= `TCQ mem0_rdst_from_alsc;
        mem1_sign_ext     <= `TCQ mem0_sign_ext;
        // mem_dmem_vld <= `TCQ ex0_dmem_vld;
        mem1_dmem_addr    <= `TCQ mem0_dmem_addr;
        mem1_dmem_size    <= `TCQ mem0_dmem_size;
        mem1_dmem_offset  <= `TCQ mem0_dmem_offset;
        mem1_ex_from_mem0 <= `TCQ mem0_exceptions;
        mem1_dmem_opcode  <= `TCQ mem0_dmem_opcode;
        mem1_dmem_amo_opcode <= `TCQ mem0_dmem_amo_opcode;

        // for system instr and csr operation
        mem1_instr_cls   <= `TCQ mem0_instr_cls  ;
        mem1_sys_opcode  <= `TCQ mem0_sys_opcode ;
        mem1_mem_opcode  <= `TCQ mem0_mem_opcode ;
        mem1_csr_cmd     <= `TCQ mem0_csr_cmd    ;
        mem1_csr_addr    <= `TCQ mem0_csr_addr   ;
        mem1_rs1_idx     <= `TCQ mem0_rs1_idx    ;
        mem1_csr_imm_sel <= `TCQ mem0_csr_imm_sel;
        mem1_rs1_data    <= `TCQ mem0_rs1_data   ;

        mem1_fp_rdst_en  <= `TCQ mem0_fp_rdst_en ;
        mem1_fp_rdst_idx <= `TCQ mem0_fp_rdst_idx;
        mem1_fp_status   <= `TCQ mem0_fp_status  ;
        mem1_mispred     <= `TCQ mem0_mispred;
    end
end

assign mem1_single_prec = (mem1_dmem_opcode == MEM_OP_LD_FP) && (mem1_dmem_size == SIZE_WORD);
// mem access dc dly
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        mem1_first_cycle <= `TCQ 1'b0;
    end else begin
        if (mem0_avail) begin
            mem1_first_cycle <= `TCQ ppl_dmem__req_o && dmem_ppl__rsp_i;
        end else begin
            mem1_first_cycle <= `TCQ 1'b0;
        end
    end
end
// to performance counter
always_ff @(posedge clk_i) begin
    alu_csr__dc_access_o <= `TCQ mem1_first_cycle;
    alu_csr__dc_miss_o   <= `TCQ mem1_first_cycle && dmem_miss;
end
// exception at mem stage
always_comb begin: gen_mem_ex
    mem1_exceptions = mem1_exceptions_q;
    if (mem1_ex_from_mem0.valid) begin
        mem1_exceptions = mem1_ex_from_mem0;
    end else if(mmu_ppl__ex_i.valid && mem1_first_cycle) begin
        mem1_exceptions = mmu_ppl__ex_i;
    end
end
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        mem1_exceptions_q <= `TCQ exception_t'(0);
    end else begin
        // if (mem0_avail) begin
        //     mem1_exceptions_q  <= `TCQ exception_t'(0);
        // end else begin
        //     mem1_exceptions_q  <= `TCQ mem1_exceptions;
        // end
        if (mem0_avail) begin
            mem1_exceptions_q  <= `TCQ exception_t'(0);
        end else begin
            mem1_exceptions_q  <= `TCQ mem1_exceptions;
        end
    end
end

// when cache hit, mem stage might be stall by mdu beacuse of write back bus confliction
// beacuse cache hit only last for one clock cycle, we must save cache hit info(including read data)   
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        mem1_access_dc_done <= `TCQ 1'b0;
    end else begin
        if (mem0_avail) begin
            mem1_access_dc_done <= `TCQ 1'b0;
        end else if (dmem_ppl__rsp_bits_i.valid) begin
            mem1_access_dc_done <= `TCQ 1'b1;
        end
    end
end
assign dmem_miss = mem1_access_dc && !dmem_ppl__rsp_bits_i.valid && !mem1_access_dc_done && !mem1_exceptions.valid;

always_ff @(posedge clk_i) begin
    mem1_dc_hit_dly <= `TCQ mem1_access_dc && dmem_ppl__rsp_bits_i.valid;
end

// read data from D cache
always_ff @(posedge clk_i) begin
    if(`DFF_IS_R(rst_i)) begin
        mem1_rd_data_temp <= `TCQ DWTH'(0);
    end else begin 
        if(mem1_dc_hit_dly) begin
            mem1_rd_data_temp <= `TCQ dmem_ppl__rsp_bits_i.rdata;
        end else begin
            mem1_rd_data_temp <= `TCQ mem1_rd_data_temp;
        end
    end
end

// output the rdst status to help hazard judgement logic
assign mem1_csr_blk_en = mem1_act && (mem1_rdst_src_sel == RDST_SRC_CSR) && mem1_rdst_en; 
assign mem1_lsu_blk_en = mem1_act && (mem1_rdst_src_sel == RDST_SRC_MEM) && (mem1_rdst_en || mem1_fp_rdst_en); 
assign alu_dec__mem1_blk_en_o = mem1_lsu_blk_en || mem1_csr_blk_en; 
assign alu_dec__mem1_blk_f_or_x_o = mem1_rdst_en;
assign alu_dec__mem1_blk_idx_o = mem1_rdst_en ? mem1_rdst_idx : mem1_fp_rdst_idx;

// -----
// [Phase: WB]
assign wb_stall = 1'b0;
assign wb_kill = !wb_stage_act[1] || ctrl_x__wb_kill_i;

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        wb_act_unkilled <= `TCQ 1'b0;
    end else begin
        wb_act_unkilled <= `TCQ mem1_avail; //wb_accpt ? mem_avail : wb_act;
    end
end
assign wb_act = wb_act_unkilled && !wb_kill;
assign wb_avail = wb_act && !wb_exceptions.valid; //wb_act && !wb_stall;
assign wb_accpt = 1'b1;

assign alu_ctrl__wb_act_o = wb_act;
assign alu_ctrl__wb_npc_o = wb_npc;

always_ff @(posedge clk_i) begin
    if(mem1_avail) begin
        wb_pc       <= `TCQ mem1_pc;
        wb_npc      <= `TCQ mem1_npc;
        wb_true_npc <= `TCQ mem1_true_npc;
        wb_instr    <= `TCQ mem1_instr;
        wb_stage_act[0] <= `TCQ mem1_stage_act[0];
        wb_stage_act[1] <= `TCQ mem1_stage_act[1];
        wb_rdst_en      <= `TCQ mem1_rdst_en;
        wb_rdst_src_sel <= `TCQ mem1_rdst_src_sel;
        wb_rdst_idx     <= `TCQ mem1_rdst_idx;
        wb_rdst_from_alsc <= `TCQ mem1_rdst_from_alsc;
        wb_dmem_offset    <= `TCQ mem1_dmem_offset;
        wb_dmem_size      <= `TCQ mem1_dmem_size;
        wb_dmem_opcode    <= `TCQ mem1_dmem_opcode;
        wb_single_prec    <= `TCQ mem1_single_prec;
        wb_sign_ext       <= `TCQ mem1_sign_ext;
        wb_fp_rdst_en     <= `TCQ mem1_fp_rdst_en;
        wb_fp_rdst_idx    <= `TCQ mem1_fp_rdst_idx;
        wb_fp_status      <= `TCQ mem1_fp_status;
        //for system instr
        wb_instr_cls    <= `TCQ mem1_instr_cls;
        wb_sys_opcode   <= `TCQ mem1_sys_opcode;
        wb_csr_cmd      <= `TCQ mem1_csr_cmd;
        wb_csr_addr     <= `TCQ mem1_csr_addr;
        wb_rs1_idx      <= `TCQ mem1_rs1_idx;
        wb_csr_imm_sel  <= `TCQ mem1_csr_imm_sel;
        wb_rs1_data     <= `TCQ mem1_rs1_data;

        wb_exceptions <= `TCQ mem1_exceptions;
        wb_dc_hit     <= `TCQ mem1_access_dc && dmem_ppl__rsp_bits_i.valid;
        wb_mispred    <= `TCQ mem1_mispred;
    end
end

//======================================================================================================================
// generate write back data
//======================================================================================================================
// MDU need to write back and occupy write back bus, at the same time dcache send cache hit back, because cache hit only
// last for one clock cycle, so we must save read data from D cache in case read data lost
// If above situation happen, the right read data come from `mem_rd_data_temp` otherwise read data come from `dmem_ppl__rsp_bits_i.rdata`
assign dmem_rdata = wb_dc_hit ? dmem_ppl__rsp_bits_i.rdata : mem1_rd_data_temp; 
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
    alu_csr__ex_o = exception_t'(0);
    // If there exists exception at phase[IF0], throw out this exception.
    if(wb_act) begin
        alu_csr__ex_o = wb_exceptions;
    end
end

assign alu_csr__pc_o = wb_pc; 
assign alu_csr__instr_o = wb_instr;
// retire instruction 
assign alu_csr__retire_en_o  = wb_act;
assign alu_csr__retire_npc_o = wb_instr_cls == INSTR_CLS_JBR ? wb_true_npc : wb_npc;
assign alu_csr__retire_is_jbr_o = wb_act && wb_instr_cls == INSTR_CLS_JBR;
assign alu_csr__mispred_o = wb_act && wb_mispred && wb_instr_cls == INSTR_CLS_JBR;
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

// assign alu_dec__bp0_rdst_o.en = dec_alu__ex0_avail_i && (bp0_alu_en || bp0_fpu_en);
assign alu_dec__bp0_rdst_o.en = dec_alu__ex0_act_i && (bp0_alu_en || bp0_fpu_en);
assign alu_dec__bp0_rdst_o.idx = bp0_fpu_en ? dec_alu__fp_rdst_idx_i : dec_alu__rdst_idx_i;
// Attention: all bypass data is 1 cycle delay than its enable and index signal.
assign alu_dec__bp0_rdst_o.data = ex0_rdst_from_alsc;
assign alu_dec__bp0_f_or_x_o = bp0_alu_en;

// generate forwardsignal in MEM0
assign bp1_alu_en = mem0_rdst_en && (mem0_rdst_idx!= 5'h0) && (mem0_rdst_src_sel == RDST_SRC_ALU || mem0_rdst_src_sel == RDST_SRC_FPU);
assign bp1_fpu_en = mem0_fp_rdst_en && (mem0_rdst_src_sel == RDST_SRC_FPU);

assign alu_dec__bp1_rdst_o.en = mem0_act && (bp1_alu_en || bp1_fpu_en);
assign alu_dec__bp1_rdst_o.idx = bp1_fpu_en ? mem0_fp_rdst_idx : mem0_rdst_idx;
// Attention: all bypass data is 1 cycle delay than its enable and index signal.
assign alu_dec__bp1_rdst_o.data = mem0_rdst_from_alsc;
assign alu_dec__bp1_f_or_x_o = bp1_alu_en;

// generate forwardsignal in MEM1
assign bp2_alu_en = mem1_rdst_en && (mem1_rdst_idx!= 5'h0) && (mem1_rdst_src_sel == RDST_SRC_ALU || mem1_rdst_src_sel == RDST_SRC_FPU);
assign bp2_fpu_en = mem1_fp_rdst_en && (mem1_rdst_src_sel == RDST_SRC_FPU);

assign alu_dec__bp2_rdst_o.en = mem1_act && (bp2_alu_en || bp2_fpu_en);
assign alu_dec__bp2_rdst_o.idx = bp2_fpu_en ? mem1_fp_rdst_idx : mem1_rdst_idx;
// Attention: all bypass data is 1 cycle delay than its enable and index signal.
assign alu_dec__bp2_rdst_o.data = mem1_rdst_from_alsc;
assign alu_dec__bp2_f_or_x_o = bp2_alu_en;
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on

endmodule : sy_ppl_alu

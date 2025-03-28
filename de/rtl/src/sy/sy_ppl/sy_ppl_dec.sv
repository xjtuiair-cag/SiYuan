// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_dec.v
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

module sy_ppl_dec
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      
    // -- <reset>
    input   logic                           rst_i,                      
    // =====================================
    // [debug and irq signals]
    input   logic                           debug_req_i,
    input   logic[1:0]                      irq_i,
    // =====================================
    // [schedule signals]
    output  logic                           dec_fet__ex0_accpt_o,
    input   logic                           alu_dec__mem_accpt_i,
    //! If ALU module finds current instruction is branch or jump, and the prediction is missed, it should send correct
    //! NPC to FETCH module.
    input   logic                           alu_x__mispred_en_i,
    //! If CTRL module sends kill command, current instruction should be set as invalid.
    //! This kill instruction can disable all phases's signals except phase[BASE].
    input   logic                           ctrl_x__ex0_kill_i,
    // =====================================
    // [to ppl_ctrl]
    // status of EX0 stages
    output  logic                           dec_ctrl__ex0_act_o,
    output  logic                           dec_ctrl__ex0_avail_o,
    // ====================================
    // [from csr]
    input   priv_lvl_t                      csr_dec__priv_lvl_i,
    input   xs_t                            csr_dec__fs_i,
    input   logic[2:0]                      csr_dec__frm_i,
    input   logic                           csr_dec__tvm_i,
    input   logic                           csr_dec__tw_i,
    input   logic                           csr_dec__tsr_i, 
    input   irq_ctrl_t                      csr_dec__irq_ctrl_i,
    input   logic                           csr_dec__debug_mode_i,    
    // =====================================
    // [to ppl_fet]
    //! FETCH module should send PC, NPC, instruction content, and stage status to the succedded module.
    //! Be attention that the instruction comes 1 cycle later than other signal, due to the extra delay of IMEM module.
    input   logic                           fet_dec__id0_avail_i,
    input   logic                           fet_dec__id0_act_i,
    input   logic[AWTH-1:0]                 fet_dec__id0_npc_i,
    input   logic[AWTH-1:0]                 fet_dec__id0_pc_i,
    input   logic[IWTH-1:0]                 fet_dec__id0_instr_i,
    input   logic                           fet_dec__id0_is_compressed_i,
    input   exception_t                     fet_dec__id0_exception_i,
    output  logic                           dec_fet__raw_hazard_o,
    // =====================================
    // [to ppl_reg]
    output  logic[4:0]                      dec_reg__rs1_idx_o,
    input   logic[DWTH-1:0]                 reg_dec__rs1_reg_i,
    output  logic[4:0]                      dec_reg__rs2_idx_o,
    input   logic[DWTH-1:0]                 reg_dec__rs2_reg_i,
    // =====================================
    // [to ppl_fp_reg]
    output  logic[4:0]                      dec_fp_reg__rs1_idx_o,
    input   logic[FLEN-1:0]                 fp_reg_dec__rs1_reg_i,
    output  logic[4:0]                      dec_fp_reg__rs2_idx_o,
    input   logic[FLEN-1:0]                 fp_reg_dec__rs2_reg_i,
    output  logic[4:0]                      dec_fp_reg__rs3_idx_o,
    input   logic[FLEN-1:0]                 fp_reg_dec__rs3_reg_i,
    // =====================================
    // [to ppl_alu]
    //! -----
    //! DEC module send decoded instruction to ALU module if current instruction belongs to algebra, logic, branch, and
    //! load/store class.
    output  logic                           dec_alu__ex0_avail_o,
    output  instr_cls_e                     dec_alu__instr_cls_o,
    output  logic[1:0]                      dec_alu__stage_act_o,
    output  logic[AWTH-1:0]                 dec_alu__npc_o,
    output  logic[AWTH-1:0]                 dec_alu__pc_o,
    output  logic[IWTH-1:0]                 dec_alu__instr_o,
    output  als_opcode_e                    dec_alu__als_opcode_o,
    output  jbr_opcode_e                    dec_alu__jbr_opcode_o,
    output  mem_opcode_e                    dec_alu__mem_opcode_o,
    output  amo_t                           dec_alu__amo_opcode_o,        
    output  sys_opcode_e                    dec_alu__sys_opcode_o,
    output  logic                           dec_alu__sign_ext_o,
    output  lrsc_cmd_e                      dec_alu__lrsc_cmd_o,
    output  logic                           dec_alu__rls_o,
    output  logic                           dec_alu__acq_o,
    output  csr_cmd_e                       dec_alu__csr_cmd_o,
    output  logic[11:0]                     dec_alu__csr_addr_o,
    output  logic                           dec_alu__csr_imm_sel_o,
    output  logic[4:0]                      dec_alu__rs1_idx_o,
    output  logic[DWTH-1:0]                 dec_alu__rs1_data_o,
    output  logic[4:0]                      dec_alu__rs2_idx_o,
    output  logic[DWTH-1:0]                 dec_alu__rs2_data_o,
    output  logic                           dec_alu__rdst_en_o,
    output  rdst_src_e                      dec_alu__rdst_src_sel_o,
    output  logic[4:0]                      dec_alu__rdst_idx_o,
    output  logic[DWTH-1:0]                 dec_alu__jbr_base_o,
    output  logic[DWTH-1:0]                 dec_alu__st_data_o,
    output  logic[AWTH-1:0]                 dec_alu__imm_o,
    output  size_e                          dec_alu__size_o,
    output  logic                           dec_alu__fp_rdst_en_o,
    output  logic[4:0]                      dec_alu__fp_rdst_idx_o,
    output  logic[FLEN-1:0]                 dec_alu__fp_result_o,
    output  logic[4:0]                      dec_alu__fp_status_o,
    output  exception_t                     dec_alu__exception_o, 
    output  logic                           dec_alu__only_word_o,                            
    output  logic                           dec_alu__is_compressed_o,
    // block mgr
    input   logic                           alu_dec__mem_blk_en_i,
    input   logic[4:0]                      alu_dec__mem_blk_idx_i,
    input   logic                           alu_dec__mem_blk_f_or_x_i,// 0 for f, 1 for x
    //! bypass signals from ALU module
    input   bp_bus_t                        alu_dec__bp0_rdst_i,
    input   bp_bus_t                        alu_dec__bp1_rdst_i,
    input   logic                           alu_dec__bp0_f_or_x_i,
    input   logic                           alu_dec__bp1_f_or_x_i,
    // =====================================
    // [to ppl_mdu]
    output  logic                           dec_mdu__ex0_avail_o,
    output  logic[AWTH-1:0]                 dec_mdu__pc_o,
    output  mdu_opcode_e                    dec_mdu__mdu_opcode_o,
    output  logic                           dec_mdu__rs1_sign_o,
    output  logic                           dec_mdu__rs2_sign_o,
    output  logic[DWTH-1:0]                 dec_mdu__rs1_data_o,
    output  logic[DWTH-1:0]                 dec_mdu__rs2_data_o,
    output  logic[4:0]                      dec_mdu__rdst_idx_o,
    output  logic                           dec_mdu__only_word_o,
    // =====================================
    // [to ppl_FPU]
    output  logic                           dec_fpu__valid_o,
    input   logic                           fpu_dec__ready_i,
    output  fpu_opcode_t                    dec_fpu__opcode_o,
    output  logic[FLEN-1:0]                 dec_fpu__rs1_data_o,
    output  logic[FLEN-1:0]                 dec_fpu__rs2_data_o,
    output  logic[FLEN-1:0]                 dec_fpu__rs3_data_o,
    output  logic[1:0]                      dec_fpu__fmt_o,
    output  logic[2:0]                      dec_fpu__rm_o,
    input   logic[FLEN-1:0]                 fpu_dec__result_i,
    input   logic[4:0]                      fpu_dec__status_i,
    input   logic                           fpu_dec__valid_i,
    // input the block information
    input   logic[MUL_STAGE-1:0]            mdu_dec__blk_en_mul_i,
    input   logic[MUL_STAGE-1:0][4:0]       mdu_dec__blk_idx_mul_i,
    input   logic                           mdu_dec__blk_en_div_i,
    input   logic[4:0]                      mdu_dec__blk_idx_div_i
);
//======================================================================================================================
// Parameters
//======================================================================================================================


//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================

logic[6:0]                          rvcls;
logic[2:0]                          funct3;
logic[6:0]                          funct7;
logic[11:0]                         funct12;
logic[4:0]                          rs1_idx;
logic[4:0]                          rs2_idx;
logic[4:0]                          rdst_idx;
als_opcode_e                        als_op_arith;
rs1_src_e                           rs1_src_sel;
rs2_src_e                           rs2_src_sel;
rs2_src_e                           fp_rs3_src_sel;
logic                               rs1_reg_en;
logic                               rs2_reg_en;
logic                               rdst_en;
rdst_src_e                          rdst_src_sel;
logic[2:0]                          waw_chk_en;
logic                               sign_ext;
size_e                              size;
logic[DWTH-1:0]                     imm;
instr_cls_e                         instr_cls;
logic[1:0]                          alu_stage_act;
als_opcode_e                        als_opcode;
jbr_opcode_e                        jbr_opcode;
mem_opcode_e                        mem_opcode;
logic[4:0]                          amo_cmd;
lrsc_cmd_e                          lrsc_cmd;
logic                               rls;
logic                               acq;
sys_opcode_e                        sys_opcode;
csr_cmd_e                           csr_cmd;
logic[11:0]                         csr_addr;
logic                               csr_imm_sel;
mdu_opcode_e                        mdu_opcode;
logic                               mdu_rs1_sign;
logic                               mdu_rs2_sign;
logic                               rs1_bp0_hit;
logic                               rs1_bp1_hit;
logic                               rs2_bp0_hit;
logic                               rs2_bp1_hit;
logic                               fp_rs1_bp0_hit;
logic                               fp_rs1_bp1_hit;
logic                               fp_rs2_bp0_hit;
logic                               fp_rs2_bp1_hit;
logic                               fp_rs3_bp0_hit;
logic                               fp_rs3_bp1_hit;

logic[DWTH-1:0]                     rs1_reg_byp;
logic[DWTH-1:0]                     rs2_reg_byp;
logic[DWTH-1:0]                     fp_rs3_reg_byp;
logic[DWTH-1:0]                     rs1_data;
logic[DWTH-1:0]                     rs2_data;
logic                               ex0_stall;
logic                               ex0_kill;
logic                               ex0_act_unkilled;
logic                               ex0_act;
(* max_fanout = 8 *) logic          ex0_avail;
logic                               ex0_accpt;
instr_cls_e                         ex0_instr_cls;
logic[DWTH-1:0]                     ex0_rs1_data;
logic[DWTH-1:0]                     ex0_rs2_data;
logic                               ex0_rdst_en;
logic[4:0]                          ex0_rdst_idx;
logic                               ex0_fp_rdst_en;
logic[4:0]                          ex0_fp_rdst_idx;
logic[2:0]                          ex0_waw_chk_en;
logic                               ex0_only_word;
logic                               ex0_blk_en;
logic                               ex0_blk_fp_en;
logic                               ex0_blk_csr_en;
logic                               ex0_fpu_valid_dly;
logic                               ex0_fpu_valid;
logic                               waw_hazard;
logic                               is_div;
logic                               is_mul;
logic                               fu_div_hazard;
logic[DIV_STAGE-1:0]                wb_bus_chain;
logic                               wb_id0_hazard;
logic                               wb_bus_hazard;
logic                               only_word;

logic                               illegal_instr;
logic                               ecall;
logic                               ebreak;

//for float-point instr
logic                               check_fprm;
logic                               fp_rs1_reg_en;
logic                               fp_rs2_reg_en;
logic                               fp_rs3_reg_en;
logic                               fp_rdst_reg_en;
logic[4:0]                          fp_rs1_idx;
logic[4:0]                          fp_rs2_idx;
logic[4:0]                          fp_rs3_idx;
logic[4:0]                          fp_rd_idx;
logic[2:0]                          fp_rm;
logic[1:0]                          fp_s_or_d;
fpu_opcode_t                        fp_opcode;
logic[1:0]                          fp_fmt;
logic[4:0]                          fp_func5;
logic[FLEN-1:0]                     fp_rs1_data;
logic[FLEN-1:0]                     fp_rs2_data;
logic[FLEN-1:0]                     fp_rs3_data;
logic                               fp_src_from_x;

logic                               st_data_sel; // 0 for x reg, 1 for fp reg

exception_t                         dec_exception;

logic                               id0_is_fp;
logic                               ex0_is_fp;
logic[FLEN-1:0]                     ex0_fp_rs1_data;
logic[FLEN-1:0]                     ex0_fp_rs2_data;
logic[FLEN-1:0]                     ex0_fp_rs3_data;
logic[1:0]                          ex0_fp_fmt;
logic[2:0]                          ex0_fp_rm;
fpu_opcode_t                        ex0_fp_opcode;
logic                               ex0_fp_src_from_x;

logic[63:0]                         interrupt_cause;
amo_t                               amo_opcode;

logic                               st_from_f_x;  // 1 for f, 0 for x
exception_t                         ex0_exception;
//======================================================================================================================
// Instance
//======================================================================================================================

//! -----
//! [Phase: ID0]

// Extract the RISC instruction
assign rvcls = get_rvcls(fet_dec__id0_instr_i);
assign funct3 = get_fu3(fet_dec__id0_instr_i);
assign funct7 = get_fu7(fet_dec__id0_instr_i);
assign funct12 = get_fu12(fet_dec__id0_instr_i);
assign rs1_idx = get_rs1(fet_dec__id0_instr_i);
assign rs2_idx = get_rs2(fet_dec__id0_instr_i);
assign rdst_idx = get_rdst(fet_dec__id0_instr_i);
assign fp_rs1_idx = fet_dec__id0_instr_i[19:15];
assign fp_rs2_idx = fet_dec__id0_instr_i[24:20];
assign fp_rs3_idx = fet_dec__id0_instr_i[31:27];
assign fp_rd_idx = fet_dec__id0_instr_i[11:7];
assign fp_rm = fet_dec__id0_instr_i[14:12];
assign fp_s_or_d = fet_dec__id0_instr_i[26:25];
assign fp_fmt = fet_dec__id0_instr_i[26:25];
assign fp_func5 = fet_dec__id0_instr_i[31:27];

always_comb begin
    case(funct3)
        AR_FU3_ADDIVE: als_op_arith = (rvcls == RVCLS_OP || rvcls == RVCLS_OP_32) && (funct7 == FU7_SUB) ? ALS_OP_SUB : ALS_OP_ADD;
        AR_FU3_SLL: als_op_arith = ALS_OP_SLL;
        AR_FU3_SLT: als_op_arith = ALS_OP_SLT;
        AR_FU3_SLTU: als_op_arith = ALS_OP_SLTU;
        AR_FU3_XOR: als_op_arith = ALS_OP_XOR;
        AR_FU3_SRA_SRL: als_op_arith = ({funct7[6:1],1'b0} == FU7_SRA) ? ALS_OP_SRA : ALS_OP_SRL;
        AR_FU3_OR: als_op_arith = ALS_OP_OR;
        AR_FU3_AND: als_op_arith = ALS_OP_AND;
        default: als_op_arith = ALS_OP_ADD;
    endcase
end

// decode
always_comb begin
    // ---------------------------------
    // common
    rs1_src_sel = RS1_SRC_ZERO;
    rs2_src_sel = RS2_SRC_ZERO;
    rs1_reg_en = 1'b0;
    rs2_reg_en = 1'b0;
    rdst_en = 1'b0;
    rdst_src_sel = RDST_SRC_ALU;
    waw_chk_en = 3'h7;
    sign_ext = 1'b1;
    size = size_e'(funct3[1:0]);                //const
    imm = DWTH'(0);
    instr_cls = INSTR_CLS_NORMAL;
    // ---------------------------------
    alu_stage_act = 2'h3;                       // alu_stage_act[0] stage mem is active;
                                                                                // alu_stage_act[1] stage wb is active
    // alu
    als_opcode = ALS_OP_ADD;
    // bru
    jbr_opcode = JBR_OP_JAL;
    // mem
    mem_opcode = MEM_OP_LOAD;
    amo_cmd = {funct7[2], funct7[6:4]};         //const
    lrsc_cmd = lrsc_cmd_e'(funct7[2]);          //const
    rls = funct7[0];                            //const
    acq = funct7[1];                            //const
    // sys
    sys_opcode = SYS_OP_CSR;
    csr_cmd = csr_cmd_e'(funct3[1:0]);          //const
    csr_addr = funct12;                         //const
    csr_imm_sel = funct3[2];                    //const
    // mdu
    mdu_opcode = MDU_OP_MUL;
    mdu_rs1_sign = 1'b0;
    mdu_rs2_sign = 1'b0;

    only_word = 1'b0;
    illegal_instr = 1'b0;
    ecall = 1'b0;
    ebreak = 1'b0;

    fp_rs1_reg_en = 1'b0;
    fp_rs2_reg_en = 1'b0;
    fp_rs3_reg_en = 1'b0;
    fp_rdst_reg_en = 1'b0;
    check_fprm = 1'b0;
    fp_opcode = FADD;

    st_data_sel = 1'b0;

    id0_is_fp = 1'b0;

    interrupt_cause = '0;
    amo_opcode = AMO_NONE;

    dec_exception = '0;
    fp_src_from_x = 1'b0;
    fp_rs3_src_sel = RS2_SRC_REG;

    st_from_f_x = 1'b0;
    if(!fet_dec__id0_exception_i.valid) begin
        case (rvcls)
            RVCLS_LOAD : begin
                instr_cls = INSTR_CLS_MEM;
                mem_opcode = MEM_OP_LOAD;
                rs1_src_sel = RS1_SRC_REG;
                rs2_src_sel = RS2_SRC_IMM;
                rs1_reg_en = 1'b1;
                rdst_en = 1'b1;
                sign_ext = (funct3[2] == 1'b0) ? 1'b1 : 1'b0;
                rdst_src_sel = RDST_SRC_MEM;
                imm = i_imm(fet_dec__id0_instr_i);
            end
            RVCLS_STORE : begin
                instr_cls = INSTR_CLS_MEM;
                mem_opcode = MEM_OP_STORE;
                rs1_src_sel = RS1_SRC_REG;
                rs2_src_sel = RS2_SRC_IMM;
                rs1_reg_en = 1'b1;
                rs2_reg_en = 1'b1;
                imm = s_imm(fet_dec__id0_instr_i);
            end
            RVCLS_BRANCH : begin
                instr_cls = INSTR_CLS_JBR;
                alu_stage_act = 2'h0;
                jbr_opcode = JBR_OP_BRANCH;
                rs1_src_sel = RS1_SRC_REG;
                rs2_src_sel = RS2_SRC_REG;
                rs1_reg_en = 1'b1;
                rs2_reg_en = 1'b1;
                imm = b_imm(fet_dec__id0_instr_i);
                case(funct3)
                    BR_FU3_BEQ: als_opcode = ALS_OP_SEQ;
                    BR_FU3_BNE: als_opcode = ALS_OP_SNE;
                    BR_FU3_BLT: als_opcode = ALS_OP_SLT;
                    BR_FU3_BLTU: als_opcode = ALS_OP_SLTU;
                    BR_FU3_BGE: als_opcode = ALS_OP_SGE;
                    BR_FU3_BGEU: als_opcode = ALS_OP_SGEU;
                    default: illegal_instr = 1'b1;
                endcase
            end
            RVCLS_JALR : begin
                instr_cls = (funct3 == 0)? INSTR_CLS_JBR : INSTR_CLS_ILLEGAL;
                jbr_opcode = JBR_OP_JALR;
                rs1_src_sel = RS1_SRC_PC;
                rs2_src_sel = RS2_SRC_FOUR;
                rs1_reg_en = 1'b1;
                rdst_en = 1'b1;
                imm = i_imm(fet_dec__id0_instr_i);
            end
            RVCLS_JAL: begin
                instr_cls = INSTR_CLS_JBR;
                rs1_src_sel = RS1_SRC_PC;
                rs2_src_sel = RS2_SRC_FOUR;
                rs1_reg_en = 1'b1;
                rdst_en = 1'b1;
                imm = j_imm(fet_dec__id0_instr_i);
            end
            RVCLS_MISC_MEM : begin
                case(funct3)
                    MEM_FU3_FENCE: begin
                        if(funct7[6:3]== 4'h0 && rs1_idx == 5'h0 && rdst_idx == 5'h0) begin
                            instr_cls = INSTR_CLS_MEM;
                            mem_opcode = MEM_OP_FENCE;
                        end
                    end
                    MEM_FU3_FENCE_I: begin
                        if(funct12 == 12'h0 && rs1_idx == 5'h0 && rdst_idx == 5'h0) begin
                            instr_cls = INSTR_CLS_SYS;
                            sys_opcode = SYS_OP_FENCEI;
                        end
                    end
                    default: begin
                        illegal_instr = 1'b1;
                    end
                endcase
            end
            RVCLS_AMO: begin
                instr_cls = INSTR_CLS_MEM;
                mem_opcode = funct7[3] ? (funct7[2] ? MEM_OP_SC : MEM_OP_LR) : MEM_OP_AMO;
                rs1_src_sel = RS1_SRC_REG;
                rs2_src_sel = RS2_SRC_ZERO;
                rs1_reg_en = 1'b1;
                rs2_reg_en = RS2_SRC_ZERO;
                rdst_en = 1'b1;
                rdst_src_sel = RDST_SRC_MEM;
                case(funct7[6:2])
                    5'h0: amo_opcode = AMO_ADD;
                    5'h1: amo_opcode = AMO_SWAP;
                    5'h2: amo_opcode = AMO_LR;
                    5'h3: amo_opcode = AMO_SC;
                    5'h4: amo_opcode = AMO_XOR;
                    5'h8: amo_opcode = AMO_OR;
                    5'hc: amo_opcode = AMO_AND;
                    5'h10: amo_opcode = AMO_MIN;
                    5'h14: amo_opcode = AMO_MAX;
                    5'h18: amo_opcode = AMO_MINU;
                    5'h1c: amo_opcode = AMO_MAXU;
                    default: illegal_instr = 1'b1;
                endcase
            end
            RVCLS_OP_IMM: begin
                instr_cls = INSTR_CLS_NORMAL;
                als_opcode = als_op_arith;
                rs1_src_sel = RS1_SRC_REG;
                rs2_src_sel = RS2_SRC_IMM;
                rs1_reg_en = 1'b1;
                rdst_en = 1'b1;
                imm = i_imm(fet_dec__id0_instr_i);
            end
            RVCLS_OP_IMM_32: begin
                instr_cls = INSTR_CLS_NORMAL;
                als_opcode = als_op_arith;
                rs1_src_sel = RS1_SRC_REG;
                rs2_src_sel = RS2_SRC_IMM;
                rs1_reg_en = 1'b1;
                rdst_en = 1'b1;
                imm = i_imm(fet_dec__id0_instr_i);
                only_word = 1'b1;
            end      
            RVCLS_OP_32: begin
                only_word = 1'b1;
                rs1_src_sel = RS1_SRC_REG;
                rs2_src_sel = RS2_SRC_REG;
                rs1_reg_en = 1'b1;
                rs2_reg_en = 1'b1;
                rdst_en = 1'b1;
                if(funct7 == FU7_MUL_DIV) begin
                    instr_cls = INSTR_CLS_MDU;
                    rdst_src_sel = funct3[2] ? RDST_SRC_DIV : RDST_SRC_MUL;
                    waw_chk_en = funct3[2] ? 3'h0 : 3'h4;
                    alu_stage_act = 2'h0;
                    case(funct3)
                        MDU_FU3_MULW: begin mdu_opcode = MDU_OP_MUL; mdu_rs1_sign = 1'b1; mdu_rs2_sign = 1'b1; end
                        MDU_FU3_DIVW: begin mdu_opcode = MDU_OP_DIV; mdu_rs1_sign = 1'b1; mdu_rs2_sign = 1'b1; end
                        MDU_FU3_DIVUW: begin mdu_opcode = MDU_OP_DIV; mdu_rs1_sign = 1'b0; mdu_rs2_sign = 1'b0; end
                        MDU_FU3_REMW: begin mdu_opcode = MDU_OP_REM; mdu_rs1_sign = 1'b1; mdu_rs2_sign = 1'b1; end
                        MDU_FU3_REMUW: begin mdu_opcode = MDU_OP_REM; mdu_rs1_sign = 1'b0; mdu_rs2_sign = 1'b0; end
                    endcase
                end else begin
                    instr_cls = INSTR_CLS_NORMAL;
                    als_opcode = als_op_arith;
                end
            end
            RVCLS_OP: begin
                rs1_src_sel = RS1_SRC_REG;
                rs2_src_sel = RS2_SRC_REG;
                rs1_reg_en = 1'b1;
                rs2_reg_en = 1'b1;
                rdst_en = 1'b1;
                if(funct7 == FU7_MUL_DIV) begin
                    instr_cls = INSTR_CLS_MDU;
                    rdst_src_sel = funct3[2] ? RDST_SRC_DIV : RDST_SRC_MUL;
                    waw_chk_en = funct3[2] ? 3'h0 : 3'h4;
                    alu_stage_act = 2'h0;
                    case(funct3)
                        MDU_FU3_MUL: begin mdu_opcode = MDU_OP_MUL; mdu_rs1_sign = 1'b1; mdu_rs2_sign = 1'b1; end
                        MDU_FU3_MULH: begin mdu_opcode = MDU_OP_MULH; mdu_rs1_sign = 1'b1; mdu_rs2_sign = 1'b1; end
                        MDU_FU3_MULHSU: begin mdu_opcode = MDU_OP_MULH; mdu_rs1_sign = 1'b1; mdu_rs2_sign = 1'b0; end
                        MDU_FU3_MULHU: begin mdu_opcode = MDU_OP_MULH; mdu_rs1_sign = 1'b0; mdu_rs2_sign = 1'b0; end
                        MDU_FU3_DIV: begin mdu_opcode = MDU_OP_DIV; mdu_rs1_sign = 1'b1; mdu_rs2_sign = 1'b1; end
                        MDU_FU3_DIVU: begin mdu_opcode = MDU_OP_DIV; mdu_rs1_sign = 1'b0; mdu_rs2_sign = 1'b0; end
                        MDU_FU3_REM: begin mdu_opcode = MDU_OP_REM; mdu_rs1_sign = 1'b1; mdu_rs2_sign = 1'b1; end
                        MDU_FU3_REMU: begin mdu_opcode = MDU_OP_REM; mdu_rs1_sign = 1'b0; mdu_rs2_sign = 1'b0; end
                    endcase
                end else begin
                    instr_cls = INSTR_CLS_NORMAL;
                    als_opcode = als_op_arith;
                end
            end
            RVCLS_SYSTEM : begin
                instr_cls = INSTR_CLS_SYS;
                case(funct3)
                    SYS_FU3_PRIV: begin
                    if(funct7 == PRI_FU7_SFENCE_VMA) begin
                        sys_opcode = SYS_OP_SFENCE_VMA; 
                        if(csr_dec__priv_lvl_i==PRIV_LVL_U || (csr_dec__priv_lvl_i==PRIV_LVL_S && csr_dec__tvm_i)) begin
                            illegal_instr = 1'b1;
                        end
                    end else begin
                        case(funct12)
                            PRI_FU12_ECALL: begin
                                ecall = 1'b1;
                                sys_opcode = SYS_OP_ECALL;
                            end
                            PRI_FU12_EBREAK: begin
                                sys_opcode = SYS_OP_EBREAK;
                                ebreak = 1'b1;
                            end
                            PRI_FU12_SRET: begin
                                if(csr_dec__priv_lvl_i==PRIV_LVL_U || (csr_dec__priv_lvl_i==PRIV_LVL_S && csr_dec__tsr_i)) begin
                                    illegal_instr = 1'b1;
                                end
                                sys_opcode = SYS_OP_SRET;
                            end
                            PRI_FU12_MRET: begin
                                if(csr_dec__priv_lvl_i==PRIV_LVL_U || csr_dec__priv_lvl_i==PRIV_LVL_S) begin
                                    illegal_instr = 1'b1;
                                end
                                sys_opcode = SYS_OP_MRET;
                            end
                            PRI_FU12_DRET: begin 
                                if(!csr_dec__debug_mode_i) begin
                                    illegal_instr = 1'b1;
                                end
                                sys_opcode = SYS_OP_DRET;
                            end
                            PRI_FU12_WFI: begin
                                if(csr_dec__priv_lvl_i==PRIV_LVL_U || (csr_dec__priv_lvl_i==PRIV_LVL_S && csr_dec__tw_i)) begin
                                    illegal_instr = 1'b1;
                                end
                                sys_opcode = SYS_OP_WFI;
                            end
                            default: illegal_instr = 1'b1;
                        endcase
                        end
                    end
                    SYS_FU3_CSRRW, SYS_FU3_CSRRS, SYS_FU3_CSRRC: begin
                        sys_opcode = SYS_OP_CSR;
                        rs1_src_sel = RS1_SRC_REG;
                        rs1_reg_en = 1'b1;
                        rdst_en = 1'b1;
                        rdst_src_sel = RDST_SRC_CSR;
                    end
                    SYS_FU3_CSRRWI, SYS_FU3_CSRRSI, SYS_FU3_CSRRCI: begin
                        sys_opcode = SYS_OP_CSR;
                        rdst_en = 1'b1;
                        rdst_src_sel = RDST_SRC_CSR;
                    end
                    default: illegal_instr = 1'b1;
                endcase
            end
            RVCLS_AUIPC: begin
                instr_cls = INSTR_CLS_NORMAL;
                rs1_src_sel = RS1_SRC_PC;
                rs2_src_sel = RS2_SRC_IMM;
                rdst_en = 1'b1;
                imm = u_imm(fet_dec__id0_instr_i);
            end
            RVCLS_LUI: begin
                instr_cls = INSTR_CLS_NORMAL;
                rs1_src_sel = RS1_SRC_ZERO;
                rs2_src_sel = RS2_SRC_IMM;
                rdst_en = 1'b1;
                imm = u_imm(fet_dec__id0_instr_i);
            end
            RVCLS_LOAD_FP: begin
                if(csr_dec__fs_i != Off) begin
                    instr_cls = INSTR_CLS_MEM;    
                    mem_opcode = MEM_OP_LD_FP;
                    rs1_src_sel = RS1_SRC_REG;
                    rs2_src_sel = RS2_SRC_IMM;
                    rs1_reg_en = 1'b1;
                    fp_rdst_reg_en = 1'b1;
                    sign_ext = (funct3[2] == 1'b0) ? 1'b1 : 1'b0;
                    rdst_src_sel = RDST_SRC_MEM;
                    imm = i_imm(fet_dec__id0_instr_i);
                end else begin
                    illegal_instr = 1'b1;
                end
            end
            RVCLS_STORE_FP: begin
                if(csr_dec__fs_i != Off) begin
                    instr_cls = INSTR_CLS_MEM;
                    mem_opcode = MEM_OP_ST_FP;
                    rs1_src_sel = RS1_SRC_REG;
                    rs2_src_sel = RS2_SRC_IMM;
                    fp_rs2_reg_en = 1'b1;
                    rs1_reg_en = 1'b1;
                    st_data_sel = 1'b1;
                    imm = s_imm(fet_dec__id0_instr_i);
                    st_from_f_x = 1'b1;
                end else begin
                    illegal_instr = 1'b1;
                end 
            end
            RVCLS_MSUB,RVCLS_MADD,RVCLS_NMADD,RVCLS_NMSUB: begin
                if(csr_dec__fs_i != Off) begin
                    rdst_src_sel = RDST_SRC_FPU;
                    id0_is_fp = 1'b1;
                    fp_rs1_reg_en = 1'b1;
                    fp_rs2_reg_en = 1'b1;
                    fp_rs3_reg_en = 1'b1;
                    fp_rdst_reg_en = 1'b1;
                    instr_cls = INSTR_CLS_FPU; 
                    check_fprm = 1'b1;
                    case(rvcls) 
                        RVCLS_MSUB: fp_opcode = FMSUB;
                        RVCLS_NMADD: fp_opcode = FNMADD;
                        RVCLS_NMSUB: fp_opcode = FNMSUB;
                        default: fp_opcode = FMADD;
                    endcase 
                    // determine fp format
                    unique case (fp_s_or_d)
                        // Only process instruction if corresponding extension is active (static)
                        2'b00: if (~RVF)             illegal_instr = 1'b1;
                        2'b01: if (~RVD)             illegal_instr = 1'b1;
                        2'b10: if (~XF16 & ~XF16ALT) illegal_instr = 1'b1;
                        2'b11: if (~XF8)             illegal_instr = 1'b1;
                        default: illegal_instr = 1'b1;
                    endcase
                    // check rounding mode
                    if (check_fprm) begin
                        unique case (fp_rm) inside
                            [3'b000:3'b100]: ; //legal rounding modes
                            3'b101: begin      // Alternative Half-Precsision encded as fmt=10 and rm=101
                                if (~XF16ALT || fp_fmt != 2'b10)
                                    illegal_instr = 1'b1;
                                unique case (csr_dec__frm_i) inside // actual rounding mode from frm csr
                                    [3'b000:3'b100]: ; //legal rounding modes
                                    default : illegal_instr = 1'b1;
                                endcase
                            end
                            3'b111: begin
                                // rounding mode from frm csr
                                unique case (csr_dec__frm_i) inside
                                    [3'b000:3'b100]: ; //legal rounding modes
                                    default : illegal_instr = 1'b1;
                                endcase
                            end
                            default : illegal_instr = 1'b1;
                        endcase
                    end
                end else begin
                    illegal_instr = 1'b1;
                end
            end
            RVCLS_OP_FP: begin
                if(csr_dec__fs_i != Off) begin
                    rdst_src_sel = RDST_SRC_FPU;
                    id0_is_fp = 1'b1;
                    fp_rs1_reg_en = 1'b1;
                    fp_rs2_reg_en = 1'b1;
                    fp_rdst_reg_en = 1'b1;
                    instr_cls = INSTR_CLS_FPU;    
                    check_fprm = 1'b1;
                    fp_rs3_src_sel = RS2_SRC_REG;
                    case(fp_func5) 
                        5'b00000: begin
                            fp_opcode = FADD;
                        end 
                        5'b00001: begin
                            fp_opcode = FSUB;
                        end
                        5'b00010: begin
                            fp_opcode = FMUL;
                        end 
                        5'b00011: begin
                            fp_opcode = FDIV;
                        end
                        5'b01011: begin
                            fp_opcode = FSQRT;
                            fp_rs2_reg_en = 1'b0;
                            if(fp_rs2_idx != 5'b00000)
                                illegal_instr = 1'b1;
                        end
                        5'b00100: begin
                            fp_opcode = FSGNJ;
                            check_fprm = 1'b0;
                            if (XF16ALT) begin        // FP16ALT instructions encoded in rm separately (static)
                                if (!(fp_rm inside {[3'b000:3'b010], [3'b100:3'b110]}))
                                    illegal_instr = 1'b1;
                            end else begin
                                if (!(fp_rm inside {[3'b000:3'b010]}))
                                    illegal_instr = 1'b1;
                            end
                        end
                        5'b00101: begin
                            fp_opcode = FMIN_MAX;
                            check_fprm = 1'b0;
                            if (XF16ALT) begin           // FP16ALT instructions encoded in rm separately (static)
                                if (!(fp_rm inside {[3'b000:3'b001], [3'b100:3'b101]}))
                                    illegal_instr = 1'b1;
                            end else begin
                                if (!(fp_rm inside {[3'b000:3'b001]}))
                                    illegal_instr = 1'b1;
                            end
                        end
                        5'b01000: begin
                            fp_opcode = FCVT_F2F;
                            fp_rs2_reg_en = 1'b0;
                            imm = i_imm(fet_dec__id0_instr_i);
                            if(fp_rs2_idx[4:3])
                                illegal_instr = 1'b1;
                            fp_rs3_src_sel = RS2_SRC_IMM;
                            // check source format
                            unique case (fp_rs2_idx[2:0])
                                // Only process instruction if corresponding extension is active (static)
                                3'b000: if (~RVF)     illegal_instr = 1'b1;
                                3'b001: if (~RVD)     illegal_instr = 1'b1;
                                3'b010: if (~XF16)    illegal_instr = 1'b1;
                                3'b110: if (~XF16ALT) illegal_instr = 1'b1;
                                3'b011: if (~XF8)     illegal_instr = 1'b1;
                                default: illegal_instr = 1'b1;
                            endcase
                        end
                        5'b10100: begin
                            fp_opcode = FCMP;
                            fp_rdst_reg_en = 1'b0;
                            rdst_en = 1'b1;
                            check_fprm = 1'b0;
                            if (XF16ALT) begin       // FP16ALT instructions encoded in rm separately (static)
                                if (!(fp_rm inside {[3'b000:3'b010], [3'b100:3'b110]}))
                                        illegal_instr = 1'b1;
                            end else begin
                                    if (!(fp_rm inside {[3'b000:3'b010]}))
                                        illegal_instr = 1'b1;
                            end
                        end
                        5'b11000: begin
                            fp_opcode = FCVT_F2I;
                            fp_rdst_reg_en = 1'b0;
                            fp_rs2_reg_en = 1'b0;
                            imm = i_imm(fet_dec__id0_instr_i);
                            fp_rs3_src_sel = RS2_SRC_IMM;
                            rdst_en = 1'b1;
                            if(fp_rs2_idx[4:3])
                                illegal_instr = 1'b1;
                        end
                        5'b11010: begin
                            fp_opcode = FCVT_I2F;
                            fp_src_from_x = 1'b1;
                            imm = i_imm(fet_dec__id0_instr_i);
                            fp_rs1_reg_en = 1'b0;
                            fp_rs2_reg_en = 1'b0;
                            fp_rs3_src_sel = RS2_SRC_IMM;
                            rs1_src_sel = RS1_SRC_REG;
                            rs1_reg_en = 1'b1;
                            if(fp_rs2_idx[4:3])
                                illegal_instr = 1'b1;
                        end
                        5'b11100: begin
                            fp_rdst_reg_en = 1'b0;
                            fp_rs2_reg_en = 1'b0;
                            rdst_en = 1'b1;
                            check_fprm = 1'b0;
                            case(fp_rm) 
                                3'b000: fp_opcode = FMV_F2X;
                                3'b001: fp_opcode = FCLASS;
                                default: illegal_instr = 1'b1;
                            endcase
                            if(fp_rs2_idx != 5'b00000)
                                illegal_instr = 1'b1;
                        end
                        5'b11110: begin
                            fp_opcode = FMV_X2F;
                            fp_src_from_x = 1'b1;
                            rs1_src_sel = RS1_SRC_REG;
                            fp_rs1_reg_en = 1'b0;
                            fp_rs2_reg_en = 1'b0;
                            rs1_reg_en = 1'b1;
                            check_fprm = 1'b0; 
                            if(fp_rm != 3'b000)
                                illegal_instr = 1'b1;
                            if(fp_rs2_idx != 5'b00000)
                                illegal_instr = 1'b1;
                        end
                        default: illegal_instr = 1'b1;
                    endcase

                    // check format
                    unique case (fp_fmt)
                        // Only process instruction if corresponding extension is active (static)
                        2'b00: if (~RVF)             illegal_instr = 1'b1;
                        2'b01: if (~RVD)             illegal_instr = 1'b1;
                        2'b10: if (~XF16 & ~XF16ALT) illegal_instr = 1'b1;
                        2'b11: if (~XF8)             illegal_instr = 1'b1;
                        default: illegal_instr = 1'b1;
                    endcase

                    if (check_fprm) begin
                        unique case (fp_rm) inside
                            [3'b000:3'b100]: ; //legal rounding modes
                            3'b101: begin      // Alternative Half-Precsision encded as fmt=10 and rm=101
                                if (~XF16ALT || fp_fmt != 2'b10)
                                    illegal_instr = 1'b1;
                                unique case (csr_dec__frm_i) inside // actual rounding mode from frm csr
                                    [3'b000:3'b100]: ; //legal rounding modes
                                    default : illegal_instr = 1'b1;
                                endcase
                            end
                            3'b111: begin
                                // rounding mode from frm csr
                                unique case (csr_dec__frm_i) inside
                                    [3'b000:3'b100]: ; //legal rounding modes
                                    default : illegal_instr = 1'b1;
                                endcase
                            end
                            default : illegal_instr = 1'b1;
                        endcase
                    end
                end else begin
                    illegal_instr = 1'b1;
                end
            end
            default: illegal_instr = 1'b1;
        endcase
        if(illegal_instr) begin
            id0_is_fp = 1'b0;
            instr_cls = INSTR_CLS_NORMAL;
            rs1_src_sel = RS1_SRC_ZERO;
            rs2_src_sel = RS2_SRC_ZERO;
            rs1_reg_en = 1'b0;
            rs2_reg_en = 1'b0;
            rdst_en = 1'b0;
            rdst_src_sel = RDST_SRC_ALU;
            fp_rs1_reg_en = 1'b0;
            fp_rs2_reg_en = 1'b0;
            fp_rs3_reg_en = 1'b0;
            fp_rdst_reg_en = 1'b0;
            waw_chk_en = 3'h7;
            alu_stage_act = 2'h3;                                                       // alu_stage_act[0] stage mem is active;
            als_opcode = ALS_OP_ADD;
            dec_exception = {ILLEGAL_INSTR,{32'b0,fet_dec__id0_instr_i},1'b1};
        end else if(ecall) begin
            case(csr_dec__priv_lvl_i)
                PRIV_LVL_U: dec_exception = {ENV_CALL_UMODE,{32'b0,fet_dec__id0_instr_i},1'b1};
                PRIV_LVL_S: dec_exception = {ENV_CALL_SMODE,{32'b0,fet_dec__id0_instr_i},1'b1};
                PRIV_LVL_M: dec_exception = {ENV_CALL_MMODE,{32'b0,fet_dec__id0_instr_i},1'b1};
                default:;
            endcase
        end else if(ebreak) begin
            dec_exception = {BREAKPOINT,{32'b0,fet_dec__id0_instr_i},1'b1}; 
        end
        // Below come from cva6 : https://github.com/openhwgroup/cva6  

        // handle interrupt as exceptions
        // -----------------
        // Interrupt Control
        // -----------------
        // we decode an interrupt the same as an exception, hence it will be taken if the instruction did not
        // throw any previous exception.
        // we have three interrupt sources: external interrupts, software interrupts, timer interrupts (order of precedence)
        // for two privilege levels: Supervisor and Machine Mode
        // Supervisor Timer Interrupt
        if (csr_dec__irq_ctrl_i.mie[S_TIMER_INTERRUPT[5:0]] && csr_dec__irq_ctrl_i.mip[S_TIMER_INTERRUPT[5:0]]) begin
            interrupt_cause = S_TIMER_INTERRUPT;
        end
        // Supervisor Software Interrupt
        if (csr_dec__irq_ctrl_i.mie[S_SW_INTERRUPT[5:0]] && csr_dec__irq_ctrl_i.mip[S_SW_INTERRUPT[5:0]]) begin
            interrupt_cause = S_SW_INTERRUPT;
        end
        // Supervisor External Interrupt
        // The logical-OR of the software-writable bit and the signal from the external interrupt controller is
        // used to generate external interrupts to the supervisor
        if (csr_dec__irq_ctrl_i.mie[S_EXT_INTERRUPT[5:0]] && (csr_dec__irq_ctrl_i.mip[S_EXT_INTERRUPT[5:0]] | irq_i[SupervisorIrq])) begin
            interrupt_cause = S_EXT_INTERRUPT;
        end
        // Machine Timer Interrupt
        if (csr_dec__irq_ctrl_i.mip[M_TIMER_INTERRUPT[5:0]] && csr_dec__irq_ctrl_i.mie[M_TIMER_INTERRUPT[5:0]]) begin
            interrupt_cause = M_TIMER_INTERRUPT;
        end
        // Machine Mode Software Interrupt
        if (csr_dec__irq_ctrl_i.mip[M_SW_INTERRUPT[5:0]] && csr_dec__irq_ctrl_i.mie[M_SW_INTERRUPT[5:0]]) begin
            interrupt_cause = M_SW_INTERRUPT;
        end
        // Machine Mode External Interrupt
        if (csr_dec__irq_ctrl_i.mip[M_EXT_INTERRUPT[5:0]] && csr_dec__irq_ctrl_i.mie[M_EXT_INTERRUPT[5:0]]) begin
            interrupt_cause = M_EXT_INTERRUPT;
        end

        if(interrupt_cause[63] && csr_dec__irq_ctrl_i.global_enable) begin
            if(csr_dec__irq_ctrl_i.mideleg[interrupt_cause[5:0]])begin
                if((csr_dec__irq_ctrl_i.sie && csr_dec__priv_lvl_i == PRIV_LVL_S) || csr_dec__priv_lvl_i == PRIV_LVL_U) begin
                    id0_is_fp = 1'b0;
                    instr_cls = INSTR_CLS_NORMAL;
                    rs1_src_sel = RS1_SRC_ZERO;
                    rs2_src_sel = RS2_SRC_ZERO;
                    rs1_reg_en = 1'b0;
                    rs2_reg_en = 1'b0;
                    rdst_en = 1'b0;
                    rdst_src_sel = RDST_SRC_ALU;
                    fp_rs1_reg_en = 1'b0;
                    fp_rs2_reg_en = 1'b0;
                    fp_rs3_reg_en = 1'b0;
                    fp_rdst_reg_en = 1'b0;
                    waw_chk_en = 3'h7;
                    alu_stage_act = 2'h3;                          // alu_stage_act[0] stage mem is active;
                    als_opcode = ALS_OP_ADD;
                    dec_exception.valid = 1'b1;
                    dec_exception.cause = interrupt_cause;
                end 
            end else begin
                id0_is_fp = 1'b0;
                instr_cls = INSTR_CLS_NORMAL;
                rs1_src_sel = RS1_SRC_ZERO;
                rs2_src_sel = RS2_SRC_ZERO;
                rs1_reg_en = 1'b0;
                rs2_reg_en = 1'b0;
                rdst_en = 1'b0;
                rdst_src_sel = RDST_SRC_ALU;
                fp_rs1_reg_en = 1'b0;
                fp_rs2_reg_en = 1'b0;
                fp_rs3_reg_en = 1'b0;
                fp_rdst_reg_en = 1'b0;
                waw_chk_en = 3'h7;
                alu_stage_act = 2'h3;                              // alu_stage_act[0] stage mem is active;
                als_opcode = ALS_OP_ADD;
                dec_exception.valid = 1'b1;
                dec_exception.cause = interrupt_cause;
            end    
        end
    end else begin
        dec_exception = fet_dec__id0_exception_i;
    end

    if(debug_req_i && !csr_dec__debug_mode_i) begin
        dec_exception.valid = 1'b1;
        dec_exception.cause = DEBUG_REQUEST;
    end
end

// -----
// Generate correct Rs1 and Rs2 data

// get rs1 and rs2 register data from reg-file
assign dec_reg__rs1_idx_o = rs1_idx;
assign dec_reg__rs2_idx_o = rs2_idx;

// check whether the bypass data should be used.
assign rs1_bp0_hit = (alu_dec__bp0_rdst_i.en && alu_dec__bp0_rdst_i.idx == rs1_idx) && alu_dec__bp0_f_or_x_i;
assign rs1_bp1_hit = (alu_dec__bp1_rdst_i.en && alu_dec__bp1_rdst_i.idx == rs1_idx) && alu_dec__bp1_f_or_x_i;
assign rs2_bp0_hit = (alu_dec__bp0_rdst_i.en && alu_dec__bp0_rdst_i.idx == rs2_idx) && alu_dec__bp0_f_or_x_i;
assign rs2_bp1_hit = (alu_dec__bp1_rdst_i.en && alu_dec__bp1_rdst_i.idx == rs2_idx) && alu_dec__bp1_f_or_x_i;

assign rs1_reg_byp = rs1_bp0_hit ? alu_dec__bp0_rdst_i.data
                   : rs1_bp1_hit ? alu_dec__bp1_rdst_i.data
                   : reg_dec__rs1_reg_i;
assign rs2_reg_byp = rs2_bp0_hit ? alu_dec__bp0_rdst_i.data
                   : rs2_bp1_hit ? alu_dec__bp1_rdst_i.data
                   : reg_dec__rs2_reg_i;

// set rs1 and rs2
always_comb begin
    case(rs1_src_sel)
        RS1_SRC_REG: rs1_data = rs1_reg_byp;
        RS1_SRC_PC: rs1_data = fet_dec__id0_pc_i;
        default: rs1_data = DWTH'(0);
    endcase
end

always_comb begin
    case(rs2_src_sel)
        RS2_SRC_REG: rs2_data = rs2_reg_byp;
        RS2_SRC_IMM: rs2_data = imm;
        RS2_SRC_FOUR: rs2_data = fet_dec__id0_is_compressed_i ? DWTH'(2) : DWTH'(4);
        default: rs2_data = DWTH'(0);
    endcase
end

// read fp register
assign dec_fp_reg__rs1_idx_o = fp_rs1_idx; 
assign dec_fp_reg__rs2_idx_o = fp_rs2_idx; 
assign dec_fp_reg__rs3_idx_o = fp_rs3_idx; 

assign fp_rs1_bp0_hit = (alu_dec__bp0_rdst_i.en && alu_dec__bp0_rdst_i.idx == fp_rs1_idx) && !alu_dec__bp0_f_or_x_i;
assign fp_rs1_bp1_hit = (alu_dec__bp1_rdst_i.en && alu_dec__bp1_rdst_i.idx == fp_rs1_idx) && !alu_dec__bp1_f_or_x_i;
assign fp_rs2_bp0_hit = (alu_dec__bp0_rdst_i.en && alu_dec__bp0_rdst_i.idx == fp_rs2_idx) && !alu_dec__bp0_f_or_x_i;
assign fp_rs2_bp1_hit = (alu_dec__bp1_rdst_i.en && alu_dec__bp1_rdst_i.idx == fp_rs2_idx) && !alu_dec__bp1_f_or_x_i;
assign fp_rs3_bp0_hit = (alu_dec__bp0_rdst_i.en && alu_dec__bp0_rdst_i.idx == fp_rs3_idx) && !alu_dec__bp0_f_or_x_i;
assign fp_rs3_bp1_hit = (alu_dec__bp1_rdst_i.en && alu_dec__bp1_rdst_i.idx == fp_rs3_idx) && !alu_dec__bp1_f_or_x_i;

assign fp_rs1_data = fp_rs1_bp0_hit ? alu_dec__bp0_rdst_i.data 
                   : fp_rs1_bp1_hit ? alu_dec__bp1_rdst_i.data 
                   : fp_reg_dec__rs1_reg_i;
assign fp_rs2_data = fp_rs2_bp0_hit ? alu_dec__bp0_rdst_i.data 
                   : fp_rs2_bp1_hit ? alu_dec__bp1_rdst_i.data 
                   : fp_reg_dec__rs2_reg_i;
assign fp_rs3_reg_byp = fp_rs3_bp0_hit ? alu_dec__bp0_rdst_i.data 
                   : fp_rs3_bp1_hit ? alu_dec__bp1_rdst_i.data 
                   : fp_reg_dec__rs3_reg_i;

always_comb begin
    case(fp_rs3_src_sel)
        RS2_SRC_REG: fp_rs3_data = fp_rs3_reg_byp;
        RS2_SRC_IMM: fp_rs3_data = imm;
        default: fp_rs3_data = DWTH'(0);
    endcase
end

// -----
// [Phase: Ex0]
assign ex0_stall = waw_hazard || fu_div_hazard || wb_bus_hazard || (ex0_is_fp && !fpu_dec__valid_i);
assign ex0_kill = ctrl_x__ex0_kill_i || alu_x__mispred_en_i;

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        ex0_act_unkilled <= `TCQ 1'b0;
    end else begin
        ex0_act_unkilled <= `TCQ ex0_accpt ? fet_dec__id0_avail_i : ex0_act;
    end
end
assign ex0_act = ex0_act_unkilled && !ex0_kill;
assign ex0_avail = ex0_act && !ex0_stall && alu_dec__mem_accpt_i;
assign ex0_accpt = !ex0_act || ex0_avail;

assign dec_ctrl__ex0_act_o = ex0_act;
assign dec_ctrl__ex0_avail_o = ex0_avail;
assign dec_fet__ex0_accpt_o = ex0_accpt;

always_ff @(posedge clk_i) begin
    if(fet_dec__id0_avail_i) begin
        ex0_instr_cls <= `TCQ instr_cls;
        ex0_rs1_data <= `TCQ rs1_data;
        ex0_rs2_data <= `TCQ rs2_data;
        ex0_rdst_en <= `TCQ rdst_en;
        ex0_rdst_idx <= `TCQ rdst_idx;
        ex0_waw_chk_en <= `TCQ waw_chk_en;
        ex0_is_fp <= `TCQ id0_is_fp;
        ex0_fp_rs1_data <= `TCQ fp_rs1_data;
        ex0_fp_rs2_data <= `TCQ fp_rs2_data;
        ex0_fp_rs3_data <= `TCQ fp_rs3_data;
        ex0_fp_fmt <= `TCQ fp_fmt;
        ex0_fp_rm <= `TCQ fp_rm;
        ex0_fp_rdst_idx <= `TCQ fp_rd_idx;
        ex0_fp_rdst_en <= `TCQ fp_rdst_reg_en;
        ex0_fp_opcode <= fp_opcode;
        ex0_fp_src_from_x <= fp_src_from_x;
    end
end

// generate signals of ALU interface
// Since we cannot guarantee the predicted next PC of multiply and divide instruction is correct, we should use the
// Misprediction check logic to fix it.
assign dec_alu__ex0_avail_o = ex0_avail;
assign dec_alu__instr_cls_o = ex0_instr_cls;

always_ff @(posedge clk_i) begin
    if(fet_dec__id0_avail_i) begin
        dec_alu__stage_act_o <= `TCQ alu_stage_act;
        dec_alu__npc_o <= `TCQ fet_dec__id0_npc_i;
        dec_alu__pc_o <= `TCQ fet_dec__id0_pc_i;
        dec_alu__instr_o <= `TCQ fet_dec__id0_instr_i;
        dec_alu__als_opcode_o <= `TCQ als_opcode;
        dec_alu__jbr_opcode_o <= `TCQ jbr_opcode;
        dec_alu__mem_opcode_o <= `TCQ mem_opcode;
        dec_alu__amo_opcode_o <= `TCQ amo_opcode;
        dec_alu__sys_opcode_o <= `TCQ sys_opcode;
        dec_alu__sign_ext_o <= `TCQ sign_ext;
        dec_alu__lrsc_cmd_o <= `TCQ lrsc_cmd;
        dec_alu__rls_o <= `TCQ rls;
        dec_alu__acq_o <= `TCQ acq;
        dec_alu__csr_cmd_o <= `TCQ csr_cmd;
        dec_alu__csr_addr_o <= `TCQ csr_addr;
        dec_alu__csr_imm_sel_o <= `TCQ csr_imm_sel;
        dec_alu__rs1_idx_o <= `TCQ rs1_idx;
        dec_alu__rs2_idx_o <= `TCQ rs2_idx;
        dec_alu__rdst_src_sel_o <= `TCQ rdst_src_sel;
        dec_alu__imm_o <= `TCQ imm;
        dec_alu__size_o <= `TCQ size;
        dec_alu__jbr_base_o <= `TCQ (instr_cls == INSTR_CLS_JBR && jbr_opcode == JBR_OP_JALR) ? rs1_reg_byp
                             : fet_dec__id0_pc_i;
        dec_alu__st_data_o <= `TCQ st_from_f_x ? fp_rs2_data : rs2_reg_byp;
        ex0_exception <= dec_exception; 
        dec_alu__only_word_o <= `TCQ only_word;
        dec_alu__is_compressed_o <= `TCQ fet_dec__id0_is_compressed_i;
    end
end
//======================================================================================================================
// exception interface 
//======================================================================================================================
always_comb begin: gen_ex0_exception
    dec_alu__exception_o = ex0_exception;
    if(ex0_kill) begin
        dec_alu__exception_o = '0;
    end
end
//======================================================================================================================
// operand interface 
//======================================================================================================================
assign dec_alu__rs1_data_o = ex0_rs1_data;
assign dec_alu__rs2_data_o = ex0_rs2_data;
assign dec_alu__rdst_idx_o = ex0_rdst_idx;
assign dec_alu__rdst_en_o = ex0_rdst_en;
assign dec_alu__fp_rdst_en_o = ex0_fp_rdst_en;
assign dec_alu__fp_rdst_idx_o = ex0_fp_rdst_idx;
//======================================================================================================================
// MDU interface 
//======================================================================================================================
assign dec_mdu__ex0_avail_o = ex0_avail && (ex0_instr_cls == INSTR_CLS_MDU);

always_ff @(posedge clk_i) begin
    if(fet_dec__id0_avail_i) begin
        dec_mdu__pc_o <= `TCQ fet_dec__id0_pc_i;
        dec_mdu__mdu_opcode_o <= `TCQ mdu_opcode;
        dec_mdu__rs1_sign_o <= `TCQ mdu_rs1_sign;
        dec_mdu__rs2_sign_o <= `TCQ mdu_rs2_sign;
    end
end
assign dec_mdu__rs1_data_o = ex0_rs1_data;
assign dec_mdu__rs2_data_o = ex0_rs2_data;
assign dec_mdu__rdst_idx_o = ex0_rdst_idx;
assign dec_mdu__only_word_o = dec_alu__only_word_o;

//======================================================================================================================
// FPU interface 
//======================================================================================================================
assign dec_fpu__valid_o = ex0_fpu_valid && !ex0_fpu_valid_dly;  
assign dec_fpu__opcode_o = ex0_is_fp ? ex0_fp_opcode : FADD;
assign dec_fpu__rs1_data_o = ex0_is_fp ? (ex0_fp_src_from_x ? ex0_rs1_data : ex0_fp_rs1_data) : '0;
assign dec_fpu__rs2_data_o = ex0_is_fp ? ex0_fp_rs2_data : '0;
assign dec_fpu__rs3_data_o = ex0_is_fp ? ex0_fp_rs3_data : '0;
assign dec_fpu__fmt_o = ex0_is_fp ? ex0_fp_fmt : '0;
assign dec_fpu__rm_o = ex0_is_fp ? ex0_fp_rm : '0;
assign dec_alu__fp_result_o = fpu_dec__result_i;
assign dec_alu__fp_status_o = fpu_dec__status_i;
assign ex0_fpu_valid = ex0_act && alu_dec__mem_accpt_i && ex0_is_fp && !fpu_dec__valid_i;

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        ex0_fpu_valid_dly <= 1'b0;
    end else begin
        ex0_fpu_valid_dly <= ex0_fpu_valid;
    end
end

//======================================================================================================================
// judge structure/data hazard
//======================================================================================================================
// analyze data hazard of ID0 phase
assign ex0_blk_en = ex0_act && (ex0_instr_cls == INSTR_CLS_MEM || ex0_instr_cls == INSTR_CLS_MDU) && ex0_rdst_en;
assign ex0_blk_fp_en = ex0_act && (ex0_instr_cls == INSTR_CLS_MEM) && ex0_fp_rdst_en;
assign ex0_blk_csr_en = ex0_act && (ex0_instr_cls == INSTR_CLS_SYS) && (dec_alu__sys_opcode_o == SYS_OP_CSR) && ex0_rdst_en;
// judge the RAW hazard stage[ID0]
always_comb begin
    dec_fet__raw_hazard_o = 1'b0;
    if(fet_dec__id0_act_i) begin
        // ex0
        if(rs1_reg_en && (ex0_blk_en || ex0_blk_csr_en) && rs1_idx == ex0_rdst_idx) begin
            dec_fet__raw_hazard_o = 1'b1;
        end
        if(rs2_reg_en && (ex0_blk_en || ex0_blk_csr_en) && rs2_idx == ex0_rdst_idx) begin
            dec_fet__raw_hazard_o = 1'b1;
        end
        // alu at mem stage
        if(rs1_reg_en && alu_dec__mem_blk_en_i && alu_dec__mem_blk_f_or_x_i && rs1_idx == alu_dec__mem_blk_idx_i) begin
            dec_fet__raw_hazard_o = 1'b1;
        end
        if(rs2_reg_en && alu_dec__mem_blk_en_i && alu_dec__mem_blk_f_or_x_i && rs2_idx == alu_dec__mem_blk_idx_i) begin
            dec_fet__raw_hazard_o = 1'b1;
        end
        if(fp_rs1_reg_en && alu_dec__mem_blk_en_i && !alu_dec__mem_blk_f_or_x_i && fp_rs1_idx == alu_dec__mem_blk_idx_i) begin
            dec_fet__raw_hazard_o = 1'b1;
        end
        if(fp_rs2_reg_en && alu_dec__mem_blk_en_i && !alu_dec__mem_blk_f_or_x_i && fp_rs2_idx == alu_dec__mem_blk_idx_i) begin
            dec_fet__raw_hazard_o = 1'b1;
        end
        if(fp_rs3_reg_en && alu_dec__mem_blk_en_i && !alu_dec__mem_blk_f_or_x_i && fp_rs3_idx == alu_dec__mem_blk_idx_i) begin
            dec_fet__raw_hazard_o = 1'b1;
        end
        // mul
        for(integer i=0; i<MUL_STAGE; i=i+1) begin
            if(rs1_reg_en && mdu_dec__blk_en_mul_i[i] && rs1_idx == mdu_dec__blk_idx_mul_i[i]) begin
                dec_fet__raw_hazard_o = 1'b1;
            end
            if(rs2_reg_en && mdu_dec__blk_en_mul_i[i] && rs2_idx == mdu_dec__blk_idx_mul_i[i]) begin
                dec_fet__raw_hazard_o = 1'b1;
            end
        end
        // div
        if(rs1_reg_en && mdu_dec__blk_en_div_i && rs1_idx == mdu_dec__blk_idx_div_i) begin
            dec_fet__raw_hazard_o = 1'b1;
        end
        if(rs2_reg_en && mdu_dec__blk_en_div_i && rs2_idx == mdu_dec__blk_idx_div_i) begin
            dec_fet__raw_hazard_o = 1'b1;
        end
        // fpu
        if(ex0_is_fp && ex0_act && !ex0_avail) begin
            dec_fet__raw_hazard_o = 1'b1; 
        end
        if(ex0_blk_fp_en && fp_rs1_reg_en && fp_rs1_idx == ex0_fp_rdst_idx) begin
            dec_fet__raw_hazard_o = 1'b1;
        end
        if(ex0_blk_fp_en && fp_rs2_reg_en && fp_rs2_idx == ex0_fp_rdst_idx) begin
            dec_fet__raw_hazard_o = 1'b1;
        end
        if(ex0_blk_fp_en && fp_rs3_reg_en && fp_rs3_idx == ex0_fp_rdst_idx) begin
            dec_fet__raw_hazard_o = 1'b1;
        end
    end
end

// judge the WAW hazard at stage[EX0]
always_comb begin
    waw_hazard = 1'b0;
    if(ex0_act && ex0_rdst_en) begin
        // mul
        for(integer i=0; i<MUL_STAGE-1; i=i+1) begin
            if(ex0_waw_chk_en[i] && mdu_dec__blk_en_mul_i[i] && mdu_dec__blk_idx_mul_i[i] == ex0_rdst_idx) begin
                waw_hazard = 1'b1;
            end
        end
        // div
        if(ex0_waw_chk_en[2] && mdu_dec__blk_en_div_i && mdu_dec__blk_idx_div_i == ex0_rdst_idx) begin
            waw_hazard = 1'b1;
        end
    end
end

// analyze FU DIV hazard at EX0 phase
assign is_div =  (dec_mdu__mdu_opcode_o == MDU_OP_DIV || dec_mdu__mdu_opcode_o == MDU_OP_REM)
    && (ex0_instr_cls == INSTR_CLS_MDU);
assign is_mul =  (dec_mdu__mdu_opcode_o == MDU_OP_MUL || dec_mdu__mdu_opcode_o == MDU_OP_MULH)
    && (ex0_instr_cls == INSTR_CLS_MDU);

assign fu_div_hazard = ex0_act && is_div && mdu_dec__blk_en_div_i;

// analyze WB bus hazard at EX0 phase
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        wb_bus_chain <= `TCQ DIV_STAGE'(0);
    end else begin
        if(ex0_avail && is_div) begin
            wb_bus_chain <= `TCQ (wb_bus_chain >> 1) | (1<<(DIV_STAGE-2));
        end else if(ex0_avail && is_mul) begin
            wb_bus_chain <= `TCQ (wb_bus_chain >> 1) | (1<<(MUL_STAGE-2));
        end else begin
            wb_bus_chain <= `TCQ wb_bus_chain >> 1;
        end
    end
end
// The write-back bus confliction detection circuit is obsolete, since in the cascading inverting circuit such
// confliction can be dealed with in write back stage. It does not need to predict this event and avoid it in EX0 stage.
// assign wb_bus_hazard = ex0_act && (
//       is_div ? wb_bus_chain[DIV_STAGE-1]
//     : is_mul ? wb_bus_chain[MUL_STAGE-1]
//     : wb_bus_chain[0] && ex0_rdst_en
// );
assign wb_bus_hazard = ex0_act && (
      is_div ? wb_bus_chain[DIV_STAGE-1]
    : is_mul ? wb_bus_chain[MUL_STAGE-1]
    : 1'b0);

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : swf_ppl_dec

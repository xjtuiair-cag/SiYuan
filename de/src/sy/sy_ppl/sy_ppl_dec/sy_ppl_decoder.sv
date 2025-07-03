// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_decoder.v
// DEPARTMENT : CAG of IAIR
// AUTHOR     : shenghuanliu
// AUTHOR'S EMAIL :liushenghuan2002@gmail.com
// -----------------------------------------------------------------------------
// Ver 1.0  2025--04--03 initial version.
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

module sy_ppl_decoder
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    // =====================================
    // [irq signals]
    input   intr_ctrl_t                     intr_ctrl_i,
    // ====================================
    // [from csr]
    input   priv_lvl_t                      csr_dec__priv_lvl_i,
    input   xs_t                            csr_dec__fs_i,
    input   logic[2:0]                      csr_dec__frm_i,
    input   logic                           csr_dec__tvm_i,
    input   logic                           csr_dec__tw_i,
    input   logic                           csr_dec__tsr_i, 
    input   logic                           csr_dec__debug_mode_i,    
    // =====================================
    // [instr]
    input   logic[IWTH-1:0]                 fet_dec__instr_i,
    input   excp_t                          fet_dec__excp_i,
    input   logic                           fet_dec__is_c_i,
    // index of register
    output  logic[4:0]                      arc_rs1_idx_o,
    output  logic[4:0]                      arc_rs2_idx_o,
    output  logic[4:0]                      arc_rs3_idx_o,  // for fp instr
    output  logic[4:0]                      arc_rdst_idx_o,
    output  logic                           arc_rs1_en_o,
    output  logic                           arc_rs2_en_o,
    output  logic                           arc_rs3_en_o,  // for fp instr
    output  logic                           arc_rdst_en_o,
    output  logic                           rs1_is_fp_o,
    output  logic                           rs2_is_fp_o,
    output  logic                           rdst_is_fp_o,
    // indicate the instr is completed, so there is no need to wait in ROB
    output  logic                           completed_o, 
    // indicate whether the instr is compressed instr
    output  logic                           excp_is_intr_o,

    output  issue_type_e                    issue_type_o,   // to which execute unit
    output  instr_cls_e                     instr_cls_o, 

    output  exu_cmd_t                       exu_cmd_o,
    output  lsu_cmd_t                       lsu_cmd_o,
    output  csr_cmd_t                       csr_cmd_o,
    output  sys_cmd_t                       sys_cmd_o,

    output  excp_t                          excp_o
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
    als_opcode_e                        als_op_arith;
    logic                               illegal_instr;
    logic                               ecall;
    logic                               ebreak;
    //for float-point instr
    logic                               check_fprm;
    logic[2:0]                          fp_rm;
    logic[1:0]                          fp_s_or_d;
    logic[1:0]                          fp_fmt;
    logic[4:0]                          fp_func5;
    logic[4:0]                          fp_rs2_idx;


//======================================================================================================================
// Instance
//======================================================================================================================
    // Extract the RISC instruction
    assign rvcls              = get_rvcls(fet_dec__instr_i);
    assign funct3             = get_fu3(fet_dec__instr_i);
    assign funct7             = get_fu7(fet_dec__instr_i);
    assign funct12            = get_fu12(fet_dec__instr_i);
    assign arc_rs1_idx_o      = get_rs1(fet_dec__instr_i);
    assign arc_rs2_idx_o      = get_rs2(fet_dec__instr_i);
    assign arc_rs3_idx_o      = get_rs3(fet_dec__instr_i);
    assign arc_rdst_idx_o     = get_rdst(fet_dec__instr_i);
    // fpu
    assign fp_rm        = fet_dec__instr_i[14:12];
    assign fp_s_or_d    = fet_dec__instr_i[26:25];
    assign fp_fmt       = fet_dec__instr_i[26:25];
    assign fp_func5     = fet_dec__instr_i[31:27];

    assign fp_rs2_idx = arc_rs2_idx_o;
    always_comb begin
        case(funct3)
            AR_FU3_ADDIVE:  als_op_arith = (rvcls == RVCLS_OP || rvcls == RVCLS_OP_32) && (funct7 == FU7_SUB) ? ALS_OP_SUB : ALS_OP_ADD;
            AR_FU3_SLL:     als_op_arith = ALS_OP_SLL;
            AR_FU3_SLT:     als_op_arith = ALS_OP_SLT;
            AR_FU3_SLTU:    als_op_arith = ALS_OP_SLTU;
            AR_FU3_XOR:     als_op_arith = ALS_OP_XOR;
            AR_FU3_SRA_SRL: als_op_arith = ({funct7[6:1],1'b0} == FU7_SRA) ? ALS_OP_SRA : ALS_OP_SRL;
            AR_FU3_OR:      als_op_arith = ALS_OP_OR;
            AR_FU3_AND:     als_op_arith = ALS_OP_AND;
            default:        als_op_arith = ALS_OP_ADD;
        endcase
    end

    // decode
    always_comb begin
        automatic logic[DWTH-1:0] imm;
        // ---------------------------------
        // common
        issue_type_o        = TO_NONE;
        instr_cls_o         = INSTR_CLS_NORMAL;

        exu_cmd_o           = exu_cmd_t'(0);
        lsu_cmd_o           = lsu_cmd_t'(0);
        csr_cmd_o           = csr_cmd_t'(0);
        sys_cmd_o           = sys_cmd_t'(0);

        lsu_cmd_o.size      = size_e'(funct3[1:0]);
        exu_cmd_o.rm        = fp_rm;
        exu_cmd_o.fmt       = fp_fmt;
        arc_rs1_en_o        = 1'b0;
        arc_rs2_en_o        = 1'b0;
        arc_rs3_en_o        = 1'b0;
        arc_rdst_en_o       = 1'b0;
        rs1_is_fp_o         = 1'b0;
        rs2_is_fp_o         = 1'b0;
        rdst_is_fp_o        = 1'b0;

        illegal_instr       = 1'b0;
        ecall               = 1'b0;
        ebreak              = 1'b0;
        check_fprm          = 1'b0;

        completed_o         = 1'b0;
        excp_is_intr_o      = 1'b0;

        excp_o              = excp_t'(0);
        // exception from fetch stage
        if (fet_dec__excp_i.valid) begin
            completed_o      = 1'b1;
            excp_o = fet_dec__excp_i;   
        // interrupt  
        end else if (intr_ctrl_i.intr_en) begin
            completed_o       = 1'b1;
            excp_is_intr_o    = 1'b1;
            excp_o.valid      = 1'b1;           
            excp_o.cause.intr = intr_ctrl_i.intr_cause;
        end else begin
            case (rvcls)
                RVCLS_LOAD : begin
                    instr_cls_o                 = INSTR_CLS_MEM;
                    issue_type_o                = TO_LSU;
                    lsu_cmd_o.mem_op            = MEM_OP_LOAD;
                    lsu_cmd_o.sign_ext          = (funct3[2] == 1'b0) ? 1'b1 : 1'b0;
                    lsu_cmd_o.imm               = i_imm(fet_dec__instr_i);
                    lsu_cmd_o.rs1_src_sel       = RS1_SRC_REG1;
                    lsu_cmd_o.rs2_src_sel       = RS2_SRC_IMM;
                    arc_rs1_en_o                = 1'b1;
                    arc_rdst_en_o               = 1'b1;
                end
                RVCLS_STORE : begin
                    instr_cls_o                 = INSTR_CLS_MEM;
                    issue_type_o                = TO_LSU;
                    lsu_cmd_o.mem_op            = MEM_OP_STORE;
                    lsu_cmd_o.imm               = s_imm(fet_dec__instr_i);
                    lsu_cmd_o.rs1_src_sel       = RS1_SRC_REG1;
                    lsu_cmd_o.rs2_src_sel       = RS2_SRC_IMM;
                    arc_rs1_en_o                = 1'b1;
                    arc_rs2_en_o                = 1'b1;
                end
                RVCLS_BRANCH : begin
                    instr_cls_o                 = INSTR_CLS_JBR;
                    issue_type_o                = TO_EXU;
                    exu_cmd_o.jbr_op            = JBR_OP_BRANCH;
                    exu_cmd_o.imm               = b_imm(fet_dec__instr_i);
                    exu_cmd_o.rs1_src_sel       = RS1_SRC_REG1;
                    exu_cmd_o.rs2_src_sel       = RS2_SRC_REG2;
                    arc_rs1_en_o                = 1'b1;
                    arc_rs2_en_o                = 1'b1;
                    case(funct3)
                        BR_FU3_BEQ:  exu_cmd_o.als_op = ALS_OP_SEQ;
                        BR_FU3_BNE:  exu_cmd_o.als_op = ALS_OP_SNE;
                        BR_FU3_BLT:  exu_cmd_o.als_op = ALS_OP_SLT;
                        BR_FU3_BLTU: exu_cmd_o.als_op = ALS_OP_SLTU;
                        BR_FU3_BGE:  exu_cmd_o.als_op = ALS_OP_SGE;
                        BR_FU3_BGEU: exu_cmd_o.als_op = ALS_OP_SGEU;
                        default: illegal_instr = 1'b1;
                    endcase
                end
                RVCLS_JALR : begin
                    instr_cls_o                 = (funct3 == 0)? INSTR_CLS_JBR : INSTR_CLS_ILLEGAL;
                    issue_type_o                = TO_EXU;
                    exu_cmd_o.jbr_op            = JBR_OP_JALR;
                    exu_cmd_o.imm               = i_imm(fet_dec__instr_i);
                    exu_cmd_o.rs1_src_sel       = RS1_SRC_PC;   // rs1_src_sel indicate the src for adder, not reg
                    exu_cmd_o.rs2_src_sel       = RS2_SRC_FOUR;
                    arc_rs1_en_o                = 1'b1;
                    arc_rdst_en_o               = 1'b1;
                end
                RVCLS_JAL: begin
                    instr_cls_o                 = INSTR_CLS_JBR;
                    issue_type_o                = TO_EXU;
                    exu_cmd_o.jbr_op            = JBR_OP_JAL;
                    exu_cmd_o.imm               = j_imm(fet_dec__instr_i);
                    exu_cmd_o.rs1_src_sel       = RS1_SRC_PC;
                    exu_cmd_o.rs2_src_sel       = RS2_SRC_FOUR;
                    arc_rdst_en_o               = 1'b1;
                end
                RVCLS_MISC_MEM : begin
                    case(funct3)
                        MEM_FU3_FENCE: begin
                            instr_cls_o         = INSTR_CLS_MEM;
                            issue_type_o        = TO_LSU;
                            lsu_cmd_o.mem_op    = MEM_OP_FENCE;
                            lsu_cmd_o.is_fence  = 1'b1;
                            // completed_o         = 1'b1;
                        end
                        MEM_FU3_FENCE_I: begin
                            instr_cls_o         = INSTR_CLS_SYS;
                            issue_type_o        = TO_NONE;
                            sys_cmd_o.sys_op    = SYS_OP_FENCEI;
                            completed_o         = 1'b1;
                        end
                        default: begin
                            illegal_instr = 1'b1;
                        end
                    endcase
                end
                RVCLS_AMO: begin
                    instr_cls_o             = INSTR_CLS_MEM;
                    issue_type_o            = TO_LSU;
                    lsu_cmd_o.mem_op        = funct7[3] ? (funct7[2] ? MEM_OP_SC : MEM_OP_LR) : MEM_OP_AMO;
                    lsu_cmd_o.rs1_src_sel   = RS1_SRC_REG1;
                    lsu_cmd_o.rs2_src_sel   = RS2_SRC_ZERO;
                    lsu_cmd_o.sign_ext      = 1'b1; 
                    arc_rs1_en_o            = 1'b1;
                    arc_rs2_en_o            = (funct7[6:2] == 5'h2) ? 1'b0 : 1'b1;
                    arc_rdst_en_o           = 1'b1;
                    case(funct7[6:2])
                        5'h0:   lsu_cmd_o.amo_op = AMO_ADD;
                        5'h1:   lsu_cmd_o.amo_op = AMO_SWAP;
                        5'h2:   lsu_cmd_o.amo_op = AMO_LR;
                        5'h3:   lsu_cmd_o.amo_op = AMO_SC;
                        5'h4:   lsu_cmd_o.amo_op = AMO_XOR;
                        5'h8:   lsu_cmd_o.amo_op = AMO_OR;
                        5'hc:   lsu_cmd_o.amo_op = AMO_AND;
                        5'h10:  lsu_cmd_o.amo_op = AMO_MIN;
                        5'h14:  lsu_cmd_o.amo_op = AMO_MAX;
                        5'h18:  lsu_cmd_o.amo_op = AMO_MINU;
                        5'h1c:  lsu_cmd_o.amo_op = AMO_MAXU;
                        default: illegal_instr = 1'b1;
                    endcase
                end
                RVCLS_OP_IMM_32, RVCLS_OP_IMM: begin
                    instr_cls_o                 = INSTR_CLS_NORMAL;
                    issue_type_o                = TO_EXU;
                    exu_cmd_o.als_op            = als_op_arith;
                    exu_cmd_o.rs1_src_sel       = RS1_SRC_REG1;
                    exu_cmd_o.rs2_src_sel       = RS2_SRC_IMM;
                    exu_cmd_o.imm               = i_imm(fet_dec__instr_i);
                    arc_rs1_en_o                = 1'b1;
                    arc_rdst_en_o               = 1'b1;
                    if (rvcls == RVCLS_OP_IMM_32) begin
                        exu_cmd_o.is_32 = 1'b1;
                    end else begin
                        exu_cmd_o.is_32 = 1'b0;                   
                    end
                end
                RVCLS_OP, RVCLS_OP_32: begin
                    issue_type_o                    = TO_EXU;   
                    arc_rs1_en_o                    = 1'b1;
                    arc_rs2_en_o                    = 1'b1;
                    arc_rdst_en_o                   = 1'b1;
                    exu_cmd_o.rs1_src_sel           = RS1_SRC_REG1;
                    exu_cmd_o.rs2_src_sel           = RS2_SRC_REG2;
                    if (funct7 == FU7_MUL_DIV) begin
                        instr_cls_o                 = INSTR_CLS_MDU;
                        case(funct3)
                            MDU_FU3_MUL:   begin exu_cmd_o.mdu_op = MDU_OP_MUL;  exu_cmd_o.rs1_sign = 1'b1; exu_cmd_o.rs2_sign = 1'b1; end
                            MDU_FU3_MULH:  begin exu_cmd_o.mdu_op = MDU_OP_MULH; exu_cmd_o.rs1_sign = 1'b1; exu_cmd_o.rs2_sign = 1'b1; end
                            MDU_FU3_MULHSU:begin exu_cmd_o.mdu_op = MDU_OP_MULH; exu_cmd_o.rs1_sign = 1'b1; exu_cmd_o.rs2_sign = 1'b0; end
                            MDU_FU3_MULHU: begin exu_cmd_o.mdu_op = MDU_OP_MULH; exu_cmd_o.rs1_sign = 1'b0; exu_cmd_o.rs2_sign = 1'b0; end
                            MDU_FU3_DIV:   begin exu_cmd_o.mdu_op = MDU_OP_DIV;  exu_cmd_o.rs1_sign = 1'b1; exu_cmd_o.rs2_sign = 1'b1; end
                            MDU_FU3_DIVU:  begin exu_cmd_o.mdu_op = MDU_OP_DIV;  exu_cmd_o.rs1_sign = 1'b0; exu_cmd_o.rs2_sign = 1'b0; end
                            MDU_FU3_REM:   begin exu_cmd_o.mdu_op = MDU_OP_REM;  exu_cmd_o.rs1_sign = 1'b1; exu_cmd_o.rs2_sign = 1'b1; end
                            MDU_FU3_REMU:  begin exu_cmd_o.mdu_op = MDU_OP_REM;  exu_cmd_o.rs1_sign = 1'b0; exu_cmd_o.rs2_sign = 1'b0; end
                        endcase
                    end else begin
                        instr_cls_o                 = INSTR_CLS_NORMAL;
                        exu_cmd_o.als_op            = als_op_arith;
                    end
                    // whether this is instruction handle only 32bit
                    if (rvcls == RVCLS_OP_32) begin
                        exu_cmd_o.is_32 = 1'b1;
                    end else begin
                        exu_cmd_o.is_32 = 1'b0;
                    end
                end
                RVCLS_SYSTEM : begin
                    case(funct3)
                        SYS_FU3_PRIV: begin
                        instr_cls_o         = INSTR_CLS_SYS;
                        issue_type_o        = TO_NONE;
                        completed_o         = 1'b1;
                        if(funct7 == PRI_FU7_SFENCE_VMA) begin
                            sys_cmd_o.sys_op = SYS_OP_SFENCE_VMA; 
                            if (csr_dec__priv_lvl_i==PRIV_LVL_U || (csr_dec__priv_lvl_i==PRIV_LVL_S && csr_dec__tvm_i)) begin
                                illegal_instr = 1'b1;
                            end
                        end else begin
                            case(funct12)
                                PRI_FU12_ECALL: begin
                                    ecall = 1'b1;
                                    sys_cmd_o.sys_op = SYS_OP_ECALL;
                                end
                                PRI_FU12_EBREAK: begin
                                    ebreak = 1'b1;
                                    sys_cmd_o.sys_op = SYS_OP_EBREAK;
                                end
                                PRI_FU12_SRET: begin
                                    if(csr_dec__priv_lvl_i==PRIV_LVL_U || (csr_dec__priv_lvl_i==PRIV_LVL_S && csr_dec__tsr_i)) begin
                                        illegal_instr = 1'b1;
                                    end
                                    sys_cmd_o.sys_op = SYS_OP_SRET;
                                end
                                PRI_FU12_MRET: begin
                                    if(csr_dec__priv_lvl_i==PRIV_LVL_U || csr_dec__priv_lvl_i==PRIV_LVL_S) begin
                                        illegal_instr = 1'b1;
                                    end
                                    sys_cmd_o.sys_op = SYS_OP_MRET;
                                end
                                PRI_FU12_DRET: begin 
                                    if(!csr_dec__debug_mode_i) begin
                                        illegal_instr = 1'b1;
                                    end
                                    sys_cmd_o.sys_op = SYS_OP_DRET;
                                end
                                PRI_FU12_WFI: begin
                                    if(csr_dec__priv_lvl_i==PRIV_LVL_U || (csr_dec__priv_lvl_i==PRIV_LVL_S && csr_dec__tw_i)) begin
                                        illegal_instr = 1'b1;
                                    end
                                    sys_cmd_o.sys_op = SYS_OP_WFI;
                                end
                                default: illegal_instr = 1'b1;
                            endcase
                            end
                        end
                        SYS_FU3_CSRRW, SYS_FU3_CSRRS, SYS_FU3_CSRRC: begin
                            instr_cls_o                 = INSTR_CLS_CSR;
                            issue_type_o                = TO_CSR;
                            csr_cmd_o.csr_op            = csr_opcode_e'(funct3[1:0]);
                            csr_cmd_o.csr_addr          = funct12;
                            arc_rs1_en_o                   = 1'b1;
                            csr_cmd_o.csr_wr_en         = !((csr_cmd_o.csr_op == CSR_RS || csr_cmd_o.csr_op == CSR_RC) && 
                                                               arc_rs1_idx_o == 5'b0);
                            csr_cmd_o.csr_rd_en         = !((csr_cmd_o.csr_op == CSR_RW) && 
                                                            arc_rdst_idx_o == 5'b0);
                            arc_rdst_en_o               = csr_cmd_o.csr_rd_en;
                        end
                        SYS_FU3_CSRRWI, SYS_FU3_CSRRSI, SYS_FU3_CSRRCI: begin
                            instr_cls_o                 = INSTR_CLS_CSR;
                            issue_type_o                = TO_CSR;
                            csr_cmd_o.csr_op            = csr_opcode_e'(funct3[1:0]);
                            csr_cmd_o.csr_addr          = funct12;
                            csr_cmd_o.csr_imm           = arc_rs1_idx_o; 
                            csr_cmd_o.with_imm          = 1'b1;
                            // arc_rdst_en_o               = 1'b1;
                            // csr_cmd_o.csr_wr_en         = !((csr_cmd_o.csr_op == CSR_RS || csr_cmd_o.csr_op == CSR_RC) && 
                            //                                    arc_rs1_idx_o == 5'b0);
                            csr_cmd_o.csr_wr_en         = 1'b1;
                            csr_cmd_o.csr_rd_en         = !((csr_cmd_o.csr_op == CSR_RW) && 
                                                            arc_rdst_idx_o == 5'b0);
                            arc_rdst_en_o               = csr_cmd_o.csr_rd_en;
                        end
                        default: illegal_instr = 1'b1;
                    endcase
                end
                RVCLS_AUIPC: begin
                    instr_cls_o                 = INSTR_CLS_NORMAL;
                    issue_type_o                = TO_EXU;   
                    exu_cmd_o.rs1_src_sel       = RS1_SRC_PC;
                    exu_cmd_o.rs2_src_sel       = RS2_SRC_IMM;
                    exu_cmd_o.imm               = u_imm(fet_dec__instr_i);
                    arc_rdst_en_o               = 1'b1;
                end
                RVCLS_LUI: begin
                    instr_cls_o                 = INSTR_CLS_NORMAL;
                    issue_type_o                = TO_EXU;
                    exu_cmd_o.rs1_src_sel       = RS1_SRC_ZERO;
                    exu_cmd_o.rs2_src_sel       = RS2_SRC_IMM;
                    exu_cmd_o.imm               = u_imm(fet_dec__instr_i);
                    arc_rdst_en_o               = 1'b1;
                end
                RVCLS_LOAD_FP: begin
                    if (csr_dec__fs_i != Off) begin
                        instr_cls_o                 = INSTR_CLS_MEM;    
                        issue_type_o                = TO_LSU;
                        lsu_cmd_o.mem_op            = MEM_OP_LD_FP;
                        lsu_cmd_o.rs1_src_sel       = RS1_SRC_REG1;
                        lsu_cmd_o.rs2_src_sel       = RS2_SRC_IMM;
                        lsu_cmd_o.sign_ext          = (funct3[2] == 1'b0) ? 1'b1 : 1'b0;
                        lsu_cmd_o.imm               = i_imm(fet_dec__instr_i);
                        arc_rs1_en_o                = 1'b1;
                        arc_rdst_en_o               = 1'b1;
                        rdst_is_fp_o                = 1'b1;
                    end else begin
                        illegal_instr = 1'b1;
                    end
                end
                RVCLS_STORE_FP: begin
                    if (csr_dec__fs_i != Off) begin
                        instr_cls_o                 = INSTR_CLS_MEM;
                        issue_type_o                = TO_LSU;
                        lsu_cmd_o.mem_op            = MEM_OP_ST_FP;
                        lsu_cmd_o.rs1_src_sel       = RS1_SRC_REG1;
                        lsu_cmd_o.rs2_src_sel       = RS2_SRC_IMM;
                        lsu_cmd_o.imm               = s_imm(fet_dec__instr_i);
                        arc_rs1_en_o                = 1'b1;
                        arc_rs2_en_o                = 1'b1;
                        rs2_is_fp_o                 = 1'b1;
                    end else begin
                        illegal_instr = 1'b1;
                    end 
                end
                RVCLS_MSUB,RVCLS_MADD,RVCLS_NMADD,RVCLS_NMSUB: begin
                    if (csr_dec__fs_i != Off) begin
                        instr_cls_o                 = INSTR_CLS_FPU; 
                        issue_type_o                = TO_EXU;
                        arc_rs1_en_o                = 1'b1;
                        arc_rs2_en_o                = 1'b1;
                        arc_rs3_en_o                = 1'b1;
                        rs1_is_fp_o                 = 1'b1;
                        rs2_is_fp_o                 = 1'b1;
                        rdst_is_fp_o                = 1'b1;
                        check_fprm                  = 1'b1;
                        exu_cmd_o.rs1_src_sel       = RS1_SRC_REG1;
                        exu_cmd_o.rs2_src_sel       = RS2_SRC_REG2;
                        exu_cmd_o.rs3_src_sel       = RS3_SRC_REG3;
                        case(rvcls) 
                            RVCLS_MSUB:  exu_cmd_o.fpu_op = FMSUB;
                            RVCLS_NMADD: exu_cmd_o.fpu_op = FNMADD;
                            RVCLS_NMSUB: exu_cmd_o.fpu_op = FNMSUB;
                            default:     exu_cmd_o.fpu_op = FMADD;
                        endcase 
                        // determine fp format
                        unique case (fp_s_or_d) // Single precision or double precision
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
                    if (csr_dec__fs_i != Off) begin
                        instr_cls_o                 = INSTR_CLS_FPU;    
                        issue_type_o                = TO_EXU;
                        arc_rs1_en_o                = 1'b1;
                        arc_rs2_en_o                = 1'b1;
                        arc_rdst_en_o               = 1'b1;
                        rs1_is_fp_o                 = 1'b1;
                        rs2_is_fp_o                 = 1'b1;
                        rdst_is_fp_o                = 1'b1;
                        exu_cmd_o.rs1_src_sel       = RS1_SRC_REG1;
                        exu_cmd_o.rs2_src_sel       = RS2_SRC_REG2;
                        exu_cmd_o.rs3_src_sel       = RS3_SRC_REG3;
                        check_fprm                  = 1'b1;
                        case(fp_func5) 
                            5'b00000: begin
                                exu_cmd_o.fpu_op         = FADD;
                                exu_cmd_o.rs1_src_sel    = RS1_SRC_ZERO;
                                exu_cmd_o.rs2_src_sel    = RS2_SRC_REG1;
                                exu_cmd_o.rs3_src_sel    = RS3_SRC_REG2;
                            end 
                            5'b00001: begin
                                exu_cmd_o.fpu_op         = FSUB;
                                exu_cmd_o.rs2_src_sel    = RS2_SRC_REG1;
                                exu_cmd_o.rs3_src_sel    = RS3_SRC_REG2;
                            end
                            5'b00010: begin
                                exu_cmd_o.fpu_op         = FMUL;
                            end 
                            5'b00011: begin
                                exu_cmd_o.fpu_op         = FDIV;
                            end
                            5'b01011: begin
                                exu_cmd_o.fpu_op         = FSQRT;
                                arc_rs2_en_o                = 1'b0;
                                rs2_is_fp_o                 = 1'b0;
                                exu_cmd_o.rs2_src_sel    = RS2_SRC_ZERO;
                                if (fp_rs2_idx != 5'b00000)
                                    illegal_instr = 1'b1;
                            end
                            5'b00100: begin
                                exu_cmd_o.fpu_op         = FSGNJ;
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
                                exu_cmd_o.fpu_op         = FMIN_MAX;
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
                                imm = i_imm(fet_dec__instr_i);
                                exu_cmd_o.fpu_op     = FCVT_F2F;
                                arc_rs2_en_o            = 1'b0;
                                rs2_is_fp_o             = 1'b0;
                                exu_cmd_o.imm[2:0]   = imm[2:0];
                                exu_cmd_o.rs2_src_sel    = RS2_SRC_REG1;
                                exu_cmd_o.rs3_src_sel    = RS3_SRC_IMM;
                                if (fp_rs2_idx[4:3])
                                    illegal_instr = 1'b1;
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
                                exu_cmd_o.fpu_op     = FCMP;
                                rdst_is_fp_o            = 1'b0;
                                check_fprm              = 1'b0;
                                if (XF16ALT) begin       // FP16ALT instructions encoded in rm separately (static)
                                    if (!(fp_rm inside {[3'b000:3'b010], [3'b100:3'b110]}))
                                            illegal_instr = 1'b1;
                                end else begin
                                        if (!(fp_rm inside {[3'b000:3'b010]}))
                                            illegal_instr = 1'b1;
                                end
                            end
                            5'b11000: begin
                                imm = i_imm(fet_dec__instr_i);
                                exu_cmd_o.fpu_op     = FCVT_F2I;
                                rdst_is_fp_o            = 1'b0;
                                arc_rs2_en_o            = 1'b0;
                                exu_cmd_o.imm[2:0]   = imm[2:0];
                                exu_cmd_o.rs2_src_sel    = RS2_SRC_REG1;
                                exu_cmd_o.rs3_src_sel    = RS3_SRC_IMM;
                                if (fp_rs2_idx[4:3])
                                    illegal_instr = 1'b1;
                            end
                            5'b11010: begin
                                imm = i_imm(fet_dec__instr_i);
                                exu_cmd_o.fpu_op     = FCVT_I2F;
                                arc_rs2_en_o            = 1'b0;
                                rs1_is_fp_o             = 1'b0;
                                rs2_is_fp_o             = 1'b0;
                                exu_cmd_o.imm[2:0]   = imm[2:0];
                                exu_cmd_o.rs2_src_sel    = RS2_SRC_REG1;
                                exu_cmd_o.rs3_src_sel    = RS3_SRC_IMM;
                                if (fp_rs2_idx[4:3])
                                    illegal_instr = 1'b1;
                            end
                            5'b11100: begin
                                rdst_is_fp_o          = 1'b0;
                                rs2_is_fp_o           = 1'b0;
                                arc_rs2_en_o          = 1'b0;
                                check_fprm            = 1'b0;
                                exu_cmd_o.rs2_src_sel    = RS2_SRC_REG1;
                                exu_cmd_o.rs3_src_sel    = RS3_SRC_REG2;
                                case(fp_rm) 
                                    3'b000: exu_cmd_o.fpu_op = FMV_F2X;
                                    3'b001: exu_cmd_o.fpu_op = FCLASS;
                                    default: illegal_instr = 1'b1;
                                endcase
                                if(fp_rs2_idx != 5'b00000)
                                    illegal_instr = 1'b1;
                            end
                            5'b11110: begin
                                exu_cmd_o.fpu_op        = FMV_X2F;
                                arc_rs2_en_o            = 1'b0;
                                rs1_is_fp_o             = 1'b0;
                                rs2_is_fp_o             = 1'b0;
                                check_fprm              = 1'b0; 
                                exu_cmd_o.rs2_src_sel   = RS2_SRC_REG1;
                                exu_cmd_o.rs3_src_sel   = RS3_SRC_REG2;
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
                instr_cls_o     = INSTR_CLS_NORMAL;
                issue_type_o    = TO_NONE;
                completed_o     = 1'b1;
                excp_o          = {ILLEGAL_INST,{32'b0,fet_dec__instr_i},1'b1};
            end else if(ecall) begin
                completed_o     = 1'b1;
                case (csr_dec__priv_lvl_i)
                    PRIV_LVL_U: excp_o = {ENV_CALL_FROM_U_MODE,{32'b0,fet_dec__instr_i},1'b1};
                    PRIV_LVL_S: excp_o = {ENV_CALL_FROM_S_MODE,{32'b0,fet_dec__instr_i},1'b1};
                    PRIV_LVL_M: excp_o = {ENV_CALL_FROM_M_MODE,{32'b0,fet_dec__instr_i},1'b1};
                    default:;
                endcase
            end else if(ebreak) begin
                completed_o     = 1'b1;
                excp_o  = {BREAK_POINT,{32'b0,fet_dec__instr_i},1'b1}; 
            end
        end 
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_decoder

// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_exu.v
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

module sy_ppl_exu
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    // =====================================
    // [From Dispatch]
    input   logic                           dis_exu__vld_i,          
    output  logic                           exu_dis__rdy_o,          
    input   exu_packet_t                    dis_exu__packet_i,
    // =====================================
    // [From CSR]
    input   logic[2:0]                      csr_fpu__frm_i,
    input   logic[6:0]                      csr_fpu__prec_i,
    // =====================================
    // [Read GPR Register]
    output  logic[PHY_REG_WTH-1:0]          gpr_rs1_idx_o,
    output  logic[PHY_REG_WTH-1:0]          gpr_rs2_idx_o,
    input   logic[DWTH-1:0]                 gpr_rs1_data_i,
    input   logic[DWTH-1:0]                 gpr_rs2_data_i,
    // =====================================
    // [Write GPR Register] (ALU/MDU/FPU)
    output  logic[2:0]                      gpr_wr_en_o,
    output  logic[2:0][PHY_REG_WTH-1:0]     gpr_wr_idx_o,
    output  logic[2:0][DWTH-1:0]            gpr_wr_data_o,
    // =====================================
    // [Read FPR]
    output  logic[PHY_REG_WTH-1:0]          fpr_rs1_idx_o,
    output  logic[PHY_REG_WTH-1:0]          fpr_rs2_idx_o,
    output  logic[PHY_REG_WTH-1:0]          fpr_rs3_idx_o,
    input   logic[DWTH-1:0]                 fpr_rs1_data_i,
    input   logic[DWTH-1:0]                 fpr_rs2_data_i,
    input   logic[DWTH-1:0]                 fpr_rs3_data_i,
    // =====================================
    // [Write FPR Register] (FPU)
    output  logic                           fpr_wr_en_o,
    output  logic[PHY_REG_WTH-1:0]          fpr_wr_idx_o,
    output  logic[DWTH-1:0]                 fpr_wr_data_o,
    // =====================================
    // [Awake From LSU/CSR]
    input   logic                           lsu_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          lsu_awake_idx_i,
    input   logic                           lsu_awake_is_fp_i,
    input   logic                           csr_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          csr_awake_idx_i,
    // =====================================
    // [Awake TO LSU/CSR]
    output  logic                           alu_awake_vld_o,
    output  logic[PHY_REG_WTH-1:0]          alu_awake_idx_o,
    output  logic                           mdu_awake_vld_o,
    output  logic[PHY_REG_WTH-1:0]          mdu_awake_idx_o,
    output  logic                           fpu_awake_vld_o,
    output  logic[PHY_REG_WTH-1:0]          fpu_awake_idx_o,
    output  logic                           fpu_awake_is_fp_o,
    // =====================================
    // [Commit to ROB] 
    output  alu_commit_t                    alu_rob__commit_o,
    output  fpu_commit_t                    fpu_rob__commit_o,
    output  mdu_commit_t                    mdu_rob__commit_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                           issue_vld;
    logic                           issue_rdy;  
    exu_packet_t                    issue_packet;
    logic                           reg_rd_stall;
    logic                           reg_rd_act_unkilled;
    logic                           reg_rd_act;
    logic                           reg_rd_avail;
    logic                           reg_rd_accpt;
    logic[DWTH-1:0]                 rs1_reg_byp;
    logic[DWTH-1:0]                 rs2_reg_byp;
    logic[DWTH-1:0]                 rs3_reg_byp;
    logic[DWTH-1:0]                 rs1_data_st1;
    logic[DWTH-1:0]                 rs2_data_st1;
    logic[DWTH-1:0]                 rs3_data_st1;
    rs1_src_e                       rs1_src_sel;
    rs2_src_e                       rs2_src_sel;
    rs3_src_e                       rs3_src_sel;
    logic                           exu_dis_stall;
    logic                           exu_dis_act_unkilled;
    logic                           exu_dis_act;
    logic                           exu_dis_avail;
    logic                           exu_dis_accpt;
    logic                           read_reg_act;          
    exu_packet_t                    issue_packet_st1;
    exu_packet_t                    issue_packet_st2;
    logic[DWTH-1:0]                 rs1_data_st2;
    logic[DWTH-1:0]                 rs2_data_st2;
    logic[DWTH-1:0]                 rs3_data_st2;
    logic                           st2_ready;
    logic                           st2_act;  
    logic                           st2_act_dly;  
    logic                           alu_en;        
    logic                           lsu_en;
    logic                           mdu_en;
    logic[DWTH-1:0]                 jbr_base;
    logic                           div_busy;    
    logic                           div_wb_stall;    
    logic                           div_busy_stall;
    logic                           fpu_stall;     
    logic                           fpu_busy;
    logic                           csr_stall;     
    logic                           csr_busy;
    logic                           mdu_wb_stall;
//======================================================================================================================
// Stage0 : Issue Queen
//======================================================================================================================
    // Stage 0 : Issue Queen
    sy_ppl_exu_iq exu_iq_inst(
        .clk_i                  (clk_i),                           
        .rst_i                  (rst_i),                           
        .flush_i                (flush_i),       

        .dis_exu__vld_i         (dis_exu__vld_i),                        
        .exu_dis__rdy_o         (exu_dis__rdy_o),                        
        .dis_exu__packet_i      (dis_exu__packet_i),                 

        .issue_vld_o            (issue_vld   ),           
        .issue_rdy_i            (issue_rdy   ),           
        .issue_packet_o         (issue_packet),              
        // awake from alu
        .alu_awake_vld_i        (alu_awake_vld_o  ),               
        .alu_awake_idx_i        (alu_awake_idx_o  ),               
        // awake from csr
        .csr_awake_vld_i        (csr_awake_vld_i  ),               
        .csr_awake_idx_i        (csr_awake_idx_i  ),               
        // awake from lsu
        .lsu_awake_vld_i        (lsu_awake_vld_i  ),               
        .lsu_awake_idx_i        (lsu_awake_idx_i  ),               
        .lsu_awake_is_fp_i      (lsu_awake_is_fp_i),                 
        // awake from mdu
        .mdu_awake_vld_i        (mdu_awake_vld_o  ),               
        .mdu_awake_idx_i        (mdu_awake_idx_o  ),               
        // awake from fpu
        .fpu_awake_vld_i        (fpu_awake_vld_o  ),               
        .fpu_awake_idx_i        (fpu_awake_idx_o  ),               
        .fpu_awake_is_fp_i      (fpu_awake_is_fp_o)
    );
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
            reg_rd_act_unkilled <= `TCQ reg_rd_accpt ? issue_vld : reg_rd_act;
        end
    end

    assign reg_rd_act   = reg_rd_act_unkilled && !reg_rd_kill;
    assign reg_rd_avail = reg_rd_act && !reg_rd_stall && exu_dis_accpt;
    assign reg_rd_accpt = !reg_rd_act || reg_rd_avail;
    assign issue_rdy = reg_rd_accpt;

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            issue_packet_st1 <= '0;
        end else begin
            if (reg_rd_accpt) begin
                issue_packet_st1 <= issue_packet;
            end
        end
    end

    assign gpr_rs1_idx_o = issue_packet_st1.phy_rs1_idx;
    assign gpr_rs2_idx_o = issue_packet_st1.phy_rs2_idx;
    assign fpr_rs1_idx_o = issue_packet_st1.phy_rs1_idx;
    assign fpr_rs2_idx_o = issue_packet_st1.phy_rs2_idx;
    assign fpr_rs3_idx_o = issue_packet_st1.phy_rs3_idx;

    // TODO : add bypass network
    assign rs1_reg_byp = issue_packet_st1.rs1_is_fp ? fpr_rs1_data_i : gpr_rs1_data_i;
    assign rs2_reg_byp = issue_packet_st1.rs2_is_fp ? fpr_rs2_data_i : gpr_rs2_data_i;
    assign rs3_reg_byp = fpr_rs3_data_i;
    // set rs1 and rs2
    assign rs1_src_sel = issue_packet_st1.exu_cmd.rs1_src_sel;
    assign rs2_src_sel = issue_packet_st1.exu_cmd.rs2_src_sel;
    assign rs3_src_sel = issue_packet_st1.exu_cmd.rs3_src_sel;
    always_comb begin : sel_rs1
        case(rs1_src_sel)
            RS1_SRC_REG1: rs1_data_st1 = rs1_reg_byp;
            RS1_SRC_REG2: rs1_data_st1 = rs2_reg_byp;
            RS1_SRC_PC:   rs1_data_st1 = issue_packet_st1.pc;
            RS1_SRC_IMM:  rs1_data_st1 = issue_packet_st1.exu_cmd.imm;
            default:      rs1_data_st1 = DWTH'(0);
        endcase
    end
    
    always_comb begin : sel_rs2
        case(rs2_src_sel)
            RS2_SRC_REG1:  rs2_data_st1 = rs1_reg_byp;
            RS2_SRC_REG2:  rs2_data_st1 = rs2_reg_byp;
            RS2_SRC_IMM:   rs2_data_st1 = issue_packet_st1.exu_cmd.imm;
            RS2_SRC_FOUR:  rs2_data_st1 = issue_packet_st1.is_c ? DWTH'(2) : DWTH'(4);
            default:       rs2_data_st1 = DWTH'(0);
        endcase
    end

    always_comb begin : sel_rs3
        case(rs3_src_sel)
            RS3_SRC_REG2:  rs3_data_st1 = rs2_reg_byp;
            RS3_SRC_REG3:  rs3_data_st1 = rs3_reg_byp;
            RS3_SRC_IMM:   rs3_data_st1 = issue_packet_st1.exu_cmd.imm;
            default:       rs3_data_st1 = DWTH'(0);
        endcase
    end
//======================================================================================================================
// Stage2 : dispatch Instr to different unit, such as MDU/ALU/CSR/FPU
//======================================================================================================================
    // Stage 2 : dispatch to MDU/ALU/CSR/FPU
    assign exu_dis_stall = div_busy_stall || mdu_wb_stall || fpu_stall; 
    assign exu_dis_kill  = flush_i;

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            exu_dis_act_unkilled <= `TCQ 1'b0;
        end else begin
            exu_dis_act_unkilled <= `TCQ exu_dis_accpt ? reg_rd_avail : exu_dis_act;
        end
    end

    assign exu_dis_act   = exu_dis_act_unkilled && !exu_dis_kill;
    assign exu_dis_avail = exu_dis_act && !exu_dis_stall;
    assign exu_dis_accpt = !exu_dis_act || exu_dis_avail;

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            issue_packet_st2 <= '0;
            rs1_data_st2     <= '0;
            rs2_data_st2     <= '0;
            rs3_data_st2     <= '0;
            jbr_base         <= '0;
        end else begin
            if (exu_dis_accpt) begin
                issue_packet_st2 <= issue_packet_st1;
                rs1_data_st2     <= rs1_data_st1;
                rs2_data_st2     <= rs2_data_st1;
                rs3_data_st2     <= rs3_data_st1;
                jbr_base         <= (issue_packet_st1.instr_cls == INSTR_CLS_JBR && issue_packet_st1.exu_cmd.jbr_op == JBR_OP_JALR)
                                     ? rs1_reg_byp : issue_packet_st1.pc;
            end
        end
    end

    // LSU Queen has enough space and div is not busy
    assign div_busy_stall = exu_dis_act && div_busy && issue_packet_st2.instr_cls == INSTR_CLS_MDU && 
                                 (issue_packet_st2.exu_cmd.mdu_op == MDU_OP_DIV || issue_packet_st2.exu_cmd.mdu_op == MDU_OP_REM);
    assign mdu_wb_stall   = exu_dis_act && div_wb_stall && issue_packet_st2.instr_cls == INSTR_CLS_MDU && 
                                 (issue_packet_st2.exu_cmd.mdu_op == MDU_OP_MUL || issue_packet_st2.exu_cmd.mdu_op == MDU_OP_MULH);
    assign fpu_stall      = exu_dis_act && fpu_busy && issue_packet_st2.instr_cls == INSTR_CLS_FPU;
                                 
    assign alu_en = exu_dis_avail && (issue_packet_st2.instr_cls == INSTR_CLS_NORMAL || 
                                      issue_packet_st2.instr_cls == INSTR_CLS_JBR);
    assign mdu_en = exu_dis_avail && (issue_packet_st2.instr_cls == INSTR_CLS_MDU);
    assign fpu_en = exu_dis_avail && (issue_packet_st2.instr_cls == INSTR_CLS_FPU);

    // To ALU
    sy_ppl_alu alu_inst(
        .clk_i                    (clk_i),                                   
        .rst_i                    (rst_i),                                   
        .flush_i                  (flush_i),

        .alu_en_i                 (alu_en),                
        .rob_idx_i                (issue_packet_st2.rob_idx),                 

        .instr_cls_i              (issue_packet_st2.instr_cls),                       
        .als_opcode_i             (issue_packet_st2.exu_cmd.als_op),                    
        .jbr_opcode_i             (issue_packet_st2.exu_cmd.jbr_op),                    
        .is_32_i                  (issue_packet_st2.exu_cmd.is_32),                        
        .is_c_i                   (issue_packet_st2.is_c),                        
        .rs1_data_i               (rs1_data_st2),                  
        .rs2_data_i               (rs2_data_st2),                  
        .jbr_base_i               (jbr_base),                  
        .pc_i                     (issue_packet_st2.pc),            
        .imm_i                    (issue_packet_st2.exu_cmd.imm),             
        .rdst_en_i                (issue_packet_st2.rdst_en),                 
        .rdst_idx_i               (issue_packet_st2.phy_rdst_idx),                  

        .alu_rob__commit_o        (alu_rob__commit_o),                        

        .alu_gpr__we_o            (gpr_wr_en_o[0]),
        .alu_gpr__idx_o           (gpr_wr_idx_o[0]),
        .alu_gpr__wdata_o         (gpr_wr_data_o[0]), 

        .alu_awake_vld_o          (alu_awake_vld_o),
        .alu_awake_idx_o          (alu_awake_idx_o)
    );   
    // TO MDU
    sy_ppl_mdu mdu_inst(
        .clk_i                    (clk_i),                       
        .rst_i                    (rst_i),                       
        .flush_i                  (flush_i),   
    
        .mdu_en_i                 (mdu_en),    
        .mdu_opcode_i             (issue_packet_st2.exu_cmd.mdu_op),        
        .mdu_rs1_sign_i           (issue_packet_st2.exu_cmd.rs1_sign),          
        .mdu_rs2_sign_i           (issue_packet_st2.exu_cmd.rs2_sign),          
        .mdu_rs1_data_i           (rs1_data_st2),          
        .mdu_rs2_data_i           (rs2_data_st2),          
        .mdu_rdst_idx_i           (issue_packet_st2.phy_rdst_idx),          
        .mdu_is_32_i              (issue_packet_st2.exu_cmd.is_32),       
        .mdu_rob_idx_i            (issue_packet_st2.rob_idx),
        .div_busy_o               (div_busy),      
        .div_wb_stall_o           (div_wb_stall),          
    
        .mdu_awake__vld_o         (mdu_awake_vld_o),
        .mdu_awake__idx_o         (mdu_awake_idx_o),

        .mdu_rob__commit_o        (mdu_rob__commit_o),

        .mdu_gpr__we_o            (gpr_wr_en_o[1]   ),         
        .mdu_gpr__idx_o           (gpr_wr_idx_o[1]  ),          
        .mdu_gpr__wdata_o         (gpr_wr_data_o[1] )
    );

    sy_ppl_fpu fpu_inst(
        .clk_i                     (clk_i),                            
        .rst_i                     (rst_i),                            
        .flush_i                   (flush_i),        

        .csr_fpu__frm_i            (csr_fpu__frm_i ),               
        .csr_fpu__prec_i           (csr_fpu__prec_i),                

        .fpu_en_i                  (fpu_en),         
        .fpu_busy_o                (fpu_busy),                    
        .fpu_op_i                  (issue_packet_st2.exu_cmd.fpu_op),         
        .fpu_rs1_i                 (rs1_data_st2),          
        .fpu_rs2_i                 (rs2_data_st2),          
        .fpu_rs3_i                 (rs3_data_st2),          
        .fpu_fmt_i                 (issue_packet_st2.exu_cmd.fmt),          
        .fpu_rm_i                  (issue_packet_st2.exu_cmd.rm),         
        .fpu_rdst_idx_i            (issue_packet_st2.phy_rdst_idx),               
        .fpu_rdst_is_fp_i          (issue_packet_st2.rdst_is_fp),                 
        .fpu_rob_idx_i             (issue_packet_st2.rob_idx),              

        .fpr_wr_en_o               (fpr_wr_en_o  ),                
        .fpr_wr_idx_o              (fpr_wr_idx_o ),             
        .fpr_wr_data_o             (fpr_wr_data_o),              

        .gpr_wr_en_o               (gpr_wr_en_o  [2]),                
        .gpr_wr_idx_o              (gpr_wr_idx_o [2]),             
        .gpr_wr_data_o             (gpr_wr_data_o[2]),              

        .fpu_rob__commit_o         (fpu_rob__commit_o),                  

        .fpu_awake_vld_o           (fpu_awake_vld_o   ),                
        .fpu_awake_idx_o           (fpu_awake_idx_o   ),                
        .fpu_awake_is_fp_o         (fpu_awake_is_fp_o )
    );


//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_exu

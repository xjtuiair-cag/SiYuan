// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_fpu.v
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

module sy_ppl_fpu
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset & flush_i]
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    // =====================================
    // [From CSR]
    input   logic[2:0]                      csr_fpu__frm_i,
    input   logic[6:0]                      csr_fpu__prec_i,
    // =====================================
    // [From EXU]
    input   logic                           fpu_en_i,
    output  logic                           fpu_busy_o,         
    input   fpu_opcode_e                    fpu_op_i,
    input   logic[DWTH-1:0]                 fpu_rs1_i,
    input   logic[DWTH-1:0]                 fpu_rs2_i,
    input   logic[DWTH-1:0]                 fpu_rs3_i,
    input   logic [1:0]                     fpu_fmt_i,
    input   logic [2:0]                     fpu_rm_i,
    input   logic[PHY_REG_WTH-1:0]          fpu_rdst_idx_i,
    input   logic                           fpu_rdst_is_fp_i,
    input   logic[ROB_WTH-1:0]              fpu_rob_idx_i,
    // =====================================
    // [Write FPR]
    output  logic                           fpr_wr_en_o,    
    output  logic[PHY_REG_WTH-1:0]          fpr_wr_idx_o,
    output  logic[DWTH-1:0]                 fpr_wr_data_o,
    // =====================================
    // [Write GPR]
    output  logic                           gpr_wr_en_o,    
    output  logic[PHY_REG_WTH-1:0]          gpr_wr_idx_o,
    output  logic[DWTH-1:0]                 gpr_wr_data_o,
    // =====================================
    // [commit]
    output  fpu_commit_t                    fpu_rob__commit_o,
    // =====================================
    // [awake to imu]
    output  logic                           fpu_awake_vld_o,
    output  logic[PHY_REG_WTH-1:0]          fpu_awake_idx_o,
    output  logic                           fpu_awake_is_fp_o
);
//======================================================================================================================
// Parameters
//======================================================================================================================

//====================================================================================================================== 
// Wire & Reg declaration
//======================================================================================================================
    logic                           fpu_ready;
    fu_data_t                       fpu_data;
    logic                           fpu_res_vld;
    logic[DWTH-1:0]                 fpu_res;
    logic[4:0]                      fpu_status;     
    logic[PHY_REG_WTH-1:0]          fpu_rdst_idx_q;
    logic                           fpu_rdst_is_fp_q;              
    logic[ROB_WTH-1:0]              fpu_rob_idx_q;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign fpu_data.operator    = fpu_op_i;
    assign fpu_data.operand_a   = fpu_rs1_i;
    assign fpu_data.operand_b   = fpu_rs2_i;
    assign fpu_data.imm         = fpu_rs3_i;
    assign fpu_data.trans_id = '0;
    assign fpu_data.fu       = FPU;

    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            fpu_busy_o <= `TCQ 1'b0;
        end else begin
            if (fpu_en_i && fpu_ready) begin
                fpu_busy_o <= `TCQ 1'b1;
            end else if (flush_i) begin
                fpu_busy_o <= `TCQ 1'b0;
            end else if (fpu_res_vld) begin
                fpu_busy_o <= `TCQ 1'b0;
            end
        end
    end
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            fpu_rdst_idx_q <= `TCQ '0;
            fpu_rdst_is_fp_q <= `TCQ '0;
            fpu_rob_idx_q <= `TCQ '0;
        end else begin
            if (fpu_en_i && fpu_ready) begin
                fpu_rdst_idx_q <= `TCQ fpu_rdst_idx_i;
                fpu_rdst_is_fp_q <= `TCQ fpu_rdst_is_fp_i;
                fpu_rob_idx_q <= `TCQ fpu_rob_idx_i;
            end
        end
    end

    fpu_wrap fpu(
       .clk_i                  (clk_i),   
       .rst_ni                 (rst_i),    
       .flush_i                (flush_i),     
       .fpu_valid_i            (fpu_en_i),         
       .fpu_ready_o            (fpu_ready),         
       .fu_data_i              (fpu_data),       

       .fpu_fmt_i              (fpu_fmt_i),       
       .fpu_rm_i               (fpu_rm_i),      
       .fpu_frm_i              (csr_fpu__frm_i ),       
       .fpu_prec_i             (csr_fpu__prec_i),        
       .fpu_trans_id_o         (),            
       .result_o               (fpu_res),      
       .fpu_valid_o            (fpu_res_vld),         
       .fpu_status_o           (fpu_status)         
    );
    assign fpu_rob__commit_o.vld      = fpu_res_vld; 
    assign fpu_rob__commit_o.rob_idx  = fpu_rob_idx_q;
    assign fpu_rob__commit_o.status   = fpu_status;
    assign fpu_rob__commit_o.flush_en = 1'b1;

    assign fpu_awake_vld_o            = fpu_res_vld;
    assign fpu_awake_idx_o            = fpu_rdst_idx_q; 
    assign fpu_awake_is_fp_o          = fpu_rdst_is_fp_q;

    assign gpr_wr_en_o                = fpu_res_vld && !fpu_rdst_is_fp_q;
    assign gpr_wr_idx_o               = fpu_rdst_idx_q;
    assign gpr_wr_data_o              = fpu_res;

    assign fpr_wr_en_o                = fpu_res_vld && fpu_rdst_is_fp_q;
    assign fpr_wr_idx_o               = fpu_rdst_idx_q;
    assign fpr_wr_data_o              = fpu_res;
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_fpu

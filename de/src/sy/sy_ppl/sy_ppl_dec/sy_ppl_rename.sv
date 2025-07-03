// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_rename.v
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

module sy_ppl_rename
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      

    input   logic                           flush_i,
    output  logic                           fl_stall_o,
    // ====================================
    // [from decode]
    input   logic                           instr_act_i,
    input   logic[4:0]                      arc_rs1_idx_i, 
    input   logic[4:0]                      arc_rs2_idx_i, 
    input   logic[4:0]                      arc_rs3_idx_i, 
    input   logic[4:0]                      arc_rdst_idx_i, 

    input   logic                           rs1_is_en_i,
    input   logic                           rs2_is_en_i,
    input   logic                           rs3_is_en_i,

    input   logic                           rdst_is_en_i,  // whether this instr need to write to regfile
    input   logic                           rs1_is_fp_i,  
    input   logic                           rs2_is_fp_i,  
    input   logic                           rdst_is_fp_i,

    output  logic[PHY_REG_WTH-1:0]          phy_rs1_idx_o,
    output  logic[PHY_REG_WTH-1:0]          phy_rs2_idx_o,
    output  logic[PHY_REG_WTH-1:0]          phy_rs3_idx_o,
    output  logic[PHY_REG_WTH-1:0]          phy_rdst_idx_o,
    output  logic[PHY_REG_WTH-1:0]          phy_old_rdst_idx_o,
    // ====================================
    // [from ROB]
    input   logic                           rob_update_arat_en_i,    
    input   logic                           rob_update_fp_reg_i,    
    input   logic[4:0]                      rob_update_arat_arc_i,
    input   logic[PHY_REG_WTH-1:0]          rob_update_arat_phy_i,
    input   logic[PHY_REG_WTH-1:0]          rob_update_arat_old_phy_i

);
//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                                   gpr_rdst_act;
    logic                                   fpr_rdst_act;
    logic                                   gpr_fl_stall; 
    logic                                   fpr_fl_stall; 
    logic[PHY_REG_WTH-1:0]                  gpr_phy_rdst_idx; 
    logic[PHY_REG_WTH-1:0]                  fpr_phy_rdst_idx; 

    logic[PHY_REG_WTH-1:0]                  gpr_phy_rs1_idx; 
    logic[PHY_REG_WTH-1:0]                  gpr_phy_rs2_idx; 
    logic[PHY_REG_WTH-1:0]                  gpr_phy_rdst_old_idx;

    logic[PHY_REG_WTH-1:0]                  fpr_phy_rs1_idx; 
    logic[PHY_REG_WTH-1:0]                  fpr_phy_rs2_idx; 
    logic[PHY_REG_WTH-1:0]                  fpr_phy_rs3_idx; 
    logic[PHY_REG_WTH-1:0]                  fpr_phy_rdst_old_idx;
//======================================================================================================================
// Instance
//======================================================================================================================
    // lookup free list to find free physical register
    assign gpr_rdst_act = instr_act_i && rdst_is_en_i && !rdst_is_fp_i;
    assign fpr_rdst_act = instr_act_i && rdst_is_en_i && rdst_is_fp_i;

    // we only apply register renaming to general purpose registers, not floating point registers
    assign phy_rs1_idx_o = rs1_is_en_i ? (rs1_is_fp_i ? fpr_phy_rs1_idx : gpr_phy_rs1_idx) : '0;
    assign phy_rs2_idx_o = rs2_is_en_i ? (rs2_is_fp_i ? fpr_phy_rs2_idx : gpr_phy_rs2_idx) : '0;
    assign phy_rs3_idx_o = rs3_is_en_i ? fpr_phy_rs3_idx : '0;
    assign phy_rdst_idx_o = rdst_is_en_i ? (rdst_is_fp_i ? fpr_phy_rdst_idx : gpr_phy_rdst_idx) : '0;
    assign phy_old_rdst_idx_o = rdst_is_en_i ? (rdst_is_fp_i ? fpr_phy_rdst_old_idx : gpr_phy_rdst_old_idx) : '0;

    assign fl_stall_o = gpr_fl_stall | fpr_fl_stall;

    sy_ppl_fl #(
        .PHY_REG_NUM                    (PHY_REG)
    ) gpr_fl_inst(
        .clk_i                          (clk_i),                              
        .rst_i                          (rst_i),                              
        .flush_i                        (flush_i),
        .fl_stall_o                     (gpr_fl_stall),

        .rdst_en_i                      (gpr_rdst_act),            
        .arc_rdst_idx_i                 (arc_rdst_idx_i),                  
        .phy_rdst_idx_o                 (gpr_phy_rdst_idx),                 

        .rob_update_afl_en_i            (rob_update_arat_en_i && !rob_update_fp_reg_i),                           
        .rob_update_afl_phy_i           (rob_update_arat_phy_i),                            
        .rob_update_afl_old_phy_i       (rob_update_arat_old_phy_i)                            
    );

    sy_ppl_fp_fl #(
        .PHY_REG_NUM                    (PHY_REG)
    ) fpr_fl_inst(
        .clk_i                          (clk_i),                              
        .rst_i                          (rst_i),                              
        .flush_i                        (flush_i),
        .fl_stall_o                     (fpr_fl_stall),

        .rdst_en_i                      (fpr_rdst_act),            
        .arc_rdst_idx_i                 (arc_rdst_idx_i),                  
        .phy_rdst_idx_o                 (fpr_phy_rdst_idx),                 

        .rob_update_afl_en_i            (rob_update_arat_en_i && rob_update_fp_reg_i),                           
        .rob_update_afl_phy_i           (rob_update_arat_phy_i),                            
        .rob_update_afl_old_phy_i       (rob_update_arat_old_phy_i)                            
    );

    sy_ppl_rat #(
        .PHY_REG_NUM                    (PHY_REG)
    ) gpr_rat_inst(
        .clk_i                          (clk_i),                           
        .rst_i                          (rst_i),                           

        .flush_i                        (flush_i),       
        .arc_rs1_idx_i                  (arc_rs1_idx_i),              
        .arc_rs2_idx_i                  (arc_rs2_idx_i),              
        .arc_rdst_idx_i                 (arc_rdst_idx_i),               

        .phy_rs1_idx_o                  (gpr_phy_rs1_idx),             
        .phy_rs2_idx_o                  (gpr_phy_rs2_idx),             
        .phy_old_rdst_idx_o             (gpr_phy_rdst_old_idx),                  

        .rdst_en_i                      (gpr_rdst_act),               
        .phy_rdst_idx_i                 (gpr_phy_rdst_idx),               

        .rob_update_arat_en_i           (rob_update_arat_en_i && !rob_update_fp_reg_i),                        
        .rob_update_arat_arc_i          (rob_update_arat_arc_i),                     
        .rob_update_arat_phy_i          (rob_update_arat_phy_i)
    );

    sy_ppl_fp_rat #(
        .PHY_REG_NUM                    (PHY_REG)
    ) fpr_rat_inst(
        .clk_i                          (clk_i),                           
        .rst_i                          (rst_i),                           

        .flush_i                        (flush_i),       
        .arc_rs1_idx_i                  (arc_rs1_idx_i),              
        .arc_rs2_idx_i                  (arc_rs2_idx_i),              
        .arc_rs3_idx_i                  (arc_rs3_idx_i),              
        .arc_rdst_idx_i                 (arc_rdst_idx_i),               

        .phy_rs1_idx_o                  (fpr_phy_rs1_idx),             
        .phy_rs2_idx_o                  (fpr_phy_rs2_idx),             
        .phy_rs3_idx_o                  (fpr_phy_rs3_idx),             
        .phy_old_rdst_idx_o             (fpr_phy_rdst_old_idx),                  

        .rdst_en_i                      (fpr_rdst_act),               
        .phy_rdst_idx_i                 (fpr_phy_rdst_idx),               

        .rob_update_arat_en_i           (rob_update_arat_en_i && rob_update_fp_reg_i),                        
        .rob_update_arat_arc_i          (rob_update_arat_arc_i),                     
        .rob_update_arat_phy_i          (rob_update_arat_phy_i)
    );
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_rename

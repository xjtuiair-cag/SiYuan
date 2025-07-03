// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_lsu.v
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

module sy_ppl_lsu
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset & flush_i]
    // -- <clock>
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    // =====================================
    // [From Dispatch]
    input   logic                           dis_lsu__vld_i,   
    output  logic                           lsu_dis__rdy_o,           
    input   lsu_packet_t                    dis_lsu__packet_i,
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
    // [To D cache]
    output  logic                           lsu_dcache__vld_o,
    input   logic                           dcache_lsu__rdy_i,
    output  dcache_req_t                    lsu_dcache__req_o,    
    input   dcache_rsp_t                    dcache_lsu__rsp_i,  
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
    // [Write Back to GPR Reg]
    output  logic                           gpr_wr_we_o,
    output  logic[PHY_REG_WTH-1:0]          gpr_wr_idx_o,
    output  logic[DWTH-1:0]                 gpr_wr_data_o,
    // =====================================
    // [Write Back to FPR Reg]
    output  logic                           fpr_wr_we_o,
    output  logic[PHY_REG_WTH-1:0]          fpr_wr_idx_o,
    output  logic[DWTH-1:0]                 fpr_wr_data_o,
    // =====================================
    // [Awake TO FPU/IMU]
    output  logic                           lsu_awake_vld_o,
    output  logic[PHY_REG_WTH-1:0]          lsu_awake_idx_o,
    output  logic                           lsu_awake_is_fp_o,    
    // =====================================
    // [Awake FROM EXU]
    input   logic                           alu_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          alu_awake_idx_i,
    input   logic                           csr_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          csr_awake_idx_i,
    input   logic                           mdu_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          mdu_awake_idx_i,
    input   logic                           fpu_awake_vld_i,
    input   logic[PHY_REG_WTH-1:0]          fpu_awake_idx_i,
    input   logic                           fpu_awake_is_fp_i,
    // =====================================
    // [Commit to ROB] 
    output  lsu_commit_t                    lsu_rob__commit_o,
    input   logic                           rob_lsu__retire_en_i,
    output  logic                           lsu_ctrl__sq_retire_empty_o 
);

//======================================================================================================================
// Parameters
//======================================================================================================================
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                           iq_issue_vld;
    logic                           iq_issue_rdy;
    logic[AWTH-1:0]                 iq_issue_paddr;
    logic[DWTH-1:0]                 iq_issue_wdata;
    logic[PHY_REG_WTH-1:0]          iq_issue_rdst_idx;
    logic                           iq_issue_rdst_is_fp;
    size_e                          iq_issue_size;
    amo_opcode_e                    iq_issue_amo_opcode;
    mem_opcode_e                    iq_issue_mem_opcode;
    logic[ROB_WTH-1:0]              iq_issue_rob_idx;
    logic                           iq_issue_sign_ext;

    logic                           atrans_vld;
    logic                           atrans_rdy;
    logic[LSU_IQ_WTH-1:0]           atrans_iq_idx;
    logic[ROB_WTH-1:0]              atrans_rob_idx;
    logic[PHY_REG_WTH-1:0]          atrans_rs1_idx;
    logic[PHY_REG_WTH-1:0]          atrans_rs2_idx;
    logic                           atrans_rs2_is_fp;
    logic[DWTH-1:0]                 atrans_imm;
    mem_opcode_e                    atrans_mem_op;
    size_e                          atrans_size;

    logic                           atrans_done;
    logic[LSU_IQ_WTH-1:0]           atrans_done_idx;
    logic[DWTH-1:0]                 atrans_wdata;
    logic[AWTH-1:0]                 atrans_paddr;
//======================================================================================================================
// LSU IQ
//======================================================================================================================
    sy_ppl_lsu_iq lsu_iq_inst(
        .clk_i                  (clk_i),                           
        .rst_i                  (rst_i),                           
        .flush_i                (flush_i),       

        .dis_lsu__vld_i         (dis_lsu__vld_i),                        
        .lsu_dis__rdy_o         (lsu_dis__rdy_o),                        
        .dis_lsu__packet_i      (dis_lsu__packet_i),                 

        .iq_issue_vld_o          (iq_issue_vld      ),     
        .iq_issue_rdy_i          (iq_issue_rdy      ),     
        .iq_issue_paddr_o        (iq_issue_paddr    ),       
        .iq_issue_wdata_o        (iq_issue_wdata    ),       
        .iq_issue_rdst_idx_o     (iq_issue_rdst_idx ),          
        .iq_issue_rdst_is_fp_o   (iq_issue_rdst_is_fp),            
        .iq_issue_size_o         (iq_issue_size     ),      
        .iq_issue_amo_opcode_o   (iq_issue_amo_opcode),            
        .iq_issue_mem_opcode_o   (iq_issue_mem_opcode),            
        .iq_issue_rob_idx_o      (iq_issue_rob_idx  ),         
        .iq_issue_sign_ext_o     (iq_issue_sign_ext ),          

        .atrans_vld_o            (atrans_vld    ),  
        .atrans_rdy_i            (atrans_rdy    ),  
        .atrans_iq_idx_o         (atrans_iq_idx ),  
        .atrans_rob_idx_o        (atrans_rob_idx),      
        .atrans_rs1_idx_o        (atrans_rs1_idx),      
        .atrans_rs2_idx_o        (atrans_rs2_idx),      
        .atrans_rs2_is_fp_o      (atrans_rs2_is_fp),
        .atrans_imm_o            (atrans_imm    ),  
        .atrans_mem_op_o         (atrans_mem_op ),      
        .atrans_size_o           (atrans_size    ),

        .atrans_done_i           (atrans_done    ),   
        .atrans_done_idx_i       (atrans_done_idx),       
        .atrans_wdata_i          (atrans_wdata   ),    
        .atrans_paddr_i          (atrans_paddr   ),    

        // awake from alu
        .alu_awake_vld_i        (alu_awake_vld_i  ),               
        .alu_awake_idx_i        (alu_awake_idx_i  ),               
        // awake from csr
        .csr_awake_vld_i        (csr_awake_vld_i  ),               
        .csr_awake_idx_i        (csr_awake_idx_i  ),    
        // awake from lsu
        .lsu_awake_vld_i        (lsu_awake_vld_o  ),               
        .lsu_awake_idx_i        (lsu_awake_idx_o  ),               
        .lsu_awake_is_fp_i      (lsu_awake_is_fp_o),                 
        // awake from mdu
        .mdu_awake_vld_i        (mdu_awake_vld_i  ),               
        .mdu_awake_idx_i        (mdu_awake_idx_i  ),               
        // awake from fpu
        .fpu_awake_vld_i        (fpu_awake_vld_i  ),               
        .fpu_awake_idx_i        (fpu_awake_idx_i  ),               
        .fpu_awake_is_fp_i      (fpu_awake_is_fp_i)
    );
//======================================================================================================================
// Address Translation Module
//======================================================================================================================
    sy_ppl_lsu_atrans atrans_inst(
        .clk_i                  (clk_i),                 
        .rst_i                  (rst_i),                 
        .flush_i                (flush_i),
    
        .atrans_vld_i           (atrans_vld    ),  
        .atrans_rdy_o           (atrans_rdy    ),  
        .atrans_iq_idx_i        (atrans_iq_idx ),     
        .atrans_rob_idx_i       (atrans_rob_idx),      
        .atrans_rs1_idx_i       (atrans_rs1_idx),      
        .atrans_rs2_idx_i       (atrans_rs2_idx),      
        .atrans_rs2_is_fp_i     (atrans_rs2_is_fp),        
        .atrans_imm_i           (atrans_imm    ),  
        .atrans_mem_op_i        (atrans_mem_op ),      
        .atrans_size_i          (atrans_size   ),   
    
        .atrans_done_o          (atrans_done    ),   
        .atrans_done_idx_o      (atrans_done_idx),       
        .atrans_wdata_o         (atrans_wdata   ),    
        .atrans_paddr_o         (atrans_paddr   ),    
    
        .lsu_mmu__req_o         (lsu_mmu__req_o     ),    
        .lsu_mmu__vaddr_o       (lsu_mmu__vaddr_o   ),      
        .lsu_mmu__is_store_o    (lsu_mmu__is_store_o),         
        .mmu_lsu__hit_i         (mmu_lsu__hit_i     ),    
        .mmu_lsu__valid_i       (mmu_lsu__valid_i   ),      
        .mmu_lsu__paddr_i       (mmu_lsu__paddr_i   ),      
        .mmu_lsu__ex_i          (mmu_lsu__ex_i      ),   
    
        .gpr_rs1_idx_o          (gpr_rs1_idx_o ),   
        .gpr_rs2_idx_o          (gpr_rs2_idx_o ),   
        .gpr_rs1_data_i         (gpr_rs1_data_i),    
        .gpr_rs2_data_i         (gpr_rs2_data_i),    
    
        .fpr_rs2_idx_o          (fpr_rs2_idx_o ),   
        .fpr_rs2_data_i         (fpr_rs2_data_i),    
    
        .atrans_excp_en_o       (lsu_rob__commit_o.excp_en),      
        .atrans_excp_tval_o     (lsu_rob__commit_o.excp_tval),        
        .atrans_excp_cause_o    (lsu_rob__commit_o.excp_code),         
        .atrans_rob_idx_o       (lsu_rob__commit_o.excp_rob_idx)
    );
//======================================================================================================================
// Ctrl Module to access D cache
//======================================================================================================================
    sy_ppl_lsu_ctrl lsu_ctrl_inst(
        .clk_i                          (clk_i),                        
        .rst_i                          (rst_i),                        
        .flush_i                        (flush_i),    
    
        .iq_issue_vld_i                 (iq_issue_vld      ),           
        .iq_issue_rdy_o                 (iq_issue_rdy      ),           
        .iq_issue_paddr_i               (iq_issue_paddr    ),             
        .iq_issue_wdata_i               (iq_issue_wdata    ),             
        .iq_issue_rdst_idx_i            (iq_issue_rdst_idx ),                
        .iq_issue_rdst_is_fp_i          (iq_issue_rdst_is_fp),                 
        .iq_issue_size_i                (iq_issue_size     ),            
        .iq_issue_amo_opcode_i          (iq_issue_amo_opcode),                  
        .iq_issue_mem_opcode_i          (iq_issue_mem_opcode),                  
        .iq_issue_rob_idx_i             (iq_issue_rob_idx  ),               
        .iq_issue_sign_ext_i            (iq_issue_sign_ext ),                

        .lsu_dcache__vld_o              (lsu_dcache__vld_o),
        .dcache_lsu__rdy_i              (dcache_lsu__rdy_i),
        .lsu_dcache__req_o              (lsu_dcache__req_o ),                  
        .dcache_lsu__rsp_i              (dcache_lsu__rsp_i ),                
    
        .gpr_wr_we_o                    (gpr_wr_we_o   ),        
        .gpr_wr_idx_o                   (gpr_wr_idx_o  ),         
        .gpr_wr_data_o                  (gpr_wr_data_o ),          
    
        .fpr_wr_we_o                    (fpr_wr_we_o  ),        
        .fpr_wr_idx_o                   (fpr_wr_idx_o ),         
        .fpr_wr_data_o                  (fpr_wr_data_o),          
    
        .lsu_awake_vld_o                (lsu_awake_vld_o   ),            
        .lsu_awake_idx_o                (lsu_awake_idx_o   ),            
        .lsu_awake_is_fp_o              (lsu_awake_is_fp_o ),                  
    
        .lsu_rob__commit_vld_o          (lsu_rob__commit_o.vld),                  
        .lsu_rob__commit_idx_o          (lsu_rob__commit_o.rob_idx),                  
        .rob_lsu__retire_en_i           (rob_lsu__retire_en_i),                 
        .lsu_ctrl__sq_retire_empty_o    (lsu_ctrl__sq_retire_empty_o)
    );

//======================================================================================================================
// just for simulation
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on
//======================================================================================================================
// probe signals
//======================================================================================================================

endmodule : sy_ppl_lsu

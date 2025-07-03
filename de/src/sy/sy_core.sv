// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_core.v
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
module sy_core
    import sy_pkg::*;
# (
    parameter HART_ID_WTH = 1,
    parameter HART_ID = 0
) (
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      
    // -- <reset>
    input   logic                           rst_i,                      
    // =====================================
    // [ctrl & status]
    input   logic[AWTH-1:0]                 boot_addr_i,

    input   logic[1:0]                      irq_i,
    input   logic                           ipi_i,

    input   logic                           debug_req_i,
    input   logic                           time_irq_i,
    // =====================================
    TL_BUS.Slave                            master
);

//======================================================================================================================
// Parameters
//======================================================================================================================


//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================

logic                           flush;           
logic                           flush_bp;     
logic                           ctrl_fet__set_en;
logic[AWTH-1:0]                 ctrl_fet__set_npc;
logic                           ctrl_fet__act;
logic                           icache_flush;
logic                           icache_flush_done;
logic                           dcache_flush;
logic                           dcache_flush_ack;
logic                           tlb_flush;
logic                           rob_ctrl__fencei_en;
logic                           rob_ctrl__sfence_vma;
logic                           rob_ctrl__uret;          
logic                           rob_ctrl__sret;          
logic                           rob_ctrl__mret;          
logic                           rob_ctrl__need_flush;          
logic                           rob_ctrl__mispred;          
logic                           rob_ctrl__wfi;        
logic                           rob_ctrl__ex_valid;          
ecode_t                         rob_ctrl__ecode;          
logic                           rob_ctrl__is_intr;
logic[AWTH-1:0]                 rob_ctrl__pc;
logic[DWTH-1:0]                 rob_ctrl__excp_tval;
trap_t                          ctrl_csr__trap;
logic                           ctrl_csr__mret;
logic                           ctrl_csr__sret;
logic                           ctrl_csr__dret;
logic[AWTH-1:0]                 csr_ctrl__trap_vec;
logic[AWTH-1:0]                 csr_ctrl__epc;
logic                           csr_ctrl__wfi_wakeup;
logic                           lsu_ctrl__st_queen_empty;
// fonted
fetch_req_t                     fet_icache__dreq;
fetch_rsp_t                     icache_fet__drsp;
bht_update_t                    rob_fet__bht_update;
btb_update_t                    rob_fet__btb_update;
logic                           fet_dec__vld;
logic                           dec_fet__rdy;
logic[AWTH-1:0]                 fet_dec__npc;
logic[AWTH-1:0]                 fet_dec__pc;
logic[IWTH-1:0]                 fet_dec__instr;
logic                           fet_dec__is_compressed;
excp_t                          fet_dec__excp;      

intr_ctrl_t                     intr_ctrl;
priv_lvl_t                      csr_dec__priv_lvl;
xs_t                            csr_dec__fs;
logic[2:0]                      csr_dec__frm;
logic                           csr_dec__tvm;
logic                           csr_dec__tw;
logic                           csr_dec__tsr; 
logic                           csr_dec__debug_mode;    

logic                           rob_update_arat_en;    
logic                           rob_update_fp_reg;
logic[4:0]                      rob_update_arat_arc;
logic[PHY_REG_WTH-1:0]          rob_update_arat_phy;
logic[PHY_REG_WTH-1:0]          rob_update_arat_old_phy;
logic                           dec_dis__vld;
logic                           dis_dec__rdy;
dispatch_t                      dec_dis__data;

logic                           dis_exu__vld;
logic                           exu_dis__rdy;
exu_packet_t                    dis_exu__packet;    
logic                           dis_csr__vld;
logic                           csr_dis__rdy;
csr_packet_t                    dis_csr__packet;    
logic                           dis_lsu__vld;
logic                           lsu_dis__rdy;
lsu_packet_t                    dis_lsu__packet;    
logic                           dis_rob__vld;
logic                           rob_dis__rdy;
rob_t                           dis_rob__packet;    
logic[ROB_WTH-1:0]              rob_dis_idx;
logic                           alu_update_en;
logic[PHY_REG_WTH-1:0]          alu_update_idx;
logic                           lsu_update_en;
logic                           lsu_update_is_fp;
logic[PHY_REG_WTH-1:0]          lsu_update_idx;
logic                           mdu_update_en;
logic[PHY_REG_WTH-1:0]          mdu_update_idx;
logic                           fpu_update_en;
logic                           fpu_update_is_fp;
logic[PHY_REG_WTH-1:0]          fpu_update_idx;

logic[2:0]                      exu_gpr_wr_en;
logic[2:0][PHY_REG_WTH-1:0]     exu_gpr_wr_idx;
logic[2:0][DWTH-1:0]            exu_gpr_wr_data;

logic                           csr_gpr_wr_en;
logic[PHY_REG_WTH-1:0]          csr_gpr_wr_idx;
logic[DWTH-1:0]                 csr_gpr_wr_data;

logic                           lsu_gpr_wr_en;
logic[PHY_REG_WTH-1:0]          lsu_gpr_wr_idx;
logic[DWTH-1:0]                 lsu_gpr_wr_data;

logic                           fpu_gpr_wr_en;
logic[PHY_REG_WTH-1:0]          fpu_gpr_wr_idx;
logic[DWTH-1:0]                 fpu_gpr_wr_data;

logic                           fpu_awake_vld;
logic[PHY_REG_WTH-1:0]          fpu_awake_idx;
logic                           fpu_awake_is_fp;

logic                           alu_awake_vld;
logic[PHY_REG_WTH-1:0]          alu_awake_idx;
logic                           csr_awake_vld;
logic[PHY_REG_WTH-1:0]          csr_awake_idx;
logic                           mdu_awake_vld;
logic[PHY_REG_WTH-1:0]          mdu_awake_idx;
logic                           lsu_awake_vld;
logic[PHY_REG_WTH-1:0]          lsu_awake_idx;
logic                           lsu_awake_is_fp;

logic                           lsu_mmu__req;
logic[63:0]                     lsu_mmu__vaddr;
logic                           lsu_mmu__is_store;
logic                           mmu_lsu__hit;
logic                           mmu_lsu__valid;
logic[63:0]                     mmu_lsu__paddr;
excp_t                          mmu_lsu__ex;
logic                           lsu_dcache__vld;             
logic                           dcache_lsu__rdy;
dcache_req_t                    lsu_dcache__req;
dcache_rsp_t                    dcache_lsu__rsp;
logic                           mmu_dcache__vld;             
logic                           dcache_mmu__rdy;
dcache_req_t                    mmu_dcache__req;
logic                           dcache_mmu__rvld;
logic[DWTH-1:0]                 dcache_mmu__rdata;
csr_bus_req_t                   csr_regfile_req;
csr_bus_rsp_t                   csr_regfile_rsp;
csr_bus_wr_t                    csr_regfile_wr;
logic                           rob_lsu__retire_en;
logic                           rob_csr__retire_en;
alu_commit_t                    alu_rob__commit;
csr_commit_t                    csr_rob__commit;
mdu_commit_t                    mdu_rob__commit;
lsu_commit_t                    lsu_rob__commit;
fpu_commit_t                    fpu_rob__commit;
logic                           lsu_ctrl__sq_retire_empty;

logic                           exu_fpr_wr_en; 
logic[PHY_REG_WTH-1:0]          exu_fpr_wr_idx;
logic[DWTH-1:0]                 exu_fpr_wr_data;
logic                           lsu_fpr_wr_en; 
logic[PHY_REG_WTH-1:0]          lsu_fpr_wr_idx;
logic[DWTH-1:0]                 lsu_fpr_wr_data;


logic[4:0][PHY_REG_WTH-1:0]     gpr_rd_idx;
logic[4:0][DWTH-1:0]            gpr_rd_data;
logic[3:0][PHY_REG_WTH-1:0]     fpr_rd_idx;
logic[3:0][DWTH-1:0]            fpr_rd_data;
priv_lvl_t                      ld_st_priv_lvl;
logic                           en_translation;
logic                           en_ld_st_translation;
logic[43:0]                     satp_ppn;
logic[ASID_WIDTH-1:0]           asid;
logic                           sum;
logic                           mxr;
logic                           rob_csr__write_fflags;
logic[4:0]                      rob_csr__fflags;
logic                           rob_csr__dirty_fp;
icache_mmu_req_t                icache_areq;
mmu_icache_rsp_t                icache_arsp;

logic[6:0]                      csr_fpu__fprec;


//======================================================================================================================
// Instance
//======================================================================================================================

sy_ppl_ctrl u_sy_ppl_ctrl (
    .clk_i                                  (clk_i),                            
    .rst_i                                  (rst_i),                            
    .flush_o                                (flush),  
    .flush_bp_o                             (flush_bp),  

    .boot_addr_i                            (boot_addr_i),                   
    .ctrl_reset_i                           (1'b0),                     
    .stat_sleep_o                           (),                     

    .ppl_tlb_flush_o                        (tlb_flush),
    .ppl_icache_flush_o                     (icache_flush),         
    .ppl_dcache_flush_o                     (dcache_flush),         
    .ppl_dcache_flush_ack_i                 (dcache_flush_ack),         

    .ctrl_fet__set_en_o                     (ctrl_fet__set_en),                 
    .ctrl_fet__set_npc_o                    (ctrl_fet__set_npc),                
    .ctrl_fet__act_o                        (ctrl_fet__act),                    

    .rob_ctrl__fencei_en_i                  (rob_ctrl__fencei_en      ),         
    .rob_ctrl__sfence_vma_i                 (rob_ctrl__sfence_vma     ),          
    .rob_ctrl__uret_i                       (rob_ctrl__uret           ),              
    .rob_ctrl__sret_i                       (rob_ctrl__sret           ),              
    .rob_ctrl__mret_i                       (rob_ctrl__mret           ),              
    .rob_ctrl__need_flush_i                 (rob_ctrl__need_flush     ),                    
    .rob_ctrl__mispred_i                    (rob_ctrl__mispred        ),                 
    .rob_ctrl__wfi_i                        (rob_ctrl__wfi            ),           
    .rob_ctrl__ex_valid_i                   (rob_ctrl__ex_valid       ),                  
    .rob_ctrl__ecode_i                      (rob_ctrl__ecode          ),               
    .rob_ctrl__is_intr_i                    (rob_ctrl__is_intr        ),       
    .rob_ctrl__pc_i                         (rob_ctrl__pc             ),  
    .rob_ctrl__excp_tval_i                  (rob_ctrl__excp_tval      ),         

    .ctrl_csr__trap_o                       (ctrl_csr__trap           ),    
    .ctrl_csr__mret_o                       (ctrl_csr__mret           ),    
    .ctrl_csr__sret_o                       (ctrl_csr__sret           ),    
    .ctrl_csr__dret_o                       (ctrl_csr__dret           ),    
    .csr_ctrl__trap_vec_i                   (csr_ctrl__trap_vec       ),        
    .csr_ctrl__epc_i                        (csr_ctrl__epc            ),   
    .csr_ctrl__wfi_wakeup_i                 (csr_ctrl__wfi_wakeup     ),          
    .lsu_ctrl__st_queen_empty_i             (lsu_ctrl__st_queen_empty )
);

sy_ppl_fronted fronted_inst(
    .clk_i                                  (clk_i),                          
    .rst_i                                  (rst_i),                          
    .flush_i                                (flush),      
    .flush_bp_i                             (flush_bp),      

    .ctrl_fet__set_en_i                     (ctrl_fet__set_en  ),                 
    .ctrl_fet__set_npc_i                    (ctrl_fet__set_npc ),                  
    .ctrl_fet__act_i                        (ctrl_fet__act     ),              
    .fet_icache__dreq_o                     (fet_icache__dreq    ),                 
    .icache_fet__drsp_i                     (icache_fet__drsp    ),                 

    .rob_fet__bht_update_i                  (rob_fet__bht_update),
    .rob_fet__btb_update_i                  (rob_fet__btb_update),

    .fet_dec__vld_o                         (fet_dec__vld        ),             
    .dec_fet__rdy_i                         (dec_fet__rdy        ),             
    .fet_dec__npc_o                         (fet_dec__npc        ),             
    .fet_dec__pc_o                          (fet_dec__pc         ),            
    .fet_dec__instr_o                       (fet_dec__instr      ),               
    .fet_dec__is_compressed_o               (fet_dec__is_compressed),                       
    .fet_dec__excp_o                        (fet_dec__excp       )
);


assign csr_dec__debug_mode = 1'b0;
sy_ppl_dec dec_inst(
    .clk_i                                  (clk_i),                         
    .rst_i                                  (rst_i),                         
    .flush_i                                (flush),     

    .intr_ctrl_i                            (intr_ctrl           ),         
    .csr_dec__priv_lvl_i                    (csr_dec__priv_lvl   ),                 
    .csr_dec__fs_i                          (csr_dec__fs         ),           
    .csr_dec__frm_i                         (csr_dec__frm        ),            
    .csr_dec__tvm_i                         (csr_dec__tvm        ),            
    .csr_dec__tw_i                          (csr_dec__tw         ),           
    .csr_dec__tsr_i                         (csr_dec__tsr        ),             
    .csr_dec__debug_mode_i                  (csr_dec__debug_mode ),                       

    .fet_dec__vld_i                         (fet_dec__vld          ),            
    .dec_fet__rdy_o                         (dec_fet__rdy          ),            
    .fet_dec__npc_i                         (fet_dec__npc          ),            
    .fet_dec__pc_i                          (fet_dec__pc           ),           
    .fet_dec__instr_i                       (fet_dec__instr        ),              
    .fet_dec__is_compressed_i               (fet_dec__is_compressed),                      
    .fet_dec__excp_i                        (fet_dec__excp         ),             

    .rob_update_arat_en_i                   (rob_update_arat_en    ),                      
    .rob_update_fp_reg_i                    (rob_update_fp_reg     ),
    .rob_update_arat_arc_i                  (rob_update_arat_arc   ),                   
    .rob_update_arat_phy_i                  (rob_update_arat_phy   ),                   
    .rob_update_arat_old_phy_i              (rob_update_arat_old_phy),                       

    .dec_dis__vld_o                         (dec_dis__vld ),            
    .dis_dec__rdy_i                         (dis_dec__rdy ),            
    .dec_dis__data_o                        (dec_dis__data)
);

sy_ppl_dis dis_inst(
    .clk_i                                  (clk_i),                          
    .rst_i                                  (rst_i),                          
    .flush_i                                (flush),      

    .dec_dis__vld_i                         (dec_dis__vld ),             
    .dis_dec__rdy_o                         (dis_dec__rdy ),             
    .dec_dis__data_i                        (dec_dis__data),              

    .dis_exu__vld_o                         (dis_exu__vld   ),             
    .exu_dis__rdy_i                         (exu_dis__rdy   ),             
    .dis_exu__packet_o                      (dis_exu__packet),                    

    .dis_csr__vld_o                         (dis_csr__vld   ),             
    .csr_dis__rdy_i                         (csr_dis__rdy   ),             
    .dis_csr__packet_o                      (dis_csr__packet),                    

    .dis_lsu__vld_o                         (dis_lsu__vld   ),             
    .lsu_dis__rdy_i                         (lsu_dis__rdy   ),             
    .dis_lsu__packet_o                      (dis_lsu__packet),  

    // .dis_fpu__vld_o                         (dis_fpu__vld   ),             
    // .fpu_dis__rdy_i                         (fpu_dis__rdy   ),             
    // .dis_fpu__packet_o                      (dis_fpu__packet),                    
    .dis_rob__vld_o                         (dis_rob__vld   ),             
    .rob_dis__rdy_i                         (rob_dis__rdy   ),             
    .dis_rob__packet_o                      (dis_rob__packet),                    
    .rob_dis_idx_i                          (rob_dis_idx    ),            

    .alu_update_en_i                        (alu_awake_vld),              
    .alu_update_idx_i                       (alu_awake_idx),               
    .csr_update_en_i                        (csr_awake_vld),              
    .csr_update_idx_i                       (csr_awake_idx),               
    .lsu_update_en_i                        (lsu_awake_vld),              
    .lsu_update_is_fp_i                     (lsu_awake_is_fp),                 
    .lsu_update_idx_i                       (lsu_awake_idx),               
    .mdu_update_en_i                        (mdu_awake_vld),              
    .mdu_update_idx_i                       (mdu_awake_idx),               
    .fpu_update_en_i                        (fpu_awake_vld),              
    .fpu_update_is_fp_i                     (fpu_awake_is_fp),                 
    .fpu_update_idx_i                       (fpu_awake_idx)
);

sy_ppl_lsu lsu_inst(
    .clk_i                                  (clk_i),                                      
    .rst_i                                  (rst_i),                                      
    .flush_i                                (flush),                  

    .dis_lsu__vld_i                         (dis_lsu__vld   ),                            
    .lsu_dis__rdy_o                         (lsu_dis__rdy   ),                                    
    .dis_lsu__packet_i                      (dis_lsu__packet),                            

    .lsu_mmu__req_o                         (lsu_mmu__req      ),                         
    .lsu_mmu__vaddr_o                       (lsu_mmu__vaddr    ),                           
    .lsu_mmu__is_store_o                    (lsu_mmu__is_store ),                              
    .mmu_lsu__hit_i                         (mmu_lsu__dtlb_hit ),                         
    .mmu_lsu__valid_i                       (mmu_lsu__valid    ),                           
    .mmu_lsu__paddr_i                       (mmu_lsu__paddr    ),                           
    .mmu_lsu__ex_i                          (mmu_lsu__ex       ),                        

    .lsu_dcache__vld_o                      (lsu_dcache__vld),
    .dcache_lsu__rdy_i                      (dcache_lsu__rdy),
    .lsu_dcache__req_o                      (lsu_dcache__req),                                
    .dcache_lsu__rsp_i                      (dcache_lsu__rsp),                              

    .gpr_rs1_idx_o                          (gpr_rd_idx[3]),                        
    .gpr_rs2_idx_o                          (gpr_rd_idx[4]),                        
    .gpr_rs1_data_i                         (gpr_rd_data[3]),                         
    .gpr_rs2_data_i                         (gpr_rd_data[4]),                         

    .fpr_rs2_idx_o                          (fpr_rd_idx[3]),                        
    .fpr_rs2_data_i                         (fpr_rd_data[3]),                         

    .gpr_wr_we_o                            (lsu_gpr_wr_en  ),                      
    .gpr_wr_idx_o                           (lsu_gpr_wr_idx ),                       
    .gpr_wr_data_o                          (lsu_gpr_wr_data),                        

    .fpr_wr_we_o                            (lsu_fpr_wr_en),                      
    .fpr_wr_idx_o                           (lsu_fpr_wr_idx),                       
    .fpr_wr_data_o                          (lsu_fpr_wr_data),                        

    .lsu_awake_vld_o                        (lsu_awake_vld  ),                          
    .lsu_awake_idx_o                        (lsu_awake_idx  ),                          
    .lsu_awake_is_fp_o                      (lsu_awake_is_fp),                                

    .alu_awake_vld_i                        (alu_awake_vld),                          
    .alu_awake_idx_i                        (alu_awake_idx),                          
    .csr_awake_vld_i                        (csr_awake_vld),                          
    .csr_awake_idx_i                        (csr_awake_idx),                          
    .mdu_awake_vld_i                        (mdu_awake_vld),                          
    .mdu_awake_idx_i                        (mdu_awake_idx),                          

    .fpu_awake_vld_i                        (fpu_awake_vld     ),                          
    .fpu_awake_idx_i                        (fpu_awake_idx     ),                          
    .fpu_awake_is_fp_i                      (fpu_awake_is_fp   ),                            

    .lsu_rob__commit_o                      (lsu_rob__commit),                            
    .rob_lsu__retire_en_i                   (rob_lsu__retire_en),                               
    .lsu_ctrl__sq_retire_empty_o            (lsu_ctrl__st_queen_empty)
);


sy_ppl_exu exu_inst(
    .clk_i                                  (clk_i),                       
    .rst_i                                  (rst_i),                       
    .flush_i                                (flush),   

    .dis_exu__vld_i                         (dis_exu__vld   ),                    
    .exu_dis__rdy_o                         (exu_dis__rdy   ),                    
    .dis_exu__packet_i                      (dis_exu__packet),             

    .csr_fpu__frm_i                         (csr_dec__frm),
    .csr_fpu__prec_i                        (csr_fpu__fprec),

    .gpr_rs1_idx_o                          (gpr_rd_idx[0]),         
    .gpr_rs2_idx_o                          (gpr_rd_idx[1]),         
    .gpr_rs1_data_i                         (gpr_rd_data[0]),          
    .gpr_rs2_data_i                         (gpr_rd_data[1]),          

    .gpr_wr_en_o                            (exu_gpr_wr_en  ),       
    .gpr_wr_idx_o                           (exu_gpr_wr_idx ),        
    .gpr_wr_data_o                          (exu_gpr_wr_data),         

    .fpr_rs1_idx_o                          (fpr_rd_idx [0]), 
    .fpr_rs1_data_i                         (fpr_rd_data[0]),                 
    .fpr_rs2_idx_o                          (fpr_rd_idx [1]), 
    .fpr_rs2_data_i                         (fpr_rd_data[1]),                 
    .fpr_rs3_idx_o                          (fpr_rd_idx [2]),                
    .fpr_rs3_data_i                         (fpr_rd_data[2]),         

    .fpr_wr_en_o                            (exu_fpr_wr_en  ),                  
    .fpr_wr_idx_o                           (exu_fpr_wr_idx ),               
    .fpr_wr_data_o                          (exu_fpr_wr_data),         

    .fpu_awake_vld_o                        (fpu_awake_vld ),           
    .fpu_awake_idx_o                        (fpu_awake_idx ),           
    .fpu_awake_is_fp_o                      (fpu_awake_is_fp),             
    .alu_awake_vld_o                        (alu_awake_vld  ),           
    .alu_awake_idx_o                        (alu_awake_idx  ),           
    .mdu_awake_vld_o                        (mdu_awake_vld  ),           
    .mdu_awake_idx_o                        (mdu_awake_idx  ),           
    .csr_awake_vld_i                        (csr_awake_vld  ),           
    .csr_awake_idx_i                        (csr_awake_idx  ),           
    .lsu_awake_is_fp_i                      (lsu_awake_is_fp),             
    .lsu_awake_vld_i                        (lsu_awake_vld  ),           
    .lsu_awake_idx_i                        (lsu_awake_idx  ),           

    .alu_rob__commit_o                      (alu_rob__commit          ),             
    .fpu_rob__commit_o                      (fpu_rob__commit          ),
    .mdu_rob__commit_o                      (mdu_rob__commit          )             
);

sy_ppl_csr csr_inst(
    .clk_i                                  (clk_i),                        
    .rst_i                                  (rst_i),                        
    .flush_i                                (flush),    

    .dis_csr__vld_i                         (dis_csr__vld    ),                     
    .csr_dis__rdy_o                         (csr_dis__rdy    ),                     
    .dis_csr__packet_i                      (dis_csr__packet ),              

    .gpr_rs1_idx_o                          (gpr_rd_idx[2]),          
    .gpr_rs1_data_i                         (gpr_rd_data[2]),           

    .gpr_wr_en_o                            (csr_gpr_wr_en  ),        
    .gpr_wr_idx_o                           (csr_gpr_wr_idx ),         
    .gpr_wr_data_o                          (csr_gpr_wr_data),          

    .lsu_awake_vld_i                        (lsu_awake_vld),            
    .lsu_awake_idx_i                        (lsu_awake_idx  ),            
    .lsu_awake_is_fp_i                      (lsu_awake_is_fp  ),              
    .alu_awake_vld_i                        (alu_awake_vld),            
    .alu_awake_idx_i                        (alu_awake_idx),            
    .mdu_awake_vld_i                        (mdu_awake_vld),            
    .mdu_awake_idx_i                        (mdu_awake_idx),            
    .fpu_awake_vld_i                        (fpu_awake_vld   ),            
    .fpu_awake_idx_i                        (fpu_awake_idx   ),            
    .fpu_awake_is_fp_i                      (fpu_awake_is_fp ),              

    .csr_awake_vld_o                        (csr_awake_vld),            
    .csr_awake_idx_o                        (csr_awake_idx),            

    .csr_regfile_req_o                      (csr_regfile_req),              
    .csr_regfile_wr_o                       (csr_regfile_wr ),             
    .csr_regfile_rsp_i                      (csr_regfile_rsp),              

    .rob_csr__retire_i                      (rob_csr__retire_en),              
    .csr_rob__commit_o                      (csr_rob__commit)
);


sy_ppl_rob rob_inst(
    .clk_i                                  (clk_i),                          
    .rst_i                                  (rst_i),                          
    .flush_i                                (flush),

    .dis_rob__vld_i                         (dis_rob__vld),             
    .rob_dis__rdy_o                         (rob_dis__rdy),             
    .dis_rob__packet_i                      (dis_rob__packet),                
    .rob_dis__idx_o                         (rob_dis_idx),             

    .alu_rob__commit_i                      (alu_rob__commit),               
    .csr_rob__commit_i                      (csr_rob__commit),               
    .lsu_rob__commit_i                      (lsu_rob__commit),               
    .mdu_rob__commit_i                      (mdu_rob__commit),                   
    .fpu_rob__commit_i                      (fpu_rob__commit),                   

    .rob_ctrl__fencei_o                     (rob_ctrl__fencei_en  ),                 
    .rob_ctrl__sfence_vma_o                 (rob_ctrl__sfence_vma ),                     
    .rob_ctrl__uret_o                       (rob_ctrl__uret       ),               
    .rob_ctrl__sret_o                       (rob_ctrl__sret       ),               
    .rob_ctrl__mret_o                       (rob_ctrl__mret       ),               
    .rob_ctrl__ex_valid_o                   (rob_ctrl__ex_valid   ),                   
    .rob_ctrl__need_flush_o                 (rob_ctrl__need_flush ),                     
    .rob_ctrl__mispred_o                    (rob_ctrl__mispred    ),                  
    .rob_ctrl__wfi_o                        (rob_ctrl__wfi        ),                
    .rob_ctrl__ecode_o                      (rob_ctrl__ecode      ),                
    .rob_ctrl__is_intr_o                    (rob_ctrl__is_intr    ),                  
    .rob_ctrl__pc_o                         (rob_ctrl__pc         ),             
    .rob_ctrl__excp_tval_o                  (rob_ctrl__excp_tval  ),                    

    .rob_update_arat_en_o                   (rob_update_arat_en     ),                   
    .rob_update_fp_reg_o                    (rob_update_fp_reg      ),
    .rob_update_arat_arc_idx_o              (rob_update_arat_arc    ),                        
    .rob_update_arat_phy_idx_o              (rob_update_arat_phy    ),                        
    .rob_update_arat_old_phy_idx_o          (rob_update_arat_old_phy),                            

    .rob_lsu__retire_en_o                   (rob_lsu__retire_en ),                             
    .rob_csr__retire_en_o                   (rob_csr__retire_en ),                             
    .rob_csr__write_fflags_o                (rob_csr__write_fflags),                      
    .rob_csr__fflags_o                      (rob_csr__fflags      ),                
    .rob_csr__dirty_fp_o                    (rob_csr__dirty_fp    ),

    .rob_fet__bht_update_o                  (rob_fet__bht_update),
    .rob_fet__btb_update_o                  (rob_fet__btb_update)
);

sy_ppl_gpr_file gpr_file_inst(
    .clk_i                                  (clk_i),                               
    .rst_i                                  (rst_i),                               

    .gpr_rd_idx_i                           (gpr_rd_idx),                
    .gpr_rd_data_o                          (gpr_rd_data),                 

    .alu_reg__rdst_en_i                     (exu_gpr_wr_en[0]   ),                      
    .alu_reg__rdst_idx_i                    (exu_gpr_wr_idx[0]  ),                       
    .alu_reg__rdst_data_i                   (exu_gpr_wr_data[0] ),                        

    .csr_reg__rdst_en_i                     (csr_gpr_wr_en   ),                      
    .csr_reg__rdst_idx_i                    (csr_gpr_wr_idx  ),                       
    .csr_reg__rdst_data_i                   (csr_gpr_wr_data ),                        

    .lsu_reg__rdst_en_i                     (lsu_gpr_wr_en  ),                      
    .lsu_reg__rdst_idx_i                    (lsu_gpr_wr_idx ),                       
    .lsu_reg__rdst_data_i                   (lsu_gpr_wr_data),                        

    .mdu_reg__rdst_en_i                     (exu_gpr_wr_en[1]  ),                      
    .mdu_reg__rdst_idx_i                    (exu_gpr_wr_idx[1] ),                       
    .mdu_reg__rdst_data_i                   (exu_gpr_wr_data[1]),                        

    .fpu_reg__rdst_en_i                     (exu_gpr_wr_en[2]     ),                      
    .fpu_reg__rdst_idx_i                    (exu_gpr_wr_idx[2]    ),                       
    .fpu_reg__rdst_data_i                   (exu_gpr_wr_data[2]   )

);

sy_ppl_fpr_file fpr_file_inst(
    .clk_i                                  (clk_i),                         
    .rst_i                                  (rst_i),                         

    .fpr_rd_idx_i                           (fpr_rd_idx ),          
    .fpr_rd_data_o                          (fpr_rd_data),           

    .lsu_reg__rdst_en_i                     (lsu_fpr_wr_en  ),                
    .lsu_reg__rdst_idx_i                    (lsu_fpr_wr_idx ),                 
    .lsu_reg__rdst_data_i                   (lsu_fpr_wr_data),                  

    .fpu_reg__rdst_en_i                     (exu_fpr_wr_en  ),                
    .fpu_reg__rdst_idx_i                    (exu_fpr_wr_idx ),                 
    .fpu_reg__rdst_data_i                   (exu_fpr_wr_data)
);

sy_ppl_csr_regfile #(
    .HART_ID_WTH (HART_ID_WTH)
) u_sy_ppl_csr_regfile (
    .clk_i                                  (clk_i                  ),                             
    .rst_i                                  (rst_i                  ),                             
    .flush_i                                (flush                  ),
                                             
    .boot_addr_i                            (boot_addr_i            ),             
    .hart_id_i                              (HART_ID[HART_ID_WTH-1:0]),
                                             
    .irq_i                                  (irq_i                  ),      
    .ipi_i                                  (ipi_i                  ),     
    .timer_irq_i                            (time_irq_i             ),             

    .priv_lvl_o                             (csr_dec__priv_lvl      ),          
    .fs_o                                   (csr_dec__fs            ),    
    .frm_o                                  (csr_dec__frm           ),     
    .tvm_o                                  (csr_dec__tvm           ),          
    .tw_o                                   (csr_dec__tw            ),          
    .tsr_o                                  (csr_dec__tsr           ),          

    .fflags_o                               (),        
    .fprec_o                                (csr_fpu__fprec         ),       

    .icache_en_o                            (),             
    .dcache_en_o                            (),             

    .ld_st_priv_lvl_o                       (ld_st_priv_lvl         ),                
    .en_translation_o                       (en_translation         ),                
    .en_ld_st_translation_o                 (en_ld_st_translation   ),                      
    .satp_ppn_o                             (satp_ppn               ),          
    .asid_o                                 (asid                   ),      
    .sum_o                                  (sum                    ),     
    .mxr_o                                  (mxr                    ),     

    .rob_csr__write_fflags_i                (rob_csr__write_fflags  ),                       
    .rob_csr__fflags_i                      (rob_csr__fflags        ),                 
    .rob_csr__dirty_fp_i                    (rob_csr__dirty_fp      ),                   

    .ctrl_csr__trap_i                       (ctrl_csr__trap         ),                
    .ctrl_csr__mret_i                       (ctrl_csr__mret         ),                
    .ctrl_csr__sret_i                       (ctrl_csr__sret         ),                
    .ctrl_csr__dret_i                       (ctrl_csr__dret         ),                

    .csr_ctrl__trap_vec_o                   (csr_ctrl__trap_vec     ),                    
    .csr_ctrl__epc_o                        (csr_ctrl__epc          ),               
    .csr_ctrl__intr_o                       (intr_ctrl),                
    .csr_ctrl__wfi_wakeup_o                 (csr_ctrl__wfi_wakeup   ),                      

    .lsu_csr__bus_req_i                     (csr_regfile_req           ),                  
    .lsu_csr__bus_wr_i                      (csr_regfile_wr            ),
    .csr_lsu__bus_rsp_o                     (csr_regfile_rsp           ) 
);


cva6_mmu #(
    .INSTR_TLB_ENTRIES      ( 16  ),
    .DATA_TLB_ENTRIES       ( 16  ) 
)mmu(
    .clk_i                                  (clk_i                  ), 
    .rst_ni                                 (rst_i                  ), 
    .flush_i                                (flush                  ),  
    .enable_translation_i                   (en_translation         ),               
    .en_ld_st_translation_i                 (en_ld_st_translation   ), // enable virtual memory translation for load/stores
                                             
    .icache_areq_i                          (icache_areq            ),        
    .icache_areq_o                          (icache_arsp            ),        
                                             
    .misaligned_ex_i                        ('0                     ),          
    .lsu_req_i                              (lsu_mmu__req           ), // request address translation
    .lsu_vaddr_i                            (lsu_mmu__vaddr         ), // virtual address in
    .lsu_is_store_i                         (lsu_mmu__is_store      ), // the translation is requested by a store
    .lsu_dtlb_hit_o                         (mmu_lsu__dtlb_hit      ), // sent in the same cycle as the request if translation hits in the DTLB
    .lsu_valid_o                            (mmu_lsu__valid         ), // translation is valid
    .lsu_paddr_o                            (mmu_lsu__paddr         ), // translated address
    .lsu_exception_o                        (mmu_lsu__ex            ), // address translation threw an exception
    .priv_lvl_i                             (csr_dec__priv_lvl      ),     
    .ld_st_priv_lvl_i                       (ld_st_priv_lvl         ),           
    .sum_i                                  (sum                    ),
    .mxr_i                                  (mxr                    ),
                                             
    .satp_ppn_i                             (satp_ppn               ),     
    .asid_i                                 (asid                   ), 
    .flush_tlb_i                            (tlb_flush              ),      
                                             
    .itlb_miss_o                            (                       ),      
    .dtlb_miss_o                            (                       ),      
                                             
    .mmu_dcache__vld_o                      (mmu_dcache__vld   ),  
    .dcache_mmu__rdy_i                      (dcache_mmu__rdy   ),        
    .mmu_dcache__data_o                     (mmu_dcache__req   ),   
    .dcache_mmu__rvld_i                     (dcache_mmu__rvld  ),     
    .dcache_mmu__rdata_i                    (dcache_mmu__rdata )   
);

sy_L1_cache  #(
    .HART_ID_WTH        (HART_ID_WTH),
    .HART_ID            (HART_ID),
    .ADDR_WTH           (AWTH),
    .REQ_PORT           (2)            
) L1_cache(
    .clk_i                                  (clk_i              ),      
    .rst_i                                  (rst_i              ),      
    .flush_ppl_i                            (flush              ),              
    .flush_icache_i                         (icache_flush       ),                 
    .flush_icache_done_o                    (icache_flush_done  ),                    
    .flush_dcache_i                         (dcache_flush       ),                 
    .flush_dcache_done_o                    (dcache_flush_ack   ),                    
    .icache_miss_o                          (),                             
    // .dcache_miss_o                          (),                             
    .icache_mmu__req_o                      (icache_areq        ),                  
    .mmu_icache__rsp_i                      (icache_arsp        ),                  
    .fetch_icache__req_i                    (fet_icache__dreq   ),                                         
    .icache_fetch__rsp_o                    (icache_fet__drsp   ),                    

    .mmu_dcache__vld_i                      (mmu_dcache__vld   ),  
    .dcache_mmu__rdy_o                      (dcache_mmu__rdy   ),        
    .mmu_dcache__data_i                     (mmu_dcache__req   ),   
    .dcache_mmu__rvld_o                     (dcache_mmu__rvld  ),     
    .dcache_mmu__rdata_o                    (dcache_mmu__rdata ),    

    .lsu_dcache__vld_i                      (lsu_dcache__vld),  
    .dcache_lsu__rdy_o                      (dcache_lsu__rdy),  
    .lsu_dcache__data_i                     (lsu_dcache__req),   
    .dcache_lsu__data_o                     (dcache_lsu__rsp),   


    .slave                                  (master             )
);

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule : sy_core
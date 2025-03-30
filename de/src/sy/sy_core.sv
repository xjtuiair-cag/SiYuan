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

// ctrl
logic                           ctrl_x__if0_kill;
logic                           ctrl_x__id0_kill;
logic                           ctrl_x__ex0_kill;
logic                           ctrl_x__mem_kill;
logic                           ctrl_x__wb_kill;
logic                           ctrl_fet__set_en;
logic[AWTH-1:0]                 ctrl_fet__set_npc;
logic                           ctrl_fet__act;
logic[DWTH-1:0]                 ctrl_alu__csr_rdata;
// fet
logic                           fet_ctrl__if0_act;
logic                           fet_ctrl__id0_act;
logic                           fet_dec__id0_avail;
logic                           fet_dec__id0_act;
logic[AWTH-1:0]                 fet_dec__id0_npc;
logic[AWTH-1:0]                 fet_dec__id0_pc;
logic[IWTH-1:0]                 fet_dec__id0_instr;
logic                           fet_dec__id0_is_compressed;

logic                           fet_dec__id0_excp_en;
ecode_e                         fet_dec__id0_excp_ecode;
// dec
logic                           dec_fet__ex0_accpt;
logic                           dec_ctrl__ex0_act;
logic                           dec_ctrl__ex0_avail;
logic                           dec_fet__raw_hazard;
logic[4:0]                      dec_reg__rs1_idx;
logic[4:0]                      dec_reg__rs2_idx;
logic                           dec_alu__ex0_avail;
instr_cls_e                     dec_alu__instr_cls;
logic[1:0]                      dec_alu__stage_act;
logic[AWTH-1:0]                 dec_alu__npc;
logic[AWTH-1:0]                 dec_alu__pc;
logic[IWTH-1:0]                 dec_alu__instr;
als_opcode_e                    dec_alu__als_opcode;
jbr_opcode_e                    dec_alu__jbr_opcode;
mem_opcode_e                    dec_alu__mem_opcode;
amo_t                           dec_alu__amo_opcode;
sys_opcode_e                    dec_alu__sys_opcode;
logic                           dec_alu__sign_ext;
lrsc_cmd_e                      dec_alu__lrsc_cmd;
logic                           dec_alu__rls;
logic                           dec_alu__acq;
csr_cmd_e                       dec_alu__csr_cmd;
logic[11:0]                     dec_alu__csr_addr;
logic                           dec_alu__csr_imm_sel;
logic[4:0]                      dec_alu__rs1_idx;
logic[DWTH-1:0]                 dec_alu__rs1_data;
logic[4:0]                      dec_alu__rs2_idx;
logic[DWTH-1:0]                 dec_alu__rs2_data;
logic                           dec_alu__rdst_en;
rdst_src_e                      dec_alu__rdst_src_sel;
logic[4:0]                      dec_alu__rdst_idx;
logic[DWTH-1:0]                 dec_alu__jbr_base;
logic[DWTH-1:0]                 dec_alu__st_data;
logic[AWTH-1:0]                 dec_alu__imm;
size_e                          dec_alu__size;
logic                           dec_alu__excp_en;
ecode_e                         dec_alu__excp_ecode;
logic                           dec_mdu__ex0_avail;
logic[AWTH-1:0]                 dec_mdu__pc;
mdu_opcode_e                    dec_mdu__mdu_opcode;
logic                           dec_mdu__rs1_sign;
logic                           dec_mdu__rs2_sign;
logic[DWTH-1:0]                 dec_mdu__rs1_data;
logic[DWTH-1:0]                 dec_mdu__rs2_data;
logic[4:0]                      dec_mdu__rdst_idx;
logic                           dec_mdu__only_word;
// reg
logic[DWTH-1:0]                 reg_dec__rs1_reg;
logic[DWTH-1:0]                 reg_dec__rs2_reg;
// alu
logic                           alu_dec__mem_accpt;
logic                           alu_x__mispred_en;
logic[AWTH-1:0]                 alu_x__mispred_pc;
logic[AWTH-1:0]                 alu_x__mispred_npc;
logic[DWTH-1:0]                 alu_ctrl__ex0_npc;
logic[AWTH-1:0]                 alu_ctrl__ex0_ls_addr;
logic[DWTH-1:0]                 alu_ctrl__ex0_pc;
logic[IWTH-1:0]                 alu_ctrl__ex0_instr;
logic[DWTH-1:0]                 alu_ctrl__mem_pc;
logic[AWTH-1:0]                 alu_ctrl__mem_ls_addr;
logic                           alu_csr__wfi_en;
logic                           alu_ctrl__fencei_en;
logic                           alu_ctrl__fence_en;
logic                           alu_ctrl__mem_act;
logic                           alu_ctrl__wb_act;
logic                           alu_dec__mem_blk_en;
logic[4:0]                      alu_dec__mem_blk_idx;
logic                           alu_dec__mem_blk_f_or_x;
bp_bus_t                        alu_dec__bp0_rdst;
bp_bus_t                        alu_dec__bp1_rdst;
logic                           alu_dec__bp0_f_or_x;
logic                           alu_dec__bp1_f_or_x;
logic                           alu_reg__rdst_en;
logic[4:0]                      alu_reg__rdst_idx;
logic[DWTH-1:0]                 alu_reg__rdst_data;
// mdu
logic                           mdu_ctrl__mul_act;
logic                           mdu_ctrl__div_act;
logic[MUL_STAGE-1:0]            mdu_dec__blk_en_mul;
logic[MUL_STAGE-1:0][4:0]       mdu_dec__blk_idx_mul;
logic                           mdu_dec__blk_en_div;
logic[4:0]                      mdu_dec__blk_idx_div;
logic                           mdu_alu__mul_wb_busy;
logic                           mdu_alu__div_wb_busy;
logic                           mdu_reg__rdst_en;
logic[4:0]                      mdu_reg__rdst_idx;
logic[DWTH-1:0]                 mdu_reg__rdst_data;

logic                           icache_flush;
logic                           icache_flush_done;
logic                           dcache_flush;
logic                           dcache_flush_ack;
logic                           tlb_flush;
logic                           alu_ctrl__sfence_vma;
logic[63:0]                     alu_ctrl__wb_npc;
logic                           csr_ctrl__eret          ; 
logic[63:0]                     csr_ctrl__epc           ;     
logic[63:0]                     csr_ctrl__trap_vec      ; 
logic                           csr_ctrl__wfi_wakeup    ;     
logic                           csr_ctrl__set_debug     ; 
logic                           csr_ctrl__ex_valid      ; 
logic                           csr_ctrl__debug_mode    ;     
logic                           csr_ctrl__flush         ; 
exception_t                     fet_dec__id0_exception  ;
fetch_req_t                     fet_icache__dreq        ;
fetch_rsp_t                     icache_fet__drsp        ;


priv_lvl_t                      priv_lvl; 
xs_t                            fs            ; 
logic[2:0]                      frm           ; 
logic[6:0]                      fprec;
irq_ctrl_t                      csr_dec__irq_ctrl       ;

logic[4:0]                      dec_fp_reg__rs1_idx     ;
logic[FLEN-1:0]                 fp_reg_dec__rs1_reg     ;
logic[4:0]                      dec_fp_reg__rs2_idx     ;
logic[FLEN-1:0]                 fp_reg_dec__rs2_reg     ;
logic[4:0]                      dec_fp_reg__rs3_idx     ;
logic[FLEN-1:0]                 fp_reg_dec__rs3_reg     ;

logic                           dec_alu__fp_rdst_en     ;
logic[4:0]                      dec_alu__fp_rdst_idx    ;
logic[FLEN-1:0]                 dec_alu__fp_result      ;
logic[4:0]                      dec_alu__fp_status      ;
exception_t                     dec_alu__exception      ; 
logic                           dec_alu__only_word      ;                            
logic                           dec_alu__is_compressed  ;

logic                           dec_fpu__valid          ;    
fpu_opcode_t                    dec_fpu__opcode         ; 
logic                           fpu_dec__ready          ;    
logic[FLEN-1:0]                 dec_fpu__rs1_data       ;       
logic[FLEN-1:0]                 dec_fpu__rs2_data       ;       
logic[FLEN-1:0]                 dec_fpu__rs3_data       ;       
logic[1:0]                      dec_fpu__fmt            ;  
logic[2:0]                      dec_fpu__rm             ; 
logic[FLEN-1:0]                 fpu_dec__result         ;     
logic[4:0]                      fpu_dec__status         ;
logic                           fpu_dec__valid          ;    

logic                           alu_csr__valid          ;   
lb_cmd_e                        alu_csr__cmd            ; 
logic[DWTH-1:0]                 alu_csr__wdata          ;   
logic[11:0]                     alu_csr__addr           ;  
logic[DWTH-1:0]                 csr_alu__rdata          ;   
exception_t                     alu_csr__ex             ;   
logic[AWTH-1:0]                 alu_csr__pc             ; 
logic[AWTH-1:0]                 alu_csr__npc            ; 
logic[31:0]                     alu_csr__instr          ;   
logic                           alu_csr__write_fflags   ;    
logic                           alu_csr__dirty_fp_state ;   
logic[4:0]                      alu_csr__fflags         ;   


logic                           alu_csr__mret           ;  
logic                           alu_csr__sret           ;  
logic                           alu_csr__dret           ;  

logic                           alu_fp_reg__rdst_en     ;
logic[4:0]                      alu_fp_reg__rdst_idx    ;
logic[DWTH-1:0]                 alu_fp_reg__rdst_data   ;

logic                           ppl_dmem__vld           ;     
logic[AWTH-1:0]                 ppl_dmem__addr          ;      
logic[DWTH-1:0]                 ppl_dmem__wdata         ;       
size_e                          ppl_dmem__size          ;      
mem_opcode_e                    ppl_dmem__opcode        ;        
logic[DWTH-1:0]                 ppl_dmem__operand       ;         
amo_t                           ppl_dmem__amo_opcode    ;            
logic                           ppl_dmem__kill          ;      
logic                           dmem_ppl__hit           ;     
logic[DWTH-1:0]                 dmem_ppl__rdata         ;       
exception_t                     dmem_ppl__exception     ; 

logic                            en_translation         ;                             
logic                            en_ld_st_translation   ;                             
priv_lvl_t                       ld_st_priv_lvl         ;                             // Privilege level at which load and stores should happen
logic                            sum                    ;       
logic                            mxr                    ;       
logic [43:0]                     satp_ppn               ;            
logic                            asid                   ;        
logic                            tvm                    ;                             // trap virtual memory
logic                            tw                     ;                             // timeout wait
logic                            tsr                    ;                             // trap sret
logic                            debug_mode             ;                             // we are in debug mode -> that will change some decoding
logic                            icache_en              ;                             // L1 ICache Enable
logic                            dcache_en              ;                             // L1 DCache Enable
logic  [4:0]                     perf_addr              ;                             // read/write address to performance counter module (up to 29 aux counters possible in riscv encoding.h)
logic  [63:0]                    perf_data              ;                             // read data from performance counter module
logic                            perf_we                ; 

logic                            lsu_mmu__req           ;   
logic[63:0]                      lsu_mmu__vaddr         ;     
logic                            lsu_mmu__is_store      ;        
logic                            mmu_lsu__dtlb_hit      ;        
logic                            mmu_lsu__valid         ;     
logic[63:0]                      mmu_lsu__paddr         ;     
exception_t                      mmu_lsu__ex            ;  

dcache_req_t [1:0]             dcache_req;
dcache_rsp_t [1:0]             dcache_rsp;

amo_req_t                           amo_req;
amo_resp_t                          amo_resp; 

icache_mmu_req_t                    icache_areq;
mmu_icache_rsp_t                    icache_arsp;

logic                               halt;
//======================================================================================================================
// Instance
//======================================================================================================================

sy_ppl_ctrl u_sy_ppl_ctrl (
    // =====================================
    // [clock & reset]
    .clk_i                                  (clk_i),                            
    .rst_i                                  (rst_i),                            
    // =====================================
    // [ctrl & status]
    .boot_addr_i                            (boot_addr_i),                   
    .ctrl_reset_i                           (1'b0),                     
    .ctrl_halt_i                            (1'b0),                     
    .stat_sleep_o                           (),                     
    // =====================================
    // [to IMEM]
    .ppl_icache_flush_o                     (icache_flush),         
    .ppl_dcache_flush_o                     (dcache_flush),         
    .ppl_dcache_flush_ack_i                 (dcache_flush_ack),         
    .ppl_tlb_flush_o                        (tlb_flush),
    // =====================================
    // [block signals]
    .ctrl_x__if0_kill_o                     (ctrl_x__if0_kill),                 
    .ctrl_x__id0_kill_o                     (ctrl_x__id0_kill),                 
    .ctrl_x__ex0_kill_o                     (ctrl_x__ex0_kill),                 
    .ctrl_x__mem_kill_o                     (ctrl_x__mem_kill),                 
    .ctrl_x__wb_kill_o                      (ctrl_x__wb_kill),
    // =====================================
    // [to ppl_fet]
    .ctrl_fet__set_en_o                     (ctrl_fet__set_en),                 
    .ctrl_fet__set_npc_o                    (ctrl_fet__set_npc),                
    .ctrl_fet__act_o                        (ctrl_fet__act),                    
    .fet_ctrl__if0_act_i                    (fet_ctrl__if0_act),                
    .fet_ctrl__id0_act_i                    (fet_ctrl__id0_act),                
    .dec_ctrl__ex0_act_i                    (dec_ctrl__ex0_act),                
    .alu_ctrl__mem_act_i                    (alu_ctrl__mem_act),                
    .alu_ctrl__wb_act_i                     (alu_ctrl__wb_act),                 
    // =====================================
    // [to ppl_alu]
    // .alu_ctrl__wfi_en_i                     (alu_ctrl__wfi_en),              
    .alu_ctrl__fencei_en_i                  (alu_ctrl__fencei_en),              
    .alu_ctrl__fence_en_i                   (alu_ctrl__fence_en),             
    .alu_ctrl__sfence_vma_i                 (alu_ctrl__sfence_vma),             
    .alu_ctrl__wb_npc_i                     (alu_ctrl__wb_npc),
    // =====================================
    // [to ppl_mdu]
    .mdu_ctrl__mul_act_i                    (mdu_ctrl__mul_act),                
    .mdu_ctrl__div_act_i                    (mdu_ctrl__div_act),                
    // =====================================
    // [from csr regfile]
    .csr_ctrl__eret_i                       (csr_ctrl__eret),
    .csr_ctrl__epc_i                        (csr_ctrl__epc),
    .csr_ctrl__trap_vec_i                   (csr_ctrl__trap_vec),
    // .csr_ctrl__wfi_wakeup_i                 (csr_ctrl__wfi_wakeup),
    .csr_ctrl__set_debug_i                  (csr_ctrl__set_debug),
    .csr_ctrl__ex_valid_i                   (csr_ctrl__ex_valid),
    .csr_ctrl__debug_mode_i                 (csr_ctrl__debug_mode),
    .csr_ctrl__flush_i                      (csr_ctrl__flush)
);

sy_ppl_fet u_sy_ppl_fet (
    // =====================================
    // [clock & reset]
    .clk_i                                  (clk_i),                            
    .rst_i                                  (rst_i),                            

    .halt_i                                 (halt),
    // =====================================
    // [block signals]
    .dec_fet__ex0_accpt_i                   (dec_fet__ex0_accpt),               
    .alu_x__mispred_en_i                    (alu_x__mispred_en),                
    .alu_x__mispred_pc_i                    (alu_x__mispred_pc),                
    .alu_x__mispred_npc_i                   (alu_x__mispred_npc),               
    .ctrl_x__if0_kill_i                     (ctrl_x__if0_kill),                 
    .ctrl_x__id0_kill_i                     (ctrl_x__id0_kill),                 
    // =====================================
    // [to ppl_ctrl]
    .ctrl_fet__set_en_i                     (ctrl_fet__set_en),                 
    .ctrl_fet__set_npc_i                    (ctrl_fet__set_npc),                
    .ctrl_fet__act_i                        (ctrl_fet__act),                    
    .fet_ctrl__if0_act_o                    (fet_ctrl__if0_act),                
    .fet_ctrl__id0_act_o                    (fet_ctrl__id0_act),                
    // =====================================
    // [to ICACHE]
    .fet_icache__dreq_o                     (fet_icache__dreq),
    .icache_fet__drsp_i                     (icache_fet__drsp),
    // =====================================
    // [to ppl_dec]
    .fet_dec__id0_avail_o                   (fet_dec__id0_avail),               
    .fet_dec__id0_act_o                     (fet_dec__id0_act),                 
    .fet_dec__id0_npc_o                     (fet_dec__id0_npc),                 
    .fet_dec__id0_pc_o                      (fet_dec__id0_pc),                  
    .fet_dec__id0_instr_o                   (fet_dec__id0_instr),               
    .fet_dec__id0_is_compressed_o           (fet_dec__id0_is_compressed),
    .dec_fet__raw_hazard_i                  (dec_fet__raw_hazard),              
    .fet_dec__id0_exception_o               (fet_dec__id0_exception)
);

sy_ppl_dec u_sy_ppl_dec (
    // =====================================
    // [clock & reset]
    .clk_i                                  (clk_i),                            
    .rst_i                                  (rst_i),                            
    // =====================================
    // [debug and irq signals]
    .debug_req_i                            (debug_req_i),
    .irq_i                                  (irq_i),
    // =====================================
    // [block signals]
    .dec_fet__ex0_accpt_o                   (dec_fet__ex0_accpt),               
    .alu_dec__mem_accpt_i                   (alu_dec__mem_accpt),               
    .alu_x__mispred_en_i                    (alu_x__mispred_en),                
    .ctrl_x__ex0_kill_i                     (ctrl_x__ex0_kill),                 
    // =====================================
    // [to ppl_ctrl]
    .dec_ctrl__ex0_act_o                    (dec_ctrl__ex0_act),                
    .dec_ctrl__ex0_avail_o                  (dec_ctrl__ex0_avail),              
    // ====================================
    // [from csr]
    .csr_dec__priv_lvl_i                    (priv_lvl),
    .csr_dec__fs_i                          (fs),
    .csr_dec__frm_i                         (frm),
    .csr_dec__tvm_i                         (tvm),
    .csr_dec__tw_i                          (tw),
    .csr_dec__tsr_i                         (tsr       ) , 
    .csr_dec__irq_ctrl_i                    (csr_dec__irq_ctrl  ) ,
    .csr_dec__debug_mode_i                  (debug_mode) ,    
    // =====================================
    // [to ppl_fet]
    .fet_dec__id0_avail_i                   (fet_dec__id0_avail),               
    .fet_dec__id0_act_i                     (fet_dec__id0_act),                 
    .fet_dec__id0_npc_i                     (fet_dec__id0_npc),                 
    .fet_dec__id0_pc_i                      (fet_dec__id0_pc),                  
    .fet_dec__id0_instr_i                   (fet_dec__id0_instr),               
    .fet_dec__id0_is_compressed_i           (fet_dec__id0_is_compressed),
    .dec_fet__raw_hazard_o                  (dec_fet__raw_hazard),              
    .fet_dec__id0_exception_i               (fet_dec__id0_exception),
    // =====================================
    // [to ppl_reg]
    .dec_reg__rs1_idx_o                     (dec_reg__rs1_idx),                 
    .reg_dec__rs1_reg_i                     (reg_dec__rs1_reg),                 
    .dec_reg__rs2_idx_o                     (dec_reg__rs2_idx),                 
    .reg_dec__rs2_reg_i                     (reg_dec__rs2_reg),                 
    // =====================================
    // [to ppl_fp_reg]
    .dec_fp_reg__rs1_idx_o                  (dec_fp_reg__rs1_idx       ) ,
    .fp_reg_dec__rs1_reg_i                  (fp_reg_dec__rs1_reg       ) ,
    .dec_fp_reg__rs2_idx_o                  (dec_fp_reg__rs2_idx       ) ,
    .fp_reg_dec__rs2_reg_i                  (fp_reg_dec__rs2_reg       ) ,
    .dec_fp_reg__rs3_idx_o                  (dec_fp_reg__rs3_idx       ) ,
    .fp_reg_dec__rs3_reg_i                  (fp_reg_dec__rs3_reg       ) ,

    // =====================================
    // [to ppl_alu]
    .dec_alu__ex0_avail_o                   (dec_alu__ex0_avail),               
    .dec_alu__instr_cls_o                   (dec_alu__instr_cls),               
    .dec_alu__stage_act_o                   (dec_alu__stage_act),               
    .dec_alu__npc_o                         (dec_alu__npc),                     
    .dec_alu__pc_o                          (dec_alu__pc),                      
    .dec_alu__instr_o                       (dec_alu__instr),                   
    .dec_alu__als_opcode_o                  (dec_alu__als_opcode),              
    .dec_alu__jbr_opcode_o                  (dec_alu__jbr_opcode),              
    .dec_alu__mem_opcode_o                  (dec_alu__mem_opcode),              
    .dec_alu__amo_opcode_o                  (dec_alu__amo_opcode),
    .dec_alu__sys_opcode_o                  (dec_alu__sys_opcode),              
    .dec_alu__sign_ext_o                    (dec_alu__sign_ext),                
    .dec_alu__lrsc_cmd_o                    (dec_alu__lrsc_cmd),                
    .dec_alu__rls_o                         (dec_alu__rls),                     
    .dec_alu__acq_o                         (dec_alu__acq),                     
    .dec_alu__csr_cmd_o                     (dec_alu__csr_cmd),                 
    .dec_alu__csr_addr_o                    (dec_alu__csr_addr),                
    .dec_alu__csr_imm_sel_o                 (dec_alu__csr_imm_sel),             
    .dec_alu__rs1_idx_o                     (dec_alu__rs1_idx),                 
    .dec_alu__rs1_data_o                    (dec_alu__rs1_data),                
    .dec_alu__rs2_idx_o                     (dec_alu__rs2_idx),                 
    .dec_alu__rs2_data_o                    (dec_alu__rs2_data),                
    .dec_alu__rdst_en_o                     (dec_alu__rdst_en),                 
    .dec_alu__rdst_src_sel_o                (dec_alu__rdst_src_sel),            
    .dec_alu__rdst_idx_o                    (dec_alu__rdst_idx),                
    .dec_alu__jbr_base_o                    (dec_alu__jbr_base),                
    .dec_alu__st_data_o                     (dec_alu__st_data),                 
    .dec_alu__imm_o                         (dec_alu__imm),                     
    .dec_alu__size_o                        (dec_alu__size),                    
    .dec_alu__fp_rdst_en_o                  (dec_alu__fp_rdst_en ),
    .dec_alu__fp_rdst_idx_o                 (dec_alu__fp_rdst_idx),
    .dec_alu__fp_result_o                   (dec_alu__fp_result  ),
    .dec_alu__fp_status_o                   (dec_alu__fp_status  ),
    .dec_alu__exception_o                   (dec_alu__exception  ), 
    .dec_alu__only_word_o                   (dec_alu__only_word  ),                            
    .dec_alu__is_compressed_o               (dec_alu__is_compressed),

    .alu_dec__mem_blk_en_i                  (alu_dec__mem_blk_en),              
    .alu_dec__mem_blk_idx_i                 (alu_dec__mem_blk_idx),             
    .alu_dec__mem_blk_f_or_x_i              (alu_dec__mem_blk_f_or_x),
    .alu_dec__bp0_rdst_i                    (alu_dec__bp0_rdst),                
    .alu_dec__bp1_rdst_i                    (alu_dec__bp1_rdst),                
    .alu_dec__bp0_f_or_x_i                  (alu_dec__bp0_f_or_x),
    .alu_dec__bp1_f_or_x_i                  (alu_dec__bp1_f_or_x),
    // =====================================
    // [to ppl_mdu]
    .dec_mdu__ex0_avail_o                   (dec_mdu__ex0_avail),               
    .dec_mdu__pc_o                          (dec_mdu__pc),                      
    .dec_mdu__mdu_opcode_o                  (dec_mdu__mdu_opcode),              
    .dec_mdu__rs1_sign_o                    (dec_mdu__rs1_sign),                
    .dec_mdu__rs2_sign_o                    (dec_mdu__rs2_sign),                
    .dec_mdu__rs1_data_o                    (dec_mdu__rs1_data),                
    .dec_mdu__rs2_data_o                    (dec_mdu__rs2_data),                
    .dec_mdu__rdst_idx_o                    (dec_mdu__rdst_idx),                
    .dec_mdu__only_word_o                   (dec_mdu__only_word),
    .mdu_dec__blk_en_mul_i                  (mdu_dec__blk_en_mul),              
    .mdu_dec__blk_idx_mul_i                 (mdu_dec__blk_idx_mul),             
    .mdu_dec__blk_en_div_i                  (mdu_dec__blk_en_div),              
    .mdu_dec__blk_idx_div_i                 (mdu_dec__blk_idx_div),             
    // =====================================
    // [to ppl_FPU]
    .dec_fpu__valid_o                        ( dec_fpu__valid       ),         
    .fpu_dec__ready_i                        ( fpu_dec__ready       ),         
    .dec_fpu__opcode_o                       ( dec_fpu__opcode      ),
    .dec_fpu__rs1_data_o                     ( dec_fpu__rs1_data    ),            
    .dec_fpu__rs2_data_o                     ( dec_fpu__rs2_data    ),            
    .dec_fpu__rs3_data_o                     ( dec_fpu__rs3_data    ),            
    .dec_fpu__fmt_o                          ( dec_fpu__fmt         ),       
    .dec_fpu__rm_o                           ( dec_fpu__rm          ),      
    .fpu_dec__result_i                       ( fpu_dec__result      ),          
    .fpu_dec__status_i                       ( fpu_dec__status      ),
    .fpu_dec__valid_i                        ( fpu_dec__valid       )         

);

sy_ppl_reg u_sy_ppl_reg (
    // =====================================
    // [clock & reset]
    .clk_i                                  (clk_i),                            
    .rst_i                                  (rst_i),                            
    // =====================================
    // [to ppl_dec]
    .dec_reg__rs1_idx_i                     (dec_reg__rs1_idx),                 
    .reg_dec__rs1_reg_o                     (reg_dec__rs1_reg),                 
    .dec_reg__rs2_idx_i                     (dec_reg__rs2_idx),                 
    .reg_dec__rs2_reg_o                     (reg_dec__rs2_reg),                 
    // =====================================
    // [to ppl_alu]
    .alu_reg__rdst_en_i                     (alu_reg__rdst_en),                 
    .alu_reg__rdst_idx_i                    (alu_reg__rdst_idx),                
    .alu_reg__rdst_data_i                   (alu_reg__rdst_data),               
    // =====================================
    // [to ppl_mdu]
    .mdu_reg__rdst_en_i                     (mdu_reg__rdst_en),                 
    .mdu_reg__rdst_idx_i                    (mdu_reg__rdst_idx),                
    .mdu_reg__rdst_data_i                   (mdu_reg__rdst_data)                
);

sy_ppl_fp_reg u_sy__ppl_fp_reg(
    // =====================================
    // [clock & reset]
    // -- <clock>
    .clk_i                      (clk_i                   ),                                    
                                 
    .rst_i                      (rst_i                   ),                                    
                                 
    .dec_fp_reg__rs1_idx_i      (dec_fp_reg__rs1_idx   ),                              
    .fp_reg_dec__rs1_reg_o      (fp_reg_dec__rs1_reg   ),                              
    .dec_fp_reg__rs2_idx_i      (dec_fp_reg__rs2_idx   ),                              
    .fp_reg_dec__rs2_reg_o      (fp_reg_dec__rs2_reg   ),                              
    .dec_fp_reg__rs3_idx_i      (dec_fp_reg__rs3_idx   ),                              
    .fp_reg_dec__rs3_reg_o      (fp_reg_dec__rs3_reg   ),                              
                                 
                                 
    .alu_fp_reg__rdst_en_i      (alu_fp_reg__rdst_en   ),                              
    .alu_fp_reg__rdst_idx_i     (alu_fp_reg__rdst_idx  ),                               
    .alu_fp_reg__rdst_data_i    (alu_fp_reg__rdst_data )                                
);

sy_ppl_alu u_sy_ppl_alu (
    // =====================================
    // [clock & reset]
    .clk_i                                  (clk_i),                            
    .rst_i                                  (rst_i),                            
    // =====================================
    // [block control]
    .alu_dec__mem_accpt_o                   (alu_dec__mem_accpt),               
    .alu_x__mispred_en_o                    (alu_x__mispred_en),                
    .alu_x__mispred_pc_o                    (alu_x__mispred_pc),                
    .alu_x__mispred_npc_o                   (alu_x__mispred_npc),               
    .ctrl_x__mem_kill_i                     (ctrl_x__mem_kill),                 
    .ctrl_x__wb_kill_i                      (ctrl_x__wb_kill),
    // =====================================
    // [csr regfile interface]
    .alu_csr__valid_o                       (alu_csr__valid ),   
    .alu_csr__cmd_o                         (alu_csr__cmd   ), 
    .alu_csr__wdata_o                       (alu_csr__wdata ),   
    .alu_csr__addr_o                        (alu_csr__addr  ),  
    .csr_alu__rdata_i                       (csr_alu__rdata ),   
    .alu_csr__ex_o                          (alu_csr__ex    ),   
    .alu_csr__pc_o                          (alu_csr__pc    ),
    .alu_csr__npc_o                         (alu_csr__npc   ), 
    .alu_csr__instr_o                       (alu_csr__instr ),   
    .alu_csr__write_fflags_o                (alu_csr__write_fflags),
    .alu_csr__dirty_fp_state_o              (alu_csr__dirty_fp_state),
    .alu_csr__fflags_o                      (alu_csr__fflags),
                                             
    .alu_csr__mret_o                        (alu_csr__mret  ),  
    .alu_csr__sret_o                        (alu_csr__sret  ),  
    .alu_csr__dret_o                        (alu_csr__dret  ),  

    // =====================================
    // [to ppl_ctrl]
    .alu_csr__wfi_o                         (alu_csr__wfi_en),                
    .alu_ctrl__fencei_en_o                  (alu_ctrl__fencei_en),            
    .alu_ctrl__fence_en_o                   (alu_ctrl__fence_en),             
    .alu_ctrl__sfence_vma_o                 (alu_ctrl__sfence_vma),
    .alu_ctrl__mem_act_o                    (alu_ctrl__mem_act),              
    .alu_ctrl__wb_act_o                     (alu_ctrl__wb_act),               
    .alu_ctrl__wb_npc_o                     (alu_ctrl__wb_npc),
    // =====================================
    // [to ppl_dec]
    .dec_alu__ex0_avail_i                   (dec_alu__ex0_avail),             
    .dec_alu__instr_cls_i                   (dec_alu__instr_cls),             
    .dec_alu__stage_act_i                   (dec_alu__stage_act),             
    .dec_alu__npc_i                         (dec_alu__npc),                   
    .dec_alu__pc_i                          (dec_alu__pc),                    
    .dec_alu__instr_i                       (dec_alu__instr),                 
    .dec_alu__als_opcode_i                  (dec_alu__als_opcode),            
    .dec_alu__jbr_opcode_i                  (dec_alu__jbr_opcode),            
    .dec_alu__mem_opcode_i                  (dec_alu__mem_opcode),            
    .dec_alu__amo_opcode_i                  (dec_alu__amo_opcode),
    .dec_alu__sys_opcode_i                  (dec_alu__sys_opcode),            
    .dec_alu__sign_ext_i                    (dec_alu__sign_ext),              
    .dec_alu__lrsc_cmd_i                    (dec_alu__lrsc_cmd),              
    .dec_alu__rls_i                         (dec_alu__rls),                   
    .dec_alu__acq_i                         (dec_alu__acq),                   
    .dec_alu__csr_cmd_i                     (dec_alu__csr_cmd),               
    .dec_alu__csr_addr_i                    (dec_alu__csr_addr),              
    .dec_alu__csr_imm_sel_i                 (dec_alu__csr_imm_sel),           
    .dec_alu__rs1_idx_i                     (dec_alu__rs1_idx),               
    .dec_alu__rs1_data_i                    (dec_alu__rs1_data),              
    .dec_alu__rs2_idx_i                     (dec_alu__rs2_idx),               
    .dec_alu__rs2_data_i                    (dec_alu__rs2_data),              
    .dec_alu__rdst_en_i                     (dec_alu__rdst_en),               
    .dec_alu__rdst_src_sel_i                (dec_alu__rdst_src_sel),          
    .dec_alu__rdst_idx_i                    (dec_alu__rdst_idx),              
    .dec_alu__jbr_base_i                    (dec_alu__jbr_base),              
    .dec_alu__st_data_i                     (dec_alu__st_data),               
    .dec_alu__imm_i                         (dec_alu__imm),                   
    .dec_alu__size_i                        (dec_alu__size),                  
    .dec_alu__fp_rdst_en_i                  (dec_alu__fp_rdst_en),
    .dec_alu__fp_rdst_idx_i                 (dec_alu__fp_rdst_idx),
    .dec_alu__fp_result_i                   (dec_alu__fp_result),
    .dec_alu__fp_status_i                   (dec_alu__fp_status),
    .dec_alu__exceptions_i                  (dec_alu__exception),
    .dec_alu__only_word_i                   (dec_alu__only_word),
    .dec_alu__is_compressed_i               (dec_alu__is_compressed),

    .alu_dec__mem_blk_en_o                  (alu_dec__mem_blk_en),              
    .alu_dec__mem_blk_idx_o                 (alu_dec__mem_blk_idx),             
    .alu_dec__mem_blk_f_or_x_o              (alu_dec__mem_blk_f_or_x),
    .alu_dec__bp0_rdst_o                    (alu_dec__bp0_rdst),                
    .alu_dec__bp1_rdst_o                    (alu_dec__bp1_rdst),                
    .alu_dec__bp0_f_or_x_o                  (alu_dec__bp0_f_or_x),
    .alu_dec__bp1_f_or_x_o                  (alu_dec__bp1_f_or_x),  
    // =====================================
    // [to ppl_mdu]
    .mdu_alu__mul_wb_busy_i                 (mdu_alu__mul_wb_busy),             
    .mdu_alu__div_wb_busy_i                 (mdu_alu__div_wb_busy),             
    // =====================================
    // [to ppl_reg]
    .alu_reg__rdst_en_o                     (alu_reg__rdst_en),                 
    .alu_reg__rdst_idx_o                    (alu_reg__rdst_idx),                
    .alu_reg__rdst_data_o                   (alu_reg__rdst_data),               
    // =====================================
    // [to ppl_fp_reg]
    .alu_fp_reg__rdst_en_o                  (alu_fp_reg__rdst_en     ),             
    .alu_fp_reg__rdst_idx_o                 (alu_fp_reg__rdst_idx    ),              
    .alu_fp_reg__rdst_data_o                (alu_fp_reg__rdst_data   ),               
    // =====================================
    // [to LSU]
    .ppl_dmem__vld_o                        (ppl_dmem__vld        ),              
    .ppl_dmem__addr_o                       (ppl_dmem__addr       ),               
    .ppl_dmem__wdata_o                      (ppl_dmem__wdata      ),                
    .ppl_dmem__size_o                       (ppl_dmem__size       ),               
    .ppl_dmem__opcode_o                     (ppl_dmem__opcode     ),                 
    .ppl_dmem__amo_opcode_o                 (ppl_dmem__amo_opcode ),                     
    .ppl_dmem__kill_o                       (ppl_dmem__kill       ),               
    .dmem_ppl__hit_i                        (dmem_ppl__hit        ),              
    .dmem_ppl__rdata_i                      (dmem_ppl__rdata      ),                
    .dmem_ppl__exception_i                  (dmem_ppl__exception  )              
);

sy_ppl_mdu u_sy_ppl_mdu (
    // =====================================
    // [clock & reset]
    .clk_i                                  (clk_i),                            
    .rst_i                                  (rst_i),                            
    // =====================================
    // [block control]
    .ctrl_x__mem_kill_i                     (ctrl_x__mem_kill),                 
    // =====================================
    // [to ppl_ctrl]
    .mdu_ctrl__mul_act_o                    (mdu_ctrl__mul_act),                
    .mdu_ctrl__div_act_o                    (mdu_ctrl__div_act),                
    // =====================================
    // [to ppl_dec]
    .dec_mdu__ex0_avail_i                   (dec_mdu__ex0_avail),               
    .dec_mdu__pc_i                          (dec_mdu__pc),                      
    .dec_mdu__mdu_opcode_i                  (dec_mdu__mdu_opcode),              
    .dec_mdu__rs1_sign_i                    (dec_mdu__rs1_sign),                
    .dec_mdu__rs2_sign_i                    (dec_mdu__rs2_sign),                
    .dec_mdu__rs1_data_i                    (dec_mdu__rs1_data),                
    .dec_mdu__rs2_data_i                    (dec_mdu__rs2_data),                
    .dec_mdu__rdst_idx_i                    (dec_mdu__rdst_idx),                
    .dec_mdu__only_word_i                   (dec_mdu__only_word),
    .mdu_dec__blk_en_mul_o                  (mdu_dec__blk_en_mul),              
    .mdu_dec__blk_idx_mul_o                 (mdu_dec__blk_idx_mul),             
    .mdu_dec__blk_en_div_o                  (mdu_dec__blk_en_div),              
    .mdu_dec__blk_idx_div_o                 (mdu_dec__blk_idx_div),             
    .mdu_alu__mul_wb_busy_o                 (mdu_alu__mul_wb_busy),             
    .mdu_alu__div_wb_busy_o                 (mdu_alu__div_wb_busy),             
    // =====================================
    // [to ppl_reg]
    .mdu_reg__rdst_en_o                     (mdu_reg__rdst_en),                 
    .mdu_reg__rdst_idx_o                    (mdu_reg__rdst_idx),                
    .mdu_reg__rdst_data_o                   (mdu_reg__rdst_data)                
);

sy_ppl_fpu u_sy_ppl_fpu(
    // =====================================
    // [clock & reset]
    // -- <clock>
    .clk_i                                  (clk_i               ),                                
    .rst_i                                  (rst_i               ),                                
    .flush_i                                (alu_x__mispred_en || ctrl_x__ex0_kill),            
                                             
    .dec_fpu__valid_i                       (dec_fpu__valid    ),                     
    .fpu_dec__ready_o                       (fpu_dec__ready    ),                     
    .dec_fpu__opcode_i                      (dec_fpu__opcode   ),
                                             
    .dec_fpu__rs1_data_i                    (dec_fpu__rs1_data ),                        
    .dec_fpu__rs2_data_i                    (dec_fpu__rs2_data ),                        
    .dec_fpu__rs3_data_i                    (dec_fpu__rs3_data ),                        
                                             
    .dec_fpu__fmt_i                         (dec_fpu__fmt      ),                   
    .dec_fpu__rm_i                          (dec_fpu__rm       ),                  
                                             
    .csr_fpu__frm_i                         (frm      ),                   
    .csr_fpu__prec_i                        (fprec     ),                    
                                             
    .fpu_dec__result_o                      (fpu_dec__result   ),                      
    .fpu_dec__status_o                      (fpu_dec__status    ),
    .fpu_dec__valid_o                       (fpu_dec__valid    )                     
);

sy_ppl_csr_regfile #(
    .HART_ID_WTH (HART_ID_WTH)
) u_sy_ppl_csr_regfile (
    // =====================================
    // [clock & reset]
    // -- <clock>
    .clk_i                                  (clk_i                  ),                             
    .rst_i                                  (rst_i                  ),                             
                                             
    .boot_addr_i                            (boot_addr_i            ),             
    .hart_id_i                              (HART_ID[HART_ID_WTH-1:0]),
    .debug_req_i                            (debug_req_i),                                     
    .halt_o                                 (halt),
                                             
    .alu_csr__valid_i                       (alu_csr__valid       ),                  
    .alu_csr__cmd_i                         (alu_csr__cmd         ),                
    .alu_csr__addr_i                        (alu_csr__addr        ),                 
    .alu_csr__wdata_i                       (alu_csr__wdata       ),                  
    .csr_alu__rdata_o                       (csr_alu__rdata       ),                  
    .alu_csr__ex_i                          (alu_csr__ex          ),               
    .alu_csr__pc_i                          (alu_csr__pc          ),               
    .alu_csr__instr_i                       (alu_csr__instr       ),                  
    .alu_csr__write_fflags_i                (alu_csr__write_fflags),
    .alu_csr__dirty_fp_state_i              (alu_csr__dirty_fp_state),
    .alu_csr__fflags_i                      (alu_csr__fflags      ),
    .alu_csr__wfi_i                         (alu_csr__wfi_en),
    .csr_ctrl__wfi_wakeup_o                 (),
    .alu_csr__mret_i                        (alu_csr__mret        ),                 
    .alu_csr__sret_i                        (alu_csr__sret        ),                 
    .alu_csr__dret_i                        (alu_csr__dret        ),                 
    .csr_dec__irq_ctrl_o                    (csr_dec__irq_ctrl    ),                     
                                             
    .irq_i                                  (irq_i                  ),         // external interrupts
    .ipi_i                                  (ipi_i                  ),       
                                             
    .timer_irq_i                            (time_irq_i            ),                 
    .priv_lvl_o                             (priv_lvl             ),            
                                             
    .csr_ctrl__eret_o                       (csr_ctrl__eret       ),                  
    .csr_ctrl__epc_o                        (csr_ctrl__epc        ),                 
    .csr_ctrl__ex_valid_o                   (csr_ctrl__ex_valid   ),                      
    .csr_ctrl__trap_vec_o                   (csr_ctrl__trap_vec   ),                      
    // .csr_ctrl__wfi_wakeup_o                 (csr_ctrl__wfi_wakeup ),                        
    .csr_ctrl__set_debug_o                  (csr_ctrl__set_debug  ),                       
    .csr_ctrl__debug_mode_o                 (csr_ctrl__debug_mode ),                        
    .csr_ctrl__flush_o                      (csr_ctrl__flush      ),                   
                                             
    .fs_o                                   (fs                   ),      
    .fflags_o                               (),          
    .frm_o                                  (frm                  ),       
    .fprec_o                                (fprec                ),         
                                             
    .en_translation_o                       (en_translation       ),                             
    .en_ld_st_translation_o                 (en_ld_st_translation ),                             
    .ld_st_priv_lvl_o                       (ld_st_priv_lvl       ),// Privilege level at which load and stores should happen
    .sum_o                                  (sum                  ),       
    .mxr_o                                  (mxr                  ),       
    .satp_ppn_o                             (satp_ppn             ),            
    .asid_o                                 (asid                 ),        
                                             
    .tvm_o                                  (tvm                  ),// trap virtual memory
    .tw_o                                   (tw                   ),// timeout wait
    .tsr_o                                  (tsr                  ),// trap sret
    .debug_mode_o                           (debug_mode           ),// we are in debug mode -> that will change some decoding
                                             
    .icache_en_o                            (icache_en            ),// L1 ICache Enable
    .dcache_en_o                            (dcache_en            ),// L1 DCache Enable
                                             
    .perf_addr_o                            (perf_addr            ),// read/write address to performance counter module (up to 29 aux counters possible in riscv encoding.h)
    .perf_data_o                            (),                     // write data to performance counter module
    .perf_data_i                            ('0),                   // read data from performance counter module
    .perf_we_o                              (perf_we              )  
);

sy_ppl_lsu u_sy_lsu(
    // =====================================
    // [clock & reset]
    // -- <clock>
    .clk_i                                  (clk_i                    ),                   // clock
    .rst_i                                  (rst_i                    ),                   // reset
                                             
    .ppl_dmem__vld_i                        (ppl_dmem__vld          ),       
    .ppl_dmem__addr_i                       (ppl_dmem__addr         ),        
    .ppl_dmem__wdata_i                      (ppl_dmem__wdata        ),         
    .ppl_dmem__size_i                       (ppl_dmem__size         ),        
    .ppl_dmem__opcode_i                     (ppl_dmem__opcode       ),          
    .ppl_dmem__amo_opcode_i                 (ppl_dmem__amo_opcode   ),              
    .ppl_dmem__kill_i                       (ppl_dmem__kill         ),        
    .dmem_ppl__hit_o                        (dmem_ppl__hit          ),       
    .dmem_ppl__rdata_o                      (dmem_ppl__rdata        ),         
    .dmem_ppl__ex_o                         (dmem_ppl__exception    ),      
                                             
    .lsu_mmu__req_o                         (lsu_mmu__req           ),      
    .lsu_mmu__vaddr_o                       (lsu_mmu__vaddr         ),        
    .lsu_mmu__is_store_o                    (lsu_mmu__is_store      ),           
    .mmu_lsu__dtlb_hit_i                    (mmu_lsu__dtlb_hit      ),           
    .mmu_lsu__valid_i                       (mmu_lsu__valid         ),        
    .mmu_lsu__paddr_i                       (mmu_lsu__paddr         ),        
    .mmu_lsu__ex_i                          (mmu_lsu__ex            ),     
                                             
    .lsu_dcache__req_o                      (dcache_req[1]),               
    .dcache_lsu__rsp_i                      (dcache_rsp[1])              
);

cva6_mmu #(
    .INSTR_TLB_ENTRIES      ( 16                     ),
    .DATA_TLB_ENTRIES       ( 16                     ) 
)mmu(
    .clk_i                                  (clk_i                  ), 
    .rst_ni                                 (rst_i                  ), 
    .flush_i                                (ctrl_x__if0_kill       ),  
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
                                             
    .priv_lvl_i                             (priv_lvl               ),     
    .ld_st_priv_lvl_i                       (ld_st_priv_lvl         ),           
    .sum_i                                  (sum                    ),
    .mxr_i                                  (mxr                    ),
                                             
    .satp_ppn_i                             (satp_ppn               ),     
    .asid_i                                 (asid                   ), 
    .flush_tlb_i                            (tlb_flush              ),      
                                             
    .itlb_miss_o                            (                       ),      
    .dtlb_miss_o                            (                       ),      
                                             
    .rsp_port_i                             (dcache_rsp[0]          ),     
    .req_port_o                             (dcache_req[0]          )  
);

sy_L1_cache  #(
    .HART_ID_WTH        (HART_ID_WTH),
    .HART_ID            (HART_ID),
    .ADDR_WTH           (AWTH),
    .REQ_PORT           (2)            
) L1_cache(
    .clk_i                                  (clk_i),      
    .rst_i                                  (rst_i),      
    .flush_icache_i                         (icache_flush),                 
    .flush_icache_done_o                    (icache_flush_done),                    
    .flush_dcache_i                         (dcache_flush),                 
    .flush_dcache_done_o                    (dcache_flush_ack),                    
    .icache_miss_o                          (),                             
    .dcache_miss_o                          (),                             
    .icache_mmu__req_o                      (icache_areq),                  
    .mmu_icache__rsp_i                      (icache_arsp),                  
    .fetch_icache__req_i                    (fet_icache__dreq),                                         
    .icache_fetch__rsp_o                    (icache_fet__drsp),                    
    .dcache_req_i                           (dcache_req),             
    .dcache_rsp_o                           (dcache_rsp),             
    .slave                                  (master)
);


//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule : sy_core
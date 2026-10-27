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
    input   logic                           clk_fpu_i,
    // -- <reset>
    input   logic                           rst_i,                      
    // =====================================
    // -- <boot address>
    input   logic[AWTH-1:0]                 boot_addr_i,
    input   logic                           boot_mode_i,
    // -- <irq>
    input   logic[1:0]                      irq_i,
    input   logic                           ipi_i,
    input   logic                           time_irq_i,
    // -- <debug>
    input   logic                           debug_req_i,
    // -- <remote call>
    input   logic                           remote_call_i,
    input   logic                           remote_invdc_i,
    input   logic                           remote_invic_i,
    input   logic                           remote_kill_i,
    output  logic                           remote_call_busy_o,
    output  logic                           remote_invdc_busy_o,
    output  logic                           remote_invic_busy_o,
    output  logic                           remote_kill_busy_o,
    input   logic[63:0]                     remote_ret_addr_i,

    input   logic                           fence_state_i,
    input   logic                           forbid_br_pred_i,
    input   logic                           exe_region_ex_en_i,
    input   logic                           is_avail_i, // if is 0, means this core is not available
    // =====================================
    // TL A
    output logic                            L1_tl_A_valid_o, 
    input  logic                            L1_tl_A_ready_i, 
    output tl_pkg::A_chan_bits_t            L1_tl_A_bits_o,
    // TL B
    input  logic                            L1_tl_B_valid_i, 
    output logic                            L1_tl_B_ready_o, 
    input  tl_pkg::B_chan_bits_t            L1_tl_B_bits_i,
    // TL C
    output logic                            L1_tl_C_valid_o, 
    input  logic                            L1_tl_C_ready_i, 
    output tl_pkg::C_chan_bits_t            L1_tl_C_bits_o,
    // TL D
    input  logic                            L1_tl_D_valid_i, 
    output logic                            L1_tl_D_ready_o, 
    input  tl_pkg::D_chan_bits_t            L1_tl_D_bits_i,
    // TL E
    output logic                            L1_tl_E_valid_o, 
    input  logic                            L1_tl_E_ready_i, 
    output tl_pkg::E_chan_bits_t            L1_tl_E_bits_o
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
logic                           ctrl_fet__step;
logic[DWTH-1:0]                 ctrl_alu__csr_rdata;
// fet
logic                           fet_ctrl__if0_act;
logic                           fet_ctrl__id0_act;
logic                           fet_dec__id0_avail;
logic                           fet_dec__id0_act;
// logic[AWTH-1:0]                 fet_dec__id0_npc;
logic[AWTH-1:0]                 fet_dec__id0_ras_addr;
logic[AWTH-1:0]                 fet_dec__id0_btb_addr;
npc_type_e                      fet_dec__id0_npc_type;
logic[AWTH-1:0]                 fet_dec__id0_pc;
logic[IWTH-1:0]                 fet_dec__id0_instr;
logic                           fet_dec__id0_is_compressed;

logic                           fet_dec__id0_excp_en;
ecode_e                         fet_dec__id0_excp_ecode;
logic                           fet_csr__ic_access;
logic                           fet_csr__ic_miss;

// dec
logic                           dec_fet__ex0_accpt;
logic                           dec_ctrl__ex0_act;
logic                           dec_ctrl__ex0_avail;
logic                           dec_fet__raw_hazard;
logic[4:0]                      dec_reg__rs1_idx;
logic[4:0]                      dec_reg__rs2_idx;
logic                           dec_alu__ex0_avail;
logic                           dec_alu__ex0_act;
instr_cls_e                     dec_alu__instr_cls;
logic[1:0]                      dec_alu__stage_act;
// logic[AWTH-1:0]                 dec_alu__npc;
logic[AWTH-1:0]                 dec_alu__ras_addr;
logic[AWTH-1:0]                 dec_alu__btb_addr;
npc_type_e                      dec_alu__npc_type;
logic[AWTH-1:0]                 dec_alu__pc;
logic[IWTH-1:0]                 dec_alu__instr;
als_opcode_e                    dec_alu__als_opcode;
jbr_opcode_e                    dec_alu__jbr_opcode;
mem_opcode_e                    dec_alu__mem_opcode;
amo_t                           dec_alu__amo_opcode;
sys_opcode_e                    dec_alu__sys_opcode;
logic                           dec_alu__sign_ext;
csr_cmd_e                       dec_alu__csr_cmd;
logic[11:0]                     dec_alu__csr_addr;
logic                           dec_alu__csr_imm_sel;
logic[4:0]                      dec_alu__rs1_idx;
logic[DWTH-1:0]                 dec_alu__rs1_data;
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
logic                           dec_alu__waw_stall;
logic                           dec_alu__ex0_stall;
logic                           dec_mdu__ex0_avail;
logic[AWTH-1:0]                 dec_mdu__npc;
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
logic                           alu_dec__tlb_miss_block;
logic                           alu_dec__dc_rsp_block;
logic                           alu_dec__mem_accpt;
logic                           alu_x__mispred_en;
logic[AWTH-1:0]                 alu_x__mispred_pc;
logic[AWTH-1:0]                 alu_x__mispred_npc;
bht_update_t                    bht_update;
btb_update_t                    btb_update;
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
logic                           alu_dec__mem0_blk_en;
logic[4:0]                      alu_dec__mem0_blk_idx;
logic                           alu_dec__mem0_blk_f_or_x;
logic                           alu_dec__mem1_blk_en;
logic[4:0]                      alu_dec__mem1_blk_idx;
logic                           alu_dec__mem1_blk_f_or_x;
bp_bus_t                        alu_dec__bp0_rdst;
bp_bus_t                        alu_dec__bp1_rdst;
bp_bus_t                        alu_dec__bp2_rdst;
logic                           alu_dec__bp0_f_or_x;
logic                           alu_dec__bp1_f_or_x;
logic                           alu_dec__bp2_f_or_x;
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
logic                           mdu_csr__retire_en;
logic[AWTH-1:0]                 mdu_csr__retire_npc;
logic                           mdu_reg__rdst_en;
logic[4:0]                      mdu_reg__rdst_idx;
logic[DWTH-1:0]                 mdu_reg__rdst_data;

logic                           icache_flush;
logic                           icache_flush_done;
logic                           dcache_flush;
logic                           dcache_flush_ack;
logic                           dcache_invalid;
logic                           tlb_flush;
logic                           alu_ctrl__sfence_vma;
logic                           alu_ctrl__ret_addr_match;
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
logic                           fet_icache__req;
logic                           fet_icache__kill;
logic                           icache_fet__rsp;
fetch_req_t                     fet_icache__req_bits    ;
fetch_rsp_t                     icache_fet__rsp_bits    ;


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

logic                           alu_csr__retire_en      ;
logic[AWTH-1:0]                 alu_csr__retire_npc     ;
logic                           alu_csr__retire_is_jbr  ;
logic                           alu_csr__mispred        ;
logic                           alu_csr__dc_access      ;
logic                           alu_csr__dc_miss        ;

logic                           alu_csr__mret           ;  
logic                           alu_csr__sret           ;  
logic                           alu_csr__dret           ;  

logic                           alu_fp_reg__rdst_en     ;
logic[4:0]                      alu_fp_reg__rdst_idx    ;
logic[DWTH-1:0]                 alu_fp_reg__rdst_data   ;

logic                            en_translation         ;                             
logic                            en_ld_st_translation   ;                             
priv_lvl_t                       ld_st_priv_lvl         ;  // Privilege level at which load and stores should happen
logic                            sum                    ;       
logic                            mxr                    ;       
logic [43:0]                     satp_ppn               ;            
logic                            asid                   ;        
logic                            tvm                    ;  // trap virtual memory
logic                            tw                     ;  // timeout wait
logic                            tsr                    ;  // trap sret
logic                            debug_mode             ;  // we are in debug mode -> that will change some decoding
logic  [4:0]                     perf_addr              ;  // read/write address to performance counter module (up to 29 aux counters possible in riscv encoding.h)
logic  [63:0]                    perf_rdata             ;  // read data from performance counter module
logic  [63:0]                    perf_wdata             ;  // write data to performance counter module
logic                            perf_we                ; 

logic                            ppl_mmu__req           ;   
logic[63:0]                      ppl_mmu__vaddr         ;     
logic                            ppl_mmu__is_store      ;        
logic                            mmu_ppl__dtlb_hit      ;        
logic                            mmu_ppl__valid         ;     
logic[63:0]                      mmu_ppl__paddr         ;     
exception_t                      mmu_ppl__ex            ;  

logic                            ppl_dmem__req;
logic                            dmem_ppl__rsp;
dcache_req_t                     ppl_dmem__req_bits;
dcache_rsp_t                     dmem_ppl__rsp_bits; 
logic                            mmu_dmem__req;
logic                            dmem_mmu__rsp;
dcache_req_t                     mmu_dmem__req_bits;
dcache_rsp_t                     dmem_mmu__rsp_bits; 


amo_req_t                           amo_req;
amo_resp_t                          amo_resp; 

icache_mmu_req_t                    icache_areq;
mmu_icache_rsp_t                    icache_arsp;

logic                               halt;
logic                               single_step;
logic                               flush_bp;               
logic                               dcache_ctrl_idle;
logic                               icache_ctrl_idle;

logic                               fet_mmu__req;
logic[AWTH-1:0]                     fet_mmu__vaddr;
logic                               mmu_fet__itlb_hit;
logic                               mmu_fet__valid;
logic[63:0]                         mmu_fet__paddr;
exception_t                         mmu_fet__ex;
logic                               mmu_fet__ptw_walking_instr;

//======================================================================================================================
// Instance
//======================================================================================================================

sy_ppl_ctrl u_sy_ppl_ctrl (
    // =====================================
    // [clock & reset]
    .clk_i                                  (clk_i),                            
    .rst_i                                  (rst_i),                            
    .flush_bp_o                             (flush_bp),                  
    // =====================================
    // [ctrl & status]
    .boot_addr_i                            (boot_addr_i),                   
    .boot_mode_i                            (boot_mode_i),
    .fence_state_i                          (fence_state_i),
    .is_avail_i                             (is_avail_i),
    // =====================================
    // [remote call]
    .remote_call_i                          (remote_call_i      ),
    .remote_invdc_i                         (remote_invdc_i     ),
    .remote_invic_i                         (remote_invic_i     ),
    .remote_kill_i                          (remote_kill_i      ),
    .remote_call_busy_o                     (remote_call_busy_o ),
    .remote_invdc_busy_o                    (remote_invdc_busy_o),
    .remote_invic_busy_o                    (remote_invic_busy_o),
    .remote_kill_busy_o                     (remote_kill_busy_o ),
    // =====================================
    // [to IMEM]
    .ppl_icache_flush_o                     (icache_flush),         
    .ppl_dcache_flush_o                     (dcache_flush),         
    .ppl_dcache_flush_ack_i                 (dcache_flush_ack),         
    .ppl_tlb_flush_o                        (tlb_flush),
    .ppl_dcache_inv_o                       (dcache_invalid),
    .dcache_ctrl_idle_i                     (dcache_ctrl_idle),
    .icache_ctrl_idle_i                     (icache_ctrl_idle),
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
    .ctrl_fet__step_o                       (ctrl_fet__step),
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
    .alu_ctrl__ret_addr_match_i             (alu_ctrl__ret_addr_match),
    // =====================================
    // [to ppl_mdu]
    .mdu_ctrl__mul_act_i                    (mdu_ctrl__mul_act),                
    .mdu_ctrl__div_act_i                    (mdu_ctrl__div_act),                
    // =====================================
    // [from csr regfile]
    .csr_ctrl__single_step_i                (single_step    ),
    .csr_ctrl__eret_i                       (csr_ctrl__eret),
    .csr_ctrl__epc_i                        (csr_ctrl__epc),
    .csr_ctrl__trap_vec_i                   (csr_ctrl__trap_vec),
    // .csr_ctrl__wfi_wakeup_i                 (csr_ctrl__wfi_wakeup),
    .csr_ctrl__set_debug_i                  (csr_ctrl__set_debug),
    .csr_ctrl__ex_valid_i                   (csr_ctrl__ex_valid),
    // .csr_ctrl__debug_mode_i                 (csr_ctrl__debug_mode),
    .csr_ctrl__flush_i                      (csr_ctrl__flush)
);

sy_ppl_fet u_sy_ppl_fet (
    // =====================================
    // [clock & reset]
    .clk_i                                  (clk_i),                            
    .rst_i                                  (rst_i),                            

    .halt_i                                 (halt),
    .debug_mode_i                           (debug_mode),
    .forbid_br_pred_i                       (forbid_br_pred_i), 

    .fet_csr__ic_access_o                   (fet_csr__ic_access),
    .fet_csr__ic_miss_o                     (fet_csr__ic_miss  ),
 
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
    .ctrl_fet__step_i                       (ctrl_fet__step),
    .fet_ctrl__if0_act_o                    (fet_ctrl__if0_act),                
    .fet_ctrl__id0_act_o                    (fet_ctrl__id0_act),                
    // =====================================
    // [From alu]
    .flush_bp_i                             (flush_bp),
    .bht_update_i                           (bht_update),
    .btb_update_i                           (btb_update),
    // =====================================
    // [to ICACHE]
    .fet_icache__kill_o                     (fet_icache__kill),
    .fet_icache__req_o                      (fet_icache__req),
    .icache_fet__rsp_i                      (icache_fet__rsp),
    .fet_icache__req_bits_o                 (fet_icache__req_bits),
    .icache_fet__rsp_bits_i                 (icache_fet__rsp_bits),
    // =====================================
    // [to MMU]
    .mmu_fet__ptw_walking_instr_i           (mmu_fet__ptw_walking_instr),
    .fet_mmu__req_o                         (fet_mmu__req     ),
    .fet_mmu__vaddr_o                       (fet_mmu__vaddr   ),
    .mmu_fet__itlb_hit_i                    (mmu_fet__itlb_hit),
    .mmu_fet__valid_i                       (mmu_fet__valid   ),
    .mmu_fet__paddr_i                       (mmu_fet__paddr   ),
    .mmu_fet__ex_i                          (mmu_fet__ex      ),
    // =====================================
    // [to ppl_dec]
    .fet_dec__id0_avail_o                   (fet_dec__id0_avail),               
    .fet_dec__id0_act_o                     (fet_dec__id0_act),                 
    // .fet_dec__id0_npc_o                     (fet_dec__id0_npc),                 
    .fet_dec__id0_ras_addr_o                (fet_dec__id0_ras_addr),                 
    .fet_dec__id0_btb_addr_o                (fet_dec__id0_btb_addr),                 
    .fet_dec__id0_npc_type_o                (fet_dec__id0_npc_type),                 
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
    // .fet_dec__id0_npc_i                     (fet_dec__id0_npc),                 
    .fet_dec__id0_ras_addr_i                (fet_dec__id0_ras_addr),                 
    .fet_dec__id0_btb_addr_i                (fet_dec__id0_btb_addr),                 
    .fet_dec__id0_npc_type_i                (fet_dec__id0_npc_type),                 
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
    .dec_alu__ex0_act_o                     (dec_alu__ex0_act),               
    .dec_alu__instr_cls_o                   (dec_alu__instr_cls),               
    .dec_alu__stage_act_o                   (dec_alu__stage_act),               
    // .dec_alu__npc_o                         (dec_alu__npc),                     
    .dec_alu__ras_addr_o                    (dec_alu__ras_addr),                     
    .dec_alu__btb_addr_o                    (dec_alu__btb_addr),                     
    .dec_alu__npc_type_o                    (dec_alu__npc_type),                     
    .dec_alu__pc_o                          (dec_alu__pc),                      
    .dec_alu__instr_o                       (dec_alu__instr),                   
    .dec_alu__als_opcode_o                  (dec_alu__als_opcode),              
    .dec_alu__jbr_opcode_o                  (dec_alu__jbr_opcode),              
    .dec_alu__mem_opcode_o                  (dec_alu__mem_opcode),              
    .dec_alu__amo_opcode_o                  (dec_alu__amo_opcode),
    .dec_alu__sys_opcode_o                  (dec_alu__sys_opcode),              
    .dec_alu__sign_ext_o                    (dec_alu__sign_ext),                
    .dec_alu__csr_cmd_o                     (dec_alu__csr_cmd),                 
    .dec_alu__csr_addr_o                    (dec_alu__csr_addr),                
    .dec_alu__csr_imm_sel_o                 (dec_alu__csr_imm_sel),             
    .dec_alu__rs1_idx_o                     (dec_alu__rs1_idx),                 
    .dec_alu__rs1_data_o                    (dec_alu__rs1_data),                
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
    .dec_alu__waw_stall_o                   (dec_alu__waw_stall),
    .dec_alu__ex0_stall_o                   (dec_alu__ex0_stall),
    .alu_dec__tlb_miss_block_i              (alu_dec__tlb_miss_block),
    .alu_dec__dc_rsp_block_i                (alu_dec__dc_rsp_block),


    .alu_dec__mem0_blk_en_i                 (alu_dec__mem0_blk_en),              
    .alu_dec__mem0_blk_idx_i                (alu_dec__mem0_blk_idx),             
    .alu_dec__mem0_blk_f_or_x_i             (alu_dec__mem0_blk_f_or_x),
    .alu_dec__mem1_blk_en_i                 (alu_dec__mem1_blk_en),              
    .alu_dec__mem1_blk_idx_i                (alu_dec__mem1_blk_idx),             
    .alu_dec__mem1_blk_f_or_x_i             (alu_dec__mem1_blk_f_or_x),
    .alu_dec__bp0_rdst_i                    (alu_dec__bp0_rdst),                
    .alu_dec__bp1_rdst_i                    (alu_dec__bp1_rdst),                
    .alu_dec__bp2_rdst_i                    (alu_dec__bp2_rdst),                
    .alu_dec__bp0_f_or_x_i                  (alu_dec__bp0_f_or_x),
    .alu_dec__bp1_f_or_x_i                  (alu_dec__bp1_f_or_x),
    .alu_dec__bp2_f_or_x_i                  (alu_dec__bp2_f_or_x),
    // =====================================
    // [to ppl_mdu]
    .dec_mdu__ex0_avail_o                   (dec_mdu__ex0_avail),               
    .dec_mdu__npc_o                         (dec_mdu__npc),                      
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

    .ret_addr_i                             (remote_ret_addr_i),
    // =====================================
    // [block control]
    .alu_dec__mem_accpt_o                   (alu_dec__mem_accpt),               
    .alu_x__mispred_en_o                    (alu_x__mispred_en),                
    .alu_x__mispred_pc_o                    (alu_x__mispred_pc),                
    .alu_x__mispred_npc_o                   (alu_x__mispred_npc),               
    .ctrl_x__mem_kill_i                     (ctrl_x__mem_kill),                 
    .ctrl_x__wb_kill_i                      (ctrl_x__wb_kill),

    .bht_update_o                           (bht_update),
    .btb_update_o                           (btb_update),
    // =====================================
    // [csr regfile interface]
    .alu_csr__valid_o                       (alu_csr__valid ),   
    .alu_csr__cmd_o                         (alu_csr__cmd   ), 
    .alu_csr__wdata_o                       (alu_csr__wdata ),   
    .alu_csr__addr_o                        (alu_csr__addr  ),  
    .csr_alu__rdata_i                       (csr_alu__rdata ),   
    .alu_csr__ex_o                          (alu_csr__ex    ),   
    .alu_csr__pc_o                          (alu_csr__pc    ),
    .alu_csr__instr_o                       (alu_csr__instr ),   
    .alu_csr__write_fflags_o                (alu_csr__write_fflags),
    .alu_csr__dirty_fp_state_o              (alu_csr__dirty_fp_state),
    .alu_csr__fflags_o                      (alu_csr__fflags),

    .alu_csr__retire_en_o                   (alu_csr__retire_en),
    .alu_csr__retire_npc_o                  (alu_csr__retire_npc),
    .alu_csr__retire_is_jbr_o               (alu_csr__retire_is_jbr),
    .alu_csr__mispred_o                     (alu_csr__mispred      ),
    .alu_csr__dc_access_o                   (alu_csr__dc_access),
    .alu_csr__dc_miss_o                     (alu_csr__dc_miss  ),
                                             
    .alu_csr__mret_o                        (alu_csr__mret  ),  
    .alu_csr__sret_o                        (alu_csr__sret  ),  
    .alu_csr__dret_o                        (alu_csr__dret  ),  

    // =====================================
    // [to ppl_ctrl]
    .alu_csr__wfi_o                         (alu_csr__wfi_en),                
    .alu_ctrl__fencei_en_o                  (alu_ctrl__fencei_en),            
    .alu_ctrl__fence_en_o                   (alu_ctrl__fence_en),             
    .alu_ctrl__sfence_vma_o                 (alu_ctrl__sfence_vma),
    .alu_ctrl__ret_addr_match_o             (alu_ctrl__ret_addr_match),
    .alu_ctrl__mem_act_o                    (alu_ctrl__mem_act),              
    .alu_ctrl__wb_act_o                     (alu_ctrl__wb_act),               
    .alu_ctrl__wb_npc_o                     (alu_ctrl__wb_npc),
    // =====================================
    // [to ppl_dec]
    .dec_alu__ex0_avail_i                   (dec_alu__ex0_avail),             
    .dec_alu__ex0_act_i                     (dec_alu__ex0_act),             
    .dec_alu__instr_cls_i                   (dec_alu__instr_cls),             
    .dec_alu__stage_act_i                   (dec_alu__stage_act),             
    // .dec_alu__npc_i                         (dec_alu__npc),                   
    .dec_alu__ras_addr_i                    (dec_alu__ras_addr),                   
    .dec_alu__btb_addr_i                    (dec_alu__btb_addr),                   
    .dec_alu__npc_type_i                    (dec_alu__npc_type),                   
    .dec_alu__pc_i                          (dec_alu__pc),                    
    .dec_alu__instr_i                       (dec_alu__instr),                 
    .dec_alu__als_opcode_i                  (dec_alu__als_opcode),            
    .dec_alu__jbr_opcode_i                  (dec_alu__jbr_opcode),            
    .dec_alu__mem_opcode_i                  (dec_alu__mem_opcode),            
    .dec_alu__amo_opcode_i                  (dec_alu__amo_opcode),
    .dec_alu__sys_opcode_i                  (dec_alu__sys_opcode),            
    .dec_alu__sign_ext_i                    (dec_alu__sign_ext),              
    .dec_alu__csr_cmd_i                     (dec_alu__csr_cmd),               
    .dec_alu__csr_addr_i                    (dec_alu__csr_addr),              
    .dec_alu__csr_imm_sel_i                 (dec_alu__csr_imm_sel),           
    .dec_alu__rs1_idx_i                     (dec_alu__rs1_idx),               
    .dec_alu__rs1_data_i                    (dec_alu__rs1_data),              
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
    .dec_alu__waw_stall_i                   (dec_alu__waw_stall),
    .dec_alu__ex0_stall_i                   (dec_alu__ex0_stall),

    .alu_dec__tlb_miss_block_o              (alu_dec__tlb_miss_block),           
    .alu_dec__dc_rsp_block_o                (alu_dec__dc_rsp_block),

    .alu_dec__mem0_blk_en_o                 (alu_dec__mem0_blk_en),              
    .alu_dec__mem0_blk_idx_o                (alu_dec__mem0_blk_idx),             
    .alu_dec__mem0_blk_f_or_x_o             (alu_dec__mem0_blk_f_or_x),
    .alu_dec__mem1_blk_en_o                 (alu_dec__mem1_blk_en),              
    .alu_dec__mem1_blk_idx_o                (alu_dec__mem1_blk_idx),             
    .alu_dec__mem1_blk_f_or_x_o             (alu_dec__mem1_blk_f_or_x),
    .alu_dec__bp0_rdst_o                    (alu_dec__bp0_rdst),                
    .alu_dec__bp1_rdst_o                    (alu_dec__bp1_rdst),                
    .alu_dec__bp2_rdst_o                    (alu_dec__bp2_rdst),                
    .alu_dec__bp0_f_or_x_o                  (alu_dec__bp0_f_or_x),
    .alu_dec__bp1_f_or_x_o                  (alu_dec__bp1_f_or_x),  
    .alu_dec__bp2_f_or_x_o                  (alu_dec__bp2_f_or_x),  
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
    // [address translation request]
    .ppl_mmu__req_o                         (ppl_mmu__req     ),       
    .ppl_mmu__vaddr_o                       (ppl_mmu__vaddr   ),         
    .ppl_mmu__is_store_o                    (ppl_mmu__is_store),            
    .mmu_ppl__dtlb_hit_i                    (mmu_ppl__dtlb_hit),            
    .mmu_ppl__valid_i                       (mmu_ppl__valid   ),         
    .mmu_ppl__paddr_i                       (mmu_ppl__paddr   ),         
    .mmu_ppl__ex_i                          (mmu_ppl__ex      ),      
    // =====================================
    // [to LSU]
    .ppl_dmem__req_o                        (ppl_dmem__req     ),
    .dmem_ppl__rsp_i                        (dmem_ppl__rsp     ),
    .ppl_dmem__req_bits_o                   (ppl_dmem__req_bits),
    .dmem_ppl__rsp_bits_i                   (dmem_ppl__rsp_bits)
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
    .dec_mdu__npc_i                         (dec_mdu__npc),                      
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
    // [to csr]
    .mdu_csr__retire_en_o                   (mdu_csr__retire_en),
    .mdu_csr__retire_npc_o                  (mdu_csr__retire_npc),
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
    .clk_fpu_i                              (clk_fpu_i           ),
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
    .single_step_o                          (single_step),
                                             
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
    .alu_csr__retire_en_i                   (alu_csr__retire_en),
    .alu_csr__retire_npc_i                  (alu_csr__retire_npc),
    .mdu_csr__retire_en_i                   (mdu_csr__retire_en),
    .mdu_csr__retire_npc_i                  (mdu_csr__retire_npc),

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
                                             
    .perf_addr_o                            (perf_addr            ),// read/write address to performance counter module (up to 29 aux counters possible in riscv encoding.h)
    .perf_data_o                            (perf_wdata),         // write data to performance counter module
    .perf_data_i                            (perf_rdata),         // read data from performance counter module
    .perf_we_o                              (perf_we              )  
);

sy_ppl_perfcnt perf_cnt_inst(
    // =====================================
    // [clock & reset]
    // -- <clock>
    .clk_i                              (clk_i),                      
    .rst_i                              (rst_i),                      
    // =====================================
    // [from CSR regfile]
    .perf_addr_i                        (perf_addr),    // read/write address to performance counter module (up to 29 aux counters possible in riscv encoding.h)
    .perf_data_i                        (perf_wdata),    // read data from performance counter module
    .perf_data_o                        (perf_rdata),    // write data to performance counter module
    .perf_we_o                          (perf_we),
    // =====================================
    // [control signals]
    .alu_instr_retire_i                 (alu_csr__retire_en),
    .mdu_instr_retire_i                 (mdu_csr__retire_en),
    .jump_instr_i                       (alu_csr__retire_is_jbr),
    .mispred_i                          (alu_csr__mispred      ),
    .ic_access_i                        (fet_csr__ic_access),
    .ic_miss_i                          (fet_csr__ic_miss),
    .dc_access_i                        (alu_csr__dc_access),
    .dc_miss_i                          (alu_csr__dc_miss)
);

cva6_mmu #(
    .INSTR_TLB_ENTRIES      ( 8                     ),
    .DATA_TLB_ENTRIES       ( 8                     ) 
)mmu(
    .clk_i                                  (clk_i                  ), 
    .rst_ni                                 (rst_i                  ), 
    .flush_i                                (ctrl_x__if0_kill       ),  
    .exe_region_ex_en_i                     (exe_region_ex_en_i     ),
    .enable_translation_i                   (en_translation         ),               
    .en_ld_st_translation_i                 (en_ld_st_translation   ), // enable virtual memory translation for load/stores
                                             
    .ptw_instr_active_o                     (mmu_fet__ptw_walking_instr),
    .fet_req_i                              (fet_mmu__req           ),
    .fet_vaddr_i                            (fet_mmu__vaddr         ),
    .fet_itlb_hit_o                         (mmu_fet__itlb_hit      ),
    .fet_valid_o                            (mmu_fet__valid         ),
    .fet_paddr_o                            (mmu_fet__paddr         ),            
    .fet_exception_o                        (mmu_fet__ex            ),
                                             
    .misaligned_ex_i                        ('0                     ),          
    .lsu_req_i                              (ppl_mmu__req           ), // request address translation
    .lsu_vaddr_i                            (ppl_mmu__vaddr         ), // virtual address in
    .lsu_is_store_i                         (ppl_mmu__is_store      ), // the translation is requested by a store
                                             
    .lsu_dtlb_hit_o                         (mmu_ppl__dtlb_hit      ), // sent in the same cycle as the request if translation hits in the DTLB
                                             
    .lsu_valid_o                            (mmu_ppl__valid         ), // translation is valid
    .lsu_paddr_o                            (mmu_ppl__paddr         ), // translated address
    .lsu_exception_o                        (mmu_ppl__ex            ), // address translation threw an exception
                                             
    .priv_lvl_i                             (priv_lvl               ),     
    .ld_st_priv_lvl_i                       (ld_st_priv_lvl         ),           
    .sum_i                                  (sum                    ),
    .mxr_i                                  (mxr                    ),
                                             
    .satp_ppn_i                             (satp_ppn               ),     
    .asid_i                                 (asid                   ), 
    .flush_tlb_i                            (tlb_flush              ),      
                                             
    .itlb_miss_o                            (                       ),      
    .dtlb_miss_o                            (                       ),      

    .dmem_mmu__ctrl_idle_i                  (dcache_ctrl_idle  ),
    .mmu_dmem__req_o                        (mmu_dmem__req     ),
    .dmem_mmu__rsp_i                        (dmem_mmu__rsp     ),
    .mmu_dmem__req_bits_o                   (mmu_dmem__req_bits),
    .dmem_mmu__rsp_bits_i                   (dmem_mmu__rsp_bits)    
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
    .invalid_dcache_i                       (dcache_invalid),
    .dcache_ctrl_idle_o                     (dcache_ctrl_idle),
    .icache_ctrl_idle_o                     (icache_ctrl_idle),

    .fetch_icache__kill_i                   (fet_icache__kill),    
    .fetch_icache__req_i                    (fet_icache__req     ),
    .icache_fetch__rsp_o                    (icache_fet__rsp     ),
    .fetch_icache__req_bits_i               (fet_icache__req_bits),
    .icache_fetch__rsp_bits_o               (icache_fet__rsp_bits),


    .ppl_dmem__kill_i                       (ctrl_x__if0_kill),    
    .ppl_dmem__req_i                        (ppl_dmem__req     ),             
    .dmem_ppl__rsp_o                        (dmem_ppl__rsp     ),             
    .ppl_dmem__req_bits_i                   (ppl_dmem__req_bits),                  
    .dmem_ppl__rsp_bits_o                   (dmem_ppl__rsp_bits),                    
                                             
    .mmu_dmem__req_i                        (mmu_dmem__req     ),             
    .dmem_mmu__rsp_o                        (dmem_mmu__rsp     ),             
    .mmu_dmem__req_bits_i                   (mmu_dmem__req_bits),                  
    .dmem_mmu__rsp_bits_o                   (dmem_mmu__rsp_bits),                    
    // TL A
    .L1_tl_A_valid_o                        (L1_tl_A_valid_o), 
    .L1_tl_A_ready_i                        (L1_tl_A_ready_i), 
    .L1_tl_A_bits_o                         (L1_tl_A_bits_o ),
    // TL B
    .L1_tl_B_valid_i                        (L1_tl_B_valid_i), 
    .L1_tl_B_ready_o                        (L1_tl_B_ready_o), 
    .L1_tl_B_bits_i                         (L1_tl_B_bits_i ),
    // TL C
    .L1_tl_C_valid_o                        (L1_tl_C_valid_o), 
    .L1_tl_C_ready_i                        (L1_tl_C_ready_i), 
    .L1_tl_C_bits_o                         (L1_tl_C_bits_o ),
    // TL D
    .L1_tl_D_valid_i                        (L1_tl_D_valid_i), 
    .L1_tl_D_ready_o                        (L1_tl_D_ready_o), 
    .L1_tl_D_bits_i                         (L1_tl_D_bits_i ),
    // TL E
    .L1_tl_E_valid_o                        (L1_tl_E_valid_o), 
    .L1_tl_E_ready_i                        (L1_tl_E_ready_i), 
    .L1_tl_E_bits_o                         (L1_tl_E_bits_o )
);


//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule : sy_core
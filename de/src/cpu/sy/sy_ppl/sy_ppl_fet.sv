// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_fet.v
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
module sy_ppl_fet
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      
    // -- <reset>
    input   logic                           rst_i,                      
    input   logic                           halt_i,
    input   logic                           debug_mode_i,
    input   logic                           forbid_br_pred_i,

    output  logic                           fet_csr__ic_access_o,
    output  logic                           fet_csr__ic_miss_o,
    // =====================================
    // [schedule signals]
    input   logic                           dec_fet__ex0_accpt_i,
    //! If ALU module finds current instruction is branch or jump, and the prediction is missed, it should send correct
    //! NPC to FETCH module.
    input   logic                           alu_x__mispred_en_i,
    input   logic[AWTH-1:0]                 alu_x__mispred_pc_i,
    input   logic[AWTH-1:0]                 alu_x__mispred_npc_i,
    //! If CTRL module sends kill command, current instruction should be set as invalid.
    //! This kill instruction can disable all phases's signals except phase[BASE].
    input   logic                           ctrl_x__if0_kill_i,
    input   logic                           ctrl_x__id0_kill_i,
    // =====================================
    // [to ppl_ctrl]
    //! CTRL module can modify the NPC by these signals.
    input   logic                           ctrl_fet__set_en_i,
    input   logic[AWTH-1:0]                 ctrl_fet__set_npc_i,
    //! Current stage works only if CTRL module sends act signal to FETCH module. If act is zero, FETCH module stop
    //! getting instruction from ITCM.
    input   logic                           ctrl_fet__act_i,
    input   logic                           ctrl_fet__step_i,
    //！Status of IF0 and ID0 stages
    output  logic                           fet_ctrl__if0_act_o,
    output  logic                           fet_ctrl__id0_act_o,
    // =====================================
    // [From alu]
    input   logic                           flush_bp_i,
    input   bht_update_t                    bht_update_i,
    input   btb_update_t                    btb_update_i,
    // =====================================
    // [to ICACHE]
    output  logic                           fet_icache__req_o,
    output  logic                           fet_icache__kill_o,
    input   logic                           icache_fet__rsp_i,
    output  fetch_req_t                     fet_icache__req_bits_o,
    input   fetch_rsp_t                     icache_fet__rsp_bits_i,
    // =====================================
    // [to MMU]
    output  logic                           fet_mmu__req_o,
    output  logic[AWTH-1:0]                 fet_mmu__vaddr_o,
    input   logic                           mmu_fet__itlb_hit_i,
    input   logic                           mmu_fet__valid_i,
    input   logic[63:0]                     mmu_fet__paddr_i,
    input   exception_t                     mmu_fet__ex_i,
    input   logic                           mmu_fet__ptw_walking_instr_i,
    // =====================================
    // [to ppl_dec]
    //! FETCH module should send PC, NPC, instruction content, and stage status to the succedded module.
    output  logic                           fet_dec__id0_avail_o,
    output  logic                           fet_dec__id0_act_o,
    // output  logic[AWTH-1:0]                 fet_dec__id0_npc_o,
    output  logic[AWTH-1:0]                 fet_dec__id0_ras_addr_o,
    output  logic[AWTH-1:0]                 fet_dec__id0_btb_addr_o,
    output  npc_type_e                      fet_dec__id0_npc_type_o,
    output  logic[AWTH-1:0]                 fet_dec__id0_pc_o,
    output  logic[IWTH-1:0]                 fet_dec__id0_instr_o,
    output  logic                           fet_dec__id0_is_compressed_o,
    input   logic                           dec_fet__raw_hazard_i,
    //! If fetch PC is not algined with 4B, transfer this exception to stage EX0 to guarantee no branch misprediction.
    //modified by liushenghuan
    output exception_t                      fet_dec__id0_exception_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                           if0_stall;
    logic                           if0_kill;
    logic                           if0_act_unkilled;
    logic                           if0_act;
    logic                           if0_avail;
    logic[AWTH-1:0]                 if0_pc;
    logic                           if0_excp_en;
    ecode_e                         if0_excp_ecode;
    logic                           id0_stall;
    logic                           id0_kill;
    logic                           if0_accpt;
    logic                           if1_stall;
    logic                           if1_kill;
    logic                           if1_act_unkilled;
    logic                           if1_act;
    logic                           if1_avail;
    logic                           if1_accpt;
    logic                           if2_stall;
    logic                           if2_kill;
    logic                           if2_act_unkilled;
    logic                           if2_act;
    logic                           if2_avail;
    logic                           if2_accpt;

    logic                           ppl_imem__rvld;
    logic                           ppl_imem__rvld_dly;
    logic                           ppl_imem__rvld_dly1;
    logic                           imem_hit_dly1;
    logic[IWTH-1:0]                 imem_instr_dly1;
    // logic[IWTH-1:0]                 imem_instr;
    logic                           id0_act_unkilled;
    logic                           id0_act;
    logic                           id0_avail;
    logic                           id0_accpt;
    logic                           id0_accpt_dly1;
    logic[IWTH-1:0]                 id0_instr_dly1;
    logic[IWTH-1:0]                 id0_instr;
    logic                           id0_is_compressed;
    logic                           btb_upd_en;
    logic[AWTH-1:0]                 btb_upd_pc;
    logic[AWTH-1:0]                 btb_upd_npc;
    logic                           bp_btb_update_en;
    logic[AWTH-1:0]                 bp_btb_update_npc;
    logic[AWTH-1:0]                 ppl_imem_raddr;
    logic                           imem_ppl__hit;
    exception_t                     id0_exception;
    logic                           fetch_valid;
    logic [1:0]                     instr_valid;
    logic [1:0][AWTH-1:0]           instr_addr;
    logic [1:0][IWTH-1:0]           instr_data;                     
    logic                           buffer_is_not_full;
    logic                           buffer_instr_valid;
    logic [AWTH-1:0]                buffer_instr_pc;
    logic [AWTH-1:0]                buffer_instr_npc;
    logic [AWTH-1:0]                buffer_ras_addr;
    logic [AWTH-1:0]                buffer_btb_addr;
    npc_type_e                      buffer_npc_type;
    logic [IWTH-1:0]                buffer_instr;
    logic                           buffer_is_compressed;
    exception_t                     buffer_ex;
    logic                           if_flush;
    logic                           clr_instr_buffer;
    logic                           shamt;
    logic [IWTH-1:0]                fet_data;   
    logic                           bp_valid;
    logic[AWTH-1:0]                 bp_addr;
    logic[1:0]                      fet_valid;
    logic[1:0][AWTH-1:0]            fet_pc;
    logic[1:0][AWTH-1:0]            fet_npc;
    logic[1:0]                      fet_instr_is_c;
    logic[1:0][IWTH-1:0]            fet_instr;
    logic                           fet_ic_req_fire_dly;
    logic                           if0_tlb_miss_block;
    logic                           if0_ic_rsp_block;
    exception_t                     if0_exception;
    logic                           if0_mmu_req_block;
    logic                           icache_req_cancel;
    logic                           if1_first_cycle;
    logic [AWTH-1:0]                if1_pc;
    logic [AWTH-1:0]                if1_npc;
    exception_t                     if1_ex_from_if0;
    exception_t                     if1_ex;
    exception_t                     if1_ex_tmp;
    logic                           if1_access_ic;
    logic                           if1_itlb_hit;
    logic                           if1_access_ic_done;
    logic                           if1_icache_miss;
    logic                           if1_ic_hit_dly;
    logic[FETCH_WIDTH-1:0]          if1_rdata_tmp;
    logic[FETCH_WIDTH-1:0]          if1_fet_data;
    btb_pred_t                      if1_btb_pred;
    bht_pred_t                      if1_bht_pred;
    logic                           fetch_valid_if1;
    logic[AWTH-1:0]                 fetch_addr_if1;
    logic[IWTH-1:0]                 fetch_data_if1;                     
    logic[1:0]                      instr_buffer_push;
    logic [FETCH_WIDTH-1:0]         if2_fet_data;
    logic                           if2_ic_hit;
    logic [AWTH-1:0]                if2_pc;
    logic                           if2_ex_valid;
    logic                           instr_realign_valid;
    btb_pred_t                      if2_btb_pred;
    bht_pred_t                      if2_bht_pred;
    logic                           if2_bp_valid;
    npc_type_e                      if2_bp_npc_type;
    logic[AWTH-1:0]                 if2_bp_jump_addr;
    logic[AWTH-1:0]                 if2_bp_btb_addr;
    logic[AWTH-1:0]                 if2_bp_ras_addr;
    logic[1:0]                      if2_bp_fet_valid;  
    logic[1:0][AWTH-1:0]            if2_bp_fet_pc;  
    logic[1:0][AWTH-1:0]            if2_bp_fet_npc;
    logic[1:0][AWTH-1:0]            if2_btb_addr;
    logic[1:0][AWTH-1:0]            if2_ras_addr;
    npc_type_e[1:0]                 if2_npc_type;
    logic                           if3_bp_valid;
    logic[AWTH-1:0]                 if3_bp_addr;
    logic[AWTH-1:0]                 if3_bp_btb_addr;
    logic[AWTH-1:0]                 if3_bp_ras_addr;
    logic[AWTH-1:0]                 if3_bp_jump_addr;
    npc_type_e                      if3_npc_type;
//======================================================================================================================
// Fetch Stage 0 
//======================================================================================================================
// For each stage of pipeline, there exist follow critical signals, indicating the status of the stage.
// $stage.accpt$ indicates whether next stage allows the signal of current stage transferring to next stage.
// $stage.act_unkilled$ indicates the status of signal that generated from last cycle, having not go through the
//   kill signals.
// $stage.act$ expresses whether current stage contains an active signal, although it might be masked by stall.
//   It is generated by $stage.act = stage.act_unkilled && !stage.kill$.
// $stage.avail$ indicates whether current stage can send the active signal to next stage. It is generated by
//   $stage.avail = stage.act && !stage.stall && stage.accpt$.
//
// Beside, the stall signal of each stage indicates the data maintains there value at the next cycle.
// While the kill signal invalidate the active signal of each stage in current cycle.

assign if_flush = ctrl_x__id0_kill_i || alu_x__mispred_en_i;
assign clr_instr_buffer = ctrl_x__id0_kill_i || alu_x__mispred_en_i;
assign fet_icache__kill_o = if_flush || if3_bp_valid;
// assign fet_ctrl__if0_act_o = if0_act;
assign fet_ctrl__if0_act_o = if0_avail;
//! -----
//! [Phase: IF0]
assign if0_stall = if0_tlb_miss_block || if0_ic_rsp_block || if0_mmu_req_block;
// assign if0_stall = if0_tlb_miss_block || if0_ic_rsp_block;
assign if0_kill = ctrl_x__if0_kill_i || alu_x__mispred_en_i || !ctrl_fet__act_i || if3_bp_valid;

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        if0_act_unkilled <= `TCQ 1'b0;
    end else begin
        if0_act_unkilled <= `TCQ if0_accpt ? 1'b1 : if0_act;
    end
end

assign if0_act = if0_act_unkilled && !if0_kill;
assign if0_avail = if0_act && !if0_stall && if1_accpt;
assign if0_accpt = !if0_act || if0_avail;

// PC generate
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        if0_pc <= `TCQ {AWTH{1'b0}};
    end else begin
        if (ctrl_fet__set_en_i) begin
            if0_pc <= `TCQ ctrl_fet__set_npc_i;
        end else if (alu_x__mispred_en_i) begin
            if0_pc <= `TCQ alu_x__mispred_npc_i;
        end else if (if3_bp_valid) begin
            if0_pc <= `TCQ if3_bp_addr;
        end else if (if0_avail) begin
            if0_pc <= `TCQ {if0_pc[AWTH-1:2],2'b0} + 4;              
        end else begin
            if0_pc <= `TCQ if0_pc;
        end
    end
end

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        if0_mmu_req_block <= `TCQ 1'b0;
    end else begin
        if (if0_kill && mmu_fet__ptw_walking_instr_i) begin
            if0_mmu_req_block <= `TCQ 1'b1;           
        end else if (if0_kill && !mmu_fet__ptw_walking_instr_i) begin
            if0_mmu_req_block <= `TCQ 1'b0;
        end else if (!mmu_fet__ptw_walking_instr_i) begin
            if0_mmu_req_block <= `TCQ 1'b0;
        end
    end
end

// assign fet_mmu__req_o = ctrl_fet__act_i && if0_act && !if0_mmu_req_block;
// assign fet_mmu__req_o   = fet_icache__req_o && icache_fet__rsp_i && !(mmu_fet__valid_i && mmu_fet__ex_i.valid);
assign fet_mmu__req_o   = fet_icache__req_o && !if0_mmu_req_block && !(mmu_fet__valid_i && mmu_fet__ex_i.valid);
assign fet_mmu__vaddr_o = {if0_pc[AWTH-1:2],2'b0}; // 4B aligned

// if itlb is miss, wait until ptw is done or exception is happen
assign if0_tlb_miss_block = fet_mmu__req_o && !mmu_fet__itlb_hit_i && !(mmu_fet__valid_i && mmu_fet__ex_i.valid);
assign if0_ic_rsp_block   = fet_icache__req_o && !icache_fet__rsp_i && !(mmu_fet__valid_i && mmu_fet__ex_i.valid);

assign if0_exception.cause = mmu_fet__ex_i.cause;
assign if0_exception.tval  = mmu_fet__ex_i.tval;
// assign if0_exception.valid = mmu_fet__ex_i.valid && mmu_fet__valid_i;
assign if0_exception.valid = mmu_fet__ex_i.valid;

// interface with icache
assign fet_icache__req_o    = ctrl_fet__act_i && if0_act;
assign fet_icache__req_bits_o.addr_inx = if0_pc[ICACHE_TAG_LSB-1:0];
assign fet_icache__req_bits_o.addr_tag = mmu_fet__paddr_i[ICACHE_TAG_MSB-1:ICACHE_TAG_LSB];

assign fet_icache__req_bits_o.kill     = if1_ex.valid && if1_first_cycle || icache_req_cancel; 

always_ff @ (posedge clk_i) begin
    // dmem_ppl_req_cancel <= ppl_dmem__req_o && dmem_ppl__rsp_i && dec_alu__ex0_stall_i;
    // icache_req_cancel <= fet_icache__req_o && icache_fet__rsp_i && (!if0_avail || mmu_fet__ex_i.valid && mmu_fet__valid_i);
    icache_req_cancel <= fet_icache__req_o && icache_fet__rsp_i && !if0_avail; 
end

//======================================================================================================================
// Fetch Stage 1 
//======================================================================================================================
assign if1_stall = if1_icache_miss; 
assign if1_kill = ctrl_x__if0_kill_i || alu_x__mispred_en_i || if3_bp_valid;

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        if1_act_unkilled <= `TCQ 1'b0;
    end else begin
        if1_act_unkilled <= `TCQ if1_accpt ? if0_avail : if1_act;
    end
end

assign if1_act = if1_act_unkilled && !if1_kill;
assign if1_avail = if1_act && !if1_stall && if2_accpt;
assign if1_accpt = !if1_act || if1_avail;

// icache access dly
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        if1_first_cycle <= `TCQ 1'b0;
    end else begin
        if (if0_avail) begin
            if1_first_cycle <= `TCQ 1'b1;
        end else begin
            if1_first_cycle <= `TCQ 1'b0;
        end
    end
end

always_ff @ (posedge clk_i) begin
    fet_csr__ic_access_o    <= `TCQ if1_first_cycle;
    fet_csr__ic_miss_o      <= `TCQ if1_first_cycle && if1_icache_miss;
end

always_ff @(posedge clk_i) begin
    if (if0_avail) begin
        if1_pc  <= `TCQ if0_pc;
        // if1_npc <= `TCQ if0_npc;
        if1_ex_from_if0  <= `TCQ if0_exception;
        if1_access_ic <= `TCQ fet_icache__req_o && icache_fet__rsp_i;
        if1_itlb_hit  <= `TCQ mmu_fet__itlb_hit_i;
    end
end
// exception at if1 stage
always_comb begin: gen_if_ex
    if1_ex = if1_ex_tmp;
    // if (if1_ex_from_if0.valid) begin
    //     if1_ex = if1_ex_from_if0;
    // end else if(mmu_fet__ex_i.valid && if1_first_cycle) begin
    //     if1_ex = mmu_fet__ex_i;
    // end
    if (if1_first_cycle && if1_itlb_hit && mmu_fet__ex_i.valid && mmu_fet__valid_i) begin
        if1_ex = mmu_fet__ex_i;
    end else if (if1_first_cycle && !if1_itlb_hit && if1_ex_from_if0.valid) begin
        if1_ex = if1_ex_from_if0;
    end
end
// assign if1_ex = if1_ex_from_if0;

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        if1_ex_tmp <= `TCQ exception_t'(0);
    end else begin
        if (if1_accpt) begin
            if1_ex_tmp <= `TCQ exception_t'(0);
        end else begin
            if1_ex_tmp <= `TCQ if1_ex;
        end
    end
end

// when cache hit, if1 stage might be stall because instr buffer is full
// beacuse cache hit only last for one clock cycle, we must save cache hit info(including read data)   
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        if1_access_ic_done <= `TCQ 1'b0;
    end else begin
        if (if0_avail) begin
            if1_access_ic_done <= `TCQ 1'b0;
        end else if (icache_fet__rsp_bits_i.valid) begin
            if1_access_ic_done <= `TCQ 1'b1;
        end
    end
end
assign if1_icache_miss = !icache_fet__rsp_bits_i.valid && !if1_access_ic_done && !if1_ex.valid;

always_ff @(posedge clk_i) begin
    if1_ic_hit_dly <= `TCQ icache_fet__rsp_bits_i.valid;
end

assign shamt = if1_pc[1];
assign fet_data = icache_fet__rsp_bits_i.data >> {shamt,4'b0};
// read data from I cache
always_ff @(posedge clk_i) begin
    if(`DFF_IS_R(rst_i)) begin
        if1_rdata_tmp <= `TCQ FETCH_WIDTH'(0);
    end else begin 
        if(icache_fet__rsp_bits_i.valid) begin
            if1_rdata_tmp <= `TCQ fet_data;
        end else begin
            if1_rdata_tmp <= `TCQ if1_rdata_tmp;
        end
    end
end
assign if1_fet_data = icache_fet__rsp_bits_i.valid ? fet_data : if1_rdata_tmp;

// BTB is used to predict the next PC 
// Enable BTB at if1 Stage, and BTB entry can be used at if2 stage 
sy_ppl_btb  #(
    .BTB_ENTRIES    (16)
) btb_inst(
    // =====================================
    // [clock & reset]
    .clk_i          (clk_i),           
    .rst_i          (rst_i),          
    .flush_i        (flush_bp_i),         
    // =====================================
    // [Virtual address from fronted]
    .vaddr_i        (if1_pc),           
    // =====================================
    // [Update when retire]
    .btb_update_i   (btb_update_i),    
    // =====================================
    // [BTB prediction]
    .btb_pred_o     (if1_btb_pred)
);
// BHT is used to predict jump or not jump
// Enable BHT at if1 Stage, and BHT entry can be used at if2 stage 
sy_ppl_bht #(
    .BHT_ENTRIES (512)
) bht_inst(
    // =====================================
    // [clock & reset & flush]
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .flush_i        (flush_bp_i),
    // =====================================
    // [Virtual address from fronted]
    .vaddr_i        (if1_pc),
    // =====================================
    // [Update when retire]
    .bht_update_i   (bht_update_i),
    // =====================================
    // [BHT prediction]
    .bht_pred_o     (if1_bht_pred)
);
//======================================================================================================================
// Fetch Stage 2 
//======================================================================================================================
assign if2_stall = 1'b0;
assign if2_kill = if_flush || if3_bp_valid;

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        if2_act_unkilled <= `TCQ 1'b0;
    end else begin
        // if1_act_unkilled <= `TCQ if1_accpt ? if0_avail : if1_act;
        if2_act_unkilled <= `TCQ if2_accpt ? if1_avail : if2_act;
    end
end

assign if2_act = if2_act_unkilled && !if2_kill;
assign if2_avail = if2_act && !if2_stall && buffer_is_not_full;
assign if2_accpt = !if2_act || if2_avail;

always_ff @(posedge clk_i) begin
    if(if1_avail) begin
        if2_ex_valid    <= `TCQ if1_ex.valid;
        if2_ic_hit      <= `TCQ icache_fet__rsp_bits_i.valid;
        if2_pc          <= `TCQ if1_pc;
        if2_fet_data    <= `TCQ if1_fet_data;
        if2_btb_pred    <= `TCQ if1_btb_pred;
        if2_bht_pred    <= `TCQ if1_bht_pred;
    end 
end
// assign if2_fet_data = if2_ic_hit ? icache_fet__rsp_bits_i.data : if1_rdata_tmp;
// instr realign
assign instr_realign_valid = if2_act && buffer_is_not_full;
sy_ppl_instr_realign instr_align_inst(
    .clk_i                         (clk_i),  
    .rst_ni                        (rst_i),   
    .flush_i                       (if_flush || if3_bp_valid),    
    .valid_i                       (instr_realign_valid),    
    .serving_unaligned_o           (),                 // we have an unaligned instruction in [0]
    .address_i                     (if2_pc),      
    .data_i                        (if2_fet_data),   
    .valid_o                       (instr_valid),    
    .addr_o                        (instr_addr),   
    .instr_o                       (instr_data) 
);
assign fet_valid = instr_valid & {~ctrl_fet__step_i,1'b1};

// branch prediction based on BTB and BHT and instruction
sy_ppl_br_pred br_pred_inst(
    // =====================================
    // [clock & reset & flush]
    .clk_i          (clk_i),                      
    .rst_i          (rst_i),                      
    .flush_i        (flush_bp_i),
    .debug_mode_i   (debug_mode_i),
    .forbid_br_pred_i (forbid_br_pred_i),
    // =====================================
    // [From fronted]
    .instr_vld_i    (fet_valid),
    .instr_i        (instr_data),
    .vaddr_i        (instr_addr),

    .btb_pred_i     (if2_btb_pred),
    .bht_pred_i     (if2_bht_pred),
    // =====================================
    // [to fronted]
    .bp_vld_o       (if2_bp_valid),   
    .npc_type_o     (if2_bp_npc_type),
    .jump_addr_o    (if2_bp_jump_addr),
    .btb_addr_o     (if2_bp_btb_addr),
    .ras_addr_o     (if2_bp_ras_addr),
    // =====================================
    // [to Instr Buffer]
    .fet_valid_o    (if2_bp_fet_valid),   
    .fet_npc_type_o (if2_npc_type),
    .fet_pc_o       (if2_bp_fet_pc)   
);
// delay one cycle for timing
always_ff @(posedge clk_i) begin
    if3_bp_valid <= `TCQ if2_bp_valid;
    if3_bp_ras_addr  <= `TCQ if2_bp_ras_addr;
    if3_bp_btb_addr  <= `TCQ if2_bp_btb_addr;
    if3_bp_jump_addr  <= `TCQ if2_bp_jump_addr;
    if3_npc_type      <= `TCQ if2_bp_npc_type;
end

always_comb begin
    if3_bp_addr = if3_bp_jump_addr;
    unique case(if3_npc_type) 
        RAS_ADDR: begin
            if3_bp_addr = if3_bp_ras_addr;
        end
        BTB_ADDR: begin
            if3_bp_addr = if3_bp_btb_addr;
        end
        default:;
    endcase
end

// push instr to buffer
assign instr_buffer_push = if2_bp_fet_valid & {if2_avail,if2_avail};
sy_ppl_instr_buffer u_instr_buffer(
    .clk_i                          (clk_i),  
    .rst_ni                         (rst_i),   
    .flush_i                        (clr_instr_buffer),    
    .fet_valid_i                    (instr_buffer_push),        
    .fet_pc_i                       (if2_bp_fet_pc),       
    // .fet_npc_i                      (if2_bp_fet_npc),       
    .fet_btb_addr_i                 ({if2_bp_btb_addr,if2_bp_btb_addr}),       
    .fet_ras_addr_i                 ({if2_bp_ras_addr,if2_bp_ras_addr}),       
    .fet_npc_type_i                 (if2_npc_type),       
    .fet_instr_i                    (instr_data),        
    .fet_ex_i                       (if2_ex_valid),      
    .ready_o                        (buffer_is_not_full),    
    .dec_ready_i                    (id0_accpt),        
    .dec_valid_o                    (buffer_instr_valid),        
    .dec_pc_o                       (buffer_instr_pc),     
    // .dec_npc_o                      (buffer_instr_npc),      
    .dec_ras_addr_o                 (buffer_ras_addr),      
    .dec_btb_addr_o                 (buffer_btb_addr),      
    .dec_npc_type_o                 (buffer_npc_type),      
    .dec_instr_o                    (buffer_instr),        
    .dec_is_compressed_o            (buffer_is_compressed),
    .dec_ex_o                       (buffer_ex)                 
);
//! -----
//! [Phase: ID0]
assign id0_stall = dec_fet__raw_hazard_i || halt_i;
assign id0_kill = ctrl_x__id0_kill_i || alu_x__mispred_en_i;

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        id0_act_unkilled <= `TCQ 1'b0;
    end else begin
        id0_act_unkilled <= `TCQ id0_accpt ? buffer_instr_valid : id0_act;
    end
end
assign id0_act = id0_act_unkilled && !id0_kill;
assign id0_avail = id0_act && !id0_stall && dec_fet__ex0_accpt_i;
assign id0_accpt = !id0_act || id0_avail;

assign fet_ctrl__id0_act_o = id0_act;
assign fet_dec__id0_act_o = id0_act;
assign fet_dec__id0_avail_o = id0_avail;

// exception in id0 stage
always_ff @(posedge clk_i) begin
    if(id0_accpt) begin
        // fet_dec__id0_npc_o <= `TCQ buffer_instr_npc;
        fet_dec__id0_ras_addr_o <= `TCQ buffer_ras_addr;
        fet_dec__id0_btb_addr_o <= `TCQ buffer_btb_addr;
        fet_dec__id0_npc_type_o <= `TCQ buffer_npc_type;
        fet_dec__id0_pc_o <= `TCQ buffer_instr_pc;
        id0_exception <= `TCQ buffer_ex;
        // id0_instr <= buffer_instr;
        id0_is_compressed <= `TCQ buffer_is_compressed;
    end
end

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        id0_instr <= `TCQ 1'b0;
    end else begin
        id0_instr <= `TCQ id0_accpt && buffer_instr_valid ? buffer_instr : id0_instr;
    end
end

assign fet_dec__id0_exception_o = id0_exception;

always_ff @(posedge clk_i) begin
    id0_accpt_dly1 <= `TCQ id0_accpt;
    id0_instr_dly1 <= `TCQ fet_dec__id0_instr_o;
end
// assign fet_dec__id0_instr_o = id0_accpt_dly1 ? id0_instr : id0_instr_dly1;
assign fet_dec__id0_instr_o = id0_instr;
assign fet_dec__id0_is_compressed_o = id0_is_compressed;
// assign bp_btb_update_en = 1'b0;
// assign bp_btb_update_npc = AWTH'(0);

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
// (* mark_debug = "true" *) logic         prb_ppl_id_act;
// (* mark_debug = "true" *) logic[63:0]   prb_ppl_id_pc;
// (* mark_debug = "true" *) logic[31:0]   prb_ppl_id_instr;
// (* mark_debug = "true" *) logic         prb_ppl_id_ex_valid;
// (* mark_debug = "true" *) logic[3:0]    prb_ppl_id_ex_cause;
// (* mark_debug = "true" *) logic[63:0]   prb_ppl_id_ex_tval;

// assign prb_ppl_id_act   = id0_act;
// assign prb_ppl_id_pc    = fet_dec__id0_pc_o;
// assign prb_ppl_id_instr = fet_dec__id0_instr_o;
// assign prb_ppl_id_ex_valid = id0_exception.valid;
// assign prb_ppl_id_ex_cause = id0_exception.cause[3:0];
// assign prb_ppl_id_ex_tval  = id0_exception.tval;

// (* mark_debug = "true" *) logic         prb_if0_act;
// (* mark_debug = "true" *) logic         prb_if1_act;
// (* mark_debug = "true" *) logic         prb_if2_act;

// (* mark_debug = "true" *) logic         prb_fet_mmu_valid;
// (* mark_debug = "true" *) logic[63:0]   prb_fet_mmu_vaddr;
// (* mark_debug = "true" *) logic         prb_mmu_fet_hit;
// (* mark_debug = "true" *) logic[63:0]   prb_mmu_fet_paddr;
// (* mark_debug = "true" *) logic         prb_mmu_fet_ex;
// (* mark_debug = "true" *) logic         prb_mmu_fet_valid;

// (* mark_debug = "true" *) logic         prb_fet_ic_req;
// (* mark_debug = "true" *) logic         prb_fet_ic_rsp;
// (* mark_debug = "true" *) logic         prb_ic_fet_valid;
// (* mark_debug = "true" *) logic[31:0]   prb_ic_fet_data;

// assign prb_if0_act = if0_act;
// assign prb_if1_act = if1_act;
// assign prb_if2_act = if2_act;

// assign prb_fet_mmu_valid    = fet_mmu__req_o;
// assign prb_fet_mmu_vaddr    = fet_mmu__vaddr_o;
// assign prb_mmu_fet_hit      = mmu_fet__itlb_hit_i;
// assign prb_mmu_fet_paddr    = mmu_fet__paddr_i;
// assign prb_mmu_fet_ex       = mmu_fet__ex_i.valid;
// assign prb_mmu_fet_valid    = mmu_fet__valid_i;

// assign prb_fet_ic_req       = fet_icache__req_o;
// assign prb_fet_ic_rsp       = icache_fet__rsp_i;
// assign prb_ic_fet_valid     = icache_fet__rsp_bits_i.valid;
// assign prb_ic_fet_data      = icache_fet__rsp_bits_i.data;
     

endmodule : sy_ppl_fet

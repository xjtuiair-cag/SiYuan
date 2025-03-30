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
    //！Status of IF0 and ID0 stages
    output  logic                           fet_ctrl__if0_act_o,
    output  logic                           fet_ctrl__id0_act_o,
    // =====================================
    // [to IMEM]
    output  fetch_req_t                     fet_icache__dreq_o,
    input   fetch_rsp_t                     icache_fet__drsp_i,
    // =====================================
    // [to ppl_dec]
    //! FETCH module should send PC, NPC, instruction content, and stage status to the succedded module.
    output  logic                           fet_dec__id0_avail_o,
    output  logic                           fet_dec__id0_act_o,
    output  logic[AWTH-1:0]                 fet_dec__id0_npc_o,
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
    (* max_fanout = 8 *) logic      if0_avail;
    logic[AWTH-1:0]                 if0_pc;
    logic                           if0_excp_en;
    ecode_e                         if0_excp_ecode;
    logic                           id0_stall;
    logic                           id0_kill;
    logic                           if0_accpt;
    logic                           ppl_imem__rvld;
    logic                           ppl_imem__rvld_dly;
    logic                           ppl_imem__rvld_dly1;
    logic                           imem_hit_dly1;
    logic[IWTH-1:0]                 imem_instr_dly1;
    logic[IWTH-1:0]                 imem_instr;
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
    exception_t                     if0_exception;
    exception_t                     id0_exception;
    logic                           fetch_valid;
    logic [1:0]                     instr_valid;
    logic [1:0][AWTH-1:0]           instr_addr;
    logic [1:0][IWTH-1:0]           instr_data;                     
    logic                           buffer_is_not_full;
    logic                           buffer_instr_valid;
    logic [AWTH-1:0]                buffer_instr_pc;
    logic [AWTH-1:0]                buffer_instr_npc;
    logic [IWTH-1:0]                buffer_instr;
    logic                           buffer_is_compressed;
    exception_t                     buffer_ex;
    logic                           flush_buffer;
    logic                           shamt;
    logic [IWTH-1:0]                fet_data;   
//======================================================================================================================
// Instance
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

//! -----
//! [Phase: IF0]
assign if0_stall = 1'b0;
assign if0_kill = ctrl_x__if0_kill_i || alu_x__mispred_en_i || (!imem_ppl__hit && ppl_imem__rvld_dly) || (!buffer_is_not_full);

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        if0_act_unkilled <= `TCQ 1'b0;
    end else begin
        if0_act_unkilled <= `TCQ if0_accpt ? ppl_imem__rvld : if0_act;
    end
end

assign if0_act = if0_act_unkilled && !if0_kill;
assign if0_avail = if0_act && !if0_stall && buffer_is_not_full;
assign if0_accpt = !if0_act || if0_avail;

assign fet_ctrl__if0_act_o = if0_act || !icache_fet__drsp_i.ready;

assign ppl_imem__rvld = ctrl_fet__act_i && if0_accpt && buffer_is_not_full;

// to icache
assign fet_icache__dreq_o.req = ctrl_fet__act_i && if0_accpt && icache_fet__drsp_i.ready && buffer_is_not_full;
assign fet_icache__dreq_o.vaddr = ppl_imem_raddr; 
assign fet_icache__dreq_o.kill = ctrl_x__if0_kill_i || alu_x__mispred_en_i;
assign imem_ppl__hit = icache_fet__drsp_i.valid;

always_comb begin
    if(ctrl_fet__set_en_i) begin
        ppl_imem_raddr = ctrl_fet__set_npc_i;
    end else if(alu_x__mispred_en_i) begin
        ppl_imem_raddr = alu_x__mispred_npc_i;
    // end else if(!ppl_imem__rvld_o || !if0_act) begin
    end else if(!if0_act) begin
        ppl_imem_raddr = if0_pc;
    end else if(bp_btb_update_en) begin
        ppl_imem_raddr = bp_btb_update_npc;
    end else begin
        ppl_imem_raddr = {if0_pc[AWTH-1:2],2'b0} + 4;
    end
end

always_ff @(posedge clk_i) begin
    if(if0_accpt) begin
        if0_pc <= `TCQ ppl_imem_raddr;
    end
end

// analyze WB bus hazard at EX0 phase
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        ppl_imem__rvld_dly <= `TCQ 1'b0;
    end else begin
        ppl_imem__rvld_dly <= `TCQ ppl_imem__rvld;
    end
end

always_comb begin: gen_if0_exception
    if0_exception = icache_fet__drsp_i.ex;

    if(ctrl_x__if0_kill_i || alu_x__mispred_en_i) begin
        if0_exception = '0;
    end else if(if0_pc[1:0] != 2'h0) begin
        if0_exception = {INSTR_ADDR_MISALIGNED, if0_pc, 1'b1}; 
    end 
end

always_ff @(posedge clk_i) begin
    if(`DFF_IS_R(rst_i)) begin
        imem_instr <= '0;
    end else begin
        if(imem_ppl__hit) begin
            imem_instr <= `TCQ icache_fet__drsp_i.data;
        end else begin
            imem_instr <= `TCQ imem_instr;
        end
    end
end

assign fetch_valid = ppl_imem__rvld_dly && imem_ppl__hit && if0_avail;
assign flush_buffer = ctrl_x__id0_kill_i || alu_x__mispred_en_i;
assign shamt = if0_pc[1];
assign fet_data = icache_fet__drsp_i.data >> {shamt,4'b0};

sy_ppl_instr_realign u_instr_align(
    .clk_i                         (clk_i),  
    .rst_ni                        (rst_i),   
    .flush_i                       (flush_buffer),    
    .valid_i                       (fetch_valid),    
    .serving_unaligned_o           (),                 // we have an unaligned instruction in [0]
    .address_i                     (if0_pc),      
    .data_i                        (fet_data),   
    .valid_o                       (instr_valid),    
    .addr_o                        (instr_addr),   
    .instr_o                       (instr_data) 
);

sy_ppl_instr_buffer u_instr_buffer(
    .clk_i                          (clk_i),  
    .rst_ni                         (rst_i),   
    .flush_i                        (flush_buffer),    
    .fet_valid_i                    (instr_valid),        
    .fet_addr_i                     (instr_addr),       
    .fet_instr_i                    (instr_data),        
    .fet_ex_i                       (icache_fet__drsp_i.ex.valid),      
    .ready_o                        (buffer_is_not_full),    
    .dec_ready_i                    (id0_accpt),        
    .dec_valid_o                    (buffer_instr_valid),        
    .dec_pc_o                       (buffer_instr_pc),     
    .dec_npc_o                      (buffer_instr_npc),      
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
        fet_dec__id0_npc_o <= `TCQ buffer_instr_npc;
        fet_dec__id0_pc_o <= `TCQ buffer_instr_pc;
        id0_exception <= buffer_ex;
        id0_instr <= buffer_instr;
        id0_is_compressed <= buffer_is_compressed;
    end
end

assign fet_dec__id0_exception_o = id0_exception;

always_ff @(posedge clk_i) begin
    id0_accpt_dly1 <= `TCQ id0_accpt;
    id0_instr_dly1 <= `TCQ fet_dec__id0_instr_o;
end
assign fet_dec__id0_instr_o = id0_accpt_dly1 ? id0_instr : id0_instr_dly1;
assign fet_dec__id0_is_compressed_o = id0_is_compressed;
assign bp_btb_update_en = 1'b0;
assign bp_btb_update_npc = AWTH'(0);

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_fet

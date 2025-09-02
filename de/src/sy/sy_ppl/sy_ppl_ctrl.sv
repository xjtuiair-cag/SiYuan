// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_ctrl.v
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

module sy_ppl_ctrl
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      
    // -- <reset>
    input   logic                           rst_i,                      
    output  logic                           flush_bp_o,
    // =====================================
    // [ctrl & status]
    input   logic[AWTH-1:0]                 boot_addr_i,
    input   logic                           ctrl_reset_i,
    input   logic                           ctrl_halt_i,
    output  logic                           stat_sleep_o,
    // =====================================
    // [to IMEM]
    output  logic                           ppl_tlb_flush_o,
    output  logic                           ppl_icache_flush_o,
    output  logic                           ppl_dcache_flush_o,
    input   logic                           ppl_dcache_flush_ack_i,
    // =====================================
    // [block signals]
    //! If CTRL module sends kill command, current instruction should be set as invalid.
    //! This kill instruction can disable all phases's signals except fetching instruction.
    output  logic                           ctrl_x__if0_kill_o,
    output  logic                           ctrl_x__id0_kill_o,
    output  logic                           ctrl_x__ex0_kill_o,
    output  logic                           ctrl_x__mem_kill_o,
    output  logic                           ctrl_x__wb_kill_o,
    // =====================================
    // [to ppl_fet]
    //! CTRL module can modify the NPC by these signals.
    output  logic                           ctrl_fet__set_en_o,
    output  logic[AWTH-1:0]                 ctrl_fet__set_npc_o,
    //! Current stage works only if CTRL module sends act signal to FETCH module. If act is zero, FETCH module stop
    //! getting instruction from ITCM.
    output  logic                           ctrl_fet__act_o,
    //Status of FET module
    input   logic                           fet_ctrl__if0_act_i,
    input   logic                           fet_ctrl__id0_act_i,
    input   logic                           dec_ctrl__ex0_act_i,
    input   logic                           alu_ctrl__mem_act_i,
    input   logic                           alu_ctrl__wb_act_i,
    // =====================================
    //! If current insruction is WFI, send sleep command to CTRL module.
    // input   logic                           alu_ctrl__wfi_en_i,
    //! If current instruction is Fence.I, send clear I$ and continue launch next instruction cmmand.
    input   logic                           alu_ctrl__fencei_en_i,
    input   logic                           alu_ctrl__fence_en_i,
    //! If current instruction is MRET, send this command to CTRL module.
    input   logic                           alu_ctrl__sfence_vma_i,
    // [to ppl_mdu]
    // status of FUs
    input   logic                           mdu_ctrl__mul_act_i,
    input   logic                           mdu_ctrl__div_act_i,
    // =====================================
    // [from ppl_wb]
    input   logic[63:0]                     alu_ctrl__wb_npc_i,
    // =====================================
    // [from ppl_csr]
    input   logic                           csr_ctrl__eret_i,
    input   logic[63:0]                     csr_ctrl__epc_i,
    input   logic[63:0]                     csr_ctrl__trap_vec_i,
    // input   logic                           csr_ctrl__wfi_wakeup_i,
    input   logic                           csr_ctrl__set_debug_i,
    input   logic                           csr_ctrl__ex_valid_i,
    input   logic                           csr_ctrl__debug_mode_i,
    input   logic                           csr_ctrl__flush_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================

typedef enum logic[4:0] {
    FSM_RESET = 0,
    FSM_INIT_CUR_PC = 1,
    FSM_PROC_EVENT = 2,
    FSM_RUN = 3,
    FSM_PAUSE = 4,
    FSM_INVALID_IC = 5,
    FSM_SLEEP = 6,
    FSM_FLUSH_TLB = 7,
    FSM_INVALID_DC = 8
} ctrl_fsm_e;

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================

logic                               ppl_idle;
logic                               sys_call;
ctrl_fsm_e                          next_state;
logic[AWTH-1:0]                     cur_pc;
logic                               ctrl_debug_req;
logic                               ctrl_excp_req;
logic                               ctrl_xret_req;
logic                               ctrl_sleep_req;
logic                               ctrl_invld_ic_req;
logic                               ctrl_invld_dc_req;
logic                               ctrl_flush_tlb_req;
logic                               set_npc_en;
ctrl_fsm_e                          cur_state;
logic[AWTH-1:0]                     cur_pc_q;
logic                               ctrl_debug_req_q;
logic                               ctrl_excp_req_q;
logic                               ctrl_xret_req_q;
logic                               ctrl_sleep_req_q;
logic                               ctrl_invld_ic_req_q;
logic                               ctrl_invld_dc_req_q;
logic                               ctrl_flush_tlb_req_q;
logic                               flush_ppl;

//======================================================================================================================
// Instance
//======================================================================================================================

// -----------------------------------------------------------------------------
// The status of swift core
assign ppl_idle = !fet_ctrl__if0_act_i && !fet_ctrl__id0_act_i && !dec_ctrl__ex0_act_i && !alu_ctrl__mem_act_i
                && !alu_ctrl__wb_act_i && !mdu_ctrl__mul_act_i && !mdu_ctrl__div_act_i;

//======================================================================================================================
// FSM logic 
//======================================================================================================================
always_comb begin
    // default
    flush_bp_o = 1'b0;
    // FSM of control module
    next_state = cur_state;
    // The privilege, mode, and current PC of Sy core
    cur_pc = cur_pc_q;
    // output signals
    // -- Drive the pipelien to work
    ctrl_fet__act_o = 1'b0;
    // -- Sy core status and information signals
    stat_sleep_o = 1'b0;
    ppl_icache_flush_o = 1'b0;
    ppl_dcache_flush_o = 1'b0;
    ppl_tlb_flush_o = 1'b0;
    // inner variables
    ctrl_excp_req = ctrl_excp_req_q;
    ctrl_xret_req = ctrl_xret_req_q;
    ctrl_sleep_req = ctrl_sleep_req_q;
    ctrl_invld_ic_req = ctrl_invld_ic_req_q;
    ctrl_invld_dc_req = ctrl_invld_dc_req_q;
    ctrl_flush_tlb_req = ctrl_flush_tlb_req_q;
    ctrl_debug_req = ctrl_debug_req_q;
    set_npc_en = 1'b0;

    // generate the next PC
    if(csr_ctrl__ex_valid_i) begin
        cur_pc = csr_ctrl__trap_vec_i;
        ctrl_excp_req = 1'b1;
    end else if(csr_ctrl__eret_i) begin
        cur_pc = csr_ctrl__epc_i;
        ctrl_xret_req = 1'b1;
    end else if(csr_ctrl__set_debug_i) begin
        ctrl_debug_req = 1'b1;
        cur_pc = SyDefaultConfig.DmBaseAddress + dbg_pkg::HaltAddress;
    end
    // // system instr
    // if(alu_ctrl__wfi_en_i && !csr_ctrl__debug_mode_i && !csr_ctrl__ex_valid_i) begin
    //     cur_pc = alu_ctrl__wb_npc_i;
    //     ctrl_sleep_req = 1'b1;
    // end
    if(alu_ctrl__fencei_en_i) begin
        cur_pc = alu_ctrl__wb_npc_i;
        ctrl_invld_ic_req = 1'b1;
    end
    if(alu_ctrl__fence_en_i) begin
        cur_pc = alu_ctrl__wb_npc_i;
        ctrl_invld_dc_req = 1'b1;
    end
    if(alu_ctrl__sfence_vma_i) begin
        cur_pc = alu_ctrl__wb_npc_i;
        ctrl_flush_tlb_req = 1'b1;
    end
    if(csr_ctrl__flush_i) begin
        cur_pc = alu_ctrl__wb_npc_i;
    end
    // FSM state
    case(cur_state)
        FSM_RESET: begin
            if(ppl_idle) begin
                next_state = FSM_INIT_CUR_PC;
                flush_bp_o = 1'b1;
            end
        end
        FSM_INIT_CUR_PC: begin
            next_state = FSM_PROC_EVENT;
            cur_pc = boot_addr_i;
        end
        FSM_PROC_EVENT: begin
            if(!ctrl_halt_i) begin
                set_npc_en = 1'b1;
                if(ctrl_invld_ic_req) begin
                    next_state = FSM_INVALID_IC;
                    ctrl_invld_ic_req = 1'b0;
                end else if(ctrl_invld_dc_req) begin
                    next_state = FSM_INVALID_DC;
                    ctrl_invld_dc_req = 1'b0;
                end else if(ctrl_flush_tlb_req) begin
                    next_state = FSM_FLUSH_TLB;
                    ctrl_flush_tlb_req = 1'b0;
                // end else if(ctrl_sleep_req) begin
                //     next_state = FSM_SLEEP;
                //     ctrl_sleep_req = 1'b0;
                end else if(ctrl_debug_req) begin
                    next_state = FSM_RUN;
                    ctrl_debug_req = 1'b0;
                end else if(ctrl_excp_req) begin
                    next_state = FSM_RUN;
                    ctrl_excp_req = 1'b0;
                    flush_bp_o = 1'b1;
                end else if(ctrl_xret_req) begin
                    next_state = FSM_RUN;
                    ctrl_xret_req = 1'b0;
                    flush_bp_o = 1'b1;
                end else begin
                    next_state = FSM_RUN;
                end
            end
        end
        FSM_RUN: begin
            ctrl_fet__act_o = 1'b1;
            if(ctrl_halt_i || ctrl_excp_req || ctrl_debug_req || ctrl_xret_req || ctrl_flush_tlb_req || ctrl_sleep_req || ctrl_invld_ic_req
                || csr_ctrl__flush_i || ctrl_invld_dc_req) begin
                next_state = FSM_PAUSE;
            end
        end
        FSM_PAUSE: begin
            if(ppl_idle) begin
                next_state = FSM_PROC_EVENT;
            end
        end
        // FSM_SLEEP: begin
        //     // SY core fall into sleep mode.
        //     stat_sleep_o = 1'b1;
        //     if(csr_ctrl__wfi_wakeup_i) begin
        //         next_state = FSM_PROC_EVENT;
        //     end
        // end
        FSM_INVALID_IC: begin
            // if fence.i require to invalid instrction cache
            ppl_icache_flush_o = 1'b1;
            ppl_dcache_flush_o = 1'b1;
            if (ppl_dcache_flush_ack_i) begin
                next_state = FSM_PROC_EVENT;
            end else begin
                next_state = FSM_INVALID_DC;
            end
        end
        FSM_INVALID_DC: begin
            // if fence require to invalid instrction cache
            ppl_dcache_flush_o = 1'b1;
            if(ppl_dcache_flush_ack_i) begin
                next_state = FSM_PROC_EVENT;
            end else begin
                next_state = FSM_INVALID_DC;
            end
        end
        FSM_FLUSH_TLB: begin
            ppl_tlb_flush_o = 1'b1; 
            next_state = FSM_PROC_EVENT;
        end
        default:;
    endcase
    // If CPU receives reset signal, the FSM jump to POWER_ON state immediately.
    if(ctrl_reset_i) begin
        next_state = FSM_RESET;
    end
end

//======================================================================================================================
// flush pipeline loigic
//======================================================================================================================
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        ctrl_fet__set_en_o <= `TCQ 1'b0;
    end else begin
        ctrl_fet__set_en_o <= `TCQ set_npc_en;
        ctrl_fet__set_npc_o <= `TCQ cur_pc;
    end
end

assign flush_ppl = csr_ctrl__ex_valid_i || csr_ctrl__set_debug_i || csr_ctrl__eret_i || ctrl_sleep_req || ctrl_flush_tlb_req || ctrl_invld_ic_req
                    || csr_ctrl__flush_i || ctrl_invld_dc_req; 
always_ff @(posedge clk_i) begin
    ctrl_x__if0_kill_o <= `TCQ flush_ppl;
    ctrl_x__id0_kill_o <= `TCQ flush_ppl;
    ctrl_x__ex0_kill_o <= `TCQ flush_ppl;
    ctrl_x__mem_kill_o <= `TCQ flush_ppl;
    ctrl_x__wb_kill_o <= `TCQ flush_ppl;
end
//======================================================================================================================
// registers
//======================================================================================================================
always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        cur_state <= `TCQ FSM_RESET;
        cur_pc_q <= `TCQ AWTH'(0);
        ctrl_excp_req_q <= `TCQ 1'b0;
        ctrl_xret_req_q <= `TCQ 1'b0;
        ctrl_sleep_req_q <= `TCQ 1'b0;
        ctrl_invld_ic_req_q <= `TCQ 1'b0;
        ctrl_invld_dc_req_q <= `TCQ 1'b0;
        ctrl_flush_tlb_req_q <= `TCQ 1'b0;
        ctrl_debug_req_q <= `TCQ 1'b0;
    end else begin
        cur_state <= `TCQ next_state;
        cur_pc_q <= `TCQ cur_pc;
        ctrl_excp_req_q <= `TCQ ctrl_excp_req;
        ctrl_xret_req_q <= `TCQ ctrl_xret_req;
        ctrl_sleep_req_q <= `TCQ ctrl_sleep_req;
        ctrl_invld_ic_req_q <= `TCQ ctrl_invld_ic_req;
        ctrl_invld_dc_req_q <= `TCQ ctrl_invld_dc_req;
        ctrl_flush_tlb_req_q <= `TCQ ctrl_flush_tlb_req;
        ctrl_debug_req_q <= `TCQ ctrl_debug_req;
    end
end

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
(* mark_debug = "true" *) ctrl_fsm_e prb_ppl_ctrl_state;

assign prb_ppl_ctrl_state = cur_state;

endmodule : sy_ppl_ctrl

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
    // [clock & reset & flush]
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    output  logic                           flush_o,
    output  logic                           flush_bp_o,
    // =====================================
    // [ctrl & status]
    input   logic[AWTH-1:0]                 boot_addr_i,
    input   logic                           ctrl_reset_i,
    output  logic                           stat_sleep_o,
    // =====================================
    // [to IMEM]
    output  logic                           ppl_tlb_flush_o,
    output  logic                           ppl_icache_flush_o,
    output  logic                           ppl_dcache_flush_o,
    input   logic                           ppl_dcache_flush_ack_i,
    // =====================================
    // [to ppl_fet]
    output  logic                           ctrl_fet__set_en_o,
    output  logic[AWTH-1:0]                 ctrl_fet__set_npc_o,
    //! Current stage works only if CTRL module sends act signal to FETCH module. If act is zero, FETCH module stop
    //! getting instruction from ITCM.
    output  logic                           ctrl_fet__act_o,
    // =====================================
    // [from ROB]
    input   logic                           rob_ctrl__fencei_en_i,
    input   logic                           rob_ctrl__sfence_vma_i,
    input   logic                           rob_ctrl__uret_i,          
    input   logic                           rob_ctrl__sret_i,          
    input   logic                           rob_ctrl__mret_i,          
    input   logic                           rob_ctrl__need_flush_i,          
    input   logic                           rob_ctrl__mispred_i,          
    input   logic                           rob_ctrl__wfi_i,        
    input   logic                           rob_ctrl__ex_valid_i,          
    input   ecode_t                         rob_ctrl__ecode_i,          
    input   logic                           rob_ctrl__is_intr_i,
    input   logic[AWTH-1:0]                 rob_ctrl__pc_i,
    input   logic[DWTH-1:0]                 rob_ctrl__excp_tval_i,
    // =====================================
    // [To CSR]
    output  trap_t                          ctrl_csr__trap_o,
    output  logic                           ctrl_csr__mret_o,
    output  logic                           ctrl_csr__sret_o,
    output  logic                           ctrl_csr__dret_o,
    // [From CSR]   
    input   logic[AWTH-1:0]                 csr_ctrl__trap_vec_i,
    input   logic[AWTH-1:0]                 csr_ctrl__epc_i,
    input   logic                           csr_ctrl__wfi_wakeup_i,
    // =====================================
    // [From LSU]
    input   logic                           lsu_ctrl__st_queen_empty_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================

typedef enum logic[3:0] {
    FSM_RESET           = 0,
    FSM_INIT_CUR_PC     = 1,
    FSM_PROC_EVENT      = 2,
    FSM_RUN             = 3,
    FSM_PAUSE           = 4,
    FSM_INVALID_IC      = 5,
    FSM_SLEEP           = 6,
    FSM_FLUSH_TLB       = 7,
    FSM_INVALID_DC      = 8
} ctrl_fsm_e;

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================

logic                               ppl_idle;
ctrl_fsm_e                          cur_state;
ctrl_fsm_e                          next_state;
logic[AWTH-1:0]                     cur_pc;
logic[AWTH-1:0]                     cur_pc_q;
logic                               ctrl_excp_req;
logic                               ctrl_xret_req;
logic                               ctrl_sleep_req;
logic                               ctrl_invld_ic_req;
logic                               ctrl_invld_dc_req;
logic                               ctrl_flush_tlb_req;
logic                               ctrl_flush_ppl_req;
logic                               set_npc_en;
logic                               ctrl_debug_req_q;
logic                               ctrl_excp_req_q;
logic                               ctrl_xret_req_q;
logic                               ctrl_sleep_req_q;
logic                               ctrl_invld_ic_req_q;
logic                               ctrl_invld_dc_req_q;
logic                               ctrl_flush_tlb_req_q;
logic                               ctrl_flush_ppl_req_q;
logic                               flush_ppl;
logic[AWTH-1:0]                     excp_pc;
logic                               excp_is_intr; 
ecode_t                             excp_cause  ; 
logic[DWTH-1:0]                     excp_tval   ; 
logic                               excp_valid  ; 
//======================================================================================================================
// Instance
//======================================================================================================================

    // -----------------------------------------------------------------------------
    // status 
    assign ppl_idle = lsu_ctrl__st_queen_empty_i;

//======================================================================================================================
// FSM logic 
//======================================================================================================================
    always_comb begin
        // default
        flush_bp_o  = 1'b0;
        // FSM of control module
        next_state = cur_state;
        // The privilege, mode, and current PC of Sy core
        cur_pc = cur_pc_q;
        // output signals
        // -- Drive the pipelien to work
        ctrl_fet__act_o = 1'b0;
        // -- Sy core status and information signals
        stat_sleep_o        = 1'b0;
        // flush I$/D$ and TLB
        ppl_icache_flush_o  = 1'b0;
        ppl_dcache_flush_o  = 1'b0;
        ppl_tlb_flush_o     = 1'b0;
        flush_ppl           = 1'b0;
        // inner variables
        ctrl_excp_req       = ctrl_excp_req_q;
        ctrl_xret_req       = ctrl_xret_req_q;
        ctrl_sleep_req      = ctrl_sleep_req_q;
        ctrl_invld_ic_req   = ctrl_invld_ic_req_q;
        ctrl_invld_dc_req   = ctrl_invld_dc_req_q;
        ctrl_flush_tlb_req  = ctrl_flush_tlb_req_q;
        ctrl_flush_ppl_req  = ctrl_flush_ppl_req_q;
        set_npc_en = 1'b0;

        if (excp_valid) begin
            cur_pc = csr_ctrl__trap_vec_i;
        end 
        // generate the next PC
        if (rob_ctrl__ex_valid_i) begin
            ctrl_excp_req = 1'b1;
        end else if(rob_ctrl__mret_i || rob_ctrl__sret_i || rob_ctrl__uret_i) begin
            ctrl_xret_req = 1'b1;
            cur_pc = csr_ctrl__epc_i;
        end
        // system instr
        if(rob_ctrl__wfi_i && !rob_ctrl__ex_valid_i) begin
            cur_pc = rob_ctrl__pc_i;
            ctrl_sleep_req = 1'b1;
        end
        if(rob_ctrl__fencei_en_i) begin
            cur_pc = rob_ctrl__pc_i;
            ctrl_invld_ic_req = 1'b1;
        end
        if(rob_ctrl__sfence_vma_i) begin
            cur_pc = rob_ctrl__pc_i;
            ctrl_flush_tlb_req = 1'b1;
        end
        if(rob_ctrl__need_flush_i) begin
            cur_pc = rob_ctrl__pc_i;
            ctrl_flush_ppl_req = 1'b1;
        end
        if (rob_ctrl__mispred_i) begin
            cur_pc = rob_ctrl__pc_i;
            ctrl_flush_ppl_req = 1'b1;
        end
        // FSM state
        case(cur_state)
            FSM_RESET: begin
                if(ppl_idle) begin
                    next_state = FSM_INIT_CUR_PC;
                end
                flush_bp_o = 1'b1;
            end
            FSM_INIT_CUR_PC: begin
                next_state = FSM_PROC_EVENT;
                cur_pc = boot_addr_i;
            end
            FSM_PROC_EVENT: begin
                set_npc_en = 1'b1;
                flush_ppl  = 1'b1;
                next_state = FSM_RUN;
                if(ctrl_invld_ic_req) begin
                    ctrl_invld_ic_req = 1'b0;
                end else if(ctrl_invld_dc_req) begin
                    ctrl_invld_dc_req = 1'b0;
                end else if(ctrl_flush_tlb_req) begin
                    ctrl_flush_tlb_req = 1'b0;
                end else if(ctrl_sleep_req) begin
                    ctrl_sleep_req = 1'b0;
                end else if(ctrl_excp_req) begin
                    ctrl_excp_req = 1'b0;
                    flush_bp_o = 1'b1;
                end else if(ctrl_xret_req) begin
                    ctrl_xret_req = 1'b0;
                    flush_bp_o = 1'b1;
                end else if (ctrl_flush_ppl_req) begin
                    ctrl_flush_ppl_req = 1'b0;
                end
            end
            FSM_RUN: begin
                ctrl_fet__act_o = 1'b1;
                if (ctrl_excp_req || ctrl_xret_req || ctrl_flush_tlb_req || ctrl_sleep_req || ctrl_invld_ic_req
                    || ctrl_invld_dc_req || ctrl_flush_ppl_req) begin
                    next_state = FSM_PAUSE;
                // end else if (ctrl_flush_ppl_req) begin
                    // next_state = FSM_PROC_EVENT;
                end
            end
            FSM_PAUSE: begin
                if(ppl_idle) begin
                    if (ctrl_flush_tlb_req) begin
                        next_state = FSM_FLUSH_TLB;
                    end else if (ctrl_sleep_req) begin
                        next_state = FSM_SLEEP; 
                    end else if (ctrl_invld_ic_req) begin
                        // flush_ppl = 1'b1;
                        next_state = FSM_INVALID_IC;
                    end else if (ctrl_invld_dc_req) begin
                        // flush_ppl = 1'b1;
                        next_state = FSM_INVALID_DC;
                    end else begin
                        next_state = FSM_PROC_EVENT;
                    end
                end
            end
            FSM_SLEEP: begin
                // SY core fall into sleep mode.
                stat_sleep_o = 1'b1;
                if(csr_ctrl__wfi_wakeup_i) begin
                    next_state = FSM_PROC_EVENT;
                end
            end
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
        if (ctrl_reset_i) begin
            next_state = FSM_RESET;
        end
    end
//======================================================================================================================
// flush pipeline 
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            ctrl_fet__set_en_o <= `TCQ 1'b0;
            ctrl_fet__set_npc_o <= `TCQ '0;
        end else begin
            ctrl_fet__set_en_o <= `TCQ set_npc_en;
            ctrl_fet__set_npc_o <= `TCQ cur_pc;
        end
    end

    // always_ff @(posedge clk_i) begin
    //     flush_o <= flush_ppl;
    // end
    assign flush_o = flush_ppl;

    // PC and exception cause
    // Delay one cycle to make sure Timing.
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            excp_pc      <= `TCQ '0;
            excp_is_intr <= `TCQ 1'b0;
            excp_cause   <= `TCQ '0;
            excp_tval    <= `TCQ '0;
            excp_valid   <= `TCQ 1'b0;
        end else begin
            if (rob_ctrl__ex_valid_i) begin
                excp_pc      <= `TCQ rob_ctrl__pc_i;
                excp_is_intr <= `TCQ rob_ctrl__is_intr_i;
                excp_cause   <= `TCQ rob_ctrl__ecode_i;
                excp_tval    <= `TCQ rob_ctrl__excp_tval_i;
            end
            excp_valid   <= `TCQ rob_ctrl__ex_valid_i;
        end
    end

    // send trap to csr regfile
    always_comb begin: gen_trap_data
        ctrl_csr__trap_o.valid = 1'b0;
        ctrl_csr__trap_o.excp_cause = ILLEGAL_INST;       
        ctrl_csr__trap_o.intr_cause = SOFTWARE_U_MODE;
        ctrl_csr__trap_o.pc = AWTH'(0);
        ctrl_csr__trap_o.tval = excp_tval;
        ctrl_csr__trap_o.is_intr = 1'b0;
        if (excp_valid && excp_is_intr) begin
            ctrl_csr__trap_o.valid = 1'b1;
            ctrl_csr__trap_o.intr_cause = excp_cause.intr;
            ctrl_csr__trap_o.is_intr = 1'b1;
            ctrl_csr__trap_o.pc = excp_pc;
        end else if(excp_valid) begin
            ctrl_csr__trap_o.valid = 1'b1;           
            ctrl_csr__trap_o.excp_cause = excp_cause.excp;
            ctrl_csr__trap_o.is_intr = 1'b0;
            ctrl_csr__trap_o.pc = excp_pc;
        end else begin
            ctrl_csr__trap_o.valid = 1'b0;            
        end
    end

    // send trap return siganl to csr_regfile
    always_comb begin: gen_trap_ret
        ctrl_csr__mret_o = 1'b0; 
        ctrl_csr__sret_o = 1'b0; 
        ctrl_csr__dret_o = 1'b0;    // not surpport
        if (rob_ctrl__mret_i) begin
            ctrl_csr__mret_o = 1'b1;
        end else if (rob_ctrl__sret_i) begin
            ctrl_csr__sret_o = 1'b1;
        end 
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
            ctrl_flush_ppl_req_q <= `TCQ 1'b0;
        end else begin
            cur_state <= `TCQ next_state;
            cur_pc_q <= `TCQ cur_pc;
            ctrl_excp_req_q <= `TCQ ctrl_excp_req;
            ctrl_xret_req_q <= `TCQ ctrl_xret_req;
            ctrl_sleep_req_q <= `TCQ ctrl_sleep_req;
            ctrl_invld_ic_req_q <= `TCQ ctrl_invld_ic_req;
            ctrl_invld_dc_req_q <= `TCQ ctrl_invld_dc_req;
            ctrl_flush_tlb_req_q <= `TCQ ctrl_flush_tlb_req;
            ctrl_flush_ppl_req_q <= `TCQ ctrl_flush_ppl_req;
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_ctrl

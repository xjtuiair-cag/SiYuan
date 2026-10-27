// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_br_pred.v
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

module sy_ppl_br_pred
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset & flush]
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    input   logic                           debug_mode_i,
    input   logic                           forbid_br_pred_i,
    // =====================================
    // [From fronted]
    input   logic[1:0]                      instr_vld_i,
    input   logic[1:0][IWTH-1:0]            instr_i,
    input   logic[1:0][AWTH-1:0]            vaddr_i,

    input   btb_pred_t                      btb_pred_i,
    input   bht_pred_t                      bht_pred_i,
    // =====================================
    // [to fronted]
    output  logic                           bp_vld_o,   
    output  npc_type_e                      npc_type_o,
    // output  logic[AWTH-1:0]                 bp_addr_o,
    output  logic[AWTH-1:0]                 jump_addr_o,
    output  logic[AWTH-1:0]                 btb_addr_o,
    output  logic[AWTH-1:0]                 ras_addr_o,
    // =====================================
    // [to Instr Buffer]
    output  logic[1:0]                      fet_valid_o,   
    output  npc_type_e[1:0]                 fet_npc_type_o,   
    output  logic[1:0][AWTH-1:0]            fet_pc_o   
    // output  logic[1:0][AWTH-1:0]            fet_npc_o
);
//======================================================================================================================
// Parameters
//======================================================================================================================
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    qdec_type_e[1:0]                instr_type;  
    logic                           ras_push;
    logic                           ras_pop;
    logic[AWTH-1:0]                 ras_push_addr;
    ras_t                           ras_pop_addr;
    logic[1:0][AWTH-1:0]            jump_addr;
    logic[1:0][AWTH-1:0]            next_pc;        
    logic[1:0]                      bp_valid_each;
    logic[1:0][IWTH-1:0]            instr_after_reply;  
    logic[1:0]                      instr_is_c;     
    logic[1:0]                      imm_is_neg;     
    npc_type_e[1:0]                 npc_type;
//======================================================================================================================
// Instance
//======================================================================================================================
    sy_ppl_qdec qdec_inst_0(
        .instr_i            (instr_i[0]),           
        .vaddr_i            (vaddr_i[0]),
        .instr_is_c_o       (instr_is_c[0]),
        .imm_is_neg_o       (imm_is_neg[0]),
        .instr_type_o       (instr_type[0]),   
        .target_address_o   (jump_addr[0])
    );

    sy_ppl_qdec qdec_inst_1(
        .instr_i            (instr_i[1]),           
        .vaddr_i            (vaddr_i[1]),
        .instr_is_c_o       (instr_is_c[1]),
        .imm_is_neg_o       (imm_is_neg[1]),
        .instr_type_o       (instr_type[1]),   
        .target_address_o   (jump_addr[1])
    );

    sy_ppl_ras #(
        .DEPTH  (4)
    ) ras_inst(
        .clk_i              (clk_i),   
        .rst_i              (rst_i),   
        .flush_i            (flush_i),     
    
        .push_i             (ras_push),    
        .pop_i              (ras_pop),   
        .data_i             (ras_push_addr),  
        .data_o             (ras_pop_addr)
    );

    assign ras_addr_o    = ras_pop_addr.ra;
    assign btb_addr_o    = btb_pred_i.target_address;
    assign jump_addr_o   = bp_valid_each[0] ? jump_addr[0] : jump_addr[1];

    always_comb begin : branch_prediction 
        ras_push_addr = '0;
        ras_push = 1'b0;
        ras_pop  = 1'b0;

        // bp_addr_o   = next_pc[1];
        // bp_addr_o = jump_addr[0];
        bp_valid_each = '0;
        for (integer i=1;i>=0;i--) begin
            next_pc[i]   = vaddr_i[i] + (instr_is_c[i] ? 2 : 4);
            npc_type[i]  = NORMAL_ADDR;
            unique case(instr_type[i]) 
                CALL_JALR : begin
                    ras_push = instr_vld_i[i];       
                    ras_push_addr = next_pc[i];
                    // bp_addr_o = btb_pred_i.target_address;
                    bp_valid_each[i] = instr_vld_i[i] && btb_pred_i.vld;
                    npc_type[i] = BTB_ADDR;
                end
                CALL_JAL: begin
                    ras_push = instr_vld_i[i];
                    ras_push_addr = next_pc[i];
                    // bp_addr_o = jump_addr[i];
                    bp_valid_each[i] = instr_vld_i[i];
                    npc_type[i] = JUMP_ADDR;
                end
                RET: begin
                    ras_pop = instr_vld_i[i];
                    // bp_addr_o = ras_pop_addr.ra;
                    bp_valid_each[i] = ras_pop_addr.vld && instr_vld_i[i];
                    npc_type[i] = RAS_ADDR;
                end
                JALR: begin
                    // bp_addr_o = btb_pred_i.target_address;
                    bp_valid_each[i] = instr_vld_i[i] && btb_pred_i.vld;
                    npc_type[i] = BTB_ADDR;
                end
                JUMP: begin
                    bp_valid_each[i] = instr_vld_i[i];
                    // bp_addr_o = jump_addr[i];
                    npc_type[i] = JUMP_ADDR;
                end
                BRANCH: begin
                    if (bht_pred_i.vld) begin
                        if (bht_pred_i.taken) begin
                            bp_valid_each[i] = instr_vld_i[i];
                            // bp_addr_o = jump_addr[i];
                            npc_type[i] = JUMP_ADDR;
                        end 
                    // static prediction
                    end else if (imm_is_neg[i]) begin
                        bp_valid_each[i] = instr_vld_i[i];
                        // bp_addr_o = jump_addr[i];
                        npc_type[i] = JUMP_ADDR;
                    end
                end
                default: ;
            endcase
            if (debug_mode_i || forbid_br_pred_i) begin
                bp_valid_each[i] = 1'b0;
            end
        end
    end

    assign bp_vld_o = |bp_valid_each;
    assign npc_type_o = bp_valid_each[0] ? npc_type[0] : npc_type[1];

    assign fet_valid_o[0] = instr_vld_i[0];
    assign fet_valid_o[1] = instr_vld_i[1] && !bp_valid_each[0];
    assign fet_npc_type_o[0] = bp_valid_each[0] ? npc_type[0] : NORMAL_ADDR;
    assign fet_npc_type_o[1] = bp_valid_each[1] ? npc_type[1] : NORMAL_ADDR;
    for (genvar i=0;i<2;i++) begin
        assign fet_pc_o[i]   = vaddr_i[i];
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off
// synopsys translate_on

endmodule

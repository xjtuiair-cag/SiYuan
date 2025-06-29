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
    // =====================================
    // [From fronted]
    input   logic[1:0]                      instr_vld_i,
    input   logic[1:0][IWTH-1:0]            instr_i,
    input   logic[1:0][AWTH-1:0]            vaddr_i,

    input   logic[AWTH-1:0]                 fet_pc_i,
    // =====================================
    // [to fronted]
    output  logic                           bp_vld_o,   
    output  logic[AWTH-1:0]                 bp_addr_o,
    // =====================================
    // [to Instr Buffer]
    output  logic[1:0]                      fet_valid_o,   
    output  logic[1:0][AWTH-1:0]            fet_pc_o,   
    output  logic[1:0][AWTH-1:0]            fet_npc_o,
    // output  logic[1:0][31:0]                fet_instr_o,
    // output  logic[1:0]                      fet_instr_is_c_o,
    // =====================================
    // [From ROB]
    input   bht_update_t                    bht_update_i,
    input   btb_update_t                    btb_update_i
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
    bht_pred_t                      bht_pred;
    btb_pred_t                      btb_pred;
    logic[1:0][AWTH-1:0]            jump_addr;
    logic[1:0][AWTH-1:0]            next_pc;        
    logic[1:0]                      bp_valid_each;
    logic[1:0][IWTH-1:0]            instr_after_reply;  
    logic[1:0]                      instr_is_c;     
    logic[1:0]                      imm_is_neg;     
//======================================================================================================================
// Instance
//======================================================================================================================
    // compressed instr to normal instr
    // sy_ppl_compress_dec compressed_dec_inst0(
    //     .instr_i               (instr_i[0]) ,
    //     .instr_o               (instr_after_reply[0]) ,
    //     .illegal_instr_o       () ,
    //     .is_compressed_o       (instr_is_c[0]) 
    // );

    // sy_ppl_compress_dec compressed_dec_inst1(
    //     .instr_i               (instr_i[1]) ,
    //     .instr_o               (instr_after_reply[1]) ,
    //     .illegal_instr_o       () ,
    //     .is_compressed_o       (instr_is_c[1]) 
    // );

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

    sy_ppl_bht #(
        .BHT_ENTRIES  (256)
    ) bht_inst(
        .clk_i              (clk_i), 
        .rst_i              (rst_i), 
        .flush_i            (flush_i),   

        .vaddr_i            (fet_pc_i),   
        .bht_update_i       (bht_update_i),        
        .bht_pred_o         (bht_pred)
    );


    sy_ppl_btb btb_inst(
        .clk_i              (clk_i),             
        .rst_i              (rst_i),            
        .flush_i            (flush_i),             
        .vaddr_i            (fet_pc_i),               
        .btb_update_i       (btb_update_i),             
        .btb_pred_o         (btb_pred) 
    );

    always_comb begin : branch_prediction 
        ras_push_addr = '0;
        ras_push = 1'b0;
        ras_pop  = 1'b0;

        bp_addr_o   = next_pc[1];
        bp_valid_each = '0;
        for (integer i=1;i>=0;i--) begin
            next_pc[i]   = vaddr_i[i] + (instr_is_c[i] ? 2 : 4);
            case(instr_type[i]) 
                CALL_JALR : begin
                    ras_push = instr_vld_i[i];       
                    ras_push_addr = next_pc[i];
                    bp_addr_o = btb_pred.vld ? btb_pred.target_address : next_pc[i];
                    bp_valid_each[i] = instr_vld_i[i];
                end
                CALL_JAL: begin
                    ras_push = instr_vld_i[i];
                    ras_push_addr = next_pc[i];
                    bp_addr_o = jump_addr[i];
                    bp_valid_each[i] = instr_vld_i[i];
                end
                RET: begin
                    ras_pop = instr_vld_i[i];
                    bp_addr_o = ras_pop_addr.vld ? ras_pop_addr.ra : next_pc[i];
                    bp_valid_each[i] = ras_pop_addr.vld && instr_vld_i[i];
                end
                JALR: begin
                    bp_addr_o = btb_pred.vld ? btb_pred.target_address : next_pc[i];
                    bp_valid_each[i] = instr_vld_i[i];
                end
                JUMP: begin
                    bp_valid_each[i] = instr_vld_i[i];
                    bp_addr_o = jump_addr[i];
                end
                BRANCH: begin
                    // if (bht_pred.vld) begin
                    //     if (bht_pred.taken) begin
                    //         bp_valid_each[i] = instr_vld_i[i];
                    //         bp_addr_o = jump_addr[i];
                    //     end 
                    // end else if (imm_is_neg[i]) begin
                    //     bp_valid_each[i] = instr_vld_i[i];
                    //     bp_addr_o = jump_addr[i];
                    // end
                    // if (bht_pred.vld && bht_pred.taken || imm_is_neg[i]) begin
                    //     bp_valid_each[i] = instr_vld_i[i];
                    //     bp_addr_o = jump_addr[i];
                    // end 
                    if (imm_is_neg[i]) begin
                        bp_valid_each[i] = instr_vld_i[i];
                        bp_addr_o = jump_addr[i];
                    end 
                end
                default: ;
            endcase
        end
    end

    assign bp_vld_o = |bp_valid_each;
    assign fet_valid_o[0] = instr_vld_i[0];
    assign fet_valid_o[1] = instr_vld_i[1] && !bp_valid_each[0];

    for (genvar i=0;i<2;i++) begin
        assign fet_pc_o[i]   = vaddr_i[i];
        assign fet_npc_o[i]  = bp_valid_each[i] ? bp_addr_o : next_pc[i];
    end
    // assign fet_instr_is_c_o = instr_is_c;
    // assign fet_instr_o      = instr_after_reply;

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off
    logic                    prb_bp_valid;
    logic[1:0]               prb_bp_valid_each;
    logic[AWTH-1:0]          prb_bp_addr;
    qdec_type_e[1:0]         prb_instr_type;
    logic[1:0]               prb_fet_vld;
    logic[1:0][AWTH-1:0]     prb_fet_pc;
    logic[1:0][AWTH-1:0]     prb_fet_npc;
    bht_update_t             prb_bht_update;
    btb_update_t             prb_btb_update;

    assign prb_bp_valid         = bp_vld_o;
    assign prb_bp_valid_each    = bp_valid_each;
    assign prb_bp_addr          = bp_addr_o;
    assign prb_fet_pc           = fet_pc_o;
    assign prb_fet_npc          = fet_npc_o;
    assign prb_instr_type       = instr_type;
    assign prb_bht_update       = bht_update_i;
    assign prb_btb_update       = btb_update_i;
// synopsys translate_on

endmodule

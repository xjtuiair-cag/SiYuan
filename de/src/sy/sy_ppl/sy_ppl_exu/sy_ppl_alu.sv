// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_alu.v
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

module sy_ppl_alu
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset & flush]
    // -- <clock>
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,

    input   logic                           alu_en_i,
    input   logic[ROB_WTH-1:0]              rob_idx_i,
    // =====================================
    // [ALU op]
    input   instr_cls_e                     instr_cls_i,    
    input   als_opcode_e                    als_opcode_i,
    input   jbr_opcode_e                    jbr_opcode_i,
    input   logic                           is_32_i,         // word
    input   logic                           is_c_i,          // comperssed instr
    input   logic[DWTH-1:0]                 rs1_data_i,
    input   logic[DWTH-1:0]                 rs2_data_i,
    input   logic[DWTH-1:0]                 jbr_base_i,
    input   logic[DWTH-1:0]                 pc_i,
    input   logic[DWTH-1:0]                 imm_i,
    input   logic                           rdst_en_i,
    input   logic[PHY_REG_WTH-1:0]          rdst_idx_i,
    // =====================================
    // [Commit to ROB]
    output  alu_commit_t                    alu_rob__commit_o,
    // =====================================
    // [Write to REG and update Reg state]
    output  logic                           alu_gpr__we_o,
    output  logic[PHY_REG_WTH-1:0]          alu_gpr__idx_o,
    output  logic[DWTH-1:0]                 alu_gpr__wdata_o, 
    // =====================================
    // [Awake]
    output  logic                           alu_awake_vld_o,
    output  logic[PHY_REG_WTH-1:0]          alu_awake_idx_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================


//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic[5:0]                          shamt;
    logic[DWTH-1:0]                     als_out;
    logic[31:0]                         als_out32;
    logic[DWTH-1:0]                     true_npc;
    logic                               dmem_misaligned;
    logic[7:0]                          dmem_strb;
    logic                               ex0_dmem_vld;
    logic                               ex0_dmem_we;
    logic[AWTH-1:0]                     ex0_dmem_addr;
    logic[DWTH-1:0]                     ex0_dmem_wdata;
    amo_opcode_e                        ex0_dmem_amo_opcode;   
    logic[DWTH-1:0]                     ex0_dmem_operand;
    mem_opcode_e                        ex0_dmem_opcode;
    logic[DWTH/8-1:0]                   ex0_dmem_wstrb;
    logic[DWTH-1:0]                     ex0_rdst_from_alsc;
    logic                               sys_instr_avail;
    logic                               is_alu_instr;
//======================================================================================================================
// ALU Execute
//======================================================================================================================
    // Process the algebra, logic, shift operation according to decoded content.
    assign shamt = rs2_data_i[5:0];
    always_comb begin
        als_out32 = 32'b0;
        case (als_opcode_i)
            ALS_OP_ADD : begin
                als_out32 = rs1_data_i[31:0] + rs2_data_i[31:0]; 
                if(is_32_i)
                    als_out = {{32{als_out32[31]}},als_out32};
                else
                    als_out = rs1_data_i + rs2_data_i;
            end
            ALS_OP_SLL : begin 
                als_out32 = rs1_data_i[31:0] << shamt[4:0];  
                if(is_32_i)
                    als_out = {{32{als_out32[31]}},als_out32};
                else
                    als_out = rs1_data_i << shamt;
            end
            ALS_OP_XOR : als_out = rs1_data_i ^ rs2_data_i;
            ALS_OP_SRL : begin
                als_out32 = rs1_data_i[31:0] >> shamt[4:0];  
                if(is_32_i)
                    als_out = {{32{als_out32[31]}},als_out32};
                else
                    als_out = rs1_data_i >> shamt;
            end
            ALS_OP_OR : als_out = rs1_data_i | rs2_data_i;
            ALS_OP_AND : als_out = rs1_data_i & rs2_data_i;
            ALS_OP_SEQ : als_out = {63'b0, rs1_data_i == rs2_data_i};
            ALS_OP_SNE : als_out = {63'b0, rs1_data_i != rs2_data_i};
            ALS_OP_SUB : begin
                als_out32 = rs1_data_i[31:0] - rs2_data_i[31:0];
                if(is_32_i)
                    als_out = {{32{als_out32[31]}},als_out32};
                else
                    als_out = rs1_data_i - rs2_data_i;
            end
            ALS_OP_SRA : begin
                als_out32 = $signed(rs1_data_i[31:0]) >>> shamt[4:0];
                if(is_32_i)
                    als_out = {{32{als_out32[31]}},als_out32};
                else
                    als_out = $signed(rs1_data_i) >>> shamt;
            end
            ALS_OP_SLT : als_out = {63'b0, $signed(rs1_data_i) < $signed(rs2_data_i)};
            ALS_OP_SGE : als_out = {63'b0, $signed(rs1_data_i) >= $signed(rs2_data_i)};
            ALS_OP_SLTU : als_out = {63'b0, rs1_data_i < rs2_data_i};
            ALS_OP_SGEU : als_out = {63'b0, rs1_data_i >= rs2_data_i};
            default : als_out = 64'h0;
        endcase
    end

    // Jump 
    always_comb begin
        if (instr_cls_i == INSTR_CLS_JBR && !(jbr_opcode_i == JBR_OP_BRANCH && !als_out[0])) begin
            true_npc = jbr_base_i + imm_i; 
        end else begin
            true_npc = pc_i + (is_c_i ? 'd2 : 'd4); 
        end
    end
//======================================================================================================================
// Commit
//======================================================================================================================
    // assign is_alu_instr = (instr_cls_i == INSTR_CLS_JBR || instr_cls_i == INSTR_CLS_NORMAL);
    assign alu_rob__commit_o.vld = alu_en_i;
    assign alu_rob__commit_o.rob_idx    = rob_idx_i;
    assign alu_rob__commit_o.true_npc   = true_npc;
    assign alu_rob__commit_o.br_taken   = als_out[0]; 
    // write back
    assign alu_gpr__we_o               = alu_en_i && rdst_en_i;
    assign alu_gpr__idx_o              = rdst_idx_i;
    assign alu_gpr__wdata_o            = als_out; 

    assign alu_awake_vld_o             = alu_gpr__we_o;
    assign alu_awake_idx_o             = alu_gpr__idx_o;
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on

// (* mark_debug = "true" *) logic         prb_alu_vld;
// (* mark_debug = "true" *) logic[63:0]   prb_alu_data;
// (* mark_debug = "true" *) logic[63:0]   prb_alu_true_pc;

// assign prb_alu_vld      = alu_en_i;
// assign prb_alu_data     = als_out;
// assign prb_alu_true_pc  = true_npc;

endmodule : sy_ppl_alu

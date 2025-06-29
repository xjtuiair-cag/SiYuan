// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_qdec.v
// DEPARTMENT : CAG of IAIR
// AUTHOR     : shenghuanliu
// AUTHOR'S EMAIL :liushenghuan2002@gmail.com
// -----------------------------------------------------------------------------
// Ver 1.0  2025--01--01 initial version.
// -----------------------------------------------------------------------------
// KEYWORDS   : quick decoder 
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

module sy_ppl_qdec
    import sy_pkg::*;
(
    // =====================================
    // [instr from fronted]
    input   logic [IWTH-1:0]             instr_i,           
    input   logic [AWTH-1:0]             vaddr_i,
    // =====================================
    // [decode info to fronted]
    output  logic                        instr_is_c_o,
    output  logic                        imm_is_neg_o,
    output  qdec_type_e                  instr_type_o,   
    output  logic[AWTH-1:0]              target_address_o
);
//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                           instr_is_c; // compressed instruction
    logic                           rvi_branch, rvc_branch;
    logic                           rvi_jump, rvc_jump;
    logic                           rvi_jalr, rvc_jalr;
    logic                           rvi_call, rvc_call;
    logic                           rvi_ret , rvc_ret;
    logic[DWTH-1:0]                 rvi_imm , rvc_imm;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign instr_is_c   = (instr_i[1:0] != 2'b11);

    // Opocde is JAL[R] and destination register is either x1 or x5
    // differentiates between JAL and BRANCH opcode, JALR comes from BHT
    // conditional branch
    assign rvi_branch = (instr_i[6:0] == OpcodeBranch);
    assign rvc_branch =  ((instr_i[15:13] == OpcodeC1Beqz) | (instr_i[15:13] == OpcodeC1Bnez))
                        & (instr_i[1:0]   == OpcodeC1) & instr_is_c;
    // jal
    assign rvi_jump   = (instr_i[6:0] == OpcodeJal);
    assign rvc_jump   = (instr_i[15:13] == OpcodeC1J) & (instr_i[1:0] == OpcodeC1) && instr_is_c;
    // jalr
    assign rvi_jalr   = (instr_i[6:0]   == OpcodeJalr);
    assign rvc_jalr   = (instr_i[15:13] == OpcodeC2JalrMvAdd)
                      & (instr_i[6:2]   == 5'b00000)
                      & (instr_i[1:0]   == OpcodeC2)
                      & instr_is_c;
    // call 
    assign rvi_call   = (rvi_jalr | rvi_jump) & ((instr_i[11:7] == 5'd1) | instr_i[11:7] == 5'd5);
    assign rvc_call   = rvc_jalr & instr_i[12];
    // return
    // check that rs1 is either x1 or x5 and that rs1 is not x1 or x5
    assign rvi_ret    = rvi_jalr & ((instr_i[11:7] != 5'd1) && instr_i[11:7] != 5'd5)
                                     & ((instr_i[19:15] == 5'd1) || instr_i[19:15] == 5'd5);
    // check that rs1 is x1 or x5
    assign rvc_ret    = ((instr_i[11:7] == 5'd1) | (instr_i[11:7] == 5'd5))  & rvc_jalr & !instr_i[12];


    assign rvi_imm    = (instr_i[3]) ? j_imm(instr_i) : b_imm(instr_i);
    // differentiates between JAL and BRANCH opcode, JALR comes from BHT
    assign rvc_imm    = (instr_i[14]) ? {{56{instr_i[12]}}, instr_i[6:5], instr_i[2], instr_i[11:10], instr_i[4:3], 1'b0}
                                       : {{53{instr_i[12]}}, instr_i[8], instr_i[10:9], instr_i[6], instr_i[7], instr_i[2], instr_i[11], instr_i[5:3], 1'b0};

    assign instr_is_c_o = instr_is_c;
    assign imm_is_neg_o = instr_is_c ? rvc_imm[63] : rvi_imm[63];
    always_comb begin : quick_decode
        instr_type_o  = NORMAL;
        // if (rvi_ret || rvc_ret) begin
        //     instr_type_o = RET;
        // end else if (rvi_call & rvi_jalr || rvc_call) begin
        //     instr_type_o = CALL_JALR;
        // end else if (rvi_call & rvi_jump) begin
        //     instr_type_o = CALL_JAL;
        // end else if (rvi_jalr || rvc_jalr) begin
        //     instr_type_o = JALR;
        // end else if (rvi_jump || rvc_jump) begin
        //     instr_type_o = JUMP;
        // end else if (rvi_branch) begin
        //     instr_type_o = BRANCH;
        // end
        if (instr_is_c) begin
            if (rvc_ret) begin
                instr_type_o = RET;
            end else if (rvc_call) begin
                instr_type_o = CALL_JALR;   
            end else if (rvc_jump) begin
                instr_type_o = JUMP;
            end else if (rvc_branch) begin
                instr_type_o = BRANCH;
            end else if (rvc_jalr) begin
                instr_type_o = JALR;
            end
        end else begin
            if (rvi_ret) begin
                instr_type_o = RET;   
            end else if (rvi_call && rvi_jalr) begin
                instr_type_o = CALL_JALR;
            end else if (rvi_call & rvi_jump) begin
                instr_type_o = CALL_JAL;   
            end else if (rvi_jalr) begin
                instr_type_o = JALR;
            end else if (rvi_jump) begin
                instr_type_o = JUMP;
            end else if (rvi_branch) begin
                instr_type_o = BRANCH;
            end
        end
        // if (rvi_jalr || rvc_jalr) begin
        //     instr_type_o = JALR;
        // end else if (rvi_jump || rvc_jump) begin
        //     instr_type_o = JUMP;
        // end else if (rvi_branch || rvc_branch) begin
        //     instr_type_o = BRANCH;
        // end

        // if (instr_is_c) begin
        //     instr_type_o = NORMAL;
        // end
    end

    assign target_address_o = vaddr_i + (instr_is_c ? rvc_imm : rvi_imm);
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule

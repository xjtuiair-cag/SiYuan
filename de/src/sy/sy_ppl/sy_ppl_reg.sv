// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_reg.v
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

module sy_ppl_reg
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      
    // -- <reset>
    input   logic                           rst_i,                      
    // =====================================
    // [to ppl_dec]
    input   logic[4:0]                      dec_reg__rs1_idx_i,
    output  logic[DWTH-1:0]                 reg_dec__rs1_reg_o,
    input   logic[4:0]                      dec_reg__rs2_idx_i,
    output  logic[DWTH-1:0]                 reg_dec__rs2_reg_o,
    // =====================================
    // [to ppl_alu]
    input   logic                           alu_reg__rdst_en_i,
    input   logic[4:0]                      alu_reg__rdst_idx_i,
    input   logic[DWTH-1:0]                 alu_reg__rdst_data_i,
    // =====================================
    // [to ppl_mdu]
    input   logic                           mdu_reg__rdst_en_i,
    input   logic[4:0]                      mdu_reg__rdst_idx_i,
    input   logic[DWTH-1:0]                 mdu_reg__rdst_data_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================


//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                           update_gpsr_en;
    logic[4:0]                      update_gpsr_idx;
    logic[DWTH-1:0]                 update_gpsr_data;
    logic[DWTH-1:0]                 gpsr[31:0];

//======================================================================================================================
// Instance
//======================================================================================================================

always_comb begin
    if(alu_reg__rdst_en_i && alu_reg__rdst_idx_i != 0) begin
        update_gpsr_en = 1'b1;
        update_gpsr_idx = alu_reg__rdst_idx_i;
        update_gpsr_data = alu_reg__rdst_data_i;
    end else begin
        update_gpsr_en = mdu_reg__rdst_en_i && (mdu_reg__rdst_idx_i != 5'h0);
        update_gpsr_idx = mdu_reg__rdst_idx_i;
        update_gpsr_data = mdu_reg__rdst_data_i;
    end
end

always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
        for(integer i=0; i<32; i=i+1) begin
            gpsr[i] <= `TCQ DWTH'(0);
        end
    end else begin
        if(update_gpsr_en) begin
            gpsr[update_gpsr_idx] <= `TCQ update_gpsr_data;
        end
    end
end

always_comb begin
    if(update_gpsr_en && (update_gpsr_idx == dec_reg__rs1_idx_i)) begin
        reg_dec__rs1_reg_o = update_gpsr_data;
    end else begin
        reg_dec__rs1_reg_o = gpsr[dec_reg__rs1_idx_i];
    end
end

always_comb begin
    if(update_gpsr_en && (update_gpsr_idx == dec_reg__rs2_idx_i)) begin
        reg_dec__rs2_reg_o = update_gpsr_data;
    end else begin
        reg_dec__rs2_reg_o = gpsr[dec_reg__rs2_idx_i];
    end
end

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off

// synopsys translate_on
endmodule : sy_ppl_reg

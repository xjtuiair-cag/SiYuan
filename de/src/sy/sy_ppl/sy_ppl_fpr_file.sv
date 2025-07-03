// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_fpr_file.v
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

module sy_ppl_fpr_file
    import sy_pkg::*;
# (
    parameter READ_PORT = 4
)(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                                   clk_i,                      
    input   logic                                   rst_i,                      
    // =====================================
    // [to ppl_dec]
    input   logic[READ_PORT-1:0][PHY_REG_WTH-1:0]   fpr_rd_idx_i,
    output  logic[READ_PORT-1:0][DWTH-1:0]          fpr_rd_data_o,
    // =====================================
    // [from ppl_lsu]
    input   logic                                   lsu_reg__rdst_en_i,
    input   logic[PHY_REG_WTH-1:0]                  lsu_reg__rdst_idx_i,
    input   logic[DWTH-1:0]                         lsu_reg__rdst_data_i,
    // =====================================
    // [from ppl_fpu]
    input   logic                                   fpu_reg__rdst_en_i,
    input   logic[PHY_REG_WTH-1:0]                  fpu_reg__rdst_idx_i,
    input   logic[DWTH-1:0]                         fpu_reg__rdst_data_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================


//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic[DWTH-1:0]                 fpr[PHY_FP_REG-1:0];
//======================================================================================================================
// Instance
//======================================================================================================================
    // Update Float-Point Register
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for(integer i=0; i<PHY_FP_REG; i=i+1) begin
                fpr[i] <= `TCQ DWTH'(0);
            end
        end else begin
            for(integer i=0; i<PHY_FP_REG; i=i+1) begin
                if (lsu_reg__rdst_en_i && lsu_reg__rdst_idx_i == i) begin
                    fpr[i] <= `TCQ lsu_reg__rdst_data_i;
                end
                if (fpu_reg__rdst_en_i && fpu_reg__rdst_idx_i == i) begin
                    fpr[i] <= `TCQ fpu_reg__rdst_data_i;
                end
            end
        end
    end

    // bypass data
    always_comb begin
        for(integer i=0; i<READ_PORT; i=i+1) begin
            fpr_rd_data_o[i] = fpr[fpr_rd_idx_i[i]];
            // if (lsu_reg__rdst_en_i && lsu_reg__rdst_idx_i == fpr_rd_idx_i[i]) begin
            //     fpr_rd_data_o[i] = lsu_reg__rdst_data_i;
            // end 
            // if (fpu_reg__rdst_en_i && fpu_reg__rdst_idx_i == fpr_rd_idx_i[i]) begin
            //     fpr_rd_data_o[i] = fpu_reg__rdst_data_i;
            // end
        end
    end

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off

// synopsys translate_on
endmodule : sy_ppl_fpr_file

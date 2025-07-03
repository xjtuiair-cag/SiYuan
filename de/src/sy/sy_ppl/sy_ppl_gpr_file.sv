// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_gpr_file.v
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

module sy_ppl_gpr_file
    import sy_pkg::*;
# (
    parameter READ_PORT = 5
)(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                                   clk_i,                      
    input   logic                                   rst_i,                      
    // =====================================
    // [to ppl_dec]
    input   logic[READ_PORT-1:0][PHY_REG_WTH-1:0]   gpr_rd_idx_i,
    output  logic[READ_PORT-1:0][DWTH-1:0]          gpr_rd_data_o,
    // =====================================
    // [from ppl_alu]
    input   logic                                   alu_reg__rdst_en_i,
    input   logic[PHY_REG_WTH-1:0]                  alu_reg__rdst_idx_i,
    input   logic[DWTH-1:0]                         alu_reg__rdst_data_i,
    // =====================================
    // [from ppl_alu]
    input   logic                                   csr_reg__rdst_en_i,
    input   logic[PHY_REG_WTH-1:0]                  csr_reg__rdst_idx_i,
    input   logic[DWTH-1:0]                         csr_reg__rdst_data_i,
    // =====================================
    // [from ppl_lsu]
    input   logic                                   lsu_reg__rdst_en_i,
    input   logic[PHY_REG_WTH-1:0]                  lsu_reg__rdst_idx_i,
    input   logic[DWTH-1:0]                         lsu_reg__rdst_data_i,
    // =====================================
    // [from ppl_mdu]
    input   logic                                   mdu_reg__rdst_en_i,
    input   logic[PHY_REG_WTH-1:0]                  mdu_reg__rdst_idx_i,
    input   logic[DWTH-1:0]                         mdu_reg__rdst_data_i,
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
    logic[DWTH-1:0]                 gpsr[PHY_REG-1:0];
//======================================================================================================================
// Instance
//======================================================================================================================
    // Update General Purpose Register
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for(integer i=0; i<PHY_REG; i=i+1) begin
                gpsr[i] <= `TCQ DWTH'(0);
            end
        end else begin
            for(integer i=1; i<PHY_REG; i=i+1) begin
                if (alu_reg__rdst_en_i && alu_reg__rdst_idx_i == i) begin
                    gpsr[i] <= `TCQ alu_reg__rdst_data_i;
                end
                if (csr_reg__rdst_en_i && csr_reg__rdst_idx_i == i) begin
                    gpsr[i] <= `TCQ csr_reg__rdst_data_i;
                end
                if (mdu_reg__rdst_en_i && mdu_reg__rdst_idx_i == i) begin
                    gpsr[i] <= `TCQ mdu_reg__rdst_data_i;
                end
                if (lsu_reg__rdst_en_i && lsu_reg__rdst_idx_i == i) begin
                    gpsr[i] <= `TCQ lsu_reg__rdst_data_i;
                end
                if (fpu_reg__rdst_en_i && fpu_reg__rdst_idx_i == i) begin
                    gpsr[i] <= `TCQ fpu_reg__rdst_data_i;
                end
            end
            gpsr[0] <= DWTH'(0);
        end
    end

    // bypass data
    always_comb begin
        for(integer i=0; i<READ_PORT; i=i+1) begin
            gpr_rd_data_o[i] = gpsr[gpr_rd_idx_i[i]];
            // if (alu_reg__rdst_en_i && alu_reg__rdst_idx_i == gpr_rd_idx_i[i]) begin 
            //     gpr_rd_data_o[i] = alu_reg__rdst_data_i;
            // end
            // if (csr_reg__rdst_en_i && csr_reg__rdst_idx_i == gpr_rd_idx_i[i]) begin 
            //     gpr_rd_data_o[i] = csr_reg__rdst_data_i;
            // end
            // if (mdu_reg__rdst_en_i && mdu_reg__rdst_idx_i == gpr_rd_idx_i[i]) begin
            //     gpr_rd_data_o[i] = mdu_reg__rdst_data_i;
            // end
            // if (lsu_reg__rdst_en_i && lsu_reg__rdst_idx_i == gpr_rd_idx_i[i]) begin
            //     gpr_rd_data_o[i] = lsu_reg__rdst_data_i;
            // end
            // if (fpu_reg__rdst_en_i && fpu_reg__rdst_idx_i == gpr_rd_idx_i[i]) begin
            //     gpr_rd_data_o[i] = fpu_reg__rdst_data_i;
            // end
            if (gpr_rd_idx_i[i] == '0) begin
                gpr_rd_data_o[i] = DWTH'(0);      // 0 reg
            end
        end
    end

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off

// synopsys translate_on
endmodule : sy_ppl_gpr_file

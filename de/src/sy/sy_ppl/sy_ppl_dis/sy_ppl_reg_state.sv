// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_reg_state.v
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

module sy_ppl_reg_state
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset & flush]
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    // ====================================
    // [From dispatch]
    input   logic                           dispatch_avail_i,
    input   logic[PHY_REG_WTH-1:0]          phy_rs1_idx_i,
    input   logic[PHY_REG_WTH-1:0]          phy_rs2_idx_i,
    input   logic[PHY_REG_WTH-1:0]          phy_rs3_idx_i,
    input   logic[PHY_REG_WTH-1:0]          phy_rdst_idx_i,
    input   logic                           rs1_is_fp_i,
    input   logic                           rs2_is_fp_i,
    input   logic                           rdst_is_en_i,
    input   logic                           rdst_is_fp_i,

    output  logic                           rs1_state_o,
    output  logic                           rs2_state_o,
    output  logic                           rs3_state_o,
    // ====================================
    // [Update state]
    // ALU
    input   logic                           alu_update_en_i,
    input   logic[PHY_REG_WTH-1:0]          alu_update_idx_i,
    // CSR
    input   logic                           csr_update_en_i,
    input   logic[PHY_REG_WTH-1:0]          csr_update_idx_i,
    // LSU
    input   logic                           lsu_update_en_i,
    input   logic                           lsu_update_is_fp_i,
    input   logic[PHY_REG_WTH-1:0]          lsu_update_idx_i,
    // MDU
    input   logic                           mdu_update_en_i,
    input   logic[PHY_REG_WTH-1:0]          mdu_update_idx_i,
    // FPU
    input   logic                           fpu_update_en_i,
    input   logic                           fpu_update_is_fp_i,
    input   logic[PHY_REG_WTH-1:0]          fpu_update_idx_i
);
//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic[PHY_REG-1:0]                      gpr_reg_state_d,gpr_reg_state_q;  // 1 indicate the reg is ready
    logic[PHY_REG-1:0]                      fp_reg_state_d,fp_reg_state_q;
    logic                                   gpr_rs1_state;
    logic                                   gpr_rs2_state;
    logic                                   fp_rs1_state;
    logic                                   fp_rs2_state;
    logic                                   fp_rs3_state;

//======================================================================================================================
// Read reg state
//======================================================================================================================
    always_comb begin : gpr_rs1_state_lookup
        gpr_rs1_state = gpr_reg_state_q[phy_rs1_idx_i];
        // awake the reg
        if ((alu_update_en_i && alu_update_idx_i == phy_rs1_idx_i) || 
            (csr_update_en_i && csr_update_idx_i == phy_rs1_idx_i) || 
            (lsu_update_en_i && lsu_update_idx_i == phy_rs1_idx_i && !lsu_update_is_fp_i) || 
            (mdu_update_en_i && mdu_update_idx_i == phy_rs1_idx_i) || 
            (fpu_update_en_i && fpu_update_idx_i == phy_rs1_idx_i && !fpu_update_is_fp_i)
        ) begin
            gpr_rs1_state = 1'b1;   // Ready        
        end 
    end
    always_comb begin : gpr_rs2_state_lookup
        gpr_rs2_state = gpr_reg_state_q[phy_rs2_idx_i];
        if ((alu_update_en_i && alu_update_idx_i == phy_rs2_idx_i) || 
            (csr_update_en_i && csr_update_idx_i == phy_rs2_idx_i) || 
            (lsu_update_en_i && lsu_update_idx_i == phy_rs2_idx_i && !lsu_update_is_fp_i) || 
            (mdu_update_en_i && mdu_update_idx_i == phy_rs2_idx_i) || 
            (fpu_update_en_i && fpu_update_idx_i == phy_rs2_idx_i && !fpu_update_is_fp_i)
        ) begin
            gpr_rs2_state = 1'b1;   // Ready        
        end 
    end
    always_comb begin : fp_rs1_state_lookup
        fp_rs1_state = fp_reg_state_q[phy_rs1_idx_i];
        if ((lsu_update_en_i && lsu_update_idx_i == phy_rs1_idx_i && lsu_update_is_fp_i) || 
            (fpu_update_en_i && fpu_update_idx_i == phy_rs1_idx_i && fpu_update_is_fp_i)
        ) begin
            fp_rs1_state = 1'b1;   // Ready        
        end 
    end
    always_comb begin : fp_rs2_state_lookup
        fp_rs2_state = fp_reg_state_q[phy_rs2_idx_i];
        if ((lsu_update_en_i && lsu_update_idx_i == phy_rs2_idx_i && lsu_update_is_fp_i) || 
            (fpu_update_en_i && fpu_update_idx_i == phy_rs2_idx_i && fpu_update_is_fp_i)
        ) begin
            fp_rs2_state = 1'b1;   // Ready        
        end 
    end
    always_comb begin : fp_rs3_state_lookup
        fp_rs3_state = fp_reg_state_q[phy_rs3_idx_i];
        if ((lsu_update_en_i && lsu_update_idx_i == phy_rs3_idx_i && lsu_update_is_fp_i) || 
            (fpu_update_en_i && fpu_update_idx_i == phy_rs3_idx_i && fpu_update_is_fp_i)
        ) begin
            fp_rs3_state = 1'b1;   // Ready        
        end 
    end

    assign rs1_state_o   = rs1_is_fp_i ? fp_rs1_state : gpr_rs1_state;
    assign rs2_state_o   = rs2_is_fp_i ? fp_rs2_state : gpr_rs2_state;
    assign rs3_state_o   = fp_rs3_state;
//======================================================================================================================
// Set reg state
//======================================================================================================================
    always_comb begin : set_gpr_reg
        gpr_reg_state_d = gpr_reg_state_q;
        for (integer i=1; i<PHY_REG; i=i+1) begin
            // set state       
            if ((dispatch_avail_i && rdst_is_en_i && !rdst_is_fp_i && i == phy_rdst_idx_i)) begin
                gpr_reg_state_d[i] =  1'b0; // 0 indicate the reg is not ready
            end
            // clr satte
            if ((alu_update_en_i && alu_update_idx_i == i) || 
                (csr_update_en_i && csr_update_idx_i == i) || 
                (lsu_update_en_i && lsu_update_idx_i == i && !lsu_update_is_fp_i) || 
                (mdu_update_en_i && mdu_update_idx_i == i) || 
                (fpu_update_en_i && fpu_update_idx_i == i && !fpu_update_is_fp_i)
            ) begin
                gpr_reg_state_d[i] = 1'b1;   // Ready        
            end 
            if (flush_i) begin
                gpr_reg_state_d[i] = 1'b1;
            end
        end
        // gpr 0 always ready
        gpr_reg_state_d[0] = 1'b1;
    end

    always_comb begin : set_fp_reg
        fp_reg_state_d = fp_reg_state_q;
        for (integer i=0; i<PHY_REG; i=i+1) begin
            // set state       
            if ((dispatch_avail_i && rdst_is_en_i && rdst_is_fp_i && i == phy_rdst_idx_i)) begin
                fp_reg_state_d[i] = 1'b0;
            end
            // clr satte
            if ((lsu_update_en_i && lsu_update_idx_i == i && lsu_update_is_fp_i) || 
                (fpu_update_en_i && fpu_update_idx_i == i && fpu_update_is_fp_i)
            ) begin
                fp_reg_state_d[i] = 1'b1;   // Ready        
            end 
            if (flush_i) begin
                fp_reg_state_d[i] = 1'b1;
            end
        end
    end

    // Gerneral purpose register state
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0; i<PHY_REG; i=i+1) begin
                gpr_reg_state_q[i] <= `TCQ 1'b1;
            end
        end else begin
            for (integer i=0; i<PHY_REG; i=i+1) begin
                gpr_reg_state_q[i] <= `TCQ gpr_reg_state_d[i];
            end
        end
    end
    // Float point register state
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0; i<PHY_REG; i=i+1) begin
                fp_reg_state_q[i] <= `TCQ 1'b1;
            end
        end else begin
            for (integer i=0; i<PHY_REG; i=i+1) begin
                fp_reg_state_q[i] <= `TCQ fp_reg_state_d[i];
            end
        end
    end

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_reg_state

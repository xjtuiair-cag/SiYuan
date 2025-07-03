// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_fp_fl.v
// DEPARTMENT : CAG of IAIR
// AUTHOR     : shenghuanliu
// AUTHOR'S EMAIL :liushenghuan2002@gmail.com
// -----------------------------------------------------------------------------
// Ver 1.0  2025--04--03 initial version.
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

module sy_ppl_fp_fl
    import sy_pkg::*;
#(
    parameter       PHY_REG_NUM = 32
)(
    // =====================================
    // [clock & reset]
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      

    input   logic                           flush_i,

    output  logic                           fl_stall_o,
    // ====================================
    // [lookup free list]
    input   logic                           rdst_en_i,
    input   logic[4:0]                      arc_rdst_idx_i, 
    output  logic[PHY_REG_WTH-1:0]          phy_rdst_idx_o,
    // ====================================
    // [retire from ROB]
    input   logic                           rob_update_afl_en_i,    
    input   logic[PHY_REG_WTH-1:0]          rob_update_afl_phy_i,
    input   logic[PHY_REG_WTH-1:0]          rob_update_afl_old_phy_i
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                                   rdst_act;
    logic[PHY_REG-1:0]                      free_list;
    logic[PHY_REG-1:0]                      arc_free_list;
    logic                                   release_en;
    logic[PHY_REG_WTH-1:0]                  release_phy_reg;
    logic[PHY_REG_WTH-1:0]                  sel_phy_reg_idx;   
    logic                                   no_free_reg;

//======================================================================================================================
// Instance
//======================================================================================================================
    assign release_en        = rob_update_afl_en_i;
    assign release_phy_reg   = rob_update_afl_old_phy_i;

    // free list
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0;i<PHY_REG_NUM;i++) begin
                free_list[i]        <= `TCQ 1'b1;
            end
        end else begin
            // when exception occur, flush pipeline and reset free list
            if (flush_i) begin
                free_list <= arc_free_list;
            // set reg not free
            end else begin 
                if (rdst_en_i) begin
                    free_list[phy_rdst_idx_o] <= 1'b0;
                end 
                // when instr retire, release the old reg
                if (release_en) begin
                    free_list[release_phy_reg] <= 1'b1;
                end

            end
        end
    end

    always_comb begin : sel_phy_reg
        sel_phy_reg_idx = '0; 
        no_free_reg     = 1'b1;
        for (integer i=0;i<PHY_REG_NUM;i++) begin
            if (free_list[i]) begin  // i-th reg is free
                sel_phy_reg_idx = i;
                no_free_reg     = 1'b0;
            end
        end
    end
    assign phy_rdst_idx_o = sel_phy_reg_idx;
    assign fl_stall_o    = no_free_reg;

    // architecture free list
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0;i<PHY_REG_NUM;i++) begin
                arc_free_list[i] <= `TCQ 1'b1; 
            end
        end else begin
            if (rob_update_afl_en_i) begin
                arc_free_list[rob_update_afl_old_phy_i] <= 1'b1;   // release old phy reg
                arc_free_list[rob_update_afl_phy_i]     <= 1'b0;
            end
        end
    end

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_fp_fl

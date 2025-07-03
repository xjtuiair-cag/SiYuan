// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_fp_rat.v
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

module sy_ppl_fp_rat
    import sy_pkg::*;
#(
    parameter       PHY_REG_NUM = 32, 
    parameter       REG_WTH     = $clog2(PHY_REG_NUM)
)(
    // =====================================
    // [clock & reset]
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      

    input   logic                           flush_i,
    // ====================================
    // [lookup rat]
    input   logic[4:0]                      arc_rs1_idx_i, 
    input   logic[4:0]                      arc_rs2_idx_i, 
    input   logic[4:0]                      arc_rs3_idx_i, 
    input   logic[4:0]                      arc_rdst_idx_i, 

    output  logic[REG_WTH-1:0]              phy_rs1_idx_o,
    output  logic[REG_WTH-1:0]              phy_rs2_idx_o,
    output  logic[REG_WTH-1:0]              phy_rs3_idx_o,
    output  logic[REG_WTH-1:0]              phy_old_rdst_idx_o,

    input   logic                           rdst_en_i,      
    input   logic[REG_WTH-1:0]              phy_rdst_idx_i, // used to modify rat
    // ====================================
    // [from ROB]
    input   logic                           rob_update_arat_en_i,    
    input   logic[4:0]                      rob_update_arat_arc_i,
    input   logic[REG_WTH-1:0]              rob_update_arat_phy_i
);
//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic[31:0][REG_WTH-1:0]            rat;
    logic[31:0][REG_WTH-1:0]            arat;
//======================================================================================================================
// Instance
//======================================================================================================================
    // Register Alias Table (RAT)
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0;i<32;i++) begin
                rat[i]        <= `TCQ '0;
            end
        end else begin
            // when exception occur, flush pipeline and reset rat
            if (flush_i) begin
                for (integer i=0;i<32;i++) begin
                    rat[i]        <= `TCQ arat[i];
                end
            // set reg not free
            end else if(rdst_en_i) begin
                rat[arc_rdst_idx_i] <= phy_rdst_idx_i;
            end 
        end
    end
    // lookup rat 
    always_comb begin : map
        phy_rs1_idx_o       = rat[arc_rs1_idx_i]; 
        phy_rs2_idx_o       = rat[arc_rs2_idx_i];
        phy_rs3_idx_o       = rat[arc_rs3_idx_i];
        phy_old_rdst_idx_o  = rat[arc_rdst_idx_i];
    end

    // Architecture Register Alias Table (aRAT)
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0;i<32;i++) begin
                arat[i]        <= `TCQ '0;
            end
        end else begin
            // when exception occur, flush pipeline and reset rat
            if (rob_update_arat_en_i) begin
                arat[rob_update_arat_arc_i] <= rob_update_arat_phy_i;
            end
        end
    end


//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_fp_rat

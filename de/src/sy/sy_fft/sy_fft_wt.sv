// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_fft_wt.v
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

module sy_fft_wt
    import fft_pkg::*;
#(
)(
    input   logic                               clk_i,           
    input   logic                               rst_i,           
    // =====================================
    // -- exe read port
    input   logic                               exe_wt_rd_en_i,       // Read valid signal 
    input   logic[LM_ADDR_WTH-1:0]              exe_wt_rd_addr_i,     // Read address 
    output  logic[63:0]                         exe_wt_rd_data_o,     // Read data 
    // -- lsu 
    input   logic                               lsu_wt_wr_en_i,        // Write valid signal 
    input   logic[LM_ADDR_WTH-1:0]              lsu_wt_addr_i,         // Write address 
    input   logic[63:0]                         lsu_wt_wr_data_i       // Write data 
);
//======================================================================================================================
// Parameters
//======================================================================================================================
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic [WT_BANK_NUM-1:0]                exe_bank_rvld;
    logic [WT_BANK_NUM-1:0]                lsu_bank_wvld;

    logic [WT_BWTH-1:0]                    exe_rd_bank_dly;

    logic                                  mem_vld[WT_BANK_NUM-1:0];
    logic                                  mem_we[WT_BANK_NUM-1:0];
    logic [LM_AWTH-1:0]                    mem_addr[WT_BANK_NUM-1:0];
    logic [63:0]                           mem_wdata[WT_BANK_NUM-1:0];
    logic [63:0]                           mem_rdata[WT_BANK_NUM-1:0];
//======================================================================================================================
// Instance
//======================================================================================================================
    // Delay chains for Read command, used for selecting the bank of read data
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        exe_rd_bank_dly <= `TCQ {exe_wt_rd_addr_i[LM_DWTH+LM_AWTH+:WT_BWTH]};
    end

    // Control logic for each bank
    for(genvar gi=0; gi<WT_BANK_NUM; gi++) begin: lm_bank_blk
        assign lsu_bank_wvld[gi]   = lsu_wt_wr_en_i  && (lsu_wt_addr_i[LM_DWTH+LM_AWTH +: WT_BWTH] == gi);
        assign exe_bank_rvld[gi]   = exe_wt_rd_en_i  && (exe_wt_rd_addr_i[LM_DWTH+LM_AWTH +: WT_BWTH] == gi);

        assign mem_vld[gi] = exe_bank_rvld[gi] || lsu_bank_wvld[gi];
        assign mem_we[gi]  = lsu_bank_wvld[gi];
        assign mem_addr[gi] = exe_bank_rvld[gi] ? exe_wt_rd_addr_i[LM_DWTH+:LM_AWTH] : lsu_wt_addr_i[LM_DWTH+:LM_AWTH];
        assign mem_wdata[gi] = lsu_wt_wr_data_i;

        // Instance of On-Chip Memory
        sp_512x64sd1_wrap wt_item (
            .clk_i                          (clk_i),
            .vld_i                          (mem_vld[gi]),
            .we_i                           (mem_we[gi]),
            .addr_i                         (mem_addr[gi]),
            .wdata_i                        (mem_wdata[gi]),
            .wstrb_i                        (8'hFF),
            .rdata_o                        (mem_rdata[gi])
        );
    end
    assign exe_wt_rd_data_o = mem_rdata[exe_rd_bank_dly];
    // Control logic for each bank
    // assign lsu_bank_wvld   = lsu_wt_wr_en_i;
    // assign exe_bank_rvld   = exe_wt_rd_en_i;

    // assign mem_vld      = exe_bank_rvld || lsu_bank_wvld;
    // assign mem_we       = lsu_bank_wvld;
    // assign mem_addr     = exe_bank_rvld ? exe_wt_rd_addr_i[LM_DWTH+:LM_AWTH] : lsu_wt_addr_i[LM_DWTH+:LM_AWTH];
    // assign mem_wdata    = lsu_wt_wr_data_i;

    // // Instance of On-Chip Memory
    // sp_512x64sd1_wrap wt_item (
    //     .clk_i                          (clk_i),
    //     .vld_i                          (mem_vld),
    //     .we_i                           (mem_we),
    //     .addr_i                         (mem_addr),
    //     .wdata_i                        (mem_wdata),
    //     .wstrb_i                        (8'hFF),
    //     .rdata_o                        (mem_rdata)
    // );

    // assign exe_wt_rd_data_o = mem_rdata;

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule 
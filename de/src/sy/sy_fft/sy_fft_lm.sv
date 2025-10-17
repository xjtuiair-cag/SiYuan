// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_fft_lm.v
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

module sy_fft_lm
    import fft_pkg::*;
#(
)(
    input   logic                               clk_i,           
    input   logic                               rst_i,           
    // =====================================
    // -- exe read port
    input   logic                               exe_lm_rd_en_i,       // Read valid signal 
    input   logic[1:0][LM_ADDR_WTH-1:0]         exe_lm_rd_addr_i,     // Read address 
    output  logic[1:0][63:0]                    exe_lm_rd_data_o,     // Read data 
    // -- exe write port
    input   logic                               exe_lm_wr_en_i,        // Write valid signal 
    input   logic[1:0][LM_ADDR_WTH-1:0]         exe_lm_wr_addr_i,      // Write address 
    input   logic[1:0][63:0]                    exe_lm_wr_data_i,      // Write data 
    // -- lsu 
    input   logic                               lsu_lm_wr_en_i,        // Write valid signal 
    input   logic                               lsu_lm_rd_en_i,        // Read valid signal 
    input   logic[LM_ADDR_WTH-1:0]              lsu_lm_addr_i,         // Write address 
    input   logic[1:0][63:0]                    lsu_lm_wr_data_i,      // Write data 
    output  logic[1:0][63:0]                    lsu_lm_rd_data_o       // Read data 
);
//======================================================================================================================
// Parameters
//======================================================================================================================
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic [BANK_NUM-1:0]                   exe_bank_wvld;
    logic [BANK_NUM-1:0]                   exe_bank_rvld;
    logic [BANK_NUM-1:0]                   load_bank_wvld;
    logic [BANK_NUM-1:0]                   store_bank_rvld;

    logic [LM_BWTH-1:0]                    exe_wr_bank_dly;
    logic [LM_BWTH-1:0]                    exe_rd_bank_dly;
    logic [LM_BWTH-1:0]                    load_wr_bank_dly;
    logic [LM_BWTH-1:0]                    store_rd_bank_dly;

    logic [BANK_NUM-1:0]                   mem_vld;
    logic [BANK_NUM-1:0]                   mem_we;
    logic [1:0][LM_AWTH-1:0]               mem_addr[BANK_NUM-1:0];
    logic [1:0][63:0]                      mem_wdata[BANK_NUM-1:0];
    logic [1:0][63:0]                      mem_rdata[BANK_NUM-1:0];
//======================================================================================================================
// Instance
//======================================================================================================================
    // Delay chains for Read command, used for selecting the bank of read data
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        // exe_wr_bank_dly     <= `TCQ {exe_lm_wr_addr_i[0][LM_DWTH+LM_AWTH+:LM_BWTH]};
        exe_rd_bank_dly     <= `TCQ {exe_lm_rd_addr_i[0][LM_DWTH+LM_AWTH+:LM_BWTH]};
        // load_wr_bank_dly    <= `TCQ {load_lm_wr_addr_i[LM_DWTH+LM_AWTH+:LM_BWTH]};
        store_rd_bank_dly   <= `TCQ {lsu_lm_addr_i[LM_DWTH+LM_AWTH+:LM_BWTH]};
    end

    // Control logic for each bank
    for(genvar gi=0; gi<BANK_NUM; gi++) begin: lm_bank_blk
        assign exe_bank_wvld[gi]    = exe_lm_wr_en_i  && (exe_lm_wr_addr_i[0][LM_DWTH+LM_AWTH +: LM_BWTH] == gi);
        assign load_bank_wvld[gi]   = lsu_lm_wr_en_i  && (lsu_lm_addr_i[LM_DWTH+LM_AWTH +: LM_BWTH] == gi);
        assign exe_bank_rvld[gi]    = exe_lm_rd_en_i  && (exe_lm_rd_addr_i[0][LM_DWTH+LM_AWTH +: LM_BWTH] == gi);
        assign store_bank_rvld[gi]  = lsu_lm_rd_en_i  && (lsu_lm_addr_i[LM_DWTH+LM_AWTH +: LM_BWTH] == gi);

        assign mem_vld[gi] = exe_bank_wvld[gi] || exe_bank_rvld[gi] || load_bank_wvld[gi] || store_bank_rvld[gi];
        assign mem_we[gi]  = exe_bank_wvld[gi] || load_bank_wvld[gi];
        assign mem_addr[gi] = exe_bank_wvld[gi] ? {exe_lm_wr_addr_i[1][LM_DWTH+:LM_AWTH],exe_lm_wr_addr_i[0][LM_DWTH+:LM_AWTH]} 
                            : exe_bank_rvld[gi] ? {exe_lm_rd_addr_i[1][LM_DWTH+:LM_AWTH],exe_lm_rd_addr_i[0][LM_DWTH+:LM_AWTH]} 
                            : {lsu_lm_addr_i[LM_DWTH+:LM_AWTH],lsu_lm_addr_i[LM_DWTH+:LM_AWTH]};
        assign mem_wdata[gi] = exe_bank_wvld[gi] ? exe_lm_wr_data_i : lsu_lm_wr_data_i;

        // Instance of On-Chip Memory
        sp_512x64sd1_wrap lm_item[1:0] (
            .clk_i                          ({clk_i,clk_i}),
            .vld_i                          ({mem_vld[gi],mem_vld[gi]}),
            .we_i                           ({mem_we[gi],mem_we[gi]}),
            .addr_i                         (mem_addr[gi]),
            .wdata_i                        (mem_wdata[gi]),
            .wstrb_i                        ({8'hFF,8'hFF}),
            .rdata_o                        (mem_rdata[gi])
        );
    end

    assign exe_lm_rd_data_o = mem_rdata[exe_rd_bank_dly];
    assign lsu_lm_rd_data_o = mem_rdata[store_rd_bank_dly];

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule 
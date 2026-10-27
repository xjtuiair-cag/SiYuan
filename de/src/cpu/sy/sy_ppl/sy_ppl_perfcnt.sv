// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_perfcnt.v
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

module sy_ppl_perfcnt
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                            clk_i,                      
    input   logic                            rst_i,                      
    // =====================================
    // [from CSR regfile]
    input   logic  [4:0]                     perf_addr_i,    // read/write address to performance counter module (up to 29 aux counters possible in riscv encoding.h)
    input   logic  [63:0]                    perf_data_i,    // read data from performance counter module
    output  logic  [63:0]                    perf_data_o,    // write data to performance counter module
    input   logic                            perf_we_o,
    // =====================================
    // [control signals]
    input   logic                            alu_instr_retire_i,
    input   logic                            mdu_instr_retire_i,
    input   logic                            jump_instr_i,
    input   logic                            mispred_i,
    input   logic                            ic_access_i,
    input   logic                            ic_miss_i,
    input   logic                            dc_access_i,
    input   logic                            dc_miss_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam logic[4:0] RETIRE_INSTR  = CSR_INSTRET[4:0];
    localparam logic[4:0] TOT_JBR_INSTR = CSR_TOT_JBR_INSTR[4:0];
    localparam logic[4:0] MISPRED_INSTR = CSR_MISPRED[4:0];
    localparam logic[4:0] TOT_IC_ACCESS = CSR_IC_ACCESS[4:0];
    localparam logic[4:0] TOT_DC_ACCESS = CSR_DC_ACCESS[4:0];
    localparam logic[4:0] IC_MISS       = CSR_IC_MISS[4:0];
    localparam logic[4:0] DC_MISS       = CSR_DC_MISS[4:0];
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic [63:0] retire_instr_d,  retire_instr_q;
    logic [63:0] tot_jbr_instr_d, tot_jbr_instr_q;
    logic [63:0] mispred_instr_d, mispred_instr_q;
    logic [63:0] tot_ic_access_d, tot_ic_access_q;
    logic [63:0] tot_dc_access_d, tot_dc_access_q;
    logic [63:0] ic_miss_d, ic_miss_q;
    logic [63:0] dc_miss_d, dc_miss_q;
//======================================================================================================================
// Instance
//======================================================================================================================
    // read performance counter
    always_comb begin
        perf_data_o = 64'b0;   
        unique case (perf_addr_i) 
            RETIRE_INSTR  : perf_data_o = retire_instr_q;
            TOT_JBR_INSTR : perf_data_o = tot_jbr_instr_q;
            MISPRED_INSTR : perf_data_o = mispred_instr_q;
            TOT_IC_ACCESS : perf_data_o = tot_ic_access_q;
            TOT_DC_ACCESS : perf_data_o = tot_dc_access_q;
            IC_MISS       : perf_data_o = ic_miss_q;
            DC_MISS       : perf_data_o = dc_miss_q;
            default: ;
        endcase
    end
    // write performance counter
    always_ff @(`DFF_CR(clk_i,rst_i)) begin
        if (`DFF_IS_R(rst_i)) begin
            mispred_instr_q  <= 64'b0;
            retire_instr_q   <= 64'b0;
            tot_jbr_instr_q  <= 64'b0;
            tot_ic_access_q  <= 64'b0;
            tot_dc_access_q  <= 64'b0;
            ic_miss_q        <= 64'b0;
            dc_miss_q        <= 64'b0;
        end else begin
            if (perf_we_o && perf_addr_i == RETIRE_INSTR) begin
                retire_instr_q <= perf_data_i;
            end else if (alu_instr_retire_i || mdu_instr_retire_i) begin
                retire_instr_q <= retire_instr_q + 1;
            end
            if (perf_we_o && perf_addr_i == TOT_JBR_INSTR) begin
                tot_jbr_instr_q <= perf_data_i;
            end else if (jump_instr_i) begin
                tot_jbr_instr_q <= tot_jbr_instr_q + 1;
            end
            if (perf_we_o && perf_addr_i == MISPRED_INSTR) begin
                mispred_instr_q <= perf_data_i;
            end else if (mispred_i) begin
                mispred_instr_q <= mispred_instr_q + 1;
            end
            if (perf_we_o && perf_addr_i == TOT_IC_ACCESS) begin
                tot_ic_access_q <= perf_data_i;
            end else if (ic_access_i) begin
                tot_ic_access_q <= tot_ic_access_q + 1;
            end
            if (perf_we_o && perf_addr_i == TOT_DC_ACCESS) begin
                tot_dc_access_q <= perf_data_i;
            end else if (dc_access_i) begin
                tot_dc_access_q <= tot_dc_access_q + 1;
            end
            if (perf_we_o && perf_addr_i == IC_MISS) begin
                ic_miss_q <= perf_data_i;
            end else if (ic_miss_i) begin
                ic_miss_q <= ic_miss_q + 1;
            end
            if (perf_we_o && perf_addr_i == DC_MISS) begin
                dc_miss_q <= perf_data_i;
            end else if (dc_miss_i) begin
                dc_miss_q <= dc_miss_q + 1;
            end
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on

endmodule : sy_ppl_perfcnt

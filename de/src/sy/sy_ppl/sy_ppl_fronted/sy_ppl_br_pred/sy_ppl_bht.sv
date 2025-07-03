// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_bht.v
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

module sy_ppl_bht 
    import  sy_pkg::*;
#(
    parameter int BHT_ENTRIES = 256,
    parameter int BHT_ENTRY_WTH = $clog2(BHT_ENTRIES)
)(
    // =====================================
    // [clock & reset & flush]
    input  logic                        clk_i,
    input  logic                        rst_i,
    input  logic                        flush_i,
    // =====================================
    // [Virtual address from fronted]
    input  logic[AWTH-1:0]              vaddr_i,
    // =====================================
    // [Update when retire]
    input  bht_update_t                 bht_update_i,
    // =====================================
    // [BHT prediction]
    output bht_pred_t                   bht_pred_o 
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam BHT_INDEX_LSB = 1;
    localparam BHT_INDEX_MSB = BHT_INDEX_LSB + BHT_ENTRY_WTH;
    typedef struct packed {
        logic       vld;
        logic[1:0]  sat_cnt; // saturation counter
    } bht_t;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    bht_t[BHT_ENTRIES-1:0]              bht_ram_d,bht_ram_q;
    logic[BHT_ENTRY_WTH-1:0]            update_idx;   
    logic[BHT_ENTRY_WTH-1:0]            read_idx;   
    logic[1:0]                          update_sat_cnt;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign update_idx = bht_update_i.pc[BHT_INDEX_MSB-1:BHT_INDEX_LSB];
    assign update_sat_cnt = bht_ram_q[update_idx].sat_cnt;
    always_comb begin : bht_update
        bht_ram_d = bht_ram_q;    
        if (bht_update_i.vld) begin
            bht_ram_d[update_idx].vld = 1'b1;
            if (update_sat_cnt == 2'b11) begin
                if (!bht_update_i.taken) begin
                    bht_ram_d[update_idx].sat_cnt = update_sat_cnt - 1;
                end
            end else if (update_sat_cnt == 2'b00) begin
                if (bht_update_i.taken) begin
                    bht_ram_d[update_idx].sat_cnt = update_sat_cnt + 1;
                end
            end begin
                if (bht_update_i.taken) begin
                    bht_ram_d[update_idx].sat_cnt = update_sat_cnt + 1;
                end else begin
                    bht_ram_d[update_idx].sat_cnt = update_sat_cnt - 1;
                end
            end
        end
    end

    assign read_idx = vaddr_i[BHT_INDEX_MSB-1:BHT_INDEX_LSB];
    always_ff @(posedge clk_i) begin
        bht_pred_o.vld      <= bht_ram_q[read_idx].vld;
        bht_pred_o.taken    <= bht_ram_q[read_idx].sat_cnt[1];
    end
//======================================================================================================================
// Registers
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            bht_ram_q <= '0;
        end else begin
            if (flush_i) begin
                for (integer i = 0; i < BHT_ENTRIES; i++) begin
                    bht_ram_q[i].vld <= 1'b0;
                    bht_ram_q[i].sat_cnt <= 2'b10;
                end
            end else begin
                bht_ram_q <= bht_ram_d;
            end
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule

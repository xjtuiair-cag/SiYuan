// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_pht.v
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

module sy_ppl_pht 
    import  sy_pkg::*;
(
    // =====================================
    // [clock & reset & flush]
    input  logic                        clk_i,
    input  logic                        rst_i,
    input  logic                        flush_i,
    // =====================================
    // [Virtual address from fronted]
    input  logic[AWTH-1:0]              vaddr_i,
    input  logic[BHT_WTH-1:0]           bhr_i,
    // =====================================
    // [Update when retire]
    input  pht_update_t                 pht_update_i,
    // =====================================
    // [BHT prediction]
    output pht_pred_t                   pht_pred_o 
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam PHT_INDEX_LSB = 2;
    localparam PHT_INDEX_MSB = PHT_INDEX_LSB + PHT_ENTRY_WTH;

    typedef struct packed {
        logic       vld;
        logic[1:0]  sat_cnt; // saturation counter
        // logic       reserved;
    } pht_t;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    pht_t[PHT_ENTRIES-1:0]              pht_ram_d,pht_ram_q;
    logic[PHT_ENTRY_WTH-1:0]            update_idx;   
    logic[PHT_ENTRY_WTH-1:0]            read_idx;   
    logic[1:0]                          update_sat_cnt;
//======================================================================================================================
// Instance
//======================================================================================================================
    // assign update_idx = pht_update_i.pc[PHT_INDEX_MSB-1:PHT_INDEX_LSB] ^ {pht_update_i.bhr,pht_update_i.pc[3:2]};
    assign update_idx = pht_update_i.pc[PHT_INDEX_MSB-1:PHT_INDEX_LSB] ^ pht_update_i.bhr;
    assign update_sat_cnt = pht_ram_q[update_idx].sat_cnt;
    always_comb begin : bht_update
        pht_ram_d = pht_ram_q;    
        if (pht_update_i.vld) begin
            pht_ram_d[update_idx].vld = 1'b1;
            if (update_sat_cnt == 2'b11) begin
                if (!pht_update_i.taken) begin
                    pht_ram_d[update_idx].sat_cnt = update_sat_cnt - 1;
                end
            end else if (update_sat_cnt == 2'b00) begin
                if (pht_update_i.taken) begin
                    pht_ram_d[update_idx].sat_cnt = update_sat_cnt + 1;
                end
            end else begin
                if (pht_update_i.taken) begin
                    pht_ram_d[update_idx].sat_cnt = update_sat_cnt + 1;
                end else begin
                    pht_ram_d[update_idx].sat_cnt = update_sat_cnt - 1;
                end
            end
        end
    end

    assign read_idx = vaddr_i[PHT_INDEX_MSB-1:PHT_INDEX_LSB] ^ bhr_i;
    assign pht_pred_o.vld    = pht_ram_q[read_idx].vld;
    assign pht_pred_o.taken  = pht_ram_q[read_idx].sat_cnt[1];
//======================================================================================================================
// Registers
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            pht_ram_q <= '0;
        end else begin
            if (flush_i) begin
                for (integer i = 0; i < PHT_ENTRIES; i++) begin
                    pht_ram_q[i].vld <= 1'b0;
                    pht_ram_q[i].sat_cnt <= 2'b10;
                end
            end else begin
                pht_ram_q <= pht_ram_d;
            end
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule

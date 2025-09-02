// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_L2_cache_lru.v
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

module sy_L2_cache_lru
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    // =====================================
    // [update lru]
    input   logic                           update_lru_i,
    input   logic[L2_CACHE_SET_WTH-1:0]     update_lru_set_i,
    input   logic[L2_CACHE_WAY_WTH-1:0]     update_lru_way_i,
    // =====================================
    // [lookup lru]
    input   logic[L2_CACHE_SET_WTH-1:0]     lookup_lru_set_i,
    output  logic[L2_CACHE_WAY_WTH-1:0]     lookup_lru_way_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                               clru0[L2_CACHE_SET_SIZE-1:0];
    logic[1:0]                          clru1[L2_CACHE_SET_SIZE-1:0];
    logic[3:0]                          clru2[L2_CACHE_SET_SIZE-1:0];
    logic[L2_CACHE_WAY_WTH-1:0]         clru_mark[L2_CACHE_SET_SIZE-1:0];
//======================================================================================================================
// LRU
//======================================================================================================================
always_ff @(`DFF_CR(clk_i, rst_i)) begin 
    if (`DFF_IS_R(rst_i)) begin
        lookup_lru_way_o <= L2_CACHE_WAY_WTH'(0);
    end else begin
        lookup_lru_way_o <= clru_mark[lookup_lru_set_i];
    end
end

if(L2_CACHE_WAY_NUM == 1) begin
    always_comb begin
        for(integer i=0; i<L2_CACHE_SET_SIZE; i++) begin
            clru_mark[i] = 1'b0;
        end
    end
end else if(L2_CACHE_WAY_NUM == 2) begin
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for(integer i=0; i<L2_CACHE_SET_SIZE; i++) begin
                clru0[i] <= `TCQ 1'b0;
            end
        end else begin
            // if(ppl_vld_dly[0] && dc_hit_o) begin
            //     clru0[ppl_addr_dly[0].set] <= `TCQ ppl_hit_way;
            // end
            if(update_lru_i) begin
                clru0[update_lru_set_i] <= `TCQ update_lru_way_i;
            end
        end
    end
    always_comb begin
        for(integer i=0; i<L2_CACHE_SET_SIZE; i++) begin
            clru_mark[i] = !clru0[i];
        end
    end
end else if(L2_CACHE_WAY_NUM == 4) begin
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for(integer i=0; i<L2_CACHE_SET_SIZE; i++) begin
                clru0[i] <= `TCQ 1'b0;
                clru1[i] <= `TCQ 2'h0;
            end
        end else begin
            if(update_lru_i) begin
                clru0[update_lru_set_i] <= `TCQ update_lru_way_i[0];
                if(!update_lru_way_i[0]) begin
                    clru1[update_lru_set_i][0] <= `TCQ update_lru_way_i[1];
                end else begin
                    clru1[update_lru_set_i][1] <= `TCQ update_lru_way_i[1];
                end
            end
        end
    end
    always_comb begin
        for(integer i=0; i<L2_CACHE_SET_SIZE; i++) begin
            clru_mark[i][0] = !clru0[i];
            clru_mark[i][1] = !clru0[i] ? !clru1[1] : !clru1[0];
        end
    end
end else if(L2_CACHE_WAY_NUM == 8) begin
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for(integer i=0; i<L2_CACHE_SET_SIZE; i++) begin
                clru0[i] <= `TCQ 1'b0;
                clru1[i] <= `TCQ 2'h0;
                clru2[i] <= `TCQ 4'h0;
            end
        end else begin
            if(update_lru_i) begin
                clru0[update_lru_set_i] <= `TCQ update_lru_way_i[0];
                if(!update_lru_way_i[0]) begin
                    clru1[update_lru_set_i][0] <= `TCQ update_lru_way_i[1];
                    if(!update_lru_way_i[1]) begin
                        clru2[update_lru_set_i][0] <= `TCQ update_lru_way_i[2];
                    end else begin
                        clru2[update_lru_set_i][1] <= `TCQ update_lru_way_i[2];
                    end
                end else begin
                    clru1[update_lru_set_i][1] <= `TCQ update_lru_way_i[1];
                    if(!update_lru_way_i[1]) begin
                        clru2[update_lru_set_i][2] <= `TCQ update_lru_way_i[2];
                    end else begin
                        clru2[update_lru_set_i][3] <= `TCQ update_lru_way_i[2];
                    end
                end
            end
        end
    end
    always_comb begin
        for(integer i=0; i<L2_CACHE_SET_SIZE; i++) begin
            clru_mark[i][0] = !clru0[i];
            clru_mark[i][1] = !clru0[i] ? !clru1[1] : !clru1[0];
            clru_mark[i][2] = !clru0[i] ? (!clru1[1] ? !clru2[3] : !clru2[2]) : (!clru1[0] ? !clru2[1] : !clru2[0]);
        end
    end
end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
// synopsys translate_off

// synopsys translate_on

endmodule : sy_L2_cache_lru

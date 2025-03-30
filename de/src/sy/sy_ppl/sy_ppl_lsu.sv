// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_lsu.v
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

module sy_ppl_lsu
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      // clock
    // -- <reset>
    input   logic                           rst_i,                      // reset
    // =====================================
    // [interface with ppl_mem stage]
    input   logic                           ppl_dmem__vld_i,
    input   logic[AWTH-1:0]                 ppl_dmem__addr_i,
    input   logic[DWTH-1:0]                 ppl_dmem__wdata_i,
    input   size_e                          ppl_dmem__size_i,
    input   mem_opcode_e                    ppl_dmem__opcode_i,
    input   amo_t                           ppl_dmem__amo_opcode_i,
    input   logic                           ppl_dmem__kill_i,
    output  logic                           dmem_ppl__hit_o,
    output  logic[DWTH-1:0]                 dmem_ppl__rdata_o,
    output  exception_t                     dmem_ppl__ex_o,

    // =====================================
    // [address translation request]
    output  logic                           lsu_mmu__req_o,
    output  logic[63:0]                     lsu_mmu__vaddr_o,
    output  logic                           lsu_mmu__is_store_o,
    input   logic                           mmu_lsu__dtlb_hit_i,
    input   logic                           mmu_lsu__valid_i,
    input   logic[63:0]                     mmu_lsu__paddr_i,
    input   exception_t                     mmu_lsu__ex_i,
    // =====================================
    // [dcache interface]
    output  dcache_req_t                    lsu_dcache__req_o,    
    input   dcache_rsp_t                    dcache_lsu__rsp_i  
);

//======================================================================================================================
// Parameters
//======================================================================================================================
typedef enum logic[2:0] {IDLE, TLB_MISS, WAIT_DATA, REPLAY, ACCESS_CACHE} state_e;
state_e state_d, state_q;

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
logic                       valid_q;
logic [AWTH-1:0]            addr_q;
logic [AWTH-1:0]            paddr_q, paddr_d;
logic [DWTH-1:0]            wdata_q;
size_e                      size_q;
mem_opcode_e                opcode_q;
amo_t                       amo_opcode;

logic                       is_store;
logic                       is_amo;
logic                       is_load;
logic                       misaligned;
logic [2:0]                 offset;
logic [2:0]                 offset_q;
logic [DWTH-1:0]            wr_data;
logic                       amo_cmd;
logic                       tlb_hit_dly1;
//======================================================================================================================
// other logic
//======================================================================================================================
// gen write data
assign offset = ppl_dmem__addr_i[2:0]; 
assign amo_cmd = (opcode_q == MEM_OP_SC) || (opcode_q == MEM_OP_AMO) || (opcode_q == MEM_OP_LR);
assign wr_data = ppl_dmem__wdata_i << (8*offset);

assign is_store = (opcode_q == MEM_OP_STORE || opcode_q == MEM_OP_ST_FP); 
assign is_load = (opcode_q == MEM_OP_LOAD || opcode_q == MEM_OP_LD_FP);
assign is_amo = (opcode_q == MEM_OP_SC) || (opcode_q == MEM_OP_AMO) || (opcode_q == MEM_OP_LR);
assign misaligned = (size_q == SIZE_HALF) ? (addr_q[0] != 1'h0): 
                    (size_q == SIZE_WORD) ? (addr_q[1:0] != 2'h0): 
                    (size_q == SIZE_DWORD) ? (addr_q[2:0] != 3'h0) : 1'b0;

assign lsu_mmu__vaddr_o = {addr_q >> 2, 2'h0};
assign lsu_mmu__is_store_o = (opcode_q == MEM_OP_STORE) || (opcode_q == MEM_OP_ST_FP) || (opcode_q == MEM_OP_SC) || (opcode_q == MEM_OP_AMO);
// dcache interface
assign lsu_dcache__req_o.addr_inx   =   addr_q[DCACHE_TAG_LSB-1:0];
assign lsu_dcache__req_o.addr_tag   =   paddr_d[DCACHE_TAG_MSB-1:DCACHE_TAG_LSB];
assign lsu_dcache__req_o.wdata      =   wdata_q;
assign lsu_dcache__req_o.we         =   is_store || (is_amo && opcode_q != MEM_OP_LR);
assign lsu_dcache__req_o.be         =   (size_q == SIZE_BYTE) ? (8'h1 << offset_q) : 
                                        (size_q == SIZE_HALF) ? (8'h3 << offset_q) : 
                                        (size_q == SIZE_WORD) ? (8'hF << offset_q) : 8'hFF;
assign lsu_dcache__req_o.size       =   size_q;
assign lsu_dcache__req_o.amo_op     =   amo_opcode;      

// return result
assign dmem_ppl__rdata_o = dcache_lsu__rsp_i.rdata;
assign lsu_dcache__req_o.kill = ppl_dmem__kill_i;

assign paddr_d = mmu_lsu__valid_i ? mmu_lsu__paddr_i : paddr_q; 
//======================================================================================================================
// Main control logic 
//======================================================================================================================
always_comb begin: p_fsm
    state_d                 = state_q;
    dmem_ppl__hit_o         = 1'b0;
    dmem_ppl__ex_o          = '0;
    lsu_mmu__req_o          = 1'b0; 
    lsu_dcache__req_o.req   = 1'b0;

    unique case (state_q)
        IDLE: begin
            if(!ppl_dmem__kill_i && valid_q) begin
                if(misaligned) begin
                    state_d = IDLE;
                    dmem_ppl__hit_o = 1'b1;
                    dmem_ppl__ex_o.valid = 1'b1;
                    dmem_ppl__ex_o.cause = is_store ? ST_ADDR_MISALIGNED : LD_ADDR_MISALIGNED;
                    dmem_ppl__ex_o.tval  = addr_q;
                end else begin
                    // send request to MMU
                    lsu_mmu__req_o = 1'b1;
                    if (mmu_lsu__dtlb_hit_i) begin
                        // send request to DCache
                        // lsu_dcache__req_o.req = 1'b1;
                        // if (dcache_lsu__rsp_i.ack) begin
                        //     state_d = WAIT_DATA;
                        // end
                        state_d = ACCESS_CACHE;
                    end else begin
                        state_d = TLB_MISS;
                    end
                end
            end
        end
        TLB_MISS: begin
            if (ppl_dmem__kill_i) begin
                state_d = IDLE;
            end else begin
                lsu_mmu__req_o = 1'b1;
                if (mmu_lsu__valid_i) begin
                    if (mmu_lsu__ex_i.valid) begin
                        dmem_ppl__ex_o = mmu_lsu__ex_i;
                        dmem_ppl__hit_o = 1'b1;
                        state_d = IDLE;
                    end else begin
                        state_d = REPLAY;
                    end
                end
            end
        end
        ACCESS_CACHE: begin
            if (ppl_dmem__kill_i) begin
                state_d = IDLE;
            end else if (mmu_lsu__valid_i && mmu_lsu__ex_i.valid) begin
                dmem_ppl__ex_o = mmu_lsu__ex_i;
                dmem_ppl__hit_o = 1'b1;
                state_d = IDLE;
            end else begin
                lsu_dcache__req_o.req = 1'b1; 
                if (dcache_lsu__rsp_i.ack) begin
                    state_d = WAIT_DATA;
                end
            end     
        end
        WAIT_DATA: begin
            if (ppl_dmem__kill_i) begin
                state_d = IDLE;
            end else if (dcache_lsu__rsp_i.valid) begin
                dmem_ppl__hit_o = 1'b1;
                state_d = IDLE;
            end         
        end
        REPLAY: begin
            lsu_dcache__req_o.req = 1'b1;
            if (dcache_lsu__rsp_i.ack) begin
                state_d = WAIT_DATA;
            end
        end
        default: state_d = IDLE;
    endcase
end
//======================================================================================================================
// registers
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i,rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            valid_q <= '0;
            addr_q <= '0;
            wdata_q <= '0;
            size_q <= SIZE_BYTE;
            opcode_q <= MEM_OP_LOAD;
            amo_opcode <= AMO_NONE;
            paddr_q <= '0;
            state_q <= IDLE;
            tlb_hit_dly1 <= 1'b0;
        end else if (ppl_dmem__kill_i) begin
            valid_q <= '0;
            addr_q <= '0;
            wdata_q <= '0;
            size_q <= SIZE_BYTE;
            opcode_q <= MEM_OP_LOAD;
            amo_opcode <= AMO_NONE;
            paddr_q <= '0;
            state_q <= IDLE; 
            tlb_hit_dly1 <= 1'b0;
        end else begin
            valid_q <= ppl_dmem__vld_i;
            if (ppl_dmem__vld_i) begin
                addr_q  <= ppl_dmem__addr_i;
                wdata_q <= wr_data;
                offset_q <= offset;
                size_q  <= ppl_dmem__size_i;
                opcode_q <= ppl_dmem__opcode_i;
                amo_opcode <= ppl_dmem__amo_opcode_i;
            end
            paddr_q <= paddr_d;
            state_q <= state_d;
            tlb_hit_dly1 <= mmu_lsu__dtlb_hit_i;
        end
    end


//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_lsu
// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_lsu_sbuf.v
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

module sy_ppl_lsu_sbuf
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,

    output  logic[SBUF_WTH-1:0]             sbuf_ins_idx_o,
    output  logic[SBUF_WTH-1:0]             sbuf_del_idx_o,
    output  logic                           sbuf_empty_o,
    output  logic                           sbuf_retire_empty_o,
    output  logic                           sbuf_specu_slot_full_o,
    // =====================================
    // [Write to Store Buffer]
    input   logic                           sbuf_vld_i,        
    output  logic                           sbuf_rdy_o,
    input   logic[AWTH-1:0]                 sbuf_paddr_i,
    input   logic[DWTH-1:0]                 sbuf_wdata_i,
    input   logic[7:0]                      sbuf_wstrb_i,
    input   size_e                          sbuf_size_i,
    input   logic                           sbuf_cacheable_i,        
    input   logic                           sbuf_is_amo_i,
    // =====================================
    // [From D cache]
    input   logic                           dcache_sbuf_vld_i,        
    input   logic[DCACHE_WAY_NUM-1:0]       dcache_sbuf_way_i,
    input   logic[SBUF_WTH-1:0]             dcache_sbuf_idx_i,
    input   amo_opcode_e                    dcache_sbuf_amo_i,
    input   logic[DWTH-1:0]                 dcache_sbuf_rdata_i,
    // =====================================
    // [Lookup data]
    input   logic[31:0]                     lookup_paddr_i,
    output  logic[7:0]                      lookup_be_o,
    output  logic[DWTH-1:0]                 lookup_data_o,
    output  logic                           lookup_stall_o,
    // =====================================
    // [Write to D cache]
    output  logic                           sbuf_dcache_we_vld_o,
    input   logic                           sbuf_dcache_we_rdy_i,                   
    output  logic[31:0]                     sbuf_dcache_addr_o,
    output  logic[DWTH-1:0]                 sbuf_dcache_wdata_o,
    output  logic[7:0]                      sbuf_dcache_be_o,
    output  logic                           sbuf_dcache_cacheable_o,
    output  logic[DCACHE_WAY_NUM-1:0]       sbuf_dcache_way_en_o,
    output  amo_opcode_e                    sbuf_dcache_amo_op_o,        
    // =====================================
    // [Retire From ROB]
    input   logic                           rob_lsu__retire_en_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    typedef struct packed {
        logic[31:0]               paddr;   
        logic[63:0]               wdata;
        logic[7:0]                wstrb;
        size_e                    size;
        logic[DCACHE_WAY_NUM-1:0] way_en;
        logic                     cacheable;                  
        logic                     is_amo;
        logic                     sc_fail;
        amo_opcode_e              amo_op;
    } sbuf_t;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    sbuf_t [SBUF_LEN-1:0]                   store_buffer_d,store_buffer_q;
    logic[SBUF_WTH-1:0]                     ins_idx_d, ins_idx_q;
    logic[SBUF_WTH-1:0]                     del_idx_d, del_idx_q;
    logic[SBUF_WTH-1:0]                     ret_idx_d, ret_idx_q;
    logic                                   ins_flag_d, ins_flag_q;       
    logic                                   del_flag_d, del_flag_q;    
    logic                                   ret_flag_d, ret_flag_q;    
    logic                                   ins_en;               
    logic                                   del_en;   
    logic                                   sbuf_is_full;
    logic                                   sbuf_is_empty;
    logic                                   retire_en;
    logic                                   ret_empty;
    logic                                   write_en;
    logic[DWTH-1:0]                         data_after_amo;
    logic[DWTH-1:0]                         wr_data;
    size_e                                  size;
    logic                                   del_is_cacheable;        
    logic                                   non_cacheable_flight_d,non_cacheable_flight_q;
    logic                                   non_cacheable_done_d,non_cacheable_done_q;
    logic[SBUF_WTH:0]                       no_retire_cnt_d,no_retire_cnt_q;
//======================================================================================================================
// Issue Queue
//======================================================================================================================
    assign sbuf_is_full = {~del_flag_q,del_idx_q} == {ins_flag_q,ins_idx_q};
    assign sbuf_is_empty= { del_flag_q,del_idx_q} == {ins_flag_q,ins_idx_q};
    assign sbuf_rdy_o = ~sbuf_is_full;
    assign ins_en = sbuf_vld_i && sbuf_rdy_o;

    assign sbuf_ins_idx_o  = ins_idx_q;
    assign sbuf_del_idx_o  = del_idx_q;
    assign sbuf_empty_o = sbuf_is_empty;
    // insert new item
    always_comb begin : insert_new_item
        for (integer i=SBUF_LEN-1; i>=0; i=i-1) begin
            store_buffer_d[i] = store_buffer_q[i];
            if (i == ins_idx_q && ins_en) begin
                store_buffer_d[i].paddr     = sbuf_paddr_i[31:0];
                store_buffer_d[i].wdata     = sbuf_wdata_i;
                store_buffer_d[i].wstrb     = sbuf_wstrb_i;
                store_buffer_d[i].size      = sbuf_size_i;
                store_buffer_d[i].way_en    = '0;
                store_buffer_d[i].cacheable = sbuf_cacheable_i;
                store_buffer_d[i].is_amo    = sbuf_is_amo_i;
                store_buffer_d[i].sc_fail   = '0;
                store_buffer_d[i].amo_op    = AMO_NONE;
            end else if (dcache_sbuf_vld_i && i == dcache_sbuf_idx_i) begin
                store_buffer_d[i].wdata = data_after_amo;
                store_buffer_d[i].way_en= dcache_sbuf_way_i;
                store_buffer_d[i].sc_fail = (dcache_sbuf_amo_i == AMO_SC) ? dcache_sbuf_rdata_i[0] : 1'b0;
                store_buffer_d[i].amo_op = dcache_sbuf_amo_i;
            end
        end
    end

    assign wr_data = store_buffer_q[dcache_sbuf_idx_i].wdata;
    assign size    = store_buffer_q[dcache_sbuf_idx_i].size;
    always_comb begin
      case (dcache_sbuf_amo_i) 
        AMO_SWAP  : data_after_amo = wr_data;
        AMO_ADD   : data_after_amo = dcache_sbuf_rdata_i + wr_data;
        AMO_AND   : data_after_amo = dcache_sbuf_rdata_i & wr_data;
        AMO_OR    : data_after_amo = dcache_sbuf_rdata_i | wr_data;
        AMO_XOR   : data_after_amo = dcache_sbuf_rdata_i ^ wr_data;
        AMO_MAX   : begin
          if (size == 2'b11) begin // double word
            data_after_amo = ($signed(dcache_sbuf_rdata_i) > $signed(wr_data)) ? dcache_sbuf_rdata_i : wr_data;
          end else begin
            data_after_amo[31:0]  = $signed({{32{dcache_sbuf_rdata_i[31]}},dcache_sbuf_rdata_i[31:0]}) > $signed({{32{wr_data[31]}},wr_data[31:0]}) 
                              ? dcache_sbuf_rdata_i[31:0] : wr_data[31:0];         
            data_after_amo[63:32] = $signed({{32{dcache_sbuf_rdata_i[63]}},dcache_sbuf_rdata_i[63:32]}) > $signed({{32{wr_data[63]}},wr_data[63:32]}) 
                              ? dcache_sbuf_rdata_i[63:32] : wr_data[63:32];         
          end
        end
        AMO_MAXU   : begin
          if (size == 2'b11) begin // double word
            data_after_amo = (dcache_sbuf_rdata_i > wr_data) ? dcache_sbuf_rdata_i : wr_data;
          end else begin
            data_after_amo[31:0]  = {{32{1'b0}},dcache_sbuf_rdata_i[31:0]} > {{32{1'b0}},wr_data[31:0]} 
                              ? dcache_sbuf_rdata_i[31:0] : wr_data[31:0];         
            data_after_amo[63:32] = {{32{1'b0}},dcache_sbuf_rdata_i[63:32]} > {{32{1'b0}},wr_data[63:32]} 
                              ? dcache_sbuf_rdata_i[63:32] : wr_data[63:32];         
          end
        end
        AMO_MIN   : begin
          if (size == 2'b11) begin // double word
            data_after_amo = ($signed(dcache_sbuf_rdata_i) < $signed(wr_data)) ? dcache_sbuf_rdata_i : wr_data;
          end else begin
            data_after_amo[31:0]  = $signed({{32{dcache_sbuf_rdata_i[31]}},dcache_sbuf_rdata_i[31:0]}) < $signed({{32{wr_data[31]}},wr_data[31:0]}) 
                              ? dcache_sbuf_rdata_i[31:0] : wr_data[31:0];         
            data_after_amo[63:32] = $signed({{32{dcache_sbuf_rdata_i[63]}},dcache_sbuf_rdata_i[63:32]}) < $signed({{32{wr_data[63]}},wr_data[63:32]}) 
                              ? dcache_sbuf_rdata_i[63:32] : wr_data[63:32];         
          end
        end
        AMO_MINU   : begin
          if (size == 2'b11) begin // double word
            data_after_amo = (dcache_sbuf_rdata_i < wr_data) ? dcache_sbuf_rdata_i : wr_data;
          end else begin
            data_after_amo[31:0]  = {{32{1'b0}},dcache_sbuf_rdata_i[31:0]} < {{32{1'b0}},wr_data[31:0]} 
                              ? dcache_sbuf_rdata_i[31:0] : wr_data[31:0];         
            data_after_amo[63:32] = {{32{1'b0}},dcache_sbuf_rdata_i[63:32]} < {{32{1'b0}},wr_data[63:32]} 
                              ? dcache_sbuf_rdata_i[63:32] : wr_data[63:32];         
          end
        end
        default   : data_after_amo = wr_data; // AMO_NONE or AMO_SC or AMO_LR
      endcase
    end

    always_comb begin : ins_idx
        {ins_flag_d,ins_idx_d} = {ins_flag_q,ins_idx_q};
        if (flush_i) begin
            {ins_flag_d,ins_idx_d} = {ret_flag_q,ret_idx_q};
        end else if (ins_en) begin
            {ins_flag_d,ins_idx_d} = {ins_flag_q,ins_idx_q} + 1;
        end 
    end

    assign retire_en = rob_lsu__retire_en_i;
    always_comb begin : retire_idx
        {ret_flag_d,ret_idx_d} = {ret_flag_q,ret_idx_q};
        if (retire_en) begin  // don't change
            {ret_flag_d,ret_idx_d} = {ret_flag_d,ret_idx_q} + 1;
        end 
    end

    always_comb begin : del_idx
        {del_flag_d,del_idx_d} = {del_flag_q,del_idx_q};
        if (del_en) begin  // don't change
            {del_flag_d,del_idx_d} = {del_flag_d,del_idx_q} + 1;
        end 
    end
    always_comb begin : no_retire_cnt
        no_retire_cnt_d = no_retire_cnt_q;
        if (flush_i) begin
            no_retire_cnt_d = 0;
        end else if (ins_en && retire_en) begin
            no_retire_cnt_d = no_retire_cnt_q;
        end else if (ins_en) begin
            no_retire_cnt_d = no_retire_cnt_q + 1;
        end else if (retire_en) begin
            no_retire_cnt_d = no_retire_cnt_q - 1;
        end
    end
    assign sbuf_specu_slot_full_o = no_retire_cnt_q == (SBUF_LEN- 1);
//======================================================================================================================
// Lookup wdata 
//======================================================================================================================
    always_comb begin
        lookup_be_o = '0;
        lookup_data_o = '0;
        lookup_stall_o = 1'b0;
        for (integer i = 0; i < SBUF_LEN*2; i = i + 1) begin
            for (integer j = 0; j < 8; j = j + 1) begin
                if (i >= {1'b0, del_idx_q} && i < {del_flag_q ^ ins_flag_q, ins_idx_q}
                    && lookup_paddr_i[31:3]==store_buffer_q[i[SBUF_WTH-1:0]].paddr[31:3] // addr match
                    && store_buffer_q[i[SBUF_WTH-1:0]].wstrb[j]) begin
                    lookup_be_o[j] = 1'b1;
                    lookup_data_o[j*8+:8] = store_buffer_q[i[SBUF_WTH-1:0]].wdata[j*8+:8];
                    lookup_stall_o = store_buffer_q[i[SBUF_WTH-1:0]].is_amo;
                end
            end
        end
    end
//======================================================================================================================
// Select an instr to access d cache
//======================================================================================================================
    always_comb begin
        non_cacheable_flight_d = non_cacheable_flight_q;
        non_cacheable_done_d   = non_cacheable_done_q;
        if (flush_i) begin
            non_cacheable_flight_d = 1'b0; 
        end else if (sbuf_dcache_we_vld_o && sbuf_dcache_we_rdy_i && !del_is_cacheable) begin
            non_cacheable_flight_d = 1'b1; 
        end else if (del_en && !del_is_cacheable) begin
            non_cacheable_flight_d = 1'b0;
        end
        if (flush_i) begin
            non_cacheable_done_d   = 1'b0;
        end else if (dcache_sbuf_vld_i && !del_is_cacheable && dcache_sbuf_idx_i == del_idx_q) begin
            non_cacheable_done_d   = 1'b1;
        end else if (del_en && !del_is_cacheable) begin
            non_cacheable_done_d   = 1'b0;
        end
    end
    // instr will be deleted is cacheable
    assign del_is_cacheable = store_buffer_q[del_idx_q].cacheable;
    // select an instr to issue
    assign ret_empty = {ret_flag_q,ret_idx_q} == {del_flag_q,del_idx_q};
    assign sbuf_retire_empty_o = ret_empty;
    // assign sbuf_dcache_we_vld_o = !ret_empty && !store_buffer_q[del_idx_q].sc_fail;
    always_comb begin
        sbuf_dcache_we_vld_o = 1'b0;
        if (del_is_cacheable && !ret_empty) begin
            sbuf_dcache_we_vld_o = !store_buffer_q[del_idx_q].sc_fail;
        end else if (!del_is_cacheable && !ret_empty && !non_cacheable_flight_q) begin
            sbuf_dcache_we_vld_o = 1'b1;
        end
    end
    always_comb begin
        del_en = 1'b0; 
        // cacheable
        if (del_is_cacheable) begin
            del_en = sbuf_dcache_we_vld_o && sbuf_dcache_we_rdy_i || !ret_empty && store_buffer_q[del_idx_q].sc_fail;
        // non cacheable
        end else begin
            del_en = !ret_empty && non_cacheable_done_q;
        end
    end
    // assign del_en = sbuf_dcache_we_vld_o && sbuf_dcache_we_rdy_i || !ret_empty && store_buffer_q[del_idx_q].sc_fail;   

    assign dcache_addr_o  = store_buffer_q[del_idx_q].paddr;
    assign dcache_wdata_o = store_buffer_q[del_idx_q].wdata;
    assign dcache_be_o    = store_buffer_q[del_idx_q].wstrb;

    assign sbuf_dcache_addr_o   = store_buffer_q[del_idx_q].paddr;
    assign sbuf_dcache_wdata_o  = store_buffer_q[del_idx_q].wdata;
    assign sbuf_dcache_be_o     = store_buffer_q[del_idx_q].wstrb;
    assign sbuf_dcache_cacheable_o = store_buffer_q[del_idx_q].cacheable;
    assign sbuf_dcache_way_en_o = store_buffer_q[del_idx_q].way_en;
    assign sbuf_dcache_amo_op_o = store_buffer_q[del_idx_q].amo_op;
//======================================================================================================================
// Reigster
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0; i<SBUF_LEN; i=i+1) begin
                store_buffer_q[i]   <= sbuf_t'(0);
            end
            {ins_flag_q,ins_idx_q}       <= '0;
            {del_flag_q,del_idx_q}       <= '0;
            {ret_flag_q,ret_idx_q}       <= '0;
            non_cacheable_flight_q       <= 1'b0;
            non_cacheable_done_q         <= 1'b0;
            no_retire_cnt_q              <= 0;
        end else begin
            for (integer i=0; i<SBUF_LEN; i=i+1) begin
                store_buffer_q[i]   <= store_buffer_d[i];
            end
            {ins_flag_q,ins_idx_q}       <= {ins_flag_d,ins_idx_d}      ;
            {del_flag_q,del_idx_q}       <= {del_flag_d,del_idx_d}      ;
            {ret_flag_q,ret_idx_q}       <= {ret_flag_d,ret_idx_d};
            non_cacheable_flight_q       <= non_cacheable_flight_d;
            non_cacheable_done_q         <= non_cacheable_done_d;
            no_retire_cnt_q              <= no_retire_cnt_d;
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

(* mark_debug = "true" *) logic[SBUF_WTH-1:0] prb_sbuf_ins_idx;
(* mark_debug = "true" *) logic[SBUF_WTH-1:0] prb_sbuf_del_idx;
(* mark_debug = "true" *) logic               prb_sbuf_flight;
(* mark_debug = "true" *) logic               prb_sbuf_done;
(* mark_debug = "true" *) logic               prb_sbuf_del_en;
(* mark_debug = "true" *) logic               prb_sbuf_slot_full;

assign prb_sbuf_ins_idx     = ins_idx_q;
assign prb_sbuf_del_idx     = del_idx_q;
assign prb_sbuf_flight      = non_cacheable_flight_q;
assign prb_sbuf_done        = non_cacheable_done_q;
assign prb_sbuf_del_en      = del_en;
assign prb_sbuf_slot_full   = sbuf_specu_slot_full_o;

// synopsys translate_off
// synopsys translate_on
endmodule : sy_ppl_lsu_sbuf

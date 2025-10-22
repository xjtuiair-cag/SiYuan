// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_L2_cache_ctrl.sv
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

module sy_L2_cache_ctrl
  import sy_pkg::*;
#(
  parameter       AXI_ID = 0
)(
    input  logic                            clk_i,
    input  logic                            rst_i,
    input  logic                            flush_en_i,
    output logic                            flush_done_o,
    output logic                            flush_L2_mem_en_o,     
    // =====================================
    // [TileLink Interface between L2 cache and Probe Ctrl]
    input  logic                            TL_A_valid_i,
    output logic                            TL_A_ready_o,
    input  tl_pkg::A_chan_bits_t            TL_A_bits_i,

    output logic                            TL_D_valid_o,
    input  logic                            TL_D_ready_i,
    output tl_pkg::D_chan_bits_t            TL_D_bits_o,
    // =====================================
    // [AXI4 Interface between L2 cache and DDR]
    output logic                            AXI_AW_valid_o,
    input  logic                            AXI_AW_ready_i,         
    output axi_pkg::aw_chan_t               AXI_AW_bits_o,

    output logic                            AXI_AR_valid_o,
    input  logic                            AXI_AR_ready_i,         
    output axi_pkg::ar_chan_t               AXI_AR_bits_o,

    output logic                            AXI_W_valid_o,
    input  logic                            AXI_W_ready_i,         
    output axi_pkg::w_chan_t                AXI_W_bits_o,

    input  logic                            AXI_R_valid_i,
    output logic                            AXI_R_ready_o,
    input  axi_pkg::r_chan_t                AXI_R_bits_i, 

    input  logic                            AXI_B_valid_i,
    output logic                            AXI_B_ready_o,
    input  axi_pkg::b_chan_t                AXI_B_bits_i,
    // =====================================
    // [interface between L2 ctrl and L2 mem]
    output logic                            data_req_o,
    output L2_data_req_t                    data_req_bits_o,
    input  L2_data_rsp_t                    data_rsp_bits_i,
    // tag port
    output logic                            tag_req_o,
    output L2_tag_req_t                     tag_req_bits_o,
    input  L2_tag_rsp_t                     tag_rsp_bits_i
);

//======================================================================================================================
// local Parameters
//======================================================================================================================
  localparam AXI_TRANS_CNT = L2_CACHE_BLOCK_SIZE / L2_CACHE_DATA_SIZE;
  localparam AXI_TRANS_CNT_WTH = $clog2(AXI_TRANS_CNT);
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    typedef enum logic[3:0] {IDLE,READ_TAG,IS_HIT,WRITE_DATA,WRITE_RSP,READ_DATA,IS_DIRTY,
                      WRITE_BACK_REQ,WRITE_BACK,WAIT_B_RSP,REFILL_REQ,REFILL,REPLAY_REQ,FLUSH_REQ,FLUSH_WAIT,FLUSH} state_e;
    state_e state_d, state_q;
    
    logic [63:0]                        addr_d, addr_q;
    tl_pkg::size_t                      size_d, size_q;
    tl_pkg::source_t                    source_d, source_q;
    tl_pkg::data_t                      tmp_data_d, tmp_data_q;
    tl_pkg::mask_t                      mask_d, mask_q;
    logic [2:0]                         tl_opcode_d, tl_opcode_q; 
    logic [AXI_TRANS_CNT_WTH:0]         addr_offset_d,addr_offset_q;
    logic [AXI_TRANS_CNT_WTH:0]         trans_cnt_d, trans_cnt_q;
    logic [L2_CACHE_TAG_LSB-1:0]        data_req_idx;
    logic [AXI_TRANS_CNT_WTH:0]         data_req_cnt;
    logic [L2_CACHE_WAY_WTH-1:0]        hit_way_idx_d, hit_way_idx_q;
    logic [L2_CACHE_WAY_NUM-1:0]        hit_way_d, hit_way_q;
    logic [L2_CACHE_WAY_WTH-1:0]        cache_hit_way_idx;
    logic [L2_CACHE_TAG_WTH-1:0]        tag;
    logic [L2_CACHE_SET_WTH-1:0]        set_inx;
    logic [L2_CACHE_WAY_NUM-1:0]        tag_match;
    logic [L2_CACHE_WAY_NUM-1:0]        cl_valid,cl_valid_d,cl_valid_q;
    logic [L2_CACHE_WAY_NUM-1:0]        cl_dirty,cl_dirty_d,cl_dirty_q;
    logic [L2_CACHE_WAY_NUM-1:0][L2_CACHE_TAG_WTH-1:0] cl_tag,cl_tag_d,cl_tag_q;
    logic [L2_CACHE_WAY_NUM-1:0]        cache_hit;    
    logic                               cl_is_dirty;
    logic [L2_CACHE_WAY_WTH-1:0]        rpl_way;
    logic [L2_CACHE_WAY_NUM-1:0]        rpl_way_one_hot;
    logic [L2_CACHE_WAY_WTH-1:0]        inv_way;
    logic                               all_ways_valid;
    logic                               write_first_data;
    logic                               axi_w_last;                 
    logic [2:0]                         TL_D_opcode;  
    logic                               cache_data_we;               
    logic                               cache_tag_we;               
    logic                               update_cl_dirty;
    logic [L2_CACHE_DATA_SIZE*8-1:0]    cache_wdata;
    logic                               update_lru;
    logic [L2_CACHE_SET_WTH-1:0]        update_lru_set;
    logic [L2_CACHE_WAY_WTH-1:0]        update_lru_way;
    logic [L2_CACHE_SET_WTH-1:0]        lookup_lru_set;
    logic [L2_CACHE_WAY_WTH-1:0]        lookup_lru_way;
    logic                               axi_or_tl; // 0 for tl, 1 for axi             
    logic                               flush_flight_d,flush_flight_q;
    logic [L2_CACHE_SET_WTH:0]          flush_set_d,flush_set_q;
    logic [L2_CACHE_WAY_NUM-1:0]        flush_dirty_cl_d,flush_dirty_cl_q;
    logic                               flush_no_dirty_cl;
    logic [L2_CACHE_WAY_WTH-1:0]        flush_dirty_way_idx;
    logic                               flush_done; 
    logic [L2_CACHE_WAY_WTH-1:0]        handle_way;
//======================================================================================================================
// cache hit 
//======================================================================================================================
  assign tag      = addr_q[L2_CACHE_TAG_MSB-1:L2_CACHE_TAG_LSB];
  assign set_inx  = addr_q[L2_CACHE_SET_MSB-1:L2_CACHE_SET_LSB];
  always_comb begin
    cache_hit_way_idx = '0;
    for (integer i=0; i<L2_CACHE_WAY_NUM; i++) begin: gen_cache_hit
      tag_match[i] = (tag_rsp_bits_i.tag[i] == tag); 
      cl_tag[i]    =  tag_rsp_bits_i.tag[i];
      cl_valid[i]  =  tag_rsp_bits_i.tag_valid[i];
      cl_dirty[i]  =  tag_rsp_bits_i.dirty[i];
      // if cache line is valid and tag is match , then cache hit
      cache_hit[i] = tag_match[i] && cl_valid[i];
      if (cache_hit[i]) begin
        cache_hit_way_idx = i;
      end
    end
  end
  assign cl_is_dirty = cl_dirty_q[rpl_way] && cl_valid_q[rpl_way];
//======================================================================================================================
// TileLink D channel
//======================================================================================================================
  assign TL_D_bits_o.opcode  = TL_D_opcode; 
  assign TL_D_bits_o.param   = tl_pkg::toN;
  assign TL_D_bits_o.size    = size_q;
  assign TL_D_bits_o.source  = source_q;
  assign TL_D_bits_o.sink    = '0;
  assign TL_D_bits_o.denied  = 1'b0;
  assign TL_D_bits_o.data    = data_rsp_bits_i.rd_data[hit_way_idx_q]; 
  assign TL_D_bits_o.corrupt = '0;
//======================================================================================================================
// AXI AW/AR/W channel
//======================================================================================================================
  always_comb begin
    AXI_AW_bits_o.addr   = {32'b0,cl_tag_q[handle_way],addr_q[L2_CACHE_SET_MSB-1:L2_CACHE_SET_LSB],{L2_CACHE_BLOCK_WTH{1'b0}}};
    if (flush_flight_q) begin
      AXI_AW_bits_o.addr = {32'b0,cl_tag_q[handle_way],flush_set_q[L2_CACHE_SET_WTH-1:0],{L2_CACHE_BLOCK_WTH{1'b0}}};     
    end
  end
  assign AXI_AW_bits_o.id     = AXI_ID;
  assign AXI_AW_bits_o.len    = AXI_TRANS_CNT-1;
  assign AXI_AW_bits_o.size   = 3'b011;
  assign AXI_AW_bits_o.burst  = axi_pkg::BURST_INCR; 
  assign AXI_AW_bits_o.lock   = '0; 
  assign AXI_AW_bits_o.cache  = '0; 
  assign AXI_AW_bits_o.prot   = 3'b1; 
  assign AXI_AW_bits_o.qos    = '0; 

  assign AXI_AR_bits_o.id     = AXI_ID;
  assign AXI_AR_bits_o.addr   = (addr_q >> L2_CACHE_BLOCK_WTH) << L2_CACHE_BLOCK_WTH;
  assign AXI_AR_bits_o.len    = AXI_TRANS_CNT-1;
  assign AXI_AR_bits_o.size   = 3'b011;
  assign AXI_AR_bits_o.burst  = axi_pkg::BURST_INCR; 
  assign AXI_AR_bits_o.lock   = '0; 
  assign AXI_AR_bits_o.cache  = '0; 
  assign AXI_AR_bits_o.prot   = 3'b1; 
  assign AXI_AR_bits_o.qos    = '0; 

  assign AXI_W_bits_o.data    = data_rsp_bits_i.rd_data[handle_way];
  assign AXI_W_bits_o.strb    = 8'hFF;
  assign AXI_W_bits_o.last    = axi_w_last; 
//======================================================================================================================
// Access Cache Mem
//======================================================================================================================
  assign tag_req_bits_o.we        = cache_tag_we;
  assign tag_req_bits_o.way_en    = cache_tag_we ? (state_q == WRITE_RSP ? hit_way_q : rpl_way_one_hot) : {L2_CACHE_WAY_NUM{1'b1}}; 
  assign tag_req_bits_o.idx       = flush_flight_q ? {flush_set_q[L2_CACHE_SET_WTH-1:0],{L2_CACHE_BLOCK_WTH{1'b0}}} 
                                            : addr_q[L2_CACHE_TAG_LSB-1:0];
  assign tag_req_bits_o.tag_valid = cache_tag_we ? 1'b1 : 1'b0;
  assign tag_req_bits_o.tag       = cache_tag_we ? addr_q[L2_CACHE_TAG_MSB-1:L2_CACHE_TAG_LSB] : '0;
  assign tag_req_bits_o.dirty     = update_cl_dirty;  

  always_comb begin
    cache_wdata = TL_A_bits_i.data;
    if (write_first_data) begin
      cache_wdata = tmp_data_q;
    end else if (state_q == REFILL) begin
      cache_wdata = AXI_R_bits_i.data;
    end
  end
  assign data_req_cnt = cache_data_we ? addr_offset_q : addr_offset_d;
  always_comb begin
    data_req_idx = {addr_q[L2_CACHE_TAG_LSB-1:L2_CACHE_BLOCK_MSB-1],data_req_cnt[AXI_TRANS_CNT_WTH-2:0],3'b0};
    if (axi_or_tl) begin
      if (flush_flight_q) begin
        data_req_idx = {flush_set_q[L2_CACHE_SET_WTH-1:0], data_req_cnt[AXI_TRANS_CNT_WTH-1:0],3'b0};            
      end else begin
        data_req_idx = {addr_q[L2_CACHE_TAG_LSB-1:L2_CACHE_BLOCK_MSB],data_req_cnt[AXI_TRANS_CNT_WTH-1:0],3'b0};     
      end
    end
  end
  assign data_req_bits_o.we       = cache_data_we;
  assign data_req_bits_o.way_en   = cache_data_we ? (state_q == REFILL ? rpl_way_one_hot : hit_way_d) : {L2_CACHE_WAY_NUM{1'b1}};
  assign data_req_bits_o.idx      = data_req_idx;
  assign data_req_bits_o.wr_data  = cache_wdata;
//======================================================================================================================
// replacement strategy 
//======================================================================================================================
  assign lookup_lru_set = addr_q[L2_CACHE_SET_MSB-1:L2_CACHE_SET_LSB];
  sy_L2_cache_lru lru_inst(
    .clk_i                (clk_i),                      
    .rst_i                (rst_i),                      
  
    .update_lru_i         (update_lru    ),
    .update_lru_set_i     (update_lru_set),
    .update_lru_way_i     (update_lru_way),
  
    .lookup_lru_set_i     (lookup_lru_set),
    .lookup_lru_way_o     (lookup_lru_way)
  );

  assign update_lru_set = addr_q[L2_CACHE_SET_MSB-1:L2_CACHE_SET_LSB];

  // find invalid cache line
  lzc #(
    .WIDTH ( L2_CACHE_WAY_NUM)
  ) cl_valid_inst(
    .in_i    ( ~cl_valid_q       ), 
    .cnt_o   ( inv_way           ),
    .empty_o ( all_ways_valid    )
  );
  // if all cache line is valid, through plru to choose replace way, otherwise choose invalid way
  assign rpl_way = all_ways_valid ? lookup_lru_way : inv_way;
  for (genvar i = 0; i < L2_CACHE_WAY_NUM; i++) begin
    assign rpl_way_one_hot[i] = (rpl_way == i) ? 1'b1: 1'b0;
  end
//======================================================================================================================
// Flush
//======================================================================================================================
  // find invalid cache line
  lzc #(
    .WIDTH ( L2_CACHE_WAY_NUM)
  ) cl_dirty_inst(
    .in_i    ( ~flush_dirty_cl_q ), 
    .cnt_o   ( flush_dirty_way_idx),
    .empty_o ( flush_no_dirty_cl )
  );
  assign flush_done = flush_set_q[L2_CACHE_SET_WTH];
  assign handle_way = flush_flight_q ? flush_dirty_way_idx : rpl_way;
//======================================================================================================================
// FSM
//======================================================================================================================
  always_comb begin : fsm
    // default assignment
    state_d                 = state_q;
    TL_A_ready_o            = 1'b0;
    TL_D_valid_o            = 1'b0;
    AXI_AW_valid_o          = 1'b0;
    AXI_AR_valid_o          = 1'b0;
    AXI_W_valid_o           = 1'b0;
    AXI_R_ready_o           = 1'b0;
    AXI_B_ready_o           = 1'b0;

    addr_d      = addr_q;
    size_d      = size_q;
    source_d    = source_q;
    tmp_data_d  = tmp_data_q;
    tl_opcode_d = tl_opcode_q; 
    mask_d      = mask_q;
    addr_offset_d = addr_offset_q;
    trans_cnt_d = trans_cnt_q;
    hit_way_idx_d = hit_way_idx_q;
    hit_way_d   = hit_way_q;
    cl_valid_d  = cl_valid_q;
    cl_dirty_d  = cl_dirty_q;
    cl_tag_d    = cl_tag_q;
    flush_flight_d = flush_flight_q;
    flush_set_d = flush_set_q;

    data_req_o      = 1'b0;

    tag_req_o       = 1'b0;
    cache_data_we   = 1'b0;
    cache_tag_we    = 1'b0;
    update_cl_dirty = 1'b0;
    write_first_data = 1'b0;
    axi_w_last      = 1'b0;
    axi_or_tl       = 1'b0;
    TL_D_opcode     = tl_pkg::AccessAck;
    update_lru      = 1'b0;
    update_lru_way  = '0;
    flush_done_o    = 1'b0;
    flush_L2_mem_en_o = 1'b0;
    unique case (state_q)
        // wait for an incoming request
        IDLE: begin
          if (flush_en_i) begin
            state_d = FLUSH_REQ;  
            flush_flight_d = 1'b1; 
            flush_set_d = '0;
          end else begin
            TL_A_ready_o = 1'b1;
            if (TL_A_valid_i) begin
              addr_d      = TL_A_bits_i.address;
              size_d      = TL_A_bits_i.size;
              source_d    = TL_A_bits_i.source;
              tmp_data_d  = TL_A_bits_i.data;
              tl_opcode_d = TL_A_bits_i.opcode;
              mask_d      = TL_A_bits_i.mask;
              state_d     = READ_TAG;
            end
          end
        end
        READ_TAG : begin
          tag_req_o = 1'b1;
          state_d   = IS_HIT;
          trans_cnt_d = '0;
          addr_offset_d = addr_q[L2_CACHE_BLOCK_MSB:L2_CACHE_DATA_MSB];
        end
        // read data and tag from cache mem and check whether we have a hit
        IS_HIT: begin
          hit_way_idx_d = cache_hit_way_idx;
          hit_way_d     = cache_hit;
          cl_dirty_d    = cl_dirty;
          cl_valid_d    = cl_valid; 
          cl_tag_d      = cl_tag;
          // cache hit
          if (|cache_hit) begin 
            update_lru = 1'b1; // update lru registers when cache hit
            update_lru_way = hit_way_idx_d;
            if (tl_opcode_q == tl_pkg::PutFullData) begin
              state_d = (size_q == 0) ? WRITE_RSP : WRITE_DATA;
              data_req_o        = 1'b1; // write first data to L2 cache
              axi_or_tl         = 1'b0;
              cache_data_we     = 1'b1;
              write_first_data  = 1'b1;
              trans_cnt_d       = trans_cnt_q + 1;
              addr_offset_d = addr_offset_q + 1;
            end else begin
              state_d = READ_DATA;
              data_req_o = 1'b1;
              axi_or_tl = 1'b0;
            end
          // cache miss 
          end else begin
            state_d   = IS_DIRTY;
          end
        end
        // write data to cache mem when cache hit
        WRITE_DATA : begin
          TL_A_ready_o = 1'b1;
          if (TL_A_valid_i) begin
            data_req_o = 1'b1;
            axi_or_tl = 1'b0;
            cache_data_we = 1'b1;
            trans_cnt_d = trans_cnt_q + 1'b1;
            addr_offset_d = addr_offset_q + 1;
            if (trans_cnt_q == size_q) begin
              state_d = WRITE_RSP;
            end
          end
        end
        // access ackonwledge
        WRITE_RSP: begin
          // update cache line to dirty
          tag_req_o = 1'b1;
          cache_tag_we = 1'b1;
          update_cl_dirty = 1'b1;
          TL_D_valid_o = 1'b1;
          if (TL_D_ready_i) begin
            state_d = IDLE;
          end
        end
        // return data to probe ctrl when cache hit
        READ_DATA : begin
          data_req_o = 1'b1;  
          axi_or_tl = 1'b0;
          TL_D_valid_o = 1'b1;
          TL_D_opcode = tl_pkg::AccessAckData;
          if (TL_D_ready_i) begin
            trans_cnt_d = trans_cnt_q + 1'b1;
            addr_offset_d = addr_offset_q + 1;
            if (trans_cnt_q == size_q) begin
              state_d = IDLE;
            end
          end
        end
        // check whether we cache line that will be replaced is dirty 
        IS_DIRTY: begin
          trans_cnt_d = '0;
          addr_offset_d = '0;
          if (cl_is_dirty) begin
            state_d = WRITE_BACK_REQ;
          end else begin
            state_d = REFILL_REQ; 
          end  
        end
        // axi address write request to ddr
        WRITE_BACK_REQ: begin
          data_req_o = 1'b1;
          axi_or_tl  = 1'b1;
          AXI_AW_valid_o = 1'b1;
          if (AXI_AW_ready_i) begin
            state_d = WRITE_BACK;  
          end
        end
        // axi write data to ddr
        WRITE_BACK: begin
          AXI_W_valid_o = 1'b1;
          data_req_o = 1'b1;
          axi_or_tl  = 1'b1;
          axi_w_last = (trans_cnt_q == AXI_TRANS_CNT - 1);
          if (AXI_W_ready_i) begin
            trans_cnt_d = trans_cnt_q + 1'b1;  
            addr_offset_d = addr_offset_q + 1'b1;
            if (trans_cnt_q == AXI_TRANS_CNT - 1) begin
              state_d = WAIT_B_RSP;
            end
          end 
        end
        // wait ddr return b rsp 
        WAIT_B_RSP: begin
          AXI_B_ready_o = 1'b1; 
          if (AXI_B_valid_i) begin
            state_d = flush_flight_q ? FLUSH : REFILL_REQ;
            flush_dirty_cl_d[flush_dirty_way_idx] = 1'b0; 
          end
        end
        // use axi ar channel to send read request
        REFILL_REQ: begin
          trans_cnt_d = '0;
          AXI_AR_valid_o = 1'b1;
          if (AXI_AR_ready_i) begin
            state_d = REFILL;
          end
        end
        // read data from ddr
        REFILL: begin 
          AXI_R_ready_o = 1'b1;
          if (AXI_R_valid_i) begin
            trans_cnt_d = trans_cnt_q + 1'b1;
            addr_offset_d = addr_offset_q + 1'b1;
            data_req_o  = 1'b1;
            axi_or_tl   = 1'b1;
            cache_data_we = 1'b1;
            if (AXI_R_bits_i.last) begin
              tag_req_o = 1'b1;
              cache_tag_we = 1'b1;
              state_d = REPLAY_REQ;
              update_lru = 1'b1;
              update_lru_way = rpl_way;
            end
          end
        end
        // replay request from probe ctrl
        REPLAY_REQ: begin
          tag_req_o = 1'b1;
          trans_cnt_d = '0;
          addr_offset_d = addr_q[L2_CACHE_BLOCK_MSB:L2_CACHE_DATA_MSB];
          state_d = IS_HIT;
        end
        FLUSH_REQ: begin
          if (flush_done) begin
            flush_done_o = 1'b1;
            flush_L2_mem_en_o = 1'b1;
            flush_flight_d = 1'b0;
            state_d = IDLE;
          end else begin
            tag_req_o = 1'b1;
            state_d = FLUSH_WAIT;
          end
        end
        FLUSH_WAIT: begin
          flush_dirty_cl_d = cl_dirty & cl_valid;
          cl_tag_d = cl_tag;
          state_d = FLUSH;
        end
        FLUSH: begin
          if (flush_no_dirty_cl) begin
            state_d = FLUSH_REQ;
            flush_set_d = flush_set_q + 1'b1;
          end else begin
            trans_cnt_d = '0;
            addr_offset_d = '0;
            state_d = WRITE_BACK_REQ;
          end
        end
        default: begin
          state_d = IDLE;
        end
    endcase // state_q
  end

//======================================================================================================================
// registers
//======================================================================================================================
  always_ff @(`DFF_CR(clk_i, rst_i)) begin 
      if (`DFF_IS_R(rst_i)) begin
        state_q       <= IDLE;
        addr_q        <= '0;
        size_q        <= '0;
        source_q      <= '0;
        tmp_data_q    <= '0;
        mask_q        <= '0;
        tl_opcode_q   <= '0; 
        trans_cnt_q   <= '0;
        addr_offset_q <= '0;
        hit_way_idx_q <= '0;
        hit_way_q     <= '0;
        cl_valid_q    <= '0;
        cl_tag_q      <= '0;
        cl_dirty_q    <= '0;
        flush_flight_q<= '0;
        flush_set_q   <= '0;
        flush_dirty_cl_q<= '0;
      end else begin
        state_q       <= state_d;
        addr_q        <= addr_d;
        size_q        <= size_d;
        source_q      <= source_d;
        tmp_data_q    <= tmp_data_d;
        mask_q        <= mask_d;
        tl_opcode_q   <= tl_opcode_d; 
        trans_cnt_q   <= trans_cnt_d;
        addr_offset_q <= addr_offset_d;
        hit_way_idx_q <= hit_way_idx_d;
        hit_way_q     <= hit_way_d;
        cl_valid_q    <= cl_valid_d;
        cl_tag_q      <= cl_tag_d;
        cl_dirty_q    <= cl_dirty_d;
        flush_flight_q<= flush_flight_d;
        flush_set_q   <= flush_set_d;
        flush_dirty_cl_q<= flush_dirty_cl_d;
      end
  end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

endmodule
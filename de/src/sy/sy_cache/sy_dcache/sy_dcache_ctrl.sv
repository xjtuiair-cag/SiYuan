// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_dcache_ctrl.v
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

module sy_dcache_ctrl  
  import sy_pkg::*;
#(
    parameter           REQ_PORT = 2
)(
    input  logic                            clk_i,
    input  logic                            rst_i,
    input  logic                            ppl_kill_i,

    output logic                            cache_miss_o,               
    output logic                            allow_probe_o,
    input  logic                            probe_flight_i, // there exist a probe req handled by miss unit      
    input  logic                            acquire_flight_i,   
    // =====================================
    // [D cache req from ppl]
    input  logic                           ppl_dmem__req_i,
    output logic                           dmem_ppl__rsp_o,
    input  dcache_req_t                    ppl_dmem__req_bits_i,
    output dcache_rsp_t                    dmem_ppl__rsp_bits_o,  
    // =====================================
    // [D cache req from mmu]
    input  logic                           mmu_dmem__req_i,
    output logic                           dmem_mmu__rsp_o,
    input  dcache_req_t                    mmu_dmem__req_bits_i,
    output dcache_rsp_t                    dmem_mmu__rsp_bits_o,  
    // =====================================
    // [To MissUnit]
    output logic                            miss_req_o,
    input  logic                            miss_ack_i,
    output miss_req_bits_t                  miss_req_bits_o,
    // [from MissUnit]
    input  logic                            miss_done_i,
    input  logic [DCACHE_DATA_SIZE*8-1:0]   miss_rdata_i,   // for non-cacheable data
    // =====================================
    // [To dcache mem]
    // data port
    output logic                            data_req_o,
    input  logic                            data_gnt_i,
    output data_req_t                       data_req_bits_o,
    input  data_rsp_t                       data_rsp_bits_i,
    // tag port
    output logic                            tag_req_o,
    input  logic                            tag_gnt_i,
    output tag_req_t                        tag_req_bits_o,
    input  tag_rsp_t                        tag_rsp_bits_i
);
//======================================================================================================================
// local Parameters
//======================================================================================================================
  localparam LRSC_CNT_INIT = 7'd80;
  localparam LRSC_THRESH   = 7'd3;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
  typedef enum logic[2:0] {IDLE,WAIT_KILL,MISS_REQ,MISS_WAIT,REPLAY_REQ,WAIT_PROBE_DONE} state_e;
  state_e state_d, state_q;

  logic [DCACHE_WAY_NUM-1:0]                      tag_match;
  logic [DCACHE_WAY_NUM-1:0]                      state_match;
  logic [DCACHE_WAY_NUM-1:0]                      is_hit;      
  logic [DCACHE_WAY_NUM-1:0]                      is_valid;      
  logic                                           need_update;
  logic [$clog2(DCACHE_WAY_NUM)-1:0]              update_way_idx;
  logic [$clog2(DCACHE_WAY_NUM)-1:0]              cache_hit_way_idx;
  logic                                           cache_hit;
  logic                                           cache_miss;
  logic                                           cacheable;

  dc_req_src_e                                    req_src_st0;
  dcache_req_t                                    dc_req_bits_st0;

  logic                                           act_st1;
  dc_req_src_e                                    req_src_st1;
  dcache_req_t                                    dc_req_bits_st1;
  logic                                           replay_req_st1;
  logic[DCACHE_TAG_WTH-1:0]                       tag_st1;  

  logic                                           act_st2;
  dc_req_src_e                                    req_src_st2;
  dcache_req_t                                    dc_req_bits_st2;
  logic                                           cache_hit_st2;
  logic                                           cache_miss_st2;
  logic [DCACHE_DATA_SIZE*8-1:0]                  cache_rd_data_st2;
  logic [DCACHE_DATA_SIZE*8-1:0]                  cache_wr_data_st2;
  logic [$clog2(DCACHE_WAY_NUM)-1:0]              cache_hit_way_idx_st2;  
  logic [DCACHE_WAY_NUM-1:0]                      cache_hit_way_st2;  
  logic                                           cache_sc_fail_st2;
  logic                                           cacheable_st2; 
  logic                                           cache_kill_st2;

  logic                                           cache_wr_en;
  logic                                           lookup_hit;
  logic [DCACHE_DATA_SIZE*8-1:0]                  lookup_data;  
  logic [DCACHE_DATA_SIZE-1:0]                    lookup_strb;  
  logic [DCACHE_DATA_SIZE*8-1:0]                  dc_mem_rdata;  
  logic [DCACHE_DATA_SIZE*8-1:0]                  cache_rd_data;  
  logic [DCACHE_DATA_SIZE*8-1:0]                  wr_data;  
  logic [DCACHE_DATA_SIZE*8-1:0]                  data_after_amo;  
  logic                                           save_lr_addr;   
  logic                                           del_lr_addr;   
  logic [6:0]                                     lrsc_cnt; 
  logic                                           sc_fail;
  logic [DCACHE_TAG_MSB-DCACHE_BLOCK_WTH-1:0]     lrsc_addr;  
  logic                                           lrsc_valid;
  logic                                           lrsc_addr_match;
  logic [$clog2(DCACHE_WAY_NUM)-1:0]              rpl_way;
  logic [$clog2(DCACHE_WAY_NUM)-1:0]              inv_way;
  logic                                           all_ways_valid;
  logic                                           update_lru;
  logic [DCACHE_SET_WTH-1:0]                      update_lru_set;
  logic [DCACHE_WAY_WTH-1:0]                      update_lru_way;
  logic [DCACHE_SET_WTH-1:0]                      lookup_lru_set;
  logic [DCACHE_WAY_WTH-1:0]                      lookup_lru_way;

  logic [DCACHE_WAY_WTH-1:0]                      update_way_d,update_way_q;            
  logic [DCACHE_WAY_WTH-1:0]                      rpl_way_d,rpl_way_q;            
  logic [DCACHE_TAG_MSB-1:0]                      miss_addr_d,miss_addr_q;
  logic                                           cacheable_d,cacheable_q;
  miss_req_cmd_e                                  miss_req_cmd_d,miss_req_cmd_q;
  logic                                           miss_we_d,miss_we_q;
  logic [DCACHE_DATA_SIZE-1:0]                    miss_be_d,miss_be_q;
  logic [DCACHE_DATA_SIZE*8-1:0]                  miss_wdata_d,miss_wdata_q;
  amo_t                                           miss_amo_op_d,miss_amo_op_q;
  dc_req_src_e                                    miss_src_d,miss_src_q;  
  logic [1:0]                                     miss_size_d,miss_size_q;  
  logic                                           allow_dc_req;
  logic                                           miss_replay_req;
  logic                                           miss_replay_rsp;
  logic [DCACHE_DATA_SIZE*8-1:0]                  miss_rdata_d,miss_rdata_q;
  dcache_req_t                                    dc_replay_bits;

  logic                                           dc_access_stall;
//======================================================================================================================
// Stage 0 : access D cache Mem
//======================================================================================================================
  always_comb begin : req_gen
    data_req_bits_o.idx      = ppl_dmem__req_bits_i.addr_inx;
    data_req_bits_o.we       = 1'b0;
    data_req_bits_o.way_en   = {DCACHE_WAY_NUM{1'b1}}; 
    data_req_bits_o.wr_data  = cache_wr_data_st2;  
    data_req_bits_o.wstrb    = dc_req_bits_st2.be;

    // tag read is earier than data read, so use addr_inx_d
    tag_req_bits_o.idx       = ppl_dmem__req_bits_i.addr_inx;
    tag_req_bits_o.we        = 1'b0;
    tag_req_bits_o.way_en    = {DCACHE_WAY_NUM{1'b1}};
    //                         {tag ,       state ,valid}
    tag_req_bits_o.wr_tag    = {'0, Nothing, 1'b0}; 

    dc_req_bits_st0          = ppl_dmem__req_bits_i;
    req_src_st0              = PPL;

    dmem_mmu__rsp_o          = 1'b0;
    dmem_ppl__rsp_o          = 1'b0;
    miss_replay_rsp          = 1'b0;

    tag_req_o                = 1'b0;
    data_req_o               = 1'b0;

    // write to D cache
    if (cache_wr_en) begin
      tag_req_o           = 1'b1;
      data_req_o          = 1'b1;
      data_req_bits_o.idx = dc_req_bits_st2.addr_inx;
      tag_req_bits_o.idx  = dc_req_bits_st2.addr_inx;     
      data_req_bits_o.we      = 1'b1;
      data_req_bits_o.way_en  = cache_hit_way_st2;
      data_req_bits_o.wr_data = cache_wr_data_st2;
      data_req_bits_o.wstrb   = dc_req_bits_st2.be;
      tag_req_bits_o.we       = 1'b1;
      tag_req_bits_o.way_en   = cache_hit_way_st2;
      tag_req_bits_o.wr_tag   = {dc_req_bits_st2.addr_tag, Dirty, 1'b1}; 
    // miss instr replay
    end else if (miss_replay_req) begin
      tag_req_o           = 1'b1;  
      data_req_o          = 1'b1;
      miss_replay_rsp     = tag_gnt_i && data_gnt_i;
      data_req_bits_o.idx = dc_replay_bits.addr_inx;
      tag_req_bits_o.idx  = dc_replay_bits.addr_inx;
      dc_req_bits_st0     = dc_replay_bits;
      req_src_st0         = miss_src_q;
    // MMU request
    end else if (mmu_dmem__req_i) begin
      tag_req_o           = !dc_access_stall && !probe_flight_i; 
      data_req_o          = !dc_access_stall && !probe_flight_i;
      dmem_mmu__rsp_o     = tag_gnt_i && data_gnt_i;
      data_req_bits_o.idx = mmu_dmem__req_bits_i.addr_inx;
      tag_req_bits_o.idx  = mmu_dmem__req_bits_i.addr_inx;     
      dc_req_bits_st0     = mmu_dmem__req_bits_i; 
      req_src_st0         = MMU;
    // PPL request
    end else if (ppl_dmem__req_i) begin
      tag_req_o           = !dc_access_stall && !probe_flight_i;
      data_req_o          = !dc_access_stall && !probe_flight_i;
      dmem_ppl__rsp_o     = tag_gnt_i && data_gnt_i;
      data_req_bits_o.we  = 1'b0;
      tag_req_bits_o.we   = 1'b0;
    end
  end    
//======================================================================================================================
// Stage 1 : Check whether the cache is hit
//======================================================================================================================
  // save signals from stage 0
  always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if (`DFF_IS_R(rst_i)) begin
      act_st1              <= `TCQ 1'b0;
      req_src_st1          <= `TCQ PPL;
      dc_req_bits_st1      <= `TCQ dcache_req_t'(0); 
      replay_req_st1       <= `TCQ 1'b0;
    end else begin
      act_st1              <= `TCQ tag_req_o && tag_gnt_i && data_req_o && data_gnt_i && !cache_wr_en;
      req_src_st1          <= `TCQ req_src_st0;
      dc_req_bits_st1      <= `TCQ dc_req_bits_st0; 
      replay_req_st1       <= `TCQ miss_replay_req && miss_replay_rsp;
    end
  end
  // if request is from ppl, physical tag come from ppl_dmem__req_bits
  assign tag_st1 = (req_src_st1 == MMU || replay_req_st1) ? dc_req_bits_st1.addr_tag : ppl_dmem__req_bits_i.addr_tag;
  assign cacheable = is_cacheable({tag_st1, {DCACHE_TAG_LSB{1'b0}}});
  always_comb begin
    for (integer i=0; i<DCACHE_WAY_NUM; i++) begin: gen_cache_hit
      tag_match[i] = (tag_rsp_bits_i.tag_data[i].tag == tag_st1); 
      if (dc_req_bits_st1.we || dc_req_bits_st1.amo_op != AMO_NONE) begin
        state_match[i] = tag_rsp_bits_i.tag_data[i].state == Dirty || tag_rsp_bits_i.tag_data[i].state == Trunk;
      end else begin
        state_match[i] = tag_rsp_bits_i.tag_data[i].state != Nothing;
      end
      is_valid[i] = tag_rsp_bits_i.tag_data[i].valid;
      // if cache line is valid and tag is match and state is match, then cache hit
      is_hit[i] = tag_match[i] && state_match[i] && is_valid[i];
    end
  end
  // cache mem has data, but need greater state, such as Branch --> Trunk, so need to update cache line
  assign need_update = |(tag_match & is_valid);
  oneHot2Int #(
    .WIDTH ( DCACHE_WAY_NUM)
  ) valid_to_idx (
    .in_i    ( tag_match & is_valid),
    .cnt_o   ( update_way_idx),
    .empty_o (         )
  );
  assign cache_hit_way_idx = update_way_idx;
  // cache hit and miss siganl
  assign cache_hit = act_st1 &&  (|is_hit) && cacheable && !(ppl_dmem__req_bits_i.kill && req_src_st1 == PPL);
  assign cache_miss= act_st1 && !(|is_hit) && cacheable && !(ppl_dmem__req_bits_i.kill && req_src_st1 == PPL);
  // output to performance registers
  assign cache_miss_o = cache_miss;

  assign dc_mem_rdata = data_rsp_bits_i.rd_data[cache_hit_way_idx];
  // look up stage2 to check whether there is write data to cache ram 
  assign lookup_hit  = act_st1 && cache_wr_en && ({tag_st1,dc_req_bits_st1.addr_inx[DCACHE_TAG_LSB-1:3]} 
                            == {dc_req_bits_st2.addr_tag,dc_req_bits_st2.addr_inx[DCACHE_TAG_LSB-1:3]});
  assign lookup_data = cache_wr_data_st2;
  assign lookup_strb = dc_req_bits_st2.be;
  // merge read data  
  always_comb begin: merge_read_data
      for (integer i=0;i<DCACHE_DATA_SIZE;i++) begin
          cache_rd_data[i*8+:8] = lookup_hit && lookup_strb[i] ? lookup_data[i*8+:8] : dc_mem_rdata[i*8+:8];
      end
  end 
  // AMO operations
  assign wr_data = dc_req_bits_st1.wdata;
  always_comb begin
    case (dc_req_bits_st1.amo_op) 
      AMO_SWAP  : data_after_amo = wr_data;
      AMO_ADD   : data_after_amo = cache_rd_data + wr_data;
      AMO_AND   : data_after_amo = cache_rd_data & wr_data;
      AMO_OR    : data_after_amo = cache_rd_data | wr_data;
      AMO_XOR   : data_after_amo = cache_rd_data ^ wr_data;
      AMO_MAX   : begin
        if (dc_req_bits_st1.size == 2'b11) begin // double word
          data_after_amo = ($signed(cache_rd_data) > $signed(wr_data)) ? cache_rd_data : wr_data;
        end else begin
          data_after_amo[31:0]  = $signed({{32{cache_rd_data[31]}},cache_rd_data[31:0]}) > $signed({{32{wr_data[31]}},wr_data[31:0]}) 
                            ? cache_rd_data[31:0] : wr_data[31:0];         
          data_after_amo[63:32] = $signed({{32{cache_rd_data[63]}},cache_rd_data[63:32]}) > $signed({{32{wr_data[63]}},wr_data[63:32]}) 
                            ? cache_rd_data[63:32] : wr_data[63:32];         
        end
      end
      AMO_MAXU   : begin
        if (dc_req_bits_st1.size == 2'b11) begin // double word
          data_after_amo = (cache_rd_data > wr_data) ? cache_rd_data : wr_data;
        end else begin
          data_after_amo[31:0]  = {{32{1'b0}},cache_rd_data[31:0]} > {{32{1'b0}},wr_data[31:0]} 
                            ? cache_rd_data[31:0] : wr_data[31:0];         
          data_after_amo[63:32] = {{32{1'b0}},cache_rd_data[63:32]} > {{32{1'b0}},wr_data[63:32]} 
                            ? cache_rd_data[63:32] : wr_data[63:32];         
        end
      end
      AMO_MIN   : begin
        if (dc_req_bits_st1.size == 2'b11) begin // double word
          data_after_amo = ($signed(cache_rd_data) < $signed(wr_data)) ? cache_rd_data : wr_data;
        end else begin
          data_after_amo[31:0]  = $signed({{32{cache_rd_data[31]}},cache_rd_data[31:0]}) < $signed({{32{wr_data[31]}},wr_data[31:0]}) 
                            ? cache_rd_data[31:0] : wr_data[31:0];         
          data_after_amo[63:32] = $signed({{32{cache_rd_data[63]}},cache_rd_data[63:32]}) < $signed({{32{wr_data[63]}},wr_data[63:32]}) 
                            ? cache_rd_data[63:32] : wr_data[63:32];         
        end
      end
      AMO_MINU   : begin
        if (dc_req_bits_st1.size == 2'b11) begin // double word
          data_after_amo = (cache_rd_data < wr_data) ? cache_rd_data : wr_data;
        end else begin
          data_after_amo[31:0]  = {{32{1'b0}},cache_rd_data[31:0]} < {{32{1'b0}},wr_data[31:0]} 
                            ? cache_rd_data[31:0] : wr_data[31:0];         
          data_after_amo[63:32] = {{32{1'b0}},cache_rd_data[63:32]} < {{32{1'b0}},wr_data[63:32]} 
                            ? cache_rd_data[63:32] : wr_data[63:32];         
        end
      end
      default   : data_after_amo = wr_data; // AMO_NONE or AMO_SC or AMO_LR
    endcase
  end
  // LR SC 
  assign save_lr_addr = (dc_req_bits_st1.amo_op == AMO_LR) && act_st1 && cache_hit;
  assign del_lr_addr  = (dc_req_bits_st1.amo_op == AMO_SC) && act_st1 && cache_hit && !sc_fail;
  // store conditional failed 
  assign sc_fail = (dc_req_bits_st1.amo_op == AMO_SC) && act_st1 && !(lrsc_valid && lrsc_addr_match);
  always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if(`DFF_IS_R(rst_i)) begin
      lrsc_cnt  <= `TCQ '0;
      lrsc_addr <= `TCQ '0;
    end else begin
      if (save_lr_addr) begin
        lrsc_addr <= {tag_st1,dc_req_bits_st1.addr_inx >> DCACHE_BLOCK_WTH};
      end
      if (save_lr_addr) begin
        lrsc_cnt <= LRSC_CNT_INIT;
      end else if (del_lr_addr) begin
        lrsc_cnt <= '0;
      end else if (lrsc_cnt != 0) begin
        lrsc_cnt <= lrsc_cnt - 1;
      end
    end
  end

  assign lrsc_addr_match = lrsc_addr == {tag_st1,(dc_req_bits_st1.addr_inx >> DCACHE_BLOCK_WTH)};
  assign lrsc_valid = lrsc_cnt > LRSC_THRESH;
  assign allow_probe_o = !lrsc_valid;
//======================================================================================================================
// Stage 2
//======================================================================================================================
  always_ff @(`DFF_CR(clk_i, rst_i)) begin
      if(`DFF_IS_R(rst_i)) begin
          act_st2          <= `TCQ 1'b0;    
          dc_req_bits_st2  <= `TCQ dcache_req_t'(0);
          req_src_st2      <= `TCQ PPL;
          cache_hit_st2    <= `TCQ 1'b0;
          cache_miss_st2   <= `TCQ 1'b0;
          cache_rd_data_st2<= `TCQ '0;
          cache_wr_data_st2<= `TCQ '0;
          cache_hit_way_st2<= `TCQ '0;
          cache_hit_way_idx_st2 <= `TCQ '0;
          cache_sc_fail_st2<= `TCQ 1'b0;
          cacheable_st2    <= `TCQ 1'b0;
      end else begin
          act_st2          <= `TCQ act_st1 && (cache_hit || !cacheable && replay_req_st1) && !(ppl_kill_i && req_src_st1 == PPL);
          dc_req_bits_st2.addr_inx  <= `TCQ dc_req_bits_st1.addr_inx;
          dc_req_bits_st2.addr_tag  <= `TCQ tag_st1;
          dc_req_bits_st2.wdata     <= `TCQ dc_req_bits_st1.wdata;
          dc_req_bits_st2.size      <= `TCQ dc_req_bits_st1.size;
          dc_req_bits_st2.we        <= `TCQ dc_req_bits_st1.we;
          dc_req_bits_st2.be        <= `TCQ dc_req_bits_st1.be;
          dc_req_bits_st2.amo_op    <= `TCQ dc_req_bits_st1.amo_op;
          dc_req_bits_st2.kill      <= `TCQ dc_req_bits_st1.kill;
          req_src_st2      <= `TCQ req_src_st1;
          cache_hit_st2    <= `TCQ cache_hit;
          cache_miss_st2   <= `TCQ cache_miss;
          cache_rd_data_st2<= `TCQ (dc_req_bits_st1.amo_op == AMO_SC) ? sc_fail : (!cacheable ? miss_rdata_q : cache_rd_data);
          cache_wr_data_st2<= `TCQ data_after_amo;
          cache_hit_way_st2<= `TCQ is_hit;
          cache_hit_way_idx_st2 <= `TCQ cache_hit_way_idx;
          cache_sc_fail_st2<= `TCQ sc_fail;
          cacheable_st2    <= `TCQ cacheable;
      end
  end

  assign dmem_ppl__rsp_bits_o.valid = (cache_hit || act_st1 && !cacheable && replay_req_st1) && req_src_st1 == PPL;
  assign dmem_ppl__rsp_bits_o.rdata = cache_rd_data_st2;

  // mmu response
  assign dmem_mmu__rsp_bits_o.valid = (cache_hit || act_st1 && !cacheable && replay_req_st1) && req_src_st1 == MMU;
  assign dmem_mmu__rsp_bits_o.rdata = cache_rd_data;

  assign cache_kill_st2 = ppl_kill_i && req_src_st2 == PPL;
  // write to cache mem
  assign cache_wr_en = !cache_kill_st2 && act_st2 && dc_req_bits_st2.we && !(dc_req_bits_st2.amo_op == AMO_SC && cache_sc_fail_st2) && cacheable_st2;
//======================================================================================================================
// FSM handle refill request 
//======================================================================================================================
  assign update_lru     = cache_hit; 
  assign update_lru_set = dc_req_bits_st1.addr_inx[DCACHE_SET_MSB-1:DCACHE_SET_LSB];
  assign update_lru_way = cache_hit_way_idx;
  assign lookup_lru_set = dc_req_bits_st1.addr_inx[DCACHE_SET_MSB-1:DCACHE_SET_LSB]; 
  // lru 
  sy_dcache_lru dc_lru_inst (
      .clk_i              (clk_i),                      
      .rst_i              (rst_i),                      

      .update_lru_i       (update_lru    ),
      .update_lru_set_i   (update_lru_set),
      .update_lru_way_i   (update_lru_way),

      .lookup_lru_set_i   (lookup_lru_set),
      .lookup_lru_way_o   (lookup_lru_way)
  );
  // find invalid cache line
  lzc #(
    .WIDTH ( DCACHE_WAY_NUM)
  ) i_lzc_inv (
    .in_i    ( ~is_valid), 
    .cnt_o   ( inv_way                         ),
    .empty_o ( all_ways_valid                  )
  );
  // if all cache line is valid, through plru to choose replace way, otherwise choose invalid way
  assign rpl_way = all_ways_valid ? lookup_lru_way : inv_way;

  assign miss_req_bits_o.cmd            = miss_req_cmd_q; 
  assign miss_req_bits_o.cacheable      = cacheable_q;
  assign miss_req_bits_o.addr           = miss_addr_q;
  assign miss_req_bits_o.we             = miss_we_q || miss_amo_op_q == AMO_LR;
  assign miss_req_bits_o.be             = miss_be_q;
  assign miss_req_bits_o.wdata          = miss_wdata_q;
  assign miss_req_bits_o.amo_op         = miss_amo_op_q;
  assign miss_req_bits_o.update_way     = update_way_q;
  assign miss_req_bits_o.rpl_way        = rpl_way_q;  

  assign dc_replay_bits.addr_inx = miss_addr_q[DCACHE_TAG_LSB-1:0];
  assign dc_replay_bits.addr_tag = miss_addr_q[DCACHE_TAG_MSB-1:DCACHE_TAG_LSB];
  assign dc_replay_bits.wdata    = miss_wdata_q;
  assign dc_replay_bits.size     = miss_size_q;
  assign dc_replay_bits.we       = miss_we_q;
  assign dc_replay_bits.be       = miss_be_q;
  assign dc_replay_bits.amo_op   = miss_amo_op_q;
  assign dc_replay_bits.kill     = 1'b0;

  assign dc_access_stall = cache_miss || !allow_dc_req || (act_st1 && !cacheable && !replay_req_st1);
  always_comb begin : refill_fsm
    state_d        = state_q;
    update_way_d   = update_way_q;            
    rpl_way_d      = rpl_way_q;            
    miss_addr_d    = miss_addr_q;
    cacheable_d    = cacheable_q;
    miss_req_cmd_d = miss_req_cmd_q;
    miss_we_d      = miss_we_q;
    miss_be_d      = miss_be_q;
    miss_wdata_d   = miss_wdata_q;
    miss_amo_op_d  = miss_amo_op_q;
    miss_src_d     = miss_src_q;
    miss_size_d    = miss_size_q;
    miss_rdata_d   = miss_rdata_q;

    allow_dc_req   = 1'b0;
    miss_req_o     = 1'b0;
    miss_replay_req= 1'b0;
    unique case (state_q)
      IDLE: begin
        allow_dc_req = 1'b1;
        // cache miss or access non-cacheable area 
        if ((cache_miss || act_st1 && !cacheable && !replay_req_st1) && !(ppl_kill_i && req_src_st1 == PPL)) begin
          // save miss instruction info, such as addr/write data and so on
          state_d = WAIT_KILL;
          update_way_d   = update_way_idx;
          rpl_way_d      = rpl_way;
          miss_addr_d    = {tag_st1,dc_req_bits_st1.addr_inx};
          cacheable_d    = cacheable;
          miss_req_cmd_d = need_update ? UPDATE : REFILL;
          miss_be_d      = dc_req_bits_st1.be;
          miss_we_d      = dc_req_bits_st1.we;
          miss_wdata_d   = dc_req_bits_st1.wdata;
          miss_amo_op_d  = dc_req_bits_st1.amo_op;
          miss_size_d    = dc_req_bits_st1.size;
          miss_src_d     = req_src_st1;
        end
      end
      WAIT_KILL: begin 
        if (ppl_kill_i && miss_src_q == PPL) begin
          state_d = IDLE;
        end else begin
          state_d = MISS_REQ;
        end
      end
      // issue request to miss unit
      MISS_REQ: begin
        if (ppl_kill_i && miss_src_q == PPL) begin
          state_d = IDLE;
        end else if (probe_flight_i) begin
          state_d = MISS_REQ;
        end else begin
          miss_req_o = 1'b1;
          if (miss_ack_i) begin
            state_d = MISS_WAIT;
          end
        end
      end
      // wait until the memory transaction returns.
      MISS_WAIT: begin
        // if miss unit has already send acquire request, don't go to WAIT_PROBE_DONE
        if (probe_flight_i && !acquire_flight_i) begin
          state_d = WAIT_PROBE_DONE;
        end else if (miss_done_i) begin
          state_d = REPLAY_REQ; 
          miss_rdata_d = miss_rdata_i;
        end
      end
      // replay read request
      REPLAY_REQ: begin
        if (probe_flight_i) begin
          state_d = REPLAY_REQ;
        end else begin
          miss_replay_req = 1'b1;
          if (miss_replay_rsp) begin
            state_d = IDLE;
          end
        end
      end
      WAIT_PROBE_DONE: begin
        if (!probe_flight_i) begin
          state_d = MISS_REQ;
        end
      end
        // KILL_MISS: begin
        //   if (probe_flight_i || miss_done_i) begin
        //     state_d = IDLE;
        //   end
        // end
      default: begin
        state_d = IDLE;
      end
    endcase // state_q
  end
//======================================================================================================================
// registers
//======================================================================================================================
  always_ff @(`DFF_CR(clk_i,rst_i)) begin : p_regs
    if(`DFF_IS_R(rst_i)) begin
      state_q        <= `TCQ IDLE;
      update_way_q   <= `TCQ '0;            
      rpl_way_q      <= `TCQ '0;            
      miss_addr_q    <= `TCQ '0;
      cacheable_q    <= `TCQ '0;
      miss_req_cmd_q <= `TCQ REFILL;
      miss_we_q      <= `TCQ '0;
      miss_be_q      <= `TCQ '0;
      miss_wdata_q   <= `TCQ '0;
      miss_amo_op_q  <= `TCQ AMO_NONE;
      miss_src_q     <= `TCQ PPL;
      miss_size_q    <= `TCQ '0;
      miss_rdata_q   <= `TCQ '0;
    end else begin
      state_q        <= `TCQ state_d;       
      update_way_q   <= `TCQ update_way_d;  
      rpl_way_q      <= `TCQ rpl_way_d;     
      miss_addr_q    <= `TCQ miss_addr_d;   
      cacheable_q    <= `TCQ cacheable_d;   
      miss_req_cmd_q <= `TCQ miss_req_cmd_d;
      miss_we_q      <= `TCQ miss_we_d;     
      miss_be_q      <= `TCQ miss_be_d;     
      miss_wdata_q   <= `TCQ miss_wdata_d;  
      miss_amo_op_q  <= `TCQ miss_amo_op_d; 
      miss_src_q     <= `TCQ miss_src_d;    
      miss_size_q    <= `TCQ miss_size_d;   
      miss_rdata_q   <= `TCQ miss_rdata_d;
    end
  end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================


(* mark_debug = "true" *) logic                           prb_dc_wr_req;
(* mark_debug = "true" *) logic                           prb_dc_replay_req;
(* mark_debug = "true" *) logic                           prb_dc_replay_rsp;
(* mark_debug = "true" *) logic                           prb_dc_mmu_req;
(* mark_debug = "true" *) logic                           prb_dc_mmu_rsp;
(* mark_debug = "true" *) logic                           prb_dc_ppl_req;
(* mark_debug = "true" *) logic                           prb_dc_ppl_rsp;

(* mark_debug = "true" *) logic                           prb_dc_st1_act;
(* mark_debug = "true" *) dc_req_src_e                    prb_dc_req_src_st1;       
dcache_req_t                    prb_dc_req_bits_st1; 
(* mark_debug = "true" *) logic                           prb_dc_replay_st1;
(* mark_debug = "true" *) logic                           prb_dc_cacheble;
(* mark_debug = "true" *) logic                           prb_dc_hit;
(* mark_debug = "true" *) logic                           prb_dc_miss;
(* mark_debug = "true" *) logic[DCACHE_WAY_WTH-1:0]       prb_dc_hit_way;
(* mark_debug = "true" *) logic                           prb_dc_lookup_hit;
(* mark_debug = "true" *) logic                           prb_dc_act_st2;
(* mark_debug = "true" *) logic                           prb_probe_flight;
(* mark_debug = "true" *) logic                           prb_dc_stall;
(* mark_debug = "true" *) logic                           prb_dc_ppl_valid;
(* mark_debug = "true" *) logic[63:0]                     prb_dc_ppl_rdata;
(* mark_debug = "true" *) logic                           prb_dc_mmu_valid;
(* mark_debug = "true" *) logic[63:0]                     prb_dc_mmu_rdata;


assign prb_dc_wr_req        = cache_wr_en;
assign prb_dc_replay_req    = miss_replay_req;
assign prb_dc_replay_rsp    = miss_replay_rsp;
assign prb_dc_mmu_req       = mmu_dmem__req_i;
assign prb_dc_mmu_rsp       = dmem_mmu__rsp_o;
assign prb_dc_ppl_req       = ppl_dmem__req_i;
assign prb_dc_ppl_rsp       = dmem_ppl__rsp_o;

assign prb_dc_st1_act       = act_st1;
assign prb_dc_req_src_st1   = req_src_st1;       
assign prb_dc_req_bits_st1  = dc_req_bits_st1; 
assign prb_dc_replay_st1    = replay_req_st1;
assign prb_dc_cacheble      = cacheable;
assign prb_dc_hit           = cache_hit;
assign prb_dc_miss          = cache_miss;
assign prb_dc_hit_way       = cache_hit_way_idx;
assign prb_dc_lookup_hit    = lookup_hit;
assign prb_dc_act_st2       = act_st2;
assign prb_probe_flight     = probe_flight_i;
assign prb_dc_stall         = dc_access_stall;

assign prb_dc_ppl_valid     = dmem_ppl__rsp_bits_o.valid;
assign prb_dc_ppl_rdata     = dmem_ppl__rsp_bits_o.rdata;
assign prb_dc_mmu_valid     = dmem_mmu__rsp_bits_o.valid;
assign prb_dc_mmu_rdata     = dmem_mmu__rsp_bits_o.rdata;

(* mark_debug = "true" *) state_e                             prb_dc_ctrl_state;
assign prb_dc_ctrl_state = state_q;

endmodule
// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_icache.v
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

module sy_icache  
  import sy_pkg::*;
#(
  parameter                             HART_ID_WTH  = 1,
  parameter logic [HART_ID_WTH-1:0]     HART_ID      = 0
) (
  input  logic                      clk_i,
  input  logic                      rst_i,
  input  logic                      kill_i,

  input  logic                      flush_i,              
  output logic                      flush_done_o,
  output logic                      ic_ctrl_idle_o,
  // fetch requests
  input  logic                      fet_icache__req_i,
  output logic                      icache_fet__rsp_o,
  input  fetch_req_t                fet_icache__req_bits_i,
  output fetch_rsp_t                icache_fet__rsp_bits_o,
  // refill port
  // A channel
  output logic                      icache_A_valid_o,
  input  logic                      icache_A_ready_i,
  output tl_pkg::A_chan_bits_t      icache_A_bits_o,
  // D channel
  output logic                      icache_D_ready_o,
  input  logic                      icache_D_valid_i,
  input  tl_pkg::D_chan_bits_t      icache_D_bits_i           
);

//======================================================================================================================
// local Parameter
//======================================================================================================================
  localparam logic [0:0]            ICACHE_ID    = 0;
  localparam logic [HART_ID_WTH:0]  SOURCE_ID = {HART_ID,ICACHE_ID};

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
  // cpmtroller FSM
  typedef enum logic[2:0] {IDLE, REFILL, REFILL_WAIT, KILL_REFILL,REPLAY_REQ} state_e;
  state_e state_d, state_q;

  logic                                                   cache_ren;                   
  logic [ICACHE_TAG_LSB-ICACHE_DATA_WTH-1:0]              cache_raddr;      // used to select data array
  logic [ICACHE_SET_WTH-1:0]                              cache_set_inx;    // used to select tag array
  logic [ICACHE_DATA_SIZE*8-1:0]                          cache_rdata [ICACHE_WAY_NUM-1:0];
  logic [ICACHE_TAG_WTH-1:0]                              cache_rtag [ICACHE_WAY_NUM-1:0];
  logic                                                   cache_rvalid [ICACHE_WAY_NUM-1:0];
  logic [ICACHE_DATA_SIZE*8-1:0]                          cache_wdata;            
  logic [ICACHE_TAG_LSB-ICACHE_DATA_WTH-1:0]              cache_waddr;      
  logic [ICACHE_TAG_LSB-ICACHE_DATA_WTH-1:0]              cache_addr; 
  logic                                                   cache_data_wr; 
  logic                                                   cache_tag_wr;
  logic [ICACHE_SET_SIZE-1:0][ICACHE_TAG_WTH-1:0]         tag_array [ICACHE_WAY_NUM-1:0];
  logic [ICACHE_SET_SIZE-1:0]                             cl_valid [ICACHE_WAY_NUM-1:0];   // cache_line_valid
  logic [ICACHE_FETCH_SIZE*8-1:0]                         cl_rdata [ICACHE_WAY_NUM-1:0];  
  logic [$clog2(ICACHE_WAY_NUM)-1:0]                      hit_idx;
  logic [ICACHE_SET_SIZE-1:0]                             plru0;
  logic [ICACHE_SET_SIZE-1:0][1:0]                        plru1;
  logic [ICACHE_SET_SIZE-1:0][1:0]                        plru_rpl_way;
  logic [1:0]                                             rpl_way,rpl_way_d,rpl_way_q;
  logic [4:0]                                             counter_d, counter_q;
  logic                                                   transaction_done;
  logic                                                   transaction_last;
  logic [ICACHE_WAY_NUM-1:0]                              cache_wen;
  logic [ICACHE_TAG_LSB-ICACHE_DATA_WTH-1:0]              waddr_d, waddr_q;      
  logic [$clog2(ICACHE_WAY_NUM)-1:0]                      inv_way;
  logic                                                   all_ways_valid;
  logic                                                   valid_flush;
  logic                                                   ic_access_stall;
  logic                                                   allow_ic_req;
  logic                                                   kill_st1;  
  logic [ICACHE_SET_WTH-1:0]                              cache_set_inx_st1;    // used to select tag array
  logic [ICACHE_SET_WTH-1:0]                              wr_set_inx;    // used to select tag array
  logic [ICACHE_TAG_LSB-1:0]                              req_addr_inx,req_addr_inx_st1;
  logic [ICACHE_DATA_MSB-1:0]                             data_offset_st1;
  logic                                                   replay_req_st1;
  logic [ICACHE_WAY_NUM-1:0]                              tag_match;
  logic [ICACHE_WAY_NUM-1:0]                              valid_bit;
  logic [ICACHE_WAY_NUM-1:0]                              is_hit;
  logic [ICACHE_TAG_WTH-1:0]                              tag_st1;  
  logic                                                   cacheable,cacheable_d,cacheable_q;
  logic [ICACHE_TAG_MSB-1:0]                              miss_addr_d,miss_addr_q;
  logic                                                   miss_replay_req;
  logic                                                   act_st1;
  logic                                                   act_st2;
  logic [FETCH_WIDTH-1:0]                                 cache_rd_data_st2;
  logic [63:0]                                            miss_rdata_d,miss_rdata_q;
  logic [FETCH_WIDTH-1:0]                                 fetch_data;  
  logic                                                   cache_hit;
  logic                                                   cache_miss;
  logic [ICACHE_TAG_WTH-1:0]                              tag_st0;
//======================================================================================================================
// Stage 0 : access I cache Mem
//======================================================================================================================
  always_comb begin : req_gen
    cache_raddr     = fet_icache__req_bits_i.addr_inx[ICACHE_TAG_LSB-1:ICACHE_DATA_MSB];
    cache_set_inx   = fet_icache__req_bits_i.addr_inx[ICACHE_SET_MSB-1:ICACHE_SET_LSB];
    req_addr_inx    = fet_icache__req_bits_i.addr_inx;
    cache_ren           = 1'b0;
    icache_fet__rsp_o   = 1'b0;
    tag_st0         = fet_icache__req_bits_i.addr_tag;
    // write to D cache
    if (miss_replay_req) begin
      cache_ren = 1'b1;
      cache_raddr   = miss_addr_q[ICACHE_TAG_LSB-1:ICACHE_DATA_MSB]; 
      cache_set_inx = miss_addr_q[ICACHE_SET_MSB-1:ICACHE_SET_LSB];
      req_addr_inx  = miss_addr_q[ICACHE_TAG_LSB-1:0];
      tag_st0       = miss_addr_q[ICACHE_TAG_MSB-1:ICACHE_TAG_LSB];
    // fet request
    end else if (fet_icache__req_i) begin
      icache_fet__rsp_o = !ic_access_stall;
      cache_ren = 1'b1; 
    end
  end
//======================================================================================================================
// Stage 1 : Check whether the cache is hit
//======================================================================================================================
  // save signals from stage 0
  always_ff @(`DFF_CR(clk_i, rst_i)) begin
    if (`DFF_IS_R(rst_i)) begin
      act_st1              <= `TCQ 1'b0;
      replay_req_st1       <= `TCQ 1'b0;
      data_offset_st1      <= `TCQ ICACHE_DATA_MSB'(0);
      req_addr_inx_st1     <= `TCQ ICACHE_TAG_LSB'(0);
      tag_st1              <= `TCQ ICACHE_TAG_WTH'(0);
    end else begin
      act_st1              <= `TCQ miss_replay_req || fet_icache__req_i && icache_fet__rsp_o;
      replay_req_st1       <= `TCQ miss_replay_req;
      data_offset_st1      <= `TCQ miss_replay_req ? {miss_addr_q[ICACHE_DATA_MSB-1],2'b0} :
                                                     {fet_icache__req_bits_i.addr_inx[ICACHE_DATA_MSB-1],2'b0};
      req_addr_inx_st1     <= req_addr_inx;
      tag_st1              <= `TCQ tag_st0;
    end
  end

  assign cache_set_inx_st1 = req_addr_inx_st1[ICACHE_SET_MSB-1:ICACHE_SET_LSB];
  // kill stage 1
  assign kill_st1 = fet_icache__req_bits_i.kill || kill_i;
  assign cacheable = is_cacheable({(64-DCACHE_TAG_WTH-DCACHE_TAG_LSB)'(0),tag_st1, {DCACHE_TAG_LSB{1'b0}}});
  // assign tag_st1 = replay_req_st1 ? miss_addr_q[ICACHE_TAG_MSB-1:ICACHE_TAG_LSB] : fet_icache__req_bits_i.addr_tag;

  for(genvar i=0; i<ICACHE_WAY_NUM; i++) begin: hit_logic
    assign tag_match[i] = (cache_rtag[i] == tag_st1); 
    assign is_hit[i] = tag_match[i] && cache_rvalid[i];
    assign cl_rdata[i] = cache_rdata[i][{data_offset_st1,3'b0} +: ICACHE_FETCH_SIZE*8];
    assign valid_bit[i] = cache_rvalid[i];
  end
  // transform hit idx from one-hot to index
  always_comb begin
    hit_idx = 0;
    for (integer i=0; i<ICACHE_WAY_NUM; i++) begin
      if (is_hit[i]) begin
        hit_idx = i;
      end
    end
  end 
  // cache hit and miss siganl
  assign cache_hit = act_st1 &&  (|is_hit) && cacheable && !kill_st1;
  assign cache_miss= act_st1 && !(|is_hit) && cacheable && !kill_st1;

  assign fetch_data = cacheable ? cl_rdata[hit_idx] : miss_rdata_q[{data_offset_st1,3'b0} +: ICACHE_FETCH_SIZE*8];
//======================================================================================================================
// Stage 2 : return data
//======================================================================================================================
  always_ff @(`DFF_CR(clk_i, rst_i)) begin
      if(`DFF_IS_R(rst_i)) begin
          act_st2          <= `TCQ 1'b0;    
          cache_rd_data_st2<= `TCQ '0;
      end else begin
          act_st2          <= `TCQ act_st1 && (cache_hit || !cacheable && replay_req_st1) && !kill_i;
          cache_rd_data_st2<= `TCQ fetch_data;
      end
  end

  assign icache_fet__rsp_bits_o.valid = cache_hit || act_st1 && !cacheable && replay_req_st1;
  // assign icache_fet__rsp_bits_o.data  = cache_rd_data_st2;
  assign icache_fet__rsp_bits_o.data  = fetch_data;
//======================================================================================================================
// FSM handle refill request 
//======================================================================================================================
  // TileLin A channel interface
  assign icache_A_bits_o.opcode = tl_pkg::Get;
  assign icache_A_bits_o.param.permission = tl_pkg::NtoB;
  // if access non-cacheable area,just read 8B
  assign icache_A_bits_o.size = cacheable_q ? (ICACHE_BLOCK_SIZE / ICACHE_DATA_SIZE - 1) : '0; 
  assign icache_A_bits_o.source = SOURCE_ID;
  // address must be aligned to size 
  assign icache_A_bits_o.address = cacheable_q ? ((miss_addr_q >> ICACHE_BLOCK_WTH) << ICACHE_BLOCK_WTH) : 
                                                 ((miss_addr_q >> ICACHE_DATA_WTH)  << ICACHE_DATA_WTH);  
  assign icache_A_bits_o.mask = {tl_pkg::MASK_WTH{1'b1}};
  assign icache_A_bits_o.data = '0;
  assign icache_A_bits_o.corrupt = 1'b0;
  // transaction counter and address
  always_comb begin : transaction_cnt
    waddr_d = waddr_q;
    counter_d = counter_q;
    if (icache_A_valid_o && icache_A_ready_i) begin
      counter_d = cacheable_q ? (ICACHE_BLOCK_SIZE / ICACHE_DATA_SIZE) : 1'b1;     
      waddr_d = miss_addr_q[ICACHE_TAG_LSB-1:ICACHE_BLOCK_WTH] << 4;
    end else if (counter_q != '0 && (icache_D_valid_i && icache_D_ready_o)) begin
      counter_d = counter_q - 1'b1;
      waddr_d = waddr_q + 1;
    end
  end
  assign transaction_done = (counter_q == '0);
  assign transaction_last = (counter_q == 1'b1);
  // not allow new fetch request
  assign ic_access_stall = !allow_ic_req;

  // find invalid cache line
  lzc #(
    .WIDTH ( ICACHE_WAY_NUM)
  ) i_lzc_inv (
    .in_i    ( ~valid_bit), 
    .cnt_o   ( inv_way                         ),
    .empty_o ( all_ways_valid                  )
  );
  // if all cache line is valid, through plru to choose replace way, otherwise choose invalid way
  assign rpl_way = all_ways_valid ? plru_rpl_way[cache_set_inx_st1] : inv_way;

  assign wr_set_inx = miss_addr_q[ICACHE_SET_MSB-1:ICACHE_SET_LSB];
  assign flush_done_o = flush_i;
  assign ic_ctrl_idle_o = (state_q == IDLE);
  always_comb begin : refill_fsm
    state_d        = state_q;
    miss_addr_d    = miss_addr_q;
    cacheable_d    = cacheable_q;
    miss_rdata_d   = miss_rdata_q;
    rpl_way_d      = rpl_way_q;
    allow_ic_req   = 1'b0;
    miss_replay_req= 1'b0;
    valid_flush    = 1'b0;
    icache_A_valid_o = 1'b0;
    icache_D_ready_o = 1'b0;
    cache_data_wr = 1'b0;
    cache_tag_wr  = 1'b0;
    unique case (state_q)
      IDLE: begin
        allow_ic_req = 1'b1;
        // cache miss or access non-cacheable area 
        if ((cache_miss || act_st1 && !cacheable && !replay_req_st1 && !kill_st1) && !kill_i) begin
          // save miss instruction info, such as addr/write data and so on
          state_d = REFILL;
          miss_addr_d    = {tag_st1,req_addr_inx_st1};
          cacheable_d    = cacheable;
          rpl_way_d      = rpl_way;
        end
      end
      REFILL: begin
        if (kill_i || flush_i) begin
          state_d = IDLE;
        end else begin
          icache_A_valid_o = 1'b1;
          if (icache_A_ready_i) begin
              state_d = REFILL_WAIT;
          end
        end
      end
      // wait until the memory transaction returns. 
      REFILL_WAIT: begin
        if (kill_i || flush_i) begin
          state_d = KILL_REFILL; 
        end else begin
          icache_D_ready_o = 1'b1;
          if (icache_D_valid_i && icache_D_ready_o) begin
            cache_data_wr = cacheable_q;  
            if (transaction_last) begin
              if (~cacheable_q) begin
                state_d = REPLAY_REQ;
                miss_rdata_d = icache_D_bits_i.data;
              end else begin
                cache_tag_wr = 1'b1;
              end
            end
          end else if (transaction_done) begin
              state_d = REPLAY_REQ; 
          end
        end
      end
      // killed miss, wait until memory responds and go back to idle
      KILL_REFILL: begin  
        icache_D_ready_o = 1'b1;
        if (icache_D_valid_i && icache_D_ready_o) begin
          if (transaction_last) begin
            if (~cacheable_q) begin
              state_d = IDLE;
            end else begin
              valid_flush = 1'b1;
            end
          end
        end else begin
          if (transaction_done == 1'b1) begin
              state_d = IDLE;
          end
        end
      end
      // replay read request
      REPLAY_REQ: begin
        if (kill_i || flush_i) begin
          state_d = IDLE;
        end else begin
          miss_replay_req = 1'b1;
          state_d = IDLE;
        end
      end
      default: begin
        state_d = IDLE;
      end
    endcase // state_q
  end
//======================================================================================================================
// replacement strategy
//======================================================================================================================
  always_ff @(`DFF_CR(clk_i, rst_i)) begin : plru
      if(`DFF_IS_R(rst_i)) begin
          for(integer i=0; i<ICACHE_SET_SIZE; i++) begin
              plru0[i] <= `TCQ 1'b0;
              plru1[i] <= `TCQ 2'h0;
          end
      end else begin
          if(cache_hit) begin
              plru0[cache_set_inx_st1] <= `TCQ hit_idx[0];
              if(!hit_idx[0]) begin
                  plru1[cache_set_inx_st1][0] <= `TCQ hit_idx[1];
              end else begin
                  plru1[cache_set_inx_st1][1] <= `TCQ hit_idx[1];
              end
          end
      end
  end
  always_comb begin
      for(integer i=0; i<ICACHE_SET_SIZE; i++) begin
          plru_rpl_way[i][0] = ~plru0[i];
          plru_rpl_way[i][1] = ~plru0[i] ? ~plru1[i][1] : ~plru1[i][0];
      end
  end
//======================================================================================================================
// Icache data/tag/valid
//======================================================================================================================
  assign cache_wdata = icache_D_bits_i.data;
  assign cache_waddr = waddr_q;

  assign cache_addr = |cache_wen ? cache_waddr : cache_raddr;
  for (genvar i = 0; i < ICACHE_WAY_NUM; i++) begin : tag_and_data
    assign cache_wen[i] = cache_data_wr && (i==rpl_way_q);
    sp_512x64sd1_wrap data_ram(
        .clk_i          (clk_i),     
        .vld_i          (cache_wen[i] || cache_ren),     
        .we_i           (cache_wen[i]),    
        .addr_i         (cache_addr),      
        .wdata_i        (cache_wdata),       
        .wstrb_i        (8'hff),       
        .rdata_o        (cache_rdata[i])
    );
   
    // tag array
    always_ff @(`DFF_CR(clk_i,rst_i))begin
      if(`DFF_IS_R(rst_i)) begin
        tag_array[i] <= '0;
      // write tag
      end else if(cache_tag_wr && (i==rpl_way_q)) begin
        tag_array[i][wr_set_inx] <= miss_addr_q[ICACHE_TAG_MSB-1:ICACHE_TAG_LSB];
      end
    end

    // read tag
    always_ff @(`DFF_CR(clk_i,rst_i))begin
      if(`DFF_IS_R(rst_i)) begin
        cache_rtag[i] <= '0;
      end else if(cache_ren) begin
        cache_rtag[i] <= tag_array[i][cache_set_inx];
      end
    end
    // valid bit array
    always_ff @(`DFF_CR(clk_i,rst_i)) begin
      if(`DFF_IS_R(rst_i)) begin
        cl_valid[i] <= '0;  
      end else if(flush_i) begin
        cl_valid[i] <= '0;
      end else if(valid_flush && (i==rpl_way_q)) begin
        cl_valid[i][wr_set_inx] <= 1'b0;
      // refill cache line
      end else if(cache_tag_wr && (i==rpl_way_q)) begin
        cl_valid[i][wr_set_inx] <= 1'b1;
      end
    end
    // read valid bit
    always_ff @(`DFF_CR(clk_i,rst_i))begin
      if(`DFF_IS_R(rst_i)) begin
        cache_rvalid[i] <= '0;
      end else if(cache_ren) begin
        cache_rvalid[i] <= cl_valid[i][cache_set_inx];
      end
    end
  end

//======================================================================================================================
// Registers
//======================================================================================================================
  always_ff @(`DFF_CR(clk_i,rst_i)) begin : p_regs
    if(`DFF_IS_R(rst_i)) begin
      state_q          <= `TCQ IDLE;
      cacheable_q      <= `TCQ 1'b0;
      counter_q        <= `TCQ '0;
      waddr_q          <= `TCQ '0;
      rpl_way_q        <= `TCQ '0;
      miss_addr_q      <= `TCQ '0;
      miss_rdata_q     <= `TCQ '0;
    end else begin
      state_q          <= `TCQ state_d;
      cacheable_q      <= `TCQ cacheable_d;
      counter_q        <= `TCQ counter_d;
      waddr_q          <= `TCQ waddr_d;
      rpl_way_q        <= `TCQ rpl_way_d;
      miss_addr_q      <= `TCQ miss_addr_d;
      miss_rdata_q     <= `TCQ miss_rdata_d;
    end
  end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
// (* mark_debug = "true" *) state_e     prb_ic_state;
// (* mark_debug = "true" *) logic       prb_ic_st1_act;
// (* mark_debug = "true" *) logic       prb_ic_hit;
// (* mark_debug = "true" *) logic       prb_ic_miss;
// (* mark_debug = "true" *) logic       prb_ic_cacheable;

// assign prb_ic_state     = state_q;
// assign prb_ic_st1_act   = act_st1;
// assign prb_ic_hit       = cache_hit;
// assign prb_ic_miss      = cache_miss;
// assign prb_ic_cacheable = cacheable;

endmodule
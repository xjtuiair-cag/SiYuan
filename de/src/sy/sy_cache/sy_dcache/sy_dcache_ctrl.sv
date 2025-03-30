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

    output logic                            cache_miss_o,               
    output logic                            allow_probe_o,
    input  logic                            probe_flight_i, // there exist a probe req handled by miss unit      
    input  logic                            acquire_flight_i,   
    // =====================================
    // [lsu and mmu will send this req]
    input  dcache_req_t [REQ_PORT-1:0]      dcache_req_i,
    output dcache_rsp_t [REQ_PORT-1:0]      dcache_rsp_o,
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
  localparam Arbiter_port = REQ_PORT; // 0 port is for mmu, 1 port is for lsu, 0 port has higher priority 
  localparam Arbiter_wth = $clog2(Arbiter_port);
  typedef enum logic [1:0] {
    READ  = 0,
    WRITE = 1,
    AMO   = 2
  } cache_cmd_e;
  localparam LRSC_CNT_INIT = 7'd80;
  localparam LRSC_THRESH   = 7'd3;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
  typedef enum logic[3:0] {IDLE,IS_HIT,RTN_DATA,MISS_REQ,MISS_WAIT,KILL_MISS,KILL_MISS_ACK,REPLAY_REQ,WAIT_PROBE_DONE} state_e;
  state_e state_d, state_q;

  logic [Arbiter_port-1:0]                        arbiter_req;
  logic [Arbiter_port-1:0]                        arbiter_gnt;
  logic [Arbiter_wth-1:0]                         arbiter_sel;
  logic [Arbiter_wth-1:0]                         arbiter_sel_d, arbiter_sel_q;
  logic                                           dcache_req;
  logic                                           dcache_ready;
  logic                                           dcache_rsp_valid;
  logic [DCACHE_TAG_WTH-1:0]                      addr_tag_d,addr_tag_q; 
  logic [DCACHE_TAG_LSB-1:0]                      addr_inx_d,addr_inx_q; 
  logic                                           save_tag;
  logic                                           kill_req;
  logic                                           tag_rd_en_dly1;
  logic                                           tag_rd_en;
  logic                                           tag_wr_en;
  logic                                           data_rd_en;
  logic                                           data_wr_en;
  logic [DCACHE_WAY_NUM-1:0]                      tag_match;
  logic [DCACHE_WAY_NUM-1:0]                      state_match;
  logic [DCACHE_WAY_NUM-1:0]                      cache_hit;    
  logic [DCACHE_WAY_NUM-1:0]                      way_valid;    
  logic                                           need_update_d, need_update_q;       
  cache_cmd_e                                     cmd_d, cmd_q;
  amo_t                                           amo_opcode_d, amo_opcode_q;
  logic [DCACHE_DATA_SIZE*8-1:0]                  cache_rd_data;
  logic [DCACHE_DATA_SIZE*8-1:0]                  cache_wr_data;
  logic [DCACHE_DATA_SIZE*8-1:0]                  wr_data_d, wr_data_q;
  logic [DCACHE_DATA_SIZE*8-1:0]                  data_after_amo;
  logic [$clog2(DCACHE_WAY_NUM)-1:0]              hit_idx,hit_idx_d,hit_idx_q;  
  logic [1:0]                                     size_d,size_q;
  logic [7:0]                                     byte_en_d,byte_en_q;
  logic [DCACHE_TAG_MSB-DCACHE_BLOCK_WTH-1:0]     lrsc_addr_d,lrsc_addr_q;  
  logic                                           sc_fail;
  logic                                           del_lr_addr;
  logic                                           lrsc_addr_match; 
  logic [6:0]                                     lrsc_cnt_d,lrsc_cnt_q;  
  logic                                           lrsc_valid;
  logic                                           save_lr_addr;
  logic                                           cacheable;
  logic [$clog2(DCACHE_WAY_NUM)-1:0]              rpl_way;
  logic [$clog2(DCACHE_WAY_NUM)-1:0]              inv_way;
  logic [DCACHE_SET_SIZE-1:0]                     plru0;
  logic [DCACHE_SET_SIZE-1:0][1:0]                plru1;
  logic [DCACHE_SET_SIZE-1:0][1:0]                plru_rpl_way;
  logic                                           will_save_tag,will_save_tag_dly;
  logic                                           all_ways_valid;
  logic [DCACHE_WAY_NUM-1:0]                      is_valid;
  logic [$clog2(DCACHE_WAY_NUM)-1:0]              update_way_idx, update_way_idx_d, update_way_idx_q;
  
//======================================================================================================================
// Instance
//======================================================================================================================
  assign arbiter_req[0] = dcache_req_i[0].req; // mmu
  assign arbiter_req[1] = dcache_req_i[1].req; // lsu

  assign dcache_rsp_o[0].ack = arbiter_gnt[0] && arbiter_req[0];  // mmu
  assign dcache_rsp_o[1].ack = arbiter_gnt[1] && arbiter_req[1];  // lsu
  
  // arbiter for tag
  rr_arb_tree #(
    .NumIn     (Arbiter_port),
    .DataWidth (1)
  ) req_rr_arb_tree (
    .clk_i  (clk_i          ),
    .rst_ni (rst_i          ),
    .flush_i('0             ),
    .rr_i   ('0             ),
    .req_i  (arbiter_req    ),
    .gnt_o  (arbiter_gnt    ),
    .data_i ('0             ),
    .gnt_i  (dcache_ready   ),
    .req_o  (dcache_req     ),
    .data_o (               ),
    .idx_o  (arbiter_sel    )
  );

  assign arbiter_sel_d = (dcache_req && dcache_ready) ? arbiter_sel : arbiter_sel_q; 

//======================================================================================================================
// Lock all necessary signals when accept a new req
//======================================================================================================================
  // lock index when accpt new req
  assign addr_inx_d = (dcache_req && dcache_ready) ? dcache_req_i[arbiter_sel].addr_inx : addr_inx_q;
  // lock tag when save tag is assert
  assign addr_tag_d = save_tag ? dcache_req_i[arbiter_sel_q].addr_tag : addr_tag_q;
  assign kill_req = dcache_req_i[arbiter_sel_q].kill;
  always_comb begin
    cmd_d = cmd_q;
    amo_opcode_d = amo_opcode_q;
    if (dcache_req && dcache_ready) begin
      amo_opcode_d = AMO_NONE;
      if (arbiter_sel) begin // lsu
        if (dcache_req_i[1].amo_op != AMO_NONE) begin
          cmd_d = AMO;
          amo_opcode_d = dcache_req_i[1].amo_op;
        end else if (dcache_req_i[1].we) begin
          cmd_d = WRITE;
        end else begin
          cmd_d = READ;
        end
      end else begin        // mmu
        cmd_d = READ;       // mmu only read
      end
    end
  end
  assign size_d    = (dcache_req && dcache_ready) ? dcache_req_i[arbiter_sel].size  : size_q;
  assign wr_data_d = (dcache_req && dcache_ready) ? dcache_req_i[arbiter_sel].wdata : wr_data_q;
  assign byte_en_d = (dcache_req && dcache_ready) ? dcache_req_i[arbiter_sel].be    : byte_en_q;

//======================================================================================================================
// interface with cache mem
//======================================================================================================================
  assign data_req_o     = data_rd_en  || data_wr_en;
  assign tag_req_o      = tag_rd_en   || tag_wr_en; 

  assign data_req_bits_o.idx      = addr_inx_q;
  assign data_req_bits_o.we       = data_wr_en ? 1'b1 : 1'b0;
  assign data_req_bits_o.way_en   = (1'b1 << hit_idx_d); // only access hit way
  assign data_req_bits_o.wr_data  = cache_wr_data; 

  // tag read is earier than data read, so use addr_inx_d
  assign tag_req_bits_o.idx       = addr_inx_d;
  assign tag_req_bits_o.we        = tag_wr_en ? 1'b1 : 1'b0;
  assign tag_req_bits_o.way_en    = tag_wr_en ? (1'b1 << hit_idx_q)  : 4'hf;
  //                                 {   tag ,   state ,valid}
  assign tag_req_bits_o.wr_tag    = {addr_tag_q, Dirty, 1'b1}; 
  // address is cacheable ? 
  assign cacheable = is_cacheable({addr_tag_q, {DCACHE_TAG_LSB{1'b0}}});
//======================================================================================================================
// cache hit generate logic 
//======================================================================================================================
  always_comb begin
    for (integer i=0; i<DCACHE_WAY_NUM; i++) begin: gen_cache_hit
      tag_match[i] = (tag_rsp_bits_i.tag_data[i].tag == addr_tag_d); 
      case(cmd_q)
        READ: state_match[i] = tag_rsp_bits_i.tag_data[i].state != Nothing;
        WRITE,AMO : state_match[i] = tag_rsp_bits_i.tag_data[i].state == Dirty
                    || tag_rsp_bits_i.tag_data[i].state == Trunk;
        default: state_match[i] = 1'b0;
      endcase
      // if cache line is valid and tag is match and state is match, then cache hit
      cache_hit[i] = tag_match[i] && state_match[i] && tag_rsp_bits_i.tag_data[i].valid;
      is_valid[i] = tag_rsp_bits_i.tag_data[i].valid;
    end
  end
  // cache mem has data, but need greater state, such as Branch --> Trunk, so need to update cache line
  assign need_update_d = tag_rd_en_dly1 ? |(tag_match & is_valid) : need_update_q;
  oneHot2Int #(
    .WIDTH ( DCACHE_WAY_NUM)
  ) valid_to_idx (
    .in_i    ( tag_match & is_valid),
    .cnt_o   ( update_way_idx),
    .empty_o (         )
  );
  assign update_way_idx_d = tag_rd_en_dly1 ? update_way_idx : update_way_idx_q;
//======================================================================================================================
// AMO Unit
//======================================================================================================================
  oneHot2Int #(
    .WIDTH ( DCACHE_WAY_NUM)
  ) hit_to_idx (
    .in_i    ( cache_hit),
    .cnt_o   ( hit_idx ),
    .empty_o (         )
  );
  assign hit_idx_d = tag_rd_en_dly1 ? hit_idx : hit_idx_q;

  assign cache_rd_data = data_rsp_bits_i.rd_data; // cache_rd_data (64bit)
  always_comb begin
    case (amo_opcode_q) 
      AMO_SWAP  : data_after_amo = wr_data_q;
      AMO_ADD   : data_after_amo = cache_rd_data + wr_data_q;
      AMO_AND   : data_after_amo = cache_rd_data & wr_data_q;
      AMO_OR    : data_after_amo = cache_rd_data | wr_data_q;
      AMO_XOR   : data_after_amo = cache_rd_data ^ wr_data_q;
      AMO_MAX   : begin
        if (size_q == 2'b11) begin // double word
          data_after_amo = ($signed(cache_rd_data) > $signed(wr_data_q)) ? cache_rd_data : wr_data_q;
        end else begin
          data_after_amo[31:0]  = $signed({{32{cache_rd_data[31]}},cache_rd_data[31:0]}) > $signed({{32{wr_data_q[31]}},wr_data_q[31:0]}) 
                            ? cache_rd_data[31:0] : wr_data_q[31:0];         
          data_after_amo[63:32] = $signed({{32{cache_rd_data[63]}},cache_rd_data[63:32]}) > $signed({{32{wr_data_q[63]}},wr_data_q[63:32]}) 
                            ? cache_rd_data[63:32] : wr_data_q[63:32];         
        end
      end
      AMO_MAXU   : begin
        if (size_q == 2'b11) begin // double word
          data_after_amo = (cache_rd_data > wr_data_q) ? cache_rd_data : wr_data_q;
        end else begin
          data_after_amo[31:0]  = {{32{1'b0}},cache_rd_data[31:0]} > {{32{1'b0}},wr_data_q[31:0]} 
                            ? cache_rd_data[31:0] : wr_data_q[31:0];         
          data_after_amo[63:32] = {{32{1'b0}},cache_rd_data[63:32]} > {{32{1'b0}},wr_data_q[63:32]} 
                            ? cache_rd_data[63:32] : wr_data_q[63:32];         
        end
      end
      AMO_MIN   : begin
        if (size_q == 2'b11) begin // double word
          data_after_amo = ($signed(cache_rd_data) < $signed(wr_data_q)) ? cache_rd_data : wr_data_q;
        end else begin
          data_after_amo[31:0]  = $signed({{32{cache_rd_data[31]}},cache_rd_data[31:0]}) < $signed({{32{wr_data_q[31]}},wr_data_q[31:0]}) 
                            ? cache_rd_data[31:0] : wr_data_q[31:0];         
          data_after_amo[63:32] = $signed({{32{cache_rd_data[63]}},cache_rd_data[63:32]}) < $signed({{32{wr_data_q[63]}},wr_data_q[63:32]}) 
                            ? cache_rd_data[63:32] : wr_data_q[63:32];         
        end
      end
      AMO_MINU   : begin
        if (size_q == 2'b11) begin // double word
          data_after_amo = (cache_rd_data < wr_data_q) ? cache_rd_data : wr_data_q;
        end else begin
          data_after_amo[31:0]  = {{32{1'b0}},cache_rd_data[31:0]} < {{32{1'b0}},wr_data_q[31:0]} 
                            ? cache_rd_data[31:0] : wr_data_q[31:0];         
          data_after_amo[63:32] = {{32{1'b0}},cache_rd_data[63:32]} < {{32{1'b0}},wr_data_q[63:32]} 
                            ? cache_rd_data[63:32] : wr_data_q[63:32];         
        end
      end
      default   : data_after_amo = wr_data_q; // AMO_NONE or AMO_SC or AMO_LR
    endcase
  end
//======================================================================================================================
// generate Write data 
//======================================================================================================================
  for (genvar i=0; i<8; i++) begin: gen_wr_data
    localparam int unsigned LSB = i*8;
    localparam int unsigned MSB = (i+1)*8-1;
    assign cache_wr_data[MSB:LSB] = byte_en_q[i] ? data_after_amo[MSB:LSB] : cache_rd_data[MSB:LSB];
  end

//======================================================================================================================
// LRSC Unit
//======================================================================================================================
  assign lrsc_addr_d = save_lr_addr ? {addr_tag_q, addr_inx_q>>DCACHE_BLOCK_WTH} : lrsc_addr_q;

  always_comb begin
    lrsc_cnt_d = lrsc_cnt_q;
    if(save_lr_addr) begin
      lrsc_cnt_d = LRSC_CNT_INIT;
    end else if (del_lr_addr) begin
      lrsc_cnt_d = 0;      
    end else if (lrsc_cnt_q != 0) begin
      lrsc_cnt_d = lrsc_cnt_q - 1;
    end
  end
  assign lrsc_addr_match = lrsc_addr_q == {addr_tag_q, addr_inx_q>>DCACHE_BLOCK_WTH};
  assign lrsc_valid = lrsc_cnt_q > LRSC_THRESH;

  assign allow_probe_o = !lrsc_valid;
  // store conditional failed 
  assign sc_fail = (amo_opcode_q == AMO_SC) && !(lrsc_valid && lrsc_addr_match);
  // assign sc_success = (amo_opcode_q == AMO_SC) && lrsc_valid && lrsc_addr_match;
//======================================================================================================================
// interface with mmu and lsu
//======================================================================================================================
  // mmu
  assign dcache_rsp_o[0].valid = dcache_rsp_valid && !arbiter_sel_q; // mmu
  assign dcache_rsp_o[0].rdata = cacheable ? cache_rd_data : miss_rdata_i;
  // lsu
  assign dcache_rsp_o[1].valid = dcache_rsp_valid && arbiter_sel_q; // lsu
  assign dcache_rsp_o[1].rdata = (amo_opcode_q == AMO_SC) ? sc_fail : (cacheable ? cache_rd_data : miss_rdata_i);

//======================================================================================================================
// interface with miss unit
//======================================================================================================================
  assign miss_req_bits_o.cmd            = need_update_q ? UPDATE : REFILL; 
  assign miss_req_bits_o.cacheable      = cacheable;
  assign miss_req_bits_o.addr           = {addr_tag_q, addr_inx_q};
  assign miss_req_bits_o.we             = (cmd_q == WRITE || cmd_q == AMO);
  assign miss_req_bits_o.be             = byte_en_q;
  assign miss_req_bits_o.wdata          = wr_data_q;
  assign miss_req_bits_o.amo_op         = amo_opcode_q;
  assign miss_req_bits_o.update_way     = update_way_idx_q;
  assign miss_req_bits_o.rpl_way        = rpl_way;  

//======================================================================================================================
// replacement strategy 
//======================================================================================================================
  logic [DCACHE_TAG_LSB-DCACHE_BLOCK_MSB-1:0] set_inx;
  assign set_inx = addr_inx_q[DCACHE_TAG_LSB-1:DCACHE_BLOCK_MSB];
  always_ff @(`DFF_CR(clk_i, rst_i)) begin : plru
      if (`DFF_IS_R(rst_i)) begin
          for (integer i=0; i<DCACHE_SET_SIZE; i++) begin
              plru0[i] <= `TCQ 1'b0;
              plru1[i] <= `TCQ 2'h0;
          end
      end else begin
          if (|cache_hit) begin
              plru0[set_inx] <= `TCQ hit_idx[0];
              if (!hit_idx[0]) begin
                  plru1[set_inx][0] <= `TCQ hit_idx[1];
              end else begin
                  plru1[set_inx][1] <= `TCQ hit_idx[1];
              end
          end
      end
  end
  always_comb begin
      for(integer i=0; i<DCACHE_SET_SIZE; i++) begin
          plru_rpl_way[i][0] = !plru0[i];
          plru_rpl_way[i][1] = !plru0[i] ? !plru1[1] : !plru1[0];
      end
  end
  always_ff @(`DFF_CR(clk_i, rst_i)) begin 
      if (`DFF_IS_R(rst_i)) begin
        way_valid         <= '0;
      end else if (tag_rd_en_dly1) begin
        for (integer i=0; i < DCACHE_WAY_NUM; i++) begin
          way_valid[i]    <= tag_rsp_bits_i.tag_data[i].valid; 
        end
      end
  end 
  // find invalid cache line
  lzc #(
    .WIDTH ( DCACHE_WAY_NUM)
  ) i_lzc_inv (
    .in_i    ( ~way_valid                      ), 
    .cnt_o   ( inv_way                         ),
    .empty_o ( all_ways_valid                  )
  );
  // if all cache line is valid, through plru to choose replace way, otherwise choose invalid way
  assign rpl_way = all_ways_valid ? plru_rpl_way[set_inx] : inv_way;
//======================================================================================================================
// FSM
//======================================================================================================================
  always_comb begin : fsm
    // default assignment
    state_d                 = state_q;
    save_tag                = 1'b0;
    tag_rd_en               = 1'b0;
    tag_wr_en               = 1'b0;
    data_rd_en              = 1'b0;
    data_wr_en              = 1'b0;
    dcache_ready            = 1'b0;
    dcache_rsp_valid        = 1'b0;
    save_lr_addr            = 1'b0; // save load reserved addr
    miss_req_o              = 1'b0; 
    cache_miss_o            = 1'b0;
    will_save_tag           = 1'b0;
    del_lr_addr             = 1'b0;

    unique case (state_q)
        // wait for an incoming request
        IDLE: begin
          // if miss unit is handling a probe, forbiden accepting new req until probe finish
          if (!kill_req && !probe_flight_i && dcache_req) begin
            tag_rd_en = 1'b1;
            if (tag_gnt_i) begin
              dcache_ready = 1'b1;
              will_save_tag = 1'b1;
              state_d = IS_HIT;
            end
          end
        end
        // read data and tag from cache mem and check whether we have a hit
        IS_HIT: begin
          save_tag = will_save_tag_dly;   
          if (kill_req) begin // kill 
            state_d = IDLE;
          end else if (probe_flight_i) begin
            state_d = WAIT_PROBE_DONE;
          end else begin
            // cache hit
            if (|cache_hit) begin 
              state_d = RTN_DATA;
              data_rd_en = 1'b1;
            // cache miss 
            end else begin
              cache_miss_o = 1'b1;
              state_d = MISS_REQ;
            end
          end
        end
        // Return data to lsu or mmu
        RTN_DATA: begin
          if (kill_req) begin
            state_d = IDLE;
          end else if (probe_flight_i) begin
            state_d = WAIT_PROBE_DONE;
          end else begin
            dcache_rsp_valid = 1'b1;
            tag_wr_en = (cmd_q == WRITE || (cmd_q == AMO && amo_opcode_q != AMO_LR && !sc_fail)); // write 
            data_wr_en = tag_wr_en;
            save_lr_addr = (cmd_q == AMO && amo_opcode_q == AMO_LR) && !lrsc_valid;
            del_lr_addr = (cmd_q == AMO && amo_opcode_q == AMO_SC) && !sc_fail;
            // if (dcache_req) begin
            //   tag_rd_en = 1'b1;
            //   if (tag_gnt_i) begin
            //     dcache_ready = 1'b1;  
            //     state_d = IS_HIT;
            //   end else begin
            //     state_d = IDLE;    
            //   end
            // end else begin
            //   state_d = IDLE;
            // end
            state_d = IDLE;
          end
        end
        // issue request to miss unit
        MISS_REQ: begin
          if (kill_req) begin
            state_d = IDLE;
          end else if (probe_flight_i) begin
            state_d = WAIT_PROBE_DONE;
          end else begin
            miss_req_o = 1'b1;
            if (miss_ack_i) begin
              state_d = MISS_WAIT;
            end
          end
        end
        // wait until the memory transaction returns.
        MISS_WAIT: begin
          if (kill_req) begin
            if (miss_done_i) begin
              state_d = IDLE;
            end else begin
              state_d = KILL_MISS;
            end
          // if miss unit has already send acquire request, don't go to WAIT_PROBE_DONE
          end else if (probe_flight_i && !acquire_flight_i) begin
            state_d = WAIT_PROBE_DONE;
          end else if (miss_done_i) begin
            // if data is non-cacheable
            if (!cacheable) begin
              dcache_rsp_valid = 1'b1;     
              state_d = IDLE;
            end else begin
              state_d = REPLAY_REQ; 
            end
          end
        end
        // replay read request
        REPLAY_REQ: begin
          if (kill_req) begin
            state_d = IDLE;
          end else if (probe_flight_i) begin
            state_d = WAIT_PROBE_DONE;  
          end else begin
            tag_rd_en = 1'b1;
            if (tag_gnt_i) begin
              state_d = IS_HIT;
            end
          end
        end
        WAIT_PROBE_DONE: begin
          if (kill_req) begin
            state_d = IDLE;
          end else if (!probe_flight_i) begin
            tag_rd_en = 1'b1;
            if (tag_gnt_i) begin
              state_d = IS_HIT;
            end
          end
        end
        KILL_MISS: begin
          if (probe_flight_i || miss_done_i) begin
            state_d = IDLE;
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
  always_ff @(posedge clk_i or negedge rst_i) begin : p_regs
    if(!rst_i) begin
      state_q           <= IDLE;
      arbiter_sel_q     <= '0; 
      addr_tag_q        <= '0; 
      addr_inx_q        <= '0; 
      need_update_q     <= '0; 
      cmd_q             <= READ; 
      amo_opcode_q      <= AMO_NONE; 
      wr_data_q         <= '0; 
      hit_idx_q         <= '0; 
      size_q            <= '0; 
      byte_en_q         <= '0; 
      lrsc_addr_q       <= '0; 
      lrsc_cnt_q        <= '0; 
      tag_rd_en_dly1  <= '0;
      will_save_tag_dly <= '0;
      update_way_idx_q <= '0;
    end else begin
      state_q           <= state_d       ;
      arbiter_sel_q     <= arbiter_sel_d ; 
      addr_tag_q        <= addr_tag_d    ; 
      addr_inx_q        <= addr_inx_d    ; 
      need_update_q     <= need_update_d ; 
      cmd_q             <= cmd_d         ; 
      amo_opcode_q      <= amo_opcode_d  ; 
      wr_data_q         <= wr_data_d     ; 
      hit_idx_q         <= hit_idx_d     ; 
      size_q            <= size_d        ; 
      byte_en_q         <= byte_en_d     ; 
      lrsc_addr_q       <= lrsc_addr_d   ; 
      lrsc_cnt_q        <= lrsc_cnt_d    ; 
      tag_rd_en_dly1    <= tag_rd_en     ;
      will_save_tag_dly <= will_save_tag ;
      update_way_idx_q  <= update_way_idx_d;
    end
  end

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule
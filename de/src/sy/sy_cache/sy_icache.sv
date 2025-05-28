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

// some code from this file come from cva6 : https://github.com/openhwgroup/cva6  

module sy_icache  
  import sy_pkg::*;
#(
  parameter                             HART_ID_WTH  = 1,
  parameter logic [HART_ID_WTH-1:0]     HART_ID      = 0
) (
  input  logic                      clk_i,
  input  logic                      rst_i,

  input  logic                      flush_i,              
  output logic                      flush_done_o,
  output logic                      cache_miss_o,               
  // address translation requests
  input  mmu_icache_rsp_t           mmu_icache__rsp_i,
  output icache_mmu_req_t           icache_mmu__req_o,
  // data requests
  input  fetch_req_t                fetch_icache__req_i,
  output fetch_rsp_t                icache_fetch__rsp_o,
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
  typedef enum logic[2:0] {IDLE, READ, REFILL, TLB_MISS, KILL_ATRANS, KILL_REFILL} state_e;
  state_e state_d, state_q;

  logic                                                   cache_ren;                   
  logic [ICACHE_TAG_LSB-ICACHE_DATA_WTH-1:0]              cache_raddr;      // used to select data array
  logic [ICACHE_SET_WTH-1:0]                              cache_set_inx;    // used to select tag array
  logic [ICACHE_DATA_SIZE*8-1:0]                          cache_rdata [ICACHE_WAY_NUM-1:0];
  logic [ICACHE_TAG_WTH-1:0]                              cache_rtag [ICACHE_WAY_NUM-1:0];
  logic                                                   cache_rvalid [ICACHE_WAY_NUM-1:0];
  logic [ICACHE_DATA_SIZE*8-1:0]                          cache_wdata;            
  logic [ICACHE_TAG_LSB-ICACHE_DATA_WTH-1:0]              cache_waddr;      
  logic                                                   cache_data_wr; 
  logic                                                   cache_tag_wr;
  logic [ICACHE_SET_SIZE-1:0][ICACHE_TAG_WTH-1:0]         tag_array [ICACHE_WAY_NUM-1:0];
  logic [ICACHE_SET_SIZE-1:0]                             cl_valid [ICACHE_WAY_NUM-1:0];   // cache_line_valid
  logic [ICACHE_TAG_WTH-1:0]                              phy_tag;
  logic                                                   cacheable_d, cacheable_q;
  logic [63:0]                                            vaddr_d, vaddr_q;
  logic [63:0]                                            paddr_d, paddr_q;
  logic [ICACHE_WAY_NUM-1:0]                              cl_hit;  // hit from tag compare
  logic [ICACHE_FETCH_SIZE*8-1:0]                         cl_rdata [ICACHE_WAY_NUM-1:0];  
  logic [$clog2(ICACHE_WAY_NUM)-1:0]                      hit_idx;
  logic [ICACHE_DATA_MSB-1:0]                             data_offset_d,data_offset_q;
  logic [ICACHE_SET_SIZE-1:0]                             plru0;
  logic [ICACHE_SET_SIZE-1:0][1:0]                        plru1;
  logic [ICACHE_SET_SIZE-1:0][1:0]                        plru_rpl_way;
  logic [1:0]                                             rpl_way;
  logic                                                   comp_en; 
  logic                                                   allow_comp;
  logic [4:0]                                             counter_d, counter_q;
  logic                                                   transaction_done;
  logic                                                   transaction_last;
  logic [ICACHE_WAY_NUM-1:0]                              cache_wen;
  logic                                                   cache_rd_en_dly1;   
  logic [ICACHE_TAG_LSB-ICACHE_DATA_WTH-1:0]              waddr_d, waddr_q;      
  logic [$clog2(ICACHE_WAY_NUM)-1:0]                      inv_way;
  logic                                                   all_ways_valid;
  logic [ICACHE_WAY_NUM-1:0]                              way_valid;
  logic                                                   valid_flush;

//======================================================================================================================
// Instance
//======================================================================================================================
  // extract tag from physical address, check if NC
  assign paddr_d   = (mmu_icache__rsp_i.fetch_valid) ? mmu_icache__rsp_i.fetch_paddr : paddr_q;
  assign phy_tag = paddr_d[ICACHE_TAG_MSB-1:ICACHE_TAG_LSB];

  // noncacheable if request goes to I/O space, or if cache is disabled
  // assign cacheable_d = (mmu_icache__rsp_i.fetch_valid) ? mmu_icache__rsp_i.cacheable : cacheable_q;
  assign cacheable_d = is_cacheable(paddr_d);
  assign comp_en = ~mmu_icache__rsp_i.fetch_exception.valid && cacheable_d && allow_comp;
  // latch this in case we have to stall later on
  // make sure this is 32bit aligned
  assign vaddr_d = (icache_fetch__rsp_o.ready & fetch_icache__req_i.req) ? fetch_icache__req_i.vaddr : vaddr_q;
  assign icache_mmu__req_o.fetch_vaddr = {vaddr_q>>2, 2'b0};

  assign cache_raddr = vaddr_d[ICACHE_TAG_LSB-1:ICACHE_DATA_MSB];
  assign cache_set_inx = vaddr_d[ICACHE_SET_MSB-1:ICACHE_SET_LSB];

  // assign data_offset_d = (icache_fetch__rsp_o.ready & fetch_icache__req_i.req) ? (vaddr_d[ICACHE_DATA_MSB-1]<<2) :
  //                        (~cacheable_q & icache_A_valid_o) ? vaddr_d[ICACHE_DATA_MSB-1]<<2 : data_offset_q;

  assign data_offset_d = (icache_fetch__rsp_o.ready && fetch_icache__req_i.req) ? (vaddr_d[ICACHE_DATA_MSB-1]<<2) :
                         data_offset_q;
 

  for(genvar i=0; i<ICACHE_WAY_NUM; i++) begin: hit_logic
    assign cl_hit[i] = cache_rvalid[i] && (cache_rtag[i] == phy_tag) && comp_en; 
    assign cl_rdata[i] = cache_rdata[i][{data_offset_q,3'b0} +: ICACHE_FETCH_SIZE*8];
  end

  oneHot2Int #(
    .WIDTH ( ICACHE_WAY_NUM)
  ) hit_to_idx (
    .in_i    ( cl_hit  ),
    .cnt_o   ( hit_idx ),
    .empty_o (         )
  );

  // read data from cache or from next level memory
  assign icache_fetch__rsp_o.vaddr = vaddr_q;
  assign icache_fetch__rsp_o.ex = mmu_icache__rsp_i.fetch_exception; // ex from mmu
  assign icache_fetch__rsp_o.data = (cacheable_d) ? cl_rdata[hit_idx] :
                                    icache_D_bits_i.data[{data_offset_q,3'b0} +: ICACHE_FETCH_SIZE*8];

  // TileLin A channel interface
  assign icache_A_bits_o.opcode = tl_pkg::Get;
  assign icache_A_bits_o.param.permission = tl_pkg::NtoB;
  // if access non-cacheable area,just read 8B
  assign icache_A_bits_o.size = cacheable_d ? (ICACHE_BLOCK_SIZE / ICACHE_DATA_SIZE - 1) : '0; 
  assign icache_A_bits_o.source = SOURCE_ID;
  // address must be aligned to size 
  assign icache_A_bits_o.address = cacheable_d ? ((paddr_d >> ICACHE_BLOCK_WTH) << ICACHE_BLOCK_WTH) : 
                                                 ((paddr_d >> ICACHE_DATA_WTH) << ICACHE_DATA_WTH);  
  assign icache_A_bits_o.mask = {tl_pkg::MASK_WTH{1'b1}};
  assign icache_A_bits_o.data = '0;
  assign icache_A_bits_o.corrupt = 1'b0;

  always_comb begin : transaction_cnt
    waddr_d = waddr_q;
    counter_d = counter_q;
    if (icache_A_valid_o && icache_A_ready_i) begin
      counter_d = cacheable_d ? (ICACHE_BLOCK_SIZE / ICACHE_DATA_SIZE) : 1'b1;     
      waddr_d = vaddr_q[ICACHE_TAG_LSB-1:ICACHE_BLOCK_WTH] << 4;
    end else if (counter_q != '0 && (icache_D_valid_i && icache_D_ready_o)) begin
      counter_d = counter_q - 1'b1;
      waddr_d = waddr_q + 1;
    end
  end
  assign transaction_done = (counter_q == '0);
  assign transaction_last = (counter_q == 1'b1);

//======================================================================================================================
// FSM
//======================================================================================================================

  always_comb begin : fsm
    // default assignment
    state_d       = state_q;
    cache_ren     = 1'b0;
    cache_data_wr = 1'b0;
    cache_tag_wr  = 1'b0;
    // interfaces
    icache_fetch__rsp_o.ready     = 1'b0;
    icache_fetch__rsp_o.valid     = 1'b0;

    icache_A_valid_o = 1'b0;
    icache_D_ready_o = 1'b0;

    icache_mmu__req_o.fetch_req = 1'b0;
    // performance counter
    cache_miss_o = 1'b0;

    allow_comp = 1'b0;
    flush_done_o = 1'b0;
    valid_flush = 1'b0;
    unique case (state_q)
      // wait for an incoming request
      IDLE: begin
          // flushes cache
          if (flush_i) begin
            state_d = IDLE;
            flush_done_o = 1'b1;
          // kill fetch
          end else begin
            icache_fetch__rsp_o.ready = 1'b1;
            // we have a new request
            if (fetch_icache__req_i.kill)begin
              cache_ren = 1'b0;
              state_d = IDLE;
            end else if (fetch_icache__req_i.req) begin
              cache_ren = 1'b1;
              state_d = READ;
            end
          end
      end
      READ: begin
          state_d = TLB_MISS;
          icache_mmu__req_o.fetch_req = 1'b1;
          // allow tag compare
          allow_comp = 1'b1;
          if (mmu_icache__rsp_i.fetch_valid) begin
            // check if we have to flush
            if (flush_i) begin
              state_d  = IDLE;
              flush_done_o = 1'b1;
            end else if (fetch_icache__req_i.kill) begin
              state_d = IDLE;
            // we have a hit or an exception output valid result
            end else if (|cl_hit || mmu_icache__rsp_i.fetch_exception.valid) begin
              icache_fetch__rsp_o.valid = 1'b1;
              // we can accept another request
              icache_fetch__rsp_o.ready = 1'b1;
              if (fetch_icache__req_i.req) begin
                cache_ren = 1'b1;
                state_d = READ;
              end else begin
                state_d = IDLE; 
              end
            end else begin
              // use TileLink A to send read request
              icache_A_valid_o = 1'b1;
              if (icache_A_ready_i) begin
                cache_miss_o = ~cacheable_q;
                state_d      = REFILL;
              end
            end
          end else if (fetch_icache__req_i.kill || flush_i) begin
            state_d  = KILL_ATRANS;
          end
      end
      //////////////////////////////////
      // wait until the physical address returns. 
      TLB_MISS: begin
        icache_mmu__req_o.fetch_req = '1;
        if (mmu_icache__rsp_i.fetch_valid) begin
          // check if we have to kill this request
          if (fetch_icache__req_i.kill || flush_i) begin
            state_d = IDLE;
            flush_done_o = flush_i;
          // check whether we got an exception
          end else if (mmu_icache__rsp_i.fetch_exception.valid) begin
            icache_fetch__rsp_o.valid = 1'b1;
            state_d = IDLE;
          end else begin
            cache_ren = 1'b1;
            state_d = READ;
          end
        end else if (fetch_icache__req_i.kill || flush_i) begin
          state_d  = KILL_ATRANS;
        end
      end
      // wait until the memory transaction returns. 
      REFILL: begin
        if (fetch_icache__req_i.kill || flush_i) begin
          state_d = KILL_REFILL; 
        end else begin
          icache_D_ready_o = 1'b1;
          if (icache_D_valid_i && icache_D_ready_o) begin
            cache_data_wr = cacheable_q;  
            if (transaction_last) begin
              if (~cacheable_q) begin
                icache_fetch__rsp_o.valid = 1'b1; 
                state_d = IDLE;
              end else begin
                cache_tag_wr = 1'b1;
              end
            end
          end else if (transaction_done) begin
              cache_ren = 1'b1;  
              state_d = READ; 
          end
        end
      end
      // killed address translation, wait until paddr is valid, and go back to idle
      KILL_ATRANS: begin
        icache_mmu__req_o.fetch_req = '1;
        if (mmu_icache__rsp_i.fetch_valid) begin
          if (flush_i) begin
            flush_done_o = 1'b1;  
          end
          state_d = IDLE;
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
        // if (icache_D_valid_i && icache_D_ready_o) begin
        //   cache_data_wr = cacheable_q;
        //   if (transaction_last) begin
        //     if (~cacheable_q) begin
        //       state_d = IDLE;
        //     end else begin
        //       cache_tag_wr = 1'b1;
        //     end
        //   end
        // end else begin
        //   if (transaction_done == 1'b1) begin
        //       state_d = IDLE;
        //   end
        // end
      end
      default: begin
        state_d = IDLE;
      end
    endcase 
  end

///////////////////////////////////////////////////////
// tag comparison, hit generation
///////////////////////////////////////////////////////

  // TODO
  // replacement strategy
  always_ff @(`DFF_CR(clk_i, rst_i)) begin : plru
      if(`DFF_IS_R(rst_i)) begin
          for(integer i=0; i<ICACHE_SET_SIZE; i++) begin
              plru0[i] <= `TCQ 1'b0;
              plru1[i] <= `TCQ 2'h0;
          end
      end else begin
          if(|cl_hit) begin
              plru0[cache_set_inx] <= `TCQ hit_idx[0];
              if(!hit_idx[0]) begin
                  plru1[cache_set_inx][0] <= `TCQ hit_idx[1];
              end else begin
                  plru1[cache_set_inx][1] <= `TCQ hit_idx[1];
              end
          end
      end
  end
  always_comb begin
      for(integer i=0; i<ICACHE_SET_SIZE; i++) begin
          plru_rpl_way[i][0] = !plru0[i];
          plru_rpl_way[i][1] = !plru0[i] ? !plru1[1] : !plru1[0];
      end
  end
  always_ff @(`DFF_CR(clk_i, rst_i)) begin 
      if (`DFF_IS_R(rst_i)) begin
        way_valid         <= '0;
      end else if (cache_rd_en_dly1) begin
        for (integer i=0; i < ICACHE_WAY_NUM; i++) begin
          way_valid[i]    <= cache_rvalid[i]; 
        end
      end
  end 
  // find invalid cache line
  lzc #(
    .WIDTH ( ICACHE_WAY_NUM)
  ) i_lzc_inv (
    .in_i    ( ~way_valid                      ), 
    .cnt_o   ( inv_way                         ),
    .empty_o ( all_ways_valid                  )
  );
  // if all cache line is valid, through plru to choose replace way, otherwise choose invalid way
  assign rpl_way = all_ways_valid ? plru_rpl_way[cache_set_inx] : inv_way;
///////////////////////////////////////////////////////
// memory arrays and regs
///////////////////////////////////////////////////////
  assign cache_wdata = icache_D_bits_i.data;
  assign cache_waddr = waddr_q;
  for (genvar i = 0; i < ICACHE_WAY_NUM; i++) begin : tag_and_data
    assign cache_wen[i] = cache_data_wr && (i==rpl_way);

    sdp_512x64sd1_wrap data_ram(
      .wr_clk_i                   (clk_i),              
      .we_i                       (cache_wen[i]),          
      .waddr_i                    (cache_waddr),             
      .wdata_i                    (cache_wdata),             
      .wstrb_i                    (8'hff),             
      .rd_clk_i                   (clk_i),              
      .re_i                       (cache_ren),          
      .raddr_i                    (cache_raddr),             
      .rdata_o                    (cache_rdata[i])    
    );
    
    // tag array
    always_ff @(posedge clk_i or negedge rst_i)begin
      if(!rst_i) begin
        tag_array[i] <= '0;
      // write tag
      end else if(cache_tag_wr && (i==rpl_way)) begin
        tag_array[i][cache_set_inx] <= phy_tag;
      end
    end

    // read tag
    always_ff @(posedge clk_i or negedge rst_i)begin
      if(!rst_i) begin
        cache_rtag[i] <= '0;
      end else if(cache_ren) begin
        cache_rtag[i] <= tag_array[i][cache_set_inx];
      end
    end
    // valid bit array
    always_ff @(posedge clk_i or negedge rst_i) begin
      if(!rst_i) begin
        cl_valid[i] <= '0;  
      end else if(flush_i) begin
        cl_valid[i] <= '0;
      end else if(valid_flush && (i==rpl_way)) begin
        cl_valid[i][cache_set_inx] <= 1'b0;
      // refill cache line
      end else if(cache_tag_wr && (i==rpl_way)) begin
        cl_valid[i][cache_set_inx] <= 1'b1;
      end
    end
    // read valid bit
    always_ff @(posedge clk_i or negedge rst_i)begin
      if(!rst_i) begin
        cache_rvalid[i] <= '0;
      end else if(cache_ren) begin
        cache_rvalid[i] <= cl_valid[i][cache_set_inx];
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_i) begin : p_regs
    if(!rst_i) begin
      vaddr_q          <= '0;
      paddr_q          <= '0;
      state_q          <= IDLE;
      cacheable_q      <= 1'b0;
      data_offset_q    <= '0;
      counter_q        <= '0;
      waddr_q          <= '0;
      cache_rd_en_dly1 <= 1'b0;
    end else begin
      vaddr_q          <= vaddr_d;
      paddr_q          <= paddr_d;
      state_q          <= state_d;
      cacheable_q      <= cacheable_d;
      data_offset_q    <= data_offset_d;
      counter_q        <= counter_d;
      waddr_q          <= waddr_d;
      cache_rd_en_dly1 <= cache_ren;
    end
  end

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule
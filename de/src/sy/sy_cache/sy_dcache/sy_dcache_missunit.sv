// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_dcache_missunit.v
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

module sy_dcache_missunit  
  import sy_pkg::*;
#(
  parameter                             HART_ID_WTH  = 1,
  parameter logic [HART_ID_WTH-1:0]     HART_ID      = 0
) (
  input  logic                      clk_i,
  input  logic                      rst_i,
  input  logic                      flush_i,  // from pipeline             
  output logic                      flush_done_o,

  output logic                      flush_dcache_mem_o, // to dcache mem
  input  logic                      allow_probe_i,
  output logic                      probe_flight_o,
  output logic                      acquire_flight_o,
  // interface with ctrl module
  // request from ctrl module
  input  logic                      miss_req_i,
  output logic                      miss_ack_o,
  input  miss_req_bits_t            miss_req_bits_i,
  output logic                      miss_done_o,
  output [DCACHE_DATA_SIZE*8-1:0]   miss_rdata_o,
  // interface with dcache mem
  output logic                      data_req_o,
  input  logic                      data_gnt_i,
  output data_req_t                 data_req_bits_o,
  input  data_rsp_t                 data_rsp_bits_i,

  output logic                      tag_req_o,
  input  logic                      tag_gnt_i,
  output tag_req_t                  tag_req_bits_o,
  input  tag_rsp_t                  tag_rsp_bits_i,

  // A channel
  output logic                      dcache_A_valid_o,
  input  logic                      dcache_A_ready_i,
  output tl_pkg::A_chan_bits_t      dcache_A_bits_o,
  // B channel
  input  logic                      dcache_B_valid_i,
  output logic                      dcache_B_ready_o,
  input  tl_pkg::B_chan_bits_t      dcache_B_bits_i,
  // C channel
  output logic                      dcache_C_valid_o,
  input  logic                      dcache_C_ready_i,
  output tl_pkg::C_chan_bits_t      dcache_C_bits_o,
  // D channel
  output logic                      dcache_D_ready_o,
  input  logic                      dcache_D_valid_i,
  input  tl_pkg::D_chan_bits_t      dcache_D_bits_i,           
  // E channel
  output logic                      dcache_E_valid_o,
  input  logic                      dcache_E_ready_i,
  output tl_pkg::E_chan_bits_t      dcache_E_bits_o

);
//======================================================================================================================
// Parameters
//======================================================================================================================
  localparam logic [0:0]            DCACHE_ID   = 1;     
  localparam                        SINK_WTH    = tl_pkg::SINK_WTH;
  localparam logic [HART_ID_WTH:0]  SOURCE_ID   = {HART_ID,DCACHE_ID};
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
  typedef enum logic[3:0] {IDLE,DIRTY,ACQUIRE,ACQUIRE_BLOCK, ACQUIRE_PERM,RELEASE_DATA,RELEASE_REQ,
                            RELEASE,RELEASE_ACK,FLUSH,GRANT_ACK} state_e;

  typedef enum logic[3:0] {PROBE_IDLE,PROBE,PROBE_ACK,PROBE_ACK_DATA} probe_state_e;

  state_e       state_d, state_q;
  probe_state_e probe_state_d, probe_state_q;

  logic                                       probe_req;
  logic                                       probe_ack;
  tl_pkg::TL_Permissions_Cap                  probe_permission_d,probe_permission_q;
  tl_pkg::source_t                            probe_source_d,probe_source_q;
  tl_pkg::address_t                           probe_addr_d,probe_addr_q;
  logic [DCACHE_TAG_LSB-1:0]                  probe_idx;
  logic                                       probe_fire;
  logic                                       miss_req_fire;
  logic [DCACHE_TAG_LSB-1:0]                  miss_req_idx; 
  logic [DCACHE_TAG_LSB-1:0]                  flush_idx;
  logic [DCACHE_TAG_LSB:0]                    flush_idx_d, flush_idx_q; 
  logic                                       tag_rd_en;
  logic                                       tag_wr_en;
  logic                                       data_rd_en;
  logic                                       data_wr_en;
  logic                                       tag_rd_en_dly1;
  logic                                       lock_probe;
  logic                                       unlock_probe; 
  logic                                       unlock_probe_dly1; 
  logic                                       probe_flight;
  logic [DCACHE_WAY_NUM-1:0]                  is_cl_dirty;
  logic                                       set_flush_mark;
  logic                                       flush_d, flush_q;
  miss_req_bits_t                             req_bits_d, req_bits_q;   
  tag_t                                       probe_wr_tag;
  tag_t                                       refill_wr_tag;
  logic                                       flush_tag_rd;
  logic                                       probe_tag_rd;
  logic                                       refill_tag_rd;
  logic                                       probe_tag_wr;
  logic                                       release_tag_wr;
  logic                                       refill_tag_wr;
  logic                                       probe_data_rd;
  logic                                       release_data_rd;
  logic                                       refill_data_wr;
  logic [DCACHE_WAY_NUM-1:0]                  flush_way, flush_way_d, flush_way_q;
  logic                                       flush_inc;
  logic [DCACHE_WAY_NUM-1:0]                  tag_match;
  logic [DCACHE_WAY_NUM-1:0]                  cl_valid, cl_valid_d, cl_valid_q;    
  logic [$clog2(DCACHE_WAY_NUM)-1:0]          cl_valid_idx, cl_valid_idx_d, cl_valid_idx_q;    
  logic [DCACHE_TAG_WTH-1:0]                  addr_tag_d, addr_tag_q;
  logic                                       cacheable;
  logic                                       is_amo_arith;
  logic                                       is_amo_logic;
  tl_pkg::TL_Atomocs_Arith                    amo_arith_op;
  tl_pkg::TL_Atomocs_logic                    amo_logic_op;
  cache_state_e                               hit_cl_state_d, hit_cl_state_q;
  cache_state_e                               release_cl_state_d, release_cl_state_q;
  logic [$clog2(DCACHE_WAY_NUM)-1:0]          rpl_way;
  logic [$clog2(DCACHE_WAY_NUM)-1:0]          release_way;
  logic [$clog2(DCACHE_WAY_NUM)-1:0]          flush_way_idx;
  tl_pkg::TL_Permissions_Shrink               probeAck_permission;
  tl_pkg::TL_Permissions_Shrink               release_permission;
  cache_state_e                               probe_next_state;
  logic [DCACHE_TAG_WTH-1:0]                  release_addr_tag_d, release_addr_tag_q;
  logic [7:0]                                 counter_d, counter_q;
  logic [DCACHE_TAG_LSB-DCACHE_DATA_WTH-1:0]  waddr_d, waddr_q;      
  logic [DCACHE_TAG_LSB-1:0]                  data_rd_addr_d, data_rd_addr_q;      
  logic                                       transaction_done;
  logic                                       transaction_last;
  logic                                       transaction_first;
  logic [SINK_WTH-1:0]                        sink_d, sink_q;
  logic                                       probe_flight_d, probe_flight_q;
  logic [DCACHE_WAY_NUM-1:0]                  is_valid;
  logic                                       flush_done;
  logic                                       probe_ack_valid;
  logic                                       release_valid;
  logic                                       is_allow_probe;
  logic                                       under_release;

//======================================================================================================================
// Save request 
//======================================================================================================================
  // if missunit is handling flush req or release data, can't accept probe req
  assign is_allow_probe = allow_probe_i && !flush_q && !under_release;
  assign under_release = state_q inside {RELEASE_DATA, RELEASE_REQ, RELEASE, RELEASE_ACK};
  assign probe_req = dcache_B_valid_i && dcache_B_bits_i.opcode == tl_pkg::Probe && is_allow_probe;
  assign dcache_B_ready_o = probe_ack;

  assign probe_fire = (dcache_B_valid_i && dcache_B_ready_o);
  assign probe_permission_d = probe_fire ? dcache_B_bits_i.param.permission : probe_permission_q;
  // assign probe_source_d = probe_fire ? dcache_B_bits_i.source : probe_source_q; // TODO: not use; multi L2 Bank will use
  assign probe_addr_d = probe_fire ? dcache_B_bits_i.address : probe_addr_q;

  assign probe_idx = probe_addr_d[DCACHE_TAG_LSB-1:0];

  // save request from ctrl module
  assign miss_req_fire = (miss_req_i && miss_ack_o);
  assign req_bits_d = miss_req_fire ? miss_req_bits_i : req_bits_q; 
  assign miss_req_idx = req_bits_d.addr[DCACHE_TAG_LSB-1:0];
  assign rpl_way = req_bits_d.rpl_way;

  assign probe_flight_d = lock_probe ? 1'b1 : (unlock_probe_dly1 ? 1'b0 : probe_flight_q);
  assign probe_flight = probe_flight_q;
  assign probe_flight_o = probe_flight_d;

  assign acquire_flight_o = (state_q inside {ACQUIRE_BLOCK, ACQUIRE_PERM});

  assign miss_rdata_o = dcache_D_bits_i.data;
//======================================================================================================================
// interface with cache mem
//======================================================================================================================
  assign tag_rd_en              = flush_tag_rd || probe_tag_rd || refill_tag_rd;
  assign tag_wr_en              = probe_tag_wr || release_tag_wr || refill_tag_wr;
  assign tag_req_o              = tag_rd_en || tag_wr_en;
  assign tag_req_bits_o.we      = tag_wr_en ? 1'b1 : 1'b0; 
  always_comb begin : gen_tag_way_and_idx
    // default values for probe tag read
    tag_req_bits_o.way_en      = 4'hf;
    tag_req_bits_o.idx         = probe_idx;  
    if (tag_wr_en) begin    // for tag write
      if (probe_tag_wr) begin   // modify the hit cache line  
        tag_req_bits_o.way_en    = cl_valid_q; 
        tag_req_bits_o.idx       = probe_idx; 
      end else if (release_tag_wr) begin  // modify the release cache line
        tag_req_bits_o.way_en    = flush_q ? flush_way : 1'b1 << req_bits_q.rpl_way; 
        tag_req_bits_o.idx       = flush_q ? flush_idx : miss_req_idx; 
      end else if (refill_tag_wr) begin
        tag_req_bits_o.way_en    = (req_bits_q.cmd == REFILL) ? (1'b1 << req_bits_q.rpl_way) : (1'b1 << req_bits_q.update_way); 
        tag_req_bits_o.idx       = miss_req_idx;  
      end
    end else begin          // for tag read
      if (refill_tag_rd) begin 
        tag_req_bits_o.way_en    = 1'b1 << req_bits_d.rpl_way;     
        tag_req_bits_o.idx       = miss_req_idx;
      end else if (flush_tag_rd) begin
        tag_req_bits_o.way_en    = flush_way;
        tag_req_bits_o.idx       = flush_idx;
      end
    end
  end
  always_comb begin : gen_tag_wr_data
    // release always flush tag
    tag_req_bits_o.wr_tag.valid = '0;      // flush tag
    tag_req_bits_o.wr_tag.tag   = '0;      
    tag_req_bits_o.wr_tag.state = Nothing;  
    if (probe_tag_wr) begin 
      tag_req_bits_o.wr_tag = probe_wr_tag; 
    end else if (refill_tag_wr) begin 
      tag_req_bits_o.wr_tag = refill_wr_tag; 
    end
  end
  // probe write tag data, probe write tag depend on probe permission
  assign probe_wr_tag.tag       = probe_addr_q[DCACHE_TAG_MSB-1:DCACHE_TAG_LSB]; 
  assign probe_wr_tag.valid     = probe_permission_q != tl_pkg::toN;
  assign probe_wr_tag.state     = probe_next_state;

  // refill write tag data, refill write tag depend on acquire permission
  assign refill_wr_tag.tag       = req_bits_q.addr[DCACHE_TAG_MSB-1:DCACHE_TAG_LSB]; 
  assign refill_wr_tag.valid     = 1'b1;
  always_comb begin
    case(dcache_D_bits_i.param.permission)
      tl_pkg::toT: refill_wr_tag.state    = Trunk;
      tl_pkg::toB: refill_wr_tag.state    = Branch;
      default:     refill_wr_tag.state    = Nothing;
    endcase
  end

  assign data_rd_en             = probe_data_rd || release_data_rd;
  assign data_wr_en             = refill_data_wr; 
  assign data_req_o             = data_rd_en || data_wr_en;
  assign data_req_bits_o.we     = data_wr_en ? 1'b1 : 1'b0; 
  assign data_req_bits_o.wr_data  = dcache_D_bits_i.data; // only write data from D channel

  always_comb begin : gen_data_way_and_idx
    data_req_bits_o.way_en      = 4'h0;
    data_req_bits_o.idx         = 4'h0;
    if (data_wr_en) begin // for data write
      data_req_bits_o.way_en    = (req_bits_q.cmd == REFILL) ? (1'b1 << req_bits_q.rpl_way) : (1'b1 << req_bits_q.update_way);
      data_req_bits_o.idx       = waddr_q << DCACHE_DATA_WTH; 
    end else begin        // for data read
      if (probe_data_rd) begin
        data_req_bits_o.way_en    = cl_valid_d; 
        data_req_bits_o.idx       = data_rd_addr_d;
      end else if (release_data_rd) begin
        data_req_bits_o.way_en    = flush_q ? flush_way : (1'b1 << req_bits_q.rpl_way); 
        data_req_bits_o.idx       = data_rd_addr_d;
      end 
    end
  end
  always_comb begin
    data_rd_addr_d = data_rd_addr_q;
    if (refill_tag_rd) begin
      data_rd_addr_d = (miss_req_idx >> DCACHE_BLOCK_WTH) << DCACHE_BLOCK_WTH;
    end else if (flush_tag_rd) begin
      data_rd_addr_d = flush_idx;
    end else if (probe_tag_rd) begin
      data_rd_addr_d = (probe_idx >> DCACHE_BLOCK_WTH) << DCACHE_BLOCK_WTH;
    end else if (dcache_C_valid_o && dcache_C_ready_i) begin
      data_rd_addr_d = data_rd_addr_q + (1'b1 << DCACHE_DATA_WTH);
    end
  end

//======================================================================================================================
// cache hit generate logic 
//======================================================================================================================
  // TODO: make tag comparison simpler
  oneHot2Int #(
    .WIDTH ( DCACHE_WAY_NUM)
  ) hit_to_idx (
    .in_i    ( cl_valid),
    .cnt_o   ( cl_valid_idx),
    .empty_o (         )
  );

  assign addr_tag_d = tag_rd_en ? (probe_tag_rd ? probe_addr_d[DCACHE_TAG_MSB-1:DCACHE_TAG_LSB] : 
                                   req_bits_q.addr[DCACHE_TAG_MSB-1:DCACHE_TAG_LSB]) : addr_tag_q; 
  always_comb begin
    for (integer i=0; i<DCACHE_WAY_NUM; i++) begin: gen_cache_hit
      tag_match[i] = (tag_rsp_bits_i.tag_data[i].tag == addr_tag_q); 
      is_cl_dirty[i] = tag_rsp_bits_i.tag_data[i].valid && tag_rsp_bits_i.tag_data[i].state == Dirty;
      // cl_valid means tag is match and cache line is valid
      cl_valid[i] = tag_match[i] && tag_rsp_bits_i.tag_data[i].valid;
      // is_valid only means cache line is valid
      is_valid[i] = tag_rsp_bits_i.tag_data[i].valid;
    end
  end

  assign cl_valid_d         = tag_rd_en_dly1 ? cl_valid : cl_valid_q;
  assign cl_valid_idx_d     = tag_rd_en_dly1 ? cl_valid_idx : cl_valid_idx_q;

  assign hit_cl_state_d = (tag_rd_en_dly1 && |cl_valid) ? tag_rsp_bits_i.tag_data[cl_valid_idx].state : hit_cl_state_q;

  assign release_way = flush_q ? flush_way_idx : req_bits_q.rpl_way;
  assign release_cl_state_d = (tag_rd_en_dly1 && tag_rsp_bits_i.tag_data[release_way].valid) ? 
                                tag_rsp_bits_i.tag_data[release_way].state : release_cl_state_q;
  assign release_addr_tag_d = (tag_rd_en_dly1 && tag_rsp_bits_i.tag_data[release_way].valid) ? 
                                tag_rsp_bits_i.tag_data[release_way].tag : release_addr_tag_q;
//======================================================================================================================
// counter to count the number of transaction
//======================================================================================================================
  // TODO
  always_comb begin : transaction_cnt
    waddr_d     = waddr_q;
    counter_d   = counter_q;
    if (transaction_first) begin
      if (dcache_A_valid_o && dcache_A_ready_i) begin // Acquire
        counter_d = '0;     
        waddr_d = (req_bits_q.addr[DCACHE_TAG_LSB-1:0] >> DCACHE_BLOCK_WTH) << (DCACHE_BLOCK_WTH - DCACHE_DATA_WTH);
      end else if (dcache_C_valid_o && dcache_C_ready_i) begin  // releaseData or probeAckData
        counter_d = (state_q == RELEASE_DATA || probe_state_q == PROBE_ACK_DATA) ? (DCACHE_BLOCK_SIZE / DCACHE_DATA_SIZE - 1) : '0;
      end else if (dcache_D_valid_i && dcache_D_ready_o) begin
        counter_d = (state_q == ACQUIRE_BLOCK) ? (DCACHE_BLOCK_SIZE / DCACHE_DATA_SIZE - 1) : '0; 
        waddr_d = waddr_q + 1'b1;
      end
    end else begin
      if (dcache_C_valid_o && dcache_C_ready_i) begin
        counter_d = counter_q - 1'b1; 
      end else if (dcache_D_valid_i && dcache_D_ready_o && cacheable) begin
        counter_d = counter_q - 1'b1; 
        waddr_d   = waddr_q + 1'b1;
      end
    end
  end
  assign transaction_done   = (counter_q == '0);
  assign transaction_last   = (counter_q == 1'b1);
  assign transaction_first  = (counter_q == '0);
//======================================================================================================================
// Flush logic
//======================================================================================================================
  assign flush_d   = set_flush_mark ? 1'b1 : (flush_done ? 1'b0 : flush_q);
  assign flush_way = flush_way_d;
  assign flush_idx = flush_idx_d[DCACHE_TAG_LSB-1:0];
  always_comb begin
    flush_way_d = flush_way_q;
    flush_idx_d = flush_idx_q;
    if (flush_done) begin
      flush_way_d = 1;
      flush_idx_d = '0;
    end else if (flush_inc)begin
      if (flush_way_q == (1'b1 << (DCACHE_WAY_NUM-1))) begin
        flush_way_d = 1; 
        flush_idx_d = flush_idx_q + (1'b1 << DCACHE_BLOCK_WTH);
      end else begin
        flush_way_d = flush_way_q << 1'b1;
      end
    end
  end

  oneHot2Int #(
    .WIDTH ( DCACHE_WAY_NUM)
  ) flush_way_idx_inst(
    .in_i    ( flush_way_q),
    .cnt_o   ( flush_way_idx),
    .empty_o (         )
  );
  assign flush_done = flush_idx_q[DCACHE_TAG_LSB];
  assign flush_done_o = flush_done;
//======================================================================================================================
// TileLink channels
//======================================================================================================================
  // A channel 
  assign cacheable = req_bits_q.cacheable;
  // if address is non-cacheable, send read, write or amo request, otherwise send acquire request
  always_comb begin : gen_A_channl_opcode_and_param
    // default assignment
    dcache_A_bits_o.opcode = tl_pkg::AcquirePerm; 
    dcache_A_bits_o.param  = tl_pkg::NtoB; 
    if (!cacheable) begin
      if (req_bits_q.amo_op != AMO_NONE) begin // AMO operation
        dcache_A_bits_o.opcode = is_amo_logic ? tl_pkg::ArithmeticData : tl_pkg::LogicalData; 
        dcache_A_bits_o.param = is_amo_logic ? amo_logic_op : amo_arith_op;
      end else begin                           // normal read/write
        dcache_A_bits_o.opcode = req_bits_q.we ? tl_pkg::PutFullData: tl_pkg::Get; 
      end
    end else if (req_bits_q.cmd == REFILL) begin
      dcache_A_bits_o.opcode = tl_pkg::AcquireBlock; 
      dcache_A_bits_o.param  = req_bits_q.we ? tl_pkg::NtoT : tl_pkg::NtoB; 
    end else if (req_bits_q.cmd == UPDATE) begin
      // dcache_A_bits_o.opcode = tl_pkg::AcquirePerm;
      dcache_A_bits_o.opcode = tl_pkg::AcquireBlock;
      dcache_A_bits_o.param  = tl_pkg::BtoT; 
    end
  end
  // amo operation translation
  always_comb begin : amo_trnas
    amo_logic_op = tl_pkg::XOR;
    amo_arith_op = tl_pkg::MIN;
    is_amo_logic = 1'b0;
    is_amo_arith = 1'b0;
    case (req_bits_q.amo_op)
      // amo logic
      AMO_XOR   : begin amo_logic_op = tl_pkg::XOR;   is_amo_logic = 1'b1;  end 
      AMO_OR    : begin amo_logic_op = tl_pkg::OR;    is_amo_logic = 1'b1;  end
      AMO_AND   : begin amo_logic_op = tl_pkg::AND;   is_amo_logic = 1'b1;  end 
      AMO_SWAP  : begin amo_logic_op = tl_pkg::SWAP;  is_amo_logic = 1'b1;  end  
      // amo arith
      AMO_MIN   : begin amo_arith_op = tl_pkg::MIN;   is_amo_arith = 1'b1;  end 
      AMO_MAX   : begin amo_arith_op = tl_pkg::MAX;   is_amo_arith = 1'b1;  end 
      AMO_MINU  : begin amo_arith_op = tl_pkg::MINU;  is_amo_arith = 1'b1;  end  
      AMO_MAXU  : begin amo_arith_op = tl_pkg::MAXU;  is_amo_arith = 1'b1;  end  
      AMO_ADD   : begin amo_arith_op = tl_pkg::ADD;   is_amo_arith = 1'b1;  end 
    endcase
  end
  // assign dcache_A_bits_o.size     = cacheable ? DCACHE_BLOCK_SIZE : DCACHE_DATA_SIZE; 
  // assign dcache_A_bits_o.size     = (!cacheable || (req_bits_q.cmd == UPDATE)) ? '0 : (DCACHE_BLOCK_SIZE / DCACHE_DATA_SIZE - 1); 
  assign dcache_A_bits_o.size     = !cacheable ? '0 : (DCACHE_BLOCK_SIZE / DCACHE_DATA_SIZE - 1); 
  assign dcache_A_bits_o.source   = SOURCE_ID; 
  assign dcache_A_bits_o.address  = cacheable ? (req_bits_q.addr >> DCACHE_BLOCK_WTH) << DCACHE_BLOCK_WTH : 
                                      (req_bits_q.addr >> DCACHE_DATA_WTH) << DCACHE_DATA_WTH; 
  assign dcache_A_bits_o.mask     = req_bits_q.be; 
  assign dcache_A_bits_o.data     = !cacheable && req_bits_q.we ? req_bits_q.wdata : '0; 
  assign dcache_A_bits_o.corrupt  = 1'b0; 
  
  // C channel 
  assign dcache_C_valid_o = probe_ack_valid || release_valid;
  always_comb begin : gen_C_channl_bits
    dcache_C_bits_o.opcode    = tl_pkg::ProbeAck;
    dcache_C_bits_o.param     = tl_pkg::NtoN;        
    dcache_C_bits_o.size      = '0;         
    dcache_C_bits_o.source    = SOURCE_ID;         
    dcache_C_bits_o.data      = '0;       
    dcache_C_bits_o.corrupt   = 1'b0;          
    if (probe_flight) begin           // for probe
      dcache_C_bits_o.opcode  = (probe_state_q==PROBE_ACK) ? tl_pkg::ProbeAck: tl_pkg::ProbeAckData;
      dcache_C_bits_o.param   = |cl_valid_q ? probeAck_permission : tl_pkg::NtoN;        
      dcache_C_bits_o.size    = (probe_state_q==PROBE_ACK) ? '0 : (DCACHE_BLOCK_SIZE / DCACHE_DATA_SIZE - 1);         
      dcache_C_bits_o.data    = (probe_state_q==PROBE_ACK) ? '0 : data_rsp_bits_i.rd_data;
      dcache_C_bits_o.address = probe_addr_q;
    end else begin                    // for release
      dcache_C_bits_o.opcode  = (state_q==RELEASE_DATA) ? tl_pkg::ReleaseData: tl_pkg::Release;
      dcache_C_bits_o.param   = release_permission;
      dcache_C_bits_o.size    = (state_q==RELEASE_DATA) ? (DCACHE_BLOCK_SIZE / DCACHE_DATA_SIZE - 1) : '0;
      dcache_C_bits_o.data    = (state_q==RELEASE_DATA) ? data_rsp_bits_i.rd_data : '0;
      if (flush_q) begin
        dcache_C_bits_o.address = {release_addr_tag_q,flush_idx_q[DCACHE_TAG_LSB-1:DCACHE_BLOCK_MSB],{DCACHE_BLOCK_WTH{1'b0}}};
      end else begin
        dcache_C_bits_o.address = {release_addr_tag_q,req_bits_q.addr[DCACHE_TAG_LSB-1:DCACHE_BLOCK_MSB],{DCACHE_BLOCK_WTH{1'b0}}};
      end
    end
  end
  // generate probe permission and next state of probe cache line
  always_comb begin
    case ({probe_permission_q, hit_cl_state_q})
      {tl_pkg::toT,Dirty}     : begin probeAck_permission = tl_pkg::TtoT; probe_next_state = Trunk  ; end 
      {tl_pkg::toT,Trunk}     : begin probeAck_permission = tl_pkg::TtoT; probe_next_state = Trunk  ; end 
      {tl_pkg::toT,Branch}    : begin probeAck_permission = tl_pkg::BtoB; probe_next_state = Branch ; end 
      {tl_pkg::toT,Nothing}   : begin probeAck_permission = tl_pkg::NtoN; probe_next_state = Nothing; end 

      {tl_pkg::toB,Dirty}     : begin probeAck_permission = tl_pkg::TtoB; probe_next_state = Branch ; end 
      {tl_pkg::toB,Trunk}     : begin probeAck_permission = tl_pkg::TtoB; probe_next_state = Branch ; end 
      {tl_pkg::toB,Branch}    : begin probeAck_permission = tl_pkg::BtoB; probe_next_state = Branch ; end 
      {tl_pkg::toB,Nothing}   : begin probeAck_permission = tl_pkg::NtoN; probe_next_state = Nothing; end 

      {tl_pkg::toN,Dirty}     : begin probeAck_permission = tl_pkg::TtoN; probe_next_state = Nothing; end 
      {tl_pkg::toN,Trunk}     : begin probeAck_permission = tl_pkg::TtoN; probe_next_state = Nothing; end 
      {tl_pkg::toN,Branch}    : begin probeAck_permission = tl_pkg::BtoN; probe_next_state = Nothing; end 
      {tl_pkg::toN,Nothing}   : begin probeAck_permission = tl_pkg::NtoN; probe_next_state = Nothing; end 
      default                 : begin probeAck_permission = tl_pkg::NtoN; probe_next_state = Nothing; end 
    endcase
    // generate release permission (cache line which will be released must be Nothing state)
    case (release_cl_state_q) 
      Dirty   : begin release_permission = tl_pkg::TtoN; end 
      Trunk   : begin release_permission = tl_pkg::TtoN; end
      Branch  : begin release_permission = tl_pkg::BtoN; end
      Nothing : begin release_permission = tl_pkg::NtoN; end
    endcase
  end

  // E channel 
  assign sink_d = dcache_D_valid_i && dcache_D_ready_o ? dcache_D_bits_i.sink : sink_q;
  assign dcache_E_bits_o.sink = sink_q;

//======================================================================================================================
// FSM
//======================================================================================================================
  always_comb begin : miss_unit_fsm
    // default assignment
    state_d                 = state_q;
    miss_ack_o              = 1'b0;
    miss_done_o             = 1'b0;
    set_flush_mark          = 1'b0;
    flush_inc               = 1'b0;
    flush_dcache_mem_o      = 1'b0;
    flush_tag_rd            = 1'b0;
    refill_tag_rd           = 1'b0;
    release_tag_wr          = 1'b0;
    refill_tag_wr           = 1'b0;
    release_data_rd         = 1'b0;
    refill_data_wr          = 1'b0;
    dcache_A_valid_o        = 1'b0;
    // dcache_C_valid_o        = 1'b0;
    release_valid           = 1'b0;
    dcache_E_valid_o        = 1'b0; 
    dcache_D_ready_o        = 1'b0;

    unique case (state_q)
        // wait for an incoming request
        IDLE: begin
          // if miss unit is handling a probe, forbiden accepting new req until probe finish
          if (probe_req || probe_flight) begin// probe has highest priority
            state_d = IDLE;
          end else if (flush_i) begin
            set_flush_mark = 1'b1;
            flush_tag_rd = 1'b1;
            state_d = FLUSH;
          end else if (miss_req_i) begin
            miss_ack_o = 1'b1;
            if (miss_req_bits_i.cmd == REFILL && miss_req_bits_i.cacheable) begin // Refill request
              refill_tag_rd = 1'b1;
              if (tag_gnt_i) begin
                state_d = DIRTY;
              end
            end else begin                          // Update request
              state_d = ACQUIRE;
            end
          end
        end
        // check if the cache line which will be replaced is dirty
        DIRTY : begin
          if (probe_req) begin
            state_d = IDLE;
          end else begin
            if (|is_cl_dirty) begin
              state_d = RELEASE_REQ;    // release with data        
            // end else if (|is_valid) begin
            //   state_d = RELEASE;        // release without data
            end else begin   
              state_d = ACQUIRE;      
            end
          end
        end
        RELEASE: begin
          release_valid = 1'b1;          
          if (dcache_C_ready_i) begin
            release_tag_wr = 1'b1;  // clean valid bit
            state_d = RELEASE_ACK;
          end
        end
        RELEASE_REQ: begin // read data ram
          release_data_rd = 1'b1;
          if (data_gnt_i) begin
            state_d = RELEASE_DATA;
          end 
        end
        RELEASE_DATA: begin
          release_valid = 1'b1;
          if (dcache_C_ready_i) begin
            // transaction finish, wait release ack 
            if (transaction_last) begin
              release_tag_wr = 1'b1;   // when transaction finish, write state to Nothing
              state_d = RELEASE_ACK;
            // transaction not finish, read next data
            end else begin
              release_data_rd = 1'b1;
              if (data_gnt_i) begin
                state_d = RELEASE_DATA;
              end else begin
                state_d = RELEASE_REQ;
              end
            end
          end else begin
            release_data_rd = 1'b1;
          end
        end
        RELEASE_ACK: begin
          // wait for release ack
          if (dcache_D_valid_i) begin
            dcache_D_ready_o = 1'b1;
            if (flush_q) begin
              flush_tag_rd = 1'b1;
              flush_inc    = 1'b1;
              state_d      = FLUSH;
            end else begin
              state_d = ACQUIRE;
            end
          end
        end
        ACQUIRE: begin
          if (probe_req) begin
            state_d = IDLE;
          end else begin
            dcache_A_valid_o = 1'b1;
            if (dcache_A_ready_i) begin
              // state_d = (req_bits_q.cmd == UPDATE || !cacheable) ? ACQUIRE_PERM : ACQUIRE_BLOCK;
              state_d = !cacheable ? ACQUIRE_PERM : ACQUIRE_BLOCK;
            end
          end
        end
        ACQUIRE_PERM : begin
          // dcache_D_ready_o = 1'b1;
          // if (dcache_D_valid_i) begin
          //   refill_tag_wr = cacheable;     // if transaction finish, modify state and tag
          //   miss_done_o = 1'b1;
          //   state_d = cacheable ? GRANT_ACK : IDLE;
          // end
          dcache_D_ready_o = 1'b1;
          if (dcache_D_valid_i) begin
            miss_done_o = 1'b1;
            state_d = IDLE;
          end
        end
        ACQUIRE_BLOCK : begin
          dcache_D_ready_o = 1'b1;
          if (dcache_D_valid_i) begin
            refill_data_wr = 1'b1;          // write data
            if (transaction_last) begin
              refill_tag_wr = 1'b1;     // if transaction finish, modify state and tag
              miss_done_o = 1'b1;
              state_d = cacheable ? GRANT_ACK : IDLE;
            end
          end 
        end
        GRANT_ACK: begin
          dcache_E_valid_o = 1'b1;
          if (dcache_E_ready_i) begin
            state_d = IDLE;
          end
        end
        FLUSH: begin
          if (flush_done) begin
            flush_dcache_mem_o = 1'b1;
            state_d = IDLE;
          end else begin
            if (|is_cl_dirty) begin
              state_d = RELEASE_REQ;
            end else begin
              state_d       = FLUSH;
              flush_tag_rd  = 1'b1; 
              flush_inc     = 1'b1;
            end
          end
        end
        default: begin
          state_d = IDLE;
        end
    endcase // state_q
  end
//======================================================================================================================
// Probe FSM
//======================================================================================================================
  always_comb begin: probe_fsm
    probe_state_d   = probe_state_q;
    lock_probe      = 1'b0;
    unlock_probe    = 1'b0;
    probe_ack       = 1'b0;
    probe_tag_rd    = 1'b0;
    probe_tag_wr    = 1'b0;
    probe_data_rd   = 1'b0;
    probe_ack_valid = 1'b0;

    case(probe_state_q)
        PROBE_IDLE: begin
          if (probe_req) begin
            lock_probe    = 1'b1;
            probe_ack     = 1'b1;
            probe_state_d = PROBE;
            probe_tag_rd  = 1'b1;
          end
        end
        PROBE: begin
          if (|(is_cl_dirty & tag_match) ) begin
            probe_data_rd = 1'b1;
            probe_state_d = PROBE_ACK_DATA;
          end else begin
            probe_state_d = PROBE_ACK; 
          end
        end
        PROBE_ACK: begin
          probe_ack_valid = 1'b1;
          if (dcache_C_ready_i) begin
            unlock_probe = 1'b1;
            probe_tag_wr = |cl_valid_q; // write tag only has probed cache line
            probe_state_d = PROBE_IDLE;
          end
        end
        PROBE_ACK_DATA: begin
          probe_ack_valid = 1'b1;  
          if (dcache_C_ready_i) begin
            if (transaction_last) begin
              unlock_probe = 1'b1;
              probe_tag_wr = 1'b1;
              probe_state_d = PROBE_IDLE;
            end else begin
              probe_data_rd = 1'b1;
              probe_state_d = PROBE_ACK_DATA;
            end
          end else begin
            probe_data_rd = 1'b1;
          end
        end
        default: begin
          probe_state_d = PROBE_IDLE;
        end
    endcase
  end
//======================================================================================================================
// registers
//======================================================================================================================
  always_ff @(`DFF_CR(clk_i,rst_i)) begin : p_regs
    if(`DFF_IS_R(rst_i)) begin
      state_q                   <= IDLE;
      probe_state_q             <= PROBE_IDLE;
      probe_permission_q        <= tl_pkg::toT;
      probe_source_q            <= '0;
      probe_addr_q              <= '0;
      flush_q                   <= '0;
      flush_idx_q               <= '0;
      flush_way_q               <=  1;
      req_bits_q                <= miss_req_bits_t'(0);   
      cl_valid_q                <= '0;
      cl_valid_idx_q            <= '0;
      addr_tag_q                <= '0;
      hit_cl_state_q            <=  Nothing;
      release_cl_state_q        <=  Nothing;
      release_addr_tag_q        <= '0;
      counter_q                 <= '0;
      waddr_q                   <= '0;
      sink_q                    <= '0;
      tag_rd_en_dly1            <= '0;
      data_rd_addr_q            <= '0;
      probe_flight_q            <= '0;
      unlock_probe_dly1         <= '0;
    end else begin
      state_q                   <= state_d;
      probe_state_q             <= probe_state_d;
      probe_permission_q        <= probe_permission_d;
      probe_source_q            <= probe_source_d;
      probe_addr_q              <= probe_addr_d;
      flush_q                   <= flush_d;
      req_bits_q                <= req_bits_d;
      cl_valid_q                <= cl_valid_d;
      cl_valid_idx_q            <= cl_valid_idx_d;
      addr_tag_q                <= addr_tag_d;
      hit_cl_state_q            <= hit_cl_state_d;
      release_cl_state_q        <= release_cl_state_d;
      release_addr_tag_q        <= release_addr_tag_d;
      counter_q                 <= counter_d;
      waddr_q                   <= waddr_d;
      sink_q                    <= sink_d;
      flush_idx_q               <= flush_idx_d;
      flush_way_q               <= flush_way_d;
      tag_rd_en_dly1            <= tag_rd_en;
      data_rd_addr_q            <= data_rd_addr_d;
      probe_flight_q            <= probe_flight_d;
      unlock_probe_dly1         <= unlock_probe;
    end
  end

(* mark_debug = "true" *) state_e prb_dcache_missunit_state;
(* mark_debug = "true" *) logic[63:0] prb_dcache_missunit_addr;
assign prb_dcache_missunit_state = state_q;
assign prb_dcache_missunit_addr = req_bits_q.addr;

//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule
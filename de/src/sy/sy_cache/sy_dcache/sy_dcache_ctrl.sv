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
(
    input  logic                            clk_i,
    input  logic                            rst_i,

    output logic                            allow_probe_o,
    // input  logic                            probe_flight_i, // there exist a probe req handled by miss unit      
    // input  logic                            acquire_flight_i,   
    // =====================================
    // [From MMU]
    input  logic                            mmu_dcache__vld_i,
    output logic                            dcache_mmu__rdy_o,      
    input  dcache_req_t                     mmu_dcache__data_i,
    output logic                            dcache_mmu__rvld_o,  
    output logic [DWTH-1:0]                 dcache_mmu__rdata_o,
    // =====================================
    // [From LSU]
    input  logic                            lsu_dcache__vld_i,
    output logic                            dcache_lsu__rdy_o,
    input  dcache_req_t                     lsu_dcache__data_i,
    output dcache_rsp_t                     dcache_lsu__data_o,
    // =====================================
    // [From MSHR]
    input  logic                            mshr_dcache__vld_i,
    output logic                            dcache_mshr__rdy_o,
    input  dcache_req_t                     mshr_dcache__data_i,
    input  logic                            mshr_dcache__afull_i,        
    input  logic                            mshr_dcache__full_i,        
    input  logic                            mshr_dcache__empty_i,
    input  req_src_e                        mshr_dcache__req_src_i,
    // =====================================
    // [TO MSHR]
    output logic                            dcache_mshr__vld_o,
    output logic[AWTH-1:0]                  dcache_mshr__addr_o,
    output miss_req_cmd_e                   dcache_mshr__cmd_o,
    output logic[DCACHE_WAY_WTH-1:0]        dcache_mshr__update_way_o,
    output logic                            dcache_mshr__cachable_o,
    output logic                            dcache_mshr__is_store_o,    
    output mshr_entry_t                     dcache_mshr__entry_o,
    // unlock cache line
    output logic                            dcache_mshr__unlock_vld_o,
    output logic                            dcache_mshr__lock_vld_o,
    output logic[DCACHE_SET_WTH-1:0]        dcache_mshr__unlock_idx_o,
    output logic[DCACHE_WAY_WTH-1:0]        dcache_mshr__unlock_way_o,
    // =====================================
    // [To MissUnit]
    output logic                            lrsc_valid_o, 
    output logic[DCACHE_SET_WTH-1:0]        lrsc_set_idx_o,
    output logic[DCACHE_WAY_WTH-1:0]        lrsc_way_idx_o,
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
  logic [DCACHE_WAY_NUM-1:0]                      tag_match;
  logic [DCACHE_WAY_NUM-1:0]                      state_match;
  logic [DCACHE_WAY_NUM-1:0]                      cache_hit;    
  logic                                           sc_fail;
  logic                                           del_lr_addr;
  logic [DCACHE_WAY_NUM-1:0]                      is_valid;
  logic [$clog2(DCACHE_WAY_NUM)-1:0]              update_way_idx;
  dcache_req_t                                    dcache_req_data_st0; 
  req_src_e                                       req_src_st0,req_src_st1;
  cache_cmd_e                                     cache_cmd_st0,cache_cmd_st1;
  logic                                           cache_is_miss;
  logic                                           cache_is_hit;
  logic                                           req_from_mshr_st1;             
  logic[DCACHE_WAY_WTH-1:0]                       cache_hit_way_idx;
  logic                                           save_lr_addr;
  logic [DCACHE_TAG_MSB-DCACHE_BLOCK_WTH-1:0]     lrsc_addr_d,lrsc_addr_q;  
  logic                                           lrsc_addr_match; 
  logic [6:0]                                     lrsc_cnt_d,lrsc_cnt_q;  
  logic                                           lrsc_valid;
  logic [DCACHE_SET_WTH-1:0]                      lrsc_set_idx;
  logic [DCACHE_WAY_WTH-1:0]                      lrsc_way_idx_d,lrsc_way_idx_q;  
  logic                                           act_st1;          
  logic[AWTH-1:0]                                 paddr_st1;     
  logic                                           cacheable_st1; 
  size_e                                          size_st1;      
  logic[7:0]                                      be_st1;        
  logic[7:0]                                      lookup_be_st1; 
  logic                                           is_store_st1;  
  logic                                           is_load_st1;   
  logic                                           is_amo_st1;
  logic[ROB_WTH-1:0]                              rob_idx_st1;   
  logic[PHY_REG_WTH-1:0]                          rdst_idx_st1;  
  logic                                           rdst_is_fp_st1;
  amo_opcode_e                                    amo_op_st1;    
  logic[DWTH-1:0]                                 data_st1;      
  logic                                           we_st1;        
  logic[SBUF_WTH-1:0]                             sbuf_idx_st1;  
  logic                                           sign_ext_st1;  
  logic[DWTH-1:0]                                 rdata;
  logic[DCACHE_WAY_WTH-1:0]                       wr_way;      
  logic[DCACHE_WAY_NUM-1:0]                       wr_way_en_st1; 
//======================================================================================================================
// Stage 0 : access D cache Mem
//======================================================================================================================
  always_comb begin : req_gen
    data_req_bits_o.idx      = lsu_dcache__data_i.paddr[DCACHE_TAG_LSB-1:0];
    data_req_bits_o.we       = 1'b0;
    data_req_bits_o.way_en   = {DCACHE_WAY_NUM{1'b1}}; 
    data_req_bits_o.wr_data  = lsu_dcache__data_i.data;  
    data_req_bits_o.wstrb    = lsu_dcache__data_i.be;

    // tag read is earier than data read, so use addr_inx_d
    tag_req_bits_o.idx       = lsu_dcache__data_i.paddr[DCACHE_TAG_LSB-1:0];;
    tag_req_bits_o.we        = 1'b0;
    tag_req_bits_o.way_en    = 4'hf;
    //                         {tag ,       state ,valid}
    tag_req_bits_o.wr_tag    = {lsu_dcache__data_i.paddr[DCACHE_TAG_MSB-1:DCACHE_TAG_LSB], Dirty, 1'b1}; 

    dcache_req_data_st0      = lsu_dcache__data_i;
    req_src_st0              = LSU;
    cache_cmd_st0            = READ;

    dcache_mshr__rdy_o      = 1'b0;
    dcache_mmu__rdy_o       = 1'b0;
    dcache_lsu__rdy_o       = 1'b0;

    tag_req_o               = 1'b0;
    data_req_o              = 1'b0;

    if (mshr_dcache__vld_i) begin
      tag_req_o           = 1'b1;
      data_req_o          = 1'b1;
      dcache_mshr__rdy_o  = tag_gnt_i && data_gnt_i;
      data_req_bits_o.idx = mshr_dcache__data_i.paddr[DCACHE_TAG_LSB-1:0];
      tag_req_bits_o.idx  = mshr_dcache__data_i.paddr[DCACHE_TAG_LSB-1:0];     
      dcache_req_data_st0 = mshr_dcache__data_i;
      req_src_st0         = mshr_dcache__req_src_i;   
      cache_cmd_st0       = (mshr_dcache__data_i.is_store || mshr_dcache__data_i.is_amo) ? WRITE : READ;
    end else if (mmu_dcache__vld_i) begin
      tag_req_o           = (!mshr_dcache__afull_i && !mshr_dcache__full_i);
      data_req_o          = (!mshr_dcache__afull_i && !mshr_dcache__full_i);
      dcache_mmu__rdy_o   = tag_gnt_i && data_gnt_i && (!mshr_dcache__afull_i && !mshr_dcache__full_i);
      data_req_bits_o.idx = mmu_dcache__data_i.paddr[DCACHE_TAG_LSB-1:0];
      tag_req_bits_o.idx  = mmu_dcache__data_i.paddr[DCACHE_TAG_LSB-1:0];;     
      dcache_req_data_st0 = mmu_dcache__data_i; 
      req_src_st0         = MMU;
      cache_cmd_st0       = READ;
    end else if (lsu_dcache__vld_i) begin
      tag_req_o           = (!mshr_dcache__afull_i && !mshr_dcache__full_i);   
      data_req_o          = (!mshr_dcache__afull_i && !mshr_dcache__full_i);
      dcache_lsu__rdy_o   = tag_gnt_i && data_gnt_i && (!mshr_dcache__afull_i && !mshr_dcache__full_i);
      data_req_bits_o.we       = lsu_dcache__data_i.we;
      data_req_bits_o.way_en   = lsu_dcache__data_i.way_en; 
      tag_req_bits_o.we        = lsu_dcache__data_i.we;
      tag_req_bits_o.way_en    = lsu_dcache__data_i.way_en;
      cache_cmd_st0       = (lsu_dcache__data_i.is_store || lsu_dcache__data_i.is_amo) ? WRITE : READ;
    end
  end  
//======================================================================================================================
// Stage 1 : Check whether the cache is hit
//======================================================================================================================
  // save signals from stage 0
  always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if (`DFF_IS_R(rst_i)) begin
          act_st1       <= '0;
          req_from_mshr_st1 <= '0;
          cache_cmd_st1 <= cache_cmd_e'(0);
          req_src_st1   <= req_src_e'(0);
          paddr_st1     <= '0;
          cacheable_st1 <= '0;
          size_st1      <= size_e'(0);
          be_st1        <= '0;
          lookup_be_st1 <= '0;
          is_store_st1  <= '0;
          is_load_st1   <= '0;
          is_amo_st1    <= '0;
          rob_idx_st1   <= '0;
          rdst_idx_st1  <= '0;
          rdst_is_fp_st1<= '0;
          amo_op_st1    <= amo_opcode_e'(0);
          data_st1      <= '0;
          we_st1        <= '0;
          sbuf_idx_st1  <= '0;
          sign_ext_st1  <= '0;
          wr_way_en_st1 <= '0;
        end else begin
          act_st1       <= tag_req_o && tag_gnt_i && data_req_o && data_gnt_i;
          req_from_mshr_st1 <= mshr_dcache__vld_i && dcache_mshr__rdy_o;
          cache_cmd_st1 <= cache_cmd_st0;
          req_src_st1   <= req_src_st0;
          paddr_st1     <= dcache_req_data_st0.paddr;
          cacheable_st1 <= dcache_req_data_st0.cacheable;
          size_st1      <= dcache_req_data_st0.size;
          be_st1        <= dcache_req_data_st0.be;
          lookup_be_st1 <= dcache_req_data_st0.lookup_be;
          is_store_st1  <= dcache_req_data_st0.is_store;
          is_load_st1   <= dcache_req_data_st0.is_load;
          is_amo_st1    <= dcache_req_data_st0.is_amo;
          rob_idx_st1   <= dcache_req_data_st0.rob_idx;
          rdst_idx_st1  <= dcache_req_data_st0.rdst_idx;
          rdst_is_fp_st1<= dcache_req_data_st0.rdst_is_fp;
          amo_op_st1    <= dcache_req_data_st0.amo_op;
          data_st1      <= dcache_req_data_st0.data;
          we_st1        <= dcache_req_data_st0.we;
          sbuf_idx_st1  <= dcache_req_data_st0.sbuf_idx;
          sign_ext_st1  <= dcache_req_data_st0.sign_ext;
          wr_way_en_st1 <= dcache_req_data_st0.way_en;
        end
  end

  // cache hit generate logic 
  always_comb begin
    for (integer i=0; i<DCACHE_WAY_NUM; i++) begin: gen_cache_hit
      tag_match[i] = (tag_rsp_bits_i.tag_data[i].tag == paddr_st1[DCACHE_TAG_MSB-1:DCACHE_TAG_LSB]); 
      case(cache_cmd_st1)
        READ:   state_match[i] = tag_rsp_bits_i.tag_data[i].state != Nothing;
        WRITE:  state_match[i] = tag_rsp_bits_i.tag_data[i].state == Dirty || tag_rsp_bits_i.tag_data[i].state == Trunk;
        default:state_match[i] = 1'b0;
      endcase
      // if cache line is valid and tag is match and state is match, then cache hit
      cache_hit[i] = tag_match[i] && state_match[i] && tag_rsp_bits_i.tag_data[i].valid;
      is_valid[i]  = tag_rsp_bits_i.tag_data[i].valid;
    end
  end
  assign cache_is_miss = act_st1 && ~(|cache_hit) && !we_st1;
  assign cache_is_hit  = act_st1 && |cache_hit && !we_st1;
  // cache mem has valid data, but need greater state, such as Branch --> Trunk, so need to update cache line
  assign need_update = |(tag_match & is_valid);

  oneHot2Int #(
    .WIDTH ( DCACHE_WAY_NUM)
  ) valid_to_idx (
    .in_i    ( tag_match & is_valid),
    .cnt_o   ( update_way_idx),
    .empty_o (         )
  );

  oneHot2Int #(
    .WIDTH ( DCACHE_WAY_NUM)
  ) hit_to_idx (
    .in_i    ( cache_hit),
    .cnt_o   ( cache_hit_way_idx),
    .empty_o (         )
  );
  oneHot2Int #(
    .WIDTH ( DCACHE_WAY_NUM)
  ) way_to_idx (
    .in_i    ( wr_way_en_st1),
    .cnt_o   ( wr_way),
    .empty_o (         )
  );

  // when cache miss happen, write to mshr
  // assign dcache_mshr__vld_o   = cache_is_miss && !req_from_mshr_st1 && (!we_st1 || we_st1 && !cacheable_st1);
  always_comb begin
    dcache_mshr__vld_o = 1'b0;
    if (cache_is_miss && !req_from_mshr_st1 && cacheable_st1) begin
      dcache_mshr__vld_o = 1'b1; 
    end else if (!cacheable_st1 && !req_from_mshr_st1 && act_st1) begin
      dcache_mshr__vld_o = 1'b1;
    end
  end
  assign dcache_mshr__addr_o  = paddr_st1;
  assign dcache_mshr__cmd_o   = need_update ? UPDATE : REFILL;
  assign dcache_mshr__update_way_o = update_way_idx;
  assign dcache_mshr__cachable_o = cacheable_st1;
  assign dcache_mshr__is_store_o = is_store_st1 || is_amo_st1;

  assign dcache_mshr__entry_o.is_store   = is_store_st1;
  assign dcache_mshr__entry_o.is_load    = is_load_st1;
  assign dcache_mshr__entry_o.is_amo     = is_amo_st1;
  assign dcache_mshr__entry_o.src        = req_src_st1;
  assign dcache_mshr__entry_o.data       = data_st1;
  assign dcache_mshr__entry_o.be         = be_st1;
  assign dcache_mshr__entry_o.lookup_be  = lookup_be_st1;
  assign dcache_mshr__entry_o.size       = size_st1;
  assign dcache_mshr__entry_o.rob_idx    = rob_idx_st1;
  assign dcache_mshr__entry_o.rdst_idx   = rdst_idx_st1;
  assign dcache_mshr__entry_o.rdst_is_fp = rdst_is_fp_st1;
  assign dcache_mshr__entry_o.sbuf_idx   = sbuf_idx_st1;
  assign dcache_mshr__entry_o.amo_op     = amo_op_st1;
  assign dcache_mshr__entry_o.sign_ext   = sign_ext_st1;
  assign dcache_mshr__entry_o.cl_offset  = paddr_st1[DCACHE_BLOCK_MSB-1:0];
  // when cache hit, unlock the cache line so this cache line can be replaced
  always_comb begin
    dcache_mshr__unlock_vld_o = 1'b0;
    dcache_mshr__lock_vld_o   = 1'b0;
    dcache_mshr__unlock_way_o  = cache_hit_way_idx;
    if (cache_is_hit) begin
      if (is_load_st1 && req_from_mshr_st1) begin
        dcache_mshr__unlock_vld_o = 1'b1;       
      end else if (is_store_st1 && !req_from_mshr_st1 && !we_st1) begin
        dcache_mshr__lock_vld_o   = 1'b1;
      end else if (is_amo_st1 && amo_op_st1 == AMO_LR && req_from_mshr_st1) begin
        dcache_mshr__unlock_vld_o = 1'b1;              
      end else if (is_amo_st1 && amo_op_st1 == AMO_SC && req_from_mshr_st1 && !we_st1) begin
        dcache_mshr__unlock_vld_o = sc_fail;
      end else if (is_amo_st1 && amo_op_st1 == AMO_SC && !req_from_mshr_st1 && !we_st1) begin
        dcache_mshr__lock_vld_o   = !sc_fail;
      end else if (is_amo_st1 && !req_from_mshr_st1 && !we_st1) begin
        dcache_mshr__lock_vld_o   = 1'b1;
      end
    end
    if (we_st1 && act_st1 && cacheable_st1) begin
      dcache_mshr__unlock_vld_o = 1'b1;
      dcache_mshr__unlock_way_o = wr_way;
    end
  end
  assign dcache_mshr__unlock_idx_o  = paddr_st1[DCACHE_SET_MSB-1:DCACHE_SET_LSB];
  // assign dcache_mshr__unlock_way_o  = cache_hit_way_idx;

  logic [DWTH-1:0] cache_mem_rdata;
  assign cache_mem_rdata = data_rsp_bits_i.rd_data[cache_hit_way_idx];
  always_comb begin : read_data_gen
    if (amo_op_st1 == AMO_SC) begin 
      rdata = sc_fail;
    end else if (!cacheable_st1) begin
      rdata = data_st1;
    end else begin
      for (integer i=0;i<8;i++) begin
        rdata[i*8+:8] = lookup_be_st1[i] ? data_st1[i*8+:8] : cache_mem_rdata[i*8+:8];
      end
    end
  end

  // send data back to LSU/MMU
  // non-cacheable access is from MSHR which means the data has been fetch from memory, so send it back 
  // assign dcache_lsu__data_o.valid    = act_st1 && req_src_st1 == LSU && (cache_is_hit || req_from_mshr_st1 && !cacheable_st1 && !is_store_st1);
  always_comb begin
    dcache_lsu__data_o.valid = 1'b0;
    if (act_st1 && req_src_st1 == LSU && !we_st1) begin
      if (is_load_st1) begin
        dcache_lsu__data_o.valid = cache_is_hit || req_from_mshr_st1 && !cacheable_st1; 
      end else if (is_store_st1) begin
        dcache_lsu__data_o.valid = cache_is_hit || req_from_mshr_st1 && !cacheable_st1;
      end else if (is_amo_st1) begin
        dcache_lsu__data_o.valid = cache_is_hit;
      end
    end
  end
  assign dcache_lsu__data_o.offset   = paddr_st1[2:0];
  assign dcache_lsu__data_o.is_load  = is_load_st1;
  assign dcache_lsu__data_o.is_store = is_store_st1;
  assign dcache_lsu__data_o.is_amo   = is_amo_st1;
  assign dcache_lsu__data_o.rdata    = rdata;
  assign dcache_lsu__data_o.rdst_idx = rdst_idx_st1;
  assign dcache_lsu__data_o.rob_idx  = rob_idx_st1;
  assign dcache_lsu__data_o.sbuf_idx = sbuf_idx_st1;
  assign dcache_lsu__data_o.rdst_is_fp = rdst_is_fp_st1;
  assign dcache_lsu__data_o.size     = size_st1;           
  assign dcache_lsu__data_o.amo_op   = amo_op_st1;
  assign dcache_lsu__data_o.way_en   = cache_hit;
  assign dcache_lsu__data_o.be       = be_st1;  
  assign dcache_lsu__data_o.sign_ext = sign_ext_st1;
  assign dcache_lsu__data_o.cacheable = cacheable_st1;
  assign dcache_lsu__data_o.st1_idle = !act_st1;
  assign dcache_lsu__data_o.mshr_empty = mshr_dcache__empty_i;
  // send data to MMU(PTW)
  assign dcache_mmu__rvld_o          = act_st1 && req_src_st1 == MMU && (cache_is_hit || req_from_mshr_st1 && !cacheable_st1);
  assign dcache_mmu__rdata_o         = cache_mem_rdata; 
//======================================================================================================================
// LRSC Unit
//======================================================================================================================
  assign save_lr_addr = (amo_op_st1 == AMO_LR) && act_st1 && cache_is_hit;
  assign del_lr_addr  = (amo_op_st1 == AMO_SC) && act_st1 && we_st1;

  assign lrsc_addr_d  = save_lr_addr ? {paddr_st1>>DCACHE_BLOCK_WTH} : lrsc_addr_q;
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
  assign lrsc_addr_match = lrsc_addr_q == {paddr_st1>>DCACHE_BLOCK_WTH};
  assign lrsc_valid = lrsc_cnt_q > LRSC_THRESH;
  assign lrsc_set_idx = lrsc_addr_q[DCACHE_SET_MSB-1:DCACHE_SET_LSB];
  assign lrsc_way_idx_d = save_lr_addr ? cache_hit_way_idx : lrsc_way_idx_q;
  assign allow_probe_o = !lrsc_valid;
  // store conditional failed 
  assign sc_fail = (amo_op_st1 == AMO_SC) && act_st1 && cache_is_hit && !(lrsc_valid && lrsc_addr_match);
  // To miss unit
  assign lrsc_valid_o = lrsc_valid;
  assign lrsc_set_idx_o = lrsc_set_idx;
  assign lrsc_way_idx_o = lrsc_way_idx_q;
//======================================================================================================================
// registers
//======================================================================================================================
  always_ff @(`DFF_CR(clk_i,rst_i)) begin : regs 
    if(`DFF_IS_R(rst_i)) begin
      lrsc_addr_q       <= '0; 
      lrsc_cnt_q        <= '0; 
      lrsc_way_idx_q    <= '0;
    end else begin
      lrsc_addr_q       <= lrsc_addr_d   ; 
      lrsc_cnt_q        <= lrsc_cnt_d    ; 
      lrsc_way_idx_q    <= lrsc_way_idx_d;
    end
  end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
(* mark_debug = "true" *) logic             prb_dcache_st1_act;
(* mark_debug = "true" *) logic[31:0]       prb_dcache_st1_paddr;
(* mark_debug = "true" *) logic[ROB_WTH-1:0]prb_dcache_st1_rob_idx;
(* mark_debug = "true" *) logic             prb_dcache_st1_is_load;
(* mark_debug = "true" *) logic             prb_dcache_st1_is_store;
(* mark_debug = "true" *) logic             prb_dcache_st1_is_amo;
(* mark_debug = "true" *) logic             prb_dcache_st1_is_we;
(* mark_debug = "true" *) logic             prb_dcache_st1_cacheable;
(* mark_debug = "true" *) logic             prb_dcache_st1_cache_miss;
(* mark_debug = "true" *) logic             prb_dcache_st1_cache_hit;
(* mark_debug = "true" *) logic[3:0]        prb_dcache_st1_hit_way;

assign prb_dcache_st1_act     = act_st1;
assign prb_dcache_st1_paddr   = paddr_st1;
assign prb_dcache_st1_rob_idx = rob_idx_st1;
assign prb_dcache_st1_is_load = is_load_st1;
assign prb_dcache_st1_is_store  = is_store_st1;
assign prb_dcache_st1_is_amo  = is_amo_st1;
assign prb_dcache_st1_is_we = we_st1;
assign prb_dcache_st1_cacheable = cacheable_st1;
assign prb_dcache_st1_cache_miss  = cache_is_miss;
assign prb_dcache_st1_cache_hit   = cache_is_hit;
assign prb_dcache_st1_hit_way = cache_hit;

 (* mark_debug = "true" *)logic                      prb_lrsc_valid;
 (* mark_debug = "true" *)logic[DCACHE_SET_WTH-1:0]  prb_lrsc_set_idx;
 (* mark_debug = "true" *)logic[DCACHE_WAY_WTH-1:0]  prb_lrsc_way_idx;

assign prb_lrsc_valid     = lrsc_valid_o;
assign prb_lrsc_set_idx   = lrsc_set_idx_o;
assign prb_lrsc_way_idx   = lrsc_way_idx_o;
(* mark_debug = "true" *) logic             prb_mmu_dcache_vld;
(* mark_debug = "true" *) logic             prb_mmu_dcache_rdy;
(* mark_debug = "true" *) logic[31:0]       prb_mmu_dcache_addr;
(* mark_debug = "true" *) logic             prb_mmu_rvalid;
(* mark_debug = "true" *) logic[63:0]       prb_mmu_rdata;

assign prb_mmu_dcache_vld   = mmu_dcache__vld_i;
assign prb_mmu_dcache_rdy   = dcache_mmu__rdy_o;
assign prb_mmu_rvalid       = dcache_mmu__rvld_o;
assign prb_mmu_dcache_addr  = mmu_dcache__data_i.paddr[31:0];
assign prb_mmu_rdata        = dcache_mmu__rdata_o;


endmodule
// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_dcache_mshr.v
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

module sy_dcache_mshr
    import sy_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    output  logic                           mshr_full_o,  // full
    output  logic                           mshr_afull_o, // almost full
    output  logic                           mshr_empty_o,

    output  logic[DCACHE_SET_SIZE-1:0][DCACHE_WAY_NUM-1:0][MSHR_WTH:0]lock_cl_o,
    // =====================================
    // [From D cache Ctrl]
    input   logic                           mshr_wr_en_i,
    input   logic[31:0]                     mshr_paddr_i,        
    input   miss_req_cmd_e                  mshr_cmd_i,
    input   logic[DCACHE_WAY_WTH-1:0]       mshr_update_way_i,    
    input   logic                           mshr_cacheable_i,
    input   logic                           mshr_is_store_i,
    input   mshr_entry_t                    mshr_wr_entry_i,

    input   logic                           mshr_unlock_vld_i,
    input   logic                           mshr_lock_vld_i,
    input   logic[DCACHE_SET_WTH-1:0]       mshr_unlock_idx_i,
    input   logic[DCACHE_WAY_WTH-1:0]       mshr_unlock_way_i,
    // =====================================
    // [Miss Req]   
    output logic                            miss_req_o,
    input  logic                            miss_ack_i,
    output logic                            miss_kill_o,
    input  logic                            miss_kill_done_i,
    output miss_req_bits_t                  miss_req_bits_o,
    input  logic                            miss_done_i,
    input  logic [DCACHE_DATA_SIZE*8-1:0]   miss_rdata_i,   // for non-cacheable data
    input  logic [DCACHE_WAY_WTH-1:0]       miss_rpl_way_i,
    // =====================================
    // [Replay]   
    output logic                            mshr_dcache__vld_o,
    input  logic                            dcache_mshr__rdy_i,      
    output dcache_req_t                     mshr_dcache__data_o,
    output req_src_e                        mshr_dcache__req_src_o          
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    typedef enum logic[2:0] {IDLE,REFILL_WAIT,REPLAY_REQ,REFILL_REQ,KILL_REFILL} state_e;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    state_e                                 state_d, state_q;
    mshr_head_t [MSHR_LEN-1:0]              mshr_head_d, mshr_head_q;
    mshr_entry_t [MSHR_LEN-1:0]             mshr_entry_d, mshr_entry_q;
    logic[MSHR_LEN-1:0]                     mshr_head_vld_d, mshr_head_vld_q;
    logic[MSHR_LEN-1:0]                     mshr_entry_vld_d, mshr_entry_vld_q;
    logic[MSHR_WTH-1:0]                     head_ins_idx_d,  head_ins_idx_q;
    logic[MSHR_WTH-1:0]                     head_del_idx_d,  head_del_idx_q;
    logic[MSHR_WTH:0]                       head_cnt_d,head_cnt_q;            
    logic[MSHR_WTH:0]                       entry_cnt_d,entry_cnt_q;            
    logic                                   merge_en;
    logic[MSHR_WTH-1:0]                     merge_idx;          
    logic                                   merge_replay;
    logic                                   head_del_en;
    logic                                   mshr_entry_afull;
    logic                                   mshr_entry_full;
    logic                                   mshr_entry_empty;
    logic                                   alloc_entry_suc;
    logic[MSHR_WTH-1:0]                     alloc_entry_idx;
    logic                                   rel_entry;
    logic[MSHR_WTH-1:0]                     rel_entry_idx;
    logic                                   mshr_head_empty;
    logic                                   mshr_head_full;
    logic                                   mshr_head_afull;
    logic[MSHR_WTH:0]                       entry_todo_cnt_d,entry_todo_cnt_q;
    logic[MSHR_WTH-1:0]                     replay_entry_d,replay_entry_q;          
    logic                                   rpl_done;

    logic[DCACHE_SET_SIZE-1:0][DCACHE_WAY_NUM-1:0][MSHR_WTH:0]lock_cl_d,lock_cl_q;
    logic                                   cl_lock_vld;       
    logic[DCACHE_SET_WTH-1:0]               cl_lock_idx;       
    logic[DCACHE_WAY_WTH-1:0]               cl_lock_way;       
    logic[MSHR_WTH:0]                       cl_lock_cnt;                
    logic                                   fresh_cmd;
    logic                                   will_fresh_cmd_d,will_fresh_cmd_q;
    logic[DCACHE_WAY_WTH-1:0]               fresh_way_d,fresh_way_q;
    logic                                   cacheable_d,cacheable_q;
    logic[DWTH-1:0]                         non_cacheable_data_d,non_cacheable_data_q;    
    logic[MSHR_LEN-1:0][MSHR_WTH-1:0]       entry_cnt; 
    logic                                   issue_vld;
    logic[MSHR_WTH-1:0]                     issue_idx;
    logic                                   replay_mark_d,replay_mark_q;
//======================================================================================================================
// Write to mshr head
//======================================================================================================================
    assign mshr_full_o  = mshr_head_full || mshr_entry_full;
    assign mshr_afull_o = mshr_head_afull || mshr_entry_afull;
    assign mshr_empty_o = mshr_head_empty && mshr_entry_empty;
    // lookup if there exists a mshr head with same addr
    // if so, merge it instead of inserting a new one
    always_comb begin
        merge_en        = 1'b0;
        merge_idx       = '0;
        merge_replay    = 1'b0;
        for (integer i=0; i<MSHR_LEN; i=i+1) begin
            // must be cacheable region when merge
            if (mshr_wr_en_i && mshr_head_vld_q[i] && mshr_cacheable_i
                && mshr_paddr_i[31:DCACHE_BLOCK_MSB] == mshr_head_q[i].paddr[31:DCACHE_BLOCK_MSB]) begin
                merge_en  = 1'b1;
                merge_idx = i;
                if (mshr_head_q[i].cmd == REFILL && !mshr_head_q[i].we && mshr_head_q[i].issue && mshr_is_store_i) begin
                    merge_replay = 1'b1;
                end else begin
                    merge_replay = 1'b0;
                end   
            end
        end
    end
    always_comb begin : mshr_head
        for (integer i=0; i<MSHR_LEN; i=i+1) begin
            entry_cnt[i]   = mshr_head_q[i].entry_cnt;
            mshr_head_d[i] = mshr_head_q[i];
            if (merge_en && merge_idx == i) begin
                // recored the entry index 
                mshr_head_d[i].entry_loc[entry_cnt[i]] = alloc_entry_idx;
                // recored how many entries belong to this head 
                mshr_head_d[i].entry_cnt = entry_cnt[i] + 1'b1;
                mshr_head_d[i].we        = mshr_head_q[i].we | mshr_is_store_i;
                mshr_head_d[i].cmd       = merge_replay ? UPDATE : mshr_head_q[i].cmd;
                mshr_head_d[i].replay    = mshr_head_q[i].replay | merge_replay;
            end else if (mshr_wr_en_i && head_ins_idx_q == i) begin
                // allocate a new mshr head
                mshr_head_d[i].paddr      = mshr_paddr_i; 
                mshr_head_d[i].cmd        = mshr_cmd_i; 
                mshr_head_d[i].update_way = mshr_update_way_i; 
                mshr_head_d[i].cacheable  = mshr_cacheable_i; 
                mshr_head_d[i].we         = mshr_is_store_i; 
                mshr_head_d[i].entry_loc  = '0;
                mshr_head_d[i].entry_loc[0] = alloc_entry_idx;
                mshr_head_d[i].entry_cnt  = 1'b1;
                mshr_head_d[i].issue      = 1'b0;
                mshr_head_d[i].replay     = 1'b0;
            end
            if (fresh_cmd && mshr_head_q[i].update_way==fresh_way_d && mshr_head_q[i].cmd == UPDATE 
                && mshr_head_vld_q[i] 
                && mshr_head_q[i].paddr[DCACHE_SET_MSB-1:DCACHE_SET_LSB] == mshr_head_q[head_del_idx_q].paddr[DCACHE_SET_MSB-1:DCACHE_SET_LSB]) begin    
                mshr_head_d[i].cmd = REFILL;
            end
            if (issue_vld && issue_idx == i) begin
                mshr_head_d[i].issue = 1'b1;
            end
        end 
    end

    assign mshr_head_full  = head_cnt_q  ==  MSHR_LEN;
    assign mshr_head_afull = head_cnt_q  == (MSHR_LEN - 1);
    assign mshr_head_empty = head_cnt_q  == '0;
    always_comb begin : head_ins_idx
        head_ins_idx_d = head_ins_idx_q;
        if (flush_i) begin
            head_ins_idx_d = '0;           
        end else if (merge_en) begin
            head_ins_idx_d = head_ins_idx_q;           
        end else if (mshr_wr_en_i) begin
            head_ins_idx_d = head_ins_idx_q + 1;                      
        end 
    end
    always_comb begin : head_del_idx
        head_del_idx_d = head_del_idx_q;
        if (flush_i) begin
            head_del_idx_d = '0;           
        end else if (head_del_en) begin
            head_del_idx_d = head_del_idx_q + 1;                      
        end 
    end
    always_comb begin : head_cnt
       head_cnt_d = head_cnt_q; 
       if (flush_i) begin
           head_cnt_d = '0;           
       end else if (merge_en && head_del_en) begin
           head_cnt_d = head_cnt_q - 1;           
       end else if (merge_en) begin
           head_cnt_d = head_cnt_q;
       end else if (mshr_wr_en_i && head_del_en) begin
           head_cnt_d = head_cnt_q;                      
       end else if (mshr_wr_en_i) begin
           head_cnt_d = head_cnt_q + 1; 
       end else if (head_del_en) begin
           head_cnt_d = head_cnt_q - 1; 
       end
    end
    always_comb begin : head_valid
        mshr_head_vld_d = mshr_head_vld_q; 
        if (mshr_wr_en_i && !merge_en) begin
            mshr_head_vld_d[head_ins_idx_q] = 1'b1;
        end 
        if (head_del_en) begin
            mshr_head_vld_d[head_del_idx_q] = 1'b0;
        end
        if (flush_i) begin
            mshr_head_vld_d = '0;
        end
    end
    // when refill one cache line, lock it until some instr access it 
    always_comb begin : lock_cl
        lock_cl_d = lock_cl_q; 
        for (integer i=0;i<DCACHE_SET_SIZE;i++) begin
            for (integer j=0;j<DCACHE_WAY_NUM;j++) begin
                lock_cl_d[i][j] = lock_cl_q[i][j];
                if (flush_i)begin
                    lock_cl_d[i][j] = '0;
                end else if ((mshr_unlock_vld_i || mshr_lock_vld_i) && mshr_unlock_idx_i == i && mshr_unlock_way_i == j) begin
                    if (mshr_unlock_vld_i && lock_cl_d[i][j] != 0) begin
                        lock_cl_d[i][j] = lock_cl_q[i][j] - 1;
                    end else if (mshr_lock_vld_i) begin
                        lock_cl_d[i][j] = lock_cl_q[i][j] + 1;
                    end
                end else if (cl_lock_vld && cl_lock_idx == i && cl_lock_way == j) begin
                    lock_cl_d[i][j] = cl_lock_cnt;
                end 
            end
        end
    end
    assign lock_cl_o = lock_cl_q;
//======================================================================================================================
// Write to mshr entry
//======================================================================================================================
    always_comb begin : allocate_free_entry
        alloc_entry_suc  = 1'b0;
        alloc_entry_idx  = '0;
        for (integer i=0; i<MSHR_LEN; i=i+1) begin
            if (mshr_entry_vld_q[i] == 1'b0) begin
                alloc_entry_suc  = 1'b1;
                alloc_entry_idx  = i;
            end
        end
    end
    always_comb begin : mshr_entry
        for (integer i=0; i<MSHR_LEN; i=i+1) begin
            mshr_entry_d[i] = mshr_entry_q[i];
            mshr_entry_vld_d[i] = mshr_entry_vld_q[i];
            if (flush_i) begin
               mshr_entry_vld_d[i] = 1'b0; 
            end else if (mshr_wr_en_i && i == alloc_entry_idx) begin
                mshr_entry_vld_d[i]  = 1'b1;
                mshr_entry_d[i]      = mshr_wr_entry_i;         
            end else if (rel_entry && rel_entry_idx == i) begin
                mshr_entry_vld_d[i] = 1'b0;
            end
        end
    end
    always_comb begin : entry_count
        entry_cnt_d = entry_cnt_q; 
        if (flush_i) begin
            entry_cnt_d = '0;
        end else if (mshr_wr_en_i && rel_entry) begin
            entry_cnt_d = entry_cnt_q;
        end else if (mshr_wr_en_i) begin
            entry_cnt_d = entry_cnt_q + 1; 
        end else if (rel_entry) begin
            entry_cnt_d = entry_cnt_q - 1;
        end
    end
    assign mshr_entry_afull = entry_cnt_q == (MSHR_LEN - 1);
    assign mshr_entry_full  = entry_cnt_q == MSHR_LEN ;
    assign mshr_entry_empty = entry_cnt_q == 0;
//======================================================================================================================
// MSHR Control Logic
//======================================================================================================================

    assign miss_req_bits_o.cmd       = mshr_head_d[head_del_idx_q].cmd;
    assign miss_req_bits_o.cacheable = mshr_head_q[head_del_idx_q].cacheable;
    assign miss_req_bits_o.we        = mshr_head_d[head_del_idx_q].we;
    assign miss_req_bits_o.addr      = cacheable_q ? (mshr_head_q[head_del_idx_q].paddr>>DCACHE_BLOCK_WTH)<<DCACHE_BLOCK_WTH : mshr_head_q[head_del_idx_q].paddr;
    assign miss_req_bits_o.update_way= replay_mark_q ? fresh_way_q : mshr_head_q[head_del_idx_q].update_way;
    assign miss_req_bits_o.be        = mshr_entry_q[replay_entry_q].be;
    assign miss_req_bits_o.wdata     = mshr_entry_q[replay_entry_q].data;
    assign miss_req_bits_o.amo_op    = mshr_entry_q[replay_entry_q].amo_op;

    assign mshr_dcache__data_o.paddr        = cacheable_q ? {mshr_head_q[head_del_idx_q].paddr>>DCACHE_BLOCK_WTH,mshr_entry_q[replay_entry_q].cl_offset} : mshr_head_q[head_del_idx_q].paddr;
    assign mshr_dcache__data_o.cacheable    = cacheable_q; 
    assign mshr_dcache__data_o.size         = mshr_entry_q[replay_entry_q].size;
    assign mshr_dcache__data_o.is_store     = mshr_entry_q[replay_entry_q].is_store;  
    assign mshr_dcache__data_o.is_load      = mshr_entry_q[replay_entry_q].is_load;
    assign mshr_dcache__data_o.is_amo       = mshr_entry_q[replay_entry_q].is_amo;
    assign mshr_dcache__data_o.rob_idx      = mshr_entry_q[replay_entry_q].rob_idx;
    assign mshr_dcache__data_o.rdst_idx     = mshr_entry_q[replay_entry_q].rdst_idx;
    assign mshr_dcache__data_o.rdst_is_fp   = mshr_entry_q[replay_entry_q].rdst_is_fp;
    assign mshr_dcache__data_o.amo_op       = mshr_entry_q[replay_entry_q].amo_op;
    assign mshr_dcache__data_o.sign_ext     = mshr_entry_q[replay_entry_q].sign_ext;
    assign mshr_dcache__data_o.sbuf_idx     = mshr_entry_q[replay_entry_q].sbuf_idx;
    assign mshr_dcache__data_o.data         = cacheable_q ? mshr_entry_q[replay_entry_q].data : non_cacheable_data_q;
    assign mshr_dcache__data_o.way_en       = 4'hf;
    assign mshr_dcache__data_o.be           = mshr_entry_q[replay_entry_q].be;
    assign mshr_dcache__data_o.lookup_be    = mshr_entry_q[replay_entry_q].lookup_be;
    assign mshr_dcache__data_o.we           = 1'b0;

    assign mshr_dcache__req_src_o           = mshr_entry_q[replay_entry_q].src;
    // replay done 
    assign rpl_done = mshr_head_q[head_del_idx_q].entry_cnt == (entry_todo_cnt_q - 1);
    always_comb begin : mshr_fsm
        state_d             = state_q;
        rel_entry           = 1'b0;
        rel_entry_idx       = '0;
        miss_req_o          = 1'b0;    
        miss_kill_o         = 1'b0;
        entry_todo_cnt_d    = entry_todo_cnt_q;
        replay_entry_d      = replay_entry_q;
        mshr_dcache__vld_o  = 1'b0;
        cacheable_d         = cacheable_q;
        non_cacheable_data_d = non_cacheable_data_q;
        will_fresh_cmd_d    = will_fresh_cmd_q;
        fresh_way_d         = fresh_way_q;
        fresh_cmd           = 1'b0;
        cl_lock_vld         = 1'b0;
        cl_lock_idx         = '0;
        cl_lock_way         = '0;
        cl_lock_cnt         = '0;
        head_del_en         = 1'b0;
        issue_vld           = 1'b0;
        issue_idx           = '0;
        replay_mark_d       = replay_mark_q;
        unique case (state_q) 
            IDLE: begin 
                if (!mshr_head_empty && !flush_i) begin
                    cacheable_d = mshr_head_q[head_del_idx_q].cacheable;
                    replay_entry_d = mshr_head_q[head_del_idx_q].entry_loc[0];
                    replay_mark_d = 1'b0;
                    state_d = REFILL_REQ;
                end
            end
            REFILL_REQ: begin
                if (flush_i) begin
                   state_d = IDLE; 
                end else begin
                    will_fresh_cmd_d = mshr_head_q[head_del_idx_q].cmd == REFILL && cacheable_q;
                    // fresh_way_d = mshr_head_q[head_del_idx_q].cmd == REFILL ? rpl_way : mshr_head_q[head_del_idx_q].update_way; 
                    miss_req_o = 1'b1;
                    if (miss_req_o & miss_ack_i) begin
                        issue_vld = 1'b1;
                        issue_idx = head_del_idx_q;
                        state_d = REFILL_WAIT;
                    end
                end
            end
            REFILL_WAIT: begin
                if (flush_i) begin
                    state_d = miss_done_i ? IDLE : KILL_REFILL;
                end else begin
                    if (miss_done_i) begin
                        if (!replay_mark_q && mshr_head_d[head_del_idx_q].replay) begin
                            replay_mark_d = 1'b1;   
                            state_d = REFILL_REQ;
                        end else begin
                            fresh_cmd = will_fresh_cmd_q;
                            cl_lock_vld = mshr_head_q[head_del_idx_q].cacheable;
                            state_d = REPLAY_REQ;
                        end
                        fresh_way_d = miss_rpl_way_i;
                        non_cacheable_data_d = miss_rdata_i;
                        entry_todo_cnt_d = 1'b1;
                        replay_entry_d = mshr_head_q[head_del_idx_q].entry_loc[0];
                        cl_lock_idx = mshr_head_q[head_del_idx_q].paddr[DCACHE_SET_MSB-1:DCACHE_SET_LSB]; 
                        cl_lock_way = miss_rpl_way_i; 
                        cl_lock_cnt = mshr_head_d[head_del_idx_q].entry_cnt;
                        // state_d = REPLAY_REQ;
                    end
                end
            end
            REPLAY_REQ: begin
                if (flush_i || rpl_done) begin
                    head_del_en = 1'b1;
                    state_d = IDLE;
                end else begin
                    mshr_dcache__vld_o = 1'b1;
                    if (dcache_mshr__rdy_i) begin
                        entry_todo_cnt_d  = entry_todo_cnt_q + 1'b1;
                        replay_entry_d    = mshr_head_q[head_del_idx_q].entry_loc[entry_todo_cnt_q[MSHR_WTH-1:0]];
                        rel_entry = 1'b1;
                        rel_entry_idx = replay_entry_q;
                    end
                end
            end
            KILL_REFILL: begin
                miss_kill_o = 1'b1;    
                if (miss_kill_done_i || miss_done_i) begin
                    state_d = IDLE;
                end
            end
            default: begin 
                state_d = IDLE;
            end
        endcase
    end
//======================================================================================================================
// Reigster
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0; i<MSHR_LEN; i=i+1) begin
                mshr_head_q[i]           <= mshr_head_t'(0);
                mshr_entry_q[i]          <= mshr_entry_t'(0);
                mshr_entry_vld_q[i]      <= '0;
                mshr_head_vld_q[i]       <= '0;
            end
            for (integer i=0; i<DCACHE_SET_SIZE; i=i+1) begin
                for (integer j=0; j<DCACHE_WAY_NUM; j=j+1) begin
                    lock_cl_q[i][j]     <= '0;
                end
            end
            head_ins_idx_q    <= '0;
            head_del_idx_q    <= '0;
            cacheable_q       <= '0;
            non_cacheable_data_q <= '0;
            will_fresh_cmd_q  <= '0;
            fresh_way_q       <= '0;
            entry_todo_cnt_q  <= '0;
            replay_entry_q    <= '0;
            state_q           <= IDLE;
            head_cnt_q        <= '0;
            entry_cnt_q       <= '0;
            replay_mark_q     <= '0;
        end else begin
            for (integer i=0; i<MSHR_LEN; i=i+1) begin
                mshr_head_q[i]           <= mshr_head_d[i];
                mshr_entry_q[i]          <= mshr_entry_d[i];
                mshr_entry_vld_q[i]      <= mshr_entry_vld_d[i];
                mshr_head_vld_q[i]       <= mshr_head_vld_d[i];
            end
            for (integer i=0; i<DCACHE_SET_SIZE; i=i+1) begin
                for (integer j=0; j<DCACHE_WAY_NUM; j=j+1) begin
                    lock_cl_q[i][j]     <= lock_cl_d[i][j];
                end
            end
            head_ins_idx_q  <= head_ins_idx_d;
            head_del_idx_q  <= head_del_idx_d;
            cacheable_q     <= cacheable_d;
            non_cacheable_data_q <= non_cacheable_data_d;
            will_fresh_cmd_q  <= will_fresh_cmd_d;
            fresh_way_q       <= fresh_way_d;
            entry_todo_cnt_q  <= entry_todo_cnt_d;
            replay_entry_q    <= replay_entry_d;
            state_q           <= state_d;
            head_cnt_q        <= head_cnt_d;
            entry_cnt_q       <= entry_cnt_d;
            replay_mark_q     <= replay_mark_d;
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
(* mark_debug = "true" *) logic             prb_mshr_wr_en;
(* mark_debug = "true" *) logic[31:0]       prb_mshr_wr_paddr;
(* mark_debug = "true" *) miss_req_cmd_e    prb_mshr_wr_cmd;
(* mark_debug = "true" *) logic             prb_mshr_is_store;
(* mark_debug = "true" *) logic             prb_mshr_cacheable;
(* mark_debug = "true" *) logic             prb_mshr_merge_en;
assign prb_mshr_wr_en = mshr_wr_en_i;
assign prb_mshr_wr_paddr = mshr_paddr_i;
assign prb_mshr_wr_cmd = mshr_cmd_i;
assign prb_mshr_is_store = mshr_is_store_i;
assign prb_mshr_cacheable = mshr_cacheable_i;
assign prb_mshr_merge_en = merge_en;


(* mark_debug = "true" *) state_e           prb_mshr_state;
(* mark_debug = "true" *) logic[MSHR_WTH:0] prb_mshr_head_cnt;
(* mark_debug = "true" *) logic[MSHR_WTH:0] prb_mshr_entry_cnt;
(* mark_debug = "true" *) logic             prb_mshr_full;
(* mark_debug = "true" *) logic             prb_mshr_afull;



(* mark_debug = "true" *) logic             prb_mshr_miss_req;
(* mark_debug = "true" *) logic             prb_mshr_miss_ack;
(* mark_debug = "true" *) logic[31:0]       prb_mshr_miss_addr;
(* mark_debug = "true" *) miss_req_cmd_e    prb_mshr_miss_cmd;
(* mark_debug = "true" *) logic             prb_mshr_miss_cacheable;


(* mark_debug = "true" *) logic             prb_mshr_dcache_vld;
(* mark_debug = "true" *) logic             prb_mshr_dcache_rdy;
(* mark_debug = "true" *) logic[31:0]       prb_mshr_dcache_addr;
(* mark_debug = "true" *) size_e            prb_mshr_dcache_size;

assign prb_mshr_state = state_q;
assign prb_mshr_head_cnt = head_cnt_q;
assign prb_mshr_entry_cnt = entry_cnt_q;
assign prb_mshr_full = mshr_full_o;
assign prb_mshr_afull = mshr_afull_o;


assign prb_mshr_miss_req = miss_req_o;
assign prb_mshr_miss_ack = miss_ack_i;
assign prb_mshr_miss_addr = miss_req_bits_o.addr[31:0];
assign prb_mshr_miss_cmd = miss_req_bits_o.cmd;
assign prb_mshr_miss_cacheable = miss_req_bits_o.cacheable;

assign prb_mshr_dcache_vld = mshr_dcache__vld_o;
assign prb_mshr_dcache_rdy = dcache_mshr__rdy_i;
assign prb_mshr_dcache_addr = mshr_dcache__data_o.paddr[31:0];
assign prb_mshr_dcache_size = mshr_dcache__data_o.size;

(* mark_debug = "true" *)logic                           prb_mshr_unlock_vld;
(* mark_debug = "true" *)logic                           prb_mshr_lock_vld;
(* mark_debug = "true" *)logic[DCACHE_SET_WTH-1:0]       prb_mshr_unlock_idx;
(* mark_debug = "true" *)logic[DCACHE_WAY_WTH-1:0]       prb_mshr_unlock_way;
(* mark_debug = "true" *)logic                           prb_mshr_cl_lock;
(* mark_debug = "true" *)logic[DCACHE_SET_WTH-1:0]       prb_mshr_cl_lock_idx;
(* mark_debug = "true" *)logic[DCACHE_WAY_WTH-1:0]       prb_mshr_cl_lock_way;

assign prb_mshr_unlock_vld      = mshr_unlock_vld_i;
assign prb_mshr_lock_vld        = mshr_lock_vld_i;
assign prb_mshr_unlock_idx      = mshr_unlock_idx_i;
assign prb_mshr_unlock_way      = mshr_unlock_way_i;
assign prb_mshr_cl_lock         = cl_lock_vld;
assign prb_mshr_cl_lock_idx     = cl_lock_idx;
assign prb_mshr_cl_lock_way     = cl_lock_way;

// synopsys translate_off
// synopsys translate_on
endmodule : sy_dcache_mshr

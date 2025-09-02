// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_probe_ctrl.v
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

module tl_probe_ctrl #(
    parameter HART_NUM              = 2,
    parameter HART_ID_WTH           = $clog2(HART_NUM),
    parameter HART_ID_LSB           = 1,
    parameter SINK_LSB              = 1,
    parameter SINK_ID               = 0,
    parameter SINK_ID_WTH           = 1,
    parameter ADDR_WTH              = 64
)(
    input                                   clk_i,
    input                                   rst_i,
    // =====================================
    // [from system bus]
    // A channel
    input  logic                            inp_A_valid_i,
    output logic                            inp_A_ready_o,
    input  tl_pkg::A_chan_bits_t            inp_A_bits_i,
    // B channel
    output logic                            inp_B_valid_o,
    input  logic                            inp_B_ready_i,
    output tl_pkg::B_chan_bits_t            inp_B_bits_o,
    // C channel
    input  logic                            inp_C_valid_i,
    output logic                            inp_C_ready_o,
    input  tl_pkg::C_chan_bits_t            inp_C_bits_i,
    // D channel
    output logic                            inp_D_valid_o,
    input  logic                            inp_D_ready_i,
    output tl_pkg::D_chan_bits_t            inp_D_bits_o,           
    // E channel
    input  logic                            inp_E_valid_i,
    output logic                            inp_E_ready_o,
    input  tl_pkg::E_chan_bits_t            inp_E_bits_i,
    // =====================================
    // [to next level memory]
    output logic                            oup_A_valid_o,
    input  logic                            oup_A_ready_i,
    output tl_pkg::A_chan_bits_t            oup_A_bits_o,

    input  logic                            oup_D_valid_i,
    output logic                            oup_D_ready_o,
    input  tl_pkg::D_chan_bits_t            oup_D_bits_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam logic [SINK_ID_WTH+SINK_LSB-1:0] SINK = {SINK_ID,{SINK_LSB{1'b0}}};

    typedef enum logic[1:0] {IDLE, PROBE, WAIT_PROBE_DONE, WAIT_E} state_e;
    state_e state_d, state_q;

    typedef enum logic[1:0]{
        PASS    = 0,
        DROP    = 1, 
        TRANS_B = 2,
        TRANS_T = 3
    } id_trans_e;
    localparam LEN = (HART_NUM==1) ? 2 : 2 ** $clog2(HART_NUM);

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic [HART_NUM-1:0]                            probe_todo_d, probe_todo_q;
    logic [HART_ID_WTH-1:0]                         probe_hart;
    logic [HART_NUM-1:0]                            req_hart_d, req_hart_q;
    logic                                           probe_busy;
    logic [ADDR_WTH-1:0]                            probe_addr_d, probe_addr_q;
    tl_pkg::TL_Permissions_Cap                      probe_perm;             
    tl_pkg::TL_Permissions_Cap                      acquire_perm;             
    logic [HART_ID_WTH-1:0]                         probe_cnt_d, probe_cnt_q;
    logic                                           probe_done;
    logic                                           core_set;
    logic                                           dma_set;
    logic                                           probeAck_done;    
    logic                                           probeAckData_done;    
    logic [2:0]                                     A_opcode_d, A_opcode_q;        
    tl_pkg::A_chan_param_t                          A_param_d, A_param_q;        
    tl_pkg::source_t                                A_source_d, A_source_q;
    tl_pkg::address_t                               A_address_d,A_address_q;
    tl_pkg::size_t                                  A_size_d,A_size_q;
    logic                                           is_acquire;

    logic                                           is_ProbeAck;
    logic                                           is_ProbeAckData;
    logic                                           is_release;
    logic                                           is_releaseData;

    logic                                           putfull_valid;
    logic                                           putfull_ready;
    tl_pkg::A_chan_bits_t                           putfull_bits;            

    logic                                           tracker_valid;
    logic                                           tracker_ready;
    tl_pkg::A_chan_bits_t                           tracker_bits;            

    logic                                           releaseAck_valid;
    logic                                           releaseAck_ready;
    tl_pkg::D_chan_bits_t                           releaseAck_bits;

    logic [1:0]                                     arbiter_A_valid;
    logic [1:0]                                     arbiter_A_ready;
    tl_pkg::A_chan_bits_t [1:0]                     arbiter_A_bits;

    logic [1:0]                                     arbiter_D_valid;
    logic [1:0]                                     arbiter_D_ready;
    tl_pkg::D_chan_bits_t [1:0]                     arbiter_D_bits;

    logic [7:0]                                     cnt_d, cnt_q; // use to count transaction
    logic                                           who_use_A_d, who_use_A_q; // 0 for putfull and 1 for tracker
    logic                                           transaction_done;
    logic                                           transaction_busy;
    logic [7:0]                                     cnt2_d, cnt2_q; // use to count transaction
    logic [7:0]                                     cnt3_d, cnt3_q; 
    logic                                           who_use_D_d, who_use_D_q; // 0 for ReleaseAck and 1 for d_normal
    logic                                           transaction_done2;
    logic                                           transaction_busy2;
    id_trans_e                                      put_what;   
    logic [HART_ID_WTH+HART_ID_LSB-1:0]             put_who;
    id_trans_e                                      transform;
    id_trans_e                                      get_what;
    logic [HART_ID_WTH+HART_ID_LSB-1:0]             get_who;
    logic                                           is_drop;
    logic                                           has_data;
    logic                                           d_normal_valid;
    logic                                           d_normal_ready;
    tl_pkg::D_chan_bits_t                           d_normal_bits;
    logic [HART_ID_WTH-1:0]                         req_hart_idx;

//======================================================================================================================
// Release and ProbeAck
//======================================================================================================================
    assign is_release       = inp_C_bits_i.opcode == tl_pkg::Release;
    assign is_releaseData   = inp_C_bits_i.opcode == tl_pkg::ReleaseData;
    assign is_ProbeAck      = inp_C_bits_i.opcode == tl_pkg::ProbeAck;
    assign is_ProbeAckData  = inp_C_bits_i.opcode == tl_pkg::ProbeAckData;

    assign probeAck_done = inp_C_valid_i && inp_C_ready_o && is_ProbeAck; // finish one probe 

    // write data to next level memory
    assign put_what = is_releaseData ? TRANS_B : DROP;
    assign put_who  = inp_C_bits_i.source[HART_ID_WTH+HART_ID_LSB-1:0];

    assign putfull_valid = inp_C_valid_i && (is_releaseData || is_ProbeAckData); 
    assign putfull_bits.opcode              = tl_pkg::PutFullData;
    assign putfull_bits.param.permission    = tl_pkg::NtoB; // param is not use, so give it default value
    assign putfull_bits.size                = inp_C_bits_i.size;  
    assign putfull_bits.source              = {put_what,put_who}; 
    assign putfull_bits.address             = inp_C_bits_i.address;
    assign putfull_bits.mask                = 8'hFF;
    assign putfull_bits.data                = inp_C_bits_i.data;
    assign putfull_bits.corrupt             = inp_C_bits_i.corrupt;

    // if is ProbeAck, we always accept it and because we don't need to do anything; 
    // if is release, we need to wait D channel ready. (Notice: xbar must have at least one level buffer)
    // if need to write data, must wait putfull ready asserted
    assign inp_C_ready_o = is_ProbeAck || (is_release ? releaseAck_ready : putfull_ready);

    assign releaseAck_valid = is_release && inp_C_valid_i;
    assign releaseAck_bits.opcode              = tl_pkg::ReleaseAck;
    assign releaseAck_bits.param.permission    = tl_pkg::toN; // param is not use, so give it default value
    assign releaseAck_bits.size                = 1'b0;  
    assign releaseAck_bits.source              = inp_C_bits_i.source; 
    assign releaseAck_bits.sink                = '0;
    assign releaseAck_bits.denied              = '0;
    assign releaseAck_bits.data                = '0;
    assign releaseAck_bits.corrupt             = '0;

//======================================================================================================================
// through A channel to send Get or Put request to next level memory
//======================================================================================================================
    always_comb begin
        cnt_d = cnt_q;
        who_use_A_d = who_use_A_q;
        if (transaction_busy) begin
            if (who_use_A_q) begin // tracker
                cnt_d = (tracker_valid && tracker_ready) ? cnt_q - 1'b1 : cnt_q;    
            end else begin      // putfull
                cnt_d = (putfull_valid && putfull_ready) ? cnt_q - 1'b1 : cnt_q;                   
            end
        end else begin    // not busy
            if (tracker_valid && tracker_ready) begin
                cnt_d = (tracker_bits.opcode == tl_pkg::Get) ? '0 : tracker_bits.size;
                who_use_A_d = 1; 
            end else if (putfull_valid && putfull_ready) begin
                cnt_d = putfull_bits.size; 
                who_use_A_d = 0;
            end
        end
    end
    assign transaction_busy = (cnt_q != '0);

    assign arbiter_A_valid = !transaction_busy ? {tracker_valid,putfull_valid} : 
                             {tracker_valid && who_use_A_q, putfull_valid && !who_use_A_q};
    assign arbiter_A_bits[0] = putfull_bits;
    assign arbiter_A_bits[1] = tracker_bits;
    assign putfull_ready = arbiter_A_ready[0] && arbiter_A_valid[0];
    assign tracker_ready = arbiter_A_ready[1] && arbiter_A_valid[1];
    tl_arbiter #(
        .N_MASTER   (2),
        .DATA_T     (tl_pkg::A_chan_bits_t)
    ) A_channel_arbiter (
        .clk_i                       (clk_i),
        .rst_i                       (rst_i),

        .inp_data_i                  (arbiter_A_bits),
        .inp_valid_i                 (arbiter_A_valid),
        .inp_ready_o                 (arbiter_A_ready),

        .oup_data_o                  (oup_A_bits_o),
        .oup_valid_o                 (oup_A_valid_o),
        .oup_ready_i                 (oup_A_ready_i)
    );
//======================================================================================================================
// Return message from next level memory
//======================================================================================================================
    // there are servel situations that next level will return message through D channel
    // 1. ProbeAckData  --> Drop
    // 2. ReleaseData   --> ReleaseAck
    // 3. AcquirePerm   --> Grant
    // 4. AcquireBlock  --> GrantData
    // 5. Get           --> AccessAckData
    // we use source id to identify different situation
    assign get_what = id_trans_e'(oup_D_bits_i.source[HART_ID_WTH+HART_ID_LSB+:2]);
    assign get_who  = oup_D_bits_i.source[HART_ID_WTH+HART_ID_LSB-1:0];

    assign probeAckData_done = oup_D_valid_i && oup_D_ready_o && is_drop;  

    assign is_drop = (get_what == DROP);
    assign has_data = (oup_D_bits_i.opcode == tl_pkg::AccessAckData);
    assign oup_D_ready_o = is_drop || d_normal_ready; 
    assign d_normal_valid = oup_D_valid_i && !is_drop;

    always_comb begin : gen_opcode_and_param
        d_normal_bits.opcode = oup_D_bits_i.opcode; // PASS
        d_normal_bits.param  = oup_D_bits_i.param;
        d_normal_bits.size   = oup_D_bits_i.size;
        if (get_what == TRANS_B) begin
            d_normal_bits.opcode = has_data ? tl_pkg::GrantData : tl_pkg::ReleaseAck;
            d_normal_bits.param  = has_data ? tl_pkg::toB : tl_pkg::toN;
            d_normal_bits.size   = has_data ? oup_D_bits_i.size : 1'b0;
        end else if (get_what == TRANS_T) begin
            d_normal_bits.opcode = tl_pkg::GrantData;
            d_normal_bits.param  = has_data ? tl_pkg::toT : tl_pkg::toN;
            d_normal_bits.size   = has_data ? oup_D_bits_i.size : 1'b0;
        end
    end
    assign d_normal_bits.source = get_who;
    assign d_normal_bits.sink = SINK; 
    assign d_normal_bits.denied = oup_D_bits_i.denied;
    assign d_normal_bits.data = oup_D_bits_i.data;
    assign d_normal_bits.corrupt = oup_D_bits_i.corrupt;
//======================================================================================================================
// Return message to hart
//======================================================================================================================
    always_comb begin
        cnt2_d      = cnt2_q;
        who_use_D_d = who_use_D_q;
        if (transaction_busy2) begin
            if (who_use_D_q) begin // releaseAck
                cnt2_d = (releaseAck_valid && releaseAck_ready) ? cnt2_q - 1'b1 : cnt2_q;    
            end else begin      // putfull
                cnt2_d = (d_normal_valid && d_normal_ready) ? cnt2_q - 1'b1 : cnt2_q;                   
            end
        end else begin    // not busy
            if (releaseAck_valid && releaseAck_ready) begin
                cnt2_d = releaseAck_bits.size;
                who_use_D_d = 1'b1; 
            end else if (d_normal_valid && d_normal_ready) begin
                cnt2_d = d_normal_bits.size; 
                who_use_D_d = 1'b0;
            end
        end
    end
    assign transaction_busy2 = (cnt2_q != '0);

    assign arbiter_D_valid = !transaction_busy2 ? {releaseAck_valid, d_normal_valid} : 
                             {releaseAck_valid && who_use_D_q, d_normal_valid && !who_use_D_q};
    assign arbiter_D_bits[0] = d_normal_bits;
    assign arbiter_D_bits[1] = releaseAck_bits;
    assign d_normal_ready    = arbiter_D_ready[0] && arbiter_D_valid[0];
    assign releaseAck_ready  = arbiter_D_ready[1] && arbiter_D_valid[1];
    tl_arbiter #(
        .N_MASTER   (2),
        .DATA_T     (tl_pkg::D_chan_bits_t)
    ) D_channel_arbiter (
        .clk_i                       (clk_i),
        .rst_i                       (rst_i),

        .inp_data_i                  (arbiter_D_bits),
        .inp_valid_i                 (arbiter_D_valid),
        .inp_ready_o                 (arbiter_D_ready),

        .oup_data_o                  (inp_D_bits_o),
        .oup_valid_o                 (inp_D_valid_o),
        .oup_ready_i                 (inp_D_ready_i)
    );

//======================================================================================================================
// Probe 
//======================================================================================================================
    assign req_hart_idx = inp_A_bits_i.source[HART_ID_LSB+:HART_ID_WTH];
    lzc #(
      .WIDTH    (LEN),
      .MODE     (1'b0) // 0 -> trailing zero, 1 -> leading zero
    ) gen_probe_hart(
        .in_i       (probe_todo_q),
        .cnt_o      (probe_hart),
        .empty_o    ()
    );
    assign probe_busy = |probe_todo_q;
    always_comb begin
        cnt3_d = cnt3_q;
        if (core_set) begin
            cnt3_d = HART_NUM - 1;
        end else if (dma_set) begin
            cnt3_d = HART_NUM;   
        end else if (probeAck_done || probeAckData_done) begin
            cnt3_d = cnt3_q - 1; 
        end 
    end
    assign probe_done = (cnt3_q == '0);

    assign inp_B_bits_o.opcode  = tl_pkg::Probe;
    assign inp_B_bits_o.param   = probe_perm;         
    assign inp_B_bits_o.size    = 1'b0;
    assign inp_B_bits_o.source  = {probe_hart, 1'b1}; // only probe dcache
    assign inp_B_bits_o.address = A_address_q;        
    assign inp_B_bits_o.mask    = '0;
    assign inp_B_bits_o.data    = '0;
    assign inp_B_bits_o.corrupt = '0;

    // generate probe permission
    always_comb begin
        acquire_perm = tl_pkg::toT;
        case (A_param_q.permission)
            tl_pkg::NtoB : acquire_perm  = tl_pkg::toB; 
            tl_pkg::NtoT : acquire_perm  = tl_pkg::toN; 
            tl_pkg::BtoT : acquire_perm  = tl_pkg::toN; 
            default      : acquire_perm  = tl_pkg::toT; 
        endcase
    end

    always_comb begin 
        probe_perm = tl_pkg::toN;
        case (A_opcode_q)
            tl_pkg::PutFullData   : probe_perm = tl_pkg::toN;     
            tl_pkg::PutPartialData: probe_perm = tl_pkg::toN;     
            tl_pkg::ArithmeticData: probe_perm = tl_pkg::toN;     
            tl_pkg::LogicalData   : probe_perm = tl_pkg::toN;     
            tl_pkg::Get           : probe_perm = tl_pkg::toB;     
            tl_pkg::Hint          : probe_perm = tl_pkg::toN;     
            tl_pkg::AcquireBlock  : probe_perm = acquire_perm;    
            tl_pkg::AcquirePerm   : probe_perm = acquire_perm;    
            default               : probe_perm = tl_pkg::toN;      
        endcase
    end
//======================================================================================================================
// tracker
//======================================================================================================================
    // save parameters from A channel
    assign A_opcode_d           = (inp_A_valid_i && inp_A_ready_o) ? inp_A_bits_i.opcode : A_opcode_q;        
    assign A_param_d            = (inp_A_valid_i && inp_A_ready_o) ? inp_A_bits_i.param  : A_param_q;        
    assign A_source_d           = (inp_A_valid_i && inp_A_ready_o) ? inp_A_bits_i.source : A_source_q;
    assign A_address_d          = (inp_A_valid_i && inp_A_ready_o) ? inp_A_bits_i.address: A_address_q;
    assign A_size_d             = (inp_A_valid_i && inp_A_ready_o) ? inp_A_bits_i.size   : A_size_q;


    assign is_acquire = (A_opcode_q == tl_pkg::AcquireBlock) || (A_opcode_q == tl_pkg::AcquirePerm);
    always_comb begin
        transform = PASS;
        if (is_acquire) begin
            case (A_param_q.permission) 
                tl_pkg::NtoB  : transform = TRANS_B; 
                tl_pkg::NtoT  : transform = TRANS_T; 
                tl_pkg::BtoT  : transform = TRANS_T; 
                default       : transform = TRANS_B; 
            endcase
        end
    end
    // this version only support acquire and get from hart 
    assign tracker_bits.opcode              = tl_pkg::Get;
    assign tracker_bits.param               = A_param_q; 
    assign tracker_bits.size                = A_size_q;  
    assign tracker_bits.source              = {transform, A_source_q[HART_ID_WTH+HART_ID_LSB-1:0]}; 
    assign tracker_bits.address             = A_address_q;
    assign tracker_bits.mask                = 8'hff;
    assign tracker_bits.data                = '0;
    assign tracker_bits.corrupt             = '0;
//======================================================================================================================
// FSM to control probe
//======================================================================================================================
    // we always accept E channel
    assign inp_E_ready_o = 1'b1;
    always_comb begin : fsm
        // default assignment
        state_d         = state_q;
        inp_A_ready_o   = 1'b0;
        req_hart_d      = req_hart_q;
        probe_todo_d    = probe_todo_q;
        core_set = 1'b0;
        dma_set = 1'b0;
        tracker_valid   = 1'b0;
        inp_B_valid_o   = 1'b0;

        unique case (state_q)
            IDLE: begin
                inp_A_ready_o = 1'b1;
                if (inp_A_valid_i) begin
                    req_hart_d = {HART_NUM{1'b1}};   
                    if (req_hart_idx < HART_NUM) begin  // dma request if req_hart_idx >= HART_NUM
                        req_hart_d[req_hart_idx] = 1'b0; // don't probe hart which request
                        core_set = 1'b1;
                    end else begin
                        dma_set = 1'b1;
                    end
                    probe_todo_d = req_hart_d;
                    state_d = PROBE;
                end
            end
            PROBE: begin
                if (!is_acquire) begin      // if I cache send request
                    state_d = WAIT_PROBE_DONE;
                end else if (!probe_busy) begin
                    state_d = WAIT_PROBE_DONE;
                end else begin
                    inp_B_valid_o = 1'b1;
                    if (inp_B_ready_i) begin
                        probe_todo_d[probe_hart] = 1'b0; 
                    end
                end
            end
            // send request to next level memory
            // Only support Get request
            WAIT_PROBE_DONE: begin
                if (probe_done || !is_acquire) begin
                    tracker_valid = 1'b1;
                    if (tracker_ready) begin
                        if (is_acquire) begin
                            state_d = WAIT_E; 
                        end else begin
                            state_d = IDLE;
                        end
                    end
                end
            end
            WAIT_E: begin
                if (inp_E_valid_i) begin
                    state_d = IDLE;
                end
            end
            default : state_d = IDLE;
        endcase
    end
//======================================================================================================================
// Register
//======================================================================================================================
    always_ff @(posedge clk_i or negedge rst_i) begin : p_regs
        if(!rst_i) begin
            state_q             <= IDLE;
            probe_todo_q        <= '0;
            req_hart_q          <= '0;
            probe_addr_q        <= '0;
            probe_cnt_q         <= '0;
            A_opcode_q          <= '0;        
            A_param_q           <= tl_pkg::A_chan_param_t'('0);        
            A_source_q          <= tl_pkg::source_t'('0);
            A_address_q         <= tl_pkg::address_t'('0);
            A_size_q            <= tl_pkg::size_t'('0);
            cnt_q               <= '0; 
            who_use_A_q         <= '0; 
            cnt2_q              <= '0; 
            cnt3_q              <= '0; 
            who_use_D_q         <= '0; 
        end else begin
            state_q             <= state_d;
            probe_todo_q        <= probe_todo_d;
            req_hart_q          <= req_hart_d;
            probe_addr_q        <= probe_addr_d;
            probe_cnt_q         <= probe_cnt_d;
            A_opcode_q          <= A_opcode_d;        
            A_param_q           <= A_param_d;        
            A_source_q          <= A_source_d;
            A_address_q         <= A_address_d;
            A_size_q            <= A_size_d;
            cnt_q               <= cnt_d; 
            who_use_A_q         <= who_use_A_d; 
            cnt2_q              <= cnt2_d; 
            cnt3_q              <= cnt3_d; 
            who_use_D_q         <= who_use_D_d; 
        end
    end


endmodule
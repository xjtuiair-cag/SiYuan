// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_fft_iq.v
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

module sy_fft_iq
    import fft_pkg::*;
(
    // =====================================
    // [clock & reset]
    // -- <clock>
    input   logic                           clk_i,                      
    input   logic                           rst_i,                      
    input   logic                           flush_i,
    // to ctrl module
    output  logic                           buf_ptr_o,
    output  logic                           wt_buf_ptr_o,
    output  logic                           bank_ptr_o,
    output  logic [IQ_WTH+1:0]              iq_status_o,
    
    input   logic                           lsu_iq__awake_en_i,
    input   logic                           lsu_iq__awake_rs2_en_i,
    input   logic                           lsu_iq__awake_rs1_idx_i,
    input   logic                           lsu_iq__awake_rs2_idx_i,
    input   logic [7:0]                     lsu_iq__awake_instr_idx_i,
    input   logic                           exe_iq__awake_en_i,
    input   logic                           exe_iq__awake_rs1_idx_i,
    input   logic                           exe_iq__awake_rs2_idx_i,
    input   logic [7:0]                     exe_iq__awake_instr_idx_i,
    // =====================================
    // [From decode]
    input   logic                           ctrl_iq__vld_i,          
    output  logic                           iq_ctrl__rdy_o,          
    input   iq_data_t                       ctrl_iq__data_i,
    // =====================================
    // [Issue]
    output  logic                           iq_lsu__vld_o,
    input   logic                           lsu_iq__rdy_i,
    output  lsu_data_t                      iq_lsu__data_o,

    output  logic                           iq_exe__vld_o,
    input   logic                           exe_iq__rdy_i,
    output  exe_data_t                      iq_exe__data_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    typedef struct packed {
        logic                       rs1_depend;
        logic[7:0]                  rs1_depend_idx;        
        logic                       rs2_depend;
        logic[7:0]                  rs2_depend_idx;        
    } depend_t;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    iq_data_t[IQ_LEN-1:0]                   iq_data_d,iq_data_q;
    depend_t[IQ_LEN-1:0]                    depend_d,depend_q;      
    depend_t                                depend_check;
    logic[IQ_WTH:0]                         ins_idx_d, ins_idx_q;
    logic                                   ins_en;               
    logic                                   del_en;   
    logic[IQ_WTH:0]                         cnt_d, cnt_q;        
    logic                                   iq_is_full;
    logic                                   iq_is_empty;   
    logic                                   sel_act;        
    logic[IQ_WTH-1:0]                       sel_idx;        

    logic[IQ_LEN-1:0]                       func_unit_rdy;   
    logic[IQ_LEN-1:0]                       buf_rdy; 

    logic                                   buf_ptr_d, buf_ptr_q;
    logic                                   wt_buf_ptr_d, wt_buf_ptr_q;
    logic[1:0]                              bank_ptr_d, bank_ptr_q;
    logic[1:0]                              buf_state_d,buf_state_q;                                
    logic[1:0]                              wt_buf_state_d,wt_buf_state_q; 
    logic                                   del_fence;
//======================================================================================================================
// Issue Queue
//======================================================================================================================
    assign iq_is_full = (cnt_q == IQ_LEN);
    assign iq_is_empty = (cnt_q == 0);
    assign iq_ctrl__rdy_o = ~iq_is_full;
    assign ins_en = ctrl_iq__vld_i && iq_ctrl__rdy_o;

    assign iq_status_o = {cnt_q,iq_is_empty,iq_is_full};
    always_comb begin : iq_gen
        for (integer i=0; i<IQ_LEN; i=i+1) begin
            iq_data_d[i] = iq_data_q[i];
            if (del_en) begin
                if (i >= sel_idx && i < (ins_idx_q - 1) && i < (IQ_LEN - 1)) begin
                    iq_data_d[i] = iq_data_q[i+1];  // make IQ compressed
                end else if (i == (ins_idx_q - 1) && ins_en)begin
                    iq_data_d[i] = ctrl_iq__data_i;   
                end
            end else begin
                if (i == ins_idx_q && ins_en) begin
                    iq_data_d[i] = ctrl_iq__data_i; // insert new instr
                end              
            end
       end 
    end
    // check dependency
    always_comb begin
        depend_check = '0;
        for (integer i=0;i<IQ_LEN; i=i+1) begin
            if (ctrl_iq__vld_i && iq_ctrl__rdy_o && (i < ins_idx_q) ) begin
                // RS1
                // RAW
                if (ctrl_iq__data_i.rs1_vld && iq_data_q[i].rdst_vld && (iq_data_q[i].rdst_idx == ctrl_iq__data_i.rs1_idx) && !iq_data_q[i].load_wt) begin
                    depend_check.rs1_depend = 1'b1;
                    depend_check.rs1_depend_idx = iq_data_q[i].instr_idx;
                // WAR
                end else if (ctrl_iq__data_i.rdst_vld && iq_data_q[i].rs1_vld && (iq_data_q[i].rs1_idx == ctrl_iq__data_i.rdst_idx) && !ctrl_iq__data_i.load_wt) begin
                    depend_check.rs1_depend = 1'b1;
                    depend_check.rs1_depend_idx = iq_data_q[i].instr_idx;
                // WAW
                end else if (ctrl_iq__data_i.rdst_vld && iq_data_q[i].rdst_vld && (iq_data_q[i].rdst_idx == ctrl_iq__data_i.rdst_idx) && !iq_data_q[i].load_wt && !ctrl_iq__data_i.load_wt) begin
                    depend_check.rs1_depend = 1'b1;
                    depend_check.rs1_depend_idx = iq_data_q[i].instr_idx;
                end
                // RS2 
                // RAW
                if (ctrl_iq__data_i.rs2_vld && iq_data_q[i].rdst_vld && (iq_data_q[i].rdst_idx == ctrl_iq__data_i.rs2_idx) && iq_data_q[i].load_wt) begin
                    depend_check.rs2_depend = 1'b1;
                    depend_check.rs2_depend_idx = iq_data_q[i].instr_idx;
                // WAR
                end else if (ctrl_iq__data_i.rdst_vld && iq_data_q[i].rs2_vld && (iq_data_q[i].rs2_idx == ctrl_iq__data_i.rdst_idx) && ctrl_iq__data_i.load_wt) begin
                    depend_check.rs2_depend = 1'b1;
                    depend_check.rs2_depend_idx = iq_data_q[i].instr_idx;
                // WAW
                end else if (ctrl_iq__data_i.rdst_vld && iq_data_q[i].rdst_vld && (iq_data_q[i].rdst_idx == ctrl_iq__data_i.rdst_idx) && ctrl_iq__data_i.load_wt && iq_data_q[i].load_wt) begin
                    depend_check.rs2_depend = 1'b1;
                    depend_check.rs2_depend_idx = iq_data_q[i].instr_idx;
                end
           end
        end  
    end
    // dependency release
    always_comb begin 
        for (integer i=0; i<IQ_LEN; i=i+1) begin
            // awake
            if (i == ins_idx_q && ins_en) begin
                depend_d[i] = depend_check;
            end else begin
                depend_d[i] = depend_q[i];
                // RS1
                if (lsu_iq__awake_en_i && lsu_iq__awake_instr_idx_i == depend_q[i].rs1_depend_idx || 
                    exe_iq__awake_en_i && exe_iq__awake_instr_idx_i == depend_q[i].rs1_depend_idx 
                ) begin
                    depend_d[i].rs1_depend = 1'b0;        
                end                   
                // RS2
                if (lsu_iq__awake_en_i && lsu_iq__awake_instr_idx_i == depend_q[i].rs2_depend_idx || 
                    exe_iq__awake_en_i && exe_iq__awake_instr_idx_i == depend_q[i].rs2_depend_idx 
               ) begin
                    depend_d[i].rs2_depend = 1'b0;        
                end
            end
        end 
    end
    always_comb begin : ins_idx
        ins_idx_d = ins_idx_q;
        cnt_d = cnt_q;
        if (flush_i) begin
            ins_idx_d = '0;
            cnt_d = '0;
        end else if (del_en && ins_en) begin  // don't change
            ins_idx_d = ins_idx_q;
            cnt_d = cnt_q;
        end else if (del_en) begin     // -1
            ins_idx_d = ins_idx_q - 1;
            cnt_d = cnt_q - 1;
        end else if (ins_en) begin
            ins_idx_d = ins_idx_q + 1; // +1
            cnt_d = cnt_q + 1;
        end 
    end
//======================================================================================================================
// Select an instr
//======================================================================================================================
    // lookup issue queue to see whether there is dependency between two instr
    // always_comb begin
    //     depend_check = '0;
    //     for (integer i=0;i<IQ_LEN; i=i+1) begin
    //         if (ctrl_iq__vld_i && iq_ctrl__rdy_o && (i < ins_idx_q) &&
    //         // normal dependency
    //         (iq_data_q[i].op != FENCE && !iq_data_q[i].load_wt && (iq_data_q[i].buf_idx == ctrl_iq__data_i.buf_idx) ||
    //         // load wt dependency with exe instr
    //         iq_data_q[i].op == EXE && ctrl_iq__data_i.op == LOAD && iq_data_q[i].load_wt ||
    //         iq_data_q[i].op == LOAD && iq_data_q[i].load_wt && ctrl_iq__data_i.op == EXE
    //         )) begin
    //             depend_check.has_depend = 1'b1;
    //             depend_check.depend_idx = iq_data_q[i].instr_idx;
    //         end   
    //     end  
    // end

    // check if func unit is ready
    always_comb begin
        func_unit_rdy = '0;
        for (integer i=0; i<IQ_LEN; i=i+1) begin
            if (iq_data_q[i].op == LOAD || iq_data_q[i].op == STORE) begin
                func_unit_rdy[i] = lsu_iq__rdy_i;
            end else if (iq_data_q[i].op == EXE)begin
                func_unit_rdy[i] = exe_iq__rdy_i;
            end else if (iq_data_q[i].op == FENCE) begin
                // fence instr retire need all func unit ready
                func_unit_rdy[i] = lsu_iq__rdy_i && exe_iq__rdy_i;
            end
        end
    end

    // check if buf is ready
    always_comb begin
        buf_rdy = '0;
        for (integer i=0; i<IQ_LEN; i=i+1) begin
            if (iq_data_q[i].op == FENCE) begin
                buf_rdy[i] = 1'b1;
            end else if (iq_data_q[i].op == LOAD && iq_data_q[i].load_wt) begin
                buf_rdy[i] = wt_buf_state_q[iq_data_q[i].rdst_idx];
            end else if (iq_data_q[i].op == LOAD && !iq_data_q[i].load_wt) begin
                buf_rdy[i] = buf_state_q[iq_data_q[i].rdst_idx];
            end else if (iq_data_q[i].op == EXE) begin
                buf_rdy[i] = buf_state_q[iq_data_q[i].rs1_idx] && wt_buf_state_q[iq_data_q[i].rs2_idx];
            end else if (iq_data_q[i].op == STORE) begin
                buf_rdy[i] = buf_state_q[iq_data_q[i].rs1_idx];
            end
        end
    end

    // select an instr to issue
    always_comb begin
        sel_act = 1'b0;
        sel_idx = '0;
        for (integer i=IQ_LEN-1; i>=0; i=i-1) begin
            if ((i < ins_idx_q) && !iq_is_empty && func_unit_rdy[i] && buf_rdy[i] && !depend_q[i].rs1_depend && !depend_q[i].rs2_depend) begin
                sel_act = 1'b1;
                sel_idx = i;
            end
            // fence 
            if ((i < ins_idx_q) && (i != 0) && !iq_is_empty && iq_data_q[i].op == FENCE) begin
                sel_act = 1'b0;
            end
        end
    end

    // Issue
    assign iq_lsu__vld_o    = sel_act && (iq_data_q[sel_idx].op == LOAD || iq_data_q[sel_idx].op == STORE);
    // data to lsu
    assign iq_lsu__data_o.is_load   = iq_data_q[sel_idx].op == LOAD;
    assign iq_lsu__data_o.load_wt   = iq_data_q[sel_idx].load_wt;
    assign iq_lsu__data_o.tot_level = iq_data_q[sel_idx].tot_level;
    assign iq_lsu__data_o.len       =(iq_data_q[sel_idx].tot_level > 10) ? MAX_LEN : (1'b1 << iq_data_q[sel_idx].tot_level);
    assign iq_lsu__data_o.buf_idx   = iq_data_q[sel_idx].rs1_idx;
    assign iq_lsu__data_o.wt_buf_idx= iq_data_q[sel_idx].rs2_idx;
    assign iq_lsu__data_o.bank_idx  = iq_data_q[sel_idx].bank_idx;
    assign iq_lsu__data_o.base_addr = iq_data_q[sel_idx].addr;
    assign iq_lsu__data_o.reverse_base = iq_data_q[sel_idx].reverse_base;
    assign iq_lsu__data_o.rd_ocm_addr = iq_data_q[sel_idx].rd_ocm_addr;
    assign iq_lsu__data_o.wr_ocm_addr = iq_data_q[sel_idx].wr_ocm_addr;
    assign iq_lsu__data_o.stride    = iq_data_q[sel_idx].stride;
    assign iq_lsu__data_o.mode      = iq_data_q[sel_idx].mode;
    assign iq_lsu__data_o.instr_idx = iq_data_q[sel_idx].instr_idx;

    assign iq_exe__vld_o    = sel_act && (iq_data_q[sel_idx].op == EXE);
    // data to exe unit
    assign iq_exe__data_o.cur_level = iq_data_q[sel_idx].cur_level >= 10 ? 9 : iq_data_q[sel_idx].cur_level;
    assign iq_exe__data_o.tot_level = iq_data_q[sel_idx].tot_level;
    assign iq_exe__data_o.len       =(iq_data_q[sel_idx].tot_level > 10) ? MAX_LEN : (1'b1 << iq_data_q[sel_idx].tot_level);
    assign iq_exe__data_o.mode      = iq_data_q[sel_idx].mode;
    assign iq_exe__data_o.buf_idx   = iq_data_q[sel_idx].rs1_idx;
    assign iq_exe__data_o.wt_buf_idx= iq_data_q[sel_idx].rs2_idx;
    assign iq_exe__data_o.bank_idx  = iq_data_q[sel_idx].bank_idx;
    assign iq_exe__data_o.rd_ocm_addr = iq_data_q[sel_idx].rd_ocm_addr;
    assign iq_exe__data_o.wr_ocm_addr = iq_data_q[sel_idx].wr_ocm_addr;
    assign iq_exe__data_o.instr_idx = iq_data_q[sel_idx].instr_idx;
    assign iq_exe__data_o.beyond_max_level = iq_data_q[sel_idx].cur_level >= 10;

    assign del_fence = sel_act && (iq_data_q[sel_idx].op == FENCE);
    assign del_en = iq_lsu__vld_o && lsu_iq__rdy_i || iq_exe__vld_o && exe_iq__rdy_i || del_fence;

    always_comb begin
        buf_ptr_d  = buf_ptr_q;
        wt_buf_ptr_d = wt_buf_ptr_q;
        bank_ptr_d = bank_ptr_q;
        buf_state_d = buf_state_q; // buf state (1 : ready, 0 : busy)
        wt_buf_state_d = wt_buf_state_q;
        // switch buf pointer when lds are coming
        if (ctrl_iq__vld_i && iq_ctrl__rdy_o && ctrl_iq__data_i.op == LOAD && ctrl_iq__data_i.is_lds) begin
            buf_ptr_d = ctrl_iq__data_i.load_wt ? buf_ptr_q : ~buf_ptr_q;
            wt_buf_ptr_d = ctrl_iq__data_i.load_wt ? ~wt_buf_ptr_q : wt_buf_ptr_q;
            // buf_ptr_d = ~buf_ptr_q;
        end 
        // switch bank pointer when exe are coming
        if (ctrl_iq__vld_i && iq_ctrl__rdy_o && ctrl_iq__data_i.op == EXE) begin
            bank_ptr_d[buf_ptr_q] = ~bank_ptr_q[buf_ptr_q];
        end
        // set buf busy
        if (iq_lsu__vld_o && lsu_iq__rdy_i && !iq_lsu__data_o.load_wt) begin
            buf_state_d[iq_lsu__data_o.buf_idx] = 1'b0; 
        end else if (iq_lsu__vld_o && lsu_iq__rdy_i && iq_lsu__data_o.load_wt) begin
            wt_buf_state_d[iq_lsu__data_o.wt_buf_idx] = 1'b0; 
        end 

        if (iq_exe__vld_o && exe_iq__rdy_i) begin
            buf_state_d[iq_exe__data_o.buf_idx] = 1'b0;
            wt_buf_state_d[iq_exe__data_o.wt_buf_idx] = 1'b0;
        end

        // free buf 
        if (lsu_iq__awake_en_i && lsu_iq__awake_rs2_en_i) begin
            wt_buf_state_d[lsu_iq__awake_rs2_idx_i] = 1'b1;
        end else if (lsu_iq__awake_en_i) begin
            buf_state_d[lsu_iq__awake_rs1_idx_i] = 1'b1;
        end
        if (exe_iq__awake_en_i) begin
            buf_state_d[exe_iq__awake_rs1_idx_i] = 1'b1;
            wt_buf_state_d[exe_iq__awake_rs2_idx_i] = 1'b1;
        end
    end
    assign buf_ptr_o = buf_ptr_d;
    assign wt_buf_ptr_o = wt_buf_ptr_d;
    assign bank_ptr_o = bank_ptr_q[buf_ptr_o];
//======================================================================================================================
// Reigster
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0; i<IQ_LEN; i=i+1) begin
                iq_data_q[i] <= iq_data_t'(0);
            end
            ins_idx_q   <= '0;
            cnt_q       <= '0;
            buf_ptr_q   <= '0;
            wt_buf_ptr_q<= '0;
            bank_ptr_q  <= '0;
            buf_state_q <= 2'b11;
            wt_buf_state_q <= 2'b11;           
        end else begin
            for (integer i=0; i<IQ_LEN; i=i+1) begin
                iq_data_q[i] <= iq_data_d[i];
            end
            ins_idx_q   <= ins_idx_d;
            cnt_q       <= cnt_d;
            buf_ptr_q   <= buf_ptr_d;
            wt_buf_ptr_q<= wt_buf_ptr_d;
            bank_ptr_q  <= bank_ptr_d;
            buf_state_q <= buf_state_d;
            wt_buf_state_q <= wt_buf_state_d;
        end
    end
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i=0; i<IQ_LEN; i=i+1) begin
                depend_q[i] <= depend_t'(0);
            end
        end else begin
            for (integer i=0; i<IQ_LEN; i=i+1) begin
                if (i >= sel_idx && del_en && i < (IQ_LEN-1)) begin
                    depend_q[i] <= depend_d[i+1];
                end else begin
                    depend_q[i] <= depend_d[i];
                end
            end
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

// synopsys translate_off
// synopsys translate_on
endmodule 

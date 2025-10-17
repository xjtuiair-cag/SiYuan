// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_fft_exe.v
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

module sy_fft_exe
    import fft_pkg::*; 
#(
)(
    input   logic                               clk_i,           
    input   logic                               rst_i,           
    input   logic                               flush_i,
    // from issue queue
    input   logic                               iq_exe__vld_i,
    output  logic                               exe_iq__rdy_o,
    input   exe_data_t                          iq_exe__data_i,
    // free buf
    output  logic                               exe_iq__awake_en_o,
    output  logic                               exe_iq__awake_rs1_idx_o,
    output  logic                               exe_iq__awake_rs2_idx_o,
    output  logic[7:0]                          exe_iq__awake_instr_idx_o,
    // interface with lm
    output  logic                               exe_lm_rd_en_o,       // Read valid signal 
    output  logic[1:0][LM_ADDR_WTH-1:0]         exe_lm_rd_addr_o,     // Read address 
    input   logic[1:0][63:0]                    exe_lm_rd_data_i,     // Read data 

    output  logic                               exe_lm_wr_en_o,        // Write valid signal 
    output  logic[1:0][LM_ADDR_WTH-1:0]         exe_lm_wr_addr_o,      // Write address 
    output  logic[1:0][63:0]                    exe_lm_wr_data_o,      // Write data 
    // interface with wt
    output  logic                               exe_wt_rd_en_o,       // Read valid signal 
    output  logic[LM_ADDR_WTH-1:0]              exe_wt_rd_addr_o,     // Read address 
    input   logic[63:0]                         exe_wt_rd_data_i     // Read data 
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    typedef enum logic[1:0] {IDLE,CALC,WAIT_FINISH} state_e;
    state_e state_d,state_q;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                                   buf_idx_d,buf_idx_q;
    logic                                   bank_idx_d,bank_idx_q;
    logic                                   wt_buf_idx_d,wt_buf_idx_q;
    logic[LM_AWTH-1:0]                      rd_ocm_addr_d,rd_ocm_addr_q;
    logic[LM_AWTH-1:0]                      wr_ocm_addr_d,wr_ocm_addr_q;
    logic[10:0]                             len_d,len_q;                                     
    logic                                   mode_d,mode_q;
    logic[3:0]                              cur_level_d,cur_level_q;            
    logic[3:0]                              tot_level_d,tot_level_q; 
    logic[7:0]                              instr_idx_d,instr_idx_q;
    logic                                   beyond_max_level_d,beyond_max_level_q;
    logic                                   lm_rd_en_dly;
    logic                                   wt_rd_en_dly;
    logic[31:0]                             A_data_real;
    logic[31:0]                             A_data_img;
    logic[31:0]                             B_data_real;
    logic[31:0]                             B_data_img;
    logic[31:0]                             W_data_real;
    logic[31:0]                             W_data_img;
    logic                                   res_valid;
    logic[31:0]                             res_A_data_real;
    logic[31:0]                             res_A_data_img;
    logic[31:0]                             res_B_data_real;
    logic[31:0]                             res_B_data_img;
    logic[10:0]                             read_cnt_d,read_cnt_q;
    logic[10:0]                             finish_cnt_d,finish_cnt_q;
    logic[1:0][LM_AWTH-1:0]                 wr_lm_addr;              
    logic[1:0][LM_AWTH-1:0]                 linear_addr; 
    logic[1:0][15:0]                        reverse_addr; 
    logic[15:0]                             wt_cnt_d,wt_cnt_q;
    logic[15:0]                             wt_cnt_max;
    logic[9:0]                              wt_rd_stride;
    logic[LM_AWTH-1:0]                      wt_rd_addr_d,wt_rd_addr_q;
    logic                                   rd_data_cross_en_d,rd_data_cross_en_q;
    logic                                   rd_data_cross_en;
    logic[10:0]                             cross_cnt_d,cross_cnt_q;
    logic                                   cross_cnt_incr_en;
    logic [LM_AWTH-1:0]                     base_ocm_off_d,base_ocm_off_q;
    logic [9:0]                             wr_lm_cnt_d,wr_lm_cnt_q;
    logic                                   wr_lm_cross_cnt_d,wr_lm_cross_cnt_q;    
    logic                                   wr_lm_cross_en_d,wr_lm_cross_en_q;
    logic                                   base_ocm_addr_incr_en;  
    logic [3:0]                             true_tot_level;             
//======================================================================================================================
// Instance
//======================================================================================================================
    assign cross_cnt_incr_en = lm_rd_en_dly;
    always_comb begin
        cross_cnt_d = cross_cnt_q;
        rd_data_cross_en_d = rd_data_cross_en_q;
        if (iq_exe__vld_i && exe_iq__rdy_o) begin
            cross_cnt_d = '0;
            rd_data_cross_en_d = 1'b0;
        end else if ((cross_cnt_q == ((1'b1 << (cur_level_q - 1))-1) && cross_cnt_incr_en)) begin
            cross_cnt_d = '0;
            rd_data_cross_en_d = ~rd_data_cross_en_q;
        end else if (cross_cnt_incr_en) begin
            cross_cnt_d = cross_cnt_q + 1;
        end
    end
    assign rd_data_cross_en = (cur_level_q == '0 || beyond_max_level_q) ? 1'b0 : rd_data_cross_en_q;
    assign A_data_real = rd_data_cross_en ? exe_lm_rd_data_i[1][31:0]  : exe_lm_rd_data_i[0][31:0];
    assign A_data_img  = rd_data_cross_en ? exe_lm_rd_data_i[1][63:32] : exe_lm_rd_data_i[0][63:32];
    assign B_data_real = rd_data_cross_en ? exe_lm_rd_data_i[0][31:0]  : exe_lm_rd_data_i[1][31:0];
    assign B_data_img  = rd_data_cross_en ? exe_lm_rd_data_i[0][63:32] : exe_lm_rd_data_i[1][63:32];
    assign W_data_real = exe_wt_rd_data_i[31:0];
    assign W_data_img  = exe_wt_rd_data_i[63:32];

    always_ff @(`DFF_CR(clk_i,rst_i)) begin
        if (`DFF_IS_R(rst_i)) begin
            lm_rd_en_dly <= 1'b0;
            wt_rd_en_dly <= 1'b0;
        end else begin
            lm_rd_en_dly <= exe_lm_rd_en_o;
            wt_rd_en_dly <= exe_wt_rd_en_o;
        end
    end

    sy_fft_butfly butterfly_inst (
        .clk_i                  (clk_i),                   
        // operand A
        .A_valid                (lm_rd_en_dly),          
        .A_data_real            (A_data_real),              
        .A_data_img             (A_data_img),             
        // operand B
        .B_valid                (lm_rd_en_dly),          
        .B_data_real            (B_data_real),              
        .B_data_img             (B_data_img),             
        // Weight
        .W_valid                (wt_rd_en_dly),          
        .W_data_real            (W_data_real),              
        .W_data_img             (W_data_img),             
        // result
        .res_valid              (res_valid      ),            
        .res_A_data_real        (res_A_data_real),                  
        .res_A_data_img         (res_A_data_img ),                 
        .res_B_data_real        (res_B_data_real),                  
        .res_B_data_img         (res_B_data_img )
    );

    assign linear_addr[0] = finish_cnt_q[10:1];  
    assign linear_addr[1] = finish_cnt_q[10:1];  

    // // reverse addr
    // logic [15:0][3:0] index;
    // always_comb begin
    //     reverse_addr[0] = linear_addr[0];  // default value
    //     reverse_addr[1] = linear_addr[1];  // default value       
    //     index = '0;
    //     for (integer i = 0; i < 10; i = i + 1) begin
    //         index[i] = cur_level_q - i + 1; 
    //         if (i < (cur_level_q + 2)) begin
    //             reverse_addr[0][i] = linear_addr[0][index[i]];
    //             reverse_addr[1][i] = linear_addr[1][index[i]];
    //         end else begin
    //             reverse_addr[0][i] = linear_addr[0][i];
    //             reverse_addr[1][i] = linear_addr[1][i];
    //         end
    //     end
    // end

   // ocm base offset generation
    always_comb begin
        base_ocm_off_d = base_ocm_off_q;
        if (iq_exe__vld_i && exe_iq__rdy_o) begin
            base_ocm_off_d = '0;
        end else if (base_ocm_addr_incr_en) begin
            base_ocm_off_d = base_ocm_off_q + (1'b1 << (cur_level_q + 1));
        end
    end
    // counter
    always_comb begin
        wr_lm_cnt_d = wr_lm_cnt_q;
        wr_lm_cross_cnt_d = wr_lm_cross_cnt_q;
        wr_lm_cross_en_d = wr_lm_cross_en_q;
        base_ocm_addr_incr_en = 1'b0;
        if (iq_exe__vld_i && exe_iq__rdy_o) begin
            wr_lm_cnt_d = '0;
            wr_lm_cross_cnt_d = '0;
            wr_lm_cross_en_d = 1'b0;
        end else if (res_valid && (wr_lm_cnt_q == ((1'b1 << cur_level_q) - 1))) begin
            wr_lm_cnt_d = '0;
            wr_lm_cross_en_d = ~wr_lm_cross_en_q;
            if (wr_lm_cross_cnt_q == 1'b1) begin
                wr_lm_cross_cnt_d = '0;
                base_ocm_addr_incr_en = 1'b1;
            end else begin
                wr_lm_cross_cnt_d = wr_lm_cross_cnt_q + 1;
            end
        end else if (res_valid) begin
            wr_lm_cnt_d = wr_lm_cnt_q + 1;
        end
    end

    assign wr_lm_addr[0] = wr_ocm_addr_q + (mode_q ? linear_addr[0] : (base_ocm_off_q + wr_lm_cnt_q));
    assign wr_lm_addr[1] = wr_ocm_addr_q + (mode_q ? linear_addr[1] : (base_ocm_off_q + wr_lm_cnt_q + (1'b1 << cur_level_q)));

    // lm addr
    assign exe_lm_rd_addr_o[0] = {buf_idx_q,bank_idx_q,rd_ocm_addr_q,3'b0};
    assign exe_lm_rd_addr_o[1] = {buf_idx_q,bank_idx_q,rd_ocm_addr_q,3'b0};

    assign exe_lm_wr_en_o      = res_valid;
    assign exe_lm_wr_addr_o[0] = wr_lm_cross_en_q ? {buf_idx_q,~bank_idx_q,wr_lm_addr[1],3'b0} : 
                                                    {buf_idx_q,~bank_idx_q,wr_lm_addr[0],3'b0};
    assign exe_lm_wr_addr_o[1] = wr_lm_cross_en_q ? {buf_idx_q,~bank_idx_q,wr_lm_addr[0],3'b0} : 
                                                    {buf_idx_q,~bank_idx_q,wr_lm_addr[1],3'b0};
    assign exe_lm_wr_data_o = wr_lm_cross_en_q ? {res_A_data_img,res_A_data_real,res_B_data_img,res_B_data_real}
                            : {res_B_data_img,res_B_data_real,res_A_data_img,res_A_data_real};

    assign wt_cnt_max = 1'b1 << cur_level_q;
    assign true_tot_level = (tot_level_q > MAX_LEVEL) ? MAX_LEVEL : tot_level_q;
    assign wt_rd_stride = 1'b1 << (true_tot_level - cur_level_q - 1);
    // wt addr
    always_comb begin
        wt_cnt_d = wt_cnt_q;
        wt_rd_addr_d = wt_rd_addr_q;
        if (iq_exe__vld_i && exe_iq__rdy_o) begin
            wt_cnt_d = '0;
            wt_rd_addr_d = '0;
        end else if (exe_wt_rd_en_o) begin
            if (wt_cnt_q == (wt_cnt_max - 1)) begin
                wt_cnt_d = '0; 
                wt_rd_addr_d = '0;
            end else begin
                wt_cnt_d = wt_cnt_q + 1;
                wt_rd_addr_d = wt_rd_addr_q + wt_rd_stride;
            end
        end
    end
    assign exe_wt_rd_addr_o = {wt_buf_idx_q,wt_rd_addr_q,3'b0};
    // assign exe_wt_rd_addr_o = {wt_rd_addr_q,3'b0};

    assign exe_iq__awake_rs1_idx_o = buf_idx_q;
    assign exe_iq__awake_rs2_idx_o = wt_buf_idx_q;
    assign exe_iq__awake_instr_idx_o = instr_idx_q;
    always_comb begin
        state_d = state_q;
        buf_idx_d = buf_idx_q;
        bank_idx_d = bank_idx_q;
        wt_buf_idx_d = wt_buf_idx_q;
        rd_ocm_addr_d = rd_ocm_addr_q;
        wr_ocm_addr_d = wr_ocm_addr_q;
        len_d = len_q;
        read_cnt_d = read_cnt_q;
        finish_cnt_d = finish_cnt_q;
        mode_d = mode_q;
        cur_level_d = cur_level_q;
        tot_level_d = tot_level_q;
        instr_idx_d = instr_idx_q;
        beyond_max_level_d = beyond_max_level_q;

        exe_iq__rdy_o = 1'b0;
        exe_lm_rd_en_o = 1'b0;
        exe_wt_rd_en_o = 1'b0;
        exe_iq__awake_en_o = 1'b0;
        unique case(state_d)
            IDLE: begin
                exe_iq__rdy_o = 1'b1;
                if (iq_exe__vld_i) begin
                    // save ctrl info
                    bank_idx_d      = iq_exe__data_i.bank_idx;   
                    buf_idx_d       = iq_exe__data_i.buf_idx;
                    wt_buf_idx_d    = iq_exe__data_i.wt_buf_idx;
                    rd_ocm_addr_d   = iq_exe__data_i.rd_ocm_addr;
                    wr_ocm_addr_d   = iq_exe__data_i.wr_ocm_addr;
                    len_d           = iq_exe__data_i.len;
                    mode_d          = iq_exe__data_i.mode;
                    cur_level_d     = iq_exe__data_i.cur_level;
                    tot_level_d     = iq_exe__data_i.tot_level;
                    instr_idx_d     = iq_exe__data_i.instr_idx;
                    beyond_max_level_d = iq_exe__data_i.beyond_max_level;

                    read_cnt_d = '0;
                    finish_cnt_d = '0;
                    state_d = CALC;
                end
            end
            CALC: begin
                exe_lm_rd_en_o = 1'b1;
                exe_wt_rd_en_o = 1'b1;
                read_cnt_d = read_cnt_q + 2'b10;
                rd_ocm_addr_d = rd_ocm_addr_q + 1'b1;
                if (read_cnt_q == (len_q - 2)) begin
                    state_d = WAIT_FINISH;
                end
            end
            WAIT_FINISH: begin
                if (finish_cnt_q == (len_q - 2)) begin
                    exe_iq__awake_en_o = 1'b1;
                    state_d = IDLE;
                end
            end
            default:;
        endcase
        if (res_valid) begin
            finish_cnt_d = finish_cnt_d + 2'b10;
        end
        if (flush_i) begin
            state_d = IDLE;   
        end
    end
//======================================================================================================================
// Registers
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i,rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            state_q         <= IDLE;
            buf_idx_q       <= '0;
            bank_idx_q      <= '0;
            wt_buf_idx_q    <= '0;
            rd_ocm_addr_q   <= '0;
            len_q           <= '0;                                     
            mode_q          <= '0;
            cur_level_q     <= '0;            
            tot_level_q     <= '0;
            read_cnt_q      <= '0;
            finish_cnt_q    <= '0;
            wt_cnt_q        <= '0;
            wt_rd_addr_q    <= '0;
            instr_idx_q     <= '0;
            cross_cnt_q     <= '0;
            rd_data_cross_en_q <= '0;
            base_ocm_off_q  <= '0;
            wr_lm_cnt_q     <= '0;
            wr_lm_cross_cnt_q     <= '0;    
            wr_lm_cross_en_q <= '0;
            beyond_max_level_q <= '0;
       end else begin
            state_q         <= state_d;
            buf_idx_q       <= buf_idx_d;
            bank_idx_q      <= bank_idx_d;
            wt_buf_idx_q    <= wt_buf_idx_d;
            rd_ocm_addr_q   <= rd_ocm_addr_d;
            len_q           <= len_d;                                     
            mode_q          <= mode_d;
            cur_level_q     <= cur_level_d;            
            tot_level_q     <= tot_level_d;
            read_cnt_q      <= read_cnt_d;
            finish_cnt_q    <= finish_cnt_d;
            wt_cnt_q        <= wt_cnt_d;
            wt_rd_addr_q    <= wt_rd_addr_d;
            instr_idx_q     <= instr_idx_d;
            cross_cnt_q     <= cross_cnt_d;
            rd_data_cross_en_q <= rd_data_cross_en_d;
            base_ocm_off_q  <= base_ocm_off_d;
            wr_lm_cnt_q     <= wr_lm_cnt_d;
            wr_lm_cross_cnt_q     <= wr_lm_cross_cnt_d;    
            wr_lm_cross_en_q <= wr_lm_cross_en_d;
            beyond_max_level_q <= beyond_max_level_d;
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule 
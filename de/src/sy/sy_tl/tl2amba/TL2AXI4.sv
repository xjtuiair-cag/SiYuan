// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : TL2AXI4.v
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


module TL2AXI4 #(
    parameter       AXI_ID = 0
)(
    input  logic                            clk_i,
    input  logic                            rst_i,
    // =====================================
    // [TileLink bus]
    input  logic                            TL_A_valid_i, 
    output logic                            TL_A_ready_o, 
    input  tl_pkg::A_chan_bits_t            TL_A_bits_i,

    output logic                            TL_D_valid_o, 
    input  logic                            TL_D_ready_i, 
    output tl_pkg::D_chan_bits_t            TL_D_bits_o,
    // =====================================
    // [AXI4 bus]
    output logic                            AXI_AW_valid_o,
    input  logic                            AXI_AW_ready_i,         
    output axi_pkg::aw_chan_t               AXI_AW_bits_o,

    output logic                            AXI_AR_valid_o,
    input  logic                            AXI_AR_ready_i,         
    output axi_pkg::ar_chan_t               AXI_AR_bits_o,

    output logic                            AXI_W_valid_o,
    input  logic                            AXI_W_ready_i,         
    output axi_pkg::w_chan_t                AXI_W_bits_o,

    input  logic                            AXI_R_valid_i,
    output logic                            AXI_R_ready_o,
    input  axi_pkg::r_chan_t                AXI_R_bits_i, 

    input  logic                            AXI_B_valid_i,
    output logic                            AXI_B_ready_o,
    input  axi_pkg::b_chan_t                AXI_B_bits_i 
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    typedef struct packed {
      logic                 wen;
      axi_pkg::arw_t        bits;
    } arw_bits_t; // address read write bits

    typedef struct packed {
      tl_pkg::size_t        size;  
      tl_pkg::source_t      source;
      logic                 is_low_32bit;
    } other_bits_t;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    arw_bits_t                              fifo_out_arw_bits;
    arw_bits_t                              fifo_in_arw_bits;
    logic                                   fifo_out_arw_valid; 
    logic                                   fifo_out_arw_ready; 
    logic                                   fifo_arw_push; 
    logic                                   fifo_in_arw_ready; 
    logic                                   fifo_arw_full;
    logic                                   fifo_arw_empty;
    logic                                   fifo_arw_pop;
    logic                                   is_put;
    logic [9:0]                             cnt_d, cnt_q;
    logic                                   put_done;
    logic                                   put_last;
    logic                                   aw_done_d, aw_done_q;       
    axi_pkg::w_chan_t                       fifo_wdata_in;  
    axi_pkg::w_chan_t                       fifo_wdata_out;  
    logic                                   fifo_wdata_push;
    logic                                   fifo_wdata_pop;
    logic                                   fifo_wdata_full;
    logic                                   fifo_wdata_empty;
    logic                                   r_hold_d, r_hold_q;
    logic                                   r_win; 
    logic                                   r_denied;
    logic                                   r_corrupt;
    logic                                   b_denied;
    logic                                   trans_busy;
    other_bits_t                            fifo_other_bits_in;
    other_bits_t                            fifo_other_bits_out;
    logic                                   fifo_other_bits_push;
    logic                                   fifo_other_bits_pop;
    logic                                   fifo_other_bits_full;
    logic                                   fifo_other_bits_empty;
    logic                                   single_trans;
    logic                                   is_low_32bit;
    logic                                   is_dword;

//======================================================================================================================
// Counter to count the number of put data
//======================================================================================================================
    assign single_trans = TL_A_bits_i.size == '0;
    assign is_low_32bit = TL_A_bits_i.mask[3:0] != '0;
    assign is_dword     = TL_A_bits_i.mask == 8'hff;
    always_comb begin : counter
        cnt_d = cnt_q; 
        if (TL_A_valid_i && TL_A_ready_o && !trans_busy) begin
            cnt_d = is_put ? TL_A_bits_i.size : 1'b0;
        end else if (TL_A_valid_i && TL_A_ready_o && trans_busy)begin
            cnt_d = cnt_q - 1'b1;
        end
    end

    assign trans_busy = cnt_q != '0;
    assign put_last = cnt_q == 1'b1;

    assign aw_done_d = (TL_A_valid_i && TL_A_ready_o) ? !put_last && is_put && !single_trans : aw_done_q;
//======================================================================================================================
// transform TL A channel to AXI4 AW/AR/W channel
//======================================================================================================================
    // send address
    assign AXI_AW_bits_o = fifo_out_arw_bits.bits.aw;
    assign AXI_AR_bits_o = fifo_out_arw_bits.bits.ar;

    assign fifo_out_arw_valid = !fifo_arw_empty;
    assign AXI_AW_valid_o = fifo_out_arw_valid &&  fifo_out_arw_bits.wen;
    assign AXI_AR_valid_o = fifo_out_arw_valid && !fifo_out_arw_bits.wen;

    assign fifo_out_arw_ready = fifo_out_arw_bits.wen ? AXI_AW_ready_i : AXI_AR_ready_i;
    assign fifo_arw_pop = fifo_out_arw_ready && fifo_out_arw_valid;

    assign is_put = TL_A_bits_i.opcode inside {tl_pkg::PutFullData, tl_pkg::PutPartialData};
    
    assign fifo_in_arw_bits.wen              =     is_put; 
    assign fifo_in_arw_bits.bits.aw.id       =     AXI_ID;
    assign fifo_in_arw_bits.bits.aw.addr     =     TL_A_bits_i.address + (is_low_32bit ? 4'h0 : 4'h4); 
    assign fifo_in_arw_bits.bits.aw.len      =     TL_A_bits_i.size; 
    assign fifo_in_arw_bits.bits.aw.size     =     is_dword ? 3'b011 : 3'b10;   // double word or single word
    assign fifo_in_arw_bits.bits.aw.burst    =     single_trans ? axi_pkg::BURST_FIXED : axi_pkg::BURST_INCR; 
    // assign fifo_in_arw_bits.bits.aw.burst    =     axi_pkg::BURST_INCR; 
    assign fifo_in_arw_bits.bits.aw.lock     =     '0; 
    assign fifo_in_arw_bits.bits.aw.cache    =     '0; 
    assign fifo_in_arw_bits.bits.aw.prot     =     3'b1; 
    assign fifo_in_arw_bits.bits.aw.qos      =     '0; 

    assign fifo_arw_push = TL_A_valid_i && (is_put ? (!aw_done_q && !fifo_wdata_full && !fifo_other_bits_full) : 
                                  !fifo_other_bits_full); 

    assign TL_A_ready_o = is_put ? ((aw_done_q || !fifo_arw_full && !fifo_other_bits_full) && !fifo_wdata_full) : !fifo_arw_full && !fifo_other_bits_full;
    fifo_v3 #(
          .FALL_THROUGH (1'b0), 
          .DEPTH        (1),    
          .dtype        (arw_bits_t)
    ) arw_fifo(
        .clk_i                      (clk_i),                               
        .rst_ni                     (rst_i),                               
        .flush_i                    (1'b0),                               
        .testmode_i                 (1'b0),                               
        .full_o                     (fifo_arw_full),                               
        .empty_o                    (fifo_arw_empty),                               
        .usage_o                    (),                                 
        .data_i                     (fifo_in_arw_bits),                               
        .push_i                     (fifo_arw_push),                               
        .data_o                     (fifo_out_arw_bits),                               
        .pop_i                      (fifo_arw_pop)       
    );
    // send data 
    assign fifo_wdata_push = TL_A_valid_i && is_put && ((!fifo_arw_full && !fifo_other_bits_full) || aw_done_q) && !fifo_wdata_full;
    assign fifo_wdata_in.data   = TL_A_bits_i.data;
    assign fifo_wdata_in.strb   = TL_A_bits_i.mask;
    assign fifo_wdata_in.last   = single_trans ? 1'b1 : put_last;

    assign AXI_W_bits_o = fifo_wdata_out;
    assign AXI_W_valid_o = !fifo_wdata_empty;
    assign fifo_wdata_pop = AXI_W_valid_o && AXI_W_ready_i;

    fifo_v3 #(
          .FALL_THROUGH (1'b0), 
          .DEPTH        (1),    
          .dtype        (axi_pkg::w_chan_t)
    ) wdata_fifo(
        .clk_i                      (clk_i),                               
        .rst_ni                     (rst_i),                               
        .flush_i                    (1'b0),                               
        .testmode_i                 (1'b0),                               
        .full_o                     (fifo_wdata_full),                               
        .empty_o                    (fifo_wdata_empty),                               
        .usage_o                    (),                                 
        .data_i                     (fifo_wdata_in),                               
        .push_i                     (fifo_wdata_push),                               
        .data_o                     (fifo_wdata_out),                               
        .pop_i                      (fifo_wdata_pop)       
    );

    // save some important signals from A channel
    assign fifo_other_bits_in.size    = TL_A_bits_i.size;
    assign fifo_other_bits_in.source  = TL_A_bits_i.source;
    assign fifo_other_bits_in.is_low_32bit = is_low_32bit;
    
    assign fifo_other_bits_push = fifo_arw_push;
    assign fifo_other_bits_pop  = (AXI_R_valid_i && AXI_R_ready_o && AXI_R_bits_i.last) || (AXI_B_valid_i && AXI_B_ready_o);
    fifo_v3 #(
          .FALL_THROUGH (1'b0), 
          .DEPTH        (1),    
          .dtype        (other_bits_t)
    ) other_bits_fifo(
        .clk_i                      (clk_i),                               
        .rst_ni                     (rst_i),                               
        .flush_i                    (1'b0),                               
        .testmode_i                 (1'b0),                               
        .full_o                     (fifo_other_bits_full),                               
        .empty_o                    (fifo_other_bits_empty),                               
        .usage_o                    (),                                 
        .data_i                     (fifo_other_bits_in),                               
        .push_i                     (fifo_other_bits_push),                               
        .data_o                     (fifo_other_bits_out),                               
        .pop_i                      (fifo_other_bits_pop)       
    );
//======================================================================================================================
// transform AXI R/B channel to TL D channel
//======================================================================================================================
    assign r_hold_d   = (AXI_R_valid_i && AXI_R_ready_o) ? !AXI_R_bits_i.last : r_hold_q;
    assign r_win      = AXI_R_valid_i || r_hold_q; 
    assign r_denied   = AXI_R_bits_i.resp == axi_pkg::RESP_DECERR;
    assign r_corrupt  = AXI_R_bits_i.resp != axi_pkg::RESP_OKAY;
    assign b_denied   = AXI_B_bits_i.resp != axi_pkg::RESP_OKAY;

    assign TL_D_valid_o = r_win ? AXI_R_valid_i : AXI_B_valid_i;
    assign TL_D_bits_o.opcode     = r_win ? tl_pkg::AccessAckData : tl_pkg::AccessAck;
    assign TL_D_bits_o.param      = tl_pkg::toN;
    assign TL_D_bits_o.size       = fifo_other_bits_out.size; 
    assign TL_D_bits_o.source     = fifo_other_bits_out.source;
    assign TL_D_bits_o.sink       = '0;
    assign TL_D_bits_o.denied     = r_win ? r_denied : b_denied;
    assign TL_D_bits_o.data       = fifo_other_bits_out.is_low_32bit ? AXI_R_bits_i.data : (AXI_R_bits_i.data << 32);
    assign TL_D_bits_o.corrupt    = r_win ? r_corrupt : '0;

    assign AXI_R_ready_o = TL_D_ready_i;
    assign AXI_B_ready_o = TL_D_ready_i && !r_win;

//======================================================================================================================
// Register
//======================================================================================================================
    always_ff @(posedge clk_i or negedge rst_i) begin : p_regs
        if(!rst_i) begin
            cnt_q               <= '0; 
            aw_done_q           <= '0;       
            r_hold_q            <= '0;
        end else begin
            cnt_q               <= cnt_d; 
            aw_done_q           <= aw_done_d;
            r_hold_q            <= r_hold_d;
        end
    end
endmodule
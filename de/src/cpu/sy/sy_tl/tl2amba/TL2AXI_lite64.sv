// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : TL2AXI_lite64.sv
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

module TL2AXI_lite64
    import sy_pkg::*;
#(
)(
    input  logic                            clk_i,
    input  logic                            rst_i,
    // =====================================
    // [TL bus]
    // A Channel
    input  logic                            tl_A_valid_i,
    output logic                            tl_A_ready_o,
    input  tl_pkg::A_chan_bits_t            tl_A_bits_i,
    // B Channel
    output logic                            tl_B_valid_o,
    input  logic                            tl_B_ready_i,
    output tl_pkg::B_chan_bits_t            tl_B_bits_o,
    // C Channel
    input  logic                            tl_C_valid_i,
    output logic                            tl_C_ready_o,
    input  tl_pkg::C_chan_bits_t            tl_C_bits_i,
    // D Channel
    output logic                            tl_D_valid_o,
    input  logic                            tl_D_ready_i,
    output tl_pkg::D_chan_bits_t            tl_D_bits_o,
    // E Channel
    input  logic                            tl_E_valid_i,
    output logic                            tl_E_ready_o,
    input  tl_pkg::E_chan_bits_t            tl_E_bits_i,
    // =====================================
    // [AXI_lite32 bus]
    output  logic[31:0]                     axi_awaddr_o,               
    output  logic                           axi_awvalid_o,              
    input   logic                           axi_awready_i,              
    output  logic[63:0]                     axi_wdata_o,                
    output  logic[7:0]                      axi_wstrb_o,
    output  logic                           axi_wvalid_o,               
    input   logic                           axi_wready_i,               
    input   logic[1:0]                      axi_bresp_i,                
    input   logic                           axi_bvalid_i,               
    output  logic                           axi_bready_o,               
    // -- read channel
    output  logic[31:0]                     axi_araddr_o,               
    output  logic                           axi_arvalid_o,              
    input   logic                           axi_arready_i,              
    input   logic[63:0]                     axi_rdata_i,                
    input   logic[1:0]                      axi_rresp_i,                
    input   logic                           axi_rvalid_i,               
    output  logic                           axi_rready_o                
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    typedef enum logic[2:0] {IDLE,SINGEL,WR_FIRE_FLY,BURST_WR,BURST_WR_RSP,BURST_RD} state_e;
    state_e state_d, state_q;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic               singel_en;
    logic[1:0]          aw_w_fire_d,aw_w_fire_q;
    logic               tl_we_d,tl_we_q;
    tl_pkg::mask_t      mask_d,mask_q;
    tl_pkg::source_t    tl_source_d,tl_source_q;
    logic               burst_en;
    logic               src_id_match;
    logic               trans_mode_match;
    logic[15:0]         outstanding_trans_d,outstanding_trans_q;
    tl_pkg::size_t      burst_len_d,burst_len_q;
    tl_pkg::size_t      burst_req_cnt_d,burst_req_cnt_q;
    tl_pkg::size_t      burst_rsp_cnt_d,burst_rsp_cnt_q;
    logic               clr_burst_trans;
    logic               add_outstanding_trans;
    logic               del_outstanding_trans;
    logic               trans_done;
    logic[31:0]         addr_d,addr_q;
    logic               tl_wr;
    logic               tl_rd;
    logic[31:0]         wr_addr_d,wr_addr_q; 
    logic[63:0]         wr_data_d,wr_data_q; 
    logic               wr_rsp;
    logic               rd_rsp;
    logic                        tl_A_valid;
    logic                        tl_A_ready;
    tl_pkg::A_chan_bits_t        tl_A_bits;
    logic                        tl_B_valid;
    logic                        tl_B_ready;
    tl_pkg::B_chan_bits_t        tl_B_bits;
    logic                        tl_C_valid;
    logic                        tl_C_ready;
    tl_pkg::C_chan_bits_t        tl_C_bits;
    logic                        tl_D_valid;
    logic                        tl_D_ready;
    tl_pkg::D_chan_bits_t        tl_D_bits;
    logic                        tl_E_valid;
    logic                        tl_E_ready;
    tl_pkg::E_chan_bits_t        tl_E_bits;

    logic               wr_req_fifo_push;
    logic               wr_req_fifo_pop;
    logic               wr_req_fifo_full;
    logic               wr_req_fifo_empty;
    tl_pkg::source_t    wr_req_fifo_push_data;
    tl_pkg::source_t    wr_req_fifo_pop_data;

    logic               rd_req_fifo_push;
    logic               rd_req_fifo_pop;
    logic               rd_req_fifo_full;
    logic               rd_req_fifo_empty;
    tl_pkg::source_t    rd_req_fifo_push_data;
    tl_pkg::source_t    rd_req_fifo_pop_data;

//======================================================================================================================
// TL interface
//======================================================================================================================
    // dma/fft use C channel to write, so need to trans C channel to A channel
    TL_C2A c2a_inst(
        // input 
        .inp_tl_A_valid_i   (tl_A_valid_i),
        .inp_tl_A_ready_o   (tl_A_ready_o),
        .inp_tl_A_bits_i    (tl_A_bits_i ),
        .inp_tl_B_valid_o   (tl_B_valid_o),
        .inp_tl_B_ready_i   (tl_B_ready_i),
        .inp_tl_B_bits_o    (tl_B_bits_o ),
        .inp_tl_C_valid_i   (tl_C_valid_i),
        .inp_tl_C_ready_o   (tl_C_ready_o),
        .inp_tl_C_bits_i    (tl_C_bits_i ),
        .inp_tl_D_valid_o   (tl_D_valid_o),
        .inp_tl_D_ready_i   (tl_D_ready_i),
        .inp_tl_D_bits_o    (tl_D_bits_o ),
        .inp_tl_E_valid_i   (tl_E_valid_i),
        .inp_tl_E_ready_o   (tl_E_ready_o),
        .inp_tl_E_bits_i    (tl_E_bits_i ),
        // output 
        .oup_tl_A_valid_o   (tl_A_valid),
        .oup_tl_A_ready_i   (tl_A_ready),
        .oup_tl_A_bits_o    (tl_A_bits ),
        .oup_tl_B_valid_i   (tl_B_valid),
        .oup_tl_B_ready_o   (tl_B_ready),
        .oup_tl_B_bits_i    (tl_B_bits ),
        .oup_tl_C_valid_o   (tl_C_valid),
        .oup_tl_C_ready_i   (tl_C_ready),
        .oup_tl_C_bits_o    (tl_C_bits ),
        .oup_tl_D_valid_i   (tl_D_valid),
        .oup_tl_D_ready_o   (tl_D_ready),
        .oup_tl_D_bits_i    (tl_D_bits ),
        .oup_tl_E_valid_o   (tl_E_valid),
        .oup_tl_E_ready_i   (tl_E_ready),
        .oup_tl_E_bits_o    (tl_E_bits )
    );
//======================================================================================================================
// TL interface
//======================================================================================================================
    // no use 
    assign tl_B_valid = 1'b0;
    assign tl_B_bits  = tl_pkg::B_chan_bits_t'(0);
    assign tl_C_ready = 1'b1;
    assign tl_E_ready = 1'b1;
    // TileLink D channel 
    assign tl_D_bits.data     = axi_bvalid_i ? 64'h0 : axi_rdata_i;
    assign tl_D_bits.param    = tl_pkg::toN;
    // assign tl_D_bits.opcode   = tl_we_q ? tl_pkg::AccessAck : tl_pkg::AccessAckData;
    assign tl_D_bits.opcode   = axi_bvalid_i ? tl_pkg::AccessAck : tl_pkg::AccessAckData;
    assign tl_D_bits.size     = (singel_en || tl_we_q) ? tl_pkg::size_t'(0) : burst_len_q;
    assign tl_D_bits.source   = singel_en ? (wr_rsp ? wr_req_fifo_pop_data : rd_req_fifo_pop_data) : tl_source_q;
    assign tl_D_bits.sink     = tl_pkg::sink_t'(0);
    assign tl_D_bits.denied   = 1'b0;
    assign tl_D_bits.corrupt  = 1'b0;
//======================================================================================================================
// FSM (handel singel trans and burst trans)
//======================================================================================================================
    assign tl_wr = tl_A_bits.opcode == tl_pkg::PutFullData || tl_A_bits.opcode == tl_pkg::PutPartialData;
    assign tl_rd = tl_A_bits.opcode == tl_pkg::Get;

    assign src_id_match = tl_source_q == tl_A_bits.source;
    assign trans_mode_match = tl_A_bits.size == tl_pkg::size_t'(0) && singel_en 
                           || tl_A_bits.size != tl_pkg::size_t'(0) && burst_en;

    assign add_outstanding_trans = tl_A_valid && tl_A_ready && singel_en;
    assign del_outstanding_trans = (axi_bvalid_i && axi_bready_o || axi_rvalid_i && axi_rready_o) && singel_en;
    // outstanding trans
    always_comb begin
        outstanding_trans_d = outstanding_trans_q;   
        if (add_outstanding_trans && del_outstanding_trans) begin
            outstanding_trans_d = outstanding_trans_q;
        end else if (add_outstanding_trans) begin
            outstanding_trans_d = outstanding_trans_q + 1'b1;
        end else if (del_outstanding_trans) begin
            outstanding_trans_d = outstanding_trans_q - 1'b1;
        end
    end
    // singel mode trans done
    assign trans_done = outstanding_trans_q == 16'h1 && del_outstanding_trans && !add_outstanding_trans;
    // burst mode trans count  
    always_comb begin
        burst_req_cnt_d = burst_req_cnt_q;
        burst_rsp_cnt_d = burst_rsp_cnt_q;
        // request count
        if (clr_burst_trans) begin
            burst_req_cnt_d = tl_pkg::size_t'(0);
        end else if ((tl_A_valid && tl_A_ready || axi_arvalid_o && axi_arready_i) && burst_en) begin
            burst_req_cnt_d = burst_req_cnt_q + 1'b1;   
        end
        // response count
        if (clr_burst_trans) begin
            burst_rsp_cnt_d = tl_pkg::size_t'(0);
        end else if ((axi_bvalid_i && axi_bready_o || axi_rvalid_i && axi_rready_o) && burst_en) begin
            burst_rsp_cnt_d = burst_rsp_cnt_q + 1'b1;   
        end
    end

    assign wr_rsp = axi_bvalid_i && axi_bready_o;
    assign rd_rsp = axi_rvalid_i && axi_rready_o;

    assign wr_req_fifo_push = tl_A_valid && tl_A_ready && singel_en && !wr_req_fifo_full && tl_wr;
    assign wr_req_fifo_pop  = tl_D_valid && tl_D_ready && singel_en && !wr_req_fifo_empty && wr_rsp;
    assign wr_req_fifo_push_data = tl_A_bits.source;
    sync_fifo # (
        .FIFO_LEN           (16),
        .DATA_WTH           (tl_pkg::SOURCE_WTH),
        .ADDR_WTH           (4),
        .FIFO_RD_TYPE       ("FWFT")                   
    ) wr_source_bits_fifo (
        // clock & reset
        .clk_i              (clk_i),
        .rst_i              (rst_i),
        // clear
        .clr_i              (1'b0),
        // write interface
        .wr_data_i          (wr_req_fifo_push_data),
        .wr_en_i            (wr_req_fifo_push),
        .full_o             (wr_req_fifo_full),
        .a_full_o           (),
        // read interface
        .rd_data_o          (wr_req_fifo_pop_data),
        .rd_en_i            (wr_req_fifo_pop),
        .empty_o            (wr_req_fifo_empty),
        .a_empty_o          ()
    );
    assign rd_req_fifo_push = tl_A_valid && tl_A_ready && singel_en && !rd_req_fifo_full && tl_rd;
    assign rd_req_fifo_pop  = tl_D_valid && tl_D_ready && singel_en && !rd_req_fifo_empty && rd_rsp;
    assign rd_req_fifo_push_data = tl_A_bits.source;
    sync_fifo # (
        .FIFO_LEN           (16),
        .DATA_WTH           (tl_pkg::SOURCE_WTH),
        .ADDR_WTH           (4),
        .FIFO_RD_TYPE       ("FWFT")                   
    ) rd_source_bits_fifo (
        // clock & reset
        .clk_i              (clk_i),
        .rst_i              (rst_i),
        // clear
        .clr_i              (1'b0),
        // write interface
        .wr_data_i          (rd_req_fifo_push_data),
        .wr_en_i            (rd_req_fifo_push),
        .full_o             (rd_req_fifo_full),
        .a_full_o           (),
        // read interface
        .rd_data_o          (rd_req_fifo_pop_data),
        .rd_en_i            (rd_req_fifo_pop),
        .empty_o            (rd_req_fifo_empty),
        .a_empty_o          ()
    );

    always_comb begin : FSM 
        state_d         = state_q;
        aw_w_fire_d     = aw_w_fire_q;
        tl_source_d     = tl_source_q;
        tl_we_d         = tl_we_q;
        burst_len_d     = burst_len_q;
        addr_d          = addr_q;
        mask_d          = mask_q;
        wr_addr_d       = wr_addr_q;
        wr_data_d       = wr_data_q;

        singel_en = 1'b0;
        burst_en  = 1'b0;

        axi_awvalid_o = 1'b0;
        axi_awaddr_o  = tl_A_bits.address[31:0];
        axi_wvalid_o  = 1'b0;
        axi_wdata_o   = tl_A_bits.data;
        axi_wstrb_o   = mask_q;
        axi_arvalid_o = 1'b0;
        axi_araddr_o  = tl_A_bits.address[31:0];
        axi_bready_o   = 1'b0;
        axi_rready_o   = 1'b0;

        tl_A_ready    = 1'b0;
        tl_D_valid    = 1'b0;

        clr_burst_trans = 1'b0;

        unique case(state_q)
            IDLE : begin 
                aw_w_fire_d = 2'b0;
                tl_we_d = tl_wr;
                mask_d = tl_A_bits.mask;
                // A channel and C channel both can send request
                if (tl_A_valid) begin
                    tl_source_d    = tl_A_bits.source;
                    if (tl_A_bits.size == tl_pkg::size_t'(0)) begin
                        // state_d = tl_wr ? SINGEL_WR : SINGEL_RD;
                        state_d = SINGEL;
                    end else begin
                        state_d = tl_wr ? BURST_WR : BURST_RD;
                        burst_len_d = tl_A_bits.size;
                        // if is read burst request, accept it
                        tl_A_ready = tl_rd;
                        addr_d = tl_A_bits.address[31:0];
                        clr_burst_trans = 1'b1;
                    end
                end
            end
            // SINGEL_WR : begin
            //     singel_en = 1'b1;
            //     axi_awvalid_o = tl_A_valid && tl_wr && src_id_match && trans_mode_match;
            //     axi_wvalid_o  = tl_A_valid && tl_wr && src_id_match && trans_mode_match;
            //     tl_A_ready    = axi_awvalid_o && axi_awready_i || axi_wvalid_o && axi_wready_i; 
            //     // address write channel and write channel handshake
            //     if (axi_awvalid_o && axi_awready_i && axi_wvalid_o && axi_wready_i) begin
            //         aw_w_fire_d = 2'b0;
            //     end else if (axi_awvalid_o && axi_awready_i) begin
            //         aw_w_fire_d[0] = 1'b1;
            //         state_d = WR_FIRE_FLY;
            //     end else if (axi_wvalid_o && axi_wready_i) begin
            //         aw_w_fire_d[1] = 1'b1;
            //         state_d = WR_FIRE_FLY;
            //     end else if (!axi_awvalid_o && !axi_wvalid_o && trans_done) begin
            //         state_d = IDLE;
            //     end
            //     // response 
            //     tl_D_valid   = axi_bvalid_i; 
            //     axi_bready_o = tl_D_ready;

            //     wr_data_d = tl_A_bits.data;
            //     wr_addr_d = tl_A_bits.address[31:0];
            // end
            // WR_FIRE_FLY: begin
            //     axi_awvalid_o = !aw_w_fire_q[0];
            //     axi_wvalid_o  = !aw_w_fire_q[1];

            //     axi_awaddr_o = wr_addr_q;
            //     axi_wdata_o  = wr_data_q;
            //     if (axi_awvalid_o && axi_awready_i) begin
            //         aw_w_fire_d[0] = 1'b1;
            //         state_d = SINGEL_WR;
            //     end else if (axi_wvalid_o && axi_wready_i) begin
            //         aw_w_fire_d[1] = 1'b1;
            //         state_d = SINGEL_WR;
            //     end
            // end
            // SINGEL_RD: begin
            //     singel_en = 1'b1;               
            //     axi_arvalid_o = tl_A_valid && tl_rd && src_id_match && trans_mode_match;
            //     tl_A_ready    = axi_arvalid_o && axi_arready_i;
            //     axi_rready_o  = tl_D_ready;
            //     // response
            //     tl_D_valid    = axi_rvalid_i;
            //     if (axi_arvalid_o && axi_arready_i) begin
            //         state_d = SINGEL_RD;    
            //     end else if (trans_done && !axi_arvalid_o) begin
            //         state_d = IDLE;
            //     end
            // end
            SINGEL: begin
                singel_en = 1'b1;   
                axi_awvalid_o = tl_A_valid && tl_wr && !wr_req_fifo_full && !rd_req_fifo_full && trans_mode_match;
                axi_wvalid_o  = tl_A_valid && tl_wr && !wr_req_fifo_full && !rd_req_fifo_full && trans_mode_match;
                axi_arvalid_o = tl_A_valid && tl_rd && !wr_req_fifo_full && !rd_req_fifo_full && trans_mode_match;
                // generate tl A channel ready 
                tl_A_ready    = axi_awvalid_o && axi_awready_i || axi_wvalid_o && axi_wready_i || 
                                axi_arvalid_o && axi_arready_i;
                // address write channel and write channel handshake
                if (axi_awvalid_o && axi_awready_i && axi_wvalid_o && axi_wready_i) begin
                    aw_w_fire_d = 2'b0;
                end else if (axi_awvalid_o && axi_awready_i) begin
                    aw_w_fire_d[0] = 1'b1;
                    state_d = WR_FIRE_FLY;
                end else if (axi_wvalid_o && axi_wready_i) begin
                    aw_w_fire_d[1] = 1'b1;
                    state_d = WR_FIRE_FLY;
                end else if (!axi_awvalid_o && !axi_wvalid_o && !axi_arvalid_o && trans_done) begin
                    state_d = IDLE;
                end               
                axi_bready_o  = tl_D_ready;
                axi_rready_o  = tl_D_ready && !axi_bvalid_i;
                // response
                tl_D_valid   = axi_bvalid_i || axi_rvalid_i; 
                // lock write addr and data
                wr_data_d = tl_A_bits.data;
                wr_addr_d = tl_A_bits.address[31:0];
            end
            WR_FIRE_FLY: begin
                axi_awvalid_o = !aw_w_fire_q[0];
                axi_wvalid_o  = !aw_w_fire_q[1];

                axi_awaddr_o = wr_addr_q;
                axi_wdata_o  = wr_data_q;
                if (axi_awvalid_o && axi_awready_i) begin
                    aw_w_fire_d[0] = 1'b1;
                    state_d = SINGEL;
                end else if (axi_wvalid_o && axi_wready_i) begin
                    aw_w_fire_d[1] = 1'b1;
                    state_d = SINGEL;
                end
            end
            BURST_WR: begin
                burst_en = 1'b1;   
                axi_awvalid_o = tl_A_valid && tl_wr && src_id_match && trans_mode_match && !aw_w_fire_q[0];
                axi_wvalid_o  = tl_A_valid && tl_wr && src_id_match && trans_mode_match && !aw_w_fire_q[1];
                tl_A_ready    = axi_awvalid_o && axi_awready_i && axi_wvalid_o && axi_wready_i || 
                                axi_awvalid_o && axi_awready_i && aw_w_fire_q[1] || 
                                axi_wvalid_o && axi_wready_i && aw_w_fire_q[0];
                axi_awaddr_o = addr_q;
                // address write channel and write channel handshake
                if (axi_awvalid_o && axi_awready_i && axi_wvalid_o && axi_wready_i) begin
                    aw_w_fire_d = 2'b0;
                end else if (axi_awvalid_o && axi_awready_i) begin
                    aw_w_fire_d[0] = 1'b1;
                end else if (axi_wvalid_o && axi_wready_i) begin
                    aw_w_fire_d[1] = 1'b1;
                end 
                if (tl_A_valid && tl_A_ready) begin
                    addr_d = addr_q + 4'h8;
                end
                // finish 
                if (tl_A_valid && tl_A_ready && burst_req_cnt_q == burst_len_q) begin 
                    state_d = BURST_WR_RSP;
                end
                // always accept write response
                axi_bready_o = 1'b1;
            end
            BURST_WR_RSP: begin
                burst_en = 1'b1;
                // always accept write response
                axi_bready_o = 1'b1;
                if (axi_bvalid_i && axi_bready_o && burst_rsp_cnt_q == burst_len_q || (burst_rsp_cnt_q == burst_len_q + 1'b1)) begin
                    tl_D_valid = 1'b1;
                    if (tl_D_valid && tl_D_ready) begin
                        state_d = IDLE;
                    end
                end
            end
            BURST_RD : begin
                burst_en = 1'b1;
                axi_arvalid_o = burst_req_cnt_q <= burst_len_q;
                axi_rready_o = tl_D_ready;           
                tl_D_valid = axi_rvalid_i;
                axi_araddr_o = addr_q;
                if (axi_rvalid_i && axi_rready_o && burst_rsp_cnt_q == burst_len_q || (burst_rsp_cnt_q == burst_len_q + 1'b1)) begin
                    state_d = IDLE;   
                end
                if (axi_arvalid_o && axi_arready_i) begin
                    addr_d = addr_q + 4'h8;
                end
            end
            default : state_d = IDLE;
        endcase
        // clear 
        if (&aw_w_fire_d) begin
            aw_w_fire_d = 2'b0;
        end
    end
//======================================================================================================================
// Register
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i,rst_i)) begin : p_regs
        if(`DFF_IS_R(rst_i)) begin
            state_q             <= IDLE;
            aw_w_fire_q         <= 2'b0;
            outstanding_trans_q <= 16'b0;
            burst_len_q         <= tl_pkg::size_t'(0);
            burst_req_cnt_q     <= tl_pkg::size_t'(0);
            burst_rsp_cnt_q     <= tl_pkg::size_t'(0);
            addr_q              <= 32'h0;
            mask_q              <= tl_pkg::mask_t'(0);   
            tl_source_q         <= tl_pkg::source_t'(0);
            tl_we_q             <= 1'b0;
            wr_addr_q           <= 32'h0;
            wr_data_q           <= 64'h0;
        end else begin
            state_q             <= state_d;
            aw_w_fire_q         <= aw_w_fire_d;
            outstanding_trans_q <= outstanding_trans_d;
            burst_len_q         <= burst_len_d;
            burst_req_cnt_q     <= burst_req_cnt_d;
            burst_rsp_cnt_q     <= burst_rsp_cnt_d;
            addr_q              <= addr_d;
            mask_q              <= mask_d;
            tl_source_q         <= tl_source_d;
            tl_we_q             <= tl_we_d;
            wr_addr_q           <= wr_addr_d;
            wr_data_q           <= wr_data_d;
       end
    end

endmodule
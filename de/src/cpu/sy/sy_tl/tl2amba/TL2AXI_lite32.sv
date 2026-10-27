// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : TL2AXI_lite32.sv
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

module TL2AXI_lite32
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
    output  logic[31:0]                     axi_wdata_o,                
    output  logic[3:0]                      axi_wstrb_o,                
    output  logic                           axi_wvalid_o,               
    input   logic                           axi_wready_i,               
    input   logic[1:0]                      axi_bresp_i,                
    input   logic                           axi_bvalid_i,               
    output  logic                           axi_bready_o,               
    // -- read channel
    output  logic[31:0]                     axi_araddr_o,               
    output  logic                           axi_arvalid_o,              
    input   logic                           axi_arready_i,              
    input   logic[31:0]                     axi_rdata_i,                
    input   logic[1:0]                      axi_rresp_i,                
    input   logic                           axi_rvalid_i,               
    output  logic                           axi_rready_o                
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    typedef enum logic[2:0] {IDLE,WRITE_REQ,WRITE,WAIT_TL_WRITE,TL_WR_RSP,READ_RSP,TL_RD_RSP} state_e;
    state_e state_d, state_q;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic [63:0]            tl_data_d, tl_data_q;
    tl_pkg::source_t        tl_source_d, tl_source_q;
    logic                   tl_is_dw_d, tl_is_dw_q; // double world
    logic                   trans_loc_d, trans_loc_q;
    tl_pkg::mask_t          tl_mask_d, tl_mask_q;
    logic[31:0]             tl_addr_d, tl_addr_q;
    logic                   tl_we_d, tl_we_q;
    logic                   tl_wr;
    logic                   tl_rd;
    logic                   is_low_32bit;
    tl_pkg::size_t          tl_trans_len_d, tl_trans_len_q;
    tl_pkg::size_t          tl_trans_cnt_d, tl_trans_cnt_q;
    logic[9:0]              axil_trans_cnt_d, axil_trans_cnt_q;
    logic[9:0]              axil_trans_len_d, axil_trans_len_q;
    logic[9:0]              axil_brsp_cnt_d, axil_brsp_cnt_q;
    logic                   reg_rd_wr_d, reg_rd_wr_q;

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
// FSM 
//======================================================================================================================
    // no use 
    assign tl_B_valid = 1'b0;
    assign tl_B_bits  = tl_pkg::B_chan_bits_t'(0);
    assign tl_C_ready = 1'b1;
    assign tl_E_ready = 1'b1;

    assign tl_wr = tl_A_bits.opcode == tl_pkg::PutFullData || tl_A_bits.opcode == tl_pkg::PutPartialData;
    assign tl_rd = tl_A_bits.opcode == tl_pkg::Get;
    assign is_low_32bit = tl_A_bits.mask[3:0] != 4'h0;

    // TileLink D channel 
    assign tl_D_bits.data = tl_data_q;
    assign tl_D_bits.opcode = tl_we_q ? tl_pkg::AccessAck : tl_pkg::AccessAckData;
    assign tl_D_bits.size = tl_pkg::size_t'(0);
    assign tl_D_bits.source = tl_source_q;
    assign tl_D_bits.sink = tl_pkg::sink_t'(0);
    assign tl_D_bits.denied = 1'b0;
    assign tl_D_bits.corrupt = 1'b0;
    assign tl_D_bits.param = tl_pkg::toT;

    // AXI32-lite read/write address
    assign axi_awaddr_o = tl_addr_q;
    assign axi_araddr_o = tl_addr_q;
    assign axi_wstrb_o  = tl_addr_q[2] ? tl_mask_q[7:4] : tl_mask_q[3:0];
    // AXI32-lite b channel response counter
    always_comb begin
        axil_brsp_cnt_d = axil_brsp_cnt_q;
        if (tl_A_valid && tl_A_ready && state_q == IDLE) begin
            axil_brsp_cnt_d = 10'b0;
        end else if (axi_bvalid_i && axi_bready_o) begin
            axil_brsp_cnt_d = axil_brsp_cnt_q + 1'b1;
        end
    end
    assign axi_bready_o = state_q != IDLE && axil_brsp_cnt_q != axil_trans_len_q && tl_we_q;

    // send read request continuous until trans cnt equal trans len
    always_comb begin
        axi_arvalid_o = 1'b0;
        if (state_q != IDLE && !tl_we_q && axil_trans_cnt_q != axil_trans_len_q) begin
            axi_arvalid_o = 1'b1;
        end
    end

    always_comb begin : FSM 
        state_d         = state_q;
        tl_data_d       = tl_data_q;
        tl_source_d     = tl_source_q;
        tl_trans_len_d  = tl_trans_len_q;
        tl_trans_cnt_d  = tl_trans_cnt_q;
        tl_is_dw_d      = tl_is_dw_q;
        trans_loc_d     = trans_loc_q;
        tl_addr_d       = tl_addr_q;
        tl_we_d         = tl_we_q;
        axil_trans_cnt_d = axil_trans_cnt_q;
        axil_trans_len_d = axil_trans_len_q;
        reg_rd_wr_d     = reg_rd_wr_q;
        tl_mask_d       = tl_mask_q;

        tl_A_ready  = 1'b0;
        tl_D_valid  = 1'b0;
        axi_awvalid_o = 1'b0;
        axi_wvalid_o  = 1'b0;
        axi_rready_o  = 1'b0;

        axi_wdata_o = tl_data_q[31:0];
        unique case(state_q)
            IDLE : begin 
                tl_A_ready = 1'b1;
                if (tl_A_valid && tl_A_ready) begin
                      tl_data_d      = tl_A_bits.data;
                      tl_source_d    = tl_A_bits.source;
                      tl_mask_d      = tl_A_bits.mask;
                      tl_trans_len_d = tl_A_bits.size;
                      tl_trans_cnt_d = tl_pkg::size_t'(0);
                      tl_is_dw_d     = tl_A_bits.mask == 8'hFF ? 1'b1 : 1'b0;
                      trans_loc_d    = is_low_32bit ? 1'b0 : 1'b1;
                      tl_addr_d      = is_low_32bit ? tl_A_bits.address : {tl_A_bits.address[31:3],3'b100};
                      tl_we_d        = tl_wr;
                      reg_rd_wr_d    = tl_A_bits.mask != 8'hFF && (tl_A_bits.size == tl_pkg::size_t'(0));
                      axil_trans_len_d = reg_rd_wr_d ? 10'b1 : (tl_A_bits.size+1'b1) << 1; // (len + 1) * 2 
                      axil_trans_cnt_d = 10'b0;
                      state_d = tl_wr ? WRITE_REQ : READ_RSP; 
                end
            end
            WRITE_REQ: begin 
                axi_awvalid_o = 1'b1;
                if (axi_awvalid_o && axi_awready_i) begin
                    state_d = WRITE;
                    // tl_addr_d = {tl_addr_q[31:3],3'b100};
                end
            end
            WRITE: begin
                axi_wvalid_o = 1'b1;
                axi_wdata_o  = trans_loc_q ? tl_data_q[63:32] : tl_data_q[31:0];
                if (axi_wvalid_o && axi_wready_i) begin
                    // increment addr
                    tl_addr_d = tl_addr_q + 4'h4;
                    if (reg_rd_wr_q) begin
                        state_d = TL_WR_RSP;
                    end else if (tl_is_dw_q == 1'b0) begin
                        tl_trans_cnt_d = tl_trans_cnt_q + 1'b1;
                        if (tl_trans_cnt_q == tl_trans_len_q) begin
                            state_d = TL_WR_RSP;
                        end else begin
                            state_d = WAIT_TL_WRITE;
                        end
                    end else begin
                        state_d = WRITE_REQ;
                        trans_loc_d = ~trans_loc_q;
                        tl_is_dw_d = ~tl_is_dw_q;
                    end
                end
            end
            WAIT_TL_WRITE: begin
                tl_A_ready = 1'b1;
                if (tl_A_valid && tl_A_ready) begin
                   tl_data_d = tl_A_bits.data; 
                   tl_is_dw_d = 1'b1;
                   trans_loc_d = 1'b0;
                   state_d = WRITE_REQ;
                end
            end
            TL_WR_RSP: begin
                if (axil_brsp_cnt_q == axil_trans_len_q) begin
                    tl_D_valid = 1'b1;
                    if (tl_D_valid && tl_D_ready) begin
                        state_d = IDLE;
                    end 
                end
            end
            READ_RSP: begin
                axi_rready_o = 1'b1;
                tl_data_d[31:0]  = trans_loc_q ? tl_data_q[31:0] : axi_rdata_i;
                tl_data_d[63:32] = trans_loc_q ? axi_rdata_i : tl_data_q[63:32];
                if (axi_rvalid_i && axi_rready_o) begin
                    trans_loc_d = ~trans_loc_q;
                    if (reg_rd_wr_q) begin
                        state_d = TL_RD_RSP;
                    end else if (tl_is_dw_q == 1'b0) begin
                        state_d = TL_RD_RSP;
                    end else begin
                        state_d = READ_RSP;
                        tl_is_dw_d = ~tl_is_dw_q;
                    end
                end
            end
            TL_RD_RSP: begin
                tl_D_valid = 1'b1;
                if (tl_D_valid && tl_D_ready) begin
                    tl_trans_cnt_d = tl_trans_cnt_q + 1'b1;
                    if (tl_trans_cnt_q == tl_trans_len_q) begin
                        state_d = IDLE;
                    end else begin
                        state_d = READ_RSP;
                        tl_is_dw_d = 1'b1;
                        trans_loc_d = 1'b0;
                    end
                end
            end
            default : state_d = IDLE;
        endcase

        // increment axi read address
        if (axi_arvalid_o && axi_arready_i) begin
            axil_trans_cnt_d = axil_trans_cnt_q + 1'b1;
            tl_addr_d = tl_addr_q + 4'h4;
        end

    end
//======================================================================================================================
// Register
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i,rst_i)) begin : p_regs
        if(`DFF_IS_R(rst_i)) begin
            state_q          <= IDLE;
            tl_data_q        <= 64'h0;
            tl_source_q      <= tl_pkg::source_t'(0);
            tl_trans_cnt_q   <= tl_pkg::size_t'(0);
            tl_is_dw_q       <= 1'b0;
            trans_loc_q      <= 1'b0;
            tl_addr_q        <= 32'b0;
            tl_we_q          <= 1'b0;
            tl_trans_len_q   <= tl_pkg::size_t'(0);
            axil_trans_cnt_q <= 10'b0;
            axil_trans_len_q <= 10'b0;
            axil_brsp_cnt_q  <= 10'b0;
            reg_rd_wr_q      <= 1'b0;
            tl_mask_q        <= tl_pkg::mask_t'(0);
        end else begin
            state_q          <= `TCQ state_d;
            tl_data_q        <= tl_data_d;
            tl_source_q      <= tl_source_d;
            tl_trans_cnt_q   <= tl_trans_cnt_d;
            tl_is_dw_q       <= tl_is_dw_d;
            trans_loc_q      <= trans_loc_d;
            tl_addr_q        <= tl_addr_d;
            tl_we_q          <= tl_we_d;
            tl_trans_len_q   <= tl_trans_len_d;
            axil_trans_cnt_q <= axil_trans_cnt_d;
            axil_trans_len_q <= axil_trans_len_d;
            axil_brsp_cnt_q  <= axil_brsp_cnt_d;
            reg_rd_wr_q      <= reg_rd_wr_d;
            tl_mask_q        <= tl_mask_d;
       end
    end

endmodule
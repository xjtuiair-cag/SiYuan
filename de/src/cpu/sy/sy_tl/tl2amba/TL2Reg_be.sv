// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : TL2Reg_be.v
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

module TL2Reg_be
    import sy_pkg::*;
#(
    parameter       ADDR_WIDTH = 64,
    parameter       DATA_WIDTH = 64 
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
    // [Reg bus]
    // clk0 send read req, clk1 will get read data 
    output logic                            en_o,
    output logic                            we_o,
    output logic [ADDR_WIDTH-1:0]           addr_o,
    output logic [DATA_WIDTH/8-1:0]         be_o,
    output logic [DATA_WIDTH-1:0]           wdata_o,
    input  logic [DATA_WIDTH-1:0]           rdata_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    enum logic [2:0] { IDLE, READ, READ_RESP, WRITE, WRITE_RESP} state_q, state_d;

//======================================================================================================================
// wire & reg declaration
//======================================================================================================================
    tl_pkg::source_t                        source_d, source_q;
    tl_pkg::size_t                          size_d, size_q;
    tl_pkg::size_t                          trans_cnt_d, trans_cnt_q;
    logic                                   is_write_d, is_write_q;
    logic [31:0]                            address_d, address_q;
    logic [7:0]                             mask_d, mask_q;
    logic                                   is_low_32bit;
    logic                                   rd_delay_d,rd_delay_q;
    logic [63:0]                            rdata_tmp_d,rdata_tmp_q;    
    logic [63:0]                            rdata;
    logic                                   tl_rd, tl_wr;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign tl_wr = TL_A_bits_i.opcode == tl_pkg::PutFullData || TL_A_bits_i.opcode == tl_pkg::PutPartialData;
    assign tl_rd = TL_A_bits_i.opcode == tl_pkg::Get;

    assign TL_D_bits_o.opcode           = is_write_q ? tl_pkg::AccessAck: tl_pkg::AccessAckData;
    assign TL_D_bits_o.param.permission = tl_pkg::toT;
    assign TL_D_bits_o.size             = tl_pkg::size_t'(0);
    assign TL_D_bits_o.source           = source_q;
    assign TL_D_bits_o.sink             = tl_pkg::sink_t'(0);
    // assign TL_D_bits_o.data             = addr_o[2] ? (rdata_i << 32) : rdata_i;
    assign TL_D_bits_o.data             = rd_delay_q ? rdata_tmp_q : rdata;
    assign TL_D_bits_o.denied           = 1'b0;
    assign TL_D_bits_o.corrupt          = 1'b0;

    assign is_low_32bit = mask_q[3:0] != '0;

    assign addr_o       = address_q + (is_low_32bit ? 4'h0 : 4'h4);
    // assign wdata_o      = is_low_32bit ? TL_A_bits_i.data : (TL_A_bits_i.data >> 32);
    assign wdata_o      = TL_A_bits_i.data;
    // assign be_o         = is_low_32bit ? mask_d : (mask_d >> 4);
    assign be_o         = mask_q;
    assign rdata        = rdata_i;

    always_comb begin
        state_d     = state_q;
        address_d   = address_q;
        source_d    = source_q;
        is_write_d  = is_write_q;
        mask_d      = mask_q;
        rd_delay_d  = rd_delay_q;
        rdata_tmp_d = rdata_tmp_q;
        size_d      = size_q;
        trans_cnt_d  = trans_cnt_q;

        TL_A_ready_o = 1'b0;
        TL_D_valid_o = 1'b0;

        we_o         = 1'b0;
        en_o         = 1'b0;
        case (state_q)
            IDLE: begin
                if (TL_A_valid_i) begin
                    source_d        = TL_A_bits_i.source;
                    address_d       = TL_A_bits_i.address[31:0];
                    is_write_d      = tl_wr;
                    size_d          = TL_A_bits_i.size;
                    mask_d          = TL_A_bits_i.mask;
                    rd_delay_d      = 1'b0;
                    trans_cnt_d     = 0;
                    if (tl_wr) begin
                        state_d = WRITE;
                    end else begin
                        state_d = READ;
                        TL_A_ready_o    = 1'b1;
                    end
                end
            end
            READ: begin
                en_o = 1'b1;
                state_d = READ_RESP;
            end
            READ_RESP: begin
                TL_D_valid_o = 1'b1;
                if (TL_D_ready_i) begin
                    trans_cnt_d = trans_cnt_q + 1;
                    rd_delay_d = 1'b0;
                    if (trans_cnt_q == size_q) begin
                        state_d = IDLE;
                    end else begin
                        state_d = READ;
                        address_d = address_q + 8;
                    end
                end else begin
                    rd_delay_d = 1'b1;
                    rdata_tmp_d = rdata;
                    state_d = READ_RESP;
                end
            end
            WRITE: begin
                TL_A_ready_o = 1'b1;
                en_o = TL_A_valid_i;
                we_o = TL_A_valid_i;
                if (TL_A_valid_i && TL_A_ready_o) begin
                    trans_cnt_d = trans_cnt_q + 1;
                    address_d = address_q + 8;
                    if (trans_cnt_q == size_q) begin
                        state_d = WRITE_RESP;
                    end
                end
            end
            WRITE_RESP: begin
                TL_D_valid_o = 1'b1;
                if (TL_D_ready_i) begin
                    state_d = IDLE;        
                end 
            end
            default : state_d = IDLE;
        endcase
    end

//======================================================================================================================
// Register
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i,rst_i)) begin : p_regs
        if(`DFF_IS_R(rst_i)) begin
            state_q     <= IDLE;
            source_q    <= tl_pkg::source_t'(0);
            address_q   <= '0;
            is_write_q  <= 1'b0;
            mask_q      <= '0;
            rd_delay_q  <= '0;
            rdata_tmp_q <= '0;
            size_q      <= tl_pkg::size_t'(0);
            trans_cnt_q  <= '0;
        end else begin
            state_q     <= state_d;
            source_q    <= source_d;
            address_q   <= address_d;
            is_write_q  <= is_write_d;
            mask_q      <= mask_d;
            rd_delay_q  <= rd_delay_d;
            rdata_tmp_q <= rdata_tmp_d;
            size_q      <= size_d;  
            trans_cnt_q <= trans_cnt_d;
        end
    end

endmodule
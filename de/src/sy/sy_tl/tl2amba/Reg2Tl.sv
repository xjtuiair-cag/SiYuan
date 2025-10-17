// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : Reg2TL.v
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

module Reg2TL
    import sy_pkg::*;
#(
    parameter       ADDR_WIDTH = 64,
    parameter       DATA_WIDTH = 64, 
    parameter       SOURCE     = 0
)(
    input  logic                            clk_i,
    input  logic                            rst_i,
    // =====================================
    // [TileLink bus]
    output logic                            TL_A_valid_o, 
    input  logic                            TL_A_ready_i, 
    output tl_pkg::A_chan_bits_t            TL_A_bits_o,

    input  logic                            TL_D_valid_i, 
    output logic                            TL_D_ready_o, 
    input  tl_pkg::D_chan_bits_t            TL_D_bits_i,
    // =====================================
    // [Reg bus]
    // clk0 send read req, clk1 will get read data 
    input  logic                            req_i,
    output logic                            gnt_o,
    input  logic                            we_i,
    input  logic [ADDR_WIDTH-1:0]           addr_i,
    input  logic [DATA_WIDTH/8-1:0]         be_i,
    input  logic [DATA_WIDTH-1:0]           wdata_i,
    output logic                            rdata_valid_o,
    output logic [DATA_WIDTH-1:0]           rdata_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    enum logic [1:0] { IDLE, READ_RESP, WRITE_RESP} state_q, state_d;
    parameter SOURCE_ID = {SOURCE,1'b0};
//======================================================================================================================
// wire & reg declaration
//======================================================================================================================
//======================================================================================================================
// Instance
//======================================================================================================================
    assign TL_A_bits_o.opcode           = we_i ? tl_pkg::PutFullData: tl_pkg::Get;
    assign TL_A_bits_o.param            = tl_pkg::NtoB;
    assign TL_A_bits_o.size             = tl_pkg::size_t'(0);
    assign TL_A_bits_o.source           = SOURCE_ID;
    assign TL_A_bits_o.address          = addr_i;
    assign TL_A_bits_o.mask             = be_i;
    assign TL_A_bits_o.data             = wdata_i;
    assign TL_A_bits_o.corrupt          = 1'b0;

    assign rdata_o = TL_D_bits_i.data;

    always_comb begin
        state_d     = state_q;

        gnt_o        = 1'b0;
        rdata_valid_o = 1'b0;
        TL_A_valid_o = 1'b0;
        TL_D_ready_o = 1'b0;
        case (state_q)
            IDLE: begin
                gnt_o = TL_A_ready_i;
                TL_A_valid_o = req_i;
                if (TL_A_valid_o && TL_A_ready_i) begin
                    state_d = we_i ? WRITE_RESP : READ_RESP;
                end
            end
            READ_RESP: begin
                TL_D_ready_o = 1'b1;
                rdata_valid_o = TL_D_valid_i;
                if (TL_D_valid_i && TL_D_ready_o) begin
                    state_d = IDLE;
                end
            end
            WRITE_RESP: begin
                TL_D_ready_o = 1'b1;
                if (TL_D_valid_i) begin
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
        end else begin
            state_q     <= state_d;
        end
    end

endmodule
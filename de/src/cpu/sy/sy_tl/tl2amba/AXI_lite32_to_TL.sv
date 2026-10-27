// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : AXI_lite32_to_TL.sv
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

module AXI_lite32_to_TL
    import sy_pkg::*;
#(
    parameter       SOURCE     = 0
)(
    input  logic                            clk_i,
    input  logic                            rst_i,
    // =====================================
    // [AXI_lite32 bus]
    input   logic[63:0]                     axi_awaddr_i,               // -- 64bit, write address
    input   logic                           axi_awvalid_i,              // -- valid
    output  logic                           axi_awready_o,              // -- ready
    input   logic[31:0]                     axi_wdata_i,                // -- 32bit, write data
    input   logic                           axi_wvalid_i,               // -- valid
    output  logic                           axi_wready_o,               // -- ready
    output  logic[1:0]                      axi_bresp_o,                // -- 2bit, responce
    output  logic                           axi_bvalid_o,               // -- valid
    input   logic                           axi_bready_i,               // -- ready
    // -- read channel
    input   logic[63:0]                     axi_araddr_i,               // -- 64bit, read address
    input   logic                           axi_arvalid_i,              // -- valid
    output  logic                           axi_arready_o,              // -- ready
    output  logic[31:0]                     axi_rdata_o,                // -- 32bit, read data
    output  logic[1:0]                      axi_rresp_o,                // -- 2bit, responce
    output  logic                           axi_rvalid_o,               // -- valid
    input   logic                           axi_rready_i,               // -- ready
    // =====================================
    // [TL bus]
    // A Channel
    output logic                            tl_A_valid_o,
    input  logic                            tl_A_ready_i,
    output tl_pkg::A_chan_bits_t            tl_A_bits_o,
    // B Channel
    input  logic                            tl_B_valid_i,
    output logic                            tl_B_ready_o,
    input  tl_pkg::B_chan_bits_t            tl_B_bits_i,
    // C Channel
    output logic                            tl_C_valid_o,
    input  logic                            tl_C_ready_i,
    output tl_pkg::C_chan_bits_t            tl_C_bits_o,
    // D Channel
    input  logic                            tl_D_valid_i,
    output logic                            tl_D_ready_o,
    input  tl_pkg::D_chan_bits_t            tl_D_bits_i,
    // E Channel
    output logic                            tl_E_valid_o,
    input  logic                            tl_E_ready_i,
    output tl_pkg::E_chan_bits_t            tl_E_bits_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================
    enum logic [1:0] { IDLE, WAIT_W, WAIT_WR_RSP,READ} state_q, state_d;
    localparam SOURCE_ID = {SOURCE,2'b0};
//======================================================================================================================
// wire & reg declaration
//======================================================================================================================
    logic[63:0]                             addr_d,addr_q;
    logic                                   align_8B;
//======================================================================================================================
// Instance
//======================================================================================================================
    // not used 
    assign tl_C_valid_o = 1'b0;
    assign tl_C_bits_o = tl_pkg::C_chan_bits_t'('0);
    assign tl_B_ready_o = 1'b0;
    assign tl_E_valid_o = 1'b0;
    assign tl_E_bits_o = tl_pkg::E_chan_bits_t'('0);

    assign tl_A_bits_o.source = SOURCE_ID;
    assign tl_A_bits_o.address = {addr_d[63:3],3'b0};   // align with 8B
    assign tl_A_bits_o.param = tl_pkg::NtoB;
    assign tl_A_bits_o.size = '0;
    assign tl_A_bits_o.mask = align_8B ? 8'hF : 8'hF0; 
    assign tl_A_bits_o.data = align_8B ? {32'b0,axi_wdata_i} : {axi_wdata_i,32'b0}; 
    assign tl_A_bits_o.corrupt = 1'b0;

    assign axi_bresp_o = 2'b00; // always ok
    assign axi_rdata_o = align_8B ? tl_D_bits_i.data[31:0] : tl_D_bits_i.data[63:32];
    assign axi_rresp_o = 2'b00;

    assign align_8B = addr_d[2] == 1'b0;
    // read fsm 
    always_comb begin
        state_d = state_q;
        addr_d = addr_q;

        tl_A_valid_o = 1'b0;
        tl_D_ready_o = 1'b0;
        tl_A_bits_o.opcode = tl_pkg::Get;

        axi_awready_o = 1'b0;
        axi_wready_o = 1'b0;
        axi_arready_o = 1'b0;
        axi_rvalid_o = 1'b0;
        axi_bvalid_o = 1'b0;
        case(state_q)   
            IDLE: begin
                axi_awready_o = tl_A_ready_i;   // write has higher priority
                axi_wready_o  = tl_A_ready_i;
                axi_arready_o = tl_A_ready_i && !axi_awvalid_i;
                if(axi_awvalid_i && axi_awready_o) begin
                    state_d = (axi_wvalid_i && axi_wready_o) ? WAIT_WR_RSP : WAIT_W;
                    addr_d = axi_awaddr_i;
                    tl_A_valid_o = axi_wvalid_i && axi_wready_o;
                    tl_A_bits_o.opcode = tl_pkg::PutFullData;
                end else if (axi_arvalid_i && axi_arready_o) begin
                    state_d = READ;
                    addr_d = axi_araddr_i;
                    tl_A_valid_o = 1'b1;
                end
            end
            WAIT_W: begin
                tl_A_bits_o.opcode = tl_pkg::PutFullData;
                axi_wready_o = tl_A_ready_i;    
                tl_A_valid_o = axi_wvalid_i;
                if (axi_wvalid_i && axi_wready_o) begin
                    state_d = WAIT_WR_RSP;
                end
            end
            // finish
            WAIT_WR_RSP: begin
                tl_D_ready_o = axi_bready_i;
                axi_bvalid_o = tl_D_valid_i;
                if (axi_bvalid_o && axi_bready_i) begin
                    state_d = IDLE;
                end
            end
            READ: begin
                axi_rvalid_o = tl_D_valid_i;
                tl_D_ready_o = axi_rready_i;
                if (axi_rvalid_o && axi_rready_i) begin
                    state_d = IDLE;
                end      
            end
        endcase
    end

//======================================================================================================================
// Register
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i,rst_i)) begin : p_regs
        if(`DFF_IS_R(rst_i)) begin
            state_q <= IDLE;
            addr_q  <= '0;
        end else begin
            state_q <= state_d;
            addr_q  <= addr_d;
        end
    end

endmodule
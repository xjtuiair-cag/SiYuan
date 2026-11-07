// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : cpu_bootrom.v
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

module cpu_bootrom
(
    input  logic                            clk_i,
    // AXI-lite 32
    input  logic[31:0]                      axil32_awaddr_i,
    input  logic                            axil32_awvalid_i,
    output logic                            axil32_awready_o,
    input  logic[31:0]                      axil32_wdata_i,
    input  logic[3:0]                       axil32_wstrb_i,
    input  logic                            axil32_wvalid_i,
    output logic                            axil32_wready_o,
    output logic                            axil32_bvalid_o,
    input  logic                            axil32_bready_i,
    output logic[1:0]                       axil32_bresp_o,

    input  logic[31:0]                      axil32_araddr_i,
    input  logic                            axil32_arvalid_i,
    output logic                            axil32_arready_o,
    output logic[31:0]                      axil32_rdata_o,
    output logic                            axil32_rvalid_o,
    input  logic                            axil32_rready_i,
    output logic[1:0]                       axil32_rresp_o
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                                   rom_req;
    logic [63:0]                            rom_addr;
    logic [63:0]                            rom_rdata;
    logic                                   is_high_32bit;
    logic                                   rom_req_dly;
//======================================================================================================================
// Instance
//======================================================================================================================
    // AXI lite to reg 
    assign axil32_awready_o = 1'b0;
    assign axil32_wready_o  = 1'b0;
    assign axil32_arready_o = 1'b1;
    assign axil32_bvalid_o  = 1'b0;
    assign axil32_bresp_o   = 2'b0;
    assign axil32_rresp_o   = 2'b0;

    assign rom_req = axil32_arvalid_i;
    assign rom_addr = {32'h0,axil32_araddr_i[31:3],3'b0};

    always_ff @(posedge clk_i) begin
        rom_req_dly <= rom_req;
        is_high_32bit <= axil32_araddr_i[2];
    end

    // ---------------
    // ROM
    // ---------------
    `ifdef LOWRISC
        bootrom_lowrisc i_bootrom (
            .clk_i   ( clk_i     ),
            .req_i   ( rom_req   ),
            .addr_i  ( rom_addr  ),
            .rdata_o ( rom_rdata )
        ); 
    `endif

    `ifdef NORMAL
        bootrom i_bootrom (
            .clk_i   ( clk_i     ),
            .req_i   ( rom_req   ),
            .addr_i  ( rom_addr  ),
            .rdata_o ( rom_rdata )
        ); 
    `endif

    assign axil32_rvalid_o = rom_req_dly;
    assign axil32_rdata_o = is_high_32bit ? rom_rdata[63:32] : rom_rdata[31:0];

endmodule


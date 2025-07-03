// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_ppl_btb.v
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

module sy_ppl_btb 
    import sy_pkg::*;
#(
    parameter int BTB_ENTRIES = 512,
    parameter int BTB_ENTRY_WTH = $clog2(BTB_ENTRIES)
)(
    // =====================================
    // [clock & reset]
    input  logic                        clk_i,           
    input  logic                        rst_i,          
    input  logic                        flush_i,         
    // =====================================
    // [Virtual address from fronted]
    input  logic [AWTH-1:0]             vaddr_i,           
    // =====================================
    // [Update when retire]
    input  btb_update_t                 btb_update_i,    
    // =====================================
    // [BTB prediction]
    output btb_pred_t                   btb_pred_o 
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    localparam BTB_INDEX_LSB = 1;
    localparam BTB_INDEX_MSB = BTB_INDEX_LSB + BTB_ENTRY_WTH;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                           btb_ram_we;
    logic[BTB_ENTRY_WTH-1:0]        btb_ram_waddr; 
    logic[AWTH-1:0]                 btb_ram_wdata;
    logic                           btb_ram_re;
    logic[BTB_ENTRY_WTH-1:0]        btb_ram_raddr; 
    logic[AWTH-1:0]                 btb_ram_rdata;
    logic[BTB_ENTRIES-1:0]          btb_entry_valid_d,btb_entry_valid_q;
//======================================================================================================================
// Instance
//======================================================================================================================
    // update btb ram
    assign btb_ram_we    = btb_update_i.vld;
    assign btb_ram_waddr = btb_update_i.pc[BTB_INDEX_MSB-1:BTB_INDEX_LSB]; 
    assign btb_ram_wdata = btb_update_i.target_address;

    assign btb_ram_re    = 1'b1;
    assign btb_ram_raddr = vaddr_i[BTB_INDEX_MSB-1:BTB_INDEX_LSB];
    // btb ram
    sdp_512x64sd1_wrap btb_ram(
      .wr_clk_i                   (clk_i),              
      .we_i                       (btb_ram_we),          
      .waddr_i                    (btb_ram_waddr),             
      .wdata_i                    (btb_ram_wdata),             
      .wstrb_i                    (8'hff),             
      .rd_clk_i                   (clk_i),              
      .re_i                       (btb_ram_re),          
      .raddr_i                    (btb_ram_raddr),             
      .rdata_o                    (btb_ram_rdata)    
    );

    always_comb begin
        btb_entry_valid_d = btb_entry_valid_q;
        if (flush_i) begin
            btb_entry_valid_d   = '0;
        end else if (btb_ram_we) begin
            btb_entry_valid_d[btb_ram_waddr] = 1'b1;
        end
    end
    // read btb 
    always_ff @(posedge clk_i) begin
        btb_pred_o.vld <= btb_entry_valid_q[btb_ram_raddr]; // delay one cycle
    end
    assign btb_pred_o.target_address = btb_ram_rdata;
//======================================================================================================================
// Registers
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            btb_entry_valid_q <= '0;
        end else begin
            btb_entry_valid_q <= btb_entry_valid_d;
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================
endmodule

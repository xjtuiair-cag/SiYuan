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
    parameter int BTB_ENTRIES = 32,
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
    typedef struct packed {
        logic                           vld;
        logic[AWTH-1:0]                 target_address;    
    } btb_t;

    localparam BTB_INDEX_LSB = 3;
    localparam BTB_INDEX_MSB = BTB_INDEX_LSB + BTB_ENTRY_WTH;
//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                           btb_ram_we;
    logic[BTB_ENTRY_WTH-1:0]        btb_ram_waddr; 
    logic[AWTH-1:0]                 btb_ram_wdata;
    logic[BTB_ENTRY_WTH-1:0]        btb_ram_raddr; 

    logic[BTB_ENTRIES-1:0][63:0]    btb_entry_data_d,btb_entry_data_q;
    btb_t[BTB_ENTRIES-1:0]          btb_entry_d,btb_entry_q;
//======================================================================================================================
// Instance
//======================================================================================================================
    // update btb ram
    assign btb_ram_we    = btb_update_i.vld;
    assign btb_ram_waddr = btb_update_i.pc[BTB_INDEX_MSB-1:BTB_INDEX_LSB]; 
    assign btb_ram_wdata = btb_update_i.target_address;

    assign btb_ram_raddr = vaddr_i[BTB_INDEX_MSB-1:BTB_INDEX_LSB];
    // btb update
    always_comb begin
        btb_entry_d = btb_entry_q;
        if (btb_ram_we) begin
            btb_entry_d[btb_ram_waddr].vld = 1'b1;
            btb_entry_d[btb_ram_waddr].target_address = btb_ram_wdata;
        end
        if (flush_i) begin
            for (integer i = 0; i < BTB_ENTRIES; i++) begin
                btb_entry_d[i].vld = 1'b0;
            end
        end
    end

    // read btbt
    assign btb_pred_o = btb_entry_q[btb_ram_raddr];
//======================================================================================================================
// Registers
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i, rst_i)) begin
        if(`DFF_IS_R(rst_i)) begin
            for (integer i = 0; i < BTB_ENTRIES; i++) begin
                btb_entry_q[i] <= btb_t'(0);
            end
        end else begin
            for (integer i = 0; i < BTB_ENTRIES; i++) begin
                btb_entry_q[i] <= btb_entry_d[i];
            end
        end
    end
//======================================================================================================================
// Signals for simulation or probes
//======================================================================================================================

endmodule

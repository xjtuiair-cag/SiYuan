// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : TL2APB.v
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

module TL2APB
    import sy_pkg::*;
#(
    parameter       APB_ADDR_WIDTH = 32,
    parameter       APB_DATA_WIDTH = 32
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
    // [APB bus]
    output logic 					        penable_o,
    output logic 					        pwrite_o,
    output logic [APB_ADDR_WIDTH-1:0] 		paddr_o,
    output logic                            psel_o,
    output logic [APB_DATA_WIDTH-1:0] 		pwdata_o,
    input  logic [APB_DATA_WIDTH-1:0] 		prdata_i,
    input  logic 					        pready_i,
    input  logic 					        pslverr_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic                                   tl_a_fifo_push;
    logic                                   tl_a_fifo_pop;
    logic                                   tl_a_fifo_full;    
    logic                                   tl_a_fifo_empty;    
    tl_pkg::A_chan_bits_t                   tl_a_fifo_data; 
    logic                                   tl_d_fifo_push;
    logic                                   tl_d_fifo_pop;
    logic                                   tl_d_fifo_full;    
    logic                                   tl_d_fifo_empty;    
    tl_pkg::D_chan_bits_t                   tl_d_fifo_data; 
    logic                                   is_write;
    logic                                   a_sel;
    logic                                   a_enable_d, a_enable_q;
    logic                                   pause_req, pause_req_dly;
    logic                                   save_size_source;
    tl_pkg::size_t                          d_size_d, d_size_q;
    tl_pkg::source_t                        d_source_d, d_source_q;
    logic                                   d_write_d, d_write_q;
    logic                                   is_low_32bit;

//======================================================================================================================
// transform TL A channel to APB channel
//======================================================================================================================
    assign is_low_32bit = tl_a_fifo_data.mask[3:0] != 4'b0;
    assign tl_a_fifo_push = TL_A_valid_i && !tl_a_fifo_full;
    assign TL_A_ready_o = !tl_a_fifo_full;

    assign is_write = tl_a_fifo_data.opcode == tl_pkg::PutFullData || tl_a_fifo_data.opcode == tl_pkg::PutPartialData;
    assign pause_req = TL_D_valid_o && !TL_D_ready_i; // if D channel request don't be accept, pause 
    assign a_sel = !tl_a_fifo_empty && !pause_req_dly;
    assign a_enable_d = a_sel ? 1'b1 : (TL_D_valid_o && TL_D_ready_i ? 1'b0 : a_enable_q);

    assign save_size_source = a_sel && !a_enable_q;
    assign d_size_d = save_size_source ? tl_a_fifo_data.size : d_size_q;
    assign d_source_d = save_size_source ? tl_a_fifo_data.source : d_source_q;
    assign d_write_d = save_size_source ? is_write : d_write_q;

    assign penable_o        =   a_enable_q; 
    assign pwrite_o         =   is_write; 
    assign paddr_o          =   tl_a_fifo_data.address[APB_ADDR_WIDTH-1:0] + (is_low_32bit ? 4'd0 : 4'd4); 
    assign psel_o           =   a_sel; 
    assign pwdata_o         =   is_low_32bit ? tl_a_fifo_data.data[APB_DATA_WIDTH-1:0] 
                                    : tl_a_fifo_data.data[32+:APB_DATA_WIDTH]; 

    assign tl_a_fifo_pop = a_enable_q && pready_i && !tl_a_fifo_empty;

    assign tl_d_fifo_push = a_enable_q && pready_i && !tl_d_fifo_full;
    assign tl_d_fifo_pop = TL_D_valid_o && TL_D_ready_i && !tl_d_fifo_empty; 
    assign TL_D_valid_o = !tl_d_fifo_empty;

    assign tl_d_fifo_data.opcode                = d_write_q ? tl_pkg::AccessAckData : tl_pkg::AccessAck;
    assign tl_d_fifo_data.param.permission      = tl_pkg::toT;
    assign tl_d_fifo_data.size                  = d_size_q;  
    assign tl_d_fifo_data.source                = d_source_q;
    assign tl_d_fifo_data.sink                  = '0;
    assign tl_d_fifo_data.denied                = d_write_q && pslverr_i;
    assign tl_d_fifo_data.data                  = is_low_32bit ? prdata_i : (prdata_i << 32);
    assign tl_d_fifo_data.corrupt               = !d_write_q && pslverr_i;

    fifo_v3 #(
          .FALL_THROUGH (1'b0), 
          .DEPTH        (1),    
          .dtype        (tl_pkg::A_chan_bits_t)
    ) TL_A_fifo(
        .clk_i                      (clk_i),                               
        .rst_ni                     (rst_i),                               
        .flush_i                    (1'b0),                               
        .testmode_i                 (1'b0),                               
        .full_o                     (tl_a_fifo_full),                               
        .empty_o                    (tl_a_fifo_empty),                               
        .usage_o                    (),                                 
        .data_i                     (TL_A_bits_i),                               
        .push_i                     (tl_a_fifo_push),                               
        .data_o                     (tl_a_fifo_data),                               
        .pop_i                      (tl_a_fifo_pop)       
    );

    fifo_v3 #(
          .FALL_THROUGH (1'b0), 
          .DEPTH        (1),    
          .dtype        (tl_pkg::D_chan_bits_t)
    ) TL_D_fifo(
        .clk_i                      (clk_i),                               
        .rst_ni                     (rst_i),                               
        .flush_i                    (1'b0),                               
        .testmode_i                 (1'b0),                               
        .full_o                     (tl_d_fifo_full),                               
        .empty_o                    (tl_d_fifo_empty),                               
        .usage_o                    (),                                 
        .data_i                     (tl_d_fifo_data),                               
        .push_i                     (tl_d_fifo_push),                               
        .data_o                     (TL_D_bits_o),                               
        .pop_i                      (tl_d_fifo_pop)       
    );

//======================================================================================================================
// Register
//======================================================================================================================
    always_ff @(`DFF_CR(clk_i,rst_i)) begin : p_regs
        if(`DFF_IS_R(rst_i)) begin
            a_enable_q      <= '0;
            pause_req_dly   <= '0;
            d_size_q        <= tl_pkg::size_t'('0);
            d_source_q      <= tl_pkg::source_t'('0);
            d_write_q       <= '0;
        end else begin
            a_enable_q      <= a_enable_d;
            pause_req_dly   <= pause_req;
            d_size_q        <= d_size_d;
            d_source_q      <= d_source_d;
            d_write_q       <= d_write_d;
        end
    end

endmodule
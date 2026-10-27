// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_uart.v
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

module sy_uart
    import sy_pkg::*;
(
    input  logic                        clk_i,
    input  logic                        rst_i,
    input  logic                        rx_i,
    output logic                        tx_o,

    output logic                        irq_o,
    // A Channel
    input  logic                        inp_tl_A_valid_i,
    output logic                        inp_tl_A_ready_o,
    input  tl_pkg::A_chan_bits_t        inp_tl_A_bits_i,
    // B Channel
    output logic                        inp_tl_B_valid_o,
    input  logic                        inp_tl_B_ready_i,
    output tl_pkg::B_chan_bits_t        inp_tl_B_bits_o,
    // C Channel
    input  logic                        inp_tl_C_valid_i,
    output logic                        inp_tl_C_ready_o,
    input  tl_pkg::C_chan_bits_t        inp_tl_C_bits_i,
    // D Channel
    output logic                        inp_tl_D_valid_o,
    input  logic                        inp_tl_D_ready_i,
    output tl_pkg::D_chan_bits_t        inp_tl_D_bits_o,
    // E Channel
    input  logic                        inp_tl_E_valid_i,
    output logic                        inp_tl_E_ready_o,
    input  tl_pkg::E_chan_bits_t        inp_tl_E_bits_i
);

//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    logic         uart_penable;
    logic         uart_pwrite;
    logic [31:0]  uart_paddr;
    logic         uart_psel;
    logic [31:0]  uart_pwdata;
    logic [31:0]  uart_prdata;
    logic         uart_pready;
    logic         uart_pslverr;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign inp_tl_B_valid_o = 1'b0;
    assign inp_tl_B_bits_o  = tl_pkg::B_chan_bits_t'(0);
    assign inp_tl_E_ready_o = 1'b1;
    assign inp_tl_C_ready_o = 1'b1;
    TL2APB #(
        .APB_ADDR_WIDTH (32),
        .APB_DATA_WIDTH (32)
    ) tl_2_apb (
        .clk_i                  (clk_i          ),         
        .rst_i                  (rst_i          ),         
        
        .TL_A_valid_i           (inp_tl_A_valid_i),                 
        .TL_A_ready_o           (inp_tl_A_ready_o),                 
        .TL_A_bits_i            (inp_tl_A_bits_i ),               

        .TL_D_valid_o           (inp_tl_D_valid_o),                 
        .TL_D_ready_i           (inp_tl_D_ready_i),                 
        .TL_D_bits_o            (inp_tl_D_bits_o ),               
        
        .penable_o              (uart_penable   ),             
        .pwrite_o               (uart_pwrite    ),            
        .paddr_o                (uart_paddr     ),           
        .psel_o                 (uart_psel      ),          
        .pwdata_o               (uart_pwdata    ),            
        .prdata_i               (uart_prdata    ),            
        .pready_i               (uart_pready    ),            
        .pslverr_i              (uart_pslverr   )
    );

    apb_uart i_apb_uart (
        .CLK     ( clk_i           ),
        .RSTN    ( rst_i           ),
        .PSEL    ( uart_psel       ),
        .PENABLE ( uart_penable    ),
        .PWRITE  ( uart_pwrite     ),
        .PADDR   ( uart_paddr[4:2] ),
        .PWDATA  ( uart_pwdata     ),
        .PRDATA  ( uart_prdata     ),
        .PREADY  ( uart_pready     ),
        .PSLVERR ( uart_pslverr    ),
        .INT     ( irq_o           ),
        .OUT1N   (                 ), // keep open
        .OUT2N   (                 ), // keep open
        .RTSN    (                 ), // no flow control
        .DTRN    (                 ), // no flow control
        .CTSN    ( 1'b0            ),
        .DSRN    ( 1'b0            ),
        .DCDN    ( 1'b0            ),
        .RIN     ( 1'b0            ),
        .SIN     ( rx_i            ),
        .SOUT    ( tx_o            )
    );
endmodule
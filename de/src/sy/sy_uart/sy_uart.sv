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
  input  logic                            clk_i,
  input  logic                            rst_i,
  input  logic                            rx_i,
  output logic                            tx_o,

  output logic                            irq_o,
  
  TL_BUS.Master                           master
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
    TL2APB #(
        .APB_ADDR_WIDTH (32),
        .APB_DATA_WIDTH (32)
    ) tl_2_apb (
        .clk_i                  (clk_i          ),         
        .rst_i                  (rst_i          ),         
        
        .TL_A_valid_i           (master.a_valid ),                 
        .TL_A_ready_o           (master.a_ready ),                 
        .TL_A_bits_i            (master.a_bits  ),               

        .TL_D_valid_o           (master.d_valid ),                 
        .TL_D_ready_i           (master.d_ready ),                 
        .TL_D_bits_o            (master.d_bits  ),               
        
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
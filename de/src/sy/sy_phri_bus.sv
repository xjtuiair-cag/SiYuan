// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_phri_bus.v
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


module sy_phri_bus
    import sy_soc_pkg::*;
#(
    parameter MASTER_NUM            = 1,
    parameter SLAVE_NUM             = 4,
    parameter REGION_NUM            = 1,
    parameter SOURCE_LSB            = 0,
    parameter SOURCE_MSB            = 1,
    parameter SINK_LSB              = 0,
    parameter SINK_MSB              = 1,
    parameter TL_ADDR_WIDTH         = 64,
    parameter MASTER_BUF_DEPTH      = 1,
    parameter SLAVE_BUF_DEPTH       = 1
)(
    input   logic                                   clk_i,
    input   logic                                   rst_i,
    TL_BUS.Master                                   master,
    // irq 
    output  logic                                   uart_irq_o,
    output  logic                                   spi_irq_o,
    // Uart
    input   logic                                   uart_rx,
    output  logic                                   uart_tx,
    // spi
    output logic                                    spi_clk_o,
    output logic                                    spi_mosi, 
    input  logic                                    spi_miso, 
    output logic                                    spi_ss   
);
//======================================================================================================================
// Parameters
//======================================================================================================================

//======================================================================================================================
// Wire & Reg declaration
//======================================================================================================================
    TL_BUS phri_bus_master  [0:0]();
    TL_BUS phri_bus_slave   [PHRI_BUS_SLAVE_NUM-1:0]();
//======================================================================================================================
// ctrl bus xbar
//======================================================================================================================
    tl_slave2master phri_bus_trans(.slave(master), .master(phri_bus_master[0]));

    sy_tl_xbar #(
        .MASTER_NUM       (1),
        .SLAVE_NUM        (PHRI_BUS_SLAVE_NUM),
        .REGION_NUM       (PHRI_BUS_REGION),
        .SOURCE_LSB       (PHRI_BUS_SRC_LSB),
        .SOURCE_MSB       (PHRI_BUS_SRC_MSB),
        .SINK_LSB         (1),
        .SINK_MSB         (4),
        .TL_ADDR_WIDTH    (64),
        .MASTER_BUF_DEPTH (1),
        .SLAVE_BUF_DEPTH  (1)
    ) ctrl_bus(
        .clk_i            ( clk_i         ),
        .rst_i            ( rst_i         ),
        .master           ( phri_bus_master),
        .slave            ( phri_bus_slave),
        .start_addr_i     ( phri_bus_start_addr),
        .end_addr_i       ( phri_bus_end_addr),
        .region_en_i      ( phri_bus_region_en)
    );
//======================================================================================================================
// Bootrom
//======================================================================================================================
    sy_bootrom bootrom(
        .clk_i       (clk_i),
        .rst_i       (rst_i),
        .master      (phri_bus_slave[ROM])
    );
//======================================================================================================================
// Uart
//======================================================================================================================
    sy_uart uart(
        .clk_i          (clk_i),         
        .rst_i          (rst_i),         
        .rx_i           (uart_rx),        
        .tx_o           (uart_tx),        
        .irq_o          (uart_irq_o),     
        .master         (phri_bus_slave[UART])
    );
//======================================================================================================================
// SPI
//======================================================================================================================
    sy_spi spi(
        .clk_i          (clk_i),    
        .rst_i          (rst_i),    
    
        .irq_o          (spi_irq_o),    
    
        .spi_clk_o      (spi_clk_o),         
        .spi_mosi       (spi_mosi),         
        .spi_miso       (spi_miso),         
        .spi_ss         (spi_ss),         
    
        .master         (phri_bus_slave[SPI])
    );       
//======================================================================================================================
// GPIO
//======================================================================================================================
    if (GPIO_EN) begin
        sy_gpio gpio(
            .clk_i              (clk_i),       
            .rst_i              (rst_i),     

            .leds_o             (led),      
            .dip_switches_i     (sw),              

            .master             (phri_bus_slave[GPIO])
        );
    end else begin
        assign led = '0;
    end

endmodule
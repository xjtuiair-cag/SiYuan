// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tb_sy_debug.v
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


module tb_sy_debug;

    logic                           clk;
    logic                           rst;
    logic                           tck; 
    logic                           tms; 
    logic                           trst_n;
    logic                           tdi; 
    logic                           tdo;
    logic[31:0]                     exit_code;
    sy_soc_sim #(
        .DDR_SIZE (64*1024*1024)
    ) soc_inst(
        // =====================================
        // [clock & reset]
        .clk_i                                  (clk),                              
        .rst_i                                  (rst),                              
        // SPI interface (we don't use SPI in dma test)
        .spi_mosi                               (),
        .spi_miso                               (),
        .spi_ss                                 (),
        .spi_clk_o                              (),
        // JTAG
        .tck                                    (tck),
        .tms                                    (tms),
        .trst_n                                 (trst_n),
        .tdi                                    (tdi),
        .tdo                                    (tdo),
        // =====================================
        .boot_addr_i                            (64'h8000_0000)                    
    );

    SimJTAG #(.TICK_DELAY(50)) simjtag_inst (
        .clock       (clk),
        .reset       (~rst),

        .enable      (1'b1),
        .init_done   (1'b1),  // 可以用某个“系统初始化完成”的信号代替

        .jtag_TCK    (tck),
        .jtag_TMS    (tms),
        .jtag_TDI    (tdi),
        .jtag_TRSTn  (trst_n),

        .jtag_TDO_data   (tdo),
        .jtag_TDO_driven (1'b1),   // 表示 jtag_TDO 始终有效

        .exit        (exit_code)
    );


    // clock generation
    initial begin
        clk = 1'b0;
        #1;
        forever begin
            #1.67 clk <= !clk; // 500MHz
        end
    end

    // reset generation
    initial begin
        rst = 1'b1;
        #10;
        rst = 1'b0;
        #10;
        rst = 1'b1;
    end

    initial begin
        $fsdbDumpfile("tb_sy_debug.fsdb");
        $fsdbDumpvars(0, tb_sy_debug, "+mda", "+all");
        //$vcdplusmemon();
    end

endmodule
// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tb_sy_spi.v
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


module tb_sy_spi;

    logic                           clk;
    logic                           rst;

    logic                           spi_clk;
    logic                           spi_cs;
    logic                           spi_mosi;
    logic                           spi_miso;

    logic                           sd_clk;
    logic                           sd_cmd_i;
    logic                           sd_cmd_o;
    logic                           sd_cmd_t;
    logic [3:0]                     sd_dat_i;
    logic [3:0]                     sd_dat_o;
    logic [3:0]                     sd_dat_t;

    logic                           wbm_clk;
    logic [31:0]                    wbm_adr;
    logic [31:0]                    wbm_dat_o;
    logic [31:0]                    wbm_dat_i;
    logic [3:0]                     wbm_sel;
    logic                           wbm_cyc;
    logic                           wbm_stb;
    logic                           wbm_we ;
    logic                           wbm_ack;
    logic [2:0]                     wbm_cti;
    logic [1:0]                     wbm_bte;



    sy_soc_sim #(
        .DDR_SIZE (64*1024*1024)
    ) soc_inst(
        // =====================================
        // [clock & reset]
        .clk_i                                  (clk),                              
        .rst_i                                  (rst),                              
        // SPI interface
        .spi_mosi                               (spi_mosi),
        .spi_miso                               (spi_miso),
        .spi_ss                                 (spi_cs),
        .spi_clk_o                              (spi_clk),
        // =====================================
        .boot_addr_i                            (64'h8000_0000)                    
    );

    assign sd_cmd_i = spi_mosi;
    assign sd_dat_i[2:0] = '0;
    assign sd_dat_i[3] = spi_cs;
    assign spi_miso = sd_dat_o[0];
    assign sd_clk = spi_clk;

    sd_top u_sd(
       // clocking/reset
       .clk_50            (clk),
       .clk_100           (clk),
       .clk_200           (clk),
       .reset_n           (rst),
       // physical interface to SD pins
       .sd_clk            (sd_clk),
       .sd_cmd_i          (sd_cmd_i),
       .sd_cmd_o          (sd_cmd_o),
       .sd_cmd_t          (sd_cmd_t),
       .sd_dat_i          (sd_dat_i),
       .sd_dat_o          (sd_dat_o),
       .sd_dat_t          (sd_dat_t),
       // wishbone interface
       .wbm_clk_o         (wbm_clk),
       .wbm_adr_o         (wbm_adr),
       .wbm_dat_i         (wbm_dat_i),
       .wbm_dat_o         (wbm_dat_o),
       .wbm_sel_o         (wbm_sel),
       .wbm_cyc_o         (wbm_cyc),
       .wbm_stb_o         (wbm_stb),
       .wbm_we_o          (wbm_we ),
       .wbm_ack_i         (wbm_ack),
       .wbm_cti_o         (wbm_cti),
       .wbm_bte_o         (wbm_bte),
       // options
       .opt_enable_hs     ('0)
       // debug (optional)
    );

    wb_ram #(
        .depth (16384),
        .memfile ("./test_data.dat")
    ) u_wb_ram(
        .wb_clk_i         (wbm_clk),    
        .wb_rst_i         (!rst),    

        .wb_adr_i         (wbm_adr),    
        .wb_dat_i         (wbm_dat_o),    
        .wb_sel_i         (wbm_sel),    
        .wb_we_i          (wbm_we),   
        .wb_bte_i         (wbm_bte),    
        .wb_cti_i         (wbm_cti),    
        .wb_cyc_i         (wbm_cyc),    
        .wb_stb_i         (wbm_stb),    

        .wb_ack_o         (wbm_ack),    
        .wb_err_o         (),    
        .wb_dat_o         (wbm_dat_i)
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
        $fsdbDumpfile("tb_sy_spi.fsdb");
        $fsdbDumpvars(0, tb_sy_spi, "+mda", "+all");
        //$vcdplusmemon();
    end

endmodule
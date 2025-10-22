// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tb_sy_riscv_test.v
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

import "DPI-C" function string getenv (input string env_name);

module tb_sy_riscv_test;
logic                           clk;
logic                           rst;

`define DCACHE_CTRL soc_inst.gen_hart[0].u_sy_inst.L1_cache.i_dcache_inst.dcache_ctrl_inst

sy_soc_sim #(
    .DDR_SIZE (64*1024*1024)
) soc_inst(
    // =====================================
    // [clock & reset]
    .clk_i                                  (clk),                              // input   logic                           
    .rst_i                                  (rst),                              // input   logic                           
    // SPI interface (we don't use SPI in riscv test)
    .spi_mosi                               (),
    .spi_miso                               (),
    .spi_ss                                 (),
    .spi_clk_o                              (),
    // JTAG
    .tck                                    ('0),
    .tms                                    ('0),
    .trst_n                                 ('0),
    .tdi                                    ('0),
    .tdo                                    (),
    // =====================================
    .boot_addr_i                            (64'h80000000)                    // input   logic[AWTH-1:0]                 
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


integer res;
string s;
string state;
logic [63:0] wb_addr;

initial begin
    state = getenv("WB_ADDR");
    if (state == "0x80001000") begin
        wb_addr = 64'h80001000;
    end else if (state == "0x80002000") begin
        wb_addr = 64'h80002000;
    end else if (state == "0x80003000") begin
        wb_addr = 64'h80003000;
    end else begin
        wb_addr = 64'h80001000;
    end
end

initial begin
    res = $fopen("res.txt","w");
    forever begin
        @(posedge clk iff (`DCACHE_CTRL.cache_wr_en == 1'b1 && 
            {`DCACHE_CTRL.dc_req_bits_st2.addr_tag,`DCACHE_CTRL.dc_req_bits_st2.addr_inx} == wb_addr));
        if(`DCACHE_CTRL.cache_wr_data_st2 == 64'b1) begin
            s = { "\n##########################################################\n"};
            s = {s, "#                ####    #    ####  ####                 #\n"};
            s = {s, "#                #  #   # #   #     #                    #\n"};
            s = {s, "#                ####  #####  ####  ####                 #\n"};
            s = {s, "#                #     #   #     #     #                 #\n"};
            s = {s, "#                #     #   #  ####  ####                 #\n"};
            s = {s, "##########################################################\n"};
            s = {s, "####################### TEST PASS ########################\n"};
            s = {s, "##########################################################\n"};
            $display("%s",s);
            $fwrite(res,"TEST PASS");
        end else begin
            s = { "\n##########################################################\n"};
            s = {s, "#           ####    #    ###  #     ####  ###            #\n"};
            s = {s, "#           #      # #    #   #     #     #  #           #\n"};
            s = {s, "#           ####  #####   #   #     ####  #  #           #\n"};
            s = {s, "#           #     #   #   #   #     #     #  #           #\n"};
            s = {s, "#           #     #   #  ###  ####  ####  ###            #\n"};
            s = {s, "##########################################################\n"};
            s = {s, "###################### TEST FAILED #######################\n"};
            s = {s, "##########################################################\n"};
            $display("%s",s);
            $display("TEST FAIL: %h",`DCACHE_CTRL.cache_wr_data_st2);
            $fwrite(res,"TEST FAIL: %h",`DCACHE_CTRL.cache_wr_data_st2);
        end
        $finish;
    end
end

initial begin
    $fsdbDumpfile("tb_sy_riscv_test.fsdb");
    $fsdbDumpvars(0, tb_sy_riscv_test, "+mda", "+all");
    //$vcdplusmemon();
end

endmodule
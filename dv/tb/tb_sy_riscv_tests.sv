// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tb_sy_riscv_tests.v
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

module tb_sy_riscv_tests;
logic                           clk;
logic                           rst;

sy_soc_sim soc_inst(
    // =====================================
    // [clock & reset]
    .clk_i                                  (clk),                              // input   logic                           
    .rst_i                                  (rst),                              // input   logic                           
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
        @(posedge clk iff (soc_inst.u_sy_inst.lsu_inst.lsu_dcache__vld_o == 1'b1 && 
            soc_inst.u_sy_inst.lsu_inst.lsu_dcache__req_o.we == 1'b1 && 
            soc_inst.u_sy_inst.lsu_inst.lsu_dcache__req_o.paddr == wb_addr));
        if(soc_inst.u_sy_inst.lsu_inst.lsu_dcache__req_o.data == 64'b1) begin
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
            $display("TEST FAIL: %h",soc_inst.u_sy_inst.lsu_inst.lsu_dcache__req_o.data);
            $fwrite(res,"TEST FAIL: %h",soc_inst.u_sy_inst.lsu_inst.lsu_dcache__req_o.data);
        end
        $finish;
    end
end

initial begin
    $fsdbDumpfile("tb_sy_riscv_tests.fsdb");
    $fsdbDumpvars(0, tb_sy_riscv_tests, "+mda", "+all");
    //$vcdplusmemon();
end

endmodule
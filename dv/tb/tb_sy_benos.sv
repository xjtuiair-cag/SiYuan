// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tb_sy_benos.v
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

module tb_sy_benos;

    logic                           clk;
    logic                           rst;

    sy_soc_sim soc_inst(
        // =====================================
        // [clock & reset]
        .clk_i                                  (clk),                              
        .rst_i                                  (rst),                              
        // =====================================
        .boot_addr_i                            (64'h8000_0000)                    
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
        $fsdbDumpfile("tb_sy_benos.fsdb");
        $fsdbDumpvars(0, tb_sy_benos, "+mda", "+all");
        //$vcdplusmemon();
    end

endmodule
// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : glb_def.v
// DEPARTMENT : CAG of IAIR
// AUTHOR     : 
// AUTHOR'S EMAIL :
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

`ifndef GLB_DEF_SVH
`define GLB_DEF_SVH

// Set platform type
// `define PLATFORM_SIM
// `define PLATFORM_XILINX
//`define PLATFORM_ASIC

`define TCQ #0.01

`define S(size) [(size)-1 : 0]

// -----
// Set HPU reset mode
`define NEG_RST
`define ASYNC_RST

`ifdef ASYNC_RST
    `ifdef NEG_RST
        `define DFF_CR(clk, sig) posedge clk or negedge sig
        `define DFF_IS_R(sig) !(sig)
    `else
        `define DFF_CR(clk, sig) posedge clk or posedge sig
        `define DFF_IS_R(sig) (sig)
    `endif
`else
    `ifdef NEG_RST
        `define DFF_CR(clk, sig) posedge clk
        `define DFF_IS_R(sig) !(sig)
    `else
        `define DFF_CR(clk, sig) posedge clk
        `define DFF_IS_R(sig) (sig)
    `endif
`endif

`define DF(out, clk, in) \
    always_ff @(posedge clk) begin \
        out <= `TCQ in; \
    end

`define DFC(out, clk, clr, in) \
    always_ff @(posedge clk) begin \
        if(clr) begin \
            out <= `TCQ 0; \
        end else begin \
            out <= `TCQ in; \
        end \
    end

`define DFE(out, clk, en, in) \
    always_ff @(posedge clk) begin \
        if(en) begin \
            out <= `TCQ in; \
        end \
    end

`define DFCE(out, clk, clr, en, in) \
    always_ff @(posedge clk) begin \
        if(clr) begin \
            out <= `TCQ 0; \
        end else if(en) begin \
            out <= `TCQ in; \
        end \
    end

`define DFR(out, clk, rst, rstval, in) \
    always_ff @(`DFF_CR(clk, rst)) begin \
        if(`DFF_IS_R(rst)) begin \
            out <= `TCQ rstval; \
        end else begin \
            out <= `TCQ in; \
        end \
    end

`define DFRC(out, clk, rst, rstval, in) \
    always_ff @(`DFF_CR(clk, rst)) begin \
        if(`DFF_IS_R(rst)) begin \
            out <= `TCQ rstval; \
        end else if(clr) begin \
            out <= `TCQ 0; \
        end else begin \
            out <= `TCQ in; \
        end \
    end

`define DFRE(out, clk, rst, rstval, en, in) \
    always_ff @(`DFF_CR(clk, rst)) begin \
        if(`DFF_IS_R(rst)) begin \
            out <= `TCQ rstval; \
        end else if(en) begin \
            out <= `TCQ in; \
        end \
    end

`define DFRCE(out, clk, rst, rstval, en, in) \
    always_ff @(`DFF_CR(clk, rst)) begin \
        if(`DFF_IS_R(rst)) begin \
            out <= `TCQ rstval; \
        end else if(clr) begin \
            out <= `TCQ 0; \
        end else if(en) begin \
            out <= `TCQ in; \
        end \
    end

`endif
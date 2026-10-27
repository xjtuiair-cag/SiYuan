// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : cdc_sync.sv
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

// Clock Domain Crossing Pulse-to-Pulse Converter
// This module safely transfers a single-cycle pulse from one clock domain to another. It uses a toggle-based
// synchronization method to ensure reliable pulse transmission across clock domain boundaries while minimizing
// metastability issues.

module cdc_pulse2pulse (
    // Clock and reset
    input                                   a_clk_i,        // Clock for domain A (input pulse domain)
    input                                   a_rst_i,        // Reset for domain A
    input                                   b_clk_i,        // Clock for domain B (output pulse domain)
    input                                   b_rst_i,        // Reset for domain B
    // Port A - Input pulse
    input                                   a_sig_i,        // Single-cycle pulse input in domain A
    // Port B - Output pulse
    output                                  b_sig_o         // Single-cycle pulse output in domain B
);

// =====================================================================================================================
// Local parameters

// =====================================================================================================================
// Local variables

logic                           a_sig_dly;
logic                           a_sig_flag;
logic                           b_sig_flag;
logic                           b_sig_flag_dly;

// =====================================================================================================================
// Instances

// --------------
// Domain A logic

// Detects input pulses and generates toggle signal
always@(`DFF_CR(a_clk_i, a_rst_i)) begin
    if (`DFF_IS_R(a_rst_i)) begin
        a_sig_dly <= `TCQ 1'b0;
        a_sig_flag <= `TCQ 1'b0;
    end else begin
        a_sig_dly <= `TCQ a_sig_i; // Store previous input pulse value
        // On rising edge of input pulse, toggle the flag
        if(!a_sig_dly && a_sig_i) begin
            a_sig_flag <= `TCQ ~a_sig_flag;
        end
    end
end

// --------------
// Domain B logic

cdc_sync # (
    .DTYPE                                  (logic),
    .DLY                                    (2),
    .RST_VAL                                (1'b0)
) u_b_sig_flag (
    // clock & reset
    .clk_i                                  (b_clk_i),          // input   logic
    .rst_i                                  (b_rst_i),          // input   logic
    // data need to be synchronized
    .data_i                                 (a_sig_flag),       // input   DTYPE
    .data_o                                 (b_sig_flag)        // output  DTYPE
);

// Synchronizes toggle signal and generates output pulse
always@(`DFF_CR(b_clk_i, b_rst_i)) begin
    if(`DFF_IS_R(b_rst_i)) begin
        b_sig_flag_dly   <= `TCQ 1'b0;
    end else begin
        // Delay for edge detection
        b_sig_flag_dly   <= `TCQ b_sig_flag;
    end
end

// Output pulse generation
// XOR of synchronized flag and its delayed version creates a single-cycle pulse
// when the flag changes value (indicating a pulse was received in domain A)
assign b_sig_o = b_sig_flag_dly ^ b_sig_flag;

// =====================================================================================================================
// Assertions

// =====================================================================================================================
// Probes

// synopsys translate_off

// synopsys translate_on

endmodule : cdc_pulse2pulse
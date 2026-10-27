module sp_512x64sd1_wrap # (
    parameter AW = 9,
    parameter DW = 64,
    parameter DWS = 8,
    parameter RD_DLY = 1
) (
    // -------------------------------------
    // [clock & reset]
    input   logic                           clk_i,
    // -------------------------------------
    // [Access port]
    input   logic                           vld_i,
    input   logic                           we_i,
    input   logic[AW-1:0]                   addr_i,
    input   logic[DW-1:0]                   wdata_i,
    input   logic[DWS-1:0]                  wstrb_i,
    output  logic[DW-1:0]                   rdata_o
);

// =====================================================================================================================
// Local parameters
localparam DEPTH = 2**AW;

//======================================================================================================================
// Local variables

logic                           we;
logic[DWS-1:0]                  wea;
logic[DW-1:0]                   wbe;
logic                           re;
logic[RD_DLY-1:0]               re_dly;
logic                           enb;
logic                           ceb;
logic                           web;
logic[DW-1:0]                   wbeb;

// =====================================================================================================================
// Instances

assign we = vld_i && we_i;
if(DWS == 1) begin
    assign wea = we;
    assign wbe = {DW{we}};
end else begin
    always_comb begin
        for(integer i=0; i<DWS; i++) begin
            wea[i] = we && wstrb_i[i];
            wbe[i*(DW/DWS) +: (DW/DWS)] = {DW/DWS{we && wstrb_i[i]}};
        end
    end
end

assign re = vld_i && !we_i;
always_ff @(posedge clk_i) begin
    re_dly <=  re;
end
always_comb begin
    enb = re;
    for(integer i=0; i<RD_DLY; i++) begin
        enb = enb || re_dly[i];
    end
end

// For ASIC SRAM
// [Note] signal end with letter 'b' is low active.
assign ceb = !(vld_i || enb);
assign web = !we_i;
assign wbeb = ~wbe;
// Memory instance

`ifdef PLATFORM_SIM
    sp_sram_unified #(
        .AWTH                           (AW),
        .DWTH                           (DW),
        .RD_TYPE                        ("READ_FIRST"),
        .RD_DELAY                       (RD_DLY)
    ) u_sp_sram (
        .clk_i                          (clk_i),        // input   logic
        .we_i                           (we),           // input   logic
        .addr_i                         (addr_i),       // input   logic[AWTH-1:0]
        .wdata_i                        (wdata_i),      // input   logic[DWTH-1:0]
        .wbe_i                          (wbe),          // input   logic[DWTH-1:0]
        .rdata_o                        (rdata_o)       // output  logic[DWTH-1:0]
    );
`endif

`ifdef PLATFORM_XILINX
    xpm_memory_sdpram #(
        .MEMORY_SIZE(DEPTH*DW),         // DECIMAL
        .MEMORY_PRIMITIVE("auto"),      // String
        .CLOCKING_MODE("common_clock"), // String
        .ECC_MODE("no_ecc"),            // String
        // Port A
        .ADDR_WIDTH_A(AW),              // DECIMAL
        .WRITE_DATA_WIDTH_A(DW),        // DECIMAL
        .BYTE_WRITE_WIDTH_A(DW/DWS),    // DECIMAL
        // Port B
        .ADDR_WIDTH_B(AW),              // DECIMAL
        .READ_DATA_WIDTH_B(DW),         // DECIMAL
        .READ_RESET_VALUE_B("0"),       // String
        .READ_LATENCY_B(RD_DLY),        // DECIMAL
        .WRITE_MODE_B("no_change"),     // String
        // MISC
        .MEMORY_OPTIMIZATION("true"),   // String
        .USE_MEM_INIT(0),               // DECIMAL
        .MEMORY_INIT_FILE("none"),      // String
        .MEMORY_INIT_PARAM("0"),        // String
        .WAKEUP_TIME("disable_sleep"),  // String
        .AUTO_SLEEP_TIME(0),            // DECIMAL
        .MESSAGE_CONTROL(0),            // DECIMAL
        .RST_MODE_A("SYNC"),            // String
        .RST_MODE_B("SYNC"),            // String
        .USE_EMBEDDED_CONSTRAINT(0)     // DECIMAL
    ) u_sp_sram (
        .clka(clk_i),                   // 1-bit input: Clock signal for port A. Also clocks port B when
                                        // parameter CLOCKING_MODE is "common_clock".
        .ena(we),                       // 1-bit input: Memory enable signal for port A. Must be high on clock
                                        // cycles when write operations are initiated. Pipelined internally.
        .wea(wea),                      // WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input
                                        // data port dina. 1 bit wide when word-wide writes are used. In
                                        // byte-wide write configurations, each bit controls the writing one
                                        // byte of dina to address addra. For example, to synchronously write
                                        // only bits [15-8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be
                                        // 4'b0010.
        .addra(addr_i),                 // ADDR_WIDTH_A-bit input: Address for port A write operations.
        .dina(wdata_i),                 // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
        .clkb(clk_i),                   // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                        // "independent_clock". Unused when parameter CLOCKING_MODE is
                                        // "common_clock".
        .enb(enb),                      // 1-bit input: Memory enable signal for port B. Must be high on clock
                                        // cycles when read operations are initiated. Pipelined internally.
        .addrb(addr_i),                 // ADDR_WIDTH_B-bit input: Address for port B read operations.
        .doutb(rdata_o),                // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
        .dbiterrb(),                    // 1-bit output: Status signal to indicate double bit error occurrence
                                        // on the data output of port B.
        .sbiterrb(),                    // 1-bit output: Status signal to indicate single bit error occurrence
                                        // on the data output of port B.
        .injectdbiterra(1'b0),          // 1-bit input: Controls double bit error injection on input data when
                                        // ECC enabled (Error injection capability is not available in
                                        // "decode_only" mode).
        .injectsbiterra(1'b0),          // 1-bit input: Controls single bit error injection on input data when
                                        // ECC enabled (Error injection capability is not available in
                                        // "decode_only" mode).
        .regceb(1'b1),                  // 1-bit input: Clock Enable for the last register stage on the output
                                        // data path.
        .rstb(1'b0),                    // 1-bit input: Reset signal for the final port B output register stage.
                                        // Synchronously resets output port doutb to the value specified by
                                        // parameter READ_RESET_VALUE_B.
        .sleep(1'b0)                    // 1-bit input: sleep signal to enable the dynamic power saving feature.
    );
`endif


endmodule : sp_512x64sd1_wrap

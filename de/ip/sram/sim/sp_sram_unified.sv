module sp_sram_unified #(
    parameter AWTH = 10,                // Address width
    parameter DWTH = 32,                // Data width
    parameter RD_TYPE = "WRITE_FIRST",  // Read-write operation type, should be: READ_FIRST, WRITE_FIRST
    parameter RD_DELAY = 2              // Number of cycles to delay read data
) (
    input   logic                           clk_i,      // Clock input
    input   logic                           we_i,       // Write enable input
    input   logic[AWTH-1:0]                 addr_i,     // Address input
    input   logic[DWTH-1:0]                 wdata_i,    // Write data input
    input   logic[DWTH-1:0]                 wbe_i,      // Write byte enable input
    output  logic[DWTH-1:0]                 rdata_o     // Read data output
);

    // Calculate memory size based on address width
    localparam MEM_SIZE = 1 << AWTH;

    // Memory array declaration
    logic[DWTH-1:0]                 mem[0 : MEM_SIZE-1];

    logic                           we;
    logic[AWTH-1:0]                 addr;
    logic[DWTH-1:0]                 wdata;
    logic[DWTH-1:0]                 wbe;
    logic[DWTH-1 : 0]               rdata_comb;
    logic[DWTH-1 : 0]               rdata_dlychain[0 : RD_DELAY];

    // Register inputs for metastability handling
    always_ff @(posedge clk_i) begin
        we <=  we_i;
        addr <=  addr_i;
        wdata <=  wdata_i;
        wbe <=  wbe_i;
    end

    // Write logic
if(RD_TYPE == "READ_FIRST") begin
    always_ff @(posedge clk_i) begin
        for(integer i=0; i<DWTH; i=i+1) begin
            if(we && wbe[i]) mem[addr][i] <=  wdata[i];
        end
    end
end else begin
    always_ff @(posedge clk_i) begin
        for(integer i=0; i<DWTH; i=i+1) begin
            if(we_i && wbe_i[i]) mem[addr_i][i] <=  wdata_i[i];
        end
    end
end

    // Read logic
    always_comb begin
        rdata_comb = mem[addr_i];
        rdata_dlychain[0] = mem[addr];
    end

    // Delay chain for read data
    always_ff @(posedge clk_i) begin
        for(integer i=0; i<RD_DELAY; i=i+1) begin
            rdata_dlychain[i+1] <=  rdata_dlychain[i];
        end
    end

    // Assign final read data output
if(RD_DELAY == 0) begin
    assign rdata_o = rdata_comb;
end else begin
    assign rdata_o = rdata_dlychain[RD_DELAY-1];
end

endmodule : sp_sram_unified

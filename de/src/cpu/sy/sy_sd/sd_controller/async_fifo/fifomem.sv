// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : fifo_mem.v
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

module fifomem
    import sy_pkg::*;
#(
    parameter  DATASIZE = 8,    // Memory data word width
    parameter  ADDRSIZE = 4,    // Number of mem address bits
    parameter  FALLTHROUGH = "TRUE" // First word fall-through
) (
    input  logic                wclk,
    input  logic                wclken,
    input  logic [ADDRSIZE-1:0] waddr,
    input  logic [DATASIZE-1:0] wdata,
    input  logic                wfull,
    input  logic                rclk,
    input  logic                rclken,
    input  logic [ADDRSIZE-1:0] raddr,
    output logic [DATASIZE-1:0] rdata
);

    localparam DEPTH = 1<<ADDRSIZE;

    logic [DATASIZE-1:0] mem [0:DEPTH-1];
    // (* ram_style = "block" *) reg [DATASIZE-1:0] mem [0:DEPTH-1];

    logic [DATASIZE-1:0] rdata_r;

    always @(posedge wclk) begin
        if (wclken && !wfull)
            mem[waddr] <= wdata;
    end

    generate
        if (FALLTHROUGH == "TRUE") begin : fallthrough
            assign rdata = mem[raddr];
        end else begin : registered_read
            always @(posedge rclk) begin
                if (rclken)
                    rdata_r <= mem[raddr];
            end
            assign rdata = rdata_r;
        end
    endgenerate

endmodule

// `resetall

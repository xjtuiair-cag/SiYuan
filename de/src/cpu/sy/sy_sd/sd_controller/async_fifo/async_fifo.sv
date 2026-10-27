// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : async_fifo.v
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

module async_fifo
    import sy_pkg::*;
#(
    parameter DSIZE = 8,
    parameter ASIZE = 4,
    parameter FALLTHROUGH = "TRUE" // First word fall-through without latency
)(
    input  logic             wclk,
    input  logic             wrst,
    input  logic             winc,
    input  logic [DSIZE-1:0] wdata,
    output logic             wfull,
    output logic             awfull,
    input  logic             rclk,
    input  logic             rrst,
    input  logic             rinc,
    output logic [DSIZE-1:0] rdata,
    output logic             rempty,
    output logic             arempty
);

    logic [ASIZE-1:0] waddr, raddr;
    logic [ASIZE  :0] wptr, rptr, wq2_rptr, rq2_wptr;

    // The module synchronizing the read point
    // from read to write domain
    sync_r2w #(
        .ASIZE (ASIZE)
    ) sync_r2w (
        .wq2_rptr (wq2_rptr),
        .rptr     (rptr),
        .wclk     (wclk),
        .wrst     (wrst)
    );

    // The module synchronizing the write point
    // from write to read domain
    sync_w2r #(
        .ASIZE (ASIZE)
    ) sync_w2r (
        .rq2_wptr (rq2_wptr),
        .wptr     (wptr),
        .rclk     (rclk),
        .rrst     (rrst)
    );

    // The module handling the write requests
    wptr_full #(
        .ADDRSIZE (ASIZE)
    ) wptr_full (
        .awfull   (awfull),
        .wfull    (wfull),
        .waddr    (waddr),
        .wptr     (wptr),
        .wq2_rptr (wq2_rptr),
        .winc     (winc),
        .wclk     (wclk),
        .wrst     (wrst)
    );

    // The DC-RAM
    fifomem #(
        .DATASIZE          (DSIZE), 
        .ADDRSIZE          (ASIZE), 
        .FALLTHROUGH    (FALLTHROUGH)
    ) fifomem (
        .rclken (rinc),
        .rclk   (rclk),
        .rdata  (rdata),
        .wdata  (wdata),
        .waddr  (waddr),
        .raddr  (raddr),
        .wclken (winc),
        .wfull  (wfull),
        .wclk   (wclk)
    );

    // The module handling read requests
    rptr_empty #(
        .ADDRSIZE (ASIZE)
    ) rptr_empty (
        .arempty  (arempty),
        .rempty   (rempty),
        .raddr    (raddr),
        .rptr     (rptr),
        .rq2_wptr (rq2_wptr),
        .rinc     (rinc),
        .rclk     (rclk),
        .rrst     (rrst)
    );
endmodule

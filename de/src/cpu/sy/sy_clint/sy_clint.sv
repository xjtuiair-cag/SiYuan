// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : sy_clint.v
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

module sy_clint #(
    parameter int unsigned ADDR_WIDTH   = 64,
    parameter int unsigned DATA_WIDTH   = 64,
    // Number of cores therefore also the number of timecmp registers and timer interrupts
    parameter int unsigned CORES_NUM    = 1 
) (
    input  logic                        clk_i,       
    input  logic                        rst_i,      
    // Real-time clock in (usually 32.768 kHz)
    input  logic                        rtc_i,       
    // Timer interrupts
    output logic [CORES_NUM-1:0]        timer_irq_o, 
    // software interrupt (a.k.a inter-process-interrupt)
    output logic [CORES_NUM-1:0]        ipi_o,      
    // A Channel
    input  logic                        tl_A_valid_i,
    output logic                        tl_A_ready_o,
    input  tl_pkg::A_chan_bits_t        tl_A_bits_i,
    // B Channel
    output logic                        tl_B_valid_o,
    input  logic                        tl_B_ready_i,
    output tl_pkg::B_chan_bits_t        tl_B_bits_o,
    // C Channel
    input  logic                        tl_C_valid_i,
    output logic                        tl_C_ready_o,
    input  tl_pkg::C_chan_bits_t        tl_C_bits_i,
    // D Channel
    output logic                        tl_D_valid_o,
    input  logic                        tl_D_ready_i,
    output tl_pkg::D_chan_bits_t        tl_D_bits_o,
    // E Channel
    input  logic                        tl_E_valid_i,
    output logic                        tl_E_ready_o,
    input  tl_pkg::E_chan_bits_t        tl_E_bits_i
);
//======================================================================================================================
// Parameters
//======================================================================================================================
    // register offset
    localparam logic [15:0] MSIP_BASE     = 16'h0;
    localparam logic [15:0] MTIMECMP_BASE = 16'h4000;
    localparam logic [15:0] MTIME_BASE    = 16'hbff8;
    localparam AddrSelWidth = (CORES_NUM == 1) ? 1 : $clog2(CORES_NUM);
//======================================================================================================================
// wire & reg declaration
//======================================================================================================================

    // signals from AXI 4 Lite
    logic [ADDR_WIDTH-1:0]      address;
    logic                       en;
    logic                       we;
    logic [DATA_WIDTH-1:0]      wdata;
    logic [DATA_WIDTH-1:0]      rdata;

    // bit 11 and 10 are determining the address offset
    logic [15:0] register_address;
    assign register_address = address[15:0];
    // actual registers
    logic [63:0]                mtime_n, mtime_q;
    logic [CORES_NUM-1:0][63:0] mtimecmp_n, mtimecmp_q;
    logic [CORES_NUM-1:0]       msip_n, msip_q;
    // increase the timer
    logic increase_timer;
//======================================================================================================================
// Instance
//======================================================================================================================
    assign tl_B_valid_o = 1'b0;
    assign tl_B_bits_o  = tl_pkg::B_chan_bits_t'(0);
    assign tl_E_ready_o = 1'b1;
    assign tl_C_ready_o = 1'b1;
    TL2Reg #(
        .ADDR_WIDTH ( ADDR_WIDTH ),
        .DATA_WIDTH ( DATA_WIDTH )
    ) tl2reg_inst(
        .clk_i              ( clk_i         ),
        .rst_i              ( rst_i         ),
        .TL_A_valid_i       ( tl_A_valid_i  ),              
        .TL_A_ready_o       ( tl_A_ready_o  ),              
        .TL_A_bits_i        ( tl_A_bits_i   ),            

        .TL_D_valid_o       ( tl_D_valid_o ),              
        .TL_D_ready_i       ( tl_D_ready_i ),              
        .TL_D_bits_o        ( tl_D_bits_o  ),            

        .addr_o             ( address       ),
        .en_o               ( en            ),
        .we_o               ( we            ),
        .wdata_o            ( wdata         ),
        .rdata_i            ( rdata         )
    );

    // -----------------------------
    // Register Update Logic
    // -----------------------------
    // APB register write logic
    always_comb begin
        mtime_n    = mtime_q;
        mtimecmp_n = mtimecmp_q;
        msip_n     = msip_q;
        // RTC says we should increase the timer
        if (increase_timer)
            mtime_n = mtime_q + 1;

        // written from APB bus - gets priority
        if (en && we) begin
            case (register_address) inside
                [MSIP_BASE:MSIP_BASE+4*CORES_NUM]: begin
                    // msip_n[$unsigned(address[AddrSelWidth-1+2:2])] = wdata[32*address[2]];
                    // msip_n[$unsigned(address[AddrSelWidth-1+2:2])] = wdata[0];
                    msip_n[register_address[AddrSelWidth-1+2:2]] = wdata[0];
                end

                [MTIMECMP_BASE:MTIMECMP_BASE+8*CORES_NUM]: begin
                    // mtimecmp_n[$unsigned(address[AddrSelWidth-1+3:3])] = wdata;
                    mtimecmp_n[register_address[AddrSelWidth-1+3:3]] = wdata;
                end

                MTIME_BASE: begin
                    mtime_n = wdata;
                end
                default:;
            endcase
        end
    end

    // APB register read logic
    always_comb begin
        rdata = 'b0;

        if (en && !we) begin
            case (register_address) inside
                [MSIP_BASE:MSIP_BASE+4*CORES_NUM]: begin
                    // rdata = msip_q[$unsigned(address[AddrSelWidth-1+2:2])];
                    rdata = msip_q[register_address[AddrSelWidth-1+2:2]];
                end

                [MTIMECMP_BASE:MTIMECMP_BASE+8*CORES_NUM]: begin
                    // rdata = mtimecmp_q[$unsigned(address[AddrSelWidth-1+3:3])];
                    rdata = mtimecmp_q[register_address[AddrSelWidth-1+3:3]];
                end

                MTIME_BASE: begin
                    rdata = mtime_q;
                end
                default:;
            endcase
        end
    end

    // -----------------------------
    // IRQ Generation
    // -----------------------------
    // The mtime register has a 64-bit precision on all RV32, RV64, and RV128 systems. Platforms provide a 64-bit
    // memory-mapped machine-mode timer compare register (mtimecmp), which causes a timer interrupt to be posted when the
    // mtime register contains a value greater than or equal (mtime >= mtimecmp) to the value in the mtimecmp register.
    // The interrupt remains posted until it is cleared by writing the mtimecmp register. The interrupt will only be taken
    // if interrupts are enabled and the MTIE bit is set in the mie register.
    always_comb begin : irq_gen
        // check that the mtime cmp register is set to a meaningful value
        for (int unsigned i = 0; i < CORES_NUM; i++) begin
            if (mtime_q >= mtimecmp_q[i]) begin
                timer_irq_o[i] = 1'b1;
            end else begin
                timer_irq_o[i] = 1'b0;
            end
        end
    end

    // -----------------------------
    // RTC time tracking facilities
    // -----------------------------
    // 1. Put the RTC input through a classic two stage edge-triggered synchronizer to filter out any
    //    metastability effects (or at least make them unlikely :-))
    logic rtc_cpu_domain;
    logic rtc_cpu_domain_q;
    cdc_sync # (
        .DTYPE   (logic),
        .DLY     (2),
        .RST_VAL (0)
    ) rtc2cpu(
        // clock & reset
        .clk_i      (clk_i),
        .rst_i      (rst_i),
        // data need to be synchronized
        .data_i     (rtc_i),
        .data_o     (rtc_cpu_domain)
    );
    always_ff @(`DFF_CR(clk_i,rst_i)) begin
        if (`DFF_IS_R(rst_i)) begin
            rtc_cpu_domain_q <= 1'b0;
        end else begin
            rtc_cpu_domain_q <= rtc_cpu_domain;
        end
    end 
    assign increase_timer = rtc_cpu_domain & (~rtc_cpu_domain_q);

    // Registers
    always_ff @(`DFF_CR(clk_i,rst_i)) begin
        if (`DFF_IS_R(rst_i)) begin
            mtime_q    <= 64'b0;
            mtimecmp_q <= 'b0;
            msip_q     <= '0;
        end else begin
            mtime_q    <= mtime_n;
            mtimecmp_q <= mtimecmp_n;
            msip_q     <= msip_n;
        end
    end

    assign ipi_o = msip_q;

endmodule

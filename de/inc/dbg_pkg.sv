// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : 
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

package dbg_pkg;

// `include "glb_def.svh"

// parameter NrHarts = 1;

parameter BUSWTH = 32;                    // bus width

// -----
// DTM

// JTAG IDCODE Value
// [xxxx                            ] version
// [    xxxxxxxxxxxxxxxx            ] part number
// [                    xxxxxxxxxxx ] manufacturer id
// [                               1] required by standard
parameter logic [31:0] IDCODE_VALUE = 32'h1C031001;

typedef enum logic [1:0] {
    DTM_NOP   = 2'h0,
    DTM_READ  = 2'h1,
    DTM_WRITE = 2'h2
} dtm_op_e;

typedef enum logic [1:0] {
    DTM_SUCCESS = 2'h0,
    DTM_ERR     = 2'h2,
    DTM_BUSY    = 2'h3
} dtm_op_status_e;

typedef struct packed {
    logic [31:18]   zero1;
    logic           dmihardreset;
    logic           dmireset;
    logic           zero0;
    logic [14:12]   idle;
    logic [11:10]   dmistat;
    logic [9:4]     abits;
    logic [3:0]     version;
} dtmcs_t;

// -----
// DMI
// typedef enum logic[1:0] {
//     CLEAR_PHASE_IDLE,
//     CLEAR_PHASE_ISOLATE,
//     CLEAR_PHASE_CLEAR,
//     CLEAR_PHASE_POST_CLEAR
// } clear_seq_phase_e;

// -----
// DM
parameter logic [3:0] DBGVERSION_011 = 4'h1;
parameter logic [3:0] DBGVERSION_013 = 4'h2;
parameter logic [3:0] DBGVERSION_100 = 4'h3;
// size of program buffer in junks of 32-bit words
parameter logic [4:0] ProgBufSize   = 5'h10;

// amount of data count registers implemented
parameter logic [3:0] DataCount     = 4'hc;

// address to which a hart should jump when it was requested to halt
parameter logic [63:0] HaltAddress = 64'h800;
parameter logic [63:0] ResumeAddress = HaltAddress + 8;
parameter logic [63:0] ExceptionAddress = HaltAddress + 16;

// address where data0-15 is shadowed or if shadowed in a CSR
// address of the first CSR used for shadowing the data
parameter logic [11:0] DataAddr = 12'h380; // we are aligned with Rocket here

// debug registers
typedef enum logic [7:0] {
    CSR_DATA0        = 8'h04,
    CSR_DATA1        = 8'h05,
    CSR_DATA2        = 8'h06,
    CSR_DATA3        = 8'h07,
    CSR_DATA4        = 8'h08,
    CSR_DATA5        = 8'h09,
    CSR_DATA6        = 8'h0A,
    CSR_DATA7        = 8'h0B,
    CSR_DATA8        = 8'h0C,
    CSR_DATA9        = 8'h0D,
    CSR_DATA10       = 8'h0E,
    CSR_DATA11       = 8'h0F,
    CSR_DMCONTROL    = 8'h10,
    CSR_DMSTATUS     = 8'h11,
    CSR_HARTINFO     = 8'h12,
    CSR_HALTSUM1     = 8'h13,
    CSR_HAWINDOWSEL  = 8'h14,
    CSR_HAWINDOW     = 8'h15,
    CSR_ABSTRACTCS   = 8'h16,
    CSR_COMMAND      = 8'h17,
    CSR_ABSTRACTAUTO = 8'h18,
    CSR_DEVTREEADDR0 = 8'h19,
    CSR_DEVTREEADDR1 = 8'h1A,
    CSR_DEVTREEADDR2 = 8'h1B,
    CSR_DEVTREEADDR3 = 8'h1C,
    CSR_NEXTDM       = 8'h1D,
    CSR_PROGBUF0     = 8'h20,
    CSR_PROGBUF1     = 8'h21,
    CSR_PROGBUF2     = 8'h22,
    CSR_PROGBUF3     = 8'h23,
    CSR_PROGBUF4     = 8'h24,
    CSR_PROGBUF5     = 8'h25,
    CSR_PROGBUF6     = 8'h26,
    CSR_PROGBUF7     = 8'h27,
    CSR_PROGBUF8     = 8'h28,
    CSR_PROGBUF9     = 8'h29,
    CSR_PROGBUF10    = 8'h2A,
    CSR_PROGBUF11    = 8'h2B,
    CSR_PROGBUF12    = 8'h2C,
    CSR_PROGBUF13    = 8'h2D,
    CSR_PROGBUF14    = 8'h2E,
    CSR_PROGBUF15    = 8'h2F,
    CSR_AUTHDATA     = 8'h30,
    CSR_HALTSUM2     = 8'h34,
    CSR_HALTSUM3     = 8'h35,
    CSR_SBADDRESS3   = 8'h37,
    CSR_SBCS         = 8'h38,
    CSR_SBADDRESS0   = 8'h39,
    CSR_SBADDRESS1   = 8'h3A,
    CSR_SBADDRESS2   = 8'h3B,
    CSR_SBDATA0      = 8'h3C,
    CSR_SBDATA1      = 8'h3D,
    CSR_SBDATA2      = 8'h3E,
    CSR_SBDATA3      = 8'h3F,
    CSR_HALTSUM0     = 8'h40
} dm_csr_e;

// debug causes
localparam logic [2:0] CauseBreakpoint = 3'h1;
localparam logic [2:0] CauseTrigger    = 3'h2;
localparam logic [2:0] CauseRequest    = 3'h3;
localparam logic [2:0] CauseSingleStep = 3'h4;

typedef struct packed {
    logic [31:25] zero1;
    logic         ndmresetpending;
    logic         stickyunavail;
    logic         impebreak;
    logic [21:20] zero0;
    logic         allhavereset;
    logic         anyhavereset;
    logic         allresumeack;
    logic         anyresumeack;
    logic         allnonexistent;
    logic         anynonexistent;
    logic         allunavail;
    logic         anyunavail;
    logic         allrunning;
    logic         anyrunning;
    logic         allhalted;
    logic         anyhalted;
    logic         authenticated;
    logic         authbusy;
    logic         hasresethaltreq;
    logic         devtreevalid;
    logic [3:0]   version;
} dmstatus_t;

typedef struct packed {
    logic         haltreq;
    logic         resumereq;
    logic         hartreset;
    logic         ackhavereset;
    logic         ackunavail;
    logic         hasel;
    logic [25:16] hartsello;
    logic [15:6]  hartselhi;
    logic         setkeepalive;
    logic         clrkeepalive;
    logic         setresethaltreq;
    logic         clrresethaltreq;
    logic         ndmreset;
    logic         dmactive;
} dmcontrol_t;

typedef struct packed {
    logic [31:24] zero1;
    logic [23:20] nscratch;
    logic [19:17] zero0;
    logic         dataaccess;
    logic [15:12] datasize;
    logic [11:0]  dataaddr;
} hartinfo_t;

typedef enum logic [2:0] {
    CmdErrNone, CmdErrBusy, CmdErrNotSupported,
    CmdErrorException, CmdErrorHaltResume,
    CmdErrorBus, CmdErrorOther = 7
} cmderr_e;

typedef struct packed {
    logic [31:29] zero3;
    logic [28:24] progbufsize;
    logic [23:13] zero2;
    logic         busy;
    logic         zero1;
    cmderr_e      cmderr;
    logic [7:4]   zero0;
    logic [3:0]   datacount;
} abstractcs_t;

typedef enum logic [7:0] {
    AccessRegister = 8'h0,
    QuickAccess    = 8'h1,
    AccessMemory   = 8'h2
} cmd_e;

typedef struct packed {
    cmd_e        cmdtype;
    logic [23:0] control;
} command_t;

typedef struct packed {
    logic [31:16] autoexecprogbuf;
    logic [15:12] zero0;
    logic [11:0]  autoexecdata;
} abstractauto_t;

typedef struct packed {
    logic         aamvirtual;
    logic [22:20] aamsize;
    logic         aampostincrement;
    logic [18:17] zero1;
    logic         write;
    logic [15:14] target_specific;
    logic [13:0]  zero0;
} ac_am_cmd_t;

typedef struct packed {
    logic         zero1;
    logic [22:20] aarsize;
    logic         aarpostincrement;
    logic         postexec;
    logic         transfer;
    logic         write;
    logic [15:0]  regno;
} ac_ar_cmd_t;

typedef struct packed {
    logic [31:29] sbversion;
    logic [28:23] zero0;
    logic         sbbusyerror;
    logic         sbbusy;
    logic         sbreadonaddr;
    logic [19:17] sbaccess;
    logic         sbautoincrement;
    logic         sbreadondata;
    logic [14:12] sberror;
    logic [11:5]  sbasize;
    logic         sbaccess128;
    logic         sbaccess64;
    logic         sbaccess32;
    logic         sbaccess16;
    logic         sbaccess8;
} sbcs_t;

// -----
// core information

// CSRs
typedef enum logic [11:0] {
    // Floating-Point CSRs
    CSR_FFLAGS         = 12'h001,
    CSR_FRM            = 12'h002,
    CSR_FCSR           = 12'h003,
    CSR_FTRAN          = 12'h800,
    // Supervisor Mode CSRs
    CSR_SSTATUS        = 12'h100,
    CSR_SIE            = 12'h104,
    CSR_STVEC          = 12'h105,
    CSR_SCOUNTEREN     = 12'h106,
    CSR_SSCRATCH       = 12'h140,
    CSR_SEPC           = 12'h141,
    CSR_SCAUSE         = 12'h142,
    CSR_STVAL          = 12'h143,
    CSR_SIP            = 12'h144,
    CSR_SATP           = 12'h180,
    // Machine Mode CSRs
    CSR_MSTATUS        = 12'h300,
    CSR_MISA           = 12'h301,
    CSR_MEDELEG        = 12'h302,
    CSR_MIDELEG        = 12'h303,
    CSR_MIE            = 12'h304,
    CSR_MTVEC          = 12'h305,
    CSR_MCOUNTEREN     = 12'h306,
    CSR_MSCRATCH       = 12'h340,
    CSR_MEPC           = 12'h341,
    CSR_MCAUSE         = 12'h342,
    CSR_MTVAL          = 12'h343,
    CSR_MIP            = 12'h344,
    CSR_PMPCFG0        = 12'h3A0,
    CSR_PMPADDR0       = 12'h3B0,
    CSR_MVENDORID      = 12'hF11,
    CSR_MARCHID        = 12'hF12,
    CSR_MIMPID         = 12'hF13,
    CSR_MHARTID        = 12'hF14,
    CSR_MCYCLE         = 12'hB00,
    CSR_MINSTRET       = 12'hB02,
    CSR_DCACHE         = 12'h701,
    CSR_ICACHE         = 12'h700,

    CSR_TSELECT        = 12'h7A0,
    CSR_TDATA1         = 12'h7A1,
    CSR_TDATA2         = 12'h7A2,
    CSR_TDATA3         = 12'h7A3,
    CSR_TINFO          = 12'h7A4,

    // Debug CSR
    CSR_DCSR           = 12'h7b0,
    CSR_DPC            = 12'h7b1,
    CSR_DSCRATCH0      = 12'h7b2, // optional
    CSR_DSCRATCH1      = 12'h7b3, // optional

    // Counters and Timers
    CSR_CYCLE          = 12'hC00,
    CSR_TIME           = 12'hC01,
    CSR_INSTRET        = 12'hC02
} csr_reg_e;

// Instruction Generation Helpers
function automatic logic [31:0] jal (logic [4:0]  rd,
                                    logic [20:0] imm);
    // OpCode Jal
    return {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'h6f};
endfunction

function automatic logic [31:0] jalr (logic [4:0]  rd,
                                    logic [4:0]  rs1,
                                    logic [11:0] offset);
    // OpCode Jal
    return {offset[11:0], rs1, 3'b0, rd, 7'h67};
endfunction

function automatic logic [31:0] andi (logic [4:0]  rd,
                                    logic [4:0]  rs1,
                                    logic [11:0] imm);
    // OpCode andi
    return {imm[11:0], rs1, 3'h7, rd, 7'h13};
endfunction

function automatic logic [31:0] slli (logic [4:0] rd,
                                    logic [4:0] rs1,
                                    logic [5:0] shamt);
    // OpCode slli
    return {6'b0, shamt[5:0], rs1, 3'h1, rd, 7'h13};
endfunction

function automatic logic [31:0] srli (logic [4:0] rd,
                                    logic [4:0] rs1,
                                    logic [5:0] shamt);
    // OpCode srli
    return {6'b0, shamt[5:0], rs1, 3'h5, rd, 7'h13};
endfunction

function automatic logic [31:0] load (logic [2:0]  size,
                                    logic [4:0]  dest,
                                    logic [4:0]  base,
                                    logic [11:0] offset);
    // OpCode Load
    return {offset[11:0], base, size, dest, 7'h03};
endfunction

function automatic logic [31:0] auipc (logic [4:0]  rd,
                                        logic [20:0] imm);
    // OpCode Auipc
    return {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'h17};
endfunction

function automatic logic [31:0] store (logic [2:0]  size,
                                        logic [4:0]  src,
                                        logic [4:0]  base,
                                        logic [11:0] offset);
    // OpCode Store
    return {offset[11:5], src, base, size, offset[4:0], 7'h23};
endfunction

function automatic logic [31:0] float_load (logic [2:0]  size,
                                            logic [4:0]  dest,
                                            logic [4:0]  base,
                                            logic [11:0] offset);
    // OpCode Load
    return {offset[11:0], base, size, dest, 7'b00_001_11};
endfunction

function automatic logic [31:0] float_store (logic [2:0]  size,
                                            logic [4:0]  src,
                                            logic [4:0]  base,
                                            logic [11:0] offset);
    // OpCode Store
    return {offset[11:5], src, base, size, offset[4:0], 7'b01_001_11};
endfunction

function automatic logic [31:0] csrw (csr_reg_e   csr,
                                    logic [4:0] rs1);
    // CSRRW, rd, OpCode System
    return {csr, rs1, 3'h1, 5'h0, 7'h73};
endfunction

function automatic logic [31:0] csrr (csr_reg_e   csr,
                                    logic [4:0] dest);
    // rs1, CSRRS, rd, OpCode System
    return {csr, 5'h0, 3'h2, dest, 7'h73};
endfunction

function automatic logic [31:0] branch(logic [4:0]  src2,
                                        logic [4:0]  src1,
                                        logic [2:0]  funct3,
                                        logic [11:0] offset);
    // OpCode Branch
    return {offset[11], offset[9:4], src2, src1, funct3,
        offset[3:0], offset[10], 7'b11_000_11};
endfunction

function automatic logic [31:0] ebreak ();
    return 32'h00100073;
endfunction

function automatic logic [31:0] wfi ();
    return 32'h10500073;
endfunction

function automatic logic [31:0] nop ();
    return 32'h00000013;
endfunction

function automatic logic [31:0] illegal ();
    return 32'h00000000;
endfunction

endpackage

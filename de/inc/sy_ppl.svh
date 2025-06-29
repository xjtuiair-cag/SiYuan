//----------------------------------------------------------------------------------------------------------------------
// Overall parameters
//----------------------------------------------------------------------------------------------------------------------

// Supported functional modules
// support IM on default
parameter EN_A_EXT = 0;
parameter EN_F_EXT = 0;
parameter EN_D_EXT = 0;
parameter EN_HPM = 0;
parameter EN_RTC = 0;
parameter EN_PRIO = 0;
parameter EN_MMU = 0;

// FU delays
parameter MUL_STAGE = 3;
parameter DIV_STAGE = 20;

// Privilege mode
parameter PRIV_U = 2'h0;
parameter PRIV_S = 2'h1;
parameter PRIV_H = 2'h2;
parameter PRIV_M = 2'h3;

parameter ADDR_DBG_ENTRY = 32'h0000_0800;

// Register alias
parameter SR_ZERO = 5'd0;
parameter SR_RA = 5'd1;
parameter SR_SP = 5'd2;
parameter SR_GP = 5'd3;
parameter SR_TP = 5'd4;
parameter SR_T0 = 5'd5;
parameter SR_T1 = 5'd6;
parameter SR_T2 = 5'd7;
parameter SR_S0 = 5'd8;
parameter SR_S1 = 5'd9;
parameter SR_A0 = 5'd10;
parameter SR_A1 = 5'd11;
parameter SR_A2 = 5'd12;
parameter SR_A3 = 5'd13;
parameter SR_A4 = 5'd14;
parameter SR_A5 = 5'd15;
parameter SR_A6 = 5'd16;
parameter SR_A7 = 5'd17;
parameter SR_S2 = 5'd18;
parameter SR_S3 = 5'd19;
parameter SR_S4 = 5'd20;
parameter SR_S5 = 5'd21;
parameter SR_S6 = 5'd22;
parameter SR_S7 = 5'd23;
parameter SR_S8 = 5'd24;
parameter SR_S9 = 5'd25;
parameter SR_S10 = 5'd26;
parameter SR_S11 = 5'd27;
parameter SR_T3 = 5'd28;
parameter SR_T4 = 5'd29;
parameter SR_T5 = 5'd30;
parameter SR_T6 = 5'd31;

//----------------------------------------------------------------------------------------------------------------------
// Instruction decode
//----------------------------------------------------------------------------------------------------------------------
function automatic logic [6 : 0] get_rvcls(logic [IWTH-1 : 0] instruction_i);
    return { instruction_i[6 : 0] };
endfunction

function automatic logic [2 : 0] get_fu3(logic [IWTH-1 : 0] instruction_i);
    return { instruction_i[14 : 12] };
endfunction

function automatic logic [6 : 0] get_fu7(logic [IWTH-1 : 0] instruction_i);
    return { instruction_i[31 : 25] };
endfunction

function automatic logic [11 : 0] get_fu12(logic [IWTH-1 : 0] instruction_i);
    return { instruction_i[31 : 20] };
endfunction

function automatic logic [4 : 0] get_rdst(logic [IWTH-1 : 0] instruction_i);
    return { instruction_i[11 : 7] };
endfunction

function automatic logic [4 : 0] get_rs1(logic [IWTH-1 : 0] instruction_i);
    return { instruction_i[19 : 15] };
endfunction

function automatic logic [4 : 0] get_rs2(logic [IWTH-1 : 0] instruction_i);
    return { instruction_i[24 : 20] };
endfunction

function automatic logic [DWTH-1 : 0] i_imm (logic [IWTH-1 : 0] instruction_i);
    return { {(DWTH-12) {instruction_i[31]}}, instruction_i[31:20] };
endfunction

function automatic logic [DWTH-1 : 0] s_imm (logic [IWTH-1 : 0] instruction_i);
    return { {(DWTH-12) {instruction_i[31]}}, instruction_i[31:25], instruction_i[11:7]};
endfunction

function automatic logic [DWTH-1 : 0] b_imm (logic [IWTH-1 : 0] instruction_i);
    return { {(DWTH-12) {instruction_i[31]}}, instruction_i[7], instruction_i[30:25], instruction_i[11:8], 1'b0 };
endfunction

function automatic logic [DWTH-1 : 0] u_imm (logic [IWTH-1 : 0] instruction_i);
    return { {(DWTH-31) {instruction_i[31]}}, instruction_i[30:12], 12'h0 };
endfunction

function automatic logic [DWTH-1 : 0] j_imm (logic [IWTH-1 : 0] instruction_i);
    return { {(DWTH-20) {instruction_i[31]}}, instruction_i[19:12], instruction_i[20], instruction_i[30:21], 1'b0 };
endfunction

function automatic logic [DWTH-1 : 0] csr_imm (logic [IWTH-1 : 0] instruction_i);
    // return { {(DWTH-4) {instruction_i[19]}}, instruction_i[18:15]};
    return { {(DWTH-5) {1'b0}}, instruction_i[19:15]};
endfunction

// basic classification of RISC-V instructions
parameter RVCLS_LOAD = 7'b0000011;
parameter RVCLS_STORE = 7'b0100011;
parameter RVCLS_BRANCH = 7'b1100011;

parameter RVCLS_LOAD_FP = 7'b0000111;
parameter RVCLS_STORE_FP = 7'b0100111;
parameter RVCLS_MSUB = 7'b1000111;
parameter RVCLS_MADD = 7'b1000011;

parameter RVCLS_JALR = 7'b1100111;

parameter RVCLS_CUSTOM_0 = 7'b0001011;
parameter RVCLS_CUSTOM_1 = 7'b0101011;
parameter RVCLS_NMSUB = 7'b1001011;
parameter RVCLS_RSV0 = 7'b1101011; // reserved

parameter RVCLS_MISC_MEM = 7'b0001111;
parameter RVCLS_AMO = 7'b0101111;
parameter RVCLS_NMADD = 7'b1001111;
parameter RVCLS_JAL = 7'b1101111;

parameter RVCLS_OP_IMM = 7'b0010011;
parameter RVCLS_OP = 7'b0110011;
parameter RVCLS_OP_FP = 7'b1010011;
parameter RVCLS_SYSTEM = 7'b1110011;

parameter RVCLS_AUIPC = 7'b0010111;
parameter RVCLS_LUI = 7'b0110111;
parameter RVCLS_RSV1 = 7'b1010111; // reserved
parameter RVCLS_RSV2 = 7'b1110111; // reserved

parameter RVCLS_OP_IMM_32 = 7'b0011011;
parameter RVCLS_OP_32 = 7'b0111011;
parameter RVCLS_CUSTOM_2 = 7'b1011011;
parameter RVCLS_CUSTOM_3 = 7'b1111011;

parameter PRI_FU7_SFENCE_VMA = 7'b0001001;

// Arithmetic FUNCT3 encodings
parameter AR_FU3_ADDIVE = 3'h0;
parameter AR_FU3_SLL = 3'h1;
parameter AR_FU3_SLT = 3'h2;
parameter AR_FU3_SLTU = 3'h3;
parameter AR_FU3_XOR = 3'h4;
parameter AR_FU3_SRA_SRL = 3'h5;
parameter AR_FU3_OR = 3'h6;
parameter AR_FU3_AND = 3'h7;

parameter FU7_SUB = 7'b0100000;
parameter FU7_SRA = 7'b0100000;

// Branch FUNCT3 encodings
parameter BR_FU3_BEQ = 3'h0;
parameter BR_FU3_BNE = 3'h1;
parameter BR_FU3_BLT = 3'h4;
parameter BR_FU3_BGE = 3'h5;
parameter BR_FU3_BLTU = 3'h6;
parameter BR_FU3_BGEU = 3'h7;

// MISC-MEM FUNCT3 encodings
parameter MEM_FU3_FENCE = 1'b0;
parameter MEM_FU3_FENCE_I = 1'b1;

// SYSTEM FUNCT3 encodings
parameter SYS_FU3_PRIV = 3'h0;
parameter SYS_FU3_CSRRW = 3'h1;
parameter SYS_FU3_CSRRS = 3'h2;
parameter SYS_FU3_CSRRC = 3'h3;
parameter SYS_FU3_CSRRWI = 3'h5;
parameter SYS_FU3_CSRRSI = 3'h6;
parameter SYS_FU3_CSRRCI = 3'h7;

// PRIV FUNCT12 encodings
parameter PRI_FU12_ECALL = 12'b000000000000;
parameter PRI_FU12_EBREAK = 12'b000000000001;
parameter PRI_FU12_URET = 12'b000000000010;
parameter PRI_FU12_SRET = 12'b000100000010;
parameter PRI_FU12_HRET = 12'b001000000010;
parameter PRI_FU12_MRET = 12'b001100000010;
parameter PRI_FU12_DRET = 12'b011110110010;
parameter PRI_FU12_WFI = 12'b000100000101;

// LOAD FUNCT3 encodings
parameter LD_FU3_LB = 3'h0;
parameter LD_FU3_LH = 3'h1;
parameter LD_FU3_LW = 3'h2;
parameter LD_FU3_LD = 3'h3;
parameter LD_FU3_LBU = 3'h4;
parameter LD_FU3_LHU = 3'h5;
parameter LD_FU3_LWU = 3'h6;

// STORE FUNCT3 encodings
parameter ST_FU3_SB = 3'h0;
parameter ST_FU3_SH = 3'h1;
parameter ST_FU3_SW = 3'h2;
parameter ST_FU3_SD = 3'h3;

// RV32-M encodings
parameter MDU_FU3_MUL = 3'h0;
parameter MDU_FU3_MULW = 3'h0;
parameter MDU_FU3_MULH = 3'h1;
parameter MDU_FU3_MULHSU = 3'h2;
parameter MDU_FU3_MULHU = 3'h3;
parameter MDU_FU3_DIV = 3'h4;
parameter MDU_FU3_DIVW = 3'h4;
parameter MDU_FU3_DIVU = 3'h5;
parameter MDU_FU3_DIVUW = 3'h5;
parameter MDU_FU3_REM = 3'h6;
parameter MDU_FU3_REMW = 3'h6;
parameter MDU_FU3_REMU = 3'h7;
parameter MDU_FU3_REMUW = 3'h7;

parameter FU7_MUL_DIV = 7'b0000001;

// --------------------
// Opcodes
// --------------------
// RV32/64G listings:
// Quadrant 0
localparam OpcodeLoad      = 7'b00_000_11;
localparam OpcodeLoadFp    = 7'b00_001_11;
localparam OpcodeCustom0   = 7'b00_010_11;
localparam OpcodeMiscMem   = 7'b00_011_11;
localparam OpcodeOpImm     = 7'b00_100_11;
localparam OpcodeAuipc     = 7'b00_101_11;
localparam OpcodeOpImm32   = 7'b00_110_11;
// Quadrant 1
localparam OpcodeStore     = 7'b01_000_11;
localparam OpcodeStoreFp   = 7'b01_001_11;
localparam OpcodeCustom1   = 7'b01_010_11;
localparam OpcodeAmo       = 7'b01_011_11;
localparam OpcodeOp        = 7'b01_100_11;
localparam OpcodeLui       = 7'b01_101_11;
localparam OpcodeOp32      = 7'b01_110_11;
// Quadrant 2
localparam OpcodeMadd      = 7'b10_000_11;
localparam OpcodeMsub      = 7'b10_001_11;
localparam OpcodeNmsub     = 7'b10_010_11;
localparam OpcodeNmadd     = 7'b10_011_11;
localparam OpcodeOpFp      = 7'b10_100_11;
localparam OpcodeRsrvd1    = 7'b10_101_11;
localparam OpcodeCustom2   = 7'b10_110_11;
// Quadrant 3
localparam OpcodeBranch    = 7'b11_000_11;
localparam OpcodeJalr      = 7'b11_001_11;
localparam OpcodeRsrvd2    = 7'b11_010_11;
localparam OpcodeJal       = 7'b11_011_11;
localparam OpcodeSystem    = 7'b11_100_11;
localparam OpcodeRsrvd3    = 7'b11_101_11;
localparam OpcodeCustom3   = 7'b11_110_11;

// RV64C listings:
// Quadrant 0
localparam OpcodeC0             = 2'b00;
localparam OpcodeC0Addi4spn     = 3'b000;
localparam OpcodeC0Fld          = 3'b001;
localparam OpcodeC0Lw           = 3'b010;
localparam OpcodeC0Ld           = 3'b011;
localparam OpcodeC0Rsrvd        = 3'b100;
localparam OpcodeC0Fsd          = 3'b101;
localparam OpcodeC0Sw           = 3'b110;
localparam OpcodeC0Sd           = 3'b111;
// Quadrant 1
localparam OpcodeC1             = 2'b01;
localparam OpcodeC1Addi         = 3'b000;
localparam OpcodeC1Addiw        = 3'b001;
localparam OpcodeC1Li           = 3'b010;
localparam OpcodeC1LuiAddi16sp  = 3'b011;
localparam OpcodeC1MiscAlu      = 3'b100;
localparam OpcodeC1J            = 3'b101;
localparam OpcodeC1Beqz         = 3'b110;
localparam OpcodeC1Bnez         = 3'b111;
// Quadrant 2
localparam OpcodeC2             = 2'b10;
localparam OpcodeC2Slli         = 3'b000;
localparam OpcodeC2Fldsp        = 3'b001;
localparam OpcodeC2Lwsp         = 3'b010;
localparam OpcodeC2Ldsp         = 3'b011;
localparam OpcodeC2JalrMvAdd    = 3'b100;
localparam OpcodeC2Fsdsp        = 3'b101;
localparam OpcodeC2Swsp         = 3'b110;
localparam OpcodeC2Sdsp         = 3'b111;
//----------------------------------------------------------------------------------------------------------------------
// FU parameters
//----------------------------------------------------------------------------------------------------------------------

typedef enum logic[1:0] {
    LB_CMD_READ= 2'h0,
    LB_CMD_WR = 2'h1,
    LB_CMD_CLR = 2'h2,
    LB_CMD_SET = 2'h3
} lb_cmd_e;

typedef enum logic[1:0] {
    SIZE_BYTE = 0,
    SIZE_HALF = 1,
    SIZE_WORD = 2,
    SIZE_DWORD = 3
} size_e;

// ALU
typedef enum logic[6:0] {
    INSTR_CLS_ILLEGAL = 7'b0000001,
    INSTR_CLS_NORMAL = 7'b0000010,
    INSTR_CLS_JBR = 7'b0000100,
    INSTR_CLS_MEM = 7'b0001000,
    INSTR_CLS_SYS = 7'b0010000,
    INSTR_CLS_MDU = 7'b0100000,
    INSTR_CLS_FPU = 7'b1000000
} instr_cls_e;

// common FU
typedef enum logic[3:0] {
    ALS_OP_ADD = 0,
    ALS_OP_SLL = 1,
    ALS_OP_XOR = 4,
    ALS_OP_SRL = 5,
    ALS_OP_OR = 6,
    ALS_OP_AND = 7,
    ALS_OP_SEQ = 8,
    ALS_OP_SNE = 9,
    ALS_OP_SUB = 10,
    ALS_OP_SRA = 11,
    ALS_OP_SLT = 12,
    ALS_OP_SGE = 13,
    ALS_OP_SLTU = 14,
    ALS_OP_SGEU = 15
} als_opcode_e;

// Jump & Branch
typedef enum logic[2:0] {
    JBR_OP_JAL    = 3'b001,
    JBR_OP_JALR   = 3'b010,
    JBR_OP_BRANCH = 3'b100
} jbr_opcode_e;

// load/store
typedef enum logic[7:0] {
    MEM_OP_LOAD   = 8'b00000001,
    MEM_OP_STORE  = 8'b00000010,
    MEM_OP_AMO    = 8'b00000100,
    MEM_OP_LR     = 8'b00001000,
    MEM_OP_SC     = 8'b00010000,
    MEM_OP_FENCE  = 8'b00100000,
    MEM_OP_LD_FP  = 8'b01000000,
    MEM_OP_ST_FP  = 8'b10000000
} mem_opcode_e;


typedef enum logic[0:0] {
    LRSC_LR = 0,
    LRSC_SC = 1
} lrsc_cmd_e;

// System
typedef enum logic[9:0] {
    SYS_OP_CSR    = 10'b0000000001,
    SYS_OP_ECALL  = 10'b0000000010,
    SYS_OP_EBREAK = 10'b0000000100,
    SYS_OP_URET   = 10'b0000001000,
    SYS_OP_SRET   = 10'b0000010000,
    SYS_OP_HRET   = 10'b0000100000,
    SYS_OP_MRET   = 10'b0001000000,
    SYS_OP_DRET   = 10'b0011000000,
    SYS_OP_FENCEI = 10'b0100000000,
    SYS_OP_WFI    = 10'b1000000000,
    SYS_OP_SFENCE_VMA= 10'b1100000000
} sys_opcode_e;

typedef enum logic[1:0] {
    CSR_RW = 1,
    CSR_RS = 2,
    CSR_RC = 3
} csr_cmd_e;

// MDU
typedef enum logic[1:0] {
    MDU_OP_MUL = 2'd0,
    MDU_OP_MULH = 2'd1,
    MDU_OP_DIV = 2'd2,
    MDU_OP_REM = 2'd3
} mdu_opcode_e;

// Register source selection
typedef enum logic[1:0] {
    RS1_SRC_ZERO = 0,
    RS1_SRC_REG = 1,
    RS1_SRC_PC = 2
} rs1_src_e;

typedef enum logic[1:0] {
    RS2_SRC_ZERO = 0,
    RS2_SRC_REG = 1,
    RS2_SRC_IMM = 2,
    RS2_SRC_FOUR = 3
} rs2_src_e;

typedef enum logic[2:0] {
    RDST_SRC_ALU = 0,
    RDST_SRC_MEM = 1,
    RDST_SRC_CSR = 2,
    RDST_SRC_MUL = 3,
    RDST_SRC_DIV = 4,
    RDST_SRC_FPU = 5
} rdst_src_e;

// bypass bus
typedef struct packed {
    logic                               en;
    logic[4:0]                          idx;
    // Obsolete: the destiny register data is 1 cycle delay than other information.
    // Now the data is at the same cycle with enable and index signal.
    logic[DWTH-1:0]                     data;
} bp_bus_t;

//----------------------------------------------------------------------------------------------------------------------
// BTB/BHT/RAS
//----------------------------------------------------------------------------------------------------------------------
typedef struct packed {
    logic                       vld;
    logic[AWTH-1:0]             pc;     
    logic[AWTH-1:0]             target_address;     
} btb_update_t;

typedef struct packed {
    logic                       vld;
    logic[AWTH-1:0]             target_address;     
} btb_pred_t;

typedef struct packed {
    logic                       vld;
    logic[AWTH-1:0]             pc;     
    logic                       taken;  
} bht_update_t;

typedef struct packed {
    logic                       vld;
    logic                       taken;
} bht_pred_t;

typedef enum logic[2:0] {  
    NORMAL       = 0,
    CALL_JALR    = 1,
    CALL_JAL     = 2,
    RET          = 3,
    BRANCH       = 4,
    JUMP         = 5,
    JALR         = 6
} qdec_type_e;

typedef struct packed {
    logic                   vld;
    logic[AWTH-1:0]         ra;    
} ras_t;

//----------------------------------------------------------------------------------------------------------------------
// Priority & IE
//----------------------------------------------------------------------------------------------------------------------

//parameter PRIV_U = 0;
//parameter PRIV_S = 1;
//parameter PRIV_H = 2;
//parameter PRIV_M = 3;

// interrupt and exception code
typedef enum logic[3:0] {
    ECODE_INST_ADDR_MISALIGNED = 0,
    ECODE_INST_ADDR_FAULT = 1,
    ECODE_ILLEGAL_INST = 2,
    ECODE_BREAKPOINT = 3,
    ECODE_LOAD_ADDR_MISALIGNED = 4,
    ECODE_LOAD_ACCESS_FAULT = 5,
    ECODE_STORE_AMO_ADDR_MISALIGNED = 6,
    ECODE_STORE_AMO_ACCESS_FAULT = 7,
    ECODE_ECALL_FROM_U = 8,
    ECODE_ECALL_FROM_S = 9,
    ECODE_ECALL_FROM_H = 10,
    ECODE_ECALL_FROM_M = 11,
    ECODE_INST_PAGE_FAULT = 12,
    ECODE_LOAD_PAGE_FAULT = 13,
    ECODE_STORE_AMO_PAGE_FAULT = 15
} ecode_e;

    // ----------------------
    // Exception Cause Codes
    // ----------------------
    localparam logic [63:0] INSTR_ADDR_MISALIGNED = 0;
    localparam logic [63:0] INSTR_ACCESS_FAULT    = 1;
    localparam logic [63:0] ILLEGAL_INSTR         = 2;
    localparam logic [63:0] BREAKPOINT            = 3;
    localparam logic [63:0] LD_ADDR_MISALIGNED    = 4;
    localparam logic [63:0] LD_ACCESS_FAULT       = 5;
    localparam logic [63:0] ST_ADDR_MISALIGNED    = 6;
    localparam logic [63:0] ST_ACCESS_FAULT       = 7;
    localparam logic [63:0] ENV_CALL_UMODE        = 8;  // environment call from user mode
    localparam logic [63:0] ENV_CALL_SMODE        = 9;  // environment call from supervisor mode
    localparam logic [63:0] ENV_CALL_MMODE        = 11; // environment call from machine mode
    localparam logic [63:0] INSTR_PAGE_FAULT      = 12; // Instruction page fault
    localparam logic [63:0] LOAD_PAGE_FAULT       = 13; // Load page fault
    localparam logic [63:0] STORE_PAGE_FAULT      = 15; // Store page fault
    localparam logic [63:0] DEBUG_REQUEST         = 24; // Debug request

    localparam int unsigned IRQ_S_SOFT  = 1;
    localparam int unsigned IRQ_M_SOFT  = 3;
    localparam int unsigned IRQ_S_TIMER = 5;
    localparam int unsigned IRQ_M_TIMER = 7;
    localparam int unsigned IRQ_S_EXT   = 9;
    localparam int unsigned IRQ_M_EXT   = 11;


typedef enum logic[1:0] {
    PRIV_LVL_M = 2'b11,
    PRIV_LVL_S = 2'b01,
    PRIV_LVL_U = 2'b00
} priv_lvl_t;

typedef enum logic [1:0] {
    Off     = 2'b00,
    Initial = 2'b01,
    Clean   = 2'b10,
    is_Dirty   = 2'b11
} xs_t;

typedef enum logic[5:0] {  
    FMADD = 1,
    FMSUB = 2,
    FNMADD = 3,
    FNMSUB = 4,
    FADD = 5,
    FSUB = 6,
    FMUL = 7,
    FDIV = 8,
    FSQRT = 9,
    FSGNJ = 10,
    FMIN_MAX = 11,
    FCVT_F2F = 12,
    FCMP = 13,
    FCVT_F2I = 14,
    FCVT_I2F = 15,
    FMV_F2X = 16,
    FCLASS = 17,
    FMV_X2F = 18,
    VFMIN = 19,
    VFMAX = 20,
    VFSGNJ = 21,
    VFSGNJN = 22,
    VFSGNJX = 23,
    VFEQ = 24,
    VFNE = 25,
    VFLT = 26,
    VFGE = 27,
    VFLE = 28,
    VFGT = 29,
    VFCPKAB_S = 30,
    VFCPKCD_S = 31,
    VFCPKAB_D = 32,
    VFCPKCD_D = 33
} fpu_opcode_t ;

parameter TRANS_ID_BITS = 3;
// Floating-point extensions configuration
localparam bit RVF = 1'b1; // Is F extension enabled
localparam bit RVD = 1'b1; // Is D extension enabled
localparam bit RVA = 1'b1; // Is A extension enabled
localparam bit RVC = 1'b1;

// Transprecision floating-point extensions configuration
localparam bit XF16    = 1'b0; // Is half-precision float extension (Xf16) enabled
localparam bit XF16ALT = 1'b0; // Is alternative half-precision float extension (Xf16alt) enabled
localparam bit XF8     = 1'b0; // Is quarter-precision float extension (Xf8) enabled
localparam bit XFVEC   = 1'b0; // Is vectorial float extension (Xfvec) enabled

// Transprecision float unit
localparam int unsigned LAT_COMP_FP32    = 'd2;
localparam int unsigned LAT_COMP_FP64    = 'd3;
localparam int unsigned LAT_COMP_FP16    = 'd1;
localparam int unsigned LAT_COMP_FP16ALT = 'd1;
localparam int unsigned LAT_COMP_FP8     = 'd1;
localparam int unsigned LAT_DIVSQRT      = 'd2;
localparam int unsigned LAT_NONCOMP      = 'd1;
localparam int unsigned LAT_CONV         = 'd2;

// --------------------------------------
// vvvv Don't change these by hand! vvvv
localparam bit FP_PRESENT = RVF | RVD | XF16 | XF16ALT | XF8;

// Length of widest floating-point format
localparam FLEN    = RVD     ? 64 : // D ext.
                     RVF     ? 32 : // F ext.
                     XF16    ? 16 : // Xf16 ext.
                     XF16ALT ? 16 : // Xf16alt ext.
                     XF8     ? 8 :  // Xf8 ext.
                     0;             // Unused in case of no FP

localparam bit NSX = XF16 | XF16ALT | XF8 | XFVEC; // Are non-standard extensions present?

localparam bit RVFVEC     = RVF     & XFVEC & FLEN>32; // FP32 vectors available if vectors and larger fmt enabled
localparam bit XF16VEC    = XF16    & XFVEC & FLEN>16; // FP16 vectors available if vectors and larger fmt enabled
localparam bit XF16ALTVEC = XF16ALT & XFVEC & FLEN>16; // FP16ALT vectors available if vectors and larger fmt enabled
localparam bit XF8VEC     = XF8     & XFVEC & FLEN>8;  // FP8 vectors available if vectors and larger fmt enabled

// type which holds xlen
typedef enum logic [0:0] {
    FPU = 1'b0,
    FPU_VEC = 1'b1
} fpu_fu_t;


typedef struct packed {
    fpu_fu_t                    fu;     
    fpu_opcode_t              operator;
    logic [63:0]              operand_a;
    logic [63:0]              operand_b;
    logic [63:0]              imm;
    logic [TRANS_ID_BITS-1:0] trans_id;
} fu_data_t;


    // type which holds xlen
    typedef enum logic [1:0] {
        XLEN_32  = 2'b01,
        XLEN_64  = 2'b10,
        XLEN_128 = 2'b11
    } xlen_t;

    typedef struct packed {
        logic         sd;     // signal dirty state - read-only
        logic [62:36] wpri4;  // writes preserved reads ignored
        xlen_t        sxl;    // variable supervisor mode xlen - hardwired to zero
        xlen_t        uxl;    // variable user mode xlen - hardwired to zero
        logic [8:0]   wpri3;  // writes preserved reads ignored
        logic         tsr;    // trap sret
        logic         tw;     // time wait
        logic         tvm;    // trap virtual memory
        logic         mxr;    // make executable readable
        logic         sum;    // permit supervisor user memory access
        logic         mprv;   // modify privilege - privilege level for ld/st
        xs_t          xs;     // extension register - hardwired to zero
        xs_t          fs;     // floating point extension register
        priv_lvl_t    mpp;    // holds the previous privilege mode up to machine
        logic [1:0]   wpri2;  // writes preserved reads ignored
        logic         spp;    // holds the previous privilege mode up to supervisor
        logic         mpie;   // machine interrupts enable bit active prior to trap
        logic         wpri1;  // writes preserved reads ignored
        logic         spie;   // supervisor interrupts enable bit active prior to trap
        logic         upie;   // user interrupts enable bit active prior to trap - hardwired to zero
        logic         mie;    // machine interrupts enable
        logic         wpri0;  // writes preserved reads ignored
        logic         sie;    // supervisor interrupts enable
        logic         uie;    // user interrupts enable - hardwired to zero
    } status_rv64_t;

    typedef struct packed {
        logic [3:0]  mode;
        logic [15:0] asid;
        logic [43:0] ppn;
    } satp_t;

    typedef struct packed {
        logic [31:28]     xdebugver;
        logic [27:16]     zero2;
        logic             ebreakm;
        logic             zero1;
        logic             ebreaks;
        logic             ebreaku;
        logic             stepie;
        logic             stopcount;
        logic             stoptime;
        logic [8:6]       cause;
        logic             zero0;
        logic             mprven;
        logic             nmip;
        logic             step;
        priv_lvl_t        prv;
    } dcsr_t;

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
        // Performance counters (Machine Mode)
        CSR_ML1_ICACHE_MISS = 12'hB03,  // L1 Instr Cache Miss
        CSR_ML1_DCACHE_MISS = 12'hB04,  // L1 Data Cache Miss
        CSR_MITLB_MISS      = 12'hB05,  // ITLB Miss
        CSR_MDTLB_MISS      = 12'hB06,  // DTLB Miss
        CSR_MLOAD           = 12'hB07,  // Loads
        CSR_MSTORE          = 12'hB08,  // Stores
        CSR_MEXCEPTION      = 12'hB09,  // Taken exceptions
        CSR_MEXCEPTION_RET  = 12'hB0A,  // Exception return
        CSR_MBRANCH_JUMP    = 12'hB0B,  // Software change of PC
        CSR_MCALL           = 12'hB0C,  // Procedure call
        CSR_MRET            = 12'hB0D,  // Procedure Return
        CSR_MMIS_PREDICT    = 12'hB0E,  // Branch mis-predicted
        CSR_MSB_FULL        = 12'hB0F,  // Scoreboard full
        CSR_MIF_EMPTY       = 12'hB10,  // instruction fetch queue empty
        CSR_MHPM_COUNTER_17 = 12'hB11,  // reserved
        CSR_MHPM_COUNTER_18 = 12'hB12,  // reserved
        CSR_MHPM_COUNTER_19 = 12'hB13,  // reserved
        CSR_MHPM_COUNTER_20 = 12'hB14,  // reserved
        CSR_MHPM_COUNTER_21 = 12'hB15,  // reserved
        CSR_MHPM_COUNTER_22 = 12'hB16,  // reserved
        CSR_MHPM_COUNTER_23 = 12'hB17,  // reserved
        CSR_MHPM_COUNTER_24 = 12'hB18,  // reserved
        CSR_MHPM_COUNTER_25 = 12'hB19,  // reserved
        CSR_MHPM_COUNTER_26 = 12'hB1A,  // reserved
        CSR_MHPM_COUNTER_27 = 12'hB1B,  // reserved
        CSR_MHPM_COUNTER_28 = 12'hB1C,  // reserved
        CSR_MHPM_COUNTER_29 = 12'hB1D,  // reserved
        CSR_MHPM_COUNTER_30 = 12'hB1E,  // reserved
        CSR_MHPM_COUNTER_31 = 12'hB1F,  // reserved
        // Cache Control (platform specifc)
        CSR_DCACHE         = 12'h701,
        CSR_ICACHE         = 12'h700,
        // Triggers
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
        // Counters and Timers (User Mode - R/O Shadows)
        CSR_CYCLE          = 12'hC00,
        CSR_TIME           = 12'hC01,
        CSR_INSTRET        = 12'hC02,
        // Performance counters (User Mode - R/O Shadows)
        CSR_L1_ICACHE_MISS = 12'hC03,  // L1 Instr Cache Miss
        CSR_L1_DCACHE_MISS = 12'hC04,  // L1 Data Cache Miss
        CSR_ITLB_MISS      = 12'hC05,  // ITLB Miss
        CSR_DTLB_MISS      = 12'hC06,  // DTLB Miss
        CSR_LOAD           = 12'hC07,  // Loads
        CSR_STORE          = 12'hC08,  // Stores
        CSR_EXCEPTION      = 12'hC09,  // Taken exceptions
        CSR_EXCEPTION_RET  = 12'hC0A,  // Exception return
        CSR_BRANCH_JUMP    = 12'hC0B,  // Software change of PC
        CSR_CALL           = 12'hC0C,  // Procedure call
        CSR_RET            = 12'hC0D,  // Procedure Return
        CSR_MIS_PREDICT    = 12'hC0E,  // Branch mis-predicted
        CSR_SB_FULL        = 12'hC0F,  // Scoreboard full
        CSR_IF_EMPTY       = 12'hC10,  // instruction fetch queue empty
        CSR_HPM_COUNTER_17 = 12'hC11,  // reserved
        CSR_HPM_COUNTER_18 = 12'hC12,  // reserved
        CSR_HPM_COUNTER_19 = 12'hC13,  // reserved
        CSR_HPM_COUNTER_20 = 12'hC14,  // reserved
        CSR_HPM_COUNTER_21 = 12'hC15,  // reserved
        CSR_HPM_COUNTER_22 = 12'hC16,  // reserved
        CSR_HPM_COUNTER_23 = 12'hC17,  // reserved
        CSR_HPM_COUNTER_24 = 12'hC18,  // reserved
        CSR_HPM_COUNTER_25 = 12'hC19,  // reserved
        CSR_HPM_COUNTER_26 = 12'hC1A,  // reserved
        CSR_HPM_COUNTER_27 = 12'hC1B,  // reserved
        CSR_HPM_COUNTER_28 = 12'hC1C,  // reserved
        CSR_HPM_COUNTER_29 = 12'hC1D,  // reserved
        CSR_HPM_COUNTER_30 = 12'hC1E,  // reserved
        CSR_HPM_COUNTER_31 = 12'hC1F  // reserved
    } csr_reg_t;

    // decoded CSR address
    typedef struct packed {
        logic [1:0]  rw;
        priv_lvl_t   priv_lvl;
        logic  [7:0] address;
    } csr_addr_t;

    // Floating-Point control and status register (32-bit!)
    typedef struct packed {
        logic [31:15] reserved;  // reserved for L extension, return 0 otherwise
        logic [6:0]   fprec;     // div/sqrt precision control
        logic [2:0]   frm;       // float rounding mode
        logic [4:0]   fflags;    // float exception flags
    } fcsr_t;

    localparam logic [63:0] SSTATUS_UIE  = 64'h00000001;
    localparam logic [63:0] SSTATUS_SIE  = 64'h00000002;
    localparam logic [63:0] SSTATUS_SPIE = 64'h00000020;
    localparam logic [63:0] SSTATUS_SPP  = 64'h00000100;
    localparam logic [63:0] SSTATUS_FS   = 64'h00006000;
    localparam logic [63:0] SSTATUS_XS   = 64'h00018000;
    localparam logic [63:0] SSTATUS_SUM  = 64'h00040000;
    localparam logic [63:0] SSTATUS_MXR  = 64'h00080000;
    localparam logic [63:0] SSTATUS_UPIE = 64'h00000010;
    localparam logic [63:0] SSTATUS_UXL  = 64'h0000000300000000;
    localparam logic [63:0] SSTATUS64_SD = 64'h8000000000000000;
    localparam logic [63:0] SSTATUS32_SD = 64'h80000000;

    localparam logic [63:0] MSTATUS_UIE  = 64'h00000001;
    localparam logic [63:0] MSTATUS_SIE  = 64'h00000002;
    localparam logic [63:0] MSTATUS_HIE  = 64'h00000004;
    localparam logic [63:0] MSTATUS_MIE  = 64'h00000008;
    localparam logic [63:0] MSTATUS_UPIE = 64'h00000010;
    localparam logic [63:0] MSTATUS_SPIE = 64'h00000020;
    localparam logic [63:0] MSTATUS_HPIE = 64'h00000040;
    localparam logic [63:0] MSTATUS_MPIE = 64'h00000080;
    localparam logic [63:0] MSTATUS_SPP  = 64'h00000100;
    localparam logic [63:0] MSTATUS_HPP  = 64'h00000600;
    localparam logic [63:0] MSTATUS_MPP  = 64'h00001800;
    localparam logic [63:0] MSTATUS_FS   = 64'h00006000;
    localparam logic [63:0] MSTATUS_XS   = 64'h00018000;
    localparam logic [63:0] MSTATUS_MPRV = 64'h00020000;
    localparam logic [63:0] MSTATUS_SUM  = 64'h00040000;
    localparam logic [63:0] MSTATUS_MXR  = 64'h00080000;
    localparam logic [63:0] MSTATUS_TVM  = 64'h00100000;
    localparam logic [63:0] MSTATUS_TW   = 64'h00200000;
    localparam logic [63:0] MSTATUS_TSR  = 64'h00400000;
    localparam logic [63:0] MSTATUS32_SD = 64'h80000000;
    localparam logic [63:0] MSTATUS_UXL  = 64'h0000000300000000;
    localparam logic [63:0] MSTATUS_SXL  = 64'h0000000C00000000;
    localparam logic [63:0] MSTATUS64_SD = 64'h8000000000000000;


    // read mask for SSTATUS over MMSTATUS
    localparam logic [63:0] SMODE_STATUS_READ_MASK = SSTATUS_UIE
                                                   | SSTATUS_SIE
                                                   | SSTATUS_SPIE
                                                   | SSTATUS_SPP
                                                   | SSTATUS_FS
                                                   | SSTATUS_XS
                                                   | SSTATUS_SUM
                                                   | SSTATUS_MXR
                                                   | SSTATUS_UPIE
                                                   | SSTATUS_SPIE
                                                   | SSTATUS_UXL
                                                   | SSTATUS64_SD;

    localparam logic [63:0] SMODE_STATUS_WRITE_MASK = SSTATUS_SIE
                                                    | SSTATUS_SPIE
                                                    | SSTATUS_SPP
                                                    | SSTATUS_FS
                                                    | SSTATUS_SUM
                                                    | SSTATUS_MXR;

    localparam logic [63:0] SY_MARCHID = 64'd3;


    localparam logic [63:0] ISA_CODE = (RVA <<  0)  // A - Atomic Instructions extension
                                     | (RVC <<  2)  // C - Compressed extension
                                     | (RVD <<  3)  // D - Double precsision floating-point extension
                                     | (RVF <<  5)  // F - Single precsision floating-point extension
                                     | (1   <<  8)  // I - RV32I/64I/128I base ISA
                                     | (1   << 12)  // M - Integer Multiply/Divide extension
                                     | (0   << 13)  // N - User level interrupts supported
                                     | (1   << 18)  // S - Supervisor mode implemented
                                     | (1   << 20)  // U - User mode implemented
                                     | (NSX << 23)  // X - Non-standard extensions present
                                     | (1   << 63); // RV64
    localparam logic [3:0] MODE_SV39 = 4'h8;
    localparam logic [3:0] MODE_OFF = 4'h0;

    typedef struct packed {
      logic [63:0] mie;
      logic [63:0] mip;
      logic [63:0] mideleg;
      logic        sie;
      logic        global_enable;
    } irq_ctrl_t;

    localparam SupervisorIrq = 1;
    localparam MachineIrq = 0;


    localparam logic [63:0] S_SW_INTERRUPT    = (1 << 63) | IRQ_S_SOFT;
    localparam logic [63:0] M_SW_INTERRUPT    = (1 << 63) | IRQ_M_SOFT;
    localparam logic [63:0] S_TIMER_INTERRUPT = (1 << 63) | IRQ_S_TIMER;
    localparam logic [63:0] M_TIMER_INTERRUPT = (1 << 63) | IRQ_M_TIMER;
    localparam logic [63:0] S_EXT_INTERRUPT   = (1 << 63) | IRQ_S_EXT;
    localparam logic [63:0] M_EXT_INTERRUPT   = (1 << 63) | IRQ_M_EXT;

    localparam logic [63:0] MIP_SSIP = 1 << IRQ_S_SOFT;
    localparam logic [63:0] MIP_MSIP = 1 << IRQ_M_SOFT;
    localparam logic [63:0] MIP_STIP = 1 << IRQ_S_TIMER;
    localparam logic [63:0] MIP_MTIP = 1 << IRQ_M_TIMER;
    localparam logic [63:0] MIP_SEIP = 1 << IRQ_S_EXT;
    localparam logic [63:0] MIP_MEIP = 1 << IRQ_M_EXT;


// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tl_pkg.v
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

package tl_pkg;
    localparam PARAM_WTH = 3;
    localparam SIZE_WTH = 8;
    localparam SOURCE_WTH = 6;
    localparam ADDRESS_WTH = 64;
    localparam DATA_WTH = 64;
    localparam MASK_WTH = 8;
    localparam SINK_WTH = 4;

    typedef logic [SIZE_WTH-1:0]        size_t;   
    typedef logic [SOURCE_WTH-1:0]      source_t;
    typedef logic [ADDRESS_WTH-1:0]     address_t;
    typedef logic [MASK_WTH-1:0]        mask_t;
    typedef logic [DATA_WTH-1:0]        data_t;
    typedef logic [SINK_WTH-1:0]        sink_t;

    localparam logic [2:0] PutFullData      = 3'd0;
    localparam logic [2:0] PutPartialData   = 3'd1;
    localparam logic [2:0] ArithmeticData   = 3'd2;
    localparam logic [2:0] LogicalData      = 3'd3;
    localparam logic [2:0] Get              = 3'd4;
    localparam logic [2:0] Hint             = 3'd5;
    localparam logic [2:0] AcquireBlock     = 3'd6;
    localparam logic [2:0] AcquirePerm      = 3'd7;
    localparam logic [2:0] Probe            = 3'd7;
    localparam logic [2:0] AccessAck        = 3'd0;
    localparam logic [2:0] AccessAckData    = 3'd1;
    localparam logic [2:0] HintAck          = 3'd2;
    localparam logic [2:0] ProbeAck         = 3'd4;
    localparam logic [2:0] ProbeAckData     = 3'd5;
    localparam logic [2:0] Release          = 3'd6;
    localparam logic [2:0] ReleaseData      = 3'd7;
    localparam logic [2:0] Grant            = 3'd4;
    localparam logic [2:0] GrantData        = 3'd5;
    localparam logic [2:0] ReleaseAck       = 3'd6;


    typedef enum logic[2:0] {  
        toT = 0,
        toB = 1,
        toN = 2
    } TL_Permissions_Cap;

    typedef enum logic[2:0] {  
        NtoB = 0,
        NtoT = 1,
        BtoT = 2
    } TL_Permissions_Grow;

    typedef enum logic[2:0] {  
        TtoB = 0,
        TtoN = 1,
        BtoN = 2,
        TtoT = 3,
        BtoB = 4,
        NtoN = 5
    } TL_Permissions_Shrink;

    typedef enum logic[2:0] {  
        MIN  = 0,
        MAX  = 1,
        MINU = 2,
        MAXU = 3,
        ADD  = 4
    } TL_Atomocs_Arith;

    typedef enum logic[2:0] {  
        XOR  = 0,
        OR   = 1,
        AND  = 2,
        SWAP = 3
    } TL_Atomocs_logic;

    typedef enum logic[2:0] {  
        PREFETCH_READ = 0,
        PREFETCH_WRITE= 1
    } TL_Hint;
   
    typedef union packed{
        TL_Permissions_Grow permission;
        TL_Atomocs_Arith    arith;
        TL_Atomocs_logic    logical; 
        TL_Hint             hint;
    } A_chan_param_t;

    typedef union packed{
        TL_Permissions_Cap  permission;
        TL_Atomocs_Arith    arith;
        TL_Atomocs_logic    logical; 
        TL_Hint             hint;
    } B_chan_param_t;

    typedef union packed{
        TL_Permissions_Shrink permission;
    } C_chan_param_t;

    typedef union packed{
        TL_Permissions_Cap permission;
    } D_chan_param_t;

    // A channel bits
    typedef struct packed {
        logic [2:0]             opcode;
        A_chan_param_t          param;
        size_t                  size;  
        source_t                source;
        address_t               address;
        mask_t                  mask;
        data_t                  data;
        logic                   corrupt;
    } A_chan_bits_t;

    // B channel bits
    typedef struct packed {
        logic [2:0]             opcode;
        B_chan_param_t          param;
        size_t                  size;  
        source_t                source;
        address_t               address;
        mask_t                  mask;
        data_t                  data;
        logic                   corrupt;
    } B_chan_bits_t;

    // C channel bits
    typedef struct packed {
        logic [2:0]             opcode;
        C_chan_param_t          param;
        size_t                  size;  
        source_t                source;
        address_t               address;
        data_t                  data;
        logic                   corrupt;
    } C_chan_bits_t;

    // D channel bits
    typedef struct packed {
        logic [2:0]             opcode;
        D_chan_param_t          param;
        size_t                  size;  
        source_t                source;
        sink_t                  sink;
        logic                   denied;
        data_t                  data;
        logic                   corrupt;
    } D_chan_bits_t;

    // E channel bits
    typedef struct packed {
        sink_t                  sink;
    } E_chan_bits_t;

endpackage
    parameter FETCH_WIDTH = 32;

    parameter ICACHE_SET_SIZE          = 32;
    parameter ICACHE_BLOCK_SIZE        = 128;
    parameter ICACHE_DATA_SIZE         = 8;
    parameter ICACHE_WAY_NUM           = 4;
    parameter ICACHE_FETCH_SIZE        = 4;   //4B
    parameter ICACHE_FETCH_WTH         = $clog2(ICACHE_FETCH_SIZE);   // 2

    parameter ICACHE_TAG_LSB           = 12;
    parameter ICACHE_TAG_WTH           = 32;
    parameter ICACHE_TAG_MSB           = ICACHE_TAG_LSB + ICACHE_TAG_WTH;

    parameter ICACHE_SET_LSB           = 7;           // 7
    parameter ICACHE_SET_WTH           = $clog2(ICACHE_SET_SIZE);    // 5
    parameter ICACHE_SET_MSB           = ICACHE_SET_LSB + ICACHE_SET_WTH;  // 12

    parameter ICACHE_BLOCK_LSB         = 0;           
    parameter ICACHE_BLOCK_WTH         = $clog2(ICACHE_BLOCK_SIZE); 
    parameter ICACHE_BLOCK_MSB         = ICACHE_BLOCK_LSB + ICACHE_BLOCK_WTH;  

    parameter ICACHE_DATA_LSB          = 0;          
    parameter ICACHE_DATA_WTH          = $clog2(ICACHE_DATA_SIZE);     // 3
    parameter ICACHE_DATA_MSB          = ICACHE_DATA_LSB + ICACHE_DATA_WTH;   // 3
    
    parameter DCACHE_SET_SIZE          = 32;   // D cache contains 32 sets
    parameter DCACHE_BLOCK_SIZE        = 128; // 128B
    parameter DCACHE_DATA_SIZE         = 8;   // Data Bus is 8B 
    parameter DCACHE_WAY_NUM           = 4;

    parameter DCACHE_TAG_LSB           = 12;
    parameter DCACHE_TAG_WTH           = 32;
    parameter DCACHE_TAG_MSB           = DCACHE_TAG_LSB + DCACHE_TAG_WTH;

    parameter DCACHE_SET_LSB           = 7;           // 7
    parameter DCACHE_SET_WTH           = $clog2(DCACHE_SET_SIZE);    // 5
    parameter DCACHE_SET_MSB           = DCACHE_SET_LSB + DCACHE_SET_WTH;  // 12

    parameter DCACHE_BLOCK_LSB         = 0;           
    parameter DCACHE_BLOCK_WTH         = $clog2(DCACHE_BLOCK_SIZE); // 7
    parameter DCACHE_BLOCK_MSB         = DCACHE_BLOCK_LSB + DCACHE_BLOCK_WTH;  

    parameter DCACHE_DATA_LSB          = 0;          
    parameter DCACHE_DATA_WTH          = $clog2(DCACHE_DATA_SIZE);     // 3
    parameter DCACHE_DATA_MSB          = DCACHE_DATA_LSB + DCACHE_DATA_WTH;   // 3

    parameter L2_CACHE_SET_SIZE        = 64;   // L2 cache contains 64 sets
    parameter L2_CACHE_BLOCK_SIZE      = 256; // 256 Byte
    parameter L2_CACHE_DATA_SIZE       = 8;   // Data Bus is 8 Byte 
    parameter L2_CACHE_WAY_NUM         = 8;
    parameter L2_CACHE_WAY_WTH         = $clog2(L2_CACHE_WAY_NUM);

    parameter L2_CACHE_TAG_LSB         = 14;
    parameter L2_CACHE_TAG_WTH         = 18;
    parameter L2_CACHE_TAG_MSB         = L2_CACHE_TAG_LSB + L2_CACHE_TAG_WTH;

    parameter L2_CACHE_SET_LSB         = 8;           
    parameter L2_CACHE_SET_WTH         = $clog2(L2_CACHE_SET_SIZE);    // 6
    parameter L2_CACHE_SET_MSB         = L2_CACHE_SET_LSB + L2_CACHE_SET_WTH;  // 14

    parameter L2_CACHE_BLOCK_LSB       = 0;           
    parameter L2_CACHE_BLOCK_WTH       = $clog2(L2_CACHE_BLOCK_SIZE); // 8
    parameter L2_CACHE_BLOCK_MSB       = L2_CACHE_BLOCK_LSB + L2_CACHE_BLOCK_WTH;  

    parameter L2_CACHE_DATA_LSB        = 0;          
    parameter L2_CACHE_DATA_WTH        = $clog2(L2_CACHE_DATA_SIZE);     // 3
    parameter L2_CACHE_DATA_MSB        = L2_CACHE_DATA_LSB + L2_CACHE_DATA_WTH;   // 3


    localparam int unsigned ICACHE_INDEX_WIDTH = 12;  // in bit
    localparam int unsigned ICACHE_TAG_WIDTH   = 44;  // in bit
    localparam int unsigned ICACHE_LINE_WIDTH  = 128; // in bit
    localparam int unsigned ICACHE_SET_ASSOC   = 4;

    localparam int unsigned DCACHE_INDEX_WIDTH = 12;  // in bit
    localparam int unsigned DCACHE_TAG_WIDTH   = 44;  // in bit
    localparam int unsigned DCACHE_LINE_WIDTH  = 128; // in bit
    localparam int unsigned DCACHE_SET_ASSOC   = 8;

    // FIFO depths of L15 adapter
    localparam ADAPTER_REQ_FIFO_DEPTH  = 2;
    localparam ADAPTER_RTRN_FIFO_DEPTH = 2;

    // Calculated parameter
    localparam ICACHE_OFFSET_WIDTH     = $clog2(ICACHE_LINE_WIDTH/8);
    localparam ICACHE_NUM_WORDS        = 2**(ICACHE_INDEX_WIDTH-ICACHE_OFFSET_WIDTH);
    localparam ICACHE_CL_IDX_WIDTH     = $clog2(ICACHE_NUM_WORDS);// excluding byte offset
    // Calculated parameter
    localparam DCACHE_OFFSET_WIDTH     = $clog2(DCACHE_LINE_WIDTH/8);
    localparam DCACHE_NUM_WORDS        = 2**(DCACHE_INDEX_WIDTH-DCACHE_OFFSET_WIDTH);
    localparam DCACHE_CL_IDX_WIDTH     = $clog2(DCACHE_NUM_WORDS);// excluding byte offset

    localparam DCACHE_NUM_BANKS        = DCACHE_LINE_WIDTH/64;

    // write buffer parameterization
    // localparam DCACHE_WBUF_DEPTH       = 8;
    // localparam DCACHE_MAX_TX           = 2**L15_TID_WIDTH;
    // localparam CACHE_ID_WIDTH          = L15_TID_WIDTH;

    // ----------------------
    // cache request ports
    // ----------------------
    // I$ address translation requests
    typedef struct packed {
        logic [63:0] cause; // cause of exception
        logic [63:0] tval;  // additional information of causing exception (e.g.: instruction causing it),
                             // address of LD/ST fault
        logic        valid;
    } exception_t;

    typedef enum logic [1:0]{  
      Dirty     = 0,
      Trunk     = 1,
      Branch    = 2,
      Nothing   = 3 
    } cache_state_e; 

    typedef struct packed {
      logic [DCACHE_TAG_WTH-1:0]                            tag; 
      cache_state_e                                         state;
      logic                                                 valid;
    } tag_t;

    typedef struct packed {
      logic                               we;
      logic [DCACHE_WAY_NUM-1:0]          way_en; 
      logic [DCACHE_TAG_LSB-1:0]          idx;
      tag_t                               wr_tag;
    } tag_req_t;

    typedef struct packed {
      tag_t [DCACHE_WAY_NUM-1:0]          tag_data; 
    } tag_rsp_t;

    typedef struct packed {
      logic                               we;
      logic [DCACHE_WAY_NUM-1:0]          way_en;
      logic [DCACHE_TAG_LSB-1:0]          idx;
      logic [DCACHE_DATA_SIZE*8-1:0]      wr_data;
    } data_req_t;

    typedef struct packed {
      logic [DCACHE_DATA_SIZE*8-1:0]      rd_data; 
    } data_rsp_t;

    typedef struct packed {
      logic                               we;
      logic [L2_CACHE_WAY_NUM-1:0]        way_en; 
      logic [L2_CACHE_TAG_LSB-1:0]        idx;
      logic                               tag_valid;
      logic [L2_CACHE_TAG_WTH-1:0]        tag;
      logic                               dirty;
    } L2_tag_req_t;

    typedef struct packed {
      logic [L2_CACHE_WAY_NUM-1:0]        tag_valid; 
      logic [L2_CACHE_WAY_NUM-1:0][L2_CACHE_TAG_WTH-1:0] tag;
      logic [L2_CACHE_WAY_NUM-1:0]        dirty;  
    } L2_tag_rsp_t;

    typedef struct packed {
      logic                               we;
      logic [L2_CACHE_WAY_NUM-1:0]        way_en;
      logic [L2_CACHE_TAG_LSB-1:0]        idx;
      logic [L2_CACHE_DATA_SIZE*8-1:0]    wr_data;
    } L2_data_req_t;

    typedef struct packed {
      logic [L2_CACHE_WAY_NUM-1:0][L2_CACHE_DATA_SIZE*8-1:0]    rd_data; 
    } L2_data_rsp_t;


    typedef struct packed {
        logic                     fetch_valid;     // address translation valid
        logic [63:0]              fetch_paddr;     // physical address in
        exception_t               fetch_exception; // exception occurred during fetch
    } icache_areq_i_t;

    typedef struct packed {
        logic                     fetch_valid;     // address translation valid
        logic [63:0]              fetch_paddr;     // physical address in
        exception_t               fetch_exception; // exception occurred during fetch
    } mmu_icache_rsp_t;

    typedef struct packed {
        logic                     fetch_req;       // address translation request
        logic [63:0]              fetch_vaddr;     // virtual address out
        logic                     cacheable;
    } icache_mmu_req_t;


    typedef struct packed {
        logic                     fetch_req;       // address translation request
        logic [63:0]              fetch_vaddr;     // virtual address out
    } icache_areq_o_t;

    // I$ data requests
    typedef struct packed {
        logic                     req;                    // we request a new word
        logic                     kill_s1;                // kill the current request
        logic                     kill_s2;                // kill the last request
        logic [63:0]              vaddr;                  // 1st cycle: 12 bit index is taken for lookup
    } icache_dreq_i_t;

    typedef struct packed {
        logic                     ready;                  // icache is ready
        logic                     valid;                  // signals a valid read
        logic [FETCH_WIDTH-1:0]   data;                   // 2+ cycle out: tag
        logic [63:0]              vaddr;                  // virtual address out
        exception_t               ex;                     // we've encountered an exception
    } icache_dreq_o_t;

    // I$ data requests
    typedef struct packed {
        logic                     req;                    // we request a new word
        logic                     kill;                // kill the current request
        logic [63:0]              vaddr;                  // 1st cycle: 12 bit index is taken for lookup
    } fetch_req_t;

    typedef struct packed {
        logic                     ready;                  // icache is ready
        logic                     valid;                  // signals a valid read
        logic [FETCH_WIDTH-1:0]   data;                   // 2+ cycle out: tag
        logic [63:0]              vaddr;                  // virtual address out
        exception_t               ex;                     // we've encountered an exception
    } fetch_rsp_t;


    typedef enum logic [3:0] {
        AMO_NONE =4'b0000,
        AMO_LR   =4'b0001,
        AMO_SC   =4'b0010,
        AMO_SWAP =4'b0011,
        AMO_ADD  =4'b0100,
        AMO_AND  =4'b0101,
        AMO_OR   =4'b0110,
        AMO_XOR  =4'b0111,
        AMO_MAX  =4'b1000,
        AMO_MAXU =4'b1001,
        AMO_MIN  =4'b1010,
        AMO_MINU =4'b1011,
        AMO_CAS1 =4'b1100, // unused, not part of riscv spec, but provided in OpenPiton
        AMO_CAS2 =4'b1101  // unused, not part of riscv spec, but provided in OpenPiton
    } amo_t;

    typedef struct packed {
        logic        req;       // this request is valid
        amo_t        amo_op;    // atomic memory operation to perform
        logic [1:0]  size;      // 2'b10 --> word operation, 2'b11 --> double word operation
        logic [63:0] operand_a; // address
        logic [63:0] operand_b; // data as layuoted in the register
    } amo_req_t;

    typedef struct packed {
        logic        ack;    // response is valid
        logic [63:0] result; // sign-extended, result
    } amo_resp_t;


    typedef struct packed {
        logic [DCACHE_TAG_LSB-1:0]     addr_inx;  
        logic [DCACHE_TAG_WTH-1:0]     addr_tag;
        logic [63:0]                   wdata;
        logic                          req;
        logic                          we;
        logic [7:0]                    be;
        logic [1:0]                    size;
        logic                          kill;
        amo_t                          amo_op;      
    } dcache_req_t;

    typedef struct packed {
        logic                          ack;
        logic                          valid;
        logic [63:0]                   rdata;
    } dcache_rsp_t;

    typedef struct packed {
        logic                          data_gnt;
        logic                          data_rvalid;
        logic [63:0]                   data_rdata;
    } dcache_req_o_t;

    typedef enum logic [0:0] {
      REFILL = 1'b0,
      UPDATE = 1'b1
    } miss_req_cmd_e;

    typedef struct packed {
      miss_req_cmd_e                      cmd;
      logic                               cacheable;
      logic                               we;
      logic [7:0]                         be;
      logic [63:0]                        wdata;
      amo_t                               amo_op;
      logic [DCACHE_TAG_MSB-1:0]          addr;
      logic [$clog2(DCACHE_WAY_NUM)-1:0]  update_way;
      logic [$clog2(DCACHE_WAY_NUM)-1:0]  rpl_way;
    } miss_req_bits_t;


// swap endianess in a 64bit word
  function automatic logic[63:0] swendian64(input logic[63:0] in);
    automatic logic[63:0] out;
    for(int k=0; k<64;k+=8)begin
        out[k +: 8] = in[63-k -: 8];
    end
    return out;
  endfunction

  function automatic logic [DCACHE_SET_ASSOC-1:0] dcache_way_bin2oh (
    input logic [$clog2(DCACHE_SET_ASSOC)-1:0] in
  );
    logic [DCACHE_SET_ASSOC-1:0] out;
    out     = '0;
    out[in] = 1'b1;
    return out;
  endfunction

  function automatic logic [ICACHE_SET_ASSOC-1:0] icache_way_bin2oh (
    input logic [$clog2(ICACHE_SET_ASSOC)-1:0] in
  );
    logic [ICACHE_SET_ASSOC-1:0] out;
    out     = '0;
    out[in] = 1'b1;
    return out;
  endfunction

  function automatic logic [DCACHE_NUM_BANKS-1:0] dcache_cl_bin2oh (
    input logic [$clog2(DCACHE_NUM_BANKS)-1:0] in
  );
    logic [DCACHE_NUM_BANKS-1:0] out;
    out     = '0;
    out[in] = 1'b1;
    return out;
  endfunction


  function automatic logic [5:0] popcnt64 (
    input logic [63:0] in
  );
    logic [5:0] cnt= 0;
    foreach (in[k]) begin
      cnt += 6'(in[k]);
    end
    return cnt;
  endfunction : popcnt64

  function automatic logic [7:0] toByteEnable8(
    input logic [2:0] offset,
    input logic [1:0] size
  );
    logic [7:0] be;
    be = '0;
    unique case(size)
      2'b00:   be[offset]       = '1; // byte
      2'b01:   be[offset +:2 ]  = '1; // hword
      2'b10:   be[offset +:4 ]  = '1; // word
      default: be               = '1; // dword
    endcase // size
    return be;
  endfunction : toByteEnable8

  // openpiton requires the data to be replicated in case of smaller sizes than dwords
  function automatic logic [63:0] repData64(
    input logic [63:0] data,
    input logic [2:0]  offset,
    input logic [1:0]  size
  );
    logic [63:0] out;
    unique case(size)
      2'b00:   for(int k=0; k<8; k++) out[k*8  +: 8]    = data[offset*8 +: 8];  // byte
      2'b01:   for(int k=0; k<4; k++) out[k*16 +: 16]   = data[offset*8 +: 16]; // hword
      2'b10:   for(int k=0; k<2; k++) out[k*32 +: 32]   = data[offset*8 +: 32]; // word
      default: out   = data; // dword
    endcase // size
    return out;
  endfunction : repData64

  // note: this is openpiton specific. cannot transmit unaligned words.
  // hence we default to individual bytes in that case, and they have to be transmitted
  // one after the other
  function automatic logic [1:0] toSize64(
    input logic  [7:0] be
  );
    logic [1:0] size;
    unique case(be)
      8'b1111_1111:                                           size = 2'b11;  // dword
      8'b0000_1111, 8'b1111_0000:                             size = 2'b10; // word
      8'b1100_0000, 8'b0011_0000, 8'b0000_1100, 8'b0000_0011: size = 2'b01; // hword
      default:                                                size = 2'b00; // individual bytes
    endcase // be
    return size;
  endfunction : toSize64

  // align the physical address to the specified size:
  // 000: bytes
  // 001: hword
  // 010: word
  // 011: dword
  // 111: DCACHE line
  function automatic logic [63:0] paddrSizeAlign(
    input logic [63:0] paddr,
    input logic [2:0]  size
  );
    logic [63:0] out;
    out = paddr;
    unique case (size)
      3'b001: out[0:0]                     = '0;
      3'b010: out[1:0]                     = '0;
      3'b011: out[2:0]                     = '0;
      3'b111: out[DCACHE_OFFSET_WIDTH-1:0] = '0;
      default: ;
    endcase
    return out;
  endfunction : paddrSizeAlign


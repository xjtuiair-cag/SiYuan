package axi_pkg;

  typedef logic [1:0] burst_t;
  typedef logic [1:0] resp_t;
  typedef logic [3:0] cache_t;
  typedef logic [2:0] prot_t;
  typedef logic [3:0] qos_t;
  typedef logic [3:0] region_t;
  typedef logic [7:0] len_t;
  typedef logic [2:0] size_t;
  typedef logic [5:0] atop_t; // atomic operations
  typedef logic [3:0] nsaid_t; // non-secure address identifier

  localparam BURST_FIXED = 2'b00;
  localparam BURST_INCR  = 2'b01;
  localparam BURST_WRAP  = 2'b10;

  localparam RESP_OKAY   = 2'b00;
  localparam RESP_EXOKAY = 2'b01;
  localparam RESP_SLVERR = 2'b10;
  localparam RESP_DECERR = 2'b11;

  localparam CACHE_BUFFERABLE = 4'b0001;
  localparam CACHE_MODIFIABLE = 4'b0010;
  localparam CACHE_RD_ALLOC   = 4'b0100;
  localparam CACHE_WR_ALLOC   = 4'b1000;


  // 4 is recommended by AXI standard, so lets stick to it, do not change
  localparam IdWidth   = 4;
  localparam UserWidth = 1;
  localparam AddrWidth = 64;
  localparam DataWidth = 64;
  localparam StrbWidth = DataWidth / 8;

  typedef logic [IdWidth-1:0]   id_t;
  typedef logic [AddrWidth-1:0] addr_t;
  typedef logic [DataWidth-1:0] data_t;
  typedef logic [StrbWidth-1:0] strb_t;
  typedef logic [UserWidth-1:0] user_t;

  // AW Channel
  typedef struct packed {
      id_t     id;
      addr_t   addr;
      len_t    len;
      size_t   size;
      burst_t  burst;
      logic    lock;
      cache_t  cache;
      prot_t   prot;
      qos_t    qos;
  } aw_chan_t;

  // W Channel
  typedef struct packed {
      data_t data;
      strb_t strb;
      logic  last;
  } w_chan_t;

  // B Channel
  typedef struct packed {
      id_t   id;
      resp_t resp;
  } b_chan_t;

  // AR Channel
  typedef struct packed {
      id_t     id;
      addr_t   addr;
      len_t    len;
      size_t   size;
      burst_t  burst;
      logic    lock;
      cache_t  cache;
      prot_t   prot;
      qos_t    qos;
  } ar_chan_t;

  // R Channel
  typedef struct packed {
      id_t   id;
      data_t data;
      resp_t resp;
      logic  last;
  } r_chan_t;

  typedef union packed {
      aw_chan_t aw;
      ar_chan_t ar;
  } arw_t;

endpackage
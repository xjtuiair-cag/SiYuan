//----------------------------------------------------------------------------------------------------------------------
// Overall parameters
//----------------------------------------------------------------------------------------------------------------------

  // Data width
  parameter IWTH = 32;                    // instruction width
  parameter AWTH = 64;                    // address width
  parameter DWTH = 64;                    // data width
  parameter CSR_WTH = 12;                 // CSR address width

  parameter IDWTH = 4;                    // AXI ID width
  parameter XAWTH = 35;                   // AXI address width
  parameter XDWTH = 128;                  // AXI data width

  localparam NrMaxRules = 16;

  localparam cacheable_region = 1;
  localparam logic [NrMaxRules-1:0][63:0] CachedRegionAddrBase = {64'h8000_0000};
  localparam logic [NrMaxRules-1:0][63:0] CachedRegionLength =  {64'h40000000};


  typedef struct packed {
    int                               RASDepth;
    int                               BTBEntries;
    int                               BHTEntries;
    // PMAs
    int unsigned                      NrNonIdempotentRules;  // Number of non idempotent rules
    logic [NrMaxRules-1:0][63:0]      NonIdempotentAddrBase; // base which needs to match
    logic [NrMaxRules-1:0][63:0]      NonIdempotentLength;   // bit mask which bits to consider when matching the rule
    int unsigned                      NrExecuteRegionRules;  // Number of regions which have execute property
    logic [NrMaxRules-1:0][63:0]      ExecuteRegionAddrBase; // base which needs to match
    logic [NrMaxRules-1:0][63:0]      ExecuteRegionLength;   // bit mask which bits to consider when matching the rule
    int unsigned                      NrCachedRegionRules;   // Number of regions which have cached property
    logic [NrMaxRules-1:0][63:0]      CachedRegionAddrBase;  // base which needs to match
    logic [NrMaxRules-1:0][63:0]      CachedRegionLength;    // bit mask which bits to consider when matching the rule
    // cache config
    bit                               Axi64BitCompliant;     // set to 1 when using in conjunction with 64bit AXI bus adapter
    bit                               SwapEndianess;         // set to 1 to swap endianess inside L1.5 openpiton adapter
    //
    logic [63:0]                      DmBaseAddress;         // offset of the debug module
  } sy_cfg_t;

    localparam sy_cfg_t SyDefaultConfig = '{
      RASDepth: 2,
      BTBEntries: 32,
      BHTEntries: 128,
      // idempotent region
      NrNonIdempotentRules: 0,
      NonIdempotentAddrBase: {64'b0, 64'b0},
      NonIdempotentLength:   {64'b0, 64'b0},
      NrExecuteRegionRules: 3,
      //                      DRAM,          Boot ROM,   Debug Module
      ExecuteRegionAddrBase: {64'h8000_0000, 64'h1_0000, 64'h0},
      ExecuteRegionLength:   {64'h40000000,  64'h10000,  64'h1000},
      // cached region
      NrCachedRegionRules:    1,
      // CachedRegionAddrBase:  {64'h8000_0000},
      CachedRegionAddrBase:  {64'h8000_0000},
      CachedRegionLength:    {64'h40000000},
      //  cache config
      Axi64BitCompliant:      1'b1,
      SwapEndianess:          1'b0,
      // debug
      DmBaseAddress:          64'h0
    };
  
  function automatic logic range_check(logic[63:0] base, logic[63:0] len, logic[63:0] address);
      // if len is a power of two, and base is properly aligned, this check could be simplified
      return (address >= base) && (address < (base+len));
  endfunction : range_check

  function automatic logic is_inside_cacheable_regions (swf_cfg_t Cfg, logic[63:0] address);
      automatic logic[NrMaxRules-1:0] pass;
      pass = '0;
      for (int unsigned k = 0; k < Cfg.NrCachedRegionRules; k++) begin
          pass[k] = range_check(Cfg.CachedRegionAddrBase[k], Cfg.CachedRegionLength[k], address);
      end
      return |pass;
  endfunction : is_inside_cacheable_regions

  function automatic logic is_cacheable(logic[63:0] address);
      automatic logic[NrMaxRules-1:0] pass;
      pass = '0;
      for (int unsigned k = 0; k < cacheable_region ; k++) begin
          pass[k] = range_check(CachedRegionAddrBase[k], CachedRegionLength[k], address);
      end
      return |pass;
  endfunction : is_cacheable


    function automatic logic is_inside_execute_regions (swf_cfg_t Cfg, logic[63:0] address);
      // if we don't specify any region we assume everything is accessible
      logic[NrMaxRules-1:0] pass;
      pass = '0;
      for (int unsigned k = 0; k < Cfg.NrExecuteRegionRules; k++) begin
        pass[k] = range_check(Cfg.ExecuteRegionAddrBase[k], Cfg.ExecuteRegionLength[k], address);
      end
      return |pass;
    endfunction : is_inside_execute_regions
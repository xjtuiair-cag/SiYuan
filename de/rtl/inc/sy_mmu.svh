    parameter ASID_WIDTH = 1;
    parameter TLB_ENTRIES = 8;
    parameter VPN_PER_WIDTH = 9;
    parameter VPN_WIDTH = 27;
    parameter PAGE_OFFSET_WIDTH = 12;
    parameter PPN_WIDTH = 44;
    parameter ADDR_WIDTH = 64;
    parameter VADDR_WIDTH = 39;
    parameter PADDR_WIDTH = 56;

    typedef struct packed {
        logic [9:0]  reserved;
        logic [43:0] ppn;
        logic [1:0]  rsw;
        logic d;
        logic a;
        logic g;
        logic u;
        logic x;
        logic w;
        logic r;
        logic v;
    } pte_t;

    typedef struct packed {
        logic                  valid;      // valid flag
        logic                  is_2M;      //
        logic                  is_1G;      //
        logic [26:0]           vpn;
        logic [ASID_WIDTH-1:0] asid;
        pte_t           content;
    } tlb_update_t;




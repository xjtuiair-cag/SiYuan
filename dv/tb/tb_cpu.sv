// +FHDR------------------------------------------------------------------------
// XJTU IAIR Corporation All Rights Reserved
// -----------------------------------------------------------------------------
// FILE NAME  : tb_cpu.v
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
import "DPI-C" function string getenv (input string env_name);

module tb_cpu;
    logic                           clk;
    logic                           clk_rtc;
    logic                           rst;

    logic                           tck; 
    logic                           tms; 
    logic                           trst_n;
    logic                           tdi; 
    logic                           tdo;
    // config bus
    logic[15:0]                     cfg_awaddr; 
    logic                           cfg_awvalid;
    logic                           cfg_awready;
    logic[31:0]                     cfg_wdata;  
    logic                           cfg_wvalid; 
    logic                           cfg_wready; 
    logic[1:0]                      cfg_bresp;  
    logic                           cfg_bvalid; 
    logic                           cfg_bready; 
    logic[15:0]                     cfg_araddr; 
    logic                           cfg_arvalid;
    logic                           cfg_arready;
    logic[31:0]                     cfg_rdata;  
    logic[1:0]                      cfg_rresp;  
    logic                           cfg_rvalid; 
    logic                           cfg_rready; 
    // DDR interface
    logic[3:0]                      cpu_awid;    
    logic[39:0]                     cpu_awaddr;  
    logic[7:0]                      cpu_awlen;   
    logic[2:0]                      cpu_awsize;  
    logic[1:0]                      cpu_awburst; 
    logic                           cpu_awvalid; 
    logic                           cpu_awready; 
    // logic[3:0]                      cpu_wid;     
    logic[63:0]                     cpu_wdata;   
    logic[7:0]                      cpu_wstrb;   
    logic                           cpu_wlast;   
    logic                           cpu_wvalid;  
    logic                           cpu_wready;  
    logic[3:0]                      cpu_bid;     
    logic[1:0]                      cpu_bresp;   
    logic                           cpu_bvalid;  
    logic                           cpu_bready;  
    logic[3:0]                      cpu_arid;   
    logic[39:0]                     cpu_araddr; 
    logic[7:0]                      cpu_arlen;  
    logic[2:0]                      cpu_arsize; 
    logic[1:0]                      cpu_arburst;
    logic                           cpu_arvalid;
    logic                           cpu_arready;
    logic[3:0]                      cpu_rid;    
    logic[63:0]                     cpu_rdata;  
    logic                           cpu_rlast;  
    logic[1:0]                      cpu_rresp;  
    logic                           cpu_rvalid; 
    logic                           cpu_rready; 
    // AXI-lite 32 interface
    logic[31:0]                     axil32_awaddr;  
    logic                           axil32_awvalid; 
    logic                           axil32_awready; 
    logic[31:0]                     axil32_wdata;   
    logic[3:0]                      axil32_wstrb;   
    logic                           axil32_wvalid;  
    logic                           axil32_wready;  
    logic[1:0]                      axil32_bresp;   
    logic                           axil32_bvalid;  
    logic                           axil32_bready;  
    logic[31:0]                     axil32_araddr;  
    logic                           axil32_arvalid; 
    logic                           axil32_arready; 
    logic[31:0]                     axil32_rdata;   
    logic[1:0]                      axil32_rresp;   
    logic                           axil32_rvalid;  
    logic                           axil32_rready;  
    // uart 
    logic                           uart_tx;
    logic                           uart_rx;

    logic                           sd_detect;
    logic                           sd_clk;
    logic                           sd_reset;
    logic [3:0]                     sd_dat_i;
    logic [3:0]                     sd_dat_o;
    logic                           sd_dat_oe_o;
    logic                           sd_cmd_i;
    logic                           sd_cmd_o;
    logic                           sd_cmd_oe_o;

    logic                           sd_device_cmd_i;
    logic                           sd_device_cmd_o;
    logic                           sd_device_cmd_t;
    logic [3:0]                     sd_device_dat_i;
    logic [3:0]                     sd_device_dat_o;
    logic [3:0]                     sd_device_dat_t;

    logic                           sd_clk_ref;  // 50M  
    logic                           sd_clk_true; // 50M or 256K   
    logic                           sd_clk_fast;
    logic                           sd_clk_slow;
    logic                           sd_clk_sel;

    logic                           wbm_clk;
    logic [31:0]                    wbm_adr;
    logic [31:0]                    wbm_dat_o;
    logic [31:0]                    wbm_dat_i;
    logic [3:0]                     wbm_sel;
    logic                           wbm_cyc;
    logic                           wbm_stb;
    logic                           wbm_we ;
    logic                           wbm_ack;
    logic [2:0]                     wbm_cti;
    logic [1:0]                     wbm_bte;
    logic [31:0]                    rdata;

    assign sd_detect = 1'b0;
    string state;
    string test;
    logic  boot_mode;

    initial begin
        state = getenv("BOOTMODE");
        test = getenv("TEST");
        if (state == "0") begin
            boot_mode = 1'b0;
        end else if (state == "1") begin
            boot_mode = 1'b1;
        end else begin
            boot_mode = 1'b1;
        end
    end

    cpu cpu_inst(
        // -------------------------------------
        // [clock & reset]
        .clk_sys_i      (clk),
        .clk_rtc_i      (clk_rtc),
        .rst_sys_i      (rst),
        .rst_i          (rst),
        .ndmreset_o     (),
        // -------------------------------------
        // [SD clock]
        // .sd_clk_ref     (clk),  // 50M  
        // -------------------------------------
        // [JTAG debug]
        .jtag_tck_i     (tck),
        .jtag_trst_n_i  (trst_n),
        .jtag_tms_i     (tms),
        .jtag_tdi_i     (tdi),
        .jtag_tdo_o     (tdo),
        // -------------------------------------
        // [Config]
        // -- AXI Lite
        // -- write channel
        .cfg_awaddr_i   (cfg_awaddr ),
        .cfg_awvalid_i  (cfg_awvalid),
        .cfg_awready_o  (cfg_awready),
        .cfg_wdata_i    (cfg_wdata  ),
        .cfg_wvalid_i   (cfg_wvalid ),
        .cfg_wready_o   (cfg_wready ),
        .cfg_bresp_o    (cfg_bresp  ),
        .cfg_bvalid_o   (cfg_bvalid ),
        .cfg_bready_i   (cfg_bready ),
        // -- read channel
        .cfg_araddr_i   (cfg_araddr ),
        .cfg_arvalid_i  (cfg_arvalid),
        .cfg_arready_o  (cfg_arready),
        .cfg_rdata_o    (cfg_rdata  ),
        .cfg_rresp_o    (cfg_rresp  ),
        .cfg_rvalid_o   (cfg_rvalid ),
        .cfg_rready_i   (cfg_rready ),
        // -- Boot mode
        .boot_mode_i    (boot_mode), // 1'h0: idle; 1'h1: boot ROM;
        // -------------------------------------
        // [L1 cache (instr/data)]
        // -- <write channel>
        .cpu_awid_o     (cpu_awid    ),
        .cpu_awaddr_o   (cpu_awaddr  ),
        .cpu_awlen_o    (cpu_awlen   ),
        .cpu_awsize_o   (cpu_awsize  ),
        .cpu_awburst_o  (cpu_awburst ),
        .cpu_awvalid_o  (cpu_awvalid ),
        .cpu_awready_i  (cpu_awready ),
        // .cpu_wid_o      (cpu_wid     ),
        .cpu_wdata_o    (cpu_wdata   ),
        .cpu_wstrb_o    (cpu_wstrb   ),
        .cpu_wlast_o    (cpu_wlast   ),
        .cpu_wvalid_o   (cpu_wvalid  ),
        .cpu_wready_i   (cpu_wready  ),
        .cpu_bid_i      (cpu_bid     ),
        .cpu_bresp_i    (cpu_bresp   ),
        .cpu_bvalid_i   (cpu_bvalid  ),
        .cpu_bready_o   (cpu_bready  ),
        // -- <read channel>
        .cpu_arid_o     (cpu_arid    ),
        .cpu_araddr_o   (cpu_araddr  ),
        .cpu_arlen_o    (cpu_arlen   ),
        .cpu_arsize_o   (cpu_arsize  ),
        .cpu_arburst_o  (cpu_arburst ),
        .cpu_arvalid_o  (cpu_arvalid ),
        .cpu_arready_i  (cpu_arready ),
        .cpu_rid_i      (cpu_rid     ),
        .cpu_rdata_i    (cpu_rdata   ),
        .cpu_rlast_i    (cpu_rlast   ),
        .cpu_rresp_i    (cpu_rresp   ),
        .cpu_rvalid_i   (cpu_rvalid  ),
        .cpu_rready_o   (cpu_rready  ),
        // -------------------------------------
        // [32bit AXI lite bus master]
        // -- write
        .axil32_awaddr_o    (axil32_awaddr ),
        .axil32_awvalid_o   (axil32_awvalid),
        .axil32_awready_i   (axil32_awready),
        .axil32_wdata_o     (axil32_wdata  ),
        .axil32_wstrb_o     (axil32_wstrb  ),
        .axil32_wvalid_o    (axil32_wvalid ),
        .axil32_wready_i    (axil32_wready ),
        .axil32_bresp_i     (axil32_bresp  ),
        .axil32_bvalid_i    (axil32_bvalid ),
        .axil32_bready_o    (axil32_bready ),
        // -- read
        .axil32_araddr_o    (axil32_araddr  ),
        .axil32_arvalid_o   (axil32_arvalid ),
        .axil32_arready_i   (axil32_arready ),
        .axil32_rdata_i     (axil32_rdata   ),
        .axil32_rresp_i     (axil32_rresp   ),
        .axil32_rvalid_i    (axil32_rvalid  ),
        .axil32_rready_o    (axil32_rready  ),
        // -------------------------------------
        // [UART]
        .uart_txd_o         (uart_tx),
        .uart_rxd_i         (uart_rx),
        // -------------------------------------
        // [SD]
        .sd_detect          (sd_detect  ),
        .sd_clk             (sd_clk     ),
        .sd_reset           (sd_reset   ),
        .sd_dat_i           (sd_dat_i   ),
        .sd_dat_o           (sd_dat_o   ),
        .sd_dat_oe_o        (sd_dat_oe_o),
        .sd_cmd_i           (sd_cmd_i   ),
        .sd_cmd_o           (sd_cmd_o   ),
        .sd_cmd_oe_o        (sd_cmd_oe_o)    
    );

    assign sd_device_cmd_i = sd_cmd_o;
    assign sd_device_dat_i = sd_dat_o;
    assign sd_cmd_i = sd_device_cmd_o;
    assign sd_dat_i = sd_device_dat_o;
    sd_top u_sd(
       // clocking/reset
       .clk_50            (clk),
       .clk_100           (clk),
       .clk_200           (clk),
       .reset_n           (rst),
       // physical interface to SD pins
       .sd_clk            (sd_clk),
       .sd_cmd_i          (sd_device_cmd_i),
       .sd_cmd_o          (sd_device_cmd_o),
       .sd_cmd_t          (sd_device_cmd_t),
       .sd_dat_i          (sd_device_dat_i),
       .sd_dat_o          (sd_device_dat_o),
       .sd_dat_t          (sd_device_dat_t),
       // wishbone interface
       .wbm_clk_o         (wbm_clk),
       .wbm_adr_o         (wbm_adr),
       .wbm_dat_i         (wbm_dat_i),
       .wbm_dat_o         (wbm_dat_o),
       .wbm_sel_o         (wbm_sel),
       .wbm_cyc_o         (wbm_cyc),
       .wbm_stb_o         (wbm_stb),
       .wbm_we_o          (wbm_we ),
       .wbm_ack_i         (wbm_ack),
       .wbm_cti_o         (wbm_cti),
       .wbm_bte_o         (wbm_bte),
       // options
       .opt_enable_hs     ('0)
       // debug (optional)
    );

    wb_ram #(
        .depth (16384),
        .memfile ("./sd.dat")
    ) u_wb_ram(
        .wb_clk_i         (wbm_clk),    
        .wb_rst_i         (!rst),    

        .wb_adr_i         (wbm_adr[13:0]),    
        .wb_dat_i         (wbm_dat_o),    
        .wb_sel_i         (wbm_sel),    
        .wb_we_i          (wbm_we),   
        .wb_bte_i         (wbm_bte),    
        .wb_cti_i         (wbm_cti),    
        .wb_cyc_i         (wbm_cyc),    
        .wb_stb_i         (wbm_stb),    

        .wb_ack_o         (wbm_ack),    
        .wb_err_o         (),    
        .wb_dat_o         (wbm_dat_i)
    );

    // DDR simulation file
    axi_mem_sim # (
      .ADDR_WTH  (40),
      .DATA_WTH  (64),
      .MEM_SIZE  (64*1024*1024)
    ) ddr_sim(
        .clk_i                (clk),          
        .rst_i                (rst),          

        .awaddr               (cpu_awaddr),           
        .awburst              (cpu_awburst),            
        .awcache              ('0),            
        .awlen                (cpu_awlen),          
        .awid                 (cpu_awid),         
        .awlock               ('0),           
        .awprot               ('0),           
        .awqos                ('0),          
        .awregion             ('0),
        .awsize               (cpu_awsize),           
        .awvalid              (cpu_awvalid),            
        .awready              (cpu_awready),            

        .wdata                (cpu_wdata),          
        .wlast                (cpu_wlast),          
        .wstrb                (cpu_wstrb),          
        .wvalid               (cpu_wvalid),           
        .wready               (cpu_wready),           

        .bresp                (cpu_bresp),          
        .bid                  (cpu_bid),            
        .bvalid               (cpu_bvalid),           
        .bready               (cpu_bready),           

        .araddr               (cpu_araddr),           
        .arburst              (cpu_arburst),            
        .arcache              ('0),            
        .arlen                (cpu_arlen),          
        .arid                 (cpu_arid),         
        .arlock               ('0),           
        .arprot               ('0),           
        .arqos                ('0),          
        .arsize               (cpu_arsize),           
        .arregion             ('0),             
        .arready              (cpu_arready),            
        .arvalid              (cpu_arvalid),            

        .rdata                (cpu_rdata),          
        .rlast                (cpu_rlast),          
        .rready               (cpu_rready),           
        .rresp                (cpu_rresp),          
        .rid                  (cpu_rid),        
        .rvalid               (cpu_rvalid)
    );

    // Bootrom 
    axi_lite32_bootrom #(
        .ADDR_WIDTH  (16),            
        .DATA_WIDTH  (32)
    ) bootrom(
        .ACLK                   (clk),
        .ARESETn                (rst),
        // Write address channel
        .AWVALID                (axil32_awvalid),
        .AWREADY                (axil32_awready),
        .AWADDR                 (axil32_awaddr[15:0]),
        // Write data channel
        .WVALID                 (axil32_wvalid),
        .WREADY                 (axil32_wready),
        .WDATA                  (axil32_wdata),
        .WSTRB                  (axil32_wstrb),
        // Write response channel
        .BVALID                 (axil32_bvalid),
        .BREADY                 (axil32_bready),
        .BRESP                  (axil32_bresp), // 2'b00 = OKAY
        // Read address channel
        .ARVALID                (axil32_arvalid),
        .ARREADY                (axil32_arready),
        .ARADDR                 (axil32_araddr[15:0]),
        // Read data channel
        .RVALID                 (axil32_rvalid),
        .RREADY                 (axil32_rready),
        .RDATA                  (axil32_rdata),
        .RRESP                  (axil32_rresp)
    ); 

    // uart receive sim
    logic rx_done;
    logic [7:0] rx_data;

    // uart module
    UART_rec #(
        .BPS            (115200),
        .CLK_fre        (50000000),
        .DATA_WIDTH     (8)
    ) u_uart_rec(
        .clk          (clk          ) ,
        .rstn         (rst          ) , 
        .uart_rx      (uart_tx      ) ,    
        .rx_done      (rx_done      ) ,    
        .rece_data    (rx_data      )  
    );
    logic   rx_done_dly0;
    logic   rx_done_dly1;
    logic   done;
    // generate done singal in clk domain
    always_ff @(posedge clk) begin 
        rx_done_dly0 <= rx_done;
        rx_done_dly1 <= rx_done_dly0;
    end
    assign done = ~rx_done_dly1 && rx_done_dly0;

    always@(posedge clk) begin : print_uart_data 
        if(done) begin
            $write("%c", rx_data);
            $fwrite(res,"%c",rx_data);
        end 
    end

    task automatic axi_lite_write(
        input  logic [15:0] addr,
        input  logic [31:0] data
    );
        // Write address
        cfg_awaddr  = addr;
        cfg_awvalid = 1'b1;
        wait (cfg_awready);
        @(posedge clk);
        cfg_awvalid = 1'b0;

        // Write data
        cfg_wdata = data;
        cfg_wvalid = 1'b1;
        wait (cfg_wready);
        @(posedge clk);
        cfg_wvalid = 1'b0;

        // Write response
        cfg_bready = 1'b1;
        wait (cfg_bvalid);
        @(posedge clk);
        cfg_bready = 1'b0;

        if (cfg_bresp != 2'b00) begin
            $error("AXI-Lite WRITE error, BRESP = %0h", cfg_bresp);
        end
    endtask

    task automatic axi_lite_read(
        input  logic [15:0] addr,
        output logic [31:0] data
    );
        // Read address
        cfg_araddr = addr;
        cfg_arvalid = 1'b1;
        wait (cfg_arready);
        @(posedge clk);
        cfg_arvalid = 1'b0;

        // Read data
        cfg_rready = 1'b1;
        wait (cfg_rvalid);
        @(posedge clk);
        data = cfg_rdata;
        cfg_rready = 1'b0;

        if (cfg_rresp != 2'b00) begin
            $error("AXI-Lite READ error, RRESP = %0h", cfg_rresp);
        end
    endtask

    task automatic axi_lite_poll_until_zero(
        input  logic [15:0] addr,
        input  int unsigned max_cycles = 1000000
    );
        logic [31:0] read_data;
        int unsigned cycle;

        cycle = 0;
        do begin
            axi_lite_read(addr, read_data);

            if (read_data == 32'h0) begin
                $display("[%0t] POLL DONE, reg[0x%08x] = 0",
                         $time, addr);
                return;
            end

            // 等待一个或多个时钟，避免读爆 DUT
            repeat (1) @(posedge clk);
            cycle = cycle + 1;

        end while (cycle < max_cycles);

        $fatal(1,
            "[%0t] POLL TIMEOUT! reg[0x%08x] never becomes zero",
            $time, addr
        );
    endtask

    task automatic rmtcall(
        input  logic [31:0] boot_addr,
        input  logic [31:0] ret_addr,
        input  logic [31:0] ctrl,
        input  logic        kill,
        input  logic [31:0] kill_ctrl,
        input  int unsigned wait_kill_cnt
    ); 
        // init PC
        axi_lite_write(16'h90, boot_addr);
        // return addr 
        axi_lite_write(16'h98, ret_addr);
        // start/invalidate ic/invalidate dc 
        axi_lite_write(16'h04, ctrl);       
        // delay 100 cycle
        if (kill == 1'b1) begin
            repeat (wait_kill_cnt) @(posedge clk);
            axi_lite_write(16'h04, kill_ctrl);       
            repeat (wait_kill_cnt) @(posedge clk);
            axi_lite_write(16'h04, ctrl);       
        end 
            
        do begin
            axi_lite_read(16'h08, rdata); 
            repeat (10) @(posedge clk);
        end while ((rdata & 32'hffff ) != 32'b0);
        repeat (10) @(posedge clk);
        axi_lite_read(16'h10, rdata); 
    endtask

    integer res;
    string s;

    initial begin
        res = $fopen("res.txt","w");
        #10;
        if (boot_mode == 1'b1) begin
            forever begin
                @(posedge clk iff (axil32_awvalid== 1'b1 && axil32_awaddr == 32'h4200_0000));
                if(axil32_wdata == 32'b0) begin
                    s = { "\n##########################################################\n"};
                    s = {s, "#                ####    #    ####  ####                 #\n"};
                    s = {s, "#                #  #   # #   #     #                    #\n"};
                    s = {s, "#                ####  #####  ####  ####                 #\n"};
                    s = {s, "#                #     #   #     #     #                 #\n"};
                    s = {s, "#                #     #   #  ####  ####                 #\n"};
                    s = {s, "##########################################################\n"};
                    s = {s, "####################### TEST PASS ########################\n"};
                    s = {s, "##########################################################\n"};
                    $display("%s",s);
                    $fwrite(res,"\nTEST PASS");
                end else begin
                    s = { "\n##########################################################\n"};
                    s = {s, "#           ####    #    ###  #     ####  ###            #\n"};
                    s = {s, "#           #      # #    #   #     #     #  #           #\n"};
                    s = {s, "#           ####  #####   #   #     ####  #  #           #\n"};
                    s = {s, "#           #     #   #   #   #     #     #  #           #\n"};
                    s = {s, "#           #     #   #  ###  ####  ####  ###            #\n"};
                    s = {s, "##########################################################\n"};
                    s = {s, "###################### TEST FAILED #######################\n"};
                    s = {s, "##########################################################\n"};
                    $display("%s",s);
                    $display("\nTEST FAIL: %h",axil32_wdata);
                    $fwrite(res,"\nTEST FAIL: %h",axil32_wdata);
                end
                $finish;
            end
        end else begin
            // 初始化信号
            cfg_awvalid = 0;
            cfg_wvalid  = 0;
            cfg_bready  = 0;
            cfg_arvalid = 0;
            cfg_rready  = 0;
            // delay 100 cycle
            repeat (100) @(posedge clk);
            if (test == "bootmode_test_01") begin
                // start core 0
                rmtcall(32'h80000000,32'hA0000000,32'h111,1'b0,32'h0,300);   
            end else if (test == "bootmode_test_02") begin
                // start core 1
                rmtcall(32'h80000000,32'hA0000000,32'h222,1'b0,32'h0,300);                  
            end else if (test == "bootmode_test_03") begin
                // start core 2
                rmtcall(32'h80000000,32'hA0000000,32'h444,1'b0,32'h0,300);                  
            end else if (test == "bootmode_test_04") begin
                // start core 3
                rmtcall(32'h80000000,32'hA0000000,32'h888,1'b0,32'h0,300);                  
            end else if (test == "bootmode_test_05") begin
                // start core 0 and kill core 0
                rmtcall(32'h80000000,32'hA0000000,32'h111,1'b1,32'h1000,300);                  
            end else if (test == "bootmode_test_06") begin
                // start core 1 and kill core 1
                rmtcall(32'h80000000,32'hA0000000,32'h222,1'b1,32'h2000,300);                  
            end else if (test == "bootmode_test_07") begin
                // start core 2 and kill core 2
                rmtcall(32'h80000000,32'hA0000000,32'h444,1'b1,32'h4000,300);                  
            end else if (test == "bootmode_test_08") begin
                // start core 3 and kill core 3
                rmtcall(32'h80000000,32'hA0000000,32'h888,1'b1,32'h8000,300);                  
            end else if (test == "bootmode_test_09") begin
                // start 4 cores 
                rmtcall(32'h80000000,32'hA0000000,32'hFFF,1'b0,32'h0,300);                  
            end else if (test == "bootmode_test_10") begin
                // start 4 cores (forbid br pred/fence state = 1/ invalidate L2 cache)
                rmtcall(32'h80000000,32'hA0000000,32'h2FF0FFF,1'b0,32'h0,300);                  
            end


            if(rdata == 32'b0) begin
                s = { "\n##########################################################\n"};
                s = {s, "#                ####    #    ####  ####                 #\n"};
                s = {s, "#                #  #   # #   #     #                    #\n"};
                s = {s, "#                ####  #####  ####  ####                 #\n"};
                s = {s, "#                #     #   #     #     #                 #\n"};
                s = {s, "#                #     #   #  ####  ####                 #\n"};
                s = {s, "##########################################################\n"};
                s = {s, "####################### TEST PASS ########################\n"};
                s = {s, "##########################################################\n"};
                $display("%s",s);
                $fwrite(res,"\nTEST PASS");
            end else begin
                s = { "\n##########################################################\n"};
                s = {s, "#           ####    #    ###  #     ####  ###            #\n"};
                s = {s, "#           #      # #    #   #     #     #  #           #\n"};
                s = {s, "#           ####  #####   #   #     ####  #  #           #\n"};
                s = {s, "#           #     #   #   #   #     #     #  #           #\n"};
                s = {s, "#           #     #   #  ###  ####  ####  ###            #\n"};
                s = {s, "##########################################################\n"};
                s = {s, "###################### TEST FAILED #######################\n"};
                s = {s, "##########################################################\n"};
                $display("%s",s);
                $display("\nTEST FAIL: %h",rdata);
                $fwrite(res,"\nTEST FAIL: %h",rdata);
            end
            $finish;
        end
    end

    // clock generation
    initial begin
        clk = 1'b0;
        #10 clk = 1'b1;
        forever begin
            #2 clk <= !clk; // 500MHz
        end
    end

    // clock generation
    initial begin
        clk_rtc = 1'b0;
        #3 clk_rtc = 1'b1;
        forever begin
            #10000 clk_rtc <= !clk_rtc; // 500MHz
        end
    end

    // reset generation
    initial begin
        rst = 1'b1;
        #10;
        rst = 1'b0;
        #10;
        rst = 1'b1;
    end


    initial begin
        $fsdbDumpfile("tb_cpu.fsdb");
        $fsdbDumpvars(0, tb_cpu, "+mda", "+all");
        //$vcdplusmemon();
    end

endmodule
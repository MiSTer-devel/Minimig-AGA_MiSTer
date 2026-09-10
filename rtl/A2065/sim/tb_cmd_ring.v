/*
 * tb_cmd_ring.v — 68k register writes must complete without the host.
 *
 * The deadlock this guards against: Main is single-threaded, and while it sits
 * in its IDE handler waiting on the Amiga, the Amiga must not be sitting on a
 * stretched DTACK waiting on Main. Register writes therefore have to retire on
 * FPGA progress alone — the entry reaching DDR3 — and never on the host having
 * read it.
 *
 * The host is deliberately absent here: nothing in this bench ever reads the
 * ring or writes anything back. If a write still needs the host, the bus never
 * releases and the test fails.
 */
`timescale 1ns/1ps

module tb_cmd_ring;

    reg clk_sys = 0; always #17.46 clk_sys = ~clk_sys;   // 28.6 MHz, Amiga side
    reg clk_ddr = 0; always #4.364 clk_ddr = ~clk_ddr;   // 114.5 MHz, DDR3 side
    reg rst_n = 0;

    reg  [23:0] cpu_addr = 0;
    reg         cpu_rw = 1, cpu_as_n = 1, cpu_ds_n = 1;
    reg  [15:0] cpu_data_in = 0;
    wire [15:0] cpu_data_out;
    wire        regs_nrdy;

    wire        cmd_pending, cmd_clear;
    wire [6:0]  cmd_rap;
    wire [15:0] cmd_data;

    integer pass = 0, fail = 0;
    task check(input cond, input [511:0] name);
        begin
            if (cond) begin pass = pass + 1; $display("  PASS  %0s", name); end
            else      begin fail = fail + 1; $display("  FAIL  %0s", name); end
        end
    endtask

    a2065_regfile regfile (
        .clk(clk_sys), .rst_n(rst_n),
        .cpu_addr(cpu_addr), .cpu_rw(cpu_rw), .cpu_as_n(cpu_as_n),
        .cpu_ds_n(cpu_ds_n), .cpu_data_in(cpu_data_in),
        .cpu_data_out(cpu_data_out), .regs_nrdy(regs_nrdy),
        .card_base(8'hEA), .card_configured(1'b1),
        .cmd_pending(cmd_pending), .cmd_rap(cmd_rap), .cmd_data(cmd_data),
        .cmd_clear(cmd_clear),
        .csr0_in(16'h0004), .csr1_in(16'd0), .csr2_in(16'd0), .csr3_in(16'd0)
    );

    wire [28:0] avl_address;
    wire [7:0]  avl_burstcount, avl_byteenable;
    wire        avl_read, avl_write;
    wire [63:0] avl_writedata;
    reg  [63:0] avl_readdata = 0;
    reg         avl_readdatavalid = 0;
    wire        avl_waitrequest = 1'b0;

    a2065_ddr3_mailbox mailbox (
        .clk(clk_ddr), .rst_n(rst_n),
        .cmd_pending(cmd_pending), .cmd_rap(cmd_rap), .cmd_data(cmd_data),
        .cmd_clear(cmd_clear),
        .csr0_out(), .csr1_out(), .csr2_out(), .csr3_out(), .a2065_int2(),
        .bram_req_valid(1'b0), .bram_req_addr(14'd0), .bram_req_wdata(16'd0),
        .bram_req_rw(1'b0), .bram_req_be(2'b11),
        .bram_req_ack(), .bram_resp_valid(), .bram_resp_data(),
        .avl_address(avl_address), .avl_burstcount(avl_burstcount),
        .avl_read(avl_read), .avl_readdata(avl_readdata),
        .avl_readdatavalid(avl_readdatavalid),
        .avl_writedata(avl_writedata), .avl_byteenable(avl_byteenable),
        .avl_write(avl_write), .avl_waitrequest(avl_waitrequest)
    );

    always @(posedge clk_ddr) avl_readdatavalid <= avl_read;

    // Watch what the mailbox posts, so the bench can tell a ring entry from
    // the index publication that follows it.
    localparam RING = 29'h03FE0000 + 29'h1100;
    localparam WPTR = 29'h03FE0000 + 29'h1001;
    integer ring_writes = 0;
    reg [63:0] last_entry = 0;
    reg [31:0] last_wptr = 32'hFFFFFFFF;
    always @(posedge clk_ddr) begin
        if (avl_write && !avl_waitrequest) begin
            if (avl_address >= RING && avl_address < RING + 256) begin
                ring_writes <= ring_writes + 1;
                last_entry  <= avl_writedata;
            end
            else if (avl_address == WPTR) last_wptr <= avl_writedata[31:0];
        end
    end

    // A 68k write to RDP, with a bound on the DTACK stretch.
    task rdp_write(input [15:0] val, output done);
        integer guard;
        begin
            done = 0; guard = 0;
            @(negedge clk_sys);
            cpu_addr = 24'hEA4000; cpu_data_in = val; cpu_rw = 0;
            @(negedge clk_sys);
            cpu_as_n = 0; cpu_ds_n = 0;
            while (guard < 300) begin
                @(negedge clk_sys);
                if (!regs_nrdy) begin done = 1; guard = 300; end
                else guard = guard + 1;
            end
            cpu_as_n = 1; cpu_ds_n = 1; cpu_rw = 1;
            repeat (3) @(negedge clk_sys);
        end
    endtask

    reg done;
    integer i, before;

    initial begin
        $display("\\n=== tb_cmd_ring (no host present) ===");
        repeat (10) @(negedge clk_sys);
        rst_n = 1;
        repeat (20) @(negedge clk_sys);

        check(last_wptr == 32'd0, "index published at reset");

        before = ring_writes;
        rdp_write(16'h0004, done);
        check(done, "register write completes with no host to drain it");
        check(ring_writes == before + 1, "one ring entry posted");
        check(last_entry[0] == 1'b1 &&
              last_entry[23:8] == 16'h0004, "entry carries the written data");
        check(last_wptr == 32'd1, "write index advanced");

        // The LANCE init sequence is a burst of back-to-back writes; every one
        // must retire, which a single un-drained slot could not manage.
        done = 1;
        for (i = 0; i < 12 && done; i = i + 1)
            rdp_write(16'h0040 + i[15:0], done);
        check(done, "12 back-to-back register writes all complete");
        check(last_wptr == 32'd13, "index advanced once per write");

        $display("=== %0d passed, %0d failed ===\\n", pass, fail);
        if (fail) $fatal(1, "cmd ring tests failed");
        $finish;
    end

    initial begin
        #400000;
        $display("GLOBAL TIMEOUT — register write never retired");
        $fatal(1, "timeout");
    end

endmodule

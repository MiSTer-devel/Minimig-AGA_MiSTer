/*
 * a2065_ddr3_mailbox.v
 *
 * DDR3 mailbox adapter for A2065 (Phase 2 — doorbell architecture).
 *
 * Runs entirely in the core's DDR3 clock domain (DDRAM_CLK, ~114 MHz).
 * Handles three functions:
 *
 *   1. CMD doorbell: regfile raises cmd_pending → mailbox writes CMD to
 *      DDR3 for ARM daemon → pulses cmd_clear.  No DTACK stretch for
 *      reads/RAP writes — only back-pressure on overlapping RDP writes.
 *
 *   2. Boardram DDR3 window: 68k accesses boardram at card+0x8000 via
 *      DTACK-stretched DDR3 read/write.  Request arrives via async
 *      handshake from clk_sys; FSM performs direct DDR3 access.
 *
 *   3. CSR shadow + INT state poll: periodically reads CSR_SHADOW and
 *      INT_STATE from DDR3 (written by ARM daemon).  CSR values feed
 *      back to regfile for 68k zero-latency reads.  INT_STATE drives
 *      the a2065_int2 output.
 *
 * Priority: CMD doorbell > boardram window > CSR/INT poll.
 */

module a2065_ddr3_mailbox (
    input  wire         clk,
    input  wire         rst_n,

    input  wire         cmd_pending,
    input  wire  [6:0]  cmd_rap,
    input  wire  [15:0] cmd_data,
    output reg          cmd_clear,

    output reg  [15:0]  csr0_out,
    output reg  [15:0]  csr1_out,
    output reg  [15:0]  csr2_out,
    output reg  [15:0]  csr3_out,
    output reg          a2065_int2,

    input  wire         bram_req_valid,
    input  wire  [13:0] bram_req_addr,
    input  wire  [15:0] bram_req_wdata,
    input  wire         bram_req_rw,
    input  wire  [1:0]  bram_req_be,
    output reg          bram_req_ack,
    output reg          bram_resp_valid,
    output reg  [15:0]  bram_resp_data,

    output reg  [28:0]  avl_address,
    output reg  [7:0]   avl_burstcount,
    output reg          avl_read,
    input  wire [63:0]  avl_readdata,
    input  wire         avl_readdatavalid,
    output reg  [63:0]  avl_writedata,
    output reg  [7:0]   avl_byteenable,
    output reg          avl_write,
    input  wire         avl_waitrequest
);

    localparam DDR3_BASE = 29'h03FE0000;

    localparam AV_CMD          = 29'h1000;
    /* Register writes are posted into a ring rather than a single slot, and
     * the bus is released as soon as the entry reaches DDR3 — the host is
     * never waited on. Waiting for host software here would deadlock: Main is
     * single-threaded, and while it sits in its IDE handler waiting for the
     * Amiga, the Amiga would be sitting on a stretched DTACK waiting for Main.
     * 256 entries is far more than the 68k can post while Main is busy
     * elsewhere. */
    localparam AV_CMD_WPTR     = 29'h1001;
    localparam AV_CMD_RING     = 29'h1100;
    localparam CMD_RING_BITS   = 8;
    localparam AV_CSR          = 29'h1002;
    localparam AV_INT          = 29'h1003;

    localparam S_IDLE          = 4'd0;
    localparam S_CMD_WR_W      = 4'd1;
    localparam S_CMD_DONE      = 4'd2;

    localparam S_BR_CAPTURE    = 4'd3;
    localparam S_BR_READ_W     = 4'd4;
    localparam S_BR_READ_D     = 4'd5;
    localparam S_BR_WRITE_W    = 4'd6;
    localparam S_BR_DONE       = 4'd7;

    localparam S_CSR_RD_W      = 4'd8;
    localparam S_CSR_RD_D      = 4'd9;
    localparam S_INT_RD_W      = 4'd10;
    localparam S_INT_RD_D      = 4'd11;

    localparam S_BR_RMW_RD_W   = 4'd12;
    localparam S_BR_RMW_RD_D   = 4'd13;

    localparam S_CMD_WPTR_W    = 4'd14;
    localparam S_WPTR_INIT     = 4'd15;

    reg [3:0] state;
    reg [31:0] cmd_wr_idx;
    reg        wptr_published;

    reg  [7:0] poll_div;

    reg  [13:0] br_addr;
    reg  [15:0] br_wdata;
    reg         br_rw;
    reg  [1:0]  br_lane;
    reg  [1:0]  br_be;

    wire [28:0] br_ddr3_addr = DDR3_BASE + {17'b0, br_addr[13:2]};

    /* Boardram writes use read-modify-write: the f2sdram2 port has only
     * ever been exercised with full-word (be=0xFF) writes (audio, PAL,
     * old DDR3 mailbox).  Partial byteenable writes are unproven and the
     * single 16-bit lane would otherwise zero its 3 line-neighbours.  So
     * read the 64-bit line, merge the target lane, write the whole line
     * back with be=0xFF. */

    reg bram_req_valid_s, bram_req_valid_s1;
    reg [13:0] bram_req_addr_s;
    reg [15:0] bram_req_wdata_s;
    reg        bram_req_rw_s;
    reg [1:0]  bram_req_be_s;

    always @(posedge clk) begin
        bram_req_valid_s  <= bram_req_valid;
        bram_req_valid_s1 <= bram_req_valid_s;

        bram_req_addr_s   <= bram_req_addr;
        bram_req_wdata_s  <= bram_req_wdata;
        bram_req_rw_s     <= bram_req_rw;
        bram_req_be_s     <= bram_req_be;
    end

    wire bram_req_active = bram_req_valid_s1;

    reg cmd_pending_s, cmd_pending_s1;
    reg [6:0]  cmd_rap_s;
    reg [15:0] cmd_data_s;

    always @(posedge clk) begin
        cmd_pending_s  <= cmd_pending;
        cmd_pending_s1 <= cmd_pending_s;
        cmd_rap_s      <= cmd_rap;
        cmd_data_s     <= cmd_data;
    end

    wire cmd_active = cmd_pending_s1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= S_IDLE;
            avl_address     <= 0;
            avl_burstcount  <= 1;
            avl_read        <= 0;
            avl_write       <= 0;
            avl_writedata   <= 0;
            avl_byteenable  <= 8'hFF;
            poll_div        <= 0;
            cmd_clear       <= 0;
            csr0_out        <= 0;
            csr1_out        <= 0;
            csr2_out        <= 0;
            csr3_out        <= 0;
            a2065_int2      <= 0;
            bram_req_ack    <= 0;
            bram_resp_valid <= 0;
            bram_resp_data  <= 0;
            br_lane         <= 0;
            br_be           <= 2'b11;
            cmd_wr_idx      <= 32'd0;
            wptr_published  <= 1'b0;
        end else begin
            avl_read        <= 0;
            avl_write       <= 0;

            /* cmd_clear / bram_req_ack / bram_resp_valid answer a requester in
             * a slower clock domain (clk_sys), so they are held until that
             * requester withdraws its request rather than pulsed for a single
             * cycle. A one-cycle pulse here is ~9ns and the far side samples
             * every ~35ns, so it would simply be missed and both sides would
             * wait forever — the request lines are already levels for the same
             * reason. Holding them makes the handshake independent of the
             * ratio between the two clocks. */
            if (!cmd_active) cmd_clear <= 0;
            if (!bram_req_active) begin
                bram_req_ack    <= 0;
                bram_resp_valid <= 0;
            end

            poll_div <= poll_div + 1'b1;

            case (state)
            S_IDLE: begin
                if (!wptr_published) begin
                    // Publish the index once after reset so the host never
                    // reads a stale value left in DDR3 by a previous session.
                    avl_address    <= DDR3_BASE + AV_CMD_WPTR;
                    avl_writedata  <= 64'd0;
                    avl_byteenable <= 8'hFF;
                    avl_burstcount <= 1;
                    avl_write      <= 1;
                    state          <= S_WPTR_INIT;
                end else if (cmd_active && !cmd_clear) begin
                    avl_address    <= DDR3_BASE + AV_CMD_RING
                                      + {21'b0, cmd_wr_idx[CMD_RING_BITS-1:0]};
                    avl_writedata  <= {39'b0, cmd_data_s, cmd_rap_s, 1'b1};
                    avl_byteenable <= 8'hFF;
                    avl_burstcount <= 1;
                    avl_write      <= 1;
                    state          <= S_CMD_WR_W;
                end else if (bram_req_active && !bram_req_ack) begin
                    br_addr      <= bram_req_addr_s;
                    br_wdata     <= bram_req_wdata_s;
                    br_rw        <= bram_req_rw_s;
                    br_be        <= bram_req_be_s;
                    br_lane      <= bram_req_addr_s[1:0];
                    bram_req_ack <= 1'b1;
                    state        <= S_BR_CAPTURE;
                end else if (&poll_div[5:0]) begin
                    avl_address    <= DDR3_BASE + AV_CSR;
                    avl_burstcount <= 1;
                    avl_read       <= 1;
                    state          <= S_CSR_RD_W;
                end
            end

            S_CMD_WR_W: begin
                if (!avl_waitrequest) begin
                    // Entry is in DDR3; publish the advanced write index so the
                    // host can see it.
                    cmd_wr_idx     <= cmd_wr_idx + 1'b1;
                    avl_address    <= DDR3_BASE + AV_CMD_WPTR;
                    avl_writedata  <= {32'b0, cmd_wr_idx + 1'b1};
                    avl_byteenable <= 8'hFF;
                    avl_burstcount <= 1;
                    avl_write      <= 1;
                    state          <= S_CMD_WPTR_W;
                end else begin
                    avl_write <= 1;
                end
            end

            S_WPTR_INIT: begin
                if (!avl_waitrequest) begin
                    wptr_published <= 1'b1;
                    state          <= S_IDLE;
                end else begin
                    avl_write <= 1;
                end
            end

            S_CMD_WPTR_W: begin
                if (!avl_waitrequest) begin
                    // Index published — release the 68k now. The host reads
                    // the ring in its own time; nothing here waits on it.
                    cmd_clear <= 1'b1;
                    state     <= S_CMD_DONE;
                end else begin
                    avl_write <= 1;
                end
            end

            S_CMD_DONE: begin
                cmd_clear <= 1'b1;
                if (!cmd_pending_s1) begin
                    cmd_clear <= 1'b0;
                    state     <= S_IDLE;
                end
            end

            S_BR_CAPTURE: begin
                // Both read and write begin by reading the 64-bit line.
                avl_address    <= br_ddr3_addr;
                avl_burstcount <= 1;
                avl_read       <= 1;
                state          <= br_rw ? S_BR_RMW_RD_W : S_BR_READ_W;
            end

            S_BR_READ_W: begin
                if (!avl_waitrequest) begin
                    avl_read <= 0;
                    state    <= S_BR_READ_D;
                end else begin
                    avl_read <= 1;
                end
            end

            S_BR_READ_D: begin
                if (avl_readdatavalid) begin
                    case (br_lane)
                    2'd0: bram_resp_data <= avl_readdata[15:0];
                    2'd1: bram_resp_data <= avl_readdata[31:16];
                    2'd2: bram_resp_data <= avl_readdata[47:32];
                    2'd3: bram_resp_data <= avl_readdata[63:48];
                    endcase
                    bram_resp_valid <= 1'b1;
                    state           <= S_BR_DONE;
                end
            end

            S_BR_WRITE_W: begin
                if (!avl_waitrequest) begin
                    bram_resp_valid <= 1'b1;
                    state           <= S_BR_DONE;
                end else begin
                    avl_write <= 1;
                end
            end

            S_BR_DONE: begin
                state <= S_IDLE;
            end

            S_BR_RMW_RD_W: begin
                if (!avl_waitrequest) begin
                    avl_read <= 0;
                    state    <= S_BR_RMW_RD_D;
                end else begin
                    avl_read <= 1;
                end
            end

            S_BR_RMW_RD_D: begin
                if (avl_readdatavalid) begin
                    // Merge only the enabled bytes of the target lane (br_be[1]
                    // = high byte / UDS, br_be[0] = low byte / LDS); keep the
                    // read-back bytes elsewhere so byte writes don't clobber
                    // their pair or the 3 line-neighbours.
                    case (br_lane)
                    2'd0: avl_writedata <= {avl_readdata[63:16],
                            br_be[1] ? br_wdata[15:8] : avl_readdata[15:8],
                            br_be[0] ? br_wdata[7:0]  : avl_readdata[7:0]};
                    2'd1: avl_writedata <= {avl_readdata[63:32],
                            br_be[1] ? br_wdata[15:8] : avl_readdata[31:24],
                            br_be[0] ? br_wdata[7:0]  : avl_readdata[23:16],
                            avl_readdata[15:0]};
                    2'd2: avl_writedata <= {avl_readdata[63:48],
                            br_be[1] ? br_wdata[15:8] : avl_readdata[47:40],
                            br_be[0] ? br_wdata[7:0]  : avl_readdata[39:32],
                            avl_readdata[31:0]};
                    2'd3: avl_writedata <= {
                            br_be[1] ? br_wdata[15:8] : avl_readdata[63:56],
                            br_be[0] ? br_wdata[7:0]  : avl_readdata[55:48],
                            avl_readdata[47:0]};
                    endcase
                    avl_address    <= br_ddr3_addr;
                    avl_byteenable <= 8'hFF;
                    avl_burstcount <= 1;
                    avl_write      <= 1;
                    state          <= S_BR_WRITE_W;
                end
            end

            S_CSR_RD_W: begin
                if (!avl_waitrequest) begin
                    avl_read <= 0;
                    state    <= S_CSR_RD_D;
                end else begin
                    avl_read <= 1;
                end
            end

            S_CSR_RD_D: begin
                if (avl_readdatavalid) begin
                    csr0_out <= avl_readdata[15:0];
                    csr1_out <= avl_readdata[31:16];
                    csr2_out <= avl_readdata[47:32];
                    csr3_out <= avl_readdata[63:48];
                    avl_address    <= DDR3_BASE + AV_INT;
                    avl_burstcount <= 1;
                    avl_read       <= 1;
                    state          <= S_INT_RD_W;
                end
            end

            S_INT_RD_W: begin
                if (!avl_waitrequest) begin
                    avl_read <= 0;
                    state    <= S_INT_RD_D;
                end else begin
                    avl_read <= 1;
                end
            end

            S_INT_RD_D: begin
                if (avl_readdatavalid) begin
                    a2065_int2 <= avl_readdata[0];
                    state      <= S_IDLE;
                end
            end

            default: state <= S_IDLE;
            endcase
        end
    end

endmodule

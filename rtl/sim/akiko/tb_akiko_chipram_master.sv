// SPDX-License-Identifier: GPL-3.0-or-later

`timescale 1ns / 1ps

module tb_akiko_chipram_master;

initial begin
	#500000 $fatal(1, "tb_akiko_chipram_master: watchdog timeout");
end

logic clk = 0;
initial forever #5 clk = ~clk;

logic c_7m = 0;
logic [3:0] c_7m_div = 0;
always @(posedge clk) begin
	c_7m_div <= c_7m_div + 4'd1;
	if (c_7m_div == 4'd7) begin
		c_7m <= ~c_7m;
		c_7m_div <= 4'd0;
	end
end

logic reset = 1;

logic        akiko_dma_req   = 0;
logic        akiko_dma_we    = 0;
logic [23:0] akiko_dma_baddr = 0;
logic  [7:0] akiko_dma_wbyte = 0;
wire   [7:0] akiko_dma_rbyte;
wire         akiko_dma_ack;

logic [24:1] chip_in_addr = 0;
logic        chip_in_l    = 1;
logic        chip_in_u    = 1;
logic        chip_in_rw   = 1;
logic        chip_in_dma  = 1;
logic [15:0] chip_in_wr   = 0;

wire  [24:1] chip_out_addr;
wire         chip_out_l;
wire         chip_out_u;
wire         chip_out_rw;
wire         chip_out_dma;
wire  [15:0] chip_out_wr;
wire  [15:0] chip_in_rd;

chipdma_arb u_dut (
	.clk             (clk             ),
	.reset           (reset           ),
	.c_7m            (c_7m            ),

	.chip_in_addr    (chip_in_addr    ),
	.chip_in_l       (chip_in_l       ),
	.chip_in_u       (chip_in_u       ),
	.chip_in_rw      (chip_in_rw      ),
	.chip_in_dma     (chip_in_dma     ),
	.chip_in_wr      (chip_in_wr      ),

	.akiko_dma_req   (akiko_dma_req   ),
	.akiko_dma_we    (akiko_dma_we    ),
	.akiko_dma_baddr (akiko_dma_baddr ),
	.akiko_dma_wbyte (akiko_dma_wbyte ),
	.akiko_dma_rbyte (akiko_dma_rbyte ),
	.akiko_dma_ack   (akiko_dma_ack   ),

	.chip_out_addr   (chip_out_addr   ),
	.chip_out_l      (chip_out_l      ),
	.chip_out_u      (chip_out_u      ),
	.chip_out_rw     (chip_out_rw     ),
	.chip_out_dma    (chip_out_dma    ),
	.chip_out_wr     (chip_out_wr     ),
	.chip_in_rd      (chip_in_rd      )
);

localparam int LATENCY = 9;

logic [7:0] mem [65536];

logic [15:0] rd_pipe [10];
logic        rd_valid_pipe [10];
logic [15:0] chipRD_r;

assign chip_in_rd = chipRD_r;

initial begin
	int ii;
	for (ii = 0; ii < 65536; ii++) mem[ii] = 8'h00;
	for (ii = 0; ii < 10; ii++) begin
		rd_pipe[ii] = 16'h0000;
		rd_valid_pipe[ii] = 1'b0;
	end
	chipRD_r = 16'h0000;
end

wire [15:0] hi_idx = {chip_out_addr[15:1], 1'b0};
wire [15:0] lo_idx = {chip_out_addr[15:1], 1'b1};

always @(posedge clk) begin
	rd_pipe[9]       <= rd_pipe[8];
	rd_pipe[8]       <= rd_pipe[7];
	rd_pipe[7]       <= rd_pipe[6];
	rd_pipe[6]       <= rd_pipe[5];
	rd_pipe[5]       <= rd_pipe[4];
	rd_pipe[4]       <= rd_pipe[3];
	rd_pipe[3]       <= rd_pipe[2];
	rd_pipe[2]       <= rd_pipe[1];
	rd_pipe[1]       <= rd_pipe[0];
	rd_valid_pipe[9] <= rd_valid_pipe[8];
	rd_valid_pipe[8] <= rd_valid_pipe[7];
	rd_valid_pipe[7] <= rd_valid_pipe[6];
	rd_valid_pipe[6] <= rd_valid_pipe[5];
	rd_valid_pipe[5] <= rd_valid_pipe[4];
	rd_valid_pipe[4] <= rd_valid_pipe[3];
	rd_valid_pipe[3] <= rd_valid_pipe[2];
	rd_valid_pipe[2] <= rd_valid_pipe[1];
	rd_valid_pipe[1] <= rd_valid_pipe[0];
	rd_pipe[0]       <= 16'h0000;
	rd_valid_pipe[0] <= 1'b0;

	if (~chip_out_dma | ~chip_out_rw) begin
		if (chip_out_rw) begin
			rd_pipe[0][15:8] <= chip_out_u ? 8'hxx : mem[hi_idx];
			rd_pipe[0][7:0]  <= chip_out_l ? 8'hxx : mem[lo_idx];
			rd_valid_pipe[0] <= 1'b1;
		end else begin
			if (~chip_out_u) mem[hi_idx] <= chip_out_wr[15:8];
			if (~chip_out_l) mem[lo_idx] <= chip_out_wr[7:0];
		end
	end

	if (rd_valid_pipe[LATENCY]) chipRD_r <= rd_pipe[LATENCY];
end

int checks = 0;
int errs   = 0;

task automatic check8(string name, logic [7:0] expected, logic [7:0] actual);
	checks++;
	if (expected !== actual) begin
		$display("FAIL %s: expected 0x%02h got 0x%02h (t=%0t)", name, expected, actual, $time);
		errs++;
	end
endtask

task automatic check_byte_at(string name, int unsigned idx, logic [7:0] expected);
	checks++;
	if (mem[idx] !== expected) begin
		$display("FAIL %s: mem[0x%0h] expected 0x%02h got 0x%02h (t=%0t)",
		         name, idx, expected, mem[idx], $time);
		errs++;
	end
endtask

task automatic akiko_read_byte(input [23:0] baddr, input [7:0] expected, input string label);
	int timeout;
	@(posedge clk);
	akiko_dma_req   <= 1'b1;
	akiko_dma_we    <= 1'b0;
	akiko_dma_baddr <= baddr;
	akiko_dma_wbyte <= 8'h00;
	timeout = 200;
	while (!akiko_dma_ack && timeout > 0) begin
		@(posedge clk);
		timeout--;
	end
	if (timeout == 0) begin
		$display("FAIL %s: timeout waiting for ack (t=%0t)", label, $time);
		errs++;
	end else begin
		check8(label, expected, akiko_dma_rbyte);
	end
	akiko_dma_req <= 1'b0;
	@(posedge clk);
endtask

task automatic akiko_write_byte(input [23:0] baddr, input [7:0] value, input string label);
	int timeout;
	@(posedge clk);
	akiko_dma_req   <= 1'b1;
	akiko_dma_we    <= 1'b1;
	akiko_dma_baddr <= baddr;
	akiko_dma_wbyte <= value;
	timeout = 200;
	while (!akiko_dma_ack && timeout > 0) begin
		@(posedge clk);
		timeout--;
	end
	if (timeout == 0) begin
		$display("FAIL %s: write timeout (t=%0t)", label, $time);
		errs++;
	end
	akiko_dma_req <= 1'b0;
	@(posedge clk);
endtask

task automatic minimig_dma_slot(input [24:1] waddr, input do_write,
                                input [15:0] wr_data, input [1:0] be_lu);
	@(posedge clk);
	chip_in_addr <= waddr;
	chip_in_u    <= ~be_lu[1];
	chip_in_l    <= ~be_lu[0];
	chip_in_rw   <= ~do_write;
	chip_in_dma  <= do_write ? 1'b1 : 1'b0;
	chip_in_wr   <= wr_data;
	@(posedge clk);
	chip_in_dma  <= 1'b1;
	chip_in_rw   <= 1'b1;
	chip_in_l    <= 1'b1;
	chip_in_u    <= 1'b1;
endtask

task automatic preload(input int unsigned idx, input [7:0] value);
	mem[idx] = value;
endtask

initial begin
	$display("tb_akiko_chipram_master: start (LATENCY=%0d)", LATENCY);

	reset = 1;
	repeat (4) @(posedge clk);
	reset = 0;
	repeat (2) @(posedge clk);

	preload(16'h0100, 8'hA5);
	akiko_read_byte(24'h000100, 8'hA5, "test1: read upper byte");

	preload(16'h0101, 8'h5A);
	akiko_read_byte(24'h000101, 8'h5A, "test2: read lower byte");

	akiko_write_byte(24'h000200, 8'hDE, "test3a: write upper byte");
	akiko_write_byte(24'h000201, 8'hAD, "test3b: write lower byte");
	check_byte_at("test3a: mem[0x200]", 16'h0200, 8'hDE);
	check_byte_at("test3b: mem[0x201]", 16'h0201, 8'hAD);

	for (int i = 0; i < 8; i++) preload(16'h0300 + i, 8'h10 + i[7:0]);
	for (int i = 0; i < 8; i++) begin
		akiko_read_byte(24'h000300 + i, 8'h10 + i[7:0], $sformatf("test4: read[%0d]", i));
	end

	preload(16'h0400, 8'h11);
	preload(16'h0401, 8'h22);
	begin : t5
		int low_cycles;
		int timeout;
		akiko_dma_req   <= 1'b1;
		akiko_dma_we    <= 1'b0;
		akiko_dma_baddr <= 24'h000400;
		timeout = 200;
		@(posedge clk);
		while (!akiko_dma_ack && timeout > 0) begin @(posedge clk); timeout--; end
		check8("test5: first byte", 8'h11, akiko_dma_rbyte);
		akiko_dma_baddr <= 24'h000401;
		low_cycles = 0;
		timeout = 200;
		@(posedge clk);
		while (!akiko_dma_ack && timeout > 0) begin
			low_cycles++;
			@(posedge clk);
			timeout--;
		end
		if (low_cycles < 1) begin
			$display("FAIL test5: ack stayed high without gap (low_cycles=%0d t=%0t)",
			         low_cycles, $time);
			errs++;
		end else begin
			checks++;
			$display("PASS test5: ack gap = %0d cycles", low_cycles);
		end
		check8("test5: second byte", 8'h22, akiko_dma_rbyte);
		akiko_dma_req <= 1'b0;
		@(posedge clk);
	end

	preload(16'h0500, 8'hCC);
	akiko_dma_req   <= 1'b1;
	akiko_dma_we    <= 1'b0;
	akiko_dma_baddr <= 24'h000500;
	begin : t6
		automatic int slot;
		automatic int t6_timeout;
		for (slot = 0; slot < 4; slot++) begin
			minimig_dma_slot(24'h001000 + slot, 0,
			                 16'h0000, 2'b11);
		end
		t6_timeout = 400;
		while (!akiko_dma_ack && t6_timeout > 0) begin
			@(posedge clk); t6_timeout--;
		end
		if (t6_timeout == 0) begin
			$display("FAIL test6: akiko ack never came");
			errs++;
		end else begin
			check8("test6: akiko got byte after minimig traffic",
			       8'hCC, akiko_dma_rbyte);
		end
		akiko_dma_req <= 1'b0;
	end

	preload(16'h0600, 8'h77);
	preload(16'h0601, 8'h88);
	akiko_dma_req   <= 1'b1;
	akiko_dma_we    <= 1'b0;
	akiko_dma_baddr <= 24'h000600;
	begin : t7
		automatic int t7_mismatches = 0;
		@(posedge clk);
		chip_in_addr <= 25'h0001234;
		chip_in_u    <= 1'b0;
		chip_in_l    <= 1'b0;
		chip_in_rw   <= 1'b1;
		chip_in_dma  <= 1'b0;
		chip_in_wr   <= 16'h0000;
		repeat (4) begin
			@(posedge clk);
			if (chip_out_dma !== chip_in_dma) t7_mismatches++;
			if (chip_out_addr !== chip_in_addr) t7_mismatches++;
			if (chip_out_rw !== chip_in_rw) t7_mismatches++;
		end
		chip_in_dma <= 1'b1;
		chip_in_rw  <= 1'b1;
		chip_in_l   <= 1'b1;
		chip_in_u   <= 1'b1;
		if (t7_mismatches > 0) begin
			$display("FAIL test7: %0d forwarding mismatches", t7_mismatches);
			errs++;
		end else begin
			checks++;
			$display("PASS test7: minimig forwarding fidelity (4 cycles)");
		end
		begin
			automatic int t7_timeout = 400;
			while (!akiko_dma_ack && t7_timeout > 0) begin
				@(posedge clk); t7_timeout--;
			end
			if (t7_timeout == 0) begin
				$display("FAIL test7: akiko ack timeout after minimig traffic");
				errs++;
			end
		end
		akiko_dma_req <= 1'b0;
	end

	preload(16'h0700, 8'h99);
	akiko_dma_req   <= 1'b1;
	akiko_dma_we    <= 1'b0;
	akiko_dma_baddr <= 24'h000700;
	begin : t8
		automatic int t8_drove_minimig_addr = 0;
		@(negedge c_7m);
		@(posedge c_7m);
		chip_in_addr <= 25'h0009999;
		chip_in_u    <= 1'b0;
		chip_in_l    <= 1'b0;
		chip_in_rw   <= 1'b0;
		chip_in_dma  <= 1'b1;
		chip_in_wr   <= 16'hAAAA;
		repeat (3) begin
			@(posedge clk);
			if (chip_out_addr === 25'h0009999) t8_drove_minimig_addr++;
		end
		chip_in_rw <= 1'b1;
		chip_in_dma <= 1'b1;
		if (t8_drove_minimig_addr == 0) begin
			$display("FAIL test8: arbiter preempted minimig (akiko address won race)");
			errs++;
		end else begin
			checks++;
			$display("PASS test8: minimig won race (%0d cycles confirmed)",
			         t8_drove_minimig_addr);
		end
		begin
			automatic int t8_timeout = 400;
			while (!akiko_dma_ack && t8_timeout > 0) begin
				@(posedge clk); t8_timeout--;
			end
		end
		akiko_dma_req <= 1'b0;
	end

	repeat (10) @(posedge clk);
	$display("tb_akiko_chipram_master: %0d checks, %0d errs", checks, errs);
	$finish;
end

endmodule

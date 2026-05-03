// SPDX-License-Identifier: GPL-3.0-or-later

`timescale 1ns / 1ps

module tb_akiko_nvram;

initial begin
	#500000 $fatal(1, "tb_akiko_nvram: watchdog timeout");
end

logic clk = 0;
initial forever #5 clk = ~clk;

logic reset = 1;
initial begin
	@(posedge clk); @(posedge clk);
	reset = 0;
end

logic scl_master = 1;
logic sda_master = 1;
wire  sda_drive;
wire  bus_scl = scl_master;
wire  bus_sda = sda_master & ~sda_drive;

akiko_nvram #(.INIT_FILE("../../init/nvram_init.hex")) dut (
	.clk       (clk),
	.reset     (reset),
	.scl_in    (bus_scl),
	.sda_in    (bus_sda),
	.sda_drive (sda_drive)
);

int errs = 0;
int tests = 0;

task automatic i2c_quarter;
	repeat (8) @(posedge clk);
endtask

task automatic i2c_start;
	scl_master = 1;
	sda_master = 1;
	i2c_quarter();
	sda_master = 0;
	i2c_quarter();
	scl_master = 0;
	i2c_quarter();
endtask

task automatic i2c_stop;
	scl_master = 0;
	sda_master = 0;
	i2c_quarter();
	scl_master = 1;
	i2c_quarter();
	sda_master = 1;
	i2c_quarter();
endtask

task automatic i2c_master_bit (input bit b);
	scl_master = 0;
	sda_master = b;
	i2c_quarter();
	scl_master = 1;
	i2c_quarter();
	scl_master = 0;
	i2c_quarter();
endtask

task automatic i2c_master_recv_bit (output bit b);
	scl_master = 0;
	sda_master = 1;
	i2c_quarter();
	scl_master = 1;
	i2c_quarter();
	b = bus_sda;
	scl_master = 0;
	i2c_quarter();
endtask

task automatic i2c_write (input [7:0] v, output bit ack);
	bit b;
	for (int i = 7; i >= 0; i--) begin
		i2c_master_bit(v[i]);
	end
	i2c_master_recv_bit(b);
	ack = ~b;
endtask

task automatic i2c_read (output [7:0] v, input bit ack);
	bit b;
	v = 0;
	for (int i = 7; i >= 0; i--) begin
		i2c_master_recv_bit(b);
		v[i] = b;
	end
	i2c_master_bit(ack ? 1'b0 : 1'b1);
endtask

task automatic check (input string name, input [7:0] got, input [7:0] want);
	tests++;
	if (got !== want) begin
		$display("FAIL [%s]: got 0x%02h, want 0x%02h", name, got, want);
		errs++;
	end else begin
		$display("PASS [%s]: 0x%02h", name, got);
	end
endtask

task automatic check_bit (input string name, input bit got, input bit want);
	tests++;
	if (got !== want) begin
		$display("FAIL [%s]: got %0d, want %0d", name, got, want);
		errs++;
	end else begin
		$display("PASS [%s]: %0d", name, got);
	end
endtask

initial begin
	bit ack;
	bit [7:0] data;

	@(negedge reset);
	repeat (8) @(posedge clk);

	$display("=== Test 1: single byte round trip @ 0x042 ===");
	i2c_start();
	i2c_write(8'hA0, ack);
	check_bit("dev_w_ack",   ack, 1);
	i2c_write(8'h42, ack);
	check_bit("waddr_ack",   ack, 1);
	i2c_write(8'hAB, ack);
	check_bit("data_w_ack",  ack, 1);
	i2c_stop();

	repeat (4) @(posedge clk);

	i2c_start();
	i2c_write(8'hA0, ack);
	check_bit("dev_w_ack2",  ack, 1);
	i2c_write(8'h42, ack);
	check_bit("waddr_ack2",  ack, 1);
	i2c_start();
	i2c_write(8'hA1, ack);
	check_bit("dev_r_ack",   ack, 1);
	i2c_read(data, 0);
	check ("readback",       data, 8'hAB);
	i2c_stop();

	repeat (4) @(posedge clk);

	$display("=== Test 2: 4-byte sequential @ 0x100 ===");
	i2c_start();
	i2c_write(8'hA2, ack);
	check_bit("seq_dev_ack", ack, 1);
	i2c_write(8'h00, ack);
	check_bit("seq_waddr_ack", ack, 1);
	i2c_write(8'h11, ack);
	i2c_write(8'h22, ack);
	i2c_write(8'h33, ack);
	i2c_write(8'h44, ack);
	i2c_stop();

	repeat (4) @(posedge clk);

	i2c_start();
	i2c_write(8'hA2, ack);
	i2c_write(8'h00, ack);
	i2c_start();
	i2c_write(8'hA3, ack);
	i2c_read(data, 1); check("seq[0]", data, 8'h11);
	i2c_read(data, 1); check("seq[1]", data, 8'h22);
	i2c_read(data, 1); check("seq[2]", data, 8'h33);
	i2c_read(data, 0); check("seq[3]", data, 8'h44);
	i2c_stop();

	repeat (4) @(posedge clk);

	$display("=== Test 3: NACK on bad devaddr 0xB0 ===");
	i2c_start();
	i2c_write(8'hB0, ack);
	check_bit("bad_dev_nack", ack, 0);
	i2c_stop();

	repeat (4) @(posedge clk);

	$display("=== Test 4: high page 0x300 via devaddr 0xA6 ===");
	i2c_start();
	i2c_write(8'hA6, ack);
	i2c_write(8'h00, ack);
	i2c_write(8'h5A, ack);
	i2c_stop();

	repeat (4) @(posedge clk);

	i2c_start();
	i2c_write(8'hA6, ack);
	i2c_write(8'h00, ack);
	i2c_start();
	i2c_write(8'hA7, ack);
	i2c_read(data, 0); check("hi_page",  data, 8'h5A);
	i2c_stop();

	repeat (8) @(posedge clk);

	begin
		bit [7:0] expected[16];
		expected = '{8'h00, 8'h56, 8'hA9, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00,
		             8'h02, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00, 8'h00};
		$display("=== Test 5: pre-initialized FlashFile magic @ 0x000 ===");
		i2c_start();
		i2c_write(8'hA0, ack);
		i2c_write(8'h00, ack);
		i2c_start();
		i2c_write(8'hA1, ack);
		for (int i = 0; i < 16; i++) begin
			i2c_read(data, i < 15 ? 1 : 0);
			check($sformatf("init[%0d]", i), data, expected[i]);
		end
		i2c_stop();
	end

	repeat (8) @(posedge clk);

	$display("=================================================");
	$display("tb_akiko_nvram: %0d tests, %0d errors", tests, errs);
	$display("=================================================");
	$finish;
end

endmodule

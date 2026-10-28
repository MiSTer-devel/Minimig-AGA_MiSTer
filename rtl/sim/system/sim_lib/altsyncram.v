// Simulation model of the altsyncram configuration Minimig's
// denise_colortable_ram_mf uses: DUAL_PORT, one clock (clock0) with its
// enable (clocken0), write byte enables on port A, port B's address
// registered on clock0, its output unregistered, the old data on a mixed-port
// read during a write.  Only for Verilator; Quartus uses its own altsyncram.

module altsyncram
#(
	parameter address_aclr_b = "NONE",
	parameter address_reg_b = "CLOCK0",
	parameter byte_size = 8,
	parameter clock_enable_input_a = "NORMAL",
	parameter clock_enable_input_b = "NORMAL",
	parameter clock_enable_output_b = "BYPASS",
	parameter intended_device_family = "Cyclone V",
	parameter lpm_type = "altsyncram",
	parameter numwords_a = 256,
	parameter numwords_b = 256,
	parameter operation_mode = "DUAL_PORT",
	parameter outdata_aclr_b = "NONE",
	parameter outdata_reg_b = "UNREGISTERED",
	parameter power_up_uninitialized = "FALSE",
	parameter read_during_write_mode_mixed_ports = "OLD_DATA",
	parameter widthad_a = 8,
	parameter widthad_b = 8,
	parameter width_a = 32,
	parameter width_b = 32,
	parameter width_byteena_a = 4
)
(
	input  [widthad_a-1:0]       address_a,
	input  [width_byteena_a-1:0] byteena_a,
	input                        clock0,
	input  [width_a-1:0]         data_a,
	input                        wren_a,
	input  [widthad_b-1:0]       address_b,
	input                        clocken0,
	output [width_b-1:0]         q_b,
	input                        aclr0,
	input                        aclr1,
	input                        addressstall_a,
	input                        addressstall_b,
	input                        byteena_b,
	input                        clock1,
	input                        clocken1,
	input                        clocken2,
	input                        clocken3,
	input  [width_b-1:0]         data_b,
	output [2:0]                 eccstatus,
	output [width_a-1:0]         q_a,
	input                        rden_a,
	input                        rden_b,
	input                        wren_b
);

reg [width_a-1:0] ram [0:numwords_a-1];
reg [width_b-1:0] rd_q;

initial for (int i = 0; i < numwords_a; i++) ram[i] = '0;

// the read happens at the edge that registers address_b: the data then in
// the array, before this edge's write (OLD_DATA)
always @(posedge clock0) if (clocken0) begin
	rd_q <= ram[address_b];
	if (wren_a)
		for (int b = 0; b < width_byteena_a; b++)
			if (byteena_a[b]) ram[address_a][b*byte_size +: byte_size] <= data_a[b*byte_size +: byte_size];
end

assign q_b = rd_q;
assign q_a = '0;
assign eccstatus = 3'd0;

endmodule

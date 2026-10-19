
module cpu_cycles
(
	input             clk,
	input             reset,

	input             ena,

	input             opc_start,
	input      [15:0] opc,
	input             opc_cond,
	input      [15:0] opc_snd,
	input             opc_dbx,
	input             cpu_ena,

	input             bus_ack,
	input       [1:0] bus_state,
	input      [31:0] bus_addr,
	input             bus_long,
	input       [1:0] cacr,
	input             cacr_clr,

	output reg        hold
);

wire go = opc_start & cpu_ena & ena;

(* ram_init_file = "rtl/tg68k/m68k_cyc_idx.mif" *) reg [5:0] cyc_rom[16384];
(* ram_init_file = "rtl/tg68k/m68k_ea_idx.mif"  *) reg [4:0] ea_rom[2048];

reg [15:0] opc_p, opc_l, opc_q;
reg [15:0] snd_l, snd_q;
reg [19:0] op_q;
reg  [2:0] v;

wire [13:0] cyc_a = (opc_p[5:3] == 3'b111) ? {opc_p[15:6], 1'b1, opc_p[2:0]}
                                           : {opc_p[15:6], 1'b0, opc_p[5:3]};

wire movem = (opc_l[15:12] == 4'h4) & opc_l[11] & ~opc_l[9] & ~opc_l[8]
           & opc_l[7] & |opc_l[5:3];

reg [4:0] rn;
integer i;
always @* begin
	rn = 5'd0;
	for (i = 0; i < 16; i = i + 1) rn = rn + {4'd0, snd_l[i]};
end

wire  [7:0] mv_cc   = opc_l[10] ? (8'd8 + {1'b0, rn, 2'b00}) : (8'd4 + {2'b00, rn, 1'b0});
wire [19:0] movem_e = {1'b1, 3'd4, 2'd0, 5'd2, mv_cc, 1'b0};

wire misc = (opc_l[15:3] == 13'h09CE);

reg  [5:0] cyc_i;
reg  [4:0] ea_i;
reg [19:0] cyc_e;
reg [19:0] misc_e;
reg [15:0] ea_e;
`include "tg68k/m68k_cyc_pal.vh"
`include "tg68k/m68k_ea_pal.vh"
`include "tg68k/m68k_misc_030.vh"

wire [19:0] op_e = misc ? misc_e : movem ? movem_e : cyc_e;

always @(posedge clk) begin
	if (~reset | ~ena) v <= 0;
	else v <= {v[1:0], go};
	if (go) opc_p <= opc;
	opc_l <= opc_p;
	snd_l <= opc_snd;
	cyc_i <= cyc_rom[cyc_a];
	opc_q <= opc_l;
	snd_q <= snd_l;
	op_q  <= op_e;
	ea_i  <= ea_rom[{op_e[18:16], movem ? 2'b01 : opc_l[7:6], opc_l[5:0]}];
end

wire [2:0] eacl  = op_q[18:16];
wire [1:0] op_t  = op_q[15:14];
wire [4:0] op_h  = op_q[13:9];
wire       divsl = (opc_q[15:6] == 10'h131) & snd_q[11];
wire [7:0] op_cc = op_q[8:1] + (divsl ? 8'd12 : 8'd0);

wire       ea_v  = ea_e[15] & |eacl;

wire ff_pre = (opc_q[15:8] == 8'h08)
           || (opc_q[15:12] == 4'hE && opc_q[11] && &opc_q[7:6]);
wire ff = ea_v & eacl[0] & snd_q[8] & ~ff_pre
        & ((opc_q[5:3] == 3'b110) | (opc_q[5:0] == 6'b111011));

wire       ff_mi = |snd_q[1:0];
wire       ff_od = ff_mi & (snd_q[1:0] != 2'b01);
wire [1:0] ff_bd = snd_q[5:4];
wire [6:0] ff_cc = (ff_mi ? (ff_bd == 2'b10 ? 7'd12 : ff_bd == 2'b11 ? 7'd16 : 7'd10)
                          : (ff_bd == 2'b10 ? 7'd8  : ff_bd == 2'b11 ? 7'd12 : 7'd6))
                 + (ff_od ? 7'd2 : 7'd0);
wire       ff_ph = ~ff_mi & (ff_bd != 2'b10) & (ff_bd != 2'b11) & (eacl != 3'd1);

wire [6:0] ea_cc = ff ? ff_cc : ea_v ? ea_e[14:8] : 7'd0;
wire [4:0] ea_h  = ff ? (ff_ph ? 5'd6 : 5'd4) : ea_v ? ea_e[7:3] : 5'd0;
wire [1:0] ea_t  = ff ? 2'd0 : ea_v ? ea_e[2:1] : 2'd0;
wire       ea_ph = ff ? ff_ph : (ea_v & ea_e[0]);
wire       model = op_q[19] & (~|eacl | ea_e[15]);

wire bcc_b = (opc_q[15:12] == 4'h6) && (opc_q[11:8] > 4'h1)
          && (opc_q[7:0] != 8'h00) && (opc_q[7:0] != 8'hFF);
wire bcc_o = (opc[15:12] == 4'h6) && (opc[11:8] > 4'h1)
          && (opc[7:0] != 8'h00) && (opc[7:0] != 8'hFF);

reg  [1:0] prev_t;
wire [4:0] ov1  = (op_h < {3'b0, ea_t}) ? op_h : {3'b0, ea_t};
wire [8:0] cc   = {1'b0, op_cc} + {2'b0, ea_cc} - {4'b0, ov1};
wire [5:0] head = ea_v ? ({1'b0, ea_h} + (ea_ph ? {1'b0, op_h} : 6'd0)) : {1'b0, op_h};
wire [5:0] ov2  = (head < {4'b0, prev_t}) ? head : {4'b0, prev_t};
wire [8:0] net  = cc - {3'b0, ov2};
wire [8:0] cost = model ? (bcc_b ? net - 9'd2 : net) : 9'd2;

reg  [1:0] b_v;
reg  [3:0] b_st;
reg [63:0] b_a;
reg  [1:0] b_lw;
reg  [3:0] b_cr;
reg  [1:0] b_cc;
reg        e_v;
reg  [1:0] e_st;
reg [31:0] e_a;
reg        e_lw;
always @(posedge clk) begin
	b_v  <= {b_v[0], bus_ack & ena};
	b_st <= {b_st[1:0], bus_state};
	b_a  <= {b_a[31:0], bus_addr};
	b_lw <= {b_lw[0], bus_long};
	b_cr <= {b_cr[1:0], cacr};
	b_cc <= {b_cc[0], cacr_clr};
	e_v  <= b_v[1];
	e_st <= b_st[3:2];
	e_a  <= b_a[63:32];
	e_lw <= b_lw[1];
end
wire  [1:0] cr_d  = b_cr[3:2];

wire        r_io  = (e_a[23:19] == 5'b11101);
wire        r_chp = (e_a[23:21] == 3'd0) | (e_a[23:21] == 3'd5) | (e_a[23:21] == 3'd6) | r_io;
wire  [5:0] c_mem = r_chp ? 6'd9 : 6'd3;

wire [23:0] tg = e_a[31:8];
wire  [5:0] sl = e_a[7:2];

reg  [23:0] ctag[64];
reg  [63:0] cvl;

wire        c_hit = cvl[sl] & (ctag[sl] == tg);

reg  [29:0] last_f;
wire        f_ev  = e_v & (e_st == 2'd0) & (e_a[31:2] != last_f);
wire        d_ev  = e_v & e_st[1] & ~e_lw;
wire        r_cr  = (e_a[23:21] == 3'd0) | ((e_a[23:21] == 3'd6) & ~&e_a[20:19]);
wire        r_nc  = r_chp & ~r_cr;
wire        ie    = cr_d[0] & ~cr_d[1] & ~r_nc;
wire        i_hit = cr_d[0] & c_hit;

wire  [5:0] f_c = (~f_ev | i_hit) ? 6'd0 : c_mem;
wire  [5:0] d_c = d_ev ? c_mem - 6'd2 : 6'd0;

reg         clr_d;
always @(posedge clk) begin
	clr_d <= b_cc[1];
	if (~reset | (b_cc[1] & ~clr_d)) begin
		cvl <= 0;
		last_f <= 30'h3FFFFFFF;
	end
	else begin
		if (f_ev) last_f <= e_a[31:2];
		if (f_ev & ~i_hit & ie) begin
			ctag[sl] <= tg;
			cvl[sl] <= 1'b1;
		end
	end
end

reg         bl;
reg   [5:0] ovc;
reg         dbx_d;
reg  [11:0] acc;
reg  [12:0] debt;

reg   [2:0] add_b;
wire [14:0] acc_n = {3'b000, acc} + 15'd2048;
wire        wr_e  = d_ev & e_st[0];
wire        dr_e  = d_ev & ~e_st[0];
wire        fm_e  = f_ev & ~i_hit;
wire  [6:0] cr_n  = (wr_e ? {1'b0, d_c} : 7'd0) + (fm_e ? {1'b0, f_c} : 7'd0);
wire [11:0] ab_x  = {cost, 3'd0} - {3'd0, cost};
wire  [5:0] ab    = v[2] ? ((ab_x[11:3] > {3'd0, ovc}) ? ovc : ab_x[8:3]) : 6'd0;
wire  [8:0] add_t = v[2] ? cost - {3'd0, ab} : 9'd0;
wire  [2:0] add_d = (opc_dbx & ~dbx_d & ena) ? 3'd4 : 3'd0;
wire signed [13:0] dn = {debt[12], debt} - {11'd0, acc_n[14:12]} + {5'd0, add_t} + {8'd0, f_c} + {8'd0, d_c}
                      + {11'd0, add_b} + {11'd0, add_d};

always @(posedge clk) begin
	dbx_d <= opc_dbx;
	add_b <= (go & bl & opc_cond) ? 3'd2 : 3'd0;
	if (~reset | ~ena) begin
		acc    <= 0;
		ovc    <= 0;
		debt   <= 0;
		prev_t <= 0;
		bl     <= 0;
		hold   <= 0;
	end
	else begin
		acc  <= acc_n[11:0];
		ovc  <= dr_e ? 6'd0 : |cr_n ? (cr_n[6] ? 6'd63 : cr_n[5:0]) : ovc - ab;
		debt <= (dn < -14'sd255) ? -13'sd255 : dn[12:0];
		hold <= (dn > 14'sd0);
		if (go) bl <= bcc_o;
		if (v[2]) prev_t <= model ? op_t : 2'd0;
	end
end

endmodule

module amiga_clk_altera
(
	input	  areset,
	input	  inclk0,
	output	  c0,
	output	  c1,
	output	  c2,
	output	  locked
);

pll pll
(
	.refclk(inclk0),
	.rst(areset),
	.outclk_0(c1),
	.outclk_1(c0),
	.outclk_2(c2),
	.locked(locked)
);


endmodule

/* ctrl_clk.v */
/* 2012, rok.krajnc@gmail.com */


module ctrl_clk (
  input  wire inclk0,
  output wire c0,
  output wire c1,
  output wire c2,
  output wire locked
);


`ifdef MINIMIG_ALTERA
ctrl_clk_altera ctrl_clk_i (
  .inclk0   (inclk0 ),
  .c0       (c0     ),
  .c1       (c1     ),
  .c2       (c2     ),
  .locked   (locked )
);
`endif


`ifdef MINIMIG_XILINX
ctrl_clk_xilinx ctrl_clk_i (
  .inclk0   (inclk0 ),
  .c0       (c0     ),
  .c1       (c1     ),
  .c2       (c2     ),
  .locked   (locked )
);
`endif


endmodule


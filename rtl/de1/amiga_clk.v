/* amiga_clk.v */
/* 2012, rok.krajnc@gmail.com */


module amiga_clk (
  input  wire areset,
  input  wire inclk0,
  output wire c0,
  output wire c1,
  output wire c2,
  output wire locked
)


`ifdef MINIMIG_ALTERA
amiga_clk_altera amiga_clk_i (
  .areset   (areset ),
  .inclk0   (inclk0 ),
  .c0       (c0     ),
  .c1       (c1     ),
  .c2       (c2     ),
  .locked   (locked )
);
`endif

`ifdef MINIMIG_XILINX
amiga_clk_xilinx amiga_clk_i (
  .areset   (areset ),
  .inclk0   (inclk0 ),
  .c0       (c0     ),
  .c1       (c1     ),
  .c2       (c2     ),
  .locked   (locked )
);

endmodule


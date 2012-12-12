/* ctrl_rst.v */


`ifdef SOC_SIM
`define RST_CNT 16'h00ff      // reset counter length used in simulations
`else
`define RST_CNT 16'hffff      // reset counter length
`endif


module ctrl_rst (
  // system
  input  wire           clk,
  // PLL lock input
  input  wire           pll_lock,
  // external reset input
  input  wire           rst_ext,
  // register reset input
  input  wire           rst_reg,
  // reset signal output
  output reg            rst
);



////////////////////////////////////////
// internal signals                   //
////////////////////////////////////////

// reset counter
reg  [16-1:0] rst_cnt;
// input signal registers
reg           pll_lock_n_t=0, rst_ext_t=0, rst_reg_t=0;
reg           pll_lock_n_r=0, rst_ext_r=0, rst_reg_r=0;
// reset wire
wire          rst_wire;



////////////////////////////////////////
// register initial settings          //
////////////////////////////////////////
initial begin
  pll_lock_n_t  = 1'b1;
  rst_ext_t     = 1'b1;
  rst_reg_t     = 1'b1;
  pll_lock_n_r  = 1'b1;
  rst_ext_r     = 1'b1;
  rst_reg_r     = 1'b1;
  rst_cnt       = `RST_CNT;
  rst           = 1'b1;
end



////////////////////////////////////////
// logic                              //
////////////////////////////////////////

// register & synchronize inputs
always @ (posedge clk)
begin
  pll_lock_n_t  <= #1 !pll_lock;
  rst_ext_t     <= #1 rst_ext;
  rst_reg_t     <= #1 rst_reg;

  pll_lock_n_r  <= #1 pll_lock_n_t;
  rst_ext_r     <= #1 rst_ext_t;
  rst_reg_r     <= #1 rst_reg_t;
end


// reset counter
always @ (posedge clk)
begin
  if (rst_reg_r || rst_ext_r || pll_lock_n_r) rst_cnt <= #1 `RST_CNT;
  else if (|rst_cnt)                          rst_cnt <= #1 rst_cnt - 1'd1;
end


// reset wire
assign rst_wire = (|rst_cnt);


// output reset registers
always @ (posedge clk)
begin
  rst   <= #1 rst_wire;
end


endmodule


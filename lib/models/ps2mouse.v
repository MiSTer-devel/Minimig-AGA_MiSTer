// ps2mouse.v
// ps2 mouse model
// 2014, rok.krajnc@gmail.com


module ps2mouse (
  input wire clk,
  input wire rst,
  inout wire mclk,
  inout wire mdat 
);


//// constants ////
localparam [8-1:0]
  PS2_SELFTEST  = 8'haa,
  PS2_ID00      = 8'h00,
  PS2_ID03      = 8'h03,
  PS2_ACK       = 8'hfa;

//// bus tri-state buffers ////
reg mclk_en=1'b0, mdat_en=1'b0;
reg mclk_o = 1'b1, mdat_o = 1'b1;
wire mclk_i, mdat_i;
assign mclk = mclk_en ? mclk_o : 1'bz;
assign mdat = mdat_en ? mdat_o : 1'bz;
assign mclk_i = mclk;
assign mdat_i = mdat;


//// bus states ////
wire bus_idle, bus_inhibit, bus_rts, bus_busy;
assign bus_idle     = ((mclk_i !== 1'b0) && (mdat_i !== 1'b0));
assign bus_inhibit  = ((mclk_i === 1'b0) && (mdat_i !== 1'b0));
assign bus_rts      = ((mclk !== 1'b0) && (mdat === 1'b0));
assign bus_busy     = ((mclk === 1'b0) && (mdat === 1'b0));


//// mouse states ////
reg [8-1:0] dat = 0;
reg [8-1:0] cmd = 0;
reg [8-1:0] sample_rate = 8'd100;
reg [2:0] intellimouse_state = 0;
reg intellimouse = 0;
reg data_reporting = 0;
reg status = 0;


//// tasks ////

// wait_ms
task wait_ms;
input integer t;
begin
  repeat (t) #1000;
end
endtask

// ps2_tick
task ps2_tick;
begin
  mclk_o = 1;
  wait_ms(30);
  mclk_o = 0;
  wait_ms(30);
end
endtask

// ps2_rx
task ps2_rx;
output reg [8-1:0] dat;
output reg status;
reg parity;
integer i;
begin
  status = 0;
  wait(bus_rts);
  wait_ms(30);
  mclk_en = 1;
  wait_ms(30);
  for (i=0; i<8; i=i+1) begin
    mclk_o = 0;
    wait_ms(30);
    mclk_o = 1;
    wait_ms(30);
    dat = {mdat_i, dat[7:1]};
  end
  mclk_o = 0;
  wait_ms(30);
  mclk_o = 1;
  wait_ms(30);
  parity = mdat_i;
  if (parity != (!(^dat))) $display("Parity mismatch!");
  mclk_o = 0;
  wait_ms(30);
  mclk_o = 1;
  wait_ms(30);
  mdat_en = 1;
  mdat_o = 0;
  mclk_o = 0;
  wait_ms(30);
  mclk_o = 1;
  wait_ms(30);
  mclk_en = 0;
  mdat_en = 0;
  mclk_o = 1;
  mdat_o = 1;
  ps2_tx(PS2_ACK, status);
end
endtask

// ps2_tx
task ps2_tx;
input reg [8-1:0] dat;
output reg status;
reg parity;
integer i;
begin
  parity = !(^dat);
  status = 0;
  wait_ms(100);
  if (!bus_idle) begin
    status = 1;
  end else begin
    mclk_en = 1;
    mdat_en = 1;
    mdat_o = 0;
    ps2_tick;
    for (i=0; i<8; i=i+1) begin
      mdat_o = dat[0];
      ps2_tick;
      dat = {1'b0, dat[7:1]};
    end
    mdat_o = parity;
    ps2_tick;
    mdat_o = 1;
    ps2_tick;
    mclk_en = 0;
    mdat_en = 0;
    mclk_o = 1;
    mdat_o = 1;
  end
end
endtask

// init
task init;
reg status;
begin
  ps2_tx(PS2_SELFTEST, status);
  if (!status) ps2_tx(PS2_ID00, status);
end
endtask

// configure
task configure;
reg configured;
begin
  configured = 0;
  while (!configured) begin
    ps2_rx(cmd, status);
    case (cmd)
      8'hff : begin
        $display("Host reset (0xff)");
        ps2_tx(PS2_SELFTEST, status);
        ps2_tx(PS2_ID00, status);
      end
      8'hf3 : begin
        $display("Host set resample rate (0xf3)");
        ps2_rx(dat, status);
        $display("Host resample rate = 0x%02x", dat);
        if      ((dat == 8'hc8) && (intellimouse_state == 0)) intellimouse_state = 1;
        else if ((dat == 8'h64) && (intellimouse_state == 1)) intellimouse_state = 2;
        else if ((dat == 8'h50) && (intellimouse_state == 2)) intellimouse_state = 3;
        if (intellimouse_state == 3) intellimouse = 1;
      end
      8'hf2 : begin
        $display("Host read device type (0xf2)");
        if (intellimouse)
          ps2_tx(PS2_ID03, status);
        else
          ps2_tx(PS2_ID00, status);
      end
      8'hf4 : begin
        $display("Host enable data reporting (0xf4)");
        data_reporting = 1;
        configured = 1;
      end
    endcase
  end
end
endtask


// report
task report;
begin
  forever begin
    #100000;
    ps2_tx(8'h0f, status);
    ps2_tx(8'h03, status);
    ps2_tx(8'h02, status);
    ps2_tx(8'h01, status);
  end
end
endtask


//// mouse model ////

initial begin
  init;
  configure;
  #200000;
  report;
end


endmodule


/********************************************/
/* vga_monitor.v                            */
/* Generates VGA sync and pixel data        */
/* Compatible with Altera DE1 board         */
/*                                          */
/* 2011, rok.krajnc@gmail.com               */
/********************************************/


module vga_monitor #(
  parameter VGA   = 1,              // SVGA or VGA mode
  parameter IRW   = 4,              // input red   width
  parameter IGW   = 4,              // input green width
  parameter IBW   = 4,              // input blue  width
  parameter ODW   = 8,              // output width
  parameter DLY   = 3,              // delay of output active
  parameter COR   = "RGB",          // color order (RGB or BGR)
  parameter FNW   = 32,             // filename string width
  parameter FEX   = "hex",          // filename extension
  parameter FILE  = ""              // filename (without extension!)
)(
  // system
  input  wire           clk,        // clock
  // status
  input  wire           oa,         // vga output active
  input  wire [  7-1:0] f_cnt,      // frame counter (resets for every second)
  input  wire           f_start,    // frame start
  // vga data
  input  wire [IRW-1:0] r_in,     
  input  wire [IGW-1:0] g_in,
  input  wire [IBW-1:0] b_in
);


////////////////////////////////////////
// internal variables
////////////////////////////////////////

/* filename */
reg [8*FNW-1:0] filename;
/* file pointer */
integer         fp = 0;
/* enabled */
reg             en;
/* vga oa reg */
reg [DLY-1:0]   oa_r;
wire [DLY :0]   oa_w;
wire            oa_out;


////////////////////////////////////////
// initial values
////////////////////////////////////////
initial begin
  en = 0;
end


////////////////////////////////////////
// tasks
////////////////////////////////////////

/* start monitor */
task start;
begin
  en = 1;
end
endtask

/* stop monitor */
task stop;
begin
  en = 0;
end
endtask


////////////////////////////////////////
// logging
////////////////////////////////////////

/* open and close file */
always @ (posedge clk)
begin
  if (en) begin    
    if (f_start) begin
      if (fp) $fclose(fp);
      $sformat(filename, "%s_%1d.%s", FILE, f_cnt, FEX);
      fp = $fopen(filename, "w");
    end
  end else begin
    if (fp) $fclose(fp); 
  end
end

/* register vga output active */
always @ (posedge clk) oa_r <= #1 {oa_r[DLY-2:0], oa};
assign oa_w = {oa_r, oa};
assign oa_out = oa_w[DLY];

/* log data to file */
always @ (posedge clk)
begin
  if (en) begin
    if (oa_out) begin
      if (COR == "RGB") $fwrite(fp, "%02x%02x%02x\n", {r_in, {(8-IRW){1'h0}}}, {g_in, {(8-IGW){1'h0}}}, {b_in, {(8-IBW){1'h0}}});
      else              $fwrite(fp, "%02x%02x%02x\n", {b_in, {(8-IBW){1'h0}}}, {g_in, {(8-IGW){1'h0}}}, {r_in, {(8-IRW){1'h0}}});
    end
  end
end


endmodule
 

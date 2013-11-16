////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// Copyright 2006, 2007 Dennis van Weeren                                     //
//                                                                            //
// This file is part of Minimig                                               //
//                                                                            //
// Minimig is free software; you can redistribute it and/or modify            //
// it under the terms of the GNU General Public License as published by       //
// the Free Software Foundation; either version 3 of the License, or          //
// (at your option) any later version.                                        //
//                                                                            //
// Minimig is distributed in the hope that it will be useful,                 //
// but WITHOUT ANY WARRANTY; without even the implied warranty of             //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              //
// GNU General Public License for more details.                               //
//                                                                            //
// You should have received a copy of the GNU General Public License          //
// along with this program.  If not, see <http://www.gnu.org/licenses/>.      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// This is Amber                                                              //
// Amber is a scandoubler to allow connection to a VGA monitor.               //
// In addition, it can overlay an OSD (on-screen-display) menu.               //
// Amber also has a pass-through mode in which                                //
// the video output can be connected to an RGB SCART input.                   //
// The meaning of _hsync_out and _vsync_out is then:                          //
// _vsync_out is fixed high (for use as RGB enable on SCART input).           //
// _hsync_out is composite sync output.                                       //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
//                                                                            //
// Changelog                                                                  //
// DW:                                                                        //
// 2006-01-10  - first serious version                                        //
// 2006-01-11  - done lot's of work, Amber is now finished                    //
// 2006-12-29  - added support for OSD overlay                                //
//                                                                            //
// JB:                                                                        //
// 2008-02-26  - synchronous 28 MHz version                                   //
// 2008-02-28  - horizontal and vertical interpolation                        //
// 2008-02-02  - hfilter/vfilter inputs added, unused inputs removed          //
// 2008-12-12  - useless scanline effect implemented                          //
// 2008-12-27  - clean-up                                                     //
// 2009-05-24  - clean-up & renaming                                          //
// 2009-08-31  - scanlines synthesis option                                   //
// 2010-05-30  - htotal changed                                               //
//                                                                            //
// RK:                                                                        //
// 2013-03-03  - cleanup                                                      //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


module Amber
(
  input  wire           clk,            // 28MHz clock
  // config
  input  wire           dblscan,        // enable VGA output (enable scandoubler)
  input  wire [  2-1:0] lr_filter,      // interpolation filter settings for low resolution
  input  wire [  2-1:0] hr_filter,      // interpolation filter settings for high resolution
  input  wire [  2-1:0] scanline,       // scanline effect enable
  // control
  input  wire [  9-1:1] htotal,         // video line length
  input  wire           hires,          // display is in hires mode (from bplcon0)
  // osd
  input  wire           osd_blank,      // OSD overlay enable (blank normal video)
  input  wire           osd_pixel,      // OSD pixel(video) data
  // input
  input  wire [  4-1:0] red_in,         // red componenent video in
  input  wire [  4-1:0] green_in,       // green component video in
  input  wire [  4-1:0] blue_in,        // blue component video in
  input  wire           _hsync_in,      // horizontal synchronisation in
  input  wire           _vsync_in,      // vertical synchronisation in
  input  wire           _csync_in,      // composite synchronization in
  // output
  output reg  [  4-1:0] red_out,        // red componenent video out
  output reg  [  4-1:0] green_out,      // green component video out
  output reg  [  4-1:0] blue_out,       // blue component video out
  output reg            _hsync_out,     // horizontal synchronisation out
  output reg            _vsync_out      // vertical synchronisation out
);


//// params ////
localparam [  4-1:0] OSD_R = 4'b1110;
localparam [  4-1:0] OSD_G = 4'b1110;
localparam [  4-1:0] OSD_B = 4'b1110;


//// control ////
reg            _hsync_in_del;           // delayed horizontal synchronisation input
reg            hss;                     // horizontal sync start

// horizontal sync start  (falling edge detection)
always @ (posedge clk) begin
  _hsync_in_del <= #1 _hsync_in;
  hss <= #1 ~_hsync_in & _hsync_in_del;
end


//// horizontal interpolation ////
reg            hi_en;                   // horizontal interpolation enable
reg  [  4-1:0] r_in_d;                  // pixel data delayed by 70ns for horizontal interpolation
reg  [  4-1:0] g_in_d;                  // pixel data delayed by 70ns for horizontal interpolation
reg  [  4-1:0] b_in_d;                  // pixel data delayed by 70ns for horizontal interpolation
wire [  5-1:0] hi_r;                    // horizontal interpolation output
wire [  5-1:0] hi_g;                    // horizontal interpolation output
wire [  5-1:0] hi_b;                    // horizontal interpolation output
/*temp */reg  [ 11-1:0] sd_lbuf_wr;              // line buffer write pointer\

// horizontal interpolation enable
always @ (posedge clk) begin
`ifdef MINIMIG_VIDEO_FILTER
  if (hss) hi_en <= #1 hires ? hr_filter[0] : lr_filter[0];
`else
  hi_en <= #1 1'b0;
`endif
end

// pixel data delayed by one hires pixel for horizontal interpolation
always @ (posedge clk) begin
  if (sd_lbuf_wr[0])  begin // sampled at 14MHz (hires clock rate)
    r_in_d <= red_in;
    g_in_d <= green_in;
    b_in_d <= blue_in;
  end
end

// interpolate & mux
assign hi_r = hi_en ? ({1'b0, red_in}   + {1'b0, r_in_d}) : {red_in[3:0]  , 1'b0};
assign hi_g = hi_en ? ({1'b0, green_in} + {1'b0, g_in_d}) : {green_in[3:0], 1'b0};
assign hi_b = hi_en ? ({1'b0, blue_in}  + {1'b0, b_in_d}) : {blue_in[3:0] , 1'b0};


//// scandoubler ////
reg  [ 18-1:0] sd_lbuf [0:1024-1];      // line buffer for scan doubling (there are 908/910 hires pixels in every line)
reg  [ 18-1:0] sd_lbuf_o;               // line buffer output register
reg  [ 18-1:0] sd_lbuf_o_d;             // compensantion for one clock delay of the second line buffer
//reg  [ 11-1:0] sd_lbuf_wr;              // line buffer write pointer
reg  [ 11-1:0] sd_lbuf_rd;              // line buffer read pointer

// scandoubler line buffer write pointer
always @ (posedge clk) begin
  if (hss || !dblscan)
    sd_lbuf_wr <= #1 11'd0;
  else
    sd_lbuf_wr <= #1 sd_lbuf_wr + 11'd1;
end

// scandoubler line buffer read pointer
always @ (posedge clk) begin
  if (hss || !dblscan || (sd_lbuf_rd == {htotal[8:1],2'b11})) // reset at horizontal sync start and end of scandoubled line
    sd_lbuf_rd <= #1 11'd0;
  else
    sd_lbuf_rd <= #1 sd_lbuf_rd + 11'd1;
end

// scandoubler line buffer write/read
always @ (posedge clk) begin
  if (dblscan) begin
    // write
    sd_lbuf[sd_lbuf_wr[10:1]] <= #1 {_hsync_in, osd_blank, osd_pixel, hi_r, hi_g, hi_b};
    // read
    sd_lbuf_o <= #1 sd_lbuf[sd_lbuf_rd[9:0]];
    // delayed data
    sd_lbuf_o_d <= #1 sd_lbuf_o;
  end
end


//// vertical interpolation ////
reg            vi_en;                   // vertical interpolation enable
reg  [ 18-1:0] vi_lbuf [0:1024-1];      // vertical interpolation line buffer
reg  [ 18-1:0] vi_lbuf_o;               // vertical interpolation line buffer output register
wire [  6-1:0] vi_r_tmp;                // vertical interpolation temp data
wire [  6-1:0] vi_g_tmp;                // vertical interpolation temp data
wire [  6-1:0] vi_b_tmp;                // vertical interpolation temp data
wire [  4-1:0] vi_r;                    // vertical interpolation outputs
wire [  4-1:0] vi_g;                    // vertical interpolation outputs
wire [  4-1:0] vi_b;                    // vertical interpolation outputs

//vertical interpolation enable
always @ (posedge clk) begin
`ifdef MINIMIG_VIDEO_FILTER
  if (hss) vi_en <= #1 hires ? hr_filter[1] : lr_filter[1];
`else
  vi_en <= #1 1'b0;
`endif
end

// vertical interpolation line buffer write/read
always @ (posedge clk) begin
  // write
  vi_lbuf[sd_lbuf_rd[9:0]] <= #1 sd_lbuf_o;
  // read
  vi_lbuf_o <= #1 vi_lbuf[sd_lbuf_rd[9:0]];
end

// interpolate & mux
assign vi_r_tmp = vi_en ? ({1'b0, sd_lbuf_o_d[14:10]} + {1'b0, vi_lbuf_o[14:10]}) : {sd_lbuf_o_d[14:10], 1'b0};
assign vi_g_tmp = vi_en ? ({1'b0, sd_lbuf_o_d[ 9: 5]} + {1'b0, vi_lbuf_o[ 9: 5]}) : {sd_lbuf_o_d[ 9: 5], 1'b0};
assign vi_b_tmp = vi_en ? ({1'b0, sd_lbuf_o_d[ 4: 0]} + {1'b0, vi_lbuf_o[ 4: 0]}) : {sd_lbuf_o_d[ 4: 0], 1'b0};

// cut unneeded bits
assign vi_r = vi_r_tmp[6-1:2];
assign vi_g = vi_g_tmp[6-1:2];
assign vi_b = vi_b_tmp[6-1:2];


//// scanlines ////
reg            sl_en;                   // scanline enable
reg  [  4-1:0] sl_r;                    // scanline data output
reg  [  4-1:0] sl_g;                    // scanline data output
reg  [  4-1:0] sl_b;                    // scanline data output

// scanline enable
always @ (posedge clk) begin
  if (hss) // reset at horizontal sync start
    sl_en <= #1 1'b0;
  else if (sd_lbuf_rd == {htotal[8:1],2'b11}) // set at end of scandoubled line
    sl_en <= #1 1'b1;
end

// scanlines
always @ (posedge clk) begin
  sl_r <= #1 ((sl_en && scanline[1]) ? 4'h0 : ((sl_en && scanline[0]) ? {1'b0, vi_r[3:1]} : vi_r));
  sl_g <= #1 ((sl_en && scanline[1]) ? 4'h0 : ((sl_en && scanline[0]) ? {1'b0, vi_g[3:1]} : vi_g));
  sl_b <= #1 ((sl_en && scanline[1]) ? 4'h0 : ((sl_en && scanline[0]) ? {1'b0, vi_b[3:1]} : vi_b));
end

//// bypass mux ////
wire           bm_hsync;
wire           bm_vsync;
wire [  4-1:0] bm_r;
wire [  4-1:0] bm_g;
wire [  4-1:0] bm_b;
wire           bm_osd_blank;
wire           bm_osd_pixel;

assign bm_hsync     = dblscan ? sd_lbuf_o_d[17] : _csync_in;
assign bm_vsync     = dblscan ? _vsync_in : 1'b1;
assign bm_r         = dblscan ? sl_r : red_in;
assign bm_g         = dblscan ? sl_g : green_in;
assign bm_b         = dblscan ? sl_b : blue_in;
assign bm_osd_blank = dblscan ? sd_lbuf_o_d[16] : osd_blank;
assign bm_osd_pixel = dblscan ? sd_lbuf_o_d[15] : osd_pixel;


//// osd ////
wire [  4-1:0] osd_r;
wire [  4-1:0] osd_g;
wire [  4-1:0] osd_b;

assign osd_r = (bm_osd_blank ? (bm_osd_pixel ? OSD_R : {2'b00, bm_r[3:2]}) : bm_r);
assign osd_g = (bm_osd_blank ? (bm_osd_pixel ? OSD_G : {2'b00, bm_g[3:2]}) : bm_g);
assign osd_b = (bm_osd_blank ? (bm_osd_pixel ? OSD_B : {2'b10, bm_b[3:2]}) : bm_b);


//// output registers ////

always @ (posedge clk) begin
  _hsync_out <= #1 bm_hsync;
  _vsync_out <= #1 bm_vsync;
  red_out    <= #1 osd_r;
  green_out  <= #1 osd_g;
  blue_out   <= #1 osd_b;
end


endmodule


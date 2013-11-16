/********************************************/
/* minimig_cpu_tb.v                         */
/* A basig minimig + CPU testbench with     */
/* normal memory                            */
/*                                          */
/* 2013, rok.krajnc@gmail.com               */
/********************************************/

//`default_nettype none
`timescale 1ns/1ps


module minimig_cpu_tb();

////////////////////////////////////////
// defines                            //
////////////////////////////////////////




////////////////////////////////////////
// internal signals                   //
////////////////////////////////////////




////////////////////////////////////////
// bench                              //
////////////////////////////////////////

//// clocks & async reset ////
reg            rst;
reg            clk_114_r;
reg            clk_28_r;
reg            pll_locked_r;
wire           clk_114;
wire           clk_28;
wire           clk_7;
wire           clk_7_en;
wire           c1;
wire           c3;
wire           cck;
wire [ 10-1:0] eclk;
wire           locked;

initial begin
  rst             = 1'b1;
  #50;
  rst             = 1'b0;
end

initial begin
  pll_locked_r  = 1'b0;
  wait (!rst);
  #50;
  pll_locked_r  = 1'b1;
end
initial begin
  clk_114_r     = 1'b1;
  wait (!rst);
  forever #4.357  clk_114_r   = ~clk_114_r;
end
initial begin
  clk_28_r      = 1'b1;
  wait (!rst);
  forever #17.428 clk_28_r    = ~clk_28_r;
end
assign clk_114    = clk_114_r;
assign clk_28     = clk_28_r;
assign locked = pll_locked_r;

// 7MHz
reg [2-1:0] clk7_cnt;
reg         clk7_en_reg;
always @ (posedge clk_28, negedge locked) begin
  if (!locked) begin
    clk7_cnt <= 2'b10;
    clk7_en_reg <= #1 1'b1;
  end else begin
    clk7_cnt <= clk7_cnt + 2'b01;
    clk7_en_reg <= #1 ~|clk7_cnt;
  end
end

assign clk_7 = clk7_cnt[1];
assign clk7_en = clk7_en_reg;

// amiga clocks & clock enables
//            __    __    __    __    __
// clk_28  __/  \__/  \__/  \__/  \__/  
//            ___________             __
// clk_7   __/           \___________/  
//            ___________             __
// c1      __/           \___________/   <- clk28m domain
//                  ___________
// c3      ________/           \________ <- clk28m domain
//

// clk_28 clock domain signal synchronous with clk signal delayed by 90 degrees
reg c3_r;
always @(posedge clk_28) begin
  c3_r <= clk_7;
end
assign c3 = c3_r;

// clk28m clock domain signal synchronous with clk signal
reg c1_r;
always @(posedge clk_28) begin
  c1_r <= ~c3_r;
end
assign c1 = c1_r;

// counter used to generate e clock enable
reg [3:0] e_cnt;
always @(posedge clk_7) begin
  if (e_cnt[3] && e_cnt[0])
    e_cnt[3:0] <= 4'd0;
  else
    e_cnt[3:0] <= e_cnt[3:0] + 4'd1;
end

// CCK clock output
assign cck = ~e_cnt[0];

// 0.709379 MHz clock enable output (clk domain pulse)
assign eclk[0] = ~e_cnt[3] & ~e_cnt[2] & ~e_cnt[1] & ~e_cnt[0]; // e_cnt == 0
assign eclk[1] = ~e_cnt[3] & ~e_cnt[2] & ~e_cnt[1] &  e_cnt[0]; // e_cnt == 1
assign eclk[2] = ~e_cnt[3] & ~e_cnt[2] &  e_cnt[1] & ~e_cnt[0]; // e_cnt == 2
assign eclk[3] = ~e_cnt[3] & ~e_cnt[2] &  e_cnt[1] &  e_cnt[0]; // e_cnt == 3
assign eclk[4] = ~e_cnt[3] &  e_cnt[2] & ~e_cnt[1] & ~e_cnt[0]; // e_cnt == 4
assign eclk[5] = ~e_cnt[3] &  e_cnt[2] & ~e_cnt[1] &  e_cnt[0]; // e_cnt == 5
assign eclk[6] = ~e_cnt[3] &  e_cnt[2] &  e_cnt[1] & ~e_cnt[0]; // e_cnt == 6
assign eclk[7] = ~e_cnt[3] &  e_cnt[2] &  e_cnt[1] &  e_cnt[0]; // e_cnt == 7
assign eclk[8] =  e_cnt[3] & ~e_cnt[2] & ~e_cnt[1] & ~e_cnt[0]; // e_cnt == 8
assign eclk[9] =  e_cnt[3] & ~e_cnt[2] & ~e_cnt[1] &  e_cnt[0]; // e_cnt == 9

initial begin
  ERR = 1'b0;
end


//// set all inputs at initial time ////
initial begin

end


//// bench ////
initial begin
  $display("BENCH : %t : soc test starting ...", $time);

  // wait for reset
  #5;
  wait(!RST);
  repeat (10) @ (posedge CLOCK_50);
  #1;


  $display("BENCH : done.");
  $finish;
end



////////////////////////////////////////
// minimig modules                    //
////////////////////////////////////////
//// TG68K main CPU ////
TG68K tg68k (
  .clk          (clk_114          ),
  .reset        (tg68_rst         ),
  .clkena_in    (1'b1             ),
  .IPL          (tg68_IPL         ),
  .dtack        (tg68_dtack       ),
  .vpa          (1'b1             ),
  .ein          (1'b1             ),
  .addr         (tg68_adr         ),
  .data_read    (tg68_dat_in      ),
  .data_write   (tg68_dat_out     ),
  .as           (tg68_as          ),
  .uds          (tg68_uds         ),
  .lds          (tg68_lds         ),
  .rw           (tg68_rw          ),
  .e            (                 ),
  .vma          (                 ),
  .wrd          (                 ),
  .ena7RDreg    (tg68_ena7RD      ),
  .ena7WRreg    (tg68_ena7WR      ),
  .enaWRreg     (tg68_enaWR       ),
  .fromram      (tg68_cout        ),
  .ramready     (tg68_cpuena      ),
  .cpu          (cpu_config       ),
  .memcfg       (memcfg           ),
  .ramaddr      (tg68_cad         ),
  .cpustate     (tg68_cpustate    ),
  .nResetOut    (                 ),
  .skipFetch    (                 ),
  .cpuDMA       (tg68_cdma        ),
  .ramlds       (tg68_clds        ),
  .ramuds       (tg68_cuds        )
);


//// minimig top ////
Minimig1 minimig (
  //m68k pins
  .cpu_address  (tg68_adr[23:1]   ), // M68K address bus
  .cpu_data     (tg68_dat_in      ), // M68K data bus
  .cpudata_in   (tg68_dat_out     ), // M68K data in
  ._cpu_ipl     (tg68_IPL         ), // M68K interrupt request
  ._cpu_as      (tg68_as          ), // M68K address strobe
  ._cpu_uds     (tg68_uds         ), // M68K upper data strobe
  ._cpu_lds     (tg68_lds         ), // M68K lower data strobe
  .cpu_r_w      (tg68_rw          ), // M68K read / write
  ._cpu_dtack   (tg68_dtack       ), // M68K data acknowledge
  ._cpu_reset   (tg68_rst         ), // M68K reset
  .cpu_clk      (clk_7            ), // M68K clock
  //sram pins
  .ram_data     (ram_data         ), // SRAM data bus
  .ramdata_in   (ramdata_in       ), // SRAM data bus in
  .ram_address  (ram_address[21:1]), // SRAM address bus
  ._ram_ce      (                 ), // SRAM chip enable
  ._ram_bhe     (_ram_bhe         ), // SRAM upper byte select
  ._ram_ble     (_ram_ble         ), // SRAM lower byte select
  ._ram_we      (_ram_we          ), // SRAM write enable
  ._ram_oe      (_ram_oe          ), // SRAM output enable
  //system  pins
  .clk28m       (clk_28           ), // output clock c1 ( 28.687500MHz)
  .clk          (clk_7            ), // output clock 7  (  7.171875MHz)
  .clk7_en      (clk7_en          ), // 7MHz clock enable
  .c1           (c1               ), // clk28m clock domain signal synchronous with clk signal
  .c3           (c3               ), // clk28m clock domain signal synchronous with clk signal delayed by 90 degrees
  .cck          (cck              ), // colour clock output (3.54 MHz)
  .eclk         (eclk             ), // 0.709379 MHz clock enable output (clk domain pulse)
  //rs232 pins
  .rxd          (minimig_rxd      ), // RS232 receive
  .txd          (minimig_txd      ), // RS232 send
  .cts          (1'b0             ), // RS232 clear to send
  .rts          (                 ), // RS232 request to send
  //I/O
  ._joy1        (Joya             ), // joystick 1 [fire2,fire,up,down,left,right] (default mouse port)
  ._joy2        (Joyb             ), // joystick 2 [fire2,fire,up,down,left,right] (default joystick port)
  .mouse_btn1   (key_3            ), // mouse button 1
  .mouse_btn2   (key_2            ), // mouse button 2
  .joy_emu_en   (joy_emu_en       ), // enable keyboard joystick emulation
  ._15khz       (_15khz           ), // scandoubler disable
  .pwrled       (                 ), // power led
  .msdat        (PS2_MDAT         ), // PS2 mouse data
  .msclk        (PS2_MCLK         ), // PS2 mouse clk
  .kbddat       (PS2_DAT          ), // PS2 keyboard data
  .kbdclk       (PS2_CLK          ), // PS2 keyboard clk
  //host controller interface (SPI)
  ._scs         (SPI_CS_N[3:1]    ), // SPI chip select
  .direct_sdi   (SD_DAT           ), // SD Card direct in
  .sdi          (SD_CMD           ), // SPI data input
  .sdo          (sdo              ), // SPI data output
  .sck          (SD_CLK           ), // SPI clock
  //video
  ._hsync       (VGA_HS           ), // horizontal sync
  ._vsync       (VGA_VS           ), // vertical sync
  .red          (VGA_R            ), // red
  .green        (VGA_G            ), // green
  .blue         (VGA_B            ), // blue
  //audio
  .left         (audio_left       ), // audio bitstream left
  .right        (audio_right      ), // audio bitstream right
  .ldata        (ldata            ), // left DAC data
  .rdata        (rdata            ), // right DAC data
  //user i/o
  .gpio         (                 ), // spare GPIO
  .cpu_config   (cpu_config       ), // CPU config
  .memcfg       (memcfg           ), // memory config
  .drv_snd      (                 ), // drive sound
  .init_b       (                 ), // vertical sync for MCU (sync OSD update)
  // fifo / track display
  .trackdisp    (track            ), // floppy track number
  .secdisp      (                 ), // sector
  .floppy_fwr   (floppy_fwr       ), // floppy fifo writing
  .floppy_frd   (floppy_frd       ), // floppy fifo reading
  .hd_fwr       (hd_fwr           ), // hd fifo writing
  .hd_frd       (hd_frd           )  // hd fifo  ading
);




////////////////////////////////////////
// input / output models              //
////////////////////////////////////////

//// buttons ////
generic_input #(
  .IW   (4),                    // input width
  .PD   (10),                   // push delay
  .DS   (1'b1),                 // default state
  .DBG  (1)                     // debug output
) buttons (
  .o            (BTN)
);


//// switches ////
generic_input #(
  .IW   (10),                   // input width
  .PD   (10),                   // push delay
  .DS   (1'b1),                 // default state
  .DBG  (1)                     // debug output
) switches (
  .o            (SW)
);


//// LEDs ////


//// GPIOs ////


//// SRAM model ////
IS61LV6416L #(
  .memdepth (262144),
  .addbits  (18)
) sram (
  .A          (SRAM_ADDR),
  .IO         (SRAM_DQ),
  .CE_        (SRAM_CE_N),
  .OE_        (SRAM_OE_N),
  .WE_        (SRAM_WE_N),
  .LB_        (SRAM_LB_N),
  .UB_        (SRAM_UB_N)
);


//// SDRAM model ////
mt48lc16m16a2 #(
  .tAC  (5.4),
  .tHZ  (5.4),
  .tOH  (2.5),
  .tMRD (2.0),    // 2 Clk Cycles
  .tRAS (40.0),
  .tRC  (58.0),
  .tRCD (18.0),
  .tRFC (60.0),
  .tRP  (18.0),
  .tRRD (12.0),
  .tWRa (7.0),     // A2 Version - Auto precharge mode (1 Clk + 7 ns)
  .tWRm (14.0)    // A2 Version - Manual precharge mode (14 ns)
) sdram (
  .Dq         (DRAM_DQ),
  .Addr       (DRAM_ADDR),
  .Ba         ({DRAM_BA_1, DRAM_BA_0}),
  .Clk        (DRAM_CLK),
  .Cke        (DRAM_CKE),
  .Cs_n       (DRAM_CS_N),
  .Ras_n      (DRAM_RAS_N),
  .Cas_n      (DRAM_CAS_N),
  .We_n       (DRAM_WE_N),
  .Dqm        ({DRAM_UDQM, DRAM_LDQM})
);


//// SDCARD model ////
sd_card #(
  .FNAME  ("../../../../sd32MBNP.img")
) sdcard (
  .sck          (SD_CLK     ),
  .ss           (SD_DAT3    ),
  .mosi         (SD_CMD     ),
  .miso         (SD_DAT     )
);


/* flash model */


endmodule


// File sdram.vhd translated with vhd2vl v2.4 VHDL to Verilog RTL translator
// vhd2vl settings:
//  * Verilog Module Declaration Style: 1995

// vhd2vl is Free (libre) Software:
//   Copyright (C) 2001 Vincenzo Liguori - Ocean Logic Pty Ltd
//     http://www.ocean-logic.com
//   Modifications Copyright (C) 2006 Mark Gonzales - PMC Sierra Inc
//   Modifications (C) 2010 Shankar Giri
//   Modifications Copyright (C) 2002, 2005, 2008-2010 Larry Doolittle - LBNL
//     http://doolittle.icarus.com/~larry/vhd2vl/
//
//   vhd2vl comes with ABSOLUTELY NO WARRANTY.  Always check the resulting
//   Verilog for correctness, ideally with a formal verification tool.
//
//   You are welcome to redistribute vhd2vl under certain conditions.
//   See the license (GPLv2) file included with the source for details.

// The result of translation follows.  Its copyright status should be
// considered unchanged from the original VHDL.

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
//                                                                          --
// Copyright (c) 2009 Tobias Gubener                                        -- 
// Subdesign fAMpIGA by TobiFlex                                            --
//                                                                          --
// This source file is free software: you can redistribute it and/or modify --
// it under the terms of the GNU General Public License as published        --
// by the Free Software Foundation, either version 3 of the License, or     --
// (at your option) any later version.                                      --
//                                                                          --
// This source file is distributed in the hope that it will be useful,      --
// but WITHOUT ANY WARRANTY; without even the implied warranty of           --
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            --
// GNU General Public License for more details.                             --
//                                                                          --
// You should have received a copy of the GNU General Public License        --
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    --
//                                                                          --
//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
// no timescale needed

module sdram(
sdata,
sdaddr,
sd_we,
sd_ras,
sd_cas,
sd_cs,
dqm,
ba,
sysclk,
reset,
zdatawr,
zAddr,
zstate,
datawr,
rAddr,
rwr,
dwrL,
dwrU,
ZwrL,
ZwrU,
dma,
cpu_dma,
c_28min,
dataout,
zdataout,
c_14m,
zena_o,
c_28m,
c_7m,
reset_out,
pulse,
enaRDreg,
enaWRreg,
ena7RDreg,
ena7WRreg
);

output [15:0] sdata;
//inout
output [11:0] sdaddr;
output sd_we;
output sd_ras;
output sd_cas;
output [3:0] sd_cs;
output [1:0] dqm;
output [1:0] ba;
// buffer
input sysclk;
input reset;
input [15:0] zdatawr;
input [23:0] zAddr;
input [2:0] zstate;
input [15:0] datawr;
input [23:0] rAddr;
input rwr;
input dwrL;
input dwrU;
input ZwrL;
input ZwrU;
input dma;
input cpu_dma;
input c_28min;
output [15:0] dataout;
output [15:0] zdataout;
output c_14m;
output zena_o;
//buffer
output c_28m;
output c_7m;
output reset_out;
output pulse;
output enaRDreg;
output enaWRreg;
output ena7RDreg;
output ena7WRreg;

reg [15:0] sdata;
reg [11:0] sdaddr;
reg sd_we;
reg sd_ras;
reg sd_cas;
reg [3:0] sd_cs;
reg [1:0] dqm;
reg [1:0] ba;
wire sysclk;
wire reset;
wire [15:0] zdatawr;
wire [23:0] zAddr;
wire [2:0] zstate;
wire [15:0] datawr;
wire [23:0] rAddr;
wire rwr;
wire dwrL;
wire dwrU;
wire ZwrL;
wire ZwrU;
wire dma;
wire cpu_dma;
wire c_28min;
reg [15:0] dataout;
reg [15:0] zdataout;
reg c_14m;
wire zena_o;
reg c_28m;
reg c_7m;
wire reset_out;
reg pulse;
reg enaRDreg;
reg enaWRreg;
reg ena7RDreg;
reg ena7WRreg;


reg [3:0] initstate;
reg [3:0] cas_sd_cs;
reg cas_sd_ras;
reg cas_sd_cas;
reg cas_sd_we;
reg [1:0] cas_dqm;
reg init_done;
reg [15:0] datain;
reg [23:0] casaddr;
reg sdwrite;
reg [15:0] sdata_reg;
reg Z_cycle;
reg zena;
reg [63:0] zcache;
reg [23:0] zcache_addr;
reg zcache_fill;
reg zcachehit;
reg [3:0] zvalid;
wire zequal;
reg [1:0] zstated;
reg [15:0] zdataoutd;
reg R_cycle;
wire rvalid;
reg [15:0] rdataout;
parameter [3:0]
  ph0 = 0,
  ph1 = 1,
  ph2 = 2,
  ph3 = 3,
  ph4 = 4,
  ph5 = 5,
  ph6 = 6,
  ph7 = 7,
  ph8 = 8,
  ph9 = 9,
  ph10 = 10,
  ph11 = 11,
  ph12 = 12,
  ph13 = 13,
  ph14 = 14,
  ph15 = 15;

reg [3:0] sdram_state;
parameter [1:0]
  nop = 0,
  ras = 1,
  cas = 2;

wire [1:0] pass;

  //-----------------------------------------------------------------------
  // SPIHOST cache
  //-----------------------------------------------------------------------
  assign zena_o = (zena == 1'b 1 && zAddr == casaddr && cas_sd_cas == 1'b 0) || zstate[1:0] == 2'b 01 || zcachehit == 1'b 1 ? 1'b 1 : 1'b 0;
  always @(sysclk or zAddr or zcache_addr or zcache or zequal or zvalid or zdataoutd) begin
    //		if zaddr(23 downto 3)=zcache_addr(23 downto 3) THEN
    //			zequal <='1';
    //		else	
    //--			zequal <='0';
    //		end if;	
    //--		zcachehit <= '0';
    if(zequal == 1'b 1 && zvalid[0] == 1'b 1) begin
      case(zaddr)
            //(2 downto 1)) is ---zcache_addr(2 downto 1)) is
      2'b 00 : begin
        zcachehit <= zvalid[0];
        zdataout <= zcache[63:48];
      end
      2'b 01 : begin
        zcachehit <= zvalid[1];
        zdataout <= zcache[47:32];
      end
      2'b 10 : begin
        zcachehit <= zvalid[2];
        zdataout <= zcache[31:16];
      end
      2'b 11 : begin
        zcachehit <= zvalid[3];
        zdataout <= zcache[15:0];
      end
      default : begin
      end
      endcase
    end
    else begin
      zdataout <= zdataoutd;
    end
  end

  //Datenübernahme
  always @(posedge sysclk or posedge reset) begin
    if(reset == 1'b 0) begin
      zcache_fill <= 1'b 0;
      zena <= 1'b 0;
      zvalid <= 4'b 0000;
    end else begin
      if(sdram_state == ph10 && Z_cycle == 1'b 1) begin
        zdataoutd <= sdata_reg;
      end
      zstated <= zstate[1:0];
      if(zequal == 1'b 1 && zstate == 2'b 11) begin
        zvalid <= 4'b 0000;
      end
      case(sdram_state)
      ph7 : begin
        zena <= Z_cycle;
      end
      ph8 : begin
        if(cas_sd_we == 1'b 1 && zstated[1] == 1'b 0 && Z_cycle == 1'b 1) begin
          //only instruction cache
          //										if cas_sd_we='1' AND Z_cycle='1' THEN
          zcache_addr <= casaddr;
          zcache_fill <= 1'b 1;
          zvalid <= 4'b 0000;
        end
      end
      ph10 : begin
        if(zcache_fill == 1'b 1) begin
          zcache[63:48] <= sdata_reg;
        end
      end
      ph11 : begin
        if(zcache_fill == 1'b 1) begin
          zcache[47:32] <= sdata_reg;
        end
      end
      ph12 : begin
        if(zcache_fill == 1'b 1) begin
          zcache[31:16] <= sdata_reg;
        end
      end
      ph13 : begin
        if(zcache_fill == 1'b 1) begin
          zcache[15:0] <= sdata_reg;
        end
        zcache_fill <= 1'b 0;
      end
      ph15 : begin
        zena <= 1'b 0;
        zvalid <= 4'b 1111;
      end
      default : begin
      end
      endcase
    end
  end

  //-----------------------------------------------------------------------
  // Main cache
  //-----------------------------------------------------------------------
  always @(sysclk or rvalid or rdataout or sdata_reg) begin
    dataout <= rdataout;
  end

  always @(posedge sysclk or posedge rvalid or posedge rdataout or posedge sdata_reg) begin
    if(sdram_state == ph10 && R_cycle == 1'b 1) begin
      rdataout <= sdata_reg;
    end
  end

  //-----------------------------------------------------------------------
  // SDRAM Basic
  //-----------------------------------------------------------------------
  assign reset_out = init_done;
  always @(sysclk or reset or sdwrite or datain or c_28min) begin
    if(sdwrite == 1'b 1) begin
      sdata <= datain;
    end
    else begin
      sdata <= 16'b ZZZZZZZZZZZZZZZZ;
    end
  end

  always @(posedge sysclk or posedge reset or posedge sdwrite or posedge datain or posedge c_28min) begin
      //   sample SDRAM data
    sdata_reg <= sdata;
  end

  always @(posedge sysclk or posedge reset or posedge sdwrite or posedge datain or posedge c_28min) begin
    if(reset == 1'b 0) begin
      initstate <= {4{1'b0}};
      init_done <= 1'b 0;
      sdram_state <= ph0;
      sdwrite <= 1'b 0;
      enaRDreg <= 1'b 0;
      enaWRreg <= 1'b 0;
      ena7RDreg <= 1'b 0;
      ena7WRreg <= 1'b 0;
    end else begin
      sdwrite <= 1'b 0;
      enaRDreg <= 1'b 0;
      enaWRreg <= 1'b 0;
      ena7RDreg <= 1'b 0;
      ena7WRreg <= 1'b 0;
      case(sdram_state)
            //LATENCY=3
      ph0 : begin
        //							IF c_28min='1' THEN
        sdram_state <= ph1;
        //							ELSE	
        //								sdram_state <= ph0;
        //							END IF;	
      end
      ph1 : begin
        if(c_28min == 1'b 1) begin
          sdram_state <= ph2;
          c_28m <= 1'b 0;
          pulse <= 1'b 0;
        end
        else begin
          sdram_state <= ph1;
        end
      end
      ph2 : begin
        //sdram_state <= ph3;
        if(c_28min == 1'b 0) begin
          sdram_state <= ph3;
          enaRDreg <= 1'b 1;
        end
        else begin
          sdram_state <= ph2;
        end
      end
      ph3 : begin
        sdram_state <= ph4;
        //							sdwrite <= '1';
        c_14m <= 1'b 0;
        c_28m <= 1'b 1;
      end
      ph4 : begin
        sdram_state <= ph5;
        sdwrite <= 1'b 1;
      end
      ph5 : begin
        sdram_state <= ph6;
        sdwrite <= 1'b 1;
        c_28m <= 1'b 0;
        pulse <= 1'b 1;
      end
      ph6 : begin
        sdram_state <= ph7;
        sdwrite <= 1'b 1;
        enaWRreg <= 1'b 1;
        ena7RDreg <= 1'b 1;
      end
      ph7 : begin
        sdram_state <= ph8;
        c_7m <= 1'b 0;
        c_14m <= 1'b 1;
        c_28m <= 1'b 1;
      end
      ph8 : begin
        sdram_state <= ph9;
      end
      ph9 : begin
        sdram_state <= ph10;
        c_28m <= 1'b 0;
        pulse <= 1'b 0;
      end
      ph10 : begin
        sdram_state <= ph11;
        enaRDreg <= 1'b 1;
      end
      ph11 : begin
        sdram_state <= ph12;
        c_14m <= 1'b 0;
        c_28m <= 1'b 1;
      end
      ph12 : begin
        sdram_state <= ph13;
      end
      ph13 : begin
        sdram_state <= ph14;
        c_28m <= 1'b 0;
        pulse <= 1'b 1;
      end
      ph14 : begin
        sdram_state <= ph15;
        enaWRreg <= 1'b 1;
        ena7WRreg <= 1'b 1;
      end
      ph15 : begin
        sdram_state <= ph0;
        c_7m <= 1'b 1;
        c_14m <= 1'b 1;
        c_28m <= 1'b 1;
        if(initstate != 4'b 1111) begin
          initstate <= initstate + 1;
        end
        else begin
          init_done <= 1'b 1;
        end
      end
      default : begin
        sdram_state <= ph0;
      end
      endcase
    end
  end

  always @(posedge initstate or posedge pass or posedge zaddr or posedge datain or posedge init_done or posedge casaddr or posedge dwrU or posedge dwrL or posedge Z_cycle) begin
    //		ba <= Addr(22 downto 21);
    sd_cs <= 4'b 1111;
    sd_ras <= 1'b 1;
    sd_cas <= 1'b 1;
    sd_we <= 1'b 1;
    sdaddr <= 12'b XXXXXXXXXXXX;
    ba <= 2'b 00;
    dqm <= 2'b 00;
    if(init_done == 1'b 0) begin
      if(sdram_state == ph2) begin
        case(initstate)
        4'b 0010 : begin
          //PRECHARGE
          sdaddr[10] <= 1'b 1;
          //all banks
          sd_cs <= 4'b 0000;
          sd_ras <= 1'b 0;
          sd_cas <= 1'b 1;
          sd_we <= 1'b 0;
        end
        4'b 0011,4'b 0100,4'b 0101,4'b 0110,4'b 0111,4'b 1000,4'b 1001,4'b 1010,4'b 1011,4'b 1100 : begin
          //AUTOREFRESH
          sd_cs <= 4'b 0000;
          sd_ras <= 1'b 0;
          sd_cas <= 1'b 0;
          sd_we <= 1'b 1;
        end
        4'b 1101 : begin
          //LOAD MODE REGISTER
          sd_cs <= 4'b 0000;
          sd_ras <= 1'b 0;
          sd_cas <= 1'b 0;
          sd_we <= 1'b 0;
          //							ba <= "00";
          //						sdaddr <= "001000100010"; --BURST=4 LATENCY=2
          sdaddr <= 12'b 001000110010;
          //BURST=4 LATENCY=3
          //							sdaddr <= "001000110000"; --noBURST LATENCY=3
        end
        default : begin
          //NOP
        end
        endcase
      end
    end
    else begin
      // Time slot control					
      if(sdram_state == ph2) begin
        R_cycle <= 1'b 0;
        Z_cycle <= 1'b 0;
        cas_sd_cs <= 4'b 1110;
        cas_sd_ras <= 1'b 1;
        cas_sd_cas <= 1'b 1;
        cas_sd_we <= 1'b 1;
        if(dma == 1'b 0 || cpu_dma == 1'b 0) begin
          R_cycle <= 1'b 1;
          sdaddr <= rAddr[20:9];
          ba <= rAddr[22:21];
          cas_dqm <= {dwrU,dwrL};
          sd_cs <= 4'b 1110;
          //ACTIVE
          sd_ras <= 1'b 0;
          casaddr <= rAddr;
          datain <= datawr;
          cas_sd_cas <= 1'b 0;
          cas_sd_we <= rwr;
        end
        else if(zstate[2] == 1'b 1 || zena_o == 1'b 1) begin
          //refresh cycle
          sd_cs <= 4'b 0000;
          //AUTOREFRESH
          sd_ras <= 1'b 0;
          sd_cas <= 1'b 0;
        end
        else begin
          Z_cycle <= 1'b 1;
          sdaddr <= zAddr[20:9];
          ba <= zAddr[22:21];
          cas_dqm <= {ZwrU,ZwrL};
          sd_cs <= 4'b 1110;
          //ACTIVE
          sd_ras <= 1'b 0;
          casaddr <= zAddr;
          datain <= zdatawr;
          cas_sd_cas <= 1'b 0;
          if(zstate == 3'b 011) begin
            cas_sd_we <= 1'b 0;
            //							dqm <= ZwrU& ZwrL;
          end
        end
      end
      if(sdram_state == ph5) begin
        sdaddr <= {1'b 0,1'b 1,1'b 0,casaddr[23],casaddr[8:1]};
        //auto precharge
        ba <= casaddr[22:21];
        sd_cs <= cas_sd_cs;
        if(cas_sd_we == 1'b 0) begin
          dqm <= cas_dqm;
        end
        sd_ras <= cas_sd_ras;
        sd_cas <= cas_sd_cas;
        sd_we <= cas_sd_we;
      end
    end
  end


endmodule

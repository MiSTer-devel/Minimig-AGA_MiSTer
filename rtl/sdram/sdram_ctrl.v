//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Copyright (c) 2009/2011 Tobias Gubener                                   //
// Subdesign fAMpIGA by TobiFlex                                            //
//                                                                          //
// This source file is free software: you can redistribute it and/or modify //
// it under the terms of the GNU General Public License as published        //
// by the Free Software Foundation, either version 3 of the License, or     //
// (at your option) any later version.                                      //
//                                                                          //
// This source file is distributed in the hope that it will be useful,      //
// but WITHOUT ANY WARRANTY; without even the implied warranty of           //
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            //
// GNU General Public License for more details.                             //
//                                                                          //
// You should have received a copy of the GNU General Public License        //
// along with this program.  If not, see <http://www.gnu.org/licenses/>.    //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//
// RK:
// 2013-02-11 - converted to Verilog
//            - cleanup
//            - 


module sdram_ctrl(
  // system
  input  wire           sysclk,
  input  wire           c_7m,
  input  wire           reset_in,
  output wire           reset_out,
  // sdram
  output reg  [ 12-1:0] sdaddr,
  output reg  [  4-1:0] sd_cs,
  output reg  [  2-1:0] ba,
  output reg            sd_we,
  output reg            sd_ras,
  output reg            sd_cas,
  output reg  [  2-1:0] dqm,
  inout  wire [ 16-1:0] sdata,
  // host
  input  wire [ 24-1:0] hostAddr,
  input  wire [  3-1:0] hostState,
  input  wire           hostL,
  input  wire           hostU,
  input  wire [ 16-1:0] hostWR,
  output reg  [ 16-1:0] hostRD,
  output wire           hostena,
  // chip
  input  wire    [23:1] chipAddr,
  input  wire           chipL,
  input  wire           chipU,
  input  wire           chipRW,
  input  wire           chip_dma,
  input  wire [ 16-1:0] chipWR,
  output reg  [ 16-1:0] chipRD,
  // cpu
  input  wire    [24:1] cpuAddr,
  input  wire [  6-1:0] cpustate,
  input  wire           cpuL,
  input  wire           cpuU,
  input  wire           cpu_dma,
  input  wire [ 16-1:0] cpuWR,
  output reg  [ 16-1:0] cpuRD,
  output reg            enaWRreg,
  output reg            ena7RDreg,
  output reg            ena7WRreg,
  output wire           cpuena
);


//// internal parameters ////
localparam [3:0]
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

parameter [1:0]
  nop = 0,
  ras = 1,
  cas = 2;


//// internal signals ////
reg  [  4-1:0] initstate;
reg  [  4-1:0] cas_sd_cs;
reg            cas_sd_ras;
reg            cas_sd_cas;
reg            cas_sd_we;
reg  [  2-1:0] cas_dqm;
reg            init_done;
reg  [ 16-1:0] datawr;
reg  [ 25-1:0] casaddr;
reg            sdwrite;
reg  [ 16-1:0] sdata_reg;
reg            hostCycle;
wire [ 25-1:0] zmAddr;
reg            zena;
reg  [ 64-1:0] zcache;
reg  [ 24-1:0] zcache_addr;
reg            zcache_fill;
reg            zcachehit;
reg  [  4-1:0] zvalid;
wire           zequal;
reg  [  2-1:0] hostStated;
reg  [ 16-1:0] hostRDd;
reg            cena;
reg  [ 64-1:0] ccache;
reg  [ 25-1:0] ccache_addr;
reg            ccache_fill;
reg            ccachehit;
reg  [  4-1:0] cvalid;
wire           cequal;
reg  [  2-1:0] cpustated;
reg  [ 16-1:0] cpuRDd;
reg  [  8-1:0] reset_cnt;
reg            reset;
reg            reset_sdstate;
reg            c_7md;
reg            c_7mdd;
reg            c_7mdr;
reg            cpuCycle;
reg            chipCycle;
reg  [  4-1:0] sdram_state;
wire [  2-1:0] pass;
wire [  4-1:0] tst_adr1;
wire [  4-1:0] tst_adr2;


// CPU states
//             [5]    [4:3]              [2]   [1:0]
// cpustate <= clkena&slower(1 downto 0)&ramcs&state
// [1:0] = state = 00-> fetch code 10->read data 11->write data 01->no memaccess


////////////////////////////////////////
// reset
////////////////////////////////////////

always @(posedge sysclk or negedge reset_in) begin
  if(~reset_in) begin
    reset_cnt <= 8'b00000000;
    reset <= 1'b0;
    reset_sdstate <= 1'b0;
  end else begin
    if(reset_cnt == 8'b00101010) begin
      reset_sdstate <= 1'b1;
    end
    if(reset_cnt == 8'b10101010) begin
      if(sdram_state == ph15) begin
        reset <= 1'b1;
      end
    end else begin
      reset_cnt <= reset_cnt + 8'd1;
      reset <= 1'b0;
    end
  end
end

assign reset_out = init_done;


////////////////////////////////////////
// host cache
////////////////////////////////////////

assign hostena = (zena == 1'b1) || (hostState[1:0] == 2'b01) || (zcachehit == 1'b1) ? 1'b1 : 1'b0;
assign zmAddr = {1'b0, ~hostAddr[23],hostAddr[22], ~hostAddr[21],hostAddr[20:0]};
assign tst_adr1 = {hostAddr[2:1],zcache_addr[2:1]};
assign zequal = (zmAddr[23:3] == zcache_addr[23:3]);

// cache read
always @(*) begin
  zcachehit = 1'b0; // TODO move to else block
  if((zequal == 1'b1) && (zvalid[0] == 1'b1) && (hostStated[1] == 1'b0)) begin
    case(tst_adr1)
    4'b0000,4'b0101,4'b1010,4'b1111 : begin
      zcachehit = zvalid[0];
      hostRD = zcache[63:48];
    end
    4'b0100,4'b1001,4'b1110,4'b0011 : begin
      zcachehit = zvalid[1];
      hostRD = zcache[47:32];
    end
    4'b1000,4'b1101,4'b0010,4'b0111 : begin
      zcachehit = zvalid[2];
      hostRD = zcache[31:16];
    end
    4'b1100,4'b0001,4'b0110,4'b1011 : begin
      zcachehit = zvalid[3];
      hostRD = zcache[15:0];
    end
    default : begin
    end
    endcase
  end
  else begin
    hostRD = hostRDd;
  end
end

// cache fill
always @(posedge sysclk or negedge reset) begin
  if(~reset) begin
    zcache_fill <= 1'b0;
    zena <= 1'b0;
    zvalid <= 4'b0000;
  end else begin
    if(enaWRreg == 1'b1) begin
      zena <= 1'b0;
    end
    if(sdram_state == ph9 && hostCycle == 1'b1) begin
      hostRDd <= sdata_reg;
    end
    if(sdram_state == ph11 && hostCycle == 1'b1) begin
      if(zmAddr == casaddr && cas_sd_cas == 1'b0) begin
        zena <= 1'b1;
      end
    end
    hostStated <= hostState[1:0];
    if(zequal == 1'b1 && hostState[1:0] == 2'b11) begin
      zvalid <= 4'b0000;
    end
    case(sdram_state)
      ph7 : begin
        if(hostStated[1] == 1'b0 && hostCycle == 1'b1) begin
          // only instruction cache
          zcache_addr <= casaddr[23:0];
          zcache_fill <= 1'b1;
          zvalid <= 4'b0000;
        end
      end
      ph9 : begin
        if(zcache_fill == 1'b1) begin
          zcache[63:48] <= sdata_reg;
        end
      end
      ph10 : begin
        if(zcache_fill == 1'b1) begin
          zcache[47:32] <= sdata_reg;
        end
      end
      ph11 : begin
        if(zcache_fill == 1'b1) begin
          zcache[31:16] <= sdata_reg;
        end
      end
      ph12 : begin
        if(zcache_fill == 1'b1) begin
          zcache[15:0] <= sdata_reg;
          zvalid <= 4'b1111;
        end
        zcache_fill <= 1'b0;
      end
      default : begin
      end
    endcase
  end
end


////////////////////////////////////////
// cpu cache
////////////////////////////////////////

assign cpuena = (cena == 1'b1) || (ccachehit == 1'b1) ? 1'b1 : 1'b0;
assign tst_adr2 = {cpuAddr[2:1],ccache_addr[2:1]};
assign cequal = (cpuAddr[24:3] == ccache_addr[24:3]);

// cache read
always @(*) begin
  ccachehit = 1'b0; // TODO move to else block
  if(cequal == 1'b1 && cvalid[0] == 1'b1 && cpustated[1] == 1'b0) begin
    case(tst_adr2)
      4'b0000,4'b0101,4'b1010,4'b1111 : begin
        ccachehit = cvalid[0];
        cpuRD = ccache[63:48];
      end
      4'b0100,4'b1001,4'b1110,4'b0011 : begin
        ccachehit = cvalid[1];
        cpuRD = ccache[47:32];
      end
      4'b1000,4'b1101,4'b0010,4'b0111 : begin
        ccachehit = cvalid[2];
        cpuRD = ccache[31:16];
      end
      4'b1100,4'b0001,4'b0110,4'b1011 : begin
        ccachehit = cvalid[3];
        cpuRD = ccache[15:0];
      end
      default : begin
      end
    endcase
  end
  else begin
    cpuRD = cpuRDd;
  end
end

// cache fill
always @(posedge sysclk or negedge reset) begin
  if(~reset) begin
    ccache_fill <= 1'b0;
    cena <= 1'b0;
    cvalid <= 4'b0000;
  end else begin
    if(cpustate[5] == 1'b1) begin
      cena <= 1'b0;
    end
    if(sdram_state == ph9 && cpuCycle == 1'b1) begin
      cpuRDd <= sdata_reg;
    end
    if(sdram_state == ph11 && cpuCycle == 1'b1) begin
      if(cpuAddr == casaddr[24:1] && cas_sd_cas == 1'b0) begin
        cena <= 1'b1;
      end
    end
    cpustated <= cpustate[1:0];
    if(cequal == 1'b1 && cpustate[1:0] == 2'b11) begin
      cvalid <= 4'b0000;
    end
    case(sdram_state)
    ph7 : begin
      if(cpustated[1] == 1'b0 && cpuCycle == 1'b1) begin
        // only instruction cache
        ccache_addr <= casaddr;
        ccache_fill <= 1'b1;
        cvalid <= 4'b0000;
      end
    end
    ph9 : begin
      if(ccache_fill == 1'b1) begin
        ccache[63:48] <= sdata_reg;
      end
    end
    ph10 : begin
      if(ccache_fill == 1'b1) begin
        ccache[47:32] <= sdata_reg;
      end
    end
    ph11 : begin
      if(ccache_fill == 1'b1) begin
        ccache[31:16] <= sdata_reg;
      end
    end
    ph12 : begin
      if(ccache_fill == 1'b1) begin
        ccache[15:0] <= sdata_reg;
        cvalid <= 4'b1111;
      end
      ccache_fill <= 1'b0;
    end
    default : begin
    end
    endcase
  end
end


////////////////////////////////////////
// chip cache
////////////////////////////////////////

always @(posedge sysclk) begin
  if(sdram_state == ph9 && chipCycle == 1'b1) begin
    chipRD <= sdata_reg;
  end
end


////////////////////////////////////////
// SDRAM control
////////////////////////////////////////

// clock mangling - TODO
always @(negedge sysclk) begin
  c_7md <= c_7m;
end
always @ (posedge sysclk) begin
  c_7mdd <= c_7md;
  c_7mdr <= c_7md &  ~c_7mdd;
end

// SDRAM data I/O
assign sdata = (sdwrite) ? datawr : 16'bzzzzzzzzzzzzzzzz;

// read data reg
always @ (posedge sysclk) begin
  sdata_reg <= sdata;
end

// write data reg
always @(posedge sysclk) begin
  if(sdram_state == ph2) begin
    if(chipCycle == 1'b1) begin
      datawr <= chipWR;
    end else if(cpuCycle == 1'b1) begin
      datawr <= cpuWR;
    end else begin
      datawr <= hostWR;
    end
  end
end

// write / read control
always @(posedge sysclk or negedge reset_sdstate) begin
  if(~reset_sdstate) begin
    sdwrite <= 1'b0;
    enaWRreg <= 1'b0;
    ena7RDreg <= 1'b0;
    ena7WRreg <= 1'b0;
  end else begin
    sdwrite <= 1'b0;
    enaWRreg <= 1'b0;
    ena7RDreg <= 1'b0;
    ena7WRreg <= 1'b0;
    case(sdram_state) // LATENCY=3
      ph2 : begin
        sdwrite <= 1'b1;
        enaWRreg <= 1'b1;
      end
      ph3 : begin
        sdwrite <= 1'b1;
      end
      ph4 : begin
        sdwrite <= 1'b1;
      end
      ph5 : begin
        sdwrite <= 1'b1;
      end
      ph6 : begin
        enaWRreg <= 1'b1;
        ena7RDreg <= 1'b1;
      end
      ph10 : begin
        enaWRreg <= 1'b1;
      end
      ph14 : begin
        enaWRreg <= 1'b1;
        ena7WRreg <= 1'b1;
      end
      default : begin
      end
    endcase
  end
end

// init counter
always @(posedge sysclk or negedge reset) begin
  if(~reset) begin
    initstate <= {4{1'b0}};
    init_done <= 1'b0;
  end else begin
    case(sdram_state) // LATENCY=3
      ph15 : begin
        if(initstate != 4'b1111) begin
          initstate <= initstate + 4'd1;
        end else begin
          init_done <= 1'b1;
        end
      end
      default : begin
      end
    endcase
  end
end

// sdram state
always @(posedge sysclk) begin
  if(c_7mdr == 1'b1) begin
    sdram_state <= ph2;
  end else begin
    case(sdram_state) // LATENCY=3
      ph0 : begin
        sdram_state <= ph1;
      end
      ph1 : begin
        sdram_state <= ph2;
      end
      ph2 : begin
        sdram_state <= ph3;
      end
      ph3 : begin
        sdram_state <= ph4;
      end
      ph4 : begin
        sdram_state <= ph5;
      end
      ph5 : begin
        sdram_state <= ph6;
      end
      ph6 : begin
        sdram_state <= ph7;
      end
      ph7 : begin
        sdram_state <= ph8;
      end
      ph8 : begin
        sdram_state <= ph9;
      end
      ph9 : begin
        sdram_state <= ph10;
      end
      ph10 : begin
        sdram_state <= ph11;
      end
      ph11 : begin
        sdram_state <= ph12;
      end
      ph12 : begin
        sdram_state <= ph13;
      end
      ph13 : begin
        sdram_state <= ph14;
      end
      ph14 : begin
        sdram_state <= ph15;
      end
      default : begin
        sdram_state <= ph0;
      end
    endcase
  end
end

// sdram control
always @(posedge sysclk) begin
  sd_cs <= 4'b1111;
  sd_ras <= 1'b1;
  sd_cas <= 1'b1;
  sd_we <= 1'b1;
  sdaddr <= 12'bxxxxxxxxxxxx;
  ba <= 2'b00;
  dqm <= 2'b00;
  if(init_done == 1'b0) begin
    if(sdram_state == ph1) begin
      case(initstate)
      4'b0010 : begin
        //PRECHARGE
        sdaddr[10] <= 1'b1;
        //all banks
        sd_cs <= 4'b0000;
        sd_ras <= 1'b0;
        sd_cas <= 1'b1;
        sd_we <= 1'b0;
      end
      4'b0011,4'b0100,4'b0101,4'b0110,4'b0111,4'b1000,4'b1001,4'b1010,4'b1011,4'b1100 : begin
        //AUTOREFRESH
        sd_cs <= 4'b0000;
        sd_ras <= 1'b0;
        sd_cas <= 1'b0;
        sd_we <= 1'b1;
      end
      4'b1101 : begin
        //LOAD MODE REGISTER
        sd_cs <= 4'b0000;
        sd_ras <= 1'b0;
        sd_cas <= 1'b0;
        sd_we <= 1'b0;
        //sdaddr <= 12b001000100010; // BURST=4 LATENCY=2
        sdaddr <= 12'b001000110010; // BURST=4 LATENCY=3
        //sdaddr <= 12'b001000110000; // noBURST LATENCY=3
      end
      default : begin
        // NOP
      end
      endcase
    end
  end else begin
    // time slot control
    if(sdram_state == ph1) begin
      cpuCycle <= 1'b0;
      chipCycle <= 1'b0;
      hostCycle <= 1'b0;
      cas_sd_cs <= 4'b1110;
      cas_sd_ras <= 1'b1;
      cas_sd_cas <= 1'b1;
      cas_sd_we <= 1'b1;
      if(chip_dma == 1'b0 || chipRW == 1'b0) begin
        chipCycle <= 1'b1;
        sdaddr <= chipAddr[20:9];
        ba <= chipAddr[22:21];
        cas_dqm <= {chipU,chipL};
        sd_cs <= 4'b1110; // active
        sd_ras <= 1'b0;
        casaddr <= {1'b0,chipAddr,1'b0};
        cas_sd_cas <= 1'b0;
        cas_sd_we <= chipRW;
      end else if(cpustate[2] == 1'b0 && cpustate[5] == 1'b0) begin
        cpuCycle <= 1'b1;
        sdaddr <= cpuAddr[20:9];
        ba <= cpuAddr[22:21];
        cas_dqm <= {cpuU,cpuL};
        sd_cs <= 4'b1110; // active
        sd_ras <= 1'b0;
        casaddr <= {cpuAddr[24:1],1'b0};
        cas_sd_cas <= 1'b0;
        cas_sd_we <=  ~cpustate[1] |  ~cpustate[0];
      end else begin
        if(hostState[2] == 1'b1 || hostena == 1'b1) begin // refresh cycle
          sd_cs <= 4'b0000; // autorefresh
          sd_ras <= 1'b0;
          sd_cas <= 1'b0;
        end else begin
          hostCycle <= 1'b1;
          sdaddr <= zmAddr[20:9];
          ba <= zmAddr[22:21];
          cas_dqm <= {hostU,hostL};
          sd_cs <= 4'b1110; // active
          sd_ras <= 1'b0;
          casaddr <= zmAddr;
          cas_sd_cas <= 1'b0;
          if(hostState == 3'b011) cas_sd_we <= 1'b0;
        end
      end
    end
    if(sdram_state == ph4) begin
      sdaddr <= {1'b0,1'b1,1'b0,casaddr[23],casaddr[8:1]}; // auto precharge
      ba <= casaddr[22:21];
      sd_cs <= cas_sd_cs;
      if(!cas_sd_we) dqm <= cas_dqm;
      sd_ras <= cas_sd_ras;
      sd_cas <= cas_sd_cas;
      sd_we <= cas_sd_we;
    end
  end
end


endmodule


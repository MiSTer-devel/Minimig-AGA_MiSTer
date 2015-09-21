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


module sdram_ctrl(
  // system
  input  wire           sysclk,
  input  wire           c_7m,
  input  wire           reset_in,
  input  wire           cache_rst,
  input  wire           cache_inhibit,
  input  wire [  4-1:0] cpu_cache_ctrl,
  output wire           reset_out,
  // sdram
  output reg  [ 13-1:0] sdaddr,
  output reg  [  4-1:0] sd_cs,
  output reg  [  2-1:0] ba,
  output reg            sd_we,
  output reg            sd_ras,
  output reg            sd_cas,
  output reg  [  2-1:0] dqm,
  inout  wire [ 16-1:0] sdata,
  // host
  input  wire [ 16-1:0] hostWR,
  input  wire [ 24-1:0] hostAddr,
  input  wire [  3-1:0] hostState,
  input  wire           hostL,
  input  wire           hostU,
  output reg  [ 16-1:0] hostRD,
  output wire           hostena,
  //input  wire           host_cs,
  //input  wire [ 24-1:0] host_adr,
  //input  wire           host_we,
  //input  wire [  2-1:0] host_bs,
  //input  wire [ 16-1:0] host_wdat,
  //output reg  [ 16-1:0] host_rdat,
  //output wire           host_ack,
  // chip
  input  wire    [23:1] chipAddr,
  input  wire           chipL,
  input  wire           chipU,
  input  wire           chipRW,
  input  wire           chip_dma,
  input  wire [ 16-1:0] chipWR,
  output reg  [ 16-1:0] chipRD,
  output wire [ 48-1:0] chip48,
  // cpu
  input  wire    [24:1] cpuAddr,
  input  wire [  6-1:0] cpustate,
  input  wire           cpuL,
  input  wire           cpuU,
  input  wire           cpu_dma,
  input  wire [ 16-1:0] cpuWR,
  output wire [ 16-1:0] cpuRD,
  output reg            enaWRreg,
  output reg            ena7RDreg,
  output reg            ena7WRreg,
  output wire           cpuena,
  output reg            enaRDreg
);



//// parameters ////
localparam [1:0]
  nop = 0,
  ras = 1,
  cas = 2;

localparam [1:0]
  WAITING = 0,
  WRITE1 = 1,
  WRITE2 = 2,
  WRITE3 = 3;

localparam [2:0]
  REFRESH = 0,
  CHIP = 1,
  CPU_READCACHE = 2,
  CPU_WRITECACHE = 3,
  HOST = 4,
  IDLE = 5;

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


//// local signals ////
reg  [ 4-1:0] initstate;
reg  [ 4-1:0] cas_sd_cs;
reg           cas_sd_ras;
reg           cas_sd_cas;
reg           cas_sd_we;
reg  [ 2-1:0] cas_dqm;
reg           init_done;
wire [16-1:0] datain;
reg  [16-1:0] datawr;
reg  [25-1:0] casaddr;
reg           sdwrite;
reg  [16-1:0] sdata_reg;
wire [25-1:0] zmAddr;
reg           zena;
reg  [64-1:0] zcache;
reg  [24-1:0] zcache_addr;
reg           zcache_fill;
reg           zcachehit;
reg  [ 4-1:0] zvalid;
reg           zequal;
reg  [ 2-1:0] hostStated;
reg  [16-1:0] hostRDd;
reg           cena;
wire [64-1:0] ccache;
wire [25-1:0] ccache_addr;
wire          ccache_fill;
wire          ccachehit;
wire [ 4-1:0] cvalid;
wire          cequal;
wire [ 2-1:0] cpuStated;
wire [16-1:0] cpuRDd;
wire [64-1:0] dcache;
wire [25-1:0] dcache_addr;
wire          dcache_fill;
wire          dcachehit;
wire [ 4-1:0] dvalid;
wire          dequal;
reg  [ 8-1:0] hostslot_cnt;
reg  [ 8-1:0] reset_cnt;
reg           reset;
reg           reset_sdstate;
reg           c_7md;
reg           c_7mdd;
reg           c_7mdr;
reg  [ 9-1:0] refreshcnt;
reg           refresh_pending;
reg  [ 4-1:0] sdram_state;
wire [ 2-1:0] pass;
// writebuffer
reg  [ 3-1:0] slot1_type = IDLE;
reg  [ 3-1:0] slot2_type = IDLE;
reg  [ 2-1:0] slot1_bank;
reg  [ 2-1:0] slot2_bank;
wire          cache_req;
wire          readcache_fill;
reg           cache_fill_1;
reg           cache_fill_2;
reg  [16-1:0] chip48_1;
reg  [16-1:0] chip48_2;
reg  [16-1:0] chip48_3;
reg           writebuffer_req;
reg           writebuffer_ena;
reg  [ 2-1:0] writebuffer_dqm;
reg  [25-1:1] writebufferAddr;
reg  [16-1:0] writebufferWR;
reg  [16-1:0] writebufferWR_reg;
wire          writebuffer_cache_ack;
reg           writebuffer_hold;
reg  [ 2-1:0] writebuffer_state;
wire [25-1:1] cpuAddr_mangled;



////////////////////////////////////////
// address mangling
////////////////////////////////////////

// Let's try some bank-interleaving.
// For addresses in the upper 16 meg we shift bits around
// so that one bank bit comes from addr(3).  This should allow
// bank interleaving to make things more efficient.
// Turns out this is counter-productive
//cpuAddr_mangled<=cpuAddr(24)&cpuAddr(3)&cpuAddr(22 downto 4)&cpuAddr(23)&cpuAddr(2 downto 1)
//  when cpuAddr(24)='1' else cpuAddr;
assign cpuAddr_mangled = cpuAddr;



////////////////////////////////////////
// reset
////////////////////////////////////////

always @(posedge sysclk) begin
  if(!reset_in) begin
    reset_cnt       <= #1 8'b00000000;
    reset           <= #1 1'b0;
    reset_sdstate   <= #1 1'b0;
  end else begin
    if(reset_cnt == 8'b00101010) begin
      reset_sdstate <= #1 1'b1;
    end
    if(reset_cnt == 8'b10101010) begin
      if(sdram_state == ph15) begin
        reset       <= #1 1'b1;
      end
    end else begin
      reset_cnt     <= #1 reset_cnt + 8'd1;
      reset         <= #1 1'b0;
    end
  end
end

assign reset_out = init_done;



////////////////////////////////////////
// host access
////////////////////////////////////////

assign hostena = zena || hostState[1:0] == 2'b01 || zcachehit ? 1'b1 : 1'b0;

// map host processor's address space to 0x400000
assign zmAddr = {2'b00, ~hostAddr[22], hostAddr[21:0]};

always @ (*) begin
  zequal = (zmAddr[23:3] == zcache_addr[23:3]) ? 1'b1 : 1'b0;
  zcachehit = 1'b0;
  if(zequal && zvalid[0] && !hostStated[1]) begin
    case ({hostAddr[2:1], zcache_addr[2:1]})
      4'b0000,
      4'b0101,
      4'b1010,
      4'b1111 : begin
        zcachehit = zvalid[0];
        hostRD    = zcache[63:48];
      end
      4'b0100,
      4'b1001,
      4'b1110,
      4'b0011 : begin
        zcachehit = zvalid[1];
        hostRD    = zcache[47:32];
      end
      4'b1000,
      4'b1101,
      4'b0010,
      4'b0111 : begin
        zcachehit = zvalid[2];
        hostRD    = zcache[31:16];
      end
      4'b1100,
      4'b0001,
      4'b0110,
      4'b1011 : begin
        zcachehit = zvalid[3];
        hostRD    = zcache[15:0];
      end
      default : begin
      end
    endcase
  end
  else begin
    hostRD = hostRDd;
  end
end


//// host data read ////
always @ (posedge sysclk) begin
  if(!reset) begin
    zcache_fill       <= #1 1'b0;
    zena              <= #1 1'b0;
    zvalid            <= #1 4'b0000;
  end else begin
    if(enaWRreg) begin
      zena            <= #1 1'b0;
    end
    if(sdram_state == ph9 && slot1_type == HOST) begin
      hostRDd         <= #1 sdata_reg;
    end
    if(sdram_state == ph11 && slot1_type == HOST) begin
      zena            <= #1 1'b1;
    end
    hostStated        <= #1 hostState[1:0];
    if(zequal && |hostState[1:0]) begin
      zvalid          <= #1 4'b0000;
    end
    case(sdram_state)
    ph7 : begin
      if(!hostStated[1] && slot1_type == HOST) begin // only instruction cache
        zcache_addr   <= #1 casaddr[23:0];
        zcache_fill   <= #1 1'b1;
        zvalid        <= #1 4'b0000;
      end
    end
    ph9 : begin
      if(zcache_fill) begin
        zcache[63:48] <= #1 sdata_reg;
      end
    end
    ph10 : begin
      if(zcache_fill) begin
        zcache[47:32] <= #1 sdata_reg;
      end
    end
    ph11 : begin
      if(zcache_fill) begin
        zcache[31:16] <= #1 sdata_reg;
      end
    end
    ph12 : begin
      if(zcache_fill) begin
        zcache[15:0]  <= #1 sdata_reg;
        zvalid        <= #1 4'b1111;
      end
      zcache_fill     <= #1 1'b0;
    end
    default : begin
    end
    endcase
  end
end



////////////////////////////////////////
// cpu cache
////////////////////////////////////////

`define SDRAM_NEW_CACHE

`ifdef SDRAM_NEW_CACHE
wire snoop_act;
assign snoop_act = ((sdram_state==ph2)&&(!chipRW));

//// cpu cache ////
cpu_cache_new cpu_cache (
  .clk              (sysclk),                       // clock
  .rst              (!reset || !cache_rst),         // cache reset
  .cache_en         (1'b1),                         // cache enable
  .cpu_cache_ctrl   (cpu_cache_ctrl),               // CPU cache control
  .cache_inhibit    (cache_inhibit),                // cache inhibit
  .cpu_cs           (!cpustate[2]),                 // cpu activity
  .cpu_adr          ({cpuAddr_mangled, 1'b0}),      // cpu address
  .cpu_bs           ({!cpuU, !cpuL}),               // cpu byte selects
  .cpu_we           (&cpustate[1:0]),               // cpu write
  .cpu_ir           (!(|cpustate[1:0])),            // cpu instruction read
  .cpu_dr           (cpustate[1] && !cpustate[0]),  // cpu data read
  .cpu_dat_w        (cpuWR),                        // cpu write data
  .cpu_dat_r        (cpuRD),                        // cpu read data
  .cpu_ack          (ccachehit),                    // cpu acknowledge
  .wb_en            (writebuffer_cache_ack),        // writebuffer enable
  .sdr_dat_r        (sdata_reg),                    // sdram read data
  .sdr_read_req     (cache_req),                    // sdram read request from cache
  .sdr_read_ack     (readcache_fill),               // sdram read acknowledge to cache
  .snoop_act        (snoop_act),                    // snoop act (write only - just update existing data in cache)
  .snoop_adr        ({1'b0, chipAddr, 1'b0}),       // snoop address
  .snoop_dat_w      (chipWR)                        // snoop write data
);

`else

//// cpu cache ////
TwoWayCache mytwc (
  .clk              (sysclk),
  .reset            (reset),
  .cache_rst        (cache_rst),
  .ready            (),
  .cpu_addr         ({7'b0000000, cpuAddr_mangled, 1'b0}),
  .cpu_req          (!cpustate[2]),
  .cpu_ack          (ccachehit),
  .cpu_wr_ack       (writebuffer_cache_ack),
  .cpu_rw           (!cpustate[1] || !cpustate[0]),
  .cpu_rwl          (cpuL),
  .cpu_rwu          (cpuU),
  .data_from_cpu    (cpuWR),
  .data_to_cpu      (cpuRD),
  .sdram_addr       (),
  .data_from_sdram  (sdata_reg),
  .data_to_sdram    (),
  .sdram_req        (cache_req),
  .sdram_fill       (readcache_fill),
  .sdram_rw         (),
  .snoop_addr       (20'bxxxxxxxxxxxxxxxxxxxx),
  .snoop_req        (1'bx)
);

`endif


//// writebuffer ////
// write buffer, enables CPU to continue while a write is in progress
always @ (posedge sysclk) begin
  if(!reset) begin
    writebuffer_req   <= #1 1'b0;
    writebuffer_ena   <= #1 1'b0;
    writebuffer_state <= #1 WAITING;
  end else begin
    case(writebuffer_state)
      WAITING : begin
        // CPU write cycle, no cycle already pending
        if(cpustate[2:0] == 3'b011) begin
          writebufferAddr <= #1 cpuAddr_mangled[24:1];
          writebufferWR   <= #1 cpuWR;
          writebuffer_dqm <= #1 {cpuU, cpuL};
          writebuffer_req <= #1 1'b1;
          if(writebuffer_cache_ack) begin
            writebuffer_ena   <= #1 1'b1;
            writebuffer_state <= #1 WRITE2;
          end
        end
      end
      WRITE2 : begin
        if(writebuffer_hold) begin
          // The SDRAM controller has picked up the request
          writebuffer_req   <= #1 1'b0;
          writebuffer_state <= #1 WRITE3;
        end
      end
      WRITE3 : begin
        if(!writebuffer_hold) begin
          // Wait for write cycle to finish, so it's safe to update the signals
          writebuffer_state <= #1 WAITING;
        end
      end
      default : begin
        writebuffer_state <= #1 WAITING;
      end
    endcase
    if(cpustate[2]) begin
      // the CPU has unpaused, so clear the ack signal
      writebuffer_ena <= #1 1'b0;
    end
  end
end

assign cpuena = cena || ccachehit || writebuffer_ena;
assign readcache_fill = (cache_fill_1 && slot1_type == CPU_READCACHE) || (cache_fill_2 && slot2_type == CPU_READCACHE);


//// chip line read ////
always @ (posedge sysclk) begin
  if(slot1_type == CHIP) begin
    case(sdram_state)
      ph9  : chipRD   <= #1 sdata_reg;
      ph10 : chip48_1 <= #1 sdata_reg;
      ph11 : chip48_2 <= #1 sdata_reg;
      ph12 : chip48_3 <= #1 sdata_reg;
    endcase
  end
end

assign chip48 = {chip48_1, chip48_2, chip48_3};



////////////////////////////////////////
// SDRAM control
////////////////////////////////////////

//// clock mangling ////
// TODO this is some weird code - it's a 7MHz clock enable on 118MHz clock, used to 'reset' the sdram state machine, to state ph2 ???
always @ (negedge sysclk) begin
  c_7md <= c_7m;
end

always @ (posedge sysclk) begin
  c_7mdd <= c_7md;
  c_7mdr <= c_7md &  ~c_7mdd;
end


//// sdram data I/O ////
assign sdata = (sdwrite) ? datawr : 16'bzzzzzzzzzzzzzzzz;


//// read data reg ////
always @ (posedge sysclk) begin
  sdata_reg <= #1 sdata;
end


//// write data reg ////
always @ (posedge sysclk) begin
  if(sdram_state == ph2) begin
    case(slot1_type)
      CHIP : begin
        datawr <= #1 chipWR;
      end
      CPU_WRITECACHE : begin
        datawr <= #1 writebufferWR_reg;
      end
      default : begin
        datawr <= #1 hostWR;
      end
    endcase
  end else if(sdram_state == ph10) begin
    case(slot2_type)
      CHIP : begin
        datawr <= #1 chipWR;
      end
      CPU_WRITECACHE : begin
        datawr <= #1 writebufferWR_reg;
      end
      default : begin
        datawr <= #1 hostWR;
      end
    endcase
  end
end


//// write / read control ////
always @ (posedge sysclk) begin
  if(!reset_sdstate) begin
    sdwrite       <= #1 1'b0;
    enaRDreg      <= #1 1'b0;
    enaWRreg      <= #1 1'b0;
    ena7RDreg     <= #1 1'b0;
    ena7WRreg     <= #1 1'b0;
  end else begin
    sdwrite       <= #1 1'b0;
    enaRDreg      <= #1 1'b0;
    enaWRreg      <= #1 1'b0;
    ena7RDreg     <= #1 1'b0;
    ena7WRreg     <= #1 1'b0;
    case(sdram_state) // LATENCY=3
      ph2 : begin
        enaWRreg  <= #1 1'b1;
      end
      ph3 : begin
        sdwrite   <= #1 1'b1;
      end
      ph4 : begin
        sdwrite   <= #1 1'b1;
      end
      ph5 : begin
        sdwrite   <= #1 1'b1;
      end
      ph6 : begin
        enaWRreg  <= #1 1'b1;
        ena7RDreg <= #1 1'b1;
      end
      ph10 : begin
        enaWRreg  <= #1 1'b1;
      end
      ph11 : begin
        sdwrite   <= #1 1'b1; // access slot 2
      end
      ph12 : begin
        sdwrite   <= #1 1'b1;
      end
      ph13 : begin
        sdwrite   <= #1 1'b1;
      end
      ph14 : begin
        enaWRreg  <= #1 1'b1;
        ena7WRreg <= #1 1'b1;
      end
      default : begin
      end
    endcase
  end
end


//// init counter ////
always @ (posedge sysclk) begin
  if(!reset) begin
    initstate <= #1 {4{1'b0}};
    init_done <= #1 1'b0;
  end else begin
    case(sdram_state) // LATENCY=3
    ph15 : begin
      if(initstate != 4'b 1111) begin
        initstate <= #1 initstate + 4'd1;
      end else begin
        init_done <= #1 1'b1;
      end
    end
    default : begin
    end
    endcase
  end
end


//// sdram state ////
always @ (posedge sysclk) begin
  if(c_7mdr) begin
    sdram_state   <= #1 ph2;
  end else begin
    case(sdram_state) // LATENCY=3
      ph0     : sdram_state <= #1 ph1;
      ph1     : sdram_state <= #1 ph2;
      ph2     : sdram_state <= #1 ph3;
      ph3     : sdram_state <= #1 ph4;
      ph4     : sdram_state <= #1 ph5;
      ph5     : sdram_state <= #1 ph6;
      ph6     : sdram_state <= #1 ph7;
      ph7     : sdram_state <= #1 ph8;
      ph8     : sdram_state <= #1 ph9;
      ph9     : sdram_state <= #1 ph10;
      ph10    : sdram_state <= #1 ph11;
      ph11    : sdram_state <= #1 ph12;
      ph12    : sdram_state <= #1 ph13;
      ph13    : sdram_state <= #1 ph14;
      ph14    : sdram_state <= #1 ph15;
      default : sdram_state <= #1 ph0;
    endcase
  end
end


//// sdram control ////
// Address bits will be allocated as follows:
// 24 downto 23: bank
// 22 downto 10: row
// 9 downto 1: column
always @ (posedge sysclk) begin
  if(!reset) begin
    refresh_pending           <= #1 1'b0;
    slot1_type                <= #1 IDLE;
    slot2_type                <= #1 IDLE;
  end
  sd_cs                       <= #1 4'b1111;
  sd_ras                      <= #1 1'b1;
  sd_cas                      <= #1 1'b1;
  sd_we                       <= #1 1'b1;
  sdaddr                      <= #1 13'bxxxxxxxxxxxxx;
  ba                          <= #1 2'b00;
  dqm                         <= #1 2'b00;
  cache_fill_1                <= #1 1'b0;
  cache_fill_2                <= #1 1'b0;
  if(cpustate[5]) begin
    cena <= 1'b0;
  end
  if(!init_done) begin
    if(sdram_state == ph1) begin
      case(initstate)
        4'b0010 : begin // PRECHARGE
          sdaddr[10]          <= #1 1'b1; // all banks
          sd_cs               <= #1 4'b0000;
          sd_ras              <= #1 1'b0;
          sd_cas              <= #1 1'b1;
          sd_we               <= #1 1'b0;
        end
        4'b0011,
        4'b0100,
        4'b0101,
        4'b0110,
        4'b0111,
        4'b1000,
        4'b1001,
        4'b1010,
        4'b1011,
        4'b1100 : begin // AUTOREFRESH
          sd_cs               <= #1 4'b0000;
          sd_ras              <= #1 1'b0;
          sd_cas              <= #1 1'b0;
          sd_we               <= #1 1'b1;
        end
        4'b1101 : begin // LOAD MODE REGISTER
          sd_cs               <= #1 4'b0000;
          sd_ras              <= #1 1'b0;
          sd_cas              <= #1 1'b0;
          sd_we               <= #1 1'b0;
          //sdaddr              <= #1 13'b0001000100010; // BURST=4 LATENCY=2
          sdaddr              <= #1 13'b0001000110010; // BURST=4 LATENCY=3
          //sdaddr              <= #1 13'b0001000110000; // noBURST LATENCY=3
        end
        default : begin
          // NOP
        end
      endcase
    end
  end else begin
    // Time slot control
    case(sdram_state)
      ph0 : begin
        cache_fill_2          <= #1 1'b1; // slot 2
      end
      ph1 : begin
        cache_fill_2          <= #1 1'b1; // slot 2
        cas_sd_cs             <= #1 4'b1110;
        cas_sd_ras            <= #1 1'b1;
        cas_sd_cas            <= #1 1'b1;
        cas_sd_we             <= #1 1'b1;
        if(|hostslot_cnt) begin
          hostslot_cnt        <= #1 hostslot_cnt - 8'd1;
        end
        if(~|refreshcnt) begin
          refresh_pending     <= #1 1'b1;
        end else begin
          refreshcnt          <= #1 refreshcnt - 9'd1;
        end
        // we give the chipset first priority
        // (this includes anything on the "motherboard" - chip RAM, slow RAM and Kickstart, turbo modes notwithstanding)
        if(!chip_dma || !chipRW) begin
          slot1_type          <= #1 CHIP;
          sdaddr              <= #1 chipAddr[22:10];
          ba                  <= #1 2'b00; // always bank zero for chipset accesses, so we can interleave Fast RAM access
          slot1_bank          <= #1 2'b00;
          cas_dqm             <= #1 {chipU,chipL};
          sd_cs               <= #1 4'b1110; // ACTIVE
          sd_ras              <= #1 1'b0;
          casaddr             <= #1 {1'b0, chipAddr, 1'b0};
          cas_sd_cas          <= #1 1'b0;
          cas_sd_we           <= #1 chipRW;
        end
        // next in line is refresh
        // (a refresh cycle blocks both access slots)
        else if(refresh_pending && slot2_type == IDLE) begin
          sd_cs               <= #1 4'b0000; // AUTOREFRESH
          sd_ras              <= #1 1'b0;
          sd_cas              <= #1 1'b0;
          refreshcnt          <= #1 9'b111111111;
          slot1_type          <= #1 REFRESH;
          refresh_pending     <= #1 1'b0;
        end
        // the Amiga CPU gets next bite of the cherry, unless the OSD CPU has been cycle-starved
        // request from write buffer
        else if(writebuffer_req && (|hostslot_cnt || (hostState[2] || hostena)) && (slot2_type == IDLE || slot2_bank != writebufferAddr[24:23])) begin
          // We only yield to the OSD CPU if it's both cycle-starved and ready to go.
          slot1_type          <= #1 CPU_WRITECACHE;
          sdaddr              <= #1 writebufferAddr[22:10];
          ba                  <= #1 writebufferAddr[24:23];
          slot1_bank          <= #1 writebufferAddr[24:23];
          cas_dqm             <= #1 writebuffer_dqm;
          sd_cs               <= #1 4'b1110; // ACTIVE
          sd_ras              <= #1 1'b0;
          casaddr             <= #1 {writebufferAddr[24:1], 1'b0};
          cas_sd_we           <= #1 1'b0;
          writebufferWR_reg   <= #1 writebufferWR;
          cas_sd_cas          <= #1 1'b0;
          writebuffer_hold    <= #1 1'b1; // let the write buffer know we're about to write
        end
        // request from read cache
        else if(cache_req && (|hostslot_cnt || (hostState[2] || hostena)) && (slot2_type == IDLE || slot2_bank != cpuAddr_mangled[24:23])) begin
          // we only yield to the OSD CPU if it's both cycle-starved and ready to go
          slot1_type          <= #1 CPU_READCACHE;
          sdaddr              <= #1 cpuAddr_mangled[22:10];
          ba                  <= #1 cpuAddr_mangled[24:23];
          slot1_bank          <= #1 cpuAddr_mangled[24:23];
          cas_dqm             <= #1 {cpuU,cpuL};
          sd_cs               <= #1 4'b1110; // ACTIVE
          sd_ras              <= #1 1'b0;
          casaddr             <= #1 {cpuAddr_mangled[24:1], 1'b0};
          cas_sd_we           <= #1 1'b1;
          cas_sd_cas          <= #1 1'b0;
        end
        else if(!hostState[2] && !hostena) begin
          hostslot_cnt        <= #1 8'b00001111;
          slot1_type          <= #1 HOST;
          sdaddr              <= #1 zmAddr[22:10];
          ba                  <= #1 2'b00;
          // Always bank zero for SPI host CPU
          slot1_bank          <= #1 2'b00;
          cas_dqm             <= #1 {hostU,hostL};
          sd_cs               <= #1 4'b1110;
          // ACTIVE
          sd_ras              <= #1 1'b0;
          casaddr             <= #1 zmAddr;
          cas_sd_cas          <= #1 1'b0;
          if(hostState == 3'b011) begin
            cas_sd_we         <= #1 1'b0;
          end
        end
        else begin
          slot1_type          <= #1 IDLE;
        end
      end
      ph2 : begin
        // slot 2
        cache_fill_2          <= #1 1'b1;
      end
      ph3 : begin
        // slot 2
        cache_fill_2          <= #1 1'b1;
      end
      ph4 : begin
        sdaddr                <= #1 {1'b0, 1'b0, 1'b1, 1'b0, casaddr[9:1]}; // AUTO PRECHARGE
        ba                    <= #1 casaddr[24:23];
        sd_cs                 <= #1 cas_sd_cs;
        if(!cas_sd_we) begin
          dqm                 <= #1 cas_dqm;
        end
        sd_ras                <= #1 cas_sd_ras;
        sd_cas                <= #1 cas_sd_cas;
        sd_we                 <= #1 cas_sd_we;
        writebuffer_hold      <= #1 1'b0; // indicate to WriteBuffer that it's safe to accept the next write
      end
      ph8 : begin
        cache_fill_1          <= #1 1'b1;
      end
      ph9 : begin
        cache_fill_1          <= #1 1'b1;
        // Access slot 2, RAS
        cas_sd_cs             <= #1 4'b1110;
        cas_sd_ras            <= #1 1'b1;
        cas_sd_cas            <= #1 1'b1;
        cas_sd_we             <= #1 1'b1;
        slot2_type            <= #1 IDLE;
        if(!refresh_pending && slot1_type != REFRESH) begin
          if(writebuffer_req && |writebufferAddr[24:23] && (slot1_type == IDLE || slot1_bank != writebufferAddr[24:23])) begin // reserve bank 0 for slot 1
            // We only yield to the OSD CPU if it's both cycle-starved and ready to go.
            slot2_type        <= #1 CPU_WRITECACHE;
            sdaddr            <= #1 writebufferAddr[22:10];
            ba                <= #1 writebufferAddr[24:23];
            slot2_bank        <= #1 writebufferAddr[24:23];
            cas_dqm           <= #1 writebuffer_dqm;
            sd_cs             <= #1 4'b1110; // ACTIVE
            sd_ras            <= #1 1'b0;
            casaddr           <= #1 {writebufferAddr[24:1], 1'b0};
            cas_sd_we         <= #1 1'b0;
            writebufferWR_reg <= #1 writebufferWR;
            cas_sd_cas        <= #1 1'b0;
            writebuffer_hold  <= #1 1'b1; // let the write buffer know we're about to write
          end
          // request from read cache
          else if(cache_req && |cpuAddr[24:23] && (slot1_type == IDLE || slot1_bank != cpuAddr_mangled[24:23])) begin // reserve bank 0 for slot 1
            slot2_type        <= #1 CPU_READCACHE;
            sdaddr            <= #1 cpuAddr_mangled[22:10];
            ba                <= #1 cpuAddr_mangled[24:23];
            slot2_bank        <= #1 cpuAddr_mangled[24:23];
            cas_dqm           <= #1 {cpuU, cpuL};
            sd_cs             <= #1 4'b1110; // ACTIVE
            sd_ras            <= #1 1'b0;
            casaddr           <= #1 {cpuAddr_mangled[24:1], 1'b0};
            cas_sd_we         <= #1 1'b1;
            cas_sd_cas        <= #1 1'b0;
          end
        end
      end
      ph10 : begin
        cache_fill_1          <= #1 1'b1;
      end
      ph11 : begin
        cache_fill_1          <= #1 1'b1;
      end
      // slot 2 CAS
      ph12 : begin
        sdaddr <= #1 {1'b0, 1'b0, 1'b1, 1'b0, casaddr[9:1]}; // AUTO PRECHARGE
        ba                    <= #1 casaddr[24:23];
        sd_cs                 <= #1 cas_sd_cs;
        if(!cas_sd_we) begin
          dqm                 <= #1 cas_dqm;
        end
        sd_ras                <= #1 cas_sd_ras;
        sd_cas                <= #1 cas_sd_cas;
        sd_we                 <= #1 cas_sd_we;
        writebuffer_hold      <= #1 1'b0; // indicate to WriteBuffer that it's safe to accept the next write
      end
      default : begin
      end
    endcase
  end
end


//// slots ////
//        Slot 1                    Slot 2
// ph0    (read)                    (Read 0 in sdata)
// ph1    Slot alloc, RAS (read)    Read0
// ph2    ... (read)                Read1
// ph3    ... (write)               Read2 (read3 in sdata)
// ph4    CAS, write0 (write)       Read3
// ph5    write1 (write)
// ph6    write2 (write)
// ph7    write3 (read)
// ph8    (read0 in sdata) (rd)
// ph9    read0 in sdata_reg (rd)   Slot alloc, RAS
// ph10   read1  (read)             ...
// ph11   read2 (rd3 in sdata, wr)  ...
// ph12   read3 (write)             CAS, write 0
// ph13   (write)                   write1
// ph14   (write)                   write2
// ph15   (read)                    write3


endmodule


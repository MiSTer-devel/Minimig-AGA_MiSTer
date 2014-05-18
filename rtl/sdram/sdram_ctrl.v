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
// 2013-02-12 - converted to Verilog
//            - cleanup
//            - code simplification
//            - added two-lines cache


module sdram_ctrl(
  // system
  input  wire           sysclk,
  input  wire           c_7m,
  input  wire           reset_in,
  input  wire           cache_rst,
  output wire           reset_out,
  // temp - cache control
  input wire            cache_ena,
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
  input  wire           host_cs,
  input  wire [ 24-1:0] host_adr,
  input  wire           host_we,
  input  wire [  2-1:0] host_bs,
  input  wire [ 16-1:0] host_wdat,
  output reg  [ 16-1:0] host_rdat,
  output wire           host_ack,
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
  output wire [ 16-1:0] cpuRD,
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
reg            zena;
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

always @ (posedge sysclk or negedge reset_in) begin
  if (~reset_in) begin
    reset_cnt <= 8'b00000000;
    reset <= 1'b0;
    reset_sdstate <= 1'b0;
  end else begin
    if (reset_cnt == 8'b00101010) begin
      reset_sdstate <= 1'b1;
    end
    if (reset_cnt == 8'b10101010) begin
      if (sdram_state == ph15) begin
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
// host access
////////////////////////////////////////

assign host_ack = zena;

always @ (posedge sysclk or negedge reset) begin
  if (~reset) begin
    zena <= 1'b0;
  end else begin
    if (enaWRreg && zena) begin
      zena <= #1 1'b0;
    end 
    if ((sdram_state == ph11) && hostCycle) begin
      if ((host_adr == casaddr[23:0]) && !cas_sd_cas) begin
        zena <= #1 1'b1;
      end
    end
  end
end

always @ (posedge sysclk) begin
  if ((sdram_state == ph9) && hostCycle) begin
    host_rdat <= sdata_reg;
  end
end


////////////////////////////////////////
// cpu cache
////////////////////////////////////////

// CPU bus register
reg     [24:1] cpuAddr_reg = 0;
reg  [  6-1:0] cpustate_reg = 0;
reg            cpuL_reg = 0;
reg            cpuU_reg = 0;
reg            cpu_dma_reg = 0;
reg  [ 16-1:0] cpuWR_reg = 0;
//  output wire [ 16-1:0] cpuRD,
//  output reg            enaWRreg,
//  output reg            ena7RDreg,
//  output reg            ena7WRreg,
//  output wire           cpuena

always @ (posedge sysclk) begin
  cpuWR_reg <= #1 cpuWR;
end

wire cache_ack;
assign cpuena = cache_ack || (cpustate[1:0] == 2'b01);

cpu_cache cpu_cache (
  // system
  .clk          (sysclk       ),
  .rst          (!(reset && cache_rst)),
  .cache_ena    (cache_ena    ),
  // cpu if
  .cpu_state    (cpustate     ),
  .cpu_adr      (cpuAddr      ),
  .cpu_bs       ({cpuU, cpuL} ),
  .cpu_dat_w    (cpuWR        ),
  .cpu_dat_r    (cpuRD        ),
  .cpu_ack      (cache_ack    ),
  // sdram if
  .sdr_state    (sdram_state  ),
  .sdr_adr      (casaddr      ),
  .sdr_cpucycle (cpuCycle     ),
  .sdr_cas      (cas_sd_cas   ),
  .sdr_dat_w    (             ),
  .sdr_dat_r    (sdata_reg    ),
  .sdr_cpu_act  (             )
);


/*
assign cpuena = cena || ccachehit || (cpustate[1:0] == 2'b01);

always @ (posedge sysclk or negedge reset) begin
  if (~reset) begin
    cena <= 1'b0;
  end else begin
    if (cpustate[5]) begin
      cena <= 1'b0;
    end
    if (sdram_state == ph11 && cpuCycle) begin
      if (cpuAddr == casaddr[24:1] && !cas_sd_cas) begin
        cena <= 1'b1;
      end
    end
  end
end

reg  [ 16-1:0] cpu_cache_dat0[0:4-1];
reg  [ 16-1:0] cpu_cache_dat1[0:4-1];
wire [  2-1:0] cpu_cache_index0, cpu_cache_index1;

reg  [ 64-1:0] ccache0, ccache1;
reg  [ 25-1:0] ccache_addr0, ccache_addr1;
reg            ccache_fill0, ccache_fill1;
reg  [  4-1:0] cvalid0, cvalid1;
wire           cequal0, cequal1;

assign cequal0 = (cpuAddr[24:3] == ccache_addr0[24:3]);
assign cequal1 = (cpuAddr[24:3] == ccache_addr1[24:3]);
assign cpu_cache_index0 = (cpuAddr[2:1] - ccache_addr0[2:1]);
assign cpu_cache_index1 = (cpuAddr[2:1] - ccache_addr1[2:1]);

always @ (posedge sysclk) cpustated <= cpustate[1:0];

// cpu cache fill
always @ (posedge sysclk or negedge reset) begin
  if (~reset) begin
    ccache_fill0 <= 1'b0;
    ccache_fill1 <= 1'b0;
    cvalid0 <= 4'b0000;
    cvalid1 <= 4'b0000;
  end else begin
    if ((cpustate[1:0] == 2'b11)) begin
      if (cequal0) cvalid0 <= 4'b0000;
      if (cequal1) cvalid1 <= 4'b0000;
    end
    // only instruction cache
    if ((sdram_state == ph7) && (cpustate[0:0] == 1'b0) && cpuCycle) begin
      if (!casaddr[3] && !cequal0) begin
        ccache_addr0 <= casaddr;
        ccache_fill0 <= 1'b1;
        cvalid0 <= 4'b0000;
      end
      if (casaddr[3] && !cequal1) begin
        ccache_addr1 <= casaddr;
        ccache_fill1 <= 1'b1;
        cvalid1 <= 4'b0000;
      end
    end
    if (ccache_fill0) begin
      case (sdram_state)
        ph9  : begin cpu_cache_dat0[0] <= sdata_reg; cvalid0[0] <= 1'b1; end
        ph10 : begin cpu_cache_dat0[1] <= sdata_reg; cvalid0[1] <= 1'b1; end
        ph11 : begin cpu_cache_dat0[2] <= sdata_reg; cvalid0[2] <= 1'b1; end
        ph12 : begin cpu_cache_dat0[3] <= sdata_reg; cvalid0[3] <= 1'b1; ccache_fill0 <= 1'b0; end
      endcase
    end else if ((cpustate[1:0] == 2'b11) && cequal0) begin
      cvalid0[cpu_cache_index0] <= 1'b0;
    end
    if (ccache_fill1) begin
      case (sdram_state)
        ph9  : begin cpu_cache_dat1[0] <= sdata_reg; cvalid1[0] <= 1'b1; end
        ph10 : begin cpu_cache_dat1[1] <= sdata_reg; cvalid1[1] <= 1'b1; end
        ph11 : begin cpu_cache_dat1[2] <= sdata_reg; cvalid1[2] <= 1'b1; end
        ph12 : begin cpu_cache_dat1[3] <= sdata_reg; cvalid1[3] <= 1'b1; ccache_fill1 <= 1'b0; end
      endcase
    end else if ((cpustate[1:0] == 2'b11) && cequal1) begin
      cvalid1[cpu_cache_index1] <= 1'b0;
    end
  end
end

always @ (posedge sysclk) begin
  if ((sdram_state == ph9) && cpuCycle)
    cpuRDd <= sdata_reg;
end

// cpu cache read
reg [15:0] cpuRD_reg = 0;
always @ (*) begin
  if (cctrl[2] && cequal0 && &cvalid0 && (cpustate[0:0] == 1'b0)) begin
    ccachehit = cvalid0[cpu_cache_index0];
    cpuRD_reg = cpu_cache_dat0[cpu_cache_index0];
  end else if (cctrl[2] && cequal1 && &cvalid1 && (cpustate[0:0] == 1'b0)) begin
    ccachehit = cvalid1[cpu_cache_index1];
    cpuRD_reg = cpu_cache_dat1[cpu_cache_index1];
  end else begin
    ccachehit = 1'b0;
    cpuRD_reg = cpuRDd;
  end
end
assign cpuRD = cpuRD_reg;
*/



////////////////////////////////////////
// chip cache
////////////////////////////////////////

reg  [ 16-1:0] chipRDd;
/*
reg  [ 16-1:0] chip_cache_dat [0:4-1];
reg  [ 24-1:0] chip_cache_adr;
reg            chip_cache_fill;
reg  [  4-1:0] chip_cache_valid;
wire           chip_cache_equal;
wire [  2-1:0] chip_cache_index;
wire           chip_cache_range;

assign chip_cache_equal = (chipAddr[23:3] == chip_cache_adr[23:3]);
assign chip_cache_index = (chipAddr[2:1] - chip_cache_adr[2:1]);
// only cache kickstart area
assign chip_cache_range = (chipAddr[21:19] == 3'b011);

// chip cache fill
always @ (posedge sysclk or negedge reset) begin
  if (~reset) begin
    chip_cache_fill <= 1'b0;
    chip_cache_valid <= 4'b0000;
  end else begin
    if ((sdram_state == ph7) && !chip_dma && chipCycle && !chip_cache_equal && chip_cache_range) begin
      chip_cache_adr <= #1 casaddr[23:0];
      chip_cache_fill <= #1 1'b1;
      chip_cache_valid <= #1 4'b0000;
    end
    if (chip_cache_fill) begin
      case (sdram_state)
        ph9  : begin chip_cache_dat[0] <= sdata_reg; chip_cache_valid[0] <= 1'b1; end
        ph10 : begin chip_cache_dat[1] <= sdata_reg; chip_cache_valid[1] <= 1'b1; end
        ph11 : begin chip_cache_dat[2] <= sdata_reg; chip_cache_valid[2] <= 1'b1; end
        ph12 : begin chip_cache_dat[3] <= sdata_reg; chip_cache_valid[3] <= 1'b1; chip_cache_fill <= 1'b0; end
      endcase
    end else if ((sdram_state == ph9) && chip_cache_equal && !chipRW && &chip_cache_valid) begin
      chip_cache_valid <= 4'b0000;
    end
  end
end
*/

always @ (posedge sysclk) begin
  if ((sdram_state == ph9) && chipCycle)
    chipRDd <= sdata_reg;
end

// chip cache read
always @ (*) begin
/*  if (cctrl[0] && chip_cache_equal && &chip_cache_valid)
    chipRD = chip_cache_dat[chip_cache_index];
  else
*/
    chipRD = chipRDd;
end


////////////////////////////////////////
// SDRAM control
////////////////////////////////////////

// clock mangling - TODO
always @ (negedge sysclk) begin
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
always @ (posedge sysclk) begin
  if (sdram_state == ph2) begin
    if (chipCycle) begin
      datawr <= chipWR;
    end else if (cpuCycle) begin
      datawr <= cpuWR;
    end else begin
      datawr <= host_wdat;
    end
  end
end

// write / read control
always @ (posedge sysclk or negedge reset_sdstate) begin
  if (~reset_sdstate) begin
    sdwrite   <= 1'b0;
    enaWRreg  <= 1'b0;
    ena7RDreg <= 1'b0;
    ena7WRreg <= 1'b0;
  end else begin
    case (sdram_state) // LATENCY=3
      ph2 : begin
        sdwrite   <= 1'b1;
        enaWRreg  <= 1'b1;
        ena7RDreg <= 1'b0;
        ena7WRreg <= 1'b0;
      end
      ph3 : begin
        sdwrite   <= 1'b1;
        enaWRreg  <= 1'b0;
        ena7RDreg <= 1'b0;
        ena7WRreg <= 1'b0;
      end
      ph4 : begin
        sdwrite   <= 1'b1;
        enaWRreg  <= 1'b0;
        ena7RDreg <= 1'b0;
        ena7WRreg <= 1'b0;
      end
      ph5 : begin
        sdwrite   <= 1'b1;
        enaWRreg  <= 1'b0;
        ena7RDreg <= 1'b0;
        ena7WRreg <= 1'b0;
      end
      ph6 : begin
        sdwrite   <= 1'b0;
        enaWRreg  <= 1'b1;
        ena7RDreg <= 1'b1;
        ena7WRreg <= 1'b0;
      end
      ph10 : begin
        sdwrite   <= 1'b0;
        enaWRreg  <= 1'b1;
        ena7RDreg <= 1'b0;
        ena7WRreg <= 1'b0;
      end
      ph14 : begin
        sdwrite   <= 1'b0;
        enaWRreg  <= 1'b1;
        ena7RDreg <= 1'b0;
        ena7WRreg <= 1'b1;
      end
      default : begin
        sdwrite   <= 1'b0;
        enaWRreg  <= 1'b0;
        ena7RDreg <= 1'b0;
        ena7WRreg <= 1'b0;
      end
    endcase
  end
end

// init counter
always @ (posedge sysclk or negedge reset) begin
  if (~reset) begin
    initstate <= {4{1'b0}};
    init_done <= 1'b0;
  end else begin
    case (sdram_state) // LATENCY=3
      ph15 : begin
        if (initstate != 4'b1111) begin
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
always @ (posedge sysclk) begin
  if (c_7mdr) begin
    sdram_state <= ph2;
  end else begin
    case (sdram_state) // LATENCY=3
      ph0     : begin
        sdram_state <= ph1;
      end
      ph1     : begin
        sdram_state <= ph2;
      end
      ph2     : begin
        sdram_state <= ph3;
      end
      ph3     : begin
        sdram_state <= ph4;
      end
      ph4     : begin
        sdram_state <= ph5;
      end
      ph5     : begin
        sdram_state <= ph6;
      end
      ph6     : begin
        sdram_state <= ph7;
      end
      ph7     : begin
        sdram_state <= ph8;
      end
      ph8     : begin
        sdram_state <= ph9;
      end
      ph9     : begin
        sdram_state <= ph10;
      end
      ph10    : begin
        sdram_state <= ph11;
      end
      ph11    : begin
        sdram_state <= ph12;
      end
      ph12    : begin
        sdram_state <= ph13;
      end
      ph13    : begin
        sdram_state <= ph14;
      end
      ph14    : begin
        sdram_state <= ph15;
      end
      default : begin
        sdram_state <= ph0;
      end
    endcase
  end
end

// sdram control
always @ (posedge sysclk) begin
  sd_cs  <= 4'b1111;
  sd_ras <= 1'b1;
  sd_cas <= 1'b1;
  sd_we  <= 1'b1;
  sdaddr <= 12'bxxxxxxxxxxxx;
  ba     <= 2'b00;
  dqm    <= 2'b00;
  if (!init_done) begin
    if (sdram_state == ph1) begin
      case (initstate)
      4'b0010 : begin
        //PRECHARGE
        sdaddr[10] <= 1'b1;
        //all banks
        sd_cs  <= 4'b0000;
        sd_ras <= 1'b0;
        sd_cas <= 1'b1;
        sd_we  <= 1'b0;
      end
      4'b0011,4'b0100,4'b0101,4'b0110,4'b0111,4'b1000,4'b1001,4'b1010,4'b1011,4'b1100 : begin
        //AUTOREFRESH
        sd_cs  <= 4'b0000;
        sd_ras <= 1'b0;
        sd_cas <= 1'b0;
        sd_we  <= 1'b1;
      end
      4'b1101 : begin
        //LOAD MODE REGISTER
        sd_cs  <= 4'b0000;
        sd_ras <= 1'b0;
        sd_cas <= 1'b0;
        sd_we  <= 1'b0;
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
    if (sdram_state == ph1) begin
      cpuCycle   <= 1'b0;
      chipCycle  <= 1'b0;
      hostCycle  <= 1'b0;
      cas_sd_cs  <= 4'b1110;
      cas_sd_ras <= 1'b1;
      cas_sd_cas <= 1'b1;
      cas_sd_we  <= 1'b1;
      //if ((!(cctrl[0] && chip_cache_equal && &chip_cache_valid) && (!chip_dma)) || !chipRW) begin
      if (!chip_dma || !chipRW) begin
        // chip cycle
        chipCycle  <= 1'b1;
        sdaddr     <= chipAddr[20:9];
        ba         <= chipAddr[22:21];
        cas_dqm    <= {chipU,chipL};
        sd_cs      <= 4'b1110; // active
        sd_ras     <= 1'b0;
        casaddr    <= {1'b0,chipAddr,1'b0};
        cas_sd_cas <= 1'b0;
        cas_sd_we  <= chipRW;
      end else if (!cpustate[2] && !cpustate[5]) begin
        // cpu cycle
        cpuCycle   <= 1'b1;
        sdaddr     <= cpuAddr[20:9];
        ba         <= cpuAddr[22:21];
        cas_dqm    <= {cpuU,cpuL};
        sd_cs      <= 4'b1110; // active
        sd_ras     <= 1'b0;
        casaddr    <= {cpuAddr[24:1],1'b0};
        cas_sd_cas <= 1'b0;
        cas_sd_we  <= ~cpustate[1] | ~cpustate[0];
      end else if (host_cs && !host_ack) begin
        // host cycle
        hostCycle  <= 1'b1;
        sdaddr     <= host_adr[20:9];
        ba         <= host_adr[22:21];
        cas_dqm    <= ~host_bs;
        sd_cs      <= 4'b1110; // active
        sd_ras     <= 1'b0;
        casaddr    <= {1'b0, host_adr};
        cas_sd_cas <= 1'b0;
        cas_sd_we  <= !host_we;
      end else begin
        // refresh cycle
        sd_cs      <= 4'b0000; // autorefresh
        sd_ras     <= 1'b0;
        sd_cas     <= 1'b0;
      end
    end
    if (sdram_state == ph4) begin
      sdaddr  <= {1'b0,1'b1,1'b0,casaddr[23],casaddr[8:1]}; // auto precharge
      ba      <= casaddr[22:21];
      sd_cs   <= cas_sd_cs;
      dqm     <= (!cas_sd_we) ? cas_dqm : 2'b00;
      sd_ras  <= cas_sd_ras;
      sd_cas  <= cas_sd_cas;
      sd_we   <= cas_sd_we;
    end
  end
end


endmodule


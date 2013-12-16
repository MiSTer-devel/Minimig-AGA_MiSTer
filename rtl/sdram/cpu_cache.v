// cpu_cache.v
// 2013, rok.krajnc@gmail.com
// this is a simple 2-way set-asociative cache
// write-through, look-through
// 2kB data cache size, 1kB per way
// with write buffer
// uses five M4K blocks in Cyclone II
// ! requires Altera Quartus prepared memories because of the byte-selects !


module cpu_cache (
  // system
  input  wire           clk,          // clock (CPU)
  input  wire           rst,          // reset (CPU)
  // cpu
  input  wire [  6-1:0] cpu_state,    // CPU state
  input  wire           cpu_cs,       // CPU state[2], or cpuDMA (sel_fast)
  input  wire [ 25-1:1] cpu_adr,      // CPU address
  input  wire [  2-1:0] cpu_bs,       // CPU byte selects
  input  wire [ 16-1:0] cpu_dat_w,    // CPU write data
  output reg  [ 16-1:0] cpu_dat_r,    // CPU read data
  output wire           cpu_ack,      // CPU cpuena
  // sdram controller
  input  wire [  4-1:0] sdr_state,    // SDRAM state
  input  wire [ 25-1:0] sdr_adr,      // SDRAM address
  input  wire           sdr_cpucycle, // SDRAM CPU got the cycle
  input  wire           sdr_cas,      // SDRAM cas
  input  wire [ 16-1:0] sdr_dat_r,    // SDRAM read data
  output wire [ 16-1:0] sdr_dat_w,    // SDRAM write data
  output wire           sdr_cpu_act   // SDRAM CPU requires access
);


//// internal signals ////
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


//// cache control state machine ////
reg           state;
reg  [ 9-1:0] st_adr;
reg           st_tag_we;
reg  [32-1:0] st_tag_dat_w;
reg           st_mem_we_0;
reg           st_mem_we_1;
reg  [ 2-1:0] st_mem_bs;
reg  [16-1:0] st_mem_dat_w;

always @ (posedge clk) begin
  if (reset) begin
    state         <= #1 ST_INIT;
    st_adr        <= #1 9'd0;
    st_tag_we     <= #1 1'b1;
    st_tag_dat_w  <= #1 32'd0;
    st_mem_we_0   <= #1 1'b1;
    st_mem_we_1   <= #1 1'b1;
    st_mem_bs     <= #1 2'b11;
    st_mem_dat_w  <= #1 16'd0;
  end else begin
    state         <= #1 ST_IDLE;
    st_adr        <= #1 {adr_idx, adr_blk};
    st_tag_we     <= #1 1'b0;
    st_tag_dat_w  <= #1 32'd0;
    st_mem_we_0   <= #1 1'b0;
    st_mem_we_1   <= #1 1'b0;
    st_mem_bs     <= #1 2'b11;
    st_mem_dat_w  <= #1 16'd0;
    case (state)
      ST_INIT : begin
        // clear cache, should be done on every CPU reset
        st_adr <= #1 st_adr + 9'd1;
        st_tag_we <= #1 1'b1;
        st_mem_we_0 <= #1 1'b1;
        st_mem_we_1 <= #1 1'b1;
        if (&st_adr) state <= #1 ST_IDLE;
        else state <= #1 ST_INIT;
      end
      ST_IDLE : begin
        if (cpu_cs) begin
          if (cpu_wr) state <= #1 ST_CPU_WRITE;
          else if (cpu_rd) state <= #1 ST_CPU_READ;
        end
      end
      ST_CPU_WRITE : begin
        // on hit, update cache
        st_mem_bs <= #1 cpu_bs; // TODO active low or active high?? if done like this, signals from CPU shold be inverted!
        st_mem_dat_w <= #1 cpu_dat_w;
        st_mem_we_0 <= #1 tag_w0_match;
        st_mem_we_1 <= #1 tag_w1_match;
        // on miss, no update neccessary
      end
      ST_CPU_READ : begin
        // on hit, update LRU flag in tag memory
        if (tag_w0_match) begin
          st_tag_we <= #1 1'b1;
          st_tag_dat_w <= #1 {1'b0, tag_dat_r[30:0]};
        end else if (tag_w1_match) begin
          st_tag_we <= #1 1'b1;
          st_tag_dat_w <= #1 {1'b1, tag_dat_r[30:0]};
        end else begin
          // on miss, fetch data from SDRAM & update tag
          st_lru <= #1 !tag_lru;
        end
      end
    endcase    
  end
end


//// CPU logic ////

// decoding cpu write / read request
// 00-> fetch code 10->read data 11->write data 01->no memaccess
assign cpu_wr = &cpu_state[1:0];
assign cpu_rd = !cpu_state[0];

// slice up cpu address
assign [ 2-1:0] adr_blk = cpu_adr[2:1];
assign [ 7-1:0] adr_idx = cpu_adr[9:3];
assign [15-1:0] adr_tag = cpu_adr[24:10];

// CPU read register
always @ (posedge clk) begin
  if (w0_tag_match && (state_r == ST_CHECK))
    cpu_dat_r <= #1 w0_dat_r;
  else if (w1_tag_match && (state_r == ST_CHECK))
    cpu_dat_r <= #1 w1_dat_r;
  else if (sdr_cpucycle && (sdr_state == ph9))
    cpu_dat_r <= #1 sdr_dat_r;
end


//// tag RAM ////
wire [ 7-1:0] tag_wadr;
wire [ 7-1:0] tag_radr;
wire          tag_we;
wire [32-1:0] tag_dat_w;
wire [32-1:0] tag_dat_r;
wire          tag_lru;
wire          tag_w0_match;
wire          tag_w1_match;
wire          tag_hit;

assign tag_radr     = adr_idx;
assign tag_wadr     = st_adr[7:0];
assign tag_dat_w    = st_tag_dat_w;
assign tag_we       = st_tag_we;
assign tag_w0_match = (adr_tag == tag_dat_r[15-1: 0]);
assign tag_w1_match = (adr_tag == tag_dat_r[30:16]);
assign tag_hit      = tag_w0_match || tag_w1_match;
assign tag_lru      = tag_dat_r[31];

`ifdef SOC_SIM
tpram_inf_128x32
`else
tpram_128x32
`endif
tag_ram (
  .clock      (clk        ),
  .wraddress  (tag_wadr   ),
  .wren       (tag_we     ),
  .data       (tag_dat_w  ),
  .rdaddress  (tag_radr   ),
  .q          (tag_dat_r  )
);


//// data RAM ////
wire [ 9-1:0] mem_wadr;
wire [ 9-1:0] mem_radr;
wire          mem_we_0;
wire          mem_we_1;
wire [ 2-1:0] mem_bs;
wire [16-1:0] mem_dat_w;
wire [16-1:0] mem_dat_r_0;
wire [16-1:0] mem_dat_r_1;

assign mem_radr   = {adr_idx, adr_blk};
assign mem_wadr   = st_adr;
assign mem_dat_w  = st_mem_dat_w;
assign mem_we_0   = st_mem_we_0;
assign mem_we_1   = st_mem_we_1;
assign mem_bs     = st_mem_bs;

`ifdef SOC_SIM
tpram_inf_be_512x16
`else
tpram_be_512x16
`endif
mem_ram_0 (
  .clock      (clk        ),
  .wraddress  (mem_wadr   ),
  .wren       (mem0_we_0  ),
  .byteena_a  (mem_bs     ),
  .data       (mem_dat_w  ),
  .rdaddress  (mem_radr   ),
  .q          (mem_dat_r_0)
);

`ifdef SOC_SIM
tpram_inf_be_512x16
`else
tpram_be_512x16
`endif
mem_ram_1 (
  .clock      (clk        ),
  .wraddress  (mem_wadr   ),
  .wren       (mem_we_1   ),
  .byteena_a  (mem_bs     ),
  .data       (mem_dat_w  ),
  .rdaddress  (mem_radr   ),
  .q          (mem_dat_r_1)
);





endmodule




////////////////////////////////////////
// cpu cache
////////////////////////////////////////

reg  [ 16-1:0] cpu_cache_dat0[0:4-1];
reg  [ 16-1:0] cpu_cache_dat1[0:4-1];
wire [  2-1:0] cpu_cache_index0, cpu_cache_index1;

reg  [ 64-1:0] ccache0, ccache1;
reg  [ 25-1:0] ccache_addr0, ccache_addr1;
reg            ccache_fill0, ccache_fill1;
reg  [  4-1:0] cvalid0, cvalid1;
wire           cequal0, cequal1;

assign cpuena = cena || ccachehit || (cpustate[1:0] == 2'b01);
assign cequal0 = (cpuAddr[24:3] == ccache_addr0[24:3]);
assign cequal1 = (cpuAddr[24:3] == ccache_addr1[24:3]);
assign cpu_cache_index0 = (cpuAddr[2:1] - ccache_addr0[2:1]);
assign cpu_cache_index1 = (cpuAddr[2:1] - ccache_addr1[2:1]);

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
    if ((sdram_state == ph7) && /*!cpustated[1]*/ (cpustate[0:0] == 1'b0) && cpuCycle) begin
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
      //cvalid0 <= 4'b0000;
      cvalid0[cpu_cache_index0] <= 1'b0;
      //cpu_cache_dat0[cpu_cache_index0] <= ({{8{cpuU}}, {8{cpuL}}} & cpu_cache_dat0[cpu_cache_index0]) | ({{8{!cpuU}}, {8{!cpuL}}} & cpuWR);
    end
    if (ccache_fill1) begin
      case (sdram_state)
        ph9  : begin cpu_cache_dat1[0] <= sdata_reg; cvalid1[0] <= 1'b1; end
        ph10 : begin cpu_cache_dat1[1] <= sdata_reg; cvalid1[1] <= 1'b1; end
        ph11 : begin cpu_cache_dat1[2] <= sdata_reg; cvalid1[2] <= 1'b1; end
        ph12 : begin cpu_cache_dat1[3] <= sdata_reg; cvalid1[3] <= 1'b1; ccache_fill1 <= 1'b0; end
      endcase
    end else if ((cpustate[1:0] == 2'b11) && cequal1) begin
      //cvalid1 <= 4'b0000;
      cvalid1[cpu_cache_index1] <= 1'b0;
      //cpu_cache_dat1[cpu_cache_index1] <= ({{8{cpuU}}, {8{cpuL}}} & cpu_cache_dat1[cpu_cache_index1]) | ({{8{!cpuU}}, {8{!cpuL}}} & cpuWR);
    end
  end
end

always @ (posedge sysclk) begin
  if ((sdram_state == ph9) && cpuCycle)
    cpuRDd <= sdata_reg;
end

// cpu cache read
always @ (*) begin
  if (cctrl[2] && cequal0 && &cvalid0 && /*!cpustated[1]*/ (cpustate[0:0] == 1'b0)) begin
    ccachehit = cvalid0[cpu_cache_index0];
    cpuRD = cpu_cache_dat0[cpu_cache_index0];
  end else if (cctrl[2] && cequal1 && &cvalid1 && /*!cpustated[1]*/ (cpustate[0:0] == 1'b0)) begin
    ccachehit = cvalid1[cpu_cache_index1];
    cpuRD = cpu_cache_dat1[cpu_cache_index1];
  end else begin
    ccachehit = 1'b0;
    cpuRD = cpuRDd;
  end
end




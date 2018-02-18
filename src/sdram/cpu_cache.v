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
  input  wire           cache_ena,    // cache control
  // cpu
  input  wire [  6-1:0] cpu_state,    // CPU state
  input  wire [ 25-1:1] cpu_adr,      // CPU address
  input  wire [  2-1:0] cpu_bs,       // CPU byte selects
  input  wire [ 16-1:0] cpu_dat_w,    // CPU write data
  output reg  [ 16-1:0] cpu_dat_r,    // CPU read data
  output reg            cpu_ack,      // CPU cpuena
  // sdram controller
  input  wire [  4-1:0] sdr_state,    // SDRAM state
  input  wire [ 25-1:0] sdr_adr,      // SDRAM address
  input  wire           sdr_cpucycle, // SDRAM CPU got the cycle
  input  wire           sdr_cas,      // SDRAM cas
  input  wire [ 16-1:0] sdr_dat_r,    // SDRAM read data
  output wire [ 16-1:0] sdr_dat_w,    // SDRAM write data
  output wire           sdr_cpu_act   // SDRAM CPU requires access
);


//// params ////

// cache states
localparam [2:0]
  ST_INIT       = 3'd0,
  ST_IDLE       = 3'd1,
  ST_PREP       = 3'd2,
  ST_CPU_WRITE  = 3'd3,
  ST_CPU_READ   = 3'd4,
  ST_FILL       = 3'd5;

// SDRAM states
localparam [3:0]
  ph0  = 4'd0,
  ph1  = 4'd1,
  ph2  = 4'd2,
  ph3  = 4'd3,
  ph4  = 4'd4,
  ph5  = 4'd5,
  ph6  = 4'd6,
  ph7  = 4'd7,
  ph8  = 4'd8,
  ph9  = 4'd9,
  ph10 = 4'd10,
  ph11 = 4'd11,
  ph12 = 4'd12,
  ph13 = 4'd13,
  ph14 = 4'd14,
  ph15 = 4'd15;


//// internal signals ////
reg  [ 6-1:0] cpu_state_r = 0;
reg  [25-1:1] cpu_adr_r = 0;
reg  [ 2-1:0] cpu_bs_r = 0;
reg  [16-1:0] cpu_dat_w_r = 0;
reg  [16-1:0] sdr_dat_r_r = 0;

wire          cpu_cs;
wire          cpu_rw;
wire          cpu_wr;
wire          cpu_rd;
wire [ 2-1:0] adr_blk;
wire [ 7-1:0] adr_idx;
wire [15-1:0] adr_tag;

reg  [ 3-1:0] state = 0;
reg  [ 9-1:0] st_adr = 0;
reg           st_lru = 0;
reg           st_tag_we = 0;
reg  [32-1:0] st_tag_dat_w = 0;
reg           st_mem_we_0 = 0;
reg           st_mem_we_1 = 0;
reg  [ 2-1:0] st_mem_bs = 0;
reg  [16-1:0] st_mem_dat_w = 0;

wire [ 7-1:0] tag_wadr;
wire [ 7-1:0] tag_radr;
wire          tag_we;
wire [32-1:0] tag_dat_w;
wire [32-1:0] tag_dat_r;
reg  [32-1:0] tag_dat_r_reg;
wire          tag_lru;
wire          tag_w0_match;
wire          tag_w1_match;
wire          tag_hit;

wire [ 9-1:0] mem_wadr;
wire [ 9-1:0] mem_radr;
wire          mem_we_0;
wire          mem_we_1;
wire [ 2-1:0] mem_bs;
wire [16-1:0] mem_dat_w;
wire [16-1:0] mem_dat_r_0;
wire [16-1:0] mem_dat_r_1;
reg  [16-1:0] mem_dat_r_0_reg;
reg  [16-1:0] mem_dat_r_1_reg;


//// CPU logic ////

// register CPU bus
always @ (posedge clk) begin
  if (rst) begin
    cpu_state_r <= #1 6'b111111;
  end else if (state == ST_IDLE) begin
    cpu_state_r <= #1 cpu_state;
  end
end

always @ (posedge clk) begin
  if (state == ST_IDLE) begin
    cpu_adr_r   <= #1 cpu_adr;
    cpu_bs_r    <= #1 cpu_bs;
    cpu_dat_w_r <= #1 cpu_dat_w;
  end
end

always @ (posedge clk) begin
  sdr_dat_r_r <= #1 sdr_dat_r;
end

// decode cpu control signals
// 00-> fetch code 10->read data 11->write data 01->no memaccess
//assign cpu_cs = !cpu_state[2] && !cpu_state[5] && (cpu_state[1:0] != 2'b01);
assign cpu_cs = !cpu_state[2];
assign cpu_rw = !cpu_state[1] | !cpu_state[0];
assign cpu_wr = &cpu_state[1:0];
//assign cpu_rd = !cpu_state[0];
assign cpu_rd = cpu_state[1:0] == 2'b00; // instruction
//assign cpu_rd = cpu_state[1:0] == 2'b10; // data
//assign cpu_rd = 0;

// slice up cpu address
assign adr_blk = cpu_adr[2:1];
assign adr_idx = cpu_adr[9:3];
assign adr_tag = cpu_adr[24:10];

// CPU read register
always @ (posedge clk) begin
  if (cache_ena && cpu_cs && tag_w0_match && (state == ST_CPU_READ))
    cpu_dat_r <= #1 mem_dat_r_0;
  else if (cache_ena && cpu_cs && tag_w1_match && (state == ST_CPU_READ))
    cpu_dat_r <= #1 mem_dat_r_1;
  else if (sdr_cpucycle && (sdr_state == ph9))
    cpu_dat_r <= #1 sdr_dat_r;
end

// CPU write buffer
reg cpu_wb_act = 0;
reg [16-1:0] cpu_wb = 0;

always @ (posedge clk) begin
  if (rst)
    cpu_wb_act <= #1 1'b0;
  else if (sdr_cpucycle && (sdr_state == ph11) && !sdr_cas && (sdr_adr[24:1] == cpu_adr))
    cpu_wb_act <= #1 1'b0;
  else if (cpu_cs && cpu_wr)
    cpu_wb_act <= #1 1'b1;
end

always @ (posedge clk) begin
  if (cpu_cs && cpu_wr && !cpu_wb_act)
    cpu_wb <= #1 cpu_dat_w;
end

// CPU acknowledge
reg ack;
always @ (posedge clk) begin
  if (rst)
    ack <= #1 1'b0;
  else begin
    if (cpu_state[5])
      ack <= #1 1'b0;
    else if (cache_ena && cpu_cs && (state == ST_CPU_READ) && (tag_w0_match || tag_w1_match))
      ack <= #1 1'b1;
  end
end

always @ (posedge clk) begin
  if (rst)
    cpu_ack <= #1 1'b0;
  else begin
    if (cpu_state[5])
      cpu_ack <= #1 1'b0;
    else if (cache_ena && cpu_cs && tag_w0_match && (state == ST_CPU_READ))
      cpu_ack <= #1 1'b1;
    else if (cache_ena && cpu_cs && tag_w1_match && (state == ST_CPU_READ))
      cpu_ack <= #1 1'b1;
//    else if (cpu_cs && cpu_wr && !cpu_wb_act)
//      cpu_ack <= #1 1'b1;
//    else if (ack)
//      cpu_ack <= #1 1'b1;
    else if (sdr_cpucycle && (sdr_state == ph11) && !sdr_cas && (sdr_adr[24:1] == cpu_adr))
      cpu_ack <= #1 1'b1;
  end
end


//// cache control state machine ////
always @ (posedge clk) begin
  if (rst) begin
    state         <= #1 ST_INIT;
    st_adr        <= #1 9'd0;
    st_lru        <= #1 1'b0;
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
        //st_mem_we_0 <= #1 1'b1;
        //st_mem_we_1 <= #1 1'b1;
        if (&st_adr) state <= #1 ST_IDLE;
        else state <= #1 ST_INIT;
      end
      ST_IDLE : begin
        if (cpu_cs && !cpu_ack)
          state <= #1 ST_PREP;
        else
          state <= #1 ST_IDLE;
      end
      ST_PREP : begin
        if (cpu_cs) begin
          // state <= #1 cpu_rw ? ST_CPU_READ : ST_CPU_WRITE;
          if (cpu_wr) state <= #1 ST_CPU_WRITE;
          else if (cpu_rd) state <= #1 ST_CPU_READ;
        end
      end
      ST_CPU_WRITE : begin
        // on hit, update cache, on miss, no update neccessary
        st_mem_bs <= #1 ~cpu_bs;
        st_mem_dat_w <= #1 cpu_dat_w;
        st_mem_we_0 <= #1 tag_w0_match;
        st_mem_we_1 <= #1 tag_w1_match;
        state <= #1 cpu_ack ? ST_IDLE : ST_CPU_WRITE;
        //if (cpu_cs) begin
        //  if (tag_w0_match || tag_w1_match) begin
        //    st_tag_we <= #1 1'b1;
        //    st_tag_dat_w <= #1 32'd0;
        //  end
        //  state <= #1 cpu_ack ? ST_IDLE : ST_CPU_WRITE;
        //end
      end
      ST_CPU_READ : begin
        //if (cpu_cs) begin
          // on hit, update LRU flag in tag memory
          if (tag_w0_match) begin
            st_tag_we <= #1 1'b1;
            st_tag_dat_w <= #1 {1'b0, tag_dat_r[30:0]};
            state <= #1 cpu_ack ? ST_IDLE : ST_CPU_READ;
          end else if (tag_w1_match) begin
            st_tag_we <= #1 1'b1;
            st_tag_dat_w <= #1 {1'b1, tag_dat_r[30:0]};
            state <= #1 cpu_ack ? ST_IDLE : ST_CPU_READ;
          end else begin
            // on miss, fetch data from SDRAM & update tag
            st_lru <= #1 tag_lru;
            state <= #1 ST_FILL;
          end
        //end
      end
      ST_FILL : begin
        if (sdr_cpucycle) begin
          st_mem_bs <= #1 2'b11;
          st_mem_dat_w <= #1 sdr_dat_r;
          case (sdr_state)
            ph9,
            ph10,
            ph11,
            ph12 : begin
              st_mem_we_0 <= #1 st_lru;
              st_mem_we_1 <= #1 !st_lru;
            end
          endcase
          case (sdr_state)
            ph10,
            ph11,
            ph12 : begin
              st_adr <= #1 {st_adr[8:2], {st_adr[1:0] + 2'b01}};
            end
          endcase
          if (sdr_state == ph12) begin
            st_tag_we <= #1 1'b1;
            st_tag_dat_w <= #1 {!st_lru, st_lru ? {tag_dat_r[30:16], 1'b0, adr_tag} : {adr_tag, tag_dat_r[15:0]}};
          end
        end
        state <= #1 cpu_ack ? ST_IDLE : ST_FILL;
      end
    endcase    
  end
end


//// tag RAM ////
assign tag_radr     = adr_idx;
assign tag_wadr     = st_adr[8:2];
assign tag_dat_w    = st_tag_dat_w;
assign tag_we       = st_tag_we;
assign tag_w0_match = (adr_tag == tag_dat_r[14: 0]);
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
always @ (posedge clk) tag_dat_r_reg <= #1 tag_dat_r;


//// data RAM ////
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
  .wren       (mem_we_0   ),
  .byteena_a  (mem_bs     ),
  .data       (mem_dat_w  ),
  .rdaddress  (mem_radr   ),
  .q          (mem_dat_r_0)
);
always @ (posedge clk) mem_dat_r_0_reg <= #1 mem_dat_r_0;

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
always @ (posedge clk) mem_dat_r_1_reg <= #1 mem_dat_r_1;


endmodule


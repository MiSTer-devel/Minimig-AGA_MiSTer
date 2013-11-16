/********************************************/
/* qmem_bridge.v                            */
/* QMEM 32-to-16 bit async bridge           */
/*                                          */
/* 2013, rok.krajnc@gmail.com               */
/********************************************/


module qmem_bridge #(
  parameter MAW = 22,
  parameter MSW = 4,
  parameter MDW = 32,
  parameter SAW = 22,
  parameter SSW = 2,
  parameter SDW = 16
)(
  // master
  input  wire           m_clk,
  input  wire [MAW-1:0] m_adr,
  input  wire           m_cs,
  input  wire           m_we,
  input  wire [MSW-1:0] m_sel,
  input  wire [MDW-1:0] m_dat_w,
  output reg  [MDW-1:0] m_dat_r,
  output reg            m_ack = 1'b0,
  output wire           m_err,
  // slave
  input  wire           s_clk,
  output reg  [SAW-1:0] s_adr,
  output reg            s_cs,
  output reg            s_we,
  output reg  [SSW-1:0] s_sel,
  output reg  [SDW-1:0] s_dat_w,
  input  wire [SDW-1:0] s_dat_r,
  input  wire           s_ack,
  input  wire           s_err
);


// sync master cs
reg [  3-1:0] cs_sync = 3'b000;
always @ (posedge s_clk) cs_sync <= #1 {cs_sync[1:0], m_cs};

// detect master cs posedge
wire cs_posedge;
assign cs_posedge = cs_sync[1] && !cs_sync[2];

// latch master data
reg  [MAW-1:0] adr_d = {MAW{1'b0}};
reg            we_d = 1'b0;
reg  [MSW-1:0] sel_d = {MSW{1'b0}};
reg  [MDW-1:0] dat_w_d = {MDW{1'b0}};
always @ (posedge s_clk) begin
  if (cs_sync[1]) begin
    adr_d   <= #1 m_adr;
    we_d    <= #1 m_we;
    sel_d   <= #1 m_sel;
    dat_w_d <= #1 m_dat_w;
  end
end

// output state machine
reg  [  3-1:0] state = 3'b000;
localparam ST_IDLE     = 3'b000;
localparam ST_U_SETUP  = 3'b010;
localparam ST_U_WAIT   = 3'b011;
localparam ST_L_SETUP  = 3'b100;
localparam ST_L_WAIT   = 3'b101;
localparam ST_A_WAIT   = 3'b111;
reg  [  2-1:0] s_ack_sync = 2'b00;
reg done = 1'b0;
always @ (posedge s_clk) begin
  case (state)
    ST_IDLE : begin
      if (cs_sync[2]) begin
        state <= #1 ST_U_SETUP;
      end
    end
    ST_U_SETUP : begin
      s_cs    <= #1 1'b1;
      s_adr   <= #1 {adr_d[22-1:2], 1'b0, 1'b0};
      s_sel   <= #1 sel_d[3:2];
      s_we    <= #1 we_d;
      s_dat_w <= #1 dat_w_d[31:16];
      state   <= #1 ST_U_WAIT;
    end
    ST_U_WAIT : begin
      if (s_ack) begin
        s_cs           <= #1 1'b0;
        m_dat_r[31:16] <= #1 s_dat_r;
        state          <= #1 ST_L_SETUP;
      end
    end
    ST_L_SETUP : begin
      s_cs    <= #1 1'b1;
      s_adr   <= #1 {adr_d[22-1:2], 1'b1, 1'b0};
      s_sel   <= #1 sel_d[1:0];
      s_we    <= #1 we_d;
      s_dat_w <= #1 dat_w_d[15:0];
      state   <= #1 ST_L_WAIT;
    end
    ST_L_WAIT : begin
      if (s_ack) begin
        s_cs           <= #1 1'b0;
        m_dat_r[15: 0] <= #1 s_dat_r;
        done           <= #1 1'b1;
        state          <= #1 ST_A_WAIT;
      end
    end
    ST_A_WAIT : begin
      if (s_ack_sync[1]) begin
        done  <= #1 1'b0;
        state <= #1 ST_IDLE;
      end
    end
  endcase
end

// master ack
reg  [  3-1:0] m_ack_sync = 3'b000;
always @ (posedge m_clk) begin
  m_ack_sync <= #1 {m_ack_sync[1:0], done};
end
wire m_ack_posedge;
assign m_ack_posedge = m_ack_sync[1] && !m_ack_sync[2];
always @ (posedge m_clk) begin
  if (m_ack_posedge) m_ack <= #1 1'b1;
  else if (m_ack) m_ack <= #1 1'b0;
end
always @ (posedge s_clk) begin
  s_ack_sync <= #1 {s_ack_sync[0], m_ack_sync[2]};
end

// master err
assign m_err = 1'b0;


endmodule


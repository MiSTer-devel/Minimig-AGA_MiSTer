// Copyright 2011, 2012 Frederic Requin
//
// This file is part of the MCC216 project
//
// J68 is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// J68 is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// The J68 core:
// -------------
// Simple re-implementation of the MC68000 CPU
// The core has the following characteristics:
//  - Tested on a Cyclone III (90 MHz) and a Stratix II (180 MHz)
//  - from 1500 (~70 MHz) to 1900 LEs (~90 MHz)
//  - 2048 x 20-bit microcode ROM
//  - 256 x 28-bit decode ROM
//  - 2 x block RAM for the data and instruction stacks
//  - stack based CPU with forth-like microcode
//  - not cycle-exact : needs a frequency ~3 x higher
//  - all 68000 instructions are implemented
//  - all 68000 exceptions are implemented

`timescale 1 ns / 1 ns

module j68
(
  // Clock and reset
  input         rst,          // CPU reset
  input         clk,          // CPU clock
  // Bus interface
  output        rd_ena,       // Read strobe
  output        wr_ena,       // Write strobe
  input         data_ack,     // Data acknowledge
  output [1:0]  byte_ena,     // Byte enable
  output [31:0] address,      // Address bus
  input  [15:0] rd_data,      // Data bus in
  output [15:0] wr_data,      // Data bus out
  // 68000 control
  output [2:0]  fc,           // Function code
  input  [2:0]  ipl_n,        // Interrupt level
  // 68000 debug
  output [3:0]  dbg_reg_addr, // Register address
  output [3:0]  dbg_reg_wren, // Register write enable
  output [15:0] dbg_reg_data, // Register write data
  output [15:0] dbg_sr_reg,   // Status register
  output [31:0] dbg_pc_reg,   // Program counter
  output [31:0] dbg_usp_reg,  // User stack pointer
  output [31:0] dbg_ssp_reg,  // Supervisor stack pointer
  output [31:0] dbg_vbr_reg,  // Vector base register
  output [7:0]  dbg_cycles,   // Cycles used
  output        dbg_ifetch    // Instruction fetch
);

  // ALU operations
  `define ALU_ADD       5'b00000
  `define ALU_ADDC      5'b00001
  `define ALU_SUB       5'b00010
  `define ALU_SUBC      5'b00011
  `define ALU_AND       5'b00100
  `define ALU_BAND      5'b10100
  `define ALU_OR        5'b00101
  `define ALU_BOR       5'b10101
  `define ALU_XOR       5'b00110
  `define ALU_BXOR      5'b10110
  `define ALU_NOT       5'b00111
  `define ALU_BNOT      5'b10111
  `define ALU_SHL       5'b01000
  `define ALU_SHR       5'b01100
  `define ALU_DIV       5'b01110
  `define ALU_MUL       5'b01111
  // ALU inputs
  `define A_ADD_ZERO    2'b00
  `define A_ADD_T       2'b10
  `define A_ADD_NOT_T   2'b11
  `define B_ADD_ZERO    2'b00
  `define B_ADD_N       2'b10
  `define B_ADD_NOT_N   2'b11
  `define A_LOG_ZERO    2'b00
  `define A_LOG_IMM     2'b01
  `define A_LOG_T       2'b10
  `define A_LOG_RAM     2'b11
  `define B_LOG_ZERO    2'b00
  `define B_LOG_IO      2'b01
  `define B_LOG_N       2'b10
  `define B_LOG_NOT_N   2'b11

  reg                 r_rst_dly;  // Delayed reset signal

  wire [19:0]         w_inst_in;  // Internal RAM instruction read
  wire                w_ram_rd;   // Internal RAM read
  reg                 r_ram_rd;   // Internal RAM read (delayed)
  wire                w_ram_wr;   // Internal RAM write
  wire [1:0]          w_ram_bena; // Internal RAM byte enable
  wire [10:0]         w_ram_addr; // Internal RAM address
  wire [15:0]         w_ram_din;  // Internal RAM data write
  wire [15:0]         w_ram_dout; // Internal RAM data read
  wire                w_ram_rdy;  // RAM data ready

  wire                w_reg_wr;   // CPU register write
  wire [1:0]          w_reg_bena; // CPU register byte enable
  wire [10:0]         w_reg_addr; // CPU register address
  
  reg  [11:0]         w_alu_c;    // ALU control (wire)
  reg  [10:0]         w_flg_c;    // Flags control (wire)
  reg  [3:0]          w_cin_c;    // Carry in control (wire)

  reg  [3:0]          r_ds_ptr;   // Data stack pointer (reg)
  reg  [3:0]          w_ds_nxt;   // Next data stack pointer (wire)
  wire [3:0]          w_ds_inc;   // Data stack pointer increment (wire)
  reg  [15:0]         r_ds[0:15]; // Data stack (regs)
  reg  [15:0]         r_ds_T;     // Data stack output T (reg)
  wire [15:0]         w_ds_N;     // Data stack output N (wire)
  wire [31:0]         w_ds_R;     // Data stack input : ALU result (wire)
  reg                 w_ds_wr;    // Data stack write enable (wire)

  wire                w_ifetch;   // Fetch next instruction
  wire [10:0]         w_pc_inc;   // PC value incremented by 1 (wire)
  reg  [10:0]         r_pc_reg;   // PC register (reg)
  reg  [10:0]         w_pc_nxt;   // Next PC value (wire)
  wire [10:0]         w_pc_loop;  // PC value for loop (wire)

  reg  [3:0]          r_rs_ptr;   // Return stack pointer (reg)
  reg  [3:0]          w_rs_nxt;   // Next return stack pointer (wire)
  reg  [10:0]         r_rs[0:15]; // Return stack (regs)
  wire [10:0]         w_rs_q;     // Return stack output (wire)
  reg  [10:0]         w_rs_d;     // Return stack input (wire)
  reg                 w_rs_wr;    // Return stack write enable (wire)
  reg                 w_rs_rd;    // Return stack read enable (wire)

  // Micro-instruction decode  
  wire        w_io_op   = (w_inst_in[19:17] == 3'b100)  ? 1'b1 : 1'b0;
  wire        w_reg_op  = (w_inst_in[19:17] == 3'b101)  ? 1'b1 : 1'b0;
  wire        w_t_mode  = (w_inst_in[15:12] == 4'b1111) ? 1'b1 : 1'b0;
  wire        w_branch;
  wire [3:0]  w_loop_cnt;
  wire        w_loop;
  wire        w_skip;

  // ALU <-> Flags
  wire [31:0] w_res;
  wire [3:0]  w_alu;
  wire [1:0]  w_size;
  wire [4:0]  w_c_flg;
  wire [5:0]  w_v_flg;
  wire [10:0] w_sr;
  wire [4:0]  w_ccr;
  wire        w_c_in;
  wire        w_z_flg;
  wire        w_g_flg;

  // Memory access
  wire        w_io_rd;    // I/O register read
  wire        w_io_wr;    // I/O register write
  wire        w_io_ext;   // External memory access
  wire        w_io_rdy;   // I/O data ready
  wire        w_io_end;   // End of I/O cycle
  wire [15:0] w_io_din;   // I/O data input
  wire [10:0] w_io_flg_c; // Flag control (for SR write)

  // M68k instruction decoder
  wire [15:0] w_insw;     // Instruction word
  wire [15:0] w_extw;     // Extension word
  wire [15:0] w_ea1b;     // Effective address #1 bitfield

  // Debug
  reg  [31:0] r_usp_reg;
  reg  [31:0] r_ssp_reg;
  reg   [7:0] r_cycles;

  // Delayed reset
  always@(posedge clk)
    r_rst_dly <= rst;
  
  // RAM access
  assign w_ram_rd   = w_reg_op & w_inst_in[7] & ~w_ram_rdy;
  assign w_ram_addr = w_reg_addr;
  assign w_ram_bena = w_reg_bena & { w_reg_wr, w_reg_wr };
  assign w_ram_din  = r_ds_T;
  assign w_ram_rdy  = (w_reg_op & w_inst_in[6]) | r_ram_rd;
  
  always@(posedge clk)
    r_ram_rd <= w_ram_rd;
    
  // Debug
  assign dbg_reg_addr    = (w_reg_wr) ? w_reg_addr[4:1] : 4'b0000;
  assign dbg_reg_wren[3] = w_reg_wr & w_reg_addr[5] & w_reg_addr[0] & w_reg_bena[1];
  assign dbg_reg_wren[2] = w_reg_wr & w_reg_addr[5] & w_reg_addr[0] & w_reg_bena[0];
  assign dbg_reg_wren[1] = w_reg_wr & w_reg_addr[5] & ~w_reg_addr[0] & w_reg_bena[1];
  assign dbg_reg_wren[0] = w_reg_wr & w_reg_addr[5] & ~w_reg_addr[0] & w_reg_bena[0];
  assign dbg_reg_data    = (w_reg_wr) ? r_ds_T : 16'h0000;
  assign dbg_sr_reg      = { (w_sr & 11'b1010_0111_000) , w_ccr};
  assign dbg_usp_reg     = r_usp_reg;
  assign dbg_ssp_reg     = r_ssp_reg;
  assign dbg_vbr_reg     = 32'h00000000;
  assign dbg_cycles      = r_cycles;
  
  always @(posedge rst or posedge clk)
  begin
    if (rst) begin
      r_usp_reg <= 32'd0;
      r_ssp_reg <= 32'd0;
      r_cycles  <= 8'd0;
    end else begin
      if (w_reg_wr) begin
        // USP low word
        if ((w_reg_addr[5:0] == 6'b011100) ||
            ((w_reg_addr[5:0] == 6'b111110) && (!w_sr[8])))
          r_usp_reg[15:0] <= r_ds_T;
        // USP high word
        if ((w_reg_addr[5:0] == 6'b011101) ||
            ((w_reg_addr[5:0] == 6'b111111) && (!w_sr[8])))
          r_usp_reg[31:16] <= r_ds_T;
        // SSP low word
        if ((w_reg_addr[5:0] == 6'b011110) ||
            ((w_reg_addr[5:0] == 6'b111110) && (w_sr[8])))
          r_ssp_reg[15:0] <= r_ds_T;
        // SSP high word
        if ((w_reg_addr[5:0] == 6'b011111) ||
            ((w_reg_addr[5:0] == 6'b111111) && (w_sr[8])))
          r_ssp_reg[31:16] <= r_ds_T;
      end
      if (dbg_ifetch)
        r_cycles <= 8'd0;
      else
        r_cycles <= r_cycles + 8'd1;
    end
  end

  // I/O access
  assign w_io_wr   = ~w_inst_in[8] & w_inst_in[6] & w_io_op;
  assign w_io_rd   = ~w_inst_in[8] & w_inst_in[7] & w_io_op & ~w_io_rdy;
  assign w_io_ext  = w_inst_in[8] & w_io_op & ~w_io_rdy;
  assign w_io_end  = w_io_rdy | w_io_wr;  


  // PC calculation
  assign w_pc_inc  = r_pc_reg + 11'd1;

  always @(w_inst_in or w_skip or w_branch or w_t_mode or w_inst_in or w_pc_inc or w_loop or w_pc_loop or r_ds_T or w_rs_q)
  begin
    case (w_inst_in[19:17])
      3'b000 : // LOOP instruction
        if (w_skip)
          // Null loop count
          w_pc_nxt <= w_inst_in[10:0];
        else
          // First instruction of the loop
          w_pc_nxt <= w_pc_inc;
      3'b001 : // JUMP/CALL instruction
        if (w_branch)
          // Branch taken
          w_pc_nxt <= w_inst_in[10:0] | (r_ds_T[10:0] & {11{w_t_mode}});
        else
          // Branch not taken
          w_pc_nxt <= w_pc_inc;
      default : // Rest of instruction
        if (w_inst_in[16])
          // With RTS
          w_pc_nxt <= w_rs_q;
        else
          if (w_loop)
            // Jump to start of loop
            w_pc_nxt <= w_pc_loop;
          else
            // Following instruction
            w_pc_nxt <= w_pc_inc;
    endcase
  end
  
  assign w_ifetch = ((w_io_end | w_ram_rdy | (~w_io_op & ~w_reg_op) | r_rst_dly) & ~rst);
  
  always @(posedge rst or posedge clk)
  begin
    if (rst)
      r_pc_reg <= 11'b111_11111111;
    else
      if (w_ifetch) r_pc_reg <= w_pc_nxt;
  end


  // Return stack pointer calculation
  always @(w_inst_in or w_ifetch or r_rs_ptr or r_pc_reg or w_pc_inc)
  begin
    if (w_inst_in[19:17] == 3'b001) begin
      if (w_inst_in[16]) begin
        // "JUMP" instruction
        w_rs_nxt <= r_rs_ptr;
        w_rs_d   <= r_pc_reg;
        w_rs_wr  <= 1'b0;
        w_rs_rd  <= 1'b0;
      end else begin
        // "CALL" instruction
        w_rs_nxt <= r_rs_ptr - 4'd1;
        w_rs_d   <= w_pc_inc;
        w_rs_wr  <= 1'b1;
        w_rs_rd  <= 1'b0;
      end
    end else begin
      if ((w_inst_in[16]) && (w_ifetch)) begin
        // Embedded "RTS"
        w_rs_nxt <= r_rs_ptr + 4'd1;
        w_rs_d   <= r_pc_reg;
        w_rs_wr  <= 1'b0;
        w_rs_rd  <= 1'b1;
      end else begin
        // No "RTS"
        w_rs_nxt <= r_rs_ptr;
        w_rs_d   <= r_pc_reg;
        w_rs_wr  <= 1'b0;
        w_rs_rd  <= 1'b0;
      end
    end
  end

  // Return stack
  always @(posedge rst or posedge clk)
  begin
    if (rst)
      r_rs_ptr <= 4'd0;
    else begin
    //else if ((w_io_end) || (!w_io_op)) begin
      // Latch the return stack pointer
      r_rs_ptr <= w_rs_nxt;
      if (w_rs_wr) r_rs[w_rs_nxt] <= w_rs_d;
    end
  end
  // Return stack output value
  assign w_rs_q = r_rs[r_rs_ptr];
  
  assign w_ds_inc = {{3{w_inst_in[13]}}, w_inst_in[12]};

  // ALU parameters and data stack update
  always@(w_inst_in or w_t_mode or r_ds_ptr or w_ds_inc)
  begin
    casez(w_inst_in[19:17])
      // LOOP
      3'b000 :
      begin
        // Generate a "DROP" or a "NOP"
        w_alu_c[11:10] <= 2'b01;             // Operand size
        w_alu_c[9]     <= 1'b0;              // CCR update
        w_alu_c[8:4]   <= `ALU_OR;           // ALU operation
        // Data stack update if "LOOP T"
        if (w_inst_in[11]) begin
          // DROP
          w_alu_c[3:2] <= `A_LOG_ZERO;       // A = 0x0000
          w_alu_c[1:0] <= `B_LOG_N;          // B = Next on stack
          w_ds_nxt <= r_ds_ptr - 4'd1;
        end else begin
          // NOP
          w_alu_c[3:2] <= `A_LOG_T;          // A = Top of stack
          w_alu_c[1:0] <= `B_LOG_ZERO;       // B = 0x0000
          w_ds_nxt <= r_ds_ptr;
        end
        w_ds_wr  <= 1'b0;
      end      
      // CALL, JUMP
      3'b001 :
      begin
        // Generate a "DROP" or a "NOP"
        w_alu_c[11:10] <= 2'b01;             // Operand size
        w_alu_c[9]     <= 1'b0;              // CCR update
        w_alu_c[8:4]   <= `ALU_OR;           // ALU operation
        // Data stack update if "JUMP (T)" or "CALL (T)"
        if (w_t_mode) begin
          // DROP
          w_alu_c[3:2] <= `A_LOG_ZERO;       // A = 0x0000
          w_alu_c[1:0] <= `B_LOG_N;          // B = Next on stack
          w_ds_nxt     <= r_ds_ptr - 4'd1;
        end else begin
          // NOP
          w_alu_c[3:2] <= `A_LOG_T;          // A = Top of stack
          w_alu_c[1:0] <= `B_LOG_ZERO;       // B = 0x0000
          w_ds_nxt     <= r_ds_ptr;
        end
        w_ds_wr        <= 1'b0;
      end      
      // LIT
      3'b010 :
      begin
        w_alu_c[11:10] <= 2'b01;             // Operand size
        w_alu_c[9]     <= 1'b0;              // CCR update
        w_alu_c[8:4]   <= `ALU_OR;           // ALU operation
        w_alu_c[3:2]   <= `A_LOG_IMM;        // A = Immediate value
        w_alu_c[1:0]   <= `B_LOG_ZERO;       // B = 0x0000
        // Data stack update
        w_ds_nxt       <= r_ds_ptr + 4'd1;
        w_ds_wr        <= 1'b1;
      end
      // FLAG
      3'b011 :
      begin
        // Generate a "NOP"
        w_alu_c[11:10] <= 2'b01;             // Operand size
        w_alu_c[9]     <= 1'b0;              // CCR update
        w_alu_c[8:4]   <= `ALU_OR;           // ALU operation
        w_alu_c[3:2]   <= `A_LOG_T;          // A = Top of stack
        w_alu_c[1:0]   <= `B_LOG_ZERO;       // B = 0x0000
        // No data stack update
        w_ds_nxt       <= r_ds_ptr;
        w_ds_wr        <= 1'b0;
      end
      // I/O reg. access
      3'b100 :
      begin
        w_alu_c[11:10] <= 2'b01;             // Operand size
        w_alu_c[9]     <= w_inst_in[9];      // CCR update
        w_alu_c[8:4]   <= `ALU_OR;           // ALU operation
        if (w_inst_in[7]) begin
          if (w_ds_inc[0]) begin
            // I/O register load
            w_alu_c[3:2] <= `A_LOG_ZERO;     // A = 0x0000
            w_alu_c[1:0] <= `B_LOG_IO;       // B = I/O data
          end else begin
            // I/O register fetch
            w_alu_c[3:2] <= `A_LOG_T;        // A = Top of stack
            w_alu_c[1:0] <= `B_LOG_ZERO;     // B = 0x0000
          end
        end else begin
          if (w_ds_inc[0]) begin
            // I/O register store
            w_alu_c[3:2] <= `A_LOG_ZERO;     // A = 0x0000
            w_alu_c[1:0] <= `B_LOG_N;        // B = Next on stack
          end else begin
            // I/O register write
            w_alu_c[3:2] <= `A_LOG_T;        // A = Top of stack
            w_alu_c[1:0] <= `B_LOG_ZERO;     // B = 0x0000
          end
        end
        // Data stack update
        w_ds_nxt       <= r_ds_ptr + w_ds_inc;
        w_ds_wr        <= w_inst_in[14];
      end
      // M68k reg. access
      3'b101 :
      begin
        w_alu_c[11:10] <= 2'b01;             // Operand size
        w_alu_c[9]     <= w_inst_in[9];      // CCR update
        w_alu_c[8:4]   <= `ALU_OR;           // ALU operation
        if (w_inst_in[7]) begin
          // M68k register load
          w_alu_c[3:2] <= `A_LOG_RAM;        // A = RAM data
          w_alu_c[1:0] <= `B_LOG_ZERO;       // B = 0x0000
        end else begin
          if (w_ds_inc[0]) begin
            // M68k register store
            w_alu_c[3:2] <= `A_LOG_ZERO;       // A = 0x0000
            w_alu_c[1:0] <= `B_LOG_N;          // B = Next on stack
          end else begin
            // M68k register write
            w_alu_c[3:2] <= `A_LOG_T;          // A = Top of stack
            w_alu_c[1:0] <= `B_LOG_ZERO;       // B = 0x0000
          end
        end
        // Data stack update
        w_ds_nxt       <= r_ds_ptr + w_ds_inc;
        w_ds_wr        <= w_inst_in[14];
      end
      // ALU operation
      3'b110 :
      begin
        w_alu_c[11:10] <= w_inst_in[11:10];   // Operand size
        w_alu_c[9]     <= w_inst_in[9];       // CCR update
        w_alu_c[8:4]   <= w_inst_in[8:4];     // ALU operation
        w_alu_c[3:2]   <= w_inst_in[3:2];     // A source
        w_alu_c[1:0]   <= w_inst_in[1:0];     // B source
        // Data stack update
        w_ds_nxt       <= r_ds_ptr + w_ds_inc;
        w_ds_wr        <= w_inst_in[14];
      end
      default:
      begin
        // Generate a "NOP"
        w_alu_c[11:10] <= 2'b01;              // Operand size
        w_alu_c[9]     <= 1'b0;               // CCR update
        w_alu_c[8:4]   <= `ALU_OR;            // ALU operation
        w_alu_c[3:2]   <= `A_LOG_T;           // A = Top of stack
        w_alu_c[1:0]   <= `B_LOG_ZERO;        // B = 0x0000
        // No data stack update
        w_ds_nxt       <= r_ds_ptr;
        w_ds_wr        <= 1'b0;
      end
    endcase
  end

  // Data stack
  always @(posedge rst or posedge clk)
  begin
    if (rst) begin
      r_ds_ptr <= 4'd0;
      r_ds_T   <= 16'h0000;
    end else if ((w_io_end) || (w_ram_rdy) || (!(w_io_op | w_reg_op))) begin
      // Latch the data stack pointer
      r_ds_ptr <= w_ds_nxt;
      // Latch the data stack value T
      r_ds_T   <= w_ds_R[15:0];
      // Latch the data stack value N
      if (w_ds_wr) r_ds[w_ds_nxt] <= w_ds_R[31:16];
    end
  end
  // Data stack output value #1 (N)
  assign w_ds_N = r_ds[r_ds_ptr];


  // Flags control
  always@(w_inst_in or w_io_flg_c)
  begin
    if (w_inst_in[19:17] == 3'b011) begin
      // Update flags
      w_flg_c <= w_inst_in[10:0];
      w_cin_c <= w_inst_in[14:11];
    end else begin
      // Keep flags
      w_flg_c <= w_io_flg_c;
      w_cin_c <= 4'b0000;
    end
  end


  // 16/32-bit ALU
  alu alu_inst
  (
    .rst(rst),
    .clk(clk),
    .size(w_alu_c[11:10]),
    .cc_upd(w_alu_c[9]),
    .alu_c(w_alu_c[8:4]),
    .a_ctl(w_alu_c[3:2]),
    .b_ctl(w_alu_c[1:0]),
    .c_in(w_c_in),
    .v_in(w_ccr[1]),
    .a_src(r_ds_T),
    .b_src(w_ds_N),
    .ram_in(w_ram_dout),
    .io_in(w_io_din),
    .imm_in(w_inst_in[15:0]),
    .result(w_ds_R),
    .c_flg(w_c_flg),
    .v_flg(w_v_flg[4:0]),
    .l_res(w_res),
    .l_alu(w_alu),
    .l_size(w_size)
  );


  // Flags update
  flags flags_inst
  (
    .rst(rst),
    .clk(clk),
    .c_flg(w_c_flg),
    .v_flg(w_v_flg),
    .l_res(w_res),
    .l_alu(w_alu),
    .l_size(w_size),
    .a_src(r_ds_T),
    .b_src(w_ds_N),
    .flg_c(w_flg_c),
    .cin_c(w_cin_c),
    .cc_out(w_ccr),
    .c_in(w_c_in),
    .z_flg(w_z_flg),
    .g_flg(w_g_flg)
  );


  // Conditional Jump/Call
  test test_inst
  (
    .rst(rst),
    .clk(clk),
    .inst_in(w_inst_in),
    .flg_in({w_g_flg, w_res[15], w_z_flg, w_c_flg[1]}),
    .sr_in({w_sr, w_ccr}),
    .a_src(r_ds_T),
    .ea1b(w_ea1b),
    .extw(w_extw),
    .branch(w_branch)
  );


  // Hardware loop
  loop loop_inst
  (
    .rst(rst),
    .clk(clk),
    .inst_in(w_inst_in),
    .i_fetch(w_ifetch),
    .a_src(r_ds_T[5:0]),
    .pc_in(w_pc_nxt),
    .pc_out(w_pc_loop),
    .branch(w_loop),
    .skip(w_skip),
    .lcount(w_loop_cnt)
  );


  // Bus interface
  mem_io mem_inst
  (
    .rst(rst),
    .clk(clk),
    .rd_ena(rd_ena),
    .wr_ena(wr_ena),
    .data_ack(data_ack),
    .byte_ena(byte_ena),
    .address(address),
    .rd_data(rd_data),
    .wr_data(wr_data),
    .fc(fc),
    .ipl_n(ipl_n),
    .io_rd(w_io_rd),
    .io_wr(w_io_wr),
    .io_ext(w_io_ext),
    .io_reg(w_reg_op),
    .io_rdy(w_io_rdy),
    .io_din(w_io_din),
    .io_dout(r_ds_T),
    .inst_in(w_inst_in),
    .cc_upd(w_alu_c[9]),
    .alu_op(w_alu_c[7:4]),
    .a_src(r_ds_T),
    .b_src(w_ds_N),
    .v_flg(w_v_flg[5]),
    .insw(w_insw),
    .extw(w_extw),
    .ea1b(w_ea1b),
    .ccr_in(w_ccr),
    .sr_out(w_sr),
    .flg_c(w_io_flg_c),
    .loop_cnt(w_loop_cnt),
    .reg_addr(w_reg_addr[5:0]),
    .reg_wr(w_reg_wr),
    .reg_bena(w_reg_bena),
    .dbg_pc(dbg_pc_reg),
    .dbg_if(dbg_ifetch)
  );
  assign w_reg_addr[10:6] = 5'b11111;

  // Microcode ROM : 2048 x 20-bit (5 x M9K)
  dpram_2048x4 dpram_inst_0
  (
    .clock(clk),
    .rden_a(w_ifetch),
    .address_a(w_pc_nxt),
    .q_a(w_inst_in[3:0]),
    .wren_b(w_ram_bena[0]),
    .address_b(w_ram_addr),
    .data_b(w_ram_din[3:0]),
    .q_b(w_ram_dout[3:0])
  );
  defparam
    dpram_inst_0.RAM_INIT_FILE = "j68_ram_0.mif";

  dpram_2048x4 dpram_inst_1
  (
    .clock(clk),
    .rden_a(w_ifetch),
    .address_a(w_pc_nxt),
    .q_a(w_inst_in[7:4]),
    .wren_b(w_ram_bena[0]),
    .address_b(w_ram_addr),
    .data_b(w_ram_din[7:4]),
    .q_b(w_ram_dout[7:4])
  );
  defparam
    dpram_inst_1.RAM_INIT_FILE = "j68_ram_1.mif";

  dpram_2048x4 dpram_inst_2
  (
    .clock(clk),
    .rden_a(w_ifetch),
    .address_a(w_pc_nxt),
    .q_a(w_inst_in[11:8]),
    .wren_b(w_ram_bena[1]),
    .address_b(w_ram_addr),
    .data_b(w_ram_din[11:8]),
    .q_b(w_ram_dout[11:8])
  );
  defparam
    dpram_inst_2.RAM_INIT_FILE = "j68_ram_2.mif";

  dpram_2048x4 dpram_inst_3
  (
    .clock(clk),
    .rden_a(w_ifetch),
    .address_a(w_pc_nxt),
    .q_a(w_inst_in[15:12]),
    .wren_b(w_ram_bena[1]),
    .address_b(w_ram_addr),
    .data_b(w_ram_din[15:12]),
    .q_b(w_ram_dout[15:12])
  );
  defparam
    dpram_inst_3.RAM_INIT_FILE = "j68_ram_3.mif";

  dpram_2048x4 dpram_inst_4
  (
    .clock(clk),
    .rden_a(w_ifetch),
    .address_a(w_pc_nxt),
    .q_a(w_inst_in[19:16]),
    .wren_b(1'b0),
    .address_b(w_ram_addr),
    .data_b(4'b0000),
    .q_b()
  );
  defparam
    dpram_inst_4.RAM_INIT_FILE = "j68_ram_4.mif";

endmodule

module alu
(
  // Clock and reset
  input             rst,    // CPU reset
  input             clk,    // CPU clock
  // Control signals
  input             cc_upd, // Condition codes update
  input      [1:0]  size,   // Operand size (00 = byte, 01 = word, 1x = long)
  input      [4:0]  alu_c,  // ALU control
  input      [1:0]  a_ctl,  // A source control
  input      [1:0]  b_ctl,  // B source control
  // Operands
  input             c_in,   // Carry in
  input             v_in,   // Overflow in
  input      [15:0] a_src,  // A source
  input      [15:0] b_src,  // B source
  input      [15:0] ram_in, // RAM read
  input      [15:0] io_in,  // I/O read
  input      [15:0] imm_in, // Immediate
  // Result
  output reg [31:0] result, // ALU result
  // Flags
  output reg [4:0]  c_flg,  // Partial C/X flags
  output reg [4:0]  v_flg,  // Partial V flag
  output reg [31:0] l_res,  // Latched result for N & Z flags
  output reg [3:0]  l_alu,  // Latched ALU control
  output reg [1:0]  l_size  // Latched operand size
);

  reg  [15:0] w_a_log; // Operand A for logic
  reg  [15:0] w_a_add; // Operand A for adder
  reg         w_a_lsb; // Operand A lsb

  reg  [15:0] w_b_log; // Operand B for logic
  reg  [15:0] w_b_add; // Operand B for adder
  reg         w_b_lsb; // Operand B lsb

  wire [17:0] w_add_r; // Adder result
  reg  [15:0] w_log_r; // Logical result
  reg  [31:0] w_lsh_r; // Left shifter result
  reg  [31:0] w_rsh_r; // Right shifter result

  wire [4:0]  w_c_flg; // Carry flags
  wire [4:0]  w_v_flg; // Overflow flags

  // A source for Adder (1 LUT level)
  always @(a_ctl or a_src)
  begin
    case (a_ctl)
      2'b00 : w_a_add <= 16'h0000;
      2'b01 : w_a_add <= 16'hFFFF;
      2'b10 : w_a_add <= a_src;
      2'b11 : w_a_add <= ~a_src;
    endcase
  end

  // B source for Adder (1 LUT level)
  always @(b_ctl or b_src)
  begin
    case (b_ctl)
      2'b00 : w_b_add <= 16'h0000;
      2'b01 : w_b_add <= 16'hFFFF;
      2'b10 : w_b_add <= b_src;
      2'b11 : w_b_add <= ~b_src;
    endcase
  end

  // A source for Logic (1 LUT level)
  always @(a_src or a_ctl or imm_in or ram_in)
  begin
    case (a_ctl)
      2'b00 : w_a_log <= 16'h0000;
      2'b01 : w_a_log <= imm_in; // Immediate value through OR
      2'b10 : w_a_log <= a_src;
      2'b11 : w_a_log <= ram_in; // RAM read through OR
    endcase
  end

  // B source for Logic (2 LUT levels)
  always @(alu_c or size or b_src or b_ctl or io_in)
  begin
    if (alu_c[4]) begin
      // Mask generation for BTST, BCHG, BCLR, BSET
      case ({b_src[4]&(size[1]|size[0]), b_src[3]&(size[1]|size[0]), b_src[2:0]})
        5'b00000 : w_b_log <= 16'b0000000000000001 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b00001 : w_b_log <= 16'b0000000000000010 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b00010 : w_b_log <= 16'b0000000000000100 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b00011 : w_b_log <= 16'b0000000000001000 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b00100 : w_b_log <= 16'b0000000000010000 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b00101 : w_b_log <= 16'b0000000000100000 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b00110 : w_b_log <= 16'b0000000001000000 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b00111 : w_b_log <= 16'b0000000010000000 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b01000 : w_b_log <= 16'b0000000100000000 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b01001 : w_b_log <= 16'b0000001000000000 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b01010 : w_b_log <= 16'b0000010000000000 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b01011 : w_b_log <= 16'b0000100000000000 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b01100 : w_b_log <= 16'b0001000000000000 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b01101 : w_b_log <= 16'b0010000000000000 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b01110 : w_b_log <= 16'b0100000000000000 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b01111 : w_b_log <= 16'b1000000000000000 & {16{~size[1]}} ^ {16{b_ctl[0]}};
        5'b10000 : w_b_log <= 16'b0000000000000001 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b10001 : w_b_log <= 16'b0000000000000010 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b10010 : w_b_log <= 16'b0000000000000100 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b10011 : w_b_log <= 16'b0000000000001000 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b10100 : w_b_log <= 16'b0000000000010000 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b10101 : w_b_log <= 16'b0000000000100000 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b10110 : w_b_log <= 16'b0000000001000000 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b10111 : w_b_log <= 16'b0000000010000000 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b11000 : w_b_log <= 16'b0000000100000000 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b11001 : w_b_log <= 16'b0000001000000000 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b11010 : w_b_log <= 16'b0000010000000000 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b11011 : w_b_log <= 16'b0000100000000000 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b11100 : w_b_log <= 16'b0001000000000000 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b11101 : w_b_log <= 16'b0010000000000000 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b11110 : w_b_log <= 16'b0100000000000000 & {16{~size[0]}} ^ {16{b_ctl[0]}};
        5'b11111 : w_b_log <= 16'b1000000000000000 & {16{~size[0]}} ^ {16{b_ctl[0]}};
      endcase
    end else begin
      case (b_ctl)
        2'b00 : w_b_log <= 16'h0000;
        2'b01 : w_b_log <= io_in;  // I/O read through OR
        2'b10 : w_b_log <= b_src;
        2'b11 : w_b_log <= ~b_src;
      endcase
    end
  end

  // Carry input (1 LUT level)
  always @(alu_c or c_in)
  begin
    case (alu_c[1:0])
      2'b00 : begin // For: R = A + B
        w_a_lsb <= 1'b0;
        w_b_lsb <= 1'b0;
      end
      2'b01 : begin // For: R = A + B + Carry
        w_a_lsb <= c_in;
        w_b_lsb <= c_in;
      end
      2'b10 : begin // For: R = A - B
        w_a_lsb <= 1'b1;
        w_b_lsb <= 1'b1;
      end
      2'b11 : begin // For: R = B - A - Borrow
        w_a_lsb <= ~c_in;
        w_b_lsb <= ~c_in;
      end
    endcase
  end

  // Adder (1 LUT level + carry chain)
  assign w_add_r = {1'b0, w_a_add, w_a_lsb} + {1'b0, w_b_add, w_b_lsb};

  // Logical operations (2 LUT levels)
  always @(alu_c or size or w_a_log or w_b_log)
  begin
    case (alu_c[1:0])
      2'b00 : w_log_r[7:0] <=  w_a_log[7:0] & w_b_log[7:0]; // AND.B
      2'b01 : w_log_r[7:0] <=  w_a_log[7:0] | w_b_log[7:0]; // OR.B
      2'b10 : w_log_r[7:0] <=  w_a_log[7:0] ^ w_b_log[7:0]; // XOR.B
      2'b11 : w_log_r[7:0] <= ~w_a_log[7:0];                // NOT.B
    endcase
    if (size == 2'b00)
      w_log_r[15:8] <= w_a_log[15:8];
    else
      case (alu_c[1:0])
        2'b00 : w_log_r[15:8] <=  w_a_log[15:8] & w_b_log[15:8]; // AND.W
        2'b01 : w_log_r[15:8] <=  w_a_log[15:8] | w_b_log[15:8]; // OR.W
        2'b10 : w_log_r[15:8] <=  w_a_log[15:8] ^ w_b_log[15:8]; // XOR.W
        2'b11 : w_log_r[15:8] <= ~w_a_log[15:8];                 // NOT.W
      endcase
  end

  // Left shifter (1 LUT level)
  always @(size or a_src or b_src or c_in)
  begin
    case (size)
      2'b00   : w_lsh_r <= { b_src[15:0], a_src[15:8], a_src[6:0], c_in }; // Byte
      2'b01   : w_lsh_r <= { b_src[15:0], a_src[14:0], c_in };             // Word
      default : w_lsh_r <= { b_src[14:0], a_src[15:0], c_in };             // Long
    endcase
  end

  // Right shifter (1 LUT level)
  always @(size or a_src or b_src or c_in)
  begin
    case (size)
      2'b00   : w_rsh_r <= { b_src[15:0], a_src[15:8], c_in, a_src[7:1] }; // Byte
      2'b01   : w_rsh_r <= { b_src[15:0], c_in, a_src[15:1] };             // Word
      default : w_rsh_r <= { c_in, b_src[15:0], a_src[15:1] };             // Long
    endcase
  end

  // Final MUX (2 LUTs level)
  always @(alu_c or a_src or w_add_r or w_log_r or w_lsh_r or w_rsh_r)
  begin
    case (alu_c[3:2])
      2'b00 : result <= { a_src, w_add_r[16:1] }; // Adder
      2'b01 : result <= { a_src, w_log_r };       // Logic
      2'b10 : result <= w_lsh_r;                  // Left shift
      2'b11 : result <= w_rsh_r;                  // Right shift
    endcase
  end

  // Partial carry flags from adder
  assign w_c_flg[0] = w_add_r[9] ^ w_a_add[8]
                    ^ w_b_add[8] ^ alu_c[1];     // Byte
  assign w_c_flg[1] = w_add_r[17] ^ alu_c[1];    // Word
  // Partial carry flags from shifter
  assign w_c_flg[2] = (a_src[0] & alu_c[2])
                    | (a_src[7] & ~alu_c[2]);    // Byte
  assign w_c_flg[3] = (a_src[0] & alu_c[2])
                    | (a_src[15] & ~alu_c[2]);   // Word
  assign w_c_flg[4] = (a_src[0]  & alu_c[2])
                    | (b_src[15] & ~alu_c[2]);   // Long
  // Partial overflow flags from adder
  assign w_v_flg[0] = w_add_r[9] ^ w_add_r[8]
                    ^ w_a_add[8] ^ w_a_add[7]
                    ^ w_b_add[8] ^ w_b_add[7];   // Byte
  assign w_v_flg[1] = w_add_r[17] ^ w_add_r[16]
                    ^ w_a_add[15] ^ w_b_add[15]; // Word
  // Partial overflow flags from shifter
  assign w_v_flg[2] = v_in | (a_src[7] ^ a_src[6]);                               // Byte
  assign w_v_flg[3] = v_in | (a_src[15] ^ a_src[14]);                             // Word
  assign w_v_flg[4] = v_in | (b_src[15] ^ b_src[14]);                             // Long

  // Latch partial flags and result
  always@(posedge rst or posedge clk)
  begin
    if (rst) begin
      c_flg  <= 5'b00000;
      v_flg  <= 5'b00000;
      l_res  <= 32'h00000000;
      l_alu  <= 4'b0000;
      l_size <= 2'b00;
    end else if (cc_upd) begin
      c_flg  <= w_c_flg;
      v_flg  <= w_v_flg;
      l_res  <= result;
      l_alu  <= alu_c[3:0];
      l_size <= size;
    end
  end

endmodule

module flags
(
  // Clock and reset
  input             rst,    // CPU reset
  input             clk,    // CPU clock
  // Flags input
  input      [4:0]  c_flg,  // Partial C/X flags
  input      [5:0]  v_flg,  // Partial V flags
  input      [31:0] l_res,  // Latched result for N & Z flags
  input      [3:0]  l_alu,  // Latched ALU control
  input      [1:0]  l_size, // Latched operand size
  // Operand input
  input      [15:0] a_src,  // A operand
  input      [15:0] b_src,  // B operand
  // Flags control
  input      [10:0] flg_c,  // Flags output control
  input      [3:0]  cin_c,  // Carry in control
  // Flags output
  output reg [4:0]  cc_out, // XNZVC 68000 flags
  output reg        c_in,   // Carry in for ALU
  output            z_flg,  // Zero flag for test block
  output            g_flg   // Greater than flag for test block
);
  reg        w_c_flg;
  reg        w_v_flg;
  reg        w_z_flg;
  reg        w_n_flg;
  wire [2:0] w_zero;
  reg        r_z_flg;

  // C/X flag computation
  always@(l_alu or l_size or c_flg)
  begin
    case (l_alu[3:2])
      2'b00 : // Adder
        if (l_size == 2'b00)
          w_c_flg <= c_flg[0]; // Byte
        else
          w_c_flg <= c_flg[1]; // Word & Long
      2'b01 : // Logic
        w_c_flg <= 1'b0;
      default : // Shifter
        case (l_size)
          2'b00   : w_c_flg <= c_flg[2]; // Byte
          2'b01   : w_c_flg <= c_flg[3]; // Word
          default : w_c_flg <= c_flg[4]; // Long
        endcase
    endcase
  end

  // V flag computation
  always@(l_alu or l_size or v_flg)
  begin
    case (l_alu[3:2])
      2'b00 : // Adder
        if (l_size == 2'b00)
          w_v_flg <= v_flg[0]; // Byte
        else
          w_v_flg <= v_flg[1]; // Word & Long
      2'b10 : // Left shifter (ASL case)
        case (l_size)
          2'b00   : w_v_flg <= v_flg[2]; // Byte
          2'b01   : w_v_flg <= v_flg[3]; // Word
          default : w_v_flg <= v_flg[4]; // Long
        endcase
      2'b11 : // Right shifter (DIVU/DIVS case)
        w_v_flg <= v_flg[5] & l_alu[1];
      default : // Logic : no overflow
        w_v_flg <= 1'b0;
    endcase
  end

  // Z flag computation
  assign w_zero[0] = (l_res[7:0] == 8'h00)      ? 1'b1 : 1'b0;
  assign w_zero[1] = (l_res[15:8] == 8'h00)     ? 1'b1 : 1'b0;
  assign w_zero[2] = (l_res[31:16] == 16'h0000) ? 1'b1 : 1'b0;
  always@(l_alu or l_size or w_zero or r_z_flg)
  begin
    if (l_alu[3]) begin
      // Shifter
      case (l_size)
        2'b00   : w_z_flg <= w_zero[0];                         // Byte
        2'b01   : w_z_flg <= w_zero[0] & w_zero[1];             // Word
        default : w_z_flg <= w_zero[0] & w_zero[1] & w_zero[2]; // Long
      endcase
    end else begin
      // Adder & Logic
      case (l_size)
        2'b00   : w_z_flg <= w_zero[0];                         // Byte
        2'b01   : w_z_flg <= w_zero[0] & w_zero[1];             // Word
        default : w_z_flg <= w_zero[0] & w_zero[1] & r_z_flg;   // Long
      endcase
    end
  end

  // N flag computation
  always@(l_alu or l_size or l_res)
  begin
    if (l_alu[3]) begin
      // Shifter
      case (l_size)
        2'b00   : w_n_flg <= l_res[7];  // Byte
        2'b01   : w_n_flg <= l_res[15]; // Word
        default : w_n_flg <= l_res[31]; // Long
      endcase
    end else begin
      // Adder & Logic
      case (l_size)
        2'b00   : w_n_flg <= l_res[7];  // Byte
        2'b01   : w_n_flg <= l_res[15]; // Word
        default : w_n_flg <= l_res[15]; // Long
      endcase
    end
  end

  // Flag output control
  //  00 : keep (-)
  //  01 : update (*)
  //  10 : clear (0)
  //  11 : set (1)
  // 100 : update, clear only (.)
  always@(posedge rst or posedge clk)
  begin
    if (rst) begin
      cc_out  <= 5'b00100;
      r_z_flg <= 1'b0;
    end
    else begin
      // C flag update
      case (flg_c[1:0])
        2'b00 : cc_out[0] <= cc_out[0];
        2'b01 : cc_out[0] <= w_c_flg;
        2'b10 : cc_out[0] <= 1'b0;
        2'b11 : cc_out[0] <= 1'b1;
      endcase
      // V flag update
      case (flg_c[3:2])
        2'b00 : cc_out[1] <= cc_out[1];
        2'b01 : cc_out[1] <= w_v_flg;
        2'b10 : cc_out[1] <= 1'b0;
        2'b11 : cc_out[1] <= 1'b1;
      endcase
      // Z flag update
      case (flg_c[6:4])
        3'b000 : cc_out[2] <= cc_out[2];
        3'b001 : cc_out[2] <= w_z_flg;
        3'b010 : cc_out[2] <= 1'b0;
        3'b011 : cc_out[2] <= 1'b1;
        3'b100 : cc_out[2] <= cc_out[2];
        3'b101 : cc_out[2] <= w_z_flg & cc_out[2];
        3'b110 : cc_out[2] <= 1'b0;
        3'b111 : cc_out[2] <= 1'b1;
      endcase
      // N flag update
      case (flg_c[8:7])
        2'b00 : cc_out[3] <= cc_out[3];
        2'b01 : cc_out[3] <= w_n_flg;
        2'b10 : cc_out[3] <= 1'b0;
        2'b11 : cc_out[3] <= 1'b1;
      endcase
      // X flag update
      case (flg_c[10:9])
        2'b00 : cc_out[4] <= cc_out[4];
        2'b01 : cc_out[4] <= w_c_flg;
        2'b10 : cc_out[4] <= 1'b0;
        2'b11 : cc_out[4] <= 1'b1;
      endcase
      if ((!l_alu[3]) && (l_size == 2'b01))
        r_z_flg <= w_zero[0] & w_zero[1];
    end
  end
  // Zero flag from word result
  assign z_flg = w_zero[0] & w_zero[1];
  // Greater than from adder : not((V xor N) or Z)
  assign g_flg = ~((v_flg[1] ^ l_res[15]) | (w_zero[0] & w_zero[1]));

  // Carry input control
  // 0000 : keep       : KEEP
  // 0001 : 0          : CLR
  // 0010 : c_flg[1]   : C_ADD
  // 0011 : w_c_flg    : C_FLG
  // 0100 : X flag     : X_SR
  // 0101 : result[7]  : N_B
  // 0110 : result[15] : N_W
  // 0111 : N flag     : N_SR
  // 1000 : a_src[0]   : T0
  // 1001 : a_src[7]   : T7
  // 1010 : a_src[15]  : T15
  // 1100 : b_src[0]   : N0
  // 1101 : b_src[7]   : N7
  // 1110 : b_src[15]  : N15
  always@(posedge rst or posedge clk)
  begin
    if (rst)
      c_in <= 1'b0;
    else
      case (cin_c)
        4'b0000 : c_in <= c_in;      // Keep flag
        4'b0001 : c_in <= 1'b0;      // For ASL, LSL, LSR
        4'b0010 : c_in <= c_flg[1];  // For ADD.L, SUB.L
        4'b0011 : c_in <= w_c_flg;   // For ADDX, SUBX, ROXL, ROXR
        4'b0100 : c_in <= cc_out[4]; // X flag
        4'b0101 : c_in <= l_res[7];  // For EXT.W
        4'b0110 : c_in <= l_res[15]; // For EXT.L
        4'b0111 : c_in <= cc_out[3]; // N flag
        4'b1000 : c_in <= a_src[0];  // For ROR
        4'b1001 : c_in <= a_src[7];  // For ASR.B, ROL.B
        4'b1010 : c_in <= a_src[15]; // For ASR.W, ROL.W
        4'b1100 : c_in <= b_src[0];  // For ROR.B, ROR.W
        4'b1101 : c_in <= b_src[7];  // For ASR.B, ROL.B
        4'b1110 : c_in <= b_src[15]; // For ASR.W, ASR.L, ROL.W, ROL.L
        default : c_in <= 1'b0;
      endcase
  end

endmodule

module test
(
  // Clock and reset
  input             rst,    // CPU reset
  input             clk,    // CPU clock
  // Micro-instruction word
  input  [19:0]     inst_in,
  // Operand input
  input  [3:0]      flg_in, // Partial flags
  input  [15:0]     sr_in,  // Status register
  input  [15:0]     a_src,  // A operand
  input  [15:0]     ea1b,   // EA #1 bitfield
  input  [15:0]     extw,   // Extension word
  // Test output
  output reg        branch  // Branch taken
);

  always@(inst_in or flg_in or sr_in or a_src or ea1b or extw)
  begin
    case (inst_in[15:12])
      4'b0000 : branch <= inst_in[11] ^ sr_in[12]; // Address error
      4'b0001 : branch <= inst_in[11] ^ flg_in[1]; // Z_FLG : Partial zero (for CHK, Bcc and DBcc)
      4'b0010 : branch <= inst_in[11] ^ flg_in[2]; // N_FLG : Partial negative (for MULS, DIVS, ABCD and SBCD)
      4'b0011 : branch <= inst_in[11] ^ flg_in[3]; // G_FLG : Greater than (for CHK)
      4'b0100 : branch <= inst_in[11] ^ a_src[0];  // T[0] (for MOVEM)
      4'b0101 : branch <= inst_in[11] ^ ea1b[4];   // (An)+ addressing
      4'b0110 : branch <= inst_in[11] ^ ea1b[7];   // Dn/An addressing
      4'b0111 : branch <= inst_in[11] ^ extw[11];  // Long/Word for d8(An,Rn)
      4'b1000 : branch <= inst_in[11] ^ sr_in[1];  // V flag
      4'b1001 : branch <= inst_in[11] ^ sr_in[3];  // N flag
      4'b1010 : branch <= inst_in[11] ^ sr_in[5];  // Branch flag (for DBcc and Bcc)
      4'b1011 : branch <= inst_in[11] ^ sr_in[11]; // Interrupt flag
      4'b1100 : branch <= inst_in[11] ^ sr_in[13]; // Supervisor flag
      4'b1101 : branch <= inst_in[11] ^ sr_in[15]; // Trace flag
      default : branch <= 1'b1;                    // Always
    endcase
  end

endmodule

module loop
(
  // Clock and reset
  input             rst,     // CPU reset
  input             clk,     // CPU clock
  // Loop control
  input  [19:0]     inst_in,
  input             i_fetch, // Instruction fetch
  input  [5:0]      a_src,   // A source
  input  [10:0]     pc_in,   // PC input
  output [10:0]     pc_out,  // PC output
  output        reg branch,  // Loop taken
  output            skip,    // Loop skipped
  output [3:0]      lcount   // Loop count for MOVEM
);

  reg [10:0] r_loop_st;  // Loop start PC
  reg [10:0] r_loop_end; // Loop end PC
  reg  [5:0] r_loop_cnt; // Loop count
  reg        r_loop_ena; // Loop enable

  always @(posedge rst or posedge clk)
  begin
    if (rst) begin
      r_loop_st  <= 11'd0;
      r_loop_end <= 11'd0;
      r_loop_cnt <= 6'd0;
      r_loop_ena <= 1'b0;
      branch     <= 1'b0;
    end else begin
      // "LOOP" instruction is executed
      if (inst_in[19:17] == 3'b000) begin
        // Store current PC (start of loop)
        r_loop_st  = pc_in;
        // Store address field (end of loop)
        r_loop_end = inst_in[10:0];
        if (inst_in[11]) begin
          // "LOOPT"
          r_loop_cnt = a_src[5:0] - 6'd1;
          // Skipped if T = 0
          r_loop_ena = ~skip;
        end else begin
          // "LOOP16"
          r_loop_cnt = 6'd15;
          // Always executed
          r_loop_ena = 1'b1;
        end
      end
      if (r_loop_ena) begin
        if (i_fetch) begin
          // End of loop reached
          if (r_loop_end == pc_in)
            if (r_loop_cnt == 6'd0) begin
              // Loop count = 0 : exit loop
              branch     <= 1'b0;
              r_loop_ena <= 1'b0;
            end else begin
              // Loop count > 0 : go on
              branch     <= 1'b1;
              r_loop_cnt <= r_loop_cnt - 6'd1;
            end
          else
            branch <= 1'b0;
        end
      end else begin
        branch <= 1'b0;
      end
    end
  end
  
  // Loop start PC value
  assign pc_out = r_loop_st;
  // Loop skipped when T is null and "LOOPT" instruction
  assign skip   = (a_src[5:0] == 6'd0) ? inst_in[11] : 1'b0;
  // Loop count for MOVEM
  assign lcount = r_loop_cnt[3:0];

endmodule

// RAM registers
// -------------
// 0xFFD6 - 0xFFD7 : VBR
// 0xFFD8 - 0xFFD9 : TMP1
// 0xFFDA - 0xFFDB : TMP2
// 0xFFDC - 0xFFDD : USP
// 0xFFDE - 0xFFDF : SSP
// 0xFFE0 - 0xFFEF : D0 - D7
// 0xFFF0 - 0xFFFF : A0 - A7

// I/O registers
// -------------
// 0000 : VEC_HI (R/W)
// 0001 : VEC_LO (R/W)
// 0010 : PC_HI (R/W)
// 0011 : PC_LO (R/W)
// 0100 : EA1_HI (R/W)
// 0101 : EA1_LO (R/W)
// 0110 : EA2_HI (R/W)
// 0111 : EA2_LO (R/W)
// 1000 : IMM  (RO)
// 1001 : LSH  (R/W)
// 1010 : ACCL (R/W)
// 1011 : ACCH (R/W)
// 1100 : DEC_JMP (RO)
// 1101 : EA1_JMP (RO)
// 1110 : EA2_JMP (RO)
// 1111 : CPU_SR (R/W)

module mem_io
(
  // Clock and reset
  input             rst,      // CPU reset
  input             clk,      // CPU clock
  // Outside bus interface
  output reg        rd_ena,   // Read strobe
  output reg        wr_ena,   // Write strobe
  input             data_ack, // Data acknowledge
  output reg [1:0]  byte_ena, // Byte enable
  output reg [31:0] address,  // Address bus
  input      [15:0] rd_data,  // Data bus in
  output reg [15:0] wr_data,  // Data bus out
  // 68000 control
  output reg [2:0]  fc,       // Function code
  input      [2:0]  ipl_n,    // Interrupt level
  // I/O bus
  input             io_rd,    // I/O read strobe from J68 micro-core
  input             io_wr,    // I/O write strobe from J68 micro-core
  input             io_ext,   // External memory access
  input             io_reg,   // Read/write to CPU register
  output reg        io_rdy,   // Data ready to J68 micro-core
  output reg [15:0] io_din,   // Data to J68 micro-core
  input      [15:0] io_dout,  // Data from J68 micro-core
  input      [19:0] inst_in,  // Microcode word
  // ALU interface (MUL/DIV)
  input             cc_upd,   // Condition codes update
  input      [3:0]  alu_op,   // ALU operation
  input      [15:0] a_src,    // A source
  input      [15:0] b_src,    // B source
  output reg        v_flg,    // V flag from divide
  // Decoder data
  output     [15:0] insw,     // Instruction word
  output     [15:0] extw,     // Extension word
  output     [15:0] ea1b,     // EA #1 bitfield
  // Status register
  input      [4:0]  ccr_in,   // XNZVC 68000 flags
  output     [10:0] sr_out,   // Status register
  output reg [10:0] flg_c,    // Flag output control
  // Register access
  input      [3:0]  loop_cnt, // Loop count for MOVEM
  output reg [5:0]  reg_addr, // Register address
  output reg        reg_wr,   // Register write enable
  output reg [1:0]  reg_bena, // Register byte enable
  // Debug
  output     [31:0] dbg_pc,   // Program counter
  output            dbg_if    // Instruction fetch
);

  reg  [8:0]  r_vec_addr;     // Vector address (reg)
  reg  [31:0] r_pc_addr;      // Program counter (reg)
  reg  [31:0] r_ea1_addr;     // Effective address #1 (reg)
  reg  [31:0] r_ea2_addr;     // Effective address #2 (reg)
  reg  [7:0]  r_cpu_sr;       // Status register high byte (reg)
  wire [2:0]  w_int_nr;       // Interrupt number (wire)
  wire        w_cc_jump;      // Condition code jump flag (wire)
  wire [31:0] w_vec_addr;     // Vector address (wire)

  reg  [15:0] r_md_lsh;       // MUL/DIV left shifter (reg)
  reg  [31:0] r_md_acc;       // MUL/DIV accumulator (reg)
  wire [31:0] w_md_val;       // Multiplier/Divisor (wire)
  wire [31:0] w_md_res;       // MUL/DIV partial result (wire)
  wire        w_borrow;       // Subtract borrow

  reg  [15:0] r_ins_word;     // Instruction word
  wire        w_ins_rdy;      // Instruction word ready
  reg  [15:0] r_ext_word;     // Extension word
  wire        w_ext_rdy;      // Extension word ready
  reg  [15:0] r_imm_word;     // Immediate word
  wire        w_imm_rdy;      // Immediate word ready
  wire [15:0] w_imm_val;      // Immediate value
  wire [11:0] w_dec_jump;     // Decoder call address
  wire [3:0]  w_ea1_jump;     // EA #1 jump table index
  wire [3:0]  w_ea2_jump;     // EA #2 jump table index

  reg         r_io_ext;       // Delayed io_ext
  reg         r_mem_rd;       // Memory read (reg)
  reg         r_mem_wr;       // Memory write (reg)
  reg         r_mem_err;      // Address error during data access (reg)
  reg  [31:0] r_err_addr;     // Address that caused an address error (reg)
  reg  [15:0] r_err_inst;     // Opcode executed during an address error (reg)
  reg  [4:0]  r_err_cpu;      // CPU state during an address error (reg)
  reg  [31:0] w_mem_addr;     // Memory address (wire)
  reg  [2:0]  w_mem_inc;      // Memory address increment (wire)
  wire        w_sp_inc;       // Memory increment for stack access (wire)
  wire [3:0]  w_loop_cnt;     // Loop count for MOVEM
  reg  [1:0]  r_ctr;

  assign dbg_pc = r_pc_addr;

  assign w_sp_inc = ((r_ins_word[2:0]  == 3'b111) && (inst_in[1:0] == 2'b00)) // EA1 with A7
                 || ((r_ins_word[11:9] == 3'b111) && (inst_in[1:0] == 2'b01)) // EA2 with A7
                  ? 1'b1 : 1'b0;
  
  // Address MUX and increment
  always@(inst_in or w_sp_inc or r_ea1_addr or r_ea2_addr or r_pc_addr or w_vec_addr)
  begin
    case (inst_in[1:0]) // addr field
      2'b00 : w_mem_addr <= r_ea1_addr; // Read/write EA1 data
      2'b01 : w_mem_addr <= r_ea2_addr; // Read/write EA2 data
      2'b10 : w_mem_addr <= r_pc_addr;  // Fetch instruction
      2'b11 : w_mem_addr <= w_vec_addr; // Fetch vector
    endcase
    case ({inst_in[10]|inst_in[11], inst_in[3:2]}) // size & incr fields
      3'b000 : w_mem_inc <= 3'b000;     // No increment, byte
      3'b001 : if (w_sp_inc)
                 w_mem_inc <= 3'b010;   // Post increment, word (stack)
               else
                 w_mem_inc <= 3'b001;   // Post increment, byte
      3'b010 : if (w_sp_inc)
                 w_mem_inc <= 3'b110;   // Pre decrement, word (stack)
               else
                 w_mem_inc <= 3'b111;   // Pre decrement, byte
      3'b011 : if (w_sp_inc)
                 w_mem_inc <= 3'b010;   // Pre increment, word (stack)
               else
                 w_mem_inc <= 3'b001;   // Pre increment, byte
      3'b100 : w_mem_inc <= 3'b000;     // No increment, word
      3'b101 : w_mem_inc <= 3'b010;     // Post increment, word
      3'b110 : w_mem_inc <= 3'b110;     // Pre decrement, word
      3'b111 : w_mem_inc <= 3'b010;     // Pre increment, word
    endcase
  end
  assign w_vec_addr = { 22'd0, r_vec_addr, 1'b0 };

  // Registers read
  always@(posedge rst or posedge clk)
  begin
    if (rst) begin
      r_ins_word <= 16'h0000;
      r_ext_word <= 16'h0000;
      r_imm_word <= 16'h0000;
      io_din     <= 16'h0000;
      io_rdy     <= 1'b0;
      r_ctr      <= 2'b00;
    end else begin
      if (io_rd) begin
        case (inst_in[3:0])
          // Effective address #1
          4'b0000 : io_din <= r_ea1_addr[15:0];
          4'b0001 : io_din <= r_ea1_addr[31:16];
          // Effective address #2
          4'b0010 : io_din <= r_ea2_addr[15:0];
          4'b0011 : io_din <= r_ea2_addr[31:16];
          // Program
          4'b0100 : io_din <= r_pc_addr[15:0];
          4'b0101 : io_din <= r_pc_addr[31:16];
          // Vectors
          4'b0110 :
          begin
            io_din <= { 5'b00000, r_vec_addr[3:1], 8'h00 };
            r_ctr  <= 2'b00;
          end
          // CPU state
          4'b0111 :
          begin
            case (r_ctr)
              2'b00 : io_din <= r_err_inst;
              2'b01 : io_din <= r_err_addr[15:0];
              2'b10 : io_din <= r_err_addr[31:16];
              2'b11 : io_din <= {11'b0, r_err_cpu };
            endcase
            r_ctr <= r_ctr + 2'd1;
          end
          // Immediate value
          4'b1000 : io_din <= w_imm_val;
          // MUL/DIV left shifter
          4'b1001 : io_din <= r_md_lsh;
          // MUL/DIV accumulator
          4'b1010 : io_din <= r_md_acc[15:0];
          4'b1011 : io_din <= r_md_acc[31:16];
          // Jump table indexes
          4'b1100 : io_din <= {  4'd0, w_dec_jump };
          4'b1101 : io_din <= { 12'd0, w_ea1_jump };
          4'b1110 : io_din <= { 12'd0, w_ea2_jump };
          // Status register : T-S--III---XNZVC
          4'b1111 : io_din <= { r_cpu_sr[7], 1'b0, r_cpu_sr[5], 2'b00, r_cpu_sr[2:0], 3'b000, ccr_in };
          default : io_din <= 16'h0000;
        endcase
      end else if ((r_mem_rd) && (data_ack)) begin
        // Memory read
        case ({ inst_in[11:10], address[0] })
          // Byte, even addr. :    ---            use
          3'b000 : io_din <= {  rd_data[7:0], rd_data[15:8] };
          // Byte, odd addr.  :    ---            use
          3'b001 : io_din <= { rd_data[15:8],  rd_data[7:0] };
          // Word, even addr. :    use            use
          3'b010 : io_din <= { rd_data[15:8],  rd_data[7:0] };
          // Word, odd addr.  :      !! exception !!
          3'b011 : io_din <= { rd_data[15:8],  rd_data[7:0] };
          // LSB, even addr.  :    ---            use
          3'b100 : io_din <= {  8'b0000_0000, rd_data[15:8] };
          // LSB, odd addr.   :    ---            use
          3'b101 : io_din <= {  8'b0000_0000,  rd_data[7:0] };
          // MSB, even addr.  :    use            ---
          3'b110 : io_din <= { rd_data[15:8],  8'b0000_0000 };
          // MSB, odd addr.   :    use            ---
          3'b111 : io_din <= {  rd_data[7:0],  8'b0000_0000 };
        endcase
        // Instruction fetch
        if (inst_in[1:0] == 2'b10)
          case (inst_in[3:2])
            2'b00   : r_ins_word <= rd_data; // Fetching instruction
            2'b01   : r_ext_word <= rd_data; // Fetching extension word
            default : r_imm_word <= rd_data; // Fetching immediate data
          endcase
      end else begin
        io_din <= 16'h0000;
      end
      // Ready signal for register read, memory read and write
      io_rdy <= io_rd | (r_mem_rd & data_ack) | (r_mem_wr & data_ack) | r_mem_err;
    end
  end
  // Status bits for the test module : T-SaeIII--b
  assign sr_out[10]  = r_cpu_sr[7];           // Trace
  assign sr_out[9]   = 1'b0;                  // Not used
  assign sr_out[8]   = r_cpu_sr[5];           // Supervisor
  assign sr_out[7]   = r_cpu_sr[4]|r_mem_err; // Address error (internal)
  assign sr_out[6]   = r_cpu_sr[3]|r_cpu_sr[4]|r_mem_err; // Exception (internal)
  assign sr_out[5:3] = r_cpu_sr[2:0];         // Interrupt level
  assign sr_out[2:1] = 2'b00;                 // Not used
  assign sr_out[0]   = w_cc_jump;             // Branch flag

  // Registers writes
  always@(posedge rst or posedge clk)
  begin
    if (rst) begin
      r_vec_addr <= 9'd0;
      r_pc_addr  <= 32'd0;
      r_ea1_addr <= 32'd0;
      r_ea2_addr <= 32'd0;
      r_md_lsh   <= 16'd0;
      r_md_acc   <= 32'd0;
      v_flg      <= 1'b0;
      r_cpu_sr   <= 8'b00100111;
      flg_c      <= 11'b00_00_000_00_00;
    end else begin
      if (io_wr) begin
        case (inst_in[3:0])
          // Effective address #1 (and #2 for RMW cycles)
          4'b0000 :
          begin
            r_ea1_addr[15:0]  <= io_dout;
            r_ea2_addr[15:0]  <= io_dout;
          end
          4'b0001 :
          begin
            r_ea1_addr[31:16] <= io_dout;
            r_ea2_addr[31:16] <= io_dout;
          end
          // Effective address #2
          4'b0010 : r_ea2_addr[15:0]  <= io_dout;
          4'b0011 : r_ea2_addr[31:16] <= io_dout;
          // Program
          4'b0100 : r_pc_addr[15:0]   <= io_dout;
          4'b0101 : r_pc_addr[31:16]  <= io_dout;
          // Vectors
          4'b0110 :
          begin
            r_vec_addr        <= { io_dout[9:2], 1'b0 };
            r_cpu_sr[4]       <= 1'b0; // Clear address error
          end
          4'b0111 : ; // No VBR on 68000, vector address is 9-bit long !
          // MUL/DIV left shifer
          4'b1001 : r_md_lsh          <= io_dout;
          // MUL/DIV accumulator
          4'b1010 : r_md_acc[15:0]    <= io_dout;
          4'b1011 : r_md_acc[31:16]   <= io_dout;
          // Status register
          4'b1111 :
          begin
            // MSB (word write)
            if (inst_in[10]) begin
              r_cpu_sr[7]   <= io_dout[15];   // Trace
              r_cpu_sr[6]   <= 1'b0;
              r_cpu_sr[5]   <= io_dout[13];   // Supervisor
              r_cpu_sr[2:0] <= io_dout[10:8]; // Interrupt mask
            end
            // LSB
            flg_c[10]     <= 1'b1;
            flg_c[9]      <= io_dout[4];    // Extend flag
            flg_c[8]      <= 1'b1;
            flg_c[7]      <= io_dout[3];    // Negative flag
            flg_c[6]      <= 1'b0;
            flg_c[5]      <= 1'b1;
            flg_c[4]      <= io_dout[2];    // Zero flag
            flg_c[3]      <= 1'b1;
            flg_c[2]      <= io_dout[1];    // Overflow flag
            flg_c[1]      <= 1'b1;
            flg_c[0]      <= io_dout[0];    // Carry flag
          end
          default : ;
        endcase
      end else begin
        flg_c <= 11'b00_00_000_00_00;

        // Memory control
        if ((io_ext) && (!r_io_ext)) begin
          // Auto-increment/decrement
          case (inst_in[1:0]) // addr field
            2'b00 : r_ea1_addr <= r_ea1_addr + { {29{w_mem_inc[2]}}, w_mem_inc };
            2'b01 : r_ea2_addr <= r_ea2_addr + { {29{w_mem_inc[2]}}, w_mem_inc };
            2'b10 : r_pc_addr  <= r_pc_addr  + 32'd2;
            2'b11 : r_vec_addr <= r_vec_addr + 9'd1;
          endcase
        end
        
        // Multiply/divide step (right shift special)
        if (alu_op[3:1] == 3'b111) begin
          // Accumulator
          if ((alu_op[0]) || (w_borrow))
            r_md_acc <= w_md_res;
          // Left shifter
          r_md_lsh <= { r_md_lsh[14:0], w_borrow };
          // V flag
          if (cc_upd) v_flg <= r_md_lsh[15];
        end
        
        // Interrupts management
        if (((w_int_nr > r_cpu_sr[2:0]) || (w_int_nr == 3'd7)) && (w_int_nr >= r_vec_addr[3:1]) && (r_vec_addr[8:4] == 5'b00011)) begin
          r_cpu_sr[3] <= 1'b1;
          r_vec_addr  <= { 5'b00011, w_int_nr, 1'b0 };
        end else begin
          r_cpu_sr[3] <= r_cpu_sr[4] | r_cpu_sr[7]; // Address error or trace mode
        end
        
        // Latch address error flag
        if (r_mem_err) r_cpu_sr[4] <= 1'b1;
      end
    end
  end
  // Interrupt number
  assign w_int_nr = ~ipl_n;
  
  // Multiply/divide step
  assign w_md_val = (r_md_lsh[15]) || (!alu_op[0]) ? { b_src, a_src } : 32'd0;
  addsub_32 addsub_inst
  (
    .add_sub(alu_op[0]),
    .dataa(r_md_acc),
    .datab(w_md_val),
    .cout(w_borrow),
    .result(w_md_res)
  );
  
  // Debug : instruction fetch signal
  assign dbg_if = (inst_in[3:0] == 4'b0010) ? io_ext & ~r_io_ext : 1'b0;

  // Memory access
  always@(posedge rst or posedge clk)
  begin
    if (rst) begin
      r_io_ext   <= 1'b0;
      address    <= 32'd0;
      r_mem_rd   <= 1'b0;
      rd_ena     <= 1'b0;
      r_mem_wr   <= 1'b0;
      wr_ena     <= 1'b0;
      byte_ena   <= 2'b00;
      r_mem_err  <= 1'b0;
      r_err_addr <= 32'd0;
      r_err_inst <= 16'h0000;
      r_err_cpu  <= 5'b00000;
      wr_data    <= 16'h0000;
    end else begin
      // Delayed io_ext
      r_io_ext <= io_ext;
      // Memory address and data output
      if ((io_ext) && (!r_io_ext) && ((!inst_in[3]) || (inst_in[1]))) begin
        // No or Post increment
        address <= w_mem_addr;
        // Function code
        fc[2] <= r_cpu_sr[5];       // 0 : User, 1 : Supervisor
        case (inst_in[1:0])
          2'b00 : fc[1:0] <= 2'b01; // EA1    : data
          2'b01 : fc[1:0] <= 2'b01; // EA2    : data
          2'b10 : fc[1:0] <= 2'b10; // PC     : program
          2'b11 : fc[1:0] <= 2'b11; // Vector : CPU
        endcase
        // Memory write
        case ({ inst_in[11:10], w_mem_addr[0] })
          // Byte, even addr. :     ---            use
          3'b000 : wr_data <= {  io_dout[7:0], io_dout[15:8] };
          // Byte, odd addr.  :     ---            use
          3'b001 : wr_data <= { io_dout[15:8],  io_dout[7:0] };
          // Word, even addr. :     use            use
          3'b010 : wr_data <= { io_dout[15:8],  io_dout[7:0] };
          // Word, odd addr.  :      !! exception !!
          3'b011 : wr_data <= { io_dout[15:8],  io_dout[7:0] };
          // LSB, even addr.  :    use            ---
          3'b100 : wr_data <= {  io_dout[7:0], io_dout[15:8] };
          // LSB, odd addr.   :    ---            use
          3'b101 : wr_data <= { io_dout[15:8],  io_dout[7:0] };
          // MSB, even addr.  :    use            ---
          3'b110 : wr_data <= { io_dout[15:8],  io_dout[7:0] };
          // MSB, odd addr.   :    ---            use
          3'b111 : wr_data <= {  io_dout[7:0], io_dout[15:8] };
        endcase
      end else if ((r_io_ext) && (inst_in[3]) && (!inst_in[1])) begin
        address <= w_mem_addr; // Pre decrement/increment
        // Function code
        fc[2] <= r_cpu_sr[5];       // 0 : User, 1 : Supervisor
        case (inst_in[1:0])
          2'b00 : fc[1:0] <= 2'b01; // EA1    : data
          2'b01 : fc[1:0] <= 2'b01; // EA2    : data
          2'b10 : fc[1:0] <= 2'b10; // PC     : program
          2'b11 : fc[1:0] <= 2'b11; // Vector : CPU
        endcase
        // Memory write
        case ({ inst_in[11:10], w_mem_addr[0] })
          // Byte, even addr. :     ---            use
          3'b000 : wr_data <= {  io_dout[7:0], io_dout[15:8] };
          // Byte, odd addr.  :     ---            use
          3'b001 : wr_data <= { io_dout[15:8],  io_dout[7:0] };
          // Word, even addr. :     use            use
          3'b010 : wr_data <= { io_dout[15:8],  io_dout[7:0] };
          // Word, odd addr.  :      !! exception !!
          3'b011 : wr_data <= { io_dout[15:8],  io_dout[7:0] };
          // LSB, even addr.  :    use            ---
          3'b100 : wr_data <= {  io_dout[7:0], io_dout[15:8] };
          // LSB, odd addr.   :    ---            use
          3'b101 : wr_data <= { io_dout[15:8],  io_dout[7:0] };
          // MSB, even addr.  :    use            ---
          3'b110 : wr_data <= { io_dout[15:8],  io_dout[7:0] };
          // MSB, odd addr.   :    ---            use
          3'b111 : wr_data <= {  io_dout[7:0], io_dout[15:8] };
        endcase
      end
      // Read, write and byte strobes
      if ((io_ext) && (!r_io_ext)) begin
        r_mem_rd <= inst_in[7];
        r_mem_wr <= inst_in[6];
        case ({ inst_in[11:10], w_mem_addr[0] })
          3'b000 : byte_ena <= { ~(inst_in[3] & ~inst_in[1]), (inst_in[3] & ~inst_in[1]) };
          3'b001 : byte_ena <= { (inst_in[3] & ~inst_in[1]), ~(inst_in[3] & ~inst_in[1]) };
          3'b010 : byte_ena <= 2'b11;
          3'b011 : // Word access at odd address !!
          begin
            byte_ena   <= 2'b00;               // No read/write
            r_mem_err  <= 1'b1;                // Address error
            r_err_addr <= w_mem_addr;          // Keep EA value
            r_err_inst <= r_ins_word;          // Keep opcode
            case (inst_in[1:0])
              2'b00 : r_err_cpu[1:0] <= 2'b01; // EA1    : data
              2'b01 : r_err_cpu[1:0] <= 2'b01; // EA2    : data
              2'b10 : r_err_cpu[1:0] <= 2'b10; // PC     : program
              2'b11 : r_err_cpu[1:0] <= 2'b11; // Vector : CPU
            endcase
            r_err_cpu[2] <= r_cpu_sr[5];       // 0 : User, 1 : Supervisor
            r_err_cpu[3] <= 1'b0;              // Instruction identified
            r_err_cpu[4] <= inst_in[7];        // 0 : Write, 1 : Read
          end
          3'b100 : byte_ena <= 2'b10;
          3'b101 : byte_ena <= 2'b01;
          3'b110 : byte_ena <= 2'b10;
          3'b111 : byte_ena <= 2'b01;
        endcase
      end
      // Keep PC value for address error exception
      if ((io_wr) && (inst_in[3:1] == 3'b010)) begin
        if (inst_in[0])
          r_err_addr[31:16] <= io_dout;
        else
          r_err_addr[15:0]  <= io_dout;
        // Address error if odd address on PC
        if ((!inst_in[0]) && (io_dout[0])) begin
          r_mem_err  <= 1'b1;       // Address error
          r_err_inst <= r_ins_word; // Keep opcode
          r_err_cpu  <= { 2'b10, r_cpu_sr[5], 2'b10 };
        end
      end
      // End of memory cycle : acknowledge or error
      if ((data_ack) || (r_mem_err)) begin
        r_mem_rd  <= 1'b0;
        rd_ena    <= 1'b0;
        r_mem_wr  <= 1'b0;
        wr_ena    <= 1'b0;
        byte_ena  <= 2'b00;
        r_mem_err <= 1'b0;
        fc        <= { r_cpu_sr[5], 2'b00 }; // No access
      end else begin
        rd_ena    <= (inst_in[7] & (~inst_in[3] | inst_in[1]) & io_ext) | r_mem_rd;
        wr_ena    <= (inst_in[6] & (~inst_in[3] | inst_in[1]) & io_ext) | r_mem_wr;
      end
    end
  end

  // Instruction decoder
  //assign w_ins_rdy = (inst_in[3:0] == 4'b0010) ? (data_ack & r_mem_rd & r_io_ext) : 1'b0;
  assign w_ins_rdy = (inst_in[3:0] == 4'b0010) ? (io_rdy & r_io_ext) : 1'b0;
  assign w_ext_rdy = (inst_in[3:0] == 4'b0110) ? (io_rdy & r_io_ext) : 1'b0;
  assign w_imm_rdy = (inst_in[3:0] == 4'b1010) ? (io_rdy & r_io_ext) : 1'b0;

  decode decode_inst
  (
    .rst(rst),
    .clk(clk),
    .ins_rdy(w_ins_rdy),
    .instr(r_ins_word),
    .ext_rdy(w_ext_rdy),
    .ext_wd(r_ext_word),
    .imm_rdy(w_imm_rdy),
    .imm_wd(r_imm_word),
    .user_mode(~r_cpu_sr[5]),
    .ccr_in(ccr_in[3:0]),
    .dec_jmp(w_dec_jump),
    .ea1_jmp(w_ea1_jump),
    .ea2_jmp(w_ea2_jump),
    .imm_val(w_imm_val),
    .ea1_bit(ea1b),
    .cc_jmp(w_cc_jump),
    .ext_inst(),
    .bit_inst(),
    .vld_inst()
  );
  assign insw = r_ins_word;
  assign extw = r_ext_word;
  
  // Registers access
  assign w_loop_cnt = ea1b[4] ? loop_cnt : ~loop_cnt;
  always@(io_reg or inst_in or r_ins_word or r_ext_word or w_loop_cnt)
  begin
    case (inst_in[3:0])
      4'b0000 : reg_addr <= { 2'b10,  r_ins_word[2:0],                 inst_in[8] }; // D[EA1]
      4'b0001 : reg_addr <= { 2'b11,  r_ins_word[2:0],                 inst_in[8] }; // A[EA1]
      4'b0010 : reg_addr <= { 1'b1,   r_ins_word[3:0],                 inst_in[8] }; // R[EA1]
      4'b0011 : reg_addr <= { 5'b11111,                                inst_in[8] }; // A7
      4'b0100 : reg_addr <= { 2'b10,  r_ins_word[11:9],                inst_in[8] }; // D[EA2]
      4'b0101 : reg_addr <= { 2'b11,  r_ins_word[11:9],                inst_in[8] }; // A[EA2]
      4'b0110 : reg_addr <= { 1'b1,   r_ins_word[6], r_ins_word[11:9], inst_in[8] }; // R[EA2]
      4'b0111 : reg_addr <= { 1'b1,   w_loop_cnt,                      inst_in[8] }; // R[CNT]
      4'b1000 : reg_addr <= { 2'b10,  r_ext_word[14:12],               inst_in[8] }; // D[EXT]
      4'b1001 : reg_addr <= { 2'b11,  r_ext_word[14:12],               inst_in[8] }; // A[EXT]
      4'b1010 : reg_addr <= { 1'b1,   r_ext_word[15:12],               inst_in[8] }; // R[EXT]
      default : reg_addr <= { 2'b01,  inst_in[2:0],                    inst_in[8] }; // VBR, TMP1, TMP2, USP, SSP
    endcase
    reg_wr      <= inst_in[6] & io_reg;
    reg_bena[0] <= io_reg;
    reg_bena[1] <= inst_in[10] & io_reg;
  end

endmodule

module decode
(
  input             rst,
  input             clk,
  input             ins_rdy,
  input      [15:0] instr,
  input             ext_rdy,
  input      [15:0] ext_wd,
  input             imm_rdy,
  input      [15:0] imm_wd,
  input             user_mode,
  input      [3:0]  ccr_in,
  output     [11:0] dec_jmp,
  output     [3:0]  ea1_jmp,
  output     [3:0]  ea2_jmp,
  output reg [15:0] imm_val,
  output     [15:0] ea1_bit,
  output reg        cc_jmp,
  output            ext_inst,
  output            bit_inst,
  output            vld_inst
);
  // $FE00 - $FEFF : Instruction decoder jump table
  // $FF00 - $FF1F : Empty
  // $FF20 - $FF2F : EA1 read BYTE jump table
  // $FF30 - $FF3F : EA1 read WORD jump table
  // $FF40 - $FF4F : EA1 read LONG jump table
  // $FF50 - $FF5F : EA1 calculation jump table
  // $FF60 - $FF6F : EA1 write BYTE jump table
  // $FF70 - $FF7F : EA1 write WORD jump table
  // $FF80 - $FF8F : EA1 write LONG jump table
  // $FF90 - $FF9F : EA2 write BYTE jump table
  // $FFA0 - $FFAF : EA2 write WORD jump table
  // $FFB0 - $FFBF : EA2 write LONG jump table
  // $FFC0 - $FFCF : Bit masks
  // $FFD0 - $FFD5 : Empty
  // $FFD6 - $FFD7 : VBR
  // $FFD8 - $FFD9 : TMP1
  // $FFDA - $FFDB : TMP2
  // $FFDC - $FFDD : USP
  // $FFDE - $FFDF : SSP
  // $FFE0 - $FFEF : Data registers (D0 - D7)
  // $FFF0 - $FFFF : Address registers (A0 - A7)


  // +---------------------+-------+----------------+------------------+
  // |        Index        |       |                |                  |
  // | Decimal  |  Binary  | Group | Description    | Op-code          |
  // +----------+----------+-------+----------------+------------------+
  // |   0..63  | 00xxxxxx |   4   | miscellaneous  | 0100111001xxxxxx |
  // |  64..95  | 010xxxxx |   0   | immediate      | 0000xxx0xx------ |
  // |  96..127 | 011xxxxx |   4   | one operand    | 0100xxx0xx------ |
  // | 128..143 | 1000xxxx |   E   | shift byte reg | 1110---x00xxx--- |
  // | 144..159 | 1001xxxx |   E   | shift word reg | 1110---x01xxx--- |
  // | 160..175 | 1010xxxx |   E   | shift long reg | 1110---x10xxx--- |
  // |    177   | 10110001 |   1   | MOVE.B         | 0001------------ |
  // |    178   | 10110010 |   2   | MOVE.L         | 0010------------ |
  // |    179   | 10110011 |   3   | MOVE.W         | 0011------------ |
  // |    182   | 10110110 |   6   | Bcc            | 0110------------ |
  // |    183   | 10110111 |   7   | MOVEQ          | 0111------------ |
  // |    186   | 10111010 |   A   | Line A         | 1010------------ |
  // |    191   | 10111111 |   F   | Line F         | 1111------------ |
  // | 192..199 | 11000xxx |   8   | OR/DIVx        | 1000---xxx------ |
  // | 200..207 | 11001xxx |   9   | SUB            | 1001---xxx------ |
  // | 208..215 | 11010xxx |   5   | ADDQ/SUBQ      | 0101---xxx------ |
  // | 216..223 | 11011xxx |   B   | CMP/EOR        | 1011---xxx------ |
  // | 224..231 | 11100xxx |   C   | AND/MULx       | 1100---xxx------ |
  // | 232..239 | 11101xxx |   D   | ADD            | 1101---xxx------ |
  // | 240..247 | 11110xxx |   E   | shift memory   | 1110---011xxx--- |
  // | 248..251 | 111110xx |   0   | bit operation  | 0000---1xx------ |
  // | 252..255 | 111111xx |   4   | two operands   | 0100---1xx------ |
  // +----------+----------+-------+----------------+------------------+
  
  // Trap routines addresses
  `define OP_PRIVILEDGED 12'h036
  `define OP_ILLEGAL     12'h038

  // Instructions groups
  wire [15:0] w_grp_p0;

  // Effective address bitfields
  wire [15:0] w_ea1b_p0;      // EA #1
  reg  [15:0] r_ea1b_p1;
  wire [9:0]  w_ea2b_p0;      // EA #2 

  // Jump table indexes
  wire [3:0]  w_ea1_jmp_p0;   // EA #1
  reg  [3:0]  r_ea1_jmp_p1;
  //reg  [3:0]  r_ea1_jmp_p2;
  wire [3:0]  w_ea2_jmp_p0;   // EA #2
  reg  [3:0]  r_ea2_jmp_p1;
  //reg  [3:0]  r_ea2_jmp_p2;

  // Instructions sub-groups
  wire        w_g0_immed_p0;
  wire        w_g0_bitimm_p0;
  wire        w_g0_bitop_p0;
  wire        w_g4_misc_p0;
  wire        w_g4_oneop_p0;
  wire        w_g4_twoop_p0;
  wire        w_g5_addsub_p0;
  wire        w_g6_bsr_p0;
  wire        w_gE_shmem_p0;
  wire        w_gE_shreg_p0;

  // NEGX, ADDX, SUBX, NBCD, ABCD, SBCD
  wire        w_g4_nbcd_p0;
  wire        w_g8_sbcd_p0;
  wire        w_gC_abcd_p0;
  wire        w_g4_negx_p0;
  wire        w_g9_subx_p0;
  wire        w_gD_addx_p0;
  
  // Pre-decode
  wire        w_ill_ins_p0;   // Illegal instruction
  reg         r_ill_ins_p1;
  wire        w_prv_ins_p0;   // Priviledged instruction
  reg         r_prv_ins_p1;
  wire        w_ext_ins_p0;   // Special Z flag treatment
  reg         r_ext_ins_p1;
  //reg         r_ext_ins_p2;
  wire        w_bit_ins_p0;   // Bit manipulation instructions
  reg         r_bit_ins_p1;
  //reg         r_bit_ins_p2;
  reg         w_vld_ins_p1;   // Valid instruction
  reg         r_vld_ins_p2;
  
  // Call address
  wire        w_call1_ena_p0; // Jump table call #1 enable
  wire        w_call2_ena_p0; // Jump table call #2 enable
  reg  [1:0]  r_call_en_p1;
  reg  [11:0] r_call_p2;

  // Indexes
  wire [5:0]  w_idx6_5_0_p0;  // 5..0
  wire [5:0]  w_idx5_B_6_p0;  // 11..9, 7..6
  wire [5:0]  w_idx4_8_3_p0;  // 8, 5..3
  wire [5:0]  w_idx4_F_C_p0;  // 15..12
  wire [5:0]  w_idx3_8_6_p0;  // 8..6
  wire [5:0]  w_idx3_A_8_p0;  // 10..8
  wire [5:0]  w_idx2_7_6_p0;  // 7..6

  // Decoder ROM
  wire [7:0]  w_addr_p0;      // Decoder ROM address
  wire [35:0] w_data_p1;      // Decoder ROM data
  reg  [15:0] w_ea1m_p1;      // Effective address #1 mask
  reg  [5:0]  w_incr_p1;      // Call address increment
  reg  [11:0] w_call_p1;      // Call address

  // Immediate values
  wire [15:0] w_imm3_i;       // For ADDQ, SUBQ, Shift reg
  wire [15:0] w_imm4_i;       // For TRAP
  wire [15:0] w_imm8_i;       // For MOVEQ, Bcc.B
  wire [15:0] w_imm5_e;       // For BTST, BCHG, BCLR, BSET
  wire [15:0] w_imm8_e;       // For d8(An, Rn), d8(PC, Rn)

  // Instructions groups decode
  assign w_grp_p0[0]    = (instr[15:12] == 4'b0000) ? 1'b1 : 1'b0; // Immed
  assign w_grp_p0[1]    = (instr[15:12] == 4'b0001) ? 1'b1 : 1'b0; // MOVE.B
  assign w_grp_p0[2]    = (instr[15:12] == 4'b0010) ? 1'b1 : 1'b0; // MOVE.L
  assign w_grp_p0[3]    = (instr[15:12] == 4'b0011) ? 1'b1 : 1'b0; // MOVE.W
  assign w_grp_p0[4]    = (instr[15:12] == 4'b0100) ? 1'b1 : 1'b0; // Misc
  assign w_grp_p0[5]    = (instr[15:12] == 4'b0101) ? 1'b1 : 1'b0; // ADDQ, SUBQ
  assign w_grp_p0[6]    = (instr[15:12] == 4'b0110) ? 1'b1 : 1'b0; // Bcc
  assign w_grp_p0[7]    = (instr[15:12] == 4'b0111) ? 1'b1 : 1'b0; // MOVEQ
  assign w_grp_p0[8]    = (instr[15:12] == 4'b1000) ? 1'b1 : 1'b0; // OR, DIV
  assign w_grp_p0[9]    = (instr[15:12] == 4'b1001) ? 1'b1 : 1'b0; // SUB
  assign w_grp_p0[10]   = (instr[15:12] == 4'b1010) ? 1'b1 : 1'b0; // Line A
  assign w_grp_p0[11]   = (instr[15:12] == 4'b1011) ? 1'b1 : 1'b0; // CMP, EOR
  assign w_grp_p0[12]   = (instr[15:12] == 4'b1100) ? 1'b1 : 1'b0; // AND, MUL
  assign w_grp_p0[13]   = (instr[15:12] == 4'b1101) ? 1'b1 : 1'b0; // ADD
  assign w_grp_p0[14]   = (instr[15:12] == 4'b1110) ? 1'b1 : 1'b0; // Shift
  assign w_grp_p0[15]   = (instr[15:12] == 4'b1111) ? 1'b1 : 1'b0; // Line F

  // Effective addresses #1 bitfield
  assign w_ea1b_p0[15]  = (instr[5:0] == 6'b111111) ? 1'b1 : 1'b0; // ???
  assign w_ea1b_p0[14]  = (instr[5:0] == 6'b111110) ? 1'b1 : 1'b0; // ???
  assign w_ea1b_p0[13]  = (instr[5:0] == 6'b111101) ? 1'b1 : 1'b0; // ???
  assign w_ea1b_p0[12]  = (instr[5:0] == 6'b111100) ? 1'b1 : 1'b0; // #imm, CCR/SR
  assign w_ea1b_p0[11]  = (instr[5:0] == 6'b111011) ? 1'b1 : 1'b0; // d8(PC,Rn)
  assign w_ea1b_p0[10]  = (instr[5:0] == 6'b111010) ? 1'b1 : 1'b0; // d16(PC)
  assign w_ea1b_p0[9]   = (instr[5:0] == 6'b111001) ? 1'b1 : 1'b0; // xxxxxxxx.L
  assign w_ea1b_p0[8]   = (instr[5:0] == 6'b111000) ? 1'b1 : 1'b0; // xxxx.W
  assign w_ea1b_p0[7]   = (instr[5:4] == 2'b00)     ? 1'b1 : 1'b0; // Bcc.W
  assign w_ea1b_p0[6]   = (instr[5:3] == 3'b110)    ? 1'b1 : 1'b0; // d8(An,Rn)
  assign w_ea1b_p0[5]   = (instr[5:3] == 3'b101)    ? 1'b1 : 1'b0; // d16(An)
  assign w_ea1b_p0[4]   = (instr[5:3] == 3'b100)    ? 1'b1 : 1'b0; // -(An)
  assign w_ea1b_p0[3]   = (instr[5:3] == 3'b011)    ? 1'b1 : 1'b0; // (An)+
  assign w_ea1b_p0[2]   = (instr[5:3] == 3'b010)    ? 1'b1 : 1'b0; // (An)
  assign w_ea1b_p0[1]   = (instr[5:3] == 3'b001)    ? 1'b1 : 1'b0; // An
  assign w_ea1b_p0[0]   = (instr[5:3] == 3'b000)    ? 1'b1 : 1'b0; // Dn

  // Effective addresses #2 bitfield
  assign w_ea2b_p0[9]   = (instr[8:6]  == 3'b111) 
                       && (instr[11:10] != 2'b00)    ? 1'b1 : 1'b0; // ???
  assign w_ea2b_p0[8]   = (instr[11:6] == 6'b001111) ? 1'b1 : 1'b0; // xxxxxxxx.L
  assign w_ea2b_p0[7]   = (instr[11:6] == 6'b000111) ? 1'b1 : 1'b0; // xxxx.W
  assign w_ea2b_p0[6]   = (instr[8:6]  == 3'b110)    ? 1'b1 : 1'b0; // d8(An,Rn)
  assign w_ea2b_p0[5]   = (instr[8:6]  == 3'b101)    ? 1'b1 : 1'b0; // d16(An)
  assign w_ea2b_p0[4]   = (instr[8:6]  == 3'b100)    ? 1'b1 : 1'b0; // -(An)
  assign w_ea2b_p0[3]   = (instr[8:6]  == 3'b011)    ? 1'b1 : 1'b0; // (An)+
  assign w_ea2b_p0[2]   = (instr[8:6]  == 3'b010)    ? 1'b1 : 1'b0; // (An)
  assign w_ea2b_p0[1]   = (instr[8:6]  == 3'b001)    ? 1'b1 : 1'b0; // An
  assign w_ea2b_p0[0]   = (instr[8:6]  == 3'b000)    ? 1'b1 : 1'b0; // Dn

  // Effective addresses indexes (6-bit EA field -> 4-bit index)
  assign w_ea1_jmp_p0[3]   = (instr[5:3] == 3'b111) ? 1'b1 : 1'b0;
  assign w_ea1_jmp_p0[2:0] = (instr[5:3] == 3'b111) ? instr[2:0] : instr[5:3];
  assign w_ea2_jmp_p0[3]   = (instr[8:6] == 3'b111) ? 1'b1 : 1'b0;
  assign w_ea2_jmp_p0[2:0] = (instr[8:6] == 3'b111) ? instr[11:9] : instr[8:6];

  // Instructions sub-groups decode
  assign w_g0_immed_p0  = w_grp_p0[0]  &  ~instr[8];
  assign w_g0_bitimm_p0 = (instr[15:8] == 8'b0000_1000) ? 1'b1 : 1'b0;
  assign w_g0_bitop_p0  = w_grp_p0[0]  &   instr[8];
  assign w_g4_misc_p0   = (instr[15:6] == 10'b0100_111_001) ? 1'b1 : 1'b0;
  assign w_g4_oneop_p0  = w_grp_p0[4]  &  ~instr[8] & ~w_g4_misc_p0;
  assign w_g4_twoop_p0  = w_grp_p0[4]  &   instr[8];
  assign w_g5_addsub_p0 = w_grp_p0[5]  & ~(instr[7] & instr[6]);
  assign w_g6_bsr_p0    = (instr[11:8] == 4'b0001) ? 1'b1 : 1'b0;
  assign w_gE_shmem_p0  = w_grp_p0[14] &   instr[7] & instr[6];
  assign w_gE_shreg_p0  = w_grp_p0[14] & ~(instr[7] & instr[6]);

  // Special Z flag treatment for NBCD, SBCD, ABCD, NEGX, SUB, ADDX
  assign w_g4_nbcd_p0   = (w_grp_p0[4])  && (instr[11:6] == 6'b100000) ? 1'b1 : 1'b0;
  assign w_g8_sbcd_p0   = (w_grp_p0[8])  &&  (instr[8:4] == 5'b10000)  ? 1'b1 : 1'b0;
  assign w_gC_abcd_p0   = (w_grp_p0[12]) &&  (instr[8:4] == 5'b10000)  ? 1'b1 : 1'b0;
  assign w_g4_negx_p0   = (w_grp_p0[4])  && (instr[11:8] == 4'b0000)   ? 1'b1 : 1'b0;
  assign w_g9_subx_p0   = (w_grp_p0[9])  && ((instr[8:4] == 5'b10000) ||
                                             (instr[8:4] == 5'b10100) ||
                                             (instr[8:4] == 5'b11000)) ? 1'b1 : 1'b0;
  assign w_gD_addx_p0   = (w_grp_p0[13]) && ((instr[8:4] == 5'b10000) ||
                                             (instr[8:4] == 5'b10100) ||
                                             (instr[8:4] == 5'b11000)) ? 1'b1 : 1'b0;
  assign w_ext_ins_p0   = w_g4_negx_p0 | w_g9_subx_p0 | w_gD_addx_p0
                        | w_g4_nbcd_p0 | w_g8_sbcd_p0 | w_gC_abcd_p0;

  // Bit manipulation instructions
  assign w_bit_ins_p0   = w_g0_bitop_p0 | w_g0_bitimm_p0;

  // Illegal instruction pre-decode (not present in the jump table)
  assign w_ill_ins_p0   = (w_grp_p0[1]  & w_ea2b_p0[1])                     // MOVE.B An,<ea>
                        | (w_grp_p0[1]  & w_ea2b_p0[9])                     // MOVE.B <ea>,???
                        | (w_grp_p0[2]  & w_ea2b_p0[9])                     // MOVE.L <ea>,???
                        | (w_grp_p0[3]  & w_ea2b_p0[9])                     // MOVE.W <ea>,???
                        | (w_grp_p0[7]  & instr[8])                         // Coldfire's MVS/MVZ instr.
                        | (w_grp_p0[14] & instr[11] & instr[7] & instr[6]); // Empty slots in shift instr.
  // Priviledged instruction pre-decode
  assign w_prv_ins_p0   = ((w_grp_p0[0])  && (instr[6]) && (w_ea1b_p0[12])) // Log. immed SR
                       || ((w_g4_misc_p0) && ((instr[6:4] == 2'b10) ||      // MOVE USP
                                              (instr[6:0] == 6'b110000) ||  // RESET
                                              (instr[6:1] == 6'b11001)))    // STOP, RTE
                       || ((w_grp_p0[4])  && (instr[11:6] == 6'b011011))    // MOVE <ea>,SR
                       ? user_mode : 1'b0;

  // Jump table call #1 enable
  assign w_call1_ena_p0 = (w_grp_p0[0]  & w_ea1b_p0[0])                     // Bit op. reg
                        | (w_grp_p0[2]  & w_ea2b_p0[1])                     // MOVEA.L
                        | (w_grp_p0[3]  & w_ea2b_p0[1])                     // MOVEA.W
                        | (w_grp_p0[4]  & ~w_g4_misc_p0 & w_ea1b_p0[0])     // SWAP, EXT
                        | (w_grp_p0[6]  & w_g6_bsr_p0)                      // BSR
                        | (w_grp_p0[8]  & w_ea1b_p0[0])                     // SBCD reg
                        | (w_grp_p0[9]  & w_ea1b_p0[0])                     // SUBX reg
                        | (w_grp_p0[12] & w_ea1b_p0[0])                     // ABCD reg, EXG
                        | (w_grp_p0[13] & w_ea1b_p0[0]);                    // ADDX reg
  // Jump table call #2 enable
  assign w_call2_ena_p0 = (w_grp_p0[0]  & ~instr[8]     & w_ea1b_p0[12])    // Log op. SR
                        | (w_grp_p0[0]  & instr[8]      & w_ea1b_p0[1])     // MOVEP
                        | (w_grp_p0[4]  & ~w_g4_misc_p0 & w_ea1b_p0[3])     // MOVEM (An)+<list>
                        | (w_grp_p0[4]  & ~w_g4_misc_p0 & w_ea1b_p0[4])     // MOVEM <list>,-(An)
                        | (w_grp_p0[5]  & w_ea1b_p0[1])                     // ADDQA, SUBQA, DBcc
                        | (w_grp_p0[8]  & w_ea1b_p0[1])                     // SBCD mem
                        | (w_grp_p0[9]  & w_ea1b_p0[1])                     // SUBX mem
                        | (w_grp_p0[11] & w_ea1b_p0[1])                     // CMPM
                        | (w_grp_p0[12] & w_ea1b_p0[1])                     // ABCD mem, EXG
                        | (w_grp_p0[13] & w_ea1b_p0[1]);                    // ADDX mem

  // 6-bit indexes calculations
  assign w_idx6_5_0_p0  = (w_g4_misc_p0)
                        ? instr[5:0]
                        : 6'b000000;
  assign w_idx5_B_6_p0  = (w_g0_immed_p0 | w_g4_oneop_p0)
                        ? { instr[14], instr[11:9], instr[7:6] }
                        : 6'b000000;
  assign w_idx4_8_3_p0  = (w_gE_shreg_p0)
                        ? { instr[7:6], instr[8], instr[5:3] }
                        : 6'b000000;
  assign w_idx4_F_C_p0  = (w_grp_p0[1] | w_grp_p0[2] | w_grp_p0[3] | w_grp_p0[6] | w_grp_p0[7] | w_grp_p0[10] | w_grp_p0[15])
                        ? { 2'b11, instr[15:12] }
                        : 6'b000000;                    
  assign w_idx3_8_6_p0  = (w_grp_p0[5] | w_grp_p0[8] | w_grp_p0[9] | w_grp_p0[11] | w_grp_p0[12] | w_grp_p0[13])
                        ? { instr[14] ^ ~instr[15], instr[13] ^ ~instr[15], instr[12] ^ ~instr[15], instr[8:6] }
                        : 6'b000000;
  assign w_idx3_A_8_p0  = (w_gE_shmem_p0)
                        ? { 3'b110, instr[10:8] }
                        : 6'b000000;
  assign w_idx2_7_6_p0  = (w_g0_bitop_p0 | w_g4_twoop_p0)
                        ? { 3'b111, instr[14], instr[7:6] }
                        : 6'b000000;

  // 256-entry table index (16-bit instr. -> 8-bit index)
  assign w_addr_p0[7]   = ((instr[12]   | instr[13]) & ~instr[15])       // Groups #1,2,3,5,6,7
                        | instr[15]     | w_g0_bitop_p0 | w_g4_twoop_p0; // Groups #8-15
  assign w_addr_p0[6]   = w_grp_p0[5]   | w_grp_p0[8]   | w_grp_p0[9]
                        | w_grp_p0[11]  | w_grp_p0[12]  | w_grp_p0[13]
                        | w_g0_immed_p0 | w_g0_bitop_p0 | w_g4_oneop_p0
                        | w_g4_twoop_p0 | w_gE_shmem_p0;
  assign w_addr_p0[5:0] = w_idx6_5_0_p0 | w_idx5_B_6_p0 | w_idx4_8_3_p0
                        | w_idx4_F_C_p0 | w_idx3_8_6_p0 | w_idx3_A_8_p0
                        | w_idx2_7_6_p0;

  // Jump table ROM
  decode_rom rom_inst
  (
    .clock(clk),
    .address(w_addr_p0),
    .q(w_data_p1)
  );
  
  always@(w_data_p1 or r_ea1b_p1 or r_ill_ins_p1 or r_prv_ins_p1 or r_call_en_p1)
  begin
    // EA #1 mask
    case (w_data_p1[11:8])
      4'b0000 : w_ea1m_p1 = 16'b000_00000_00000000; // $0000
      4'b0001 : w_ea1m_p1 = 16'b000_00011_01110101; // $01F5
      4'b0010 : w_ea1m_p1 = 16'b000_00011_01111100; // $01FC
      4'b0011 : w_ea1m_p1 = 16'b000_00011_01111101; // $01FD
      4'b0100 : w_ea1m_p1 = 16'b000_00011_01111110; // $01FE
      4'b0101 : w_ea1m_p1 = 16'b000_00011_01111111; // $01FF
      4'b0110 : w_ea1m_p1 = 16'b000_01111_01001101; // $07CD
      4'b0111 : w_ea1m_p1 = 16'b000_01111_01100100; // $07E4
      4'b1000 : w_ea1m_p1 = 16'b000_01111_01100101; // $07E5
      4'b1001 : w_ea1m_p1 = 16'b000_01111_01101100; // $07EC
      4'b1010 : w_ea1m_p1 = 16'b000_01111_01111101; // $07FD
      4'b1011 : w_ea1m_p1 = 16'b000_10011_01111101; // $09FD
      4'b1100 : w_ea1m_p1 = 16'b000_11111_01111101; // $0FFD
      4'b1101 : w_ea1m_p1 = 16'b000_11111_01111111; // $0FFF
      default : w_ea1m_p1 = 16'b111_11111_01111111; // $7FFF
    endcase
    // Call address increment
    w_incr_p1 = (w_data_p1[23:18] & {6{r_call_en_p1[0]}})
              | (w_data_p1[17:12] & {6{r_call_en_p1[1]}});
    // Call address
    if (((w_ea1m_p1 & r_ea1b_p1) == 16'h0000) || (r_ill_ins_p1)) begin
      // Illegal instruction
      w_call_p1 <= `OP_ILLEGAL;
      w_vld_ins_p1 <= 1'b0;
    end else if (r_prv_ins_p1) begin
      // Priviledge violation
      w_call_p1 <= `OP_PRIVILEDGED;
      w_vld_ins_p1 <= 1'b1;
    end else begin
      // Valid instruction
      w_call_p1 <= w_data_p1[35:24] + { 6'b000000, w_incr_p1 };
      w_vld_ins_p1 <= 1'b1;
    end
  end

  // Latch the indexes and bitfields
  always @(posedge rst or posedge clk)
  begin
    if (rst) begin
      r_ea1_jmp_p1 <= 4'b0000;
      r_ea2_jmp_p1 <= 4'b0000;
      r_ill_ins_p1 <= 1'b0;
      r_prv_ins_p1 <= 1'b0;
      r_ext_ins_p1 <= 1'b0;
      r_bit_ins_p1 <= 1'b0;
      r_call_en_p1 <= 2'b00;
      r_ea1b_p1    <= 16'b0000000_00000000;      
      
      //r_ext_ins_p2 <= 1'b0;
      //r_bit_ins_p2 <= 1'b0;
      r_vld_ins_p2 <= 1'b0;
      //r_ea1_jmp_p2 <= 4'b0000;
      //r_ea2_jmp_p2 <= 4'b0000;
      r_call_p2    <= 12'h000;
    end else begin
      // Cycle #1
      r_ea1_jmp_p1 <= w_ea1_jmp_p0;
      r_ea2_jmp_p1 <= w_ea2_jmp_p0;
      r_ill_ins_p1 <= w_ill_ins_p0;
      r_prv_ins_p1 <= w_prv_ins_p0;
      r_ext_ins_p1 <= w_ext_ins_p0;
      r_bit_ins_p1 <= w_bit_ins_p0;
      r_call_en_p1 <= { w_call2_ena_p0, w_call1_ena_p0 };
      r_ea1b_p1    <= w_ea1b_p0;
      // Cycle #2
      //r_ext_ins_p2 <= r_ext_ins_p1;
      //r_bit_ins_p2 <= r_bit_ins_p1;
      r_vld_ins_p2 <= w_vld_ins_p1;
      //r_ea1_jmp_p2 <= r_ea1_jmp_p1;
      //r_ea2_jmp_p2 <= r_ea2_jmp_p1;
      r_call_p2    <= w_call_p1;
    end
  end
  
  assign vld_inst = r_vld_ins_p2;
  assign ext_inst = r_ext_ins_p1;
  assign bit_inst = r_bit_ins_p1;
  assign dec_jmp  = r_call_p2;
  assign ea1_jmp  = r_ea1_jmp_p1;
  assign ea2_jmp  = r_ea2_jmp_p1;
  assign ea1_bit  = r_ea1b_p1;

  // Immediate values from instruction word
  // For ADDQ, SUBQ and shift immediate 
  assign w_imm3_i[15:4] = 12'h000;
  assign w_imm3_i[3]    = (instr[11:9] == 3'b000) ? (w_g5_addsub_p0 | (w_gE_shreg_p0 & ~instr[5])) : 1'b0;
  assign w_imm3_i[2:0]  = (w_g5_addsub_p0 | (w_gE_shreg_p0 & ~instr[5])) ? instr[11:9] : 3'b000;
  // For TRAP #x : xxx0 - xxxF -> 0080 - 00BC
  assign w_imm4_i[15:8] = 8'h00;
  assign w_imm4_i[7:0]  = (w_g4_misc_p0) ? {2'b10, instr[3:0], 2'b00} : 8'h00;
  // For MOVEQ and Bcc.B
  assign w_imm8_i[15:8] = (w_grp_p0[6] | (w_grp_p0[7] & ~instr[8])) ? {8{instr[7]}} : 8'h00;
  assign w_imm8_i[7:0]  = (w_grp_p0[6] | (w_grp_p0[7] & ~instr[8])) ? instr[7:0] : 8'h00;

  // Immediate values from extension word
  // For BTST, BCHG, BCLR and BSET
  assign w_imm5_e[15:5] = 11'b0;
  assign w_imm5_e[4:0]  = ext_wd[4:0];
  // For d8(An,Rn) and d8(PC,Rn)
  assign w_imm8_e[15:8] = {8{ext_wd[7]}};
  assign w_imm8_e[7:0]  = ext_wd[7:0];

  // Latch the immediate values
  always @(posedge rst or posedge clk)
  begin
    if (rst) begin
      imm_val <= 16'h0000;
    end else begin
      if (ins_rdy) imm_val <= w_imm3_i | w_imm4_i | w_imm8_i;
      if (ext_rdy) begin
        if (w_g0_bitimm_p0)
          imm_val <= w_imm5_e;
        else
          imm_val <= w_imm8_e;
      end
      if (imm_rdy) imm_val <= imm_wd;
    end
  end
  
  // Jump flag from condition codes
  always @(posedge rst or posedge clk)
  begin
    if (rst)
      cc_jmp <= 1'b0;
    else
      case (instr[11:8])
        4'b0000 : cc_jmp <= 1'b1;                                   // T
        4'b0001 : cc_jmp <= 1'b0;                                   // F
        4'b0010 : cc_jmp <= ~(ccr_in[0] | ccr_in[2]);               // HI
        4'b0011 : cc_jmp <=   ccr_in[0] | ccr_in[2];                // LS
        4'b0100 : cc_jmp <= ~ ccr_in[0];                            // CC
        4'b0101 : cc_jmp <=   ccr_in[0];                            // CS
        4'b0110 : cc_jmp <= ~ ccr_in[2];                            // NE
        4'b0111 : cc_jmp <=   ccr_in[2];                            // EQ
        4'b1000 : cc_jmp <= ~ ccr_in[1];                            // VC
        4'b1001 : cc_jmp <=   ccr_in[1];                            // VS
        4'b1010 : cc_jmp <= ~ ccr_in[3];                            // PL
        4'b1011 : cc_jmp <=   ccr_in[3];                            // MI
        4'b1100 : cc_jmp <= ~(ccr_in[1] ^ ccr_in[3]);               // GE
        4'b1101 : cc_jmp <=   ccr_in[1] ^ ccr_in[3];                // LT
        4'b1110 : cc_jmp <= ~((ccr_in[1] ^ ccr_in[3]) | ccr_in[2]); // GT
        4'b1111 : cc_jmp <=   (ccr_in[1] ^ ccr_in[3]) | ccr_in[2];  // LE
      endcase
  end
  
endmodule

module dpram_2048x4
(
  // Clock
  input         clock,
  // Port A : micro-instruction fetch
  input         rden_a,
  input  [10:0] address_a,
  output [3:0]  q_a,
  // Port B : m68k registers read/write
  input         wren_b,
  input  [10:0] address_b,
  input  [3:0]  data_b,
  output [3:0]  q_b
);
parameter RAM_INIT_FILE = "j68_ram.mif";

  altsyncram altsyncram_component
  (
    .clock0(clock),
    .wren_a(1'b0),
    .wren_b(wren_b),
    .address_a(address_a),
    .address_b(address_b),
    .data_a(4'b0000),
    .data_b(data_b),
    .q_a(q_a),
    .q_b(q_b),
    .aclr0(1'b0),
    .aclr1(1'b0),
    .addressstall_a(~rden_a),
    .addressstall_b(1'b0),
    .byteena_a(1'b1),
    .byteena_b(1'b1),
    .clock1(1'b1),
    .clocken0(1'b1),
    .clocken1(1'b1),
    .clocken2(1'b1),
    .clocken3(1'b1),
    .eccstatus(),
    .rden_a(1'b1),
    .rden_b(1'b1)
  );
  defparam
    altsyncram_component.address_reg_b = "CLOCK0",
    altsyncram_component.byteena_reg_b = "CLOCK0",
    altsyncram_component.byte_size = 8,
    altsyncram_component.clock_enable_input_a = "BYPASS",
    altsyncram_component.clock_enable_input_b = "BYPASS",
    altsyncram_component.clock_enable_output_a = "BYPASS",
    altsyncram_component.clock_enable_output_b = "BYPASS",
    altsyncram_component.indata_reg_b = "CLOCK0",
    altsyncram_component.init_file = RAM_INIT_FILE,
    altsyncram_component.intended_device_family = "Stratix II",
    altsyncram_component.lpm_type = "altsyncram",
    altsyncram_component.numwords_a = 2048,
    altsyncram_component.numwords_b = 2048,
    altsyncram_component.operation_mode = "BIDIR_DUAL_PORT",
    altsyncram_component.outdata_aclr_a = "NONE",
    altsyncram_component.outdata_aclr_b = "NONE",
    altsyncram_component.outdata_reg_a = "UNREGISTERED",
    altsyncram_component.outdata_reg_b = "UNREGISTERED",
    altsyncram_component.power_up_uninitialized = "FALSE",
    altsyncram_component.ram_block_type = "AUTO",
    altsyncram_component.read_during_write_mode_mixed_ports = "OLD_DATA",
    //altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_WITH_NBE_READ",
    //altsyncram_component.read_during_write_mode_port_b = "NEW_DATA_WITH_NBE_READ",
    altsyncram_component.widthad_a = 11,
    altsyncram_component.widthad_b = 11,
    altsyncram_component.width_a = 4,
    altsyncram_component.width_b = 4,
    altsyncram_component.width_byteena_a = 1,
    altsyncram_component.width_byteena_b = 1,
    altsyncram_component.wrcontrol_wraddress_reg_b = "CLOCK0";

endmodule

module addsub_32
(
  input         add_sub,
  input  [31:0] dataa,
  input  [31:0] datab,
  output        cout,
  output [31:0] result
);

  lpm_add_sub lpm_add_sub_component
  (
    .add_sub(add_sub),
    .dataa(dataa),
    .datab(datab),
    .cout(cout),
    .result(result)
    // synopsys translate_off
    ,
    .aclr(),
    .cin(),
    .clken(),
    .clock(),
    .overflow()
    // synopsys translate_on
  );
  defparam
    lpm_add_sub_component.lpm_direction = "UNUSED",
    lpm_add_sub_component.lpm_hint = "ONE_INPUT_IS_CONSTANT=NO,CIN_USED=NO",
    lpm_add_sub_component.lpm_representation = "UNSIGNED",
    lpm_add_sub_component.lpm_type = "LPM_ADD_SUB",
    lpm_add_sub_component.lpm_width = 32;

endmodule

module decode_rom
(
  input          clock,
  input   [7:0] address,
  output [35:0] q
);

  altsyncram  altsyncram_component
  (
        .clock0 (clock),
        .address_a (address),
        .q_a (q),
        .aclr0 (1'b0),
        .aclr1 (1'b0),
        .address_b (1'b1),
        .addressstall_a (1'b0),
        .addressstall_b (1'b0),
        .byteena_a (1'b1),
        .byteena_b (1'b1),
        .clock1 (1'b1),
        .clocken0 (1'b1),
        .clocken1 (1'b1),
        .clocken2 (1'b1),
        .clocken3 (1'b1),
        .data_a ({36{1'b1}}),
        .data_b (1'b1),
        .eccstatus (),
        .q_b (),
        .rden_a (1'b1),
        .rden_b (1'b1),
        .wren_a (1'b0),
        .wren_b (1'b0));
  defparam
    altsyncram_component.clock_enable_input_a = "BYPASS",
    altsyncram_component.clock_enable_output_a = "BYPASS",
    altsyncram_component.init_file = "j68_dec.mif",
    altsyncram_component.intended_device_family = "Stratix II",
    altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
    altsyncram_component.lpm_type = "altsyncram",
    altsyncram_component.numwords_a = 256,
    altsyncram_component.operation_mode = "ROM",
    altsyncram_component.outdata_aclr_a = "NONE",
    altsyncram_component.outdata_reg_a = "UNREGISTERED",
    altsyncram_component.widthad_a = 8,
    altsyncram_component.width_a = 36,
    altsyncram_component.width_byteena_a = 1;

endmodule

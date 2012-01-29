//----------------------------------------------------------------------------
//----------------------------------------------------------------------------
//                                                                          --
// Copyright (c) 2008-2009 Tobias Gubener                                   --
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

module cfide (
  input  wire           sysclk,
  input  wire           n_reset,
  input  wire           cpuena_in,
  input  wire [ 16-1:0] memdata_in,
  input  wire [ 24-1:0] addr,
  input  wire [ 16-1:0] cpudata_in,
  input  wire [  2-1:0] state,
  input  wire           lds,
  input  wire           uds,
  input  wire           sd_di,
  output wire           memce,
  output wire [ 16-1:0] cpudata,
  output wire           cpuena,
  output wire           TxD,
  output wire [  8-1:0] sd_cs,
  output wire           sd_clk,
  output wire           sd_do,
  input  wire           sd_dimm,
  input  wire           enaWRreg
);


localparam [0:0] idle = 0, io_aktion = 1;


reg  [ 10-1:0] shift;
reg  [ 10-1:0] clkgen;
reg            shiftout;
reg            txbusy;
reg            ld;
wire           rs232_select;
wire           PART_select;
wire           SPI_select;
wire           ROM_select;
wire           RAM_write;
wire [ 16-1:0] part_in;
wire [ 16-1:0] IOdata;
reg            IOcpuena;
reg            micro_state;
reg  [  8-1:0] sd_out;
reg  [  8-1:0] sd_in;
reg            sd_di_in;
reg  [ 14-1:0] shiftcnt;
reg            sck;
reg  [  8-1:0] scs;
wire           SD_busy;
reg  [  8-1:0] spi_div;
reg  [  8-1:0] spi_speed;
wire [ 16-1:0] rom_data;
reg  [ 16-1:0] timecnt;
reg  [ 16-1:0] timeprecnt;
wire [  2-1:0] byteena_in;
wire           wren_in;




assign byteena_in = ~{uds, lds};
assign wren_in = RAM_write & enaWRreg;

startram srom (
  .address  (addr[10:1]),
  .byteena  (byteena_in),
  .clock    (sysclk),
  .data     (cpudata_in),
  .wren     (wren_in),
  .q        (rom_data));

assign memce   = (ROM_select == 1'b0) && (addr[23] == 1'b0) ? 1'b0 : 1'b1;
assign cpudata = (ROM_select == 1'b1) ? rom_data : (IOcpuena == 1'b1) ? IOdata : (PART_select == 1'b1) ? part_in : memdata_in;
assign part_in = timecnt; //DEE010

assign IOdata = {SD_busy,7'b 0000000,sd_in};
assign cpuena = ROM_select == 1'b1 || PART_select == 1'b1 ? 1'b1 : rs232_select == 1'b1 || SPI_select == 1'b1 ? IOcpuena : cpuena_in;
assign RAM_write = ROM_select == 1'b1 && state == 2'b11 ? 1'b1 : 1'b0;

assign ROM_select   = (addr[23:12] == 12'h000) ? 1'b1 : 1'b0;
assign rs232_select = (addr[23:12] == 12'hda8) ? 1'b1 : 1'b0;
assign PART_select  = (addr[23:12] == 12'hdee) ? 1'b1 : 1'b0;
assign SPI_select   = (addr[23:12] == 12'hda4) ? 1'b1 : 1'b0;


//---------------------------------------------------------------
// SPI-Interface
//---------------------------------------------------------------
assign sd_cs   = ~scs;
assign sd_clk  = ~sck;
assign sd_do   = sd_out[7];
assign SD_busy = shiftcnt[13];

always @(*) begin
  if(scs[1]  == 1'b1)
    sd_di_in <= sd_di;
  else
    sd_di_in <= sd_dimm;
end

always @(posedge sysclk or negedge n_reset) begin
  if(n_reset == 1'b0) begin
    shiftcnt <= {14{1'b0}};
    spi_div <= {8{1'b0}};
    scs <= {8{1'b0}};
    sck <= 1'b0;
    spi_speed <= 8'b00000000;
  end else begin
    if(enaWRreg == 1'b1) begin
      if(SPI_select == 1'b1 && state == 2'b11 && SD_busy == 1'b0) begin
        //SD write
        if(addr[3] == 1'b1) begin
          //DA4008
          spi_speed <= cpudata_in[7:0];
        end
        else if(addr[2] == 1'b1) begin
          //DA4004
          scs[0] <= ~cpudata_in[0];
          if(cpudata_in[7] == 1'b1) begin
            scs[7] <= ~cpudata_in[0];
          end
          if(cpudata_in[6] == 1'b1) begin
            scs[6] <= ~cpudata_in[0];
          end
          if(cpudata_in[5] == 1'b1) begin
            scs[5] <= ~cpudata_in[0];
          end
          if(cpudata_in[4] == 1'b1) begin
            scs[4] <= ~cpudata_in[0];
          end
          if(cpudata_in[3] == 1'b 1) begin
            scs[3] <= ~cpudata_in[0];
          end
          if(cpudata_in[2] == 1'b1) begin
            scs[2] <= ~cpudata_in[0];
          end
          if(cpudata_in[1] == 1'b1) begin
            scs[1] <= ~cpudata_in[0];
          end
        end
        else begin
          //DA4000
          spi_div <= spi_speed;
          if(scs[6]  == 1'b1) begin
            // SPI direkt Mode
            shiftcnt <= 14'b11000000000111;
          end
          else begin
            shiftcnt <= 14'b10000000000111;
          end
          sd_out <= cpudata_in[7:0];
          sck <= 1'b1;
        end
      end
      else begin
        if(spi_div == 8'b00000000) begin
          spi_div <= spi_speed;
          if(SD_busy == 1'b1) begin
            if(sck == 1'b0) begin
              if(shiftcnt[12:0]  != 13'b0000000000000) begin
                sck <= 1'b1;
              end
              shiftcnt <= shiftcnt - 14'd1;
              sd_out <= {sd_out[6:0], 1'b1};
            end
            else begin
              sck <= 1'b0;
              sd_in <= {sd_in[6:0], sd_di_in};
            end
          end
        end
        else begin
          spi_div <= spi_div - 8'd1;
        end
      end
    end
  end
end



//---------------------------------------------------------------
// IO States
//---------------------------------------------------------------
always @(posedge sysclk) begin
  if(enaWRreg == 1'b1) begin
    micro_state <= idle;
    ld <= 1'b0;
    IOcpuena <= 1'b0;
    case(micro_state)
    idle : begin
      if(rs232_select == 1'b1 && state == 2'b11) begin
        if(txbusy == 1'b0) begin
          ld <= 1'b1;
          micro_state <= io_aktion;
          IOcpuena <= 1'b1;
        end
      end
      else if(SPI_select == 1'b1) begin
        if(SD_busy == 1'b0) begin
          micro_state <= io_aktion;
          IOcpuena <= 1'b1;
        end
      end
      else if(addr[23] == 1'b1 && state[1] == 1'b1) begin
        micro_state <= io_aktion;
        IOcpuena <= 1'b1;
      end
    end
    io_aktion : begin
      micro_state <= idle;
    end
    default : begin
      micro_state <= idle;
    end
    endcase
  end
end


//---------------------------------------------------------------
// Simple UART only TxD
//---------------------------------------------------------------
assign TxD =  ~shiftout;

always @(*) begin
  if(shift == 10'b0000000000) begin
    txbusy <= 1'b0;
  end
  else begin
    txbusy <= 1'b1;
  end
end

always @(posedge sysclk or negedge n_reset) begin
  if(n_reset == 1'b0) begin
    shiftout <= 1'b0;
    shift <= 10'b0000000000;
  end else begin
    if(enaWRreg == 1'b1) begin
      if(ld == 1'b1) begin
        shift <= {1'b1, cpudata_in[15:8], 1'b0};
        //STOP,MSB...LSB, START
      end
      if(clkgen != 0) begin
        clkgen <= clkgen - 10'd1;
      end
      else begin
        //      clkgen <= "1110101001";--937;    --108MHz/115200
        //      clkgen <= "0011101010";--234;    --27MHz/115200
        //      clkgen <= "0011111000";--249-1;    --28,7MHz/115200
        //      clkgen <= "0011110101";--246-1;    --28,7MHz/115200
        clkgen <= 10'b0001111100;
        //249-1;    --14,3MHz/115200
        shiftout <=  ~shift[0]  & txbusy;
        shift <= {1'b0, shift[9:1]};
      end
    end
  end
end

//---------------------------------------------------------------
// timer
//---------------------------------------------------------------
always @(posedge sysclk) begin
  if(enaWRreg == 1'b1) begin
    if(timeprecnt == 0) begin
      timeprecnt <= 16'h3808;
      timecnt <= timecnt + 16'd1;
    end
    else begin
      timeprecnt <= timeprecnt - 16'd1;
    end
  end
end


endmodule


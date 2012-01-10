// File SRAM.vhd translated with vhd2vl v2.0 VHDL to Verilog RTL translator
// Copyright (C) 2001 Vincenzo Liguori - Ocean Logic Pty Ltd - http://www.ocean-logic.com
// Modifications (C) 2006 Mark Gonzales - PMC Sierra Inc
// 
// vhd2vl comes with ABSOLUTELY NO WARRANTY
// ALWAYS RUN A FORMAL VERIFICATION TOOL TO COMPARE VHDL INPUT TO VERILOG OUTPUT 
// 
// This is free software, and you are welcome to redistribute it under certain conditions.
// See the license file license.txt included with the source for details.


module SRAM(
clk,
pulse,
fifoinptr,
fifodwr,
fifowr,
fifooutptr,
track,
dsklen,
addr,
data,
oe,
wr,
fifodrd,
hex1,
hex10,
hex100,
led
);

input clk;
input pulse;
input[12:0] fifoinptr;
input[15:0] fifodwr;
input fifowr;
input[12:0] fifooutptr;
input[7:0] track;
input[13:0] dsklen;
//		dsklen        : in std_logic_vector(2 downto 0);  
output[17:0] addr;
output[15:0] data;
// inout
output oe;
output wr;
output[15:0] fifodrd;
output[6:0] hex1;
output[6:0] hex10;
output[6:0] hex100;
output[9:0] led;

wire   clk;
wire   pulse;
wire  [12:0] fifoinptr;
wire  [15:0] fifodwr;
wire   fifowr;
wire  [12:0] fifooutptr;
wire  [7:0] track;
wire  [13:0] dsklen;
wire  [17:0] addr;
wire  [15:0] data;
wire   oe;
wire   wr;
reg  [15:0] fifodrd;
reg  [6:0] hex1;
reg  [6:0] hex10;
reg  [6:0] hex100;
reg  [9:0] led;


//    subtype SLV12 is std_logic_vector (11 downto 0);
//    type Rom255x12 is array (0 to 255) of std_logic_vector(11 downto 0);--SLV12;
//    constant BCDRom : Rom255x12 := (
//         x"000", x"001", x"002", x"003", x"004", x"005", x"006", x"007", x"008", x"009",
//         x"010", x"011", x"012", x"013", x"014", x"015", x"016", x"017", x"018", x"019",
//         x"020", x"021", x"022", x"023", x"024", x"025", x"026", x"027", x"028", x"029",
//         x"030", x"031", x"032", x"033", x"034", x"035", x"036", x"037", x"038", x"039",
//         x"040", x"041", x"042", x"043", x"044", x"045", x"046", x"047", x"048", x"049",
//         x"050", x"051", x"052", x"053", x"054", x"055", x"056", x"057", x"058", x"059",
//         x"060", x"061", x"062", x"063", x"064", x"065", x"066", x"067", x"068", x"069",
//         x"070", x"071", x"072", x"073", x"074", x"075", x"076", x"077", x"078", x"079",
//         x"080", x"081", x"082", x"083", x"084", x"085", x"086", x"087", x"088", x"089",
//         x"090", x"091", x"092", x"093", x"094", x"095", x"096", x"097", x"098", x"099",
//         x"100", x"101", x"102", x"103", x"104", x"105", x"106", x"107", x"108", x"109",
//         x"110", x"111", x"112", x"113", x"114", x"115", x"116", x"117", x"118", x"119",
//         x"120", x"121", x"122", x"123", x"124", x"125", x"126", x"127", x"128", x"129",
//         x"130", x"131", x"132", x"133", x"134", x"135", x"136", x"137", x"138", x"139",
//         x"140", x"141", x"142", x"143", x"144", x"145", x"146", x"147", x"148", x"149",
//         x"150", x"151", x"152", x"153", x"154", x"155", x"156", x"157", x"158", x"159",
//         x"160", x"161", x"162", x"163", x"164", x"165", x"166", x"167", x"168", x"169",
//         x"170", x"171", x"172", x"173", x"174", x"175", x"176", x"177", x"178", x"179",
//         x"180", x"181", x"182", x"183", x"184", x"185", x"186", x"187", x"188", x"189",
//         x"190", x"191", x"192", x"193", x"194", x"195", x"196", x"197", x"198", x"199",
//         x"200", x"201", x"202", x"203", x"204", x"205", x"206", x"207", x"208", x"209",
//         x"210", x"211", x"212", x"213", x"214", x"215", x"216", x"217", x"218", x"219",
//         x"220", x"221", x"222", x"223", x"224", x"225", x"226", x"227", x"228", x"229",
//         x"230", x"231", x"232", x"233", x"234", x"235", x"236", x"237", x"238", x"239",
//         x"240", x"241", x"242", x"243", x"244", x"245", x"246", x"247", x"248", x"249",
//         x"250", x"251", x"252", x"253", x"254", x"255" );
wire [11:0] digits;
reg  ledon;
reg [15:0] ledon_cnt;

  assign oe =  ~clk | pulse;
  assign wr = clk | pulse |  ~fifowr;
  assign addr = clk == 1'b 1 ? {5'b 00000,fifooutptr} : {5'b 00000,fifoinptr};
  assign data = clk == 1'b 0 ? fifodwr : 16'b ZZZZZZZZZZZZZZZZ;
  always @(posedge pulse or posedge digits or posedge dsklen) begin
    if(clk == 1'b 1) begin
      fifodrd <= data;
    end
    if(fifowr == 1'b 1) begin
      ledon_cnt <= 16'b 1111111111111111;
      //digits <= BCDRom(to_integer(unsigned(track)));
    end
    else begin
      if(ledon_cnt != 16'b 0000000000000000) begin
        ledon_cnt <= ledon_cnt - 1;
      end
    end
    //		END IF;	
    //		IF rising_edge(clk) THEN
    if(ledon_cnt == 16'b 0000000000000000) begin
      ledon <= 1'b 0;
    end
    else begin
      ledon <= 1'b 1;
    end
  end

  always @(pulse or digits or dsklen) begin
    case(digits[3:0] )
    4'b 0000 : begin
      hex1 <= 7'b 1000000;
      //.db 0x40	;0
    end
    4'b 0001 : begin
      hex1 <= 7'b 1111001;
      //.db 0x79	;1
    end
    4'b 0010 : begin
      hex1 <= 7'b 0100100;
      //.db 0x24	;2
    end
    4'b 0011 : begin
      hex1 <= 7'b 0110000;
      //.db 0x30	;3
    end
    4'b 0100 : begin
      hex1 <= 7'b 0011001;
      //.db 0x19	;4
    end
    4'b 0101 : begin
      hex1 <= 7'b 0010010;
      //.db 0x12	;5
    end
    4'b 0110 : begin
      hex1 <= 7'b 0000010;
      //.db 0x02	;6
    end
    4'b 0111 : begin
      hex1 <= 7'b 1111000;
      //.db 0x78	;7
    end
    4'b 1000 : begin
      hex1 <= 7'b 0000000;
      //.db 0x00	;8
    end
    4'b 1001 : begin
      hex1 <= 7'b 0010000;
      //.db 0x10	;9
    end
    default : begin
      hex1 <= 7'b XXXXXXX;
    end
    endcase
    case(digits[7:4] )
    4'b 0000 : begin
      hex10 <= 7'b 1000000;
      //.db 0x40	;0
    end
    4'b 0001 : begin
      hex10 <= 7'b 1111001;
      //.db 0x79	;1
    end
    4'b 0010 : begin
      hex10 <= 7'b 0100100;
      //.db 0x24	;2
    end
    4'b 0011 : begin
      hex10 <= 7'b 0110000;
      //.db 0x30	;3
    end
    4'b 0100 : begin
      hex10 <= 7'b 0011001;
      //.db 0x19	;4
    end
    4'b 0101 : begin
      hex10 <= 7'b 0010010;
      //.db 0x12	;5
    end
    4'b 0110 : begin
      hex10 <= 7'b 0000010;
      //.db 0x02	;6
    end
    4'b 0111 : begin
      hex10 <= 7'b 1111000;
      //.db 0x78	;7
    end
    4'b 1000 : begin
      hex10 <= 7'b 0000000;
      //.db 0x00	;8
    end
    4'b 1001 : begin
      hex10 <= 7'b 0010000;
      //.db 0x10	;9
    end
    default : begin
      hex10 <= 7'b XXXXXXX;
    end
    endcase
    case(digits[11:8] )
    4'b 0000 : begin
      hex100 <= 7'b 1000000;
      //.db 0x40	;0
    end
    4'b 0001 : begin
      hex100 <= 7'b 1111001;
      //.db 0x79	;1
    end
    4'b 0010 : begin
      hex100 <= 7'b 0100100;
      //.db 0x24	;2
      //			WHEN "0011" => hex100 <= "0110000";--.db 0x30	;3
      //			WHEN "0100" => hex100 <= "0011001";--.db 0x19	;4
      //			WHEN "0101" => hex100 <= "0010010";--.db 0x12	;5
      //			WHEN "0110" => hex100 <= "0000010";--.db 0x02	;6
      //			WHEN "0111" => hex100 <= "1111000";--.db 0x78	;7
      //			WHEN "1000" => hex100 <= "0000000";--.db 0x00	;8
      //			WHEN "1001" => hex100 <= "0010000";--.db 0x10	;9
    end
    default : begin
      hex100 <= 7'b XXXXXXX;
    end
    endcase
    led <= 10'b 0000000000;
    if(ledon == 1'b 1) begin
      case(dsklen[12:10] )
      3'b 000 : begin
        led[0]  <= 1'b 1;
      end
      3'b 001 : begin
        led[1]  <= 1'b 1;
      end
      3'b 010 : begin
        led[2]  <= 1'b 1;
      end
      3'b 011 : begin
        led[3]  <= 1'b 1;
      end
      3'b 100 : begin
        led[4]  <= 1'b 1;
      end
      3'b 101 : begin
        led[5]  <= 1'b 1;
      end
      3'b 110 : begin
        led[6]  <= 1'b 1;
      end
      3'b 111 : begin
        led[7]  <= 1'b 1;
      end
      default : begin
      end
      endcase
    end
  end


endmodule

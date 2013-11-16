/* sd_card.v */
/*  2012, rok.krajnc@gmail.com */


module sd_card #(
  parameter FNAME=""
)(
  input  wire sck,
  input  wire ss,
  input  wire mosi,
  output wire miso
);

`define SEEK_SET 0
`define SEEK_CUR 1
`define SEEK_END 2

// file I/O
integer res;
integer file;
initial begin
  file = $fopen(FNAME, "rb+");
  if (!file) $display("ERR : SD_CARD : cannot open file %s!", FNAME);
end

// commands
localparam [7:0] 
  CMD0  = 8'h40,
  CMD8  = 8'h48,
  CMD55 = 8'h77,
  CMD41 = 8'h69,
  CMD58 = 8'h7a,
  CMD17 = 8'h51;
  


// transmit / receive
reg  [ 2:0] trxcnt = 3'h0;
reg  [ 7:0] tx     = 8'hff;
reg  [ 7:0] rx     = 8'hff;
wire        trxdone;

always @ (posedge sck) if (!ss) rx     <= #1 {rx[6:0], mosi};
always @ (negedge sck) if (!ss) tx     <= #1 {tx[6:0], 1'b1};
always @ (posedge sck) if (!ss) trxcnt <= #1 trxcnt + 1;
assign miso = tx[7];
assign trxdone = (trxcnt == 3'd7);


// receive
localparam [3:0] RX_CMD=0, RX_DAT1=1, RX_DAT2=2, RX_DAT3=3, RX_DAT4=4, RX_CRC=5;
reg  [ 3:0] cmdstate = RX_CMD;
reg  [ 7:0] rcmd = 8'hff;
reg  [31:0] rarg;
reg  [ 7:0] rcrc;
reg         cmddone=0;

always begin
  @ (posedge sck);
  if (trxdone) begin
    #2;
    case (cmdstate)
      RX_CMD  : begin cmddone=0; rcmd = 8'hff; if(rx != 8'hff) begin rcmd = rx; cmdstate = RX_DAT1; end end
      RX_DAT1 : begin rarg[31:24] = rx; cmdstate = RX_DAT2; end
      RX_DAT2 : begin rarg[23:16] = rx; cmdstate = RX_DAT3; end
      RX_DAT3 : begin rarg[15: 8] = rx; cmdstate = RX_DAT4; end
      RX_DAT4 : begin rarg[ 7: 0] = rx; cmdstate = RX_CRC;  end
      RX_CRC  : begin rcrc[ 7: 0] = rx; cmdstate = RX_CMD; cmddone=1; end
    endcase
  end
end


// transmit
integer readlen=512;
localparam [3:0] TX_IDLE=0, TX_DLY=1, TX_TRAN=2;
reg  [ 3:0] txstate = TX_IDLE;
reg  [ 7:0] txdat [0:512+5-1];
reg         txact = 1'h0;
reg  [10:0] txlen;
integer     i;

always begin
  @ (negedge sck);
  if (trxcnt == 3'd0) begin
    #2;
    case (txstate)
      TX_IDLE : begin if (txact) begin   txstate=TX_TRAN; i=0; end end
      TX_DLY  : begin                    txstate=TX_TRAN; end
      TX_TRAN : begin if (txlen) begin tx=txdat[i]; i=i+1; txlen=txlen-1; txstate = TX_TRAN; end else begin txact=0; txstate=TX_IDLE; end end
    endcase
  end
end


// state
localparam [3:0] ST_IDLE=0, ST_READ=3;
reg  [ 3:0] state = ST_IDLE;
reg         rdy = 0;

always begin
  @ (posedge sck);
  if (trxdone && !txact && cmddone) begin
    #2;
    case (rcmd)
      CMD0  : begin txact=1; txlen=1; txdat[0]=8'h01; end
      CMD8  : begin txact=1; txlen=5; txdat[0]=8'h01; txdat[1]=00; txdat[2]=8'h00; txdat[3]=8'h01; txdat[4]=8'haa; end
      CMD55 : begin txact=1; txlen=1; txdat[0]=8'h01; end
      CMD41 : begin txact=1; txlen=1; txdat[0]=8'h00; end
      CMD58 : begin txact=1; txlen=5; txdat[0]=8'h00; txdat[1]=00; txdat[2]=8'h00; txdat[3]=8'h00; txdat[4]=8'h00; end
      CMD17 : begin txact=1; txlen=readlen+5; read_data(rarg); end
    endcase
  end
end


// read data
task read_data;
input [31:0] adr;
integer i;
begin
  txdat[0]=8'h00;
  txdat[1]=8'hff;
  txdat[2]=8'hfe;
  res = $fseek(file, adr, `SEEK_SET);
  //for(i=3; i<readlen+3; i=i+1) res = $fread(txdat[i], file);
  res = $fread(txdat, file, 3, readlen);
  txdat[515]=8'hff;
  txdat[516]=8'hff;
end
endtask


endmodule


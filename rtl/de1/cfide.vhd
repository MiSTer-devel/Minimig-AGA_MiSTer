------------------------------------------------------------------------------
------------------------------------------------------------------------------
--                                                                          --
-- Copyright (c) 2008-2009 Tobias Gubener                                   --
-- Subdesign fAMpIGA by TobiFlex                                            --
--                                                                          --
-- This source file is free software: you can redistribute it and/or modify --
-- it under the terms of the GNU General Public License as published        --
-- by the Free Software Foundation, either version 3 of the License, or     --
-- (at your option) any later version.                                      --
--                                                                          --
-- This source file is distributed in the hope that it will be useful,      --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of           --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            --
-- GNU General Public License for more details.                             --
--                                                                          --
-- You should have received a copy of the GNU General Public License        --
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.    --
--                                                                          --
------------------------------------------------------------------------------
------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;


entity cfide is
   port (
  sysclk: in std_logic;
  n_reset: in std_logic;
  cpuena_in: in std_logic;
  memdata_in: in std_logic_vector(15 downto 0);
  addr: in std_logic_vector(23 downto 0);
  cpudata_in: in std_logic_vector(15 downto 0);
  state: in std_logic_vector(1 downto 0);
  lds: in std_logic;
  uds: in std_logic;
  sd_di    : in std_logic;
  memce: out std_logic;
  cpudata: out std_logic_vector(15 downto 0);
  cpuena: buffer std_logic;
  TxD: out std_logic;
  sd_cs     : out std_logic_vector(7 downto 0);
  sd_clk     : out std_logic;
  sd_do    : out std_logic;
  sd_dimm    : in std_logic;
  enaWRreg    : in std_logic :='1'
  );
end cfide;


architecture wire of cfide is

  COMPONENT startram
    PORT
  (
    address    : IN STD_LOGIC_VECTOR (9 DOWNTO 0);
    byteena    : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
    clock    : IN STD_LOGIC ;
    data    : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
    wren    : IN STD_LOGIC ;
    q    : OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
    );
  END COMPONENT;


signal shift: std_logic_vector(9 downto 0);
signal clkgen: std_logic_vector(9 downto 0);
signal shiftout: std_logic;
signal txbusy: std_logic;
signal ld: std_logic;
signal rs232_select: std_logic;
signal PART_select: std_logic;
signal SPI_select: std_logic;
signal ROM_select: std_logic;
signal RAM_write: std_logic;
signal part_in: std_logic_vector(15 downto 0);
signal IOdata: std_logic_vector(15 downto 0);
signal IOcpuena: std_logic;

type micro_states is (idle, io_aktion);
signal micro_state    : micro_states;

signal sd_out  : std_logic_vector(7 downto 0);
signal sd_in  : std_logic_vector(7 downto 0);
signal sd_di_in  : std_logic;
signal shiftcnt  : std_logic_vector(13 downto 0);
signal sck    : std_logic;
signal scs    : std_logic_vector(7 downto 0);
signal SD_busy    : std_logic;
signal spi_div: std_logic_vector(7 downto 0);
signal spi_speed: std_logic_vector(7 downto 0);
signal rom_data: std_logic_vector(15 downto 0);

signal timecnt: std_logic_vector(15 downto 0);
signal timeprecnt: std_logic_vector(15 downto 0);

signal byteena_in: std_logic_vector(1 downto 0);
signal wren_in: std_logic;

begin

byteena_in <= (not uds)&(not lds);
wren_in <= RAM_write AND enaWRreg;

srom: startram
  PORT MAP
  (
    address => addr(10 downto 1),  --: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
--    byteena  => byteena_in ,      --  : IN STD_LOGIC_VECTOR (1 DOWNTO 0),
    byteena(0) => not lds,
    byteena(1) => not uds,
    clock   => sysclk,                --: IN STD_LOGIC ;
    data  => cpudata_in,    --  : IN STD_LOGIC_VECTOR (15 DOWNTO 0),
    wren  => RAM_write AND enaWRreg,    --   : IN STD_LOGIC ,
    q    => rom_data
    );




memce <= '0' WHEN ROM_select='0' AND addr(23)='0' ELSE '1';
cpudata <=  rom_data WHEN ROM_select='1' ELSE
      IOdata WHEN IOcpuena='1' ELSE
      part_in WHEN PART_select='1' ELSE
      memdata_in;
part_in <= timecnt;                                             --DEE010


IOdata <= SD_busy&"0000000"&sd_in;
cpuena <= '1' WHEN ROM_select='1' OR PART_select='1' ELSE
      IOcpuena WHEN rs232_select='1' OR SPI_select='1' ELSE
      cpuena_in;

RAM_write <= '1' when ROM_select='1' AND state="11" ELSE '0';
ROM_select <= '1' when addr(23 downto 12)=X"000" ELSE '0';
rs232_select <= '1' when addr(23 downto 12)=X"DA8" ELSE '0';
PART_select <= '1' when addr(23 downto 12)=X"DEE" ELSE '0';
SPI_select <= '1' when addr(23 downto 12)=X"DA4" ELSE '0';


-----------------------------------------------------------------
-- SPI-Interface
-----------------------------------------------------------------
  sd_cs <= NOT scs;
  sd_clk <= NOT sck;
  sd_do <= sd_out(7);
  SD_busy <= shiftcnt(13);

  PROCESS (sysclk, n_reset, scs, sd_di, sd_dimm) BEGIN
      IF scs(1)='1' THEN
        sd_di_in <= sd_di;
      ELSE
        sd_di_in <= sd_dimm;
      END IF;
  END process;



  PROCESS (sysclk, n_reset, scs, sd_di, sd_dimm) BEGIN
    IF n_reset ='0' THEN
      shiftcnt <= (OTHERS => '0');
      spi_div <= (OTHERS => '0');
      scs <= (OTHERS => '0');
      sck <= '0';
      spi_speed <= "00000000";

    ELSIF rising_edge(sysclk) THEN
    IF enaWRreg='1' THEN
      IF SPI_select='1' AND state="11" AND SD_busy='0' THEN   --SD write
        IF addr(3)='1' THEN        --DA4008
          spi_speed <= cpudata_in(7 downto 0);
        ELSIF addr(2)='1' THEN        --DA4004
          scs(0) <= not cpudata_in(0);
          IF cpudata_in(7)='1' THEN
            scs(7) <= not cpudata_in(0);
          END IF;
          IF cpudata_in(6)='1' THEN
            scs(6) <= not cpudata_in(0);
          END IF;
          IF cpudata_in(5)='1' THEN
            scs(5) <= not cpudata_in(0);
          END IF;
          IF cpudata_in(4)='1' THEN
            scs(4) <= not cpudata_in(0);
          END IF;
          IF cpudata_in(3)='1' THEN
            scs(3) <= not cpudata_in(0);
          END IF;
          IF cpudata_in(2)='1' THEN
            scs(2) <= not cpudata_in(0);
          END IF;
          IF cpudata_in(1)='1' THEN
            scs(1) <= not cpudata_in(0);
          END IF;
        ELSE              --DA4000
          spi_div <= spi_speed;
          IF scs(6)='1' THEN    -- SPI direkt Mode
            shiftcnt <= "11000000000111";
          ELSE
            shiftcnt <= "10000000000111";
          END IF;
          sd_out <= cpudata_in(7 downto 0);
          sck <= '1';
        END IF;
      ELSE
        IF spi_div="00000000" THEN
          spi_div <= spi_speed;
          IF SD_busy='1' THEN
            IF sck='0' THEN
              IF shiftcnt(12 downto 0)/="0000000000000" THEN
                sck <='1';
              END IF;
              shiftcnt <= shiftcnt-1;
              sd_out <= sd_out(6 downto 0)&'1';
            ELSE
              sck <='0';
              sd_in <= sd_in(6 downto 0)&sd_di_in;
            END IF;
          END IF;
        ELSE
          spi_div <= spi_div-1;
        END IF;
      END IF;
    END IF;
    END IF;
  END PROCESS;


-----------------------------------------------------------------
-- IO States
-----------------------------------------------------------------
process(sysclk, shift)
begin
  IF rising_edge(sysclk) THEN
  IF enaWRreg='1' THEN
    micro_state <= idle;
    ld <= '0';
    IOcpuena <= '0';
    CASE micro_state IS
      WHEN idle =>
        IF rs232_select='1' AND state="11" THEN
          IF txbusy='0' THEN
            ld <= '1';
            micro_state <= io_aktion;
            IOcpuena <= '1';
          END IF;
        ELSIF SPI_select='1' THEN
          IF SD_busy='0' THEN
            micro_state <= io_aktion;
            IOcpuena <= '1';
          END IF;
        ELSIF addr(23)='1' AND state(1)='1' THEN
          micro_state <= io_aktion;
          IOcpuena <= '1';
        END IF;

      WHEN io_aktion =>
        micro_state <= idle;

      WHEN OTHERS =>
        micro_state <= idle;
    END CASE;
  END IF;
  END IF;
end process;


-----------------------------------------------------------------
-- Simple UART only TxD
-----------------------------------------------------------------
TxD <= not shiftout;
process(n_reset, sysclk, shift) begin
  if shift="0000000000" then
    txbusy <= '0';
  else
    txbusy <= '1';
  end if;
end process;

process(n_reset, sysclk, shift) begin
  if n_reset='0' then
    shiftout <= '0';
    shift <= "0000000000";
  elsif rising_edge(sysclk) then
  IF enaWRreg='1' THEN
    if ld = '1' then
      shift <=  '1' & cpudata_in(15 downto 8) & '0';      --STOP,MSB...LSB, START
    end if;
    if clkgen/=0 then
        clkgen <= clkgen-1;
    else
--      clkgen <= "1110101001";--937;    --108MHz/115200
--      clkgen <= "0011101010";--234;    --27MHz/115200
--      clkgen <= "0011111000";--249-1;    --28,7MHz/115200
--      clkgen <= "0011110101";--246-1;    --28,7MHz/115200
      clkgen <= "0001111100";--249-1;    --14,3MHz/115200
      shiftout <= not shift(0) and txbusy;
         shift <=  '0' & shift(9 downto 1);
    end if;
  END IF;
  end if;
end process;

-----------------------------------------------------------------
-- timer
-----------------------------------------------------------------
process(sysclk)
begin
     IF rising_edge(sysclk) THEN
  IF enaWRreg='1' THEN
    IF timeprecnt=0 THEN
      timeprecnt <= X"3808";
      timecnt <= timecnt+1;
    ELSE
      timeprecnt <= timeprecnt-1;
    END IF;
  END IF;
  end if;
end process;


end;


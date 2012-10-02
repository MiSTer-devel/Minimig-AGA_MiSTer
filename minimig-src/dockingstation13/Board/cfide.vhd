------------------------------------------------------------------------------
------------------------------------------------------------------------------
--                                                                          --
-- Copyright (c) 2008-2011 Tobias Gubener                                   -- 
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
-- MUX CPLD
	mux_clk : out std_logic;
	mux : out std_logic_vector(3 downto 0);
	mux_d : out std_logic_vector(3 downto 0);
	mux_q : in std_logic_vector(3 downto 0);
	sysclk: in std_logic;	
	n_reset: in std_logic;	
	cpuena_in: in std_logic;			
	memdata_in: in std_logic_vector(15 downto 0);		
	addr: in std_logic_vector(23 downto 0);		
	cpudata_in: in std_logic_vector(15 downto 0);	
	state: in std_logic_vector(1 downto 0);		
	lds: in std_logic;			
	uds: in std_logic;			
	sd_di		: in std_logic;
		
	memce: out std_logic;			
	cpudata: out std_logic_vector(15 downto 0);		
	cpuena: buffer std_logic;			
	TxD: out std_logic;			
	sd_cs 		: out std_logic_vector(7 downto 0);
	sd_clk 		: out std_logic;
	sd_do		: out std_logic;
	sd_dimm		: in std_logic;		--for sdcard
	enaWRreg    : in std_logic:='1';
	
	kb_clki: in std_logic;
	kb_datai: in std_logic;
	ms_clki: in std_logic;
	ms_datai: in std_logic;
	kb_clk: out std_logic;
	kb_data: out std_logic;
	ms_clk: out std_logic;
	ms_data: out std_logic;
	nreset: out std_logic;
	ir: buffer std_logic;
	ena1MHz: out std_logic;
	irq_d: in std_logic;
	led: in std_logic_vector(1 downto 0)


   );

end cfide;


architecture wire of cfide is

	COMPONENT startram
    PORT 
	(
		address		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		byteena		: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
    );
	END COMPONENT;




signal shift: std_logic_vector(9 downto 0);
signal clkgen: std_logic_vector(9 downto 0);
signal shiftout: std_logic;
signal txbusy: std_logic;
signal ld: std_logic;
signal rs232_select: std_logic;
signal KEY_select: std_logic;
signal PART_select: std_logic;
signal SPI_select: std_logic;
signal ROM_select: std_logic;
signal RAM_write: std_logic;
signal rs232data: std_logic_vector(15 downto 0);
signal part_in: std_logic_vector(15 downto 0);
signal IOdata: std_logic_vector(15 downto 0);
signal IOcpuena: std_logic;

--type micro_states is (idle, io_aktion, ide1, set_addr, set_data1, set_data2, set_data3, read1, read2, read3, read4, waitclose, setwaitend, waitend);
--signal micro_state		: micro_states;
--signal next_micro_state		: micro_states;

type support_states is (idle, io_aktion);
signal support_state		: support_states;
signal next_support_state		: support_states;

signal sd_out	: std_logic_vector(15 downto 0);
signal sd_in	: std_logic_vector(15 downto 0);
signal sd_in_shift	: std_logic_vector(15 downto 0);
signal sd_di_in	: std_logic;
--signal spi_word	: std_logic;
signal shiftcnt	: std_logic_vector(13 downto 0);
signal sck		: std_logic;
signal scs		: std_logic_vector(7 downto 0);
signal dscs		: std_logic;
signal SD_busy		: std_logic;
signal spi_div: std_logic_vector(7 downto 0);
signal spi_speed: std_logic_vector(7 downto 0);
signal rom_data: std_logic_vector(15 downto 0);

signal timecnt: std_logic_vector(15 downto 0);
signal timeprecnt: std_logic_vector(15 downto 0);

--signal led_green	 : std_logic;
--signal led_red	 : std_logic;
--signal ir	 : std_logic;
signal enacnt: std_logic_vector(6 downto 0);

-- MUX
	signal mux_clk_reg : std_logic := '0';
	signal mux_reg : std_logic_vector(3 downto 0) := (others => '1');
	signal mux_regd : std_logic_vector(3 downto 0) := (others => '1');
	signal mux_d_reg : std_logic_vector(3 downto 0) := (others => '1');
	signal mux_d_regd : std_logic_vector(3 downto 0) := (others => '1');

begin

srom: startram
	PORT MAP 
	(
		address => addr(11 downto 1),	--: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		byteena(0)	=> not lds,			--	: IN STD_LOGIC_VECTOR (1 DOWNTO 0),
		byteena(1)	=> not uds,			--	: IN STD_LOGIC_VECTOR (1 DOWNTO 0),
		clock   => sysclk,								--: IN STD_LOGIC ;
		data	=> cpudata_in,		--	: IN STD_LOGIC_VECTOR (15 DOWNTO 0),
		wren	=> RAM_write AND enaWRreg,		-- 	: IN STD_LOGIC ,
		q		=> rom_data									--: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
    );




memce <= '0' WHEN ROM_select='0' AND addr(23)='0' ELSE '1';
cpudata <=  rom_data WHEN ROM_select='1' ELSE 
			IOdata WHEN IOcpuena='1' ELSE
			part_in WHEN PART_select='1' ELSE 
			memdata_in;
part_in <= 
			timecnt WHEN addr(4 downto 1)="1000" ELSE	--DEE010
			"XXXXXXXX"&"1"&"0000001";-- WHEN addr(4 downto 1)="1001" ELSE	--DEE012
			
IOdata <= sd_in;			
--IOdata <=   --rs232data WHEN rs232_select='1' ELSE 
--			sd_in WHEN SPI_select='1' ELSE
--			IDErd_data(7 downto 0)&IDErd_data(15 downto 8);
cpuena <= '1' WHEN ROM_select='1' OR PART_select='1' OR state="01" ELSE
		  IOcpuena WHEN rs232_select='1' OR SPI_select='1' ELSE 
		  cpuena_in; 

rs232data <= X"FFFF" WHEN txbusy='1' ELSE X"0000";

sd_in(15 downto 8) <= sd_in_shift(15 downto 8) WHEN lds='0' ELSE sd_in_shift(7 downto 0); 
sd_in(7 downto 0) <= sd_in_shift(7 downto 0);

RAM_write <= '1' when ROM_select='1' AND state="11" ELSE '0';
ROM_select <= '1' when addr(23 downto 12)=X"000" ELSE '0';
rs232_select <= '1' when addr(23 downto 12)=X"DA8" ELSE '0';
KEY_select <= '1' when addr(23 downto 12)=X"DE0" ELSE '0';
PART_select <= '1' when addr(23 downto 12)=X"DEE" ELSE '0';
SPI_select <= '1' when addr(23 downto 12)=X"DA4" AND state(1)='1' ELSE '0';

-----------------------------------------------------------------
-- Support States
-----------------------------------------------------------------
process(sysclk, shift)
begin
   	IF sysclk'event AND sysclk = '1' THEN
		IF enacnt="1101100" THEN
			enacnt <= "0000000";
			ena1MHz <= '1';
		ELSE
			enacnt <= enacnt+1;
			ena1MHz <= '0';
		END IF;
		IF enaWRreg='1' THEN
			support_state <= idle;
			ld <= '0';
			IOcpuena <= '0';
			CASE support_state IS
				WHEN idle => 
					IF rs232_select='1' AND state="11" THEN
						IF txbusy='0' THEN
							ld <= '1';
							support_state <= io_aktion;
							IOcpuena <= '1';
						END IF;	
					ELSIF SPI_select='1' THEN		
						IF SD_busy='0' THEN
							support_state <= io_aktion;
							IOcpuena <= '1';
						END IF;
					END IF;
						
				WHEN io_aktion => 
					support_state <= idle;
					
				WHEN OTHERS => 
					support_state <= idle;
			END CASE;
		END IF;	
	END IF;	
end process; 

-- -----------------------------------------------------------------------
-- MUX CPLD
-- -----------------------------------------------------------------------
	-- MUX clock
	process(sysclk)
	begin
		if rising_edge(sysclk) then
--			if enaWRreg = '1' then
				mux_clk_reg <= not mux_clk_reg;
--			end if;
		end if;
	end process;

	-- MUX read
	process(sysclk)
	begin
		if rising_edge(sysclk) then
--			if mux_clk_reg = '1' and enaWRreg = '1' then
			if mux_clk_reg = '1' then
				case mux_reg is
				when X"B" =>
--					reset_button_n <= mux_q(1);
					nreset <= mux_q(1);
--					led_green <= mux_q(1);
					ir <= mux_q(3);
				when X"A" =>
--					vga_id <= mux_q;
				when X"E" =>
					kb_data <= mux_q(0);
					kb_clk <= mux_q(1);
					ms_data <= mux_q(2);
					ms_clk <= mux_q(3);
				when others =>
					null;
				end case;
			end if;
		end if;
	end process;

	-- MUX write
	process(sysclk)
	begin
--		led_red <= ir;
		if rising_edge(sysclk) then
			if mux_clk_reg = '1' then
				mux_reg <= X"C";
				mux_d_reg(3) <= '1';
				mux_d_reg(2) <= NOT scs(1);
				mux_d_reg(1) <= sd_out(15);
				mux_d_reg(0) <= NOT sck;
				case mux_reg is
					when X"6" =>
--						mux_d_reg <= "1111";
--						if docking_station = '1' then
--							mux_d_reg <= "1" & docking_irq & "11";
--						end if;
--						mux_reg <= X"6";
--						
--						mux_d_regd <= "10" & led_green & led_red;
						mux_d_regd <= "10" & led(0) & led(1);
						mux_regd <= X"B";
					when X"B" =>
						mux_d_regd(3 downto 1) <= "111";
						mux_d_regd(0) <= shiftout;
--						mux_d_regd(0) <= '1';
						mux_regd <= X"D";
					when X"C" =>
--	--					mux_d_reg <= iec_reg;
--						mux_regd <= X"D";
						mux_reg <= mux_regd;
						mux_d_reg <= mux_d_regd;
					when X"D" =>
						mux_d_regd(0) <= kb_datai;
						mux_d_regd(1) <= kb_clki;
						mux_d_regd(2) <= ms_datai;
						mux_d_regd(3) <= ms_clki;
						mux_regd <= X"E";
					when X"E" =>
	--					mux_reg <= X"A";
	--					mux_D_reg <= X"F";
--						mux_d_regd <= "10" & led_green & led_red;
--						mux_regd <= X"B";

						mux_d_regd <= "1" & irq_d & "11";
						mux_regd <= X"6";
					when others =>
						mux_regd <= X"B";
--						mux_d_regd <= "10" & led_green & led_red;
						mux_d_regd <= "10" & led(0) & led(1);
				end case;
			end if;
		end if;
	end process;
	
	mux_clk <= mux_clk_reg;
	mux_d <= mux_d_reg;
	mux <= mux_reg;

-----------------------------------------------------------------
-- SPI-Interface
-----------------------------------------------------------------	
	sd_cs <= NOT scs;
	sd_clk <= NOT sck;
	sd_do <= sd_out(15);
	SD_busy <= shiftcnt(13);
	
	PROCESS (sysclk, n_reset, scs, sd_di, sd_dimm) BEGIN
--		IF (sysclk'event AND sysclk='0') THEN
			IF scs(1)='0' THEN
				sd_di_in <= sd_di;
			ELSE	
				sd_di_in <= sd_dimm;
			END IF;
--		END IF;
		IF n_reset ='0' THEN 
			shiftcnt <= (OTHERS => '0');
			spi_div <= (OTHERS => '0');
			scs <= (OTHERS => '0');
			sck <= '0';
			spi_speed <= "00000000";
			dscs <= '0';
		ELSIF (sysclk'event AND sysclk='1') THEN
		IF enaWRreg='1' THEN
			IF SPI_select='1' AND state="11" AND SD_busy='0' THEN	 --SD write
				IF addr(3)='1' THEN				--DA4008
					spi_speed <= cpudata_in(7 downto 0);
				ELSIF addr(2)='1' THEN				--DA4004
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
				ELSE							--DA4000
					spi_div <= spi_speed;
					sd_out <= cpudata_in(15 downto 0);
					IF scs(6)='1' THEN		-- SPI direkt Mode
						shiftcnt <= "10111111111111";
--						shiftcnt <= "100"&cpudata_in(7 downto 0)&"111";
						sd_out <= "1111111111111111";
--						sd_out(15 downto 8) <= cpudata_in(7 downto 0);
					ELSIF uds='0' AND lds='0' THEN
						shiftcnt <= "10000000001111";
--						spi_word <= '1';
					ELSE
						shiftcnt <= "10000000000111";
--						spi_word <= '0';
						IF lds='0' THEN
							sd_out(15 downto 8) <= cpudata_in(7 downto 0);
						END IF;
					END IF;
--					IF uds='1' THEN
--						sd_out(15 downto 8) <= cpudata_in(7 downto 0);
--					END IF;	
					sck <= '1';
--					spi_div <= spi_speed;
--					IF scs(6)='1' THEN		-- SPI direkt Mode
--						shiftcnt <= "10111111111111";
----						shiftcnt <= "100"&cpudata_in(7 downto 0)&"111";
----						sd_out <= "11111111";
--					ELSE
--						shiftcnt <= "10000000000111";
--					END IF;
--					sd_out <= cpudata_in(7 downto 0);
--					sck <= '1';
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
							sd_out <= sd_out(14 downto 0)&'1';
						ELSE	
							sck <='0';
							sd_in_shift <= sd_in_shift(14 downto 0)&sd_di_in;
--							IF spi_word='0' THEN
--								sd_in_shift(8) <= sd_di_in;
--							END IF;
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
-- Simple UART only TxD
-----------------------------------------------------------------
TxD <= not shiftout;
process(n_reset, sysclk, shift)
begin
	if shift="0000000000" then
		txbusy <= '0';
	else
		txbusy <= '1';
	end if;

	if n_reset='0' then
		shiftout <= '0';
		shift <= "0000000000"; 
	elsif sysclk'event and sysclk = '1' then
	IF enaWRreg='1' THEN
		if ld = '1' then
			IF lds='0'THEN
				shift <=  '1' & cpudata_in(7 downto 0) & '0';			--STOP,MSB...LSB, START
			ELSE	
				shift <=  '1' & cpudata_in(15 downto 8) & '0';			--STOP,MSB...LSB, START
			END IF;		
		end if;
		if clkgen/=0 then
			clkgen <= clkgen-1;
		else	
--			clkgen <= "1110101001";--937;		--108MHz/115200
--			clkgen <= "0011101010";--234;		--27MHz/115200
			clkgen <= "0011111000";--249-1;		--28,7MHz/115200
--			clkgen <= "0011110101";--246-1;		--28,7MHz/115200
--			clkgen <= "0001111100";--249-1;		--14,3MHz/115200
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
   	IF sysclk'event AND sysclk = '1' THEN
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

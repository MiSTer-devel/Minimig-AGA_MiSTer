-- -----------------------------------------------------------------------
--
-- Turbo Chameleon
--
-- Multi purpose FPGA expansion for the Commodore 64 computer
--
-- -----------------------------------------------------------------------
-- Copyright 2005-2011 by Peter Wendrich (pwsoft@syntiac.com)
-- All Rights Reserved.
--
-- http://www.syntiac.com/chameleon.html
-- -----------------------------------------------------------------------
--
-- Chameleon docking station
--
-- -----------------------------------------------------------------------
-- clk      - system clock
-- enable   - must be cycle high to advance statemachine (sync with MUX)
-- ena_1mhz - must be one cycle high each micro-second. Used for timers.

-- -----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

-- -----------------------------------------------------------------------

entity chameleon_docking_station is
	port (
		clk : in std_logic;
		
		dotclock_n : in std_logic;
		io_ef_n : in std_logic;
		rom_lh_n : in std_logic;
		irq_d : in std_logic;
		irq_q : out std_logic;
		
		joystick1 : out unsigned(5 downto 0);
		joystick2 : out unsigned(5 downto 0);
		joystick3 : out unsigned(5 downto 0);
		joystick4 : out unsigned(5 downto 0);
		--  0 = col0, row0
		--  1 = col1, row0
		--  8 = col0, row1
		-- 63 = col7, row7
		keys : out unsigned(63 downto 0);
		restore_key_n : out std_logic;
		
	-- Amiga keyboard
		amiga_power_led : in std_logic;
		amiga_drive_led : in std_logic;
		amiga_reset_n : out std_logic;
		amiga_trigger : out std_logic;
		amiga_scancode : out unsigned(7 downto 0)
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of chameleon_docking_station is
	constant shift_reg_bits : integer := 13*8;
	signal shift_reg : unsigned(shift_reg_bits-1 downto 0);
	signal bit_cnt : unsigned(7 downto 0) := (others => '0');
	signal once : std_logic := '0';

	signal key_reg : unsigned(63 downto 0) := (others => '1');
	signal restore_n_reg : std_logic := '1';
	signal joystick1_reg : unsigned(5 downto 0) := (others => '0');
	signal joystick2_reg : unsigned(5 downto 0) := (others => '0');
	signal joystick3_reg : unsigned(5 downto 0) := (others => '0');
	signal joystick4_reg : unsigned(5 downto 0) := (others => '0');
	signal dotclock_n_reg : std_logic := '0';
	signal dotclock_n_dly : std_logic := '0';
	signal io_ef_n_reg : std_logic := '0';
	signal rom_lh_n_reg : std_logic := '1';
	signal irq_q_reg : std_logic := '1';
	
	signal amiga_reset_n_reg : std_logic := '0';
	signal amiga_trigger_reg : std_logic := '0';
	signal amiga_scancode_reg : unsigned(7 downto 0) := (others => '0');
	
	signal dotclock_nd: std_logic;
	signal dotclock_ndd: std_logic;
	signal dotclock_cnt: unsigned(5 downto 0) := (others => '0');
	signal docking_station : std_logic;

	
begin
	joystick1 <= joystick1_reg;
	joystick2 <= joystick2_reg;
	joystick3 <= joystick3_reg;
	joystick4 <= joystick4_reg;
	keys <= key_reg;
	restore_key_n <= restore_n_reg;
	amiga_reset_n <= amiga_reset_n_reg;
	amiga_trigger <= amiga_trigger_reg;
	amiga_scancode <= amiga_scancode_reg;
	irq_q <= irq_q_reg OR NOT docking_station;

	process(clk) is
	begin
		if rising_edge(clk) then
			dotclock_nd <= dotclock_n;
			dotclock_ndd <= dotclock_nd;
			IF dotclock_ndd='0' AND dotclock_nd='1' THEN
				dotclock_cnt <= (others => '0');
			ELSIF dotclock_ndd='1' AND dotclock_nd='0' THEN
				IF dotclock_cnt(5 downto 4)="01" THEN  --0x10-0x1F(0x19)
					docking_station <= '1';				--Docking Station
				ELSE	
					docking_station <= '0';				--C64
				END IF;
			ELSIF dotclock_ndd='1' THEN
				dotclock_cnt <= dotclock_cnt+1;
				IF dotclock_cnt(5)='1' THEN
					docking_station <= '0';				--Single
				END IF;
			END IF;
		end if;
	end process;
	
	--
	-- Sample DotClock, IO_EF and ROM_LH input.
	process(clk) is
	begin
		if rising_edge(clk) then
			dotclock_n_reg <= dotclock_n;
			dotclock_n_dly <= dotclock_n_reg;
			io_ef_n_reg <= io_ef_n;
			rom_lh_n_reg <= rom_lh_n;
		end if;
	end process;

	--
	-- Receive serial stream
	process(clk) is
	begin
		if rising_edge(clk) then
			if (dotclock_n_reg = '0') and (dotclock_n_dly = '1') then
				shift_reg <= (not rom_lh_n_reg) & shift_reg(shift_reg'high downto 1);
				bit_cnt <= bit_cnt + 1;
			end if;
			if (io_ef_n_reg = '1') and (bit_cnt >= shift_reg_bits) then
				-- Word trigger. Signals start of serial bit-stream.
				bit_cnt <= (others => '0');
			end if;
		end if;
	end process;
	
	--
	-- Amiga keyboard LED control
	process(clk) is
	begin
		if rising_edge(clk) then
			irq_q_reg <= '1';
			if (bit_cnt >= 40) and (bit_cnt < 56) then
				irq_q_reg <= amiga_power_led;
			end if;
			if (bit_cnt >= 72) and (bit_cnt < 88) then
				irq_q_reg <= amiga_drive_led;
			end if;
		end if;
	end process;

	--
	-- Decode bytes
	process(clk) is
	begin
		if rising_edge(clk) then
			if bit_cnt = shift_reg_bits then
				-- Map shifted bits to joysticks

--				joystick1_reg <= shift_reg(101 downto 96);
				joystick1_reg <= shift_reg(101)& shift_reg(100) & shift_reg(96) & shift_reg(97) & shift_reg(98) & shift_reg(99);
--				joystick2_reg <= shift_reg(85 downto 80);
				joystick2_reg <= shift_reg(85)& shift_reg(84) & shift_reg(80) & shift_reg(81) & shift_reg(82) & shift_reg(83);
--				joystick3_reg <= shift_reg(102)& shift_reg(103) & shift_reg(92) & shift_reg(93) & shift_reg(94) & shift_reg(95);
				joystick3_reg <= shift_reg(102)& shift_reg(103) & shift_reg(95) & shift_reg(94) & shift_reg(93) & shift_reg(92);
--				joystick4_reg <= shift_reg(86) & shift_reg(87) & shift_reg(88) & shift_reg(89) & shift_reg(90) & shift_reg(91);
				joystick4_reg <= shift_reg(86) & shift_reg(87) & shift_reg(91) & shift_reg(90) & shift_reg(89) & shift_reg(88);
				restore_n_reg <= shift_reg(1);

				-- Map shifted bits to C64 keyboard
				if (shift_reg(87 downto 80) = X"FF") and (shift_reg(103 downto 96) = X"FF") then
					for row in 0 to 7 loop
						for col in 0 to 7 loop
							-- uC scans column wise.
							key_reg(row*8 + col) <= shift_reg(16 + col*8 + row);
						end loop;
					end loop;
				else
					-- Prevent conflict between keyboard and joystick.
					-- Relase all keyboard keys while joystick button(s) are pressed.
					key_reg <= (others => '1');
				end if;
				
				-- Amiga keyboard
				amiga_reset_n_reg <= shift_reg(2);
				if shift_reg(0) = '1' then
					amiga_scancode_reg <= shift_reg(15 downto 8);
					amiga_trigger_reg <= once;
				end if;
				once <= '0';
			end if;
			if (io_ef_n_reg = '1') then
				once <= '1';
			end if;

			-- No docking station connected.
			-- Disable all outputs to prevent conflicts.
			if docking_station = '0' then
				joystick1_reg <= (others => '1');
				joystick2_reg <= (others => '1');
				joystick3_reg <= (others => '1');
				joystick4_reg <= (others => '1');
				key_reg <= (others => '1');
				restore_n_reg <= '1';
				amiga_reset_n_reg <= '1';
			end if;
		end if;
	end process;
end architecture;

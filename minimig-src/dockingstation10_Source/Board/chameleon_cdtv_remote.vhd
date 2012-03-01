-- -----------------------------------------------------------------------
--
-- Turbo Chameleon
--
-- Multi purpose FPGA expansion for the Commodore 64 computer
--
-- -----------------------------------------------------------------------
-- Copyright 2005-2011 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/chameleon.html
--
-- This source file is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published
-- by the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This source file is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
--
-- -----------------------------------------------------------------------
--
-- CDTV IR remote
--
-- -----------------------------------------------------------------------
-- clk         - system clock input
-- ena_1mhz    - Enable must be '1' one clk cycle each 1 Mhz.
-- ir          - signal from infra-red detector.
--
-- key_1       - high when "1" is pressed on remote
-- key_2       - high when "2" is pressed on remote
-- key_3       - high when "3" is pressed on remote
-- key_4       - high when "4" is pressed on remote
-- key_5       - high when "5" is pressed on remote
-- key_6       - high when "6" is pressed on remote
-- key_7       - high when "7" is pressed on remote
-- key_8       - high when "8" is pressed on remote
-- key_9       - high when "9" is pressed on remote
-- key_0       - high when "0" is pressed on remote
-- key_escape  - high when "ESCAPE" is pressed on remote
-- key_enter   - high when "ENTER" is pressed on remote
-- key_genlock - high when "GENLOCK" is pressed on remote
-- key_cdtv    - high when "CD/TV" is pressed on remote
-- key_power   - high when "POWER" is pressed on remote
-- key_rew     - high when "REW" is pressed on remote
-- key_play    - high when "PLAY/PAUSE" is pressed on remote
-- key_ff      - high when "FF" is pressed on remote
-- key_stop    - high when "STOP" is pressed on remote
-- key_vol_up  - high when "VOL up" is pressed on remote
-- key_vol_dn  - high when "VOL dn" is pressed on remote
-- joystick_a  - first joystick emulation output (bits are '1' when idle).
--               This output is active when remote is in MOUSE mode.
-- joystick_b  - second joystick emulation output (bits are '1' when idle).
--               This output is active when remote is in JOY mode.
-- -----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

-- -----------------------------------------------------------------------

entity chameleon_cdtv_remote is
	port (
		clk : in std_logic;
		ena_1mhz : in std_logic;
		ir : in std_logic := '1';
		
		trigger : out std_logic;

		key_1 : out std_logic;
		key_2 : out std_logic;
		key_3 : out std_logic;
		key_4 : out std_logic;
		key_5 : out std_logic;
		key_6 : out std_logic;
		key_7 : out std_logic;
		key_8 : out std_logic;
		key_9 : out std_logic;
		key_0 : out std_logic;
		key_escape : out std_logic;
		key_enter : out std_logic;
		key_genlock : out std_logic;
		key_cdtv : out std_logic;
		key_power : out std_logic;
		key_rew : out std_logic;
		key_play : out std_logic;
		key_ff : out std_logic;
		key_stop : out std_logic;
		key_vol_up : out std_logic;
		key_vol_dn : out std_logic;
		joystick_a : out unsigned(5 downto 0);
		joystick_b : out unsigned(5 downto 0)
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of chameleon_cdtv_remote is
	constant long_timeout  : integer := 110000; -- 110 msec, this timeout is used while receiving a code (timeout is extended)
	constant short_timeout : integer :=  75000; --  75 msec, this timeout is used while waiting
	type state_t is (
		STATE_IDLE,         -- Nothing received
		STATE_END_CODE,     -- Code received, reseting timeouts
		STATE_WAIT_REPEAT,  -- Waiting for new code or key-held code (for 75 ms)
		STATE_START,        -- Start of new code
		STATE_LOW,          -- receive ir signal is low
		STATE_HIGH          -- receive ir signal is high
		);
	signal state : state_t := STATE_IDLE;
	
	signal pre_trigger : std_logic := '0'; -- trigger out 1 clock later to sync with decoding logic
	signal timer : integer range 0 to long_timeout := 0;
	signal bitlength : integer range 0 to 16000 := 0;
	signal bitcount : integer range 0 to 24 := 0;
	signal shiftreg : unsigned(23 downto 0) := (others => '0');
	signal current_code : unsigned(11 downto 0) := (others => '1');
begin
	process(clk)
	begin
		if rising_edge(clk) then
			pre_trigger <= '0';
		-- State machine
			case state is
			when STATE_IDLE =>
				if (ir = '1') and (bitlength > 8500) then
					state <= STATE_START;
				end if;
				bitcount <= 0;
			when STATE_END_CODE =>
				-- Transient state to reset timer.
				-- Wait for next repeat or new code until timeout.
				state <= STATE_WAIT_REPEAT;
				bitcount <= 0;
			when STATE_WAIT_REPEAT =>
				if (ir = '1') and (bitlength > 8500) then
					state <= STATE_START;
				end if;
				bitcount <= 0;
			when STATE_START =>
				if (ir = '0') and (bitlength > 1500) and (bitlength < 3000) then
					-- It is a key-held code. No further processing.
					state <= STATE_END_CODE;
				end if;
				if (ir = '0') and (bitlength >= 3000) then
					state <= STATE_LOW;
				end if;
				bitcount <= 0;
			when STATE_LOW =>
				if ir = '1' then
					state <= STATE_HIGH;
				end if;
				if bitcount = 24 then
					state <= STATE_END_CODE;
					if shiftreg(23 downto 12) = (not shiftreg(11 downto 0)) then
						-- Valid code
						current_code <= shiftreg(23 downto 12);
						pre_trigger <= '1';
					end if;
				end if;
			when STATE_HIGH =>
				if ir = '0' then
					state <= STATE_LOW;
					bitcount <= bitcount + 1;
					if bitlength > 800 then
						-- Long bit (1100)
						shiftreg <= shiftreg(shiftreg'high-1 downto shiftreg'low) & '1';
					else
						-- short bit (420)
						shiftreg <= shiftreg(shiftreg'high-1 downto shiftreg'low) & '0';
					end if;
				end if;
			end case;

		-- Determine bit-length
			if (ir = '1' and ((state = STATE_IDLE) or (state = STATE_WAIT_REPEAT) or (state = STATE_LOW)))
			or (ir = '0' and ((state = STATE_START) or (state = STATE_HIGH))) then
				bitlength <= 0;
			elsif ena_1mhz = '1' then
				bitlength <= bitlength + 1;
			end if;

		-- Process timeout
			if (state = STATE_IDLE) or (state = STATE_END_CODE) then
				timer <= 0;
			elsif timer = long_timeout then
				-- Timeout occured, reset statemachine
				state <= STATE_IDLE;
				bitlength <= 0;
				current_code <= (others => '1');
			elsif (timer >= short_timeout) and (state = STATE_WAIT_REPEAT) then
				-- Timeout occured, reset statemachine
				state <= STATE_IDLE;
				bitlength <= 0;
				current_code <= (others => '1');
			elsif ena_1mhz = '1' then
				timer <= timer + 1;
			end if;
		end if;
	end process;

	decode_ir_code: process(clk)
	begin
		if rising_edge(clk) then
			trigger <= pre_trigger;			
			key_1 <= '0';
			key_2 <= '0';
			key_3 <= '0';
			key_4 <= '0';
			key_5 <= '0';
			key_6 <= '0';
			key_7 <= '0';
			key_8 <= '0';
			key_9 <= '0';
			key_0 <= '0';
			key_escape <= '0';
			key_enter <= '0';
			key_genlock <= '0';
			key_cdtv <= '0';
			key_power <= '0';
			key_rew <= '0';
			key_play <= '0';
			key_ff <= '0';
			key_stop <= '0';
			key_vol_up <= '0';
			key_vol_dn <= '0';
			joystick_a <= (others => '1');
			joystick_b <= (others => '1');
			
			case current_code(5 downto 0) is
			when "000001" => key_1 <= '1';
			when "100001" => key_2 <= '1';
			when "010001" => key_3 <= '1';
			when "001001" => key_4 <= '1';
			when "101001" => key_5 <= '1';
			when "011001" => key_6 <= '1';
			when "000101" => key_7 <= '1';
			when "100101" => key_8 <= '1';
			when "010101" => key_9 <= '1';
			when "111001" => key_0 <= '1';
			when "110001" => key_escape <= '1';
			when "110101" => key_enter <= '1';
			when "100010" => key_genlock <= '1';
			when "000010" => key_cdtv <= '1';
			when "010010" => key_power <= '1';
			when "110010" => key_rew <= '1';
			when "001010" => key_play <= '1';
			when "011010" => key_ff <= '1';
			when "101010" => key_stop <= '1';
			when "000110" => key_vol_up <= '1';
			when "111010" => key_vol_dn <= '1';
			when others =>
				null;
			end case;
			
			if (current_code(11) = '0') and (current_code(1 downto 0) = "00") then
--				joystick_a <= not (current_code(6) & current_code(7) & current_code(2) & current_code(3) & current_code(4) & current_code(5));
				joystick_a <= not (current_code(6) & current_code(7) & current_code(5) & current_code(4) & current_code(3) & current_code(2));
			end if;
			if (current_code(11) = '1') and (current_code(1 downto 0) = "00") then
--				joystick_b <= not (current_code(6) & current_code(7) & current_code(2) & current_code(3) & current_code(4) & current_code(5));
				joystick_b <= not (current_code(6) & current_code(7) & current_code(5) & current_code(4) & current_code(3) & current_code(2));
			end if;
		end if;	
	end process;

end architecture;






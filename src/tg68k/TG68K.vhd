------------------------------------------------------------------------------
------------------------------------------------------------------------------
--                                                                          --
-- Copyright (c) 2009-2011 Tobias Gubener                                   --
-- Subdesign fAMpIGA by TobiFlex                                            --
--                                                                          --
-- This is the TOP-Level for TG68KdotC_Kernel to generate 68K Bus signals   --
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


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity TG68K is
  port(
    clk           : in      std_logic;
    reset         : in      std_logic;
    clkena_in     : in      std_logic:='1';
    IPL           : in      std_logic_vector(2 downto 0):="111";
    dtack         : in      std_logic;
    addr          : buffer  std_logic_vector(31 downto 0);
    data_read     : in      std_logic_vector(15 downto 0);
    data_write    : buffer  std_logic_vector(15 downto 0);
    as            : out     std_logic;
    uds           : out     std_logic;
    lds           : out     std_logic;
    rw            : out     std_logic;
    ena7RDreg     : in      std_logic:='1';
    ena7WRreg     : in      std_logic:='1';
    fromram       : in      std_logic_vector(15 downto 0);
    ramready      : in      std_logic:='0';
    cpu           : in      std_logic_vector(1 downto 0);
    fastramcfg    : in      std_logic_vector(2 downto 0);
    turbochipram  : in      std_logic;
    turbokick     : in      std_logic;
    bootrom       : in      std_logic:='0';
    cache_inhibit : out     std_logic;
    ramaddr       : out     std_logic_vector(31 downto 0);
    ramcs         : out     std_logic;
    cpustate      : out     std_logic_vector(1 downto 0);
    nResetOut     : buffer  std_logic;
    ramlds        : out     std_logic;
    ramuds        : out     std_logic;
    CACR_out      : buffer  std_logic_vector(3 downto 0);
    VBR_out       : buffer  std_logic_vector(31 downto 0)
  );
end TG68K;


ARCHITECTURE logic OF TG68K IS

SIGNAL cpuaddr          : std_logic_vector(31 downto 0);
SIGNAL r_data           : std_logic_vector(15 downto 0);
SIGNAL cpuIPL           : std_logic_vector(2 downto 0);
SIGNAL as_s             : std_logic;
SIGNAL as_e             : std_logic;
SIGNAL uds_s            : std_logic;
SIGNAL uds_e            : std_logic;
SIGNAL lds_s            : std_logic;
SIGNAL lds_e            : std_logic;
SIGNAL rw_s             : std_logic;
SIGNAL rw_e             : std_logic;
SIGNAL waitm            : std_logic;
SIGNAL clkena_e         : std_logic;
SIGNAL S_state          : std_logic_vector(1 downto 0);
SIGNAL wr               : std_logic;
SIGNAL uds_in           : std_logic;
SIGNAL lds_in           : std_logic;
SIGNAL state            : std_logic_vector(1 downto 0);
SIGNAL clkena           : std_logic;
SIGNAL sel_autoconfig   : std_logic;
SIGNAL autoconfig_out   : std_logic_vector(1 downto 0); -- We use this as a counter since we have two cards to configure
SIGNAL autoconfig_data  : std_logic_vector(3 downto 0);
SIGNAL sel_ram          : std_logic;
SIGNAL sel_chipram      : std_logic;
SIGNAL turbochip_ena    : std_logic := '0';
SIGNAL turbochip_d      : std_logic := '0';
SIGNAL turbokick_d      : std_logic := '0';

SIGNAL datatg68         : std_logic_vector(15 downto 0);

SIGNAL z2ram_ena        : std_logic;
SIGNAL z3ram_base0      : std_logic_vector(4 downto 0);
SIGNAL z3ram_base1      : std_logic_vector(3 downto 0);
SIGNAL z3ram_ena0       : std_logic;
SIGNAL z3ram_ena1       : std_logic;
SIGNAL sel_z2ram        : std_logic;
SIGNAL sel_z3ram0       : std_logic;
SIGNAL sel_z3ram1       : std_logic;
SIGNAL sel_kickram      : std_logic;
signal sel_kicklower    : std_logic;

SIGNAL NMI_addr         : std_logic_vector(31 downto 0);
SIGNAL sel_nmi_vector   : std_logic;

BEGIN

-- NMI
PROCESS(clk) BEGIN
	IF rising_edge(clk) THEN
		IF reset='0' THEN
			NMI_addr <= X"0000007c";
		ELSE
			NMI_addr <= VBR_out + X"0000007c";
		END IF;
	END IF;
END PROCESS;


addr <= cpuaddr;
datatg68 <= fromram WHEN sel_ram='1' and sel_nmi_vector='0' 
       ELSE autoconfig_data&r_data(11 downto 0) WHEN sel_autoconfig='1'
       ELSE r_data;

sel_autoconfig  <= '1' WHEN fastramcfg/="000" AND cpuaddr(23 downto 19)="11101" AND autoconfig_out/="00" ELSE '0'; --$E80000 - $EFFFFF
sel_z3ram0      <= '1' WHEN (cpuaddr(31 downto 27) = z3ram_base0) AND z3ram_ena0='1' ELSE '0';
sel_z3ram1      <= '1' WHEN (cpuaddr(31 downto 28) = z3ram_base1) AND z3ram_ena1='1' ELSE '0';
sel_z2ram       <= '1' WHEN (cpuaddr(31 downto 24) = "00000000") AND ((cpuaddr(23 downto 21) = "001") OR (cpuaddr(23 downto 21) = "010") OR (cpuaddr(23 downto 21) = "011") OR (cpuaddr(23 downto 21) = "100")) AND z2ram_ena='1' ELSE '0';

-- turbochip is off during boot overlay
sel_chipram     <= '1' WHEN (cpuaddr(31 downto 24) = "00000000") AND (cpuaddr(23 downto 21)="000") AND turbochip_d='1' ELSE '0'; --$000000 - $1FFFFF

-- don't sel_kickram when writing (state = "11")
sel_kickram     <= '1' WHEN (cpuaddr(31 downto 24) = "00000000") AND ((cpuaddr(23 downto 19)="11111") OR (cpuaddr(23 downto 19)="11100"))  AND turbokick_d='1' and state /="11"  ELSE '0'; -- $f8xxxx, e0xxxx

sel_kicklower   <= '1' when (cpuaddr(31 downto 24) = "00000000") AND (cpuaddr(23 downto 18)="111110") else '0';

--  we route everything hrtmon related through cart.v (needs a couple of signals to
--  decide what to do, would not be good style to replicate that here). 
sel_nmi_vector  <= '1' WHEN (cpuaddr(31 downto 2) = NMI_addr(31 downto 2)) and state="10"  ELSE '0';
-- sel_cart        <= '1' when  (cpuaddr(31 downto 24) = "00000000") AND (cpuaddr(23 downto 20)="1010")  AND turbochip_ena='1' AND turbokick_d='1' ELSE '0';

--  added fast access to slowram $c0-$d8, when turobochip is enabled.
-- sel_slowram    <= '1'  when (cpuaddr(31 downto 24) = "00000000") AND ( (cpuaddr(23 downto 20)="1100") or (cpuaddr (23 downto 19) = "11010"))  AND turbochip_ena='1' AND turbochip_d='1' ELSE '0';
-- could only enable this if slowram is set to 1.5M (like for chipram). But
-- there also seems to be another problem. Somehow fails with bootrom and AGA.
-- 

sel_ram         <= '1'  WHEN state/="01" and sel_nmi_vector='0' AND (sel_z2ram='1' OR sel_z3ram0='1' OR sel_z3ram1='1' OR sel_chipram='1' OR sel_kickram='1') ELSE '0';

cache_inhibit   <= '0'; --'1' WHEN sel_chipram='1' OR sel_kickram='1' ELSE '0';

cpustate <= state;
ramlds <= lds_in;
ramuds <= uds_in;

-- This is the mapping to the sram
-- map 00-1f to 00-1f (chipram), a0-ff to 20-7f. All non-fastram goes into the first
-- 8M block. This map should be the same as in minimig_sram_bridge.v 
-- 8M Zorro II RAM 20-9f goes to 80-ff 
ramaddr(31 downto 30) <= "00";
ramaddr(29)           <= sel_z3ram0 or sel_z3ram1 or sel_z2ram;
ramaddr(28)           <= not sel_z3ram0;
ramaddr(27)           <= cpuaddr(27) when sel_z3ram1 = '1' else '1';
ramaddr(26 downto 23) <= cpuaddr(26 downto 23) when (sel_z3ram0 or sel_z3ram1) = '1' else (others => '0');
ramaddr(22 downto 19) <= cpuaddr(22 downto 19);
ramaddr(18)           <= '1' when (sel_kicklower = '1' and bootrom= '1') else cpuaddr(18); 
ramaddr(17 downto 0)  <= cpuaddr(17 downto 0);

pf68K_Kernel_inst: work.TG68KdotC_Kernel
generic map
(
	SR_Read        => 2, -- 0=>user,   1=>privileged,    2=>switchable with CPU(0)
	VBR_Stackframe => 2, -- 0=>no,     1=>yes/extended,  2=>switchable with CPU(0)
	extAddr_Mode   => 2, -- 0=>no,     1=>yes,           2=>switchable with CPU(1)
	MUL_Mode       => 2, -- 0=>16Bit,  1=>32Bit,         2=>switchable with CPU(1),  3=>no MUL,
	DIV_Mode       => 2, -- 0=>16Bit,  1=>32Bit,         2=>switchable with CPU(1),  3=>no DIV,
	BitField       => 2  -- 0=>no,     1=>yes,           2=>switchable with CPU(1)
)
PORT MAP
(
	clk            => clk,           -- : in std_logic;
	nReset         => reset,         -- : in std_logic:='1';      --low active
	clkena_in      => clkena,        -- : in std_logic:='1';
	data_in        => datatg68,      -- : in std_logic_vector(15 downto 0);
	IPL            => cpuIPL,        -- : in std_logic_vector(2 downto 0):="111";
	IPL_autovector => '1',           -- : in std_logic:='0';
	regin_out      => open,          -- : out std_logic_vector(31 downto 0);
	addr_out       => cpuaddr,       -- : buffer std_logic_vector(31 downto 0);
	data_write     => data_write,    -- : out std_logic_vector(15 downto 0);
	nWr            => wr,            -- : out std_logic;
	nUDS           => uds_in,
	nLDS           => lds_in,        -- : out std_logic;
	nResetOut      => nResetOut,

	CPU            => cpu,
	busstate       => state,         -- 00->fetch code 10->read data 11->write data 01->no memaccess
	CACR_out       => CACR_out,
	VBR_out        => VBR_out
);


PROCESS(clk,turbochipram, turbokick) BEGIN
	IF rising_edge(clk) THEN
          IF (reset='0' or nResetOut='0' ) THEN
			turbochip_d <= '0';
			turbokick_d <= '0';
		ELSIF state="01" THEN -- No mem access, so safe to switch chipram access mode
			turbochip_d<=turbochipram;
			turbokick_d<=turbokick;
		END IF;
	END IF;
END PROCESS;

PROCESS (clk, fastramcfg, autoconfig_out, cpuaddr) BEGIN
	autoconfig_data <= "1111";

	IF autoconfig_out /= "00" THEN
		if fastramcfg(2) = '0' then
			-- Zorro II RAM (Up to 8 meg at 0x200000)
			CASE cpuaddr(6 downto 1) IS
				WHEN "000000" => autoconfig_data <= "1110";    -- Zorro-II card, add mem, no ROM
				WHEN "000001" => 
					CASE fastramcfg(1 downto 0) IS
						WHEN   "01" => autoconfig_data <= "0110";  -- 2MB
						WHEN   "10" => autoconfig_data <= "0111";  -- 4MB
						WHEN OTHERS => autoconfig_data <= "0000";  -- 8MB
					END CASE;
				WHEN "001000" => autoconfig_data <= "1110";    -- Manufacturer ID: 0x139c
				WHEN "001001" => autoconfig_data <= "1100";
				WHEN "001010" => autoconfig_data <= "0110";
				WHEN "001011" => autoconfig_data <= "0011";
				WHEN "010011" => autoconfig_data <= "1110";    --serial=1
				WHEN OTHERS => null;
			END CASE;
		else
			-- Zorro III RAM 256MB
			CASE cpuaddr(6 downto 1) IS
				WHEN "000000" => autoconfig_data <= "1010";    -- Zorro-III card, add mem, no ROM
				WHEN "000001" =>
					if autoconfig_out(1) = '1' then
						autoconfig_data <= "0011";    -- 128MB/extended
					else
						autoconfig_data <= "0100";    -- 256MB/extended
					end if;
				WHEN "000010" => autoconfig_data <= "1110";    -- ProductID=0x10 (only setting upper nibble)
				WHEN "000100" => autoconfig_data <= "0000";    -- Memory card, not silenceable, Extended size, reserved.
				WHEN "000101" => autoconfig_data <= "1111";    -- 0000 - logical size matches physical size TODO change this to 0001, so it is autosized by the OS, WHEN it will be 24MB.
				WHEN "001000" => autoconfig_data <= "1110";    -- Manufacturer ID: 0x139c
				WHEN "001001" => autoconfig_data <= "1100";
				WHEN "001010" => autoconfig_data <= "0110";
				WHEN "001011" => autoconfig_data <= "0011";
				WHEN "010011" => autoconfig_data <= "11"& not autoconfig_out; -- serial=1/2
				WHEN OTHERS => null;
			END CASE;
		end if;
	END IF;

	IF rising_edge(clk) THEN
		IF (reset='0' or nResetOut='0') THEN
			autoconfig_out <= "01";    --autoconfig on
			z2ram_ena  <='0';
			z3ram_ena0 <='0';
			z3ram_ena1 <='0';
			z3ram_base0<="00001";
			z3ram_base1<="0001";
		ELSIF sel_autoconfig='1' AND state="11"AND uds_in='0' AND clkena='1' THEN
			if fastramcfg(2) = '0' then
				if cpuaddr(6 downto 1) = "100100" then -- Register 0x48 - config, ZII RAM
					z2ram_ena <= '1';
					autoconfig_out<="00";
				end if;
			else
				if cpuaddr(6 downto 1) = "100010" then -- Register 0x44, assign base address to ZIII RAM.
					if autoconfig_out = "01" then
						z3ram_base1    <= data_write(15 downto 12);
						z3ram_ena1     <= '1';
						autoconfig_out <= fastramcfg(0)&'0';
					else
						z3ram_base0    <= data_write(15 downto 11);
						z3ram_ena0     <= '1';
						autoconfig_out <= "00";
					end if;
				end if;
			end if;
		END IF;
	END IF;
END PROCESS;

clkena <= '1' when (clkena_in='1' AND (state="01" OR (ena7RDreg='1' AND clkena_e='1') OR ramready='1')) else '0';

PROCESS (clk) BEGIN
	IF rising_edge(clk) THEN
		IF clkena='1' THEN
			ramcs <= '0';
		ELSE
			ramcs <= sel_ram;
		END IF;
	END IF;
END PROCESS;

PROCESS (clk, reset, state, as_s, as_e, rw_s, rw_e, uds_s, uds_e, lds_s, lds_e, sel_ram) BEGIN
	IF state="01" THEN
		as  <= '1';
		rw  <= '1';
		uds <= '1';
		lds <= '1';
	ELSE
		as  <= (as_s AND as_e) OR sel_ram;
		rw  <= rw_s AND rw_e;
		uds <= uds_s AND uds_e;
		lds <= lds_s AND lds_e;
	END IF;

	IF (reset='0') THEN
		S_state <= "00";
		as_s  <= '1';
		rw_s  <= '1';
		uds_s <= '1';
		lds_s <= '1';
	ELSIF rising_edge(clk) THEN
		IF ena7WRreg='1' THEN
			as_s  <= '1';
			rw_s  <= '1';
			uds_s <= '1';
			lds_s <= '1';
			CASE S_state IS
				WHEN "00" =>
					IF state/="01" AND sel_ram='0' THEN
						uds_s   <= uds_in;
						lds_s   <= lds_in;
						S_state <= "01";
					END IF;
				WHEN "01" =>
					as_s    <= '0';
					rw_s    <= wr;
					uds_s   <= uds_in;
					lds_s   <= lds_in;
					S_state <= "10";
				WHEN "10" =>
					r_data <= data_read;
					IF waitm='0' THEN
						S_state <= "11";
					ELSE
						as_s  <= '0';
						rw_s  <= wr;
						uds_s <= uds_in;
						lds_s <= lds_in;
					END IF;
				WHEN "11" =>
					S_state <= "00";
				WHEN OTHERS => null;
			END CASE;
		END IF;
	END IF;
	
	IF (reset='0' ) THEN
		as_e  <= '1';
		rw_e  <= '1';
		uds_e <= '1';
		lds_e <= '1';
		clkena_e <= '0';
	ELSIF rising_edge(clk) THEN
		IF ena7RDreg='1' THEN
			as_e  <= '1';
			rw_e  <= '1';
			uds_e <= '1';
			lds_e <= '1';
			clkena_e <= '0';
			CASE S_state IS
				WHEN "00" =>
					cpuIPL <= IPL;
					IF sel_ram='0' THEN
						IF state/="01" THEN
							as_e <= '0';
						END IF;
						rw_e <= wr;
						IF wr='1' THEN
							uds_e <= uds_in;
							lds_e <= lds_in;
						END IF;
					END IF;
				WHEN "01" =>
					as_e  <= '0';
					rw_e  <= wr;
					uds_e <= uds_in;
					lds_e <= lds_in;
				WHEN "10" =>
					rw_e   <= wr;
					cpuIPL <= IPL;
					waitm  <= dtack;
				WHEN OTHERS =>
					clkena_e <= '1';
			END CASE;
		END IF;
	END IF;
END PROCESS;

END;


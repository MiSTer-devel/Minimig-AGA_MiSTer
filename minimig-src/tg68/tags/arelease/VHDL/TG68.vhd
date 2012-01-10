------------------------------------------------------------------------------
------------------------------------------------------------------------------
--                                                                          --
-- This is the TOP-Level for TG68_fast to generate 68K Bus signals          --
--                                                                          --
-- Copyright (c) 2007 Tobias Gubener <tobiflex@opencores.org>               -- 
--                                                                          --
-- This source file is free software: you can redistribute it and/or modify --
-- it under the terms of the GNU Lesser General Public License as published --
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
--
-- Revision 1.0 2007/11/05
-- Clean up code and first release
--
-- known bugs/todo:
-- Add CHK INSTRUCTION
-- Add MOVEP INSTRUCTION
-- full decode ILLEGAL INSTRUCTIONS
-- Add FDC Output
-- add odd Address test
-- add TRACE
-- Movem with regmask==x0000



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity TG68 is
   port(        
		clk           : in std_logic;
		reset         : in std_logic;
        clkena_in     : in std_logic:='1';
        data_in       : in std_logic_vector(15 downto 0);
        IPL           : in std_logic_vector(2 downto 0):="111";
        dtack         : in std_logic;
        addr          : out std_logic_vector(31 downto 0);
        data_out      : out std_logic_vector(15 downto 0);
        as            : out std_logic;
        uds           : out std_logic;
        lds           : out std_logic;
        rw            : out std_logic
        );
end TG68;

ARCHITECTURE logic OF TG68 IS

	COMPONENT TG68_fast
    PORT (
        clk           : in std_logic;
        reset         : in std_logic;
        clkena_in     : in std_logic;
        data_in       : in std_logic_vector(15 downto 0);
		IPL			  : in std_logic_vector(2 downto 0);
        test_IPL      : in std_logic;
        address       : out std_logic_vector(31 downto 0);
        data_write    : out std_logic_vector(15 downto 0);
        state_out     : out std_logic_vector(1 downto 0);
        decodeOPC     : buffer std_logic;
		wr			  : out std_logic;
		UDS, LDS	  : out std_logic
        );
	END COMPONENT;


   SIGNAL as_s        : std_logic;
   SIGNAL as_e        : std_logic;
   SIGNAL uds_s       : std_logic;
   SIGNAL uds_e       : std_logic;
   SIGNAL lds_s       : std_logic;
   SIGNAL lds_e       : std_logic;
   SIGNAL rw_s        : std_logic;
   SIGNAL rw_e        : std_logic;
   SIGNAL waitm       : std_logic;
   SIGNAL clkena_e    : std_logic;
   SIGNAL S_state     : std_logic_vector(1 downto 0);
   SIGNAL decode	  : std_logic;
   SIGNAL wr	      : std_logic;
   SIGNAL uds_in	  : std_logic;
   SIGNAL lds_in	  : std_logic;
   SIGNAL state       : std_logic_vector(1 downto 0);
   SIGNAL clkena	  : std_logic;


BEGIN  

TG68_fast_inst: TG68_fast
	PORT MAP (
		clk => not clk, 		-- : in std_logic;
        reset => reset, 		-- : in std_logic;
        clkena_in => clkena, 	-- : in std_logic;
        data_in => data_in, 	-- : in std_logic_vector(15 downto 0);
		IPL => IPL, 			-- : in std_logic_vector(2 downto 0);
        test_IPL => '0', 		-- : in std_logic;
        address => addr, 		-- : out std_logic_vector(31 downto 0);
        data_write => data_out, -- : out std_logic_vector(15 downto 0);
        state_out => state, 	-- : out std_logic_vector(1 downto 0);
        decodeOPC => decode, 	-- : buffer std_logic;
		wr => wr, 				-- : out std_logic;
		UDS => uds_in, 			-- : out std_logic;
		LDS => lds_in 			-- : out std_logic;
        );
	
--	clkena <= '1' WHEN clkena_in='1' AND ((clkena_e OR decode)='1')
--				  ELSE '0';

	
	PROCESS (clk)
	BEGIN
		IF rising_edge(clk) THEN
--			IF clkena_in='1' AND ((clkena_e OR decode)='1') THEN
			IF clkena_in='1' AND (clkena_e='1' OR state="01") THEN
				clkena <= '1';
			ELSE 
				clkena <= '0';
			END IF;	
		END IF;	
	END PROCESS;
				
PROCESS (clk, reset, state, as_s, as_e, rw_s, rw_e, uds_s, uds_e, lds_s, lds_e)
	BEGIN
		IF state="01" THEN 
			as <= '1';
			rw <= '1';
			uds <= '1';
			lds <= '1';
		ELSE
			as <= as_s AND as_e;
			rw <= rw_s AND rw_e;
			uds <= uds_s AND uds_e;
			lds <= lds_s AND lds_e;
		END IF;
		IF reset='0' THEN
			S_state <= "11";
			as_s <= '1';
			rw_s <= '1';
			uds_s <= '1';
			lds_s <= '1';
		ELSIF rising_edge(clk) THEN
        	IF clkena_in='1' THEN
				as_s <= '1';
				rw_s <= '1';
				uds_s <= '1';
				lds_s <= '1';
								 IF state/="01" OR decode='1' THEN
				CASE S_state IS
					WHEN "00" => as_s <= '0';
								 rw_s <= wr;
								 IF wr='1' THEN
									 uds_s <= uds_in;
									 lds_s <= lds_in;
								 END IF;
									S_state <= "01";
					WHEN "01" => as_s <= '0';
								 rw_s <= wr;
								 uds_s <= uds_in;
								 lds_s <= lds_in;
								 S_state <= "10";
					WHEN "10" =>
								 rw_s <= wr;
								 IF waitm='0' THEN
									S_state <= "11";
								 END IF;
					WHEN "11" =>
								 S_state <= "00";
				END CASE;
								 END IF;
			END IF;
		END IF;	
		IF reset='0' THEN
			as_e <= '1';
			rw_e <= '1';
			uds_e <= '1';
			lds_e <= '1';
			clkena_e <= '0';
		ELSIF falling_edge(clk) THEN
        	IF clkena_in='1' THEN
				as_e <= '1';
				rw_e <= '1';
				uds_e <= '1';
				lds_e <= '1';
				clkena_e <= '0';
				CASE S_state IS
					WHEN "00" =>
					WHEN "01" =>
					WHEN "10" => as_e <= '0';
								 uds_e <= uds_in;
								 lds_e <= lds_in;
								 IF state="01" THEN
									 clkena_e <= '1';
									 waitm <= '0';
								 ELSE
									 clkena_e <= NOT dtack;
									 waitm <= dtack;
								 END IF;
					WHEN "11" =>
				END CASE;
			END IF;
		END IF;	
	END PROCESS;
END;	
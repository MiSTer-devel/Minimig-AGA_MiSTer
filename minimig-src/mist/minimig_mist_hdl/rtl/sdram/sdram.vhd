------------------------------------------------------------------------------
------------------------------------------------------------------------------
--                                                                          --
-- Copyright (c) 2009 Tobias Gubener                                        -- 
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
 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sdram is
port
	(
	sdata		: inout std_logic_vector(15 downto 0);
	sdaddr		: out std_logic_vector(11 downto 0);
	sd_we		: out std_logic;
	sd_ras		: out std_logic;
	sd_cas		: out std_logic;
	sd_cs		: out std_logic_vector(3 downto 0);
	dqm			: out std_logic_vector(1 downto 0);
	ba			: buffer std_logic_vector(1 downto 0);

	sysclk		: in std_logic;
	reset		: in std_logic;
	
	zdatawr		: in std_logic_vector(15 downto 0);
	zAddr		: in std_logic_vector(23 downto 0);
	zstate		: in std_logic_vector(2 downto 0);
	datawr		: in std_logic_vector(15 downto 0);
	rAddr		: in std_logic_vector(23 downto 0);
	rwr			: in std_logic;
	dwrL		: in std_logic;
	dwrU		: in std_logic;
	ZwrL		: in std_logic;
	ZwrU		: in std_logic;
	dma			: in std_logic;
	cpu_dma		: in std_logic;
	c_28min		: in std_logic;
	
	dataout		: out std_logic_vector(15 downto 0);
	zdataout	: out std_logic_vector(15 downto 0);
	c_14m		: out std_logic;
	zena_o		: buffer std_logic;
	c_28m		: out std_logic;
	c_7m		: out std_logic;
	reset_out	: out std_logic;
	pulse		: out std_logic;
	enaRDreg	: out std_logic;
	enaWRreg	: out std_logic;
	ena7RDreg	: out std_logic;
	ena7WRreg	: out std_logic
	);
end;

architecture rtl of sdram is


signal initstate	:std_logic_vector(3 downto 0);
signal cas_sd_cs	:std_logic_vector(3 downto 0);
signal cas_sd_ras	:std_logic;
signal cas_sd_cas	:std_logic;
signal cas_sd_we 	:std_logic;
signal cas_dqm		:std_logic_vector(1 downto 0);
signal init_done	:std_logic;
signal datain		:std_logic_vector(15 downto 0);
signal casaddr		:std_logic_vector(23 downto 0);
signal sdwrite 		:std_logic;
signal sdata_reg	:std_logic_vector(15 downto 0);

signal Z_cycle		:std_logic;
signal zena			:std_logic;
signal zcache		:std_logic_vector(63 downto 0);
signal zcache_addr	:std_logic_vector(23 downto 0);
signal zcache_fill	:std_logic;
signal zcachehit	:std_logic;
signal zvalid		:std_logic_vector(3 downto 0);
signal zequal		:std_logic;
signal zstated		:std_logic_vector(1 downto 0);
signal zdataoutd	:std_logic_vector(15 downto 0);

signal R_cycle		:std_logic;
signal rvalid		:std_logic;
signal rdataout		:std_logic_vector(15 downto 0);


type sdram_states is (ph0,ph1,ph2,ph3,ph4,ph5,ph6,ph7,ph8,ph9,ph10,ph11,ph12,ph13,ph14,ph15);
signal sdram_state		: sdram_states;
type pass_states is (nop,ras,cas);
signal pass		: pass_states;

begin
	
-------------------------------------------------------------------------
-- SPIHOST cache
-------------------------------------------------------------------------
	zena_o <= '1' when (zena='1' and zAddr=casaddr and cas_sd_cas='0') or zstate(1 downto 0)="01" OR zcachehit='1' else '0'; 
	
	process (sysclk, zAddr, zcache_addr, zcache, zequal, zvalid, zdataoutd) 
	begin
--		if zaddr(23 downto 3)=zcache_addr(23 downto 3) THEN
--			zequal <='1';
--		else	
			zequal <='0';
--		end if;	
		zcachehit <= '0';
		if zequal='1' and zvalid(0)='1' THEN
			case (zaddr(2 downto 1)-zcache_addr(2 downto 1)) is
				when "00"=>
					zcachehit <= zvalid(0);
					zdataout <= zcache(63 downto 48);
				when "01"=>
					zcachehit <= zvalid(1);
					zdataout <= zcache(47 downto 32);
				when "10"=>
					zcachehit <= zvalid(2);
					zdataout <= zcache(31 downto 16);
				when "11"=>
					zcachehit <= zvalid(3);
					zdataout <= zcache(15 downto 0);
				when others=> null;
			end case;	
		else	
			zdataout <= zdataoutd;
		end if;	
	end process;		
		
	
--Datenübernahme
	process (sysclk, reset) begin
		if reset = '0' THEN
			zcache_fill <= '0';
			zena <= '0';
			zvalid <= "0000";
		elsif (sysclk'event and sysclk='1') THEN
				if sdram_state=ph10 AND Z_cycle='1' THEN 
					zdataoutd <= sdata_reg;
				end if;
				zstated <= zstate(1 downto 0);
				if zequal='1' and zstate="11" THEN
					zvalid <= "0000";
				end if;
					case sdram_state is	
						when ph7 =>	
										zena <= Z_cycle;
						when ph8 =>	
										if cas_sd_we='1' AND zstated(1)='0' AND Z_cycle='1' THEN	--only instruction cache
--										if cas_sd_we='1' AND Z_cycle='1' THEN
											zcache_addr <= casaddr;
											zcache_fill <= '1';
											zvalid <= "0000";
										end if;
						when ph10 =>	
										if zcache_fill='1' THEN
											zcache(63 downto 48) <= sdata_reg;
										end if;
						when ph11 =>	
										if zcache_fill='1' THEN
											zcache(47 downto 32) <= sdata_reg;
										end if;
						when ph12 =>	
										if zcache_fill='1' THEN
											zcache(31 downto 16) <= sdata_reg;
										end if;
						when ph13 =>	
										if zcache_fill='1' THEN
											zcache(15 downto 0) <= sdata_reg;
										end if;
										zcache_fill <= '0';
						when ph15 =>	
										zena <= '0';
										zvalid <= "1111";
						when others =>	null;
					end case;	
			end if;
	end process;		
	
-------------------------------------------------------------------------
-- Main cache
-------------------------------------------------------------------------
	process (sysclk, rvalid, rdataout, sdata_reg)
    begin
		dataout <= rdataout;
		if (sysclk'event and sysclk='1') THEN
			if sdram_state=ph10 AND R_cycle='1' THEN 
				rdataout <= sdata_reg;
			end if;
		end if;
	end process;		
	
	
-------------------------------------------------------------------------
-- SDRAM Basic
-------------------------------------------------------------------------
	reset_out <= init_done;

	process (sysclk, reset, sdwrite, datain, c_28min) begin
		IF sdwrite='1' THEN
			sdata <= datain;
		ELSE
			sdata <= "ZZZZZZZZZZZZZZZZ";
		END IF;
		
--   sample SDRAM data
		if (sysclk'event and sysclk='1') THEN
			sdata_reg <= sdata;
		END IF;	
		
		if reset = '0' then
			initstate <= (others => '0');
			init_done <= '0';
			sdram_state <= ph0;
			sdwrite <= '0';
			enaRDreg <= '0';
			enaWRreg <= '0';
			ena7RDreg <= '0';
			ena7WRreg <= '0';
		ELSIF (sysclk'event and sysclk='1') THEN
			sdwrite <= '0';
			enaRDreg <= '0';
			enaWRreg <= '0';
			ena7RDreg <= '0';
			ena7WRreg <= '0';
			case sdram_state is	--LATENCY=3
				when ph0 =>	
--							IF c_28min='1' THEN
								sdram_state <= ph1;
--							ELSE	
--								sdram_state <= ph0;
--							END IF;	
				when ph1 =>	
							IF c_28min='1' THEN
								sdram_state <= ph2;
								c_28m <= '0';
								pulse <= '0';
							ELSE	
								sdram_state <= ph1;
							END IF;	
				when ph2 =>	--sdram_state <= ph3;
							IF c_28min='0' THEN
								sdram_state <= ph3;
								enaRDreg <= '1';
							ELSE	
								sdram_state <= ph2;
							END IF;	
				when ph3 =>	sdram_state <= ph4;
--							sdwrite <= '1';
							c_14m <= '0';
							c_28m <= '1';
				when ph4 =>	sdram_state <= ph5;
							sdwrite <= '1';
				when ph5 => sdram_state <= ph6;
							sdwrite <= '1';
							c_28m <= '0';
							pulse <= '1';
				when ph6 =>	sdram_state <= ph7;
							sdwrite <= '1';
							enaWRreg <= '1';
							ena7RDreg <= '1';
				when ph7 =>	sdram_state <= ph8;
							c_7m <= '0';
							c_14m <= '1';
							c_28m <= '1';
				when ph8 =>	sdram_state <= ph9;
				when ph9 =>	sdram_state <= ph10;
							c_28m <= '0';
							pulse <= '0';
				when ph10 => sdram_state <= ph11;
							enaRDreg <= '1';
				when ph11 => sdram_state <= ph12;
							c_14m <= '0';
							c_28m <= '1';
				when ph12 => sdram_state <= ph13;
				when ph13 => sdram_state <= ph14;
							c_28m <= '0';
							pulse <= '1';
				when ph14 => sdram_state <= ph15;
							enaWRreg <= '1';
							ena7WRreg <= '1';
				when ph15 => sdram_state <= ph0;
							c_7m <= '1';
							c_14m <= '1';
							c_28m <= '1';
							if initstate /= "1111" THEN
								initstate <= initstate+1;
							else
								init_done <='1';	
							end if;
				when others => sdram_state <= ph0;
			end case;	
		END IF;	
	end process;		


	
	process (sysclk, initstate, pass, zaddr, datain, init_done, casaddr, dwrU, dwrL, Z_cycle) begin



		if (sysclk'event and sysclk='1') THEN
--		ba <= Addr(22 downto 21);
			sd_cs <="1111";
			sd_ras <= '1';
			sd_cas <= '1';
			sd_we <= '1';
			sdaddr <= "XXXXXXXXXXXX";
			ba <= "00";
			dqm <= "00";
			if init_done='0' then
				if sdram_state =ph2 then
					case initstate is
						when "0010" => --PRECHARGE
							sdaddr(10) <= '1'; 	--all banks
							sd_cs <="0000";
							sd_ras <= '0';
							sd_cas <= '1';
							sd_we <= '0';
						when "0011"|"0100"|"0101"|"0110"|"0111"|"1000"|"1001"|"1010"|"1011"|"1100" => --AUTOREFRESH
							sd_cs <="0000"; 
							sd_ras <= '0';
							sd_cas <= '0';
							sd_we <= '1';
						when "1101" => --LOAD MODE REGISTER
							sd_cs <="0000";
							sd_ras <= '0';
							sd_cas <= '0';
							sd_we <= '0';
--							ba <= "00";
	--						sdaddr <= "001000100010"; --BURST=4 LATENCY=2
							sdaddr <= "001000110010"; --BURST=4 LATENCY=3
--							sdaddr <= "001000110000"; --noBURST LATENCY=3
						when others =>	null;	--NOP
					end case;
				END IF;
			else		
	
-- Time slot control					
				if sdram_state=ph2 THEN
					R_cycle <= '0';
					Z_cycle <= '0';
					cas_sd_cs <= "1110"; 
					cas_sd_ras <= '1';
					cas_sd_cas <= '1';
					cas_sd_we <= '1';
					IF dma='0' OR cpu_dma='0' THEN
						R_cycle <= '1';
						sdaddr <= rAddr(20 downto 9);
						ba <= rAddr(22 downto 21);
						cas_dqm <= dwrU& dwrL;
						sd_cs <= "1110"; --ACTIVE
						sd_ras <= '0';
						casaddr <= rAddr;
						datain <= datawr;
						cas_sd_cas <= '0';
						cas_sd_we <= rwr;
					ELSIF zstate(2)='1' OR zena_o='1' THEN	--refresh cycle
						sd_cs <="0000"; --AUTOREFRESH
						sd_ras <= '0';
						sd_cas <= '0';
					ELSE	
						Z_cycle <= '1';
						sdaddr <= zAddr(20 downto 9);
						ba <= zAddr(22 downto 21);
						cas_dqm <= ZwrU& ZwrL;
						sd_cs <= "1110"; --ACTIVE
						sd_ras <= '0';
						casaddr <= zAddr;
						datain <= zdatawr;
						cas_sd_cas <= '0';
						IF zstate="011" THEN
							cas_sd_we <= '0';
--							dqm <= ZwrU& ZwrL;
						END IF;
					END IF;
				END IF;
				if sdram_state=ph5 then
					sdaddr <=  '0' & '1' & '0' & casaddr(23)&casaddr(8 downto 1);--auto precharge
					ba <= casaddr(22 downto 21);
					sd_cs <= cas_sd_cs; 
					IF cas_sd_we='0' THEN
						dqm <= cas_dqm;
					END IF;
					sd_ras <= cas_sd_ras;
					sd_cas <= cas_sd_cas;
					sd_we  <= cas_sd_we;
				END IF;
			END IF;	
		END IF;	
	END process;		
END;

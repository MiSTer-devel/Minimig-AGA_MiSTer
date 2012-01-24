library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity Audio_shifter is
port
	(
	clk			: in std_logic;	--32MHz
	nreset		: in std_logic;
	rechts		: in std_logic_vector(15 downto 0);
	links		: in std_logic_vector(15 downto 0);
	exchan		: in std_logic;
	aud_bclk 	: out std_logic;
	aud_daclrck : out std_logic;
	aud_dacdat	: out std_logic;
	aud_xck		: out std_logic
	);
end;

architecture rtl of Audio_shifter is

signal shiftcnt	: std_logic_vector(8 downto 0);
signal shift	: std_logic_vector(15 downto 0);
signal test		: std_logic_vector(14 downto 0);

begin
	process (nreset, clk, shiftcnt, shift) begin
		aud_bclk <= not shiftcnt(2);
		aud_daclrck <= shiftcnt(7);				
		aud_dacdat <= shift(15);
 	 aud_xck <= shiftcnt(0);
  end process;

	process (nreset, clk, shiftcnt, shift) begin

		if nreset='0' then 
			shiftcnt <= (OTHERS => '0');
		elsif rising_edge(clk) then
			test <= test-1;
			shiftcnt <= shiftcnt-1;
			if shiftcnt(6 downto 3)<=15 and shiftcnt(2 downto 0)="000" then
				IF shiftcnt(6 downto 3)= 0 then	
			    	IF (exchan XOR shiftcnt(7))='1' THEN	--aud_daclrck					
						shift <= links;		--signed data		
					ELSE
						shift <= rechts;	--signed data		
				   	END IF;
				ELSE
					shift(15 downto 1) <= shift(14 downto 0);
				END IF;
			end if;
		end if;
	end process;
end;


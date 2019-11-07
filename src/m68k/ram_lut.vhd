library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;
  use work.M68K_Pack.all;

entity RAM_LUT is
  generic (
    g_width             : in integer := 8;
    g_depth             : in integer := 4; -- note BITS here
    g_has_a_write       : in boolean := true;
    g_has_a_read        : in boolean := false;
    g_use_init          : in boolean := true;
    g_hex_init_filename : in string := "none";
    g_bin_init_filename : in string := "none"
    );
  port (
    i_a_addr       : in  word(g_depth-1 downto 0) := (others => '0');
    i_a_data       : in  word(g_Width-1 downto 0) := (others => '0');
    o_a_data       : out word(g_Width-1 downto 0); -- optional op
    i_a_write      : in  bit1 := '0'; -- write enable
    i_a_clk        : in  bit1 := '0';

    i_b_addr       : in  word(g_depth-1 downto 0);
    o_b_data       : out word(g_Width-1 downto 0)
    );
end;

architecture RTL of RAM_LUT is

  type regfile_t is ARRAY(0 TO (2**g_depth) - 1) OF std_logic_vector(g_width-1 downto 0);
  signal regfile                : regfile_t := (OTHERS => (OTHERS => '0'));
  attribute ramstyle            : string;
  attribute ramstyle of regfile : signal is "logic";
begin

	process (i_a_clk)
	begin
		if rising_edge(i_a_clk) then
			if i_a_write = '1' then
				regfile(conv_integer(i_a_addr)) <= i_a_data;
			end if;
		end if;
	end process;

	o_a_data <= regfile(conv_integer(i_a_addr));
	o_b_data <= regfile(conv_integer(i_b_addr));
end;

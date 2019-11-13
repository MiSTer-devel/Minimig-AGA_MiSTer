--
-- All rights reserved
-- Mike Johnson
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: www.fpgaarcade.com
--
-- Email support@fpgaarcade.com

-- derived from TG68K
-- Copyright (c) 2009-2013 Tobias Gubener --
-- Patches by MikeJ, Till Harbaum, Rok Krajnk, ...                          --
-- Subdesign fAMpIGA by TobiFlex --


library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

  use work.M68K_Pack.all;

entity M68K_Core is
  generic (
    g_xil_regfile       : in   boolean := true -- set for xilinx prims on regfile
    );
  port (
    i_clk               : in   bit1;
    i_ena               : in   bit1;
    i_rst               : in   bit1; -- note active high
    --
    i_cpu_type          : in  word( 1 downto 0) := "00"; -- 00->68000 01->68010 11->68020
    --
    i_data              : in  word(15 downto 0);
    o_addr              : out word(31 downto 0);
    --
    o_data              : out word(15 downto 0);
    --
    i_ipl_l             : in  word( 2 downto 0) := "111";
    i_ipl_autovector    : in  bit1 := '1';

    i_berr              : in  bit1 := '0';     -- only 68000 Stackpointer dummy, active high
    o_clr_berr          : out bit1;
    --
    o_wr_l              : out bit1; -- read high, write low
    o_uds_l             : out bit1;
    o_lds_l             : out bit1;

    o_busstate          : out word(1 downto 0); -- 00-> fetch code 10->read data 11->write data 01->no memaccess
    o_reset_l           : out bit1;
    o_fc                : out word(2 downto 0);
    --  for debug
    o_skip_fetch        : out bit1;
    o_regin             : out word(31 downto 0);
    o_cacr              : out word( 3 downto 0);
    o_vbr               : out word(31 downto 0)
    );
end;

architecture logic of M68K_Core is


  attribute keep : string;
  attribute equivalent_register_removal : string;

  signal cpu_type               : tCputype;

  signal syncReset              : word(3 downto 0);
  signal Reset                  : bit1;
  signal clkena_lw              : bit1;
  signal TG68_PC                : word(31 downto 0);
  signal tmp_TG68_PC            : word(31 downto 0);
  signal TG68_PC_add            : word(31 downto 0);
  signal PC_dataa               : word(31 downto 0);
  signal PC_datab               : word(31 downto 0);
  signal memaddr                : word(31 downto 0);
  signal state                  : word(1 downto 0);
  signal set_datatype           : word(1 downto 0);
  signal exe_datatype           : word(1 downto 0);
  signal opcode                 : word(15 downto 0);
  signal exe_opcode             : word(15 downto 0);
  signal exe_pc                 : word(31 downto 0);
  signal last_opc_pc            : word(31 downto 0);
  signal sndOPC                 : word(15 downto 0);

  signal last_opc_read          : word(15 downto 0);
  signal reg_QA                 : word(31 downto 0);
  signal reg_QB                 : word(31 downto 0);
  signal Wwrena                 : bit1;
  signal Lwrena                 : bit1;
  signal Bwrena                 : bit1;
  signal rf_dest_addr           : word(3 downto 0);

  signal rf_source_addr         : word(3 downto 0);
  signal rf_source_addrd        : word(3 downto 0);

  type regfile_t is array(0 TO 15) OF word(31 downto 0);
  signal regfile                : regfile_t := (others => (others => '0'));
  signal RDindex_A              : word( 3 downto 0);
  signal RDindex_B              : word( 3 downto 0);
  signal regfile_we : bit1;

  signal WR_AReg                : bit1;
  signal addr                   : word(31 downto 0);
  signal memaddr_reg            : word(31 downto 0);
  signal memaddr_delta          : word(31 downto 0);
  signal memaddr_delta_sel      : integer range 0 to 15; -- debug only
  signal use_base               : bit;
  signal ea_data                : word(31 downto 0);
  signal OP1out                 : word(31 downto 0);
  signal OP2out                 : word(31 downto 0);
  signal OP1outbrief            : word(15 downto 0);
  signal OP1in                  : word(31 downto 0);
  signal ALUout                 : word(31 downto 0);
  signal data_write_tmp         : word(31 downto 0);
  signal data_write_sel         : integer range 0 to 15; -- debug only
  signal data_write_mux         : word(47 downto 0);
  signal data_write             : word(15 downto 0);
  signal nextpass               : bit1;
  signal addsub_q               : word(31 downto 0);
  signal briefdata              : word(31 downto 0);

  signal c_out                  : word(2 downto 0);
  signal mem_address            : word(31 downto 0);
  signal memaddr_a              : word(31 downto 0);
  signal TG68_PC_word           : bit1;
  signal brief                  : word(15 downto 0);
  signal store_in_tmp           : bit1;
  signal exec_write_back        : bit1;
  signal writePCbig             : bit1;
  signal setopcode              : bit1;
  signal decodeOPC              : bit1;
  signal execOPC                : bit1;
  signal setexecOPC             : bit1;
  signal endOPC                 : bit1;
  signal setendOPC              : bit1;
  signal Flags                  : word(7 downto 0); -- ...XNZVC
  signal FlagsSR                : word(7 downto 0) := (others => '0'); -- T.S..III  (T1,T0,S,M,.III) for 68020
  signal SRin                   : word(7 downto 0);
  signal exec_DIRECT            : bit1;
  signal exec_tas               : bit1;
  signal exe_condition          : bit1;
  signal rot_bits               : word(1 downto 0);
  signal rot_cnt                : word(5 downto 0);
  signal movem_actiond          : bit1;
  signal movem_regaddr          : word(3 downto 0);
  signal movem_mux              : word(3 downto 0);
  signal movem_run              : bit1;
  signal use_direct_data        : bit1;
  signal direct_data            : bit1;

  signal set_V_Flag             : bit1;
  signal set_Cmp2_Flags         : word(3 downto 0);
  signal trap_berr              : bit1;
  signal trap_7word             : bit1;
  signal trap_interrupt         : bit1;
  signal trapd                  : bit1;
  signal trap_SR                : word(7 downto 0);
  signal make_trace             : bit1;
  signal make_berr              : bit1;
  signal trap_trace             : bit1;

  signal stop                   : bit1;
  signal trap_vector            : word(11 downto 0);
  signal trap_vector_stackfmt   : word( 3 downto 0);
  signal trap_vector_vbr        : word(31 downto 0);
  signal USP                    : word(31 downto 0) := (others => '0');

  signal IPL_nr                 : word(2 downto 0);
  signal rIPL_nr                : word(2 downto 0);
  signal IPL_vec                : word(7 downto 0);
  signal interrupt              : bit1;
  signal setinterrupt           : bit1;
  signal SVmode                 : bit1;
  signal preSVmode              : bit1;
  signal Suppress_Base          : bit1;
  signal Z_error                : bit1;

  signal data_read              : word(31 downto 0);
  signal bf_ext_in              : word(7 downto 0);
  signal bf_ext_out             : word(7 downto 0);
  signal byte                   : bit1;
  signal long_start             : bit1;
  signal long_start_alu         : bit1;
  signal long_done              : bit1;
  signal memmask                : word(5 downto 0);
  signal set_memmask            : word(5 downto 0);
  signal memread                : word(3 downto 0);
  signal wbmemmask              : word(5 downto 0);
  signal memmaskmux             : word(5 downto 0);
  signal oddout                 : bit1;
  signal set_oddout             : bit1;
  signal PCbase                 : bit1;

  signal last_data_read         : word(31 downto 0);
  signal last_data_in           : word(31 downto 0);

  signal bf_offset              : word(31 downto 0);
  signal bf_offset_l            : word(4 downto 0);
  signal bf_loffset             : word(4 downto 0);
  signal bf_width               : word(4 downto 0);
  signal bf_bhits               : word(5 downto 0);
  signal alu_bf_width           : word(4 downto 0);
  signal alu_bf_offset          : word(31 downto 0);
  signal alu_bf_loffset         : word(4 downto 0);

  signal movec_data             : word(31 downto 0);
  signal VBR                    : word(31 downto 0);
  signal CACR                   : word(3 downto 0);
  signal exec                   : r_Opc;

  signal micro_state            : micro_states;
  signal regin                  : word(31 downto 0);
  signal fc                     : word( 2 downto 0);

  -- from decode
  signal next_micro_state       : micro_states;
  signal set                    : r_Opc;
  signal set_exec               : r_Opc;
  signal setnextpass            : bit1;
  signal setstate               : word(1 downto 0);
  signal getbrief               : bit1;
  signal setstackaddr           : bit1;
  signal set_Suppress_Base      : bit1;
  signal set_PCbase             : bit1;
  signal set_direct_data        : bit1;
  signal datatype               : word(1 downto 0);
  signal set_rot_cnt            : word(5 downto 0);
  signal set_rot_bits           : word(1 downto 0);
  signal set_stop               : bit1;

  signal movem_presub           : bit1;
  signal regdirectsource        : bit1;
  signal dest_areg              : bit1;
  signal source_areg            : bit1;
  signal data_is_source         : bit1;
  signal write_back             : bit1;
  signal writePC                : bit1;
  signal ea_only                : bit1;
  signal source_lowbits         : bit1;
  signal source_2ndHbits        : bit1;
  signal source_2ndMbits        : bit1;
  signal source_2ndLbits        : bit1;
  signal source_briefMbits      : bit1;

  signal dest_2ndHbits          : bit1;
  signal dest_2ndLbits          : bit1;
  signal dest_hbits             : bit1;
  signal set_exec_tas           : bit1;
  signal trapmake               : bit1;
  signal trap_illegal           : bit1;
  signal trap_addr_error        : bit1;
  signal trap_priv              : bit1;
  signal trap_1010              : bit1;
  signal trap_1111              : bit1;
  signal trap_trap              : bit1;
  signal set_Z_error            : bit1;
  signal writeSR                : bit1;
  signal set_vectoraddr         : bit1;
  signal set_writePCbig         : bit1;
  signal TG68_PC_brw            : bit1;
  signal setdispbyte            : bit1;
  signal setdisp                : bit1;
  signal Regwrena_now           : bit1;

begin

  p_type : process
  begin
    wait until rising_edge(i_clk);
    cpu_type.is_68000 <= '0';
    cpu_type.is_68010 <= '0';
    cpu_type.is_68020 <= '0';
    cpu_type.ge_68010 <= '0';
    cpu_type.ge_68020 <= '0';

    if (i_cpu_type = "00") then
      cpu_type.is_68000 <= '1';
    elsif (i_cpu_type = "01") then
      cpu_type.is_68010 <= '1';
      --
      cpu_type.ge_68010 <= '1';
    else
      cpu_type.is_68020 <= '1';
      --
      cpu_type.ge_68010 <= '1';
      cpu_type.ge_68020 <= '1';
    end if;
  end process;

  u_alu : entity work.M68K_ALU
  port map(
    clk                  => i_clk,            --: in std_logic;
    Reset                => Reset,            --: in std_logic;
    clkena_lw            => clkena_lw,        --: in std_logic:='1';
    execOPC              => execOPC,          --: in bit;
    exe_condition        => exe_condition,    --: in std_logic;
    exec_tas             => exec_tas,         --: in std_logic;
    long_start           => long_start_alu,   --: in bit;
    movem_presub         => movem_presub,     --: in bit;
    set_stop             => set_stop,         --: in bit;
    Z_error              => Z_error,          --: in bit;
    rot_bits             => rot_bits,         --: in word(1 downto 0);
    exec                 => exec,             --: in bit_vector(lastOpcBit downto 0);
    OP1out               => OP1out,           --: in word(31 downto 0);
    OP2out               => OP2out,           --: in word(31 downto 0);
    reg_QA               => reg_QA,           --: in word(31 downto 0);
    reg_QB               => reg_QB,           --: in word(31 downto 0);
    opcode               => opcode,           --: in word(15 downto 0);
    datatype             => datatype,         --: in word(1 downto 0);
    exe_opcode           => exe_opcode,       --: in word(15 downto 0);
    exe_datatype         => exe_datatype,     --: in word(1 downto 0);
    sndOPC               => sndOPC,           --: in word(15 downto 0);
    last_data_read       => last_data_read(15 downto 0), --: in word(31 downto 0);
    data_read            => data_read(15      downto 0), --: in word(31 downto 0);
    FlagsSR              => FlagsSR,          --: in word(7 downto 0);
    micro_state          => micro_state,      --: in micro_states;
    bf_ext_in            => bf_ext_in,
    bf_ext_out           => bf_ext_out,
    bf_width             => alu_bf_width,
    bf_offset            => alu_bf_offset,
    bf_loffset           => alu_bf_loffset,
    set_V_Flag_out       => set_V_Flag,       --: buffer bit;
    set_Cmp2_Flags_out   => set_Cmp2_Flags,
    Flags_out            => Flags,
    alu_c_out            => c_out,
    addsub_q_out         => addsub_q,
    ALUout               => ALUout
  );

  long_start_alu <= (not memmaskmux(3));

  -----------------------------------------------------------------------------
  -- Bus control
  -----------------------------------------------------------------------------
  o_wr_l     <= '0' when (state = "11") else '1';
  o_busstate <= state;
  o_reset_l   <= '0' when (exec.opcRESET = '1') else '1';

  -- does shift for byte access. note active low me
  -- should produce address error on 68000
  memmaskmux <= memmask when (addr(0) = '1') else memmask(4 downto 0) & '1';
  o_uds_l    <= memmaskmux(5);
  o_lds_l    <= memmaskmux(4);
  o_clr_berr <= '1' when (setopcode = '1' and trap_berr = '1') else '0';

  clkena_lw  <= '1' when (i_ena = '1' and memmaskmux(3) = '1') else '0'; -- step

  process (i_clk, i_rst)
  begin
    if i_rst = '1' then
      syncReset <= "0000";
      Reset <= '1';
    elsif rising_edge(i_clk) then
      if i_ena = '1' then
        syncReset <= syncReset(2 downto 0) & '1';
        Reset <= not syncReset(3);
      end if;
    end if;
  end process;

  process (last_data_in, i_data, memmaskmux, memread, data_read)
  begin
    if memmaskmux(4) = '0' then
      data_read <= last_data_in(15 downto 0) & i_data;
    else
      data_read <= last_data_in(23 downto 0) & i_data(15 downto 8);
    end if;

    if memread(0) = '1' or (memread(1 downto 0) = "10" and memmaskmux(4) = '1') then
      data_read(31 downto 16) <= (others => data_read(15));
    end if;
  end process;

  process (memmask, memread)
  begin
    long_start <= not memmask(1);
    long_done  <= not memread(1);
  end process;

  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if clkena_lw = '1' and state = "10" then
        if memmaskmux(4) = '0' then
          bf_ext_in <= last_data_in(23 downto 16);
        else
          bf_ext_in <= last_data_in(31 downto 24);
        end if;
      end if;
    end if;
  end process;

  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if Reset = '1' then
        last_data_read <= (others => '0');
      elsif i_ena = '1' then
        if state = "00" or exec.update_ld = '1' then
          last_data_read <= data_read;
          if state(1) = '0' and memmask(1) = '0' then
            last_data_read(31 downto 16) <= last_opc_read;
          elsif state(1) = '0' or memread(1) = '1' then
            last_data_read(31 downto 16) <= (others => i_data(15));
          end if;
        end if;
        last_data_in <= last_data_in(15 downto 0) & i_data(15 downto 0);
      end if;
    end if;
  end process;

  process (exec, reg_QB, data_write_tmp, oddout, bf_ext_out, addr )
    variable data_write_muxin : word(31 downto 0);
  begin
    if exec.write_reg = '1' then
      data_write_muxin := reg_QB; -- 32 bits
    else
      data_write_muxin := data_write_tmp;
    end if;

    data_write_mux <= (others => '0'); -- 47..0
    if oddout = addr(0) then -- byte shift
      data_write_mux(39 downto 0) <= bf_ext_out & data_write_muxin;
    else
      data_write_mux(47 downto 8) <= bf_ext_out & data_write_muxin;
    end if;
  end process;

  process(exec, memmaskmux, data_write_mux, data_write_tmp)
  begin
    if memmaskmux(1) = '0' then
      data_write <= data_write_mux(47 downto 32);
    elsif memmaskmux(3) = '0' then
      data_write <= data_write_mux(31 downto 16);
    else
      data_write <= data_write_mux(15 downto 0);
    end if;

    if exec.mem_byte = '1' then --movep
      data_write(7 downto 0) <= data_write_tmp(15 downto 8);
    end if;
  end process;

  -- drive output data, output bytes on both half-words during byte write
  o_data(15 downto 8) <= data_write(15 downto 8) WHEN memmaskmux(5)='0' ELSE data_write( 7 downto 0);
  o_data( 7 downto 0) <= data_write( 7 downto 0) WHEN memmaskmux(4)='0' ELSE data_write(15 downto 8);
  --o_data <= data_write;
  -----------------------------------------------------------------------------
  -- Registerfile
  -----------------------------------------------------------------------------
  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if clkena_lw = '1' then
        rf_source_addrd <= rf_source_addr;
        WR_AReg <= rf_dest_addr(3);
        RDindex_A <= rf_dest_addr(3 downto 0);
        RDindex_B <= rf_source_addr(3 downto 0);

        -- this won't be used if g_xil_regfile is set. Handy for simulation though
        if Wwrena = '1' then
          regfile  (conv_integer(RDindex_A)) <= regin;
        end if;

        if exec.to_USP = '1' then
          USP <= reg_QA;
        end if;
      end if;
    end if;
  end process;

  regfile_we <= clkena_lw and Wwrena;

  gen_regfile : if not g_xil_regfile generate
  begin
    process (regfile, RDindex_A, RDindex_B)
    begin
      reg_QA <= regfile(conv_integer(RDindex_A));
      reg_QB <= regfile(conv_integer(RDindex_B));
    end process;
  end generate;

  u_regfile : entity work.RAM_LUT
  generic map (
    g_width       => 32,
    g_depth       => 4,
    g_has_a_read  => true
    )
  port map (
    i_a_addr      => RDindex_A,
    i_a_data      => regin,
    o_a_data      => reg_QA,
    i_a_write     => regfile_we,
    i_a_clk       => i_clk,

    i_b_addr      => RDindex_B,
    o_b_data      => reg_QB
    );

  process (exec, Regwrena_now, exe_datatype, WR_AReg, movem_actiond)
  begin
    Bwrena <= '0';
    Wwrena <= '0';
    Lwrena <= '0';
    if exec.presub = '1' or exec.postadd = '1' or exec.changeMode = '1' then -- -(An)+
      Wwrena <= '1';
      Lwrena <= '1';
    elsif Regwrena_now = '1' then --dbcc
      Wwrena <= '1';
    elsif exec.Regwrena = '1' then --read (mem)
      Wwrena <= '1';
      case exe_datatype is
        when "00" => -- byte
          Bwrena <= '1';
        when "01" => -- word
          if WR_AReg = '1' or movem_actiond = '1' then
            Lwrena <= '1';
          end if;
        when others => -- long
          Lwrena <= '1';
      end case;
    end if;
  end process;

  process (Bwrena, Lwrena, exe_datatype, WR_AReg, movem_actiond, exec, ALUout, memaddr, memaddr_a, ea_only, USP, movec_data, reg_QA)
  begin
    regin <= ALUout;
    if exec.save_memaddr = '1' then -- only used for movem
      regin <= memaddr;
    elsif exec.get_ea_now = '1' and ea_only = '1' then
      regin <= memaddr_a;
    elsif exec.from_USP = '1' then
      regin <= USP;
    elsif exec.movec_rd = '1' then
      regin <= movec_data;
    end if;

    if (Bwrena = '1') then
      regin(15 downto 8) <= reg_QA(15 downto 8);
    end if;

    if (Lwrena = '0') then
      regin(31 downto 16) <= reg_QA(31 downto 16);
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- set dest regaddr
  -----------------------------------------------------------------------------
  process (opcode, rf_source_addrd, brief, setstackaddr, dest_hbits, dest_areg, data_is_source, sndOPC, exec, set, dest_2ndHbits, dest_2ndLbits)
  begin
    if exec.movem_action = '1' then
      rf_dest_addr <= rf_source_addrd;
    elsif set.briefext = '1' then
      rf_dest_addr <= brief(15 downto 12);
    elsif set.brieflow = '1' then
      rf_dest_addr <= brief( 3 downto  0);
    elsif set.get_bfoffset = '1' then

      --rf_dest_addr <= sndOPC(9 downto 6);
      -- untested from tg68k
      if opcode(15 downto 12) = "1110" then
        rf_dest_addr <= '0' & sndOPC(8 downto 6);
        else
        rf_dest_addr <= sndOPC(9 downto 6);
      end if;

    elsif dest_2ndHbits = '1' then
      -- untested from tg68k
      rf_dest_addr <= '0' & sndOPC(14 downto 12);

    elsif set.write_reminder = '1' or dest_2ndLbits = '1'then
      -- untested from tg68k
      rf_dest_addr <= '0' & sndOPC(2 downto 0);

    elsif setstackaddr = '1' then
      rf_dest_addr <= "1111";
    elsif dest_hbits = '1' then
      rf_dest_addr <= dest_areg & opcode(11 downto 9);
    else
      if opcode(5 downto 3) = "000" or data_is_source = '1' then
        rf_dest_addr <= dest_areg & opcode(2 downto 0);
      else
        rf_dest_addr <= '1' & opcode(2 downto 0);
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- set source regaddr
  -----------------------------------------------------------------------------
  process (opcode, movem_presub, movem_regaddr, source_lowbits, source_areg, sndOPC, brief, exec, set, source_2ndLbits, source_2ndMbits, source_2ndHbits, source_briefMbits)
  begin
    if exec.movem_action = '1' or set.movem_action = '1' then
      if movem_presub = '1' then
        rf_source_addr <= movem_regaddr Xor "1111";
      else
        rf_source_addr <= movem_regaddr;
      end if;
    elsif source_2ndLbits = '1' then
      -- untested from tg68k
      rf_source_addr <= '0' & sndOPC( 2 downto 0);

      elsif source_2ndMbits = '1' then
      rf_source_addr <= sndOPC( 9 downto 6);

    elsif source_2ndHbits = '1' then
      -- untested from tg68k
      rf_source_addr <= '0' & sndOPC(14 downto 12);
    elsif source_briefMbits = '1' then
      rf_source_addr <= brief( 9 downto 6);
    elsif source_lowbits = '1' then
      rf_source_addr <= source_areg & opcode(2 downto 0);
    elsif exec.linksp = '1' then
      rf_source_addr <= "1111";
    else
      rf_source_addr <= source_areg & opcode(11 downto 9);
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- set OP1out
  -----------------------------------------------------------------------------
  process (reg_QA, store_in_tmp, ea_data, long_start, addr, exec, memmaskmux, data_write_tmp)
  begin
    OP1out <= reg_QA;
    if exec.OP1out_zero = '1' then
      OP1out <= (others => '0');
    elsif exec.ea_data_OP1 = '1' and store_in_tmp = '1' then
      OP1out <= ea_data;
    elsif exec.opcPACK = '1' then
      OP1out <= data_write_tmp;
    elsif exec.movem_action = '1' or memmaskmux(3) = '0' or exec.OP1addr = '1' then
      OP1out <= addr;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- set OP2out
  -----------------------------------------------------------------------------
  process (  OP2out, reg_QB, exe_opcode, exe_datatype, execOPC, exec, use_direct_data, store_in_tmp, data_write_tmp, ea_data)
  begin
    OP2out(15 downto 0) <= reg_QB(15 downto 0);
    OP2out(31 downto 16) <= (others => OP2out(15));

    if exec.OP2out_one = '1' then
      OP2out(15 downto 0) <= "1111111111111111";
    elsif exec.opcEXT = '1' then
      if exe_opcode(6) = '0' or exe_opcode(8) = '1' then --ext.w
        OP2out(15 downto 8) <= (others => OP2out(7));
      end if;

    elsif (use_direct_data = '1' and exec.opcPACK = '0') or (exec.exg = '1' and execOPC = '1') or exec.get_bfoffset = '1' then
      OP2out <= data_write_tmp;

    elsif (exec.ea_data_OP1 = '0' and store_in_tmp = '1') or exec.ea_data_OP2 = '1' then
      OP2out <= ea_data;

    elsif exec.opcMOVEQ = '1' then
      OP2out(7 downto 0) <= exe_opcode(7 downto 0);
      OP2out(15 downto 8) <= (others => exe_opcode(7));

    elsif exec.opcADDQ = '1' then
      OP2out(2 downto 0) <= exe_opcode(11 downto 9);
      if exe_opcode(11 downto 9) = "000" then
        OP2out(3) <= '1';
      else
        OP2out(3) <= '0';
      end if;
      OP2out(15 downto 4) <= (others => '0');
    elsif exe_datatype = "10" then
      OP2out(31 downto 16) <= reg_QB(31 downto 16);
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- handle EA_data, data_write
  -----------------------------------------------------------------------------
  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if Reset = '1' then
        store_in_tmp <= '0';
        exec_write_back <= '0';
        direct_data <= '0';
        use_direct_data <= '0';
        Z_error <= '0';

      elsif clkena_lw = '1' then
        direct_data <= '0';

        if state = "11" then
          exec_write_back <= '0';
        elsif setstate = "10" and write_back = '1' and (opcode(15 downto 12)/="0100" or next_micro_state = idle) then  	--this shut be a fix for pinball --thanks slingshot
          exec_write_back <= '1';
        end if;

        if set_direct_data = '1' then
          direct_data <= '1';
          if set_exec.opcPACK = '1' then
            use_direct_data <= '0';
          else
            use_direct_data <= '1';
          end if;
        elsif endOPC = '1' then
          use_direct_data <= '0';
        end if;
        exec_DIRECT <= set_exec.opcMOVE;

        if endOPC = '1' then
          store_in_tmp <= '0';
          Z_error <= '0';
        else
          if set_Z_error = '1' then
            Z_error <= '1';
          end if;
          if set_exec.opcMOVE = '1' and state = "11" then
            use_direct_data <= '1';
          end if;

          if state = "10" then
            store_in_tmp <= '1';
          end if;
          if direct_data = '1' and state = "00" then
            store_in_tmp <= '1';
          end if;
        end if;

        if state = "10" then
          ea_data <= data_read;
        elsif exec.get_2ndOPC = '1' or set_PCbase='1' then --TH cmpi (d16,PC) fix
          ea_data <= addr;
        elsif exec.store_ea_data = '1' or (direct_data = '1' and state = "00") then
          ea_data <= last_data_read;
        end if;

        if writePC = '1' then
          data_write_sel <= 0;
          --data_write_tmp <= TG68_PC;
          data_write_tmp <= TG68_PC(31 downto 1) & '0'; -- patch for address error pc
        elsif exec.writePC_add = '1' then
          data_write_sel <= 1;
          data_write_tmp <= TG68_PC_add;
         elsif micro_state=trap00 then
          data_write_sel <= 2;
          data_write_tmp <= exe_pc;
        elsif micro_state = trap0 then
          data_write_sel <= 3;
          -- this is only active for 010+ since in 000 writePC is
          -- true in state trap0
          data_write_tmp(15 downto 0) <= trap_vector_stackfmt & trap_vector(11 downto 0);
        elsif exec.hold_dwr = '1' then
          data_write_sel <= 4;
          data_write_tmp <= data_write_tmp;
        elsif exec.exg = '1' then
          data_write_sel <= 5;
          data_write_tmp <= OP1out;
        elsif exec.get_ea_now = '1' and ea_only = '1' then -- ist for pea
          data_write_sel <= 6;
          data_write_tmp <= addr;
        elsif execOPC = '1' or micro_state = pack2 then
          data_write_sel <= 7;
          data_write_tmp <= ALUout;
        elsif (exec_DIRECT = '1' and state = "10") then
          data_write_sel <= 8;
          data_write_tmp <= data_read;
          if exec.movepl = '1' then
            data_write_tmp(31 downto 8) <= data_write_tmp(23 downto 0);
          end if;
        elsif exec.movepl = '1' then
          data_write_sel <= 9;
          data_write_tmp(15 downto 0) <= reg_QB(31 downto 16);
        elsif direct_data = '1' then
          data_write_sel <= 10;
          data_write_tmp <= last_data_read;
        elsif writeSR = '1' then
          data_write_sel <= 11;
          data_write_tmp(15 downto 0) <= trap_SR(7 downto 0) & Flags(7 downto 0);
        else
          data_write_sel <= 12;
          data_write_tmp <= OP2out;
        end if;

      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- brief
  -----------------------------------------------------------------------------
  process (brief, OP1out, OP1outbrief, cpu_type)
  begin
    if brief(11) = '1' then
      OP1outbrief <= OP1out(31 downto 16);
    else
      OP1outbrief <= (others => OP1out(15));
    end if;
    briefdata <= OP1outbrief & OP1out(15 downto 0);

    if (cpu_type.ge_68020 = '1') then -- 68020 only
      case brief(10 downto 9) is -- mikej SCALE factor
        when "00" => briefdata <= OP1outbrief & OP1out(15 downto 0);
        when "01" => briefdata <= OP1outbrief(14 downto 0) & OP1out(15 downto 0) & '0';
        when "10" => briefdata <= OP1outbrief(13 downto 0) & OP1out(15 downto 0) & "00";
        when "11" => briefdata <= OP1outbrief(12 downto 0) & OP1out(15 downto 0) & "000";
        when others => NULL;
      end case;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- MEM_IO
  -----------------------------------------------------------------------------
  -- for 010+,

  -- 68000 produces 3 word stack frames
  --  PCL, PCH, SR (high to low) <SP
  --  ** bus or address error produce 7 word
  --  PCL, PCH, SR, IR, ADDR_L, ADDR_H, FC  <SP  first 3 are correct which is probably enough
  --
  -- 68010 produces 4 word stack frames, format 0
  --   VEC, PCL, PCH, SR < SP
  --   Bus and Address Error Stack Frame, Format $8, 29 words!
  --
  -- 68020 produces 4/6 word stack frames, format 0 and 6 word
  --   6 word format 2 for vector 14,18,1C,24, CHK/2/TRAPcc,TRAPv,TRACE,/0
  --   EA,EA, VEC, PCL, PCH, SR  format2
  --   Bus and Address error either 16 words(formatA) at instruction boundary
  --   or 46 words(formatB) otherwise
  --    all end ---- PC, SR  < SP

  -- for bus/addr err 010/20 we'll put a standard format0 exception frame for now

  process (i_clk )
    variable fmt2 : bit1;
    variable trap7w : bit1;
  begin
    if rising_edge(i_clk) then
      if clkena_lw = '1' then

        fmt2 := '0';
        trap7w := '0';

        if trap_berr='1' then
          trap_vector(11 downto 0) <= X"008"; trap7w := '1';
        end if;

        if trap_addr_error = '1' then
          trap_vector(11 downto 0) <= X"00C"; trap7w := '1';
        end if;

        if trap_illegal = '1' then
          trap_vector(11 downto 0) <= X"010";
        end if;

        if z_error = '1' then
          trap_vector(11 downto 0) <= X"014"; fmt2 := '1';
        end if;

        if exec.trap_chk = '1' then
          trap_vector(11 downto 0) <= X"018"; fmt2 := '1';
        end if;

        if exec.trap_trapv = '1' then -- also TRAPcc
          trap_vector(11 downto 0) <= X"01C"; fmt2 := '1';
        end if;

        if trap_priv = '1' then
          trap_vector(11 downto 0) <= X"020";
        end if;

        if trap_trace = '1' then
          trap_vector(11 downto 0) <= X"024"; fmt2 := '1';
        end if;

        if trap_1010 = '1' then
          trap_vector(11 downto 0) <= X"028";
        end if;

        if trap_1111 = '1' then
          trap_vector(11 downto 0) <= X"02C";
        end if;

        if trap_trap = '1' then
          trap_vector(11 downto 0) <= x"0" & "10" & opcode(3 downto 0) & "00";
        end if;

        if trap_interrupt = '1' then
          trap_vector(11 downto 0) <= "00" & IPL_vec & "00"; --TH
        end if;
        -- TH TODO: non-autovector IRQs

        if next_micro_state = trap0 or next_micro_state = trap00 then
          -- stack frame format #2 only for 020+
          trap_vector_stackfmt <= "0000";
          if (cpu_type.ge_68020 = '1') then
            if fmt2 = '1' then
              trap_vector_stackfmt <= "0010";
            end if;
          end if;

          trap_7word <= '0';
          if (cpu_type.is_68000 = '1') then
            trap_7word <= trap7w;
          end if;
        end if;

      end if;
    end if;
  end process;

  process (setdisp, memaddr_a, briefdata, memaddr_delta, setdispbyte, datatype, interrupt, rIPL_nr, IPL_vec,
           memaddr_reg, reg_QA, use_base, VBR, last_data_read, trap_vector, exec, set, cpu_type)
  begin
    --
    if (cpu_type.ge_68010 = '0') then
      trap_vector_vbr <= (x"00000" & trap_vector);
    else
      trap_vector_vbr <= (x"00000" & trap_vector) + VBR;
    end if;

    memaddr_a(4 downto 0) <= "00000";
    memaddr_a(7 downto 5) <= (others => memaddr_a(4));
    memaddr_a(15 downto 8) <= (others => memaddr_a(7));
    memaddr_a(31 downto 16) <= (others => memaddr_a(15));
    if setdisp = '1' then
      if exec.briefext = '1' then
        memaddr_a <= briefdata + memaddr_delta;
      elsif setdispbyte = '1' then
        memaddr_a(7 downto 0) <= last_data_read(7 downto 0);
      else
        memaddr_a <= last_data_read;
      end if;
    elsif set.presub = '1' then
      if set.longaktion = '1' then
        memaddr_a(4 downto 0) <= "11100";
      elsif datatype = "00" and set.use_SP = '0' then
        memaddr_a(4 downto 0) <= "11111";
      else
        memaddr_a(4 downto 0) <= "11110";
      end if;
    elsif interrupt = '1' then
      memaddr_a(4 downto 0) <= '1' & rIPL_nr & '0';
    end if;
  end process;


  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if (reset = '1') then
        tmp_TG68_PC   <= (others => '0');
        use_base      <= '0';
        memaddr_delta <= (others => '0');
        memaddr_delta_sel <= 0;
        memaddr       <= (others => '0');
      else
        if i_ena = '1' then
          if exec.get_2ndOPC = '1' or (state = "10" and memread(0) = '1') then
            tmp_TG68_PC <= addr;
          end if;
          use_base <= '0';

          if memmaskmux(3) = '0' then
            memaddr_delta <= addsub_q;
            memaddr_delta_sel <= 0;
          elsif exec.mem_addsub = '1' then
            memaddr_delta <= addsub_q;
            -- note, this should give an exception for 68000
            if exec.movem_action = '1' and memmaskmux(3) = '1' and (memmaskmux(5 downto 4) = "10" or memmaskmux(5 downto 4) = "01") and (movem_presub = '0') then
              memaddr_delta <= addr; -- hold for non-aligned case, only when incrementing
            else
              memaddr_delta <= addsub_q;
            end if;
            memaddr_delta_sel <= 1;
          elsif set_exec.upperbound = '1' then -- bit of a bodge
            -- this will break for 32 bit bus access, fix properly
            if (datatype = "00") then
              memaddr_delta <= addr + "1";
            else
              memaddr_delta <= addr + "10";
            end if;
            memaddr_delta_sel <= 2;
          elsif state = "01" and (exec_write_back = '1' or micro_state = cas) then
            memaddr_delta <= tmp_TG68_PC;
            memaddr_delta_sel <= 3;
          elsif exec.direct_delta = '1' then
            memaddr_delta <= data_read;
            memaddr_delta_sel <= 4;
          elsif exec.ea_to_pc = '1' and setstate = "00" then
            memaddr_delta <= addr;
            memaddr_delta_sel <= 5;
          elsif set.addrlong = '1' then
            memaddr_delta <= last_data_read;
            memaddr_delta_sel <= 6;
          elsif setstate = "00" then
            memaddr_delta <= TG68_PC_add;
            memaddr_delta_sel <= 7;
          elsif exec.dispouter = '1' then
            memaddr_delta <= ea_data + memaddr_a;
            memaddr_delta_sel <= 8;
          elsif set_vectoraddr = '1' then
            memaddr_delta <= trap_vector_vbr;
            memaddr_delta_sel <= 9;
          else
            memaddr_delta <= memaddr_a;
            memaddr_delta_sel <= 10;
            if interrupt = '0' and Suppress_Base = '0' then
              -- if interrupt='0' and Suppress_Base='0' and setstate(1)='1' then
              use_base <= '1';
            end if;
          end if;

          if (long_done='0' and state(1)='1') or movem_presub='0' THEN
            memaddr <= addr;
          end if;

        end if;
      end if;
    end if;
  end process;

  process(memaddr_reg, memaddr_delta, use_base, reg_QA)
  begin
    -- if access done, and not aligned, don't increment
    addr <= memaddr_reg + memaddr_delta;

    if use_base = '0' then
      memaddr_reg <= (others => '0');
    else
      memaddr_reg <= reg_QA;
    end if;
  end process;
  o_addr <= addr;
  -----------------------------------------------------------------------------
  -- PC Calc + fetch opcode
  -----------------------------------------------------------------------------
  IPL_nr <= not i_ipl_l;

  process (setstate, state, exec_write_back, set_direct_data, next_micro_state, stop, make_trace, make_berr, IPL_nr, FlagsSR, set_rot_cnt, opcode, writePCbig, set_exec, exec,
         PC_dataa, PC_datab, setnextpass, last_data_read, TG68_PC_brw, TG68_PC_word, Z_error, trap_trap, interrupt, tmp_TG68_PC, TG68_PC)
  begin
    PC_dataa <= TG68_PC;
    if TG68_PC_brw = '1' then
      PC_dataa <= tmp_TG68_PC;
    end if;

    PC_datab(2 downto 0) <= (others => '0');
    PC_datab(3) <= PC_datab(2);
    PC_datab( 7 downto  4) <= (others => PC_datab(3));
    PC_datab(15 downto  8) <= (others => PC_datab(7));
    PC_datab(31 downto 16) <= (others => PC_datab(15));

    if interrupt = '1' then
      PC_datab(2 downto 1) <= "11";
    end if;
    if exec.writePC_add = '1' then
      if writePCbig = '1' then
        PC_datab(3) <= '1';
        PC_datab(1) <= '1';
      else
        PC_datab(2) <= '1';
      end if;
      -- check what this does trap wise
      if trap_trap = '1' or exec.trap_trapv = '1' or exec.trap_chk = '1' or Z_error = '1' then
        PC_datab(1) <= '1';
      end if;
    elsif state = "00" then
      PC_datab(1) <= '1';
    end if;

    if TG68_PC_brw = '1' then
      if TG68_PC_word = '1' then
        PC_datab <= last_data_read;
      else
        PC_datab(7 downto 0) <= opcode(7 downto 0);
      end if;
    end if;

    TG68_PC_add <= PC_dataa + PC_datab;

    setopcode <= '0';
    setendOPC <= '0';
    setinterrupt <= '0';
    if setstate = "00" and next_micro_state = idle and setnextpass = '0' and (exec_write_back = '0' or state = "11") and set_rot_cnt = "000001" and set_exec.opcCHK = '0' and set_exec.opcCHK2 = '0' then
      setendOPC <= '1';
      if FlagsSR(2 downto 0)<IPL_nr or IPL_nr="111"  or make_trace='1'  or make_berr='1' then
        setinterrupt <= '1';
      elsif stop = '0' then
        setopcode <= '1';
      end if;
    end if;
    setexecOPC <= '0';
    -- bit of a bodge here with cmp2/chk2. We trick it into executing the opcode twice.
    if setstate = "00" and (next_micro_state = idle or next_micro_state = upperbound2) and set_direct_data = '0' and (exec_write_back = '0' or state = "10") then
      setexecOPC <= '1';
    end if;

  end process;

  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if Reset = '1' then
        memmask <= "111111";
        memread <= "1111";

        TG68_PC <= X"00000004";

        interrupt <= '0';
        decodeOPC <= '0';
        endOPC <= '0';
        execOPC <= '0';

        exe_datatype <= (others => '0');
        exe_opcode <= (others => '0');

        state <= "01";
        trap_interrupt <= '0';
        last_opc_read <= X"4EF9"; --jmp nn.l
        TG68_PC_word <= '0';

        rot_cnt <= "000001";
        byte <= '0';
        trap_trace <= '0';
        trap_berr <= '0';
        writePCbig <= '0';
        Suppress_Base <= '0';
        make_berr <= '0';
        stop <= '0';

        brief <= (others => '0');
      else
        if i_ena = '1' then
          memmask <= memmask(3 downto 0) & "11";
          memread <= memread(1 downto 0) & memmaskmux(5 downto 4);
          -- if wbmemmask(5 downto 4)="11" then
          -- wbmemmask <= memmask;
          -- end if;
          if exec.directPC = '1' then
            TG68_PC <= data_read;
          elsif exec.ea_to_pc = '1' then
            TG68_PC <= addr;
          elsif (state = "00" or TG68_PC_brw = '1') and stop = '0' then
            TG68_PC <= TG68_PC_add;
          end if;
        end if;

        if clkena_lw = '1' then
          interrupt <= setinterrupt;
          decodeOPC <= setopcode;
          endOPC    <= setendOPC;
          execOPC   <= setexecOPC;

          exe_datatype <= set_datatype;
          exe_opcode <= opcode;

          if trap_berr = '0' then
            make_berr <= (i_berr or make_berr);
          else
            make_berr <= '0';
          end if;

          stop <= set_stop or (stop and not setinterrupt);
          if setinterrupt = '1' then
            make_berr <= '0';
            trap_berr <= '0';

            if make_trace = '1' then
              trap_trace <= '1';
            elsif make_berr='1' THEN
              trap_berr <= '1';
            else
              rIPL_nr <= IPL_nr;
              IPL_vec <= "00011" & IPL_nr; -- TH
              trap_interrupt <= '1';
            end if;
          end if;

          if micro_state = trap0 and i_ipl_autovector = '0' then
            IPL_vec <= last_data_read(7 downto 0); -- TH
          end if;

          if state = "00" then
            last_opc_read <= data_read(15 downto 0);
            last_opc_pc <= tg68_pc;
          end if;

          if setopcode = '1' then
            trap_interrupt <= '0';
            trap_trace <= '0';
            TG68_PC_word <= '0';
            trap_berr <= '0';
          elsif opcode(7 downto 0) = "00000000" or opcode(7 downto 0) = "11111111" or data_is_source = '1' then
            TG68_PC_word <= '1';
          end if;

          if exec.get_bfoffset = '1' then
            alu_bf_width <= bf_width;
            alu_bf_loffset <= bf_loffset;
            alu_bf_offset <= bf_offset;
          end if;

          byte <= '0';
          memread <= "1111";
          fc(1) <= not setstate(1) or (PCbase and not setstate(0));
          fc(0) <= setstate(1) and (not PCbase or setstate(0));
          if interrupt = '1' then
            fc(1 downto 0) <= "11";
          end if;

          if (state = "10" and write_back = '1' and setstate /= "10") or set_rot_cnt /= "000001" or (stop = '1' and interrupt = '0') or set_exec.opcCHK = '1' or set_exec.opcCHK2 = '1' then
            state <= "01";
            memmask <= "111111";
          elsif execOPC = '1' and exec_write_back = '1' then
            state <= "11";
            fc(1 downto 0) <= "01";
            memmask <= wbmemmask;
            if datatype = "00" then
              byte <= '1';
            end if;
          else
            state <= setstate;
            if setstate = "01" then
              memmask <= "111111";
              wbmemmask <= "111111";
            elsif exec.get_bfoffset = '1' then
              memmask <= set_memmask;
              wbmemmask <= set_memmask;
              oddout <= set_oddout;
            elsif set.longaktion = '1' then
              memmask <= "100001";
              wbmemmask <= "100001";
              oddout <= '0';
            elsif set_datatype = "00" and setstate(1) = '1' then
              memmask <= "101111";
              wbmemmask <= "101111";
              if set.mem_byte = '1' then
                oddout <= '0';
              else
                oddout <= '1';
              end if;
            else
              memmask <= "100111";
              wbmemmask <= "100111";
              oddout <= '0';
            end if;
          end if;

          if decodeOPC = '1' then
            rot_bits <= set_rot_bits;
            writePCbig <= '0';
          else
            writePCbig <= set_writePCbig or writePCbig;
          end if;
          if decodeOPC = '1' or exec.ld_rot_cnt = '1' or rot_cnt /= "000001" then
            rot_cnt <= set_rot_cnt;
          end if;
          if setstate(1) = '1' and set_datatype = "00" then
            byte <= '1';
          end if;

          if set_Suppress_Base = '1' then
            Suppress_Base <= '1';
          elsif setstate(1) = '1' or (ea_only = '1' and set.get_ea_now = '1') then
            Suppress_Base <= '0';
          end if;
          if getbrief = '1' then
            if state(1) = '1' then
              brief <= last_opc_read(15 downto 0);
            else
              brief <= data_read(15 downto 0);
            end if;
          end if;

          if decodeOPC = '1' or interrupt = '1' then
            trap_SR <= FlagsSR;
          end if;
        end if;

      end if;
    end if;
  end process;

  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if Reset = '1' then
        opcode     <= x"2E79"; --move $0,a7
        exe_pc     <= (others => '0');
        nextpass   <= '0';
      else
        if clkena_lw = '1' then
          -- experimental fix to clear state during trap
          if next_micro_state = trap0 or next_micro_state = trap00 then
            opcode <= X"4E71";          --nop
            nextpass <= '0';
          elsif setopcode='1' and i_berr='0' then
            if state = "00" then
              opcode <= data_read(15 downto 0);
              exe_pc <= tg68_pc;
            else
              opcode <= last_opc_read(15 downto 0);
              exe_pc <= last_opc_pc;
            end if;
            nextpass <= '0';
          elsif setinterrupt = '1' or setopcode='1' THEN
            opcode <= X"4E71";          --nop
            -- untested from TG68K, investigate
            --opcode(15 downto 12) <= X"7"; --moveq
            --opcode( 8 downto 6) <= "001"; --word

            nextpass <= '0';
          else
            if setnextpass = '1' or regdirectsource = '1' then
              nextpass <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  process (i_clk)
  begin
    if rising_edge(i_clk) then

      if Reset = '1' then
        PCbase <= '1';
      elsif clkena_lw = '1' then
        PCbase <= set_PCbase or PCbase;
        if setexecOPC = '1' or (state(1) = '1' and movem_run = '0') then
          PCbase <= '0';
        end if;
      end if;
    end if;
  end process;

  process (i_clk)
    variable x : bit1;
  begin
    if rising_edge(i_clk) then
      if Reset = '1' then
        exec <= (others => '0');
        exec_tas <= '0';

      elsif clkena_lw = '1' then
        exec <= set;
        exec_tas <= '0';
        exec.subidx <= set.presub or set.subidx;

        if setexecOPC = '1' then
          exec     <= opc_or(set_exec, set);
          exec_tas <= set_exec_tas;
        end if;
        exec.get_2ndOPC <= set.get_2ndOPC or setopcode;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  --prepare Bitfield Parameters
  ------------------------------------------------------------------------------
  process (sndOPC, reg_QA, reg_QB, bf_width, bf_offset, bf_offset_l, bf_bhits, opcode, setstate)
  begin
        -- the ALU needs the full real offset to return the correct result for
        -- bfffo
    if sndOPC(11) = '1' then
      bf_offset <= reg_QA;
    else
      bf_offset <= (others => '0');
      bf_offset(4 downto 0) <= sndOPC(10 downto 6);
    end if;
        -- offset within long word
    bf_offset_l <= bf_offset(4 downto 0);

    if sndOPC(5) = '1' then
      bf_width <= reg_QB(4 downto 0) - 1;
    else
      bf_width <= sndOPC(4 downto 0) - 1;
    end if;
    bf_bhits <= ('0' & bf_width) + ('0' & bf_offset_l);
    set_oddout <= not bf_bhits(3);

    bf_loffset <= 31 - bf_bhits(4 downto 0);
    if opcode(4 downto 3) /= "00" then
      -- memory is being read with byte precision, thus offset
      -- bit 2:0 are only used in the alu
      bf_loffset(4 downto 3) <= "00";
      bf_offset_l(4 downto 3) <= "00";
    end if;

    case bf_bhits(5 downto 3) is
      when "000" =>
        set_memmask <= "101111";
      when "001" =>
        set_memmask <= "100111";
      when "010" =>
        set_memmask <= "100011";
      when "011" =>
        set_memmask <= "100001";
      when others =>
        set_memmask <= "100000";
    end case;
    if setstate = "00" then
      set_memmask <= "100111";
    end if;

  end process;

  ------------------------------------------------------------------------------
  --SR op
  ------------------------------------------------------------------------------
  process (FlagsSR, last_data_read, OP2out, exec)
  begin
    if exec.andisR = '1' then
      SRin <= FlagsSR and last_data_read(15 downto 8);
    elsif exec.eorisR = '1' then
      SRin <= FlagsSR xor last_data_read(15 downto 8);
    elsif exec.orisR = '1' then
      SRin <= FlagsSR or last_data_read(15 downto 8);
    else
      SRin <= OP2out(15 downto 8);
    end if;
  end process;

  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if Reset = '1' then
        FlagsSR(7 downto 6) <= "00"; -- Clear T1,T0 to disable tracing, all CPUs
        FlagsSR(5) <= '1';
        FlagsSR(4) <= '0'; -- Clear M bit (020 only)
        FlagsSR(2 downto 0) <= "111";
        fc(2) <= '1';
        SVmode <= '1';
        preSVmode <= '1';
        make_trace <= '0';
      elsif clkena_lw = '1' then
        if setopcode = '1' then
         -- 020 has trace mode 01 which is trace on change of flow only, not supported currently
          make_trace <= FlagsSR(7);
          if set.changeMode = '1' then
            SVmode <= not SVmode;
          else
            SVmode <= preSVmode;
          end if;
        end if;
        if set.changeMode = '1' then
          preSVmode <= not preSVmode;
          FlagsSR(5) <= not preSVmode;
          fc(2) <= not preSVmode;
        end if;
        if micro_state = trap3 then
          FlagsSR(7) <= '0';
        end if;
        if trap_trace = '1' and state = "10" then
          make_trace <= '0';
        end if;
        if exec.directSR = '1' or set_stop = '1' then
          FlagsSR <= data_read(15 downto 8);
        end if;
        if interrupt = '1' and trap_interrupt = '1' then
          FlagsSR(2 downto 0) <= rIPL_nr;
        end if;

        if exec.to_SR = '1' then
          FlagsSR(7 downto 0) <= SRin and x"f7"; -- write back SR and mask out the unused bit
          fc(2) <= SRin(5);
          -- end if;
        elsif exec.update_FC = '1' then
          fc(2) <= FlagsSR(5);
        end if;
        if interrupt = '1' then
          fc(2) <= '1';
        end if;
      end if;
    end if;
  end process;
  o_fc <= fc;

  -----------------------------------------------------------------------------
  -- decode opcode
  -----------------------------------------------------------------------------
  u_decode : entity work.M68K_Decode
  generic map (
    BarrelShifter  => 2
  )
  port map (
    cpu             => i_cpu_type,
    OP1out          => OP1out,
    OP2out          => OP2out,
    opcode          => opcode,
    exe_condition   => exe_condition,
    nextpass        => nextpass,
    micro_state     => micro_state,
    state           => state,
    decodeOPC       => decodeOPC,
    setexecOPC      => setexecOPC,
    Flags           => Flags,
    FlagsSR         => FlagsSR,
    direct_data     => direct_data,
    trapd           => trapd,
    movem_run       => movem_run,
    last_data_read  => last_data_read,
    set_V_Flag      => set_V_Flag,
    set_Cmp2_Flags  => set_Cmp2_Flags,
    Z_error         => Z_error,
    trap_trace      => trap_trace,
    trap_interrupt  => trap_interrupt,
    SVmode          => SVmode,
    preSVmode       => preSVmode,
    stop            => stop,
    long_done       => long_done,
    execOPC         => execOPC,
    exec_write_back => exec_write_back,
    c_out           => c_out,
    interrupt       => interrupt,
    rot_cnt         => rot_cnt,
    brief           => brief,
    addr            => addr,
    last_data_in    => last_data_in,
    long_start      => long_start,

    sndOPC          => sndOPC,
    exec            => exec,
    reg_QA          => reg_QA,
    reg_QB          => reg_QB,
    trap_berr       => trap_berr,
    trap_7word      => trap_7word,
    --
    o_skipFetch              => o_skip_fetch,
    o_next_micro_state       => next_micro_state,
    o_set                    => set,
    o_set_exec               => set_exec,
    o_setnextpass            => setnextpass,
    o_setstate               => setstate,
    o_getbrief               => getbrief,
    o_setstackaddr           => setstackaddr,
    o_set_Suppress_Base      => set_Suppress_Base,
    o_set_PCbase             => set_PCbase,
    o_set_direct_data        => set_direct_data,
    o_datatype               => datatype,
    o_set_rot_cnt            => set_rot_cnt,
    o_set_rot_bits           => set_rot_bits,
    o_set_stop               => set_stop,
    o_movem_presub           => movem_presub,
    o_regdirectsource        => regdirectsource,
    o_dest_areg              => dest_areg,
    o_source_areg            => source_areg,
    o_data_is_source         => data_is_source,
    o_write_back             => write_back,
    o_writePC                => writePC,
    o_ea_only                => ea_only,
    o_source_lowbits         => source_lowbits,
    o_source_2ndHbits        => source_2ndHbits,
    o_source_2ndMbits        => source_2ndMbits,
    o_source_2ndLbits        => source_2ndLbits,
    o_source_briefMbits      => source_briefMbits,
    o_dest_2ndHbits          => dest_2ndHbits,
    o_dest_2ndLbits          => dest_2ndLbits,
    o_dest_hbits             => dest_hbits,
    o_set_exec_tas           => set_exec_tas,
    o_trapmake               => trapmake,
    o_trap_illegal           => trap_illegal,
    o_trap_addr_error        => trap_addr_error,
    o_trap_priv              => trap_priv,
    o_trap_1010              => trap_1010,
    o_trap_1111              => trap_1111,
    o_trap_trap              => trap_trap,
    o_set_Z_error            => set_Z_error,
    o_writeSR                => writeSR,
    o_set_vectoraddr         => set_vectoraddr,
    o_set_writePCbig         => set_writePCbig,
    o_TG68_PC_brw            => TG68_PC_brw,
    o_setdispbyte            => setdispbyte,
    o_setdisp                => setdisp,
    o_Regwrena_now           => Regwrena_now
    );

  set_datatype <= datatype;  -- mikej remove and merge once regression running
  process (i_clk)
  begin
    -----------------------------------------------------------------------------
    -- execute microcode
    -----------------------------------------------------------------------------
    if rising_edge(i_clk) then
      if Reset='1' then
        micro_state <= ld_nn;
        trapd <= '0';
      elsif clkena_lw='1' then
        trapd <= trapmake;
        micro_state <= next_micro_state;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- MOVEC
  -----------------------------------------------------------------------------
  process (i_clk)
  begin
    -- all other hexa codes should give illegal isntruction exception
    if rising_edge(i_clk) then
      if Reset = '1' then
        VBR <= (others => '0');
        --CACR <= (others => '0');
        CACR <= "0001"; -- default cache on at boot for A500 systems
      elsif clkena_lw = '1' and exec.movec_wr = '1' then
        case brief(11 downto 0) is
          when X"000" => NULL; -- SFC -- 68010+
          when X"001" => NULL; -- DFC -- 68010+
          when X"002" => CACR <= reg_QA(3 downto 0); -- 68020+
          when X"800" => NULL; -- USP -- 68010+
          when X"801" => VBR <= reg_QA; -- 68010+
          when X"802" => NULL; -- CAAR -- 68020+
          when X"803" => NULL; -- MSP -- 68020+
          when X"804" => NULL; -- isP -- 68020+
          when others => NULL;
        end case;
      end if;
    end if;
  end process;

  process (VBR, CACR, brief)
  begin
    movec_data <= (others => '0');
    case brief(11 downto 0) is
      when X"002" => movec_data <= "0000000000000000000000000000" & (CACR AND "0011");

      when X"801" =>
        movec_data <= VBR;
        --end if;
      when others => NULL;
    end case;
  end process;

  o_cacr <= CACR;
  o_vbr  <= VBR;

  -----------------------------------------------------------------------------
  -- Conditions
  -----------------------------------------------------------------------------
  process (exe_opcode, Flags)
  begin
    case exe_opcode(11 downto 8) is
      when X"0" => exe_condition <= '1';
      when X"1" => exe_condition <= '0';
      when X"2" => exe_condition <= not Flags(0) and not Flags(2);
      when X"3" => exe_condition <= Flags(0) or Flags(2);
      when X"4" => exe_condition <= not Flags(0);
      when X"5" => exe_condition <= Flags(0);
      when X"6" => exe_condition <= not Flags(2);
      when X"7" => exe_condition <= Flags(2);
      when X"8" => exe_condition <= not Flags(1);
      when X"9" => exe_condition <= Flags(1);
      when X"a" => exe_condition <= not Flags(3);
      when X"b" => exe_condition <= Flags(3);
      when X"c" => exe_condition <= (Flags(3) and Flags(1)) or (not Flags(3) and not Flags(1));
      when X"d" => exe_condition <= (Flags(3) and not Flags(1)) or (not Flags(3) and Flags(1));
      when X"e" => exe_condition <= (Flags(3) and Flags(1) and not Flags(2)) or (not Flags(3) and not Flags(1) and not Flags(2));
      when X"f" => exe_condition <= (Flags(3) and not Flags(1)) or (not Flags(3) and Flags(1)) or Flags(2);
      when others => NULL;
    end case;
  end process;

  -----------------------------------------------------------------------------
  -- Movem
  -----------------------------------------------------------------------------
  process (i_clk)
  begin
    if rising_edge(i_clk) then
      if clkena_lw = '1' then
        movem_actiond <= exec.movem_action;
        if decodeOPC = '1' then
          sndOPC <= data_read(15 downto 0);
        elsif exec.movem_action = '1' or set.movem_action = '1' then
          case movem_regaddr is
            when "0000" => sndOPC(0) <= '0';
            when "0001" => sndOPC(1) <= '0';
            when "0010" => sndOPC(2) <= '0';
            when "0011" => sndOPC(3) <= '0';
            when "0100" => sndOPC(4) <= '0';
            when "0101" => sndOPC(5) <= '0';
            when "0110" => sndOPC(6) <= '0';
            when "0111" => sndOPC(7) <= '0';
            when "1000" => sndOPC(8) <= '0';
            when "1001" => sndOPC(9) <= '0';
            when "1010" => sndOPC(10) <= '0';
            when "1011" => sndOPC(11) <= '0';
            when "1100" => sndOPC(12) <= '0';
            when "1101" => sndOPC(13) <= '0';
            when "1110" => sndOPC(14) <= '0';
            when "1111" => sndOPC(15) <= '0';
            when others => NULL;
          end case;
        end if;
      end if;
    end if;
  end process;

  process (sndOPC, movem_mux)
  begin
    movem_regaddr <= "0000";
    movem_run <= '1';
    if sndOPC(3 downto 0) = "0000" then
      if sndOPC(7 downto 4) = "0000" then
        movem_regaddr(3) <= '1';
        if sndOPC(11 downto 8) = "0000" then
          if sndOPC(15 downto 12) = "0000" then
            movem_run <= '0';
          end if;
          movem_regaddr(2) <= '1';
          movem_mux <= sndOPC(15 downto 12);
        else
          movem_mux <= sndOPC(11 downto 8);
        end if;
      else
        movem_mux <= sndOPC(7 downto 4);
        movem_regaddr(2) <= '1';
      end if;
    else
      movem_mux <= sndOPC(3 downto 0);
    end if;

    if movem_mux(1 downto 0) = "00" then
      movem_regaddr(1) <= '1';
      if movem_mux(2) = '0' then
        movem_regaddr(0) <= '1';
      end if;
    else
      if movem_mux(0) = '0' then
        movem_regaddr(0) <= '1';
      end if;
    end if;
  end process;

  o_regin <= regin;
  end;

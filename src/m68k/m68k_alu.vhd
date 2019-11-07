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

entity M68K_ALU is
  port (
    clk               : in  bit1;
    Reset             : in  bit1;
    clkena_lw         : in  bit1 := '1';
    execOPC           : in  bit1;
    exe_condition     : in  bit1;
    exec_tas          : in  bit1;
    long_start        : in  bit1;
    movem_presub      : in  bit1;
    set_stop          : in  bit1;
    Z_error           : in  bit1;
    rot_bits          : in  word( 1 downto 0);
    exec              : in  r_Opc;
    OP1out            : in  word(31 downto 0);
    OP2out            : in  word(31 downto 0);
    reg_QA            : in  word(31 downto 0);
    reg_QB            : in  word(31 downto 0);
    opcode            : in  word(15 downto 0);
    datatype          : in  word( 1 downto 0);
    exe_opcode        : in  word(15 downto 0);
    exe_datatype      : in  word( 1 downto 0);
    sndOPC            : in  word(15 downto 0);
    last_data_read    : in  word(15 downto 0);
    data_read         : in  word(15 downto 0);
    FlagsSR           : in  word( 7 downto 0);
    micro_state       : in  micro_states;
    bf_ext_in         : in  word( 7 downto 0);
    bf_ext_out        : out word( 7 downto 0);
    bf_width          : in  word( 4 downto 0);
    bf_loffset        : in  word( 4 downto 0);
    bf_offset         : in  word(31 downto 0);
    --
    set_V_Flag_out    : out bit1;
    set_Cmp2_Flags_out: out word( 3 downto 0);
    Flags_out         : out word( 7 downto 0);
    alu_c_out         : out word( 2 downto 0);
    addsub_q_out      : out word(31 downto 0);
    ALUout            : out word(31 downto 0)
  );
end;

architecture RTL of M68K_ALU IS
  constant verbose : boolean := true; -- off
  --constant verbose : boolean := false; -- on
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -- ALU and more
  -----------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  signal OP1in              : word(31 downto 0);
  signal addsub_a           : word(31 downto 0);
  signal addsub_b           : word(31 downto 0);
  signal notaddsub_b        : word(33 downto 0);
  signal add_result         : word(33 downto 0);
  signal addsub_ofl         : word( 2 downto 0);
  signal opaddsub           : bit1;
  signal c_in               : word( 3 downto 0);
  signal flag_z             : word( 2 downto 0);
  signal set_flags          : word( 3 downto 0); --NZVC
  signal set_flags_cmp2_l   : word( 3 downto 0); --NZVC
  signal set_flags_cmp2_u   : word( 3 downto 0); --NZVC
  signal set_flags_cmp2     : word( 3 downto 0); -- final
  signal sign_cmp2_l        : bit1;
  signal sign_cmp2_u        : bit1;
  signal sign_cmp2_reg      : bit1;
  signal sign_cmp2_reg_t1   : bit1;
  signal OP2out_cmp2        : word(31 downto 0);
  signal OP2out_cmp2_t1     : word(31 downto 0); -- diag only

  signal CCRin              : word( 7 downto 0);

  signal niba_l             : word(5 downto 0);
  signal niba_h             : word(5 downto 0);
  signal niba_lc            : bit1;
  signal niba_lca           : bit1;
  signal niba_lpt           : bit1;
  signal niba_hc            : bit1;
  signal bcda_lc            : bit1;
  signal bcda_hc            : bit1;
  signal nibs_l             : word(5 downto 0);
  signal nibs_h             : word(5 downto 0);
  signal nibs_lc            : bit1;
  signal nibs_lca           : word(4 downto 0);
  signal nibs_hc            : bit1;

  signal bcd_a              : word(8 downto 0);
  signal bcd_s              : word(8 downto 0);
  signal pack_out           : word(15 downto 0);
  signal pack_a             : word(15 downto 0);
  signal result_mulu        : word(63 downto 0);
  signal result_div         : word(63 downto 0);
  signal set_mV_Flag        : bit1;

  signal rot_rot     : bit1;
  signal rot_lsb     : bit1;
  signal rot_msb     : bit1;
  signal rot_X       : bit1;
  signal rot_C       : bit1;
  signal rot_out     : word(31 downto 0);
  signal asl_VFlag   : bit1;
  signal bit_bits    : word(1 downto 0);
  signal bit_number  : word(4 downto 0);
  signal bits_out    : word(31 downto 0);
  signal one_bit_in  : bit1;
  signal bchg        : bit1;
  signal bset        : bit1;

  signal mulu_sign    : bit1;
  signal mulu_signext : word(16 downto 0);
  signal muls_msb     : bit1;
  signal mulu_reg     : word(63 downto 0);
  signal FAsign       : bit1;
  signal faktorA      : word(31 downto 0);
  signal faktorB      : word(31 downto 0);

  signal div_reg      : word(63 downto 0);
  signal div_quot     : word(63 downto 0);
  signal div_neg      : bit1;
  signal div_bit      : bit1;
  signal div_sub      : word(32 downto 0);
  signal div_over     : word(32 downto 0);
  signal div_V_Flag   : bit1;
  signal flip_V_Flag  : bit1;
  signal nozero       : bit1;
  signal div_qsign    : bit1;
  signal divisor      : word(63 downto 0);
  signal divs         : bit1;
  signal signedOP     : bit1;
  signal OP1_sign     : bit1;
  signal OP2_sign     : bit1;
  signal OP2outext    : word(15 downto 0);

  signal in_offset    : word(5 downto 0);
  signal datareg      : word(31 downto 0);
  signal insert       : word(31 downto 0);
  signal bf_datareg   : word(31 downto 0);
  signal result       : word(39 downto 0);
  signal result_tmp   : word(39 downto 0);
  signal sign         : word(31 downto 0);
  signal bf_loff_dir  : word(4 downto 0);
  signal bf_set2      : word(39 downto 0);
  signal copy         : word(39 downto 0);

  signal bf_firstbit  : word(5 downto 0);
  signal bf_bset      : bit1;
  signal bf_NFlag     : bit1;
  signal bf_bchg      : bit1;
  signal bf_ins       : bit1;
  signal bf_exts      : bit1;
  signal bf_extu      : bit1;
  signal bf_fffo      : bit1;
  signal bf_d32       : bit1;
  signal index        : word(4 downto 0);
  signal bf_flag_z    : bit1;
  signal bf_flag_n    : bit1;
  signal set_V_Flag   : bit1;
  signal Flags        : word(7 downto 0);
  signal c_out        : word(2 downto 0);
  signal addsub_q     : word(31 downto 0);

begin
  -----------------------------------------------------------------------------
  -- set OP1in
  -----------------------------------------------------------------------------
  process (OP2out, reg_QB, opcode, OP1out, OP1in, exe_datatype, addsub_q, execOPC, exec,
       pack_out, bcd_a, bcd_s, mulu_reg, result_div, exe_condition, bf_offset, bf_width,
       Flags, FlagsSR, bits_out, exec_tas, rot_out, exe_opcode, result, bf_fffo, bf_firstbit, bf_datareg)
  begin
    ALUout <= OP1in;
    ALUout(7) <= OP1in(7) OR exec_tas;
    if exec.opcBFwb= '1' then
      ALUout <= result(31 downto 0);
      if bf_fffo = '1' then
        ALUout <= bf_offset + bf_width + 1 - bf_firstbit;
      end if;
    end if;

    OP1in <= addsub_q;
    if exec.opcABCD= '1' then
      OP1in(7 downto 0) <= bcd_a(7 downto 0);
    elsif exec.opcSBCD= '1' then
      OP1in(7 downto 0) <= bcd_s(7 downto 0);
    elsif exec.opcMULU= '1' then
      if exec.write_lowlong= '1' then
      OP1in <= mulu_reg(31 downto 0);
      else
      OP1in <= mulu_reg(63 downto 32);
      end if;
    elsif exec.opcDIVU= '1' then
      if exe_opcode(15) = '1' then
      OP1in <= result_div(47 downto 32) & result_div(15 downto 0);
      else --64bit
      if exec.write_reminder = '1' then
        OP1in <= result_div(63 downto 32);
      else
        OP1in <= result_div(31 downto 0);
      end if;
      end if;
    elsif exec.opcOR= '1' then
      OP1in <= OP2out OR OP1out;
    elsif exec.opcand= '1' then
      OP1in <= OP2out and OP1out;
    elsif exec.opcScc= '1' then
      OP1in(7 downto 0) <= (others => exe_condition);
    elsif exec.opcEOR= '1' then
      OP1in <= OP2out xor OP1out;
    elsif exec.opcMOVE= '1' OR exec.exg= '1' then
      -- OP1in <= OP2out(31 downto 8)&(OP2out(7)OR exec_tas)&OP2out(6 downto 0);
      OP1in <= OP2out;
    elsif exec.opcROT= '1' then
      OP1in <= rot_out;
    elsif exec.opcSWAP= '1' then
      OP1in <= OP1out(15 downto 0) & OP1out(31 downto 16);
    elsif exec.opcBITS= '1' then
      OP1in <= bits_out;
    elsif exec.opcBF= '1' then
      OP1in <= bf_datareg;
    elsif exec.opcMOVECCR= '1' then
      OP1in(15 downto 8) <= "00000000";
      OP1in( 7 downto 0) <= Flags;
    elsif exec.opcMOVESR= '1' then
      OP1in(15 downto 8) <= FlagsSR;
      OP1in( 7 downto 0) <= Flags;
      -- possible byte move fix
      --IF exe_datatype="00" THEN
      --OP1in(15 downto 8) <= "00000000";

    elsif exec.opcPACK= '1' then
      OP1in(15 downto 0) <= pack_out;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- addsub
  -----------------------------------------------------------------------------
  process (OP1out, OP2out, execOPC, datatype, Flags, long_start, movem_presub, exe_datatype, exec, addsub_a, addsub_b, opaddsub,
           notaddsub_b, add_result, c_in, sndOPC, micro_state)
  variable cas2 : bit1;
  begin
    -- override bodge. This may be a better way of doing cmp2 as well
    cas2 := '0';
    if (micro_state = cas2_3 or micro_state = cas2_5) then
      cas2 := '1';
    end if;

    addsub_a <= OP1out;
    if exec.get_bfoffset= '1' then
      if sndOPC(11) = '1' then
      addsub_a <= OP1out(31) & OP1out(31) & OP1out(31) & OP1out(31 downto 3);
      else
      addsub_a <= "000000000000000000000000000000" & sndOPC(10 downto 9);
      end if;
    end if;

    if exec.subidx= '1' then
      opaddsub <= '1';
    else
      opaddsub <= '0';
    end if;

    c_in(0) <= '0';
    addsub_b <= OP2out;
    if execOPC = '0' and exec.OP2out_one= '0' and exec.get_bfoffset= '0' and cas2 = '0' then
      if long_start = '0' and datatype = "00" and exec.use_SP= '0' then
      addsub_b <= "00000000000000000000000000000001";
      elsif long_start = '0' and exe_datatype = "10" and (exec.presub OR exec.postadd OR movem_presub) = '1' then
      if exec.movem_action= '1' then -- used for initial offset / aligned case
        addsub_b <= "00000000000000000000000000000110";
      else
        addsub_b <= "00000000000000000000000000000100";
      end if;
      else
      addsub_b <= "00000000000000000000000000000010";
      end if;
    else
      if (exec.use_XZFlag= '1' and Flags(4) = '1') OR exec.opcCHK= '1' then
      c_in(0) <= '1';
      end if;
      opaddsub <= exec.addsub;
    end if;

    if opaddsub = '0' OR long_start = '1' then --ADD
      notaddsub_b <= '0' & addsub_b & c_in(0);
    else --SUB
      notaddsub_b <= not ('0' & addsub_b & c_in(0));
    end if;
    add_result <= (('0' & addsub_a & notaddsub_b(0)) + notaddsub_b);

    c_in(1) <= add_result( 9) xor addsub_a( 8) xor addsub_b( 8);
    c_in(2) <= add_result(17) xor addsub_a(16) xor addsub_b(16);
    c_in(3) <= add_result(33);

    addsub_q <= add_result(32 downto 1);
    addsub_ofl(0) <= (c_in(1) xor add_result( 8) xor addsub_a( 7) xor addsub_b( 7)); --V Byte
    addsub_ofl(1) <= (c_in(2) xor add_result(16) xor addsub_a(15) xor addsub_b(15)); --V Word
    addsub_ofl(2) <= (c_in(3) xor add_result(32) xor addsub_a(31) xor addsub_b(31)); --V Long
    c_out <= c_in(3 downto 1);
  end process;

  ------------------------------------------------------------------------------
  --ALU
  ------------------------------------------------------------------------------
  process (exe_opcode, OP1out, OP2out, pack_a,  niba_l, niba_lpt, niba_hc, niba_h, niba_lc, niba_lca, nibs_hc, nibs_h, nibs_l, nibs_lc, nibs_lca, Flags)
  begin
    if exe_opcode(7 downto 6) = "01" then
      -- PACK
      pack_a <= std_logic_vector(unsigned(OP1out(15 downto 0)) + unsigned(OP2out(15 downto 0)));
      pack_out <= "00000000" & pack_a(11 downto 8) & pack_a(3 downto 0);
    else
      -- UNPK
      pack_a <= "0000" & OP2out(7 downto 4) & "0000" & OP2out(3 downto 0);
      pack_out <= std_logic_vector(unsigned(OP1out(15 downto 0)) + unsigned(pack_a));
    end if;

    --BCD_ARITH-------------------------------------------------------------------
    --ABCD
    bcd_a    <= niba_hc & (niba_h(4 downto 1) + ('0', niba_hc, niba_hc, niba_lca)) & (niba_l(4 downto 1) + ('0', niba_lc, niba_lc, '0'));
    niba_l   <= ('0' & OP1out(3 downto 0) & '1') + ('0' & OP2out(3 downto 0) & Flags(4));
    niba_lpt <= (niba_l(4) and niba_l(3)) OR (niba_l(4) and niba_l(2));
    niba_lc  <= niba_l(5) OR niba_lpt;
    niba_lca <= niba_l(5) and niba_lpt;

    niba_h   <= ('0' & OP1out(7 downto 4) & '1') + ('0' & OP2out(7 downto 4) & niba_lc);
    niba_hc  <= niba_h(5) OR (niba_h(4) and niba_h(3)) OR (niba_h(4) and niba_h(2));

    --SBCD
    bcd_s    <= nibs_hc & (nibs_h(4 downto 1) - ('0', nibs_hc, nibs_hc, nibs_lca(4))) & nibs_lca(3 downto 0);
    nibs_l   <= ('0' & OP1out(3 downto 0) & '0') - ('0' & OP2out(3 downto 0) & Flags(4));
    nibs_lc  <= nibs_l(5);
    nibs_lca <= '0' & nibs_l(4 downto 1) - ('0', '0', nibs_lc, nibs_lc, '0');

    nibs_h   <= ('0' & OP1out(7 downto 4) & '0') - ('0' & OP2out(7 downto 4) & nibs_lc);
    nibs_hc  <= nibs_h(5);
  end process;

  -----------------------------------------------------------------------------
  -- Bits
  -----------------------------------------------------------------------------
  process (clk, exe_opcode, OP1out, OP2out, one_bit_in, bchg, bset, bit_Number, sndOPC, reg_QB)
  begin
    if rising_edge(clk) then
      if clkena_lw = '1' then
      bchg <= '0';
      bset <= '0';
      case opcode(7 downto 6) IS
        when "01" => --bchg
        bchg <= '1';
        when "11" => --bset
        bset <= '1';
        when others => NULL;
      end case;
      end if;
    end if;

    if exe_opcode(8) = '0' then
      if exe_opcode(5 downto 4) = "00" then
      bit_number <= sndOPC(4 downto 0);
      else
      bit_number <= "00" & sndOPC(2 downto 0);
      end if;
    else
      if exe_opcode(5 downto 4) = "00" then
      bit_number <= reg_QB(4 downto 0);
      else
      bit_number <= "00" & reg_QB(2 downto 0);
      end if;
    end if;

    one_bit_in <= OP1out(to_integer(unsigned(bit_Number)));
    bits_out <= OP1out;
    bits_out(to_integer(unsigned(bit_Number))) <= (bchg and not one_bit_in) OR bset;
  end process;

  -----------------------------------------------------------------------------
  -- Bit Field
  -----------------------------------------------------------------------------
  -- Bitfields can have up to four (register) operands, e.g. bfins d0,d1{d2,d3}
  -- the width an offset operands are evaluated while the second opcode word is
  -- evaluated. These values are latched, so the two other registers can be read
  -- in the next cycle while the ALU is working since the tg68k can only read
  -- from two registers at once.
  --
  -- All bitfield operations can operate on registers or memory. There are
  -- two fundamental differences which make the shifters quite complex:
  -- 1. Memory content is delivered byte aligned to the ALU. Thus all shifting
  --    is 7 bits far at most. Registers are 32 bit in size and may require
  --    shifting of up to 31 bit positions
  -- 2. Memory operations can affect 5 bytes. Thus all shifting is 40 bit in that
  --    case. Registers are 32 bit in size and bitfield operations wrap. Shifts
  --    are actually rotations for that reason
  --
  -- The destination operand is transfered via op1out and bf_ext into the ALU.
  --
  -- bftst, bfset, bfclr and bfchg
  --------------------------------
  -- bftst, bfset, bfclr and bfchg work very similar. A "sign" vector is generated
  -- having "width" right aligned 0-bits and the rest ones.
  -- A "copy" vector is generated from this by shifting through copymux so
  -- this contains a 1 for all bits in bf_ext_in & op1out that will not be
  -- affected by the operation.
  -- The result vector is either all 1's (bfset), all 0's(bfclr) or the inverse
  -- of bf_ext_in & op1out. Those bits in result that have a 1 in the copy
  -- vector are overwritten with the original value from bf_ext_in & op1out
  -- The result is returned through bf_ext_out and ALUout
  --
  -- These instructions only calculate the Z and N flags. Both are derived
  -- directly from bf_ext_in & op1out with the help of the copy vector and
  -- the offset/width fields. Thus Z and N are set from the previous contents
  -- of the bitfield.
  --
  -- bfins
  --------
  -- bfins reuses most of the functionality of bfset, bfclr and bfchg. But it
  -- has another 32 bit parameter that's being used for the source. This is passed
  -- to the ALU via op2out. This is moved to the shift register and shifted
  -- bf_shift bits to the right.
  -- The input valus is also store in datareg and the lowest "width" bits
  -- are masked. This is then forwarded to op1in which in turn uses the normal
  -- mechanisms to generate the flags. A special bf_NFlag is also generated
  -- from this. Z and N are set from these and not from the previous bitfield
  -- contents as with bfset, bfclr or bfchg
  --
  -- bfextu/bfexts
  ----------------
  -- bfexts and bfextu use the same shifter that is used by bfins to shift the
  -- data to be inserted. It's using that same shifter to shift data in the
  -- opposite direction. Flags are set from the extraced data
  --
  -- bfffo
  --------
  -- bfffo uses the same data path as bfext. But instead of directly returning
  -- the extracted data it determines the highest bit setin the result
  process (clk, bf_ins, bf_bchg, bf_bset, bf_exts, bf_extu, bf_set2, OP1out, OP2out, result_tmp, bf_ext_in,
       datareg, bf_NFlag, result, reg_QB, sign, bf_d32, copy, bf_loffset, bf_width, bf_loff_dir, exe_opcode)
  begin
    if rising_edge(clk) then
      if clkena_lw = '1' then
      bf_bset <= '0';
      bf_bchg <= '0';
      bf_ins  <= '0';
      bf_exts <= '0';
      bf_extu <= '0';
      bf_fffo <= '0';
      bf_d32  <= '0';

      case opcode(10 downto 8) is
        when "010" => bf_bchg <= '1'; --BFCHG
        when "011" => bf_exts <= '1'; --BFEXTS
        when "001" => bf_extu <= '1'; --BFEXTU
      -- when "100" => insert <= (others =>'0'); --BFCLR
        when "101" => bf_fffo <= '1'; --BFFFO
        when "110" => bf_bset <= '1'; --BFSET
        when "111" => bf_ins  <= '1'; --BFinS
        when others => NULL;
      end case;

          -- ea is a register
      if opcode(4 downto 3) = "00" then
        bf_d32 <= '1';
      end if;

      bf_ext_out <= result(39 downto 32);
      end if;
    end if;

      ------------- BF_SET2 --------------
      if bf_ins = '1' then
        bf_loff_dir <= 32 - bf_loffset;
      else
        bf_loff_dir <= bf_loffset;
      end if;

      if bf_d32 = '1' then
        -- 32bit: rotate 0..31 bits left or right, don't care for upper 8 bits
        bf_set2 <= "--------" & word(unsigned(OP2out) ror to_integer(unsigned(bf_loff_dir)));
      else
        if bf_ins = '1' then
        -- 40 bit: shift 0..7 bits left
        bf_set2 <= word(unsigned(bf_ext_in & OP2out) sll to_integer(unsigned(bf_loffset(2 downto 0))));
        else
        -- 40 bit: shift 0..7 bits right
        bf_set2 <= word(unsigned(bf_ext_in & OP2out) srl to_integer(unsigned(bf_loffset(2 downto 0))));
        end if;
      end if;

      ------------- COPY --------------
      if bf_d32 = '1' then
        -- 32bit: rotate 32 bits 0..31 bits left, don't care for upper 8 bits
        copy <= "--------" & word(unsigned(sign) rol to_integer(unsigned(bf_loffset)));
      else
        -- 40 bit: shift 40 bits 0..7 bits left, fill with '1's (hence the two not's)
        copy <= not word(unsigned(x"00" & (not sign)) sll to_integer(unsigned(bf_loffset(2 downto 0))));
      end if;

    if bf_ins = '1' then
      datareg <= reg_QB;
    else
      datareg <= bf_set2(31 downto 0);
    end if;

      -- do the bitfield operation itself
    if bf_ins = '1' then
      result <= bf_set2;
    elsif bf_bchg = '1' then
      result <= not (bf_ext_in & OP1out);
    elsif bf_bset = '1' then
      result <= (others => '1');
    else
      result <= (others => '0');
    end if;

    sign <= (others => '0');
    bf_NFlag <= datareg(to_integer(unsigned(bf_width)));
    for i in 0 TO 31 loop
      if i > bf_width then
      datareg(i) <= '0';
      sign(i) <= '1';
      end if;
    end loop;

    -- Set bits 32..39 to 0 if operating on register to make sure
    -- zero flag calculation over all 40 bits works correctly

    result_tmp(31 downto 0) <= OP1out;

    if bf_d32 = '1' then
      result_tmp(39 downto 32) <= "00000000";
    else
      result_tmp(39 downto 32) <= bf_ext_in;
    end if;

    bf_flag_z <= '1';
    if bf_d32 = '0' then
      -- The test for this overflow shouldn't be needed. But GHDL complains
      -- otherwise.
      if(to_integer(unsigned('0' & bf_loffset)+unsigned(bf_width)) > 39) then
      bf_flag_n <= result_tmp(39);
      else
      bf_flag_n <= result_tmp(to_integer(unsigned('0' & bf_loffset)+unsigned(bf_width)));
      end if;
    else
      --TH: TODO: check if this really does what it's supposed to
      bf_flag_n <= result_tmp(to_integer(unsigned(bf_loffset)+unsigned(bf_width)));
    end if;
    for i in 0 TO 39 loop
      if copy(i) = '1' then
      result(i) <= result_tmp(i);
      elsif result_tmp(i) = '1' then
      bf_flag_z <= '0';
      end if;
    end loop;

    if bf_exts = '1' and bf_NFlag = '1' then
      bf_datareg <= datareg OR sign;
    else
      bf_datareg <= datareg;
    end if;

    --BFFFO
    if    datareg(31) = '1' then bf_firstbit <= "100000";
    elsif datareg(30) = '1' then bf_firstbit <= "011111";
    elsif datareg(29) = '1' then bf_firstbit <= "011110";
    elsif datareg(28) = '1' then bf_firstbit <= "011101";
    elsif datareg(27) = '1' then bf_firstbit <= "011100";
    elsif datareg(26) = '1' then bf_firstbit <= "011011";
    elsif datareg(25) = '1' then bf_firstbit <= "011010";
    elsif datareg(24) = '1' then bf_firstbit <= "011001";
    elsif datareg(23) = '1' then bf_firstbit <= "011000";
    elsif datareg(22) = '1' then bf_firstbit <= "010111";
    elsif datareg(21) = '1' then bf_firstbit <= "010110";
    elsif datareg(20) = '1' then bf_firstbit <= "010101";
    elsif datareg(19) = '1' then bf_firstbit <= "010100";
    elsif datareg(18) = '1' then bf_firstbit <= "010011";
    elsif datareg(17) = '1' then bf_firstbit <= "010010";
    elsif datareg(16) = '1' then bf_firstbit <= "010001";
    elsif datareg(15) = '1' then bf_firstbit <= "010000";
    elsif datareg(14) = '1' then bf_firstbit <= "001111";
    elsif datareg(13) = '1' then bf_firstbit <= "001110";
    elsif datareg(12) = '1' then bf_firstbit <= "001101";
    elsif datareg(11) = '1' then bf_firstbit <= "001100";
    elsif datareg(10) = '1' then bf_firstbit <= "001011";
    elsif datareg(9)  = '1' then bf_firstbit <= "001010";
    elsif datareg(8)  = '1' then bf_firstbit <= "001001";
    elsif datareg(7)  = '1' then bf_firstbit <= "001000";
    elsif datareg(6)  = '1' then bf_firstbit <= "000111";
    elsif datareg(5)  = '1' then bf_firstbit <= "000110";
    elsif datareg(4)  = '1' then bf_firstbit <= "000101";
    elsif datareg(3)  = '1' then bf_firstbit <= "000100";
    elsif datareg(2)  = '1' then bf_firstbit <= "000011";
    elsif datareg(1)  = '1' then bf_firstbit <= "000010";
    elsif datareg(0)  = '1' then bf_firstbit <= "000001";
    else                         bf_firstbit <= "000000";
    end if;

  end process;

  -----------------------------------------------------------------------------
  -- Rotation
  -----------------------------------------------------------------------------
  process (exe_opcode, OP1out, Flags, rot_bits, rot_msb, rot_lsb, rot_out, rot_rot, exec)
  begin
    case exe_opcode(7 downto 6) IS
      when "00" => --Byte
      rot_rot <= OP1out(7);
      when "01" | "11" => --Word
      rot_rot <= OP1out(15);
      when "10" => --Long
      rot_rot <= OP1out(31);
      when others => NULL;
    end case;

    case rot_bits IS
      when "00" => --ASL, ASR
      rot_lsb <= '0';
      rot_msb <= rot_rot;
      when "01" => --LSL, LSR
      rot_lsb <= '0';
      rot_msb <= '0';
      when "10" => --ROXL, ROXR
      rot_lsb <= Flags(4);
      rot_msb <= Flags(4);
      when "11" => --ROL, ROR
      rot_lsb <= rot_rot;
      rot_msb <= OP1out(0);
      when others => NULL;
    end case;

    if exec.rot_nop = '1' then
      rot_out <= OP1out;
      rot_X <= Flags(4);
      if rot_bits = "10" then --ROXL, ROXR
      rot_C <= Flags(4);
      else
      rot_C <= '0';
      end if;
    else
      if exe_opcode(8) = '1' then --left
      rot_out <= OP1out(30 downto 0) & rot_lsb;
      rot_X <= rot_rot;
      rot_C <= rot_rot;
      else --right
      rot_X <= OP1out(0);
      rot_C <= OP1out(0);
      rot_out <= rot_msb & OP1out(31 downto 1);
      case exe_opcode(7 downto 6) IS
        when "00" => --Byte
        rot_out(7) <= rot_msb;
        when "01" | "11" => --Word
        rot_out(15) <= rot_msb;
        when others => NULL;
      end case;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------
  --CCR op
  ------------------------------------------------------------------------------
  process (clk, Reset, exe_opcode, exe_datatype, Flags, last_data_read, OP2out, flag_z, OP1in, c_out, addsub_ofl,
    bcd_s, bcd_a, exec)

  begin
    if exec.andiSR = '1' then
      CCRin <= Flags and last_data_read(7 downto 0);
    elsif exec.eoriSR = '1' then
      CCRin <= Flags xor last_data_read(7 downto 0);
    elsif exec.oriSR = '1' then
      CCRin <= Flags OR last_data_read(7 downto 0);
    else
      CCRin <= OP2out(7 downto 0);
    end if;

    ------------------------------------------------------------------------------
    --Flags
    ------------------------------------------------------------------------------
    flag_z <= "000";
    if exec.use_XZFlag = '1' and flags(2) = '0' then
      flag_z <= "000";
    elsif OP1in(7 downto 0) = "00000000" then
      flag_z(0) <= '1';
      if OP1in(15 downto 8) = "00000000" then
      flag_z(1) <= '1';
      if OP1in(31 downto 16) = "0000000000000000" then
        flag_z(2) <= '1';
      end if;
      end if;
    end if;

    -- --Flags NZVC
    if exe_datatype = "00" then --Byte
      set_flags <= OP1in(7) & flag_z(0) & addsub_ofl(0) & c_out(0);
      if exec.opcABCD = '1' then
      set_flags(0) <= bcd_a(8);
      set_flags(1) <= '0';
      elsif exec.opcSBCD = '1' then
      set_flags(0) <= bcd_s(8);
      set_flags(1) <= '0';
      end if;
    elsif exe_datatype = "10" OR exec.opcCPMAW = '1' then --Long
      set_flags <= OP1in(31) & flag_z(2) & addsub_ofl(2) & c_out(2);
    else --Word
      set_flags <= OP1in(15) & flag_z(1) & addsub_ofl(1) & c_out(1);
    end if;

    if rising_edge(clk) then
      if clkena_lw = '1' then
      if exec.directSR = '1' OR set_stop = '1' then
        Flags(7 downto 0) <= data_read(7 downto 0);
      end if;
      if exec.directCCR = '1' then
        Flags(7 downto 0) <= data_read(7 downto 0);
      end if;

      if exec.opcROT = '1' then
        asl_VFlag <= ((set_flags(3) xor rot_rot) OR asl_VFlag);
      else
        asl_VFlag <= '0';
      end if;
      if exec.to_CCR = '1' then
        Flags(7 downto 0) <= CCRin(7 downto 0); --CCR
      elsif Z_error = '1' then
        if exe_opcode(8) = '0' then
        Flags(3 downto 0) <= reg_QA(31) & "000";
        else
        Flags(3 downto 0) <= "0100";
        end if;
      elsif exec.no_Flags = '0' then
        if exec.opcADD = '1' then
        Flags(4) <= set_flags(0);
        elsif exec.opcROT = '1' and rot_bits /= "11" and exec.rot_nop = '0' then
        Flags(4) <= rot_X;
        end if;

        if (exec.opcADD OR exec.opcCMP) = '1' then
        Flags(3 downto 0) <= set_flags;
        elsif (micro_state = cas2_3) then
        Flags(3 downto 0) <= set_flags;
        elsif (micro_state = cas2_5) then
        -- we need to combine flags here a bit better
        Flags(3 downto 0) <= Flags(3 downto 0) and set_flags(3 downto 0);
        Flags(3) <= '0'; -- bodge
        Flags(0) <= '0'; -- bodge
        elsif exec.opcCAS = '1' then
        -- not correct
        Flags(3 downto 0) <= '0' & set_flags_cmp2(2) & "00"; -- ??

        elsif exec.opcDIVU = '1' then
        if div_V_Flag = '1' then
          Flags(3 downto 0) <= "1110";
        else
          if flip_V_Flag = '1' then --this corner case is odd, investigate, it's a +ve/-ve long div which gives -ve result 0x80000000
          Flags(3 downto 0) <= not OP1in(15) & not flag_z(1) & "00";
          else
          Flags(3 downto 0) <= OP1in(15) & flag_z(1) & "00";
          end if;

        end if;
        elsif exec.write_reminder = '1' then -- z-flag MULU.l
        Flags(3) <= set_flags(3);
        Flags(2) <= set_flags(2) and Flags(2);
        Flags(1) <= '0';
        Flags(0) <= '0';
        elsif exec.write_lowlong = '1' then -- flag MULU.l
        Flags(3) <= set_flags(3);
        Flags(2) <= set_flags(2);
        Flags(1) <= set_mV_Flag; --V
        Flags(0) <= '0';
        elsif exec.opcOR = '1' OR exec.opcand = '1' OR exec.opcEOR = '1' OR exec.opcMOVE = '1' OR exec.opcMOVEQ = '1' OR exec.opcSWAP = '1' OR exec.opcBF = '1' or exec.opcMULU = '1' then
        Flags(1 downto 0) <= "00";
        Flags(3 downto 2) <= set_flags(3 downto 2);
        if exec.opcBF = '1' then
          -- flags(2) has correctly been set from set_flags
          Flags(3) <= bf_NFlag;
          -- "normal" flags are taken from op2in
          if bf_fffo = '0' and bf_extu='0' and bf_exts='0' and bf_ins='0' then
          Flags(2) <= bf_flag_z;
          Flags(3) <= bf_flag_n;
          end if;
        end if;
        elsif exec.opcROT = '1' then
        Flags(3 downto 2) <= set_flags(3 downto 2);
        Flags(0) <= rot_C;
        if rot_bits = "00" and ((set_flags(3) xor rot_rot) OR asl_VFlag) = '1' then --ASL/ASR
          Flags(1) <= '1';
        else
          Flags(1) <= '0';
        end if;
        elsif exec.opcBITS = '1' then
        Flags(2) <= not one_bit_in;
        elsif exec.opcCHK = '1' then
        -- note, should only set N, Z is undefined
        -- N is set if D < 0, cleared if D > ea
        -- OP1out = reg, OP2out = EA
        if exe_datatype = "01" then --Word
          Flags(3) <= OP1out(15);
        else
          Flags(3) <= OP1out(31);
        end if;
        -- VV potentially not required (Z)
        if OP1out(15 downto 0) = X"0000" and (exe_datatype = "01" or OP1out(31 downto 16) = X"0000") then
          Flags(2) <= '1';
        else
          Flags(2) <= '0';
        end if;
        Flags(1 downto 0) <= "00";

        elsif exec.opcCHK2 = '1' then
        --
        -- CHK2
        --
        -- sign_cmp2_l lb
        -- sign_cmp2_u ub
        --assert verbose report "ALU exec opcCHK2 (upper bound)." & lf &
                  --" OP2out_l (ea ) : " & to_hstring(OP2out_cmp2_t1) & lf &
                  --" OP1out  (reg)  : " & to_hstring(OP1out) & lf &
                  ----"   sign         : " &  std_logic'image(sign_cmp2_reg_t1) & lf &
                  --" OP2out_u (ea ) : " & to_hstring(OP2out_cmp2) & lf &
                  --" exe_datatype : " & to_hstring(exe_datatype) & lf  &

                  --" L [ Z : " & std_logic'image(set_flags_cmp2_l(2)) &
                    --", C : " & std_logic'image(set_flags_cmp2_l(0)) & " ] sign " & std_logic'image(sign_cmp2_l) & lf &

                  --" U [ Z : " & std_logic'image(set_flags_cmp2_u(2)) &
                    --", C : " & std_logic'image(set_flags_cmp2_u(0)) & " ] sign " & std_logic'image(sign_cmp2_u)
                  --severity note;

        --chk only allows Dx. Chk2 can be A or D
        -- if A reg used, and operation size is byte or word, sign extend bounds to 32 bit and compare all against A
        -- if signed values then lower bound should be smaller
        Flags(2) <= set_flags_cmp2(2); -- Z
        Flags(0) <= set_flags_cmp2(0); -- C
        end if;
      end if;
      end if;
      Flags(7 downto 5) <= "000";
    end if;
  end process;

  -- for cas op1out is ea data, op2out is dc
  process (OP1out, OP2out, exe_datatype, sndOPC, OP2out_cmp2, micro_state)
  -- we needed an extra adder to do the cmp2 (the other one is busy doing EA, so I've used it for both bounds checks to ease timing
  -- It's also easier to use for cas/cas2 as execOPC is not set for the first compare

    variable cmp2_aext               : bit1;
    variable cmp2_c_in               : word( 3 downto 0);
    variable cmp2_addsub_a           : word(31 downto 0);
    variable cmp2_addsub_b           : word(31 downto 0);
    variable cmp2_notaddsub_b        : word(33 downto 0);
    variable cmp2_add_result         : word(33 downto 0);
    variable cmp2_c_out              : word( 2 downto 0);

    variable cmp2_z_in               : word(31 downto 0);
    variable cmp2_z                  : word( 2 downto 0);
  begin

    cmp2_aext := '0';
    if micro_state = upperbound or micro_state = upperbound2 then
      cmp2_aext := sndOPC(15); -- address extend
    end if;

    OP2out_cmp2 <= OP2out;
    if (cmp2_aext = '1') then
      if (exe_datatype = "00") then -- byte
      OP2out_cmp2(31 downto 8) <= (others => OP2out(7));
      end if;
      if (exe_datatype = "01") then -- word
      OP2out_cmp2(31 downto 16) <= (others => OP2out(15));
      end if;
    end if;

    cmp2_c_in(0) := '0';
    cmp2_addsub_a := OP1out;
    cmp2_addsub_b := OP2out_cmp2;

    cmp2_notaddsub_b := not ('0' & cmp2_addsub_b & cmp2_c_in(0));
    cmp2_add_result  := (('0' & cmp2_addsub_a & cmp2_notaddsub_b(0)) + cmp2_notaddsub_b);

    cmp2_c_in(1) := cmp2_add_result( 9) xor cmp2_addsub_a( 8) xor cmp2_addsub_b( 8);
    cmp2_c_in(2) := cmp2_add_result(17) xor cmp2_addsub_a(16) xor cmp2_addsub_b(16);
    cmp2_c_in(3) := cmp2_add_result(33);

    cmp2_c_out := cmp2_c_in(3 downto 1);

    cmp2_z_in := cmp2_add_result(32 downto 1);

    cmp2_z := "000";
    if cmp2_z_in(7 downto 0) = "00000000" then
      cmp2_z(0) := '1';
      if cmp2_z_in(15 downto 8) = "00000000" then
      cmp2_z(1) := '1';
        if cmp2_z_in(31 downto 16) = "0000000000000000" then
        cmp2_z(2) := '1';
        end if;
      end if;
    end if;

    if exe_datatype = "10" or cmp2_aext = '1' then --Long or addr
      sign_cmp2_u   <= OP2out_cmp2(31);
      sign_cmp2_reg <= OP1out(31);
      set_flags_cmp2_u <= '0' & cmp2_z(2) & '0' & cmp2_c_out(2);
    elsif exe_datatype = "00" then --Byte
      sign_cmp2_u   <= OP2out_cmp2(7);
      sign_cmp2_reg <= OP1out(7);
      set_flags_cmp2_u <= '0' & cmp2_z(0) & '0' & cmp2_c_out(0);
    else --Word
      sign_cmp2_u   <= OP2out_cmp2(15);
      sign_cmp2_reg <= OP1out(15);
      set_flags_cmp2_u <= '0' & cmp2_z(1) & '0' & cmp2_c_out(1);
    end if;
    -- this is the "live" version, used for upper bound
  end process;

  process (clk)
  begin
    -- registered, so lower bound
    if rising_edge(clk) then
      if clkena_lw = '1' then
      sign_cmp2_l <= sign_cmp2_u;
      sign_cmp2_reg_t1 <= sign_cmp2_reg; -- static but good for timing
      set_flags_cmp2_l <= set_flags_cmp2_u;
      OP2out_cmp2_t1 <= OP2out_cmp2;
      end if;
    end if;
  end process;

  -- calc flags for cmp2/chk2, we need them early to decide to trap or not for chk2
  process (set_flags_cmp2_l, set_flags_cmp2_u, sign_cmp2_l, sign_cmp2_u, sign_cmp2_reg_t1)
  begin
    -- NZVC
    -- not used
    set_flags_cmp2(3) <= '0';
    set_flags_cmp2(1) <= '0';
    --
    set_flags_cmp2(2) <= '0'; -- Z
    if (set_flags_cmp2_l(2) = '1') then -- Z
      assert verbose report "=LB, Z set " severity note;
      set_flags_cmp2(2) <= '1'; -- Z
    end if;

    if (set_flags_cmp2_u(2) = '1') then
      set_flags_cmp2(2) <= '1';
      assert verbose report "=UB, Z set " severity note;
    end if;

    if (sign_cmp2_l = '1' and sign_cmp2_u = '0') then
      --assert false report "**** -ve LB, +ve UB **** " severity note;
      -- C set if out of bounds/ cleared otherwise
      set_flags_cmp2(0) <= '0';  -- c
      if ((set_flags_cmp2_l(0) xor sign_cmp2_l xor sign_cmp2_reg_t1) = '1') then
      if (set_flags_cmp2_l(2) = '0') then
        assert verbose report "** LB OOB **" severity note;
        set_flags_cmp2(0) <= '1';  -- c
      end if;
      end if;

      if ((set_flags_cmp2_u(0) xor sign_cmp2_u xor sign_cmp2_reg_t1) = '0') then
      if (set_flags_cmp2_u(2) = '0') then
        assert verbose report "** UB OOB **" severity note;
        set_flags_cmp2(0) <= '1';  -- c
      end if;
      end if;
    else
      -- C set if out of bounds/ cleared otherwise
      set_flags_cmp2(0) <= '0';  -- c
      if (set_flags_cmp2_l(0) = '1') then
      if (set_flags_cmp2_l(2) = '0') then
        assert verbose report "** LB OOB **" severity note;
        set_flags_cmp2(0) <= '1';  -- c
      end if;
      end if;

      if (set_flags_cmp2_u(0) = '0') then
      if (set_flags_cmp2_u(2) = '0') then
        assert verbose report "** UB OOB **" severity note;
        set_flags_cmp2(0) <= '1';  -- c
      end if;
      end if;
    end if;
  end process;

  -------------------------------------------------------------------------------
  ---- MULU/MULS
  -------------------------------------------------------------------------------
  process (exe_opcode, OP2out, muls_msb, mulu_reg, FAsign, mulu_sign, reg_QA, faktorB, result_mulu, signedOP, micro_state)
  begin
    if (signedOP = '1' and faktorB(31) = '1') OR FAsign = '1' then
      muls_msb <= mulu_reg(63);
    else
      muls_msb <= '0';
    end if;

    if signedOP = '1' and faktorB(31) = '1' then
      mulu_sign <= '1';
    else
      mulu_sign <= '0';
    end if;

    result_mulu <= muls_msb & mulu_reg(63 downto 1);
    if mulu_reg(0) = '1' then
      if FAsign = '1' then
      result_mulu(63 downto 31) <= (muls_msb & mulu_reg(63 downto 32) - (mulu_sign & faktorB));
      else
      result_mulu(63 downto 31) <= (muls_msb & mulu_reg(63 downto 32) + (mulu_sign & faktorB));
      end if;
    end if;

    -- temp fix. Write of 64 bit result causes glitch to OP2out during the first write, and we are not finished yet
    -- long combinatorial path
    if exe_opcode(15) = '1' then
      faktorB(31 downto 16) <= OP2out(15 downto 0);
      faktorB(15 downto  0) <= (others => '0');
    else
      faktorB <= OP2out;
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if clkena_lw = '1' then
        -- moved one later
        if (result_mulu(63 downto 32) = X"00000000" and (signedOP = '0' or  result_mulu(31) = '0')) or
          (result_mulu(63 downto 32) = X"FFFFFFFF" and  signedOP = '1' and result_mulu(31) = '1')  then
          set_mV_Flag <= '0';
        else
          set_mV_Flag <= '1';
        end if;

        if micro_state = mul1 then

          mulu_reg(63 downto 32) <= (others => '0');
          if divs = '1' and ((exe_opcode(15) = '1' and reg_QA(15) = '1') OR (exe_opcode(15) = '0' and reg_QA(31) = '1')) then --MULS Neg faktor
          FAsign <= '1';
          mulu_reg(31 downto 0) <= 0 - reg_QA;
          else
          FAsign <= '0';
          mulu_reg(31 downto 0) <= reg_QA;
          end if;
        elsif exec.opcMULU = '0' then
          mulu_reg <= result_mulu;
        end if;
      end if;
    end if;
  end process;

  -------------------------------------------------------------------------------
  ---- DIVU/DIVS
  -------------------------------------------------------------------------------

  process (execOPC, OP1out, OP2out, div_reg, div_neg, div_bit, div_sub, div_quot, OP1_sign, div_over, result_div, reg_QA, opcode, sndOPC, divs, exe_opcode, reg_QB,
          signedOP, nozero, div_qsign, OP2outext)
  begin
    divs <= (opcode(15) and opcode(8)) OR (not opcode(15) and sndOPC(11));
    divisor(15 downto 0) <= (others => '0');
    divisor(63 downto 32) <= (others => divs and reg_QA(31));
    if exe_opcode(15) = '1' then
      divisor(47 downto 16) <= reg_QA;
    else
      divisor(31 downto 0) <= reg_QA;
      if exe_opcode(14) = '1' and sndOPC(10) = '1' then
      divisor(63 downto 32) <= reg_QB;
      end if;
    end if;
    if signedOP = '1' OR opcode(15) = '0' then
      OP2outext <= OP2out(31 downto 16);
    else
      OP2outext <= (others => '0');
    end if;
    if signedOP = '1' and OP2out(31) = '1' then
      div_sub <= (div_reg(63 downto 31)) + ('1' & OP2out(31 downto 0));
    else
      div_sub <= (div_reg(63 downto 31)) - ('0' & OP2outext(15 downto 0) & OP2out(15 downto 0));
    end if;
    div_bit <= div_sub(32);
    if div_bit = '1' then
      div_quot(63 downto 32) <= div_reg(62 downto 31);
    else
      div_quot(63 downto 32) <= div_sub(31 downto 0);
    end if;
    div_quot(31 downto 0) <= div_reg(30 downto 0) & not div_bit;
    if ((nozero = '1' and signedOP = '1' and (OP2out(31) xor OP1_sign xor div_neg xor div_qsign) = '1' ) --Overflow DIVS
    OR (signedOP = '0' and div_over(32) = '0')) then --Overflow DIVU
      set_V_Flag <= '1';
    else
      set_V_Flag <= '0';
    end if;
  end process;

  process (clk)
  begin
    if rising_edge(clk) then
      if clkena_lw = '1' then
      div_V_Flag <= set_V_Flag;
      signedOP <= divs;
      if micro_state = div1 then
        nozero <= '0';
        if divs = '1' and divisor(63) = '1' then -- Neg divisor
        OP1_sign <= '1';
        div_reg <= 0 - divisor;
        else
        OP1_sign <= '0';
        div_reg <= divisor;
        end if;
      else
        div_reg <= div_quot;
        nozero <= not div_bit OR nozero;
      end if;

      if micro_state = div2 then
        flip_V_Flag <= '0';
        if (div_sub(32 downto 1) = x"00000000") and (div_sub(0) & div_reg(30 downto 0) = x"00000000") then
        div_qsign <= not OP2out(31);
        flip_V_Flag <= '1';
        else
        div_qsign <= not div_bit; -- used for signed overflow detection only
        end if;

        div_neg <= signedOP and (OP2out(31) xor OP1_sign);
        div_over <= ('0' & div_reg(63 downto 32)) - ('0' & OP2out);
      end if;
      if exec.write_reminder = '0' then
        if div_neg = '1' then
        result_div(31 downto 0) <= 0 - div_quot(31 downto 0);
        else
        result_div(31 downto 0) <= div_quot(31 downto 0);
        end if;

        if OP1_sign = '1' then
        result_div(63 downto 32) <= 0 - div_quot(63 downto 32);
        else
        result_div(63 downto 32) <= div_quot(63 downto 32);
        end if;
      end if;
      end if;
    end if;
  end process;

  Flags_out <= Flags;
  process (clk)
  begin
    if falling_edge(clk) then
      set_Cmp2_Flags_out <= set_flags_cmp2;
      addsub_q_out       <= addsub_q;
      alu_c_out          <= c_out;
      set_V_Flag_out     <= set_V_Flag;
    end if;
  end process;

end;
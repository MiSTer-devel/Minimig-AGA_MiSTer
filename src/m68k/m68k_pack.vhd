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


Package M68K_Pack is

  subtype bit1      is std_logic;
  subtype word      is std_logic_vector;

  type tCputype is record
    is_68000 : bit1;
    is_68010 : bit1;
    is_68020 : bit1;
    ge_68010 : bit1; -- 68010 or 68020 or..
    ge_68020 : bit1; -- 68020 or...
  end record;

  type micro_states is (idle, nop, ld_nn, st_nn, ld_dAn1, ld_AnXn1, ld_AnXn2, st_dAn1, ld_AnXnbd1, ld_AnXnbd2, ld_AnXnbd3,
                          ld_229_1, ld_229_2, ld_229_3, ld_229_4, st_229_1, st_229_2, st_229_3, st_229_4,
                          st_AnXn1, st_AnXn2, bra1, bsr1, bsr2, nopnop, dbcc1, movem1, movem2, movem3,
                          andi, op_AxAy, cmpm, link1, link2, unlink1, unlink2, int1, int2, int3, int4, rtr1, rte1,
                          rte2, rte3, rte4, rte5, rtd1, rtd2, trap00, trap0, trap1, trap2, trap3,
                          trap4, trap5, trap6, movec1, movep1, movep2, movep3, movep4, movep5, rota1, bf1,
                          mul1, mul2, mul_w,  mul_end1,  mul_end2, div1, div2, div3, div4, div_end1, div_end2, pack1, pack2, pack3,
                          upperbound, upperbound2, cas, cas_eq, cas_neq, cas2_1, cas2_2, cas2_3, cas2_4, cas2_5, cas2_6, cas2_eq_1, cas2_neq_1, cas2_neq_2);

    type r_Opc is record
       opcMOVE        : bit1;
       opcMOVEQ       : bit1;
       opcMOVESR      : bit1;
       opcMOVECCR     : bit1;
       opcADD         : bit1;
       opcADDQ        : bit1;
       opcOR          : bit1;
       opcAND         : bit1;
       opcEOR         : bit1;
       opcCMP         : bit1;
       opcCAS         : bit1;
       opcROT         : bit1;
       opcCPMAW       : bit1;
       opcEXT         : bit1;
       opcABCD        : bit1;
       opcSBCD        : bit1;
       opcBITS        : bit1;
       opcSWAP        : bit1;
       opcScc         : bit1;
       andiSR         : bit1;
       eoriSR         : bit1;
       oriSR          : bit1;
       opcMULU        : bit1;
       opcDIVU        : bit1;
       dispouter      : bit1;
       rot_nop        : bit1;
       ld_rot_cnt     : bit1;
       writePC_add    : bit1;
       ea_data_OP1    : bit1;
       ea_data_OP2    : bit1;
       use_XZFlag     : bit1;
       get_bfoffset   : bit1;
       save_memaddr   : bit1;
       opcCHK         : bit1;
       opcCHK2        : bit1;
       movec_rd       : bit1;
       movec_wr       : bit1;
       Regwrena       : bit1;
       update_FC      : bit1;
       linksp         : bit1;
       movepl         : bit1;
       update_ld      : bit1;
       OP1addr        : bit1;
       write_reg      : bit1;
       changeMode     : bit1;
       ea_build       : bit1;
       trap_chk       : bit1;
       trap_trapv     : bit1;
       store_ea_data  : bit1;
       addrlong       : bit1;
       postadd        : bit1;
       presub         : bit1;
       subidx         : bit1;
       no_Flags       : bit1;
       use_SP         : bit1;
       to_CCR         : bit1;
       to_SR          : bit1;
       OP2out_one     : bit1;
       OP1out_zero    : bit1;
       mem_addsub     : bit1;
       addsub         : bit1;
       directPC       : bit1;
       direct_delta   : bit1;
       directSR       : bit1;
       directCCR      : bit1;
       exg            : bit1;
       get_ea_now     : bit1;
       ea_to_pc       : bit1;
       hold_dwr       : bit1;
       to_USP         : bit1;
       from_USP       : bit1;
       write_lowlong  : bit1;
       write_reminder : bit1;
       movem_action   : bit1;
       briefext       : bit1;
       brieflow       : bit1;
       get_2ndOPC     : bit1;
       mem_byte       : bit1;
       longaktion     : bit1;
       opcRESET       : bit1;
       opcBF          : bit1;
       opcBFwb        : bit1;
       opcPACK        : bit1;
       upperbound     : bit1;
    end record;

    function opc_or(a : r_Opc; b : r_Opc) return r_Opc;

    type r_Decode_pipe is record
      skipFetch              : bit1;
      next_micro_state       : micro_states;
      set                    : r_Opc;
      set_exec               : r_Opc;
      setnextpass            : bit1;
      setstate               : word(1 downto 0);
      getbrief               : bit1;
      setstackaddr           : bit1;
      set_Suppress_Base      : bit1;
      set_PCbase             : bit1;
      set_direct_data        : bit1;
      datatype               : word(1 downto 0);
      set_rot_cnt            : word(5 downto 0);
      set_rot_bits           : word(1 downto 0);
      set_stop               : bit1;
      movem_presub           : bit1;
      regdirectsource        : bit1;
      dest_areg              : bit1;
      source_areg            : bit1;
      data_is_source         : bit1;
      write_back             : bit1;
      writePC                : bit1;
      ea_only                : bit1;
      source_lowbits         : bit1;
      source_2ndHbits        : bit1;
      source_2ndMbits        : bit1;
      source_2ndLbits        : bit1;
      source_briefMbits      : bit1;
      dest_2ndHbits          : bit1;
      dest_2ndLbits          : bit1;
      dest_hbits             : bit1;
      set_exec_tas           : bit1;
      trap_make              : bit1;
      trap_illegal           : bit1;
      trap_addr_error        : bit1;
      trap_priv              : bit1;
      trap_1010              : bit1;
      trap_1111              : bit1;
      trap_trap              : bit1;
      set_Z_error            : bit1;
      writeSR                : bit1;
      set_vectoraddr         : bit1;
      set_writePCbig         : bit1;
      TG68_PC_brw            : bit1;
      setdispbyte            : bit1;
      setdisp                : bit1;
      ea_build_now           : bit1;
    end record;


  constant z_Decode_pipe : r_Decode_pipe := (
    '0',
    idle,
    (others => '0'),
    (others => '0'),
    '0',
    (others => '0'),
    '0',
    '0',
    '0',
    '0',
    '0',
    (others => '0'),
    (others => '0'),
    (others => '0'),
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0',
    '0'
    );

  type r_Decode_pipe_array is array (natural range <>) of r_Decode_pipe;

  type r_OpDecodeIp is record
    -- current state input to decoder block
    cpu             : word( 1 downto 0);
    OP1out          : word(31 downto 0);
    OP2out          : word(31 downto 0);
    opcode          : word(15 downto 0);
    exe_condition   : bit1;
    nextpass        : bit1;
    micro_state     : micro_states;
    state           : word( 1 downto 0);
    decodeOPC       : bit1;
    setexecOPC      : bit1;
    Flags           : word( 7 downto 0);
    FlagsSR         : word( 7 downto 0);
    direct_data     : bit1;
    trapd           : bit1;
    movem_run       : bit1;
    last_data_read  : word(31 downto 0);
    set_V_Flag      : bit1;
    Z_error         : bit1;
    trap_trace      : bit1;
    trap_interrupt  : bit1;
    SVmode          : bit1;
    preSVmode       : bit1;
    stop            : bit1;
    long_done       : bit1;
    execOPC         : bit1;
    exec_write_back : bit1;
    exe_datatype    : word( 1 downto 0);
    c_out           : word( 2 downto 0);
    interrupt       : bit1;
    rot_cnt         : word( 5 downto 0);
    brief           : word(15 downto 0);
    addr            : word(31 downto 0);
    last_data_in    : word(31 downto 0);
    long_start      : bit1;
  end record;

  function to_hstring (value : std_logic_vector) return string;

end;

package body M68K_Pack is

  -- bit painful
  function opc_or(a : r_Opc; b : r_Opc) return r_Opc is
    variable r : r_Opc;
  begin
    r := (others => '0');
    r.opcMOVE         := a.opcMOVE        or b.opcMOVE;
    r.opcMOVEQ        := a.opcMOVEQ       or b.opcMOVEQ;
    r.opcMOVESR       := a.opcMOVESR      or b.opcMOVESR;
    r.opcMOVECCR      := a.opcMOVECCR     or b.opcMOVECCR;
    r.opcADD          := a.opcADD         or b.opcADD;
    r.opcADDQ         := a.opcADDQ        or b.opcADDQ;
    r.opcOR           := a.opcOR          or b.opcOR;
    r.opcAND          := a.opcAND         or b.opcAND;
    r.opcEOR          := a.opcEOR         or b.opcEOR;
    r.opcCMP          := a.opcCMP         or b.opcCMP;
    r.opcCAS          := a.opcCAS         or b.opcCAS;
    r.opcROT          := a.opcROT         or b.opcROT;
    r.opcCPMAW        := a.opcCPMAW       or b.opcCPMAW;
    r.opcEXT          := a.opcEXT         or b.opcEXT;
    r.opcABCD         := a.opcABCD        or b.opcABCD;
    r.opcSBCD         := a.opcSBCD        or b.opcSBCD;
    r.opcBITS         := a.opcBITS        or b.opcBITS;
    r.opcSWAP         := a.opcSWAP        or b.opcSWAP;
    r.opcScc          := a.opcScc         or b.opcScc;
    r.andiSR          := a.andiSR         or b.andiSR;
    r.eoriSR          := a.eoriSR         or b.eoriSR;
    r.oriSR           := a.oriSR          or b.oriSR;
    r.opcMULU         := a.opcMULU        or b.opcMULU;
    r.opcDIVU         := a.opcDIVU        or b.opcDIVU;
    r.dispouter       := a.dispouter      or b.dispouter;
    r.rot_nop         := a.rot_nop        or b.rot_nop;
    r.ld_rot_cnt      := a.ld_rot_cnt     or b.ld_rot_cnt;
    r.writePC_add     := a.writePC_add    or b.writePC_add;
    r.ea_data_OP1     := a.ea_data_OP1    or b.ea_data_OP1;
    r.ea_data_OP2     := a.ea_data_OP2    or b.ea_data_OP2;
    r.use_XZFlag      := a.use_XZFlag     or b.use_XZFlag;
    r.get_bfoffset    := a.get_bfoffset   or b.get_bfoffset;
    r.save_memaddr    := a.save_memaddr   or b.save_memaddr;
    r.opcCHK          := a.opcCHK         or b.opcCHK;
    r.opcCHK2         := a.opcCHK2        or b.opcCHK2;
    r.movec_rd        := a.movec_rd       or b.movec_rd;
    r.movec_wr        := a.movec_wr       or b.movec_wr;
    r.Regwrena        := a.Regwrena       or b.Regwrena;
    r.update_FC       := a.update_FC      or b.update_FC;
    r.linksp          := a.linksp         or b.linksp;
    r.movepl          := a.movepl         or b.movepl;
    r.update_ld       := a.update_ld      or b.update_ld;
    r.OP1addr         := a.OP1addr        or b.OP1addr;
    r.write_reg       := a.write_reg      or b.write_reg;
    r.changeMode      := a.changeMode     or b.changeMode;
    r.ea_build        := a.ea_build       or b.ea_build;
    r.trap_chk        := a.trap_chk       or b.trap_chk;
    r.trap_trapv      := a.trap_trapv     or b.trap_trapv;
    r.store_ea_data   := a.store_ea_data  or b.store_ea_data;
    r.addrlong        := a.addrlong       or b.addrlong;
    r.postadd         := a.postadd        or b.postadd;
    r.presub          := a.presub         or b.presub;
    r.subidx          := a.subidx         or b.subidx;
    r.no_Flags        := a.no_Flags       or b.no_Flags;
    r.use_SP          := a.use_SP         or b.use_SP;
    r.to_CCR          := a.to_CCR         or b.to_CCR;
    r.to_SR           := a.to_SR          or b.to_SR;
    r.OP2out_one      := a.OP2out_one     or b.OP2out_one;
    r.OP1out_zero     := a.OP1out_zero    or b.OP1out_zero;
    r.mem_addsub      := a.mem_addsub     or b.mem_addsub;
    r.addsub          := a.addsub         or b.addsub;
    r.directPC        := a.directPC       or b.directPC;
    r.direct_delta    := a.direct_delta   or b.direct_delta;
    r.directSR        := a.directSR       or b.directSR;
    r.directCCR       := a.directCCR      or b.directCCR;
    r.exg             := a.exg            or b.exg;
    r.get_ea_now      := a.get_ea_now     or b.get_ea_now;
    r.ea_to_pc        := a.ea_to_pc       or b.ea_to_pc;
    r.hold_dwr        := a.hold_dwr       or b.hold_dwr;
    r.to_USP          := a.to_USP         or b.to_USP;
    r.from_USP        := a.from_USP       or b.from_USP;
    r.write_lowlong   := a.write_lowlong  or b.write_lowlong;
    r.write_reminder  := a.write_reminder or b.write_reminder;
    r.movem_action    := a.movem_action   or b.movem_action;
    r.briefext        := a.briefext       or b.briefext;
    r.brieflow        := a.brieflow       or b.brieflow;
    r.get_2ndOPC      := a.get_2ndOPC     or b.get_2ndOPC;
    r.mem_byte        := a.mem_byte       or b.mem_byte;
    r.longaktion      := a.longaktion     or b.longaktion;
    r.opcRESET        := a.opcRESET       or b.opcRESET;
    r.opcBF           := a.opcBF          or b.opcBF;
    r.opcBFwb         := a.opcBFwb        or b.opcBFwb;
    r.opcPACK         := a.opcPACK        or b.opcPACK;
    r.upperbound      := a.upperbound     or b.upperbound;

    return r;
  end function;

  function to_hstring (value : std_logic_vector) return string is
    constant ne     : integer := (value'length+3)/4;
    variable pad    : std_logic_vector(0 to (ne*4 - value'length) - 1);
    variable ivalue : std_logic_vector(0 to ne*4 - 1);
    variable result : string(1 to ne);
    variable quad   : std_logic_vector(0 to 3);
  begin
    if value'length < 1 then
      return "";
    else
      if value (value'left) = 'Z' then
        pad := (others => 'Z');
      else
        pad := (others => '0');
      end if;
      ivalue := pad & value;

      for i in 0 to ne-1 loop
        quad := To_X01Z(ivalue(4*i to 4*i+3));
        case quad is
          when x"0"   => result(i+1) := '0';
          when x"1"   => result(i+1) := '1';
          when x"2"   => result(i+1) := '2';
          when x"3"   => result(i+1) := '3';
          when x"4"   => result(i+1) := '4';
          when x"5"   => result(i+1) := '5';
          when x"6"   => result(i+1) := '6';
          when x"7"   => result(i+1) := '7';
          when x"8"   => result(i+1) := '8';
          when x"9"   => result(i+1) := '9';
          when x"A"   => result(i+1) := 'A';
          when x"B"   => result(i+1) := 'B';
          when x"C"   => result(i+1) := 'C';
          when x"D"   => result(i+1) := 'D';
          when x"E"   => result(i+1) := 'E';
          when x"F"   => result(i+1) := 'F';
          when "ZZZZ" => result(i+1) := 'Z';
          when others => result(i+1) := 'X';
        end case;
      end loop;
      return result;
    end if;
  end function to_hstring;

end;

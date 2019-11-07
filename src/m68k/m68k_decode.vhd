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

entity M68K_Decode is
 generic (
    BarrelShifter  : integer := 0  --0=>no,    1=>yes,   2=>switchable with CPU(1)
  );
  port (
    cpu             : in  word( 1 downto 0) := "00"; -- 00->68000 01->68010 11->68020(only some parts - yet)
    OP1out          : in  word(31 downto 0);
    OP2out          : in  word(31 downto 0);
    opcode          : in  word(15 downto 0);
    exe_condition   : in  bit1;
    nextpass        : in  bit1;
    micro_state     : in  micro_states;
    state           : in  word( 1 downto 0);
    decodeOPC       : in  bit1;
    setexecOPC      : in  bit1;
    Flags           : in  word( 7 downto 0); -- ...XNZVC
    FlagsSR         : in  word( 7 downto 0) := (others => '0'); -- T.S..III
    direct_data     : in  bit1;
    trapd           : in  bit1;
    movem_run       : in  bit1;
    last_data_read  : in  word(31 downto 0);
    set_V_Flag      : in  bit1;
    set_Cmp2_Flags  : in  word( 3 downto 0);
    Z_error         : in  bit1;
    trap_trace      : in  bit1;
    trap_interrupt  : in  bit1;
    SVmode          : in  bit1;
    preSVmode       : in  bit1;
    stop            : in  bit1;
    long_done       : in  bit1;
    execOPC         : in  bit1;
    exec_write_back : in  bit1;
    c_out           : in  word( 2 downto 0);
    interrupt       : in  bit1;
    rot_cnt         : in  word( 5 downto 0);
    brief           : in  word(15 downto 0);
    addr            : in  word(31 downto 0);
    last_data_in    : in  word(31 downto 0);
    long_start      : in  bit1;

    sndOPC          : in  word(15 downto 0);
    exec            : in  r_Opc;
    reg_QA          : in  word(31 downto 0);
    reg_QB          : in  word(31 downto 0);
    trap_berr       : in  bit1;
    trap_7word      : in  bit1; -- 68000 bus/address exception
    --
    o_skipFetch              : out bit1;
    --
    o_next_micro_state       : out micro_states;
    o_set                    : out r_Opc;
    o_set_exec               : out r_Opc;
    o_setnextpass            : out bit1;
    o_setstate               : out word(1 downto 0);
    o_getbrief               : out bit1;
    o_setstackaddr           : out bit1;
    o_set_Suppress_Base      : out bit1;
    o_set_PCbase             : out bit1;
    o_set_direct_data        : out bit1;
    o_datatype               : out word(1 downto 0);
    o_set_rot_cnt            : out word(5 downto 0);
    o_set_rot_bits           : out word(1 downto 0);
    o_set_stop               : out bit1;

    o_movem_presub           : out bit1;
    o_regdirectsource        : out bit1;
    o_dest_areg              : out bit1;
    o_source_areg            : out bit1;
    o_data_is_source         : out bit1;
    o_write_back             : out bit1;
    o_writePC                : out bit1;
    o_ea_only                : out bit1;
    o_source_lowbits         : out bit1;
    o_source_2ndHbits        : out bit1;
    o_source_2ndMbits        : out bit1;
    o_source_2ndLbits        : out bit1;
    o_source_briefMbits      : out bit1;
    o_dest_2ndHbits          : out bit1;
    o_dest_2ndLbits          : out bit1;
    o_dest_hbits             : out bit1;
    o_set_exec_tas           : out bit1;
    o_trapmake               : out bit1;
    o_trap_illegal           : out bit1;
    o_trap_addr_error        : out bit1;
    o_trap_priv              : out bit1;
    o_trap_1010              : out bit1;
    o_trap_1111              : out bit1;
    o_trap_trap              : out bit1;
    o_set_Z_error            : out bit1;
    o_writeSR                : out bit1;
    o_set_vectoraddr         : out bit1;
    o_set_writePCbig         : out bit1;
    o_TG68_PC_brw            : out bit1;
    o_setdispbyte            : out bit1;
    o_setdisp                : out bit1;
    o_Regwrena_now           : out bit1
  );
end;


-- brief format extension word
-- 15     index type 0=Dm,1=Am
-- 14..12 index reg
-- 11     index size 0=word 1=long
-- 10.. 9 scale 00,1,2,4, 11=8  scale for 020 only
--  8     0
--  7.. 0 displacement

-- full format extension word
--  8     1
-- base displacement 0-2 words. Outer, 0-2 words


architecture RTL of M68K_Decode is

  signal build_logical        : bit1;
  signal build_bcd            : bit1;

  signal Regwrena_now         : bit1;

  signal p : r_Decode_pipe_array(4 downto 1);
begin
  process(cpu, trapd, preSVmode, interrupt, trap_berr, micro_state, trap_trace, setexecOPC, FlagsSR, decodeOPC, exec, opcode, trap_interrupt, p(4))
    constant e : integer := 4;
    constant o : integer := 1;
  begin
    -- STAGE 0
    p(o) <= z_Decode_pipe;

    if p(e).trap_make = '1' and trapd = '0' then
      -- trace is already handled below
      if cpu(0) = '1' and (exec.trap_chk = '1' or p(e).set.trap_trapv='1') then -- or Z_error='1' then
        p(o).next_micro_state <= trap00;
      else
        p(o).next_micro_state <= trap0;
      end if;
      if (cpu(0) = '0') then  -- 68000 only
        p(o).set.writePC_add <= '1';
      end if;
      if preSVmode = '0' then
        p(o).set.changeMode <= '1';
      end if;
      p(o).setstate <= "01";
    end if;

    if interrupt='1' and trap_berr='1' THEN
      p(o).next_micro_state <= trap0;
      if preSVmode='0' THEN
        p(o).set.changeMode <= '1';
      end if;
      p(o).setstate <= "01";
    end if;

    if micro_state = int1 or (interrupt = '1' and trap_trace = '1') then
      if (cpu(0)='1') and trap_trace='1' then
        p(o).next_micro_state <= trap00;
      else
        p(o).next_micro_state <= trap0;
      end if;

      if preSVmode = '0' then
        p(o).set.changeMode <= '1';
      end if;
      p(o).setstate <= "01";
    end if;

    if setexecOPC = '1' and FlagsSR(5) /= preSVmode then
      p(o).set.changeMode <= '1';
    end if;

    if interrupt = '1' and trap_interrupt = '1' then
      p(o).next_micro_state <= int1;
      p(o).set.update_ld <= '1';
      p(o).setstate<= "10";
    end if;

    if p(e).ea_only = '0' and p(e).set.get_ea_now = '1' then
      p(o).setstate <= "10";
    end if;

    if p(e).setstate(1) = '1' and p(e).datatype(1) = '1' then -- was set_datatype
      p(o).set.longaktion <= '1';
    end if;

    if (p(e).ea_build_now = '1' and decodeOPC = '1') or exec.ea_build = '1' then
      case opcode(5 downto 3) is --source
        when "010" | "011" | "100" => -- -(An)+
          p(o).set.get_ea_now <= '1';
          p(o).setnextpass <= '1';
          if opcode(3) = '1' then --(An)+
            p(o).set.postadd <= '1';
            if opcode(2 downto 0) = "111" then
              p(o).set.use_SP <= '1';
            end if;
          end if;
          if opcode(5) = '1' then -- -(An)
            p(o).set.presub <= '1';
            if opcode(2 downto 0) = "111" then
              p(o).set.use_SP <= '1';
            end if;
          end if;
        when "101" => --(d16,An)
          p(o).next_micro_state <= ld_dAn1;
        when "110" => --(d8,An,Xn)
          p(o).next_micro_state <= ld_AnXn1;
          p(o).getbrief <= '1';
        when "111" =>
          case opcode(2 downto 0) is
            when "000" => --(xxxx).w
              p(o).next_micro_state <= ld_nn;
            when "001" => --(xxxx).l
              p(o).set.longaktion <= '1';
              p(o).next_micro_state <= ld_nn;
            when "010" => --(d16,PC)
              p(o).next_micro_state <= ld_dAn1;
              p(o).set.dispouter <= '1';
              p(o).set_Suppress_Base <= '1';
              p(o).set_PCbase <= '1';
            when "011" => --(d8,PC,Xn)
              p(o).next_micro_state <= ld_AnXn1;
              p(o).getbrief <= '1';
              p(o).set.dispouter <= '1';
              p(o).set_Suppress_Base <= '1';
              p(o).set_PCbase <= '1';
            when "100" => --#data
              p(o).setnextpass <= '1';
              p(o).set_direct_data <= '1';
              if p(e).datatype = "10" then
                p(o).set.longaktion <= '1';
              end if;
            when others => NULL;
          end case;
        when others => NULL;
      end case;
    end if;
  end process;

  process (cpu, opcode, rot_cnt, decodeOPC, setexecOPC, SVmode,
           nextpass, micro_state, c_out, OP1out, OP2out, exec, state, direct_data, movem_run, brief,
           long_done, stop, Flags, trap_interrupt, trap_trace, Z_error, set_V_Flag, set_Cmp2_Flags, last_data_read, p, sndOPC )
    constant i : integer := 1;
    constant o : integer := 2;
    constant e : integer := 4; -- pipe end

    variable datatype : word(1 downto 0);

    variable v_opcor : bit1;
    variable v_opcand : bit1;
    variable v_opcEor : bit1;

  begin
    -- STAGE 1
    p(o) <= p(i);
    build_logical <= '0';
    build_bcd     <= '0';

    datatype := "10"; --Long
    case opcode(7 downto 6) is
      when "00"   => datatype := "00"; --Byte
      when "01"   => datatype := "01"; --Word
      when others => null;
    end case;
    p(o).datatype <= datatype;

    -- decrement xyz
    p(o).set_rot_cnt <= "000001";
    if (rot_cnt /= "000001") then
      p(o).set_rot_cnt <= rot_cnt - "1";
    end if;

    if p(i).set.changeMode = '1' then
      p(o).set.to_USP     <= '1';
      p(o).set.from_USP   <= '1';
      p(o).setstackaddr <= '1';
    end if;

    ------------------------------------------------------------------------------
    --prepere opcode
    ------------------------------------------------------------------------------
    case opcode(15 downto 12) is
      -- 0000 ----------------------------------------------------------------------------
      when "0000" =>
        if opcode(8) = '1' and opcode(5 downto 3) = "001" then --movep
          p(o).datatype <= "00"; --Byte
          p(o).set.use_SP <= '1'; --addr+2
          p(o).set.no_Flags <= '1';
          if opcode(7) = '0' then --to register
            p(o).set_exec.Regwrena <= '1';
            p(o).set_exec.opcMOVE <= '1';
            p(o).set.movepl <= '1';
          end if;
          if decodeOPC = '1' then
            if opcode(6) = '1' then
              p(o).set.movepl <= '1';
            end if;
            if opcode(7) = '0' then
              p(o).set_direct_data <= '1'; -- to register
            end if;
            p(o).next_micro_state <= movep1;
          end if;
          if setexecOPC = '1' then
            p(o).dest_hbits <= '1';
          end if;
        else
          -- not movep
          if opcode(8) = '1' or opcode(11 downto 9) = "100" then --Bits
            p(o).set_exec.opcBITS <= '1';
            p(o).set_exec.ea_data_OP1 <= '1';
            if opcode(7 downto 6) /= "00" then
              if opcode(5 downto 4) = "00" then
                p(o).set_exec.Regwrena <= '1';
              end if;
              p(o).write_back <= '1';
            end if;
            if opcode(5 downto 4) = "00" then
              p(o).datatype <= "10"; --Long
            else
              p(o).datatype <= "00"; --Byte
            end if;

            if opcode(8) = '0' then
              if decodeOPC = '1' then
                p(o).next_micro_state <= nop;
                p(o).set.get_2ndOPC <= '1';
                p(o).set.ea_build <= '1';
              end if;
            else
              p(o).ea_build_now <= '1';
            end if;
          --
          elsif opcode(11 downto 8) = "1110" and opcode (7 downto 6) /= "11" then --MOVES not in 68000 ?? eh check for 010+?
            if (cpu(0) = '1')  then
              -- to do
            else
              p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
            end if;
          else
            -- catch 020 cmp2/chk2/cas2 -- we know 8=0
            if    opcode(11) = '0' and opcode(7 downto 6) = "11" then -- cmp2 OR chk2
              if cpu(1) = '1' then
                --assert false report "cmp2 or chk2" severity note;
                -- cmp2 = chk2 but sets condition codes rather than taking an exception
                -- SETs Z if equal to either bound and C flag if Rn out of bounds
                -- size 10..9, 5..3 src mode, 2..0 src reg

                p(o).datatype <= opcode(10 downto 9);

                if decodeOPC = '1' then
                  p(o).set.get_2ndOPC <= '1';
                  p(o).next_micro_state <= nop;
                  p(o).set.ea_build <= '1';
                end if;

                if micro_state = idle and nextpass = '1' then
                  p(o).setstate <= "10"; -- read again
                  p(o).next_micro_state <= upperbound;
                  p(o).set_exec.upperbound <= '1';

                  p(o).source_lowbits <= '1';
                  p(o).dest_2ndHbits  <= '1';

                  p(o).set.addsub <= '1';
                end if;

                if micro_state = upperbound and nextpass = '1' then
                  p(o).set_exec.opcCHK2 <= '1';    -- maybe change to set. and remove upperbound bodge on setexecOPC
                  p(o).source_lowbits <= '1';
                  p(o).dest_2ndHbits  <= '1';

                  p(o).set.addsub <= '1';
                end if;

                if micro_state = upperbound2 then
                  p(o).set.trap_chk <= '1';
                  if sndOPC(11) = '1' then
                    if (set_Cmp2_Flags(0) = '1') then
                      p(o).trap_make <= '1';
                    end if;
                  end if;
                end if;

              else
                p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
              end if;

            elsif opcode(11) = '1' and opcode(7 downto 6) = "11" then -- cas/2
              if cpu(1) = '1' then
                 -- note different width encoding here
                 case opcode(10 downto 9) is
                   when "01"   => p(o).datatype <= "00"; --Byte
                   when "11"   => p(o).datatype <= "10"; --Long
                   when others => p(o).datatype <= "01"; --Word
                                  --p(o).set.longaktion <= '1';
                end case;

                if    opcode(5 downto 0) = "111100" then
                  --
                  -- CAS2
                  --
                  if opcode(10 downto 9) = "01" then -- no byte
                    p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
                  else
                    if decodeOPC = '1' then
                      --assert false report "cas2" severity note;
                      p(o).set.get_2ndOPC <= '1';
                      p(o).next_micro_state <= cas2_1;
                    end if;

                    if micro_state = cas2_1 then
                      -- fetch Rn1
                      p(o).dest_2ndHbits  <= '1';   -- 15..12
                      p(o).getbrief <= '1'; -- use brief for 2nd opperand
                      p(o).set.get_ea_now <= '1';
                    end if;

                    if micro_state = cas2_2 then -- now the address is in QA, and we will do the EA read
                      p(o).dest_2ndLbits  <= '1'; --  3..0
                      p(o).set.addsub <= '1';
                    end if;

                    if micro_state = cas2_3 then
                      p(o).set.briefext <= '1'; -- set dest, 15..12 in brief for ea fetch
                      p(o).set.get_ea_now <= '1';
                    end if;

                    if micro_state = cas2_4 then
                      p(o).setstate <= "01";
                      p(o).set.brieflow <= '1'; -- dest 3..0 from brief
                      p(o).set.addsub <= '1';
                    end if;

                    if micro_state = cas2_5 then
                      p(o).setstate <= "01"; -- stall
                    end if;

                    if micro_state = cas2_6 then
                      if Flags(2) ='1' then
                        assert false report "cas2 both EQ" severity note;
                        -- write DU1/DU2 to RN1/RN2
                        p(o).next_micro_state <= cas2_eq_1;
                        p(o).setstate <= "11"; -- write back
                        p(o).set_exec.opcMOVE <= '1';
                        -- do rn2 (brief) first
                        p(o).set.briefext      <= '1'; -- 15..12
                        p(o).source_briefMbits <= '1'; --  9.. 6

                        p(o).set.write_reg    <= '1';
                      else
                        assert false report "cas2 both NOT EQ" severity note;
                        -- read RN1/RN2 to DC
                        p(o).next_micro_state <= cas2_neq_1;
                        -- rn2 -> dc2. rn2 is still hanging around so we don't need to refetch
                        p(o).setstate <= "01";
                        p(o).set.Regwrena       <= '1';
                        p(o).set.brieflow       <= '1';  -- register dest brief 3..0
                        p(o).set.exg            <= '1';  -- clear alu path
                      end if;
                    end if;

                    if micro_state = cas2_eq_1 then
                      p(o).setstate <= "11"; -- write back
                      p(o).set_exec.opcMOVE <= '1';
                      p(o).dest_2ndHbits    <= '1'; -- 15..12
                      p(o).source_2ndMbits  <= '1'; --  9.. 6
                      p(o).set.write_reg    <= '1';
                    end if;

                    if micro_state = cas2_neq_1 then
                      p(o).next_micro_state <= cas2_neq_2;
                      p(o).setstate <= "10"; -- read
                      -- rn1 -> dc1
                      p(o).set.get_ea_now     <= '1';
                      p(o).dest_2ndHbits      <= '1';  -- source 15..12
                    end if;

                    if micro_state = cas2_neq_2 then
                      p(o).setstate <= "01"; -- idle
                      p(o).set.Regwrena       <= '1';
                      p(o).dest_2ndLbits      <= '1';  -- sets register dest (3..0)
                      p(o).set.exg            <= '1';  -- clear alu path
                    end if;
                    -- Done!
                  end if;
                else
                  --
                  -- CAS
                  --
                  if opcode(5 downto 4) = "00" or opcode(5 downto 1) = "11101" or opcode(5 downto 1) = "11111" then
                    -- dn/an illegal, as are 111,01-, 111,11- modes
                    p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
                  else
                    --assert false report "cas" severity note;
                    -- EA is compared to Dc
                    -- if equal, DU -> EA
                    -- otherwise EA -> DC
                    -- du2nd 8..6, dc 2..0
                    -- op1out = Dx to compare

                    if decodeOPC = '1' then
                      p(o).set.get_2ndOPC <= '1';
                      p(o).next_micro_state <= nop;
                      p(o).set.ea_build <= '1';
                    end if;

                    if nextpass = '1' and micro_state = idle then
                      p(o).source_2ndLbits <= '1';
                      p(o).set.ea_data_OP1 <= '1';
                      p(o).set.opcCAS <= '1';
                      p(o).set.addsub <= '1';

                      -- time to think
                      p(o).setstate <= "01";
                      p(o).next_micro_state <= cas;
                    end if;

                    if micro_state = cas then
                      if set_Cmp2_Flags(2) = '1' then
                        --assert false report "cas EQ" severity note;
                        p(o).setstate <= "11"; -- write back
                        p(o).next_micro_state <= cas_eq;
                        p(o).source_2ndMbits  <= '1';
                        p(o).set.write_reg    <= '1';
                      else
                        --assert false report "cas NOT EQ" severity note;
                        p(o).setstate <= "01";
                        p(o).next_micro_state <= cas_neq;
                        p(o).set.Regwrena       <= '1';
                        p(o).dest_2ndLbits      <= '1';  -- sets register dest
                        p(o).set.exg            <= '1';  -- clear alu path
                      end if;
                    end if;

                  end if;

                end if;
              else
                p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
              end if;
            else
              --andi, ...xxxi
              v_opcor  := '0';
              v_opcand := '0';
              v_opcEor := '0';

              if opcode(11 downto 9) = "000" then --orI
                p(o).set_exec.opcor  <= '1'; v_opcor := '1';
              end if;
              if opcode(11 downto 9) = "001" then --andI
                p(o).set_exec.opcand <= '1'; v_opcand := '1';
              end if;
              if opcode(11 downto 9) = "010" or opcode(11 downto 9) = "011" then --SUBI, ADDI
                p(o).set_exec.opcADD <= '1';
              end if;
              if opcode(11 downto 9) = "101" then --EorI
                p(o).set_exec.opcEor <= '1'; v_opcEor := '1';
              end if;
              if opcode(11 downto 9) = "110" then --CMPI
                p(o).set_exec.opcCMP <= '1';
              end if;

              if opcode(7) = '0' and opcode(5 downto 0) = "111100" and (v_opcor or v_opcEor or v_opcand) = '1' then --SR
                if decodeOPC = '1' and SVmode = '0' and opcode(6) = '1' then --SR
                  p(o).trap_priv <= '1'; p(o).trap_make <= '1';
                else
                  p(o).set.no_Flags <= '1';
                  if decodeOPC = '1' then
                    if opcode(6) = '1' then
                      p(o).set.to_SR <= '1';
                    end if;
                    p(o).set.to_CCR <= '1';
                    p(o).set.andisR <= v_opcand;
                    p(o).set.eorisR <= v_opcEor;
                    p(o).set.orisR  <= v_opcor;
                    p(o).setstate <= "01";
                    p(o).next_micro_state <= nopnop;
                  end if;
                end if;
              else
                if decodeOPC = '1' then
                  p(o).next_micro_state <= andi;
                  p(o).set.ea_build <= '1';
                  p(o).set_direct_data <= '1';
                  if datatype = "10" then
                    p(o).set.longaktion <= '1';
                  end if;
                end if;
                if opcode(5 downto 4) /= "00" then
                  p(o).set_exec.ea_data_OP1 <= '1';
                end if;
                if opcode(11 downto 9) /= "110" then --CMPI
                  if opcode(5 downto 4) = "00" then
                    p(o).set_exec.Regwrena <= '1';
                  end if;
                  p(o).write_back <= '1';
                end if;
                if opcode(10 downto 9) = "10" then --CMPI, SUBI
                  p(o).set.addsub <= '1';
                end if;
              end if;
            end if;
          end if;
        end if;
      -- 0001, 0010, 0011 -----------------------------------------------------------------
      when "0001" | "0010" | "0011" => --move.b, move.l, move.w
        p(o).set_exec.opcMOVE <= '1';
        p(o).ea_build_now <= '1';
        if opcode(8 downto 6) = "001" then p(o).set.no_Flags <= '1'; end if;
        if opcode(5 downto 4) = "00" then --Dn, An
          if opcode(8 downto 7) = "00" then
            p(o).set_exec.Regwrena <= '1';
          end if;
        end if;

        case opcode(13 downto 12) is
          when "01"   => p(o).datatype <= "00"; --Byte
          when "10"   => p(o).datatype <= "10"; --Long
          when others => p(o).datatype <= "01"; --Word
        end case;

        p(o).source_lowbits <= '1'; -- Dn=> An=>
        if opcode(3) = '1' then p(o).source_areg <= '1'; end if;

        if nextpass = '1' or opcode(5 downto 4) = "00" then
          p(o).dest_hbits <= '1';
          if opcode(8 downto 6) /= "000" then p(o).dest_areg <= '1'; end if;
        end if;

        if micro_state = idle and (nextpass = '1' or (opcode(5 downto 4) = "00" and decodeOPC = '1')) then
          case opcode(8 downto 6) is --destination
            when "000" | "001" => --Dn,An
              p(o).set_exec.Regwrena <= '1';
            when "010" | "011" | "100" => --destination -(an)+
              if opcode(6) = '1' then --(An)+
                p(o).set.postadd <= '1';
                if opcode(11 downto 9) = "111" then
                  p(o).set.use_SP <= '1';
                end if;
              end if;
              if opcode(8) = '1' then -- -(An)
                p(o).set.presub <= '1';
                if opcode(11 downto 9) = "111" then p(o).set.use_SP <= '1'; end if;
              end if;

              p(o).setstate <= "11";
              p(o).next_micro_state <= nop;
              if nextpass = '0' then
                p(o).set.write_reg <= '1';
              end if;

            when "101" => --(d16,An)
              p(o).next_micro_state <= st_dAn1;

            when "110" => --(d8,An,Xn)
              p(o).next_micro_state <= st_AnXn1;
              p(o).getbrief <= '1';

            when "111" =>
              case opcode(11 downto 9) is
                when "000" => --(xxxx).w
                  p(o).next_micro_state <= st_nn;
                when "001" => --(xxxx).l
                  p(o).set.longaktion <= '1';
                  p(o).next_micro_state <= st_nn;
                when others => NULL;
              end case;

            when others => NULL;
          end case;
        end if;
      -- 0100 ----------------------------------------------------------------------------
      when "0100" => --rts_group
        if opcode(8) = '1' then --lea
          if opcode(6) = '1' then --lea
            if opcode(7) = '1' then
              p(o).source_lowbits <= '1';
              -- if opcode(5 downto 3)="000" and opcode(10)='0' then --ext
              if opcode(5 downto 4) = "00" then --extb.l
                p(o).set_exec.opcEXT <= '1';
                p(o).set_exec.opcMOVE <= '1';
                p(o).set_exec.Regwrena <= '1';
              else
                p(o).source_areg <= '1';
                p(o).ea_only <= '1';
                p(o).set_exec.Regwrena <= '1';
                p(o).set_exec.opcMOVE <= '1';
                p(o).set.no_Flags <= '1';
                if opcode(5 downto 3) = "010" then --lea (Am),An
                  p(o).dest_areg <= '1';
                  p(o).dest_hbits <= '1';
                else
                  p(o).ea_build_now <= '1';
                end if;
                if p(e).set.get_ea_now = '1' then
                  p(o).setstate <= "01";
                  p(o).set_direct_data <= '1';
                end if;
                if setexecOPC = '1' then
                  p(o).dest_areg <= '1';
                  p(o).dest_hbits <= '1';
                end if;
              end if;
            else
              p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
            end if;
          else --chk
            if opcode(7)='1' and opcode(5 downto 0) /= "111111" then
              p(o).datatype <= "01"; --Word
              p(o).set.trap_chk <= '1';
              if (c_out(1) = '0' or OP1out(15) = '1' or OP2out(15) = '1') and exec.opcCHK = '1' then
                p(o).trap_make <= '1';
              end if;
            elsif cpu(1) = '1' then --chk long for 68020
              p(o).datatype <= "10"; --Long
              p(o).set.trap_chk <= '1';
              if (c_out(2) = '0' or OP1out(31) = '1' or OP2out(31) = '1') and exec.opcCHK = '1' then
                p(o).trap_make <= '1';
              end if;
            else
              p(o).trap_illegal <= '1'; -- chk long for 68020
              p(o).trap_make <= '1';
            end if;

            if opcode(7) = '1' or cpu(1) = '1' then
              if (nextpass = '1' or opcode(5 downto 4) = "00") and exec.opcCHK = '0' and micro_state = idle then
                p(o).set_exec.opcCHK <= '1';
              end if;
              p(o).ea_build_now <= '1';
              p(o).set.addsub <= '1';
              if setexecOPC = '1' then
                p(o).dest_hbits <= '1';
                p(o).source_lowbits <= '1';
              end if;
            end if;
          end if;
        else
          case opcode(11 downto 9) is
            when "000" =>
              if opcode(7 downto 6) = "11" then --move from SR
                if (cpu(0) = '0') or SVmode = '1' then
                  -- if SVmode='1' then
                  p(o).ea_build_now <= '1';
                  p(o).set_exec.opcMOVESR <= '1';
                  p(o).datatype <= "01";
                  p(o).write_back <= '1'; -- 68000 also reads first
                  if cpu(0) = '1' and state = "10" then
                    p(o).skipFetch <= '1';
                  end if;
                  if opcode(5 downto 4) = "00" then
                    p(o).set_exec.Regwrena <= '1';
                  end if;
                else
                  p(o).trap_priv <= '1'; p(o).trap_make <= '1';
                end if;
              else --negx
                p(o).ea_build_now <= '1';
                p(o).set_exec.use_XZFlag <= '1';
                p(o).write_back <= '1';
                p(o).set_exec.opcADD <= '1';
                p(o).set.addsub <= '1';
                p(o).source_lowbits <= '1';
                if opcode(5 downto 4) = "00" then
                  p(o).set_exec.Regwrena <= '1';
                end if;
                if setexecOPC = '1' then
                  p(o).set.OP1out_zero <= '1';
                end if;
              end if;
            when "001" =>
              if opcode(7 downto 6) = "11" then --move from CCR 68010
                if (cpu(0) = '1') then
                  p(o).ea_build_now <= '1';
                  p(o).set_exec.opcMOVECCR <= '1';
                  p(o).datatype <= "01"; -- WRONG, should be WORD zero extended.
                  p(o).write_back <= '1'; -- 68000 also reads first

                  if opcode(5 downto 4) = "00" then
                    p(o).set_exec.Regwrena <= '1';
                  end if;
                else
                  p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
                end if;
              else --clr
                p(o).ea_build_now <= '1';
                p(o).write_back <= '1';
                p(o).set_exec.opcand <= '1';
                if cpu(0) = '1' and state = "10" then
                  p(o).skipFetch <= '1';
                end if;
                if setexecOPC = '1' then
                  p(o).set.OP1out_zero <= '1';
                end if;
                if opcode(5 downto 4) = "00" then
                  p(o).set_exec.Regwrena <= '1';
                end if;
              end if;
            when "010" =>
              p(o).ea_build_now <= '1';
              if opcode(7 downto 6) = "11" then --move to CCR
                p(o).datatype <= "01";
                p(o).source_lowbits <= '1';
                if (decodeOPC = '1' and opcode(5 downto 4) = "00") or state = "10" or direct_data = '1' then
                  p(o).set.to_CCR <= '1';
                end if;
              else --neg
                p(o).write_back <= '1';
                p(o).set_exec.opcADD <= '1';
                p(o).set.addsub <= '1';
                p(o).source_lowbits <= '1';
                if opcode(5 downto 4) = "00" then
                  p(o).set_exec.Regwrena <= '1';
                end if;
                if setexecOPC = '1' then
                  p(o).set.OP1out_zero <= '1';
                end if;
              end if;
            when "011" => -- not / move toSR
              if opcode(7 downto 6) = "11" then --move to SR
                if SVmode = '1' then
                  p(o).ea_build_now <= '1';
                  p(o).datatype <= "01";
                  p(o).source_lowbits <= '1';
                  if (decodeOPC = '1' and opcode(5 downto 4) = "00") or state = "10" or direct_data = '1' then
                    p(o).set.to_SR <= '1';
                    p(o).set.to_CCR <= '1';
                  end if;
                  if exec.to_SR = '1' or (decodeOPC = '1' and opcode(5 downto 4) = "00") or state = "10" or direct_data = '1' then
                    p(o).setstate <= "01";
                  end if;
                else
                  p(o).trap_priv <= '1'; p(o).trap_make <= '1';
                end if;
              else --not
                p(o).ea_build_now <= '1';
                p(o).write_back <= '1';
                p(o).set_exec.opcEor <= '1';
                p(o).set_exec.ea_data_OP1 <= '1';
                if opcode(5 downto 3) = "000" then
                  p(o).set_exec.Regwrena <= '1';
                end if;
                if setexecOPC = '1' then
                  p(o).set.OP2out_one <= '1';
                end if;
              end if;
            when "100" | "110" =>
              if opcode(7) = '1' then --movem, ext
                if opcode(5 downto 3) = "000" and opcode(10) = '0' then --ext
                  p(o).source_lowbits <= '1';
                  p(o).set_exec.opcEXT <= '1';
                  p(o).set_exec.opcMOVE <= '1';
                  p(o).set_exec.Regwrena <= '1';
                  if opcode(6) = '0' then
                    p(o).datatype <= "01"; --WorD
                  end if;
                else --movem
                  -- if opcode(11 downto 7)="10001" or opcode(11 downto 7)="11001" then --MOVEM
                  p(o).ea_only <= '1';
                  p(o).set.no_Flags <= '1';
                  if opcode(6) = '0' then
                    p(o).datatype <= "01"; --Word transfer
                  end if;
                  if (opcode(5 downto 3) = "100" or opcode(5 downto 3) = "011") and state = "01" then -- -(An), (An)+
                    p(o).set_exec.save_memaddr <= '1';
                    p(o).set_exec.Regwrena <= '1';
                  end if;
                  if opcode(5 downto 3) = "100" then -- -(An)
                    p(o).movem_presub <= '1';
                    p(o).set.subidx <= '1';
                  end if;
                  if state = "10" then
                    p(o).set.Regwrena <= '1';
                    p(o).set.opcMOVE <= '1';
                  end if;
                  if decodeOPC = '1' then
                    p(o).set.get_2ndOPC <= '1';
                    if opcode(5 downto 3) = "010" or opcode(5 downto 3) = "011" or opcode(5 downto 3) = "100" then
                      p(o).next_micro_state <= movem1;
                    else
                      p(o).next_micro_state <= nop;
                      p(o).set.ea_build <= '1';
                    end if;
                  end if;
                  if p(e).set.get_ea_now = '1' then
                    if movem_run = '1' then
                      p(o).set.movem_action <= '1';
                      if opcode(10) = '0' then
                        p(o).setstate <= "11";
                        p(o).set.write_reg <= '1';
                      else
                        p(o).setstate <= "10";
                      end if;
                      p(o).next_micro_state <= movem2;
                      p(o).set.mem_addsub <= '1';
                    else
                      p(o).setstate <= "01";
                    end if;
                  end if;
                end if;
              else
                if opcode(10) = '1' then --MUL.L, DIV.L 68020
                  if cpu(1)='1' then
                    if decodeOPC = '1' then
                      p(o).next_micro_state <= nop;
                      p(o).set.get_2ndOPC <= '1';
                      p(o).set.ea_build <= '1';
                    end if;
                    if (micro_state = idle and nextpass = '1') or (opcode(5 downto 4) = "00" and exec.ea_build = '1') then
                      p(o).setstate <= "01";
                      p(o).dest_2ndHbits <= '1';
                      p(o).source_2ndLbits <= '1';
                      if opcode(6) = '1' then
                        p(o).next_micro_state <= div1;
                      else
                        p(o).next_micro_state <= mul1;
                        p(o).set.ld_rot_cnt <= '1';
                      end if;
                    end if;
                    if z_error = '0' and set_V_Flag = '0' and p(e).set.opcDIVU = '1' then
                      p(o).set.Regwrena <= '1';
                    end if;
                    p(o).source_lowbits <= '1';
                    if nextpass = '1' or (opcode(5 downto 4) = "00" and decodeOPC = '1') then
                      p(o).dest_hbits <= '1';
                    end if;
                    p(o).datatype <= "10";
                  else
                    p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
                  end if;

                else --pea, swap
                  if opcode(6) = '1' then
                    p(o).datatype <= "10";
                    if opcode(5 downto 3) = "000" then --swap
                      p(o).set_exec.opcSWAP <= '1';
                      p(o).set_exec.Regwrena <= '1';
                    elsif opcode(5 downto 3) = "001" then --bkpt
                      p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
                    else --pea
                      p(o).ea_only <= '1';
                      p(o).ea_build_now <= '1';
                      if nextpass = '1' and micro_state = idle then
                        p(o).set.presub <= '1';
                        p(o).setstackaddr <= '1';
                        p(o).setstate <= "11";
                        p(o).next_micro_state <= nop;
                      end if;
                      if p(e).set.get_ea_now = '1' then
                        p(o).setstate <= "01";
                      end if;
                    end if;
                  else
                    if opcode(5 downto 3) = "001" then --link.l
                      p(o).datatype <= "10";
                      p(o).set_exec.opcADD <= '1'; --for displacement
                      p(o).set_exec.Regwrena <= '1';
                      p(o).set.no_Flags <= '1';
                      if decodeOPC = '1' then
                        p(o).set.linksp <= '1';
                        p(o).set.longaktion <= '1';
                        p(o).next_micro_state <= link1;
                        p(o).set.presub <= '1';
                        p(o).setstackaddr <= '1';
                        p(o).set.mem_addsub <= '1';
                        p(o).source_lowbits <= '1';
                        p(o).source_areg <= '1';
                        p(o).set.store_ea_data <= '1';
                      end if;
                    else --nbcd
                      p(o).ea_build_now <= '1';
                      p(o).set_exec.use_XZFlag <= '1';
                      p(o).write_back <= '1';
                      p(o).set_exec.opcADD <= '1';
                      p(o).set_exec.opcSBCD <= '1';
                      p(o).source_lowbits <= '1';
                      if opcode(5 downto 4) = "00" then
                        p(o).set_exec.Regwrena <= '1';
                      end if;
                      if setexecOPC = '1' then
                        p(o).set.OP1out_zero <= '1';
                      end if;
                    end if;
                  end if;
                end if;
              end if;
              --
            when "101" => --tst, tas 4aFC - illegal
              if opcode(7 downto 2) = "111111" then --illegal
                p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
              else
                p(o).ea_build_now <= '1';
                if setexecOPC = '1' then
                  p(o).source_lowbits <= '1';
                  if opcode(3) = '1' then --MC68020...
                    p(o).source_areg <= '1';
                  end if;
                end if;
                p(o).set_exec.opcMOVE<= '1';
                if opcode(7 downto 6) = "11" then --tas
                  p(o).set_exec_tas <= '1';
                  p(o).write_back <= '1';
                  p(o).datatype <= "00"; --Byte
                  if opcode(5 downto 4) = "00" then
                    p(o).set_exec.Regwrena <= '1';
                  end if;
                end if;
              end if;
              ---- when "110"=>
            when "111" => --4EXX
              --
              -- ea_only <= '1';
              -- ea_build_now <= '1';
              -- if nextpass='1' and micro_state=idle then
              -- p(o).set.presub) <= '1';
              -- setstackaddr <='1';
              -- p(o).set.mem_addsub) <= '1';
              -- setstate <="11";
              -- next_micro_state <= nop;
              -- end if;
              -- if p(o).set.get_ea_now)='1' then
              -- setstate <="01";
              -- end if;
              --
              if opcode(7) = '1' then --jsr, jmp
                p(o).datatype <= "10";
                p(o).ea_only <= '1';
                p(o).ea_build_now <= '1';
                if exec.ea_to_pc = '1' then
                  p(o).next_micro_state <= nop;
                end if;
                if nextpass = '1' and micro_state = idle and opcode(6) = '0' then
                  p(o).set.presub <= '1';
                  p(o).setstackaddr <= '1';
                  p(o).setstate <= "11";
                  p(o).next_micro_state <= nopnop;
                end if;

                if micro_state = ld_AnXn1 and brief(8) = '0' then --JMP/JSR n(Ax,Dn)
                  p(o).skipFetch <= '1';
                end if;

                if state = "00" then
                  p(o).writePC <= '1';
                end if;
                p(o).set.hold_dwr <= '1';

                if p(e).set.get_ea_now = '1' then --jsr
                  if exec.longaktion = '0' or long_done = '1' then
                    p(o).skipFetch <= '1';
                  end if;
                  p(o).setstate <= "01";
                  p(o).set.ea_to_pc <= '1';
                end if;
              else --
                case opcode(6 downto 0) is
                  when "1000000" | "1000001" | "1000010" | "1000011" | "1000100" | "1000101" | "1000110" | "1000111" | --trap
                       "1001000" | "1001001" | "1001010" | "1001011" | "1001100" | "1001101" | "1001110" | "1001111" => --trap
                    p(o).trap_trap <= '1'; p(o).trap_make <= '1';
                  when "1010000" | "1010001" | "1010010" | "1010011" | "1010100" | "1010101" | "1010110" | "1010111" => --link
                    p(o).datatype <= "10";
                    p(o).set_exec.opcADD <= '1'; --for displacement
                    p(o).set_exec.Regwrena <= '1';
                    p(o).set.no_Flags <= '1';
                    if decodeOPC = '1' then
                      p(o).next_micro_state <= link1;
                      p(o).set.presub <= '1';
                      p(o).setstackaddr <= '1';
                      p(o).set.mem_addsub <= '1';
                      p(o).source_lowbits <= '1';
                      p(o).source_areg <= '1';
                      p(o).set.store_ea_data <= '1';
                    end if;

                  when "1011000" | "1011001" | "1011010" | "1011011" | "1011100" | "1011101" | "1011110" | "1011111" => --unlink
                    p(o).datatype <= "10";
                    p(o).set_exec.Regwrena <= '1';
                    p(o).set_exec.opcMOVE <= '1';
                    p(o).set.no_Flags <= '1';
                    if decodeOPC = '1' then
                      p(o).setstate <= "01";
                      p(o).next_micro_state <= unlink1;
                      p(o).set.opcMOVE <= '1';
                      p(o).set.Regwrena <= '1';
                      p(o).setstackaddr <= '1';
                      p(o).source_lowbits <= '1';
                      p(o).source_areg <= '1';
                    end if;

                  when "1100000" | "1100001" | "1100010" | "1100011" | "1100100" | "1100101" | "1100110" | "1100111" => --move An,USP
                    if SVmode = '1' then
                      -- p(o).set.no_Flags <= '1';
                      p(o).set.to_USP <= '1';
                      p(o).source_lowbits <= '1';
                      p(o).source_areg <= '1';
                      p(o).datatype <= "10";
                    else
                      p(o).trap_priv <= '1'; p(o).trap_make <= '1';
                    end if;
                  when "1101000" | "1101001" | "1101010" | "1101011" | "1101100" | "1101101" | "1101110" | "1101111" => --move USP,An
                    if SVmode = '1' then
                      -- p(o).set.no_Flags <= '1';
                      p(o).set.from_USP <= '1';
                      p(o).datatype <= "10";
                      p(o).set_exec.Regwrena <= '1';
                    else
                      p(o).trap_priv <= '1'; p(o).trap_make <= '1';
                    end if;

                  when "1110000" => --reset
                    if SVmode = '0' then
                      p(o).trap_priv <= '1'; p(o).trap_make <= '1';
                    else
                      p(o).set.opcRESET <= '1';
                      if decodeOPC = '1' then
                        p(o).set.ld_rot_cnt <= '1';
                        p(o).set_rot_cnt <= "000000";
                      end if;
                    end if;

                  when "1110001" => --nop

                  when "1110010" => --stop
                    if SVmode = '0' then
                      p(o).trap_priv <= '1'; p(o).trap_make <= '1';
                    else
                      if decodeOPC = '1' then
                        p(o).setnextpass <= '1';
                        p(o).set_stop <= '1';
                      end if;
                      if stop = '1' then
                        p(o).skipFetch <= '1';
                      end if;

                    end if;

                  when "1110011" | "1110111" => --rte/rtr
                    if SVmode = '1' or opcode(2) = '1' then
                      if decodeOPC = '1' then
                        p(o).setstate <= "10";
                        p(o).set.postadd <= '1';
                        p(o).setstackaddr <= '1';
                        if opcode(2) = '1' then
                          p(o).set.directCCR <= '1';
                          p(o).next_micro_state <= rtr1;
                        else
                          p(o).set.directSR <= '1';
                          p(o).next_micro_state <= rte1;
                        end if;

                      end if;
                    else
                      p(o).trap_priv <= '1'; p(o).trap_make <= '1';
                    end if;

                  when "1110100" => --rtd
                    if (cpu(0) = '0') then
                      p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
                    else
                      p(o).datatype <= "10";
                      p(o).set_exec.opcADD <= '1'; --for displacement
                      p(o).set_exec.Regwrena <= '1';
                      p(o).set.no_Flags <= '1';
                      if decodeOPC = '1' then
                        p(o).setstate <= "10";
                        p(o).set.postadd <= '1';
                        p(o).setstackaddr <= '1';
                        p(o).set.direct_delta <= '1';
                        p(o).set.directPC <= '1';
                        p(o).next_micro_state <= rtd1;
                      end if;
                    end if;

                  when "1110101" => --rts
                    p(o).datatype <= "10";
                    if decodeOPC = '1' then
                      p(o).setstate <= "10";
                      p(o).set.postadd <= '1';
                      p(o).setstackaddr <= '1';
                      p(o).set.direct_delta <= '1';
                      p(o).set.directPC <= '1';
                      p(o).next_micro_state <= nopnop;
                    end if;

                  when "1110110" => --trapv
                    if decodeOPC = '1' then
                      p(o).setstate <= "01";
                    end if;
                    if Flags(1) = '1' and state = "01" then
                      p(o).set.trap_trapv <= '1'; p(o).trap_make <= '1';
                    end if;

                  when "1111010" | "1111011" => --movec
                    if (cpu(0) = '0') then
                      p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
                    elsif SVmode = '0' then
                      p(o).trap_priv <= '1'; p(o).trap_make <= '1';
                    else
                      p(o).datatype <= "10"; --Long
                      if last_data_read(11 downto 0) = X"800" then
                          p(o).set.from_USP <= '1';
                        if opcode(0) = '1' then
                          p(o).set.to_USP <= '1';
                        end if;
                      end if;
                      if opcode(0) = '0' then
                        p(o).set_exec.movec_rd <= '1';
                      else
                        p(o).set_exec.movec_wr <= '1';
                      end if;
                      if decodeOPC = '1' then
                        p(o).next_micro_state <= movec1;
                        p(o).getbrief <= '1';
                      end if;
                    end if;

                  when others =>
                    p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
                end case;
              end if;
            when others => NULL;
          end case;
        end if;
        --
      -- 0101 ----------------------------------------------------------------------------
      when "0101" => --subq, addq, trapxcc
        if cpu(1)='1' and (opcode(7 downto 1) = "1111101" or opcode(7 downto 0) = "11111100") then -- TRAPcc
          if decodeOPC = '1' then
            p(o).next_micro_state <= nop;
            if (opcode(2) = '1') then
               p(o).setstate <= "01"; -- idle
            else
              p(o).setstate <= "10"; -- read
              if (opcode(0) = '1') then -- long
                p(o).datatype <= "10"; -- long word
              else
                p(o).datatype <= "01"; -- word
              end if;
            end if;
          end if;
        --when trapcc1 => --trapcc
        --if exe_condition = '0' then
            --Regwrena_now <= '1';
            --if c_out(1) = '1' then
              --p(o).skipFetch <= '1';
              --p(o).next_micro_state <= nop;
              --p(o).TG68_PC_brw <= '1';
            --end if;

        elsif opcode(7 downto 6) = "11" then --dbcc
          if opcode(5 downto 3) = "001" then --dbcc
            if decodeOPC = '1' then
              p(o).next_micro_state <= dbcc1;
              p(o).set.OP2out_one <= '1';
              p(o).data_is_source <= '1';
            end if;
          else --Scc
            p(o).datatype <= "00"; --Byte
            p(o).ea_build_now <= '1';
            p(o).write_back <= '1';
            p(o).set_exec.opcScc <= '1';
            if cpu(0) = '1' and state = "10" then
              p(o).skipFetch <= '1';
            end if;
            if opcode(5 downto 4) = "00" then
              p(o).set_exec.Regwrena <= '1';
            end if;
          end if;
        else --addq, subq
          p(o).ea_build_now <= '1';
          if opcode(5 downto 3) = "001" then
            p(o).set.no_Flags <= '1';
          end if;
          if opcode(8) = '1' then
            p(o).set.addsub <= '1';
          end if;
          p(o).write_back <= '1';
          p(o).set_exec.opcADDQ <= '1';
          p(o).set_exec.opcADD <= '1';
          p(o).set_exec.ea_data_OP1 <= '1';
          if opcode(5 downto 4) = "00" then
            p(o).set_exec.Regwrena <= '1';
          end if;
        end if;
        --
        ---- 0110 ----------------------------------------------------------------------------
      when "0110" => --bra,bsr,bcc
        p(o).datatype <= "10";

        if micro_state = idle then
          if opcode(11 downto 8) = "0001" then --bsr
            p(o).set.presub <= '1';
            p(o).setstackaddr <= '1';
            if opcode(7 downto 0) = "11111111" then
              p(o).next_micro_state <= bsr2;
              p(o).set.longaktion <= '1';
            elsif opcode(7 downto 0) = "00000000" then
              p(o).next_micro_state <= bsr2;
            else
              p(o).next_micro_state <= bsr1;
              p(o).setstate <= "11";
              p(o).writePC <= '1';
            end if;
          else --bra
            if opcode(7 downto 0) = "11111111" then
              p(o).next_micro_state <= bra1;
              p(o).set.longaktion <= '1';
            elsif opcode(7 downto 0) = "00000000" then
              p(o).next_micro_state <= bra1;
            else
              p(o).setstate <= "01";
              p(o).next_micro_state <= bra1;
            end if;
          end if;
        end if;
        -- 0111 ----------------------------------------------------------------------------
      when "0111" => --moveq
        -- if opcode(8)='0' then -- Cloanto's Amiga Forver ROMs have mangled movq instructions with a 1 here...
        if trap_interrupt = '0' and trap_trace = '0' then
          p(o).datatype <= "10"; --Long
          p(o).set_exec.Regwrena <= '1';
          p(o).set_exec.opcMOVEQ <= '1';
          p(o).set_exec.opcMOVE <= '1';
          p(o).dest_hbits <= '1';
        end if;
        -- else
        -- trap_illegal <= '1'; -- trap_make <= '1';
        -- end if;
        ---- 1000 ----------------------------------------------------------------------------
      when "1000" => --or
        if opcode(7 downto 6) = "11" then --divu, divs
          if opcode(5 downto 4) = "00" then --Dn, An
            p(o).regdirectsource <= '1';
          end if;
          if (micro_state = idle and nextpass = '1') or (opcode(5 downto 4) = "00" and decodeOPC = '1') then
            p(o).setstate <= "01";
            p(o).next_micro_state <= div1;
          end if;
          p(o).ea_build_now <= '1';
          if z_error = '0' and set_V_Flag = '0' then
            p(o).set_exec.Regwrena <= '1';
          end if;
          p(o).source_lowbits <= '1';
          if nextpass = '1' or (opcode(5 downto 4) = "00" and decodeOPC = '1') then
            p(o).dest_hbits <= '1';
          end if;
          p(o).datatype <= "01";

        elsif opcode(8) = '1' and opcode(5 downto 4) = "00" then --sbcd, pack , unpack
          if opcode(7 downto 6) = "00" then --sbcd
            build_bcd <= '1';
            p(o).set_exec.opcADD <= '1';
            p(o).set_exec.opcSBCD <= '1';
          elsif cpu(1) = '1' and (opcode(7 downto 6) = "01" or opcode(7 downto 6) = "10") then --pack, unpack
            p(o).datatype <= "01"; --Word
            p(o).set_exec.opcPACK <= '1';
            p(o).set.no_Flags <= '1'; -- this command modifies no flags
            -- immediate value is kept in op1
            -- source value is in op2

            if opcode(3) = '0' then -- R/M bit = 0 -> Dy->Dy, 1 -(Ax),-(Ay)
              p(o).dest_hbits <= '1'; -- dest register is encoded in bits 9-11
              p(o).source_lowbits <= '1'; -- source register is encoded in bits 0-2
              p(o).set_exec.Regwrena <= '1'; -- write result into register
              p(o).set_exec.ea_data_OP1 <= '1'; -- immediate value goes into op2
              p(o).set.hold_dwr <= '1';
              -- pack writes a byte only
              if opcode(7 downto 6) = "01" then
                p(o).datatype <= "00"; --Byte
              else
                p(o).datatype <= "01"; --Word
              end if;
              if decodeOPC = '1' then
                p(o).next_micro_state <= nop;
                p(o).set_direct_data <= '1';
              end if;
            else
              p(o).set_exec.ea_data_OP1 <= '1';
              p(o).source_lowbits <= '1'; -- source register is encoded in bits 0-2
              if decodeOPC = '1' then
                -- first step: read source value
                if opcode(7 downto 6) = "10" then -- UNPK reads a byte
                  p(o).datatype <= "00"; -- Byte
                end if;
                p(o).set_direct_data <= '1';
                p(o).setstate <= "10";
                p(o).set.update_ld <= '1';
                p(o).set.presub <= '1';
                p(o).next_micro_state <= pack1;
                p(o).dest_areg <= '1'; --???
              end if;
            end if;
          else
            p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
          end if;
        else --or
          p(o).set_exec.opcor <= '1';
          build_logical <= '1';
        end if;
        ---- 1001, 1101 -----------------------------------------------------------------------
      when "1001" | "1101" => --sub, add
        p(o).set_exec.opcADD <= '1';
        p(o).ea_build_now <= '1';
        if opcode(14) = '0' then
          p(o).set.addsub <= '1';
        end if;

        if opcode(7 downto 6) = "11" then -- --adda, suba
          if opcode(8) = '0' then --adda.w, suba.w
            p(o).datatype <= "01"; --Word
          end if;
          p(o).set_exec.Regwrena <= '1';
          p(o).source_lowbits <= '1';
          if opcode(3) = '1' then
            p(o).source_areg <= '1';
          end if;
          p(o).set.no_Flags <= '1';
          if setexecOPC = '1' then
            p(o).dest_areg <= '1';
            p(o).dest_hbits <= '1';
          end if;
        else
          if opcode(7 downto 6) = "00" and opcode(5 downto 3) = "001" then -- illegal, word/long only
            p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
          end if;

          if opcode(8) = '1' and opcode(5 downto 4) = "00" then --addx, subx
            build_bcd <= '1';
          else --sub, add
            build_logical <= '1';
          end if;
        end if;
        ---- 1010 ----------------------------------------------------------------------------
      when "1010" => --Trap 1010
        p(o).trap_1010 <= '1'; p(o).trap_make <= '1';
        ---- 1011 ----------------------------------------------------------------------------
      when "1011" => --eor, cmp
        p(o).ea_build_now <= '1';
        if opcode(7 downto 6) = "11" then --CMPA
          if opcode(8) = '0' then --cmpa.w
            p(o).datatype <= "01"; --Word
            p(o).set_exec.opcCPMAW <= '1';
          end if;
          p(o).set_exec.opcCMP <= '1';
          if setexecOPC = '1' then
            p(o).source_lowbits <= '1';
            if opcode(3) = '1' then
              p(o).source_areg <= '1';
            end if;
            p(o).dest_areg <= '1';
            p(o).dest_hbits <= '1';
          end if;
          p(o).set.addsub <= '1';
        else
          if opcode(8) = '1' then
            if opcode(5 downto 3) = "001" then --cmpm
              p(o).set_exec.opcCMP <= '1';
              if decodeOPC = '1' then
                p(o).setstate <= "10";
                p(o).set.update_ld <= '1';
                p(o).set.postadd <= '1';
                if opcode(2 downto 0) = "111" then
                  p(o).set.use_SP <= '1';
                end if;
                p(o).next_micro_state <= cmpm;
              end if;
              p(o).set_exec.ea_data_OP1 <= '1';
              p(o).set.addsub <= '1';
            else --Eor
              build_logical <= '1';
              p(o).set_exec.opcEor <= '1';
            end if;
          else --CMP
            build_logical <= '1';
            p(o).set_exec.opcCMP <= '1';
            p(o).set.addsub <= '1';
          end if;
        end if;
        ---- 1100 ----------------------------------------------------------------------------
      when "1100" => --and, exg
        if opcode(7 downto 6) = "11" then --mulu, muls
          if opcode(5 downto 4) = "00" then --Dn, An
            p(o).regdirectsource <= '1';
          end if;
          if (micro_state = idle and nextpass = '1') or (opcode(5 downto 4) = "00" and decodeOPC = '1') then
            p(o).setstate <= "01";
            p(o).set.ld_rot_cnt <= '1';
            p(o).next_micro_state <= mul1;
          end if;
          p(o).ea_build_now <= '1';
          p(o).set_exec.Regwrena <= '1';
          p(o).source_lowbits <= '1';
          if (nextpass = '1') or (opcode(5 downto 4) = "00" and decodeOPC = '1') then
            p(o).dest_hbits <= '1';
          end if;
          p(o).datatype <= "01";

        elsif opcode(8) = '1' and opcode(5 downto 4) = "00" then --exg, abcd
          if opcode(7 downto 6) = "00" then --abcd
            build_bcd <= '1';
            p(o).set_exec.opcADD <= '1';
            p(o).set_exec.opcABCD <= '1';
          else --exg
            p(o).datatype <= "10";
            p(o).set.Regwrena <= '1';
            p(o).set.exg <= '1';
            if opcode(6) = '1' and opcode(3) = '1' then
              p(o).dest_areg <= '1';
              p(o).source_areg <= '1';
            end if;
            if decodeOPC = '1' then
              p(o).setstate <= "01";
            else
              p(o).dest_hbits <= '1';
            end if;
          end if;
        else --and
          p(o).set_exec.opcand <= '1';
          build_logical <= '1';
        end if;
        ---- 1110 ----------------------------------------------------------------------------
      when "1110" => --rotation / bitfield
        if opcode(7 downto 6) = "11" then
          if opcode(11) = '0' then
            p(o).set_exec.opcROT <= '1';
            p(o).ea_build_now <= '1';
            p(o).datatype <= "01";
            p(o).set_rot_bits <= opcode(10 downto 9);
            p(o).set_exec.ea_data_OP1 <= '1';
            p(o).write_back <= '1';
          else --bitfield
            if cpu(1) = '0' then
              p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
            else
              if decodeOPC = '1' then
                p(o).next_micro_state <= nop;
                p(o).set.get_2ndOPC <= '1';
                p(o).set.ea_build <= '1';
              end if;
              p(o).set_exec.opcBF <= '1';

              -- BFCLR, BFSET, BFINS, BFCHG, BFFFO, BFTST
              if opcode(10) = '1' or opcode(8) = '0' then
                p(o).set_exec.opcBFwb <= '1';
                -- BFFFO operating on memory
                if opcode(10 downto 8) = "101" and opcode(4 downto 3) /= "00"  then
                  p(o).set_exec.ea_data_OP2 <= '1';
                end if;
                p(o).set_exec.ea_data_OP1 <= '1';
              end if;
                                                        -- BFCHG, BFCLR, BFSET, BFINS
              if opcode(10 downto 8) = "010" or opcode(10 downto 8) = "100" or
                             opcode(10 downto 8) = "110" or opcode(10 downto 8) = "111" then
                p(o).write_back <= '1';
              end if;
              p(o).ea_only <= '1';
                                                        -- BFEXTU, BFEXTS, BFFFO
              if opcode(10 downto 8) = "001" or opcode(10 downto 8) = "011" or
                             opcode(10 downto 8) = "101" then
                p(o).set_exec.Regwrena <= '1';
              end if;
                                                        -- register destination
              if opcode(4 downto 3) = "00" then
                                -- bftst doesn't write
                                if opcode(10 downto 8) /= "000" then
                p(o).set_exec.Regwrena <= '1';
                                end if;
                if exec.ea_build = '1' then
                  p(o).dest_2ndHbits <= '1';
                  p(o).source_2ndLbits <= '1';
                  p(o).set.get_bfoffset <= '1';
                  p(o).setstate <= "01";
                end if;
              end if;
              if p(e).set.get_ea_now = '1' then
                p(o).setstate <= "01";
              end if;
              if exec.get_ea_now = '1' then
                p(o).dest_2ndHbits <= '1';
                p(o).source_2ndLbits <= '1';
                p(o).set.get_bfoffset <= '1';
                p(o).setstate <= "01";
                p(o).set.mem_addsub <= '1';
                p(o).next_micro_state <= bf1;
              end if;

              if setexecOPC = '1' then
                if opcode(10 downto 8) = "111" then --BFINS
                  p(o).source_2ndHbits <= '1';
                elsif opcode(10 downto 8)="001" or opcode(10 downto 8)="011" or
                                  opcode(10 downto 8)="101" THEN
                  --BFEXTU, BFEXTS, BFFFO
                  p(o).source_lowbits <= '1';
                  p(o).dest_2ndHbits <= '1';
                end if;
              end if;
            end if;
          end if;
        else
          -- register rotation/shift
          p(o).set_exec.opcROT <= '1';
          p(o).set_rot_bits <= opcode(4 downto 3);
          p(o).data_is_source <= '1';
          p(o).set_exec.Regwrena <= '1';
          if decodeOPC = '1' then
            if opcode(5) = '1' then
              -- load rotation count from register
              p(o).next_micro_state <= rota1;
              p(o).set.ld_rot_cnt <= '1';
              p(o).setstate <= "01";
            else
              p(o).set_rot_cnt(2 downto 0) <= opcode(11 downto 9);
              if opcode(11 downto 9) = "000" then
                p(o).set_rot_cnt(3) <= '1';
              else
                p(o).set_rot_cnt(3) <= '0';
              end if;
            end if;
          end if;
        end if;
        ---- ----------------------------------------------------------------------------
      when others =>
        p(o).trap_1111 <= '1'; p(o).trap_make <= '1';
    end case;

  end process;

  -- stage 3 frigging
  process(cpu, state, opcode, decodeOPC, addr, setexecOPC, trapd, build_logical, build_bcd, p)
    constant i : integer := 2;
    constant o : integer := 3;
    constant e : integer := 4;
  begin
    -- STAGE 2
    p(o) <= p(i);

    -- use for and, or, Eor, CMP
    if build_logical = '1' then
      p(o).ea_build_now <= '1';
      if p(i).set_exec.opcCMP = '0' and (opcode(8) = '0' or opcode(5 downto 4) = "00" ) then
        p(o).set_exec.Regwrena <= '1';
      end if;
      if opcode(8) = '1' then
        p(o).write_back <= '1';
        p(o).set_exec.ea_data_OP1 <= '1';
      else
        p(o).source_lowbits <= '1';
        if opcode(3) = '1' then --use for cmp
          p(o).source_areg <= '1';
        end if;
        if setexecOPC = '1' then
          p(o).dest_hbits <= '1';
        end if;
      end if;
    end if;

    -- use for ABCD, SBCD, ADDX, SUBX
    if build_bcd = '1' then
      p(o).set_exec.use_XZFlag <= '1';
      p(o).set_exec.ea_data_OP1 <= '1';
      p(o).write_back <= '1';
      p(o).source_lowbits <= '1';
      if opcode(3) = '1' then
        if decodeOPC = '1' then
          p(o).setstate <= "10";
          p(o).set.update_ld <= '1';
          p(o).set.presub <= '1';
          if opcode(2 downto 0) = "111" then
            p(o).set.use_SP <= '1';
          end if;
          p(o).next_micro_state <= op_AxAy;
          p(o).dest_areg <= '1'; --???
        end if;
      else
        p(o).dest_hbits <= '1';
        p(o).set_exec.Regwrena <= '1';
      end if;
    end if;

    if p(e).set_Z_error = '1' then -- divu by zero  set_Z_error be moved?
      p(o).trap_make <= '1';
      if trapd = '0' then
        p(o).writePC <= '1';
      end if;
    end if;

    -- address trap for unaligned access
    if (addr(0) = '1') then
      if (cpu(1) = '1') then -- 020
        if (state = "00") then
          p(o).trap_addr_error <= '1'; p(o).trap_make <= '1';
         end if;
      else
        if (state /= "01") then
           p(o).trap_addr_error <= '1'; p(o).trap_make <= '1';
        end if;
      end if;
    end if;
  end process;

  process (micro_state, cpu, opcode, last_data_read, OP2out, rot_cnt, trap_interrupt, trap_7word, trap_trace, brief,
           exec, sndOPC, exe_condition, long_start, c_out, movem_run, last_data_in, p(3))
    constant i : integer := 3;
    constant o : integer := 4;
  begin
    -- STAGE 3
    p(o) <= p(i);
    Regwrena_now <= '0';

    case micro_state is
      -- fetch modes
      when ld_nn => -- (nnnn).w/l=>
        p(o).set.get_ea_now <= '1';
        p(o).set.addrlong <= '1';
        p(o).setnextpass <= '1';

      when st_nn => -- =>(nnnn).w/l
        p(o).set.addrlong <= '1';
        p(o).setstate <= "11";
        p(o).next_micro_state <= nop;

      when ld_dAn1 => -- d(An)=>, --d(PC)=>
        p(o).set.get_ea_now <= '1';
        p(o).setdisp <= '1'; --word
        p(o).setnextpass <= '1';

      when ld_AnXn1 => -- d(An,Xn)=>, --d(PC,Xn)=>  starts here with decoding brief
        if brief(8) = '0' or (cpu(1) = '0') then
          -- mikej brief extension word only
          p(o).setdisp <= '1'; --byte
          p(o).setdispbyte <= '1';
          p(o).setstate <= "01";
          p(o).set.briefext <= '1';
          p(o).next_micro_state <= ld_AnXn2;
        else
          if brief(7) = '1' then --suppress Base
            p(o).set_suppress_base <= '1';
          elsif exec.dispouter = '1' then
            p(o).set.dispouter <= '1';
          end if;
          if brief(5) = '0' then --NULL Base Displacement
            p(o).setstate <= "01";
          else --Word Base Displacement
            if brief(4) = '1' then
              p(o).set.longaktion <= '1'; --LONG Base Displacement
            end if;
          end if;
          p(o).next_micro_state <= ld_229_1;
        end if;

      when ld_AnXn2 =>   -- does the actuall final read
        p(o).set.get_ea_now <= '1';
        p(o).setdisp <= '1'; --brief
        p(o).setnextpass <= '1';

       -------------------------------------------------------------------------------------

      when ld_229_1 => -- (bd,An,Xn)=>, --(bd,PC,Xn)=>
        if brief(5) = '1' then --Base Displacement
          p(o).setdisp <= '1'; --add last_data_read
        end if;
        if brief(6) = '0' and brief(2) = '0' then --Preindex or Index
          p(o).set.briefext <= '1';
          p(o).setstate <= "01";
          if brief(1 downto 0) = "00" then
            p(o).next_micro_state <= ld_AnXn2;
          else
            p(o).next_micro_state <= ld_229_2;
          end if;
        else
          if brief(1 downto 0) = "00" then
            p(o).set.get_ea_now <= '1';
            p(o).setnextpass <= '1';
          else
            p(o).setstate <= "10";
            p(o).set.longaktion <= '1';
            p(o).next_micro_state <= ld_229_3;
          end if;
        end if;

      when ld_229_2 => -- (bd,An,Xn)=>, --(bd,PC,Xn)=>
        p(o).setdisp <= '1'; -- add Index
        p(o).setstate <= "10";
        p(o).set.longaktion <= '1';
        p(o).next_micro_state <= ld_229_3;

      when ld_229_3 => -- (bd,An,Xn)=>, --(bd,PC,Xn)=>
        p(o).set_suppress_base <= '1';
        p(o).set.dispouter <= '1';
        if brief(1) = '0' then --NULL Outer Displacement
          p(o).setstate <= "01";
        else --WORD Outer Displacement
          if brief(0) = '1' then
            p(o).set.longaktion <= '1'; --LONG Outer Displacement
          end if;
        end if;
        p(o).next_micro_state <= ld_229_4;

      when ld_229_4 => -- (bd,An,Xn)=>, --(bd,PC,Xn)=>
        if brief(1) = '1' then -- Outer Displacement
          p(o).setdisp <= '1'; --add last_data_read
        end if;
        if brief(6) = '0' and brief(2) = '1' then --Postindex
          p(o).set.briefext <= '1';
          p(o).setstate <= "01";
          p(o).next_micro_state <= ld_AnXn2; -- go get it
        else
          p(o).set.get_ea_now <= '1';
          p(o).setnextpass <= '1';
        end if;

        ----------------------------------------------------------------------------------------
      when st_dAn1 => -- =>d(An)
        p(o).setstate <= "11";
        p(o).setdisp <= '1'; --word
        p(o).next_micro_state <= nop;

      when st_AnXn1 => -- =>d(An,Xn)
        if brief(8) = '0' or (cpu(1) = '0') then
          p(o).setdisp <= '1'; --byte
          p(o).setdispbyte <= '1';
          p(o).setstate <= "01";
          p(o).set.briefext <= '1';
          p(o).next_micro_state <= st_AnXn2;
        else
          if brief(7) = '1' then --suppress Base
            p(o).set_suppress_base <= '1';
            -- elsif exec(dispouter)='1' then
            -- set.dispouter) <= '1';
          end if;
          if brief(5) = '0' then --NULL Base Displacement
            p(o).setstate <= "01";
          else --WorD Base Displacement
            if brief(4) = '1' then
              p(o).set.longaktion <= '1'; --LONG Base Displacement
            end if;
          end if;
          p(o).next_micro_state <= st_229_1;
        end if;

      when st_AnXn2 =>
        p(o).setstate <= "11";
        p(o).setdisp <= '1'; --brief
        p(o).next_micro_state <= nop;

        -------------------------------------------------------------------------------------

      when st_229_1 => -- (bd,An,Xn)=>, --(bd,PC,Xn)=>
        if brief(5) = '1' then --Base Displacement
          p(o).setdisp <= '1'; --add last_data_read
        end if;
        if brief(6) = '0' and brief(2) = '0' then --Preindex or Index
          p(o).set.briefext <= '1';
          p(o).setstate <= "01";
          if brief(1 downto 0) = "00" then
            p(o).next_micro_state <= st_AnXn2;
          else
            p(o).next_micro_state <= st_229_2;
          end if;
        else
          if brief(1 downto 0) = "00" then
            p(o).setstate <= "11";
            p(o).next_micro_state <= nop;
          else
            p(o).set.hold_dwr <= '1';
            p(o).setstate <= "10";
            p(o).set.longaktion <= '1';
            p(o).next_micro_state <= st_229_3;
          end if;
        end if;

      when st_229_2 => -- (bd,An,Xn)=>, --(bd,PC,Xn)=>
        p(o).setdisp <= '1'; -- add Index
        p(o).set.hold_dwr <= '1';
        p(o).setstate <= "10";
        p(o).set.longaktion <= '1';
        p(o).next_micro_state <= st_229_3;

      when st_229_3 => -- (bd,An,Xn)=>, --(bd,PC,Xn)=>
        p(o).set.hold_dwr <= '1';
        p(o).set_suppress_base <= '1';
        p(o).set.dispouter <= '1';
        if brief(1) = '0' then --NULL Outer Displacement
          p(o).setstate <= "01";
        else --WorD Outer Displacement
          if brief(0) = '1' then
            p(o).set.longaktion <= '1'; --LONG Outer Displacement
          end if;
        end if;
        p(o).next_micro_state <= st_229_4;

      when st_229_4 => -- (bd,An,Xn)=>, --(bd,PC,Xn)=>
        p(o).set.hold_dwr <= '1';
        if brief(1) = '1' then -- Outer Displacement
          p(o).setdisp <= '1'; --add last_data_read
        end if;
        if brief(6) = '0' and brief(2) = '1' then --Postindex
          p(o).set.briefext <= '1';
          p(o).setstate <= "01";
          p(o).next_micro_state <= st_AnXn2;
        else
          p(o).setstate <= "11";
          p(o).next_micro_state <= nop;
        end if;

        ----------------------------------------------------------------------------------------
      when bra1 => --bra
        if exe_condition = '1' then
          p(o).TG68_PC_brw <= '1'; --pc+0000
          p(o).next_micro_state <= nop;
          p(o).skipFetch <= '1';
        end if;

      when bsr1 => --bsr short
        p(o).TG68_PC_brw <= '1';
        p(o).next_micro_state <= nop;

      when bsr2 => --bsr
        if long_start = '0' then
          p(o).TG68_PC_brw <= '1';
        end if;
        p(o).skipFetch <= '1';
        p(o).set.longaktion <= '1';
        p(o).writePC <= '1';
        p(o).setstate <= "11";
        p(o).next_micro_state <= nopnop;
        p(o).setstackaddr <= '1';

      when nopnop => --bsr
        p(o).next_micro_state <= nop;

      when dbcc1 => --dbcc
        if exe_condition = '0' then
          Regwrena_now <= '1';
          if c_out(1) = '1' then
            p(o).skipFetch <= '1';
            p(o).next_micro_state <= nop;
            p(o).TG68_PC_brw <= '1';
          end if;
        end if;

      when movem1 => --movem
        if last_data_read(15 downto 0) /= X"0000" then
            p(o).setstate <= "01";
          if opcode(5 downto 3) = "100" then
            p(o).set.mem_addsub <= '1';
          end if;
          p(o).next_micro_state <= movem2;
        end if;

      when movem2 => --movem
        if movem_run = '0' then
          p(o).setstate <= "01";
        else
          p(o).set.movem_action <= '1';
          p(o).set.mem_addsub <= '1';
          p(o).next_micro_state <= movem2;
          if opcode(10) = '0' then
            p(o).setstate <= "11";
            p(o).set.write_reg <= '1';
          else
            p(o).setstate <= "10";
          end if;
        end if;

      when andi => --andi
        if opcode(5 downto 4) /= "00" then
          p(o).setnextpass <= '1';
        end if;

      when op_AxAy => -- op -(Ax),-(Ay)
        p(o).set_direct_data <= '1';
        p(o).set.presub <= '1';
        if opcode(11 downto 9) = "111" then
          p(o).set.use_SP <= '1';
        end if;
        p(o).dest_hbits <= '1';
        p(o).dest_areg <= '1';
        p(o).setstate <= "10";

      when cmpm => -- cmpm (Ay)+,(Ax)+
        p(o).set_direct_data <= '1';
        p(o).set.postadd <= '1';
        if opcode(11 downto 9) = "111" then
          p(o).set.use_SP <= '1';
        end if;
        p(o).dest_hbits <= '1';
        p(o).dest_areg <= '1';
        p(o).setstate <= "10";

      when link1 => -- link
        p(o).setstate <= "11";
        p(o).source_areg <= '1';
        p(o).set.opcMOVE <= '1';
        p(o).set.Regwrena <= '1';
        p(o).next_micro_state <= link2;
      when link2 => -- link
        p(o).setstackaddr <= '1';
        p(o).set.ea_data_OP2 <= '1';

      when unlink1 => -- unlink
        p(o).setstate <= "10";
        p(o).setstackaddr <= '1';
        p(o).set.postadd <= '1';
        p(o).next_micro_state <= unlink2;

      when unlink2 => -- unlink
        p(o).set.ea_data_OP2 <= '1';

      when trap00 =>          -- TRAP format #2
        p(o).next_micro_state <= trap0;
        p(o).set.presub <= '1';
        p(o).setstackaddr <='1';
        p(o).setstate <= "11";
        p(o).datatype <= "10";

      when trap0 => -- TRAP
        p(o).set.presub <= '1';
        p(o).setstackaddr <= '1';
        p(o).setstate <= "11";
        if (cpu(0) = '1') then --68010 or 68020 extra word. writePC_add was set before for 68000
          p(o).set.writePC_add <= '1';
          p(o).datatype <= "01";
          p(o).next_micro_state <= trap1;
        else
          --if trap_interrupt='1' or trap_trace='1' or trap_berr='1' then
          --if trap_interrupt='1' or trap_trace='1' then
            p(o).writePC <= '1';
          --end if;
          p(o).datatype <= "10";
          p(o).next_micro_state <= trap2;
        end if;

      when trap1 => -- TRAP
        -- ONLY here for 68010/20 (format/vector word)
        if trap_interrupt = '1' or trap_trace = '1' then
          p(o).writePC <= '1';
        end if;
        p(o).set.presub <= '1';
        p(o).setstackaddr <= '1';
        p(o).setstate <= "11";
        p(o).datatype <= "10";
        p(o).next_micro_state <= trap2;

      when trap2 => -- TRAP
        p(o).set.presub <= '1';
        p(o).setstackaddr <= '1';
        p(o).setstate <= "11";
        p(o).datatype <= "01";
        p(o).writeSR <= '1';
        if trap_7word='1' then -- 7 word berr/addr frame for 68000 only
          p(o).next_micro_state <= trap4;
        else
          p(o).next_micro_state <= trap3;
        end if;

      when trap3 => -- TRAP
        p(o).set_vectoraddr <= '1';
        p(o).datatype <= "10";
        p(o).set.direct_delta <= '1';
        p(o).set.directPC <= '1';
        p(o).setstate <= "10";
        p(o).next_micro_state <= nopnop;

      when trap4 =>           -- TRAP
        p(o).set.presub <= '1';
        p(o).setstackaddr <='1';
        p(o).setstate <= "11";
        p(o).datatype <= "01";
        p(o).writeSR <= '1';
        p(o).next_micro_state <= trap5;

      when trap5 =>           -- TRAP
        p(o).set.presub <= '1';
        p(o).setstackaddr <='1';
        p(o).setstate <= "11";
        p(o).datatype <= "10";
        p(o).writeSR <= '1';
        p(o).next_micro_state <= trap6;

      when trap6 =>           -- TRAP
        p(o).set.presub <= '1';
        p(o).setstackaddr <='1';
        p(o).setstate <= "11";
        p(o).datatype <= "01";
        p(o).writeSR <= '1';
        p(o).next_micro_state <= trap3;

      when rtr1 => -- RTR
        p(o).datatype <= "10";
        p(o).setstate <= "10";
        p(o).set.postadd <= '1';
        p(o).setstackaddr <= '1';
        p(o).set.direct_delta <= '1';
        p(o).set.directPC <= '1';
        p(o).next_micro_state <= nopnop;

        -- return from exception - RTE
      -- fetch PC and status register from stack
      -- 010+ fetches another word containing
      -- the 12 bit vector offset and the
      -- frame format. If the frame format is
      -- 2 another two words have to be taken
      -- from the stack
      when rte1 => -- RTE
        p(o).datatype <= "10";
        p(o).setstate <= "10";
        p(o).set.postadd <= '1';
        p(o).setstackaddr <= '1';
        if (cpu(0) = '0') then
          p(o).set.direct_delta <= '1';
        end if;
        p(o).set.directPC <= '1';
        p(o).next_micro_state <= rte2;

      when rte2 => -- RTE
        p(o).datatype <= "01";
        p(o).set.update_FC <= '1';
        if (cpu(0) = '1') then  -- 010+ reads another word
          p(o).setstate <= "10";
          p(o).set.postadd <= '1';
          p(o).setstackaddr <= '1';
          p(o).next_micro_state <= rte3;
        else
          p(o).next_micro_state <= nop;
        end if;

      when rte3 => -- RTE
         p(o).setstate <= "01"; -- idle state to wait for input data to arrive
         p(o).next_micro_state <= rte4;

      when rte4 =>            -- RTE -- check for stack frame format #2
         if last_data_in(15 downto 12)="0010" then -- read another 32 bits in this case
           p(o).setstate <= "10"; -- read
           p(o).datatype <= "10"; -- long word
           p(o).set.postadd <= '1';
           p(o).setstackaddr <= '1';
           p(o).next_micro_state <= rte5;
         else
           p(o).datatype <= "01";
           p(o).next_micro_state <= nop;
         end if;

      when rte5 =>            -- RTE
        p(o).next_micro_state <= nop;

      when rtd1 => -- RTD
        p(o).set.store_ea_data <= '1';
        p(o).next_micro_state <= rtd2;

      when rtd2 => -- RTD
        p(o).setstackaddr <= '1';
        p(o).set.ea_data_OP2 <= '1';

      when movec1 => -- MOVEC
        p(o).set.briefext <= '1';
        p(o).set_writePCbig <= '1';
        if (brief(11 downto 0) = X"000" or brief(11 downto 0) = X"001" or brief(11 downto 0) = X"800" or brief(11 downto 0) = X"801") or
           (cpu(1) = '1' and (brief(11 downto 0) = X"002" or brief(11 downto 0) = X"802" or brief(11 downto 0) = X"803" or brief(11 downto 0) = X"804")) then
            if opcode(0) = '0' then
              p(o).set.Regwrena <= '1';
            end if;
          -- elsif brief(11 downto 0)=X"800"or brief(11 downto 0)=X"001" or brief(11 downto 0)=X"000" then
          -- trap_addr_error <= '1';
          -- trapmake <= '1';
        else
          p(o).trap_illegal <= '1'; p(o).trap_make <= '1';
        end if;

      when movep1 => -- MOVEP d(An)
        p(o).setdisp <= '1';
        p(o).set.mem_addsub <= '1';
        p(o).set.mem_byte <= '1';
        p(o).set.OP1addr <= '1';
        if opcode(6) = '1' then
          p(o).set.movepl <= '1';
        end if;
        if opcode(7) = '0' then
          p(o).setstate <= "10";
        else
          p(o).setstate <= "11";
        end if;
        p(o).next_micro_state <= movep2;

      when movep2 =>
        if opcode(6) = '1' then
          p(o).set.mem_addsub <= '1';
          p(o).set.OP1addr <= '1';
        end if;
        if opcode(7) = '0' then
          p(o).setstate <= "10";
        else
          p(o).setstate <= "11";
        end if;
        p(o).next_micro_state <= movep3;

      when movep3 =>
        if opcode(6) = '1' then
          p(o).set.mem_addsub <= '1';
          p(o).set.OP1addr <= '1';
          p(o).set.mem_byte <= '1';
          if opcode(7) = '0' then
            p(o).setstate <= "10";
          else
            p(o).setstate <= "11";
          end if;
          p(o).next_micro_state <= movep4;
        else
          p(o).datatype <= "01"; --Word
        end if;

      when movep4 =>
        if opcode(7) = '0' then
          p(o).setstate <= "10";
        else
          p(o).setstate <= "11";
        end if;
        p(o).next_micro_state <= movep5;
      when movep5 =>
        p(o).datatype <= "10"; --Long

      when mul1 => -- mulu
        if opcode(15) = '1' then
          p(o).set_rot_cnt <= "001110";
        else
          p(o).set_rot_cnt <= "011110";
        end if;
        p(o).setstate <= "01";
        p(o).next_micro_state <= mul2;

      when mul2 => -- mulu
        p(o).setstate <= "01";
        if rot_cnt = "000001" then
          --p(o).next_micro_state <= mul_end1;
          p(o).next_micro_state <= mul_w;
        else
          p(o).next_micro_state <= mul2;
        end if;

      when mul_w => -- mulu  wait state for timing and bug fix, see alu
        p(o).setstate <= "01";
        p(o).next_micro_state <= mul_end1;

      when mul_end1 => -- mulu
        p(o).datatype <= "10";
        p(o).set.opcMULU <= '1';
        if opcode(15) = '0' then
          p(o).dest_2ndHbits <= '1';
          p(o).source_2ndLbits <= '1';
          p(o).set.write_lowlong <= '1';
          if sndOPC(10) = '1' then
            p(o).setstate <= "01";
            p(o).next_micro_state <= mul_end2;
          end if;
          p(o).set.Regwrena <= '1';
        end if;
        p(o).datatype <= "10";

      when mul_end2 => -- divu
        p(o).set.write_reminder <= '1';
        p(o).set.Regwrena <= '1';
        p(o).set.opcMULU <= '1';

      when div1 => -- divu
        p(o).setstate <= "01";
        p(o).next_micro_state <= div2;

      when div2 => -- divu
        if (OP2out(31 downto 16) = x"0000" or opcode(15) = '1') and OP2out(15 downto 0) = x"0000" then --div zero
          p(o).set_Z_error <= '1';
        else
          p(o).next_micro_state <= div3;
        end if;
        p(o).set.ld_rot_cnt <= '1';
        p(o).setstate <= "01";

      when div3 => -- divu
        if opcode(15) = '1' then
          p(o).set_rot_cnt <= "001101";
        else
          p(o).set_rot_cnt <= "011101";
        end if;
        p(o).setstate <= "01";
        p(o).next_micro_state <= div4;

      when div4 => -- divu
        p(o).setstate <= "01";
        if rot_cnt = "000001" then
          p(o).next_micro_state <= div_end1;
        else
          p(o).next_micro_state <= div4;
        end if;

      when div_end1 => -- divu
        if opcode(15) = '0' then
          p(o).set.write_reminder <= '1';
          p(o).next_micro_state <= div_end2;
          p(o).setstate <= "01";
        end if;
        p(o).set.opcDIVU <= '1';
        p(o).datatype <= "10";

      when div_end2 => -- divu
        p(o).dest_2ndHbits <= '1';
        p(o).source_2ndLbits <= '1';--???
        p(o).set.opcDIVU <= '1';

      when rota1 =>
        if OP2out(5 downto 0) /= "000000" then
          p(o).set_rot_cnt <= OP2out(5 downto 0);
        else
          p(o).set_exec.rot_nop <= '1';
        end if;

      when bf1 =>
        p(o).setstate <= "10";

      when pack1 =>
        -- result computation
        if opcode(7 downto 6) = "10" then -- UNPK reads a byte
          p(o).datatype <= "00"; -- Byte
        end if;
        p(o).set.ea_data_OP2 <= '1';
        p(o).set.opcPACK <= '1';
        p(o).next_micro_state <= pack2;

      when pack2 =>
        -- write result
        if opcode(7 downto 6) = "01" then -- PACK writes a byte
          p(o).datatype <= "00";
        end if;
        p(o).set.presub <= '1';
        if opcode(11 downto 9) = "111" then
          p(o).set.use_SP <= '1';
        end if;
        p(o).setstate <= "11";
        p(o).dest_hbits <= '1';
        p(o).dest_areg <= '1';
        p(o).next_micro_state <= pack3;

      when pack3 =>
        -- this is just to keep datatype == 00
        -- for byte writes
        -- write result
        if opcode(7 downto 6) = "01" then -- PACK writes a byte
          p(o).datatype <= "00";
        end if;

      when upperbound => -- cas2/cmp2/chk2 second fetch
        p(o).next_micro_state <= upperbound2;
        -- set state to 00, will be caught and last cycle set to 1 at top level
        --p(o).setstate <= "01";

      -- using these as sequencer states/debug. Could be optimized
      when upperbound2 =>
      when cas =>
      when cas_eq =>
      when cas_neq =>

      when cas2_1 =>
        p(o).next_micro_state <= cas2_2;
      when cas2_2 =>
        p(o).next_micro_state <= cas2_3;
      when cas2_3 =>
        p(o).next_micro_state <= cas2_4;
      when cas2_4 =>
        p(o).next_micro_state <= cas2_5;
      when cas2_5 =>
        p(o).next_micro_state <= cas2_6;

      when others => NULL;
    end case;
  end process;

  o_skipFetch              <= p(4).skipFetch;

  o_next_micro_state       <= p(4).next_micro_state;
  o_set                    <= p(4).set;
  o_set_exec               <= p(4).set_exec;
  o_setnextpass            <= p(4).setnextpass;
  o_setstate               <= p(4).setstate;

  o_getbrief               <= p(4).getbrief;

  o_setstackaddr           <= p(4).setstackaddr;
  o_set_Suppress_Base      <= p(4).set_Suppress_Base;
  o_set_PCbase             <= p(4).set_PCbase;
  o_set_direct_data        <= p(4).set_direct_data;
  o_datatype               <= p(4).datatype;
  o_set_rot_cnt            <= p(4).set_rot_cnt;
  o_set_rot_bits           <= p(4).set_rot_bits;
  o_set_stop               <= p(4).set_stop;

  o_movem_presub           <= p(4).movem_presub;
  o_regdirectsource        <= p(4).regdirectsource;
  o_dest_areg              <= p(4).dest_areg;
  o_source_areg            <= p(4).source_areg;
  o_data_is_source         <= p(4).data_is_source;
  o_write_back             <= p(4).write_back;
  o_writePC                <= p(4).writePC;
  o_ea_only                <= p(4).ea_only;
  o_source_lowbits         <= p(4).source_lowbits;
  o_source_2ndHbits        <= p(4).source_2ndHbits;
  o_source_2ndMbits        <= p(4).source_2ndMbits;
  o_source_2ndLbits        <= p(4).source_2ndLbits;
  o_source_briefMbits      <= p(4).source_briefMbits;
  o_dest_2ndHbits          <= p(4).dest_2ndHbits;
  o_dest_2ndLbits          <= p(4).dest_2ndLbits;
  o_dest_hbits             <= p(4).dest_hbits;
  o_set_exec_tas           <= p(4).set_exec_tas;
  o_trapmake               <= p(4).trap_make;
  o_trap_illegal           <= p(4).trap_illegal;
  o_trap_addr_error        <= p(4).trap_addr_error;
  o_trap_priv              <= p(4).trap_priv;
  o_trap_1010              <= p(4).trap_1010;
  o_trap_1111              <= p(4).trap_1111;
  o_trap_trap              <= p(4).trap_trap;
  o_set_Z_error            <= p(4).set_Z_error;
  o_writeSR                <= p(4).writeSR;
  o_set_vectoraddr         <= p(4).set_vectoraddr;
  o_set_writePCbig         <= p(4).set_writePCbig;
  o_TG68_PC_brw            <= p(4).TG68_PC_brw;

  o_setdispbyte            <= p(4).setdispbyte;
  o_setdisp                <= p(4).setdisp;
  o_Regwrena_now           <= Regwrena_now;
end;

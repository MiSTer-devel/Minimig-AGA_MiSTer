// Copyright 2011, 2012 Frederic Requin
//
// This file is part of the MCC216 project
//
// J68 is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// J68 is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// The J68 microcode

///////////////////////////////////////
// 0100.111001.110000 : RESET opcode //
///////////////////////////////////////
Op_RESET:
  LIT    #0
  LOOP16                       // Loop 16 times
  WRW    RH[CNT]               // Clear register high
  WRW    RL[CNT]               // Clear register low
  ENDLOOP
  STW    VECL                  // Point to $00000000
  LDW    (VEC)+                // Load SSP high word from memory
  WRW    SSPH                  // into SSP MSW
  STW    A7H                   // into A7 MSW
  LDW    (VEC)+                // Load SSP low word from memory
  WRW    SSPL                  // into SSP LSW
  STW    A7L                   // into A7 LSW
  LIT    #$2704                // Supervisor mode, no interrupt
  CALL   Resume_Exec           // Write SR, get PC from vector

/////////////////////////
// Instruction decoder //
/////////////////////////

Decode:
  FTI    (PC)+                 // Fetch instruction
  NOP
  LDW    DECJ                  // Load subroutine index
  CALL   $0000(T)              // Call sub-routine
  JUMPN  I_SR,Decode           // Decode next instruction if no interrupt/trap

/////////////////////////////////
// Interrupts/Traps management //
/////////////////////////////////

  JUMP   T_SR,Trap_Trace       // Trace exception
  JUMP   A_SR,Trap_Address     // Adress error exception
  
  CALL   Enter_Super           // Enter supervisor mode (if necessary)
  CALL   PC_SR_to_Stack        // Save PC and SR to stack
  CALL   SR_Super              // Modify SR (T clear, S set)
  LIT    #$20FF                // Mask for interrupt level in SR
  ANDW                         // Clear interrupt level
  LDW    VECL                  // Get interrupt level from vector
  ORW                          // Update interrupt level
  CALL   Resume_Exec           // Write SR, get PC from vector
  JUMP   Decode                // Back to the instruction decoder

Trap_Trace:
  LIT    #$0024                // Trace set : use trap vector 0x24
  CALL   Trap_Processing       // Process exception
  JUMP   Decode                // Back to the instruction decoder
  
Trap_Address:
  LIT    #$000C                // Set trap vector to 0x0C
  STW    VECL
  CALL   Enter_Super           // Enter supervisor mode (if necessary)
  CALL   PC_SR_to_Stack        // Save PC and SR to stack
  LDW    CPUS
  STW    -(EA2)                // Instruction -> -(EA2)
  LDW    CPUS
  STW    -(EA2)                // Address low -> -(EA2)
  LDW    CPUS
  STW    -(EA2)                // Address high -> -(EA2)
  LDW    CPUS
  STW    -(EA2)                // CPU state -> -(EA2)
  CALL   EA2_to_SP             // EA2 -> SP
  CALL   SR_Super              // Modify SR (T clear, S set)
  CALL   Resume_Exec           // Write SR, get PC from vector
  JUMP   Decode                // Back to the instruction decoder

Trap_LineF:
  LIT    #$002C                // Set trap vector to 0x2C
  JUMP   Trap_Processing       // Process exception

Trap_LineA:
  LIT    #$0028                // Set trap vector to 0x28
  JUMP   Trap_Processing       // Process exception

Trap_DivZero:
  LIT    #$0014                // Set trap vector to 0x14
  JUMP   Trap_Processing       // Process exception

Trap_Privileged:
  LIT    #$0020                // Set trap vector to 0x20
  JUMP   Trap_Processing       // Process exception

Trap_Illegal:
  LDW    PCH                   // Load PC high word
  LDW    PCL                   // Load PC low word
  LIT    #$FFFE                // Value -2
  CALL   AddVal                // Subtract 2 from PC
  STW    PCH                   // Change PCH
  STW    PCL                   // Change PCL
  LIT    #$0010                // Set trap vector to 0x10

Trap_Processing:
  STW    VECL
  CALL   Enter_Super           // Enter supervisor mode (if necessary)
  CALL   PC_SR_to_Stack        // Save PC and SR to stack
  CALL   SR_Super              // Modify SR (T clear, S set)
  JUMP   Resume_Exec           // Write SR, get PC from vector

///////////////////////////////////////
// 0000.000000.xxxxxx : ORI.B opcode //
///////////////////////////////////////
Op_ORIB:
  LDW    (PC)+                 // Read immediate value
  CALL   EA1_Read_B            // Read byte from effective address
  ORB.                         // OR it with the immediate value
  FLAG   -**00,CIN=CLR         // Update N and Z, clear V and C
  JUMP   EA1_Update_B          // Write back result

/////////////////////////////////////////
// 0000.000000.111100 : ORI CCR opcode //
/////////////////////////////////////////
Op_ORI_CCR:
  LDW    (PC)+                 // Read immediate value
  LDB    SR                    // Read SR
  ORB                          // OR CCR with the immediate value
  STB    SR RTS                // Update SR

///////////////////////////////////////
// 0000.000001.xxxxxx : ORI.W opcode //
///////////////////////////////////////
Op_ORIW:
  LDW    (PC)+                 // Read immediate value
  CALL   EA1_Read_W            // Read word from effective address
  ORW.                         // OR it with the immediate value
  FLAG   -**00,CIN=CLR         // Update N and Z, clear V and C
  JUMP   EA1_Update_W          // Write back result

////////////////////////////////////////
// 0000.000001.111100 : ORI SR opcode //
////////////////////////////////////////
Op_ORI_SR:
  LDW    (PC)+                 // Read immediate value
  LDW    SR                    // Read SR
  ORW                          // OR it with the immediate value
  STW    SR                    // Update SR
  JUMP   Leave_Super           // Super <-> User switch

///////////////////////////////////////
// 0000.000010.xxxxxx : ORI.L opcode //
///////////////////////////////////////
Op_ORIL:
  CALL   EA1_RL_to_TMP1        // Immediate -> TMP1, read long from EA
  ORW.                         // OR EA LSW with immediate LSW
  SWAP                         // Get EA MSW
  LDW    TMP1H                 // Get immediate MSW
  ORL.                         // OR EA MSW with immediate MSW
  FLAG   -**00,CIN=CLR         // Update N and Z, clear V and C
  JUMP   EA1_Update_L          // Write back result

////////////////////////////////////////
// 0000.001000.xxxxxx : ANDI.B opcode //
////////////////////////////////////////
Op_ANDIB:
  LDW    (PC)+                 // Read immediate value
  CALL   EA1_Read_B            // Read byte from effective address
  ANDB.                        // AND it with the immediate value
  FLAG   -**00,CIN=CLR         // Update N and Z, clear V and C
  JUMP   EA1_Update_B          // Write back result

//////////////////////////////////////////
// 0000.001000.111100 : ANDI CCR opcode //
//////////////////////////////////////////
Op_ANDI_CCR:
  LDW    (PC)+                 // Read immediate value
  LDB    SR                    // Read CCR
  ANDB                         // AND CCR with the immediate value
  STB    SR RTS                // Update CCR

////////////////////////////////////////
// 0000.001001.xxxxxx : ANDI.W opcode //
////////////////////////////////////////
Op_ANDIW:
  LDW    (PC)+                 // Read immediate value
  CALL   EA1_Read_W            // Read word from effective address
  ANDW.                        // AND it with the immediate value
  FLAG   -**00,CIN=CLR         // Update N and Z, clear V and C
  JUMP   EA1_Update_W          // Write back result

/////////////////////////////////////////
// 0000.001001.111100 : ANDI SR opcode //
/////////////////////////////////////////
Op_ANDI_SR:
  LDW    (PC)+                 // Read immediate value
  LDW    SR                    // Read SR
  ANDW                         // AND it with the immediate value
  STW    SR                    // Update SR
  JUMP   Leave_Super           // Super <-> User switch

////////////////////////////////////////
// 0000.001010.xxxxxx : ANDI.L opcode //
////////////////////////////////////////
Op_ANDIL:
  CALL   EA1_RL_to_TMP1        // Immediate -> TMP1, read long from EA
  ANDW.                        // AND immediate LSW with EA LSW
  SWAP                         // Get EA MSW
  LDW    TMP1H                 // Get immediate MSW
  ANDL.                        // AND immediate MSW with EA MSW
  FLAG   -**00,CIN=CLR         // Update N and Z, clear V and C
  JUMP   EA1_Update_L          // Write back result

////////////////////////////////////////
// 0000.010000.xxxxxx : SUBI.B opcode //
////////////////////////////////////////
Op_SUBIB:
  LDW    (PC)+                 // Read immediate value
  CALL   EA1_Read_B            // Read byte from effective address
  SUBB.                        // Subtract the immediate value
  FLAG   *****,CIN=CLR         // Update X, N, Z, V and C flags
  JUMP   EA1_Update_B          // Write back result

////////////////////////////////////////
// 0000.010001.xxxxxx : SUBI.W opcode //
////////////////////////////////////////
Op_SUBIW:
  LDW    (PC)+                 // Read immediate value
  CALL   EA1_Read_W            // Read word from effective address
  SUBW.                        // Subtract the immediate value
  FLAG   *****,CIN=CLR         // Update X, N, Z, V and C flags
  JUMP   EA1_Update_W          // Write back result

////////////////////////////////////////
// 0000.010010.xxxxxx : SUBI.L opcode //
////////////////////////////////////////
Op_SUBIL:
  CALL   EA1_RL_to_TMP1        // Immediate -> TMP1, read long from EA
  SUB2W.                       // Subtract EA LSW with immediate LSW
  SWAP                         // Get EA MSW
  LDW    TMP1H                 // Get immediate MSW
  FLAG   -----,CIN=C_ADD       // Carry in is adder carry out
  SUBC2L.                      // Subtract EA MSW with immediate MSW
  FLAG   *****,CIN=CLR         // Update X, N, Z, V and C flags
  JUMP   EA1_Update_L          // Write back result

////////////////////////////////////////
// 0000.011000.xxxxxx : ADDI.B opcode //
////////////////////////////////////////
Op_ADDIB:
  LDW    (PC)+                 // Read immediate value
  CALL   EA1_Read_B            // Read byte from effective address
  ADDB.                        // Add the immediate value
  FLAG   *****,CIN=CLR         // Update flags
  JUMP   EA1_Update_B          // Write back result

////////////////////////////////////////
// 0000.011001.xxxxxx : ADDI.W opcode //
////////////////////////////////////////
Op_ADDIW:
  LDW    (PC)+                 // Read immediate value
  CALL   EA1_Read_W            // Read word from effective address
  ADDW.                        // Add the immediate value
  FLAG   *****,CIN=CLR         // Update flags
  JUMP   EA1_Update_W          // Write back result

////////////////////////////////////////
// 0000.011010.xxxxxx : ADDI.L opcode //
////////////////////////////////////////
Op_ADDIL:
  CALL   EA1_RL_to_TMP1        // Immediate -> TMP1, read long from EA
  ADDW.                        // Add EA LSW with immediate LSW
  SWAP                         // Get EA MSW
  LDW    TMP1H                 // Get immediate MSW
  FLAG   -----,CIN=C_ADD       // Carry in is adder carry out
  ADDCL.                       // Add EA MSW with immediate MSW
  FLAG   *****,CIN=CLR         // Update X, N, Z, V and C flags
  JUMP   EA1_Update_L          // Write back result

/////////////////////////////////////////
// 0000.100000.xxxxxx : BTST #x opcode //
/////////////////////////////////////////
// BTST.B #x,<ea>
Op_BTSTB_i:
  LDW    (PC)+                 // Read immediate value = bit number
Op_BTSTB_jmp:
  CALL   EA1_Read_B            // Read byte from effective address
  BANDB.                       // Bit-AND with flag update
  FLAG   --*--,CIN=CLR         // Update Z flag
  DROP   RTS                   // Drop result
Op_BTSTB_call:
  CALL   EA1_Read_B            // Read byte from effective address
  OVER                         // Dupplicate bit number
  OVER                         // Dupplicate byte data
  BANDB.                       // Bit-AND with flag update
  FLAG   --*--,CIN=CLR         // Update Z flag
  DROP   RTS                   // Drop result

// BTST.L #x,Dn
Op_BTSTL_i:
  LDW    (PC)+                 // Read immediate value = bit number
Op_BTSTL_jmp:
  DUP                          // Dupplicate bit number
  LDW    RL[EA1]               // Read Dn LSW
  BANDW.                       // Bit-AND with flag update
  DROP                         // Drop result
  LDW    RH[EA1]               // Read Dn MSW
  BANDL.                       // Bit-AND with flag update
  FLAG   --*--,CIN=CLR         // Update Z flag
  DROP   RTS                   // Drop result

/////////////////////////////////////////
// 0000.100001.xxxxxx : BCHG #x opcode //
/////////////////////////////////////////
// BCHG.B #x,<ea>
Op_BCHGB_i:
  LDW    (PC)+                 // Read immediate value = bit number
Op_BCHGB_jmp:
  CALL   Op_BTSTB_call         // Test the bit first
  BXORB                        // Bit-XOR
  JUMP   EA1_Update_B          // Write back result

// BCHG.L #x,Dn
Op_BCHGL_i:
  CALL   Op_BTSTL_i            // Test the bit first
  LDW    IMMR                  // Read immediate value = bit number
Op_BCHGL_jmp:
  DUP                          // Dupplicate bit number
  LDW    RL[EA1]               // Read Dn LSW
  BXORW                        // Bit-XOR
  STW    RL[EA1]               // Write back Dn LSW
  LDW    RH[EA1]               // Read Dn MSW
  BXORL                        // Bit-XOR
  STW    RH[EA1] RTS           // Write back Dn MSW

/////////////////////////////////////////
// 0000.100010.xxxxxx : BCLR #x opcode //
/////////////////////////////////////////
// BCLR.B #x,<ea>
Op_BCLRB_i:
  LDW    (PC)+                 // Read immediate value = bit number
Op_BCLRB_jmp:
  CALL   Op_BTSTB_call         // Test the bit first
  BMSKB                        // Bit-MASK
  JUMP   EA1_Update_B          // Write back result

// BCLR.L #x,Dn
Op_BCLRL_i:
  CALL   Op_BTSTL_i            // Test the bit first
  LDW    IMMR                  // Read immediate value = bit number
Op_BCLRL_jmp:
  DUP                          // Dupplicate bit number
  LDW    RL[EA1]               // Read Dn LSW
  BMSKW                        // Bit-MASK
  STW    RL[EA1]               // Write back Dn LSW
  LDW    RH[EA1]               // Read Dn MSW
  BMSKL                        // Bit-MASK
  STW    RH[EA1] RTS           // Write back Dn MSW

/////////////////////////////////////////
// 0000.100011.xxxxxx : BSET #x opcode //
/////////////////////////////////////////
// BSET.B #x,<ea>
Op_BSETB_i:
  LDW    (PC)+                 // Read immediate value = bit number
Op_BSETB_jmp:
  CALL   Op_BTSTB_call         // Test the bit first
  BORB                         // Bit-OR
  JUMP   EA1_Update_B          // Write back result

// BSET.L #x,Dn
Op_BSETL_i:
  CALL   Op_BTSTL_i            // Test the bit first
  LDW    IMMR                  // Read immediate value = bit number
Op_BSETL_jmp:
  DUP                          // Dupplicate bit number
  LDW    RL[EA1]               // Read Dn LSW
  BORW                         // Bit-OR
  STW    RL[EA1]               // Write back Dn LSW
  LDW    RH[EA1]               // Read Dn MSW
  BORL                         // Bit-OR
  STW    RH[EA1] RTS           // Write back Dn MSW

////////////////////////////////////////
// 0000.101000.xxxxxx : EORI.B opcode //
////////////////////////////////////////
Op_EORIB:
  LDW    (PC)+                 // Read immediate value
  CALL   EA1_Read_B            // Read byte from effective address
  XORB.                        // XOR it with the immediate value
  FLAG   -**00,CIN=CLR         // Update N and Z, clear V and C
  JUMP   EA1_Update_B          // Write back result

//////////////////////////////////////////
// 0000.101000.111100 : EORI CCR opcode //
//////////////////////////////////////////
Op_EORI_CCR:
  LDW    (PC)+                 // Read immediate value
  LDB    SR                    // Read CCR
  XORB                         // XOR CCR with the immediate value
  STB    SR RTS                // Update CCR

////////////////////////////////////////
// 0000.101001.xxxxxx : EORI.W opcode //
////////////////////////////////////////
Op_EORIW:
  LDW    (PC)+                 // Read immediate value
  CALL   EA1_Read_W            // Read word from effective address
  XORW.                        // XOR it with the immediate value
  FLAG   -**00,CIN=CLR         // Update N and Z, clear V and C
  JUMP   EA1_Update_W          // Write back result

/////////////////////////////////////////
// 0000.101001.111100 : EORI SR opcode //
/////////////////////////////////////////
Op_EORI_SR:
  LDW    (PC)+                 // Read immediate value
  LDW    SR                    // Read SR
  XORW                         // XOR it with the immediate value
  STW    SR                    // Update SR
  JUMP   Leave_Super           // Super <-> User switch

////////////////////////////////////////
// 0000.101010.xxxxxx : EORI.L opcode //
////////////////////////////////////////
Op_EORIL:
  CALL   EA1_RL_to_TMP1        // Immediate -> TMP1, read long from EA
  XORW.                        // XOR EA LSW with immediate LSW
  SWAP                         // Get EA MSW
  LDW    TMP1H                 // Get immediate MSW
  XORL.                        // XOR EA MSW with immediate MSW
  FLAG   -**00,CIN=CLR         // Update N and Z, clear V and C
  JUMP   EA1_Update_L          // Write back result

////////////////////////////////////////
// 0000.110000.xxxxxx : CMPI.B opcode //
////////////////////////////////////////
Op_CMPIB:
  LDW    (PC)+                 // Read immediate value
  CALL   EA1_Read_B            // Read byte from effective address
  SUBB.                        // Subtract immediate value
  FLAG   -****,CIN=CLR         // Update N, Z, V and C
  DROP RTS                     // Drop result

////////////////////////////////////////
// 0000.110001.xxxxxx : CMPI.W opcode //
////////////////////////////////////////
Op_CMPIW:
  LDW    (PC)+                 // Read immediate value
  CALL   EA1_Read_W            // Read word from effective address
  SUBW.                        // Subtract immediate value
  FLAG   -****,CIN=CLR         // Update N, Z, V and C
  DROP RTS                     // Drop result

////////////////////////////////////////
// 0000.110010.xxxxxx : CMPI.L opcode //
////////////////////////////////////////
Op_CMPIL:
  CALL   EA1_RL_to_TMP1
  SUB2W.
  DROP
  LDW    TMP1H
  FLAG   -----,CIN=C_ADD
  SUBC2L.
  FLAG   -****,CIN=CLR
  DROP RTS

/////////////////////////////////////////
// 0000.yyy100.xxxxxx : BTST Dn opcode //
/////////////////////////////////////////
// BTST.B Dx,<ea>
Op_BTSTB_r:
  LDB    DL[EA2]               // Read Dx LSB = bit number
  JUMP   Op_BTSTB_jmp          // Execute BTST.B

// BTST.L Dx,Dy
Op_BTSTL_r:
  LDB    DL[EA2]               // Read Dx LSB = bit number
  JUMP   Op_BTSTL_jmp          // Execute BTST.L

/////////////////////////////////////////////////
// 0000.yyy100.001xxx : MOVEP.W to reg. opcode //
/////////////////////////////////////////////////
Op_MOVEPW_r:
  CALL   Calc_d16_An_EA1       // Calculate d16(An)
  JUMP   Op_MOVEPW_r_jmp       // Execute MOVEP.W

/////////////////////////////////////////
// 0000.yyy101.xxxxxx : BCHG Dn opcode //
/////////////////////////////////////////
Op_BCHGB_r:
  LDB    DL[EA2]               // Read Dx LSB = bit number
  JUMP   Op_BCHGB_jmp          // Execute BCHG.B

Op_BCHGL_r:
  LDB    DL[EA2]               // Read Dx LSB = bit number
  DUP                          // Dupplicate bit number
  CALL   Op_BTSTL_jmp          // Execute BTST.L
  JUMP   Op_BCHGL_jmp          // Execute BCHG.L

/////////////////////////////////////////////////
// 0000.yyy101.001xxx : MOVEP.L to reg. opcode //
/////////////////////////////////////////////////
Op_MOVEPL_r:
  CALL   Calc_d16_An_EA1       // Calculate d16(An)
  LDH    (EA1)+                // Get MSB
  LDL    (EA1)+                // Get LSB
  ORW                          // Combine the MSB and LSB
  STW    DH[EA2]               // Store the word to Dn high
Op_MOVEPW_r_jmp:
  LDH    (EA1)+                // Get MSB
  LDL    (EA1)                 // Get LSB
  ORW                          // Combine the MSB and LSB
  STW    DL[EA2] RTS           // Store the word to Dn low

/////////////////////////////////////////
// 0000.yyy110.xxxxxx : BCLR Dn opcode //
/////////////////////////////////////////
Op_BCLRB_r:
  LDB    DL[EA2]               // Read Dx LSB = bit number
  JUMP   Op_BCLRB_jmp          // Execute BCLR.B

Op_BCLRL_r:
  LDB    DL[EA2]               // Read Dx LSB = bit number
  DUP                          // Dupplicate bit number
  CALL   Op_BTSTL_jmp          // Execute BTST.L
  JUMP   Op_BCLRL_jmp          // Execute BCLR.L

/////////////////////////////////////////////////
// 0000.yyy110.001xxx : MOVEP.W to mem. opcode //
/////////////////////////////////////////////////
Op_MOVEPW_m:
  CALL   Calc_d16_An_EA1       // Calculate d16(An)
  JUMP   Op_MOVEPW_m_jmp       // Execute MOVEP.W

/////////////////////////////////////////
// 0000.yyy111.xxxxxx : BSET Dn opcode //
/////////////////////////////////////////
Op_BSETB_r:
  LDB    DL[EA2]               // Read Dx LSB = bit number
  JUMP   Op_BSETB_jmp          // Execute BSET.B

Op_BSETL_r:
  LDB    DL[EA2]               // Read Dx LSB = bit number
  DUP                          // Dupplicate bit number
  CALL   Op_BTSTL_jmp          // Execute BTST.L
  JUMP   Op_BSETL_jmp          // Execute BSET.L

/////////////////////////////////////////////////
// 0000.yyy111.001xxx : MOVEP.L to mem. opcode //
/////////////////////////////////////////////////
Op_MOVEPL_m:
  CALL   Calc_d16_An_EA1       // Calculate d16(An)
  LDW    DH[EA2]               // Get Dn high
  DUP                          // Dupplicate the value
  STH    (EA1)+                // Write MSB to memory
  STL    (EA1)+                // Write LSB to memory
Op_MOVEPW_m_jmp:
  LDW    DL[EA2]               // Get Dn low
  DUP                          // Dupplicate the value
  STH    (EA1)+                // Write MSB to memory
  STL    (EA1) RTS             // Write LSB to memory

////////////////////////////////////////
// 0001.yyyyyy.xxxxxx : MOVE.B opcode //
////////////////////////////////////////
Op_MOVEB:
  CALL   EA1_Read_B
  TSTB.
  FLAG   -**00,CIN=CLR
  JUMP   EA2_Write_B

/////////////////////////////////////////////////////
// 0010.yyyyyy.xxxxxx : MOVE.L and MOVEA.L opcodes //
/////////////////////////////////////////////////////
Op_MOVEL:
  CALL   EA1_Read_L
  TSTW.
  SWAP
  TSTL.
  FLAG   -**00,CIN=CLR
  JUMP   EA2_Write_L

Op_MOVEAL:
  CALL   EA1_Read_L
  SWAP
  JUMP   EA2_Write_L

/////////////////////////////////////////////////////
// 0011.yyyyyy.xxxxxx : MOVE.W and MOVEA.W opcodes //
/////////////////////////////////////////////////////
Op_MOVEW:
  CALL   EA1_Read_W
  TSTW.
  FLAG   -**00,CIN=CLR
  JUMP   EA2_Write_W

Op_MOVEAW:
  CALL   EA1_Read_W
  JUMP   EA2_Write_W

////////////////////////////////////////
// 0100.000000.xxxxxx : NEGX.B opcode //
////////////////////////////////////////
Op_NEGXB:
  CALL   EA1_Read_B
  FLAG   -----,CIN=X_SR
  NEGCB.
  FLAG   **#**,CIN=CLR
  JUMP   EA1_Update_B

////////////////////////////////////////
// 0100.000001.xxxxxx : NEGX.W opcode //
////////////////////////////////////////
Op_NEGXW:
  CALL   EA1_Read_W
  FLAG   -----,CIN=X_SR
  NEGCW.
  FLAG   **#**,CIN=CLR
  JUMP   EA1_Update_W

////////////////////////////////////////
// 0100.000010.xxxxxx : NEGX.L opcode //
////////////////////////////////////////
Op_NEGXL:
  CALL   EA1_Read_L
  FLAG   -----,CIN=X_SR
  NEGCW.
  FLAG   -----,CIN=C_ADD
  SWAP
  NEGCL.
  FLAG   **#**,CIN=CLR
  JUMP   EA1_Update_L

//////////////////////////////////////////////
// 0100.000011.xxxxxx : MOVE from SR opcode //
//////////////////////////////////////////////
Op_MOVEfSR:
  LDW    SR
  JUMP   EA1_Write_W

///////////////////////////////////////
// 0100.001000.xxxxxx : CLR.B opcode //
///////////////////////////////////////
Op_CLRB:
  FLAG   -0100
  LIT    #0
  JUMP   EA1_Write_B

///////////////////////////////////////
// 0100.001001.xxxxxx : CLR.W opcode //
///////////////////////////////////////
Op_CLRW:
  FLAG   -0100
  LIT    #0
  JUMP   EA1_Write_W

///////////////////////////////////////
// 0100.001010.xxxxxx : CLR.L opcode //
///////////////////////////////////////
Op_CLRL:
  FLAG   -0100
  LIT    #0
  LIT    #0
  JUMP   EA1_Write_L

///////////////////////////////////////
// 0100.010000.xxxxxx : NEG.B opcode //
///////////////////////////////////////
Op_NEGB:
  CALL   EA1_Read_B
  NEGB.
  FLAG   *****,CIN=CLR
  JUMP   EA1_Update_B

///////////////////////////////////////
// 0100.010001.xxxxxx : NEG.W opcode //
///////////////////////////////////////
Op_NEGW:
  CALL   EA1_Read_W
  NEGW.
  FLAG   *****,CIN=CLR
  JUMP   EA1_Update_W

///////////////////////////////////////
// 0100.010010.xxxxxx : NEG.L opcode //
///////////////////////////////////////
Op_NEGL:
  CALL   EA1_Read_L
  NEGW.
  FLAG   -----,CIN=C_ADD
  SWAP
  NEGCL.
  FLAG   *****,CIN=CLR
  JUMP   EA1_Update_L

/////////////////////////////////////////////
// 0100.010011.xxxxxx : MOVE to CCR opcode //
/////////////////////////////////////////////
Op_MOVEtCCR:
  CALL   EA1_Read_W
  STB    SR RTS

///////////////////////////////////////
// 0100.011000.xxxxxx : NOT.B opcode //
///////////////////////////////////////
Op_NOTB:
  CALL   EA1_Read_B
  NOTB.
  FLAG   -**00,CIN=CLR
  JUMP   EA1_Update_B

///////////////////////////////////////
// 0100.011001.xxxxxx : NOT.W opcode //
///////////////////////////////////////
Op_NOTW:
  CALL   EA1_Read_W
  NOTW.
  FLAG   -**00,CIN=CLR
  JUMP   EA1_Update_W

///////////////////////////////////////
// 0100.011010.xxxxxx : NOT.L opcode //
///////////////////////////////////////
Op_NOTL:
  CALL   EA1_Read_L
  NOTW.
  SWAP
  NOTL.
  FLAG   -**00,CIN=CLR
  JUMP   EA1_Update_L

////////////////////////////////////////////
// 0100.011011.xxxxxx : MOVE to SR opcode //
////////////////////////////////////////////
Op_MOVEtSR:
  CALL   EA1_Read_W            // Read word from effective address
  STW    SR                    // Store it in SR
  JUMP   Leave_Super           // Super <-> User switch

//////////////////////////////////////
// 0100.100000.xxxxxx : NBCD opcode //
//////////////////////////////////////
Op_NBCD:
  CALL   EA1_Read_B            // Read byte from effective address
  LIT    #0                    // Load BCD value 00
  CALL   SBCD_Calc             // Execute BCD subtract : 00 - byte
  FLAG   -*#--,CIN=CLR         // Update N and Z flags
  JUMP   EA1_Update_B          // Write back result

/////////////////////////////////////
// 0100.100001.xxxxxx : PEA opcode //
/////////////////////////////////////
Op_PEA:
  CALL   EA1_Calc              // Compute effective address
  CALL   SP_to_EA2             // A7 -> EA2
  LDW    EA1L
  STW    -(EA2)                // EA1 low -> -(EA2)
  LDW    EA1H
  STW    -(EA2)                // EA1 high -> -(EA2)
  JUMP   EA2_to_SP             // EA2 -> SP

//////////////////////////////////////
// 0100.100001.00xxxx : SWAP opcode //
//////////////////////////////////////

Op_SWAP:
  LDW    DL[EA1]
  LDW    DH[EA1]          // Read Dn.L swapped
  FLAG   ---00,CIN=CLR    // Clear V and C flags

Write_DnL:
  TSTW.
  STW    DL[EA1]
  TSTL.
  FLAG   -**--,CIN=CLR    // Update N and Z flags
  STW    DH[EA1] RTS      // Store result into Dn.L

Write_DnW:
  TSTW.
  FLAG   -**--,CIN=CLR    // Update N and Z flags
  STW    DL[EA1] RTS      // Store result into Dn.W

Write_DnB:
  TSTB.
  FLAG   -**--,CIN=CLR    // Update N and Z flags
  STB    DL[EA1] RTS      // Store result into Dn.B

/////////////////////////////////////////////////
// 0100.100010.xxxxxx : MOVEM.W to mem. opcode //
/////////////////////////////////////////////////
// MOVEM.W <list>,<ea>
Op_MOVEMW_m:
  LDW    (PC)+                 // Get register list
  CALL   EA1_Calc              // Compute effective address
  LOOP16                       // Loop 16 times
  JUMPN  T0,NoMoveW_m          // Bit #0 cleared : do not move register
  LDW    RL[CNT]               // Bit #0 set : load register
  STW    (EA1)+                // Store it to memory
NoMoveW_m:
  RSHW                         // Get next bit
  ENDLOOP                      // End of loop
  DROP   RTS                   // Drop register list

// MOVEM.W <list>,-(An)
Op_MOVEMW_mpd:
  LDW    (PC)+                 // Get register list
  CALL   Get_An_EA1            // Compute effective address
  LOOP16                       // Loop 16 times
  JUMPN  T0,NoMoveW_mpd        // Bit #0 cleared : do not move register
  LDW    RL[CNT]               // Bit #0 set : load register
  STW    -(EA1)                // Store it to memory
NoMoveW_mpd:
  RSHW                         // Get next bit
  ENDLOOP                      // End of loop
  DROP                         // Drop register list
  JUMP   Set_An_EA1            // Update An

///////////////////////////////////////
// 0100.100010.000xxx : EXT.W opcode //
///////////////////////////////////////
Op_EXTW:
  LIT    #$FF00                // Mask value
  LDW    DL[EA1]               // Load register
  TSTB.                        // Test LSB
  FLAG   -**00,CIN=CLR         // Update N and Z flags
  JUMP   N_SR,Op_EXTW_Neg      // Check N flag
  MSKW                         // 00xx
  STW    DL[EA1] RTS           // Store register

Op_EXTW_Neg:
  ORW                          // FFxx
  STW    DL[EA1] RTS           // Store register

/////////////////////////////////////////////////
// 0100.100011.xxxxxx : MOVEM.L to mem. opcode //
/////////////////////////////////////////////////
// MOVEM.L <list>,<ea>
Op_MOVEML_m:
  LDW    (PC)+                 // Get register list
  CALL   EA1_Calc              // Compute effective address
  LOOP16                       // Loop 16 times
  JUMPN  T0,NoMoveL_m          // Bit #0 cleared : do not move register
  LDW    RH[CNT]               // Bit #0 set : move register to memory
  STW    (EA1)+
  LDW    RL[CNT]
  STW    (EA1)+
NoMoveL_m:
  RSHW                         // Get next bit
  ENDLOOP                      // End of loop
  DROP   RTS                   // Drop register list

// MOVEM.L <list>,-(An)
Op_MOVEML_mpd:
  LDW    (PC)+                 // Get register list
  CALL   Get_An_EA1            // Compute effective address
  LOOP16                       // Loop 16 times
  JUMPN  T0,NoMoveL_mpd        // Bit #0 cleared : do not move register
  LDW    RL[CNT]               // Bit #0 set : move register to memory
  STW    -(EA1)
  LDW    RH[CNT]
  STW    -(EA1)
NoMoveL_mpd:
  RSHW                         // Get next bit
  ENDLOOP                      // End of loop
  DROP                         // Drop register list
  JUMP   Set_An_EA1            // Update An

///////////////////////////////////////
// 0100.100011.000xxx : EXT.L opcode //
///////////////////////////////////////
Op_EXTL:
  LDW    DL[EA1].              // Load Dn.W
  FLAG   -----,CIN=T15         // Carry in is bit #15 (sign)
  DROP                         // Drop LSW
  EXTW                         // Extend word to long
  FLAG   -**00,CIN=CLR         // Update N and Z, clear V and C
  STW    DH[EA1] RTS           // Store MSW

///////////////////////////////////////
// 0100.101000.xxxxxx : TST.B opcode //
///////////////////////////////////////
Op_TSTB:
  CALL   EA1_Read_B
  TSTB.
  FLAG   -**00,CIN=CLR
  DROP RTS

///////////////////////////////////////
// 0100.101001.xxxxxx : TST.W opcode //
///////////////////////////////////////
Op_TSTW:
  CALL   EA1_Read_W
  TSTW.
  FLAG   -**00,CIN=CLR
  DROP RTS

///////////////////////////////////////
// 0100.101010.xxxxxx : TST.L opcode //
///////////////////////////////////////
Op_TSTL:
  CALL   EA1_Read_L
  TSTW.
  DROP
  TSTL.
  FLAG   -**00,CIN=CLR
  DROP RTS

/////////////////////////////////////
// 0100.101011.xxxxxx : TAS opcode //
/////////////////////////////////////
Op_TASB:
  CALL   EA1_Read_B
  TSTB.
  FLAG   -**00,CIN=CLR
  LIT    #$0080
  ORB
  JUMP   EA1_Update_B

/////////////////////////////////////////////////
// 0100.110010.xxxxxx : MOVEM.W to reg. opcode //
/////////////////////////////////////////////////
Op_MOVEMW_r:
  LDW    (PC)+                 // Get register list
  CALL   EA1_Calc              // Compute effective address

  LOOP16                       // Loop 16 times

  JUMPN  T0,NoMoveW_r          // Bit #0 cleared : do not move register
  LDW    (EA1)+                // Bit #0 set : load memory
  FLAG   -----,CIN=T15         // Carry in is bit #15 (sign)
  STW    RL[CNT]               // Store LSW to register
  EXTW                         // Extend word to long
  STW    RH[CNT]               // Store MSW to register
NoMoveW_r:
  RSHW                         // Get next bit
  ENDLOOP

  FLAG   -----,CIN=CLR         // Clear carry in
  DROP   RTS                   // Drop register list

Op_MOVEMW_rpi:
  CALL   Op_MOVEMW_r           // Execute MOVEM.W (An)+,<list>
  JUMP   Set_An_EA1            // Update An

/////////////////////////////////////////////////
// 0100.110011.xxxxxx : MOVEM.L to reg. opcode //
/////////////////////////////////////////////////
Op_MOVEML_r:
  LDW    (PC)+                 // Get register list
  CALL   EA1_Calc              // Compute effective address

  LOOP16                       // Loop 16 times

  JUMPN  T0,NoMoveL_r          // Bit #0 cleared : do not move register
  LDW    (EA1)+                // Bit #0 Set : load memory
  STW    RH[CNT]               // Store MSW to register
  LDW    (EA1)+                // Load memory
  STW    RL[CNT]               // Store LSW to register
NoMoveL_r:
  RSHW                         // Get next bit
  ENDLOOP

  DROP   RTS                   // Drop register list

Op_MOVEML_rpi:
  CALL   Op_MOVEML_r           // Execute MOVEM.L (An)+,<list>
  JUMP   Set_An_EA1            // Update An

/////////////////////////////////////
// 0100.111001.110001 : NOP opcode //
/////////////////////////////////////
Op_NOP:
  NOP    RTS                   // No operation

//////////////////////////////////////
// 0100.111001.00xxxx : TRAP opcode //
//////////////////////////////////////
Op_TRAP:
  LDW    IMMR                  // Load immediate value (vector number)
  JUMP   Trap_Processing       // Execute exception

//////////////////////////////////////
// 0100.111001.010xxx : LINK opcode //
//////////////////////////////////////
Op_LINK:
  FTW    (PC)+                 // Get displacement
  CALL   SP_to_EA2             // A7 -> EA2
  LDW    AH[EA1]
  LDW    AL[EA1]               // Get An.l
  STW    -(EA2)
  STW    -(EA2)                // Store An on the stack
  LDW    EA2H                  // Get EA2 high
  WRW    AH[EA1]               // Write it to An high
  LDW    EA2L                  // Get EA2 low
  WRW    AL[EA1]               // Write it to An low
  CALL   AddOffs               // Add displacement to SP
  STW    A7H                   // Update A7 high
  STW    A7L RTS               // Update A7 low

//////////////////////////////////////
// 0100.111001.011xxx : UNLK opcode //
//////////////////////////////////////
Op_UNLK:
  LDW    AH[EA1]
  STW    EA2H             // An high -> EA2 high
  LDW    AL[EA1]
  STW    EA2L             // An low -> EA2 low
  LDW    (EA2)+
  STW    AH[EA1]          // (EA2)+ -> An high
  LDW    (EA2)+
  STW    AL[EA1]          // (EA2)+ -> An low
  LDW    EA2H
  STW    A7H              // EA2 high -> A7 high
  LDW    EA2L
  STW    A7L RTS          // EA2 low -> A7 low

/////////////////////////////////////////////
// 0100.111001.100xxx : MOVE to USP opcode //
/////////////////////////////////////////////
Op_MOVEtUSP:
  LDW    AH[EA1]
  LDW    AL[EA1]               // Get An.l
  STW    USPL
  STW    USPH RTS              // Write to USP

///////////////////////////////////////////////
// 0100.111001.101xxx : MOVE from USP opcode //
///////////////////////////////////////////////
Op_MOVEfUSP:
  LDW    USPH
  LDW    USPL                  // Get USP
  STW    AL[EA1]
  STW    AH[EA1] RTS           // Write to An.l

//////////////////////////////////////
// 0100.111001.110010 : STOP opcode //
//////////////////////////////////////
Op_STOP:
  LDW    (PC)+                 // Load immediate data
  STW    SR                    // Change SR
Op_STOP_Wait:
  JUMPN  I_SR,Op_STOP_Wait     // Wait for interrupt
  JUMP   Leave_Super           // Super <-> User switch

/////////////////////////////////////
// 0100.111001.110011 : RTE opcode //
/////////////////////////////////////
Op_RTE:
  CALL   SP_to_EA2             // A7 -> EA2
  LDW    (EA2)+                // Get SR
  STW    SR                    // Update SR
  CALL   Op_RTS_jmp            // Get PC, update A7
  JUMP   Leave_Super           // Super <-> User switch

/////////////////////////////////////
// 0100.111001.110101 : RTS opcode //
/////////////////////////////////////
Op_RTS:
  CALL   SP_to_EA2             // A7 -> EA2
Op_RTS_jmp:
  LDW    (EA2)+                // Get PC high
  STW    PCH                   // Update PC high
  LDW    (EA2)+                // Get PC low
  STW    PCL                   // Update PC low
  JUMP   EA2_to_SP             // EA2 -> A7

///////////////////////////////////////
// 0100.111001.110110 : TRAPV opcode //
///////////////////////////////////////
Op_TRAPV:
  JUMPN  V_SR,Op_NOP           // V cleared : do nothing
  LIT    #$001C                // Trap vector : 0x1C
  JUMP   Trap_Processing       // Execute exception

/////////////////////////////////////
// 0100.111001.110111 : RTR opcode //
/////////////////////////////////////
Op_RTR:
  CALL   SP_to_EA2             // A7 -> EA2
  LDW    (EA2)+                // Get CCR
  STB    SR                    // Update CCR
  JUMP   Op_RTS_jmp            // Get PC, update A7

/////////////////////////////////////
// 0100.111010.xxxxxx : JSR opcode //
/////////////////////////////////////
Op_JSR:
  CALL   EA1_Calc              // Compute effective adddress
  CALL   PC_to_Stack           // Save current PC to stack

EA1_to_PC:
  LDW    EA1H
  STW    PCH                   // EA1 high -> PC high
  LDW    EA1L
  STW    PCL RTS               // EA1 low -> PC low

/////////////////////////////////////
// 0100.111011.xxxxxx : JMP opcode //
/////////////////////////////////////
Op_JMP:
  CALL   EA1_Calc              // Compute effective adddress
  JUMP   EA1_to_PC             // Update PC with effective address

///////////////////////////////////////
// 0100.yyy110.xxxxxx : CHK.W opcode //
///////////////////////////////////////
Op_CHKW:
  CALL   EA1_Read_W            // Load word from effective address
  LDW    DL[EA2].              // Load Dn.w
  FLAG   -**00,CIN=CLR         // Update N and Z, clear V and C
  JUMP   N_SR,Trap_Neg         // Trap if Dn.w negative
  SUBW.                        // Compute Dn.w - <ea>
  JUMP   G_FLG,Trap_Grt        // Trap if Dn.w > <ea>
  DROP   RTS                   // Drop Dn.w - <ea>

Trap_Grt:
  FLAG   -0---,CIN=CLR         // Clear the N flag
  DROP                         // Drop subtract result
  LIT    #$0018                // Set trap vector to 0x18
  JUMP   Trap_Processing       // Execute exception

Trap_Neg:
  DROP                         // Drop Dn.w
  DROP                         // Drop word from effective address
  LIT    #$0018                // Set trap vector to 0x18
  JUMP   Trap_Processing       // Execute exception

/////////////////////////////////////
// 0100.yyy111.xxxxxx : LEA opcode //
/////////////////////////////////////
Op_LEA:
  CALL   EA1_Calc
  LDW    EA1L
  STW    AL[EA2]
  LDW    EA1H
  STW    AH[EA2] RTS

////////////////////////////////////////
// 0101.yyy000.xxxxxx : ADDQ.B opcode //
////////////////////////////////////////
Op_ADDQB:
  LDW    IMMR
  CALL   EA1_Read_B
  ADDB.
  FLAG   *****,CIN=CLR
  JUMP   EA1_Update_B

////////////////////////////////////////
// 0101.yyy001.xxxxxx : ADDQ.W opcode //
////////////////////////////////////////
Op_ADDQW:
  LDW    IMMR
  CALL   EA1_Read_W
  ADDW.
  FLAG   *****,CIN=CLR
  JUMP   EA1_Update_W

////////////////////////////////////////
// 0101.yyy010.xxxxxx : ADDQ.L opcode //
////////////////////////////////////////
Op_ADDQL:
  LDW    IMMR
  STW    TMP1L
  CALL   EA1_Read_L
  LDW    TMP1L
  ADDW.
  FLAG   -----,CIN=C_ADD
  SWAP
  LIT    #0
  ADDCL.
  FLAG   *****,CIN=CLR
  JUMP   EA1_Update_L

Op_ADDQA:
  LDW    IMMR
  LDW    AL[EA1]
  ADDW.
  STW    AL[EA1]
  LIT    #0
  LDW    AH[EA1]
  FLAG   -----,CIN=C_ADD
  ADDCL.
  STW    AH[EA1] RTS

////////////////////////////////////////
// 0101.yyy100.xxxxxx : SUBQ.B opcode //
////////////////////////////////////////
Op_SUBQB:
  LDW    IMMR
  CALL   EA1_Read_B
  SUBB.
  FLAG   *****,CIN=CLR
  JUMP   EA1_Update_B

////////////////////////////////////////
// 0101.yyy101.xxxxxx : SUBQ.W opcode //
////////////////////////////////////////
Op_SUBQW:
  LDW    IMMR
  CALL   EA1_Read_W
  SUBW.
  FLAG   *****,CIN=CLR
  JUMP   EA1_Update_W

////////////////////////////////////////
// 0101.yyy110.xxxxxx : SUBQ.L opcode //
////////////////////////////////////////
Op_SUBQL:
  LDW    IMMR
  STW    TMP1L
  CALL   EA1_Read_L
  LDW    TMP1L
  SUB2W.
  FLAG   -----,CIN=C_ADD
  SWAP
  LIT    #0
  SUBC2L.
  FLAG   *****,CIN=CLR
  JUMP   EA1_Update_L

Op_SUBQA:
  LDW    IMMR
  LDW    AL[EA1]
  SUBW.
  STW    AL[EA1]
  LIT    #0
  LDW    AH[EA1]
  FLAG   -----,CIN=C_ADD
  SUBCL.
  STW    AH[EA1] RTS

/////////////////////////////////////
// 0101.cccc11.xxxxxx : Scc opcode //
/////////////////////////////////////
Op_Scc:
  JUMP   B_SR,Op_Scc_Set
  LIT    #$0000
  JUMP   EA1_Write_B
Op_Scc_Set:
  LIT    #$00FF
  JUMP   EA1_Write_B

//////////////////////////////////////
// 0101.cccc11.001xxx : DBcc opcode //
//////////////////////////////////////
Op_DBcc:
  JUMPN  B_SR,Op_DBcc_Exec     // Condition false : decrement Dn.w
Op_DBcc_Exit:
  FTW    (PC)+ RTS             // Condition true : do nothing
Op_DBcc_Exec:
  LDW    DL[EA1]               // Load Dn.w into T
  DECW                         // Decrement T
  WRW    DL[EA1]               // Write back result
  NOTW.                        // Invert result (0xFFFF -> 0x0000)
  DROP                         // Drop the result
  JUMP   Z_FLG,Op_DBcc_Exit    // Z flag set : do not take the branch
                               // Z flag clear : take the branch
  LDW    PCH                   // Load PC high word
  LDW    PCL                   // Load PC low word
  FTW    (PC)+                 // Get 16-bit displacement
  JUMP   AddWOffs_PC           // Add word offset to PC

//////////////////////////////////////////////////
// 0110.cccc.xxxxxxxx : Bcc.B and Bcc.W opcodes //
//////////////////////////////////////////////////
Op_Bcc:
  JUMPN  B_SR,FetchDisp        // Branch not taken : only fetch displacement
  LDW    PCH                   // Load PC high word
  LDW    PCL                   // Load PC low word
  CALL   FetchDisp             // Fetch displacement

AddWOffs_PC:
  CALL   AddOffs               // Add word offset to PC
  STW    PCH                   // Change PCH
  STW    PCL RTS               // Change PCL

/////////////////////////////////////////////////////////
// 0110.0001.xxxxxxxx : BSR.B, BSR.W and BSR.L opcodes //
/////////////////////////////////////////////////////////
Op_BSR:
  LDW    PCH              // Load PC high word
  LDW    PCL              // Load PC low word
  CALL   FetchDisp        // Fetch displacement
  CALL   PC_to_Stack
  JUMP   AddWOffs_PC

FetchDisp:
  LDW    IMMR.                 // Read byte displacement
  JUMPN  Z_FLG,ShortBranch     // Displacement not null, skip next 2 instr.
  DROP                         // Drop byte displacement
  FTW    (PC)+ RTS             // Fetch word displacement
ShortBranch:
  DROP   RTS                   // Drop byte displacement

///////////////////////////////////////
// 0111.yyy0.xxxxxxxx : MOVEQ opcode //
///////////////////////////////////////
Op_MOVEQ:
  LDW    IMMR.                 // Load immediate word with partial flags update
  FLAG   -----,CIN=T15         // Carry in is bit #15 (sign)
  EXTW                         // Extend word to long
  FLAG   -**00,CIN=CLR         // Update the M68k flags
  STW    DH[EA2]               // Store the word into Dx high
  STW    DL[EA2] RTS           // Store the word into Dx low

//////////////////////////////////////
// 1000.yyy-00.xxxxxx : OR.B opcode //
//////////////////////////////////////
Op_ORB_r:
  CALL   Op_ORB                // Execute OR.B
  STB    DL[EA2] RTS           // Write back result to register

Op_ORB_m:
  CALL   Op_ORB                // Execute OR.B
  JUMP   EA1_Update_B          // Write back result to memory

Op_ORB:
  CALL   EA1_Read_B            // Read byte from effective address
  LDB    DL[EA2]               // Read byte from register
  ORB.                         // OR both bytes
  FLAG   -**00,CIN=CLR RTS     // Update N and Z, clear V and C

//////////////////////////////////////
// 1000.yyy100.00xxxx : SBCD opcode //
//////////////////////////////////////
Op_SBCD_r:
  LDB    DL[EA1]               // Dy
  LDB    DL[EA2]               // Dx
  CALL   SBCD_Calc             // Compute BCD subtraction
  FLAG   -*#--,CIN=CLR         // Update N and Z flags
  STB    DL[EA2] RTS           // Update Dx

Op_SBCD_m:
  CALL   EA1_RB_An_Dec         // Read byte with -(An)
  CALL   EA2_RB_An_Dec         // Read byte with -(An)
  CALL   SBCD_Calc             // Compute BCD subtraction
  FLAG   -*#--,CIN=CLR         // Update N and Z flags
  STB    (EA2)+ RTS            // TODO : -(A7) case !!!

SBCD_Calc:
  OVER                         // Duplicate Src
  LIT    #$000F                // Mask for low nibble
  ANDW                         // Keep Src low nibble
  OVER                         // Duplicate Dst
  LIT    #$000F                // Mask for low nibble
  ANDW                         // Keep Dst low nibble
  FLAG   0---0,CIN=X_SR        // Carry in is the X flag
  SUBCW.                       // Compute Dst - Src - X
  JUMPN  N_FLG,SBCD_PosLoNib   // Jump if result > 0
  LIT    #6
  SUB2W                        // Subtract 6 to the result
SBCD_PosLoNib:

  SWAP                         // Get Dst
  LIT    #$00F0                // Mask for high nibble
  ANDW                         // Keep Dst high nibble
  ADDW                         // Add it to the intermediate result
  SWAP
  LIT    #$00F0                // Mask for high nibble
  ANDW                         // Keep Src high nibble
  SUB2W.                       // Subtract it to the intermediate result
  JUMPN  N_FLG,SBCD_PosHiNib   // Jump if result > 0
  LIT    #$0060
  SUB2W                        // Subtract  $60 to the result
  FLAG   1---1                 // Set X and C
SBCD_PosHiNib:
  NOP.   RTS                   // Update intermediate flags

//////////////////////////////////////
// 1000.yyy-01.xxxxxx : OR.W opcode //
//////////////////////////////////////
Op_ORW_r:
  CALL   Op_ORW                // Execute OR.W
  STW    DL[EA2] RTS           // Write back result to register

Op_ORW_m:
  CALL   Op_ORW                // Execute OR.W
  JUMP   EA1_Update_W          // Write back result to memory

Op_ORW:
  CALL   EA1_Read_W            // Read word from effective address
  LDW    DL[EA2]               // Read word from register
  ORW.                         // OR both words
  FLAG   -**00,CIN=CLR RTS     // Update N and Z, clear V and C

//////////////////////////////////////
// 1000.yyy-10.xxxxxx : OR.L opcode //
//////////////////////////////////////
Op_ORL_r:
  CALL   Op_ORL                // Execute OR.L
  JUMP   EA2_WL_Reg            // Write back result to register

Op_ORL_m:
  CALL   Op_ORL                // Execute OR.L
  JUMP   EA1_Update_L          // Write back result to memory

Op_ORL:
  CALL   EA1_Read_L            // Read long from effective address
  LDW    DL[EA2]               // Read Dn LSW
  ORW.                         // OR both LSW
  SWAP                         // Swap LSW and MSW
  LDW    DH[EA2]               // Read Dn MSW
  ORL.                         // OR both MSW
  FLAG   -**00,CIN=CLR RTS     // Update N and Z, clear V and C

//////////////////////////////////////
// 1000.yyy011.001xxx : DIVU opcode //
//////////////////////////////////////
Op_DIVU:
  CALL   EA1_Read_W            // Load the source (word)
  FLAG   ----0,CIN=CLR         // Clear C flag
  TSTW.                        // Check if source is null
  JUMP   Z_FLG,Trap_DivZero    // Divide by zero error

  LDW    DH[EA2]
  LDW    DL[EA2]               // Load the destination (long)
  CALL   Op_DIVx               // Do the divide
  JUMP   V_SR,Op_Div_Overflow2 // Overflow : do not store the result
  FLAG   -**-0,CIN=CLR         // Update N and Z flags
  STW    DL[EA2]
  STW    DH[EA2] RTS           // Store the result

Op_DIVx:
  // Load 32-bit subtractor (Destination)
  STW    ACCL                  // Bits 15..0
  STW    ACCH                  // Bits 31..16
  // Divisor is loaded into the upper 16-bit (Source)
  LIT    #0                    // Lower 16-bit cleared
  // Clear 16-bit result shifter
  WRW    LSHR

  // 17 divide steps
  DIV.                         // First step is outside the loop
  LOOP16                       // Loop 16 times

  // One step of the division (right shift + subtract)
  DIV.                         // 16 following steps
  ENDLOOP                      // End of loop

  // Discard the 32-bit divisor
  DROP
  DROP

  FLAG   ---*-,CIN=CLR         // Update the V flag
  JUMP   V_SR,Op_Div_Overflow2 // V flag set : overflow occured

  // Read the 16-bit remainder from the subtractor
  LDW    ACCL                  // Bits 15..0
  // Read the 16-bit result shifter
  LDW    LSHR. RTS             // T = quotient, N = remainder

Op_Div_Overflow:
  DROP
  DROP                         // Drop the intermediate result
Op_Div_Overflow2:
  FLAG   ---1-,CIN=CLR RTS     // Set the overflow flag

//////////////////////////////////////
// 1000.yyy111.001xxx : DIVS opcode //
//////////////////////////////////////
Op_DIVS:
  CALL   EA1_Read_W            // Load the source (word)
  FLAG   ----0,CIN=CLR         // Clear C flag
  TSTW.                        // Check if source is null
  JUMP   Z_FLG,Trap_DivZero    // Divide by zero error

  JUMPN  N_FLG,Op_DIVS_Src_Pos // Check source sign bit
  NEGW                         // Bit set : take the oposite
  LDW    DH[EA2].
  LDW    DL[EA2]               // Load the destination (long)
  JUMPN  N_FLG,Op_DIVS_Neg     // Sign cleared : result will be negative
  NEGW.                        // Sign set : take the opposite
  FLAG   -----,CIN=C_ADD
  SWAP
  NEGCL.
  SWAP

Op_DIVS_Pos:
  CALL   Op_DIVx               // Result will pe positive
  JUMP   V_SR,Op_Div_Overflow2 // Overflow : do not store the result
  JUMP   N_FLG,Op_Div_Overflow // Sign set : do not store the result
  FLAG   -**-0,CIN=CLR         // Update N and Z flags
  STW    DL[EA2]
  STW    DH[EA2] RTS           // Store the result

Op_DIVS_Src_Pos:
  LDW    DH[EA2].
  LDW    DL[EA2]               // Load the destination (long)
  JUMPN  N_FLG,Op_DIVS_Pos     // Sign cleared : result will be positive
  NEGW.                        // Sign set : take the opposite
  FLAG   -----,CIN=C_ADD
  SWAP
  NEGCL.
  SWAP

Op_DIVS_Neg:
  CALL   Op_DIVx               // Do the divide
  JUMP   V_SR,Op_Div_Overflow2 // Overflow : do not store the result
  JUMP   N_FLG,Op_Div_Overflow // Sign set : do not store the result
  NEGW.                        // Take the oposite
  FLAG   -**-0,CIN=CLR         // Update N and Z flags
  STW    DL[EA2]
  STW    DH[EA2] RTS           // Store the result

///////////////////////////////////////
// 1001.yyy-00.xxxxxx : SUB.B opcode //
///////////////////////////////////////
Op_SUBB_r:
  CALL   EA1_Read_B
  LDB    DL[EA2]
  SUBB.
  FLAG   *****,CIN=CLR
  STB    DL[EA2] RTS

Op_SUBB_m:
  LDB    DL[EA2]
  CALL   EA1_Read_B
  SUBB.
  FLAG   *****,CIN=CLR
  JUMP   EA1_Update_B

////////////////////////////////////////
// 1001.yyy100.00xxxx : SUBX.B opcode //
////////////////////////////////////////
Op_SUBXB_r:
  LDB    DL[EA1]
  LDB    DL[EA2]
  FLAG   -----,CIN=X_SR
  SUBCB.
  FLAG   **#**,CIN=CLR
  STB    DL[EA2] RTS

Op_SUBXB_m:
  CALL   EA1_RB_An_Dec
  CALL   EA2_RB_An_Dec
  FLAG   -----,CIN=X_SR
  SUBCB.
  FLAG   **#**,CIN=CLR
  STB    (EA2)+ RTS  // TODO : -(A7) case !!!

///////////////////////////////////////
// 1001.yyy-01.xxxxxx : SUB.W opcode //
///////////////////////////////////////
Op_SUBW_r:
  CALL   EA1_Read_W
  LDW    DL[EA2]
  SUBW.
  FLAG   *****,CIN=CLR
  STW    DL[EA2] RTS

Op_SUBW_m:
  LDW    DL[EA2]
  CALL   EA1_Read_W
  SUBW.
  FLAG   *****,CIN=CLR
  JUMP   EA1_Update_W

////////////////////////////////////////
// 1001.yyy101.00xxxx : SUBX.W opcode //
////////////////////////////////////////
Op_SUBXW_r:
  LDW    DL[EA1]
  LDW    DL[EA2]
  FLAG   -----,CIN=X_SR
  SUBCW.
  FLAG   **#**,CIN=CLR
  STW    DL[EA2] RTS

Op_SUBXW_m:
  CALL   EA1_RW_An_Dec
  CALL   EA2_RW_An_Dec
  FLAG   -----,CIN=X_SR
  SUBCW.
  FLAG   **#**,CIN=CLR
  STW    (EA2) RTS

///////////////////////////////////////
// 1001.yyy-10.xxxxxx : SUB.L opcode //
///////////////////////////////////////
Op_SUBL_r:
  CALL   EA1_Read_L
  LDW    DL[EA2]
  SUBW.
  STW    DL[EA2]
  LDW    DH[EA2]
  FLAG   -----,CIN=C_ADD
  SUBCL.
  FLAG   *****,CIN=CLR
  STW    DH[EA2] RTS

Op_SUBL_m:
  CALL   EA1_Read_L
  LDW    DL[EA2]
  SUB2W.
  SWAP
  LDW    DH[EA2]
  FLAG   -----,CIN=C_ADD
  SUBC2L.
  FLAG   *****,CIN=CLR
  JUMP   EA1_Update_L

////////////////////////////////////////
// 1001.yyy110.00xxxx : SUBX.L opcode //
////////////////////////////////////////
Op_SUBXL_r:
  LDW    DL[EA1]               // Read LSW from register
  LDW    DL[EA2]               // Read LSW from register
  FLAG   -----,CIN=X_SR        // Carry in is X flag
  SUBCW.                       // Subtract both LSW
  STW    DL[EA2]               // Store result back to register
  LDW    DH[EA1]               // Read MSW from register
  LDW    DH[EA2]               // Read MSW from register
  FLAG   -----,CIN=C_ADD       // Carry in is adder carry
  SUBCL.                       // Subtract both MSW
  FLAG   **#**,CIN=CLR         // Update X, N, Z, V and C
  STW    DH[EA2] RTS           // Store result back to register

Op_SUBXL_m:
  CALL   Get_An_EA1            // An -> EA1
  CALL   Get_An_EA2            // An -> EA2
  LDW    -(EA1)                // Read LSW from effective address #1
  LDW    -(EA2)                // Read LSW from effective address #2
  FLAG   -----,CIN=X_SR        // Carry in is X flag
  SUBCW.                       // Subtract both LSW
  LDW    -(EA1)                // Read MSW from effective address #1
  LDW    -(EA2)                // Read MSW from effective address #2
  CALL   Set_An_EA1            // EA1 -> An
  CALL   Set_An_EA2            // EA2 -> An
  FLAG   -----,CIN=C_ADD       // Carry in is adder carry
  SUBCL.                       // Subtract both MSW
  STW    (EA2)+                // Write back MSW to memory
  FLAG   **#**,CIN=CLR         // Update X, N, Z, V and C
  STW    (EA2) RTS             // Write back LSW to memory

////////////////////////////////////////
// 1001.yyy011.xxxxxx : SUBA.W opcode //
////////////////////////////////////////
Op_SUBAW:
  CALL   EA1_Read_W            // Read word from effective address
  FLAG   -----,CIN=T15         // Carry in is bit #15 (sign)
  EXTW                         // Extend word to long
  SWAP                         // Swap LSW and MSW
Op_SUBA_jmp:
  LDW    AL[EA2]               // Read An LSW
  SUBW.                        // Subtract word to An LSW
  STW    AL[EA2]               // Store An LSW
  LDW    AH[EA2]               // Read An MSW
  FLAG   -----,CIN=C_ADD       // Carry in is adder carry
  SUBCL                        // Subtract extended word to An MSW
  STW    AH[EA2] RTS           // Store An MSW

////////////////////////////////////////
// 1001.yyy111.xxxxxx : SUBA.L opcode //
////////////////////////////////////////
Op_SUBAL:
  CALL   EA1_Read_L            // Read long from effective address
  JUMP   Op_SUBA_jmp           // Execute SUBA

///////////////////////////////////////
// 1011.yyy000.xxxxxx : CMP.B opcode //
///////////////////////////////////////
Op_CMPB:
  CALL   EA1_Read_B
  LDB    DL[EA2]
  SUBB.
  FLAG   -****,CIN=CLR
  DROP RTS

///////////////////////////////////////
// 1011.yyy001.xxxxxx : CMP.W opcode //
///////////////////////////////////////
Op_CMPW:
  CALL   EA1_Read_W
  LDW    DL[EA2]
  SUBW.
  FLAG   -****,CIN=CLR
  DROP RTS

///////////////////////////////////////
// 1011.yyy010.xxxxxx : CMP.L opcode //
///////////////////////////////////////
Op_CMPL:
  CALL   EA1_Read_L
  LDW    DL[EA2]
  SUBW.
  DROP
  LDW    DH[EA2]
  FLAG   -----,CIN=C_ADD
  SUBCL.
  FLAG   -****,CIN=CLR
  DROP RTS

////////////////////////////////////////
// 1011.yyy011.xxxxxx : CMPA.W opcode //
////////////////////////////////////////
Op_CMPAW:
  CALL   EA1_Read_W            // Read word from effective address
  FLAG   -----,CIN=T15         // Carry in is bit #15 (sign)
  EXTW                         // Extend word to long
  SWAP                         // Swap MSW and LSW
Op_CMPA:
  LDW    AL[EA2]               // Read An LSW
  SUBW.                        // Subtract word from An LSW
  DROP                         // Drop result
  LDW    AH[EA2]               // Read An MSW
  FLAG   -----,CIN=C_ADD       // Carry in is adder carry
  SUBCL.                       // Subtract extended word from An MSW
  FLAG   -****,CIN=CLR         // Update N, Z, V and C
  DROP RTS                     // Drop result

////////////////////////////////////////
// 1011.yyy100.xxxxxx : EOR.B opcode //
////////////////////////////////////////
Op_EORB:
  CALL   EA1_Read_B
  LDB    DL[EA2]
  XORB.
  FLAG   -**00,CIN=CLR
  JUMP   EA1_Update_B

////////////////////////////////////////
// 1011.yyy100.001xxx : CMPM.B opcode //
////////////////////////////////////////
Op_CMPMB:
  CALL   EA1_RB_An_Inc
  CALL   EA2_RB_An_Inc
  SUBB.
  FLAG   -****,CIN=CLR
  DROP   RTS

////////////////////////////////////////
// 1011.yyy101.xxxxxx : EOR.W opcode //
////////////////////////////////////////
Op_EORW:
  CALL   EA1_Read_W
  LDW    DL[EA2]
  XORW.
  FLAG   -**00,CIN=CLR
  JUMP   EA1_Update_W

////////////////////////////////////////
// 1011.yyy101.001xxx : CMPM.W opcode //
////////////////////////////////////////
Op_CMPMW:
  CALL   EA1_RW_An_Inc
  CALL   EA2_RW_An_Inc
  SUBW.
  FLAG   -****,CIN=CLR
  DROP   RTS

////////////////////////////////////////
// 1011.yyy110.xxxxxx : EOR.L opcode //
////////////////////////////////////////
Op_EORL:
  CALL   EA1_Read_L
  LDW    DL[EA2]
  XORW.
  SWAP
  LDW    DH[EA2]
  XORL.
  FLAG   -**00,CIN=CLR
  JUMP   EA1_Update_L

////////////////////////////////////////
// 1011.yyy110.001xxx : CMPM.L opcode //
////////////////////////////////////////
Op_CMPML:
  CALL   Get_An_EA1            // An -> EA1
  CALL   Get_An_EA2            // An -> EA2
  LDW    (EA1)+                // Read MSW from effective address #1
  LDW    (EA2)+                // Read MSW from effective address #2
  LDW    (EA1)+                // Read LSW from effective address #1
  LDW    (EA2)+                // Read LSW from effective address #2
  CALL   Set_An_EA1            // EA1 -> An
  CALL   Set_An_EA2            // EA2 -> An
  SUBW.                        // Subtract both LSW
  DROP                         // Drop result
  FLAG   -----,CIN=C_ADD       // Carry in is adder carry
  SUBCL.                       // Subtract both MSW
  FLAG   -****,CIN=CLR         // Update N, Z, V and C
  DROP   RTS                   // Drop result

////////////////////////////////////////
// 1011.yyy111.xxxxxx : CMPA.L opcode //
////////////////////////////////////////
Op_CMPAL:
  CALL   EA1_Read_L            // Read long from effective address
  JUMP   Op_CMPA               // Execute CMPA

///////////////////////////////////////
// 1100.yyy-00.xxxxxx : AND.B opcode //
///////////////////////////////////////
Op_ANDB_r:
  CALL   Op_ANDB               // Execute AND.B
  STB    DL[EA2] RTS           // Write back result to register

Op_ANDB_m:
  CALL   Op_ANDB               // Execute AND.B
  JUMP   EA1_Update_B          // Write back result to memory

Op_ANDB:
  CALL   EA1_Read_B            // Read byte from effective address
  LDB    DL[EA2]               // Read byte from register
  ANDB.                        // AND both bytes
  FLAG   -**00,CIN=CLR RTS     // Update N and Z, clear V and C

//////////////////////////////////////
// 1100.yyy100.00xxxx : ABCD opcode //
//////////////////////////////////////
Op_ABCD_r:
  LDB    DL[EA1]               // Dy
  LDB    DL[EA2]               // Dx
  CALL   ABCD_Calc             // Compute BCD addition
  FLAG   -*#--,CIN=CLR         // Update N and Z flags
  STB    DL[EA2] RTS           // Update Dx

Op_ABCD_m:
  CALL   EA1_RB_An_Dec
  CALL   EA2_RB_An_Dec
  CALL   ABCD_Calc             // Compute BCD addition
  FLAG   -*#--,CIN=CLR         // Update N and Z flags
  STB    (EA2)+ RTS            // TODO : -(A7) case !!!

ABCD_Calc:
  OVER                         // Duplicate Src
  LIT    #$000F                // Mask for low nibble
  ANDW                         // Keep Src low nibble
  OVER                         // Duplicate Dst
  LIT    #$000F                // Mask for low nibble
  ANDW.                        // Keep Dst low nibble
  FLAG   0---0,CIN=X_SR        // Carry in is the X flag
  ADDCW                        // Compute Src + Dst + X
  LIT    #10                   // Comparison value
  OVER                         // Duplicate result
  SUBW.                        // Compare it to 10
  JUMP   N_FLG,ABCD_Less10     // Jump if result < 0
  LIT    #$0010                // BCD carry value
  ADDW                         // Add 10 (BCD) to the result
  SWAP                         // Keep result
ABCD_Less10:                   
  DROP                         // Drop the intermediate result
                               
  SWAP                         // Get Dst
  LIT    #$00F0                // Mask for high nibble
  ANDW                         // Keep Dst high nibble
  ADDW                         // Add it to the intermediate result
  SWAP
  LIT    #$00F0                // Mask for high nibble
  ANDW                         // Keep Src high nibble
  ADDW                         // Add it to the intermediate result
  LIT    #$A0
  OVER                         // Duplicate result
  SUBW.                        // Compare it to 160
  JUMP   N_FLG,ABCD_Less100    // Jump if result < 0
  FLAG   1---1                 // Set X and C
  SWAP                         // Keep (result - 160)
ABCD_Less100:
  DROP.  RTS                   // Drop the intermediate result

///////////////////////////////////////
// 1100.yyy-01.xxxxxx : AND.W opcode //
///////////////////////////////////////
Op_ANDW_r:
  CALL   Op_ANDW               // Execute AND.W
  STW    DL[EA2] RTS           // Write back result to register

Op_ANDW_m:
  CALL   Op_ANDW               // Execute AND.W
  JUMP   EA1_Update_W          // Write back result to memory

Op_ANDW:
  CALL   EA1_Read_W            // Read word from effective address
  LDW    DL[EA2]               // Read word from register
  ANDW.                        // AND both words
  FLAG   -**00,CIN=CLR RTS     // Update N and Z, clear V and C

/////////////////////////////////////
// 1100.yyy101.00xxxx : EXG opcode //
/////////////////////////////////////
Op_EXG_DD:
  LDW   DH[EA1]
  LDW   DL[EA1]
  LDW   DH[EA2]
  LDW   DL[EA2]
  STW   DL[EA1]
  STW   DH[EA1]
  STW   DL[EA2]
  STW   DH[EA2] RTS

Op_EXG_AA:
  LDW   AH[EA1]
  LDW   AL[EA1]
  LDW   AH[EA2]
  LDW   AL[EA2]
  STW   AL[EA1]
  STW   AH[EA1]
  STW   AL[EA2]
  STW   AH[EA2] RTS

///////////////////////////////////////
// 1100.yyy-10.xxxxxx : AND.L opcode //
///////////////////////////////////////
Op_ANDL_r:
  CALL   Op_ANDL
  JUMP   EA2_WL_Reg

Op_ANDL_m:
  CALL   Op_ANDL
  JUMP   EA1_Update_L

Op_ANDL:
  CALL   EA1_Read_L
  LDW    DL[EA2]
  ANDW.
  SWAP
  LDW    DH[EA2]
  ANDL.
  FLAG   -**00,CIN=CLR RTS

/////////////////////////////////////
// 1100.yyy110.001xxx : EXG opcode //
/////////////////////////////////////
Op_EXG_DA:
  LDW    AH[EA1]
  LDW    AL[EA1]
  LDW    DH[EA2]
  LDW    DL[EA2]
  STW    AL[EA1]
  STW    AH[EA1]
  STW    DL[EA2]
  STW    DH[EA2] RTS

//////////////////////////////////////
// 1100.yyy011.001xxx : MULU opcode //
//////////////////////////////////////
Op_MULU:
  LDW    DL[EA2]          // Load the destination
  CALL   EA1_Read_W       // Load the source
Op_MULS_Pos:
  CALL   Op_MULx
  TSTW.
  STW    DL[EA2]
  TSTL.
  FLAG   -**00,CIN=CLR
  STW    DH[EA2] RTS

Op_MULx:
  // Load 16-bit shifter (source)
  STW    LSHR
  // Destination is loaded into the upper 16-bit
  LIT    #0               // Lower 16-bit cleared
  // Clear 32-bit accummulator
  WRW    ACCL             // Bits 15..0
  WRW    ACCH             // Bits 31..16
  // Right shift destination by one position
  FLAG   -----,CIN=CLR
  RSHL

  LOOP16                  // Loop 16 times

  // One step of the multiply (right shift + add)
  MUL
  ENDLOOP

  // Discard the destination
  DROP
  DROP

  // Read the 32-bit result from the accumulator
  LDW    ACCH             // Bits 31..16
  LDW    ACCL RTS         // Bits 15..0

//////////////////////////////////////
// 1100.yyy111.001xxx : MULS opcode //
//////////////////////////////////////
Op_MULS:
  LDW    DL[EA2]               // Load the destination (word)
  CALL   EA1_Read_W            // Load the source (word)
  TSTW.                        // Check source sign
  JUMPN  N_FLG,Op_MULS_Src_Pos // Source sign cleared
  NEGW                         // Source sign set : take the opposite
  SWAP.                        // Check destination
  JUMPN  N_FLG,Op_MULS_Neg     // Sign cleared : result will be negative
  NEGW                         // Sign set : take the opposite
  JUMP   Op_MULS_Pos           // Result will pe positive

Op_MULS_Src_Pos:
  SWAP.                        // Check destination
  JUMPN  N_FLG,Op_MULS_Pos     // Sign cleared : result will be positive
  NEGW                         // Sign set : take the opposite

Op_MULS_Neg:
  CALL   Op_MULx
  NEGW.
  STW    DL[EA2]
  FLAG   -----,CIN=C_ADD
  NEGCL.
  FLAG   -**00,CIN=CLR
  STW    DH[EA2] RTS

///////////////////////////////////////
// 1101.yyy-00.xxxxxx : ADD.B opcode //
///////////////////////////////////////
Op_ADDB_r:
  CALL   Op_ADDB               // Execute ADD.B
  STB    DL[EA2] RTS           // Write back result to register

Op_ADDB_m:
  CALL   Op_ADDB               // Execute ADD.B
  JUMP   EA1_Update_B          // Write back result to memory

Op_ADDB:
  CALL   EA1_Read_B            // Read byte from effective address
  LDB    DL[EA2]               // Read byte from register
  ADDB.                        // Add both bytes
  FLAG   *****,CIN=CLR RTS     // Update X, N, Z, V and C

////////////////////////////////////////
// 1101.yyy100.00xxxx : ADDX.B opcode //
////////////////////////////////////////
Op_ADDXB_r:
  LDB    DL[EA1]
  LDB    DL[EA2]
  FLAG   -----,CIN=X_SR
  ADDCB.
  FLAG   **#**,CIN=CLR
  STB    DL[EA2] RTS

Op_ADDXB_m:
  CALL   EA1_RB_An_Dec
  CALL   EA2_RB_An_Dec
  FLAG   -----,CIN=X_SR
  ADDCB.
  FLAG   **#**,CIN=CLR
  STB    (EA2)+ RTS  // TODO : -(A7) case !!!

///////////////////////////////////////
// 1101.yyy-01.xxxxxx : ADD.W opcode //
///////////////////////////////////////
Op_ADDW_r:
  CALL   Op_ADDW               // Execute ADD.W
  STW    DL[EA2] RTS           // Write back result to register

Op_ADDW_m:
  CALL   Op_ADDW               // Execute ADD.W
  JUMP   EA1_Update_W          // Write back result to memory

Op_ADDW:
  CALL   EA1_Read_W            // Read word from effective address
  LDW    DL[EA2]               // Read word from register
  ADDW.                        // Add both words
  FLAG   *****,CIN=CLR RTS     // Update X, N, Z, V and C

////////////////////////////////////////
// 1101.yyy101.00xxxx : ADDX.W opcode //
////////////////////////////////////////
Op_ADDXW_r:
  LDW    DL[EA1]
  LDW    DL[EA2]
  FLAG   -----,CIN=X_SR
  ADDCW.
  FLAG   **#**,CIN=CLR
  STW    DL[EA2] RTS

Op_ADDXW_m:
  CALL   EA1_RW_An_Dec
  CALL   EA2_RW_An_Dec
  FLAG   -----,CIN=X_SR
  ADDCW.
  FLAG   **#**,CIN=CLR
  STW    (EA2) RTS

///////////////////////////////////////
// 1101.yyy-10.xxxxxx : ADD.L opcode //
///////////////////////////////////////
Op_ADDL_r:
  CALL   Op_ADDL               // Execute ADD.L
  JUMP   EA2_WL_Reg            // Write back result to register

Op_ADDL_m:
  CALL   Op_ADDL               // Execute ADD.L
  JUMP   EA1_Update_L          // Write back result to memory

Op_ADDL:
  CALL   EA1_Read_L            // Read long from effective address
  LDW    DL[EA2]               // Read Dn LSW
  ADDW.                        // Add both LSW
  SWAP                         // Swap LSW and MSW
  LDW    DH[EA2]               // Read Dn MSW
  FLAG   -----,CIN=C_ADD       // Carry in is adder carry out
  ADDCL.                       // Add both MSW
  FLAG   *****,CIN=CLR RTS     // Update X, N, Z, V and C

////////////////////////////////////////
// 1101.yyy110.00xxxx : ADDX.L opcode //
////////////////////////////////////////
Op_ADDXL_r:
  LDW    DL[EA1]
  LDW    DL[EA2]
  FLAG   -----,CIN=X_SR
  ADDCW.
  STW    DL[EA2]
  LDW    DH[EA1]
  LDW    DH[EA2]
  FLAG   -----,CIN=C_ADD
  ADDCL.
  FLAG   **#**,CIN=CLR
  STW    DH[EA2] RTS

Op_ADDXL_m:
  CALL   Get_An_EA1            // An -> EA1
  CALL   Get_An_EA2            // An -> EA2
  LDW    -(EA1)                // Read LSW from effective address #1
  LDW    -(EA2)                // Read LSW from effective address #2
  FLAG   -----,CIN=X_SR        // Carry in is X flag
  ADDCW.                       // Add both LSW
  LDW    -(EA1)                // Read MSW from effective address #1
  LDW    -(EA2)                // Read MSW from effective address #2
  CALL   Set_An_EA1            // EA1 -> An
  CALL   Set_An_EA2            // EA2 -> An
  FLAG   -----,CIN=C_ADD       // Carry in is adder carry
  ADDCL.                       // Add both MSW
  STW    (EA2)+                // Write back MSW to memory
  FLAG   **#**,CIN=CLR         // Update X, N, Z, V and C
  STW    (EA2) RTS             // Write back LSW to memory

////////////////////////////////////////
// 1101.yyy011.xxxxxx : ADDA.W opcode //
////////////////////////////////////////
Op_ADDAW:
  CALL   EA1_Read_W            // Read word from effective address
  FLAG   -----,CIN=T15         // Carry in is bit #15 (sign)
  EXTW                         // Extend word to long
  SWAP                         // Swap LSW and MSW
Op_ADDA_jmp:
  LDW    AL[EA2]               // Read An LSW
  ADDW.                        // Add word to An LSW
  STW    AL[EA2]               // Store An LSW
  LDW    AH[EA2]               // Read An MSW
  FLAG   -----,CIN=C_ADD       // Carry in is adder carry
  ADDCL                        // Add extended word to An MSW
  STW    AH[EA2] RTS           // Store An MSW

////////////////////////////////////////
// 1101.yyy111.xxxxxx : ADDA.L opcode //
////////////////////////////////////////
Op_ADDAL:
  CALL   EA1_Read_L            // Read long from effective address
  JUMP   Op_ADDA_jmp           // Execute ADDA

/////////////////////////////////////////////
// 1110.yyy000.100xxx : ASR.B Dx,Dy opcode //
/////////////////////////////////////////////
Op_ASRB_rr:
  LDB    DL[EA1]          // Load Dy.B
  LDW    DL[EA2]          // Load shift count
  JUMP   ASRB_jmp

/////////////////////////////////////////////
// 1110.yyy000.000xxx : ASR.B #x,Dy opcode //
/////////////////////////////////////////////
Op_ASRB_ir:
  LDB    DL[EA1]          // Load Dy.B
  LDW    IMMR             // Load shift count
ASRB_jmp:
  FLAG   ---00,CIN=N7     // Clear V and C flags
  LOOPT                   // Loop shift count times
  RSHB.                   // Right shift with flag update
  FLAG   *--0*,CIN=T7     // Update X and C flags
  ENDLOOP
  JUMP   Write_DnB        // Store result into Dy.B

/////////////////////////////////////////////
// 1110.yyy000.101xxx : LSR.B Dx,Dy opcode //
/////////////////////////////////////////////
Op_LSRB_rr:
  LDB    DL[EA1]          // Load Dy.B
  LDW    DL[EA2]          // Load shift count
  JUMP   LSRB_jmp

/////////////////////////////////////////////
// 1110.yyy000.001xxx : LSR.B #x,Dy opcode //
/////////////////////////////////////////////
Op_LSRB_ir:
  LDB    DL[EA1]          // Load Dy.B
  LDW    IMMR             // Load shift count
LSRB_jmp:
  FLAG   ---00,CIN=CLR    // Clear V and C flags
  LOOPT                   // Loop shift count times
  RSHB.                   // Right shift with flag update
  FLAG   *--0*,CIN=CLR    // Update X and C flags
  ENDLOOP
  JUMP   Write_DnB        // Store result into Dy.B

//////////////////////////////////////////////
// 1110.yyy000.110xxx : ROXR.B Dx,Dy opcode //
//////////////////////////////////////////////
Op_ROXRB_rr:
  LDB    DL[EA1]          // Load Dy.B
  LDW    DL[EA2]          // Load shift count
  JUMP   ROXRB_jmp

//////////////////////////////////////////////
// 1110.yyy000.010xxx : ROXR.B #x,Dy opcode //
//////////////////////////////////////////////
Op_ROXRB_ir:
  LDB    DL[EA1]          // Load Dy.B
  LDW    IMMR             // Load shift count
ROXRB_jmp:
  FLAG   ---0-,CIN=X_SR   // Clear V flag
  LOOPT                   // Loop shift count times
  RSHB.                   // Right shift with flag update
  FLAG   *--0*,CIN=C_FLG  // Update X and C flags
  ENDLOOP
  JUMP   Write_DnB        // Store result into Dy.B

/////////////////////////////////////////////
// 1110.yyy000.111xxx : ROR.B Dx,Dy opcode //
/////////////////////////////////////////////
Op_RORB_rr:
  LDB    DL[EA1]          // Load Dy.B
  LDW    DL[EA2]          // Load shift count
  JUMP   RORB_jmp

/////////////////////////////////////////////
// 1110.yyy000.011xxx : ROR.B #x,Dy opcode //
/////////////////////////////////////////////
Op_RORB_ir:
  LDB    DL[EA1]          // Load Dy.B
  LDW    IMMR             // Load shift count
RORB_jmp:
  FLAG   ---00,CIN=N0     // Clear V and C flags
  LOOPT                   // Loop shift count times
  RSHB.                   // Right shift with flag update
  FLAG   ---0*,CIN=T0     // Update C flag
  ENDLOOP
  JUMP   Write_DnB        // Store result into Dy.B

/////////////////////////////////////////////
// 1110.yyy100.100xxx : ASL.B Dx,Dy opcode //
/////////////////////////////////////////////
Op_ASLB_rr:
  LDB    DL[EA1]          // Load Dy.B
  LDW    DL[EA2]          // Load shift count
  JUMP   ASLB_jmp

/////////////////////////////////////////////
// 1110.yyy100.000xxx : ASL.B #x,Dy opcode //
/////////////////////////////////////////////
Op_ASLB_ir:
  LDB    DL[EA1]          // Load Dy.B
  LDW    IMMR             // Load shift count
ASLB_jmp:
  FLAG   ---00,CIN=CLR    // Clear V and C flags
  LOOPT                   // Loop shift count times
  LSHB.                   // Left shift with flag update
  FLAG   *--**,CIN=CLR    // Update X, V and C flags
  ENDLOOP
  JUMP   Write_DnB        // Store result into Dy.B

/////////////////////////////////////////////
// 1110.yyy100.101xxx : LSL.B Dx,Dy opcode //
/////////////////////////////////////////////
Op_LSLB_rr:
  LDB    DL[EA1]          // Load Dy.B
  LDW    DL[EA2]          // Load shift count
  JUMP   LSLB_jmp

/////////////////////////////////////////////
// 1110.yyy100.001xxx : LSL.B #x,Dy opcode //
/////////////////////////////////////////////
Op_LSLB_ir:
  LDB    DL[EA1]          // Load Dy.B
  LDW    IMMR             // Load shift count
LSLB_jmp:
  FLAG   ---00,CIN=CLR    // Clear V and C flags
  LOOPT                   // Loop shift count times
  LSHB.                   // Left shift with flag update
  FLAG   *--0*,CIN=CLR    // Update X and C flags
  ENDLOOP
  JUMP   Write_DnB        // Store result into Dy.B

//////////////////////////////////////////////
// 1110.yyy100.110xxx : ROXL.B Dx,Dy opcode //
//////////////////////////////////////////////
Op_ROXLB_rr:
  LDB    DL[EA1]          // Load Dy.B
  LDW    DL[EA2]          // Load shift count
  JUMP   ROXLB_jmp

//////////////////////////////////////////////
// 1110.yyy100.010xxx : ROXL.B #x,Dy opcode //
//////////////////////////////////////////////
Op_ROXLB_ir:
  LDB    DL[EA1]          // Load Dy.B
  LDW    IMMR             // Load shift count
ROXLB_jmp:
  FLAG   ---0-,CIN=X_SR   // Clear V flag
  LOOPT                   // Loop shift count times
  LSHB.                   // Left shift with flag update
  FLAG   *--0*,CIN=C_FLG  // Update X and C flags
  ENDLOOP
  JUMP   Write_DnB        // Store result into Dy.B

/////////////////////////////////////////////
// 1110.yyy100.111xxx : ROL.B Dx,Dy opcode //
/////////////////////////////////////////////
Op_ROLB_rr:
  LDB    DL[EA1]          // Load Dx.B
  LDW    DL[EA2]          // Load shift count
  JUMP   ROLB_jmp

/////////////////////////////////////////////
// 1110.yyy100.011xxx : ROL.B #x,Dy opcode //
/////////////////////////////////////////////
Op_ROLB_ir:
  LDB    DL[EA1]          // Load Dx.B
  LDW    IMMR             // Load shift count
ROLB_jmp:
  FLAG   ---00,CIN=N7     // Clear V and C flags
  LOOPT                   // Loop shift count times
  LSHB.                   // Left shift with flag update
  FLAG   ---0*,CIN=T7     // Update C flag
  ENDLOOP
  JUMP   Write_DnB        // Store result into Dy.B

/////////////////////////////////////////////
// 1110.yyy001.100xxx : ASR.W Dx,Dy opcode //
/////////////////////////////////////////////
Op_ASRW_rr:
  LDW    DL[EA1]          // Load Dy.W
  LDW    DL[EA2]          // Load shift count
  JUMP   ASRW_jmp

/////////////////////////////////////////////
// 1110.yyy001.000xxx : ASR.W #x,Dy opcode //
/////////////////////////////////////////////
Op_ASRW_ir:
  LDW    DL[EA1]          // Load Dy.W
  LDW    IMMR             // Load shift count
ASRW_jmp:
  FLAG   ---00,CIN=N15    // Clear V and C flags
  LOOPT                   // Loop shift count times
  RSHW.                   // Right shift with flag update
  FLAG   *--0*,CIN=T15    // Update X and C flags
  ENDLOOP
  JUMP   Write_DnW        // Store result into Dy.W

/////////////////////////////////////////////
// 1110.yyy001.101xxx : LSR.W Dx,Dy opcode //
/////////////////////////////////////////////
Op_LSRW_rr:
  LDW    DL[EA1]          // Load Dy.W
  LDW    DL[EA2]          // Load shift count
  JUMP   LSRW_jmp

/////////////////////////////////////////////
// 1110.yyy001.001xxx : LSR.W #x,Dy opcode //
/////////////////////////////////////////////
Op_LSRW_ir:
  LDW    DL[EA1]          // Load Dy.W
  LDW    IMMR             // Load shift count
LSRW_jmp:
  FLAG   ---00,CIN=CLR    // Clear V and C flags
  LOOPT                   // Loop shift count times
  RSHW.                   // Right shift with flag update
  FLAG   *--0*,CIN=CLR    // Update X and C flags
  ENDLOOP
  JUMP   Write_DnW        // Store result into Dy.W

//////////////////////////////////////////////
// 1110.yyy001.110xxx : ROXR.W Dx,Dy opcode //
//////////////////////////////////////////////
Op_ROXRW_rr:
  LDW    DL[EA1]          // Load Dy.W
  LDW    DL[EA2]          // Load shift count
  JUMP   ROXRW_jmp

//////////////////////////////////////////////
// 1110.yyy001.010xxx : ROXR.W #x,Dy opcode //
//////////////////////////////////////////////
Op_ROXRW_ir:
  LDW    DL[EA1]          // Load Dy.W
  LDW    IMMR             // Load shift count
ROXRW_jmp:
  FLAG   ---0-,CIN=X_SR   // Clear V flag
  LOOPT                   // Loop shift count times
  RSHW.                   // Right shift with flag update
  FLAG   *--0*,CIN=C_FLG  // Update X and C flags
  ENDLOOP
  JUMP   Write_DnW        // Store result into Dy.W

/////////////////////////////////////////////
// 1110.yyy001.111xxx : ROR.W Dx,Dy opcode //
/////////////////////////////////////////////
Op_RORW_rr:
  LDW    DL[EA1]          // Load Dy.W
  LDW    DL[EA2]          // Load shift count
  JUMP   RORW_jmp

/////////////////////////////////////////////
// 1110.yyy001.011xxx : ROR.W #x,Dy opcode //
/////////////////////////////////////////////
Op_RORW_ir:
  LDW    DL[EA1]          // Load Dy.W
  LDW    IMMR             // Load shift count
RORW_jmp:
  FLAG   ---00,CIN=N0     // Clear V and C flags
  LOOPT                   // Loop shift count times
  RSHW.                   // Right shift with flag update
  FLAG   ---0*,CIN=T0     // Update C flag
  ENDLOOP
  JUMP   Write_DnW        // Store result into Dy.W

/////////////////////////////////////////////
// 1110.yyy101.100xxx : ASL.W Dx,Dy opcode //
/////////////////////////////////////////////
Op_ASLW_rr:
  LDW    DL[EA1]          // Load Dy.W
  LDW    DL[EA2]          // Load shift count
  JUMP   ASLW_jmp

/////////////////////////////////////////////
// 1110.yyy101.000xxx : ASL.W #x,Dy opcode //
/////////////////////////////////////////////
Op_ASLW_ir:
  LDW    DL[EA1]          // Load Dy.W
  LDW    IMMR             // Load shift count
ASLW_jmp:
  FLAG   ---00,CIN=CLR    // Clear V and C flags
  LOOPT                   // Loop shift count times
  LSHW.                   // Left shift with flag update
  FLAG   *--**,CIN=CLR    // Update X, V and C flags
  ENDLOOP
  JUMP   Write_DnW        // Store result into Dy.W

/////////////////////////////////////////////
// 1110.yyy101.101xxx : LSL.W Dx,Dy opcode //
/////////////////////////////////////////////
Op_LSLW_rr:
  LDW    DL[EA1]          // Load Dy.W
  LDW    DL[EA2]          // Load shift count
  JUMP   LSLW_jmp

/////////////////////////////////////////////
// 1110.yyy101.101xxx : LSL.W #x,Dy opcode //
/////////////////////////////////////////////
Op_LSLW_ir:
  LDW    DL[EA1]          // Load Dy.W
  LDW    IMMR             // Load shift count
LSLW_jmp:
  FLAG   ---00,CIN=CLR    // Clear V and C flags
  LOOPT                   // Loop shift count times
  LSHW.                   // Left shift with flag update
  FLAG   *--0*,CIN=CLR    // Update X and C flags
  ENDLOOP
  JUMP   Write_DnW        // Store result into Dy.W

//////////////////////////////////////////////
// 1110.yyy101.110xxx : ROXL.W Dx,Dy opcode //
//////////////////////////////////////////////
Op_ROXLW_rr:
  LDW    DL[EA1]          // Load Dy.W
  LDW    DL[EA2]          // Load shift count
  JUMP   ROXLW_jmp

//////////////////////////////////////////////
// 1110.yyy101.010xxx : ROXL.W #x,Dy opcode //
//////////////////////////////////////////////
Op_ROXLW_ir:
  LDW    DL[EA1]          // Load Dy.W
  LDW    IMMR             // Load shift count
ROXLW_jmp:
  FLAG   ---0-,CIN=X_SR   // Clear V flag
  LOOPT                   // Loop shift count times
  LSHW.                   // Left shift with flag update
  FLAG   *--0*,CIN=C_FLG  // Update X and C flags
  ENDLOOP
  JUMP   Write_DnW        // Store result into Dy.W

/////////////////////////////////////////////
// 1110.yyy101.111xxx : ROL.W Dx,Dy opcode //
/////////////////////////////////////////////
Op_ROLW_rr:
  LDW    DL[EA1]          // Load Dy.W
  LDW    DL[EA2]          // Load shift count
  JUMP   ROLW_jmp

/////////////////////////////////////////////
// 1110.yyy101.011xxx : ROL.W #x,Dy opcode //
/////////////////////////////////////////////
Op_ROLW_ir:
  LDW    DL[EA1]          // Load Dy.W
  LDW    IMMR             // Load shift count
ROLW_jmp:
  FLAG   ---00,CIN=N15    // Clear V and C flags
  LOOPT                   // Loop shift count times
  LSHW.                   // Left shift with flag update
  FLAG   ---0*,CIN=T15    // Update C flag
  ENDLOOP
  JUMP   Write_DnW        // Store result into Dy.W

/////////////////////////////////////////////
// 1110.yyy010.100xxx : ASR.L Dx,Dy opcode //
/////////////////////////////////////////////
Op_ASRL_rr:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  FLAG   ---00,CIN=N15    // Clear V and C flags
  LDW    DL[EA2]          // Load shift count
  JUMP   ASRL_jmp

/////////////////////////////////////////////
// 1110.yyy010.000xxx : ASR.L #x,Dy opcode //
/////////////////////////////////////////////
Op_ASRL_ir:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  FLAG   ---00,CIN=N15    // Clear V and C flags
  LDW    IMMR             // Load shift count
ASRL_jmp:
  LOOPT                   // Loop shift count times
  RSHL.                   // Right shift with flag update
  FLAG   *--0*,CIN=N15    // Update X and C flags
  ENDLOOP
  JUMP   Write_DnL        // Store result into Dy.L

/////////////////////////////////////////////
// 1110.yyy010.101xxx : LSR.L Dx,Dy opcode //
/////////////////////////////////////////////
Op_LSRL_rr:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  LDW    DL[EA2]          // Load shift count
  JUMP   LSRL_jmp

/////////////////////////////////////////////
// 1110.yyy010.001xxx : LSR.L #x,Dy opcode //
/////////////////////////////////////////////
Op_LSRL_ir:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  LDW    IMMR             // Load shift count
LSRL_jmp:
  FLAG   ---00,CIN=CLR    // Clear V and C flags
  LOOPT                   // Loop shift count times
  RSHL.                   // Right shift with flag update
  FLAG   *--0*,CIN=CLR    // Update X and C flags
  ENDLOOP
  JUMP   Write_DnL        // Store result into Dy.L

//////////////////////////////////////////////
// 1110.yyy010.110xxx : ROXR.L Dx,Dy opcode //
//////////////////////////////////////////////
Op_ROXRL_rr:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  LDW    DL[EA2]          // Load shift count
  JUMP   ROXRL_jmp

//////////////////////////////////////////////
// 1110.yyy010.010xxx : ROXR.L #x,Dy opcode //
//////////////////////////////////////////////
Op_ROXRL_ir:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  LDW    IMMR             // Load shift count
ROXRL_jmp:
  FLAG   ---0-,CIN=X_SR   // Clear V flag
  LOOPT                   // Loop shift count times
  RSHL.                   // Right shift with flag update
  FLAG   *--0*,CIN=C_FLG  // Update X and C flags
  ENDLOOP
  JUMP   Write_DnL        // Store result into Dy.L

/////////////////////////////////////////////
// 1110.yyy010.111xxx : ROR.L Dx,Dy opcode //
/////////////////////////////////////////////
Op_RORL_rr:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  LDW    DL[EA2]          // Load shift count
  JUMP   RORL_jmp

/////////////////////////////////////////////
// 1110.yyy010.011xxx : ROR.L #x,Dy opcode //
/////////////////////////////////////////////
Op_RORL_ir:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  LDW    IMMR             // Load shift count
RORL_jmp:
  FLAG   ---00,CIN=N0     // Clear V and C flags
  LOOPT                   // Loop shift count times
  FLAG   ---0*,CIN=T0     // Update C flag
  RSHL.                   // Right shift with flag update
  ENDLOOP
  JUMP   Write_DnL        // Store result into Dy.L

/////////////////////////////////////////////
// 1110.yyy110.100xxx : ASL.L Dx,Dy opcode //
/////////////////////////////////////////////
Op_ASLL_rr:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  LDW    DL[EA2]          // Load shift count
  JUMP   ASLL_jmp

/////////////////////////////////////////////
// 1110.yyy110.000xxx : ASL.L #x,Dy opcode //
/////////////////////////////////////////////
Op_ASLL_ir:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  LDW    IMMR             // Load shift count
ASLL_jmp:
  FLAG   ---00,CIN=CLR    // Clear V and C flags
  LOOPT                   // Loop shift count times
  LSHL.                   // Left shift with flag update
  FLAG   *--**,CIN=CLR    // Update X, V and C flags
  ENDLOOP
  JUMP   Write_DnL        // Store result into Dy.L

/////////////////////////////////////////////
// 1110.yyy110.101xxx : LSL.L Dx,Dy opcode //
/////////////////////////////////////////////
Op_LSLL_rr:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  LDW    DL[EA2]          // Load shift count
  JUMP   LSLL_jmp

/////////////////////////////////////////////
// 1110.yyy110.001xxx : LSL.L #x,Dy opcode //
/////////////////////////////////////////////
Op_LSLL_ir:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  LDW    IMMR             // Load shift count
LSLL_jmp:
  FLAG   ---00,CIN=CLR    // Clear V and C flags
  LOOPT                   // Loop shift count times
  LSHL.                   // Left shift with flag update
  FLAG   *--0*,CIN=CLR    // Update X and C flags
  ENDLOOP
  JUMP   Write_DnL        // Store result into Dy.L

//////////////////////////////////////////////
// 1110.yyy110.110xxx : ROXL.L Dx,Dy opcode //
//////////////////////////////////////////////
Op_ROXLL_rr:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  LDW    DL[EA2]          // Load shift count
  JUMP   ROXLL_jmp

//////////////////////////////////////////////
// 1110.yyy110.010xxx : ROXL.L #x,Dy opcode //
//////////////////////////////////////////////
Op_ROXLL_ir:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  LDW    IMMR             // Load shift count
ROXLL_jmp:
  FLAG   ---0-,CIN=X_SR   // Clear V flag
  LOOPT                   // Loop shift count times
  LSHL.                   // Left shift with flag update
  FLAG   *--0*,CIN=C_FLG  // Update X and C flags
  ENDLOOP
  JUMP   Write_DnL        // Store result into Dy.L

/////////////////////////////////////////////
// 1110.yyy110.111xxx : ROL.L Dx,Dy opcode //
/////////////////////////////////////////////
Op_ROLL_rr:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  FLAG   ---00,CIN=N15    // Clear V and C flags
  LDW    DL[EA2]          // Load shift count
  JUMP   ROLL_jmp

/////////////////////////////////////////////
// 1110.yyy110.011xxx : ROL.L #x,Dy opcode //
/////////////////////////////////////////////
Op_ROLL_ir:
  LDW    DH[EA1]
  LDW    DL[EA1]          // Load Dy.L
  FLAG   ---00,CIN=N15    // Clear V and C flags
  LDW    IMMR             // Load shift count
ROLL_jmp:
  LOOPT                   // Loop shift count times
  FLAG   ---0*,CIN=N15    // Update C flag
  LSHL.                   // Left shift with flags update
  ENDLOOP
  JUMP   Write_DnL        // Store result into Dy.L

////////////////////////////////////////////
// 1110.000011.xxxxxx : ASR.W <ea> opcode //
////////////////////////////////////////////
Op_ASRW_m:
  CALL   EA1_Read_W       // Load <ea>.W
  FLAG   -----,CIN=T15    // Carry in is Bit #15
  RSHW.                   // Right shift with flags update
  FLAG   ***0*,CIN=CLR    // Update M68k flags
  JUMP   EA1_Update_W     // Save <ea>.W

////////////////////////////////////////////
// 1110.001011.xxxxxx : LSR.W <ea> opcode //
////////////////////////////////////////////
Op_LSRW_m:
  CALL   EA1_Read_W       // Load <ea>.W
  FLAG   -----,CIN=CLR    // Carry in is 0
  RSHW.                   // Right shift with flags update
  FLAG   ***0*,CIN=CLR    // Update M68k flags
  JUMP   EA1_Update_W     // Save <ea>.W

/////////////////////////////////////////////
// 1110.010011.xxxxxx : ROXR.W <ea> opcode //
/////////////////////////////////////////////
Op_ROXRW_m:
  CALL   EA1_Read_W       // Load <ea>.W
  FLAG   -----,CIN=X_SR   // Carry in is X flag
  RSHW.                   // Right shift with flags update
  FLAG   ***0*,CIN=CLR    // Update M68k flags
  JUMP   EA1_Update_W     // Save <ea>.W

////////////////////////////////////////////
// 1110.011011.xxxxxx : ROR.W <ea> opcode //
////////////////////////////////////////////
Op_RORW_m:
  CALL   EA1_Read_W       // Load <ea>.W
  FLAG   -----,CIN=T0     // Carry in is Bit #0
  RSHW.                   // Right shift with flags update
  FLAG   -**0*,CIN=CLR    // Update M68k flags
  JUMP   EA1_Update_W     // Save <ea>.W

////////////////////////////////////////////
// 1110.100011.xxxxxx : ASL.W <ea> opcode //
////////////////////////////////////////////
Op_ASLW_m:
  CALL   EA1_Read_W       // Load <ea>.W
  FLAG   -----,CIN=CLR    // Carry in is 0
  LSHW.                   // Left shift with flags update
  FLAG   *****,CIN=CLR    // Update M68k flags
  JUMP   EA1_Update_W     // Save <ea>.W

////////////////////////////////////////////
// 1110.101011.xxxxxx : LSL.W <ea> opcode //
////////////////////////////////////////////
Op_LSLW_m:
  CALL   EA1_Read_W       // Load <ea>.W
  FLAG   -----,CIN=CLR    // Carry in is 0
  LSHW.                   // Left shift with flags update
  FLAG   ***0*,CIN=CLR    // Update M68k flags
  JUMP   EA1_Update_W     // Save <ea>.W

/////////////////////////////////////////////
// 1110.110011.xxxxxx : ROXL.W <ea> opcode //
/////////////////////////////////////////////
Op_ROXLW_m:
  CALL   EA1_Read_W       // Load <ea>.W
  FLAG   -----,CIN=X_SR   // Carry in is X flag
  LSHW.                   // Left shift with flags update
  FLAG   ***0*,CIN=CLR    // Update M68k flags
  JUMP   EA1_Update_W     // Save <ea>.W

////////////////////////////////////////////
// 1110.111011.xxxxxx : ROL.W <ea> opcode //
////////////////////////////////////////////
Op_ROLW_m:
  CALL   EA1_Read_W       // Load <ea>.W
  FLAG   -----,CIN=T15    // Carry in is Bit #15
  LSHW.                   // Left shift with flags update
  FLAG   -**0*,CIN=CLR    // Update M68k flags
  JUMP   EA1_Update_W     // Save <ea>.W

////////////////////////////////////
// Effective Address #1 read BYTE //
////////////////////////////////////

EA1_Read_B:
  LDW    EA1J             // Load jump table index
  JUMP   $0730(T)         // Call sub-routine

EA1_RB_An:
  CALL   Get_An_EA1
  LDB    (EA1) RTS

EA1_RB_An_Inc:
  CALL   Get_An_EA1
  LDB    (EA1)+
  JUMP   Set_An_EA1

EA1_RB_d16_An:
  CALL   Calc_d16_An_EA1
  LDB    (EA1) RTS

EA1_RB_AbsW:
  CALL   Calc_AbsW_EA1
  LDB    (EA1) RTS

EA1_RB_AbsL:
  CALL   Calc_AbsL_EA1
  LDB    (EA1) RTS

EA1_RB_d16_PC:
  CALL   Calc_d16_PC_EA1
  LDB    (EA1) RTS

EA1_RB_d8_PC_Rn:
  CALL   Calc_d8_PC_Rn_EA1
  LDB    (EA1) RTS

////////////////////////////////////
// Effective Address #1 read WORD //
////////////////////////////////////

EA1_Read_W:
  LDW    EA1J             // Load jump table index
  JUMP   $0740(T)         // Call sub-routine

EA1_RW_An:
  CALL   Get_An_EA1
  LDW    (EA1) RTS

EA1_RW_An_Inc:
  CALL   Get_An_EA1
  LDW    (EA1)+
  JUMP   Set_An_EA1

EA1_RW_d16_An:
  CALL   Calc_d16_An_EA1
  LDW    (EA1) RTS

EA1_RW_AbsW:
  CALL   Calc_AbsW_EA1
  LDW    (EA1) RTS

EA1_RW_AbsL:
  CALL   Calc_AbsL_EA1
  LDW    (EA1) RTS

EA1_RW_d16_PC:
  CALL   Calc_d16_PC_EA1
  LDW    (EA1) RTS

EA1_RW_d8_PC_Rn:
  CALL   Calc_d8_PC_Rn_EA1
  LDW    (EA1) RTS

////////////////////////////////////
// Effective Address #1 read LONG //
////////////////////////////////////

EA1_Read_L:
  LDW    EA1J             // Load jump table index
  JUMP   $0750(T)         // Call sub-routine

EA1_RL_Reg:
  LDW    RH[EA1]
  LDW    RL[EA1] RTS      // Read Dn.L or An.L

EA1_RL_An:
  CALL   Get_An_EA1
  JUMP   EA1_RL

EA1_RL_An_Inc:
  CALL   Get_An_EA1
  LDW    (EA1)+           // Read high word
  LDW    (EA1)+           // Read low word
  JUMP   Set_An_EA1

EA1_RL_An_Dec:
  CALL   Get_An_EA1
  LDW    -(EA1)           // Read low word
  LDW    -(EA1)           // Read high word
  SWAP
  JUMP   Set_An_EA1

EA1_RL_d16_An:
  CALL   Calc_d16_An_EA1
  JUMP   EA1_RL

EA1_RL_AbsW:
  CALL   Calc_AbsW_EA1
  JUMP   EA1_RL

EA1_RL_AbsL:
  CALL   Calc_AbsL_EA1
  JUMP   EA1_RL

EA1_RL_d16_PC:
  CALL   Calc_d16_PC_EA1
  JUMP   EA1_RL

EA1_RL_d8_PC_Rn:
  CALL   Calc_d8_PC_Rn_EA1
  JUMP   EA1_RL

EA1_RL_to_TMP1:
  LDW    (PC)+
  STW    TMP1H
  LDW    (PC)+
  STW    TMP1L
  CALL   EA1_Read_L
  LDW    TMP1L RTS

//////////////////////////////////////
// Effective Address #1 calculation //
//////////////////////////////////////
EA1_Calc:
  LDW    EA1J             // Load jump table index
  JUMP   $0760(T)         // Call sub-routine

//////////////////////////////////////
// Effective Address #1 update BYTE //
//////////////////////////////////////

EA1_Update_B:
  JUMP   EA1_7,EA1_WB_Reg
  JUMP   EA1_4,EA1_UpdB_An
  STB    (EA2) RTS
EA1_UpdB_An:
  STB    (EA1)+ RTS  // TODO : -(A7) case !!!

//////////////////////////////////////
// Effective Address #1 update WORD //
//////////////////////////////////////

EA1_Update_W:
  JUMP   EA1_7,EA1_WW_Reg
  JUMP   EA1_4,EA1_UpdW_An
  STW    (EA2) RTS
EA1_UpdW_An:
  STW    (EA1) RTS

//////////////////////////////////////
// Effective Address #1 update LONG //
//////////////////////////////////////

EA1_Update_L:
  JUMP   EA1_7,EA1_WL_Reg
  JUMP   EA1_4,EA1_WL
  JUMP   EA2_WL

/////////////////////////////////////
// Effective Address #1 write BYTE //
/////////////////////////////////////

EA1_Write_B:
  LDW    EA1J             // Load jump table index
  JUMP   $0770(T)         // Call sub-routine

EA1_WB_An:
  CALL   Get_An_EA1
  STB    (EA1) RTS

EA1_WB_An_Inc:
  CALL   Get_An_EA1
  STB    (EA1)+
  JUMP   Set_An_EA1

EA1_WB_d16_An:
  CALL   Calc_d16_An_EA1
  STB    (EA1) RTS


/////////////////////////////////////
// Effective Address #1 write WORD //
/////////////////////////////////////

EA1_Write_W:
  LDW    EA1J             // Load jump table index
  JUMP   $0780(T)         // Call sub-routine

EA1_WW_An:
  CALL   Get_An_EA1
  STW    (EA1) RTS

EA1_WW_An_Inc:
  CALL   Get_An_EA1
  STW    (EA1)+
  JUMP   Set_An_EA1

EA1_WW_d16_An:
  CALL   Calc_d16_An_EA1
  STW    (EA1) RTS

/////////////////////////////////////
// Effective Address #1 write LONG //
/////////////////////////////////////

EA1_Write_L:
  LDW    EA1J             // Load jump table index
  JUMP   $0790(T)         // Call sub-routine

EA1_WL_Reg:
  STW    RH[EA1]
  STW    RL[EA1] RTS      // Write Dn.L or An.L

EA1_WL_An:
  CALL   Get_An_EA1
  JUMP   EA1_WL

EA1_WL_An_Inc:
  CALL   Get_An_EA1
  STW    (EA1)+           // Write high word
  STW    (EA1)+           // Write low word
  JUMP   Set_An_EA1

EA1_WL_An_Dec:
  CALL   Get_An_EA1
  SWAP
  STW    -(EA1)           // Write low word
  STW    -(EA1)           // Write high word
  JUMP   Set_An_EA1

///////////////////////////////
// Effective Address #2 read //
///////////////////////////////

EA2_RB_An_Inc:
  CALL   Get_An_EA2
  LDB    (EA2)+
  JUMP   Set_An_EA2

EA2_RB_An_Dec:
  CALL   Get_An_EA2
  LDB    -(EA2)
  JUMP   Set_An_EA2

EA2_RW_An_Inc:
  CALL   Get_An_EA2
  LDW    (EA2)+
  JUMP   Set_An_EA2

EA2_RW_An_Dec:
  CALL   Get_An_EA2
  LDW    -(EA2)
  JUMP   Set_An_EA2

/////////////////////////////////////
// Effective Address #2 write BYTE //
/////////////////////////////////////

EA2_Write_B:
  LDW    EA2J             // Load jump table index
  JUMP   $07A0(T)         // Call sub-routine

EA2_WB_An:
  CALL   Get_An_EA2
  STB    (EA2) RTS

EA2_WB_An_Inc:
  CALL   Get_An_EA2
  STB    (EA2)+
  JUMP   Set_An_EA2

EA2_WB_d16_An:
  CALL   Calc_d16_An_EA2
  STB    (EA2) RTS


/////////////////////////////////////
// Effective Address #2 write WORD //
/////////////////////////////////////

EA2_Write_W:
  LDW    EA2J                  // Load jump table index
  JUMP   $07B0(T)              // Call sub-routine

EA2_WW_AReg:
  FLAG   -----,CIN=T15         // Carry in is bit #15 (sign)
  STW    AL[EA2]               // Write An LSW
  EXTW                         // Extend word to long
  STW    AH[EA2] RTS           // Write An MSW

EA2_WW_An:
  CALL   Get_An_EA2
  STW    (EA2) RTS

EA2_WW_An_Inc:
  CALL   Get_An_EA2
  STW    (EA2)+
  JUMP   Set_An_EA2

EA2_WW_d16_An:
  CALL   Calc_d16_An_EA2
  STW    (EA2) RTS


/////////////////////////////////////
// Effective Address #2 write LONG //
/////////////////////////////////////

EA2_Write_L:
  LDW    EA2J             // Load jump table index
  JUMP   $07C0(T)         // Call sub-routine

EA2_WL_Reg:
  STW    RH[EA2]
  STW    RL[EA2] RTS      // Write Dn.l or An.l

EA2_WL_An:
  CALL   Get_An_EA2
  JUMP   EA2_WL

EA2_WL_An_Inc:
  CALL   Get_An_EA2
  STW    (EA2)+           // Write high word
  STW    (EA2)+           // Write low word
  JUMP   Set_An_EA2

EA2_WL_An_Dec:
  CALL   Get_An_EA2
  SWAP
  STW    -(EA2)           // Write low word
  STW    -(EA2)           // Write high word
  JUMP   Set_An_EA2

///////////////////////
// Utility functions //
///////////////////////

AddOffs:
  LDW    IMMR                  // Read word offset
AddVal:
  FLAG   -----,CIN=T15         // Carry in is bit #15 (sign)
  ADDW.                        // Add low words
  SWAP                         // Swap high/low words
  EXTW                         // Extend word offset to long
  FLAG   -----,CIN=C_ADD       // Carry in is adder carry
  ADDCL  RTS                   // Add high words

Add_Ext_Rn:
  LDW    RL[EXT]               // Read Rn low
  FLAG   -----,CIN=T15         // Carry in is bit #15 (sign)
  ADDW.                        // Add low words
  SWAP                         // Swap low/high words
  JUMP   EXT_11,LongRn         // Long index case : skip the next 2 instructions
  EXTW
  FLAG   -----,CIN=C_ADD       // Carry in is carry out
  ADDCL  RTS                   // Add high words
LongRn:
  LDW    RH[EXT]               // Read Rn high
  FLAG   -----,CIN=C_ADD       // Carry in is carry out
  ADDCL  RTS                   // Add high words

PC_SR_to_Stack:
  CALL   SP_to_EA2             // A7 -> EA2
  LDW    PCL
  STW    -(EA2)                // PC low -> -(EA2)
  LDW    PCH
  STW    -(EA2)                // PC high -> -(EA2)
  LDW    SR
  STW    -(EA2)                // SR -> -(EA2)
  JUMP   EA2_to_SP             // EA2 -> SP
    
PC_to_Stack:
  CALL   SP_to_EA2             // A7 -> EA2
  LDW    PCL
  STW    -(EA2)                // PC low -> -(EA2)
  LDW    PCH
  STW    -(EA2)                // PC high -> -(EA2)

EA2_to_SP:
  LDW    EA2H
  STW    A7H                   // EA2 high -> A7 high
  LDW    EA2L
  STW    A7L RTS               // EA2 low -> A7 low

SP_to_EA2:
  LDW    A7H
  STW    EA2H                  // A7 high -> EA2 high
  LDW    A7L
  STW    EA2L RTS              // A7 low -> EA2 low

A7_to_USP:
  LDW    A7H
  STW    USPH                  // A7 high -> USP high
  LDW    A7L
  STW    USPL RTS              // A7 low -> USP low

A7_to_SSP:
  LDW    A7H
  STW    SSPH                  // A7 high -> SSP high
  LDW    A7L
  STW    SSPL RTS              // A7 low -> SSP low

Enter_Super:
  JUMP   S_SR,A7_to_SSP        // S bit set : update SSP
  CALL   A7_to_USP             // S bit clear : update USP

SSP_to_A7:
  LDW    SSPH
  STW    A7H                   // SSP high -> A7 high
  LDW    SSPL
  STW    A7L RTS               // SSP low -> A7 low

USP_to_A7:
  LDW    USPH
  STW    A7H                   // USP high -> A7 high
  LDW    USPL
  STW    A7L RTS               // USP low -> A7 low

Leave_Super:
  CALL   A7_to_SSP             // Update SSP
  JUMPN  S_SR,USP_to_A7        // S bit clear : update A7 with USP
  NOP    RTS                   // S bit set : keep A7

SR_Super:
  LDW    SR                    // Read SR
  LIT    #$7FFF
  ANDW                         // Clear trace bit
  LIT    #$2000
  ORW    RTS                   // Set supervisor bit

Resume_Exec:
  STW    SR                    // Initialize SR
  LDW    (VEC)+                // Load PC high word from memory
  STW    PCH                   // into PC MSW
  LDW    (VEC)+                // Load PC low word from memory
  STW    PCL                   // into PC LSW
  LIT    #$0060
  STW    VECL RTS              // Allow interrupts, clear address error

////////////////////////////////////
// Effective address #1 functions //
////////////////////////////////////

Add_Offs_An_EA1:
  LDW    AH[EA1]          // Read An high
  LDW    AL[EA1]          // Read An low
  JUMP   AddOffs

Get_An_EA1:
  LDW    AL[EA1]          // Read An low
  STW    EA1L
  LDW    AH[EA1]          // Read An high
  STW    EA1H RTS

Set_An_EA1:
  LDW    EA1L
  STW    AL[EA1]          // Write An low
  LDW    EA1H
  STW    AH[EA1] RTS      // Write An high

Calc_d16_An_EA1:
  FTW    (PC)+            // Fetch 16-bit displacement
  CALL   Add_Offs_An_EA1  // Add 16-bit displacement to An
  STW    EA1H             // Store result in EA1H
  STW    EA1L RTS         // Store result in EA1L

Calc_d8_An_Rn_EA1:
  FTE    (PC)+            // Fetch 16-bit extension word
  CALL   Add_Offs_An_EA1  // Add 8-bit displacement to An
  SWAP                    // Swap low/high words
  CALL   Add_Ext_Rn       // Add Rn to An
  STW    EA1H             // Store result in EA1H
  STW    EA1L RTS         // Store result in EA1L

Calc_AbsW_EA1:
  LDW    (PC)+                 // Read 16-bit address
  FLAG   -----,CIN=T15         // Carry in is bit #15 (sign)
  EXTW                         // Extend word to long
  STW    EA1H                  // Store result in EA1H
  STW    EA1L RTS              // Store result in EA1L

Calc_AbsL_EA1:
  LDW    (PC)+                 // Read MSW of 32-bit address
  STW    EA1H                  // Store result in EA1H
  LDW    (PC)+                 // Read LSW of 32-bit address
  STW    EA1L RTS              // Store result in EA1L

Calc_d16_PC_EA1:
  LDW    PCH              // Load PC high word
  LDW    PCL              // Load PC low word
  FTW    (PC)+            // Fetch 16-bit displacement
  CALL   AddOffs          // Add displacement to PC
  STW    EA1H             // Store result in EA1H
  STW    EA1L RTS         // Store result in EA1L

Calc_d8_PC_Rn_EA1:
  LDW    PCH              // Load PC high word
  LDW    PCL              // Load PC low word
  FTE    (PC)+            // Fetch 16-bit extension word
  CALL   AddOffs          // Add displacement to PC
  SWAP                    // Swap low/high words
  CALL   Add_Ext_Rn       // Add Rn to An
  STW    EA1H             // Store result in EA1H
  STW    EA1L RTS         // Store result in EA1L

////////////////////////////////////
// Effective address #2 functions //
////////////////////////////////////

Add_Offs_An_EA2:
  LDW    AH[EA2]               // Read An high
  LDW    AL[EA2]               // Read An low
  JUMP   AddOffs               // Add offset to An

Get_An_EA2:
  LDW    AL[EA2]               // Read An low
  STW    EA2L                  // Store result in EA2L
  LDW    AH[EA2]               // Read An high
  STW    EA2H RTS              // Store result in EA2H

Set_An_EA2:
  LDW    EA2L                  // Read address from EA2L
  STW    AL[EA2]               // Write An low
  LDW    EA2H                  // Read address from EA2H
  STW    AH[EA2] RTS           // Write An high

Calc_AbsW_EA2:
  LDW    (PC)+                 // Read 16-bit address
  FLAG   -----,CIN=T15         // Carry in is bit #15 (sign)
  EXTW                         // Extend word to long
  STW    EA2H                  // Store result in EA2H
  STW    EA2L RTS              // Store result in EA2L

Calc_AbsL_EA2:
  LDW    (PC)+                 // Read MSW of 32-bit address
  STW    EA2H                  // Store result in EA2H
  LDW    (PC)+                 // Read LSW of 32-bit address
  STW    EA2L RTS              // Store result in EA2L

Calc_d16_An_EA2:
  FTW    (PC)+            // Fetch 16-bit displacement
  CALL   Add_Offs_An_EA2  // Add 16-bit displacement to An
  STW    EA2H             // Store result in EA2H
  STW    EA2L RTS         // Store result in EA2L

Calc_d8_An_Rn_EA2:
  FTE    (PC)+            // Fetch 16-bit extension word
  CALL   Add_Offs_An_EA2  // Add 8-bit displacement to An
  SWAP                    // Swap low/high words
  CALL   Add_Ext_Rn       // Add Rn to An
  STW    EA2H             // Store result in EA2H
  STW    EA2L RTS         // Store result in EA2L

Calc_d16_PC_EA2:
  LDW    PCH              // Load PC high word
  LDW    PCL              // Load PC low word
  FTW    (PC)+            // Fetch 16-bit displacement
  CALL   AddOffs          // Add displacement to PC
  STW    EA2H             // Store result in EA2H
  STW    EA2L RTS         // Store result in EA2L

Calc_d8_PC_Rn_EA2:
  LDW    PCH              // Load PC high word
  LDW    PCL              // Load PC low word
  FTE    (PC)+            // Fetch 16-bit extension word
  CALL   AddOffs          // Add displacement to PC
  SWAP                    // Swap low/high words
  CALL   Add_Ext_Rn       // Add Rn to An
  STW    EA2H             // Store result in EA2H
  STW    EA2L RTS         // Store result in EA2L

  ORG    $0730
  //
  // $FF30 : EA1 read BYTE
  //
  LDB    RL[EA1] RTS       // Dx
  JUMP   $0000             // Unused
  JUMP   EA1_RB_An         // (Ax)
  JUMP   EA1_RB_An_Inc     // (Ax)+
  JUMP   EA1_RB_An_Dec     // -(Ax)
  JUMP   EA1_RB_d16_An     // d16(Ax)
  CALL   Calc_d8_An_Rn_EA1 // d8(Ax,Rx)
  LDB    (EA1) RTS         // Unused
  JUMP   EA1_RB_AbsW       // XXXX.w
  JUMP   EA1_RB_AbsL       // XXXXXXXX.l
  JUMP   EA1_RB_d16_PC     // d16(PC)
  JUMP   EA1_RB_d8_PC_Rn   // d8(PC,Rx)
  LDW    (PC)+ RTS         // #XX
EA1_RB_An_Dec:
  CALL   Get_An_EA1        // Unused
  LDB    -(EA1)            // Unused
  JUMP   Set_An_EA1        // Unused

  //
  // $FF40 : EA1 read WORD
  //
  LDW    RL[EA1] RTS       // Dx
  LDW    RL[EA1] RTS       // Ax
  JUMP   EA1_RW_An         // (Ax)
  JUMP   EA1_RW_An_Inc     // (Ax)+
  JUMP   EA1_RW_An_Dec     // -(Ax)
  JUMP   EA1_RW_d16_An     // d16(Ax)
  CALL   Calc_d8_An_Rn_EA1 // d8(Ax,Rx)
  LDW    (EA1) RTS         // Unused
  JUMP   EA1_RW_AbsW       // XXXX.w
  JUMP   EA1_RW_AbsL       // XXXXXXXX.l
  JUMP   EA1_RW_d16_PC     // d16(PC)
  JUMP   EA1_RW_d8_PC_Rn   // d8(PC,Rx)
  LDW    (PC)+ RTS         // #XXXX
EA1_RW_An_Dec:
  CALL   Get_An_EA1        // Unused
  LDW    -(EA1)            // Unused
  JUMP   Set_An_EA1        // Unused

  //
  // $FF50 : EA1 read LONG
  //
  JUMP   EA1_RL_Reg        // Dx
  JUMP   EA1_RL_Reg        // Ax
  JUMP   EA1_RL_An         // (Ax)
  JUMP   EA1_RL_An_Inc     // (Ax)+
  JUMP   EA1_RL_An_Dec     // -(Ax)
  JUMP   EA1_RL_d16_An     // d16(Ax)
  CALL   Calc_d8_An_Rn_EA1 // d8(Ax,Rx)
  JUMP   EA1_RL            // Unused
  JUMP   EA1_RL_AbsW       // XXXX.w
  JUMP   EA1_RL_AbsL       // XXXXXXXX.l
  JUMP   EA1_RL_d16_PC     // d16(PC)
  JUMP   EA1_RL_d8_PC_Rn   // d8(PC,Rx)
  LDW    (PC)+             // #XXXXXXXX
  LDW    (PC)+ RTS         // Unused
EA1_RL:
  LDW    (EA1)+            // Unused
  LDW    (EA1) RTS         // Unused

  //
  // $FF60 : EA1 calculation
  //
  JUMP   $0000             // Unused
  JUMP   $0000             // Unused
  JUMP   Get_An_EA1        // (Ax)
  JUMP   Get_An_EA1        // (Ax)+
  JUMP   Get_An_EA1        // -(Ax)
  JUMP   Calc_d16_An_EA1   // d16(Ax)
  JUMP   Calc_d8_An_Rn_EA1 // d8(Ax,Rx)
  JUMP   $0000             // Unused
  JUMP   Calc_AbsW_EA1     // XXXX.w
  JUMP   Calc_AbsL_EA1     // XXXXXXXX.l
  JUMP   Calc_d16_PC_EA1   // d16(PC)
  JUMP   Calc_d8_PC_Rn_EA1 // d8(PC,Rx)
  JUMP   $0000             // Unused
  JUMP   $0000             // Unused
  JUMP   $0000             // Unused
  JUMP   $0000             // Unused
  //
  // $FF70 : EA1 write BYTE
  //
EA1_WB_Reg:
  STB    RL[EA1] RTS       // Dx
  JUMP   $0000             // Unused
  JUMP   EA1_WB_An         // (Ax)
  JUMP   EA1_WB_An_Inc     // (Ax)+
  JUMP   EA1_WB_An_Dec     // -(Ax)
  JUMP   EA1_WB_d16_An     // d16(Ax)
  CALL   Calc_d8_An_Rn_EA1 // d8(Ax,Rx)
  STB    (EA1) RTS         // Unused
  JUMP   EA1_WB_AbsW       // XXXX.w
  CALL   Calc_AbsL_EA1     // XXXXXXXX.l
  STB    (EA1) RTS         // Unused
EA1_WB_AbsW:
  CALL   Calc_AbsW_EA1     // Unused
  STB    (EA1) RTS         // Unused
EA1_WB_An_Dec:
  CALL   Get_An_EA1        // Unused
  STB    -(EA1)            // Unused
  JUMP   Set_An_EA1        // Unused

  //
  // $FF80 : EA1 write WORD
  //
EA1_WW_Reg:
  STW    RL[EA1] RTS       // Dx
  JUMP   $0000             // Unused
  JUMP   EA1_WW_An         // (Ax)
  JUMP   EA1_WW_An_Inc     // (Ax)+
  JUMP   EA1_WW_An_Dec     // -(Ax)
  JUMP   EA1_WW_d16_An     // d16(Ax)
  CALL   Calc_d8_An_Rn_EA1 // d8(Ax,Rx)
  STW    (EA1) RTS         // Unused
  JUMP   EA1_WW_AbsW       // XXXX.w
  CALL   Calc_AbsL_EA1     // XXXXXXXX.l
  STW    (EA1) RTS         // Unused
EA1_WW_AbsW:
  CALL   Calc_AbsW_EA1     // Unused
  STW    (EA1) RTS         // Unused
EA1_WW_An_Dec:
  CALL   Get_An_EA1        // Unused
  STW    -(EA1)            // Unused
  JUMP   Set_An_EA1        // Unused

  //
  // $FF90 : EA1 write LONG
  //
  JUMP   EA1_WL_Reg        // Dx
  JUMP   EA1_WL_Reg        // Ax
  JUMP   EA1_WL_An         // (Ax)
  JUMP   EA1_WL_An_Inc     // (Ax)+
  JUMP   EA1_WL_An_Dec     // -(Ax)
  JUMP   EA1_WL_d16_An     // d16(Ax)
  CALL   Calc_d8_An_Rn_EA1 // d8(Ax,Rx)
  JUMP   EA1_WL            // Unused
  JUMP   EA1_WL_AbsW       // XXXX.w
  CALL   Calc_AbsL_EA1     // XXXXXXXX.l
EA1_WL:
  STW    (EA1)+            // Unused
  STW    (EA1) RTS         // Unused
EA1_WL_d16_An:
  CALL   Calc_d16_An_EA1   // Unused
  JUMP   EA1_WL            // Unused
EA1_WL_AbsW:
  CALL   Calc_AbsW_EA1     // Unused
  JUMP   EA1_WL            // Unused

  //
  // $FFA0 : EA2 write BYTE
  //
  STB    DL[EA2] RTS       // Dx
  JUMP   $0000             // Unused
  JUMP   EA2_WB_An         // (Ax)
  JUMP   EA2_WB_An_Inc     // (Ax)+
  JUMP   EA2_WB_An_Dec     // -(Ax)
  JUMP   EA2_WB_d16_An     // d16(Ax)
  CALL   Calc_d8_An_Rn_EA2 // d8(Ax,Rx)
  STB    (EA2) RTS         // Unused
  JUMP   EA2_WB_AbsW       // XXXX.w
  CALL   Calc_AbsL_EA2     // XXXXXXXX.l
  STB    (EA2) RTS         // Unused
EA2_WB_AbsW:
  CALL   Calc_AbsW_EA2     // Unused
  STB    (EA2) RTS         // Unused
EA2_WB_An_Dec:
  CALL   Get_An_EA2        // Unused
  STB    -(EA2)            // Unused
  JUMP   Set_An_EA2        // Unused

  //
  // $FFB0 : EA2 write WORD
  //
  STW    RL[EA2] RTS       // Dx
  JUMP   EA2_WW_AReg       // Ax
  JUMP   EA2_WW_An         // (Ax)
  JUMP   EA2_WW_An_Inc     // (Ax)+
  JUMP   EA2_WW_An_Dec     // -(Ax)
  JUMP   EA2_WW_d16_An     // d16(Ax)
  CALL   Calc_d8_An_Rn_EA2 // d8(Ax,Rx)
  STW    (EA2) RTS         // Unused
  JUMP   EA2_WW_AbsW       // XXXX.w
  CALL   Calc_AbsL_EA2     // XXXXXXXX.l
  STW    (EA2) RTS         // Unused
EA2_WW_AbsW:
  CALL   Calc_AbsW_EA2     // Unused
  STW    (EA2) RTS         // Unused
EA2_WW_An_Dec:
  CALL   Get_An_EA2        // Unused
  STW    -(EA2)            // Unused
  JUMP   Set_An_EA2        // Unused
  
  //
  // $FFC0 : EA2 write LONG
  //
  JUMP   EA2_WL_Reg        // Dx
  JUMP   EA2_WL_Reg        // Ax
  JUMP   EA2_WL_An         // (Ax)
  JUMP   EA2_WL_An_Inc     // (Ax)+
  JUMP   EA2_WL_An_Dec     // -(Ax)
  JUMP   EA2_WL_d16_An     // d16(Ax)
  CALL   Calc_d8_An_Rn_EA2 // d8(Ax,Rx)
  JUMP   EA2_WL            // Unused
  JUMP   EA2_WL_AbsW       // XXXX.w
  CALL   Calc_AbsL_EA2     // XXXXXXXX.l
EA2_WL:
  STW    (EA2)+            // Unused
  STW    (EA2) RTS         // Unused
EA2_WL_d16_An:
  CALL   Calc_d16_An_EA2   // Unused
  JUMP   EA2_WL            // Unused
EA2_WL_AbsW:
  CALL   Calc_AbsW_EA2     // Unused
  JUMP   EA2_WL            // Unused

  NOP
  NOP
  NOP
  NOP
  NOP
  NOP

  //
  // $FFD6 : Miscellaneous regiters
  //
  LIT    #$0000                // VBR LSW
  LIT    #$0000                // VBR MSW
  LIT    #$0000                // TMP1 LSW
  LIT    #$0000                // TMP1 MSW
  LIT    #$0000                // TMP2 LSW
  LIT    #$0000                // TMP2 MSW
  LIT    #$0000                // USP LSW
  LIT    #$0000                // USP MSW
  LIT    #$0000                // SSP LSW
  LIT    #$0000                // SSP MSW
  //
  // $FFE0 : Data regiters
  //
  LIT    #$0000                // D0 LSW
  LIT    #$0000                // D0 MSW
  LIT    #$0000                // D1 LSW
  LIT    #$0000                // D1 MSW
  LIT    #$0000                // D2 LSW
  LIT    #$0000                // D2 MSW
  LIT    #$0000                // D3 LSW
  LIT    #$0000                // D3 MSW
  LIT    #$0000                // D4 LSW
  LIT    #$0000                // D4 MSW
  LIT    #$0000                // D5 LSW
  LIT    #$0000                // D5 MSW
  LIT    #$0000                // D6 LSW
  LIT    #$0000                // D6 MSW
  LIT    #$0000                // D7 LSW
  LIT    #$0000                // D7 MSW
  //
  // $FFF0 : Address regiters
  //
  LIT    #$0000                // A0 LSW
  LIT    #$0000                // A0 MSW
  LIT    #$0000                // A1 LSW
  LIT    #$0000                // A1 MSW
  LIT    #$0000                // A2 LSW
  LIT    #$0000                // A2 MSW
  LIT    #$0000                // A3 LSW
  LIT    #$0000                // A3 MSW
  LIT    #$0000                // A4 LSW
  LIT    #$0000                // A4 MSW
  LIT    #$0000                // A5 LSW
  LIT    #$0000                // A5 MSW
  LIT    #$0000                // A6 LSW
  LIT    #$0000                // A6 MSW
  LIT    #$0000                // A7 LSW
  LIT    #$0000                // A7 MSW

  // 0 - 63 : Miscellaneous instructions (group #4)
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_TRAP,      Op_TRAP,      Op_TRAP,       $7FFF
  TABLE  Op_LINK,      Op_LINK,      Op_LINK,       $7FFF
  TABLE  Op_LINK,      Op_LINK,      Op_LINK,       $7FFF
  TABLE  Op_LINK,      Op_LINK,      Op_LINK,       $7FFF
  TABLE  Op_LINK,      Op_LINK,      Op_LINK,       $7FFF
  TABLE  Op_LINK,      Op_LINK,      Op_LINK,       $7FFF
  TABLE  Op_LINK,      Op_LINK,      Op_LINK,       $7FFF
  TABLE  Op_LINK,      Op_LINK,      Op_LINK,       $7FFF
  TABLE  Op_LINK,      Op_LINK,      Op_LINK,       $7FFF
  TABLE  Op_UNLK,      Op_UNLK,      Op_UNLK,       $7FFF
  TABLE  Op_UNLK,      Op_UNLK,      Op_UNLK,       $7FFF
  TABLE  Op_UNLK,      Op_UNLK,      Op_UNLK,       $7FFF
  TABLE  Op_UNLK,      Op_UNLK,      Op_UNLK,       $7FFF
  TABLE  Op_UNLK,      Op_UNLK,      Op_UNLK,       $7FFF
  TABLE  Op_UNLK,      Op_UNLK,      Op_UNLK,       $7FFF
  TABLE  Op_UNLK,      Op_UNLK,      Op_UNLK,       $7FFF
  TABLE  Op_UNLK,      Op_UNLK,      Op_UNLK,       $7FFF
  TABLE  Op_MOVEtUSP,  Op_MOVEtUSP,  Op_MOVEtUSP,   $7FFF
  TABLE  Op_MOVEtUSP,  Op_MOVEtUSP,  Op_MOVEtUSP,   $7FFF
  TABLE  Op_MOVEtUSP,  Op_MOVEtUSP,  Op_MOVEtUSP,   $7FFF
  TABLE  Op_MOVEtUSP,  Op_MOVEtUSP,  Op_MOVEtUSP,   $7FFF
  TABLE  Op_MOVEtUSP,  Op_MOVEtUSP,  Op_MOVEtUSP,   $7FFF
  TABLE  Op_MOVEtUSP,  Op_MOVEtUSP,  Op_MOVEtUSP,   $7FFF
  TABLE  Op_MOVEtUSP,  Op_MOVEtUSP,  Op_MOVEtUSP,   $7FFF
  TABLE  Op_MOVEtUSP,  Op_MOVEtUSP,  Op_MOVEtUSP,   $7FFF
  TABLE  Op_MOVEfUSP,  Op_MOVEfUSP,  Op_MOVEfUSP,   $7FFF
  TABLE  Op_MOVEfUSP,  Op_MOVEfUSP,  Op_MOVEfUSP,   $7FFF
  TABLE  Op_MOVEfUSP,  Op_MOVEfUSP,  Op_MOVEfUSP,   $7FFF
  TABLE  Op_MOVEfUSP,  Op_MOVEfUSP,  Op_MOVEfUSP,   $7FFF
  TABLE  Op_MOVEfUSP,  Op_MOVEfUSP,  Op_MOVEfUSP,   $7FFF
  TABLE  Op_MOVEfUSP,  Op_MOVEfUSP,  Op_MOVEfUSP,   $7FFF
  TABLE  Op_MOVEfUSP,  Op_MOVEfUSP,  Op_MOVEfUSP,   $7FFF
  TABLE  Op_MOVEfUSP,  Op_MOVEfUSP,  Op_MOVEfUSP,   $7FFF
  TABLE  Op_RESET,     Op_RESET,     Op_RESET,      $7FFF
  TABLE  Op_NOP,       Op_NOP,       Op_NOP,        $7FFF
  TABLE  Op_STOP,      Op_STOP,      Op_STOP,       $7FFF
  TABLE  Op_RTE,       Op_RTE,       Op_RTE,        $7FFF
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Op_RTS,       Op_RTS,       Op_RTS,        $7FFF
  TABLE  Op_TRAPV,     Op_TRAPV,     Op_TRAPV,      $7FFF
  TABLE  Op_RTR,       Op_RTR,       Op_RTR,        $7FFF
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  // 64 - 95 : Immediate instructions (group #0)
  TABLE  Op_ORIB,      Op_ORIB,      Op_ORI_CCR,    $09FD
  TABLE  Op_ORIW,      Op_ORIW,      Op_ORI_SR,     $09FD
  TABLE  Op_ORIL,      Op_ORIL,      Op_ORIL,       $01FD
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Op_ANDIB,     Op_ANDIB,     Op_ANDI_CCR,   $09FD
  TABLE  Op_ANDIW,     Op_ANDIW,     Op_ANDI_SR,    $09FD
  TABLE  Op_ANDIL,     Op_ANDIL,     Op_ANDIL,      $01FD
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Op_SUBIB,     Op_SUBIB,     Op_SUBIB,      $01FD
  TABLE  Op_SUBIW,     Op_SUBIW,     Op_SUBIW,      $01FD
  TABLE  Op_SUBIL,     Op_SUBIL,     Op_SUBIL,      $01FD
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Op_ADDIB,     Op_ADDIB,     Op_ADDIB,      $01FD
  TABLE  Op_ADDIW,     Op_ADDIW,     Op_ADDIW,      $01FD
  TABLE  Op_ADDIL,     Op_ADDIL,     Op_ADDIL,      $01FD
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Op_BTSTB_i,   Op_BTSTL_i,   Op_BTSTL_i,    $07FD
  TABLE  Op_BCHGB_i,   Op_BCHGL_i,   Op_BCHGL_i,    $01FD
  TABLE  Op_BCLRB_i,   Op_BCLRL_i,   Op_BCLRL_i,    $01FD
  TABLE  Op_BSETB_i,   Op_BSETL_i,   Op_BSETL_i,    $01FD
  TABLE  Op_EORIB,     Op_EORIB,     Op_EORI_CCR,   $09FD
  TABLE  Op_EORIW,     Op_EORIW,     Op_EORI_SR,    $09FD
  TABLE  Op_EORIL,     Op_EORIL,     Op_EORIL,      $01FD
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Op_CMPIB,     Op_CMPIB,     Op_CMPIB,      $01FD
  TABLE  Op_CMPIW,     Op_CMPIW,     Op_CMPIW,      $01FD
  TABLE  Op_CMPIL,     Op_CMPIL,     Op_CMPIL,      $01FD
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  // 96 - 127 : One operand instructions (group #4)
  TABLE  Op_NEGXB,     Op_NEGXB,     Op_NEGXB,      $01FD
  TABLE  Op_NEGXW,     Op_NEGXW,     Op_NEGXW,      $01FD
  TABLE  Op_NEGXL,     Op_NEGXL,     Op_NEGXL,      $01FD
  TABLE  Op_MOVEfSR,   Op_MOVEfSR,   Op_MOVEfSR,    $01FD
  TABLE  Op_CLRB,      Op_CLRB,      Op_CLRB,       $01FD
  TABLE  Op_CLRW,      Op_CLRW,      Op_CLRW,       $01FD
  TABLE  Op_CLRL,      Op_CLRL,      Op_CLRL,       $01FD
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Op_NEGB,      Op_NEGB,      Op_NEGB,       $01FD
  TABLE  Op_NEGW,      Op_NEGW,      Op_NEGW,       $01FD
  TABLE  Op_NEGL,      Op_NEGL,      Op_NEGL,       $01FD
  TABLE  Op_MOVEtCCR,  Op_MOVEtCCR,  Op_MOVEtCCR,   $0FFD
  TABLE  Op_NOTB,      Op_NOTB,      Op_NOTB,       $01FD
  TABLE  Op_NOTW,      Op_NOTW,      Op_NOTW,       $01FD
  TABLE  Op_NOTL,      Op_NOTL,      Op_NOTL,       $01FD
  TABLE  Op_MOVEtSR,   Op_MOVEtSR,   Op_MOVEtSR,    $0FFD
  TABLE  Op_NBCD,      Op_NBCD,      Op_NBCD,       $01FD
  TABLE  Op_PEA,       Op_SWAP,      Op_PEA,        $07E5
  TABLE  Op_MOVEMW_m,  Op_EXTW,      Op_MOVEMW_mpd, $01F5
  TABLE  Op_MOVEML_m,  Op_EXTL,      Op_MOVEML_mpd, $01F5
  TABLE  Op_TSTB,      Op_TSTB,      Op_TSTB,       $01FD
  TABLE  Op_TSTW,      Op_TSTW,      Op_TSTW,       $01FD
  TABLE  Op_TSTL,      Op_TSTL,      Op_TSTL,       $01FD
  TABLE  Op_TASB,      Op_TASB,      Op_TASB,       $01FD
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Op_MOVEMW_r,  Op_MOVEMW_r,  Op_MOVEMW_rpi, $07EC
  TABLE  Op_MOVEML_r,  Op_MOVEML_r,  Op_MOVEML_rpi, $07EC
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Op_JSR,       Op_JSR,       Op_JSR,        $07E4
  TABLE  Op_JMP,       Op_JMP,       Op_JMP,        $07E4
  // 128 - 143 : Shift byte register (group #E)
  TABLE  Op_ASRB_ir,   Op_ASRB_ir,   Op_ASRB_ir,    $7FFF
  TABLE  Op_LSRB_ir,   Op_LSRB_ir,   Op_LSRB_ir,    $7FFF
  TABLE  Op_ROXRB_ir,  Op_ROXRB_ir,  Op_ROXRB_ir,   $7FFF
  TABLE  Op_RORB_ir,   Op_RORB_ir,   Op_RORB_ir,    $7FFF
  TABLE  Op_ASRB_rr,   Op_ASRB_rr,   Op_ASRB_rr,    $7FFF
  TABLE  Op_LSRB_rr,   Op_LSRB_rr,   Op_LSRB_rr,    $7FFF
  TABLE  Op_ROXRB_rr,  Op_ROXRB_rr,  Op_ROXRB_rr,   $7FFF
  TABLE  Op_RORB_rr,   Op_RORB_rr,   Op_RORB_rr,    $7FFF
  TABLE  Op_ASLB_ir,   Op_ASLB_ir,   Op_ASLB_ir,    $7FFF
  TABLE  Op_LSLB_ir,   Op_LSLB_ir,   Op_LSLB_ir,    $7FFF
  TABLE  Op_ROXLB_ir,  Op_ROXLB_ir,  Op_ROXLB_ir,   $7FFF
  TABLE  Op_ROLB_ir,   Op_ROLB_ir,   Op_ROLB_ir,    $7FFF
  TABLE  Op_ASLB_rr,   Op_ASLB_rr,   Op_ASLB_rr,    $7FFF
  TABLE  Op_LSLB_rr,   Op_LSLB_rr,   Op_LSLB_rr,    $7FFF
  TABLE  Op_ROXLB_rr,  Op_ROXLB_rr,  Op_ROXLB_rr,   $7FFF
  TABLE  Op_ROLB_rr,   Op_ROLB_rr,   Op_ROLB_rr,    $7FFF
  // 144 - 159 : Shift word register (group #E)
  TABLE  Op_ASRW_ir,   Op_ASRW_ir,   Op_ASRW_ir,    $7FFF
  TABLE  Op_LSRW_ir,   Op_LSRW_ir,   Op_LSRW_ir,    $7FFF
  TABLE  Op_ROXRW_ir,  Op_ROXRW_ir,  Op_ROXRW_ir,   $7FFF
  TABLE  Op_RORW_ir,   Op_RORW_ir,   Op_RORW_ir,    $7FFF
  TABLE  Op_ASRW_rr,   Op_ASRW_rr,   Op_ASRW_rr,    $7FFF
  TABLE  Op_LSRW_rr,   Op_LSRW_rr,   Op_LSRW_rr,    $7FFF
  TABLE  Op_ROXRW_rr,  Op_ROXRW_rr,  Op_ROXRW_rr,   $7FFF
  TABLE  Op_RORW_rr,   Op_RORW_rr,   Op_RORW_rr,    $7FFF
  TABLE  Op_ASLW_ir,   Op_ASLW_ir,   Op_ASLW_ir,    $7FFF
  TABLE  Op_LSLW_ir,   Op_LSLW_ir,   Op_LSLW_ir,    $7FFF
  TABLE  Op_ROXLW_ir,  Op_ROXLW_ir,  Op_ROXLW_ir,   $7FFF
  TABLE  Op_ROLW_ir,   Op_ROLW_ir,   Op_ROLW_ir,    $7FFF
  TABLE  Op_ASLW_rr,   Op_ASLW_rr,   Op_ASLW_rr,    $7FFF
  TABLE  Op_LSLW_rr,   Op_LSLW_rr,   Op_LSLW_rr,    $7FFF
  TABLE  Op_ROXLW_rr,  Op_ROXLW_rr,  Op_ROXLW_rr,   $7FFF
  TABLE  Op_ROLW_rr,   Op_ROLW_rr,   Op_ROLW_rr,    $7FFF
  // 160 - 175 : Shift long register (group #E)
  TABLE  Op_ASRL_ir,   Op_ASRL_ir,   Op_ASRL_ir,    $7FFF
  TABLE  Op_LSRL_ir,   Op_LSRL_ir,   Op_LSRL_ir,    $7FFF
  TABLE  Op_ROXRL_ir,  Op_ROXRL_ir,  Op_ROXRL_ir,   $7FFF
  TABLE  Op_RORL_ir,   Op_RORL_ir,   Op_RORL_ir,    $7FFF
  TABLE  Op_ASRL_rr,   Op_ASRL_rr,   Op_ASRL_rr,    $7FFF
  TABLE  Op_LSRL_rr,   Op_LSRL_rr,   Op_LSRL_rr,    $7FFF
  TABLE  Op_ROXRL_rr,  Op_ROXRL_rr,  Op_ROXRL_rr,   $7FFF
  TABLE  Op_RORL_rr,   Op_RORL_rr,   Op_RORL_rr,    $7FFF
  TABLE  Op_ASLL_ir,   Op_ASLL_ir,   Op_ASLL_ir,    $7FFF
  TABLE  Op_LSLL_ir,   Op_LSLL_ir,   Op_LSLL_ir,    $7FFF
  TABLE  Op_ROXLL_ir,  Op_ROXLL_ir,  Op_ROXLL_ir,   $7FFF
  TABLE  Op_ROLL_ir,   Op_ROLL_ir,   Op_ROLL_ir,    $7FFF
  TABLE  Op_ASLL_rr,   Op_ASLL_rr,   Op_ASLL_rr,    $7FFF
  TABLE  Op_LSLL_rr,   Op_LSLL_rr,   Op_LSLL_rr,    $7FFF
  TABLE  Op_ROXLL_rr,  Op_ROXLL_rr,  Op_ROXLL_rr,   $7FFF
  TABLE  Op_ROLL_rr,   Op_ROLL_rr,   Op_ROLL_rr,    $7FFF
  // 176 - 191 : Instruction groups
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Op_MOVEB,     Op_MOVEB,     Op_MOVEB,      $0FFD
  TABLE  Op_MOVEL,     Op_MOVEAL,    Op_MOVEL,      $0FFF
  TABLE  Op_MOVEW,     Op_MOVEAW,    Op_MOVEW,      $0FFF
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Op_Bcc,       Op_BSR,       Op_Bcc,        $7FFF
  TABLE  Op_MOVEQ,     Op_MOVEQ,     Op_MOVEQ,      $7FFF
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_LineA,   Trap_LineA,   Trap_LineA,    $7FFF
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_LineF,   Trap_LineF,   Trap_LineF,    $7FFF
  // 192 - 199 : OR/DIV instructions (group #8)
  TABLE  Op_ORB_r,     Op_ORB_r,     Op_ORB_r,      $0FFD
  TABLE  Op_ORW_r,     Op_ORW_r,     Op_ORW_r,      $0FFD
  TABLE  Op_ORL_r,     Op_ORL_r,     Op_ORL_r,      $0FFD
  TABLE  Op_DIVU,      Op_DIVU,      Op_DIVU,       $0FFD
  TABLE  Op_ORB_m,     Op_SBCD_r,    Op_SBCD_m,     $01FF
  TABLE  Op_ORW_m,     Op_ORW_m,     Op_ORW_m,      $01FC
  TABLE  Op_ORL_m,     Op_ORL_m,     Op_ORL_m,      $01FC
  TABLE  Op_DIVS,      Op_DIVS,      Op_DIVS,       $0FFD
  // 200 - 207 : SUB instructions (group #9)
  TABLE  Op_SUBB_r,    Op_SUBB_r,    Op_SUBB_r,     $0FFD
  TABLE  Op_SUBW_r,    Op_SUBW_r,    Op_SUBW_r,     $0FFF
  TABLE  Op_SUBL_r,    Op_SUBL_r,    Op_SUBL_r,     $0FFF
  TABLE  Op_SUBAW,     Op_SUBAW,     Op_SUBAW,      $0FFF
  TABLE  Op_SUBB_m,    Op_SUBXB_r,   Op_SUBXB_m,    $01FF
  TABLE  Op_SUBW_m,    Op_SUBXW_r,   Op_SUBXW_m,    $01FF
  TABLE  Op_SUBL_m,    Op_SUBXL_r,   Op_SUBXL_m,    $01FF
  TABLE  Op_SUBAL,     Op_SUBAL,     Op_SUBAL,      $0FFF
  // 208 - 215 : ADDQ/SUBQ instructions (group #5)
  TABLE  Op_ADDQB,     Op_ADDQB,     Op_ADDQB,      $01FD
  TABLE  Op_ADDQW,     Op_ADDQW,     Op_ADDQA,      $01FF
  TABLE  Op_ADDQL,     Op_ADDQL,     Op_ADDQA,      $01FF
  TABLE  Op_Scc,       Op_Scc,       Op_DBcc,       $01FF
  TABLE  Op_SUBQB,     Op_SUBQB,     Op_SUBQB,      $01FD
  TABLE  Op_SUBQW,     Op_SUBQW,     Op_SUBQA,      $01FF
  TABLE  Op_SUBQL,     Op_SUBQL,     Op_SUBQA,      $01FF
  TABLE  Op_Scc,       Op_Scc,       Op_DBcc,       $01FF
  // 216 - 223 : CMP/EOR instructions (group #B)
  TABLE  Op_CMPB,      Op_CMPB,      Op_CMPB,       $0FFD
  TABLE  Op_CMPW,      Op_CMPW,      Op_CMPW,       $0FFF
  TABLE  Op_CMPL,      Op_CMPL,      Op_CMPL,       $0FFF
  TABLE  Op_CMPAW,     Op_CMPAW,     Op_CMPAW,      $0FFF
  TABLE  Op_EORB,      Op_EORB,      Op_CMPMB,      $01FF
  TABLE  Op_EORW,      Op_EORW,      Op_CMPMW,      $01FF
  TABLE  Op_EORL,      Op_EORL,      Op_CMPML,      $01FF
  TABLE  Op_CMPAL,     Op_CMPAL,     Op_CMPAL,      $0FFF
  // 224 - 231 : AND/MUL instructions (group #C)
  TABLE  Op_ANDB_r,    Op_ANDB_r,    Op_ANDB_r,     $0FFD
  TABLE  Op_ANDW_r,    Op_ANDW_r,    Op_ANDW_r,     $0FFD
  TABLE  Op_ANDL_r,    Op_ANDL_r,    Op_ANDL_r,     $0FFD
  TABLE  Op_MULU,      Op_MULU,      Op_MULU,       $0FFD
  TABLE  Op_ANDB_m,    Op_ABCD_r,    Op_ABCD_m,     $01FF
  TABLE  Op_ANDW_m,    Op_EXG_DD,    Op_EXG_AA,     $01FF
  TABLE  Op_ANDL_m,    Op_ANDL_m,    Op_EXG_DA,     $01FE
  TABLE  Op_MULS,      Op_MULS,      Op_MULS,       $0FFD
  // 232 - 239 : ADD instructions (group #D)
  TABLE  Op_ADDB_r,    Op_ADDB_r,    Op_ADDB_r,     $0FFD
  TABLE  Op_ADDW_r,    Op_ADDW_r,    Op_ADDW_r,     $0FFF
  TABLE  Op_ADDL_r,    Op_ADDL_r,    Op_ADDL_r,     $0FFF
  TABLE  Op_ADDAW,     Op_ADDAW,     Op_ADDAW,      $0FFF
  TABLE  Op_ADDB_m,    Op_ADDXB_r,   Op_ADDXB_m,    $01FF
  TABLE  Op_ADDW_m,    Op_ADDXW_r,   Op_ADDXW_m,    $01FF
  TABLE  Op_ADDL_m,    Op_ADDXL_r,   Op_ADDXL_m,    $01FF
  TABLE  Op_ADDAL,     Op_ADDAL,     Op_ADDAL,      $0FFF
  // 240 - 247 : Memory shift instructions (group #E)
  TABLE  Op_ASRW_m,    Op_ASRW_m,    Op_ASRW_m,     $01FC
  TABLE  Op_ASLW_m,    Op_ASLW_m,    Op_ASLW_m,     $01FC
  TABLE  Op_LSRW_m,    Op_LSRW_m,    Op_LSRW_m,     $01FC
  TABLE  Op_LSLW_m,    Op_LSLW_m,    Op_LSLW_m,     $01FC
  TABLE  Op_ROXRW_m,   Op_ROXRW_m,   Op_ROXRW_m,    $01FC
  TABLE  Op_ROXLW_m,   Op_ROXLW_m,   Op_ROXLW_m,    $01FC
  TABLE  Op_RORW_m,    Op_RORW_m,    Op_RORW_m,     $01FC
  TABLE  Op_ROLW_m,    Op_ROLW_m,    Op_ROLW_m,     $01FC
  // 248 - 251 : Bit operation instructions (group #0)
  TABLE  Op_BTSTB_r,   Op_BTSTL_r,   Op_MOVEPW_r,   $0FFF
  TABLE  Op_BCHGB_r,   Op_BCHGL_r,   Op_MOVEPL_r,   $01FF
  TABLE  Op_BCLRB_r,   Op_BCLRL_r,   Op_MOVEPW_m,   $01FF
  TABLE  Op_BSETB_r,   Op_BSETL_r,   Op_MOVEPL_m,   $01FF
  // 252 - 255 : Two operand instructions (Group #4)
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Trap_Illegal, Trap_Illegal, Trap_Illegal,  $0000
  TABLE  Op_CHKW,      Op_CHKW,      Op_CHKW,       $0FFD
  TABLE  Op_LEA,       Op_LEA,       Op_LEA,        $07E4

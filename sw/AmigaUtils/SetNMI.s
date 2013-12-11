; SetNMI.s
; 2013, rok.krajnc@gmail.com
; gets VBR and upadted NMI vector to address of HRTmon entry point

execbase = 4
superstate = -150
userstate = -156
NMI_vec = $7c
HRTmon_entry = $00a0000c

EnterSuper:
  move.l execbase,a6
  jsr superstate(a6)
  move.l d0,savesp
SetNMI:
  movec vbr,d0
  add.l #NMI_vec,d0
  move.l d0,a6
  move.l #HRTmon_entry,(a6)
EnterUser:
  move.l execbase,a6
  move.l savesp,d0
  jsr userstate(a6)
savesp: blk.l 1
Return:
  rts



        XDEF _WheelDriver_ServerStub

        XREF _WheelDriver_Server

_WheelDriver_ServerStub
        movem.l d2-d7/a2-a4,-(a7)
        move.l  a1,-(a7)
        jsr     _WheelDriver_Server
        lea     (4,a7),a7
        movem.l (a7)+,d2-d7/a2-a4
        move.l  #0,d0
        rts



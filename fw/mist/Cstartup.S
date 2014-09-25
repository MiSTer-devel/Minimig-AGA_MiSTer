/*------------------------------------------------------------------------------
//*-         ATMEL Microcontroller Software Support  -  ROUSSET  -
//*------------------------------------------------------------------------------
//* The software is delivered "AS IS" without warranty or condition of any
//* kind, either express, implied or statutory. This includes without
//* limitation any warranty or condition with respect to merchantability or
//* fitness for any particular purpose, or against the infringements of
//* intellectual property rights of others.
//*-----------------------------------------------------------------------------
//*- File source          : Cstartup.s
//*- Object               : Generic CStartup for KEIL and GCC No Use REMAP
//*- Compilation flag     : None
//*-
//*- 1.0 10/Mar/05 JPP    : Creation
//*- 1.1 01/Apr/05 JPP    : save SPSR 
//*-----------------------------------------------------------------------------*/

     .equ   IRQ_Stack_Size,     0x00000060

/* #include "AT91SAM7S256_inc.h"	  */

	.equ AIC_IVR,         (256) 
	.equ AIC_FVR,         (260) 
	.equ AIC_EOICR,       (304)
	.equ AT91C_BASE_AIC,  (0xFFFFF000)

#;------------------------------------------------------------------------------
#;- Section Definition
#;-----------------
#;-  Section    
#;- .internal_ram_top 	Top_Stack: used by the cstartup for vector initalisation 
#;-			management defined by ld and affect from ldscript 
#;------------------------------------------------------------------------------
	.section 	.internal_ram_top
	.code 32
	.align 	0
	.global	Top_Stack
Top_Stack:
	
/*------------------------------------------------------------------------------
*- Area Definition
*------------------------------------------------------------------------------
* .text is used instead of .section .text so it works with arm-aout too.  */
        .section 	.reset
        .text
        .global _startup
        .func   _startup
_startup:
reset: 
/*------------------------------------------------------------------------------
//*- Exception vectors 
//*--------------------
//*- These vectors can be read at address 0 or at RAM address
//*- They ABSOLUTELY requires to be in relative addresssing mode in order to
//*- guarantee a valid jump. For the moment, all are just looping.
//*- If an exception occurs before remap, this would result in an infinite loop.
//*- To ensure if a exeption occurs before start application to infinite loop.
//*------------------------------------------------------------------------------*/

                B           InitReset           /* 0x00 Reset handler */
undefvec:
                B           undefvec            /* 0x04 Undefined Instruction */
swivec:
                B           swivec              /* 0x08 Software Interrupt */
pabtvec:
                B           pabtvec             /* 0x0C Prefetch Abort */
dabtvec:
                B           dabtvec             /* 0x10 Data Abort */
rsvdvec:
                B           rsvdvec             /* 0x14 reserved  */
irqvec:
                B           IRQ_Handler_Entry   /* 0x18 IRQ	 */
fiqvec:               			            	/* 0x1c FIQ	*/
/*------------------------------------------------------------------------------
//*- Function             : FIQ_Handler_Entry
//*- Treatments           : FIQ Controller Interrupt Handler.
//*- Called Functions     : AIC_FVR[interrupt] 
//*------------------------------------------------------------------------------*/

FIQ_Handler_Entry:

/*- Switch in SVC/User Mode to allow User Stack access for C code 	*/
/* because the FIQ is not yet acknowledged*/

/*- Save and r0 in FIQ_Register */
            mov         r9,r0
	        ldr         r0 , [r8, #AIC_FVR]
            msr         CPSR_c,#I_BIT | F_BIT | ARM_MODE_SVC

/*- Save scratch/used registers and LR in User Stack */
            stmfd       sp!, { r1-r3, r12, lr}

/*- Branch to the routine pointed by the AIC_FVR */
            mov         r14, pc
            bx          r0

/*- Restore scratch/used registers and LR from User Stack */
            ldmia       sp!, { r1-r3, r12, lr}

/*- Leave Interrupts disabled and switch back in FIQ mode */
            msr         CPSR_c, #I_BIT | F_BIT | ARM_MODE_FIQ

/*- Restore the R0 ARM_MODE_SVC register */
            mov         r0,r9

/*- Restore the Program Counter using the LR_fiq directly in the PC */
            subs        pc,lr,#4
	.align 0
.RAM_TOP:
	.word	Top_Stack

InitReset:
/*------------------------------------------------------------------------------
/*- Low level Init (PMC, AIC, ? ....) by C function AT91F_LowLevelInit
/*------------------------------------------------------------------------------*/
            	.extern   AT91F_LowLevelInit
/*- minumum C initialization */
/*- call  AT91F_LowLevelInit( void) */

            ldr     r13,.RAM_TOP            /* temporary stack in internal RAM */
/*--Call Low level init function in ABSOLUTE through the Interworking	*/
	        ldr	    r0,=AT91F_LowLevelInit
            mov     lr, pc
	        bx	    r0
/*------------------------------------------------------------------------------
//*- Stack Sizes Definition
//*------------------------
//*- Interrupt Stack requires 2 words x 8 priority level x 4 bytes when using
//*- the vectoring. This assume that the IRQ management.
//*- The Interrupt Stack must be adjusted depending on the interrupt handlers.
//*- Fast Interrupt not requires stack If in your application it required you must
//*- be definehere.
//*- The System stack size is not defined and is limited by the free internal
//*- SRAM.
//*------------------------------------------------------------------------------*/

/*------------------------------------------------------------------------------
//*- Top of Stack Definition
//*-------------------------
//*- Interrupt and Supervisor Stack are located at the top of internal memory in 
//*- order to speed the exception handling context saving and restoring.
//*- ARM_MODE_SVC (Application, C) Stack is located at the top of the external memory.
//*------------------------------------------------------------------------------*/

	  .EQU		IRQ_STACK_SIZE,    (3*8*4)
          .EQU		ARM_MODE_FIQ,       0x11
          .EQU		ARM_MODE_IRQ,       0x12
          .EQU		ARM_MODE_SVC,       0x13

          .EQU		I_BIT,              0x80
          .EQU		F_BIT,              0x40

/*------------------------------------------------------------------------------
//*- Setup the stack for each mode
//*-------------------------------*/
                mov     r0,r13

/*- Set up Fast Interrupt Mode and set FIQ Mode Stack*/
                msr     CPSR_c, #ARM_MODE_FIQ | I_BIT | F_BIT
/*- Init the FIQ register*/
            	ldr     r8, =AT91C_BASE_AIC

/*- Set up Interrupt Mode and set IRQ Mode Stack*/
                msr     CPSR_c, #ARM_MODE_IRQ | I_BIT | F_BIT
                mov     r13, r0                     /* Init stack IRQ */
                sub     r0, r0, #IRQ_Stack_Size
/*- Set up Supervisor Mode and set Supervisor Mode Stack*/
                msr     CPSR_c, #ARM_MODE_SVC
                mov     r13, r0                     /* Init stack Sup */

/*- Enable interrupt & Set up Supervisor Mode and set Supervisor Mode Stack*/

# Relocate .data section (Copy from ROM to RAM)
                LDR     R1, =_etext
                LDR     R2, =_data
                LDR     R3, =_edata
LoopRel:        CMP     R2, R3
                LDRLO   R0, [R1], #4
                STRLO   R0, [R2], #4
                BLO     LoopRel

# Clear .bss section (Zero init)
                MOV     R0, #0
                LDR     R1, =__bss_start__
                LDR     R2, =__bss_end__
LoopZI:         CMP     R1, R2
                STRLO   R0, [R1], #4
                BLO     LoopZI

		ldr	lr,=exit
		ldr	r0,=main
		bx	r0

        .size   _startup, . - _startup
        .endfunc
		
	
/* "exit" dummy added by mthomas to avoid sbrk write read etc. needed
   by the newlib default "exit" */
        .global exit
        .func   exit
exit:
        b    .
	.size   exit, . - exit
        .endfunc



/*------------------------------------------------------------------------------
//*- Manage exception
//*---------------
//*- This module The exception must be ensure in ARM mode
//*------------------------------------------------------------------------------
//*------------------------------------------------------------------------------
//*- Function             : IRQ_Handler_Entry
//*- Treatments           : IRQ Controller Interrupt Handler.
//*- Called Functions     : AIC_IVR[interrupt] 
//*------------------------------------------------------------------------------*/
        .global IRQ_Handler_Entry
        .func   IRQ_Handler_Entry

IRQ_Handler_Entry:

/*- Manage Exception Entry  */
/*- Adjust and save LR_irq in IRQ stack  */
            sub         lr, lr, #4
            stmfd       sp!, {lr}

/*- Save SPSR need to be saved for nested interrupt */
            mrs         r14, SPSR
            stmfd       sp!, {r14}

/*- Save and r0 in IRQ stack  */
            stmfd       sp!, {r0}

/*- Write in the IVR to support Protect Mode  */
/*- No effect in Normal Mode  */
/*- De-assert the NIRQ and clear the source in Protect Mode */
            ldr         r14, =AT91C_BASE_AIC
	    ldr         r0 , [r14, #AIC_IVR]
	    str         r14, [r14, #AIC_IVR]

/*- Enable Interrupt and Switch in Supervisor Mode */
            msr         CPSR_c, #ARM_MODE_SVC

/*- Save scratch/used registers and LR in User Stack */
            stmfd       sp!, { r1-r3, r12, r14}

/*- Branch to the routine pointed by the AIC_IVR  */
            mov         r14, pc
            bx          r0
/*- Restore scratch/used registers and LR from User Stack*/
            ldmia       sp!, { r1-r3, r12, r14}

/*- Disable Interrupt and switch back in IRQ mode */
            msr         CPSR_c, #I_BIT | ARM_MODE_IRQ

/*- Mark the End of Interrupt on the AIC */
            ldr         r14, =AT91C_BASE_AIC
            str         r14, [r14, #AIC_EOICR]

/*- Restore SPSR_irq and r0 from IRQ stack */
            ldmia       sp!, {r0}

/*- Restore SPSR_irq and r0 from IRQ stack */
            ldmia       sp!, {r14}
            msr         SPSR_cxsf, r14

/*- Restore adjusted  LR_irq from IRQ stack directly in the PC */
            ldmia       sp!, {pc}^
	
        .size   IRQ_Handler_Entry, . - IRQ_Handler_Entry
        .endfunc
/*---------------------------------------------------------------
//* ?EXEPTION_VECTOR
//* This module is only linked if needed for closing files.
//*---------------------------------------------------------------*/
        .global AT91F_Default_FIQ_handler
        .func   AT91F_Default_FIQ_handler
AT91F_Default_FIQ_handler:
            b     AT91F_Default_FIQ_handler
        .size   AT91F_Default_FIQ_handler, . - AT91F_Default_FIQ_handler
        .endfunc

        .global AT91F_Default_IRQ_handler
        .func   AT91F_Default_IRQ_handler
AT91F_Default_IRQ_handler:
            b     AT91F_Default_IRQ_handler
        .size   AT91F_Default_IRQ_handler, . - AT91F_Default_IRQ_handler
        .endfunc

        .global AT91F_Spurious_handler
        .func   AT91F_Spurious_handler
AT91F_Spurious_handler:
            b     AT91F_Spurious_handler
        .size   AT91F_Spurious_handler, . - AT91F_Spurious_handler
        .endfunc


        .end

	

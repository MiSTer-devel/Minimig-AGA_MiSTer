//*----------------------------------------------------------------------------
//*         ATMEL Microcontroller Software Support  -  ROUSSET  -
//*----------------------------------------------------------------------------
//* The software is delivered "AS IS" without warranty or condition of any
//* kind, either express, implied or statutory. This includes without
//* limitation any warranty or condition with respect to merchantability or
//* fitness for any particular purpose, or against the infringements of
//* intellectual property rights of others.
//*----------------------------------------------------------------------------
//* File Name           : Cstartup_SAM7.c
//* Object              : Low level initializations written in C for GCC Tools
//* Creation            : 12/Jun/04
//* 1.2   28/Feb/05 JPP : LIB change AT91C_WDTC_WDDIS & PLL
//* 1.3   21/Mar/05 JPP : Change PLL Wait time
//*----------------------------------------------------------------------------

// Include the board file description
#include "AT91SAM7S256.h"

// The following functions must be write in ARM mode this function called directly
// by exception vector
extern void AT91F_Spurious_handler(void);
extern void AT91F_Default_IRQ_handler(void);
extern void AT91F_Default_FIQ_handler(void);

//*----------------------------------------------------------------------------
//* \fn    AT91F_LowLevelInit
//* \brief This function performs very low level HW initialization
//*        this function can be use a Stack, depending the compilation
//*        optimization mode
//*----------------------------------------------------------------------------
void AT91F_LowLevelInit( void)
{
 int            i;
 AT91PS_PMC     pPMC = AT91C_BASE_PMC;
    //* Set Flash Waite sate
	//  Single Cycle Access at Up to 30 MHz, or 40
	//  if MCK = 47923200 I have 50 Cycle for 1 usecond ( flied MC_FMR->FMCN
	    AT91C_BASE_MC->MC_FMR = ((AT91C_MC_FMCN)&(48 <<16)) | AT91C_MC_FWS_1FWS ;

    //* Watchdog Disable
        AT91C_BASE_WDTC->WDTC_WDMR= AT91C_WDTC_WDDIS;

	//* Set MCK at 47 923 200
    // 1 Enabling the Main Oscillator:
        // SCK = 1/32768 = 30.51 uSecond
    	// Start up time = 8 * 6 / SCK = 56 * 30.51 = 1,46484375 ms
       pPMC->PMC_MOR = ( (AT91C_CKGR_OSCOUNT) & (0x06 <<8)) | AT91C_CKGR_MOSCEN ;
        // Wait the startup time
        while(!(pPMC->PMC_SR & AT91C_PMC_MOSCS));
	// 2 Checking the Main Oscillator Frequency (Optional)
	// 3 Setting PLL and divider:
		// - div by 5 Fin = 3,6864 =(18,432 / 5)
		// - Mul 25+1: Fout =	95,8464 =(3,6864 *26)
		// for 96 MHz the erroe is 0.16%
		// Field out NOT USED = 0
		// PLLCOUNT pll startup time estimate at : 0.844 ms
		// PLLCOUNT 28 = 0.000844 /(1/32768)
       pPMC->PMC_PLLR = ((AT91C_CKGR_DIV & 0x05) |
                         (AT91C_CKGR_PLLCOUNT & (28<<8)) |
                         (AT91C_CKGR_MUL & (25<<16)));

        // Wait the startup time
        while(!(pPMC->PMC_SR & AT91C_PMC_LOCK));
        while(!(pPMC->PMC_SR & AT91C_PMC_MCKRDY));
 	// 4. Selection of Master Clock and Processor Clock
 	// select the PLL clock divided by 2
 	    pPMC->PMC_MCKR =  AT91C_PMC_PRES_CLK_2 ;
 	    while(!(pPMC->PMC_SR & AT91C_PMC_MCKRDY));

 	    pPMC->PMC_MCKR |= AT91C_PMC_CSS_PLL_CLK  ;
 	    while(!(pPMC->PMC_SR & AT91C_PMC_MCKRDY));

	// Set up the default interrupts handler vectors
	AT91C_BASE_AIC->AIC_SVR[0] = (int) AT91F_Default_FIQ_handler ;
	for (i=1;i < 31; i++)
	{
	    AT91C_BASE_AIC->AIC_SVR[i] = (int) AT91F_Default_IRQ_handler ;
	}
	AT91C_BASE_AIC->AIC_SPU  = (int) AT91F_Spurious_handler ;

}


/********************************************/
/* audio_top.v                              */
/*                                          */
/* 2012, rok.krajnc@gmail.com               */
/********************************************/


module audio_top (
  input  wire           clk,
  input  wire           rst_n,
  // config
  input  wire           mix,
  // audio shifter
  input  wire [ 15-1:0] rdata,
  input  wire [ 15-1:0] ldata,
  input  wire           exchan,
  output wire           aud_bclk,
  output wire           aud_daclrck,
  output wire           aud_dacdat,
  output wire           aud_xck,
  // I2C audio config
  output wire           i2c_sclk,
  inout                 i2c_sdat
);



////////////////////////////////////////
// modules                            //
////////////////////////////////////////

// don't include these two modules for sim, as they have some probems in simulation
`ifndef SOC_SIM


// audio shifter
audio_shifter audio_shifter (
  .clk          (clk              ),
  .nreset       (rst_n            ),
  .mix          (mix              ),
  .rdata        (rdata            ),
  .ldata        (ldata            ),
  .exchan       (exchan           ),
  .aud_bclk     (aud_bclk         ),
  .aud_daclrck  (aud_daclrck      ),
  .aud_dacdat   (aud_dacdat       ),
  .aud_xck      (aud_xck          )
);


// I2C audio config
I2C_AV_Config audio_config (
  // host side
  .iCLK         (clk              ),
  .iRST_N       (rst_n            ),
  // i2c side
  .oI2C_SCLK    (i2c_sclk         ),
  .oI2C_SDAT    (i2c_sdat         )
);


`endif // SOC_SIM



endmodule


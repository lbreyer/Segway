module Segway(clk,RST_n,INERT_SS_n,INERT_MOSI,INERT_SCLK,
              INERT_MISO,INERT_INT,A2D_SS_n,A2D_MOSI,A2D_SCLK,
			  A2D_MISO,PWM1_lft,PWM2_lft,PWM1_rght,PWM2_rght,
			  OVR_I_lft,OVR_I_rght,piezo_n,piezo,RX);
			  
  input clk,RST_n;
  input INERT_MISO;						// Serial in from inertial sensor
  input A2D_MISO;						// Serial in from A2D
  input INERT_INT;						// Interrupt from inertial indicating data ready
  input OVR_I_lft,OVR_I_rght;			// Instantaneous over current in motor
  input RX;								// UART input from BLE module

  
  output A2D_SS_n, INERT_SS_n;			// Slave selects to A2D and inertial sensor
  output A2D_MOSI, INERT_MOSI;			// MOSI signals to A2D and inertial sensor
  output A2D_SCLK, INERT_SCLK;			// SCLK signals to A2D and inertial sensor
  output PWM1_lft, PWM2_lft;  			// left motor speed/direction controls
  output PWM1_rght,PWM2_rght;			// right motor speed/direction controls
  output piezo_n,piezo;					// diff drive to piezo for sound
    
  wire rst_n;							// synchronized global reset signal
  wire vld;								// tells us a new inertial reading is valid
  wire [15:0] ptch;						// ptch reading from inertial interface
  wire [15:0] ptch_rt;
  wire signed [11:0] lft_spd, rght_spd;	// from balance_cntrl to mtr_drv, specify absolute speed to drive motor
  wire lft_rev, rght_rev;				// left & right motor direction
  wire [11:0] lft_ld, rght_ld;		// measurements from load cells
  wire [11:0] batt;						// proportional to battery measurement
  wire [11:0] steer_pot;
  wire norm_mode;						// asserted from steer_en to piezo
  wire en_steer;						// steering enabled
  wire rider_off;						// from steer_en to auth_blk
  wire batt_low;
  wire too_fast;
  wire pwr_up;							// asserted from Auth_blk to balance_cntrl to enable unit
  wire OVR_I_lft,OVR_I_rght;
  
  localparam BATT_THRES = 12'h800;
  localparam fast_sim = 0;
  
  //////////////////////////////////////////////////////
  // Instantiate Auth_blk that handles authorization //
  ////////////////////////////////////////////////////
  Auth_blk iAuth(.clk(clk),.rst_n(rst_n),.RX(RX),.rider_off(rider_off),.pwr_up(pwr_up));

						
  //////////////////////////////////////////////////////////
  // Instantiate interface to inertial sensor (ST iNEMO) //
  ////////////////////////////////////////////////////////
  inert_intf #(fast_sim) iNEMO(.clk(clk),.rst_n(rst_n),.ptch(ptch),.ptch_rt(ptch_rt),
                   .vld(vld),.SS_n(INERT_SS_n),.SCLK(INERT_SCLK),
				   .MOSI(INERT_MOSI),.MISO(INERT_MISO),
				   .INT(INERT_INT));
  
  /////////////////////////////////////
  // Instantiate balance controller //
  ///////////////////////////////////					 
  balance_cntrl #(fast_sim) iBAL(.clk(clk),.rst_n(rst_n),.vld(vld),.ptch(ptch),
                     .ptch_rt(ptch_rt),.pwr_up(pwr_up),.rider_off(rider_off),
					 .steer_pot(steer_pot),.en_steer(en_steer),.lft_spd(lft_spd),
					 .rght_spd(rght_spd),.too_fast(too_fast));


  //////////////////////////////////
  // Instantiate steering enable //
  ////////////////////////////////				 
  steer_en #(fast_sim) iSTR(.clk(clk),.rst_n(rst_n),.lft_ld(lft_ld),
                            .rght_ld(rght_ld),
							.en_steer(en_steer),.rider_off(rider_off));

  
  //////////////////////////////
  // Instantiate motor drive //
  ////////////////////////////  
  mtr_drv iDRV(.clk(clk),.rst_n(rst_n),.lft_spd(lft_spd),
               .rght_spd(rght_spd),.PWM1_lft(PWM1_lft),.PWM2_lft(PWM2_lft),
			   .PWM1_rght(PWM1_rght),.PWM2_rght(PWM2_rght),
			   .OVR_I_lft(OVR_I_lft),.OVR_I_rght(OVR_I_rght));
	  
	  
 ////////////////////////////////////////////////////////////
  // Instantiate A2D Interface for reading battery voltage //
  //////////////////////////////////////////////////////////
  A2D_intf iA2D(.clk(clk),.rst_n(rst_n),.nxt(vld),.lft_ld(lft_ld),.rght_ld(rght_ld),
                .batt(batt),.steer_pot(steer_pot),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
				.MOSI(A2D_MOSI),.MISO(A2D_MISO));
		

  assign batt_low = (batt<BATT_THRES) ? 1'b1 : 1'b0;
  /////////////////////////////////////
  // Instantiate reset synchronizer //
  /////////////////////////////////// 		
  piezo_drv #(fast_sim) iBUZZ(.clk(clk),.rst_n(rst_n),.en_steer(en_steer),.too_fast(too_fast),
              .batt_low(batt_low),.piezo(piezo),.piezo_n(piezo_n));
				  

  /////////////////////////////////////
  // Instantiate reset synchronizer //
  ///////////////////////////////////  
  rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));
  
endmodule

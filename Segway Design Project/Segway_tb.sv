`timescale 1ns/1ps
module Segway_tb();
			
//// Interconnects to DUT/support defined as type wire /////
wire SS_n,SCLK,MOSI,MISO,INT;				// to inertial sensor
wire A2D_SS_n,A2D_SCLK,A2D_MOSI,A2D_MISO;	// to A2D converter
wire RX_TX;
wire PWM1_rght, PWM2_rght, PWM1_lft, PWM2_lft;
wire piezo,piezo_n;
wire cmd_sent;
wire rst_n;					// synchronized global reset

////// Stimulus is declared as type reg ///////
reg clk, RST_n;
reg [7:0] cmd;				// command host is sending to DUT
reg send_cmd;				// asserted to initiate sending of command
reg signed [15:0] rider_lean;
reg [11:0] ld_cell_lft, ld_cell_rght,steerPot,batt;	// A2D values
reg OVR_I_lft, OVR_I_rght;

///// Internal registers for testing purposes??? /////////


////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Segway with Inertial sensor //
//////////////////////////////////////////////////////////////	
SegwayModel iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),
                  .MISO(MISO),.MOSI(MOSI),.INT(INT),.PWM1_lft(PWM1_lft),
				  .PWM2_lft(PWM2_lft),.PWM1_rght(PWM1_rght),
				  .PWM2_rght(PWM2_rght),.rider_lean(rider_lean));				  

/////////////////////////////////////////////////////////
// Instantiate Model of A2D for load cell and battery //
///////////////////////////////////////////////////////
ADC128S_FC iA2D(.clk(clk),.rst_n(RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
             .MISO(A2D_MISO),.MOSI(A2D_MOSI),.ld_cell_lft(ld_cell_lft),.ld_cell_rght(ld_cell_rght),
			 .steerPot(steerPot),.batt(batt));			
	 
////// Instantiate DUT ////////
Segway iDUT(.clk(clk),.RST_n(RST_n),.INERT_SS_n(SS_n),.INERT_MOSI(MOSI),
            .INERT_SCLK(SCLK),.INERT_MISO(MISO),.INERT_INT(INT),.A2D_SS_n(A2D_SS_n),
			.A2D_MOSI(A2D_MOSI),.A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),
			.PWM1_lft(PWM1_lft),.PWM2_lft(PWM2_lft),.PWM1_rght(PWM1_rght),
			.PWM2_rght(PWM2_rght),.OVR_I_lft(OVR_I_lft),.OVR_I_rght(OVR_I_rght),
			.piezo_n(piezo_n),.piezo(piezo),.RX(RX_TX));

//// Instantiate UART_tx (mimics command from BLE module) //////
UART_tx iTX(.clk(clk),.rst_n(rst_n),.TX(RX_TX),.trmt(send_cmd),.tx_data(cmd),.tx_done(cmd_sent));

/////////////////////////////////////
// Instantiate reset synchronizer //
///////////////////////////////////
rst_synch iRST(.clk(clk),.RST_n(RST_n),.rst_n(rst_n));

initial begin
  ///Luke's Test incase the tasks do not work.
  
  /*clk = 0;
  RST_n = 0;
  cmd = 8'h00;
  send_cmd = 0;
  rider_lean = 16'h0000;
  ld_cell_lft = 12'h000;
  ld_cell_rght = 12'h000;
  steerPot = 12'h000;
  batt = 12'h000;
  OVR_I_lft = 0; 
  OVR_I_rght = 0;
  @(posedge clk);
  @(negedge clk);
    RST_n = 1; 
	
  repeat(100) @(posedge clk);
    cmd = 8'h67;
    send_cmd = 1;
  @(posedge clk);
  @(negedge clk);
    send_cmd = 0;
  repeat(800000) @(posedge clk);
    rider_lean = 16'h0FFF;
  repeat(1600000) @(posedge clk);
    rider_lean = 16'h0000;
  repeat(800000) @(posedge clk);
  //Rewrote with the use of tasks
  //Test for PID
  Initialize;
  ld_cell_lft = 12'h200;
  ld_cell_rght = 12'h200;
  
  repeat(100) @(posedge clk);
  
  SendCmd(8'h67);

  repeat(800000) @(posedge clk);
    rider_lean = 16'h0FFF;

  repeat(1600000) @(posedge clk);
    rider_lean = 16'h0000;

  repeat(800000) @(posedge clk);

  $stop();
  //Rider On Test(left and right load cells have already been set.)
  batt = 12'hFFF;
  $display("1");
  check_value(0, iDUT.pwr_up, "pwr_up", "RIDER ON");
  SendCmd(8'h67);

  repeat(800000) @(posedge clk);
  $display("2");
  check_value(1, iDUT.pwr_up, "pwr_up", "RIDER ON");
  rider_lean = 16'h0FFF;

  //Waiting to test steerpot
  repeat(2000000) @(posedge clk);

  //Turning Left and Right
  steerPot = 12'h200;
  ld_cell_lft = 12'h200;
  ld_cell_rght = 12'h200;

  repeat(2000000) @(posedge clk);
  $display("3");
  check_value(1, ((iPHYS.omega_rght < iPHYS.omega_lft) || (iPHYS.omega_rght > iPHYS.omega_lft)), "left or right ", "Turning_Left_or_Right");

  steerPot = 12'hF00;
  $display("4");
  check_value(1, ((iPHYS.omega_rght < iPHYS.omega_lft) || (iPHYS.omega_rght > iPHYS.omega_lft)), "left or right", "Turning_Left_or_Right");

  //Testing Rider OFF
  ld_cell_lft = 0;
  ld_cell_rght = 0;
  repeat(2000000) @(posedge clk);
  $display("5");
  check_value(0, iDUT.iBAL.en_steer, "en_steer", "Rider_OFF");

  SendCmd(8'h73);
  repeat(2000000) @(posedge clk);
  $display("6");
  check_value(0, iDUT.pwr_up, "pwr_up", "RIDER ON");

  $stop();
*/

  //RIDER_LEAN;
  //RIDER_ON;
  //LEFT_RIGHT;
  //RIDER_OFF;
  //MTR_DRIVE_TEST;
  STEPPING_OFF;
  $display("YAHOOO!!!!");
  $stop();
end
`include "tb_tests.sv"

always
  #10 clk = ~clk;

endmodule	

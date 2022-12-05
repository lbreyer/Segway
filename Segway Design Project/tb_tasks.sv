/*
*This file contains all the tasks/functions used in the Segway Project.
*/

//This task intalize the tests.
task Initialize;
	clk = 0;
	RST_n = 0;
	cmd = 0;
	send_cmd = 0;
	rider_lean = 0;
	ld_cell_lft = 0;
	ld_cell_rght = 0;
	steerPot = 0;
	batt = 0;
	OVR_I_lft = 0; 
	OVR_I_rght = 0;
	@(posedge clk);
	@(negedge clk);
	RST_n = 1;
endtask

//Used to send the command to UART
task SendCmd (input byte command);
	(@negedge clk);
	cmd = command;
	send_cmd  = 1;
	(@negedge clk);
	send_cmd = 0;
endtask

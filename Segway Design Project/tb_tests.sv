`include "tb_tasks.sv"
/*
* This file contains all the tests
*/
task RIDER_LEAN;
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
endtask

task RIDER_ON;
    Initialize;
    ld_cell_lft = 12'h200;
    ld_cell_rght = 12'h200;
    batt = 12'hFFF;
    repeat(800000) @(posedge clk);

    check_value(0, iDUT.pwr_up, "pwr_up", "RIDER ON");

    SendCmd(8'h67);

    repeat(1600000) @(posedge clk);
    $display("2");
    check_value(1, iDUT.pwr_up, "pwr_up", "RIDER ON");
endtask

task LEFT_RIGHT;
    Initialize;
    ld_cell_lft = 12'h200;
    ld_cell_rght = 12'h200;
    batt = 12'hFFF;
    repeat(800000) @(posedge clk);
    SendCmd(8'h67);
    repeat(800000) @(posedge clk);
    rider_lean = 16'h0FFF;
    repeat(2000000) @(posedge clk);
    check_value(1, iDUT.pwr_up, "pwr_up", "RIDER ON");
    repeat(2000000) @(posedge clk);

    steerPot = 12'h200;
    repeat(2000000) @(posedge clk);
    $display("3");
    check_value(1, ((iPHYS.omega_rght < iPHYS.omega_lft) || (iPHYS.omega_rght > iPHYS.omega_lft)), "left or right ", "Turning_Left_or_Right");

    steerPot = 12'hF00;
    repeat(2000000) @(posedge clk);
    $display("4");
    check_value(1, ((iPHYS.omega_rght < iPHYS.omega_lft) || (iPHYS.omega_rght > iPHYS.omega_lft)), "left or right", "Turning_Left_or_Right");
endtask

task RIDER_OFF;
    Initialize;
    ld_cell_lft = 12'h200;
    ld_cell_rght = 12'h200;
    batt = 12'hFFF;
    repeat(800000) @(posedge clk);

    SendCmd(8'h67);

    repeat(1600000) @(posedge clk);
    check_value(1, iDUT.pwr_up, "pwr_up", "RIDER OFF");
    repeat(1600000) @(posedge clk);
    ld_cell_lft = 0;
    ld_cell_rght = 0;
    
    repeat(2000000) @(posedge clk);
    $display("5");
    check_value(0, iDUT.iBAL.en_steer, "en_steer", "Rider_OFF");
    repeat(800000) @(posedge clk);
    SendCmd(8'h73);
    repeat(2000000) @(posedge clk);
    $display("6");
    check_value(0, iDUT.pwr_up, "pwr_up", "RIDER OFF");
endtask

task MTR_DRIVE_TEST;
    Initialize;
    repeat(128) @(posedge iDUT.iDRV.PWM_synch) begin
    repeat(2) @(posedge clk) begin end
    @(negedge clk)
        OVR_I_lft = 1;
    repeat(20) @(negedge clk) begin end
        OVR_I_lft = 0;
    end

    @(posedge clk)
    // if(iDUT.iDRV.OVR_I_shtdwn !== 0) begin
    //     $display("OVR_I_shtdwn is asserted but should not be");
    //     $stop;
    // end
    check_value(iDUT.iDRV.OVR_I_shtdwn, 0, "OVR_I_shtdwn", "MTR_DRIVE_TEST");

    repeat (136) begin

    @(posedge iDUT.iDRV.PWM_synch) begin
        repeat(256) @(posedge clk) begin end  //wait for blanking window to end

        repeat(2) @(posedge clk) begin end
        
        @(negedge clk)
        OVR_I_lft = 1;
        repeat(20) @(negedge clk) begin end
        OVR_I_lft = 0;
    end
    end

    @(posedge clk)
    // if(iDUT.iDRV.OVR_I_shtdwn !== 1) begin
    //     $display("OVR_I_shtdwn is not asserted but should be");
    //     $stop;
    // end
    check_value(iDUT.iDRV.OVR_I_shtdwn, 1, "OVR_I_shtdwn", "MTR_DRIVE_TEST");
endtask

task STEPPING_OFF;
Initialize;
    ld_cell_lft = 12'h200;
    ld_cell_rght = 12'h200;
    batt = 12'hFFF;
    repeat(800000) @(posedge clk);
    SendCmd(8'h67);
    repeat(800000) @(posedge clk);
    rider_lean = 16'h0FFF;
    repeat(2000000) @(posedge clk);
    check_value(1, iDUT.pwr_up, "pwr_up", "RIDER ON");
    repeat(2000000) @(posedge clk);

    ld_cell_lft = 12'h200;
    ld_cell_rght = 12'h000;
    repeat(2000000) @(posedge clk);
    check_value(0, iDUT.iBAL.en_steer, "en_steer", "Rider_OFF");
endtask

module SegwayMath(clk, rst_n, PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast);

input signed [11:0] PID_cntrl; // PID control signal
input [11:0] steer_pot; // Segway steering potential
input [7:0] ss_tmr; // Slow start timer
input clk, rst_n, en_steer, pwr_up; // clock, active low asynch reset, steering enable and powered up signals

output signed [11:0] lft_spd, rght_spd; // Left and right wheel speeds
output reg too_fast; // Signal alert for too fast operation

// Intermediary signals
logic signed [19:0] ss_temp; 
logic signed [11:0] steer_temp;
logic signed [12:0] lft_torque, rght_torque, lft_torque_t, rght_torque_t, PID_ss_ext, 
			lft_shaped, rght_shaped;

// Scaling motion with soft start to improve smoothness 
assign ss_temp = PID_cntrl * $signed({1'b0,ss_tmr});

// Steering input calculations
assign steer_temp = (&steer_pot[11:9] & |steer_pot[8:0]) ? 12'hE00 - 12'h7FF :
			~|steer_pot[11:9] ? 12'h200 - 12'h7FF : steer_pot - 12'h7FF;
assign PID_ss_ext = {ss_temp[19],ss_temp[19:8]}; // Sign extension and attenuation 

// Wheel torque assignment
assign lft_torque_t = en_steer ? PID_ss_ext + {{4{steer_temp[11]}}, steer_temp[11:4]} + {{3{steer_temp[11]}}, steer_temp[11:3]} : PID_ss_ext;
assign rght_torque_t = en_steer ? PID_ss_ext - {{4{steer_temp[11]}}, steer_temp[11:4]} + {{3{steer_temp[11]}}, steer_temp[11:3]} : PID_ss_ext;

//extra flop on lft_torque for max delay purposes
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    lft_torque <= 13'h0000;
  else
    lft_torque <= lft_torque_t;

//extra flop on rght_torque for max delay purposes
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    rght_torque <= 13'h0000;
  else
    rght_torque <= rght_torque_t;

// Deadzone shaping (left)
assign lft_shaped = pwr_up ? (lft_torque[12] & lft_torque < -8'h3C) || (~lft_torque[12] & lft_torque > 8'h3C) ? lft_torque[12] ? lft_torque - 13'h3C0: lft_torque + 13'h3C0 : lft_torque * $signed(6'h10) : 13'h0000;

// Deadzone shaping (right)
assign rght_shaped = pwr_up ? (rght_torque[12] & rght_torque < -8'h3C) || (~rght_torque[12] & rght_torque > 8'h3C) ? rght_torque[12] ? rght_torque - 13'h3C0 : rght_torque + 13'h3C0 : rght_torque * $signed(6'h10) : 13'h0000;

// Final Saturation & Over Speed Detection
assign lft_spd = (~lft_shaped[12] & lft_shaped[11]) ? 12'h7FF : 
(lft_shaped[12] & ~lft_shaped[11]) ? 12'h800 :
lft_shaped[11:0];
assign rght_spd = (~rght_shaped[12] & rght_shaped[11]) ? 12'h7FF : 
(rght_shaped[12] & ~rght_shaped[11]) ? 12'h800 :
rght_shaped[11:0];

assign too_fast = (lft_spd > $signed(12'd1792) || rght_spd > $signed(12'd1792));

endmodule

module SegwayMath(PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast);

input signed [11:0] PID_cntrl;
input [11:0] steer_pot;
input [7:0] ss_tmr;
input en_steer, pwr_up;

output signed [11:0] lft_spd, rght_spd;
output too_fast;

logic signed [19:0] ss_temp;
logic signed [11:0] PID_ss, steer_temp1, steer_temp2, steer_temp3;
logic signed [12:0] lft_torque, rght_torque, PID_ss_ext, lft_torq_temp, rght_torq_temp, 
			lft_torq_low, lft_torq_high, lft_torque_comp, lft_mult, lft_shaped_low, lft_shaped,
			rght_torq_low, rght_torq_high, rght_torque_comp, rght_mult, rght_shaped_low, rght_shaped;

// Scaling with soft start
assign ss_temp = PID_cntrl * $signed({1'b0,ss_tmr});
assign PID_ss = ss_temp[19:8];

// Steering input
assign steer_temp1 = (&steer_pot[11:9] & |steer_pot[8:0]) ? 12'hE00 :
			~|steer_pot[11:9] ? 12'h200 : steer_pot;
assign steer_temp2 = $signed(steer_temp1) - 12'h7FF;
assign steer_temp3 = {{4{steer_temp2[11]}}, steer_temp2[11:4]} + {{3{steer_temp2[11]}}, steer_temp2[11:3]};
assign PID_ss_ext = {PID_ss[11],PID_ss};

assign lft_torq_temp = PID_ss_ext + steer_temp3;
assign rght_torq_temp = PID_ss_ext - steer_temp3;

assign lft_torque = en_steer ? lft_torq_temp : PID_ss_ext;
assign rght_torque = en_steer ? rght_torq_temp : PID_ss_ext;

// Deadzone shaping (left)
assign lft_torq_low = lft_torque - 13'h3C0;
assign lft_torq_high = lft_torque + 13'h3C0;
assign lft_torque_comp = lft_torque[12] ? lft_torq_low : lft_torq_high;

assign lft_mult = lft_torque * $signed(6'h10);
assign lft_shaped_low = (lft_torque[12] & lft_torque < -8'h3C) || (~lft_torque[12] & lft_torque > 8'h3C) ? lft_torque_comp : lft_mult;

assign lft_shaped = pwr_up ? lft_shaped_low : 13'h0000;

// Deadzone shaping (right)
assign rght_torq_low = rght_torque - 13'h3C0;
assign rght_torq_high = rght_torque + 13'h3C0;
assign rght_torque_comp = rght_torque[12] ? rght_torq_low : rght_torq_high;

assign rght_mult = rght_torque * $signed(6'h10);
assign rght_shaped_low = (rght_torque[12] & rght_torque < -8'h3C) || (~rght_torque[12] & rght_torque > 8'h3C) ? rght_torque_comp : rght_mult;

assign rght_shaped = pwr_up ? rght_shaped_low : 13'h0000;

// Final Saturation & Over Speed Detect
assign lft_spd = (~lft_shaped[12] & lft_shaped[11]) ? 12'h7FF : 
(lft_shaped[12] & ~lft_shaped[11]) ? 12'h800 :
lft_shaped[11:0];
assign rght_spd = (~rght_shaped[12] & rght_shaped[11]) ? 12'h7FF : 
(rght_shaped[12] & ~rght_shaped[11]) ? 12'h800 :
rght_shaped[11:0];

assign too_fast = (lft_spd > $signed(12'd1792) || rght_spd > $signed(12'd1792));

endmodule

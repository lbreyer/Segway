module PWM11(clk, rst_n, duty, PWM_sig, PWM_synch, OVR_I_blank_n);

input [10:0] duty; // PWM duty
input clk, rst_n;

output reg PWM_sig, PWM_synch, OVR_I_blank_n;

logic [10:0] cnt;

assign PWM_synch = &cnt; // Synch signal, tests for max value
assign OVR_I_blank_n = cnt > 255; // Blanking signal

//flipflop for PWM signal
always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    PWM_sig <= 1'b0; // asynch reset
  else if (cnt >= duty)
    PWM_sig <= 1'b0; // R reset signal asserted
  else if (~|cnt)
    PWM_sig <= 1'b1; // S signal asserted

//cnt increment
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    cnt <= 8'h00;
  else
    cnt <= cnt + 1; // combinational increment of cnt

endmodule

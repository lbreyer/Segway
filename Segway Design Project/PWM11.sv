module PWM11(clk, rst_n, duty, PWM_sig, PWM_synch, OVR_I_blank_n);

input [10:0] duty;
input clk, rst_n;

output reg PWM_sig, PWM_synch, OVR_I_blank_n;

logic [10:0] cnt;

//sr_ff iSR(.clk(clk), .S(cnt_all_zeros), .R(R), .rst_n(rst_n), .q(PWM_sig)); // SR FF
//iq_cnt iCNT(.clk(clk), .rst_n(rst_n), .cnt(cnt)); // Counter

//assign cnt_all_zeros = ~|cnt; // Test if cnt = 11'h000
//assign R = cnt >= duty; // Reset signal test for SR FF

assign PWM_synch = &cnt; // Synch signal, tests for max value
assign OVR_I_blank_n = cnt > 255; // Blanking signal

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    PWM_sig <= 1'b0; // asynch reset
  else if (cnt >= duty)
    PWM_sig <= 1'b0; // R reset signal asserted
  else if (~|cnt)
    PWM_sig <= 1'b1; // S signal asserted

always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    cnt <= 8'h00;
  else
    cnt <= cnt + 1; // combinational increment of cnt

endmodule


/*module sr_ff(clk, S, R, rst_n, q);

input clk, S, R, rst_n;
output reg q;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    q <= 1'b0; // asynch reset
  else if (R)
    q <= 1'b0; // R reset signal asserted
  else if (S)
    q <= 1'b1; // S signal asserted

endmodule 

module iq_cnt(clk, rst_n, cnt);

input clk, rst_n;

output [10:0] cnt;

reg [10:0] cnt;

always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    cnt <= 8'h00;
  else
    cnt <= cnt + 1; // combinational increment of cnt

endmodule*/

module balance_cntrl #(parameter fast_sim = 1) (clk, rst_n, vld, ptch, ptch_rt, pwr_up, rider_off, steer_pot, en_steer, lft_spd, rght_spd, too_fast);

input clk, rst_n, vld, pwr_up, rider_off, en_steer;
input [11:0] steer_pot;
input [15:0] ptch, ptch_rt;

output [11:0] lft_spd, rght_spd;
output reg too_fast;

reg [7:0] ss_tmr;
reg [11:0] PID_cntrl, PID_cntrl_t;
reg [15:0] ptch_t;
//reg too_fast_t;

// PID and Segway math component block
PID iPID (.clk(clk), .rst_n(rst_n), .vld(vld), .ptch(ptch), .ptch_rt(ptch_rt), 
	.pwr_up(pwr_up), .rider_off(rider_off), .PID_cntrl(PID_cntrl_t), .ss_tmr(ss_tmr));
SegwayMath iSMATH(.clk(clk), .rst_n(rst_n), .PID_cntrl(PID_cntrl), .ss_tmr(ss_tmr), .steer_pot(steer_pot), .en_steer(en_steer), .pwr_up(pwr_up), .lft_spd(lft_spd), .rght_spd(rght_spd), .too_fast(too_fast));

/*always_ff @(negedge clk, negedge rst_n)
  if (!rst_n)
    ptch_f <= 16'h0000; // asynch preset
  else
    ptch_f <= ptch;    // hold value

always_ff @(negedge clk, negedge rst_n)
  if (!rst_n)
    ptch_rt_f <= 16'h0000; // asynch preset
  else
    ptch_rt_f <= ptch_rt;    // hold value*/

//assign ptch_f = rst_n ? ptch : 16'h0000;
//assign ptch_rt_f = rst_n ? ptch_rt : 16'h0000;

//extra flop on ptch_rt for max delay purposes
/*always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    ptch_rt_t <= 16'h0000;
  else
    ptch_rt_t <= ptch_rt;*/

//extra flop on too_fast for max delay purposes
/*always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    too_fast <= 1'b0;
  else
    too_fast <= too_fast_t;*/

//extra flop on ss_tmr for max delay purposes
/*always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    ss_tmr <= 8'h00;
  else
    ss_tmr <= ss_tmr_t;*/

//extra flop on PID_cntrl for max delay purposes
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    PID_cntrl <= 16'h0000;
  else
    PID_cntrl <= PID_cntrl_t;

endmodule;
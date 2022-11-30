module steer_en(clk, rst_n, lft_ld, rght_ld, en_steer, rider_off);

parameter fast_sim = 1'b1;

input clk, rst_n;
input logic signed [11:0] lft_ld, rght_ld;

output logic en_steer, rider_off;

logic [25:0] cnt;
logic signed [12:0] sum;
logic signed [11:0] diff, diff_abs;
logic sum_lt_min, sum_gt_min, diff_gt_1_4, diff_gt_15_16, tmr_full, clr_tmr;

localparam [9:0] MIN_RIDER_WT = 10'h200;
localparam [6:0] WT_HYSTERESIS = 7'h40;

steer_en_SM iSM(.clk(clk), .rst_n(rst_n), .tmr_full(tmr_full), .sum_gt_min(sum_gt_min), 
		.sum_lt_min(sum_lt_min), .diff_gt_1_4(diff_gt_1_4), .diff_gt_15_16(diff_gt_15_16), 
		.clr_tmr(clr_tmr), .en_steer(en_steer), .rider_off(rider_off));

assign sum = lft_ld + rght_ld;
assign diff = lft_ld - rght_ld;

assign sum_lt_min = sum < (MIN_RIDER_WT - WT_HYSTERESIS);
assign sum_gt_min = sum > (MIN_RIDER_WT + WT_HYSTERESIS);

assign diff_abs = diff[11] ? -diff : diff;
assign diff_gt_1_4 = diff_abs > sum[12:2];
assign diff_gt_15_16 = diff_abs > (sum - sum[12:4]);

assign tmr_full = fast_sim ? &cnt[14:0] : cnt >= 26'h3FE56C0;

// 1.34s timer
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    cnt <= 26'h0000000; // rst counter
  else if (clr_tmr)
    cnt <= 26'h0000000;
  else
    cnt <= cnt + 1'b1; 

endmodule

module balance_cntrl #(parameter fast_sim = 1) (clk, rst_n, vld, ptch, ptch_rt, pwr_up, rider_off, steer_pot, en_steer, lft_spd, rght_spd, too_fast);

input clk, rst_n, vld, pwr_up, rider_off, en_steer;
input [11:0] steer_pot;
input [15:0] ptch, ptch_rt;

output [11:0] lft_spd, rght_spd;
output too_fast;

logic [7:0] ss_tmr;
logic [11:0] PID_cntrl;

// PID and Segway math component block
PID iPID (.clk(clk), .rst_n(rst_n), .vld(vld), .ptch(ptch), .ptch_rt(ptch_rt), 
	.pwr_up(pwr_up), .rider_off(rider_off), .PID_cntrl(PID_cntrl), .ss_tmr(ss_tmr));
SegwayMath iSMATH(.PID_cntrl(PID_cntrl), .ss_tmr(ss_tmr), .steer_pot(steer_pot), .en_steer(en_steer), .pwr_up(pwr_up), .lft_spd(lft_spd), .rght_spd(rght_spd), .too_fast(too_fast));


endmodule;
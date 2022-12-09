//Team Gambling: Drew Tovar, Luke Breyer, Rago Senthilkumar, Johnny Palmumbo

module inertial_integrator(clk, rst_n, vld, ptch_rt, AZ, ptch);


////////////////////////////////
////inputs/outputs/localparams//
////////////////////////////////
input clk, rst_n;
input vld;
input signed [15:0] AZ, ptch_rt;

output signed [15:0] ptch;

localparam PTCH_RT_OFFSET = 16'h0050;
localparam signed AZ_OFFSET = 16'h00A0;

logic signed [15:0] AZ_comp;
logic [15:0] ptch_rt_comp;
logic [26:0] ptch_int;
logic [26:0] fusion_ptch_offset;
logic signed [15:0] ptch_acc;
logic signed [25:0] ptch_acc_product;
///////////////////////////////

assign AZ_comp = AZ - AZ_OFFSET;
assign ptch_rt_comp = ptch_rt - PTCH_RT_OFFSET;

assign ptch_acc_product = AZ_comp * $signed(327);	// 327 is fudge factor
assign ptch_acc = {{3{ptch_acc_product[25]}},ptch_acc_product[25:13]}; // pitch angle calculated from accel only

//flop flop for setting fusion ptch offset
always_ff @(posedge clk, negedge rst_n) begin
if(!rst_n) fusion_ptch_offset <= 0;
else if (ptch_acc > ptch) // if pitch calculated from accel > pitch calculated from gyro
	fusion_ptch_offset <= +1024;
else
	fusion_ptch_offset <= -1024;
end



//flip flop to assert vld
always_ff @(posedge clk, negedge rst_n) begin
if (!rst_n)
	ptch_int <= 0;
else if (vld)
	ptch_int <= ptch_int - {{11{ptch_rt_comp[15]}}, ptch_rt_comp} + fusion_ptch_offset;
end

assign ptch = ptch_int[26:11];

endmodule
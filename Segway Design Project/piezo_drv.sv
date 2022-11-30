module piezo_drv (clk, rst_n, en_steer, too_fast, batt_low, piezo, piezo_n);

parameter fast_sim = 1'b1;

input clk, rst_n, en_steer, too_fast, batt_low;
output logic piezo, piezo_n;

logic init, rpt;
logic [6:0] increment;
logic [14:0] prd_cntr, curr_prd;
logic [25:0] dur_cntr, curr_dur;
logic [27:0] rpt_cntr;

logic [2:0] state, nxt_state;
typedef enum reg [2:0] { IDLE, G6, C7, E7_1, G7_1, E7_2, G7_2} state_t;

localparam [27:0] repeat_const = 28'h8F0D180;
localparam [14:0] G6_prd = 15'h7C90;
localparam [22:0] G6_dur = 23'h7FFFFF; // TODO: Fix durations
localparam [14:0] C7_prd = 15'h5D51;
localparam [22:0] C7_dur = 23'h7FFFFF;
localparam [14:0] E7_prd = 15'h4A11;
localparam [22:0] E7_1_dur = 23'h7FFFFF;
localparam [22:0] E7_2_dur = 23'h3FFFFF;
localparam [14:0] G7_prd = 15'h3E48;
localparam [23:0] G7_1_dur = 24'hBFFFFF;
localparam [24:0] G7_2_dur = 25'h1FFFFFF;

generate if (fast_sim) begin
        assign increment = 7'h40;
   end else begin
        assign increment = 7'h001;
   end endgenerate

assign rpt = rpt_cntr >= repeat_const;

// Durration counter
always_ff @(posedge clk)
  if (!rst_n)
    dur_cntr <= 26'h0000000; // Init counter
  else if (init)
    dur_cntr <= 26'h0000000; // Init counter
  else
    dur_cntr <= dur_cntr + increment;

// Repeat Timer
always_ff @(posedge clk)
  if (!rst_n)
    rpt_cntr <= 28'h0000000; // Init counter
  else if (rpt)
    rpt_cntr <= 28'h0000000; // Init counter
  else
    rpt_cntr <= rpt_cntr + increment;

// Period Timer
always_ff @(posedge clk)
  if (!rst_n)
    prd_cntr <= 15'h0000; // Init counter
  else if (init)
    prd_cntr <= 15'h0000; // Init counter
  else if (prd_cntr >= curr_prd)
    prd_cntr <= 15'h0000;
  else
    prd_cntr <= prd_cntr + increment;

// State Control
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else 
    state <= nxt_state;

always_comb begin
  nxt_state = state;
  piezo = 1'b0;
  piezo_n = 1'b1;
  init = 1'b0;
  curr_prd = 1'b0;
  curr_dur = 1'b0;

  case (state)
    IDLE: begin
	  curr_prd = 1'b0;
	  curr_dur = 1'b0;
 	  if (too_fast) begin
	    init = 1'b1;
	    curr_prd = G6_prd;
	    curr_dur = G6_dur;
	    nxt_state = G6;
	  end
          else if (batt_low & rpt) begin
	    init = 1'b1;
	    curr_prd = G7_prd;
	    curr_dur = G7_2_dur;
            nxt_state = G7_2;
          end
	  else if (en_steer & rpt) begin
	    init = 1'b1;
	    curr_prd = G6_prd;
	    curr_dur = G6_dur;
            nxt_state = G6;
          end
          else nxt_state = IDLE;
        end
    G6: begin // G6 STATE 1
	curr_prd = G6_prd;
	curr_dur = G6_dur;
	piezo = prd_cntr < curr_prd / 2;
	piezo_n = ~piezo;
        if (batt_low & dur_cntr >= curr_dur) begin
          nxt_state = IDLE;
        end
	else if (dur_cntr >= curr_dur) begin
	  init = 1'b1;
	  curr_prd = C7_prd;
	  curr_dur = C7_dur;
	  nxt_state = C7;
        end
 	else nxt_state = G6;
       end
    C7: begin // C7 STATE 2
	curr_prd = C7_prd;
	curr_dur = C7_dur;
	piezo = prd_cntr < curr_prd / 2;
	piezo_n = ~piezo;
        if (batt_low & dur_cntr >= curr_dur) begin
	  init = 1'b1;
	  curr_prd = G6_prd;
	  curr_dur = G6_dur;
	  nxt_state = G6;
        end
	else if (dur_cntr >= curr_dur) begin
	  init = 1'b1;
	  curr_prd = E7_prd;
	  curr_dur = E7_1_dur;
	  nxt_state = E7_1;
        end
 	else nxt_state = C7;
       end
    E7_1: begin // E7 STATE 3
	curr_prd = E7_prd;
	curr_dur = E7_1_dur;
	piezo = prd_cntr < curr_prd / 2;
	piezo_n = ~piezo;
        if (too_fast & dur_cntr >= curr_dur) begin
	    init = 1'b1;
	    curr_prd = G6_prd;
	    curr_dur = G6_dur;
	    nxt_state = IDLE;
	end
        else if (batt_low & dur_cntr >= curr_dur) begin
	  init = 1'b1;
	  curr_prd = C7_prd;
	  curr_dur = C7_dur;
	  nxt_state = C7;
        end
	else if (dur_cntr >= curr_dur) begin
	  init = 1'b1;
	  curr_prd = G7_prd;
	  curr_dur = G7_1_dur;
	  nxt_state = G7_1;
        end
 	else nxt_state = E7_1;
       end
    G7_1: begin // G7 STATE 4
	curr_prd = G7_prd;
	curr_dur = G7_1_dur;
	piezo = prd_cntr < curr_prd / 2;
	piezo_n = ~piezo;
        if (batt_low & dur_cntr >= curr_dur) begin
	  init = 1'b1;
	  curr_prd = E7_prd;
	  curr_dur = E7_1_dur;
	  nxt_state = E7_1;
        end
	else if (dur_cntr >= curr_dur) begin
	  init = 1'b1;
	  curr_prd = E7_prd;
	  curr_dur = E7_2_dur;
	  nxt_state = E7_2;
        end
 	else nxt_state = G7_1;
       end
    E7_2: begin // E7 STATE 5
	curr_prd = E7_prd;
	curr_dur = E7_2_dur;
	piezo = prd_cntr < curr_prd / 2;
	piezo_n = ~piezo;
        if (batt_low & dur_cntr >= curr_dur) begin
	  init = 1'b1;
	  curr_prd = G7_prd;
	  curr_dur = G7_1_dur;
	  nxt_state = G7_1;
        end
	else if (dur_cntr >= curr_dur) begin
	  init = 1'b1;
	  curr_prd = G7_prd;
	  curr_dur = G7_2_dur;
	  nxt_state = G7_2;
        end
 	else nxt_state = E7_2;
       end
    G7_2: begin // G7 STATE 6
	curr_prd = G7_prd;
	curr_dur = G7_2_dur;
	piezo = prd_cntr < curr_prd / 2;
	piezo_n = ~piezo;
        if (batt_low & dur_cntr >= curr_dur) begin
	  init = 1'b1;
	  curr_prd = E7_prd;
	  curr_dur = E7_2_dur;
	  nxt_state = E7_2;
        end
	else if (dur_cntr >= curr_dur) begin
	  nxt_state = IDLE;
        end
 	else nxt_state = G7_2;
       end
    default: nxt_state = IDLE;
    endcase
end



endmodule

module A2D_intf(clk, rst_n, nxt, lft_ld, rght_ld, steer_pot, batt, SS_n, SCLK, MOSI, MISO);

input clk, rst_n, nxt, MISO;

output logic SS_n, SCLK, MOSI;
output reg [11:0] lft_ld, rght_ld, steer_pot, batt;

logic wrt, done, cnt, update;
logic [1:0] state, nxt_state, rr_cntr;
logic [2:0] channel;
logic [15:0] wt_data, rd_data;

typedef enum reg [1:0] { IDLE, SPI1, DEAD, SPI2} state_t;

SPI_mnrch iSPI(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), 
	.wrt(wrt), .wt_data(wt_data), .done(done), .rd_data(rd_data));


assign wt_data = {2'b00,channel[2:0],11'h000};
assign channel = rr_cntr == 2'b00 ? 3'b000 : rr_cntr == 2'b01 ? 3'b100 : rr_cntr == 2'b10 ? 3'b101 : 3'b110;
assign lft_ld = update & (rr_cntr == 2'b00) ? rd_data[11:0] : lft_ld;
assign rght_ld = update & (rr_cntr == 2'b01) ? rd_data[11:0] : rght_ld;
assign steer_pot = update & (rr_cntr == 2'b10) ? rd_data[11:0] : steer_pot;
assign batt = update & (rr_cntr == 2'b11) ? rd_data[11:0] : batt;

// Round Robin Counter
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    rr_cntr <= 2'b00; // Load counter
  else if (cnt)
    rr_cntr <= rr_cntr + 2'b01; 

// State Control
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else 
    state <= nxt_state;

always_comb begin
  nxt_state = state;
  wrt = 1'b0;
  cnt = 1'b0;
  update = 1'b0;

  case (state)
    IDLE: begin
          if (nxt) begin
	    wrt = 1'b1;
            nxt_state = SPI1;
          end
          else nxt_state = IDLE;
        end
    SPI1: begin
             if (done) begin
	       nxt_state = DEAD;
	     end
 	     else nxt_state = SPI1;
            end
    DEAD: begin
            if (SCLK) begin
	      wrt = 1'b1;
	      nxt_state = SPI2;
	    end
            else nxt_state = DEAD;
           end
    SPI2: begin
             if (done) begin
	       update = 1'b1;
	       cnt = 1'b1;
	       nxt_state = IDLE;
	     end
 	     else nxt_state = SPI2;
            end
    endcase
end



endmodule

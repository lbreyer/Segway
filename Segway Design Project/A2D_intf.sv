module A2D_intf(clk, rst_n, nxt, lft_ld, rght_ld, steer_pot, batt, SS_n, SCLK, MOSI, MISO);

input clk, rst_n, nxt, MISO; // Clock, active low asynch reset, next operation, and mstr. in s out signals

output logic SS_n, SCLK, MOSI;
output reg [11:0] lft_ld, rght_ld, steer_pot, batt;

// Intermediary signals
logic wrt, done, cnt, update;
logic [1:0] state, nxt_state, rr_cntr;
logic [2:0] channel;
logic [15:0] wt_data, rd_data;

typedef enum reg [1:0] { IDLE, SPI1, DEAD, SPI2} state_t;

SPI_mnrch iSPI(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), 
	.wrt(wrt), .wt_data(wt_data), .done(done), .rd_data(rd_data));


assign wt_data = {2'b00,channel[2:0],11'h000};
assign channel = rr_cntr == 2'b00 ? 3'b000 : rr_cntr == 2'b01 ? 3'b100 : rr_cntr == 2'b10 ? 3'b101 : 3'b110;

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

// lf_ld
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    lft_ld <= 12'h000;
  else if (update & (rr_cntr == 2'b00))
    lft_ld <= rd_data[11:0];

// rght_ld
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    rght_ld <= 12'h000;
  else if (update & (rr_cntr == 2'b01))
    rght_ld <= rd_data[11:0];

// steer_pot
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    steer_pot <= 12'h000;
  else if (update & (rr_cntr == 2'b10))
    steer_pot <= rd_data[11:0];

// state machine area stuff for a2d
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    batt <= 12'h000;
  else if (update & (rr_cntr == 2'b11))
    batt <= rd_data[11:0];
// beginning of SM
always_comb begin
  nxt_state = state;
  wrt = 1'b0; // Default outputs
  cnt = 1'b0;
  update = 1'b0;
  
  case (state)
    IDLE: begin
          if (nxt) begin // When next signal asserted, begin SPI transaction 1
	    wrt = 1'b1;
            nxt_state = SPI1;
          end
          else nxt_state = IDLE; // Wait for next opperation
        end
    SPI1: begin
             if (done) begin // At the end of the SPI 1 transaction, wait a clock
	       nxt_state = DEAD;
	     end
 	     else nxt_state = SPI1;
            end
    DEAD: begin
            if (SCLK) begin //wait for SCLK to transition
	      wrt = 1'b1;
	      nxt_state = SPI2;
	    end
            else nxt_state = DEAD;
           end
    SPI2: begin
             if (done) begin // At the end of the second SPI transation, signal completion and wait for next
	       update = 1'b1;
	       cnt = 1'b1;
	       nxt_state = IDLE;
	     end
 	     else nxt_state = SPI2;
            end
    endcase
end



endmodule

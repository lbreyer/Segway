module SPI_mnrch(clk, rst_n, SS_n, SCLK, MOSI, MISO, wrt, wt_data, done, rd_data);

input clk, rst_n, MISO, wrt; // Clock, active low asynch reset, mast. in s out, write enable signal
input [15:0] wt_data; // Data to write

output logic SS_n, SCLK, MOSI, done; // Active low SS, SCLK clock, mast. out s in, and transaction done signals
output logic [15:0] rd_data; // Read data output

// Intermediarry signals
logic ld_SCLKl, smpl, shft, MISO_smpl, init, done15, ld_SCLK, set_done;
logic [1:0] state, nxt_state;
logic [3:0] SCLK_div, bit_cntr;

typedef enum reg [1:0] { IDLE, F_PORCH, ACTIVE, B_PORCH} state_t;


assign SCLK = SCLK_div[3]; // SCLK high conditional
assign smpl = SCLK_div == 4'b0111; // Check for sampling condition
assign MOSI = rd_data[15]; // MOSI output signal

// SCLK clk
always_ff @(posedge clk)
  if (ld_SCLK)
    SCLK_div <= 4'b1011; // Load clk
  else 
    SCLK_div <= SCLK_div + 4'h1;

// Shift Register
always_ff @(posedge clk)
  if (smpl)
    MISO_smpl <= MISO; // Store sample

// Read data rotational flop
always_ff @(posedge clk)
  if (init)
    rd_data <= wt_data; // initialize to write data
  else if (shft)
    rd_data <= {rd_data[14:0],MISO_smpl}; // If shift in next bit

// Bit counter
always_ff @(posedge clk)
  if (init)
    bit_cntr <= 4'b0000; // Init counter
  else if (shft) 
    bit_cntr <= bit_cntr + 4'h1;

// Output Flip Flops
always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) begin
    SS_n <= 1'b1; // Reset high
  end
  else if (init) begin
    SS_n <= 1'b0; // initialize low
  end
  else if (set_done) begin
    SS_n <= 1'b1; // Return high when done
  end

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) begin
    done <= 1'b0;
  end
  else if (init) begin
    done <= 1'b0;
  end
  else begin
    done <= set_done; // Done output of state machine
  end
 
// State Control
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else 
    state <= nxt_state;

// State machine logic
always_comb begin
  nxt_state = IDLE;
  set_done = 1'b0; // Default outputs
  init = 1'b0;
  ld_SCLK = 1'b0;
  shft = 1'b0;

  case (state)
    IDLE: begin
	  ld_SCLK = 1'b1; // Hold SCLK high while idle
          shft = 1'b0;
          if (wrt) begin // When write signal recieved, begin transaction
            init = 1'b1;
            nxt_state = F_PORCH;
          end
          else nxt_state = IDLE; // Wait for write signal
        end
    F_PORCH: begin
             if (smpl) begin // After first sample, move to active state
	       nxt_state = ACTIVE;
	     end
 	     else nxt_state = F_PORCH;
            end
    ACTIVE: begin
	    shft = SCLK_div == 4'b1111; // Check shift condition
            if (&bit_cntr) begin // If bit counter is full, transaction is conculding move to back porch
	      nxt_state = B_PORCH;
	    end
            else nxt_state = ACTIVE;
           end
    B_PORCH: begin
             if (SCLK_div == 4'b1111) begin // Set B_Porch final conds
               shft = 1'b1;
               ld_SCLK = 1'b1; // Hold SCLK
               set_done = 1'b1;
	       nxt_state = IDLE;
	     end
 	     else nxt_state = B_PORCH;
            end
    endcase
end

endmodule

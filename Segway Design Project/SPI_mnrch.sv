module SPI_mnrch(clk, rst_n, SS_n, SCLK, MOSI, MISO, wrt, wt_data, done, rd_data);

input clk, rst_n, MISO, wrt;
input [15:0] wt_data;

output logic SS_n, SCLK, MOSI, done;
output logic [15:0] rd_data;

logic ld_SCLKl, smpl, shft, MISO_smpl, init, done15, ld_SCLK, set_done;
logic [1:0] state, nxt_state;
logic [3:0] SCLK_div, bit_cntr;
//logic [15:0] shft_reg;

typedef enum reg [1:0] { IDLE, F_PORCH, ACTIVE, B_PORCH} state_t;

// SCLK clk
always_ff @(posedge clk)
  if (ld_SCLK)
    SCLK_div <= 4'b1011; // Load clk
  else 
    SCLK_div <= SCLK_div + 4'h1; 

assign SCLK = SCLK_div[3];
assign smpl = SCLK_div == 4'b0111; // Check for sampling condition

// Shift Register
always_ff @(posedge clk)
  if (smpl)
    MISO_smpl <= MISO; // Store sample

always_ff @(posedge clk)
  if (init)
    rd_data <= wt_data;
  else if (shft)
    rd_data <= {rd_data[14:0],MISO_smpl}; // If shift in next bit

//assign rd_data = shft_reg;
assign MOSI = rd_data[15];

// Bit counter
always_ff @(posedge clk)
  if (init)
    bit_cntr <= 4'b0000; // Init counter
  else if (shft) 
    bit_cntr <= bit_cntr + 4'h1;

// Output Flip Flops
always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) begin
    SS_n <= 1'b1;
  end
  else if (init) begin
    SS_n <= 1'b0;
  end
  else if (set_done) begin
    SS_n <= 1'b1;
  end

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n) begin
    done <= 1'b0;
  end
  else if (init) begin
    done <= 1'b0;
  end
  //else if (set_done) begin
  //  done <= 1'b1;
  else begin
    done <= set_done;
  end
 
// State Control
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else 
    state <= nxt_state;

always_comb begin
  nxt_state = IDLE;
  set_done = 1'b0;
  init = 1'b0;
  ld_SCLK = 1'b0;

  case (state)
    IDLE: begin
	  ld_SCLK = 1'b1; // Hold SCLK
          shft = 1'b0;
          if (wrt) begin
            init = 1'b1;
            nxt_state = F_PORCH;
          end
          else nxt_state = IDLE;
        end
    F_PORCH: begin
             if (smpl) begin
	       nxt_state = ACTIVE;
	     end
 	     else nxt_state = F_PORCH;
            end
    ACTIVE: begin
	    shft = SCLK_div == 4'b1111; // Check shift condition
            if (&bit_cntr) begin
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

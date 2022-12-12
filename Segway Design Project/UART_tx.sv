module UART_tx(clk, rst_n, TX, trmt, tx_data, tx_done);

input clk, rst_n, trmt; // transmit enable signal
input [7:0] tx_data; // tx data line

output reg TX, tx_done; // transaction tx complete and TX line signals

// Intermediary signals
logic shift, init, trans, set_done, state, nxt_state;
logic [3:0] bit_cnt;
logic [8:0] data, shft_reg;
logic [11:0] baud_cnt;

typedef enum reg { IDLE, ACTIVE} state_t;

// Shifter Logic
assign data = {tx_data, 1'b0};
assign TX = shft_reg[0];

// Counter Logic
assign shift = baud_cnt == 12'hA2C;
assign cnt_rst = init | shift;

// Shift Counter
always_ff @(posedge clk)
  if (init)
    bit_cnt <= 4'h0; // Init to zeros
  else if (shift)
    bit_cnt <= bit_cnt + 1; // combinational increment of cnt

// Baud Counter
always_ff @(posedge clk)
  if (cnt_rst)
    baud_cnt <= 12'h000; // cnt reset
  else if (trans)
    baud_cnt <= baud_cnt + 1; // combinational increment of cnt

// State FF
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else 
    state <= nxt_state;

// Shifter Flip Flop
always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    shft_reg <= 9'h1FF; // asynch reset
  else if (init)
    shft_reg <= data; // value init
  else if (shift) 
    shft_reg <= {1'b1, shft_reg[8:1]};    // conditionally enabled

// Done SR Flip Flop
always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    tx_done <= 1'b0; // asynch reset
  else if (init)
    tx_done <= 1'b0; // R reset signal asserted
  else if (set_done)
    tx_done <= 1'b1; // S signal asserted
  
// Comb state logic
always_comb begin
  nxt_state = IDLE;
  set_done = 1'b0; // Default outputs
  init = 1'b0;
  trans = 1'b0;
  set_done = 1'b0;
  
  case (state)
    IDLE: if (trmt) begin // On transmit begin signal, begin transaction
            trans = 1'b1;
            init = 1'b1;
            nxt_state = ACTIVE;
          end
          else nxt_state = IDLE; // Wait for transmission
    ACTIVE: begin
          init = 1'b0;
	  trans = 1'b1;
          if (bit_cnt == 4'hA) begin // Bit count full, signal end of transaction and await next
            trans = 1'b0;
            set_done = 1'b1;
            nxt_state = IDLE;
          end
          else nxt_state = ACTIVE;
        end
    default: nxt_state = IDLE;
  endcase
end

endmodule
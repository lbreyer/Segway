module UART_rx(clk, rst_n, RX, clr_rdy, rx_data, rdy);

input clk, rst_n, RX, clr_rdy;

output reg [7:0] rx_data; // rx data line
output reg rdy; // Signal module operation ready

// Intermediary Signals
logic shift, start, receiving, set_rdy, state, nxt_state, RX_meta, RX_metaT;
logic [3:0] bit_cnt;
logic [8:0] rx_shft_reg;
logic [12:0] baud_cnt;

typedef enum reg { IDLE, ACTIVE} state_t;

// Shifter Logic
assign rx_data = rx_shft_reg[7:0];

// Counter Logic
assign shift = ~|baud_cnt;

// Metastability FF
always_ff @(posedge clk)
  if (clr_rdy) begin
    RX_metaT <= 1'b1;
    RX_meta <= 1'b1;
  end
  else begin
    RX_metaT <= RX;
    RX_meta <= RX_metaT;
  end

// Baud Counter
always_ff @(posedge clk)
  if (start)
    baud_cnt <= 13'h0516; // Baud preset to half
  else if (shift)
    baud_cnt <= 13'h0A2C; // Baud full preset
  else if (receiving)
    baud_cnt <= baud_cnt - 1; // combinational decrement of cnt

// Shift Counter
always_ff @(posedge clk)
  if (start)
    bit_cnt <= 4'h0; // Init to zeros
  else if (shift)
    bit_cnt <= bit_cnt + 1; // combinational increment of cnt

// Shifter Flip Flop
always_ff @(posedge clk)
  if (shift)
    rx_shft_reg <= {RX_meta, rx_shft_reg[8:1]}; // Meta shift

// Done SR Flip Flop
always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    rdy <= 1'b0; // asynch reset
  else if (clr_rdy)
    rdy <= 1'b0; // clr reset signal asserted
  else if (start)
    rdy <= 1'b0; // start signal asserted
  else if (set_rdy)
    rdy <= 1'b1;    // set ready

// State FF
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else 
    state <= nxt_state;

// State Machine logic
always_comb begin
  nxt_state = IDLE;
  set_rdy = 1'b0; // Default outputs
  start = 1'b0;
  receiving = 1'b0;
  
  case (state)
    IDLE: if (~RX) begin // Begin transaction on RX line low
            receiving = 1'b1;
            start = 1'b1;
            nxt_state = ACTIVE;
          end
          else nxt_state = IDLE; // Wait for start signal
    ACTIVE: begin
          start = 1'b0;
	  receiving = 1'b1;
          if (bit_cnt == 4'hA) begin // Bit count full
            receiving = 1'b0;
            set_rdy = 1'b1;
            nxt_state = IDLE;
          end
          else nxt_state = ACTIVE;
        end
    default: nxt_state = IDLE;
  endcase
end

endmodule
module Auth_blk(clk, rst_n, RX, rider_off, pwr_up);

input clk, rst_n, RX, rider_off; // Clock, active low asynch reset, RX bit, and rider off of segway signals
output logic pwr_up; // Signal representing the power state

// Intermediary signals
logic [7:0] rx_data;
logic clr_rdy, rdy;
logic [1:0] state, nxt_state;

// Command constants
localparam g = 8'h67; // GO comand
localparam s = 8'h73; // STOP command

typedef enum reg [1:0] { IDLE, PWR1, PWR2 } state_t;

// UART_rx Block
UART_rx iUARTrx(.clk(clk), .rst_n(rst_n), .RX(RX), .clr_rdy(clr_rdy), .rx_data(rx_data), .rdy(rdy));


// State ff
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else 
    state <= nxt_state;
  
// auth_SM logic
always_comb begin
  nxt_state = IDLE;
  pwr_up = 1'b0; // Default output signals
  clr_rdy = 1'b0;
  
  case (state)
    IDLE: if (rdy & rx_data == g) begin // If go signal recieved, power up segway
            pwr_up = 1'b1;
            clr_rdy = 1'b1;
            nxt_state = PWR1;
          end
          else nxt_state = IDLE; // Wait for go signal
    PWR1: begin
          pwr_up = 1'b1; // Power is always held high while holding PWR1
          if (rdy & rx_data == s) begin // If stop signal recieved, go to await rider off
            clr_rdy = 1'b1;
            nxt_state = PWR2;
          end
	  else if (rider_off & rdy & rx_data == s) begin // If rider is off and stop signal, stop
            clr_rdy = 1'b1;
	    pwr_up = 1'b0;
            nxt_state = IDLE;
          end
          else nxt_state = PWR1;
        end
    PWR2: begin
          pwr_up = 1'b1; // Power help high until rider steps off
          if (rider_off) begin // Rider steps off segway, stop
            pwr_up = 1'b0;
            nxt_state = IDLE;
          end
	  else if (rdy & rx_data == g) begin // Go signal recieved, reenter power mode
            clr_rdy = 1'b1;
            nxt_state = PWR1;
          end
          else nxt_state = PWR2;
        end
    default: nxt_state = IDLE;
  endcase
end

endmodule;

module UART_tx(clk, rst_n, TX, trmt, tx_data, tx_done);

input clk, rst_n, trmt;
input [7:0] tx_data;

output TX, tx_done;

logic shift, init, trans, set_done, state, nxt_state;
logic [3:0] bit_cnt;
logic [8:0] data, shft_reg;
logic [11:0] baud_cnt;

typedef enum reg { IDLE, ACTIVE} state_t;

shift_ff iFF1(.data(data), .clk(clk), .rst_n(rst_n), .init(init), .shift(shift), .shft_reg(shft_reg));
done_ff iFF2(.clk(clk), .set_done(set_done), .init(init), .rst_n(rst_n), .tx_done(tx_done));
bd_cnt iCNT1(.clk(clk), .cnt_rst(cnt_rst), .trans(trans), .cnt(baud_cnt));
shft_cnt iCNT2(.clk(clk), .init(init), .shift(shift), .bit_cnt(bit_cnt));

// Shifter Logic
assign data = {tx_data, 1'b0};
assign TX = shft_reg[0];

// Counter Logic
assign shift = baud_cnt == 12'hA2C;
assign cnt_rst = init | shift;

// State FF
always_ff @(posedge clk or negedge rst_n)
  if (!rst_n)
    state <= IDLE;
  else 
    state <= nxt_state;
  
// Comb state logic
always_comb begin
  nxt_state = IDLE;
  set_done = 1'b0;
  
  case (state)
    IDLE: if (trmt) begin
            trans = 1'b1;
            init = 1'b1;
            nxt_state = ACTIVE;
          end
          else nxt_state = IDLE;
    ACTIVE: begin
          init = 1'b0;
          if (bit_cnt == 4'hA) begin
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


// Baud Counter
module bd_cnt(clk, cnt_rst, trans, cnt);

input clk, cnt_rst, trans;

output [11:0] cnt;

reg [11:0] cnt;

always_ff @(posedge clk)
  if (cnt_rst)
    cnt <= 12'h000; // cnt reset
  else if (trans)
    cnt <= cnt + 1; // combinational increment of cnt

endmodule


// Shift Counter
module shft_cnt(clk, init, shift, bit_cnt);

input clk, init, shift;

output reg [3:0] bit_cnt;


always_ff @(posedge clk)
  if (init)
    bit_cnt <= 4'h0; // Init to zeros
  else if (shift)
    bit_cnt <= bit_cnt + 1; // combinational increment of cnt

endmodule


// Shifter Flip Flop
module shift_ff(data, clk, rst_n, init, shift, shft_reg);

input [8:0] data;
input clk, init, shift, rst_n;

output reg [8:0] shft_reg;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    shft_reg <= 9'h1FF; // asynch reset
  else if (init)
    shft_reg <= data; // value init
  else if (shift) 
    shft_reg <= {1'b1, shft_reg[8:1]};    // conditionally enabled

endmodule


// Done SR Flip Flop
module done_ff(clk, set_done, init, rst_n, tx_done);

input clk, set_done, init, rst_n;
output reg tx_done;

always_ff @(posedge clk, negedge rst_n)
  if (!rst_n)
    tx_done <= 1'b0; // asynch reset
  else if (init)
    tx_done <= 1'b0; // R reset signal asserted
  else if (set_done)
    tx_done <= 1'b1; // S signal asserted

endmodule  
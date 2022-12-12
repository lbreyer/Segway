module rst_synch(RST_n, clk, rst_n);

input RST_n, clk;
output reg rst_n;

logic temp;

always_ff @(negedge clk, negedge RST_n)
  if (!RST_n)
    temp <= 1'b0; // asynch reset
  else
    temp <= 1'b1;    // hold value

//double flopped for metastability
always_ff @(negedge clk, negedge RST_n)
  if (!RST_n)
    rst_n <= 1'b0; // asynch reset
  else
    rst_n <= temp;    // hold value

endmodule 
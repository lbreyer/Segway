module rst_synch(RST_n, clk, rst_n);

input RST_n, clk;
output reg rst_n;

logic temp;

//asynch_rst_ff iFF1(.d(1'b1), .clk(clk), .rst_n(RST_n), .q(temp));
//asynch_rst_ff iFF2(.d(temp), .clk(clk), .rst_n(RST_n), .q(rst_n));

always_ff @(negedge clk, negedge RST_n)
  if (!RST_n)
    temp <= 1'b0; // asynch reset
  else
    temp <= 1'b1;    // hold value

always_ff @(negedge clk, negedge RST_n)
  if (!RST_n)
    rst_n <= 1'b0; // asynch reset
  else
    rst_n <= temp;    // hold value

endmodule 


/*module asynch_rst_ff(d, clk, rst_n, q);
input d, clk, rst_n;
output reg q;
always_ff @(negedge clk, negedge rst_n)
  if (!rst_n)
    q <= 1'b0; // asynch reset
  else
    q <= d;    // hold value
endmodule*/ 
module inert_intf(clk,rst_n,ptch,ptch_rt,vld,SS_n,SCLK,
                  MOSI,MISO,INT);
 
  parameter fast_sim = 1;
 
  input clk, rst_n;
  input MISO;					// SPI input from inertial sensor
  input INT;					// goes high when measurement ready
  
  output signed [15:0] ptch;	// fusion corrected pitch
  output signed [15:0] ptch_rt;
  output reg vld;				// goes high for 1 clock when new outputs available
  output SS_n,SCLK,MOSI;		// SPI outputs
 

  ////////////////////////////////////////////
  // Declare any needed internal registers //
  //////////////////////////////////////////
  reg [15:0] timer;
  reg [7:0] AZh,AZl;
  reg [7:0] ptch_rt_h,ptch_rt_l;
  reg INT_ff1,INT_ff2;
  
  //////////////////////////////////////
  // Outputs of SM are of type logic //
  ////////////////////////////////////
  logic [15:0] cmd;				// SPI command to inertial unit used for initialization
  logic wrt;					// wrt strobe to inertial sensor used during initialization
  logic clr_tmr;
  logic capture_ptchl,capture_ptchh;
  logic capture_AZl,capture_AZh;

  wire done;
  wire [15:0] inert_data;
  wire signed [15:0] ptch_rt_raw;	// prior to filter for spurious readings
  wire signed [15:0] AZ;
  
  
  ///////////////////////////////////////
  // Create enumerated type for state //
  /////////////////////////////////////
  typedef enum reg [3:0] {INIT1,INIT2,INIT3,INIT4,WAIT,PTCHL,PTCHH,
                          AZL,AZH} state_t;
  
  state_t state,nxt_state;
  
  ///////////////////////////////////////////////////////////
  // Instantiate SPI master for Inertial Sensor interface //
  /////////////////////////////////////////////////////////
  SPI_mnrch iSPI(.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),
                  .MISO(MISO),.MOSI(MOSI),.wrt(wrt),.done(done),
				  .rd_data(inert_data),.cmd(cmd));
				  
  ////////////////////////////////////////////////////////////////////
  // Instantiate Angle Engine that takes in angular rate readings  //
  // and acceleration info and produces ptch,roll, & yaw readings //
  /////////////////////////////////////////////////////////////////
  inertial_integrator iINT(.clk(clk), .rst_n(rst_n), .vld(vld),
                           .ptch_rt(ptch_rt), .AZ(AZ), .ptch(ptch));

  /////////////////////////////////////////
  // Double Flop INT for meta-stability //
  ///////////////////////////////////////
  always_ff @(posedge clk,negedge rst_n)
    if (!rst_n) begin
	  INT_ff1 <= 1'b0;
	  INT_ff2 <= 1'b0;
	end else begin
	  INT_ff1 <= INT;
	  INT_ff2 <= INT_ff1;
	end
	  
  ////////////////////////
  // Infer state flops //
  //////////////////////
  always_ff @(posedge clk,negedge rst_n)
    if (!rst_n)
	  state <= INIT1;
	else
	  state <= nxt_state;
	  
  //////////////////////////
  // Create 16-bit timer //
  ////////////////////////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
	   timer <= 0;
	 else if (clr_tmr)
	   timer <= 0;
	 else
	   timer <= timer + 1;
	  
  always_comb begin
    clr_tmr = 0;
    cmd = 16'hxxxx;
    wrt = 0;				// internal wrt strobe to inertial sensor used during initialization
	capture_ptchl = 0;
	capture_ptchh = 0;
	capture_AZl = 0;
	capture_AZh = 0;
	vld = 0;
	nxt_state = INIT1;
	
	 case (state)
	   INIT1 : begin
	     cmd = 16'h0D02;		// Enable INT1 for Gyro inert_data ready
		  if (&timer) begin
		    wrt = 1;
		    nxt_state = INIT2;
		  end
	   end
	   INIT2 : begin
	     cmd = 16'h1053;		// Setup Accel for 208 Smpls/sec & +/- 2g, 50Hz filter
		  if (&timer[9:0]) begin
		    wrt = 1;
		    nxt_state = INIT3;
		  end else
		    nxt_state = INIT2;
	   end
	   INIT3 : begin
	     cmd = 16'h1150;		// Setup Gyro for 208 Smpls/sec & +/- 245 deg/sec
		  if (&timer[9:0]) begin
		    wrt = 1;
		    nxt_state = INIT4;
		  end else
		    nxt_state = INIT3;
	   end
	   INIT4 : begin
	     cmd = 16'h1460;		// Turn Rounding on
		  if (&timer[9:0]) begin
		    wrt = 1;
		    nxt_state = WAIT;
		  end else 
		    nxt_state = INIT4;
	   end
	   WAIT : begin			// waiting for INT (gyro data ready)
	     cmd = 16'hA200;		// read PTCH low next
	     if (INT_ff2) begin
		    wrt = 1;
		    clr_tmr = 1;
		    nxt_state = PTCHL;
		  end else
		    nxt_state = WAIT;
	   end
	   PTCHL : begin
	     cmd = 16'hA300;		// read PTCH high next
		  capture_ptchl = done;
		  if (&timer[9:0]) begin
		    wrt = 1;
		    nxt_state = PTCHH;
		  end else
		    nxt_state = PTCHL;
      end
	   PTCHH : begin
	     cmd = 16'hAC00;		// read AZ low next
		  capture_ptchh = done;
		  if (&timer[9:0]) begin
		    wrt = 1;
		    nxt_state = AZL;
		  end else
		    nxt_state = PTCHH;
      end
	   AZL : begin
	     cmd = 16'hAD00;		// read AZ high next
		  capture_AZl = done;
		  if (&timer[9:0]) begin
		    wrt = 1;
		    nxt_state = AZH;
		  end else
		    nxt_state = AZL;
      end
	   AZH : begin
		  capture_AZh = done;
		  if (&timer[9:0]) begin
		    vld = 1;
		    nxt_state = WAIT;
		  end else
		    nxt_state = AZH;
      end
	   default : begin
	  	  clr_tmr = 1;
	     nxt_state = INIT1;
	   end
	 endcase
  end
  
  always_ff @(posedge clk)
    if (capture_ptchl)
	  ptch_rt_l <= inert_data[7:0];

  always_ff @(posedge clk)
    if (capture_ptchh)
	  ptch_rt_h <= inert_data[7:0];

  always_ff @(posedge clk)
    if (capture_AZl)
	  AZl <= inert_data[7:0];

  always_ff @(posedge clk)
    if (capture_AZh)
	  AZh <= inert_data[7:0];	  
  
  assign AZ = {AZh,AZl};
  assign ptch_rt_raw = {ptch_rt_h,ptch_rt_l};
  
  generate if (fast_sim)
    assign ptch_rt = ptch_rt_raw;		// no filter needed in simulation
  else
    assign ptch_rt = (ptch_rt_raw>$signed(16'h1F00)) ? 16'h0000 :
                     (ptch_rt_raw<$signed(-16'h1F00)) ? -16'h0000 :
				     ptch_rt_raw;
  endgenerate
  
 
endmodule
	  
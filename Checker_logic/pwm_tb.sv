`timescale 1ns/1ns
module pwm_tb;
	logic 		clk_i;	//clocksignal
	logic 		rst_ni;	//active low reset
	logic 		write;	//write enable(when write=1, we can write in our registers)								
	logic  [7:0]    addr_i;	//address of registers coming from SweRV 										
	logic  [31:0]   wdata_i; // 32 bits instruction coming from SweRV-> write data																	
	logic  [31:0]  	rdata_o; //read data																								
  	logic         	o_pwm;	// output of PWM in the form of pulse (Channel 1)
	logic         	o_pwm_2; // output of PWM in the form of pulse (Channel 2)
	logic     	oe_pwm1;  //output enable pin (channel 1)
	logic     	oe_pwm2;  //output enable pin (channel 2)
	logic [31:0]	div;	//variable for storing value of divisor from wdata_i
	logic [31:0]	per;	//variable for storing value of period from wdata_i
	logic [31:0]	dc;		//variable for storing value of duty cycle from wdata_i
	
pwm pwm_dut(.*);

//Duty cycle is the on time of pwm pulse from total period
//divisor divides clock frequency, and pwm operates on divisor
//peeriod is the total time in which pulse will be created either high or low. when pulse is high it's on-time.

always begin	//clock generation block
    #10;
    clk_i=1'b0;
    #10;
    clk_i=1'b1;
end

//divisor can never be set 0, divisor clock won't be generated
//period can never be set 0, there will be no period
//duty cycle can never be greater than period

initial begin

	rst_ni = 1'b0;	
	write = 1'b0;	// must be low in the begining so that no garbage data writes on wdata_i

	@(posedge clk_i);
	rst_ni = 1'b1;	//enable reset(active low) to start operations
	write = 1'b1;	//when write is on values of wdata_i are assigned to registers according to addresses

	//divisor (channel 1)
	@(posedge clk_i);	
	addr_i = 8'd4;	//give address of divisor to write on it
	//wdata_i = 32'd2;
	wdata_i = $urandom_range(1,20);	//value of divisor is set here
	div = wdata_i;	//divisor value saved in div variable for checker logic

	//period (channel 1)
	@(posedge clk_i);
	addr_i = 8'd8;	//configure period
	//wdata_i = 32'd10;
	wdata_i = $urandom_range(1,20); // value of period is set here
	per = wdata_i;	//value of period is saved in per variable for checker logic

	//DC (channel 1)
	@(posedge clk_i);
	addr_i = 8'd12;	//configure duty cycle
	//wdata_i = 32'd6;
	wdata_i = $urandom_range(1,(per-32'd1));// value for Duty Cycle (must be lesser than period)
	dc = wdata_i; 	//duty cycle's value is saved in dc variable for checker logic

	// control (channel 1)
	@(posedge clk_i);
	addr_i = 8'd0;	//send addressof control at the end to enable channel
	wdata_i = 32'd7;	//send 7 to enable channel as all first three bitsof wdata_i are used for control logic
	
	@(posedge clk_i);
	write = 1'b0;			
end 

//////////////////// CHECKER LOGIC BLOCK ////////////////////////////

logic [31:0] 	counter = 0;	//counts original clock pulses
logic [31:0]	one_div = 0;	//tells how much original clock pulses the half pulse of divisor contains
logic [31:0]	total_div_clocks = 0; //tells how much original clock pulses 1 complete pulse of divisor contains
logic [31:0]	total_clocks = 0; //the numbers of original clocks in total period
logic [31:0]	on_time = 0;	// the number of original clocks in Duty Cycle(on-time of period)

always @ (posedge clk_i) begin 

	$display("The value of divisor is = ",div);	//printing value of randomly generated divisor 
	$display("The value of period is = ",per);	//printing value of randomly generated period 
	$display("The Duty Cycle is = ",dc);		//printing value of randomly generated Duty Cycle 
	
	one_div = 32'd1 * div;	// half pulse of divisor (one_div) = 1 x divisor
	total_div_clocks = one_div + one_div;  //1 complete pulse of divisor (total_div_clocks) =	one_div + one_div
	$display("The total number of original clocks in 1 complete pulse of divisor clock are = ",total_div_clocks);
	total_clocks = total_div_clocks * per;  //total original clocks calculated (total_clocks) = total_div_clocks x periods
	$display("The total number of original clocks in total divisor clocks according to ",per," periods  are = ",total_clocks);
	on_time = dc*total_div_clocks;  // original clocks in Duty cycle(on-time) = duty cycle * total_div_clocks
	$display("The total on_time is   = ",on_time);
	
	// counter for counting the original clock exactly after when the output enable signal gets high
	if (oe_pwm1) begin 
		counter <= counter + 32'd1;
	end
	
	//display text when counter gets equal to the clocks counted for on time and also finds pwm signal high
	if (counter == (on_time) && o_pwm == 1'b1) begin 
		$display("on-time is correct according to Duty cycle provided");
	end
	
	//display text when counter gets greater to the clocks counted for on time and lesser then total clocks calculated and also finds pwm signal low
	if (counter > (on_time) && counter < (total_clocks + 32'b1) && o_pwm == 1'b0) begin 
		$display("Off-time is correct according to Duty cycle provided");
	end
	
	//display text when counter equal to total clocks calculated 
	if (counter == total_clocks) begin
		$display("Total period is correct,with correct clock counts according to divider");
		$display("total original clocks counted by checker",counter);
		$stop;
	end
end
endmodule 
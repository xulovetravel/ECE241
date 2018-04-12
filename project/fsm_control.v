module control (
	input clk, rst,
	input [3:0] KEY,
	input SW, prepost,
	input [7:0] tol, cont, br,
	output reg loadbr, loadcont, loadtol, loadbackr, loadbackg, loadbackb, loadkey, fx,
	output reg LED,
	output reg [2:0] setbackled,
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
	);
	
	reg [3:0] current_state, next_state;
	reg [7:0] first, second, q;
	initial current_state = 0; // initializes the current state to S_R
	
	localparam S_R = 0;
	localparam S_BR = 1;
	localparam S_CONT = 13;
	localparam S_PREPOST = 14;
	localparam S_PREPOST_WAIT = 15;
	localparam S_TOLER = 4;
	localparam S_TRANS = 5;
	localparam S_RED = 6;
	localparam S_RED_WAIT = 7;
	localparam S_GREEN = 8;
	localparam S_GREEN_WAIT = 9;
	localparam S_BLUE = 10;
	localparam S_KEY_GREENSCREEN = 12;
	localparam S_GREENSCREEN = 2;
	localparam S_NORMAL = 3;
	localparam S_GREENSCREEN_COUNT = 11;
	
	always @(*) // case for pre and post, using clk for rising clock edge.
    begin
		if (SW) // when SW is in greenstate.
		begin
			first = 8'b00000000;
			second = 8'b00000000;
			q = tol; // value of post passes through to output q
	   end
	   else // when SW is in normal state.
		begin
			first = cont;
			second = br;
			q = prepost; // q is set to 0
		end
	end
	
	always@(*)
	begin
		case(current_state)
			S_R:
			begin
				if (SW)
					next_state = S_GREENSCREEN_COUNT; // go to greenscreen state
				else
					next_state = S_NORMAL; // Go to normal state
			end
			
			S_GREENSCREEN_COUNT:
			begin
				if (count == 270000) // wait 1/100s to prevent debouncing (arbitary but works)
					next_state = S_GREENSCREEN;
				else
					next_state = S_GREENSCREEN_COUNT;
			end
			
			S_NORMAL: 
			begin
				if (KEY[3])
					next_state = S_BR; // load brightness
				else if (KEY[2])
					next_state = S_CONT; // load contrast
				else if (KEY[1])
					next_state = S_PREPOST; // set prepost
				else
					next_state = S_R;
				//else if (SW)
				//	next_state = S_GREENSCREEN; // go to greenscreen state	
				//else
				//	next_state = S_NORMAL;
			end
			
			S_BR: next_state = S_NORMAL;
			S_CONT: next_state = S_NORMAL;
			S_PREPOST: next_state = S_PREPOST_WAIT;
			S_PREPOST_WAIT: next_state = KEY[1] ? S_PREPOST_WAIT : S_NORMAL;
			
	     	S_GREENSCREEN:
			begin
				if (KEY[3])
					next_state = S_KEY_GREENSCREEN; // set key colour for greenscreen.
				else if (KEY[2])
					next_state = S_TOLER; // set tolerance
				else if (KEY[1])
					next_state = S_RED; // set background colour
				else
					next_state = S_R;
				//else if (!SW)
				//	next_state = S_NORMAL; // go back to normal state
				//else
				//	next_state = S_GREENSCREEN;
			end
			
			S_TOLER: next_state = S_GREENSCREEN;
			//S_RED: next_state = S_GREENSCREEN;
			S_RED: next_state = KEY[1] ? S_RED : S_RED_WAIT; // have to release key first
       		S_RED_WAIT: next_state = KEY[1] ? S_GREEN : S_RED_WAIT; // pressed second time to set loadgreen
			S_GREEN: next_state = KEY[1] ? S_GREEN : S_GREEN_WAIT;
			S_GREEN_WAIT: next_state = KEY[1] ? S_BLUE : S_GREEN_WAIT; // pressed third time to set loadblue.
			S_BLUE: next_state = KEY[1] ? S_BLUE : S_GREENSCREEN;
			S_KEY_GREENSCREEN: next_state = S_GREENSCREEN;
			default:;
		endcase
	end
	
	always@(*)
	begin
		loadbr = 0;
		loadcont = 0;
		loadtol = 0;
		loadbackr = 0;
		loadbackg = 0;
		loadbackb = 0;
		loadkey = 0;
		fx = 0;
		setbackled[2:0] = 0;
		LED = 0;
		case(current_state)
			S_BR: loadbr = 1; // loads brightness
			S_CONT: loadcont = 1; // loads contrast
			S_TOLER: loadtol = 1; // loads tolerance
			S_GREENSCREEN_COUNT: LED = 1; // led turns on when i'm in greenstate state
			S_GREENSCREEN: LED = 1;
			S_RED:
			begin
				loadbackr = 1; // loads background colour
				setbackled[0] = 1; // leds show which state of loading i'm in
			end
			S_GREEN: 
			begin
				loadbackg = 1;
				setbackled[1] = 1;
			end
			S_BLUE:
			begin
				loadbackb = 1;
				setbackled[2] = 1;
			end
			S_KEY_GREENSCREEN: loadkey = 1; // loads key colour
			S_PREPOST: fx = 1; // sets fx pre/post toggle
			default:;
		endcase
	end
	
	integer count;
	initial count = 0;
	
	always@(posedge clk) // debouncer
	begin
		if (current_state == S_GREENSCREEN_COUNT)
			count <= count + 1;
		else if (current_state == S_GREENSCREEN)
			count <= 0;
	end

	always@(posedge clk)
	begin
		if (rst)
			current_state <= 0;
		else
			current_state <= next_state;
	end
		
Seg7display u0 (
.c0(first[3]), // assign port SW[0] to port x
.c1(first[2]), // assign port SW[1] to port y
.c2(first[1]), // assign port SW[9] to port s
.c3(first[0]), // assign port LEDR[0] to port m
.a(HEX0[0]), // assign port SW[0] to port x
.b(HEX0[1]), // assign port SW[1] to port y
.c(HEX0[2]), // assign port SW[9] to port s
.d(HEX0[3]), // assign port LEDR[0] to port m
.e(HEX0[4]), // assign port SW[1] to port y
.f(HEX0[5]), // assign port SW[9] to port s
.g(HEX0[6]) // assign port LEDR[0] to port m
);

Seg7display u1 (
.c0(first[7]), // assign port SW[0] to port x
.c1(first[6]), // assign port SW[1] to port y
.c2(first[5]), // assign port SW[9] to port s
.c3(first[4]), // assign port LEDR[0] to port m
.a(HEX1[0]), // assign port SW[0] to port x
.b(HEX1[1]), // assign port SW[1] to port y
.c(HEX1[2]), // assign port SW[9] to port s
.d(HEX1[3]), // assign port LEDR[0] to port m
.e(HEX1[4]), // assign port SW[1] to port y
.f(HEX1[5]), // assign port SW[9] to port s
.g(HEX1[6]) // assign port LEDR[0] to port m
);

Seg7display u2 (
.c0(second[3]), // assign port SW[0] to port x
.c1(second[2]), // assign port SW[1] to port y
.c2(second[1]), // assign port SW[9] to port s
.c3(second[0]), // assign port LEDR[0] to port m
.a(HEX2[0]), // assign port SW[0] to port x
.b(HEX2[1]), // assign port SW[1] to port y
.c(HEX2[2]), // assign port SW[9] to port s
.d(HEX2[3]), // assign port LEDR[0] to port m
.e(HEX2[4]), // assign port SW[1] to port y
.f(HEX2[5]), // assign port SW[9] to port s
.g(HEX2[6]) // assign port LEDR[0] to port m
);

Seg7display u3 (
.c0(second[7]), // assign port SW[0] to port x
.c1(second[6]), // assign port SW[1] to port y
.c2(second[5]), // assign port SW[9] to port s
.c3(second[4]), // assign port LEDR[0] to port m
.a(HEX3[0]), // assign port SW[0] to port x
.b(HEX3[1]), // assign port SW[1] to port y
.c(HEX3[2]), // assign port SW[9] to port s
.d(HEX3[3]), // assign port LEDR[0] to port m
.e(HEX3[4]), // assign port SW[1] to port y
.f(HEX3[5]), // assign port SW[9] to port s
.g(HEX3[6]) // assign port LEDR[0] to port m
);

Seg7display u4 (
.c0(q[3]), // assign port SW[0] to port x
.c1(q[2]), // assign port SW[1] to port y
.c2(q[1]), // assign port SW[9] to port s
.c3(q[0]), // assign port LEDR[0] to port m
.a(HEX4[0]), // assign port SW[0] to port x
.b(HEX4[1]), // assign port SW[1] to port y
.c(HEX4[2]), // assign port SW[9] to port s
.d(HEX4[3]), // assign port LEDR[0] to port m
.e(HEX4[4]), // assign port SW[1] to port y
.f(HEX4[5]), // assign port SW[9] to port s
.g(HEX4[6]) // assign port LEDR[0] to port m
);

Seg7display u5 (
.c0(q[7]), // assign port SW[0] to port x0
.c1(q[6]), // assign port SW[1] to port y
.c2(q[5]), // assign port SW[9] to port s
.c3(q[4]), // assign port LEDR[0] to port m
.a(HEX5[0]), // assign port SW[0] to port x
.b(HEX5[1]), // assign port SW[1] to port y
.c(HEX5[2]), // assign port SW[9] to port s
.d(HEX5[3]), // assign port LEDR[0] to port m
.e(HEX5[4]), // assign port SW[1] to port y
.f(HEX5[5]), // assign port SW[9] to port s
.g(HEX5[6]) // assign port LEDR[0] to port m
);

	  

	
endmodule

module Seg7display(c0,c1,c2,c3,a,b,c,d,e,f,g);
input c0,c1,c2,c3;
output a,b,c,d,e,f,g;
assign a=~((c0|~c1|c2|c3) &(c0|c1|c2|~c3)& (~c0|~c1|c2|~c3)& (~c0|c1|~c2|~c3));
assign b= ~((~c0|~c1|c2|c3) &(c0|~c1|c2|~c3)& (~c0|~c1|~c2|~c3) &(~c0|c1|~c2|~c3)& (~c0|~c1|~c2|c3) & (c0|~c1|~c2|c3));
assign c= ~((~c0|~c1|c2|c3) &(~c0|~c1|~c2|~c3)& (~c0|~c1|~c2|c3) &(c0|c1|~c2|c3));
assign d= ~((c0|~c1|c2|c3) &(c0|c1|c2|~c3)& (c0|~c1|~c2|~c3) &(~c0|~c1|~c2|~c3)& (~c0|c1|~c2|c3));
assign e= ~((c0|c1|c2|~c3) &(c0|c1|~c2|~c3)& (c0|~c1|c2|~c3) &(c0|~c1|~c2|~c3)& (c0|~c1|c2|c3) & (~c0|c1|c2|~c3));
assign f= ~((c0|c1|~c2|~c3) &(c0|c1|c2|~c3)& (c0|c1|~c2|c3) &(c0|~c1|~c2|~c3)& (~c0|~c1|c2|~c3));
assign g= ~((c0|c1|c2|c3) &(c0|c1|c2|~c3)& (~c0|~c1|c2|c3) &(c0|~c1|~c2|~c3));
endmodule

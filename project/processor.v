module processor(clk, enable, rin, gin, bin, rkey, gkey, bkey, rback, gback, bback, tol, rvga, gvga, bvga);
	input clk, enable;
	input [7:0] rin, gin, bin, rkey, gkey, bkey, rback, gback, bback, tol;
	output [7:0] rvga, gvga, bvga;
	
	wire [8:0] tolg = tol + 10;
	reg [7:0] tolgout;
	always@(*)
	begin
		if (tolg > 255)
			tolgout = 255;
		else
			tolgout = tolg;
	end

	greenscreen r (clk, rin, rback, rkey, tol, enable, rvga);
	greenscreen g (clk, gin, gback, gkey, tolg, enable, gvga);
	greenscreen b (clk, bin, bback, bkey, tol, enable, bvga);

endmodule

module greenscreen (clk, in, back, key, tol, enable, out);
	input clk;
	input [7:0] in, back, key, tol;
	input enable;
	output reg [7:0] out;

	wire signed [8:0] check;
	reg signed [8:0] factor;
	reg [7:0] outwait;
	reg [31:0] shift_reg[13:0];
	reg [7:0] shift_reg2[50:0];
	wire [7:0] regout, mix, backint, inint;
	wire [31:0] factorf, tolf, intf, backf, ratio, ratiosub, ratio2, backmult, inmult;
	integer i, j;
	
	assign check = in - key; // 9-bit 2's complement, difference between input & key

	// take absolute value of check (= factor)
	always@(*)
	begin
		if (check[8] == 1) // check msb
			factor = -check;
		else
			factor = check;
	end

	always@(*)
	begin
		if (factor <= 10 && enable) // if it's really close do a direct replacement
		begin
			outwait = back;
			out = regout;
		end
		else if (factor > 10 && factor <= tol && enable) // greater than 5 but less than tolerance
		begin
			outwait = 0;
			out = mix;
		end
		else // keep everything as is
		begin
			outwait = in;
			out = regout;
		end
	end
	
	// algorithm is:
	// ratio = factor/tolerance
	// ratio is the amount of background mixed in
	// 1-ratio is the amount of original input mixed in
	// out = (ratio)(background) + (1-ratio)(input)
	
	// convert values to floating point (6 cycles)
	int2fp i1 (clk, factor, factorf);
	int2fp i2 (clk, tol, tolf);
	int2fp i3 (clk, in, inf);
	int2fp i4 (clk, back, backf);

	// floating point division (14 cycles, ratio = factorf/tolf)
	div d1 (clk, factorf, tolf, ratio);

	// perform subtraction (14 cycles, 1-ratio)
	sub s1 (clk, 32'b00111111100000000000000000000000, ratio, ratiosub); // that 32-bit string is in IEEE float

	// delay ratio by 14 cycles to match with subtraction (shift register)
	always@(posedge clk)
	begin
		shift_reg[0] <= ratio;
		for (i = 1; i < 14; i = i + 1)
			shift_reg[i] <= shift_reg[i-1];
	end
	assign ratio2 = shift_reg[13];

	// perform multiplication (11 cycles, backmult=ratio2*back and inmult=ratiosub*in)
	mult m1 (clk, ratio2, backf, backmult);
	mult m2 (clk, ratiosub, intf, inmult);

	// convert everything back to int and add them up (6 cycles)
	fp2int f1 (clk, backmult, backint);
	fp2int f2 (clk, inmult, inint);
	assign mix = backint + inint;

	// shift register so everything will match up
	// total delay = 51 cycles
	always@(posedge clk)
	begin
		shift_reg2[0] <= outwait;
		for (j = 1; j < 51; j = j + 1)
			shift_reg2[j] <= shift_reg2[j-1];
	end
	assign regout = shift_reg2[50];

endmodule
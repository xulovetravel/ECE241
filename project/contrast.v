// based on the algorithm found at http://www.dfstudios.co.uk/articles/programming/image-programming-algorithms/image-processing-algorithms-part-5-contrast-adjustment/
// (we converted and wrote it in verilog)

module contrast (rin,gin,bin,contrast,clk,rvga,gvga,bvga,clip);
	input [7:0] rin,gin,bin,contrast;
	input clk;
	output [7:0] rvga;
	output [7:0] gvga;
	output [7:0] bvga;
	output clip;

	integer a, b, c, d;
	wire [31:0] bf, df, f;

	// contrast correction factor
	// f = (259(contrast + 255))/((255)(259-contrast))
	// therefore f = b/d

	always@(*) // ints must be assigned in always block
	begin
		a = contrast+255;
		b = 259*a;
		c = 259-contrast;
		d = 255*c;
	end
	
	// all calculations will be done using single-precision floating point
	
	// transform b and d to float (6 cycles)
	int2fp i1 (clk, b, bf);
	int2fp i2 (clk, d, df);
	
	// floating point division (b/d, 14 cycles)
	div d1 (clk, bf, df, f);
	
	// contrast formula (as module)

	contrastcolours c1 (clk, f, rin, rvga, clipr);
	contrastcolours c2 (clk, f, gin, gvga, clipg);
	contrastcolours c3 (clk, f, bin, bvga, clipb);

	assign clip = clipr + clipg + clipb; // check for clipping and turn on clip LED

endmodule

module contrastcolours (
	input clk,
	input [31:0] f,
	input [7:0] rgb,
	output reg [7:0] colour,
	output reg clip
	);
	
	// colour = f(rgb - 128) + 128, where rgb is the current r, g, or b colour

	integer e, i;
	wire signed [31:0] g; // same as int (signed) but can be connected to modules
	wire [31:0] ef, ef2, gf;
	reg [31:0] shift_reg[13:0];
	
	always@(*)
		e = rgb - 128;

	// transform e to float
	int2fp i1 (clk, e, ef);

	// we need a shift register to slow down ef by 14 clock cycles (since it takes 14 cycles for b/d division)
	always@(posedge clk)
	begin
		shift_reg[0] <= ef;
		for (i = 1; i < 14; i = i + 1)
			shift_reg[i] <= shift_reg[i-1];
	end
	assign ef2 = shift_reg[13];

	// colour = f*ef2 + 128
	// do multiplication with f and ef2, 11 clock cycles
	mult m1 (clk, f, ef2, gf);

	// convert g back to int (by rounding it), 6 clock cycles
	// total 37 cycles
	fp2int f1 (clk, gf, g);

	// colour = g + 128
	always@(*)
	begin
		if ((g + 128) > 255)
		begin
			colour = 255; // prevent clipping
			clip = 1;
		end
		else if ((g + 128) < 0)
		begin
			colour = 0;
			clip = 1;
		end
		else
		begin
			colour = g + 128;
			clip = 0;
		end
	end

endmodule
	

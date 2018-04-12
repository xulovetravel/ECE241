module setkey(clk, set, rin, gin, bin, x, y, rkey, gkey, bkey);
	input clk, set;
	input [7:0] rin, gin, bin;
	input [10:0] x, y;
	output [7:0] rkey, gkey, bkey;

	reg [7:0] rPix[3:0], gPix[3:0], bPix[3:0];
	wire [7:0] rreg, greg, breg;
	reg load;
	reg [2:0] done;
	wire [9:0] r, g, b;

	initial
	begin
		done = 0;
	end

	always@(posedge clk)
	begin
		if (load)
		begin
			if (x == 319 && y == 239 && done == 0) // we're collecting the 4 center pixels	
			begin
				rPix[0] <= rin;
				gPix[0] <= gin;
				bPix[0] <= bin;
				done <= done + 1;
			end
			else if (x == 320 && y == 239 && done == 1)
			begin
				rPix[1] <= rin;
				gPix[1] <= gin;
				bPix[1] <= bin;
				done <= done + 1;
			end
			else if (x == 319 && y == 240 && done == 2)
			begin
				rPix[2] <= rin;
				gPix[2] <= gin;
				bPix[2] <= bin;
				done <= done + 1;
			end
			else if (x == 320 && y == 240 && done == 3)
			begin
				rPix[3] <= rin;
				gPix[3] <= gin;
				bPix[3] <= bin;
				done <= done + 1;
			end
			else if (done == 4)
				done <= 0; // reset done
		end
	end

	// add them up
	assign r = rPix[0] + rPix[1] + rPix[2] + rPix[3];
	assign g = gPix[0] + gPix[1] + gPix[2] + gPix[3];
	assign b = bPix[0] + bPix[1] + bPix[2] + bPix[3];

	// perform division... has output latency of 1 clock cycle
	// average them by dividing by 4
	wire w1, w2, w3; // useless wires holding the remainder
	
	div_setkey d0 (clk, 4, r, rkey, w1);
	div_setkey d1 (clk, 4, g, gkey, w2);
	div_setkey d2 (clk, 4, b, bkey, w3);

	always@(posedge clk)
	begin
		if (set) // press set to start the process
			load <= 1;
		else if (done == 4) // have collected all 4 pixels
		begin
			load <= 0;
		end
	end

endmodule

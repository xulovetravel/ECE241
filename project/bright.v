// brightness involves increasing all r, g, and b values by a set amount

module bright(rin,gin,bin,bright,rvga,gvga,bvga,clip);
	input [7:0] rin,gin,bin,bright;
	output [7:0] rvga;
	output [7:0] gvga;
	output [7:0] bvga;
	output clip;
	wire [8:0] red,green,blue;
	assign red = rin+bright;
	assign green = gin+bright;
	assign blue = bin+bright;

	// check that none of the colours are clipping, if they are clipping output 255
	checkclip c1 (red, rvga, clipr);
	checkclip c2 (green, gvga, clipg);
	checkclip c3 (blue, bvga, clipb);

	assign clip = clipr + clipg + clipb;

endmodule

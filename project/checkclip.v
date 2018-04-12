module checkclip (colour, colour_out, clip); // check for clipping
	input [8:0] colour;
	output reg [7:0] colour_out;
	output reg clip;
	
	always@(*)
	begin
		if (colour > 255)
		begin
			colour_out = 255; // clipping
			clip = 1;
		end
		else
		begin
			colour_out = colour[7:0];
			clip = 0;
		end
	end
	
endmodule

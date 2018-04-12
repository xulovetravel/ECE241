// Code modified by Timothy Lui and Richard Xu for ECE241
// Our additional code and modules are at the end of this file
//
// NOTE: Some of the Terasic code contains latches. This was their design decision and not ours.

// Start of Terasic code:

// ============================================================================
// Copyright (c) 2013 by Terasic Technologies Inc.
// ============================================================================
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// ============================================================================
//           
//  Terasic Technologies Inc
//  9F., No.176, Sec.2, Gongdao 5th Rd, East Dist, Hsinchu City, 30070. Taiwan
//  
//  
//                     web: http://www.terasic.com/  
//                     email: support@terasic.com
//
// ============================================================================
//Date:  Mon Jun 17 20:35:29 2013
// ============================================================================

//`define ENABLE_HPS

module DE1_SoC_TV(

      ///////// ADC /////////
      output             ADC_CONVST,
      output             ADC_DIN,
      input              ADC_DOUT,
      output             ADC_SCLK,

      ///////// AUD /////////
      input              AUD_ADCDAT,
      inout              AUD_ADCLRCK,
      inout              AUD_BCLK,
      output             AUD_DACDAT,
      inout              AUD_DACLRCK,
      output             AUD_XCK,

      ///////// CLOCK2 /////////
      input              CLOCK2_50,

      ///////// CLOCK3 /////////
      input              CLOCK3_50,

      ///////// CLOCK4 /////////
      input              CLOCK4_50,

      ///////// CLOCK /////////
      input              CLOCK_50,

      ///////// DRAM /////////
      output      [12:0] DRAM_ADDR,
      output      [1:0]  DRAM_BA,
      output             DRAM_CAS_N,
      output             DRAM_CKE,
      output             DRAM_CLK,
      output             DRAM_CS_N,
      inout       [15:0] DRAM_DQ,
      output             DRAM_LDQM,
      output             DRAM_RAS_N,
      output             DRAM_UDQM,
      output             DRAM_WE_N,

      ///////// FPGA /////////
      output             FPGA_I2C_SCLK,
      inout              FPGA_I2C_SDAT,

      ///////// KEY /////////
      input       [3:0]  KEY,

      ///////// LEDR /////////
      output      [9:0]  LEDR,
	  
	  ///////// HEX0 /////////
      output      [6:0]  HEX0,

      ///////// HEX1 /////////
      output      [6:0]  HEX1,

      ///////// HEX2 /////////
      output      [6:0]  HEX2,

      ///////// HEX3 /////////
      output      [6:0]  HEX3,

      ///////// HEX4 /////////
      output      [6:0]  HEX4,

      ///////// HEX5 /////////
      output      [6:0]  HEX5,

      ///////// SW /////////
      input       [9:0]  SW,

      ///////// TD /////////
      input              TD_CLK27,
      input      [7:0]  TD_DATA,
      input             TD_HS,
      output             TD_RESET_N,
      input             TD_VS,

      ///////// VGA /////////
      output      [7:0]  VGA_B,
      output             VGA_BLANK_N,
      output             VGA_CLK,
      output      [7:0]  VGA_G,
      output             VGA_HS,
      output      [7:0]  VGA_R,
      output             VGA_SYNC_N,
      output             VGA_VS
);



//=======================================================
//  REG/WIRE declarations
//=======================================================

wire	CLK_18_4;
wire	CLK_25;

//	For Audio CODEC
wire		AUD_CTRL_CLK;	//	For Audio Controller

//	For ITU-R 656 Decoder
wire	[15:0]	YCbCr;
wire	[9:0]	TV_X;
wire			TV_DVAL;

//	For VGA Controller
wire	[9:0]	mRed;
wire	[9:0]	mGreen;
wire	[9:0]	mBlue;
wire	[10:0]	VGA_X;
wire	[10:0]	VGA_Y;
wire			VGA_Read;	//	VGA data request
wire			m1VGA_Read;	//	Read odd field
wire			m2VGA_Read;	//	Read even field

//	For YUV 4:2:2 to YUV 4:4:4
wire	[7:0]	mY;
wire	[7:0]	mCb;
wire	[7:0]	mCr;

//	For field select
wire	[15:0]	mYCbCr;
wire	[15:0]	mYCbCr_d;
wire	[15:0]	m1YCbCr;
wire	[15:0]	m2YCbCr;
wire	[15:0]	m3YCbCr;

//	For Delay Timer
wire			TD_Stable;
wire			DLY0;
wire			DLY1;
wire			DLY2;

//	For Down Sample
wire	[3:0]	Remain;
wire	[9:0]	Quotient;

wire			mDVAL;

wire	[15:0]	m4YCbCr;
wire	[15:0]	m5YCbCr;
wire	[8:0]	Tmp1,Tmp2;
wire	[7:0]	Tmp3,Tmp4;

wire            NTSC;
wire            PAL;
//=============================================================================
// Structural coding
//=============================================================================


//	All inout port turn to tri-state 

assign	AUD_ADCLRCK	=	AUD_DACLRCK;
assign	GPIO_A	=	36'hzzzzzzzzz;
assign	GPIO_B	=	36'hzzzzzzzzz;

//	Turn On TV Decoder
assign	TD_RESET_N	=	1'b1;

assign	AUD_XCK	=	AUD_CTRL_CLK;

assign	LED	=	VGA_Y;


assign	m1VGA_Read	=	VGA_Y[0]		?	1'b0		:	VGA_Read	;
assign	m2VGA_Read	=	VGA_Y[0]		?	VGA_Read	:	1'b0		;
assign	mYCbCr_d	=	!VGA_Y[0]		?	m1YCbCr		:
											      m2YCbCr		;
assign	mYCbCr		=	m5YCbCr;

assign	Tmp1	=	m4YCbCr[7:0]+mYCbCr_d[7:0];
assign	Tmp2	=	m4YCbCr[15:8]+mYCbCr_d[15:8];
assign	Tmp3	=	Tmp1[8:2]+m3YCbCr[7:1];
assign	Tmp4	=	Tmp2[8:2]+m3YCbCr[15:9];
assign	m5YCbCr	=	{Tmp4,Tmp3};

//	TV Decoder Stable Check
TD_Detect			u2	(	.oTD_Stable(TD_Stable),
							.oNTSC(NTSC),
							.oPAL(PAL),
							.iTD_VS(TD_VS),
							.iTD_HS(TD_HS),
							.iRST_N(KEY[0])	);

//	Reset Delay Timer
Reset_Delay			u3	(	.iCLK(CLOCK_50),
							.iRST(TD_Stable),
							.oRST_0(DLY0),
							.oRST_1(DLY1),
							.oRST_2(DLY2));

//	ITU-R 656 to YUV 4:2:2
ITU_656_Decoder		u4	(	//	TV Decoder Input
							.iTD_DATA(TD_DATA),
							//	Position Output
							.oTV_X(TV_X),
							//	YUV 4:2:2 Output
							.oYCbCr(YCbCr),
							.oDVAL(TV_DVAL),
							//	Control Signals
							.iSwap_CbCr(Quotient[0]),
							.iSkip(Remain==4'h0),
							.iRST_N(DLY1),
							.iCLK_27(TD_CLK27)	);

//	For Down Sample 720 to 640
DIV 				u5	(	.aclr(!DLY0),	
							.clock(TD_CLK27),
							.denom(4'h9),
							.numer(TV_X),
							.quotient(Quotient),
							.remain(Remain));

//	SDRAM frame buffer
Sdram_Control_4Port	u6	(	//	HOST Side
						   .REF_CLK(TD_CLK27),
							.CLK_18(AUD_CTRL_CLK),
						   .RESET_N(DLY0),
							//	FIFO Write Side 1
						   .WR1_DATA(YCbCr),
							.WR1(TV_DVAL),
							.WR1_FULL(WR1_FULL),
							.WR1_ADDR(0),
							.WR1_MAX_ADDR(NTSC ? 640*507 : 640*576),		//	525-18
							.WR1_LENGTH(9'h80),
							.WR1_LOAD(!DLY0),
							.WR1_CLK(TD_CLK27),
							//	FIFO Read Side 1
						   .RD1_DATA(m1YCbCr),
				        	.RD1(m1VGA_Read),
				        	.RD1_ADDR(NTSC ? 640*13 : 640*22),			//	Read odd field and bypess blanking
							.RD1_MAX_ADDR(NTSC ? 640*253 : 640*262),
							.RD1_LENGTH(9'h80),
				        	.RD1_LOAD(!DLY0),
							.RD1_CLK(TD_CLK27),
							//	FIFO Read Side 2
						    .RD2_DATA(m2YCbCr),
				        	.RD2(m2VGA_Read),
				        	.RD2_ADDR(NTSC ? 640*267 : 640*310),			//	Read even field and bypess blanking
							.RD2_MAX_ADDR(NTSC ? 640*507 : 640*550),
							.RD2_LENGTH(9'h80),
				        	.RD2_LOAD(!DLY0),
							.RD2_CLK(TD_CLK27),
							//	SDRAM Side
						   .SA(DRAM_ADDR),
						   .BA(DRAM_BA),
						   .CS_N(DRAM_CS_N),
						   .CKE(DRAM_CKE),
						   .RAS_N(DRAM_RAS_N),
				         .CAS_N(DRAM_CAS_N),
				         .WE_N(DRAM_WE_N),
						   .DQ(DRAM_DQ),
				         .DQM({DRAM_UDQM,DRAM_LDQM}),
							.SDR_CLK(DRAM_CLK)	);

//	YUV 4:2:2 to YUV 4:4:4
YUV422_to_444		u7	(	//	YUV 4:2:2 Input
							.iYCbCr(mYCbCr),
							//	YUV	4:4:4 Output
							.oY(mY),
							.oCb(mCb),
							.oCr(mCr),
							//	Control Signals
							.iX(VGA_X-160),
							.iCLK(TD_CLK27),
							.iRST_N(DLY0));

//	YCbCr 8-bit to RGB-10 bit 
YCbCr2RGB 			u8	(	//	Output Side
							.Red(mRed), // these are 10-bit outputs
							.Green(mGreen),
							.Blue(mBlue),
							.oDVAL(mDVAL),
							//	Input Side
							.iY(mYFinal),
							.iCb(mCbFinal),
							.iCr(mCrFinal),
							.iDVAL(VGA_Read),
							//	Control Signal
							.iRESET(!DLY2),
							.iCLK(TD_CLK27));

//	VGA Controller
// modified for 8 bits as opposed to 10 bits
wire [7:0] vga_r8;
wire [7:0] vga_g8;
wire [7:0] vga_b8;
assign VGA_R = vga_r8;
assign VGA_G = vga_g8;
assign VGA_B = vga_b8;

VGA_Ctrl			u9	(	//	Host Side
							.iRed(mRedFinal),
							.iGreen(mGreenFinal),
							.iBlue(mBlueFinal),
							.oCurrent_X(VGA_X), // outputs current x and y coord
							.oCurrent_Y(VGA_Y),
							.oRequest(VGA_Read), // this goes up when the module is still accepting video
							//	VGA Side
							.oVGA_R(vga_r8),
							.oVGA_G(vga_g8),
							.oVGA_B(vga_b8),
							.oVGA_HS(VGA_HS),
							.oVGA_VS(VGA_VS),
							.oVGA_SYNC(VGA_SYNC_N),
							.oVGA_BLANK(VGA_BLANK_N),
							.oVGA_CLOCK(VGA_CLK),
							//	Control Signal
							.iCLK(TD_CLK27),
							.iRST_N(DLY2)	);

//	Line buffer, delay one line
Line_Buffer u10	(	.aclr(!DLY0),
					.clken(VGA_Read),
					.clock(TD_CLK27),
					.shiftin(mYCbCr_d),
					.shiftout(m3YCbCr));

Line_Buffer u11	(	.aclr(!DLY0),
					.clken(VGA_Read),
					.clock(TD_CLK27),
					.shiftin(m3YCbCr),
					.shiftout(m4YCbCr));

AUDIO_DAC 	u12	(	//	Audio Side
					.oAUD_BCK(AUD_BCLK),
					.oAUD_DATA(AUD_DACDAT),
					.oAUD_LRCK(AUD_DACLRCK),
					//	Control Signals
					.iSrc_Select(2'b01),
			      .iCLK_18_4(AUD_CTRL_CLK),
					.iRST_N(DLY1)	);

//	Audio CODEC and video decoder setting
I2C_AV_Config 	u1	(	//	Host Side
						.iCLK(CLOCK_50),
						.iRST_N(KEY[0]),
						//	I2C Side
						.I2C_SCLK(FPGA_I2C_SCLK),
						.I2C_SDAT(FPGA_I2C_SDAT)	);	


// Custom modules for video processor project
// 
// original wires mRed, mGreen, mBlue (10bits) connects the final RGB output
// to the VGA out - we will tap that signal and output to vga mRedFinal,
// mGreenFinal, mBlueFinal
//
// also tapping mY, mCr, mCb and replacing with mYFinal, mCrFinal, mCbFinal
//
// THIS SYSTEM RUNS AT 27MHZ AS OPPOSED TO 50MHZ (Terasic's choice, not ours)

// Control FSM
// reset is handled by FSM (no hard reset avaliable or necessary)

control c1(TD_CLK27, ~KEY[0], ~KEY[3:0], SW[8], prepost, tol, cont, br, loadbr, loadcont, loadtol, loadbackr,
loadbackg, loadbackb, loadkey, fx, LEDR[8], LEDR[2:0], HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
wire loadbr, loadcont, loadbackr, loadbackb, loadbackg, fx, loadtol, loadkey;
reg [7:0] br, cont, backr, backg, backb,tol; // stores values
reg prepost;

// control flip-flops
always@(posedge TD_CLK27)
begin
	if (loadbr) // load brightness
		br <= SW[7:0];
	if (loadcont) // load contrast
		cont <= SW[7:0];
	if (loadbackr) // loads background value (has 3 for r, g, and b)
		backr <= SW[7:0];
	if (loadbackg)
		backg <= SW[7:0];
	if (loadbackb)
		backb <= SW[7:0];
	if (fx) // pre/post fx toggle
	begin
		if (prepost)
			prepost <= 0; // this is a toggle
		else
			prepost <= 1;
	end
	if (loadtol) // load tolerance
		tol <= SW[7:0];
end

// setkey module
setkey s1 (TD_CLK27, loadkey, mRedFinal, mGreenFinal, mBlueFinal, VGA_X, VGA_Y, mRedKey, mGreenKey, mBlueKey);

// pre or post processor (make brightness and contrast processing happen
// BEFORE or AFTER the greenscreen effect)
always@(*)
begin
	if (prepost) // post fx
	begin
		// connect terasic video out to greenscreen module
		mRedGS = mRed[9:2]; 
		mGreenGS = mGreen[9:2];
		mBlueGS = mBlue[9:2];
		// connect greenscreen out to fx in
		mRedFX = mRedGSo;
		mGreenFX = mGreenGSo;
		mBlueFX = mBlueGSo;
		// connect contrast out to main out
		mRedFinal = mRedCont;
		mGreenFinal = mGreenCont;
		mBlueFinal = mBlueCont;
	end
	else // pre fx
	begin
		// connect terasic video out to fx module
		mRedFX = mRed[9:2];
		mGreenFX = mGreen[9:2];
		mBlueFX = mBlue[9:2];
		// connect fx module to greenscreen in
		mRedGS = mRedCont;
		mGreenGS = mGreenCont;
		mBlueGS = mBlueCont;
		// connect greenscreen out to main out
		mRedFinal = mRedGSo;
		mGreenFinal = mGreenGSo;
		mBlueFinal = mBlueGSo;
	end
end

// RGB processing

wire [7:0] mRedKey, mBlueKey, mGreenKey; // key colour outputs
reg [7:0] mRedGS, mGreenGS, mBlueGS; // inputs to greenscreen module
wire [7:0] mRedGSo, mGreenGSo, mBlueGSo; // outputs of greenscreen module
reg [7:0] mRedFX, mGreenFX, mBlueFX; // inputs to fx modules
wire [7:0] mRedBright, mGreenBright, mBlueBright; // outputs of brightness module
wire [7:0] mRedCont, mGreenCont, mBlueCont; // outputs of contrast module
reg [7:0] mRedFinal, mGreenFinal, mBlueFinal; // final output to DAC

initial
begin // initialize all regs to 0
	br = 0; 
	cont = 0; 
	backr = 0;
	backg = 0;
	backb = 0;
	prepost = 0;
	tol = 0;
end

bright p1 (mRedFX, mGreenFX, mBlueFX, br, mRedBright, mGreenBright, mBlueBright, LEDR[6]); // brightness module
contrast p2 (mRedBright, mGreenBright, mBlueBright, cont, TD_CLK27, mRedCont, mGreenCont, mBlueCont, LEDR[5]); // contrast module

processor g1 (TD_CLK27, SW[9], mRedGS, mGreenGS, mBlueGS, mRedKey, mGreenKey, mBlueKey, backr, backg, backb, tol, mRedGSo, mGreenGSo, mBlueGSo); //greenscreen module

// commented out... if commented in will bypass all processing
//assign mRedFinal = mRed[9:2];
//assign mGreenFinal = mGreen[9:2];
//assign mBlueFinal = mBlueB[9:2];

// YCrCb processing (not needed for now but maybe...)

wire [7:0] mYFinal, mCrFinal, mCbFinal;

assign mYFinal = mY;
assign mCrFinal = mCr;
assign mCbFinal = mCb;

endmodule
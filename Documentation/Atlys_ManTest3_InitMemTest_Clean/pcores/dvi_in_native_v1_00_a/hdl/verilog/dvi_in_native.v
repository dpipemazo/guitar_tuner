`timescale 1 ps / 1 ps

module dvi_in_native (
	input  wire reset,
	output wire pixel_clk, 
	output wire ready,
	output wire [7:0] blue_dout,      // Blue data out
	output wire [7:0] green_dout,     // Green data out
	output wire [7:0] red_dout,       // Red data out
	output wire       hsync,          // hsync data
	output wire       vsync,          // vsync data
	output wire       de,             // data enable
  
	input  wire [3:0] TMDS,
	input  wire [3:0] TMDSB
);

  dvi_decoder dec0 ( 
    .TMDS_Clk_p(TMDS[3]),
    .TMDS_Clk_n(TMDSB[3]),
    .TMDS_Data_Ch_p(TMDS[2:0]),
    .TMDS_Data_Ch_n(TMDSB[2:0]),
    .Reset(reset),
    .Ready(ready),
    .Pixel_Clock(pixel_clk),
    .RGB({red_dout, green_dout, blue_dout}),
    .DE(de),
    .VSync(vsync),
    .HSync(hsync)
    );

endmodule

// Copyright (C) 2004-2009 Synfora, Inc.  All rights reserved.
// 
// This file contains Confidential Information of Synfora, Inc. In
// addition, certain inventions disclosed in this file may be claimed
// within patents owned or patent applications filed by Synfora or
// third parties.  Any use of Synfora's copyrighted works,
// confidential information, patented inventions, or patent-pending
// inventions is subject to the terms and conditions of your written
// license agreement with Synfora, Inc.  All other use and disclosure
// is strictly prohibited.
// 

`ifdef PICO_CLOCK_EDGE
`else
   `define PICO_CLOCK_EDGE posedge
`endif
`ifdef PICO_CLOCK_SENSITIVITY
`else
   `define PICO_CLOCK_SENSITIVITY clk
`endif
`ifdef PICO_RESET_SENSITIVITY
`else
   `define PICO_RESET_SENSITIVITY
`endif
`ifdef PICO_RESET_SENSITIVITY2
`else
   `define PICO_RESET_SENSITIVITY2 reset
`endif

`timescale 1 ns / 10 ps

module mpylw_multi_stage_noreset (clk, reset, flush, enable, pred, i0, i1, o0_enable, o0);

   // synopsys template
   parameter inwidth    = 4;
   parameter inwidth0   = inwidth;
   parameter inwidth1   = inwidth;
   parameter outwidth   = 8;
   parameter outlsb     = 0;
   parameter numstage   = 2;

   // coverage off
   // pragma coverage off
   // VCS coverage off
   // synopsys translate_off
      initial begin
         if ( numstage < 2 ) begin
            $display ("ERROR::::");
            $display ("mc_log:  ERROR:  numstage (%d) must be >= 2 in %m.  Stopping simulation", numstage);
            $display ("END ERROR");
            $finish;
         end
      end
   // synopsys translate_on
   // VCS coverage on
   // pragma coverage on
   // coverage on

   input                    clk;
   wire                     clk;

   input                    reset;
   wire                     reset;

   input                    flush;
   wire                     flush;
   
   input                    enable;
   wire                     enable;

   input                    pred;
   wire                     pred;

   input                    [inwidth0-1:0] i0;
   wire                     [inwidth0-1:0] i0;

   input                    [inwidth1-1:0] i1;
   wire                     [inwidth1-1:0] i1;


   output                   o0_enable;
   wire                     o0_enable;

   output                   [outwidth-1:0] o0;
   wire                     [outwidth-1:0] o0;


   reg                      [inwidth0-1:0] i0_ff;
   reg                      [inwidth1-1:0] i1_ff;
   reg                      [numstage-2:0] pred_delay_ff;
   reg                      [outwidth-1:0] prod_delay_ff[((numstage>2)?(numstage-3):0):0];
   
   wire                     [inwidth0+inwidth1-1:0] prod_out;
   wire                     [inwidth0+inwidth1+outwidth+outlsb-1:0] o0_temp;

   integer i;

   assign   o0_temp  =  {{(outwidth+outlsb){1'b0}},prod_out} ;

   // When (numstage==2), the register is placed at the output of the multiplier.
   // For cases with (numstage > 2), one register is placed at the input and the
   // rest are placed at the output of the multiplier
   assign  prod_out  =  (numstage>2)?(i0_ff * i1_ff) : (i0 * i1);

   assign       o0   =  prod_delay_ff[((numstage>2)?(numstage-3):0)];
   assign o0_enable  =  pred_delay_ff[(numstage-2)];

   // Registers at the input of the multiplier
   always @ (`PICO_CLOCK_EDGE `PICO_CLOCK_SENSITIVITY) begin
       if(enable) begin
         i0_ff  <= i0; 
         i1_ff  <= i1; 
       end
   end

   // Shifting pred
   reg shiftout;
   always @ (`PICO_CLOCK_EDGE `PICO_CLOCK_SENSITIVITY `PICO_RESET_SENSITIVITY) begin
     if (`PICO_RESET_SENSITIVITY2) {shiftout, pred_delay_ff} <= {numstage{1'b0}};
     else begin
       if (flush) {shiftout, pred_delay_ff} <= {numstage{1'b0}};
       else if (enable) {shiftout, pred_delay_ff} <= {pred_delay_ff,pred}; // shift reg
     end
   end  

   // Registers at the output of the multiplier
   always @ (`PICO_CLOCK_EDGE `PICO_CLOCK_SENSITIVITY) begin
     if(enable) begin
      prod_delay_ff[0] <= o0_temp[outwidth+outlsb-1:outlsb];
     end  

     //Shift register: Used only if the multiplier has > 3 stages
     for (i = 0; i< (numstage-3) ; i = i+1) begin
        if(enable) begin 
          prod_delay_ff[i+1] <= prod_delay_ff[i];
        end  
     end
   end

endmodule

// Copyright (C) 2004-2009 Synfora, Inc.  All rights reserved.
// Copyright (C) 2000-2002 Hewlett-Packard Company All rights reserved.
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
// $Revision: 1.7 $

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

module incdec_counter (clk, reset, enable, load, inc, dec, i0, o0);

   // synopsys template
   parameter width = 32;
   parameter countby = 1;

   input              clk;           // system clk
   wire               clk;

   input              reset;         // system reset
   wire               reset;

   input              enable;        // enables load or count
   wire               enable;

   input              load;          // loads i0 into counter
   wire               load;

   input              inc;           // 1 = inc counter
   wire               inc;

   input              dec;           // 1 = dec counter, inc=dec=0 or 1 => do nothing
   wire               dec;

   input  [width-1:0] i0;            // init count value
   wire   [width-1:0] i0;

   output [width-1:0] o0;            // count out
   wire   [width-1:0] o0;

   reg    [width-1:0] count_ff;

   assign o0 = count_ff;

   wire [31:0] value         =   countby;
   wire [width+31:0] step    = {{width{value[31]}}, value};
   reg cout;

   always @ (`PICO_CLOCK_EDGE `PICO_CLOCK_SENSITIVITY `PICO_RESET_SENSITIVITY) begin
      if (`PICO_RESET_SENSITIVITY2) count_ff <= {width {1'b0}};
      else begin
         case ({enable, load, inc, dec}) // 0in case -full -parallel
            4'b1100, 4'b1101, 4'b1110, 4'b1111:               
                      {cout, count_ff} <= {1'b0, i0};        
            4'b1010:  {cout, count_ff} <= count_ff + step[width-1:0];
            4'b1001:  {cout, count_ff} <= count_ff - step[width-1:0];
            default:  {cout, count_ff} <= {1'b0, count_ff};
            // 0in overflow -var count_ff
            // 0in underflow -var count_ff
         endcase
      end
   end

endmodule

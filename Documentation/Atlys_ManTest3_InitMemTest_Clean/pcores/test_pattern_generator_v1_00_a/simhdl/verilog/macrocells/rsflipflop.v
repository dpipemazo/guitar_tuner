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
// $Revision: 1.10 $

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

module rsflipflop (clk, reset, init, r, s, q);

   // synopsys template
   parameter initvalue = 1'b0;

   input   clk;             // system clk
   wire    clk;

   input   reset;           // system reset
   wire    reset;

   input   init;            // loads initvalue into flop
   wire    init;

   input   r;               // reset flop to 0
   wire    r;

   input   s;               // set flop to 1
   wire    s;


   output  q;               // output
   wire    q;


   reg     rs_ff;

   assign  q = rs_ff;

   always @ (`PICO_CLOCK_EDGE `PICO_CLOCK_SENSITIVITY `PICO_RESET_SENSITIVITY) begin
      if      (`PICO_RESET_SENSITIVITY2) rs_ff <= 1'b0;
      else if  (init) rs_ff <= initvalue;
      else begin
         case ({s,r})
            2'b00:    rs_ff <= rs_ff;
            2'b01:    rs_ff <= 1'b0;
            2'b10:    rs_ff <= 1'b1;
//coverage off
//pragma coverage off
//VCS coverage off
            2'b11:    rs_ff <= 1'b0;
            default:  rs_ff <= 1'bx;
//coverage on
//pragma coverage on
//VCS coverage on
         endcase
      end
         
      // coverage off
      // pragma coverage off
      // VCS coverage off
      // synopsys translate_off
         if ( {s,r} == 2'b11 ) begin
            $display ("ERROR::::");
            $display ("mc_log:  ERROR:  r = s = 1 in %m.  stoping simulation");
            $display ("END ERROR");
            $finish;
         end
      // synopsys translate_on
      // VCS coverage on
      // pragma coverage on
      // coverage on
   
   end

endmodule

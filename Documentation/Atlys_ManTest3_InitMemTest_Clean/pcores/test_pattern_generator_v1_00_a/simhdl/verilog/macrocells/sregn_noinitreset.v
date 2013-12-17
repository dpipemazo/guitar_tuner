// Copyright (C) 2005-2009 Synfora, Inc.  All rights reserved.
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
// $Revision: 1.4 $

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

module sregn_noinitreset (clk, enable, i0, o0) ;

  // synopsys template
     parameter width = 32;

     input              clk;         // system clk
     wire               clk;

     input              enable;      // (dis)enables flops
     wire               enable;

     input  [width-1:0] i0;          // input data
     wire   [width-1:0] i0;


     output [width-1:0] o0;          // output data
     wire   [width-1:0] o0;


     reg    [width-1:0] o0_ff;

     assign o0 = o0_ff;


   always @ (`PICO_CLOCK_EDGE `PICO_CLOCK_SENSITIVITY) begin
      if (enable) o0_ff <= i0;
   end

endmodule

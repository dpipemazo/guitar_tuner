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

`timescale 1 ns / 10 ps

module sext (i0, o0);

   // synopsys template
   parameter inwidth  = 16;
   parameter outwidth = 32;
   parameter signedflag  = 1'b0;

   input   [inwidth-1:0] i0;          // data in
   wire    [inwidth-1:0] i0;

   output [outwidth-1:0] o0;          // sign extended data out
   wire   [outwidth-1:0] o0;


   // coverage off
   // pragma coverage off
   // VCS coverage off
   // synopsys translate_off
   initial begin
      if (inwidth > outwidth) begin
         $display ("ERROR::::");
         $display ("mc_log:  ERROR:  inwidth (%d) > outwidth (%d) in %m.  Stopping simulation", inwidth, outwidth);
         $display ("END ERROR");
         $finish;
      end
   end
   // synopsys translate_on
   // VCS coverage on
   // pragma coverage on
   // coverage on

   wire flag = signedflag;
   wire [inwidth+outwidth-1:0] extended;
   assign extended = {{(outwidth){flag & i0[inwidth-1]}}, i0};
   assign o0 = extended[outwidth-1:0];

endmodule

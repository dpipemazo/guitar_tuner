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
// $Revision: 1.5 $

`define SEL_DEFAULT_CASE_VAL 1'bx

`timescale 1 ns / 10 ps

module select_1_1_wn (i0, enable0, o0);

   // synopsys template
   parameter dwidth = 32;

   input  [dwidth-1:0] i0;
   wire   [dwidth-1:0] i0;

   input  enable0;
   wire   enable0;

   output [dwidth-1:0] o0;
   reg    [dwidth-1:0] o0;


   wire   enable = enable0;

   always @(*) begin

      case (enable) // 0in < case -full -parallel
         1'b1: o0 = i0;
         1'b0: o0 = {dwidth{1'b0}};
      endcase
   end

endmodule

`undef SEL_DEFAULT_CASE_VAL

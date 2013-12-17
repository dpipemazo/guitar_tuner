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
// $Revision: 1.9 $

`define SEL_DEFAULT_CASE_VAL 1'bx

`timescale 1 ns / 10 ps

module select_3_1_wn (i0, i1, i2, enable0, enable1, enable2, o0);

   // synopsys template
   parameter dwidth = 32;

   input  [dwidth-1:0] i0, i1, i2;
   wire   [dwidth-1:0] i0, i1, i2;

   input  enable0, enable1, enable2;
   wire   enable0, enable1, enable2;

   output [dwidth-1:0] o0;
   reg    [dwidth-1:0] o0;


   wire [3-1:0] enable = {enable2, enable1, enable0};
   // 0in bits_off -var enable -min 2 -max 3

   always @(*) begin
   
      if(dwidth > 1) begin
         case (enable) // 0in < case -full -parallel
            3'b001: o0 = i0;
            3'b010: o0 = i1;
            3'b100: o0 = i2;
//coverage off
//pragma coverage off
//VCS coverage off
            default: o0 = {dwidth{`SEL_DEFAULT_CASE_VAL}};
//coverage on
//pragma coverage on
//VCS coverage on
         endcase
      end
      else begin
         case (enable) // 0in < case -full -parallel
            3'b001: o0 = i0;
            3'b010: o0 = i1;
            3'b100: o0 = i2;
            3'b000: o0 = {dwidth{1'b0}};
//coverage off
//pragma coverage off
//VCS coverage off
            default: o0 = {dwidth{`SEL_DEFAULT_CASE_VAL}};
//coverage on
//pragma coverage on
//VCS coverage on
         endcase
      end
   end

endmodule

`undef SEL_DEFAULT_CASE_VAL

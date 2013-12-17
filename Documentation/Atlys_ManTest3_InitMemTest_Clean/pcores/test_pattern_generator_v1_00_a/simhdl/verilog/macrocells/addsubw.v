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
// $Revision: 1.2 $

`timescale 1 ns / 10 ps

module addsubw (i0, i1, op, pred, o0, o0_enable);

   // synopsys template
   parameter width = 4;               // width of input and output data

   input  [width-1:0] i0;             // input data i0
   wire   [width-1:0] i0;

   input  [width-1:0] i1;             // input data i1
   wire   [width-1:0] i1;

   input        [1:0] op;             // 00 : add (no carry in/out); msb not used
   wire         [1:0] op;

                                      // 01 : sub (no borrow in/out); msb not used
   input              pred;           //
   wire               pred;


   output [width-1:0] o0;             // output data o0 = i0 +/- i1
   wire   [width-1:0] o0;

   output             o0_enable;      // reflected pred
   wire               o0_enable;



   // 0in known_driven -var i0
   // 0in known_driven -var i1
   // 0in known_driven -var op
   // 0in never -var op[1]
   // 0in known_driven -var pred
   // 0in data_used -var o0 -start o0_enable -start_count 1 -stop_count 2

   assign o0_enable = pred;

   assign o0        = i0 + (i1 ^ {width{op[0]}}) + op[0];

endmodule



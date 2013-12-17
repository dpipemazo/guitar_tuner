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
// $Revision: 1.4 $

`timescale 1 ns / 10 ps

module combine6_wn ( i0, i1, i2, i3, i4, i5, o0 );

   // synopsys template
   parameter inwidth = 1;

   input    [inwidth-1:0] i0;
   wire     [inwidth-1:0] i0;

   input    [inwidth-1:0] i1;
   wire     [inwidth-1:0] i1;

   input    [inwidth-1:0] i2;
   wire     [inwidth-1:0] i2;

   input    [inwidth-1:0] i3;
   wire     [inwidth-1:0] i3;

   input    [inwidth-1:0] i4;
   wire     [inwidth-1:0] i4;

   input    [inwidth-1:0] i5;
   wire     [inwidth-1:0] i5;


   output [6*inwidth-1:0] o0;
   wire   [6*inwidth-1:0] o0;


   assign o0 = {i5, i4, i3, i2, i1, i0};

endmodule


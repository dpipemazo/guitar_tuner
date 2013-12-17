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
// $Revision: 1.8 $

`timescale 1 ns / 10 ps

module shrkw (op, pred, i0, o0_enable, o0);

   // synopsys template
   parameter width     = 8;
   parameter shiftbits = 2;

   // 0in assert -var (shiftbits <= width)

   input                     op;      // 0 Logical shift, 1 Arithmetic shift
   wire                      op;

   input                     pred;
   wire                      pred;

   input         [width-1:0] i0;
   wire          [width-1:0] i0;


   output                    o0_enable;
   wire                      o0_enable;

   output        [width-1:0] o0;
   wire          [width-1:0] o0;


   assign o0_enable = pred;

   //assign o0 = op ? ($signed(i0) >>> shiftbits) : (i0 >> shiftbits);

   // add extra bits so that even shiftbits == 0 will work.
   wire [shiftbits+width:0] sign_extended, zero_extended;
   assign sign_extended = {{(shiftbits+1){i0[width-1]}}, i0};
   assign zero_extended = {{(shiftbits+1){1'b0}}, i0};

   assign o0 = op ? sign_extended[shiftbits+width-1 : shiftbits] :
                    zero_extended[shiftbits+width-1 : shiftbits];


endmodule

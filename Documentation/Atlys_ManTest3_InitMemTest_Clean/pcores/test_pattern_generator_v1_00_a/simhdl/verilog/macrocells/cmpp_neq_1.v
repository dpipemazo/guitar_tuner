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

module cmpp_neq_1 (i0, i1, op, pred, o0_enable, o1_enable, o0, o1);

   // synopsys template
   parameter width = 4;          // bit width of inputs and output

   input              pred;
   wire               pred;

   input  [width-1:0] i0;        //                    o0       o1
   wire   [width-1:0] i0;

   input  [width-1:0] i1;        //                 -------- --------
   wire   [width-1:0] i1;

   input        [2:0] op;        // 000 : !equal   ( normal   normal )
   wire         [2:0] op;

                                 // 001 : !equal   ( normal  inverted)
                                 // 010 : !equal   (inverted  normal )
                                 // 011 : !equal   (inverted inverted)
                                 // 1** :  no-op   (   0        0    )
   output             o0_enable;
   reg                o0_enable;

   output             o1_enable;
   reg                o1_enable;

   output             o0;
   reg                o0;

   output             o1;
   reg                o1;



   reg                outt;      // temp reg

   always @ (i0 or i1 or pred or op) begin

         outt      = (i0 != i1); // not equal
         o0_enable = 1'b1;
         o1_enable = 1'b1;
         o0        = (!op[1] && pred && outt) || (op[1] && pred && !outt);
         o1        = (!op[0] && pred && outt) || (op[0] && pred && !outt);
   end

endmodule


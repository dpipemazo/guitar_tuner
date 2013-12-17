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
// $Revision: 1.3 $

`timescale 1 ns / 10 ps

module cmpr_eq (i0, i1, op, pred, o0_enable, o0);

     // synopsys template
     parameter width = 4;               // bit width of inputs and output

     input              pred;           //
     wire               pred;

     input  [width-1:0] i0;             //
     wire   [width-1:0] i0;

     input  [width-1:0] i1;             //
     wire   [width-1:0] i1;

     input              op;             // op - kind of operation
     wire               op;
					// op - not used
     output             o0_enable;      //
     wire               o0_enable;

     output [width-1:0] o0;             //
     reg    [width-1:0] o0;

             //

     reg                outt;           // temp reg
     reg [width:0] zero_extended_outt;

     assign o0_enable = pred;

     always @ (i0 or i1) begin

          outt = (i0 == i1);           // equal
          zero_extended_outt = {{width{1'b0}}, outt};
          o0 = zero_extended_outt[width-1:0];
     end

endmodule


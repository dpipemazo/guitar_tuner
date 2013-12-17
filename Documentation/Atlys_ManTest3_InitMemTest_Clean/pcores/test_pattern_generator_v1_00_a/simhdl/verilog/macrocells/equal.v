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

module equal (i0, i1, o0);

     // synopsys template
     parameter width = 2;

     input  [width-1:0] i0;   // input data i0
     wire   [width-1:0] i0;

     input  [width-1:0] i1;   // input data i1
     wire   [width-1:0] i1;


     output             o0;   // output data
     wire               o0;


     assign o0 = (i0 == i1) ? 1'b1 : 1'b0 ;

endmodule

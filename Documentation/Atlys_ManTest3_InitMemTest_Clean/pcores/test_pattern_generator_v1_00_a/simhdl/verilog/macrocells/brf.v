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
// $Revision: 1.11 $

`timescale 1 ns / 10 ps

module brf (enable,
            /*btr,*/ op, running, 
	    p, p_enable,
	    lc, lc_out, lc_enable);
	    
     // synopsys template
     parameter lcwidth   = 16;
/*     parameter addrwidth = 32;  */            // commenting out unused btr port parameter

     input                  enable;
     wire                   enable;

/*     input [addrwidth-1:0]  btr;
       wire  [addrwidth-1:0]  btr;   */

     input                  running; // from controller 
     wire                   running;

     input                  op; // pulses at II-1 cycle
     wire                   op;

     input   [lcwidth-1:0]  lc;
     wire    [lcwidth-1:0]  lc;


     output                 p_enable;
     reg                    p_enable;

     output                 lc_enable; // pulses when lc changes
     reg                    lc_enable;

     output                 p;
     reg                    p;

     output  [lcwidth-1:0]  lc_out;
     reg     [lcwidth-1:0]  lc_out;



     wire 		 brf_cycle;

     assign brf_cycle = op & enable & running;

     reg cout;
     // Signal p, p_enable, lc_out, lc_enable
     always @(brf_cycle or lc) 
     begin
       if (brf_cycle)
       begin
         p_enable = 1'b1; // Old brf : Low in last brf cycle 
         if (lc > {lcwidth{1'b0}})
         begin
           {cout, lc_out} = lc + {lcwidth{1'b1}};
	       lc_enable = 1'b1;
           p = 1'b1;
	     end
	     else
	     begin
           {cout, lc_out} = {1'b0, lc};
	       lc_enable = 1'b1; // to register the chained mv lc 0 write
           p = 1'b0;
	     end
       end
       else
       begin
         {cout, lc_out} = {1'b0, lc};
	     lc_enable = 1'b0;
	     p = 1'b0;
         p_enable = 1'b0;
       end
     end

endmodule


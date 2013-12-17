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

`ifdef PICO_CLOCK_EDGE
`else
   `define PICO_CLOCK_EDGE posedge
`endif
`ifdef PICO_CLOCK_SENSITIVITY
`else
   `define PICO_CLOCK_SENSITIVITY clk
`endif
`ifdef PICO_RESET_SENSITIVITY
`else
   `define PICO_RESET_SENSITIVITY
`endif
`ifdef PICO_RESET_SENSITIVITY2
`else
   `define PICO_RESET_SENSITIVITY2 reset
`endif

`timescale 1 ns / 10 ps


module stream_buffer_with_passthru_noreset  (clk, reset, flush, load_req, load_ready, indata,
                      store_req, store_ready, outdata);


     parameter width = 8;
     parameter depth = 16;

   input              clk;
   wire               clk;

   input              reset;
   wire               reset;

   input              flush;
   wire               flush;

   input              load_ready;
   wire               load_ready;

   input  [width-1:0] indata;
   wire   [width-1:0] indata;

   input              store_ready;
   wire               store_ready;


   output             load_req;
   wire               load_req;

   output             store_req;
   wire               store_req;

   output [width-1:0] outdata;
   wire   [width-1:0] outdata;

   wire           addq = load_ready;
   wire         shiftq = store_ready;


   wire full, empty;
   wire [width-1:0]  outdata_tmp;
   
   // coverage off
   // pragma coverage off
   // VCS coverage off
   // synopsys translate_off
   // copy of valid_ff used for deadlock checking:
   reg    [depth:0] validff1; // [0] always unused
   integer i;
   // synopsys translate_on
   // VCS coverage on
   // pragma coverage on
   // coverage on
    
   generate 
     if (depth == 0) begin
        wire empty_0, full_0;
        wire  [width-1:0]  outdata_0;
        fifo_0 #(.width(width)) fifo_0_inst0 (
                      .addq(addq),
                      .shiftq(shiftq),
                      .indata(indata),
                      .full(full_0),
                      .empty(empty_0),
                      .outdata(outdata_0));

        assign full  = full_0;
        assign empty = empty_0;
        assign outdata_tmp =outdata_0;

        // coverage off
        // pragma coverage off
        // VCS coverage off
        // synopsys translate_off
        always @ (`PICO_CLOCK_EDGE `PICO_CLOCK_SENSITIVITY  `PICO_RESET_SENSITIVITY ) begin
          validff1 <= {depth{1'b0}};
        end
        // synopsys translate_on
        // VCS coverage on
        // pragma coverage on
        // coverage on

     end
     else if (depth > 0) begin
         wire  empty_1, full_1;
         wire addq_1, shiftq_1;
         wire  [width-1:0]  outdata_1;

         assign addq_1   = empty_1 & shiftq & addq ? 1'b0 : addq;  
         assign shiftq_1 = empty_1 & shiftq & addq ? 1'b0 :shiftq;
        
        fifo_noreset #(.width(width), .depth(depth)) fifo_noreset_inst0 (
                      .clk(clk),
                      .reset(reset),
                      .flush(flush),
                      .addq(addq_1),
                      .shiftq(shiftq_1),
                      .indata(indata),
                      .full(full_1),
                      .empty(empty_1),
                      .outdata(outdata_1));

        assign full  = full_1;
        assign empty = empty_1;
        assign outdata_tmp = outdata_1;

        // coverage off
        // pragma coverage off
        // VCS coverage off
        // synopsys translate_off
        always @ (`PICO_CLOCK_EDGE `PICO_CLOCK_SENSITIVITY  `PICO_RESET_SENSITIVITY ) begin
          for (i = 0; i< depth ; i = i+1) begin
             if( i < fifo_noreset_inst0.count_ff ) begin
                validff1[i] <= 1'b1 ;
             end 
             else begin  
                validff1[i] <= 1'b0 ;
             end  
          end      
        end  
        // synopsys translate_on
        // VCS coverage on
        // pragma coverage on
        // coverage on

     end
   endgenerate

   assign     load_req = (depth==0) ? !full : (shiftq | !full);
   assign    store_req = (depth==0) ? !empty : (addq | !empty);
   assign    outdata  = (depth ==0) ? outdata_tmp : ((empty & addq) ? indata : outdata_tmp);

endmodule


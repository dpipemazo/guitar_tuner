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
// $Revision: 1.16 $

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

module ststr_sx_noreset (clk, reset, enable, sign, pred,
                 datain, str_req, str_dataout, str_ready, stallbar, flush);

     // synopsys template
     parameter dwidth  = 32;  // data bit width
     parameter sdwidth = 32;  // stream bit width
     parameter strid   =  0;  // stream id

     // 0in assert -var (dwidth <= sdwidth)

     // coverage off
     // pragma coverage off
     // VCS coverage off
     // synopsys translate_off
     initial begin
          if (dwidth > sdwidth) begin
               $display ("ERROR::::");
               $display ("mc_log:  ERROR:  dwidth (%d) > sdwidth (%d) in %m.  stoping simulation", dwidth, sdwidth);
               $display ("END ERROR");
               $finish;
          end
     end
     // synopsys translate_on
     // VCS coverage on
     // pragma coverage on
     // coverage on

     input                clk;
     wire                 clk;

     input                reset;
     wire                 reset;

     input                enable;
     wire                 enable;

     input                sign;
     wire                 sign;

     input                pred;
     wire                 pred;

     input   [dwidth-1:0] datain;
     wire    [dwidth-1:0] datain;


     output               str_req;
     wire                 str_req;

     output [sdwidth-1:0] str_dataout;
     wire   [sdwidth-1:0] str_dataout;

     input                str_ready;
     wire                 str_ready;

     output               stallbar;
     wire                 stallbar;

     input                flush;
     wire                 flush;


   // coverage off
   // pragma coverage off
   // VCS coverage off
   // synopsys translate_off
   initial begin
       // use strid
      `ifdef PICO_WARNINGS_OFF
      `else
           $display ("mc_log:  INFO:  ststr_sx_noreset instantiated as %m with strid %d", strid);
      `endif
   end
   // synopsys translate_on
   // VCS coverage on
   // pragma coverage on
   // coverage on



     wire                 pred_and_enable;
     reg [sdwidth-1:0]    unconsumed_data_ff;
     reg		  unsatisfied_req_ff;
     wire		   request_sent;
     wire 		   request_granted;
     wire 		   request_refused;
     wire [sdwidth+dwidth-1:0] data_padded;
     wire [sdwidth-1:0]   dataout_sig;
     

     assign pred_and_enable = (pred & enable);
     assign request_granted = (request_sent & str_ready);
     assign request_refused = (request_sent & ~str_ready);

     assign dataout_sig = data_padded[sdwidth-1:0];

     // hold and stallbar generation
     assign stallbar        = ~request_refused;
     always @ (`PICO_CLOCK_EDGE `PICO_CLOCK_SENSITIVITY `PICO_RESET_SENSITIVITY) begin
      if (`PICO_RESET_SENSITIVITY2) unsatisfied_req_ff <= 1'b0;
      else begin
	if (flush) unsatisfied_req_ff <= 1'b0;
	else unsatisfied_req_ff <= request_refused;
      end
     end

     always @ (`PICO_CLOCK_EDGE `PICO_CLOCK_SENSITIVITY) begin
       if (pred_and_enable)
         unconsumed_data_ff <= dataout_sig;
     end

     assign request_sent = unsatisfied_req_ff | pred_and_enable;
     assign str_req = request_sent;

     // sdwidth < dwidth not possible in pico-express created designs
     assign data_padded = sign ? {{sdwidth{datain[dwidth-1]}}, datain} :
                                 {{sdwidth{1'b0}}, datain};
     assign str_dataout = unsatisfied_req_ff ? unconsumed_data_ff : dataout_sig;

endmodule

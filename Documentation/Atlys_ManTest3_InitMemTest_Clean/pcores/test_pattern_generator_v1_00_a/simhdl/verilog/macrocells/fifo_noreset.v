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


`timescale 1ns / 1ps

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

`define PICO_ASYNC_RESET 0

`timescale 1 ns / 10 ps

module fifo_noreset (clk, indata, outdata, shiftq, addq, reset, flush, empty, full);

     parameter width = 16;
     parameter depth = 16;


input clk, shiftq, addq, reset, flush;
wire  clk, shiftq, addq, reset, flush;

input [width-1:0] indata;
wire [width-1:0] indata;

output  empty, full;
wire    empty, full;

output [width-1:0] outdata;
wire   [width-1:0] outdata;

reg  [width-1:0] fifo_ff[depth-1:0];

function integer clogb2(input integer depth);
 begin
     for (clogb2=0; depth>0; clogb2=clogb2+1)
          depth= depth>>1;
     end
 endfunction

reg [clogb2(depth)-1:0] addr_ff, count_ff ;
reg   full_ff, not_empty_ff, onefull_ff;

wire   addq_only, shiftq_only, shiftq_addq, empty_copy;

assign empty = empty_copy;
assign full  = full_ff;
assign empty_copy = ~not_empty_ff;

assign addq_only = (addq & !full_ff & (!shiftq |(shiftq & empty_copy)));
assign shiftq_only = (shiftq & !empty_copy & !addq);
assign shiftq_addq = (shiftq & addq & not_empty_ff);

always @ (`PICO_CLOCK_EDGE `PICO_CLOCK_SENSITIVITY  `PICO_RESET_SENSITIVITY ) begin
   if ((`PICO_ASYNC_RESET == 1) & (`PICO_RESET_SENSITIVITY2)) begin
       not_empty_ff <= 1'b0;
       full_ff      <= 1'b0;
       onefull_ff   <= 1'b0;
   end
   else if ((`PICO_ASYNC_RESET == 1) & (flush)) begin
       not_empty_ff <= 1'b0;
       full_ff      <= 1'b0;
       onefull_ff   <= 1'b0;
   end    
   else if ((`PICO_ASYNC_RESET == 0) & (`PICO_RESET_SENSITIVITY2 | flush)) begin
       not_empty_ff <= 1'b0;
       full_ff      <= 1'b0;
       onefull_ff   <= 1'b0;
   end
   else begin
      if (addq_only) begin    
          if (empty_copy) begin
              not_empty_ff <= 1'b1;
              onefull_ff <= 1'b1;
          end
          else if (depth>1) begin
              onefull_ff <= 1'b0;
          end
      end                     
 
      else if (shiftq_only)  begin
         if (onefull_ff)    begin
              not_empty_ff <= 1'b0;
              onefull_ff   <= 1'b0;

         end     
         else if (depth>1)  begin
             if (count_ff == 2'b10) begin
                 onefull_ff   <= 1'b1;
             end
         end     
      end   
      
      if (addq_only & (count_ff == depth-1))  full_ff <= 1'b1;
      else if (shiftq_only)   full_ff <= 1'b0;
             
   end
end 

integer  i;

always @ (`PICO_CLOCK_EDGE `PICO_CLOCK_SENSITIVITY  `PICO_RESET_SENSITIVITY ) begin
 if ((`PICO_ASYNC_RESET == 1) & (`PICO_RESET_SENSITIVITY2)) begin
     addr_ff <= {clogb2(depth){1'b0}};
 end
 else if ((`PICO_ASYNC_RESET == 1) & (flush)) begin
     addr_ff <= {clogb2(depth){1'b0}};
 end    
 else if ((`PICO_ASYNC_RESET == 0) & (`PICO_RESET_SENSITIVITY2 | flush)) begin
     addr_ff <= {clogb2(depth){1'b0}};
 end
 else begin
    if (addq_only & not_empty_ff) begin    
      addr_ff <= addr_ff + 1'b1;
    end 
    else if (shiftq_only & ~onefull_ff)  begin
      addr_ff <= addr_ff - 1'b1;
    end    
 end
end 


always @ (`PICO_CLOCK_EDGE `PICO_CLOCK_SENSITIVITY  `PICO_RESET_SENSITIVITY ) begin
  if ((`PICO_ASYNC_RESET == 1) & (`PICO_RESET_SENSITIVITY2)) begin
       count_ff <= {clogb2(depth){1'b0}};
  end
  else if ((`PICO_ASYNC_RESET == 1) & (flush)) begin
       count_ff <= {clogb2(depth){1'b0}};
  end    
  else if ((`PICO_ASYNC_RESET == 0) & (`PICO_RESET_SENSITIVITY2 | flush)) begin
       count_ff <= {clogb2(depth){1'b0}};
  end
  else begin
    if (addq_only) begin    
       count_ff <= count_ff + 1'b1;
    end 
    else if (shiftq_only)  begin
       count_ff <= count_ff - 1'b1;
    end 
  end
end 

always @ (`PICO_CLOCK_EDGE `PICO_CLOCK_SENSITIVITY) begin
     if (addq_only  | shiftq_addq ) begin
            for (i=depth-1; i>0; i=i-1) begin
              fifo_ff[i] <= fifo_ff[i-1];
            end
              fifo_ff[0]<= indata;
      end
end

assign  outdata = fifo_ff[addr_ff];

endmodule

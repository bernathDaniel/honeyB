`timescale 1ns/1ps
/***************************************/
/*              MatMul 2x2             */
/***************************************/

// NUM MEMS = How many memories | LOG2_LINES_PER NUM - 2^4=16 address lines
module xbox_xlr_dmy1 #(parameter NUM_MEMS=1,LOG2_LINES_PER_MEM=4)  (

  // XBOX memories interface

   // System Clock and Reset
   input clk,
   input rst_n, // asserted when 0

   // Accelerator XBOX mastered memories interface

   output logic [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0] xlr_mem_addr,  // address per memory instance - 16 addresses if LOG2=4

  // xlr_mem_wdata - for each address (row) has 8 words, each word has 32 bytes
   output logic [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_wdata, // 32 bytes write data interface per memory instance - 
   output logic [NUM_MEMS-1:0]      [31:0] xlr_mem_be,    // 32 byte-enable mask per data byte per instance.
   output logic [NUM_MEMS-1:0]             xlr_mem_rd,    // read signal per instance.
   output logic [NUM_MEMS-1:0]             xlr_mem_wr,    // write signal per instance.
   input        [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_rdata, // 32 bytes read data interface per memory instance

   // Command Status Register Interface
   input  [31:0][31:0] host_regs,                   // regs accelerator write data, reflecting registers content as most recently written by SW over APB
   input        [31:0] host_regs_valid_pulse,       // reg written by host (APB) (one per register)
                                                    
   output logic [31:0][31:0] host_regs_data_out,          // regs accelerator write data,  this is what SW will read when accessing the register
                                                    // provided that the register specific host_regs_valid_out is asserted
   output logic [31:0] host_regs_valid_out        // reg accelerator (one per register)  
);

//--------------------------------------------------------------------------------

/************************************************/
/*              Signal Declarations             */
/************************************************/

// Simple MatMul of a 2x2 matrix Performing A*B = C
// C(1,1) = A(1,1)B(1,1) + A(1,2)B(2,1) | C(1,2) = A(1,1)B(1,2) + A(1,2)B(2,2) and so on, each element 32-bits
// A = xlr_mem_rdata[0][3:0] in xlr_mem_addr[0][0] the first address, A(1,1) = word[0], A(1,2) = word[1] and so on
// B = xlr_mem_rdata[0][7:4] in xlr_mem_addr[0][0] the first address as well, B(1,1) = word[4] until B(2,2) = word[7]
// C = xlr_mem_wdata[0][3:0] in xlr_mem_addr[0][1] the second address, word[3:0].

// Start, busy, done signal definitions :

assign start = host_regs[0] && host_regs_valid_pulse;

 // if host_regs[0] = 32'h1 AND valid = 1'b1 then start = 1

logic busy;
assign host_regs_data_out[0] = {31'b0, busy}; // Define GPR[0] as busy for readability and communication to CPU.
assign host_regs_valid_out[0] = 1'b1; // Define GPR_out[0] as always valid so CPU always know if xlr is busy.

logic done;
assign host_regs_data_out[1] = {31'b0, done}; // Define GRP[1] as done for readability and communication to CPU.
assign host_regs_valid_out[1] = done; // Valid = 1 only if Result is ready for reading by CPU.

// States - IDLE, READ, MUL, SUM, DONE; 

logic [4:0] state, next_state;

localparam IDLE = 5'b00001;
localparam READ = 5'b00010;
localparam MUL = 5'b00100;
localparam SUM = 5'b01000;
localparam DONE = 5'b10000;

// Temp Mem Packed Array :

logic [7:0][31:0] mem_arr, next_mem_arr; // for storing the read data + multiplication data
logic [3:0][31:0] res_arr; // for storing the sum result and hold for writing back

/************************************************/
/*                  Sequentials                 */
/************************************************/

always @(posedge clk, negedge rst_n) begin // State Seq.
  if(!rst_n) state <= IDLE;
  else state <= next_state;
end

always @(posedge clk, negedge rst_n) begin // mem_arr Seq.
  if(!rst_n) mem_arr <= '0;
  else mem_arr <= next_mem_arr;
end

always @(posedge clk, negedge rst_n) begin // res_arr Seq.
  if(!rst_n) xlr_mem_wdata[0] <= '0;
  else xlr_mem_wdata[0][3:0] <= res_arr[3:0];
end

/************************************************/
/*                 Combinational                */
/************************************************/

always @* begin
  xlr_mem_addr = '{default: 32'h0};
  xlr_mem_be = 32'h0;
  xlr_mem_rd = 1'b0;
  xlr_mem_wr = 1'b0;
  busy = 1'b0;
  done = 1'b0;
  next_mem_arr = '{default: 32'h0};
  res_arr = '{default: 32'h0};
  next_state = IDLE;
  case(state)
    IDLE: begin
      if(start) begin // Start = 1 | Start reading information
        next_state = READ; // Move to Read, Request data from SRAM:
      end
      else next_state = IDLE;
    end
    READ: begin
      busy = 1'b1;
      xlr_mem_addr[0] = 4'h0; // Read from Addr 0
      xlr_mem_rd[0] = 1'b1; // En Read - Test
      xlr_mem_be[0] = 32'hFFFFFFFF; // En all 32 bits for rd per word;
      next_mem_arr = xlr_mem_rdata[0];
      next_state = MUL;
    end
    MUL: begin
      busy = 1'b1;
      next_mem_arr[0] = mem_arr[0] * mem_arr[4];
      next_mem_arr[1] = mem_arr[1] * mem_arr[6];
      next_mem_arr[2] = mem_arr[0] * mem_arr[5];
      next_mem_arr[3] = mem_arr[1] * mem_arr[7];
      next_mem_arr[4] = mem_arr[2] * mem_arr[4];
      next_mem_arr[5] = mem_arr[3] * mem_arr[6];
      next_mem_arr[6] = mem_arr[2] * mem_arr[5];
      next_mem_arr[7] = mem_arr[3] * mem_arr[7];
      next_state = SUM;
    end
    SUM: begin
      busy = 1'b1;
      res_arr[0] = mem_arr[0] + mem_arr[1];
      res_arr[1] = mem_arr[2] + mem_arr[3];
      res_arr[2] = mem_arr[4] + mem_arr[5];
      res_arr[3] = mem_arr[6] + mem_arr[7];
      next_state = DONE;
    end
    DONE: begin // During this state I'm writing to the SRAM, and signaling that I'm done.
      busy = 1'b0;
      done = 1'b1;
      xlr_mem_addr[0] = 4'h1; // Write Result into Addr[1]
      xlr_mem_wr[0] = 1'b1; // Enable Writing
      xlr_mem_be[0] = 32'hFFFFFFFF; // Enable all bits for writing in a word
      next_state = IDLE;
    end
    default: begin
      next_state = IDLE; // if something unexpected happens, go to IDLE and print msg:
      $display("Undefined behavior occured at: %t", $time);
    end
  endcase
end
endmodule

// A = xlr_mem_rdata[0][3:0] || B = xlr_mem_rdata[0][7:4] @ Addr : xlr_mem_addr[0]
// C = xlr_mem_wdata[1][3:0] @ Addr : xlr_mem_addr[1]
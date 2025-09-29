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
//==================================================================================================================================
// FUNCTIONALITIES

  /**********************************************************************/
  /*                           FUNCTIONALITIES                          */
  /**********************************************************************/

  /*
    Note for unpacked 32-byte signed computations:
  //--------------------------------------------------
    In a case like this we'd have 8-bits (Unsigned: 0 <= val <= 255 | Signed: -128 <= s_val <= 127)
    This means that both the *MULTIPLER* and *MULTIPLICAND* are restricted:
  //-------------------------------------------------
  //
  //[-11 <= MR, MD <= 11] -> 5-bits max, OVFLW SAFE!
  //
  //-------------------------------------------------
  */

  /*
    Simple MatMul of a 2x2 matrix Performing A*B = C :
  //-----------------------------------------------------

    C(1,1) = A(1,1)B(1,1) + A(1,2)B(2,1) | C(1,2) = A(1,1)B(1,2) + A(1,2)B(2,2) and so on, each element 32-bits
    A = xlr_mem_rdata[0][3:0] in xlr_mem_addr[0][0] the first address, A(1,1) = word[0], A(1,2) = word[1] and so on
    B = xlr_mem_rdata[0][7:4] in xlr_mem_addr[0][0] the first address as well, B(1,1) = word[4] until B(2,2) = word[7]
    C = xlr_mem_wdata[0][3:0] in xlr_mem_addr[0][1] the second address, word[3:0].

  */
//==================================================================================================================================
// ENUMERATIONS

  // Memory enumeration - Update when NUM_MEMS changes
  // ---------------------------------------------------
  typedef enum logic [$clog2(NUM_MEMS)-1:0] {
    MEM0 = 0,
    MEM1 = 1
  } x_mem;

  // SW-HW Register allocation indices
  // ---------------------------------------------------
  enum {
    START_REG_IDX,  // 0 |Index of the register indicating GO_HONEY
    BUSY_REG_IDX,   // 1 |Index of the register indicating BUSY
    DONE_REG_IDX    // 2 |Index of the register indicating DONE
  } regs_idx;
//==================================================================================================================================
// DECLARATIONS

  logic start_honey;    // The actual signal fed into our FSM.
  logic calcopy_honey;  // The calcopy honey
  logic calcopy_en;     // Enable the calcopy honey

  logic busy;
  logic done;

  logic [NUM_MEMS-1:0][7:0][31:0] mem_arr;             // mem buffer
  logic [NUM_MEMS-1:0][7:0][31:0] res_arr, res_arr_ps; // pre-sampling + buffer for write
//==================================================================================================================================
// HOST REGS INTERFACE 

  logic [31:0][31:0] host_regs_data_out_ps; // pre-sampled CS output 


  always_comb begin // Update comb logic - BUSY & DONE allocated registers
    host_regs_data_out_ps = host_regs_data_out;
      //$monitor("[XLR DUT]: host_regs_data_out = %0h changes at %0t", host_regs_data_out, $time);  // prints on signal changes

    if (done) host_regs_data_out_ps[DONE_REG_IDX] = 32'h1;  // Update     
    else      host_regs_data_out_ps[DONE_REG_IDX] = 32'h0;  // Clear

    if (busy) host_regs_data_out_ps[BUSY_REG_IDX] = 32'h1;  // Update
    else      host_regs_data_out_ps[BUSY_REG_IDX] = 32'h0;  // Clear
  end 


  always @(posedge clk, negedge rst_n) begin // Sample host regs output
    if(~rst_n) host_regs_data_out <= '0;
    else       host_regs_data_out <= host_regs_data_out_ps;  
  end


  always_comb begin // Update output host registers
    host_regs_valid_out               = '0; // Default
    host_regs_valid_out[DONE_REG_IDX] = (host_regs_data_out[DONE_REG_IDX] == 32'h1);
    host_regs_valid_out[BUSY_REG_IDX] = 1'b1;
  end

  // GPR Cloning Nomenclatures
  //======================================================
  assign start_honey    = (host_regs[START_REG_IDX] == 32'h1) && host_regs_valid_pulse[START_REG_IDX];
  assign calcopy_honey  = (host_regs[START_REG_IDX] == 32'h2) && host_regs_valid_pulse[START_REG_IDX];
//==================================================================================================================================

  /**********************************************************************/
  /*                           STATE MACHINE                            */
  /**********************************************************************/

  /*--------------------------*/
  /*        Definitions       */
  /*--------------------------*/

  typedef enum logic [4:0] { // 1-Hot Enoding for Performance
    IDLE  = 5'b00001,
    READ  = 5'b00010,
    CALC  = 5'b00100,
    WRITE = 5'b01000,
    DONE  = 5'b10000
  } state_machine;

  state_machine state, next_state;
//==================================================================================================================================


/************************************************/
/*                  Sequentials                 */
/************************************************/

always @(posedge clk, negedge rst_n) begin // State Seq.
  if(!rst_n) state <= IDLE;
  else state <= next_state;
end

//-----------------------------------------------------------------//

always @(posedge clk, negedge rst_n) begin // Sequential FSM
  if (!rst_n) begin 
    mem_arr <= '0;
    res_arr <= '0;
  end else if (calcopy_honey)
    calcopy_en <= 1'b1;
  else if (state == READ) begin
    mem_arr[MEM0] <= xlr_mem_rdata[MEM0];
  end else if (state == CALC) begin
    if (calcopy_en) res_arr[MEM1] <= res_arr_ps[MEM0]; // Copy result into [MEM1] too
                    res_arr[MEM0] <= res_arr_ps[MEM0];
  end else if (state == DONE) calcopy_en <= 1'b0;
end

/************************************************/
/*                 Combinational                */
/************************************************/

always @* begin
  xlr_mem_addr = '{default: 32'h0};
  xlr_mem_be = 32'h0;
  xlr_mem_rd = 1'b0;
  xlr_mem_wr = 1'b0;
  busy = 1'b1;
  done = 1'b0;
  xlr_mem_wdata = res_arr;
  next_state = IDLE;
  case(state)
    IDLE: begin
      busy = 1'b0;
      if(start_honey || calcopy_honey) begin // Start = 1 | Start reading information
        xlr_mem_addr[MEM0]  = 8'h00; // Read from Addr[0]
        xlr_mem_rd  [MEM0]  = 1'b1;  // En Read
        next_state          = READ;  // Move to Read, Sample in next posedge
          //$monitor("[XLR DUT]: at %0t\n\t\t\tstart_honey = %0h\n\t\t\tcalcopy_honey = %0h ", $time, start_honey, calcopy_honey);
      end
      else next_state = IDLE;
    end
    READ: begin
      next_state  = CALC;
        //$monitor("[XLR DUT]: xlr_mem_rdata = %0h changes at %0t", xlr_mem_rdata[0], $time);
    end
    CALC: begin
      next_state = WRITE;
                        // Calc
      res_arr_ps[MEM0][0] = mem_arr[MEM0][0] * mem_arr[MEM0][4] + mem_arr[MEM0][1] * mem_arr[MEM0][6];
      res_arr_ps[MEM0][1] = mem_arr[MEM0][0] * mem_arr[MEM0][5] + mem_arr[MEM0][1] * mem_arr[MEM0][7];
      res_arr_ps[MEM0][2] = mem_arr[MEM0][2] * mem_arr[MEM0][4] + mem_arr[MEM0][3] * mem_arr[MEM0][6];
      res_arr_ps[MEM0][3] = mem_arr[MEM0][2] * mem_arr[MEM0][5] + mem_arr[MEM0][3] * mem_arr[MEM0][7];
      res_arr_ps[MEM0][7:4] = '0; // 0 out the unused
    end // -> Data Sampled into res_arr & ready to write
    WRITE: begin                         // WR REQ
      xlr_mem_addr[MEM0] = 8'h01;        // Write Result into Addr[1]
      xlr_mem_wr  [MEM0] = 1'b1;         // En Writing
      xlr_mem_be  [MEM0] = 32'hFFFFFFFF; // En all bits for writing in a word ( Gate Enabled for Sampling by Memory)
      if (calcopy_en) begin
        xlr_mem_addr[MEM1] = 8'h01;        // Write Result into Addr[MEM1][1] !
        xlr_mem_wr  [MEM1] = 1'b1;         
        xlr_mem_be  [MEM1] = 32'hFFFFFFFF; // Mimicking the same operations on MEM[1]
      end
      next_state = DONE;
    end
    DONE: begin
      busy = 1'b0;
      done = 1'b1;
       //$monitor("[XLR DUT]: changes at %0t\nxlr_mem_wdata[0] = %h\nxlr_mem_wdata[1] = %h", $time, xlr_mem_wdata[0], xlr_mem_wdata[1]);

      next_state = IDLE;
    end
    default: begin
      next_state = IDLE; // if something unexpected happens, go to IDLE and print msg:
      $display("Undefined behavior occured at: %t", $time);
    end
  endcase
end
endmodule
`timescale 1ns/1ps
/***************************************/
/*              MatMul 2x2             */
/***************************************/

module xbox_xlr_dmy1 #(parameter NUM_MEMS=2,LOG2_LINES_PER_MEM=8)  (

  // XBOX memories interface

   // System Clock and Reset
   input clk,
   input rst_n, // asserted when 0

   // Accelerator XBOX mastered memories interface

   output logic [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0] xlr_mem_addr, // address per memory instance - 256 addresses if LOG2=8

  // xlr_mem_wdata - for each address (row) has 8 words, each word has 32 bytes
   output logic [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_wdata, // 32 bytes write data interface per memory instance - 
   output logic [NUM_MEMS-1:0]      [31:0] xlr_mem_be,    // 32 byte-enable mask per data byte per instance.
   output logic [NUM_MEMS-1:0]             xlr_mem_rd,    // read signal per instance.
   output logic [NUM_MEMS-1:0]             xlr_mem_wr,    // write signal per instance.
   input        [NUM_MEMS-1:0] [7:0][31:0] xlr_mem_rdata, // 32 bytes read data interface per memory instance

   // Command Status Register Interface
   input  [31:0][31:0] host_regs,                         // regs accelerator write data, reflecting registers content as most recently written by SW over APB
   input        [31:0] host_regs_valid_pulse,             // reg written by host (APB) (one per register)
                                                    
   output logic [31:0][31:0] host_regs_data_out,          // regs accelerator write data,  this is what SW will read when accessing the register
                                                          // provided that the register specific host_regs_valid_out is asserted
   output logic [31:0] host_regs_valid_out                // reg accelerator (one per register)

   //input [18:0]        trig_soc_xmem_wr_addr,           // optional trigger, XBOX memory address accessed by SOC (processor/apb)
   //input               trig_soc_xmem_wr                 // optional trigger, validate actual SOC xmem wr access  
);
//==================================================================================================================================

  /**********************************************************************/
  /*                           FUNCTIONALITIES                          */
  /**********************************************************************/

  /* 
    Simple MatMul of a 2x2 matrix Performing A*B = C :
    -----------------------------------------------------

    C(1,1) = A(1,1)B(1,1) + A(1,2)B(2,1) | C(1,2) = A(1,1)B(1,2) + A(1,2)B(2,2) and so on, each element 32-bits
    A = xlr_mem_rdata[0][3:0] in xlr_mem_addr[0][0] the first address, A(1,1) = word[0], A(1,2) = word[1] and so on
    B = xlr_mem_rdata[0][7:4] in xlr_mem_addr[0][0] the first address as well, B(1,1) = word[4] until B(2,2) = word[7]
    C = xlr_mem_wdata[0][3:0] in xlr_mem_addr[0][1] the second address, word[3:0].

    */

//==================================================================================================================================

  /**********************************************************************/
  /*                             DECLARATIONS                           */
  /**********************************************************************/                                                                                           /*

  Parameters
  ======================================================                                                                                                              */

  // Byte Size & Number
  // ----------------------------------------------
  localparam BYTE_WIDTH = 8 ;
  localparam NUM_BYTES  = 32;
  localparam FIRST_BYTE = 0;
  localparam LAST_BYTE  = NUM_BYTES - 1;

  // rows (addr lines) = 2^LOG2_LINES_PER_MEM
  // ----------------------------------------------
  localparam MAX_HEIGHT = 1 << LOG2_LINES_PER_MEM; /* = 2^8 = 256                                                                                                                     *//*

  
  Variables
  ======================================================                                                                                                         */
  
  // Memory enumeration - Update when NUM_MEMS changes
  // ---------------------------------------------------
  typedef enum logic [$clog2(NUM_MEMS)-1:0] {
    MEM0 = 0,
    MEM1 = 1
  } x_mem;

  x_mem        mem_xlr            ; // Contains MEM0, MEM1 (... up to MEM7)


  logic        go_honey           ; // go honey
  logic [31:0] matA_base_addr     ; // For the base address - Assuming a trivilal zero for project.
  logic [31:0] matBT_base_addr    ; // For the base address - Assuming a trivilal zero for project.
  logic [31:0] out_mat_base_addr  ; // For the output matrix base address - Also Assuming a trivial zero for the project.
  logic [31:0] matA_rows_H        ; // Each row in matA represent a single row vector 1x32, a total of N rows
  logic [31:0] matBT_cols_H       ; // MatB is received as a transposed matrix, B^T = 32xM in the memory
                                    // It's represented seen as B = Mx32 !
                                    // Effectively perfroming a Horizontal Byte-Byte multiplication where:
                                    // Each row_H from matA multiplies *ALL* of matB's cols_H, H -> Horizontal Vector Multiplication


  logic busy;
  logic done;
  //---------------------------------------------------------------------------------//
  //    | Element Size |                |  2D Array  || Ascending upckd Notation |
  logic [BYTE_WIDTH-1:0] A_BT_mat_upckd [NUM_MEMS-1:0][0:NUM_BYTES-1             ];
  //---------------------------------------------------------------------------------//
  
  logic [3:0][31:0] res_arr; /* for storing the sum result and hold for writing back                                                                                 *//*

                                                                                                                                                        
  Optionals for later use
  ======================================================                                                                                                                   */                                                                                                           

  // Row Buffers
  // --------------------------------------------------
  // logic [7:0][31:0] new_row_buf;               // Holds the      sampled row
  // logic [7:0][31:0] updated_row_ps;            // Holds the pre -sampled result
  // logic [7:0][31:0] updated_row_ps;            // Holds the post-sampled result


  // Current addr pointers to matrix
  // --------------------------------------------------
  // logic [TBD-1:0] crnt_rd_addr;
  // logic [TBD-1:0] crnt_wr_addr;


  // Matrix row variables & Useful flags
  // --------------------------------------------------
  // logic [$clog2(MAX_ROWS):0] mat_rd_row_idx;   // Current matrix read  index
  // logic [$clog2(MAX_ROWS):0] mat_wr_row_idx;   // Current matrix write index
  // logic [$clog2(MAX_ROWS):0] mat_rows;         // Matrix  total  rows

  // logic                      next_is_last_row; // Indicate next row will be last (Useful for border handling)
  // logic                      is_last_row;      // Indicate we are at the last row


  // SW-HW Register allocation indices
  // ---------------------------------------------------
  enum {
    MAT_A_BASE_ADDR_REG_IDX     ,     // 0 |Index of the register holding the base address
    MAT_BT_BASE_ADDR_REG_IDX    ,     // 1 |Index of the register holding the base address
    OUT_MAT_BASE_ADDR_REG_IDX   ,     // 2 |Index of the register holding the base address
    MAT_A_HEIGHT_H_REG_IDX      ,     // 3 |Index of the register holding the matrix height  - **HORIZONTAL**
    MAT_B_WIDTH_H_REG_IDX       ,     // 4 |Index of the register holding the matrix width   - **HORIZONTAL**
    GO_HONEY_REG_IDX                  ,     // 5 |Index of the register indicating GO_HONEY
    BUSY_REG_IDX                ,     // 6 |Index of the register indicating BUSY
    DONE_REG_IDX                ,     // 7 |Index of the register indicating DONE
  } regs_idx;
//==================================================================================================================================

//==================================================================================================================================

  /**********************************************************************/
  /*                         HOST REGS INTERFACE                        */
  /**********************************************************************/

  logic [31:0][31:0] host_regs_data_out_ps; // pre-sampled CS output 


  always_comb begin // Update comb logic - BUSY & DONE allocated registers
    host_regs_data_out_ps = host_regs_data_out;

    if (done) host_regs_data_out_ps[DONE_REG_IDX][0] = 1'b1;  // Update     
    else      host_regs_data_out_ps[DONE_REG_IDX][0] = 1'b0;  // Clear

    if (busy) host_regs_data_out_ps[BUSY_REG_IDX][0] = 1'b1;  // Update
    else      host_regs_data_out_ps[BUSY_REG_IDX][0] = 1'b0;  // Clear
  end 


  always @(posedge clk, negedge rst_n) begin // Sample host regs output
    if(~rst_n) host_regs_data_out <= '0;
    else       host_regs_data_out <= host_regs_data_out_ps;  
  end

  
  always_comb begin // Update output host registers
    host_regs_valid_out               = '0; // Default
    host_regs_valid_out[DONE_REG_IDX] = host_regs_data_out[DONE_REG_IDX][0];
    host_regs_valid_out[BUSY_REG_IDX] = 1'b1;
  end                                                                                                                                                                                             /*


  CSR Cloning Nomenclatures
  ======================================================                                                                                                                                       */

  assign go_honey           = host_regs[GO_HONEY_REG_IDX][0] && host_regs_valid_pulse[GO_HONEY_REG_IDX]; // = 32'h1 !          
  assign matA_base_addr     = host_regs[GO_HONEY_REG_IDX]
  assign matBT_base_addr    = host_regs[GO_HONEY_REG_IDX]
  assign out_mat_base_addr  = host_regs[GO_HONEY_REG_IDX]
  assign matA_rows_H        = host_regs[GO_HONEY_REG_IDX]
  assign matBT_cols_H       = host_regs[GO_HONEY_REG_IDX]
//==================================================================================================================================

//==================================================================================================================================

  /**********************************************************************/
  /*                           STATE MACHINE                            */
  /**********************************************************************/

  /*--------------------------*/
  /*        Definitions       */
  /*--------------------------*/

  typedef enum logic [4:0] { // 1-Hot Enoding for Performance
    IDLE = 5'b00001;
    READ = 5'b00010;
    MUL  = 5'b00100;
    SUM  = 5'b01000;
    DONE = 5'b10000;
  } state_machine;

  state_machine state, next_state;


  /************************************************/
  /*                 Combinational                */
  /************************************************/

  always @* begin

    xlr_mem_addr  = '{default: 32'h0};
    xlr_mem_be    = '0;
    xlr_mem_rd    = '0;
    xlr_mem_wr    = '0;
    busy          = '0;
    done          = '0;
    next_mem_arr  = '{default: 32'h0};
    res_arr       = '{default: 32'h0};
    next_state    = IDLE;

    case(state)

      IDLE: begin
        if (go_honey) begin
          next_state = READ; // Move to Read, Request data from SRAM:
          xlr_mem_rd[MEM0]  = 1'b1;
        end else next_state = IDLE;
      end

      READ: begin
        busy = 1'b1;
        xlr_mem_addr[MEM0]  = 8'h0;                 // Read from Addr 0
        xlr_mem_rd[MEM0]    = 1'b1;                 // En Read - Test
        next_mem_arr        = xlr_mem_rdata[MEM0];
        next_state          = MUL;
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
        next_state      = SUM;
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
        busy            = 1'b0;
        done            = 1'b1;
        xlr_mem_addr[0] = 4'h1;         // Write Result into Addr[1]
        xlr_mem_wr[0]   = 1'b1;         // Enable Writing
        xlr_mem_be[0]   = 32'hFFFFFFFF; // Enable all bits for writing in a word
        next_state      = IDLE;
      end

      default: begin
        next_state      = IDLE; // if something unexpected happens, go to IDLE and print msg:
        $display("Undefined behavior occured at: %t", $time);
      end
    endcase
  end

  /************************************************/
  /*                  Sequentials                 */
  /************************************************/

  //~~~~~~~~~~~~~~~~~~~~~~~~~~| FSM |~~~~~~~~~~~~~~~~~~~~~~~~~~~~//
  
  always @(posedge clk, negedge rst_n) begin // State Seq.
    if(!rst_n) state <= IDLE;
    else state <= next_state;
  end

  // FSM Control
  // ------------------------------

  always @(posedge clk, negedge rst_n) begin
    if (!rst_n) 

  end



  always @(posedge clk, negedge rst_n) begin // mem_arr Seq.
    if(!rst_n) mem_arr <= '0;
    else mem_arr <= next_mem_arr;
  end

  always @(posedge clk, negedge rst_n) begin // res_arr Seq.
    if(!rst_n) xlr_mem_wdata <= '0;
    else xlr_mem_wdata[0][3:0] <= res_arr[3:0];
  end
endmodule
//==================================================================================================================================

//==================================================================================================================================

  /**********************************************************************/
  /*                        BYTE ENABLE KNOWHOW                         */
  /**********************************************************************/                                                                                                /*

  [NUM_MEMS-1:0][31:0] xlr_mem_be || Memory Layout : [7:0][31:0] = 8 words * 4 bytes = 32 bytes
  xlr_mem_be[mem_idx][31:0] maps directly to these 32 bytes:

  ~ Format for use:
  -----------------------
  xlr_mem_be[mem_idx][31:0] 32'h7654_3210;
  
  The numbers [0,..,7] represent each word, this means : 32'h000A_0000; Will Access Word 4

  xlr_mem_be[mem_idx][0 ] -> Byte 0 (word 0, bits[7:0  ])
  xlr_mem_be[mem_idx][1 ] -> Byte 1 (word 0, bits[15:8 ])
  xlr_mem_be[mem_idx][2 ] -> Byte 2 (word 0, bits[23:16])
  xlr_mem_be[mem_idx][3 ] -> Byte 3 (word 0, bits[31:24])
  xlr_mem_be[mem_idx][4 ] -> Byte 4 (word 1, bits[7:0  ])
  xlr_mem_be[mem_idx][5 ] -> Byte 5 (word 1, bits[15:8 ])
    .
    .
    .
  xlr_mem_be[mem_idx][31] -> Byte 7 (word 7, bits[31:24])

  Practical Examples - Word Access
  *********************************

  ~ Write entire first word (bytes 0-3):
  ----------------------------------------
  xlr_mem_be = 32'h0000_000F;  // bits [3:0] = 1

  ~ Write entire last word (bytes 28-31):
  ----------------------------------------
  xlr_mem_be = 32'hF000_0000;  // bits [31:28] = 1

  ~ Write all bytes (full 256-bit line):
  ----------------------------------------
  xlr_mem_be = 32'hFFFF_FFFF;  // all bits = 1

  Practical Examples - Byte Access
  *********************************

  1) Access only within word 0:
  --------------------------------------------
  ~ Access only byte 0 (bits [7:0] of word 0):
  xlr_mem_be = 32'h0000_0001;  // A = 1

  ~ Access only byte 1 (bits [15:8] of word 0):
  xlr_mem_be = 32'h0000_0002;  // A = 2

  ~ Access only byte 2 (bits [23:16] of word 0):
  xlr_mem_be = 32'h0000_0004;  // A = 4

  ~ Access only byte 3 (bits [31:24] of word 0):
  xlr_mem_be = 32'h0000_0008;  // A = 8

  2) Access only within word 5:
  --------------------------------------------
  // Access only byte 20 (bits [7:0] of word 5):
  xlr_mem_be = 32'h0010_0000;  // bit [20] = 1

  // Access only byte 21 (bits [15:8] of word 5):
  xlr_mem_be = 32'h0020_0000;  // bit [21] = 1

  // Access only byte 22 (bits [23:16] of word 5):
  xlr_mem_be = 32'h0040_0000;  // bit [22] = 1

  // Access only byte 23 (bits [31:24] of word 5):
  xlr_mem_be = 32'h0080_0000;  // bit [23] = 1

  General Pattern Accesses
  *********************************

  1) One-Byte Access:
  -------------------------
  A = 2^Byte | Byte = [0,3]

  2) Two-Bytes Access:
  -------------------------
  A = 2^ByteX + 2^ByteY | ByteX, ByteY = [0,3]

  3) Three-Bytes Access:
  -------------------------
  A = 2^ByteX + 2^ByteY + 2^ByteZ | ByteX, ByteY, ByteZ = [0,3]

  ============================================================================                                                                                       */
  
  // Extras:
  // ------------------------------------
  // A = xlr_mem_rdata[0][3:0] || B = xlr_mem_rdata[0][7:4] @ Addr : xlr_mem_addr[0]
  // C = xlr_mem_wdata[1][3:0] @ Addr : xlr_mem_addr[1]
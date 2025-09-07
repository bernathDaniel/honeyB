//=============================================================================
// Project  : HoneyB V3
// File Name: xlr_mem_if.sv
//=============================================================================
// Description: Signal interface for agent xlr_mem
//=============================================================================

`ifndef XLR_MEM_IF_SV
`define XLR_MEM_IF_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*; // for parameters
import xlr_mem_pkg::*; // for parameterized _if

interface xlr_mem_if #( parameter
  NUM_MEMS = 1,
  LOG2_LINES_PER_MEM = 4
) (
  input logic clk,
  input logic rst_n
);

  timeunit      1ns;
  timeprecision 1ps;

  // Inputs
  logic [NUM_MEMS-1:0] [7:0][31:0] mem_rdata;

  // Outputs
  logic [NUM_MEMS-1:0] [LOG2_LINES_PER_MEM-1:0] mem_addr;
  logic [NUM_MEMS-1:0] [7:0][31:0]              mem_wdata;
  logic [NUM_MEMS-1:0] [31:0]                   mem_be;
  logic [NUM_MEMS-1:0]                          mem_rd;
  logic [NUM_MEMS-1:0]                          mem_wr;

  // Setting the class parameters to 0 - Default values to emphasize that we're factory overriding them later

  class xlr_mem_class #(int NUM_MEMS = 0, int LOG2_LINES_PER_MEM = 0) extends xlr_mem_if_base;
    `uvm_component_param_utils(xlr_mem_class#(NUM_MEMS,LOG2_LINES_PER_MEM))

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // GET Methods for accessing the signals of the interface.

    function logic get_clk();
      return clk;
    endfunction : get_clk

    function logic get_rst();
      return rst_n;
    endfunction : get_rst

    function logic [7:0][31:0] get_mem_rdata(input x_mem m);
      return mem_rdata[int'(m)];
    endfunction : get_mem_rdata

    function logic [LOG2_LINES_PER_MEM-1:0] get_mem_addr(input x_mem m);
      return mem_addr[int'(m)];
    endfunction : get_mem_addr

    function logic [7:0][31:0] get_mem_wdata(input x_mem m);
      return mem_wdata[int'(m)];
    endfunction : get_mem_wdata

    function logic [31:0] get_mem_be(input x_mem m);
      return mem_be[int'(m)];
    endfunction : get_mem_be

    function logic get_mem_rd(input x_mem m);
      return mem_rd[int'(m)];
    endfunction : get_mem_rd

    function logic get_mem_wr(input x_mem m);
      return mem_wr[int'(m)];
    endfunction : get_mem_wr

    task rd(
      input x_mem m,
      input logic [7:0][31:0] m_rdata
      );
      mem_rdata[int'(m)] <= m_rdata;
    endtask : rd

    // will be implemented later !! after changing this make the same change for wr's I/Os !!
    /*task wr(
      input logic [NUM_MEMS-1:0]                          m_wr,
      input logic [NUM_MEMS-1:0] [LOG2_LINES_PER_MEM-1:0] m_addr,
      input logic [NUM_MEMS-1:0] [31:0]                   m_be,
      input logic [NUM_MEMS-1:0] [7:0][31:0]              m_wdata
      );
      `honeyb("WRITE TASK", "CURRENTLY EMPTY", "Nothin' to see here") // Added because it seems that if empty it does an error
      mem_wr <= m_wr;
      mem_addr <= m_addr;
      mem_be <= m_be;
      mem_wdata <= m_wdata; // these are added as defaults to prevent errors - change later
    endtask : wr*/

    task wait4rd_req(input x_mem m);
      wait (mem_rd[int'(m)] == 1'b1 && mem_addr[int'(m)][0] == '0);
    endtask : wait4rd_req

    task wait4wr_req(input x_mem m);
      wait (mem_wr[int'(m)] == 1'b1);
    endtask : wait4wr_req

    task posedge_clk(); // posedge clk delay
      @(posedge clk);
    endtask : posedge_clk

    task negedge_clk(); // negedge clk delay
      @(negedge clk);
    endtask : negedge_clk

    task wait4rst_n(); // wait for rst_n deassertion
      @(posedge rst_n);
    endtask : wait4rst_n

  endclass : xlr_mem_class
  
  // Function to override abstract base class with concrete implementation of class
  // called from tb_prepend_to_initial.sv
  // The path_name is key to overriding the correct parameterized instantiation

  function void use_concrete_class();
    string path_name;
    path_name = $sformatf("*.xlr_mem_if_%0d_%0d", NUM_MEMS, LOG2_LINES_PER_MEM);
    xlr_mem_if_base::type_id::set_inst_override( xlr_mem_class#(NUM_MEMS,LOG2_LINES_PER_MEM)::get_type(), path_name, null);
  endfunction : use_concrete_class
endinterface : xlr_mem_if

`endif // XLR_MEM_IF_SV
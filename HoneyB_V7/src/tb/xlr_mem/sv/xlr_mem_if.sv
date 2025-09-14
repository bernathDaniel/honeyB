//=============================================================================
// Project  : HoneyB V7
// File Name: xlr_mem_if.sv
//=============================================================================
// Description: Signal interface for agent xlr_mem
//=============================================================================

`ifndef XLR_MEM_IF_SV
`define XLR_MEM_IF_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_mem_pkg::*;

interface xlr_mem_if #( parameter
  NUM_MEMS = 2,
  LOG2_LINES_PER_MEM = 8
) (
  input logic clk,
  input logic rst_n
);

  // Memory Sizing Parameters
  // ===================================

  int unsigned m_num_mems;
  int unsigned m_log2_lines_per_mem;
  int unsigned m_addr;

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
    endfunction // boilerplate

    //================================================
    //                 Get Methods                   
    //================================================

    // Clock Methods
    // =============
      function logic  get_clk();             return  clk;    endfunction
      task            clk_posedge_wait();  @(posedge clk);   endtask
      task            clk_negedge_wait();  @(negedge clk);   endtask

    // Reset Methods
    // =============
      function logic  get_rst_n();                 return  rst_n;           endfunction
      // Wait for Assertion (Interruption handling)
      task            rst_n_negedge_wait();      @(negedge rst_n);          endtask
      task            rst_n_posedge_wait();      @(posedge rst_n);          endtask
      task            rst_n_wait_until_deassert(); wait(   rst_n);          endtask


    // Read Data Methods
    // =================
      function logic [NUM_MEMS-1:0][7:0][31:0] get_rdata_all();          return mem_rdata;          endfunction
      function logic               [7:0][31:0] get_rdata(input x_mem m); return mem_rdata[int'(m)]; endfunction

    // Address Methods
    // ===============
      function logic [NUM_MEMS-1:0][LOG2_LINES_PER_MEM-1:0] get_addr_all();           return mem_addr;          endfunction
      function logic               [LOG2_LINES_PER_MEM-1:0] get_addr(input x_mem m);  return mem_addr[int'(m)]; endfunction

    // Write Data Methods
    // ==================
      function logic [NUM_MEMS-1:0][7:0][31:0] get_wdata_all();           return mem_wdata;           endfunction
      function logic               [7:0][31:0] get_wdata(input x_mem m);  return mem_wdata[int'(m)];  endfunction

    // Byte Enable Methods
    // ===================
      function logic [NUM_MEMS-1:0][31:0] get_be_all();           return mem_be;          endfunction
      function logic               [31:0] get_be(input x_mem m);  return mem_be[int'(m)]; endfunction

    // Read Control Methods
    // ====================
      function logic [NUM_MEMS-1:0] get_rd_all();                          return mem_rd;                     endfunction
      function logic                get_rd(input x_mem m);                 return mem_rd[int'(m)];            endfunction
      task                          rd_wait_until_asserted(input x_mem m); while(    mem_rd[int'(m)] != 1'b1 
                                                                                  && rst_n) // Reset Handling For
                                                                                            // Unexpected Resets!
                                                                                              @(posedge clk); endtask
      task wait_for_dut_rd_request();
        forever begin
          @(posedge clk);
          for (int m = 0; m < NUM_MEMS; m++) begin
            if (get_rd(x_mem'(m))) return;
          end // mem_rd "Polling" // - MONITOR
        end
      endtask
                                                                                              
      

    // Write Control Methods
    // =====================
      function logic [NUM_MEMS-1:0] get_wr_all();                           return mem_wr;                    endfunction
      function logic                get_wr(input x_mem m);                  return mem_wr[int'(m)];           endfunction
      task                          wr_wait_until_asserted(input x_mem m);  while(     mem_wr[int'(m)] != 1'b1 
                                                                                    && rst_n) // Reset Handling For
                                                                                              // Unexpected Resets!
                                                                                                @(posedge clk); endtask

      task wait_for_dut_wr_request();
        forever begin
          @(posedge clk);
          for (int m = 0; m < NUM_MEMS; m++) begin
            if (get_wr(x_mem'(m))) return;
          end // mem_wr "Polling" // - MONITOR
        end
      endtask


    // Pin Wiggling Methods
    // ====================
      task pin_wig_rst();                 mem_rdata <= '0;                endtask
      task pin_wig_rdata(
        input x_mem m,
        input logic [7:0][31:0] m_rdata); mem_rdata[int'(m)] <= m_rdata;  endtask

    // Frontdoor Driver Methods
    //===========================
      function bit [NUM_MEMS-1:0] get_active_rd_mems();
        for (int m = 0; m < NUM_MEMS; m++) begin
          get_active_rd_mems[m] = get_rd(x_mem'(m));
        end // Implicit array return 
      endfunction 

      function bit [NUM_MEMS-1:0] get_active_wr_mems();
        for (int m = 0; m < NUM_MEMS; m++) begin
          get_active_wr_mems[m] = get_wr(x_mem'(m));
        end // Implicit array return 
      endfunction

      task wait_for_dut_request(); // For the Driver
        forever begin
          @(posedge clk);
          for (int m = 0; m < NUM_MEMS; m++) begin
            if (get_rd(x_mem'(m)) || get_wr(x_mem'(m))) return;
          end // DUT "Polling"
        end
      endtask

      task wait_for_rd_sampling();
        forever begin
          @(posedge clk);
          for (int m = 0; m < NUM_MEMS; m++) begin
            if (get_rd(x_mem'(m))) return;
          end // mem_rd "Polling" // - MONITOR
        end
      endtask

      task wait_for_wr_sampling();
        forever begin
          @(posedge clk);
          for (int m = 0; m < NUM_MEMS; m++) begin
            if (get_wr(x_mem'(m))) return;
          end // mem_wr "Polling" // - MONITOR
        end
      endtask
  endclass : xlr_mem_class

  //=======================================================================
  //                          CONCRETE CLASS                             
  //=======================================================================

    function void use_concrete_class();
      string path_name;
      path_name = $sformatf("*.xlr_mem_if_%0d_%0d", NUM_MEMS, LOG2_LINES_PER_MEM);
      xlr_mem_if_base::type_id::set_inst_override( xlr_mem_class#(NUM_MEMS,LOG2_LINES_PER_MEM)::get_type(), path_name, null);
    endfunction : use_concrete_class
endinterface : xlr_mem_if

`endif // XLR_MEM_IF_SV
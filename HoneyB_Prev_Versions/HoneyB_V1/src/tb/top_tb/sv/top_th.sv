//=============================================================================
// Project  : HoneyB V1
// File Name: top_th.sv
//=============================================================================
// Description: Test Harness
//=============================================================================

module top_th;

  timeunit      1ns;
  timeprecision 1ps;

  logic clk;
  logic rst_n;
  parameter hclk_per = 4;

  // Pin-level interfaces connected to DUT

  xlr_mem_if _mem_if (
    .clk(clk),
    .rst_n(rst_n)
  );

  xlr_gpp_if _gpp_if (
    .clk(clk),
    .rst_n(rst_n)
  );

  //**************************************//
  // IMPORTANT : In order to connect the  //
  // DUT with the agent's virtual IF      //
  // we need to assign into the DUT ports //
  // the agent IF signals as seen below   //
  // from this moment the setting of the  //
  // virtual IF is done in a reusable way //
  //****************************************

  // Instantiate the dut
  xbox_xlr_dmy1 #(
    .NUM_MEMS(1),
    .LOG2_LINES_PER_MEM(4)
    ) dut (
      .clk(_mem_if.clk),
      .rst_n(_mem_if.rst_n),
      .xlr_mem_addr(_mem_if.mem_addr),
      .xlr_mem_wdata(_mem_if.mem_wdata),
      .xlr_mem_be(_mem_if.mem_be),
      .xlr_mem_rd(_mem_if.mem_rd),
      .xlr_mem_wr(_mem_if.mem_wr),
      .xlr_mem_rdata(_mem_if.mem_rdata),
      .host_regs(_gpp_if.host_regsi),
      .host_regs_valid_pulse(_gpp_if.host_regs_valid),                                       
      .host_regs_data_out(_gpp_if.host_regso),
      .host_regs_valid_out(_gpp_if.host_regso_valid)
  );

  // clk gen
  initial clk = 0;
  always #hclk_per clk = ~clk;

  // rst_n gen
  initial
  begin
    rst_n = 0;        
    #20
    rst_n = 1; // Desassert reset after 20ns delay
  end
endmodule


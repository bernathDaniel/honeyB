//=============================================================================
// Project  : HoneyB V4
// File Name: top_tb.sv
//=============================================================================
// Description: Testbench
//=============================================================================

`include "uvm_macros.svh"

import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_mem_pkg::*;

module top_tb;

  timeunit      1ns;
  timeprecision 1ps;

  top_config top_env_config;

  // Test harness
  top_th th();

  initial begin
    // pass the agent interfaces from test harness to top_config
    th._mem_if_28.use_concrete_class();

    // Create and populate top-level configuration object
    top_env_config = new("top_env_config");
    if ( !top_env_config.randomize() )
      `uvm_error("top_tb", "Failed to randomize top-level configuration object" )


    top_env_config.m_xlr_gpp_config.vif = th._gpp_if;

    uvm_config_db #(top_config)::set(null, "uvm_test_top", "config", top_env_config); // top_cfg not called from test_top but can be
    uvm_config_db #(top_config)::set(null, "uvm_test_top.m_env", "config", top_env_config); // top_config is called from m_env (top_env)

    uvm_root::get().set_timeout(1ms, 1);  // global sim timeout
    run_test("top_test");
  end
endmodule
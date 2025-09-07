//=============================================================================
// Project  : HoneyB V3
// File Name: top_test.sv
//=============================================================================
// Description: Test class for top (included in package top_test_pkg)
//=============================================================================

`ifndef TOP_TEST_SV
`define TOP_TEST_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_mem_pkg::*;


class top_test extends uvm_test;

  `uvm_component_utils(top_test)

  top_env m_env;

  extern function new(string name, uvm_component parent);
  extern function void build_phase(uvm_phase phase);
endclass : top_test

function top_test::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

function void top_test::build_phase(uvm_phase phase);
  top_config m_config;
  if (!uvm_config_db #(top_config)::get(this, "", "config", m_config))
    `uvm_error(get_type_name(), "Unable to get top_config")

  // # of sequences for the parameterized IF - may be unnecessary.
  m_config.m_xlr_mem_config.count = 4;
  
  // Strings to uniquely identify instances of parameterized interface. Used by factory overrides.
  m_config.m_xlr_mem_config.iface_string = "xlr_mem_if_2_8";

  xlr_mem_default_seq::type_id::set_type_override(xlr_mem_seq::get_type()); // Overriding the default seq with a custom one.
  m_env = top_env::type_id::create("m_env", this);
endfunction : build_phase

`endif // TOP_TEST_SV


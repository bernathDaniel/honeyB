//=============================================================================
// Project  : HoneyB V2
// File Name: port_converter.sv
//=============================================================================
// Description: Adapter - converts protocols to TLM
//              Port Converter has 1 analysis port even though we have
//              2 hybrid agents that require conversion because in top env
//              we instantiate it twice !
//
//              NOTE - CURRENTLY UNUSED - NO NEED !
//
//=============================================================================

`ifndef PORT_CONVERTER_SV
`define PORT_CONVERTER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


class port_converter #(type T = uvm_sequence_item) extends uvm_subscriber #(T);
  `uvm_component_param_utils(port_converter#(T))

  // For connecting analysis port of monitor to analysis export of xlr_scoreboard

  //uvm_analysis_port #(xlr_mem_tx) analysis_port_0; // m_xlr_mem_agent
  //uvm_analysis_port #(xlr_gpp_tx) analysis_port_1; // m_xlr_gpp_agent
  uvm_analysis_port #(T) analysis_port;
  

  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
  endfunction

  function void write(T t);
    analysis_port.write(t);
  endfunction
endclass

`endif // PORT_CONVERTER_SV


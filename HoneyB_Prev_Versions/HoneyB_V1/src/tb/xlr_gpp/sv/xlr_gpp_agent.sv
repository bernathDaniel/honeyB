//=============================================================================
// Project  : HoneyB V1
// File Name: xlr_gpp_agent.sv
//=============================================================================
// Description: Agent for xlr_gpp
//=============================================================================

`ifndef XLR_GPP_AGENT_SV
`define XLR_GPP_AGENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


class xlr_gpp_agent extends uvm_agent;

  `uvm_component_utils(xlr_gpp_agent)

  uvm_analysis_port #(xlr_gpp_tx) analysis_port_in; // input signals
  uvm_analysis_port #(xlr_gpp_tx) analysis_port_out; // output signals


  xlr_gpp_config       m_config;
  xlr_gpp_sequencer_t  m_sequencer;
  xlr_gpp_driver       m_driver;
  xlr_gpp_monitor      m_monitor;

  local int m_is_active = -1;

  extern function new(string name, uvm_component parent);

  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern function uvm_active_passive_enum get_is_active();
endclass : xlr_gpp_agent 


function  xlr_gpp_agent::new(string name, uvm_component parent);
  super.new(name, parent);
    analysis_port_in = new("analysis_port_in", this);
    analysis_port_out = new("analysis_port_out", this);
endfunction : new

function void xlr_gpp_agent::build_phase(uvm_phase phase);

  if (!uvm_config_db #(xlr_gpp_config)::get(this, "", "config", m_config))
    `uvm_error("", "xlr_gpp config not found")

  m_monitor     = xlr_gpp_monitor    ::type_id::create("m_monitor", this);

  if (get_is_active() == UVM_ACTIVE)
  begin
    m_driver    = xlr_gpp_driver     ::type_id::create("m_driver", this);
    m_sequencer = xlr_gpp_sequencer_t::type_id::create("m_sequencer", this);
  end
endfunction : build_phase


function void xlr_gpp_agent::connect_phase(uvm_phase phase);
  if (m_config.vif == null)
    `uvm_warning("", "xlr_gpp virtual interface is not set!")

  m_monitor.vif = m_config.vif;
  m_monitor.analysis_port_in.connect(analysis_port_in); // Child (Monitor) - Parent (Agent) connection
  m_monitor.analysis_port_out.connect(analysis_port_out);

  if (get_is_active() == UVM_ACTIVE)
  begin
    m_driver.seq_item_port.connect(m_sequencer.seq_item_export); // Peer2Peer connection (Export -> Port Broadcasting)
    m_driver.vif = m_config.vif;
  end
endfunction : connect_phase


function uvm_active_passive_enum xlr_gpp_agent::get_is_active();
  if (m_is_active == -1)
  begin
    if (uvm_config_db#(uvm_bitstream_t)::get(this, "", "is_active", m_is_active))
    begin
      if (m_is_active != m_config.is_active)
        `uvm_warning("", "is_active field in config_db conflicts with config object")
    end
    else 
      m_is_active = m_config.is_active;
  end
  return uvm_active_passive_enum'(m_is_active);
endfunction : get_is_active

`endif // XLR_GPP_AGENT_SV


//=============================================================================
// Project  : HoneyB V2
// File Name: xlr_mem_agent.sv
//=============================================================================
// Description: Agent for xlr_mem
//=============================================================================

`ifndef XLR_MEM_AGENT_SV
`define XLR_MEM_AGENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_mem_pkg::*;


class xlr_mem_agent extends uvm_agent;

    `uvm_component_utils(xlr_mem_agent)

    uvm_analysis_port #(xlr_mem_tx) analysis_port_in; // input signals
    uvm_analysis_port #(xlr_mem_tx) analysis_port_out; // output signals

    // References to concrete interface access objects
    xlr_mem_if_base m_xlr_mem_if; // NEW ADDITION

    xlr_mem_config       m_config;
    xlr_mem_sequencer_t  m_sequencer;
    xlr_mem_driver       m_driver;
    xlr_mem_monitor      m_monitor;

    local int m_is_active = -1;

    extern function new(string name, uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern function uvm_active_passive_enum get_is_active();
endclass : xlr_mem_agent 


function  xlr_mem_agent::new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port_in = new("analysis_port_in", this);
    analysis_port_out = new("analysis_port_out", this);
endfunction : new

function void xlr_mem_agent::build_phase(uvm_phase phase);

    if (!uvm_config_db #(xlr_mem_config)::get(this, "", "config", m_config)) begin
        `uvm_error("", "xlr_mem config not found")
    end

    m_monitor     = xlr_mem_monitor    ::type_id::create("m_monitor", this);

    if (get_is_active() == UVM_ACTIVE) begin
        m_driver    = xlr_mem_driver     ::type_id::create("m_driver", this);
        m_sequencer = xlr_mem_sequencer_t::type_id::create("m_sequencer", this);
    end

    /* NOTE - Factory create and the use of concrete classes
        ||----------------------------------------------------------------------------------------------------------------------------------
        || Have the factory create instances of the concrete classes for communcation with the parameterized SystemVerilog interfaces
        || Factory overrides cause the concrete classes defined in the interface to get instantiated (rather than the abstract classes)
        || The factory overrides work off the instance names "xlr_mem_if_<NUM_MEMS>_<LOG2_LINES_PER_NUM>"
        ||----------------------------------------------------------------------------------------------------------------------------------*/

    // defined in Top_test.sv || if m_config.iface_string = "xlr_mem_if_1_4" -> 1 = NUM_MEMS | 4 = LOG2_LINES_PER_NUM !!!
    m_xlr_mem_if = xlr_mem_if_base::type_id::create(m_config.iface_string, this);
  
    /* For V3 - NUM_MEMS = 2 || LOG2_LINES_PER_NUM = 8
        // defined in Top_test.sv || if m_config.iface_string = "xlr_mem_if_2_8" -> 2 = NUM_MEMS | 8 = LOG2_LINES_PER_NUM !!!
        // m_xlr_mem_if = xlr_mem_if_base::type_id::create(m_config.iface_string, this);*/
endfunction : build_phase


function void xlr_mem_agent::connect_phase(uvm_phase phase);

    if (m_config.vif == null)
        `uvm_warning("", "xlr_mem virtual interface is not set!")

    m_monitor.vif = m_config.vif; // TODO: Figure out what it's used for, try to remove and see if it has any impact
    m_monitor.analysis_port_in.connect(analysis_port_in); // Child (Monitor) - Parent (Agent) connection
    m_monitor.analysis_port_out.connect(analysis_port_out);

    if (get_is_active() == UVM_ACTIVE) begin
        m_driver.seq_item_port.connect(m_sequencer.seq_item_export); // Peer2Peer connection (Export -> Port Broadcasting)
        m_driver.vif = m_config.vif; // TODO: Figure out what it's used for, try to remove and see if it has any impact
    end

    /* Propagate references to concrete interface object down to driver and monitor
        This is the part responsible for creating the old "vif" objects that were in the driver and monitor !*/
    m_driver.m_xlr_mem_if  = m_xlr_mem_if;
    m_monitor.m_xlr_mem_if = m_xlr_mem_if;
endfunction : connect_phase


function uvm_active_passive_enum xlr_mem_agent::get_is_active();
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

`endif // XLR_MEM_AGENT_SV
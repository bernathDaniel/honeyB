//=============================================================================
// Project  : HoneyB V3
// File Name: top_env.sv
//=============================================================================
// Description: Environment for top
//=============================================================================

`ifndef TOP_ENV_SV
`define TOP_ENV_SV

`include "uvm_macros.svh"
import uvm_pkg::*;


class top_env extends uvm_env;

  `uvm_component_utils(top_env)

  extern function new(string name, uvm_component parent);

  reference                   m_reference;                
  xlr_scoreboard              m_xlr_scoreboard;
  xlr_top_reg_block           m_xlr_top_reg_block; // New addition of the top mem model block !
  xlr_reg2mem_adapter         m_xlr_reg2mem; // New addition of the reg2mem adapter !

  // Child agents
  xlr_mem_config    m_xlr_mem_config;  
  xlr_mem_agent     m_xlr_mem_agent;   
  xlr_mem_coverage  m_xlr_mem_coverage;

  xlr_gpp_config    m_xlr_gpp_config;  
  xlr_gpp_agent     m_xlr_gpp_agent;   
  xlr_gpp_coverage  m_xlr_gpp_coverage;

  top_config        m_config;

  extern function void build_phase(uvm_phase phase);
  extern function void connect_phase(uvm_phase phase);
  extern function void end_of_elaboration_phase(uvm_phase phase);
  extern task          run_phase(uvm_phase phase);
endclass : top_env 


function top_env::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

function void top_env::build_phase(uvm_phase phase);
  `honeyb("TOP ENV", "In build_phase...")

  if (!uvm_config_db #(top_config)::get(this, "", "config", m_config)) 
    `uvm_error("", "Unable to get top_config")

  m_xlr_mem_config = m_config.m_xlr_mem_config;

  uvm_config_db #(xlr_mem_config)::set(this, "m_xlr_mem_agent", "config", m_xlr_mem_config);
  if (m_xlr_mem_config.is_active == UVM_ACTIVE )
    uvm_config_db #(xlr_mem_config)::set(this, "m_xlr_mem_agent.m_sequencer", "config", m_xlr_mem_config);
  uvm_config_db #(xlr_mem_config)::set(this, "m_xlr_mem_coverage", "config", m_xlr_mem_config);

  m_xlr_gpp_config = m_config.m_xlr_gpp_config;

  uvm_config_db #(xlr_gpp_config)::set(this, "m_xlr_gpp_agent", "config", m_xlr_gpp_config);
  if (m_xlr_gpp_config.is_active == UVM_ACTIVE )
    uvm_config_db #(xlr_gpp_config)::set(this, "m_xlr_gpp_agent.m_sequencer", "config", m_xlr_gpp_config);
  uvm_config_db #(xlr_gpp_config)::set(this, "m_xlr_gpp_coverage", "config", m_xlr_gpp_config);

  begin
    // Instantiate reference model and xlr scoreboard
    m_reference                   = reference                  ::type_id::create("m_reference", this);
    m_xlr_scoreboard              = xlr_scoreboard             ::type_id::create("m_xlr_scoreboard", this);
    // New addition for top mem block
    m_xlr_top_reg_block           = xlr_top_reg_block          ::type_id::create("m_xlr_top_reg_block", this);
    m_xlr_top_reg_block.build();
    m_xlr_reg2mem         = xlr_reg2mem_adapter        ::type_id::create("m_xlr_reg2mem", this);
  end

  for (int i = 0; i < NUM_MEMS; i++) begin // Assign NUM_MEMS SRAM Blocks to mem agent's cfg to grant access from agent
    m_xlr_mem_config.mem_blocks[i] = m_xlr_top_reg_block.mem_blocks[i];
  end
  // Temporarily remove the coverage until test bench works properly

  m_xlr_mem_agent    = xlr_mem_agent   ::type_id::create("m_xlr_mem_agent", this);
  m_xlr_gpp_agent    = xlr_gpp_agent   ::type_id::create("m_xlr_gpp_agent", this);
endfunction : build_phase


function void top_env::connect_phase(uvm_phase phase);
  `honeyb("TOP ENV", "In connect_phase...")

  begin
    //**************************************************************//
    // Connect agents analysis ports to REF Model & Adapter exports //
    //**************************************************************//

    // Connect agents to reference
    m_xlr_mem_agent.analysis_port_in.connect(m_reference.analysis_export_mem); // REF Model subscribes to the input monitor !!
    m_xlr_gpp_agent.analysis_port_in.connect(m_reference.analysis_export_gpp);

    // Connect agents directly to scoreboard - Unused because agent -> adapter(converter) -> scrbrd
    m_xlr_mem_agent.analysis_port_out.connect(m_xlr_scoreboard.mem_dut_export);
    m_xlr_gpp_agent.analysis_port_out.connect(m_xlr_scoreboard.gpp_dut_export);

    //**************************************************************//
    //        Connect REF Model & Adapters to xlr scoreboard        //
    //**************************************************************//

    // Connect reference model to scoreboard (REF ports) 
    m_reference.analysis_port_mem.connect(m_xlr_scoreboard.mem_ref_export);
    m_reference.analysis_port_gpp.connect(m_xlr_scoreboard.gpp_ref_export);
  end

  begin // UVM RAL Connections
    m_xlr_top_reg_block.xlr_mem_map.set_sequencer(m_xlr_mem_agent.m_sequencer, m_xlr_reg2mem);
    m_xlr_top_reg_block.xlr_mem_map.set_auto_predict(1); // No predictor used, we're using UVM RAL's predictor instead.
  end
endfunction : connect_phase

function void top_env::end_of_elaboration_phase(uvm_phase phase);
  uvm_factory factory = uvm_factory::get();
  `uvm_info("", "Information printed from top_env::end_of_elaboration_phase method", UVM_MEDIUM)
  `uvm_info("", $sformatf("Verbosity threshold is %d", get_report_verbosity_level()), UVM_MEDIUM)
  uvm_top.print_topology();
  factory.print();
endfunction : end_of_elaboration_phase

task top_env::run_phase(uvm_phase phase);
  top_default_seq vseq;

  vseq = top_default_seq::type_id::create("vseq");
  vseq.set_item_context(null, null);
  if ( !vseq.randomize() )
    `uvm_fatal("", "Failed to randomize virtual sequence")
  vseq.m_xlr_mem_agent = m_xlr_mem_agent;
  vseq.m_xlr_gpp_agent = m_xlr_gpp_agent;
  vseq.m_xlr_reg2mem = m_xlr_reg2mem;
  vseq.set_starting_phase(phase);
  vseq.start(null);
endtask : run_phase

`endif // TOP_ENV_SV


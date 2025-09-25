//=============================================================================
// Project  : HoneyB V7
// File Name: top_env.sv
//=============================================================================
// Description: Environment for top
//=============================================================================

`ifndef TOP_ENV_SV
`define TOP_ENV_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;


class top_env extends uvm_env;

  `uvm_component_utils(top_env)

  extern function new(string name, uvm_component parent);


  reference         m_reference;                
  xlr_scoreboard    m_xlr_scoreboard;        

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
endfunction // Boilerplate

function void top_env::build_phase(uvm_phase phase);
  `honeyb("TOP Environment", "Starting build_phase...")

  if (!uvm_config_db #(top_config)::get(this, "", "config", m_config)) 
    `uvm_error("", "Unable to get top_config")

  m_xlr_mem_config = m_config.m_xlr_mem_config;

  uvm_config_db #(xlr_mem_config)::set(this, "m_xlr_mem_agent", "config", m_xlr_mem_config);
  if (m_xlr_mem_config.is_active == UVM_ACTIVE )
    uvm_config_db #(xlr_mem_config)::set(this, "m_xlr_mem_agent.m_sequencer", "config", m_xlr_mem_config);
  uvm_config_db #(xlr_mem_config)::set(this, "m_xlr_mem_coverage", "config", m_xlr_mem_config);

  m_xlr_gpp_config = m_config.m_xlr_gpp_config;

  uvm_config_db #(xlr_gpp_config)::set(this, "m_xlr_gpp_agent", "config", m_xlr_gpp_config);
  if (m_xlr_gpp_config.is_active == UVM_ACTIVE ) begin
    uvm_config_db #(xlr_gpp_config)::set(this, "m_xlr_gpp_agent.m_sequencer", "config", m_xlr_gpp_config);
  end
  uvm_config_db #(xlr_gpp_config)::set(this, "m_xlr_gpp_coverage", "config", m_xlr_gpp_config);

  m_xlr_mem_agent    = xlr_mem_agent::type_id::create("m_xlr_mem_agent", this);
  m_xlr_gpp_agent    = xlr_gpp_agent::type_id::create("m_xlr_gpp_agent", this);

  m_xlr_mem_coverage = xlr_mem_coverage::type_id::create("m_xlr_mem_coverage", this);
  m_xlr_gpp_coverage = xlr_gpp_coverage::type_id::create("m_xlr_gpp_coverage", this);

  m_reference        = reference::type_id::create("m_reference", this);
  m_xlr_scoreboard   = xlr_scoreboard::type_id::create("m_xlr_scoreboard", this);
endfunction : build_phase


function void top_env::connect_phase(uvm_phase phase);
  `honeyb("TOP Environment", "Starting connect_phase...")
    //==============================================
    // [MEM] Agent APs (IN/OUT) <-> Coverage AEs
    //==============================================
      if (!m_config.m_xlr_mem_config.coverage_enable)
        `honeyb("Top Environemnt", "MEM Coverage Disabled!")
      else begin
        `honeyb("Top Environment", "MEM Coverage Enabled, Connecting...")
        m_xlr_mem_agent.analysis_port_in.connect(m_xlr_mem_coverage.mem_cov_in_export);
        m_xlr_mem_agent.analysis_port_out.connect(m_xlr_mem_coverage.mem_cov_out_export);
      end
    //==============================================
    // [GPP] Agent APs (IN/OUT) <-> Coverage AEs
    //==============================================
      if (!m_config.m_xlr_gpp_config.coverage_enable)
        `honeyb("Top Environemnt", "GPP Coverage Disabled!")
      else begin
        `honeyb("Top Environment", "GPP Coverage Enabled, Connecting...")
        m_xlr_gpp_agent.analysis_port_in.connect(m_xlr_gpp_coverage.gpp_cov_in_export);
        m_xlr_gpp_agent.analysis_port_out.connect(m_xlr_gpp_coverage.gpp_cov_out_export);
      end
    //==============================================
    // [MEM&GPP] Agent APs (IN) <-> REF Model AEs
    //==============================================
      m_xlr_mem_agent.analysis_port_in.connect(m_reference.analysis_export_mem);
      m_xlr_gpp_agent.analysis_port_in.connect(m_reference.analysis_export_gpp);

    //==============================================
    // [MEM&GPP] Agent APs (OUT) <-> Scoreboard AEs
    //==============================================
      m_xlr_mem_agent.analysis_port_out.connect(m_xlr_scoreboard.mem_dut_export);
      m_xlr_gpp_agent.analysis_port_out.connect(m_xlr_scoreboard.gpp_dut_export);

    //==============================================
    // [MEM&GPP] REF Model APs <-> Scoreboard AEs
    //==============================================
      m_reference.analysis_port_mem.connect(m_xlr_scoreboard.mem_ref_export);
      m_reference.analysis_port_gpp.connect(m_xlr_scoreboard.gpp_ref_export);
endfunction : connect_phase

function void top_env::end_of_elaboration_phase(uvm_phase phase);
  uvm_factory factory = uvm_factory::get();
  `honeyb("TOP Environment", "Information printed from top_env::end_of_elaboration_phase method")
  //`uvm_info("", $sformatf("Verbosity threshold is %d", get_report_verbosity_level()), UVM_MEDIUM)
  uvm_top.print_topology();
  factory.print();
endfunction // Boilerplate

task top_env::run_phase(uvm_phase phase);
  top_default_seq vseq;

  vseq = top_default_seq::type_id::create("vseq");
  vseq.set_item_context(null, null); // Doesn't run on a Sequencer!
  if ( !vseq.randomize() )
    `uvm_fatal("", "Failed to randomize virtual sequence")
  vseq.m_xlr_mem_agent = m_xlr_mem_agent;
  vseq.m_xlr_gpp_agent = m_xlr_gpp_agent;
  vseq.m_seq_count = m_config.m_seq_count;
    // Overriding m_seq_count through Top_Test!
  vseq.set_starting_phase(phase);
  vseq.start(null);
endtask // Boilerplate

`endif // TOP_ENV_SV


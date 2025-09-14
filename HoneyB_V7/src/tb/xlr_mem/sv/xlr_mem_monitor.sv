//=========================================================================================
// Project  : HoneyB V7
// File Name: xlr_mem_monitor.sv
//=========================================================================================
// Description: Monitor for xlr_mem
	// Important: The monitor takes care both of the inputs and the outputs
	//            therefore it has 2 analysis ports, 1 for the inputs and 1 for outputs
	//            since we have a single tx class for both input & output
	//            this means that the transaction being broadcasted includes all tx's
	//            thus, through the input analysis ports the output signals will be
	//            propagated with 'x' values and vice versa for the output analysis port.
//=========================================================================================

`ifndef XLR_MEM_MONITOR_SV
`define XLR_MEM_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import honeyb_pkg::*;
import xlr_mem_pkg::*;

class xlr_mem_monitor extends uvm_monitor;
	`uvm_component_utils(xlr_mem_monitor)


	xlr_mem_if_base m_xlr_mem_if;

	uvm_analysis_port #(xlr_mem_tx) analysis_port_in; 	// input  signals
	uvm_analysis_port #(xlr_mem_tx) analysis_port_out; 	// output signals

	xlr_mem_tx m_trans_in;
	xlr_mem_tx m_trans_out;

	bit [NUM_MEMS-1:0] rd_mems;	// Arrays for all read / write reqs
  bit [NUM_MEMS-1:0] wr_mems; // from multiple memories

	extern function new(string name, uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);
	extern task do_mon();

	// Mon Sampling Helpers:
  //----------------------
		extern function void flush_trans_in();
		extern function void flush_trans_out();

		extern function void create_trans_in(int m);
		extern function void create_trans_out(int m);

		extern function void get_all_trans_out(); 
endclass // Boilerplate + Helpers


function xlr_mem_monitor::new(string name, uvm_component parent);
	super.new(name, parent);
	analysis_port_in 		= new("analysis_port_in",  this);
	analysis_port_out 	= new("analysis_port_out", this);
endfunction // Boilerplate


function void xlr_mem_monitor::build_phase(uvm_phase phase);
endfunction // Boilerplate


task xlr_mem_monitor::run_phase(uvm_phase phase);
	//`honeyb("MEM MON", "run_phase initialized...")
	m_trans_in 	= xlr_mem_tx::type_id::create("m_trans_in"	);
	m_trans_out = xlr_mem_tx::type_id::create("m_trans_out"	);
	do_mon();
endtask // Booilerplate + Report

task xlr_mem_monitor::do_mon();

	fork // in & out monitors work in parallel

		//=======================================================================
		//                        DUT INPUT MONITOR                            
		//=======================================================================
		 // Monitor only when in reg's asserted (indicating valid input)
		 // Inputs are testbench related (by driver) and set to be sent on
		 // negedge Making sure that no timing violations will occur

		forever begin // - OK - // Input rst_n handling.
			m_xlr_mem_if.rst_n_negedge_wait();
			if (!m_xlr_mem_if.get_rst_n()) begin
																					#RACE_CTRL;
				m_trans_in.mem_rdata  = m_xlr_mem_if.get_rdata_all();
				m_trans_in.set_e_mode("rst_i"); // "INPUT RESET" Event
				// Report
				//`honeyb("MEM MON", "rst_n detected, INPUT transactions are reset")
				//m_trans_in.print();
				analysis_port_in.write(m_trans_in);
			end
			m_xlr_mem_if.rst_n_posedge_wait();
		end

		forever begin // - OK - // Read REQ & RSP Sampling //
			flush_trans_in();
			m_xlr_mem_if.wait_for_rd_sampling();

			rd_mems = m_xlr_mem_if.get_active_rd_mems();
					for (int m = 0; m < NUM_MEMS; m++) begin
						if (rd_mems[m]) begin 
																	create_trans_in(m);
						end // DUT's REQ sampling
					end   // & e_mode set
			m_trans_in.set_e_mode("rd");

			m_xlr_mem_if.clk_posedge_wait();

			for (int m = 0; m < NUM_MEMS; m++) begin
				if (rd_mems[m]) begin 
															m_trans_in.mem_rdata[m] = m_xlr_mem_if.get_rdata(x_mem'(m));			
				end
    	end // Driver's RSP sampling

			//`honeyb("MEM MON", "Read Requested...")
			//m_trans_in.print(); // Report

			analysis_port_in.write(m_trans_in);
		end

		//=======================================================================
		//                        DUT OUTPUT MONITOR                           
		//=======================================================================
		 // Monitor only when out reg's asserted (indicating valid output)
		 // Outputs are DUT related and set to be sent on posedge.
		 // This will allow well synchronized timing of the triggerd
		 // signals from the DUT.

		forever begin // - OK - // Output rst_n handling.
			m_xlr_mem_if.rst_n_negedge_wait();
			if (!m_xlr_mem_if.get_rst_n()) begin
																						#RACE_CTRL;
				get_all_trans_out(); // all output = 0 
				m_trans_out.set_e_mode("rst_o"); // "OUTPUT_RESET" Event
				//`honeyb("MEM MON", "rst_n detected, OUTPUT transactions are reset")
				#RACE_CTRL;
				analysis_port_out.write(m_trans_out);
			end
			m_xlr_mem_if.rst_n_posedge_wait();
		end

		forever begin // - OK - // Write REQ Sampling //
			flush_trans_out();
			m_xlr_mem_if.wait_for_wr_sampling();

			wr_mems = m_xlr_mem_if.get_active_wr_mems();
					for (int m = 0; m < NUM_MEMS; m++) begin
						if (wr_mems[m]) begin 
																	create_trans_out(m);
						end // DUT's REQ Sampling
					end		// & e_mode_set
			m_trans_out.set_e_mode("wr");

			m_xlr_mem_if.clk_posedge_wait();
			//																	#RACE_CTRL;

			//`honeyb("MEM MON", "Write Requested...")
			//m_trans_out.print(); // Report

			analysis_port_out.write(m_trans_out);
		end
	join_none
endtask : do_mon

//===========================================
//					Monitor Helper Methods
//===========================================
	// Flushers
	//===========
	function void xlr_mem_monitor::flush_trans_in(); 
		m_trans_in.mem_addr = '0; m_trans_in.mem_rdata 	= '0;
															m_trans_in.mem_rd 		= '0;
																				rd_mems    	= '0;
	endfunction // Complete flush for new incoming samples (IN)

	function void xlr_mem_monitor::flush_trans_out(); 
		m_trans_out.mem_addr  = '0; m_trans_out.mem_be 	= '0;
		m_trans_out.mem_wdata = '0; m_trans_out.mem_wr 	= '0;
																					wr_mems 	= '0;
	endfunction // Complete flush for new incoming samples (OUT)

	// Creators
	//===========
	function void xlr_mem_monitor::create_trans_in(int m);
							m_trans_in.mem_addr[m]  = m_xlr_mem_if.get_addr  (x_mem'(m));
							m_trans_in.mem_rd[m]    = m_xlr_mem_if.get_rd    (x_mem'(m));
	endfunction // Create a complete sampling input transaction

	function void xlr_mem_monitor::create_trans_out(int m);
							m_trans_out.mem_addr[m]  = m_xlr_mem_if.get_addr  (x_mem'(m));
							m_trans_out.mem_wr[m]    = m_xlr_mem_if.get_wr    (x_mem'(m));
							m_trans_out.mem_wdata[m] = m_xlr_mem_if.get_wdata (x_mem'(m));
							m_trans_out.mem_be[m]    = m_xlr_mem_if.get_be    (x_mem'(m));
	endfunction // Create a complete sampling output transaction

	// Astractor
	//===========
	function void xlr_mem_monitor::get_all_trans_out(); 
							m_trans_out.mem_addr   = m_xlr_mem_if.get_addr_all();
							m_trans_out.mem_wdata  = m_xlr_mem_if.get_wdata_all();
							m_trans_out.mem_be     = m_xlr_mem_if.get_be_all();
							m_trans_out.mem_rd     = m_xlr_mem_if.get_rd_all();
							m_trans_out.mem_wr     = m_xlr_mem_if.get_wr_all();
	endfunction // Mainly for Code Abstraction

`endif // XLR_MEM_MONITOR_SV
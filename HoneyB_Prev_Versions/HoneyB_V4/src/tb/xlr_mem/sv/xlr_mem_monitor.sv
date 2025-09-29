//=========================================================================================
// Project  : HoneyB V4
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

	extern function new(string name, uvm_component parent);
	extern function void build_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);
	extern task do_mon();
endclass : xlr_mem_monitor 


function xlr_mem_monitor::new(string name, uvm_component parent);
	super.new(name, parent);
	analysis_port_in 		= new("analysis_port_in",  this);
	analysis_port_out 	= new("analysis_port_out", this);
endfunction : new


function void xlr_mem_monitor::build_phase(uvm_phase phase);
endfunction : build_phase


task xlr_mem_monitor::run_phase(uvm_phase phase);
	// Update Statement
	`honeyb("MEM MON", "run_phase initialized...")
	m_trans_in 	= xlr_mem_tx::type_id::create("m_trans_in"	);
	m_trans_out = xlr_mem_tx::type_id::create("m_trans_out"	);
	do_mon();
endtask : run_phase

task xlr_mem_monitor::do_mon();

	bit rst_asserted = 1'b0; // Flag for rst_n

	fork // in & out monitors work in parallel

		/*                            DUT INPUT MONITOR                          */
		//-----------------------------------------------------------------------//
			//     Monitor only when in reg's asserted (indicating valid input)    //
			//     Inputs are testbench related (by driver) and set to be sent on  //
			//     negedge Making sure that no timing violations will occur        //
			//                                                                     //
			//---------------------------------------------------------------------*/

		// Input rst_n handling.
		forever begin
			if (!m_xlr_mem_if.get_rst_n()) begin
				rst_asserted = 1'b1;
				#1; // add small delay
				m_trans_in.mem_rdata  = m_xlr_mem_if.get_rdata_all(); // all should be '0 for rst_n 
				m_trans_in.set_e_mode("rst_i"); // Declares "INPUT RESET" Event

				// Report Statement
				`honeyb("MEM MON", "rst_n detected, INPUT transactions are reset")
				analysis_port_in.write(m_trans_in);
			end
			m_xlr_mem_if.rst_n_posedge_wait();
			rst_asserted = 1'b0;
		end

		forever begin
			int mem_idx = -1; // Initialized every new iteration to -1 where : 0 <= mem_idx <= NUM_MEMS-1

			m_xlr_mem_if.clk_posedge_wait(); // forever begin every posedge clk now !!
			#1; // DO NOT TOUCH!

			for (int k = 0; k < NUM_MEMS; k++) begin // Quick sweep over all the mem_rd signals, for finding the right one-hot signal
				if (m_xlr_mem_if.get_rd(x_mem'(k)) == 1'b1) begin
					mem_idx = k;
					break;
				end
			end

			if (mem_idx >= 0) begin

				m_trans_in.set_e_mode("rd"); 						// for rd signal related tx.methods()
				m_trans_in.set_mem(x_mem'(mem_idx)); 	// maps 0 -> MEM0, 1->MEM1, ...

				m_trans_in.mem_rd		[mem_idx] = m_xlr_mem_if.get_rd			(x_mem'(mem_idx));
				m_trans_in.mem_addr	[mem_idx] = m_xlr_mem_if.get_addr		(x_mem'(mem_idx));

				m_xlr_mem_if.clk_negedge_wait(); // -> Moved the wait negedge here to mimick the driver behavior with full intent.
				#1; // small delay so it can capture the driver's NBA assignments.

				m_trans_in.mem_rdata[mem_idx] = m_xlr_mem_if.get_rdata	(x_mem'(mem_idx));

				// Report Statement
				`honeyb("MEM MON", "Read Requested...")
				m_trans_in.print();
				analysis_port_in.write(m_trans_in); // broadcast to REF (& Coverage, soon)
			end
		end

		/*                           DUT OUTPUT MONITOR                          */ 
		//-----------------------------------------------------------------------//
			//     Monitor only when out reg's asserted (indicating valid output)  //
			//     Outputs are DUT related and set to be sent on posedge.          //
			//     This will allow well synchronized timing of the triggerd        //
			//     signals from the DUT.                                           //
			//                                                                     //
			//---------------------------------------------------------------------//

		// Output rst_n handling.
		forever begin
			if (!m_xlr_mem_if.get_rst_n()) begin
				#1; // DO NOT CHANGE !!
				m_trans_out.mem_addr   = m_xlr_mem_if.get_addr_all();
				m_trans_out.mem_wdata  = m_xlr_mem_if.get_wdata_all();
				m_trans_out.mem_be     = m_xlr_mem_if.get_be_all();
				m_trans_out.mem_rd     = m_xlr_mem_if.get_rd_all();
				m_trans_out.mem_wr     = m_xlr_mem_if.get_wr_all();

				m_trans_out.set_e_mode("rst_o"); // Declares "OUTPUT_RESET" Event

				// Report
				`honeyb("MEM MON", "rst_n detected, OUTPUT transactions are reset")
				analysis_port_out.write(m_trans_out);
			end
			m_xlr_mem_if.rst_n_posedge_wait();
		end

		forever begin
			int mem_idx = -1;   // Initialized every new iteration to -1 where : 0 <= mem_idx <= NUM_MEMS-1

			m_xlr_mem_if.clk_posedge_wait();
			#1;
			for (int k = 0; k < NUM_MEMS; k++) begin // Will need to change when Dual-Port mechanism is implemented
				if (m_xlr_mem_if.get_wr(x_mem'(k)) == 1'b1) begin
				mem_idx = k;
				break;
				end
      end

			if (mem_idx >= 0) begin

				m_trans_out.set_e_mode("wr"); // for rd signal related tx.methods()
				m_trans_out.set_mem(x_mem'(mem_idx)); // maps 0 -> MEM0, 1->MEM1, ...


				m_trans_out.mem_addr	[mem_idx] = m_xlr_mem_if.get_addr		(x_mem'(mem_idx));
				m_trans_out.mem_wdata	[mem_idx] = m_xlr_mem_if.get_wdata	(x_mem'(mem_idx));
				m_trans_out.mem_be		[mem_idx] = m_xlr_mem_if.get_be			(x_mem'(mem_idx));
				m_trans_out.mem_wr		[mem_idx] = m_xlr_mem_if.get_wr			(x_mem'(mem_idx));

				// Report Statement
				`honeyb("MEM MON", "Write Requested, Broadcasting...")
				m_trans_out.print();
				analysis_port_out.write(m_trans_out); // Broadcast
			end
		end
	join
endtask : do_mon

`endif // XLR_MEM_MONITOR_SV


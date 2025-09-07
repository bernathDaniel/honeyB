task xlr_gpp_monitor::do_mon;
  forever @(posedge vif.clk)
  begin
    // Create a new transaction object for each valid input
    if(vif.host_regs_valid[0] && vif.host_regsi[0][0]) begin
      
      // Capture the input values
      m_trans.host_regsi = vif.host_regsi;
      m_trans.host_regs_valid = vif.host_regs_valid;
      
      // Send the transaction through the analysis port
      analysis_port.write(m_trans);
      
      // Log the captured data
      `uvm_info(get_type_name(), $sformatf("Captured Control Input: host_regsi[0][0] = %0d host_regs_valid[0] = %0d", m_trans.host_regsi[0][0], m_trans.host_regs_valid[0]), UVM_HIGH)
      
      // For start command, provide additional logging
      if(m_trans.host_regsi[0][0] && m_trans.host_regs_valid[0]) begin
        `uvm_info(get_type_name(), $sformatf("Detected START command"), UVM_MEDIUM)
      end
    end

    //*********************************************************************//
    //                           DUT OUTPUT MONITOR                        //
    //     Monitor only when out reg's asserted (indicating valid output)  //
    //*********************************************************************//
    
     // Create a new transaction object for each valid input
    if(vif.host_regso[1][0] && vif.host_regso_valid[1]) begin
      
      // Capture the input values
      m_trans.host_regso = vif.host_regso;
      m_trans.host_regso_valid = vif.host_regso_valid;
      
      // Send the transaction through the analysis port
      analysis_port.write(m_trans);

      // Log the captured data
      `uvm_info(get_type_name(), $sformatf("Captured control output (DONE): host_regso[1][0] = %0d host_regso_valid[1] = %0d", m_trans.host_regso[1][0], m_trans.host_regso_valid[1]), UVM_HIGH)
      `uvm_info(get_type_name(), $sformatf("Captured control output (BUSY): host_regso[0][0] = %0d host_regso_valid[0] = %0d", m_trans.host_regso[0][0], m_trans.host_regso_valid[0]), UVM_HIGH)
      if(m_trans.host_regso[1][0] && m_trans.host_regso_valid[1]) begin
        `uvm_info(get_type_name(), $sformatf("Detected DONE command"), UVM_MEDIUM)
      end
    end
  end
endtask
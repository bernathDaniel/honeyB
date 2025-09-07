task xlr_mem_monitor::do_mon;
  forever @(posedge vif.clk)
  begin
    // Only monitor when mem_rd is asserted
    if(vif.mem_rd) begin
      // Capture the 3D array mem_rdata
      m_trans.mem_rdata = vif.mem_rdata;
      m_trans.mem_rd = vif.mem_rd;
      m_trans.mem_addr = vif.mem_addr;
      
      // Send the transaction through the analysis port
      analysis_port.write(m_trans);
      
      // Log the captured data
      `uvm_info(get_type_name(), $sformatf("Read Requested ! Addr SRC : mem_addr[0] = %0d", m_trans.mem_addr[0]),UVM_HIGH)
      for (int i = 0; i < 8; i++)
        `uvm_info(get_type_name(), $sformatf("Captured mem_rdata[0][%0d] = %0d", i, m_trans.mem_rdata[0][i]), UVM_HIGH)
    end
    else begin
      `uvm_info(get_type_name(), $sformatf("ERROR: No Read Request at mem input agent",UVM_HIGH)
    end

    //*********************************************************************//
    //                           DUT OUTPUT MONITOR                        //
    //     Monitor only when mem_wr is asserted (indicating valid output)  //
    //*********************************************************************//

    if (vif.mem_wr)
    begin
      // Capture all the output signals
      m_trans.mem_addr = vif.mem_addr;
      m_trans.mem_wdata = vif.mem_wdata;
      m_trans.mem_be = vif.mem_be;
      m_trans.mem_rd = vif.mem_rd;
      m_trans.mem_wr = vif.mem_wr;
      
      // Send transaction through analysis port
      analysis_port.write(m_trans);
      
      // Log the captured data
      `uvm_info(get_type_name(), $sformatf("Write Requested ! Addr SRC : mem_addr[0] = %0d", m_trans.mem_addr[0]),UVM_HIGH)
      for (int i = 0; i < 8; i++)
        `uvm_info(get_type_name(), $sformatf("Captured mem_wdata[0][%0d] = %0d", i, m_trans.mem_wdata[0][i]), UVM_HIGH)
    end
    else begin
      `uvm_info(get_type_name(), $sformatf("ERROR: No Write Request at mem output agent",UVM_HIGH)
    end
  end
endtask
                

task xlr_gpp_driver::run_phase(uvm_phase phase);
  `uvm_info(get_type_name(), "run_phase", UVM_HIGH)
  
  forever
  begin
    seq_item_port.get_next_item(req);
    
    wait (vif.rst_n == 1);
    phase.raise_objection(this);
    
    repeat ($urandom_range(0, 2)) @(posedge vif.clk);
    
    // Drive host_regsi value
    vif.host_regsi <= req.host_regsi;
    // Drive valid pulse for one cycle
    vif.host_regs_valid <= req.host_regs_valid;
    
    @(posedge vif.clk);
    vif.host_regsi <= 0;
    vif.host_regs_valid <= 0;
    
    // If this was a start signal, wait for busy to clear and done to 	  assert
    if (req.host_regsi[0][0] && req.host_regs_valid[0]) begin
      wait(vif.host_regso[1][0] == 1 && vif.host_regso_valid[1] == 1);
      // Wait for done to clear - done is in GPR[1], GPR[0] holds busy signal !
    end
    
    fork
      begin
        repeat (5) @(posedge vif.clk);
        phase.drop_objection(this);
      end
    join_none
    
    seq_item_port.item_done();
  end
endtask : run_phase
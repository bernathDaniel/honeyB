task xlr_mem_driver::run_phase(uvm_phase phase);
  // Declares that run phase starts
  `uvm_info(get_type_name(), "run_phase", UVM_HIGH)

  forever
  begin
    seq_item_port.get_next_item(req);// waits for next available tx

    wait (vif.rst_n == 1);// waits for deassertion of rst_n
    phase.raise_objection(this);// tells the tb that this task is busy
  
    // adds small delay before driving the data
    repeat ($urandom_range(0, 1)) @(posedge vif.clk);

    // wait for DUT to send read request
    wait (vif.mem_rd == 1);
    
    // assign transaction to DUT interface
    vif.mem_rdata <= req.mem_rdata;
    
    @(posedge vif.clk); // wait 1 clk cycle
  
    // Create delay before dropping objection, this is useful to make
    // sure that the test won't be interrupted if new transaction
    // takes time, but we add "fork" to do this in parallel
    // meaning that while drop_objection is delayed, if new
    // transaction is available, the test will proceed to driving it
    fork
      begin
        repeat (10) @(posedge vif.clk);
        phase.drop_objection(this);
      end
    join_none
    
    //Notified UVM that the current transaction is done
    seq_item_port.item_done();
    
  end
endtask : run_phase

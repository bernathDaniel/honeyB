covergroup m_cov;
  option.per_instance = 1;
  
  // Cover host_regsi[0] bit values (0 or 1)
  cp_host_regsi: coverpoint m_item.host_regsi[0][0] {
    bins regsi_values[] = {0, 1};
  }
  
  // Cover host_regs_valid[0] bit values (0 or 1)
  cp_host_regs_valid: coverpoint m_item.host_regs_valid[0] {
    bins valid_values[] = {0, 1};
  }
  
  // Cover the cross of the two control bits
  cp_cross: cross cp_host_regsi, cp_host_regs_valid {
    // This will create bins for all 4 combinations:
    // (0,0), (0,1), (1,0), (1,1)
  }
endgroup
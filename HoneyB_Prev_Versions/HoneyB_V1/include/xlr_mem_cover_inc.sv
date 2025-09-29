covergroup m_cov;
  option.per_instance = 1;
  
  // Cover each word of mem_rdata[0][7:0]
  // A[1,1] Value
  cp_word0: coverpoint m_item.mem_rdata[0][0] {
    bins word_value[] = {[0:20]};
  }
  // A[1,2] Value
  cp_word1: coverpoint m_item.mem_rdata[0][1] {
    bins word_value[] = {[0:20]};
  }
  // A[2,1] Value
  cp_word2: coverpoint m_item.mem_rdata[0][2] {
    bins word_value[] = {[0:20]};
  }
  // A[2,2] Value
  cp_word3: coverpoint m_item.mem_rdata[0][3] {
    bins word_value[] = {[0:20]};
  }
  // B[1,1] Value
  cp_word4: coverpoint m_item.mem_rdata[0][4] {
    bins word_value[] = {[0:20]};
  }
  // B[1,2] Value
  cp_word5: coverpoint m_item.mem_rdata[0][5] {
    bins word_value[] = {[0:20]};
  }
  // B[2,1] Value
  cp_word6: coverpoint m_item.mem_rdata[0][6] {
    bins word_value[] = {[0:20]};
  }
  // B[2,2] Value
  cp_word7: coverpoint m_item.mem_rdata[0][7] {
    bins word_value[] = {[0:20]};
  }
endgroup
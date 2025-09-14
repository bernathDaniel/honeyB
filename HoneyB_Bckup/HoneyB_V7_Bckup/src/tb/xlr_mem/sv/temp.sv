//======================================
//    Enhanced Memory Dump Functions  
//======================================

// Add these function declarations to your class extern section:
extern function void create_dump_directories();
extern function void dump_init_state(int mem_idx, mem_init_policy policy);

// Add these function implementations:

function void xlr_mem_model::create_dump_directories();
  string base_dir = m_config.dump_directory;
  
  // Create base directory
  void'($system($sformatf("mkdir -p %s", base_dir)));
  
  // Create subdirectories for different initialization types
  void'($system($sformatf("mkdir -p %sinit_rand_mem_dump", base_dir)));
  void'($system($sformatf("mkdir -p %sinit_file_mem_dump", base_dir)));
  void'($system($sformatf("mkdir -p %sinit_empty_mem_dump", base_dir)));
  
  `honeyb("MEM Model", "DUMP_DIRS_CREATED", $sformatf("Created dump directory structure at '%s'", base_dir))
endfunction

function void xlr_mem_model::dump_init_state(int mem_idx, mem_init_policy policy);
  if (!m_config.enable_init_dumps) return;
  
  string subdir;
  string policy_name;
  
  // Determine subdirectory and policy name based on initialization type
  case (policy)
    INIT_RANDOM: begin
      subdir = "init_rand_mem_dump/";
      policy_name = "random";
    end
    INIT_FILE: begin
      subdir = "init_file_mem_dump/";
      policy_name = "file";
    end
    default: begin // INIT_NONE
      subdir = "init_empty_mem_dump/";
      policy_name = "empty";
    end
  endcase
  
  string filename = $sformatf("%s%sinit_%s_mem%0d_%0t.txt", 
                             m_config.dump_directory, subdir, policy_name, mem_idx, $time);
  
  dump_mem(mem_idx, filename);
endfunction

// Modified init functions to use organized dumps:

function void xlr_mem_model::init_all();
  // Create directory structure first
  if (m_config.enable_write_dumps) begin
    create_dump_directories();
  end
  
  for (int m = 0; m < NUM_MEMS; m++) begin
    has_last[m]       = 1'b0;
    last_mem_rdata[m] = '0;
  end // reset trackers

  for (int m = 0; m < NUM_MEMS; m++) begin
    mem_init_policy policy = get_init_policy(m);
    
    case (policy)
      INIT_RANDOM: begin
        init_mem_random(m);
        dump_init_state(m, INIT_RANDOM);
      end
      
      INIT_FILE: begin
        if (m_config.init_file_per_mem.exists(m)) begin
          init_mem_file(m, m_config.init_file_per_mem[m]);
          dump_init_state(m, INIT_FILE);
        end else begin
          `honeyb("[ERROR] MEM Model", "INIT_FILE MISSING", $sformatf("mem=%0d no file path; leaving uninitialized", m))
          dump_init_state(m, INIT_NONE); // Dump as empty since no file
        end
      end
      
      default: begin /* INIT_NONE */
        dump_init_state(m, INIT_NONE);
      end
    endcase
  end
endfunction // per-mem policy

// Enhanced dump_mem function to handle subdirectory paths:
function void xlr_mem_model::dump_mem(int mem_idx, string filename = "");
  string dump_file;
  int fd;
  int addr_count = 0;
  
  // Generate filename if not provided
  if (filename == "") begin
    dump_file = $sformatf("%smem_%0d_dump_%0t.txt", m_config.dump_directory, mem_idx, $time);
  end else begin
    // If filename already includes directory path, use as-is
    // Otherwise prepend base directory
    if (filename[0] == "/" || filename.substr(1,1) == ":") begin
      dump_file = filename; // Absolute path
    end else if (filename.substr(0, m_config.dump_directory.len()-1) == m_config.dump_directory) begin
      dump_file = filename; // Already includes base directory
    end else begin
      dump_file = $sformatf("%s%s", m_config.dump_directory, filename); // Relative to base
    end
  end
  
  fd = $fopen(dump_file, "w");
  if (fd == 0) begin
    `honeyb("[ERROR] MEM Model", $sformatf("(DUMP) Cannot open file '%s' for writing", dump_file))
    return;
  end
  
  // Write header information
  $fwrite(fd, "# Memory Dump for mem[%0d] at time %0t\n", mem_idx, $time);
  $fwrite(fd, "# Format: <addr_hex> <data_256bits_hex>\n");
  $fwrite(fd, "# Memory Config: %0d mems, %0d lines per mem, %0d bits per line\n", 
          NUM_MEMS, LINES_PER_MEM, NUM_WORDS * WORD_WIDTH);
  $fwrite(fd, "#\n");
  
  // Dump all initialized addresses (associative array keys)
  if (mem[mem_idx].size() == 0) begin
    $fwrite(fd, "# Memory is empty (no initialized addresses)\n");
  end else begin
    // Get all addresses and sort them for readability
    int addr_list[$];
    foreach (mem[mem_idx][addr]) begin
      addr_list.push_back(addr);
    end
    addr_list.sort();
    
    // Write each address and its data
    foreach (addr_list[i]) begin
      int addr = addr_list[i];
      $fwrite(fd, "%08h %064h\n", addr, mem[mem_idx][addr]);
      addr_count++;
    end
  end
  
  $fclose(fd);
  `honeyb("MEM Model", "DUMP_Complete", $sformatf("mem=%0d file='%s' dumped %0d addresses", mem_idx, dump_file, addr_count))
endfunction
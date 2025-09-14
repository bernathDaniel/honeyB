dut_top               = xbox_xlr_dmy1
nested_config_objects = yes

#Path ignored on EDA Playground
syosil_scoreboard_src_path = ../../syosil/src

# Define I/O's for REF Model - has to be like "m_$agent_name_agent"

ref_model_input  = reference m_xlr_mem_agent
ref_model_input  = reference m_xlr_gpp_agent

ref_model_output = reference m_xlr_mem_agent
ref_model_output = reference m_xlr_gpp_agent

# IOP is when we have multiple protocols, in this case
# we have 2 - 1 for data protocol, 1 for control protocol

ref_model_compare_method    = reference iop

# Define the files that'll include REF calc the DUT should do :

ref_model_inc_inside_class  = reference reference_inc_inside_class.sv  inline
ref_model_inc_after_class   = reference reference_inc_after_class.sv   inline

#IDK what it is yet 
top_default_seq_count = 20

#uvm_cmdline = +UVM_VERBOSITY=UVM_HIGH

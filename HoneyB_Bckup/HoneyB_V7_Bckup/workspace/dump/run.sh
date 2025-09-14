cd /home/runner
export PATH=/usr/bin:/bin:/tool/pandora64/bin:/xcelium23.09/tools.lnx86/bin:/xcelium23.09/bin:/xcelium23.09/tools.lnx86/systemc/gcc/bin:/usr/local/bin
export IFV_HOME=/xcelium23.09
export LDV_TOOLS=/xcelium23.09/tools.lnx86
export SPMN_HOME=/xcelium23.09
export TOP_INSTALL_DIR=/xcelium23.09
export LM_LICENSE_FILE=5280@10.116.0.5
export IUS_HOME=/xcelium23.09
export SOCV_KIT_HOME=/xcelium23.09
export SPECMAN_HOME=/xcelium23.09/specman
export EMGR_HOME=/xcelium23.09
export NCSIM_VERSION=23.09
export HOME=/home/runner
export LDV_HOME=/xcelium23.09
EU_INC_PATH=`perl /playground_lib/easier_uvm_gen/easier_uvm_gen.pl -x inc_path`  ; EU_DUT_SOURCE_PATH=`perl /playground_lib/easier_uvm_gen/easier_uvm_gen.pl -x dut_source_path` ; EU_PROJECT=`perl /playground_lib/easier_uvm_gen/easier_uvm_gen.pl -x project`  ; EU_REGMODEL_FILE=`perl /playground_lib/easier_uvm_gen/easier_uvm_gen.pl -x regmodel_file` ; mkdir $EU_INC_PATH ; mv reference_inc_inside_class.sv reference_inc_after_class.sv xlr_mem_cover_inc.sv xlr_mem_driver_inc_inside_class.sv xlr_mem_driver_inc_after_class.sv xlr_mem_do_mon.sv xlr_gpp_cover_inc.sv xlr_gpp_driver_inc_inside_class.sv xlr_gpp_driver_inc_after_class.sv xlr_gpp_do_mon.sv  $EU_INC_PATH ; mkdir $EU_DUT_SOURCE_PATH ; mv design.sv  $EU_DUT_SOURCE_PATH ; if [ -f $EU_INC_PATH/$EU_REGMODEL_FILE ]; then cp $EU_INC_PATH/$EU_REGMODEL_FILE . ; fi; perl /playground_lib/easier_uvm_gen/easier_uvm_gen.pl -c  xlr_mem.tpl xlr_gpp.tpl ; cd $EU_PROJECT  && cd sim ; chmod 755 compile_ius.sh ; source ./compile_ius.sh ; cd /home/runner  ; echo 'Creating result.zip...' && zip -r /tmp/tmp_zip_file_123play.zip . && mv /tmp/tmp_zip_file_123play.zip result.zip
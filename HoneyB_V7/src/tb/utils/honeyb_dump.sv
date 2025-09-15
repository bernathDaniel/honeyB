



`uvm_fatal("checkpoint", "OK")



//===========================================================================
//                              GPP DEBUG DUMP
//===========================================================================


//                         DUT DRIVER   [GPP]

// HONEYB DEBUGGING SYSTEM - DO NOT TOUCH
        if ((DEBUG_MODE == DBG_ALL) || (DEBUG_MODE == DBG_GPP_DRV)) begin
          #PRNT_CTRL;
          `honeyb("| DEBUG       | ", "ENTER RST - OK")
          `honeyb("| DEBUG PRINT | ", $sformatf("host_regs = %0h", vif.host_regsi))
          `honeyb("| DEBUG PRINT | ", $sformatf("host_regs_valid = %0h", vif.host_regs_valid))
        end

// HONEYB DEBUGGING SYSTEM - DO NOT TOUCH
        if ((DEBUG_MODE == DBG_ALL) || (DEBUG_MODE == DBG_GPP_DRV)) begin
          #PRNT_CTRL;
          `honeyb("| DEBUG       | ", "RST RECOVERY - OK")
        end

//---------------------------------------------------------------------------------

//                        DUT INPUT MONITOR  [GPP]

// HONEYB DEBUGGING SYSTEM - DO NOT TOUCH
          if ((DEBUG_MODE == DBG_ALL) || (DEBUG_MODE == DBG_GPP_MON)) begin
            #PRNT_CTRL;
            `honeyb("| DEBUG       | ", "ENTER RST - OK")
            m_trans_in.print();
          end

// HONEYB DEBUGGING SYSTEM - DO NOT TOUCH
          if ((DEBUG_MODE == DBG_ALL) || (DEBUG_MODE == DBG_GPP_MON)) begin
            #PRNT_CTRL;
            `honeyb("| DEBUG       | ", "RST RECOVERY OK")
          end

//---------------------------------------------------------------------------------

//                        DUT OUTPUT MONITOR   [GPP]          

// HONEYB DEBUGGING SYSTEM - DO NOT TOUCH
          if ((DEBUG_MODE == DBG_ALL) || (DEBUG_MODE == DBG_GPP_MON)) begin
            #PRNT_CTRL;
            `honeyb("| DEBUG       | ", "ENTER RST - OK")
            m_trans_out.print();
          end

// HONEYB DEBUGGING SYSTEM - DO NOT TOUCH
        if ((DEBUG_MODE == DBG_ALL) || (DEBUG_MODE == DBG_GPP_MON)) begin
          #PRNT_CTRL;
          `honeyb("| DEBUG       | ", "RST RECOVERY - OK")
        end

//===========================================================================
//                              MEM DEBUG DUMP
//===========================================================================

//                         DUT DRIVER   [MEM]

// HONEYB DEBUGGING SYSTEM - DO NOT TOUCH
        if ((DEBUG_MODE == DBG_ALL) || (DEBUG_MODE == DBG_MEM_DRV)) begin
          #PRNT_CTRL;
          `honeyb("| DEBUG       | ", "PINS RESET - OK")
        end


// HONEYB DEBUGGING SYSTEM - DO NOT TOUCH
        if ((DEBUG_MODE == DBG_ALL) || (DEBUG_MODE == DBG_MEM_DRV)) begin
          #PRNT_CTRL;
          `honeyb("| DEBUG       | ", "RST RECOVERY - OK")
        end

//---------------------------------------------------------------------------------

//                        DUT INPUT MONITOR  [MEM]


// HONEYB DEBUGGING SYSTEM - DO NOT TOUCH
					if ((DEBUG_MODE == DBG_ALL) || (DEBUG_MODE == DBG_MEM_MON)) begin
						#PRNT_CTRL;
						`honeyb("| DEBUG       | ", "ENTER RST - OK")
						m_trans_in.print();
					end

// HONEYB DEBUGGING SYSTEM - DO NOT TOUCH
				if ((DEBUG_MODE == DBG_ALL) || (DEBUG_MODE == DBG_MEM_MON)) begin
					#PRNT_CTRL;
					`honeyb("| DEBUG       | ", "RST RECOVERY - OK")
				end

//---------------------------------------------------------------------------------

//                        DUT OUTPUT MONITOR  [MEM]

// HONEYB DEBUGGING SYSTEM - DO NOT TOUCH
          if ((DEBUG_MODE == DBG_ALL) || (DEBUG_MODE == DBG_MEM_MON)) begin
            #PRNT_CTRL;
            `honeyb("| DEBUG       | ", "ENTER RST - OK")
            m_trans_out.print();
          end

// HONEYB DEBUGGING SYSTEM - DO NOT TOUCH
        if ((DEBUG_MODE == DBG_ALL) || (DEBUG_MODE == DBG_MEM_MON)) begin
          #PRNT_CTRL;
          `honeyb("| DEBUG       | ", "RST RECOVERY OK")
        end

//---------------------------------------------------------------------------------

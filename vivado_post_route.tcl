##############################################################################
## This file is part of 'SLAC Firmware Standard Library'.
## It is subject to the license terms in the LICENSE.txt file found in the 
## top-level directory of this distribution and at: 
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
## No part of 'SLAC Firmware Standard Library', including this file, 
## may be copied, modified, propagated, or distributed except according to 
## the terms contained in the LICENSE.txt file.
##############################################################################

## \file vivado_post_route.tcl
# \brief This script runs at the end of the place and route (outside of impl_1)

########################################################
## Get variables and Custom Procedures
########################################################
source -quiet $::env(RUCKUS_DIR)/vivado_env_var.tcl
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

########################################################
## Check if passed timing
########################################################
if { [CheckTiming false] == true } {
   # Make the GIT build tag
   GitBuildTag
   
   #########################################################
   ## Check if need to include python files with build
   #########################################################   
   if { [file isdirectory ${PROJ_DIR}/python] == 1 } {
      source ${RUCKUS_DIR}/vivado_pyrogue.tcl
   }   
   
   #########################################################
   ## Check if need to include YAML files with build
   #########################################################
   if { [file exists ${PROJ_DIR}/yaml/000TopLevel.yaml] == 1 } {
      source ${RUCKUS_DIR}/vivado_cpsw.tcl
   }
   
   #########################################################
   ## Check if SDK's .sysdef file exists
   #########################################################
   set mbPath [get_files -quiet {MicroblazeBasicCore.bd}]
  
# Override if we've got a different one
if { [info exists ::env(RUCKMORE_MICROBLAZE)] } {
	set bd_name [string map{\" {}} $::env(RUCKMORE_MICROBLAZE)]
	set mbPath "${bd_name.bd}"
}
 
   # Check if SDK_SRC_PATH is a valid path
   if { [expr [info exists ::env(SDK_SRC_PATH)]] == 1 && ${mbPath} != "" &&
        [file exists ${OUT_DIR}/${VIVADO_PROJECT}.runs/impl_1/${PROJECT}.sysdef] == 1 } {
      # Check if custom SDK exist
      if { [file exists ${VIVADO_DIR}/sdk.tcl] == 1 } {   
         source ${VIVADO_DIR}/sdk.tcl
      } else {
         set SDK_PRJ_RDY false
         set SDK_RETRY_CNT 0
         while { ${SDK_PRJ_RDY} != true } {
            set src_rc [catch {exec xsdk -batch -source ${RUCKUS_DIR}/vivado_sdk_prj.tcl >@stdout} _RESULT]      
            if {$src_rc} {
               puts "\n********************************************************"
               puts "Retrying to build SDK project"
               puts ${_RESULT}
               puts "********************************************************\n"
               # Increment the counter
               incr SDK_RETRY_CNT
               # Check for max retries
               if { ${SDK_RETRY_CNT} == 10 } {
                  puts "Failed to build the SDK project"
                  exit -1
                  # break
               }
            } else {
               set SDK_PRJ_RDY true
            }         
         }
         # Generate .ELF
         set src_rc [catch {exec xsdk -batch -source ${RUCKUS_DIR}/vivado_sdk_elf.tcl >@stdout}]    
         # Add .ELF to the .bit file
         source ${RUCKUS_DIR}/vivado_sdk_bit.tcl       
      }
   }

   # Target specific post_route script
   SourceTclFile ${VIVADO_DIR}/post_route.tcl
}

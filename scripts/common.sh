#!/usr/bin/env bash

###########
# Salesforce Easy Deployments - Templated Script
# common.sh
# Runs script sanity checks and sets common global variables.
#  
# Last Modified: January 2022
# By: Benjamin Ngo
###########

# In the specific scripts, please run $(startScript) before sourcing common.sh.
# $(startScript) will set the needed $scripts_path and $repo_path variables.


# Sanity check to check if running script is located in the correct repo subfolder.
isScriptsPathValid () {
    local scripts_folder_expected_name="scripts"
    local running_script_folder_name="${scripts_path##*/}"
    
    test "$running_script_folder_name" = "${scripts_folder_expected_name}"
    local do_scripts_folders_match=$?
    if [ $do_scripts_folders_match -eq 1 ]; then
        error_scripts_folder="Error: Parent directory of Running Script does not appear correct."
        echo "${script_name}: ${error_scripts_folder}"
        exit 1
    fi
}

# Sanity check to check if Working Directory is the repo directory.
isRepoSetAsWorkingDirectory () (
    local required_repo_file="sfdx-project.json"
    if [ ! -f "$required_repo_file" ]; then
        error_repo_folder="Error: Parent directory of directory of Running Script does not appear correct."
        echo "${script_name}: ${error_repo_folder}"
        exit 1
    fi
)

# If sanity checks pass, sets common global variables.
checkScriptAndSetGlobalVariables () {
    if isScriptsPathValid && isRepoSetAsWorkingDirectory; then
        pmd_version="6.41.0"
        pmd_run_command="${repo_path}/pmd-bin-${pmd_version}/bin/run.sh pmd"
    else
        exit 1
    fi
}

#!/usr/bin/env bash
set -euo pipefail

###########
# @title Salesforce Easy Checks - Templated Script
# @filename common.sh
# @description Runs script sanity checks and sets common global variables.
# @author Benjamin Ngo
###########

# In the specific scripts, before sourcing common.sh, please run $(startScript).
# $(startScript) will set the needed $script_folder_path and $repo_path variables.


# @description Displays a message with the script name prepended. 
# @param {$1} The message text.
displayMessage () {
    local message="$*"
    echo "${script_name}: ${message}" 
}


# @description Displays a message and returns an exit status of 0 (success).
# @param {$1} The message text.
displayMessageAndReturn () {
    local message="$*"
    echo "${script_name}: ${message}"
    return 0
}


# @description Displays an error and quits the script.
# @param {$1} The error text.
displayErrorAndQuit () {
    local error_message="$*"
    echo "${script_name}: ${error_message}"
    exit 1
}


# @description Displays a three-line error message, and then quits the script.
# @param {$1} Error text for the first line.
# @param {$2} Error text for the second line.
# @param {$2} Error text for the third line.
displayErrorThreeLinesAndQuit () {
    local error_line_one="$1"
    local error_line_two="$2"
    local error_line_three="$3"
    echo "${script_name}: ${error_line_one}"
    echo "${script_name}: ${error_line_two}"
    echo "${script_name}: ${error_line_three}"
    exit 1
}


# @description Checks if running script is located in the correct repo subfolder.
isScriptsPathValid () {
    local scripts_folder_expected_name="scripts"
    local running_script_folder_name="${script_folder_path##*/}"
    
    test "${running_script_folder_name}" = "${scripts_folder_expected_name}"
    local do_scripts_folders_match=$?
    if [ ${do_scripts_folders_match} -eq 1 ]; then
        local error_scripts_folder="Error: Parent directory of Running Script does not appear correct."
        displayErrorAndQuit "${error_scripts_folder}"
    fi
}


# @description Checks if Working Directory is the repo directory.
isRepoSetAsWorkingDirectory () (
    local required_repo_file="sfdx-project.json"
    if [ ! -f "${required_repo_file}" ]; then
        local error_repo_folder="Error: Parent directory of directory of Running Script does not appear correct."
        displayErrorAndQuit "${error_repo_folder}"
    fi
)


# @description Runs sanity checks and then sets common global variables.
checkScriptAndSetGlobalVariables () {
    if isScriptsPathValid && isRepoSetAsWorkingDirectory; then
        pmd_version="6.41.0"
        pmd_script_path="${repo_path}/pmd-bin-${pmd_version}/bin/run.sh"
    else
        exit 1
    fi
}


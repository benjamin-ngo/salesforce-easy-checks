#!/usr/bin/env bash
set -euo pipefail

###########
# @title Salesforce Easy Checks - Templated Script
# @filename lint.sh
# @description Checks code quality of Aura, LWC, and Apex files.
# @author Benjamin Ngo
###########


# @description Sets working directory and runs script sanity checks.
startScript () {
    script_name="$(basename -- "${BASH_SOURCE[0]}")"
    local script_folder_path=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"; pwd)
    local repo_path="${script_folder_path%*/*}"
    local common_script_name="common.sh"

    cd "${repo_path}"
    source "${script_folder_path}/${common_script_name}"
    checkScriptAndSetGlobalVariables
}


# @description Quits for bad git branch names.
# @param {$1} The name of the git branch to check.
quitIfBranchNameNotValid () {
    local branch_to_check="$*"
    case "${branch_to_check}" in
        *" "* | "" )
            local error_branch_name="Error: Please pass function with a valid git branch name."
            displayErrorAndQuit "${error_branch_name}"
            ;;
    esac
}



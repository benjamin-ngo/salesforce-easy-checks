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


# @description Gets the latest changes for the specified branch.
# @param {$1} The name of the git branch to fetch from.
fetchBranch () {
    # Quits if the branch name is not valid.
    local branch_to_check="$*"
    quitIfBranchNameNotValid "${branch_to_check}"

    local message_fetching_now="Fetching latest \"${branch_to_check}\" branch..."
    displayMessage "${message_fetching_now}"
    echo ""

    # Empty file ensures git stash works if there are no unsaved changes in the repo.
    local git_stash_file=".lintsh_gitstash.txt"
    local error_stash_or_fetch="Error with saving working directory or retrieving Git branches."
    touch "${git_stash_file}" || displayErrorAndQuit "${error_stash_or_fetch}"

    local stash_message="Working directory before ./scripts/lint.sh"
    local is_stash_successful=1
    local is_function_successful=0
    {
        git stash push --include-untracked --message "${stash_message}" &&
        is_stash_successful=$? &&
        git fetch --no-tags --depth=1 origin "${branch_to_check}" &&
        git checkout "${branch_to_check}" &&
        git checkout "@{-1}"
    } ||
    {
        is_function_successful=1
    }
    
    # Restores the working directory back to its original state.
    if [ "${is_stash_successful}" -eq "0" ]; then
        git stash pop
    fi
    rm "${git_stash_file}"
    echo ""
    if [ "${is_function_successful}" -eq "1" ]; then
        displayErrorAndQuit "${error_stash_or_fetch}"
    fi
}



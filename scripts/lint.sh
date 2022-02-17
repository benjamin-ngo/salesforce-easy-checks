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


# @description Lists added or modified (not deleted) files, for the specified upstream branch and file extension.
# @param {$1} The name of the upstream git branch to diff against. 
# @param {$2} The file extension to filter the diff against.
diffForBranchAndExtension () {
    # Quits if invalid arguments are provided.
    if [ "$#" -ne "2" ]; then
        local error_argument_incorrect="Error: \$(diffForBranchAndExtension) expects two arguments."
        local suggestion_argument_upstream_branch="The first argument is the name of the upstream git branch to diff against."
        local suggestion_argument_file_extension="The second argument is the file extension to filter the diff against. Valid options are \"js\" or \"cls\"."
        displayErrorThreeLinesAndQuit "${error_argument_incorrect}" "${suggestion_argument_upstream_branch}" "${suggestion_argument_file_extension}"
    fi
    local upstream_branch="$1"
    quitIfBranchNameNotValid "${upstream_branch}"

    # Uses the second argument to determine git diff behavior. Quits if second argument is invalid.
    local file_extension_to_filter_for="$2"
    local git_path_globs
    case "${file_extension_to_filter_for}" in
        "js" )
            # Test files are not supported for now.
            git_path_globs="**/aura/*/*.js **/lwc/*/*.js :(exclude)*.test.js"
            ;;
        "cls" )
            git_path_globs="**/classes/*.cls"
            ;;
        * )
            local error_argument_file_extension="Error: Valid options for the second argument of \$(diffForBranchAndExtension) are \"js\" or \"cls\"."
            displayErrorAndQuit "${error_argument_file_extension}"
    esac

    # Runs git diff against the specified file extension and upstream branch.
    local list_of_diff
    {
        list_of_diff=$(git diff --name-only "${upstream_branch}" --diff-filter=d -- ${git_path_globs})
    } ||
    {
        local error_git_diff="Error with git diff for branch \"${upstream_branch}\" and file extension \"${file_extension_to_filter_for}\"."
        displayErrorAndQuit "${error_git_diff}"
    }
    echo "${list_of_diff}"
}

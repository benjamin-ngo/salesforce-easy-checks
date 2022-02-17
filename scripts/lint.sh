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


# @description Lints Aura and LWC JavaScript files and outputs linting results.
# @param {$1} Space-separated list of Aura/LWC files or directories for linting.
lintJS () {
    # Quits for invalid arguments, or if npm or ESLint is not installed.
    local js_files_to_lint="$*"
    local js_linter_path="node_modules/eslint/bin/eslint.js"
    if [ -z "${js_files_to_lint}" ]; then
        local error_argument_incorrect="Error: \$(lintJS) expects a space-separated list of Aura/LWC files or directories as arguments."
        displayErrorAndQuit "${error_argument_incorrect}"
    elif [ ! -f "${js_linter_path}" ]; then
        local error_no_js_linter="Error with locating npm or ESLint. Ensure npm is installed, run \"npm install\" from the repo directory, and then try again."
        displayErrorAndQuit "${error_no_js_linter}"
    fi

    # Lints the JS files and outputs the results.
    {
        node ${js_linter_path} --no-error-on-unmatched-pattern ${js_files_to_lint}
    } ||
    {
        # ESLint documentation specifies exit status of 2 indicates ESLint internal issues.
        local js_linter_status="$?"
        if [ "${js_linter_status}" -eq 2 ]; then
            local error_linting_js="Error: Aura/LWC linting failed due to an ESLint configuration problem or internal error."
            displayErrorAndQuit "${error_linting_js}"
        else
            return "${js_linter_status}"
        fi
    }

}


# @description Lints Apex .cls files and outputs linting results.
# @param {$1} Comma-separated list of files or directories containing Apex files for linting.
lintCls () {
    # Quits for invalid arguments, or if PMD is not installed.
    local cls_files_to_lint="$*"
    local cls_linter_path="${pmd_script_path}"
    if [ -z "${cls_files_to_lint}" ]; then
        local error_argument_incorrect="Error: \$(lintCls) expects Apex directories or files as arguments."
        displayErrorAndQuit "${error_argument_incorrect}"
    elif [ ! -f "${cls_linter_path}" ]; then
        local error_no_cls_linter="Error with locating PMD. Please run \"./scripts/postinstall.sh\" from the repo directory and then try again."
        displayErrorAndQuit "${error_no_cls_linter}"
    fi

    # Lints the Apex files and outputs the results.
    local cls_linter_rulesets="force-app/main/default/classes/.pmd-rules.xml"
    {
        "${cls_linter_path}" pmd --no-cache --format textcolor --rulesets "${cls_linter_rulesets}" --dir "${cls_files_to_lint}"
    }  ||
    {
        # PMD documentation specifies exit status of 1 indicates PMD internal issues.
        local cls_linter_status="$?"
        if [ "$?" -eq 1 ]; then
            local error_linting_pmd="Error: Apex linting failed due to arguments or a PMD exception."
            displayErrorAndQuit "${error_linting_pmd}"
        else
            return "${cls_linter_status}"
        fi
    }
}


# @description Lints repo by calling dedicated linting functions for results.
# @param {$1} Space-separated list of Aura/LWC files or directories for linting, or an empty argument.
# @param {$2} Comma-separated list of Apex files or directories for linting, or an empty argument.
lintRepo () {
    # Quits if invalid arguments are provided.
    if [ "$#" -ne "2" ]; then
        local error_argument_incorrect="Error: \$(lintRepo) expects two arguments."
        local suggestion_argument_js="The first argument is a space-separated list of Aura/LWC files or directories for linting, or an empty argument."
        local suggestion_argument_cls="The second argument is a comma-separated list of Apex files or directories for linting, or an empty argument."
        displayErrorThreeLinesAndQuit "${error_argument_incorrect}" "${suggestion_argument_js}" "${suggestion_argument_cls}"
    fi

    # Lints repo.
    local js_repo_paths="$1"
    local cls_repo_paths="$2"
    local lintJS_results=0
    local lintCls_results=0
    local message_linting_now="Linting files now..."
    displayMessage "${message_linting_now}"
    
    # Skips linting if no arguments are given.
    set +e
    if [ -n "${js_repo_paths}" ] ; then
        lintJS "${js_repo_paths}"
        lintJS_results=$?
    fi
    # Single comma argument is used to work around how PMD Linter parses arguments.
    if [ "${cls_repo_paths}" != "," ] || [ -n "${cls_repo_paths}" ]; then
        lintCls "${cls_repo_paths}"
        lintCls_results=$?
    fi
    set -e
    
    # Displays linting results.
    echo ""
    if [ "${lintJS_results}" -ne 0 ] || [ "${lintCls_results}" -ne 0 ]; then
        local error_linting_failed=">>> Some files FAILED linting. Please check above for details. <<<"
        displayErrorAndQuit "${error_linting_failed}"
    else
        local message_linting_passed=">>> All files PASSED linting. <<<"
        displayMessage "${message_linting_passed}"
    fi
}


# @description Sets up and runs linters based on user input.
# @param {$1} User input keyphrase to determine linting behavior.
main () {
    startScript
    script_parameter="$*"
    case "${script_parameter}" in

        "diff:all")
            local upstream_branch="main"
            fetchBranch "${upstream_branch}"

            diff_of_js_files=$(diffForBranchAndExtension "${upstream_branch}" "js")
            diff_of_cls_files=$(diffForBranchAndExtension "${upstream_branch}" "cls" | tr "\n" ",")
            lintRepo "${diff_of_js_files}" "${diff_of_cls_files}"
            ;;

        "repo:all")
            local js_repo_paths="force-app/main/default/lwc force-app/main/default/aura"
            local cls_repo_paths="force-app/main/default/classes"
            lintRepo "${js_repo_paths}" "${cls_repo_paths}"
            ;;

        # Script returns instead of quitting to make testing easier.
        *)
            local error_linting_pmd="Error with arguments. Try \"./scripts/lint.sh diff:all\" to lint changed files, or try \"./scripts/lint.sh repo:all\" to lint all files."
            displayMessageAndReturn "${error_linting_pmd}"
            ;;
    esac
}
main "$*"


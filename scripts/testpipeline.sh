#!/usr/bin/env bash
set -euo pipefail

###########
# @title Salesforce Easy Checks - Templated Script
# @filename testpipeline.sh
# @description Runs automated unit and integration tests to ensure checks pipeline works.
# @author Benjamin Ngo
###########


# @description Sets global variables and the working directory.
startScriptForTestpipeline () {
    script_folder_path=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"; pwd)
    local repo_path="${script_folder_path%*/*}"
    cd "${repo_path}"

    pmd_version="6.41.0"
    pmd_folder="pmd-bin-${pmd_version}"
}


# @description Displays an error message, without the script name prepended.
# @param {$1} The test error message text.
displayTestErrorAndReturn () {
    local test_error="$*"
    echo ""
    echo "${test_error}" 
    echo ""
    return 1
}


# @description Displays an error if environment setup or clean up for tests fail.
testSetupOrTeardownFailed () {
    local error_setup_failed="[*** ERROR ***] Test setup or teardown for ${script_name} has failed."
    displayTestErrorAndReturn "${error_setup_failed}"
}


# @description Displays syntax help text for $(testScriptOrFunction).
testScriptOrFunctionErrorSyntax () {
    local error_argument_incorrect="[*** ERROR ***] Two arguments are expected for \$(testScriptOrFunction)."
    local suggestion_argument_exit_status="To test for exit statuses, try syntax \$(testScriptOrFunction \"script_path_or_function\" \"expected_exit_status\")."
    local suggestion_argument_error_stub="To test for partial error messages, try syntax \$(testScriptOrFunction \"script_path_or_function\" \"expected_error_message_stub\")."
    echo ""
    echo "${error_argument_incorrect}"
    echo "${suggestion_argument_exit_status}"
    echo "${suggestion_argument_error_stub}"
    echo ""
    return 1
}


# @description Tests script file or function and outputs the result. To test a script function, please source the script first.
# @param {$1} The path of the script file, or the name of a script function.
# @param {$2} A numeric exit status value, or the partial error message for a failure exit status.
testScriptOrFunction () {
    # Quits if provided arguments are not supported.
    if [ "$#" -ne "2" ]; then
        testScriptOrFunctionErrorSyntax
    elif [ "$2" = "" ]; then
        local error_argument_empty="[*** ERROR ***] Empty strings for \$(testScriptOrFunction) are not supported."
        displayTestErrorAndReturn "${error_argument_empty}"
    fi

    # Tests the script file or function. Captures the results.
    local command_to_test="$1"
    local command_to_test_output
    command_to_test_output=$(${command_to_test})
    local command_to_test_exit_status=$?

    # Sets labels and messages based on the input parameters.
    local test_name_type
    local unit_test_details=""
    if [ "${command_to_test}" = "${script_path}" ]; then
        test_name_type="Script Test"
    else
        test_name_type="Function Test"
        unit_test_details=" : \$(${command_to_test})"
    fi

    local expected_result="$2"
    local test_outcome_type
    if [ "${expected_result}" = "0" ]; then
        test_outcome_type="Positive"
    else
        test_outcome_type="Negative"
    fi
    local message_test_passes="[ PASS ] ${test_outcome_type} ${test_name_type} for ${script_name}${unit_test_details}"
    local error_test_fails="[*** FAIL ***] ${test_outcome_type} ${test_name_type} for ${script_name}${unit_test_details}"


    # Tests to see if the output is expected. 
    local is_result_expected
    local is_expected_result_displayed=1
    local exit_status_expected
    case "${expected_result}" in

        # Non-numeric ${expected_result} is assumed to be an error message stub.
        *[!0-9]* )
            # Parameter Expansion ensures ${output_result_comparison} is empty if there is a partial string match.
            local output_result_comparison=${command_to_test_output##*$expected_result*}
            is_expected_result_displayed=0
            exit_status_expected="An exit status from 1 to 255."
            
            if [ -z "${output_result_comparison}" ]; then
                [ ${command_to_test_exit_status} -ge 1 ]
                is_result_expected=$?
            else
                is_result_expected=1
            fi
            ;;

        # Numeric ${expected_result} will be tested for exit status only.
        * )
            exit_status_expected="${expected_result}"
            test "${command_to_test_exit_status}" -eq "${expected_result}"
            is_result_expected=$?
            ;;
    esac

    # Displays results of the test.
    if [ ${is_result_expected} -eq 0 ]; then
        echo "${message_test_passes}"
        return 0
    else
        echo ""
        echo "${error_test_fails}"
        echo "Expected Exit Status: ${exit_status_expected}"
        echo "Actual Exit Status: ${command_to_test_exit_status}"

        # If $2 is an error message stub, displays the expected output.
        if [ "${is_expected_result_displayed}" -eq 0 ]; then
            echo "Expected Output: ${expected_result}"
        fi
        echo "Actual Output (on next line):"
        echo "${command_to_test_output}"
        echo ""
        return 1
    fi
}


# @description Runs a test for the specified script file.
# @param {$1} The script filename.
testAndSetScriptPath () {
    script_name="$*"
    script_path="${script_folder_path}/${script_name}"
    testScriptOrFunction "${script_path}" "0"
}


# @description Runs tests specific for scripts/common.sh
testsForCommonSH () (
    testAndSetScriptPath "common.sh"
    source "${script_path}" 
    
    local error_display_test="\"Test message\""
    testScriptOrFunction "displayErrorAndQuit ${error_display_test}" "${error_display_test}"
    testScriptOrFunction "displayErrorThreeLinesAndQuit 111aaa 222bbb 333ccc" "222bbb"
    
    local error_repo_folder="Error: Parent directory of directory of Running Script does not appear correct."
    mv --no-clobber "sfdx-project.json" "sfdx-project.json.original" || testSetupOrTeardownFailed
    testScriptOrFunction "isRepoSetAsWorkingDirectory" "${error_repo_folder}"
    testScriptOrFunction "checkScriptAndSetGlobalVariables" "${error_repo_folder}"
    mv --no-clobber "sfdx-project.json.original" "sfdx-project.json" || testSetupOrTeardownFailed
)


# @description Runs tests specific for scripts/postinstall.sh
testsForPostinstallSH () (
    if [ -d "${pmd_folder}" ]; then
        mv "${pmd_folder}" "${pmd_folder}.original" || testSetupOrTeardownFailed
    fi

    # Test is repeated to test $(installPmd) and $(quitIfPmdAlreadyInstalled).
    # Standard Error is redirected to suppress curl output.
    (testAndSetScriptPath "postinstall.sh") 2> /dev/null
    (testAndSetScriptPath "postinstall.sh") 2> /dev/null
    mv "${pmd_folder}.original" "${pmd_folder}"  || testSetupOrTeardownFailed
)


# @description Runs tests specific for scripts/lint.sh
testsForLintSH () (
    # Standard Output is redirected to suppress help message for lint.sh arguments. 
    testAndSetScriptPath "lint.sh"
    source "${script_path}" > /dev/null
    
    local invalid_branch_name="invalid branch name"
    local empty_argument=""
    local error_branch_name="Error: Please pass function with a valid git branch name."
    testScriptOrFunction "quitIfBranchNameNotValid ${invalid_branch_name}" "${error_branch_name}"
    testScriptOrFunction "quitIfBranchNameNotValid ${empty_argument}" "${error_branch_name}"
    
    local error_argument_incorrect_diff="Error: \$(diffForBranchAndExtension) expects two arguments."
    testScriptOrFunction "diffForBranchAndExtension ${empty_argument}" "${error_argument_incorrect_diff}"
    testScriptOrFunction "diffForBranchAndExtension 1 2 3" "${error_argument_incorrect_diff}"

    local error_argument_incorrect_lintJS="Error: \$(lintJS) expects a space-separated list of Aura/LWC files or directories as arguments."
    testScriptOrFunction "lintJS ${empty_argument}" "${error_argument_incorrect_lintJS}"
    
    local error_no_js_linter="Error with locating npm or ESLint. Ensure npm is installed, run \"npm install\" from the repo directory, and then try again."
    mv --no-clobber "node_modules" "node_modules.original" || testSetupOrTeardownFailed
    testScriptOrFunction "lintJS force-app" "${error_no_js_linter}"
    mv --no-clobber "node_modules.original" "node_modules" || testSetupOrTeardownFailed

    local error_argument_incorrect_cls="Error: \$(lintCls) expects Apex directories or files as arguments."
    testScriptOrFunction "lintCls" "${error_argument_incorrect_cls}"

    local error_no_cls_linter="Error with locating PMD. Please run \"./scripts/postinstall.sh\" from the repo directory and then try again."
    mv "${pmd_folder}" "${pmd_folder}.original" || testSetupOrTeardownFailed
    testScriptOrFunction "lintCls force-app" "${error_no_cls_linter}"
    mv "${pmd_folder}.original" "${pmd_folder}" || testSetupOrTeardownFailed

    local error_argument_incorrect_lintRepo="Error: \$(lintRepo) expects two arguments."
    testScriptOrFunction "lintRepo ${empty_argument}" "${error_argument_incorrect_lintRepo}"
    testScriptOrFunction "lintRepo 1 2 3" "${error_argument_incorrect_lintRepo}"
)


# @description Runs slower tests for the $(lintJS) and $(lintCls) functions from scripts/lint.sh. Assumes lint.sh is sourced in beforehand.
testsForLintShLinters () {
    # Sets up the test environment.
    local aura_test_directory="tests/aura_test"
    local lwc_test_directory="tests/lwc_test"
    local cls_test_directory="tests/classes_test"
    {
        cp --no-clobber "force-app/main/default/aura/.eslintrc.json" "${aura_test_directory}/.eslintrc.json" &&
        cp --no-clobber "force-app/main/default/lwc/.eslintrc.json" "${lwc_test_directory}/.eslintrc.json" 
    } || testSetupOrTeardownFailed

    # Runs various tests.
    local aura_to_lint_clean="${aura_test_directory}/auraToTestLinter/auraToTestLinter_clean.js"
    local lwc_to_lint_clean="${lwc_test_directory}/lwcToTestLinter/lwcToTestLinter_clean.js"
    testScriptOrFunction "lintJS ${aura_to_lint_clean} ${lwc_to_lint_clean}" "0"

    local aura_to_lint_bad="${aura_test_directory}/auraToTestLinter/auraToTestLinter_bad.js"
    local lwc_to_lint_bad="${lwc_test_directory}/lwcToTestLinter/lwcToTestLinter_bad.js"
    testScriptOrFunction "lintJS ${aura_to_lint_bad} ${lwc_to_lint_bad}" "10 problems (10 errors, 0 warnings)"   
    
    local cls_to_lint_clean="${cls_test_directory}/clsToTestLinter/clsToTestLinter_clean.cls"
    local cls_to_lint_bad="${cls_test_directory}/clsToTestLinter/clsToTestLinter_bad.cls"
    testScriptOrFunction "lintCls ${cls_to_lint_clean}" "0"
    testScriptOrFunction "lintCls ${cls_to_lint_bad}" "OperationWithLimitsInLoop"

    # Cleans up the test environment and performs a failing test.
    {
        rm "${aura_test_directory}/.eslintrc.json" &&
        rm "${lwc_test_directory}/.eslintrc.json" 
    } || testSetupOrTeardownFailed
    local error_linting_js="Error: Aura/LWC linting failed due to an ESLint configuration problem or internal error."
    testScriptOrFunction "lintJS ${lwc_to_lint_clean}" "${error_linting_js}" 2> /dev/null
}


# @description Runs tests for the $(diffForBranchAndExtension) function from scripts/lint.sh. Assumes lint.sh is sourced in beforehand.
testsForLintShDiff () {
    # Sets up the test for diff of new files.
    local aura_test_directory="tests/aura_test"
    local lwc_test_directory="tests/lwc_test"
    local cls_test_directory="tests/classes_test"

    local aura_test_directory_renamed="tests/aura"
    local lwc_test_directory_renamed="tests/lwc"
    local cls_test_directory_renamed="tests/classes"
    local aura_to_lint_clean_renamed="${aura_test_directory_renamed}/auraToTestLinter/auraToTestLinter_clean.js"
    local lwc_to_lint_clean_renamed="${lwc_test_directory_renamed}/lwcToTestLinter/lwcToTestLinter_clean.js"
    local cls_to_lint_clean_renamed="${cls_test_directory_renamed}/clsToTestLinter/clsToTestLinter_clean.cls"
    {
        mv "${aura_test_directory}" "${aura_test_directory_renamed}" &&
        mv "${lwc_test_directory}" "${lwc_test_directory_renamed}" &&
        mv "${cls_test_directory}" "${cls_test_directory_renamed}" &&
        git add "${aura_test_directory_renamed}" "${lwc_test_directory_renamed}" "${cls_test_directory_renamed}" 
    } || testSetupOrTeardownFailed

    # Tests $(diffForBranchAndExtension) for the diff of new files.
    local message_js_diff_pass="Positive Function Test for "${script_name}" : \$(diffForBranchAndExtension "${branch_to_check}" js)"
    local message_cls_diff_pass="Positive Function Test for "${script_name}" : \$(diffForBranchAndExtension "${branch_to_check}" cls)"
    js_diff_results=$(diffForBranchAndExtension "${branch_to_check}" "js")
    cls_diff_results=$(diffForBranchAndExtension "${branch_to_check}" "cls")
    
    # Manual tests are done since $(testScriptOrFunction) does not support testing output of successful exit statuses.
    case "${js_diff_results}" in
        *"${aura_to_lint_clean_renamed}"*"${lwc_to_lint_clean_renamed}"* )
            echo "[ PASS ] ${message_js_diff_pass}"
            ;;
        *)
            echo ""
            echo "[*** FAIL ***] ${message_js_diff_pass}"
            echo ""
            ;;
    esac
    case "${cls_diff_results}" in
        *"${cls_to_lint_clean_renamed}"* )
            echo "[ PASS ] ${message_cls_diff_pass}"
            ;;
        *)
            echo ""
            echo "[*** FAIL ***] ${message_cls_diff_pass}"
            echo ""
            ;;
    esac

    # Cleans up from the test for diff of new files.
    {
        git rm --cached -r --quiet "${aura_test_directory_renamed}" "${lwc_test_directory_renamed}" "${cls_test_directory_renamed}" &&
        mv "${aura_test_directory_renamed}" "${aura_test_directory}" &&
        mv "${lwc_test_directory_renamed}" "${lwc_test_directory}"  &&
        mv "${cls_test_directory_renamed}" "${cls_test_directory}"
    } || testSetupOrTeardownFailed


    # Sets up the test for diff of no changes.
    local js_diff_results_stashed
    local cls_diff_results_stashed
    local branch_to_check_stashed="HEAD"
    local git_stash_file=".testpipeline_gitstash.txt"
    local stash_message="Working directory before ./scripts/testpipeline.sh"
    {
        touch "${git_stash_file}" &&
        git stash push --include-untracked --message "${stash_message}" --quiet
    } || testSetupOrTeardownFailed
    
    # Tests for the diff of no changes.
    local message_js_diff_stash_pass="Positive Function Test for "${script_name}" : \$(diffForBranchAndExtension "${branch_to_check_stashed}" js)"
    local message_cls_diff_stash_pass="Positive Function Test for "${script_name}" : \$(diffForBranchAndExtension "${branch_to_check_stashed}" cls)"
    js_diff_results_stashed=$(diffForBranchAndExtension "HEAD" "js")
    cls_diff_results_stashed=$(diffForBranchAndExtension "HEAD" "cls")
    
    # Manual tests are done since $(testScriptOrFunction) does not support testing output of successful exit statuses.
    if [ -z "${js_diff_results_stashed}" ] && [ -z "${cls_diff_results_stashed}" ]; then
        echo "[ PASS ] ${message_js_diff_stash_pass}"
        echo "[ PASS ] ${message_cls_diff_stash_pass}"
    else
        echo "[*** FAIL ***] ${message_js_diff_stash_pass}"
        echo "[*** FAIL ***] ${message_js_diff_stash_pass}"
    fi

    # Cleans up from the test for diff of no files.
    {
        git stash pop --quiet &&
        rm "${git_stash_file}"
    } || testSetupOrTeardownFailed
}


# @description Runs tests for scripts/lint.sh that involve third-party tools, including linters or git. 
testsForLintShSlow () (
    # Standard output or error is sometimes redirected to suppress unneeded CLI messages.
    local script_name="lint.sh"
    local script_path="${script_folder_path}/${script_name}"
    source "${script_path}" > /dev/null

    local branch_to_check="main"
    local branch_to_check_bad="testNotRealBranchAtAll"
    local error_stash_or_fetch="Error with saving working directory or retrieving Git branches."
    testScriptOrFunction "fetchBranch ${branch_to_check}" "0"  2> /dev/null
    testScriptOrFunction "fetchBranch ${branch_to_check_bad}" "${error_stash_or_fetch}" 2> /dev/null

    testsForLintShLinters
    testsForLintShDiff
)


# @description Runs fast Unit Tests for each script file.
testSuiteToRunFast () {
    testAndSetScriptPath "preinstall.js"
    testsForCommonSH
    testsForLintSH
}


# @description Runs slower Integration Tests for each script file.
testSuiteToRunSlow () {
    testsForPostinstallSH
    testsForLintShSlow
}


# @description Sets up and runs the testing pipeline.
main () {
    startScriptForTestpipeline
    local message_run_tests_fast="Running Unit Tests now..."
    local message_run_tests_slow="Running Integration Tests now..."
    local test_results_fast
    local test_results_slow

    # Runs the tests.
    echo "${message_run_tests_fast}"
    test_results_fast=$(testSuiteToRunFast) && 
    echo "$test_results_fast" 
    echo ""
    echo "${message_run_tests_slow}"
    test_results_slow=$(testSuiteToRunSlow) && 
    echo "$test_results_slow"
    echo ""

    # Determines the cumulative test results.
    local test_results_all="${test_results_fast} ${test_results_slow}"
    case "${test_results_all}" in
        *"[*** FAIL ***]"* | *"[*** ERROR ***]"* ) 
            echo ""
            local error_test_suite_failed=">>> Some tests FAILED. Please check above for details. <<<"
            echo "${error_test_suite_failed}"
            echo ""
            return 1
            ;;
        * ) 
            local message_test_suite_passed=">>> All tests PASSED. <<<"
            echo "${message_test_suite_passed}"
            echo ""
            return 0
            ;;
    esac
}
main


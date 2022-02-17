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


# Displays syntax help text for $(testScriptOrFunction).
testScriptOrFunctionErrorSyntax () {
    local error_argument_incorrect="[*** ERROR ***] Two arguments are expected for \$(testScriptOrFunction)."
    local suggestion_argument_exit_status="To test for exit statuses of 0 or 1, try syntax \$(testScriptOrFunction \"script_path_or_function\" \"expected_exit_status\")."
    local suggestion_argument_error_stub="To test for error messages, try syntax \$(testScriptOrFunction \"script_path_or_function\" \"expected_error_message_stub\")."
    echo ""
    echo "${error_argument_incorrect}"
    echo "${suggestion_argument_exit_status}"
    echo "${suggestion_argument_error_stub}"
    echo ""
    return 1
}


# Shows that $(testScriptOrFunction) does not support empty string arguments. 
testScriptOrFunctionArgumentEmpty () {
    local error_argument_empty="[*** ERROR ***] Empty strings for \$(testScriptOrFunction) are not supported"
    echo ""
    echo "${error_argument_empty}"
    echo ""
    return 1
}


# Tests script file or function and outputs the result. Expects 2 arguments.
    # First argument: The path of the script file, or the name of a script function.
    # Second argument: An exit status of 0 or 1, or the expected error message stub (without the filename).
# To test a script function, please source the script beforehand.
testScriptOrFunction () {
    # Quits if provided arguments are not supported.
    if [ "$#" -ne "2" ]; then
        testScriptOrFunctionErrorSyntax
    elif [ "$2" = "" ]; then
        testScriptOrFunctionArgumentEmpty
    fi

    # Tests the script file or function. Captures the results.
    local command_to_test="$1"
    local command_to_test_output
    command_to_test_output=$($command_to_test)
    local command_to_test_exit_status=$?

    # Sets labels and messages based on the input parameters.
    local test_name_type
    local unit_test_details=""
    if [ "$command_to_test" = "$script_path" ]; then
        test_name_type="Integration Test"
    else
        test_name_type="Unit Test"
        unit_test_details=" : \$(${command_to_test})"
    fi

    local expected_result="$2"
    local test_outcome_type
    if [ "$expected_result" = "0" ]; then
        test_outcome_type="Positive"
    else
        test_outcome_type="Negative"
    fi
    local message_test_passes="[ PASS ] ${test_outcome_type} ${test_name_type} for ${script_name}${unit_test_details}"
    local error_test_fails="[*** FAIL ***] ${test_outcome_type} ${test_name_type} for ${script_name}${unit_test_details}"


    # Tests to see if the output is expected. 
    local is_result_expected
    local exit_status_expected
    case "$expected_result" in
        "0" | "1")
            exit_status_expected="$expected_result"
            test "$command_to_test_exit_status" -eq "$expected_result"
            ;;
        *)
            exit_status_expected=1
            local expected_error_message_full="${script_name}: ${expected_result}"
            [ $command_to_test_exit_status -eq $exit_status_expected ] && [ "$command_to_test_output" = "$expected_error_message_full" ]
            ;;
    esac
    is_result_expected=$?

    # Displays results of the test.
    if [ $is_result_expected -eq 0 ]; then
        echo "${message_test_passes}"
        return 0
    else
        echo ""
        echo "${error_test_fails}"
        echo "Expected Exit Status: ${exit_status_expected}"
        echo "Actual Exit Status: ${command_to_test_exit_status}"

        # If $2 is an error message stub, displays the expected output.
        if [ "$expected_result" != 0 ] && [ "$expected_result" != 1 ]; then
            echo "Expected Output: ${expected_error_message_full}"
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
    source "$script_path" 
    {
        local error_display_test="\"Test message\""
        testScriptOrFunction "displayErrorAndQuit ${error_display_test}" "${error_display_test}"
    }
    {
        local error_repo_folder="Error: Parent directory of directory of Running Script does not appear correct."
        mv --no-clobber "sfdx-project.json" "sfdx-project.json.original" &&
        testScriptOrFunction "isRepoSetAsWorkingDirectory" "${error_repo_folder}"
        testScriptOrFunction "checkScriptAndSetGlobalVariables" "${error_repo_folder}"
        mv --no-clobber "sfdx-project.json.original" "sfdx-project.json"
    }
)


# @description Runs tests specific for scripts/postinstall.sh
testsForPostinstallSH () (
    if [ -d "${pmd_folder}" ]; then
        mv "${pmd_folder}" "${pmd_folder}.original"
    fi
    {
        # Standard Error is redirected to suppress curl output.
        # Two tests are done to check $(installPmd) and $(quitIfPmdAlreadyInstalled) functions.
        (testAndSetScriptPath "postinstall.sh") 2> /dev/null
        (testAndSetScriptPath "postinstall.sh") 2> /dev/null
    } &&
    rm --recursive "${pmd_folder}"
    mv "${pmd_folder}.original" "${pmd_folder}" 
)


# @description Runs fast Unit Tests for each script file.
testSuiteToRunFast () {
    testAndSetScriptPath "preinstall.js"
    testsForCommonSH
}


# @description Runs slower Integration Tests for each script file.
testSuiteToRunSlow () {
    testsForPostinstallSH
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


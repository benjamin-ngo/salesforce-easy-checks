#!/usr/bin/env bash
set -euo pipefail

###########
# Salesforce Easy Checks - Templated Script
# postinstall.sh
# Supports installing non-NPM dependencies (such as PMD) after running "npm install".
#  
# Last Modified: January 2022
# By: Benjamin Ngo
###########


# Sets global variables and working directory. Runs script sanity checks.
startScript () {
    script_name="$(basename -- "${BASH_SOURCE[0]}")"
    script_folder_path=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"; pwd)
    repo_path="${script_folder_path%*/*}"
    common_script_name="common.sh"

    cd "$repo_path"
    source "${script_folder_path}/${common_script_name}"
    checkScriptAndSetGlobalVariables
}

# Quits the script if the correct PMD version is already installed.
# Some PMD variables are defined in $(checkScriptAndSetGlobalVariables) of common.sh
quitIfPmdAlreadyInstalled () {
    # Returns if PMD is not installed.
    if [ ! -f "${pmd_script_path}" ]; then
        return 0
    fi

    # Quits if correct PMD version is already installed.
    pmd_version_output=$( "${pmd_script_path}" pmd --version  )
    test "${pmd_version_output#PMD }" = "${pmd_version}"
    do_pmd_versions_match=$?
    if [ $do_pmd_versions_match -eq 0 ]; then
        message_pmd_already_installed="Correct PMD version already exists. Skipping download."
        echo "${script_name}: ${message_pmd_already_installed}"
        exit 0
    fi
}

# Installs PMD. Default behavior does not overwrite files.
# $pmd_version is defined in $(checkScriptAndSetGlobalVariables) of common.sh
installPmd () {
    pmd_download_path="https://github.com/pmd/pmd/releases/download/pmd_releases/${pmd_version}/pmd-bin-${pmd_version}.zip"
    
    message_pmd_install_attempt="Attempting to download and install PMD."
    echo "${script_name}: ${message_pmd_install_attempt}"
    {
        curl --continue-at - --location --remote-name "${pmd_download_path}" &&
        unzip -n "pmd-bin-${pmd_version}.zip" &&
        rm "pmd-bin-${pmd_version}.zip"
    } ||
    {
        error_pmd_install="Error with downloading or unzipping PMD."
        echo "${script_name}: ${error_pmd_install}"
        exit 1
    }
}

# Holds script logic. Can be refactored in future to support more unit testing.
main () {
    startScript
    quitIfPmdAlreadyInstalled
    installPmd
}
main

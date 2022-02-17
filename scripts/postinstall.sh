#!/usr/bin/env bash
set -euo pipefail

###########
# @title Salesforce Easy Checks - Templated Script
# @filename postinstall.sh
# @description Installs non-NPM dependencies (such as PMD) after running "npm install".
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


# @description Quits the script if the correct PMD version is already installed.
quitIfPmdAlreadyInstalled () {
    # Returns if PMD is not installed.
    if [ ! -f "${pmd_script_path}" ]; then
        return 0
    fi

    # Quits if correct PMD version is already installed.
    local pmd_version_output
    pmd_version_output=$( "${pmd_script_path}" pmd --version )
    test "${pmd_version_output#PMD }" = "${pmd_version}"
    local do_pmd_versions_match=$?
    if [ ${do_pmd_versions_match} -eq 0 ]; then
        local message_pmd_already_installed="Correct PMD version already exists. Skipping download."
        displayMessage "${message_pmd_already_installed}"
        exit 0
    fi
}


# @description Installs PMD. Default behavior does not overwrite files.
installPmd () {
    local pmd_download_path="https://github.com/pmd/pmd/releases/download/pmd_releases/${pmd_version}/pmd-bin-${pmd_version}.zip"
    local message_pmd_install_attempt="Attempting to download and install PMD."
    echo "${script_name}: ${message_pmd_install_attempt}"
    {
        curl --continue-at - --location --remote-name "${pmd_download_path}" &&
        unzip -n "pmd-bin-${pmd_version}.zip" &&
        rm "pmd-bin-${pmd_version}.zip"
    } ||
    {
        local error_pmd_install="Error with downloading or unzipping PMD."
        displayErrorAndQuit "${error_pmd_install}"
    }
}


# @description Starts the script.
main () {
    startScript
    quitIfPmdAlreadyInstalled
    installPmd
}
main


#!/usr/bin/env bash

###########
# Salesforce Easy Deployments - Templated Script
# postinstall.sh
# Supports installing non-NPM dependencies (such as PMD) after running "npm install" 
#  
# Last Modified: January 2022
# By: Benjamin Ngo
###########


# Importable variables and dependent functions
getRepoPath () {
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
    cd ..
    pwd
}
repo_path="$(getRepoPath)"
script_name="$(basename -- "${BASH_SOURCE[0]}")"
pmd_version="6.41.0"
pmd_download_path="https://github.com/pmd/pmd/releases/download/pmd_releases/${pmd_version}/pmd-bin-${pmd_version}.zip"
pmd_run_command="${repo_path}/pmd-bin-${pmd_version}/bin/run.sh pmd"


# Script starts below.
cd "${repo_path}"

# Quits if PMD is already installed.
pmd_version_output=$( ${pmd_run_command} --version 2> /dev/null )
test "${pmd_version_output#PMD }" = "${pmd_version}"
do_pmd_versions_match=$?
if [ $do_pmd_versions_match -eq 0 ]; then
    message_pmd_already_installed="Correct PMD version already exists. Skipping download."
    echo "${script_name}: ${message_pmd_already_installed}"
    exit 0
fi

# Attempts to install PMD.
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

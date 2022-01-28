#!/usr/bin/env node

/**********
* Salesforce Easy Checks - Templated Script
* preinstall.js
* Warns and quits Scripts on non-POSIX systems.
*  
* Last Modified: January 2022
* By: Benjamin Ngo
**********/

const isWindows = process.platform === "win32";
if(isWindows){
    const isWindowsError = "\"Salesforce Easy Deployments\" only supports POSIX compatible systems."
    const isWindowsSuggestion = "Please try again with alternatives such as \"Windows Subsystem for Linux\".\n"
    console.error(isWindowsError);
    console.error(isWindowsSuggestion);
    process.exitCode = 1;
}

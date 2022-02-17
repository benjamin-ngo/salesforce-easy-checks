#!/usr/bin/env node

/**********
* @title Salesforce Easy Checks - Templated Script
* @filename preinstall.js
* @description Warns and quits scripts on non-POSIX systems.
* @author Benjamin Ngo
**********/


const path = require("path");
const scriptName = path.basename(__filename);

const isWindows = process.platform === "win32";
if(isWindows){
    const isWindowsError = "\"Salesforce Easy Checks\" only supports POSIX compatible systems."
    const isWindowsSuggestion = "Please try again with alternatives such as \"Windows Subsystem for Linux\".\n"
    console.error(scriptName + ": " + isWindowsError);
    console.error(scriptName + ": " + isWindowsSuggestion);
    process.exitCode = 1;
}


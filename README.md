# Salesforce Easy Checks

[![Code Check](../../actions/workflows/checks.yaml/badge.svg)](../../actions/workflows/checks.yaml)
[![Test Pipeline Check](../../actions/workflows/testpipeline.yaml/badge.svg)](../../actions/workflows/testpipeline.yaml)

The differences between Apex, SOQL, Aura, and LWC can be confusing. Let's make life easier.

Clone from Salesforce Easy Checks and improve your code quality today!

![Check the code by running "./scripts/lint.sh diff:all"](/docs/assets/diffAll.gif?raw=true)



## Features

:heavy_check_mark: Local scripts provide quick feedback on Apex, Aura, and LWC code

:heavy_check_mark: Github Action publishes linting results to increase confidence in Pull Requests

:heavy_check_mark: Included Unit Tests and Integration Tests allow painless expansion of features



## Requirements

The following dependencies and versions are recommended for Salesforce Easy Checks:

- A POSIX-complaint environment (ie: [Debian](https://www.debian.org/distrib/), [macOS](https://www.apple.com/ca/macos/), [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install))
- [Node.js](https://nodejs.org/en/download/) 16.14.0 and npm 8.3.1
- [unzip](https://packages.debian.org/bullseye/unzip) 6.00
- [git](https://git-scm.com/downloads) 2.30.2

If other versions are used, please run the Unit Tests and Integration Tests first.
```shell
./scripts/testpipeline.sh
```

![Run "./scripts/testpipeline.sh" to test Salesforce Easy Checks.](/docs/assets/testPipeline.gif?raw=true)



## Getting Started

1) [Create your Github Repo](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) from this Template.


2) Clone your newly created Repo. Navigate into it.
   ```Shell
   git clone https://github.com/benjamin-ngo/salesforce-easy-checks.git
   cd salesforce-easy-checks
   ```
   The URL and Directory above will differ based on your Repo.


3) Set up PMD, ESLint, and the related dependencies.
   ```Shell
   npm install
   ```


4) To lint new code:
   ```Shell
   ./scripts/lint.sh diff:all
   ```

   To lint the entire repo:
   ```Shell
   ./scripts/lint.sh repo:all
   ```

   The scripts will handle git commands, linters, and any unexpected errors!


5) For Pull Requests, a Github Action lints changed code and publishes the results.

   This increases the confidence of Pull Requests.

   ![Review the Pull Requests and see for yourself!](/docs/assets/githubAction.gif?raw=true)



## Expert Users

Feel free to customize Salesforce Easy Checks to meet your needs.

All scripts have extensive error handling and are built with modular design.

Just run the included Unit Tests and Integration Tests after each customization.
```shell
./scripts/testpipeline.sh
```



# Salesforce Easy Checks



## Introduction

Salesforce can be confusing. The differences between Apex, SOQL, Aura, and LWC can be overwhelming.

Let's make life easier. Clone from Salesforce Easy Checks and improve your code quality today!



## Features

- Local scripts provide quick feedback on Apex, Aura, and LWC code

- Github Action publishes linting results to increase confidence in Pull Requests

- Included Unit Tests and Integration Tests allow painless expansion of features



# Requirements

The following software are recommended for Salesforce Easy Checks:

- A POSIX-complaint environment (ie: [Debian](https://www.debian.org/distrib/), [macOS](https://www.apple.com/ca/macos/), [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install))
- [Node.js](https://nodejs.org/en/download/) 16.14.0 and npm 8.3.1
- [unzip](https://packages.debian.org/bullseye/unzip) 6.00
- [git](https://git-scm.com/downloads) 2.30.2

If other software versions are used, please test extensively first.



# Getting Started

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


6) *(Optional)* Customize the scripts to meet your needs.

   Scripts have extensive error handling and are built with modular design.

   Run the included Unit Tests and Integration Tests to ensure everything still works.
   ```shell
   ./scripts/testpipeline.sh
   ```



# Licensing

Placeholder text.


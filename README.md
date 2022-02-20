# Salesforce Easy Checks


## Introduction

Salesforce can be confusing. The differences between Apex, SOQL, Aura, and LWC can be overwhelming.
Let Salesforce Easy Checks make life easier. Clone from this Repo and improve your code quality today!


## Features

- Local scripts provide quick feedback on Apex, Aura, and LWC code
- Github Action publishes linting results to increase confidence in Pull Requests
- Included Unit Tests and Integration Tests allow painless expansion of features


# Requirements

The following software are recommended for Salesforce Easy Checks:

- A [POSIX](https://www.debian.org/distrib/) [compatible](https://www.apple.com/ca/macos/) [environment](https://docs.microsoft.com/en-us/windows/wsl/install)
    (ie: Debian Linux, macOS, WSL2, etc.)
- [Node.js 16.14.0 and npm 8.3.1](https://nodejs.org/en/download/)
- [unzip 6.00](https://packages.debian.org/bullseye/unzip)
- [git 2.30.2](https://git-scm.com/downloads)

If other software versions are used, please test extensively first.


# Getting Started

1) [Create your Github Repo](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) from this Template.

2) Clone your newly created Repo.
```Shell
git clone https://github.com/benjamin-ngo/salesforce-easy-checks.git
```
The URL above will differ based on the URL of your Repo.

3) Open a terminal. Navigate to your cloned Repo. 

4) Set up PMD, ESLint, and the related dependencies.
```JavaScript
npm install
```

5) Develop your Salesforce application. Commit and push the changes.
```Shell
git add --all
git commit
git push
```

6) Check your code quality.

    - Lint new code with
    ```Shell
    ./scripts/lint.sh diff:all
    ```

    - Lint your entire repo with
    ```Shell
    ./scripts/lint.sh repo:all
    ``` 

    The scripts will handle git commands, linters, and any unexpected errors!

7) When ready, submit your Pull Request!
   A Github Action will lint your Pull Request. The results will be published to increase confidence in the Pull Request.

8) If needed, refactor your Pull Request.
   Each new update will re-run the Github Action and linters.

9) (Optional) Customize or expand the scripts to meet your needs.
   Scripts have extensive error handling and are built with modular design.

   Run the included Unit Tests and Integration Tests to ensure everything works.
   ```shell
   ./scripts/testpipeline.sh
   ```


# Licensing

Placeholder text.

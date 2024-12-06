#!/bin/bash

# Repository management constants
REPO_CONFIG_DIR="${CONFIG_DIR}/repository"
TEMPLATE_DIR="${REPO_CONFIG_DIR}/templates"
WORKFLOW_DIR="${REPO_CONFIG_DIR}/workflows"

init_repo_manager() {
    # Create necessary directories
    mkdir -p "${TEMPLATE_DIR}/issues"
    mkdir -p "${TEMPLATE_DIR}/pull_request"
    mkdir -p "${WORKFLOW_DIR}"
    
    # Initialize default configurations if they don't exist
    init_default_templates
    init_default_workflows
    init_default_configs
}

init_default_templates() {
    # Issue templates
    cat > "${TEMPLATE_DIR}/issues/bug_report.md" << 'EOL'
---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug, needs-triage
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment:**
 - OS: [e.g. Ubuntu 20.04]
 - Version: [e.g. 1.0.0]
 - Additional context:
EOL

    # PR template
    cat > "${TEMPLATE_DIR}/pull_request/default.md" << 'EOL'
---
name: Pull Request
about: Create a pull request to contribute
title: ''
labels: needs-review
assignees: ''
---

**Related Issue**
Fixes #(issue)

**Changes Made**
- [ ] Feature implementation
- [ ] Bug fix
- [ ] Documentation update
- [ ] Tests added/updated

**Testing**
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

**Documentation**
- [ ] Documentation updated
- [ ] Comments added/updated
- [ ] API documentation updated (if applicable)

**Additional Notes**
Any additional information that reviewers should know.
EOL
}

init_default_workflows() {
    # CI workflow
    cat > "${WORKFLOW_DIR}/ci.yml" << 'EOL'
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Run tests
      run: |
        ./tests/run_all_tests.sh
    - name: Upload coverage
      uses: codecov/codecov-action@v1

  lint:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Run linting
      run: |
        shellcheck **/*.sh
EOL

    # Security workflow
    cat > "${WORKFLOW_DIR}/security.yml" << 'EOL'
name: Security Scan

on:
  push:
    branches: [ main ]
  schedule:
    - cron: '0 0 * * *'

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Run security scan
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        ignore-unfixed: true
        format: 'table'
        exit-code: '1'
        severity: 'CRITICAL,HIGH'
EOL

    # Automated release workflow
    cat > "${WORKFLOW_DIR}/release.yml" << 'EOL'
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Generate changelog
      id: changelog
      uses: metcalfc/changelog-generator@v0.4.4
    - name: Create release
      uses: softprops/action-gh-release@v1
      with:
        body: ${{ steps.changelog.outputs.changelog }}
        files: |
          LICENSE
          *.md
EOL

    # Dependency update workflow
    cat > "${WORKFLOW_DIR}/dependencies.yml" << 'EOL'
name: Update Dependencies

on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly
  workflow_dispatch:

jobs:
  update-deps:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Check for updates
      id: vars
      run: |
        if command -v apt-get >/dev/null 2>&1; then
          sudo apt-get update
          sudo apt-get upgrade -y
        fi
    - name: Create Pull Request
      uses: peter-evans/create-pull-request@v3
      with:
        title: 'chore: update dependencies'
        body: 'Automated dependency updates'
        branch: 'deps/update'
        labels: dependencies
EOL

    # Documentation workflow
    cat > "${WORKFLOW_DIR}/docs.yml" << 'EOL'
name: Documentation

on:
  push:
    branches: [ main ]
    paths:
      - 'docs/**'
      - '**.md'

jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Setup mdBook
      uses: peaceiris/actions-mdbook@v1
    - name: Build documentation
      run: mdbook build
    - name: Deploy to GitHub Pages
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./book
EOL

    # Performance monitoring workflow
    cat > "${WORKFLOW_DIR}/performance.yml" << 'EOL'
name: Performance Monitoring

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  benchmark:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Run benchmarks
      run: |
        ./tests/performance/run_benchmarks.sh
    - name: Store benchmark result
      uses: benchmark-action/github-action-benchmark@v1
      with:
        tool: 'customBenchmark'
        output-file-path: ./benchmark_results.json
        github-token: ${{ secrets.GITHUB_TOKEN }}
        auto-push: true
        alert-threshold: '200%'
        comment-on-alert: true
EOL

    # Stale issue management
    cat > "${WORKFLOW_DIR}/stale.yml" << 'EOL'
name: Stale Issue Management

on:
  schedule:
    - cron: '0 0 * * *'

jobs:
  stale:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/stale@v3
      with:
        repo-token: ${{ secrets.GITHUB_TOKEN }}
        stale-issue-message: 'This issue has been automatically marked as stale due to inactivity.'
        stale-pr-message: 'This PR has been automatically marked as stale due to inactivity.'
        stale-issue-label: 'stale'
        stale-pr-label: 'stale'
        days-before-stale: 60
        days-before-close: 7
EOL
}

init_default_configs() {
    # EditorConfig
    cat > "${REPO_CONFIG_DIR}/.editorconfig" << 'EOL'
root = true

[*]
end_of_line = lf
insert_final_newline = true
charset = utf-8
trim_trailing_whitespace = true

[*.{sh,bash}]
indent_style = space
indent_size = 4

[*.{yml,yaml}]
indent_style = space
indent_size = 2
EOL

    # Git attributes
    cat > "${REPO_CONFIG_DIR}/.gitattributes" << 'EOL'
* text=auto eol=lf
*.sh text eol=lf
*.md text eol=lf
*.yml text eol=lf
*.yaml text eol=lf
EOL

    # CODEOWNERS
    cat > "${REPO_CONFIG_DIR}/CODEOWNERS" << 'EOL'
# Default owners for everything in the repo.
* @project-maintainers

# DevOps and CI configuration
.github/** @devops-team
*.yml @devops-team

# Documentation
docs/** @docs-team
*.md @docs-team

# Core components
src/** @core-team
tests/** @core-team @qa-team
EOL

    # Auto-labeler configuration
    cat > "${REPO_CONFIG_DIR}/labeler.yml" << 'EOL'
# Add 'documentation' label to any changes in docs
documentation:
  - docs/**/*
  - '**/*.md'

# Add 'test' label to any change to test files
test:
  - tests/**/*

# Add size labels to PRs based on line changes
size/XS:
  - '(length < 10)'
size/S:
  - '(10 <= length < 50)'
size/M:
  - '(50 <= length < 200)'
size/L:
  - '(200 <= length < 500)'
size/XL:
  - '(length >= 500)'

# Add 'breaking' label when certain files change
breaking:
  - 'BREAKING_CHANGES.md'
  - 'src/core/**/*'
EOL

    # Branch protection settings
    cat > "${REPO_CONFIG_DIR}/branch-protection.json" << 'EOL'
{
  "protection": {
    "required_status_checks": {
      "strict": true,
      "contexts": [
        "continuous-integration/travis-ci",
        "security-scan"
      ]
    },
    "enforce_admins": true,
    "required_pull_request_reviews": {
      "dismissal_restrictions": {
        "users": [],
        "teams": ["maintainers"]
      },
      "dismiss_stale_reviews": true,
      "require_code_owner_reviews": true,
      "required_approving_review_count": 2
    },
    "restrictions": null
  }
}
EOL

    # Commit message template
    cat > "${REPO_CONFIG_DIR}/commit-template" << 'EOL'
# <type>(<scope>): <subject>
# |<----  Using a Maximum Of 50 Characters  ---->|

# Explain why this change is being made
# |<----   Try To Limit Each Line to a Maximum Of 72 Characters   ---->|

# Provide links or keys to any relevant tickets, articles or other resources
# Example: Fixes #23

# --- COMMIT END ---
# Type can be
#    feat     (new feature)
#    fix      (bug fix)
#    refactor (refactoring production code)
#    style    (formatting, missing semi colons, etc; no code change)
#    docs     (changes to documentation)
#    test     (adding or refactoring tests; no production code change)
#    chore    (updating grunt tasks etc; no production code change)
# --------------------
# Remember to
#    Capitalize the subject line
#    Use the imperative mood in the subject line
#    Do not end the subject line with a period
#    Separate subject from body with a blank line
#    Use the body to explain what and why vs. how
#    Can use multiple lines with "-" for bullet points in body
# --------------------
EOL
}

show_repo_management_menu() {
    while true; do
        clear
        echo -e "\033[36m=== Repository Management ===\033[0m"
        echo
        echo "1) Configure Templates"
        echo "2) Manage Workflows"
        echo "3) Repository Settings"
        echo "4) Development Environment"
        echo "5) Apply All Configurations"
        echo "b) Back"
        echo
        read -n 1 -p "Select option: " choice
        echo
        
        case $choice in
            1) show_template_menu ;;
            2) show_workflow_menu ;;
            3) show_repo_settings_menu ;;
            4) show_dev_env_menu ;;
            5) apply_all_configs ;;
            b|B) return 0 ;;
            *) continue ;;
        esac
    done
}

apply_all_configs() {
    clear
    echo "Applying repository configurations..."
    
    # Create .github directory structure
    mkdir -p .github/{workflows,ISSUE_TEMPLATE,PULL_REQUEST_TEMPLATE}
    
    # Copy templates
    cp "${TEMPLATE_DIR}/issues/"* .github/ISSUE_TEMPLATE/
    cp "${TEMPLATE_DIR}/pull_request/"* .github/PULL_REQUEST_TEMPLATE/
    
    # Copy workflows
    cp "${WORKFLOW_DIR}/"* .github/workflows/
    
    # Copy configs
    cp "${REPO_CONFIG_DIR}/.editorconfig" .
    cp "${REPO_CONFIG_DIR}/.gitattributes" .
    cp "${REPO_CONFIG_DIR}/CODEOWNERS" .github/
    cp "${REPO_CONFIG_DIR}/labeler.yml" .github/
    cp "${REPO_CONFIG_DIR}/commit-template" .git/commit-template
    
    # Configure git to use commit template
    git config --local commit.template .git/commit-template
    
    # Apply branch protection (requires GitHub API token)
    if [[ -n "${GITHUB_TOKEN}" ]]; then
        echo "Applying branch protection rules..."
        # Add GitHub API call here to apply branch protection
    fi
    
    echo "Configuration applied successfully!"
    echo "Press any key to continue..."
    read -n 1
}

# Add to main menu
add_repo_management_menu() {
    add_menu_item "main" "repo" "7) Repository Management" "show_repo_management_menu"
} 
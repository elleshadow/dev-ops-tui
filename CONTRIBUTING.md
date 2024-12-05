# Contributing to Dev-Ops TUI Library

We love your input! We want to make contributing to Dev-Ops TUI Library as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## We Develop with GitHub

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

## Development Process

We use GitHub Flow, so all code changes happen through pull requests:

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. If you've changed APIs, update the documentation
4. Ensure the test suite passes
5. Make sure your code follows the existing style
6. Issue that pull request!

## Code Style

- Use 4 spaces for indentation
- Follow shellcheck recommendations
- Add comments for complex logic
- Keep functions focused and small
- Use meaningful variable names
- Add error handling for robustness

## Testing

### Running Tests

```bash
# Run all tests
./tests/run_tests.sh

# Run specific test suite
./tests/tui/components/core/base_test.sh
```

### Writing Tests

1. Create test files in the appropriate directory under `tests/`
2. Use the provided test framework
3. Include both positive and negative test cases
4. Test edge cases and error conditions
5. Keep tests focused and descriptive

Example test:
```bash
it "should handle special input correctly"
test_special_input() {
    local result
    result=$(handle_special_input "test input")
    assert_equals "$result" "expected output"
}
```

## Documentation

- Update README.md with any new features
- Document all public functions
- Include usage examples
- Update configuration documentation
- Add inline comments for complex logic

## Issue Reporting

### Bug Reports

When reporting bugs, please include:

1. Your operating system and version
2. Bash version (`bash --version`)
3. Steps to reproduce the issue
4. Expected behavior
5. Actual behavior
6. Any relevant logs or error messages

### Feature Requests

We welcome feature requests! Please include:

1. Clear description of the feature
2. Use cases and benefits
3. Potential implementation approach
4. Any relevant examples

## Pull Request Process

1. Update the README.md with details of changes if applicable
2. Update the CHANGELOG.md with a note describing your changes
3. The PR will be merged once you have the sign-off of at least one maintainer

## Community

- Be welcoming and inclusive
- Respect different viewpoints and experiences
- Accept constructive criticism
- Focus on what's best for the community
- Show empathy towards other community members

## License

By contributing, you agree that your contributions will be licensed under the MIT License. 
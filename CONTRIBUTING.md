# Contributing to Passport

Thank you for your interest in contributing to Passport! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and collaborative environment. Please be considerate and constructive in your communications.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- A clear and descriptive title
- Detailed steps to reproduce the issue
- Expected behavior vs actual behavior
- Code samples demonstrating the issue
- Your environment (Swift version, macOS version, etc.)
- Any error messages or stack traces

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:

- A clear and descriptive title
- Detailed description of the proposed feature
- Use cases and examples
- Why this enhancement would be useful
- Any potential implementation approaches

### Pull Requests

1. **Fork the repository** and create your branch from `master`
2. **Make your changes** following the coding standards below
3. **Add tests** for any new functionality
4. **Ensure all tests pass** by running `swift test`
5. **Update documentation** as needed
6. **Write clear commit messages** following our commit message guidelines
7. **Submit your pull request**

## Development Setup

### Prerequisites

- Swift 6.2 or later
- macOS 14 or later
- Xcode 15 or later (recommended)

### Building the Project

```bash
# Clone your fork
git clone https://github.com/yourusername/passport.git
cd passport

# Build the project
swift build

# Run tests
swift test

# Run the demo
swift run PassportDemo
```

### Project Structure

```
Passport/
├── Sources/
│   ├── Passport/              # Main library code
│   │   ├── Builders/          # Code and SQL builders
│   │   │   ├── Code/          # Language-specific code generators
│   │   │   └── SQL/           # SQL dialect implementations
│   │   ├── Definitions/       # Core type definitions
│   │   └── Passport.docc/     # Documentation catalog
│   ├── PassportMacros/        # Swift macro implementations
│   ├── PassportDemo/          # Example usage
│   └── PassportTests/         # Test suite
└── Package.swift
```

## Coding Standards

### Swift Style Guidelines

- Follow standard Swift naming conventions
- Use meaningful variable and function names
- Prefer `let` over `var` when possible
- Use type inference where it improves readability
- Keep functions focused and concise

### Documentation

- Add documentation comments to all public APIs
- Use Swift's documentation markup (`///`)
- Include examples in documentation where helpful
- Document parameters, return values, and thrown errors

Example:

```swift
/// Builds a SELECT query with type-safe arguments.
///
/// - Parameters:
///   - argType: The type of arguments this query accepts
///   - builder: A closure that configures the query
/// - Returns: A configured Query instance
public static func select<Args: QueryArguments>(
    with argType: Args.Type,
    @QueryBuilder builder: (SelectQueryBuilder) -> Void
) -> Query {
    // Implementation
}
```

### Testing

- Write tests for all new functionality
- Ensure tests are clear and well-named
- Test both success and failure cases
- Aim for high code coverage
- Use descriptive test names that explain what is being tested

Example:

```swift
func testSelectQueryWithSingleFilter() throws {
    // Test implementation
}

func testInsertQueryWithMultipleFields() throws {
    // Test implementation
}
```

### Commit Messages

Follow these guidelines for commit messages:

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters
- Reference issues and pull requests after the first line

Example:

```
Add support for MySQL dialect

- Implement MySQL type conversions
- Add MySQL-specific query syntax
- Include tests for MySQL dialect

Closes #123
```

## Adding New Features

### Adding a New Language

To add support for a new programming language:

1. Create a new file in `Sources/Passport/Builders/Code/`
2. Conform to the `Language` protocol
3. Implement all required methods:
   - `comment(for:)` - Generate comments
   - `convert(type:inFile:)` - Convert DataType to language-specific type
   - `buildModel(_:inFile:)` - Generate model/struct code
   - `buildRecord(_:inFile:)` - Generate record code
   - `buildEnum(_:inFile:)` - Generate enum code
4. Add comprehensive tests
5. Update documentation

### Adding a New SQL Dialect

To add support for a new database system:

1. Create a new file in `Sources/Passport/Builders/SQL/`
2. Conform to the `Dialect` protocol
3. Implement type conversions and SQL generation
4. Add comprehensive tests
5. Update documentation

### Adding Query Features

When adding new query capabilities:

1. Update the query builder interfaces
2. Ensure SQL generation works for all dialects
3. Update code generators to support the new feature
4. Add tests for all languages and dialects
5. Update documentation and examples

## Testing

### Running Tests

```bash
# Run all tests
swift test

# Run tests in verbose mode
swift test --verbose

# Run specific test
swift test --filter PassportTests.testSelectQuery
```

### Writing Tests

- Place tests in `Sources/PassportTests/`
- Use XCTest framework
- Test edge cases and error conditions
- Verify generated code correctness

## Documentation

### Building Documentation

```bash
# Generate DocC documentation
swift package generate-documentation

# Preview documentation
swift package --disable-sandbox preview-documentation
```

### Updating Documentation

When making changes:

- Update relevant README sections
- Update DocC documentation in `.docc` files
- Add inline code documentation
- Update examples if APIs change

## Release Process

(For maintainers)

1. Update version in relevant files
2. Update CHANGELOG.md
3. Create a git tag
4. Push tag to trigger release
5. Update release notes on GitHub

## Questions?

If you have questions about contributing:

- Open an issue for discussion
- Check existing issues and pull requests
- Review the documentation

## License

By contributing to Passport, you agree that your contributions will be licensed under the same license as the project (MIT License).

---

Thank you for contributing to Passport!

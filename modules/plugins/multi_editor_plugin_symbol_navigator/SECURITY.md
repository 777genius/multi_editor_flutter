# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: **security@example.com** (replace with actual email)

You should receive a response within 48 hours. If for some reason you do not, please follow up via email to ensure we received your original message.

Please include the following information (as much as you can provide) to help us better understand the nature and scope of the issue:

* Type of issue (e.g. buffer overflow, SQL injection, cross-site scripting, etc.)
* Full paths of source file(s) related to the issue
* The location of the affected source code (tag/branch/commit or direct URL)
* Any special configuration required to reproduce the issue
* Step-by-step instructions to reproduce the issue
* Proof-of-concept or exploit code (if possible)
* Impact of the issue, including how an attacker might exploit it

## Security Considerations

### WASM Sandbox

The Symbol Navigator Plugin uses WebAssembly for code parsing. WASM runs in a sandboxed environment with the following security measures:

1. **Memory Isolation**: WASM has its own linear memory, isolated from host memory
2. **No Direct System Access**: Cannot access file system, network, or system resources
3. **Controlled Imports**: Only explicitly allowed functions can be called
4. **Type Safety**: All operations are type-checked at compile time

### Input Validation

All input to the parser is validated:

- **File size limits**: Maximum 100MB per file
- **Content validation**: UTF-8 encoding required
- **Language detection**: Only supported languages accepted
- **Memory limits**: Bounded allocations in WASM

### Data Handling

- **No data persistence**: Parsed symbols stored in memory only
- **No network communication**: All processing is local
- **No credential handling**: Plugin doesn't access sensitive data
- **Read-only access**: Only reads file content, no writes

### Known Security Boundaries

1. **Regular Expression DoS**: Current regex-based parser may be vulnerable to ReDoS attacks with specially crafted input. Mitigation: Implement timeout (500ms debounce), switch to tree-sitter.

2. **Memory Exhaustion**: Extremely large files could exhaust WASM memory. Mitigation: 100MB file size limit, memory bounds checking.

3. **Malformed Code**: Parser handles syntax errors gracefully without crashes. All errors are caught and logged.

### Best Practices for Users

1. **Keep Updated**: Always use the latest version with security patches
2. **Validate Input**: Don't parse untrusted code without review
3. **Monitor Resources**: Watch memory usage for large codebases
4. **Report Issues**: Report any security concerns immediately

### Security Updates

We will:
- Release security patches as soon as possible
- Document vulnerabilities in CHANGELOG.md
- Notify users through GitHub Security Advisories
- Credit reporters (unless they prefer to remain anonymous)

## Vulnerability Disclosure Timeline

1. **Day 0**: Security issue reported
2. **Day 1-2**: Acknowledge receipt and begin investigation
3. **Day 3-7**: Develop and test fix
4. **Day 7-14**: Release patch and security advisory
5. **Day 14+**: Public disclosure (if appropriate)

## Security Hall of Fame

We recognize and thank security researchers who responsibly disclose vulnerabilities:

- (No reports yet - be the first!)

## Contact

For security concerns: security@example.com
For general issues: GitHub Issues
For urgent matters: maintainer email

Thank you for helping keep Symbol Navigator Plugin and its users safe!

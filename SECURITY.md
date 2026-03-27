# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 1.2.x   | :white_check_mark: |
| 1.1.x   | :x:                |
| 1.0.x   | :x:                |

Only the latest release receives security updates.

## Reporting a Vulnerability

If you discover a security vulnerability in AgriPulse, please report it responsibly:

1. **Do NOT open a public GitHub issue** for security vulnerabilities.
2. **Email**: Send details to pradeeppeddineni1@gmail.com with the subject line `[SECURITY] AgriPulse Vulnerability Report`.
3. **Include**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

You can expect an initial response within 48 hours. We will work with you to understand and address the issue before any public disclosure.

## Security Measures

### Application Security
- **No user accounts or authentication** — no credentials to leak
- **No analytics or tracking SDKs** — no data collection
- **All data stored locally** on device using SwiftData — nothing transmitted to our servers
- **HTTPS only** — all API calls use TLS (Google News RSS, PIB.gov.in)
- **No user-generated content** — app only reads from public RSS feeds
- **App Transport Security (ATS)** enforced — iOS blocks insecure HTTP by default

### CI/CD Security
- **SAST scanning** on every build — checks for hardcoded secrets, embedded credentials, insecure URLs
- **Swift compiler warnings-as-errors** — catches potential issues at build time
- **Unit tests** run on every build
- **Code signing** handled by Codemagic with encrypted credentials — no secrets in source code
- **API keys** stored as environment variables, never in source
- **`.p8` private key** gitignored — never committed to repository

### Supply Chain
- **Minimal dependencies** — only FeedKit (RSS parsing) and SwiftSoup (HTML parsing)
- **Swift Package Manager** with version pinning
- **No third-party analytics, crash reporting, or ad SDKs**

## Scope

This policy covers the AgriPulse iOS application and its source code. It does not cover:
- Third-party services (Google News, PIB.gov.in, App Store Connect)
- The Codemagic CI/CD platform
- Apple's TestFlight or App Store infrastructure

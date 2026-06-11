# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in [Project Name], please report it responsibly:

**Do NOT create a public GitHub issue.**

Instead:

1. Email: [Your security contact email]
2. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if available)

We will respond within 48 hours and work with you to address the issue.

## Security Best Practices

- Never commit `.env` files or secrets
- Use environment variables for all sensitive data
- Keep dependencies updated (`pnpm update`)
- Review security advisories: `pnpm audit`

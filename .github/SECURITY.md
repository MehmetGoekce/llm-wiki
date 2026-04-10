# Security Policy

## Reporting a Vulnerability

If you discover a security issue in llm-wiki, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, email: **mehmetgoekce@memotech.ch**

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact

You will receive a response within 72 hours.

## Scope

Security issues in llm-wiki typically involve:

- **Credential leaks:** Wiki pages accidentally containing API tokens, passwords,
  or secrets (the wiki is git-tracked and credentials must stay in L1 memory)
- **Setup script:** Path injection or file overwrite vulnerabilities in `setup.sh`
- **Template injection:** Malicious content in wiki pages affecting template rendering

## Design Principles

llm-wiki is designed with security boundaries:

- **L1 (memory) is git-excluded** — credentials stay here
- **L2 (wiki) is git-tracked** — no secrets allowed
- **Lint rule 6** scans for credential patterns automatically
- **Append-only semantics** prevent accidental data loss

# L1 Memory Rule Examples

These are examples of rules that belong in **L1 (Claude Memory)** -- the auto-loaded
context that Claude reads at the start of every session. L1 rules are quick, actionable,
and universally relevant. Deep knowledge lives in L2 (the wiki).

---

## 1. Formatting Rule

**File:** `memory/feedback_file_naming.md`

```markdown
# File Naming Convention

- Always use snake_case for file names: `user_profile.ts`, not `userProfile.ts`
- Directories use kebab-case: `api-routes/`, not `apiRoutes/`
- Test files: `<module_name>.test.ts` (colocated with source)
- This applies to all new files. Existing files are renamed only during refactors.
```

---

## 2. Deployment Gotcha

**File:** `memory/feedback_deploy_migrations.md`

```markdown
# Database Migrations Before Deploy

- ALWAYS run `npm run db:migrate` before deploying to staging or production
- The deploy script does NOT run migrations automatically
- Forgetting this causes 500 errors on any endpoint that touches new columns
- Rollback command: `npm run db:rollback` (reverts last batch only)
```

---

## 3. API Constraint

**File:** `memory/feedback_staging_api_limits.md`

```markdown
# Staging API Rate Limits

- Staging API allows max 100 requests per minute per IP
- Exceeding this returns 429 Too Many Requests (no retry-after header)
- Batch operations: use the `/bulk` endpoint instead of looping single requests
- CI pipeline uses a dedicated IP -- rate limits apply there too
```

---

## 4. Identity Rule

**File:** `memory/user_brand.md`

```markdown
# Brand Identity

- Company name is always written as: ACME Corp (all-caps ACME, capitalized Corp)
- Never: Acme Corp, acme corp, AcmeCorp, ACME CORP
- Tagline: "Engineering Excellence Since 2012"
- Primary domain: acmecorp.dev (not .com)
```

---

## 5. Credential Note

**File:** `memory/reference_credentials.md`

```markdown
# Credential Management

- All API tokens and secrets are stored in 1Password (vault: "Engineering")
- NEVER commit credentials to git -- use .env files (already in .gitignore)
- Staging tokens rotate monthly on the 1st -- check 1Password if auth fails
- Production secrets are managed via environment variables on the hosting platform
```

---

## Why L1?

These rules are L1 because they apply **across sessions** and Claude needs them
**immediately** -- not after a wiki query. Compare with L2 content like "how does our
CI pipeline work end-to-end" which is detailed knowledge retrieved on demand.

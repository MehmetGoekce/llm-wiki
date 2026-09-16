# Spec: L1/L2 Routing — Knowledge Layer Decision Logic

## Description

When new knowledge is extracted (during ingest, query, or user interaction), the system
must decide whether it belongs in L1 (Claude Code memory, auto-loaded every session) or
L2 (wiki, queried on demand). This is the core architectural decision that makes the
dual-layer cache effective. Wrong routing degrades the system: too much in L1 = slow
session starts and context bloat; too little in L1 = repeated mistakes.

---

## Requirements

### The Routing Rule

- REQ-300: The system SHALL evaluate every extracted fact against the routing question:
  "If the LLM does not know this right now, what happens?"
- REQ-301: If the consequence is **data loss, security incident, or production
  failure**, the fact SHALL be routed to L1.
- REQ-302: If the consequence is **embarrassing output** (wrong name, wrong address,
  incorrect brand voice), the fact SHALL be routed to L1.
- REQ-303: If the consequence is **incorrect but easily correctable** (wrong count,
  outdated detail), the fact SHALL be routed to L2.
- REQ-304: If the consequence is **missing context requiring a follow-up question**,
  the fact SHALL be routed to L2.

### L1 Content Categories

- REQ-310: Operational rules and gotchas (things that prevent mistakes in the moment)
  SHALL be stored in L1.
- REQ-311: User identity and preferences (name spelling, address, communication style)
  SHALL be stored in L1.
- REQ-312: Credentials and secrets (API tokens, passwords, connection strings)
  MUST be stored in L1. They MUST NOT be stored in L2 under any circumstances.
- REQ-313: Tool-specific quirks that apply in every session (e.g., "PM2 reload does
  not work with npm start") SHALL be stored in L1.

### L2 Content Categories

- REQ-320: Project details and timelines SHALL be stored in L2.
- REQ-321: Workflow documentation SHALL be stored in L2.
- REQ-322: Research and learning notes SHALL be stored in L2.
- REQ-323: Business intelligence and strategy SHALL be stored in L2.
- REQ-324: Historical decisions and rationale SHALL be stored in L2.

### Security Boundary

- REQ-330: L1 memory directory MUST be git-excluded (typically at
  `~/.claude/projects/*/memory/` which is not in the repo).
- REQ-331: L2 wiki MUST be assumed git-tracked. All L2 content is potentially
  visible in version control history.
- REQ-332: The system SHALL treat the L1/L2 boundary as a hard security boundary
  for credentials. There is no "soft" credential storage in L2.

### L1 Size Management

- REQ-340: L1 SHOULD contain 10-20 files (optimal range).
- REQ-341: If L1 exceeds approximately 30 files, the system SHOULD recommend an
  audit to move contextual knowledge to L2.
- REQ-342: Each L1 file SHOULD cover one topic and be concise (a few lines, not
  pages of detail).

### Boundary Evolution

- REQ-350: Knowledge MAY be promoted from L2 to L1 when the same mistake is
  repeated across multiple sessions (pattern: operational gotcha discovered the
  hard way).
- REQ-351: Knowledge MAY be demoted from L1 to L2 when it becomes historical
  context rather than an active operational rule (pattern: project completes,
  credentials rotated).
- REQ-352: Multiple related L1 files SHOULD be merged when they cover the same
  system or topic, to keep L1 lean.
- REQ-353: (Superseded by REQ-370-379.) Access-based staleness does not apply to L1:
  every L1 file is auto-loaded every session, so "last referenced" carries no signal.
  L1 staleness is detected by claim class and verification date instead.
- REQ-354: The `/wiki lint` command SHOULD flag L2 pages queried in every session
  as candidates for L1 promotion.

### L1 Staleness (Claim Class + Verification Date)

A stale L1 rule does not look cold — it is loaded every session. It shows up as the
agent confidently acting on an outdated assumption. Staleness is therefore tied to
*what kind of claim* a rule makes, not to how often it is read.

- REQ-370: An L1 memory file MAY carry the frontmatter key `asserts-current-behavior`
  with value `true` or `false`.
- REQ-371: `asserts-current-behavior: true` marks a **falsifiable claim about the
  current state of a system** — a path, command, flag, version, port, API surface,
  tool quirk, or external behavior that can change without the rule changing
  (e.g. "PM2 reload does not work with npm start").
- REQ-372: `asserts-current-behavior: false` marks a **decision, preference, identity
  fact, or rationale** (e.g. "no AI attribution in commits", "name is spelled with
  a cedilla"). Such rules SHALL never be reported as stale.
- REQ-373: An L1 memory file with `asserts-current-behavior: true` MAY carry the
  frontmatter key `verified` with an ISO 8601 date (YYYY-MM-DD): the last date on
  which the claim was checked against evidence (see specs/prune.md REQ-910-915).
- REQ-374: A rule is **due for verification** when `asserts-current-behavior` is `true`
  AND (`verified` is absent OR `verified` is older than `l1_verify_days`, default 90,
  see specs/config.md REQ-660).
- REQ-375: An L1 memory file WITHOUT the `asserts-current-behavior` key is
  **unclassified**. Unclassified files SHALL NOT be reported as due; they SHALL only be
  counted (see specs/lint.md REQ-222) and offered for classification by
  `/wiki prune --l1`.
- REQ-376: The system SHALL read both keys either at the top level of the frontmatter
  or inside a `metadata:` block. When writing, it SHALL use the location the file
  already uses for its other metadata (a `metadata:` block if present, top level
  otherwise) and MUST NOT reorder or remove any other frontmatter keys.
- REQ-377: The L1 index file (e.g. `MEMORY.md`) SHALL be exempt from classification
  and verification; it is an index, not a rule.
- REQ-378: Detecting due rules is read-only and belongs to `/wiki lint` (Rule 12).
  Acting on them — classify, re-verify, demote to L2, delete — belongs to
  `/wiki prune --l1` and requires per-item user confirmation.
- REQ-379: Warning at the moment a due rule is about to justify an action
  (planning vs. action gate) is OUT OF SCOPE for this spec. L1 loading is performed
  by Claude Code, not by llm-wiki; the system cannot enforce a runtime gate and SHALL
  NOT claim to.

### Routing During Ingest

- REQ-360: During /wiki ingest Phase 1, the system SHALL apply the routing rule
  (REQ-300-304) to each extracted fact.
- REQ-361: Facts routed to L1 SHALL NOT be written to wiki pages. The system SHALL
  instead recommend saving them to the memory directory.
- REQ-362: Facts routed to L2 SHALL proceed through the normal ingest pipeline
  (Phases 2-5).
- REQ-363: If a source contains both L1 and L2 facts, the system SHALL process
  L2 facts via ingest AND separately recommend L1 facts for memory storage.
- REQ-364: The system SHOULD present the routing recommendation to the user before
  writing, especially for ambiguous cases (severity:: important facts that could
  go either way).

---

## Scenarios

### Scenario 1: Operational gotcha — routes to L1

```
GIVEN the user ingests "SSH max 3 calls to VPS, otherwise OOM reboot"
WHEN the system evaluates L1/L2 routing
THEN the consequence of not knowing is "production failure" (OOM reboot)
AND the system SHALL recommend: "This is an L1 candidate (operational gotcha).
    Save to memory, not wiki."
AND the system SHALL NOT create a wiki page for this fact
```

### Scenario 2: Project timeline — routes to L2

```
GIVEN the user ingests "Book chapter 1 deadline is April 20"
WHEN the system evaluates L1/L2 routing
THEN the consequence of not knowing is "missing context, ask follow-up"
AND the system SHALL route this to L2 (wiki)
AND proceed with normal ingest to create/update a project page
```

### Scenario 3: Credential in source — hard L1 boundary

```
GIVEN the user ingests text containing "Strapi API token: abc123xyz789..."
WHEN the system evaluates L1/L2 routing
THEN the system SHALL identify this as a credential (REQ-312)
AND the system MUST route to L1
AND the system MUST NOT write the token to any wiki page
AND the system SHALL recommend: "Credential detected. Save to L1 memory only.
    Wiki is git-tracked."
```

### Scenario 4: Mixed source — L1 and L2 facts

```
GIVEN the user ingests a deployment runbook containing:
    - "Always stop ClamAV before deploy" (operational gotcha)
    - "Deploy script is at scripts/deploy-vps.sh" (project context)
    - "VPS IP: 84.234.21.71" (infrastructure detail)
    - "API token: Bearer xyz..." (credential)
WHEN the system evaluates L1/L2 routing
THEN "Stop ClamAV before deploy" SHALL be recommended for L1 (prevents OOM)
AND "API token" MUST be recommended for L1 (credential, hard boundary)
AND "Deploy script path" SHALL be routed to L2 (project context)
AND "VPS IP" MAY go to either L1 or L2 (borderline: wrong IP = failed deploy,
    but easily correctable)
AND the system SHALL process L2 facts via ingest
AND separately list L1 recommendations for user action
```

### Scenario 5: User identity — routes to L1

```
GIVEN the user says "My name is spelled Goekce with a cedille: Goekce"
WHEN the system evaluates L1/L2 routing
THEN the consequence of not knowing is "embarrassing output" (misspelled name)
AND the system SHALL recommend L1 storage
AND the system SHALL NOT create a wiki page for name spelling
```

### Scenario 6: L1 bloat detected — audit recommended

```
GIVEN the L1 memory directory contains 35 files
WHEN the user runs /wiki lint or /wiki status
THEN the system SHALL warn: "L1 has 35 files (recommended: 10-20, audit at 30+).
    Review for candidates to demote to L2."
AND the system SHOULD point to `/wiki prune --l1` for classification and verification
```

### Scenario 7: L2 page frequently queried — promotion candidate

```
GIVEN the wiki page Wiki/Tech/Deployment is queried in 8 of the last 10 sessions
WHEN the user runs /wiki lint
THEN the system SHALL flag the page as an L1 promotion candidate (info)
AND suggest: "Wiki/Tech/Deployment is queried almost every session.
    Consider promoting key rules to L1 memory."
```

### Scenario 7b: Decision rule never goes stale

```
GIVEN L1 file feedback_no_ai_attribution.md has asserts-current-behavior: false
AND the file was last modified 400 days ago
WHEN the user runs /wiki lint
THEN the system SHALL NOT report the file as due for verification
```

### Scenario 7c: Behavior claim due for verification

```
GIVEN L1 file feedback_pm2_reload.md has asserts-current-behavior: true
AND verified: 2026-03-01
AND l1_verify_days is 90 and today is 2026-06-15 (106 days later)
WHEN the user runs /wiki lint
THEN the system SHALL report the file as "L1 verification due" (warning)
AND suggest: "Run /wiki prune --l1 to check this claim against evidence."
```

### Scenario 7d: Metadata block is respected

```
GIVEN an L1 file whose frontmatter contains `metadata:` with `type: feedback`
WHEN /wiki prune --l1 classifies it as asserts-current-behavior: true
THEN the key SHALL be written inside the `metadata:` block
AND name, description, and every other existing key SHALL remain unchanged and in order
```

### Scenario 8: Ambiguous routing — user decision needed

```
GIVEN the user ingests "Strapi port must be 1338 everywhere"
WHEN the system evaluates L1/L2 routing
THEN the consequence could be "failed deploy" (L1) or "easily fixable config" (L2)
AND the system SHALL present both options to the user:
    "L1 (auto-loaded): Prevents port mismatch every session.
     L2 (wiki): Documented but only loaded when querying Strapi."
AND the system SHALL wait for user confirmation before routing
```

---

## Acceptance Criteria

- [ ] Every extracted fact is evaluated against the routing rule before storage
- [ ] Credentials NEVER reach L2 wiki pages (hard security boundary)
- [ ] L1 candidates are recommended to the user, not silently written to wiki
- [ ] Mixed sources produce both L2 ingest AND L1 recommendations
- [ ] L1 size warnings trigger at ~30 files
- [ ] Ambiguous cases are presented to user for decision
- [ ] Works with both Logseq and Obsidian L2 backends
- [ ] Boundary evolution (promote/demote) is suggested during lint
- [ ] L1 staleness uses claim class + verification date, never access frequency
- [ ] Rules with asserts-current-behavior: false are never reported as stale
- [ ] Unclassified L1 files are counted, not flagged as due
- [ ] Frontmatter writes preserve all other keys and their order
- [ ] No runtime planning/action gate is claimed (REQ-379)

---

## Dependencies

- `llm-wiki.yml` must specify `memory_path` for L1 location
- specs/ingest.md Phase 1 calls this routing logic
- specs/lint.md Rules 6 (credential leak) and 9 (L1/L2 duplicates) enforce boundaries
- specs/lint.md Rule 12 detects due L1 rules; specs/prune.md `--l1` acts on them
- specs/config.md REQ-660 defines `l1_verify_days`

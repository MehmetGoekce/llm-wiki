# Spec: /wiki prune — LRU-Demote (Index Eviction)

## Description

The prune command keeps two-stage routing precise as the wiki grows by evicting cold
pages from the live hub index. A page is "cold" when it has not been read (logged in
the Access-Log) within a configurable window (default 6 months). Eviction is NOT
deletion and NOT a file move: the page keeps its filename and location, its incoming
`[[links]]` stay valid, and it remains greppable as an L3 fallback. Only its routing
line moves from the hub `### Index` to `### Archive`, and the page is marked
`archived::`. This is the access-frequency eviction layer of the L1/L2/L3 cache model —
the counterpart to query (read path) and ingest (write path).

prune is meant to run on a schedule (default cadence: 6 months). The command itself
does NOT self-schedule; the user wires it via their own scheduler.

`/wiki prune --l1` is a separate mode for L1 memory. Access frequency cannot find stale
L1 rules (every L1 file is loaded every session), so this mode works on claim class and
verification date (specs/l1-l2-routing.md REQ-370-379): it classifies unclassified
files, checks due behavior claims against read-only evidence, and lets the user
re-verify, demote to L2, or delete each one. `--l1` does NOT run the L2 index eviction,
and plain `/wiki prune` does NOT touch L1.

---

## Requirements

### Phase 1: Access Profile

- REQ-600: The system SHALL read `llm-wiki.yml` first to determine tool mode, wiki
  path, and memory path.
- REQ-601: The system SHALL read the Access-Log page (`Wiki/Reference/Access-Log`) and
  determine the last-access date per page from its newest log entry.
- REQ-602: For a page that has never been logged, the system SHALL use its `created::`
  date as the last-access proxy.
- REQ-603: The cold threshold SHALL be "no access in N months", where N defaults to 6
  and is overridable via `--months N`.
- REQ-604: The system SHALL EXEMPT from demotion: hub pages (type hub), the Schema page,
  the Dashboard page, the Access-Log page, and any page with `status:: active` that is
  a project (in-flight work is never evicted, even if unread).

### Phase 2: Demote Candidates

- REQ-610: The system SHALL list demote candidates (page — last-access date — age in
  months) and present them to the user BEFORE any write. Demotion is opt-in.
- REQ-611: For each confirmed candidate, the system SHALL add the property
  `archived:: <today>` — the canonical demoted marker, valid on any page type (see
  specs/schema.md REQ-565). It MUST NOT modify `created::` or `updated::`.
- REQ-612: For pages whose `status` enum includes `archived` (Entity), the system
  SHOULD also set `status:: archived`. For types whose enum does NOT (Project,
  Knowledge), the system MUST NOT set an out-of-enum `status` value.
- REQ-613: The system SHALL move the page's routing line from the hub `### Index` to
  the hub `### Archive` section VERBATIM (move, not delete).
- REQ-614: The system MUST NOT rename the page or move its file to another namespace.
  The tool links by page name; a move would break every incoming `[[link]]`.
- REQ-615: After demotion, all incoming `[[links]]` to the page SHALL remain valid and
  the page SHALL remain readable via the L3 grep fallback in query.

### Phase 3: Report + Commit

- REQ-620: The system SHALL report the demoted list, the new live-index size per
  namespace, and the hot pages (top access count) for contrast.
- REQ-621: The system SHALL create a git commit for the structural change (hub index
  edits + page property changes). This commit also carries any pending Access-Log
  appends (which are non-structural and not committed per-query).
- REQ-622: The system SHALL note when the next prune is due (N months out). It MUST NOT
  create a scheduler entry itself.

### L1 Mode (`--l1`)

#### Phase L1-1: Scope

- REQ-900: `/wiki prune --l1` SHALL require `memory_path`. If it is absent, the system
  SHALL display "memory_path not configured — L1 mode unavailable." and abort.
- REQ-901: The system SHALL skip the L1 index file (specs/l1-l2-routing.md REQ-377).
- REQ-902: The batch size SHALL default to 10 and be overridable via `--batch N`. The
  verification window SHALL default to `l1_verify_days` and be overridable via
  `--days N`.
- REQ-903: Every write in L1 mode SHALL require confirmation. L1 is not git-tracked:
  there is no undo. Before any delete or demote, the system SHALL show the full file
  content it is about to remove.

#### Phase L1-2: Classify

- REQ-905: For up to one batch of unclassified files, the system SHALL propose a value
  for `asserts-current-behavior` (true/false) with a one-line reason per file, applying
  the definitions in specs/l1-l2-routing.md REQ-371-372.
- REQ-906: The user SHALL be able to confirm the whole batch or override individual
  proposals. Only confirmed values SHALL be written (specs/l1-l2-routing.md REQ-376 placement rules apply).
- REQ-907: Classification MUST NOT set `verified`. A newly classified behavior claim
  is due until evidence has been checked.
- REQ-908: A file whose content is mixed (a decision plus a behavior claim) SHOULD be
  classified `true` and the proposal SHOULD suggest splitting it into two files.

#### Phase L1-3: Gather Evidence

- REQ-910: For each due rule (up to one batch, oldest `verified` first, never-verified
  before dated), the system SHALL extract the concrete, checkable elements the rule
  names: file paths, commands, flags, versions, ports, config keys, URLs.
- REQ-911: Evidence gathering MUST be read-only: checking file existence, reading
  files, searching file contents, reading dependency manifests, and running commands
  only with read-only informational flags (`--version`, `--help`). The system MUST NOT
  run commands with side effects, write to disk, deploy, or change remote state.
- REQ-912: The system SHALL report one verdict per rule — `supports`, `contradicts`, or
  `inconclusive` — with the evidence behind it (what was checked, what was found).
- REQ-913: A rule whose elements cannot be checked locally (external service behavior,
  pricing, third-party policy) SHALL be reported `inconclusive` with the reason
  "not locally verifiable". The system MUST NOT fetch remote content to decide.
- REQ-914: Evidence output MUST NOT include credential values. For a rule that holds
  a credential, the system SHALL report only whether the referenced location exists.
- REQ-915: The system MUST NOT decide on its own. A verdict is input for the user,
  not an action.

#### Phase L1-4: Act (per rule, user choice)

- REQ-920: The system SHALL offer three actions per due rule: **re-verify**, **demote
  to L2**, **delete**. It SHALL recommend one based on the verdict: `supports` →
  re-verify; `contradicts` → demote (history still useful) or delete; `inconclusive`
  → re-verify only if the user confirms the claim from their own knowledge.
- REQ-921: **Re-verify** SHALL set `verified: <today>`. If the verdict is
  `contradicts`, re-verify SHALL only be offered together with a proposed corrected
  rule text, and both SHALL be written together on confirmation.
- REQ-922: **Demote to L2** SHALL route the rule's content through the normal ingest
  path (specs/ingest.md): append it as a history block to the most relevant wiki page
  found via hub-index routing, or create a page if none fits. The block SHALL carry
  `source:: l1-demotion` and the date. Only after the wiki write succeeds SHALL the
  system delete the L1 file and remove its line from the L1 index file.
- REQ-923: A rule containing a credential MUST NOT be demoted to L2
  (specs/l1-l2-routing.md REQ-312). Only re-verify and delete SHALL be offered.
- REQ-924: **Delete** SHALL remove the L1 file and its line from the L1 index file.
- REQ-925: Choosing none of the three (skip) SHALL leave the file untouched; it stays
  due and reappears in the next run.

#### Phase L1-5: Report + Commit

- REQ-928: The system SHALL report counts: classified (true/false), re-verified,
  demoted, deleted, skipped, and remaining unclassified and due files.
- REQ-929: The system SHALL create a git commit for wiki pages changed by demotion
  (plus pending Access-Log appends). L1 changes are not committed (L1 is git-excluded,
  specs/l1-l2-routing.md REQ-330).

---

## Scenarios

### Scenario 1: Cold page demoted

```
GIVEN Wiki/Tech/Legacy-Foo was last logged in the Access-Log on 2025-09-01
AND today is 2026-06-07 (≈ 9 months, exceeds the 6-month threshold)
AND it is a knowledge page (not a hub, not active project, not Schema/Dashboard/Access-Log)
WHEN the user runs /wiki prune
THEN the system SHALL list Wiki/Tech/Legacy-Foo as a demote candidate (last access 2025-09-01, 9 mo)
AND on confirmation SHALL add archived:: 2026-06-07 to the page (created::/updated:: unchanged)
AND move its routing line from the Wiki/Tech hub `### Index` to `### Archive`
AND NOT rename or move the page file
AND commit the change
```

### Scenario 2: Never-accessed page uses created date

```
GIVEN Wiki/Learning/Old-Course has no Access-Log entries
AND its created:: date is 2025-08-01 (older than 6 months)
WHEN the user runs /wiki prune
THEN the system SHALL treat 2025-08-01 as its last-access proxy
AND list it as a demote candidate
```

### Scenario 3: Active project exempt

```
GIVEN Wiki/Projects/Big-Migration has status:: active
AND it has not been read in 8 months
WHEN the user runs /wiki prune
THEN the system SHALL NOT list it as a demote candidate (active projects are exempt)
```

### Scenario 4: Custom window

```
GIVEN several pages last accessed between 3 and 5 months ago
WHEN the user runs /wiki prune --months 3
THEN the system SHALL list every page with no access in the last 3 months as a candidate
```

### Scenario 5: Re-promotion is handled by query, not prune

```
GIVEN Wiki/Tech/Legacy-Foo is demoted (archived::, routing line in `### Archive`)
WHEN a later /wiki query L3 grep matches it and reads it in full
THEN re-promotion is offered by the query command (specs/query.md REQ-452), NOT prune
AND prune SHALL never auto-promote pages
```

### Scenario 6: Demotion preserves incoming links

```
GIVEN Wiki/Projects/Acme links to [[Wiki/Tech/Legacy-Foo]]
WHEN Wiki/Tech/Legacy-Foo is demoted by /wiki prune
THEN the [[Wiki/Tech/Legacy-Foo]] link in Wiki/Projects/Acme SHALL still resolve
AND lint SHALL NOT report it as a broken reference
```

### Scenario 7: Obsidian mode

```
GIVEN llm-wiki.yml is configured with tool: obsidian
AND Wiki/Tech/Legacy-Foo.md is a cold page
WHEN the user runs /wiki prune
THEN the system SHALL add archived: <today> to the YAML frontmatter
AND move the routing line within the Wiki/Tech hub (Wiki/Tech/_index.md) from
    `### Index` to `### Archive`
AND keep the file at Wiki/Tech/Legacy-Foo.md (no move)
```

### Scenario 8: L1 classification batch

```
GIVEN memory_path holds 25 unclassified L1 files
WHEN the user runs /wiki prune --l1
THEN the system SHALL propose asserts-current-behavior values for 10 files, each with a reason
    e.g. "feedback_pm2_reload.md → true (claims PM2 reload fails with npm start)"
         "feedback_no_ai_attribution.md → false (records a preference)"
AND on confirmation SHALL write only the key, without verified
AND report 15 files still unclassified
```

### Scenario 9: Evidence contradicts a rule

```
GIVEN feedback_hook_path.md (asserts-current-behavior: true, verified: 2026-02-01) says
    "the hook lives at ~/.claude/hooks/rtk-rewrite.sh"
AND that path does not exist, but settings.json references ~/Projekte/tools/rtk/hooks/rtk-rewrite.sh
WHEN the user runs /wiki prune --l1
THEN the system SHALL report verdict contradicts, with both paths as evidence
AND recommend demote or delete
AND offer re-verify only together with a corrected rule text naming the new path
AND write nothing until the user chooses
```

### Scenario 10: Not locally verifiable

```
GIVEN reference_hosting_prices.md (asserts-current-behavior: true, no verified) states a monthly price
WHEN the user runs /wiki prune --l1
THEN the system SHALL report verdict inconclusive — "not locally verifiable"
AND NOT fetch the provider website
```

### Scenario 11: Demote to L2

```
GIVEN feedback_old_deploy_flow.md is due and the verdict is contradicts
AND the user chooses demote
WHEN the system executes the action
THEN it SHALL show the full file content first
AND append a history block with source:: l1-demotion to the page routed via the hub index
    (e.g. Wiki/Tech/Deployment)
AND only then delete feedback_old_deploy_flow.md and its MEMORY.md line
AND commit the wiki change
```

### Scenario 12: Credential rule cannot be demoted

```
GIVEN reference_strapi_credentials.md is due
WHEN the user runs /wiki prune --l1
THEN the evidence SHALL show only whether the referenced location exists, never the value
AND the offered actions SHALL be re-verify and delete only
```

### Scenario 13: Modes are separate

```
GIVEN cold L2 pages and due L1 rules both exist
WHEN the user runs /wiki prune
THEN only L2 index eviction SHALL run
WHEN the user runs /wiki prune --l1
THEN only L1 classification and verification SHALL run
```

---

## Acceptance Criteria

- [ ] Last-access computed from the Access-Log; created:: used as proxy when never logged
- [ ] Default 6-month threshold, overridable via --months N
- [ ] Hubs, Schema, Dashboard, Access-Log, and active projects are exempt
- [ ] Candidates shown to the user before any write (opt-in)
- [ ] Demote adds archived:: (and status:: archived only where the enum allows)
- [ ] Routing line moved from `### Index` to `### Archive` (move, not delete)
- [ ] Page file never renamed or moved — incoming [[links]] stay valid
- [ ] Demoted page still greppable as L3 fallback
- [ ] Re-promotion is query's responsibility, not prune's
- [ ] Structural change committed; next-prune date reported (no self-scheduling)
- [ ] Works in both Logseq and Obsidian modes
- [ ] `--l1` requires memory_path and never runs L2 eviction; plain prune never touches L1
- [ ] Classification proposes, user confirms, verified is never set by classification
- [ ] Evidence gathering is strictly read-only and local; no remote fetches
- [ ] Every rule gets a verdict (supports / contradicts / inconclusive) with evidence
- [ ] Three actions per rule, nothing written without confirmation, full content shown before removal
- [ ] Demote writes to L2 first, deletes L1 only after the wiki write succeeds
- [ ] Credential rules: never demoted, values never printed

---

## Dependencies

- `llm-wiki.yml` must exist and be valid (see specs/config.md)
- specs/schema.md defines the `archived::` marker, the hub `### Index`/`### Archive`
  structure, and the Access-Log page
- specs/query.md writes the Access-Log this command consumes and owns re-promotion
- specs/lint.md rules 10-11 detect index drift and archived-in-live-index left by an
  interrupted prune
- specs/l1-l2-routing.md REQ-370-379 define claim class, verification date, and due rules
  for `--l1`; specs/lint.md Rule 12 reports them; specs/config.md REQ-660 sets the window
- specs/ingest.md is reused by the demote-to-L2 action

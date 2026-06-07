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

---

## Dependencies

- `llm-wiki.yml` must exist and be valid (see specs/config.md)
- specs/schema.md defines the `archived::` marker, the hub `### Index`/`### Archive`
  structure, and the Access-Log page
- specs/query.md writes the Access-Log this command consumes and owns re-promotion
- specs/lint.md rules 10-11 detect index drift and archived-in-live-index left by an
  interrupted prune

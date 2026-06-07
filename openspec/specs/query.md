# Spec: /wiki query — Knowledge Retrieval & Synthesis

## Description

The query command searches the wiki for information relevant to a user's question,
synthesizes an answer from multiple sources, and optionally creates new pages to fill
knowledge gaps. It is the primary read path — the counterpart to ingest (write path).

---

## Requirements

### Phase 0: Routing (Stage 1 — cheap index read)

- REQ-440: The system SHALL read `llm-wiki.yml` first to determine tool mode,
  wiki path, and memory path.
- REQ-441: The system SHALL parse the user's question to identify candidate
  namespaces and entity names.
- REQ-442: The system SHALL read ONLY the hub page of each candidate namespace —
  NOT every full page in that namespace — to obtain its `### Index` routing lines.
- REQ-443: The system SHALL match the routing lines (`[[link]] -- description #tags`)
  in the hub `### Index` against the question and select the 3 most relevant child
  pages (maximum 5). This two-stage routing is the default retrieval path.
- REQ-444: The system SHALL treat full-text grep over all wiki pages as an L3
  FALLBACK, used only when routing yields nothing usable (namespace unclear, hub
  index missing or empty, or no routing line matches) — NOT as the default path.

### Phase 1: Targeted Read (Stage 2 — only the chosen pages)

- REQ-400: The system SHALL read ONLY the pages selected in Phase 0 (or, on the L3
  fallback, the top 3-5 grep matches).
- REQ-404: The system SHALL load at most 3 pages simultaneously (JIT retrieval).
  If more than 3 are relevant, read in batches.
- REQ-405: The system SHOULD also read L1 Memory files when the question touches
  topics that may have operational rules or gotchas stored there.

### Phase 1b: Access Logging (LRU signal)

- REQ-450: For each page READ IN FULL (Phase 1, not the Phase 0 hub-index reads),
  the system SHALL append one line to the Access-Log page (`Wiki/Reference/Access-Log`):
  `<ISO-date> -- [[Wiki/NS/Page]] -- query`.
- REQ-451: The Access-Log append SHALL be non-structural — the system MUST NOT create
  a git commit per query. The append rides along with the next prune/lint/ingest commit.
- REQ-452: If the L3 fallback reads a page marked `archived::` (a re-hit on an evicted
  page), the system SHOULD offer to re-promote it: move its routing line from the hub
  `### Archive` back into `### Index` and remove the archived properties.

### Phase 2: Synthesize

- REQ-410: The system SHALL combine information from multiple wiki pages into
  a coherent answer, not just dump raw page content.
- REQ-411: The system SHALL check the `confidence::` property of each source page
  and weight high-confidence sources over low-confidence ones.
- REQ-412: The system SHALL check the `updated::` date of each source page and
  flag sources older than 90 days as potentially stale.
- REQ-413: The system SHALL note when sources contradict each other and present
  both perspectives rather than silently choosing one.
- REQ-414: The system MUST NOT fabricate information that is not present in the
  wiki or L1 memory. If the wiki does not contain an answer, say so.

### Phase 3: Optional Write-Back

- REQ-420: If the query reveals a knowledge gap (question has no answer in the
  wiki), the system SHOULD offer to create a new page.
- REQ-421: If the synthesis produces a useful summary that does not exist as a
  wiki page, the system SHOULD offer to save it as a new page.
- REQ-422: The system MUST NOT write any pages without explicit user confirmation.
  Write-back is always opt-in, never automatic.
- REQ-423: Write-back operations SHALL follow the same rules as ingest Phase 3
  (required properties, append-only, cross-references, hub updates).

### Phase 4: Output

- REQ-430: The system SHALL include source attribution in every answer, listing
  the wiki pages used: "Sources: [[Wiki/Tech/Strapi]], [[Wiki/Reference/Workflows]]"
- REQ-431: The system SHALL explicitly flag stale sources (updated:: > 90 days)
  with a warning: "Note: [[Wiki/Tech/X]] was last updated [date] and may be outdated."
- REQ-432: The system SHALL explicitly flag low-confidence sources with a warning:
  "Note: [[Wiki/Learning/Y]] has confidence:: low — verify before acting on this."
- REQ-433: The system SHOULD suggest related pages that the user might want to
  explore further, even if they were not directly used in the answer.
- REQ-434: If no relevant pages are found, the system SHALL clearly state:
  "No information found in the wiki for this topic." and offer to create a page
  via write-back (REQ-420).

---

## Scenarios

### Scenario 1: Simple question — single page match

```
GIVEN the wiki contains Wiki/Tech/Strapi with content about Strapi CMS
AND the page has confidence:: high and updated:: 2026-04-01
WHEN the user runs /wiki query "what port does Strapi use?"
THEN the system SHALL read Wiki/Tech/Strapi
AND synthesize an answer from that page's content
AND output: "Sources: [[Wiki/Tech/Strapi]]"
AND NOT flag the source as stale (updated 9 days ago)
```

### Scenario 2: Complex question — multi-page synthesis

```
GIVEN the wiki contains:
    - Wiki/Tech/Deployment (deploy process, VPS details)
    - Wiki/Tech/Strapi (CMS configuration, port settings)
    - Wiki/Reference/Workflows (deploy workflow steps)
WHEN the user runs /wiki query "how do I deploy a new blog post?"
THEN the system SHALL read all 3 pages (batching if needed)
AND combine deployment steps from Workflows with Strapi API details
AND present a coherent answer (not just 3 raw page dumps)
AND output: "Sources: [[Wiki/Tech/Deployment]], [[Wiki/Tech/Strapi]],
    [[Wiki/Reference/Workflows]]"
```

### Scenario 3: No results — wiki gap detected

```
GIVEN the wiki has no pages mentioning "Kubernetes"
WHEN the user runs /wiki query "how is Kubernetes configured?"
THEN the system SHALL state: "No information found in the wiki for Kubernetes."
AND offer: "Would you like me to create a Wiki/Tech/Kubernetes page?"
AND NOT fabricate an answer about Kubernetes
```

### Scenario 4: Stale source flagged

```
GIVEN Wiki/Tech/Docker has updated:: 2025-12-01 and confidence:: high
AND today is 2026-04-10 (131 days old, exceeds 90-day threshold)
WHEN the user runs /wiki query "what Docker version are we using?"
THEN the system SHALL use the page to answer the question
AND flag: "Note: [[Wiki/Tech/Docker]] was last updated 2025-12-01
    (131 days ago) and may be outdated."
```

### Scenario 5: Low-confidence source flagged

```
GIVEN Wiki/Learning/Rust has confidence:: low
WHEN the user runs /wiki query "what Rust resources do we have?"
THEN the system SHALL use the page to answer
AND flag: "Note: [[Wiki/Learning/Rust]] has confidence:: low —
    verify before acting on this."
```

### Scenario 6: Write-back offered and accepted

```
GIVEN the user asks /wiki query "what is our Redis setup?"
AND the wiki has no Redis page
AND the user previously ingested Redis information in L1 memory
WHEN the system reports "No wiki page for Redis"
AND offers "Would you like me to create Wiki/Tech/Redis?"
AND the user confirms "yes"
THEN the system SHALL create Wiki/Tech/Redis with required properties
AND update the Wiki/Tech hub page
AND follow all ingest Phase 3 rules (append-only, cross-refs, etc.)
```

### Scenario 7: Write-back offered and declined

```
GIVEN the same setup as Scenario 6
WHEN the system offers to create Wiki/Tech/Redis
AND the user declines "no"
THEN the system SHALL NOT create any pages
AND SHALL NOT modify any existing pages
```

### Scenario 8: L1 Memory supplements wiki answer

```
GIVEN Wiki/Tech/Deployment contains general deploy documentation
AND L1 Memory file feedback_deploy_ram.md contains "Stop ClamAV before deploy"
WHEN the user runs /wiki query "anything I should know before deploying?"
THEN the system SHALL read the wiki page AND the L1 memory file
AND include both in the synthesized answer
AND attribute: "Sources: [[Wiki/Tech/Deployment]] + L1 Memory (deploy gotcha)"
```

### Scenario 9: Contradicting sources

```
GIVEN Wiki/Tech/Strapi says "Strapi runs on port 1337"
AND Wiki/Reference/Workflows says "Strapi API is at localhost:1338"
WHEN the user runs /wiki query "what port is Strapi on?"
THEN the system SHALL present both values
AND note the contradiction: "Wiki sources disagree: Wiki/Tech/Strapi says 1337,
    Wiki/Reference/Workflows says 1338. Verify which is current."
AND NOT silently pick one value
```

### Scenario 10: Batching when many pages match

```
GIVEN a query matches 7 relevant wiki pages
WHEN the system needs to read them for synthesis
THEN the system SHALL read at most 3 pages at a time
AND process in batches: read 3 → extract relevant info → read next 3 → read last 1
AND synthesize from all extracted information
AND list all 7 pages in source attribution
```

### Scenario 11: Two-stage routing via hub index

```
GIVEN the Wiki/Tech hub `### Index` contains:
    - [[Wiki/Tech/Strapi]] -- Headless CMS, ports, deploy gotchas #strapi #deploy
    - [[Wiki/Tech/PM2]] -- Process manager, cwd/reload bug #pm2 #deploy
    - [[Wiki/Tech/Nginx]] -- Reverse proxy, TLS, upstream ports #nginx
WHEN the user runs /wiki query "what port does Strapi run on?"
THEN the system SHALL read ONLY the Wiki/Tech hub page in Phase 0
AND select [[Wiki/Tech/Strapi]] from its routing line description
AND read ONLY Wiki/Tech/Strapi in Phase 1 (NOT PM2, NOT Nginx, NOT a full-namespace grep)
AND append "<today> -- [[Wiki/Tech/Strapi]] -- query" to Wiki/Reference/Access-Log
```

### Scenario 12: L3 fallback when routing finds nothing

```
GIVEN no hub `### Index` routing line mentions "rate limiting"
WHEN the user runs /wiki query "how do we handle rate limiting?"
THEN Phase 0 SHALL return no confident match
AND the system SHALL fall back to a full-text grep across all wiki pages (L3)
AND read the top 3-5 grep matches in Phase 1
```

### Scenario 13: Re-promote an evicted page on re-hit

```
GIVEN Wiki/Tech/Legacy-Foo has archived:: 2026-06-07 and sits in the Wiki/Tech hub `### Archive`
AND a full-text grep (L3 fallback) matches it for a new query
WHEN the system reads Wiki/Tech/Legacy-Foo in full
THEN the system SHOULD offer: "Wiki/Tech/Legacy-Foo was archived but is relevant again —
    re-promote it to the live index?"
AND on confirmation SHALL move its routing line from `### Archive` to `### Index`
AND remove the archived:: property and reset status::
```

---

## Acceptance Criteria

- [ ] Phase 0 routing reads ONLY hub index pages, not full namespace contents
- [ ] Phase 1 reads ONLY the pages selected by routing (or grep matches on fallback)
- [ ] Full-text grep is the L3 fallback, not the default retrieval path
- [ ] All phases execute in order (Routing, Targeted Read, Access Logging, Synthesize, Write-Back, Output)
- [ ] Max 3 pages loaded simultaneously
- [ ] Every full-page read appends one line to the Access-Log
- [ ] Access-Log append does NOT trigger a per-query git commit
- [ ] Re-hit on an archived page offers re-promotion
- [ ] Answers synthesized from multiple sources (not raw dumps)
- [ ] Confidence levels checked and low-confidence flagged
- [ ] Staleness checked and old sources flagged (90-day threshold)
- [ ] Contradictions surfaced, not silently resolved
- [ ] No fabrication — "not found" when wiki has no answer
- [ ] Write-back requires explicit user confirmation
- [ ] Source attribution in every answer
- [ ] L1 Memory consulted when relevant
- [ ] Works in both Logseq and Obsidian modes

---

## Dependencies

- `llm-wiki.yml` must exist and be valid (see specs/config.md)
- specs/schema.md defines valid page properties checked during synthesis, the hub
  `### Index`/`### Archive` structure, and the Access-Log page
- specs/ingest.md Phase 3 rules apply to write-back operations and maintain routing lines
- specs/prune.md defines LRU-Demote, which consumes the Access-Log this command writes
- specs/l1-l2-routing.md defines when L1 Memory is relevant

# Architecture Diagrams

Mermaid diagrams of the main flows. GitHub renders them in place.

## L1/L2 architecture

What loads every session (L1) and what is read on demand (L2), and how new knowledge is routed.

```mermaid
graph TB
    subgraph "Every Session (Auto-loaded)"
        L1[L1: Claude Memory<br/>~14 files]
        L1R[Rules & Gotchas]
        L1I[Identity & Preferences]
        L1C[Credentials]
        L1 --> L1R
        L1 --> L1I
        L1 --> L1C
    end

    subgraph "On Demand (/llm-wiki query)"
        L2[L2: Logseq Wiki<br/>~46 pages]
        L2P[Projects & History]
        L2W[Workflows & Processes]
        L2K[Research & Learning]
        L2 --> L2P
        L2 --> L2W
        L2 --> L2K
    end

    NEW[New Knowledge] --> ROUTE{Quick rule<br/>or gotcha?}
    ROUTE -->|Yes| L1
    ROUTE -->|No| L2

    USER[User Query] --> CLAUDE[Claude Code]
    CLAUDE --> L1
    CLAUDE -->|Deep question| L2
```

## Ingest flow

The five phases of `/llm-wiki ingest`.

```mermaid
graph LR
    SRC[Source<br/>URL / File / Text] --> A[Phase 1<br/>Analyze & Extract]
    A --> B[Phase 2<br/>Scan Wiki<br/>Find affected pages]
    B --> C[Phase 3<br/>Update 5-15 Pages<br/>Create new / Append]
    C --> D[Phase 4<br/>Quality Gate<br/>Properties? Cross-refs?<br/>No credentials?]
    D --> E[Phase 5<br/>Report<br/>Pages touched / Warnings]
    E --> GIT[git commit]
```

## Query routing

Two-stage routing of `/llm-wiki query` through the hub indexes, the L3 fallback, and how the
Access-Log feeds `/llm-wiki prune`.

```mermaid
graph LR
    Q[Question] --> P0[Phase 0<br/>Routing<br/>Read hub Index only]
    P0 --> PICK{Routing line<br/>matches?}
    PICK -->|Yes| P1[Phase 1<br/>Read chosen<br/>3-5 full pages]
    PICK -->|No match| L3[L3 Fallback<br/>Full-text grep<br/>over all pages]
    L3 --> P1
    P1 --> LOG[Phase 1b<br/>Append to Access-Log<br/>one line per read]
    LOG --> SYN[Phase 2<br/>Synthesize<br/>+ source attribution]
    LOG -. feeds .-> PRUNE[/llm-wiki prune<br/>evict cold pages]
    PRUNE -. demote .-> ARCH[Hub Archive<br/>archived:: marker<br/>file stays, links intact]
```

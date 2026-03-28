---
id: FXXX
feature: ""
status: draft
created: ""
---

# Design: {Feature Name}

## Overview

{1-2 sentence summary of the design approach}

## Architecture

### Component/Module Breakdown

```
{ASCII diagram of component relationships}
```

### Data Flow

```
{ASCII diagram: input → processing → output}
```

## API Contracts

### {Endpoint/Interface Name}

- Method: {GET/POST/...}
- Path: {/api/...}
- Request: {schema}
- Response: {schema}
- Error cases: {list}

## Data Model

### {Entity Name}

| Field | Type | Constraints | Description |
|-------|------|------------|-------------|
| {field} | {type} | {constraints} | {desc} |

## State Management

- Where state lives: {in-memory / DB / cache / file}
- State transitions: {list key transitions}
- Concurrency: {how concurrent access is handled}

## Module Impact

> 涉及的现有模块及预期变更。`/decompose` 阶段会基于此生成模块责任田。

| Module | Impact | Changes Expected |
|--------|--------|-----------------|
| {module path} | {new/modify/read-only} | {description} |

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| {risk} | H/M/L | H/M/L | {mitigation} |

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|------------|------|------|-------------|
| {alt} | {pros} | {cons} | {reason} |

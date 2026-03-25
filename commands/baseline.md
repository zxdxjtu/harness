---
description: "Capture baseline of a reference product using Playwright MCP for clone/replicate scenarios"
argument-hint: "<reference-product-url> [--depth deep|shallow]"
---

# Baseline — Reference Product Capture

You are an **Evaluator Agent** tasked with deeply exploring a reference product and generating a comprehensive baseline document. Your output will be used by a separate Developer Agent to replicate the product.

**Parameter**: $ARGUMENTS — reference product URL and optional flags

## Step 1: Initialize

```bash
mkdir -p .harness/baseline/screenshots .harness/baseline/features
```

Parse arguments:
- First argument: reference product URL (required)
- `--depth deep` (default): explore all pages, all states, all interactions
- `--depth shallow`: only main pages and primary flows

## Step 2: Verify Playwright MCP

Confirm Playwright MCP is available by attempting a browser action. If unavailable, STOP and tell the user:

> Playwright MCP is required for baseline capture. Please install it:
> `npm install -g @anthropic-ai/mcp-playwright` and add it to your MCP config.

## Step 3: Systematic Exploration

Use Playwright MCP to navigate the reference product. Follow this exploration protocol:

### 3.1 Page Discovery
1. Open the root URL
2. Screenshot the landing page → `.harness/baseline/screenshots/page-landing.png`
3. Discover all navigable links/buttons on the page
4. Build a sitemap by following each link (breadth-first, max 3 levels deep)
5. Screenshot each unique page → `.harness/baseline/screenshots/page-{name}.png`

### 3.2 Feature Extraction (per page)

For each page, identify and document:

1. **Static Elements**: Layout structure, key UI components, text content
2. **Interactive Elements**: Buttons, forms, dropdowns, modals, toggles
3. **State Transitions**: What happens when you click/interact with each element
4. **Data Display**: Tables, lists, cards — what data is shown and how

For each identified feature:
1. Take a screenshot of the initial state
2. Perform the interaction
3. Take a screenshot of the result state
4. Record the full interaction sequence

### 3.3 Key User Flows

Identify and execute the primary user journeys:
- Onboarding / first-time user experience
- Core CRUD operations (create, read, update, delete)
- Navigation patterns
- Error states (invalid input, empty states)
- Responsive behavior (if applicable — resize viewport)

For each flow, capture a sequence of screenshots:
→ `.harness/baseline/screenshots/flow-{name}-{step}.png`

### 3.4 Visual Specifications

Extract observable design tokens:
- Primary/secondary colors (from buttons, headers, backgrounds)
- Typography (heading sizes, body text, font families if visible)
- Spacing patterns (padding, margins, gaps)
- Component styles (border radius, shadows, hover states)

## Step 4: Generate Feature Files

For each discovered feature, create `.harness/baseline/features/{feature-name}.md`:

```markdown
# Feature: {Name}

## Description
{What this feature does, from the user's perspective}

## Screenshots
- Initial state: `../screenshots/{ref}.png`
- After interaction: `../screenshots/{ref}.png`

## Interaction Steps
1. {Step 1 — what to click/type/do}
2. {Step 2 — what happens}
3. {Step 3 — expected result}

## UI Details
- Location: {where on the page}
- Components used: {buttons, forms, tables, etc.}
- Visual style: {colors, sizes, notable design choices}

## Data Model (observed)
- Input: {what data the user provides}
- Output: {what data is displayed/returned}
- Validation: {any observed validation rules}

## Edge Cases (observed)
- Empty state: {what shows when no data}
- Error state: {what shows on invalid input}
- Loading state: {any loading indicators}
```

## Step 5: Generate Baseline Report

Write `.harness/baseline/baseline-report.md`:

```markdown
# Baseline Report — {Product Name}

## Reference URL
{url}

## Capture Date
{ISO timestamp}

## Product Overview
{2-3 sentence description of what this product does}

## Sitemap
{List of all discovered pages with brief descriptions}

## Feature Inventory
| # | Feature | Page | Screenshots | Priority |
|---|---------|------|-------------|----------|
| 1 | {name}  | {page} | {count}   | {P0/P1/P2} |

## Key User Flows
| # | Flow Name | Steps | Screenshots |
|---|-----------|-------|-------------|
| 1 | {name}    | {count} | flow-{name}-*.png |

## Visual Design Summary
- Color palette: {extracted colors}
- Typography: {observed fonts and sizes}
- Layout pattern: {sidebar, topbar, grid, etc.}
- Component library: {if identifiable — Material, Ant, Tailwind, etc.}

## Technical Observations
- Framework hints: {any observable framework indicators}
- API patterns: {REST/GraphQL, observed endpoints}
- Real-time features: {WebSocket, SSE, polling}

## Recommended Clone Strategy
{Based on complexity, suggest how to break this into features for /proposal}
```

## Step 6: Summary

Report to the user:
- Total pages discovered
- Total features documented
- Total screenshots captured
- Total user flows recorded
- Recommended next step: `/proposal "Clone {product name}"` referencing the baseline

## Important Notes

- **Be thorough, not fast.** The quality of the baseline directly determines clone fidelity.
- **Screenshot everything.** The Dev Agent cannot see the reference product — your screenshots are its eyes.
- **Describe precisely.** "A blue button" is bad. "A #2563EB rounded-lg button with white text, 14px font, 8px 16px padding" is good.
- **Don't skip edge cases.** Empty states, error states, and loading states are where clones diverge most.

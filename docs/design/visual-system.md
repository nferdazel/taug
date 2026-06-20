# TAUG Visual System

**Date:** 2026-06-20
**Purpose:** Design source of truth for visual implementation

---

## Design Principles

1. **Density over whitespace.** Research requires information density, not breathing room.
2. **Hierarchy through weight, not size.** Use font weight and color, not giant fonts.
3. **Borders over shadows.** 1px borders define space. Shadows are avoided.
4. **Monospace for data.** Financial numbers in monospace. UI text in sans-serif.
5. **Consistent rhythm.** 4px base unit. Everything aligns to grid.

---

## Typography Scale

| Token | Font | Size | Weight | Usage |
|---|---|---|---|---|
| Page Title | Sans | 16px | w600 | Workspace headers |
| Section Title | Sans | 13px | w600 | Card/section headers |
| Body | Sans | 12px | w400 | Primary text |
| Caption | Sans | 11px | w400 | Secondary text |
| Micro | Sans | 10px | w500 | Labels, badges |
| Data Value | Mono | 14px | w600 | Primary financial values |
| Data Medium | Mono | 12px | w500 | Table data |
| Data Small | Mono | 11px | w500 | Compact data |
| Data Meta | Mono | 10px | w400 | Timestamps, metadata |

---

## Spacing Scale

| Token | Value | Usage |
|---|---|---|
| xs | 4px | Inline gaps |
| sm | 8px | Component internal padding |
| md | 12px | Section gaps |
| lg | 16px | Card padding |
| xl | 24px | Major section gaps |

---

## Layout Rules

### Workspace Width

```
max-width: 1400px
padding: 0 24px
margin: 0 auto
```

Content never stretches full width on large monitors. Constrained width increases density and readability.

### Content Regions

```
┌─────────────────────────────────────────────────────────┐
│ Header (48px)                                           │
├─────────────────────────────────────────────────────────┤
│ Toolbar (40px) — search, filters, actions               │
├─────────────────────────────────────────────────────────┤
│ Content (fill) — constrained to max-width               │
│   ┌───────────────────────────────────────────────────┐ │
│   │ Tables, cards, forms                              │ │
│   └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## Table Rules

- Header: 32px height, border-bottom, muted text
- Rows: 40px height, border-bottom, hover highlight
- Cells: 6px vertical, 12px horizontal padding
- Monospace for numeric data
- Right-align numbers
- Left-align text

---

## Form Rules

- Dialog width: 480px
- Field height: 36px
- Field padding: 8px 12px
- Label above field, 4px gap
- 12px between fields
- Primary action: filled button
- Secondary action: outlined button

---

## Empty State Rules

- Icon: 32px, muted color
- Title: 13px, w600
- Description: 11px, muted
- Action: primary button
- Max width: 320px
- Centered in available space

---

## Interaction Rules

- Hover: background lighten (5% opacity white)
- Active: background darken
- Focus: accent border
- Cursor: pointer on clickable rows
- Transition: 150ms ease

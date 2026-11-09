# Dashboard UI Overhaul — Execution Spec

Goal: turn the barebones report into a presentable, consulting-grade (BCG/Bain-style)
executive dashboard. The semantic-model cleanup is already applied live; this document
is the **report-canvas** work, which must be done in Power BI Desktop (the canvas is not
editable through the modeling connection).

Colors, fonts and visual defaults are carried by the theme file
[`powerbi/product_growth_executive_theme.json`](../powerbi/product_growth_executive_theme.json).
The palette is validated colorblind-safe (OKLab ΔE ≥ 8 on adjacent pairs, light surface).

---

## 0. Apply the theme (2 minutes, do first)

1. Power BI Desktop → **View** ribbon → **Themes** → dropdown → **Browse for themes**.
2. Select `powerbi/product_growth_executive_theme.json`.
3. Every visual repaints: white cards, rounded corners, soft shadow, grey page plane,
   Segoe UI throughout, the 8-colour categorical ramp, status good/neutral/bad.

After this, the steps below are layout + per-visual polish only.

---

## 1. Canvas & grid (every page)

| Property | Value |
|---|---|
| Canvas size | 1280 × 720 (16:9), **Type: Custom** under Page → Canvas settings |
| Page plane | `#f9f9f7` (theme default) |
| Outer margin | 24 px gutter on all four sides |
| Column grid | 12 columns, 16 px gap → each col ≈ 85 px |
| Row rhythm | header 72 px · KPI row 120 px · chart rows 230 px |
| Snap | View → **Gridlines ON**, **Snap to grid ON** |

Everything aligns to this grid. Misaligned edges are the #1 "barebones" tell.

---

## 2. Header band (every page — makes it look like a product)

A full-width band across the top, 1280 × 72, at x0 y0:

- **Rectangle** (Insert → Shapes → Rectangle): fill `#0d366b` (deep blue), no border.
- **Title text box**, left-aligned at x24: page name in Segoe UI Semibold 18 `#ffffff`
  (e.g. "Customer Retention"). Below it, Segoe UI 10 `#cde2fb`: the business question
  ("Are customers returning after their first purchase?").
- **Right side**: small logo/wordmark `Product Growth Analytics` Segoe UI Semibold 11 `#ffffff`.
- **Page navigation**: a row of **Buttons** (Insert → Buttons → Blank) along the band,
  one per page, Page navigation action. Selected = `#ffffff` text + 2px bottom underline
  `#eb6834`; unselected = `#86b6ef` text. Keep identical on all 5 pages → consistent nav.

---

## 3. KPI card row (directly under header)

Replace default Card visuals with **4–6 cards** in one row, each 1 grid-col-group wide,
120 px tall, 16 px gap.

Per card:
- Visual: **Card (new)** or Card. Background `#ffffff`, border radius 10, soft shadow (theme).
- **Value**: Segoe UI Semibold 30 `#0b0b0b` (callout class).
- **Category label**: Segoe UI 10 `#898781`, above or below value.
- Add a **small trend sparkline** (line chart, no axes, 1px) or a delta vs prior period
  in `#006300` (up-good) / `#d03b3b` (down-bad) with a ▲/▼ glyph. Delta always ships
  with the arrow glyph + label — never colour alone.

Card metrics per page come from the existing measures (already formatted R$ / % / #,0):
- Overview: Total Customers · Total Orders · Total Revenue · Average Order Value · Repeat Purchase Rate
- Retention: Repeat Customer % · Repeat Customers · One-Time Customers · Average Purchase Frequency
- CLV: Average Customer Revenue · Revenue per Customer · Top 10 Percent Customers · Repeat Revenue %
- Fulfillment: Total Orders Done · Delivery Completion Rate · Late Delivery Rate · Avg Fulfillment Days · Avg Review Score

---

## 4. Chart zone (below KPI row)

- **Max 4 visuals per page.** More than that reads as clutter, not analysis.
- Each visual in its own white card (border + shadow from theme), titled top-left,
  Segoe UI Semibold 12.
- One **hero chart** (the primary trend/cohort) spanning ~7 columns; supporting visuals
  stacked at the right ~5 columns.
- Remove every default visual border/background override so the theme governs — do NOT
  hand-set colours per visual (breaks the single-system look).

### Colour roles — use these, not rainbow
| Meaning | Colour | Where |
|---|---|---|
| Primary series / single-series bars & lines | `#2a78d6` blue | default |
| Second category | `#eb6834` orange | 2-series splits |
| On-Time / good / positive | `#0ca30c` green | delivery, deltas |
| Late / critical | `#d03b3b` red | delivery, risk |
| Warning / medium | `#fab219` amber | SLA medium |
| Not-delivered / N/A | `#898781` grey | null state |
| Sequential magnitude (heatmap, map) | blue ramp `#cde2fb` → `#0d366b` | cohort heatmap, state map |

**Relief rule (required):** three categorical fills — aqua `#1baf7a`, yellow `#eda100`,
magenta `#e87ba4` — sit below 3:1 contrast on the light surface. Wherever they are used,
**turn Data labels ON** (or keep a table view). Do not rely on the swatch alone.

---

## 5. Typography scale (whole report)

| Role | Font | Size | Colour |
|---|---|---|---|
| Page title | Segoe UI Semibold | 18 | `#ffffff` on band |
| Card value | Segoe UI Semibold | 30 | `#0b0b0b` |
| Visual title | Segoe UI Semibold | 12 | `#0b0b0b` |
| Axis / labels | Segoe UI | 10 | `#898781` |
| Body / category | Segoe UI | 10 | `#52514e` |

No other sizes. Three weights max. This alone moves it from "default PBI" to "designed".

---

## 6. Slicer rail (global filters)

Put slicers in a **thin left rail** (x24, below header, ~2 columns) OR a collapsible
filter bar — not scattered. Use the global filters already specced in the case notes:
Purchase Year, Purchase Month, Customer State, Product Category, Payment Type, Customer Segment.

- Style: dropdown slicers (not tiles) to save space, white bg, radius 8 (theme).
- Add a **Clear all slicers** button (Insert → Button → bookmark to default state).
- Set **Edit interactions** so slicers filter all visuals consistently.

---

## 7. Page-by-page polish

Pages follow the existing specs in each case's `09_dashboard_notes.md`. Apply the shell
above to all, then:

- **Executive Overview** — KPI row + Monthly Revenue Trend (line, blue) as hero +
  Revenue by State (filled map, blue sequential) + Monthly Customer Growth (column, blue).
- **Retention** — Cohort heatmap as hero (blue sequential ramp, data labels on),
  Retention curve (line), Monthly retention trend. Heatmap is the money visual — give it room.
- **Repeat Purchase** — One-Time vs Repeat (single stacked bar or donut: grey vs blue),
  Purchase-frequency histogram (column, blue), Top repeat customers (bar).
- **CLV** — Customer value distribution (histogram), Revenue by segment (bar: High/Med/Low
  = blue/orange/grey), Top-20 customers (bar), Lifetime scatter (blue dots).
- **Fulfillment** — Funnel chart hero, delivery outcome donut (green/amber/red/grey),
  SLA-by-state bar with average reference line.
- **Executive Insights** (every case) — no raw visuals: a clean 2-column layout of
  Key Findings (left) and Priority Matrix (right, 2×2 Impact×Effort using a scatter or
  shapes), pulled from the `07`/`08` markdown. This is the page execs screenshot.

---

## 8. Final pass (the 10-minute credibility check)

- [ ] Theme applied; no per-visual colour overrides left.
- [ ] All edges snap to the grid; KPI cards equal width.
- [ ] Every visual has a left-aligned title that states what it shows.
- [ ] ≤ 4 visuals per page; whitespace between cards is even.
- [ ] Tooltips on; each carries order count + revenue + the primary metric.
- [ ] Legends present for ≥2 series; the three low-contrast fills have data labels.
- [ ] One number formatting standard: R$ money, % rates, #,0 counts (already set on measures).
- [ ] Nav buttons identical and aligned on all pages; selected state visible.
- [ ] Screenshot each page and look at it — fix label collisions and overflow.

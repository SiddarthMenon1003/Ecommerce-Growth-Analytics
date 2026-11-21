# Dashboard Notes — Revenue Growth (Case 05)

Source: `analytics_marts/05_revenue_growth_mart.sql` (grain: category × month).
Relate in the model: `product_category_name` → Dim Products, `revenue_month` → Dim Date.

## Suggested page: "Revenue Growth"

**KPI tiles**
- Total Product Revenue (`SUM(monthly_revenue)`), R$13.6M
- Latest-Year Revenue vs Prior Year (YoY %)
- Categories = 80% of Revenue (18 of 74) — concentration
- Top Category Share %
- Peak Month Revenue (Nov 2017)

**Charts**
1. **Revenue over time** (line/area, `revenue_month` × `monthly_revenue`) — trend + Q4 peak.
2. **New vs Returning revenue over time** (stacked area) — acquisition- vs retention-led.
   (from `03_revenue_trends.sql` Section C)
3. **Revenue by category — Pareto** (bar + cumulative line, top 15) — concentration.
4. **Growth-portfolio matrix** (scatter: X = `category_total_revenue`, Y = growth %,
   colour = portfolio_role) — Stars / Cash Cows / Questions / Low Priority.
   (from `05_growth_portfolio.sql`)
5. **Category momentum** (bar, recent-6m growth %, top movers) — where to invest.

## Candidate DAX measures
- `RG Total Revenue = SUM(revenue_growth_mart[monthly_revenue])`
- `RG YoY % = DIVIDE([RG Total Revenue] - prior-year, prior-year)`
- `RG Top Category Share % = DIVIDE(top category revenue, [RG Total Revenue])`
- Reuse `revenue_year` / `revenue_month_num` for time intelligence.

Note: build after the semantic model imports `revenue_growth_mart`. The page is not yet
added to the report (report currently covers Cases 01–04 + Overview).

# Strategic Recommendations — Revenue Growth

These recommendations follow from the findings: revenue is growing but concentrated and
acquisition-led, and the largest categories are also the fastest growing.

### 1. Double down on the "Star" categories 🔴 High
The top categories (*beleza_saude*, *informatica_acessorios*, *relogios_presentes*,
*esporte_lazer*) combine the largest revenue with the fastest growth. Concentrate
merchandising, inventory, and promotion budget on this short list rather than spreading it
across 74 categories.
- **Expected impact:** compounding growth where momentum already exists.
- **Metric:** revenue and growth% of the Star quadrant (see `05_growth_portfolio.sql`).

### 2. Convert the second purchase — the biggest structural lever 🔴 High
Revenue is acquisition-led; repeat customers are worth ~2× a one-time buyer yet are a tiny
share of revenue. A modest lift in repeat rate (e.g., to 10%) adds material incremental
revenue at low marginal cost (sized in `06_business_impact.sql`).
- **Expected impact:** incremental revenue independent of acquisition spend.
- **Metric:** repeat purchase rate, returning-customer revenue share.

### 3. Plan for seasonality 🟡 Medium
Revenue peaks sharply in Q4 (Black Friday / holidays). Align inventory, staffing, and
marketing to the seasonal curve; do not extrapolate annual run-rate from off-peak months.
- **Expected impact:** fewer stock-outs/overstocks around the demand peak.
- **Metric:** forecast accuracy vs seasonal baseline.

### 4. Manage category-concentration risk 🟡 Medium
With 18 of 74 categories making 80% of revenue, the business is exposed if a top category
weakens. Cultivate a small set of high-growth "Question" categories as future diversifiers.
- **Expected impact:** reduced single-category dependency over time.
- **Metric:** top-5 / top-10 category revenue share (see `06_business_impact.sql`).

### 5. Instrument for a real growth forecast 🟡 Medium (enabler)
The dataset supports historical diagnosis only. To move from diagnosis to forecasting,
capture forward signals (traffic, catalogue changes, promotions calendar) so revenue can
be projected rather than described.
- **Expected impact:** turns this case from retrospective to predictive.
- **Metric:** existence of a monthly revenue forecast with tracked error.

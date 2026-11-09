# Executive Findings — Customer Value & Marketing Prioritisation

## Scope note

This case was originally framed as "Marketing ROI" (CAC, ROAS, channel performance).
The Olist dataset contains **no marketing spend, channel, or attribution data**, so true
CAC/ROAS cannot be computed. The case is scoped to what the data supports: **segmenting
customers by value and assigning a marketing priority** so limited budget targets the
customers most worth acquiring and retaining.

> **Grain fix applied (2026-11-04).** The mart now aggregates on `customer_unique_id`
> (true customer), not the order-scoped `customer_id`. Figures below are the corrected
> customer-grain numbers, measured from the model. The live Power BI import still reflects
> the old grain until the ETL is re-run and the dataset refreshed (see remediation P0).

---

## Executive Summary

The marketplace serves **96,096 customers** generating **R$16.0M** in revenue. It is an
acquisition-led, low-loyalty business: **96.9% of customers (93,099) purchase only once**,
and just **3.1% (2,997) ever return**. Repeat customers are nearly **twice as valuable**
as one-time buyers (**R$315 vs R$162** average revenue), yet because they are so few they
account for only **5.9% of revenue (R$0.94M)**.

The strategic implication: value is spread across a huge one-time base, so marketing
should (a) prioritise the highest-value customers for spend and (b) convert more one-time
buyers into repeat buyers, where each conversion roughly doubles customer value.

---

## Key Finding 1 — The business is acquisition-led, loyalty-light

96.9% one-time vs 3.1% repeat. The marketplace replaces, rather than retains, its customer
base. This matches the Case 1 cohort conclusion and is now consistent across all marts
(previously the marts showed 100% one-time due to the grain bug).

## Key Finding 2 — Repeat customers are ~2× more valuable

Average revenue is R$315 per repeat customer vs R$162 per one-time customer. Converting a
one-time buyer to a second purchase roughly doubles their value — the single highest-
leverage marketing action available.

## Key Finding 3 — Value is concentrated, so spend should be tiered

Revenue is uneven across the base: a high-value tier drives a disproportionate share while
a large low-value tail contributes little. Uniform spend across all customers is
inefficient; budget should follow value (Convert / Nurture / Low Priority tiers).

## Key Finding 4 — True "Marketing ROI" is not measurable with this data

No spend or channel data means CAC, ROAS and payback cannot be computed. The honest
deliverable is **relative value prioritisation**; any ROI figure from this dataset would
be fabricated. Instrumentation needed is listed in the recommendations.

---

## Overall Assessment

The data supports a credible value-prioritisation and second-purchase-conversion strategy:
concentrate spend on high-value customers and on moving one-time buyers to repeat, where
value roughly doubles. It does **not** support a marketing-ROI story until channel and
spend data are captured.

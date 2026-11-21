# Executive Findings — Revenue Growth

## Case Overview

This analysis investigates where the marketplace's future revenue will come from. It
measures revenue trend and momentum (month-over-month and year-over-year), the
concentration and growth of product categories, and the split between new-customer and
returning-customer revenue — then sizes the realistic upside of the main growth levers.

The work was conducted on the PostgreSQL warehouse using a `revenue_growth_mart`
(category × month grain) and six analytical SQL studies: data validation, exploratory
analysis, revenue trends, category performance, a growth-portfolio matrix, and business
impact.

> **Revenue definition.** Category/product figures use item-level revenue
> (`SUM(order_items.price)`), which totals **R$13.6M**. Order-level payment revenue
> (`SUM(payments.payment_value)` ≈ **R$16.0M**) is higher because it also includes
> freight and installment effects. The two are used consistently and not mixed.

---

## Executive Summary

Revenue is **growing year-on-year but increasingly concentrated**, and that growth is
still **acquisition-led rather than retention-led**. Annual revenue rose from **R$6.16M
(2017) to R$7.39M (2018 through October)**, with a clear seasonal peak in **November 2017
(R$1.0M, Black Friday)**. The data tails off at the edges (the first and last months are
partial), so the apparent late-period softening is partly a data-coverage artifact.

Growth is carried by a **small set of large, fast-growing categories**. The **top 10
categories hold 62% of revenue** and just **18 of 74 categories make up 80%**. On a
same-period year-over-year basis (current year vs prior year over the same months), the
biggest categories are also among the fastest growing — *relogios_presentes* **+175%**,
*utilidades_domesticas* **+159%**, *beleza_saude* **+158%**, *informatica_acessorios*
**+102%** — so the portfolio's "Stars" and "Cash Cows" overlap at the top.

The largest structural risk to future revenue is the same one surfaced in Cases 1–2:
the business **re-acquires rather than retains**, so revenue growth depends on an
ever-larger top of funnel. The biggest unlocked lever is lifting repeat revenue.

---

# Key Finding 1 — Revenue is growing, but seasonally and from a partial base

Monthly revenue climbs steadily from late 2016, peaks at **~R$1.0M in November 2017**
(Black Friday / holiday season), and remains elevated through 2018. Year-over-year, 2018
is tracking **above 2017**. The edge months (Sep 2016, late 2018) are partial and should
not be read as a decline.

**Implication:** the base trend is positive; planning should be seasonally aware
(Q4 spike) rather than extrapolated from the partial tail.

---

# Key Finding 2 — Revenue is concentrated in a handful of categories

- **Top 10 categories = 62% of revenue**; **18 of 74 categories = 80%**.
- Leaders: *beleza_saude* (9.3%), *relogios_presentes* (8.9%), *cama_mesa_banho* (7.6%),
  *esporte_lazer* (7.3%), *informatica_acessorios* (6.7%).

**Implication:** category concentration is a double-edged sword — efficient to manage, but
a few categories carry the business, so their health is a material revenue risk.

---

# Key Finding 3 — The biggest categories are also the fastest growing

On a **same-period year-over-year** basis (current-year-to-date vs the same months of the
prior year, ending at the last complete month — which removes seasonality and partial-tail
distortion), the whole business is up roughly **+140%** YoY, and several of the largest
categories are **accelerating fastest**: *relogios_presentes* **+175%**,
*utilidades_domesticas* **+159%**, *beleza_saude* **+158%**, *informatica_acessorios*
**+102%**, *esporte_lazer* **+92%**.

> **Method note.** A naive trailing-6-month comparison is misleading here because the
> Nov Black Friday peak and the dataset's partial final month skew it negative. The
> same-period YoY measure (used in `04` Section C and `05`) is the honest read.

**Implication:** the growth portfolio's **Stars** (high revenue + high growth) are clear.
Investment should concentrate where size and momentum already coincide, rather than being
spread evenly across 74 categories.

---

# Key Finding 4 — Growth is acquisition-led, not retention-led

Consistent with Cases 1–2, the overwhelming majority of revenue comes from **first-time
purchases**; returning-customer revenue is a small minority (repeat customers are ~3% of
the base and ~6% of revenue). Future revenue therefore depends heavily on continuously
acquiring new customers.

**Implication:** the single largest untapped revenue lever is **repeat purchasing** — the
value gap between repeat (~R$315) and one-time (~R$162) customers is large, and even a few
points of repeat-rate improvement compounds into meaningful incremental revenue (sized in
`06_business_impact.sql`).

---

## Scope & Limitations

- Item-level revenue excludes freight/installments by design; order-level payment revenue
  is reported separately.
- First and last months in the dataset are partial — trend reads should exclude them.
- The dataset ends in 2018 and has no forward-looking or macro signals, so this is a
  *historical* growth diagnosis, not a forecast.

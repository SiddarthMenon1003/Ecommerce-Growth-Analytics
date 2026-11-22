# Executive Findings — Experimentation

## Case Overview

Product teams need evidence before shipping changes. This case builds the
**experimentation capability**: how to design a credible A/B test (hypotheses,
sample size, power, minimum detectable effect) and how to evaluate results
(significance, confidence intervals, effect size).

> **Scope / data limitation (stated honestly).** The Olist dataset has **no
> randomized-experiment data** — no control/treatment assignment, no test logs
> — so a true A/B test **cannot** be run on it. This case delivers:
> 1. a **reusable statistics toolkit** (`src/experimentation/ab_toolkit.py`),
> 2. a **worked test on real observational data** (delivery timing → review
>    score), clearly labelled as observational, and
> 3. **design templates** (sample size / power) for two proposed experiments.
> Code: `src/experimentation/experiment_analysis.py`. Run:
> `python -m src.experimentation.experiment_analysis`.

---

## Executive Summary

The experimentation framework is in place and demonstrated on a real signal.
The worked observational test confirms, with overwhelming statistical strength,
that **late delivery is associated with a ~2-star drop in review score**
(4.29★ → 2.27★; Welch t ≈ −101, p ≈ 0, 95% CI [−2.06, −1.98], Cohen's d ≈
−1.71 — a *large* effect). This makes delivery timeliness the clearest,
best-evidenced lever on customer satisfaction in the dataset.

The design templates size two recommended experiments. The headline design
constraint: the **second-purchase nudge** is hard to power because the baseline
repeat rate is tiny (3.1%) — detecting a +0.5pp lift needs **~20,300 customers
per arm** (~40,600 total, ~4 months at current volume). A fulfillment change is
far cheaper to test: detecting a **0.1-star** review lift needs only **~2,450
per arm**.

---

# Key Finding 1 — Late delivery → lower reviews (observational, highly significant)

Comparing **Late** deliveries to **non-late** (Early + On Time):

| Group | n | Mean review |
|---|---|---|
| Late | 6,382 | **2.27★** |
| Non-late | 89,448 | **4.29★** |

- **Difference:** −2.02 stars · **Welch t ≈ −101**, df ≈ 6,877 · **p ≈ 0**
- **95% CI for the gap:** [−2.06, −1.98] — a tight, large, highly significant gap
- **Effect size:** Cohen's d ≈ **−1.71** (large)

**Caveat:** this is **observational**, not a randomized test. Late and on-time
orders may differ in other ways (region, category, season). It quantifies a
strong *association* — enough to justify running a real experiment, not to
*prove* causation on its own.

---

# Key Finding 2 — Experiment design: what each test would cost

**Second-purchase nudge (repeat rate, baseline 3.1%), 80% power, α = 0.05:**

| Target lift | New rate | Per arm | Total | ~Duration* |
|---|---|---|---|---|
| +0.3pp | 3.4% | 54,816 | 109,632 | long |
| **+0.5pp** | **3.6%** | **20,303** | **40,606** | **~124 days** |
| +1.0pp | 4.1% | 5,422 | 10,844 | short |

\* at ~330 newly-eligible customers/day.

**Fulfillment change (review score, sd ≈ 1.25), 80% power:**

| MDE | Per arm |
|---|---|
| 0.05★ | 9,812 |
| **0.10★** | **2,453** |
| 0.20★ | 614 |

**Implication:** small-baseline-rate tests (repeat rate) are expensive to power;
continuous-metric tests (review score) are cheap. Prioritise experiments where
the metric is continuous and the expected effect is large — which is exactly the
delivery → review relationship surfaced above.

---

## What "done" looks like

- `ab_toolkit.py` — sample size (proportions & means), MDE, duration, Welch
  t-test, two-proportion z-test.
- `experiment_analysis.py` — runs the observational test + both designs against
  the live warehouse and prints the report above.
- This is a **framework + worked example**, not a live experiment result — by
  necessity, given the data. The instrumentation needed to run real tests
  (assignment, event logging) is noted in the recommendations.

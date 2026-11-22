"""
A/B Testing Toolkit
===================

Reusable statistics for designing and evaluating experiments:

Design (before the test):
  - sample_size_proportions : customers per arm to detect a rate change
  - sample_size_means       : customers per arm to detect a mean change
  - mde_proportions         : smallest rate lift detectable at a given sample
  - experiment_duration     : days to reach the required sample

Evaluation (after the test, or on observational groups):
  - welch_ttest_summary     : two-sample Welch t-test from summary stats
  - two_proportion_ztest    : z-test for a difference in conversion rates

All functions return plain dataclasses / dicts so they are easy to print,
log, or feed into a report. Formulas use scipy + statsmodels.
"""

from dataclasses import dataclass
import numpy as np
from scipy import stats
from statsmodels.stats.power import NormalIndPower
from statsmodels.stats.proportion import proportion_effectsize

_POWER = NormalIndPower()


# ---------------------------------------------------------------- design ----
def sample_size_proportions(baseline_rate, target_rate, alpha=0.05, power=0.80):
    """Customers PER ARM to detect baseline_rate -> target_rate (two-sided)."""
    es = proportion_effectsize(target_rate, baseline_rate)
    n = _POWER.solve_power(effect_size=abs(es), alpha=alpha, power=power,
                           alternative="two-sided")
    return int(np.ceil(n))


def sample_size_means(mde, std_dev, alpha=0.05, power=0.80):
    """Customers PER ARM to detect a mean difference of `mde` (same units as std_dev)."""
    es = mde / std_dev
    n = _POWER.solve_power(effect_size=abs(es), alpha=alpha, power=power,
                           alternative="two-sided")
    return int(np.ceil(n))


def mde_proportions(n_per_arm, baseline_rate, alpha=0.05, power=0.80):
    """Smallest absolute rate lift detectable with n_per_arm (returns pp as a rate)."""
    es = _POWER.solve_power(nobs1=n_per_arm, alpha=alpha, power=power,
                            alternative="two-sided")
    # invert proportion_effectsize (arcsine) around the baseline
    phi1 = 2 * np.arcsin(np.sqrt(baseline_rate))
    target = np.sin((phi1 + es) / 2) ** 2
    return target - baseline_rate


def experiment_duration(total_sample, eligible_per_day):
    """Calendar days to accrue `total_sample` at `eligible_per_day`."""
    return int(np.ceil(total_sample / eligible_per_day))


# ------------------------------------------------------------ evaluation ----
@dataclass
class TTestResult:
    mean_diff: float
    t_stat: float
    df: float
    p_value: float
    ci95: tuple
    cohens_d: float

    def summary(self):
        lo, hi = self.ci95
        return (f"diff={self.mean_diff:+.3f} | t={self.t_stat:.1f} "
                f"df~{self.df:.0f} p={self.p_value:.2e} | "
                f"95% CI [{lo:+.3f}, {hi:+.3f}] | Cohen's d={self.cohens_d:+.2f}")


def welch_ttest_summary(n1, mean1, sd1, n2, mean2, sd2):
    """Two-sample Welch t-test from summary statistics (unequal variance)."""
    se = np.sqrt(sd1**2 / n1 + sd2**2 / n2)
    t = (mean1 - mean2) / se
    df = (sd1**2 / n1 + sd2**2 / n2) ** 2 / (
        (sd1**2 / n1) ** 2 / (n1 - 1) + (sd2**2 / n2) ** 2 / (n2 - 1))
    p = 2 * stats.t.sf(abs(t), df)
    tcrit = stats.t.ppf(0.975, df)
    diff = mean1 - mean2
    ci = (diff - tcrit * se, diff + tcrit * se)
    sp = np.sqrt(((n1 - 1) * sd1**2 + (n2 - 1) * sd2**2) / (n1 + n2 - 2))
    return TTestResult(diff, t, df, p, ci, diff / sp)


def two_proportion_ztest(conv1, n1, conv2, n2):
    """Two-proportion z-test. conv* = number of conversions, n* = arm size."""
    p1, p2 = conv1 / n1, conv2 / n2
    p_pool = (conv1 + conv2) / (n1 + n2)
    se = np.sqrt(p_pool * (1 - p_pool) * (1 / n1 + 1 / n2))
    z = (p1 - p2) / se
    p = 2 * stats.norm.sf(abs(z))
    se_diff = np.sqrt(p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2)
    ci = ((p1 - p2) - 1.96 * se_diff, (p1 - p2) + 1.96 * se_diff)
    return {"rate1": p1, "rate2": p2, "diff": p1 - p2,
            "z": z, "p_value": p, "ci95": ci}

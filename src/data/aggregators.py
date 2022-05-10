"""
Functions to create columns for analysis dataset at user-month frequency.

"""
import os

import numpy as np
import pandas as pd
from scipy import stats
import s3fs

from src import config
import src.helpers.data as hd
import src.helpers.helpers as hh


aggregator_funcs = []


def aggregator(func):
    aggregator_funcs.append(func)
    return func


@aggregator
@hh.timer
def savings_accounts_flows(df):
    """Saving accounts flows variables."""
    sa_flows = df.amount.where(df.is_sa_flow == 1, 0)
    in_out = df.is_debit.map({False: "sa_inflows", True: "sa_outflows"})
    group_vars = [df.user_id, df.ym, in_out]
    return (
        sa_flows.groupby(group_vars)
        .sum()
        .abs()
        .unstack()
        .fillna(0)
        .apply(hd.winsorise, how="upper", pct=1)
        .assign(
            sa_netflows=lambda df: df.sa_inflows - df.sa_outflows,
            has_sa_inflows=lambda df: (df.sa_inflows > 0).astype(int),
        )
        .drop(columns="sa_outflows")
    )


@aggregator
@hh.timer
def income(df):
    """Mean monthly income by calendar year."""
    is_income_pmt = df.tag_group.eq("income") & ~df.is_debit
    inc_pmts = df.amount.where(is_income_pmt, 0).mul(-1).rename("month_income")
    year = df.date.dt.year.rename("year")
    group_cols = [df.user_id, df.ym, year]

    return (
        inc_pmts.groupby(group_cols)
        .sum()
        .groupby(["user_id", "year"])
        .transform("mean")
        .droplevel('year')
    )


@aggregator
@hh.timer
def treatment(df):
    """Indicator for post signup period."""
    group_cols = [df.user_id, df.ym]
    t = df.date >= df.user_registration_date
    return t.groupby(group_cols).max().astype("int").rename("t")


# @aggregator
@hh.timer
def old_income(df):
    """Income variables.

    Incomes are multiplied by -1 to get positive numbers (credits are negative
    in dataset).

    `year_income` is sum of income payments in calendar year, scaled to
    12-month incomes to account for user-years with incomplete data.

    `has_regular_income` is dummy indicating whether user received income in at least
    10 our of last 12 months.

    `has_month_income` is a dummy indicating whether user received income in
    current calendar month.
    """
    is_income_pmt = df.tag_group.eq("income") & ~df.is_debit
    amount = df.amount.where(is_income_pmt, 0).mul(-1)
    group_cols = [df.user_id, df.ym]

    month_income_effective = (
        amount.groupby(group_cols)
        .sum()
        .rename("month_income_effective")
        .div(1000)
        .pipe(hd.winsorise, pct=1, how="upper")
    )

    user_year = lambda x: (x[0], x[1].year)
    scaled_inc = lambda s: s.sum() / s.size * 12
    year_income = (
        month_income_effective.groupby(user_year)
        .transform(scaled_inc)
        .rename("year_income")
    )

    month_income = year_income.div(12).rename("month_income")

    income_variability = (
        month_income_effective.groupby("user_id")
        .rolling(window=12, min_periods=1)
        .std()
        .droplevel(0)
        .rename("income_var")
    )

    has_mt_income = month_income_effective.gt(0).astype(int).rename("has_month_income")

    return pd.concat(
        [
            month_income_effective,
            month_income,
            year_income,
            income_variability,
            has_mt_income,
        ],
        axis=1,
    ).dropna()


# @aggregator
@hh.timer
def pct_credit(df):
    """Proportion of month spend paid by credit card."""
    group_cols = [df.user_id, df.ym]

    is_spend = df.tag_group.eq("spend") & df.is_debit
    spend = df.amount.where(is_spend, np.nan).groupby(group_cols).sum()

    is_cc_spend = is_spend & df.account_type.eq("credit card")
    cc_spend = df.amount.where(is_cc_spend, np.nan).groupby(group_cols).sum()

    return cc_spend.div(spend).mul(100).rename("pct_credit")


# @aggregator
# @aggregator
@hh.timer
def age(df):
    """Adds user age at time of transaction."""
    group_cols = [df.user_id, df.ym]
    age = df.date.dt.year - df.birth_year
    return age.groupby(group_cols).first().rename("age")


# @aggregator
@hh.timer
def female(df):
    """Dummy for whether user is a women."""
    group_cols = [df.user_id, df.ym]
    return df.groupby(group_cols).is_female.first()


# @aggregator
# @aggregator
@hh.timer
def benefits(df):
    """Dummy indicating (non-family) benefit receipt."""
    tags = ["benefits", "job seekers benefits", "other benefits", "incapacity benefits"]
    is_benefit = df.tag_auto.isin(tags)
    benefits = df.amount.where(is_benefit, 0)
    group_cols = [df.user_id, df.ym]
    return benefits.groupby(group_cols).sum().lt(0).astype(int).rename("has_benefits")


# @aggregator
@hh.timer
def pension(df):
    """Dummy for whether user receives pension in current month."""
    age = df.date.dt.year - df.birth_year
    is_pension = df.tag.eq("pensions") & age.ge(60)
    pensions = df.amount.where(is_pension, 0)
    group_cols = [df.user_id, df.ym]
    return pensions.groupby(group_cols).sum().lt(0).astype(int).rename("has_pension")


# @aggregator
@hh.timer
def has_rent_payments(df):
    """Dummies for rent payments.

    Classifying "mortgage or rent" auto tags as mortgages since data inspectio
    suggests that this is accurate for majority of cases.

    Cases where user makes both rent and mortgage payment in same month account
    for less than 2.5% of test dataset, so ignoring this issue.
    """
    group_cols = [df.user_id, df.ym]
    tags = ["rent"]
    is_rent_pmt = df.tag_auto.isin(tags)
    rent_pmts = df.id.where(is_rent_pmt, np.nan)
    return (
        rent_pmts.groupby(group_cols).count().gt(0).astype(int).rename("has_rent_pmt")
    )


# @aggregator
@hh.timer
def has_mortgage_payments(df):
    """Dummies for mortgage payments.

    Classifying "mortgage or rent" auto tags as mortgages since data
    inspectio suggests that this is accurate for majority of cases.  Cases
    where user makes both rent and mortgage payment in same month account
    for less than 2.5% of test dataset, so ignoring this issue.
    """
    group_cols = [df.user_id, df.ym]
    tags = ["mortgage or rent", "mortgage payment"]
    is_mortgage_pmt = df.tag_auto.isin(tags)
    mortgage_pmts = df.id.where(is_mortgage_pmt, np.nan)
    return (
        mortgage_pmts.groupby(group_cols)
        .count()
        .gt(0)
        .astype(int)
        .rename("has_mortgage_pmt")
    )


# @aggregator
@hh.timer
def loan_funds_and_repayments(df):
    """Dummies for receiving and repaying loans."""
    group_cols = [df.user_id, df.ym]
    loan_tags = [
        "personal loan",
        "unsecured loan funds",
        "payday loan",
        "unsecured loan repayment",
        "payday loan funds",
        "secured loan repayment",
    ]
    is_loan = df.tag_auto.isin(loan_tags)

    loan_funds = (
        df.id.where(is_loan & ~df.is_debit, np.nan)
        .groupby(group_cols)
        .count()
        .gt(0)
        .astype(int)
        .rename("has_loan_funds")
    )

    loan_repayment = (
        df.id.where(is_loan & df.is_debit)
        .groupby(group_cols)
        .count()
        .gt(0)
        .astype(int)
        .rename("has_loan_repmt")
    )
    return pd.concat([loan_funds, loan_repayment], axis=1)


# @aggregator
@hh.timer
def region(df):
    """Region and urban dummy."""
    group_cols = [df.user_id, df.ym]
    return df.groupby(group_cols)[["region_name", "is_urban"]].first()


# @aggregator
@hh.timer
def generation(df):
    """Generation of user.

    Source: https://www.beresfordresearch.com/age-range-by-generation/
    """

    def gen(x):
        if 1928 <= x <= 1945:
            gen = "Post War"
        elif 1946 <= x <= 1964:
            gen = "Boomers"
        elif 1965 <= x <= 1980:
            gen = "Gen X"
        elif 1981 <= x <= 1996:
            gen = "Millennials"
        else:
            gen = "Gen Z"
        return gen

    group_cols = [df.user_id, df.ym]
    gens = ["Post War", "Boomers", "Gen X", "Millennials", "Gen Z"]
    gen_cats = pd.CategoricalDtype(gens, ordered=True)
    return (
        df.groupby(group_cols)
        .birth_year.first()
        .map(gen)
        .astype(gen_cats)
        .rename("generation")
    )


# @aggregator
@hh.timer
def overdraft_fees(df):
    """Dummy for whether overdraft fees were paid."""
    pattern = r"(?:od|o/d|overdraft).*(?:fee|interest)"
    is_od_fee = df.desc.str.contains(pattern) & df.is_debit
    od_fees = df.id.where(is_od_fee, np.nan)
    group_cols = [df.user_id, df.ym]
    return od_fees.groupby(group_cols).count().gt(0).astype(int).rename("has_od_fees")


# @aggregator
@hh.timer
def month_spend(df):
    """Total monthly spend.

    Expressed in £'000s to ease coefficient comparison.
    """
    is_spend = df.tag_group.eq("spend") & df.is_debit
    spend = df.amount.where(is_spend, np.nan)
    group_cols = [df.user_id, df.ym]
    return (
        spend.groupby(group_cols)
        .sum()
        .div(1000)
        .pipe(hd.winsorise, pct=1, how="upper")
        .rename("month_spend")
    )


# @aggregator
@hh.timer
def month_spend_txn_value_and_counts(df):
    """Monthly value and count of spend txns per category.

    Spend value expressed in £'000s to ease coefficient comparison.
    """

    def colname(prefix, x):
        """Turn x into proper column name with prefix."""
        return prefix + x.replace(",", "").replace(" ", "_")

    is_spend = df.tag_group.eq("spend") & df.is_debit
    spend_amount = df.amount.where(is_spend, np.nan)
    group_cols = [df.user_id, df.ym, df.tag_spend]

    spend = (
        spend_amount.groupby(group_cols, observed=True)
        .sum()
        .unstack()
        .rename(columns=lambda x: colname("spend_", x))
        .fillna(0)
        .div(1000)
    )

    counts = (
        spend_amount.groupby(group_cols, observed=True)
        .count()
        .unstack()
        .rename(columns=lambda x: colname("count_", x))
        .fillna(0)
    )

    return pd.concat([spend, counts], join="inner", axis=1)


def _entropy_base_values(df, cat, stat="size", wknd=False):
    """Spend txns counts or values for each cat by user-month.

    Args:
    df: A txn-level dataframe.
    cat: A column from df to be used for categorising spending transactions.
    stat: A stat in {'size', 'sum'} to calculate entropy based on counts or
      volume, respectively.
    wknd: A Boolean indicating whether spend txns should be categorised
      by (cat, wknd), if True, or by (cat), if False, where wknd is a dummy
      indicating whether a txn is dated as a Sa, So, or Mo.

    Returns:
      A DataFrame with user-month rows, category columns, and count values.
    """
    is_cat_observed_spend = df.tag_group.eq("spend") & df.is_debit & df[cat].notna()
    df = df.loc[is_cat_observed_spend].copy()
    if wknd:
        is_wknd = df.date.dt.dayofweek.isin([5, 6, 0]).astype(str)
        df[cat] = df[cat].astype(str) + is_wknd
    group_cols = [df.user_id, df.ym] + [cat]
    return df.groupby(group_cols, observed=True).amount.agg(stat).unstack().fillna(0)


def _entropy_scores(df, norm=False, zscore=False, smooth=False):
    """Returns row-wise Shannon entropy scores based on base values.

    Args:
    df: A DataFrame with entity rows, category columns, and count values.
    norm: A Boolean value indicating whether to divide entorpy by
      max entropy.
    smoothed: A Boolean value indicating whether to apply additive smoothing
      to the base values in df before calculating probabilities.

    Returns:
      A series with entropy scores for each row.
    """
    row_totals = df.sum(1)
    num_unique = len(df.columns)
    if smooth:
        probs = (df + 1).div(row_totals + num_unique, axis=0)
    else:
        probs = df.div(row_totals, axis=0)
    e = stats.entropy(probs, base=2, axis=1)
    if norm:
        e = e / np.log2(num_unique)
    if zscore:
        e = (e - e.mean()) / e.std()
    return pd.Series(e, index=df.index)


def _cat_count_std(base_values):
    """Returns row-wise standard deviation of base_values."""
    return base_values.std(1)


# @aggregator
@hh.timer
def cat_based_entropy(df):
    """Calculate entropy based on category txn base values."""
    cats = ["tag", "tag_spend", "merchant"]
    scores = []
    for cat in cats:
        base_values = _entropy_base_values(df, cat, stat="size")
        scores.extend(
            [
                _entropy_scores(base_values, smooth=False).rename(f"entropy_{cat}"),
                _entropy_scores(base_values, smooth=False, zscore=True).rename(
                    f"entropy_{cat}_z"
                ),
                _entropy_scores(base_values, smooth=True).rename(f"entropy_{cat}_s"),
                _entropy_scores(base_values, smooth=True, zscore=True).rename(
                    f"entropy_{cat}_sz"
                ),
                _cat_count_std(base_values).rename(f"std_{cat}"),
            ]
        )
    return pd.concat(scores, axis=1)


# @aggregator
@hh.timer
def grocery_shop_entropy(df):
    """Returns Shannon entropy based on grocery merchant counts."""

    def is_grocery_shop(df):
        """Return True if a txn is a grocery shop.

        Regex requires optional supermarket suffix because for some merchants
        (e.g. Tesco), other suffixes like 'finance' or 'fuel' also occurr,
        while those that only sell groceries (e.g. Ocado) appear without a
        suffix.
        """
        grocers = [
            "tesco",
            "sainsburys",
            "asda",
            "morrisons",
            "aldi",
            "co-op",
            "lidl",
            "waitrose",
            "iceland",
            "ocado",
        ]
        p = fr"^({'|'.join(grocers)})(:?\ssupermarket)?$"
        return df.merchant_business_line.str.match(p)

    data = df[["user_id", "ym", "tag_group", "is_debit", "amount", "date"]].copy()
    data["merchant"] = df.merchant.where(is_grocery_shop(df), np.nan)
    counts = _entropy_base_values(data, cat="merchant", stat="size", wknd=True)
    return pd.concat(
        [
            _entropy_scores(counts).rename("entropy_groc"),
            _entropy_scores(counts, zscore=True).rename("entropy_groc_z"),
            _entropy_scores(counts, smooth=True).rename("entropy_groc_s"),
            _entropy_scores(counts, smooth=True, zscore=True).rename("entropy_groc_sz"),
        ],
        axis=1,
    )


# @aggregator
@hh.timer
def txns_count(df):
    group_cols = [df.user_id, df.ym]
    return (
        df.groupby(group_cols)
        .id.size()
        .rename("txns_count")
        .pipe(hd.trim, how="upper", pct=1)
        .dropna()
    )


# @aggregator
@hh.timer
def spend_txns_count(df):
    is_spend = df.tag_group.eq("spend") & df.is_debit
    group_cols = [df.user_id, df.ym]
    return is_spend.groupby(group_cols).sum().rename("txns_count_spend")

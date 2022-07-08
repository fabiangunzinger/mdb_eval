"""
Functions to validate integrity of analysis data.

"""

import numpy as np

import src.config as config


validators = []


def validator(func):
    """Add func to list of validator functions."""
    validators.append(func)
    return func


@validator
def no_missing_values(df):
    exceptions = ['dspend_mean']
    assert df.drop(exceptions, axis='columns').notna().all().all()
    return df


@validator
def correct_treatment_lags(df):
    assert df[df.t.eq(0)].tt.between(-np.inf, -1).all()
    assert df[df.t.eq(1)].tt.between(0, np.inf).all()
    return df


@validator
def at_least_min_year_income(df, min_income=config.MIN_YEAR_INCOME):
    assert df.month_income.min() >= min_income / 12
    return df


@validator
def min_pre_and_post_signup_months(df):
    g = df.groupby("user_id")
    assert g.tt.min().max() <= -config.MIN_PRE_MONTHS
    assert g.tt.max().min() >= config.MIN_POST_MONTHS - 1  # [0, 5] are post periods
    return df


@validator
def min_month_spend(df, min_spend=config.MIN_MONTH_SPEND):
    assert df.month_spend.min() >= min_spend
    return df


@validator
def min_month_txns(df, min_txns=config.MIN_MONTH_TXNS):
    assert df.txns_count.min() >= min_txns
    return df


@validator
def complete_demographic_info(df):
    assert df.filter(regex="is_female|age|region").isna().sum().sum() == 0
    return df


@validator
def working_age(df):
    assert df.age.between(18, 65, inclusive="both").all()
    return df

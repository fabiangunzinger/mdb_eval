"""
Functions to select users for analysis data.

"""

import collections
import functools
import itertools

import numpy as np

import src.config as cf
import src.helpers.helpers as hh


selectors = []
sample_counts = collections.Counter()


def selector(func):
    selectors.append(func)
    return func


def counter(func):
    """Count sample after applying function and update selection table.

    First line of func docstring is used for description in selection table.
    """

    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        df = func(*args, **kwargs)
        description = func.__doc__.splitlines()[0]
        sample_counts.update(
            {
                description + "@users": df.user_id.nunique(),
                description + "@user_months": len(df),
                description + "@txns": df.txns_count.sum(),
                description + "@txns_volume": df.txns_volume.sum() / 1e6,
            }
        )
        return df

    return wrapper


@selector
@counter
def add_raw_count(df):
    """Raw sample
    Add count of raw dataset to selection table."""
    return df


# @selector
# @counter
def drop_first_and_last_month(df):
    """Drop first and last month

    These will likely have incomplete data.
    """
    g = df.groupby("user_id")
    ym_max = g.ym.transform("max")
    ym_min = g.ym.transform("min")
    cond = df.ym.between(ym_min, ym_max, inclusive="neither")
    return df[cond]


@selector
@counter
def signup_after_march_2017(df):
    """App signup after March 2017

    To ensure that we have at least 12 months of account history
    available, which became available for all major banks from
    April 2017 onwards.
    """
    cond = df.user_reg_ym.ge('2017-04')
    users = cond[cond].index
    return df[df.user_id.isin(users)]


# @selector
# @counter
def pre_and_post_signup_data(df, lower=cf.MIN_PRE_MONTHS, upper=cf.MIN_POST_MONTHS):
    """At least 6 months of pre and post signup data

    Also ensures that we obser users during all months during that period.
    """
    required_periods = set(range(-lower, upper))

    def cond_checker(g):
        observed_periods = set(g.tt.unique())
        return required_periods.issubset(observed_periods)

    cond = df.groupby("user_id").apply(cond_checker)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def has_savings_account(df):
    """At least one savings account"""
    cond = df.has_savings_account.groupby(df.user_id).max().eq(1)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def has_current_account(df):
    """At least one current account"""
    cond = df.has_current_account.groupby(df.user_id).max().eq(1)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def year_income(df, min_income=cf.MIN_YEAR_INCOME):
    """At least \pounds5,000 of annual income"""
    cond = df.groupby("user_id").month_income_mean.min().ge(min_income / 12)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def month_min_txns(df, min_txns=cf.MIN_MONTH_TXNS):
    """At least 10 txns each month"""
    cond = df.groupby("user_id").txns_count.min().ge(min_txns)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def month_min_spend(df, min_spend=cf.MIN_MONTH_SPEND):
    """At least \pounds200 of monthly spend"""
    cond = df.groupby("user_id").month_spend.min().ge(min_spend)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def max_active_accounts(df, max_accounts=cf.MAX_ACTIVE_ACCOUNTS):
    """No more than 10 active accounts"""
    cond = df.groupby("user_id").accounts_active.max().le(max_accounts)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def complete_demographic_info(df):
    """Complete demographic information

    Retains only users for which we have full demographic information.
    """
    cols = ["age", "is_female", "is_urban"]
    cond = df[cols].isna().groupby(df.user_id).sum().sum(1).eq(0)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def working_age(df):
    """Working age"""
    cond = df.groupby("user_id").age.first().between(18, 65, inclusive="both")
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def add_final_count(df):
    """Final sample
    Add count of final dataset to selection table."""
    return df

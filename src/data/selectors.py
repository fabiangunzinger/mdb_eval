"""
Functions to select users for analysis data.

First line in docstring is used in selection table.
"""

import collections
import functools
import itertools

import src.config as config

selector_funcs = []
sample_counts = collections.Counter()


def selector(func):
    selector_funcs.append(func)
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


@selector
@counter
def year_income(df, min_income=config.MIN_YEAR_INCOME):
    """Annual income of at least \pounds5,000"""
    cond = df.groupby("user_id").month_income.min().ge(min_income / 12)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def savings_account(df):
    """At least one savings account"""
    cond = df.has_sa_account.groupby(df.user_id).max().eq(1)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def min_number_of_months(df, min_months=config.MIN_TOTAL_MONTHS):
    """At least 12 months of data"""
    cond = df.groupby("user_id").size().ge(min_months)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def min_pre_signup_data(df, min_months=config.MIN_PRE_MONTHS):
    """At least 6 months of pre-signup data"""
    cond = df.groupby("user_id").tt.min().le(-6)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def month_min_spend(df, min_spend=config.MIN_MONTH_SPEND):
    """Monthly spend of at least \pounds200"""
    cond = df.groupby("user_id").month_spend.min().ge(min_spend)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def month_min_txns(df, min_txns=config.MIN_MONTH_TXNS):
    """At least 10 txns each month"""
    cond = df.groupby("user_id").txns_count.min().ge(min_txns)
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


# @selector
# def return_data_and_counter(df):
#     return df, sample_counts

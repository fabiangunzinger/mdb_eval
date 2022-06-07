"""
Functions to select users for analysis data.

"""

import collections
import functools
import itertools

import src.config as config
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
                "  " + description + "@users": df.user_id.nunique(),
                "  " + description + "@user_months": len(df),
                "  " + description + "@txns": df.txns_count.sum(),
                "  " + description + "@txns_volume": df.txns_volume.sum() / 1e6,
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
def drop_beta_users(df):
    """Drop all beta users
    App was launched sometime in 2011, so drop all users registering before
    2012.
    """
    cond = df.groupby('user_id').user_registration_date.ge('2012-01-01')
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
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
def min_pre_signup_data(df, min_pre_months=config.MIN_PRE_MONTHS):
    """At least 6 months of pre-signup data"""
    cond = df.groupby("user_id").tt.min().le(-min_pre_months)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def min_post_signup_data(df, min_post_months=config.MIN_POST_MONTHS):
    """At least 6 months of post-signup data"""
    cond = df.groupby("user_id").tt.max().ge(min_post_months)
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
def has_savings_account(df):
    """At least one savings account"""
    cond = df.has_savings_account.groupby(df.user_id).max().eq(1)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


# @selector
# @counter
def savings_accounts_added_at_once(df):
    """All savings accounts observed throughout"""
    cond = df.groupby('user_id').sa_added_once.first()
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def max_active_accounts(df, max_accounts=config.MAX_ACTIVE_ACCOUNTS):
    """No more than 10 active accounts"""
    cond = df.groupby("user_id").accounts_active.max().le(max_accounts)
    users = cond[cond].index
    return df[df.user_id.isin(users)]


@selector
@counter
def year_income(df, min_income=config.MIN_YEAR_INCOME):
    """At least \pounds5,000 of annual income"""
    cond = df.groupby("user_id").month_income.min().ge(min_income / 12)
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
def month_min_spend(df, min_spend=config.MIN_MONTH_SPEND):
    """At least \pounds200 of monthly spend"""
    cond = df.groupby("user_id").month_spend.min().ge(min_spend)
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


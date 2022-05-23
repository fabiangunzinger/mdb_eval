"""
Functions to validate integrity of analysis data.

"""

import src.config as config


validator_funcs = []


def validator(func):
    """Add func to list of validator functions."""
    validator_funcs.append(func)
    return func


@validator
def no_missing_values(df):
    assert df.isna().sum().sum() == 0
    return df


@validator
def at_least_min_year_income(df, min_income=config.MIN_YEAR_INCOME):
    assert df.month_income.min() >= min_income / 12
    return df


@validator
def at_least_one_savings_account(df):
    assert df.groupby('user_id').txns_count_sa.max().gt(0).all()
    return df


@validator
def min_number_of_months(df):
    assert df.groupby('user_id').size().ge(6).all()
    return df


@validator
def min_month_spend(df, min_spend=config.MIN_MONTH_SPEND):
    assert df.month_spend.min() >= min_spend
    return df


@validator
def complete_demographic_info(df):
    assert df.filter(regex='is_female|age|region').isna().sum().sum() == 0
    return df


@validator
def reasonable_age_bounds(df):
    assert df.age.between(16, 110, inclusive='both')
    return df

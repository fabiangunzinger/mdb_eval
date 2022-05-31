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


TIMER_ON = False


aggregators = []


def aggregator(func):
    aggregators.append(func)
    return func


@aggregator
@hh.timer(on=TIMER_ON)
def numeric_ym(df):
    """Numeric ym variable for use in R."""
    group_cols = [df.user_id, df.ym]
    g = df.ym.groupby(group_cols).first()
    yr = g.dt.year.astype("string")
    mt = g.dt.month.astype("string").apply("{:0>2}".format)
    return (yr + mt).astype("int").rename("ymn")


@aggregator
@hh.timer(on=TIMER_ON)
def txns_count(df):
    group_cols = [df.user_id, df.ym]
    return df.groupby(group_cols).id.size().rename("txns_count")


@aggregator
@hh.timer(on=TIMER_ON)
def txns_volume(df):
    group_cols = [df.user_id, df.ym]
    return df.amount.abs().groupby(group_cols).sum().rename("txns_volume")


@aggregator
@hh.timer(on=TIMER_ON)
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
        .droplevel("year")
    )


@aggregator
@hh.timer(on=TIMER_ON)
def savings_accounts_flows(df):
    """Saving accounts flows variables."""
    is_sa_flow = df.account_type.eq("savings") & df.amount.abs().gt(5)
    sa_flows = df.amount.where(df.is_sa_flow == 1, 0)
    in_out = df.is_debit.map({True: "outflows", False: "inflows"})
    month_income = income(df)
    group_vars = [df.user_id, df.ym, in_out]
    return (
        sa_flows.groupby(group_vars)
        .sum()
        .abs()
        .unstack()
        .fillna(0)
        .assign(
            netflows=lambda df: df.inflows - df.outflows,
            netflows_norm=lambda df: df.netflows / month_income,
            inflows_norm=lambda df: df.inflows / month_income,
            outflows_norm=lambda df: df.outflows / month_income,
            has_pos_netflows=lambda df: (df.netflows > 0).astype(int),
            pos_netflows=lambda df: df.netflows * df.has_pos_netflows,
        )
        .replace([np.inf, -np.inf, np.nan], 0)
    )


@aggregator
@hh.timer(on=TIMER_ON)
def treatment(df):
    """Indicator for post signup period."""
    group_cols = [df.user_id, df.ym]
    t = df.date >= df.user_registration_date
    return t.groupby(group_cols).max().astype("int").rename("t")


@aggregator
@hh.timer(on=TIMER_ON)
def time_to_treatment(df):
    """Number of leads or lags to signup month."""
    group_cols = [df.user_id, df.ym]
    ym = df.ym.view("int")
    reg_ym = df.user_registration_date.dt.to_period("m").view("int")
    return ym.sub(reg_ym).groupby(group_cols).first().rename("tt")


@aggregator
@hh.timer(on=TIMER_ON)
def month_spend(df):
    """Total monthly spend."""
    is_spend = df.tag_group.eq("spend") & df.is_debit
    spend = df.amount.where(is_spend, np.nan)
    group_cols = [df.user_id, df.ym]
    return spend.groupby(group_cols).sum().rename("month_spend")


@aggregator
@hh.timer(on=TIMER_ON)
def user_registration_date(df):
    """User registration date."""
    group_cols = [df.user_id, df.ym]
    return df.groupby(group_cols).user_registration_date.first()


@aggregator
@hh.timer(on=TIMER_ON)
def age(df):
    """Adds user age at time of signup."""
    group_cols = [df.user_id, df.ym]
    age = df.user_registration_date.dt.year - df.birth_year
    return age.groupby(group_cols).first().rename("age")


@aggregator
@hh.timer(on=TIMER_ON)
def female(df):
    """Dummy for whether user is a women."""
    group_cols = [df.user_id, df.ym]
    return df.groupby(group_cols).is_female.first()


@aggregator
@hh.timer(on=TIMER_ON)
def region(df):
    """Region and urban dummy."""
    group_cols = [df.user_id, df.ym]
    return (
        df.rename(columns={"region_name": "region"})
        .groupby(group_cols)[["region", "is_urban"]]
        .first()
    )


@aggregator
@hh.timer(on=TIMER_ON)
def sa_account(df):
    """Indicator for whether user has at least one savings account added.

    We can only observe an account as added when we observe a transaction. So
    the indicator is one when we observe at least one sa txn for the user.
    """
    group_cols = [df.user_id, df.ym]
    return (
        df.account_type.eq("savings")
        .groupby(group_cols)
        .max()
        .groupby("user_id")
        .transform("max")
        .rename("has_sa_account")
    )


@aggregator
@hh.timer(on=TIMER_ON)
def generation(df):
    """Generation of user.

    Source: https://www.beresfordresearch.com/age-range-by-generation/
    """

    def gen(x):
        if np.isnan(x):
            gen = np.nan
        elif 1928 <= x <= 1945:
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
        .to_frame()
        .assign(generation_code=lambda df: df.generation.cat.codes)
    )


@aggregator
@hh.timer(on=TIMER_ON)
def new_loan(df):
    """Dummy indicating loan takeout."""
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
    loans = df.id.where(is_loan & ~df.is_debit, np.nan)
    return loans.groupby(group_cols).count().gt(0).astype(int).rename("new_loan")


@aggregator
@hh.timer(on=TIMER_ON)
def proportion_credit(df):
    """Proportion of month spend paid by credit card."""
    group_cols = [df.user_id, df.ym]
    is_spend = df.tag_group.eq("spend") & df.is_debit
    spend = df.amount.where(is_spend, np.nan).groupby(group_cols).sum()
    is_cc_spend = is_spend & df.account_type.eq("credit card")
    cc_spend = df.amount.where(is_cc_spend, np.nan).groupby(group_cols).sum()
    return cc_spend.div(spend).rename("prop_credit")


@aggregator
@hh.timer(on=TIMER_ON)
def discretionary_spend(df):
    """Highly discretionary spend as a proportion of monthly income."""
    tags = [
        "accessories",
        "appearance",
        "beauty products",
        "beauty treatments",
        "clothes",
        "clothes - designer or other",
        "clothes - everyday or work",
        "clothes - other",
        "designer clothes",
        "food, groceries, household",
        "groceries",
        "supermarket",
        "jewellery",
        "personal electronics",
        "shoes",
        "cinema",
        "concert & theatre",
        "dining and drinking",
        "dining or going out",
        "enjoyment",
        "entertainment, tv, media",
        "gambling",
        "games and gaming",
        "hotel/b&b",
        "lunch or snacks",
        "sports event",
        "take-away",
    ]

    group_cols = [df.user_id, df.ym]
    is_desc_spend = df.tag_auto.isin(tags) & df.is_debit
    desc_spend = df.amount.where(is_desc_spend, np.nan).groupby(group_cols).sum()
    month_income = income(df)
    return (
        desc_spend.div(month_income)
        .replace([np.inf, -np.inf, np.nan], 0)
        .rename("disc_spend")
    )

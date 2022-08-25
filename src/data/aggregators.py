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
def month(df):
    """Numeric month for use as FE."""
    group_cols = [df.user_id, df.ym]
    return df.date.dt.month.groupby(group_cols).first().rename("month")


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
    """Month and year income."""
    is_income_pmt = df.tag_group.eq("income") & ~df.is_debit
    inc_pmts = df.amount.where(is_income_pmt, 0).mul(-1)
    year = df.date.dt.year.rename("year")

    month_income = (
        inc_pmts.groupby([df.user_id, df.ym, year]).sum().rename("month_income")
    )
    year_income = inc_pmts.groupby([df.user_id, year]).sum().rename("year_income")
    month_income_mean = (
        inc_pmts.groupby([df.user_id, df.ym, year])
        .sum()
        .groupby(["user_id", "year"])
        .transform("mean")
        .rename("month_income_mean")
    )

    data = pd.merge(month_income, year_income, left_index=True, right_index=True)

    return pd.merge(
        data, month_income_mean, left_index=True, right_index=True
    ).droplevel("year")


@aggregator
@hh.timer(on=TIMER_ON)
def savings_accounts_flows(df):
    """Saving accounts flows variables."""
    is_sa_flow = df.account_type.eq("savings") & df.amount.abs().gt(5)
    sa_flows = df.amount.where(df.is_sa_flow, 0)
    in_out = df.is_debit.map({True: "outflows", False: "inflows"})
    month_income = income(df).month_income
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
def user_registration_ym(df):
    """Year-month of user registration."""
    group_cols = [df.user_id, df.ym]
    return (
        df.groupby(group_cols)
        .user_registration_date.first()
        .dt.to_period("m")
        .rename("user_reg_ym")
    )


@aggregator
@hh.timer(on=TIMER_ON)
def treatment(df):
    """Treatment indicator."""
    group_cols = [df.user_id, df.ym]
    reg_ym = user_registration_ym(df)
    return df.groupby(group_cols).ym.first().ge(reg_ym).astype("int").rename("t")


@aggregator
@hh.timer(on=TIMER_ON)
def time_to_treatment(df):
    """Leads or lags to signup month.

    Month of signup is set to tt = 0.
    """
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
        .assign(region_code=lambda df: df.region.factorize()[0])
    )


@aggregator
@hh.timer(on=TIMER_ON)
def has_savings_account(df):
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
        .rename("has_savings_account")
    )


@aggregator
@hh.timer(on=TIMER_ON)
def has_current_account(df):
    """Indicator for whether user has at least one current account added.

    We can only observe an account as added when we observe a transaction. So
    the indicator is one when we observe at least one current account txn for
    the user.
    """
    group_cols = [df.user_id, df.ym]
    return (
        df.account_type.eq("current")
        .groupby(group_cols)
        .max()
        .groupby("user_id")
        .transform("max")
        .rename("has_current_account")
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
    """Highly discretionary spend."""
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
    is_disc_spend = df.tag_auto.isin(tags) & df.is_debit
    return (
        df.amount.where(is_disc_spend, np.nan)
        .groupby(group_cols)
        .agg([("dspend", "sum"), ("dspend_count", "count"), ("dspend_mean", "mean")])
    )


@aggregator
@hh.timer(on=TIMER_ON)
def num_accounts(df):
    """Number of active accounts."""
    group_cols = [df.user_id, df.ym]
    total = (
        df.groupby("user_id")
        .account_id.nunique()
        .rename("accounts_total")
        .reset_index()
    )
    return (
        df.groupby(group_cols)
        .account_id.nunique()
        .rename("accounts_active")
        .reset_index()
        .merge(total)
        .set_index(["user_id", "ym"])
    )


@aggregator
@hh.timer(on=TIMER_ON)
def investments(df):
    """Flows into investment and pension funds."""
    group_cols = [df.user_id, df.ym]
    is_invest = df.tag_auto.eq("pension or investments") & df.is_debit
    invest = df.amount.where(is_invest, 0)
    return invest.groupby(group_cols).sum().rename('investments')


@aggregator
@hh.timer(on=TIMER_ON)
def user_precedence_tag_based_savings(df):
    """
    Transfers from current accounts to (linked and unlinked)
    savings accounts based on manual user tags.
    """
    group_vars = [df.user_id, df.ym]
    is_tfr = (
        df.tag_up.str.contains("saving") & df.account_type.eq("current") & df.is_debit
    )
    tfr = df.amount.where(is_tfr, 0)
    return tfr.groupby(group_vars).sum().rename('up_savings')


@aggregator
@hh.timer(on=TIMER_ON)
def current_account_transfers(df):
    """
    Transfers from current accounts.
    """
    group_vars = [df.user_id, df.ym]
    is_tfr = (
        df.tag_group.eq("transfers") & df.account_type.eq("current") & df.is_debit
    )
    tfr = df.amount.where(is_tfr, 0)
    return tfr.groupby(group_vars).sum().rename('ca_transfers')


@aggregator
@hh.timer(on=TIMER_ON)
def credit_card_payments(df):
    """
    Payments into credit card accounts.
    """
    group_vars = [df.user_id, df.ym]
    is_cc_inflow = (
        df.account_type.eq("credit card")
        & ~df.is_debit
        & df.tag_auto.eq("credit card") # discards refunds
    )
    cc_inflow = df.amount.where(is_cc_inflow, 0).mul(-1)
    return cc_inflow.groupby(group_vars).sum().rename('cc_payments')


@aggregator
@hh.timer(on=TIMER_ON)
def loan_funds(df):
    """Loan funds inflow."""
    LOAN_FUND_TAGS = [
        "personal loan",
        "unsecured loan funds",
        "payday loan",
        "payday loan funds",
        "student loan funds",
    ]
    group_vars = [df.user_id, df.ym]
    is_loan_fund = df.tag_auto.isin(LOAN_FUND_TAGS) & ~df.is_debit
    loan_fund = df.amount.where(is_loan_fund, 0).mul(-1)
    return loan_fund.groupby(group_vars).sum().rename("loan_funds")


@aggregator
@hh.timer(on=TIMER_ON)
def loan_repayment(df):
    """Loan repayments."""
    LOAN_RPMT_TAGS = [
        "secured loan repayment",
        "unsecured loan repayment",
        "student loan repayment",
        "payday loan",
        "personal loan",
    ]
    group_vars = [df.user_id, df.ym]
    is_loan_rpmt = df.tag_auto.isin(LOAN_RPMT_TAGS) & df.is_debit
    loan_rpmt = df.amount.where(is_loan_rpmt, 0)
    return loan_rpmt.groupby(group_vars).sum().rename("loan_rpmt")



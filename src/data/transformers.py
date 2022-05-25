"""
Functions to transform variables.

"""

import src.helpers.data as hd


transformer_funcs = []


def transformer(func):
    """Add func to list of transformer functions."""
    transformer_funcs.append(func)
    return func


@transformer
def winsorise_sa_flows(df):
    df['inflows'] = hd.winsorise(df.inflows, pct=1, how='upper')
    df['outflows'] = hd.winsorise(df.outflows, pct=1, how='upper')
    df['netflows'] = hd.winsorise(df.netflows, pct=1, how='both')
    df['inflows_norm'] = hd.winsorise(df.inflows_norm, pct=1, how='upper')
    df['outflows_norm'] = hd.winsorise(df.outflows_norm, pct=1, how='upper')
    df['netflows_norm'] = hd.winsorise(df.netflows_norm, pct=1, how='both')
    return df


@transformer
def winsorise_month_income(df):
    df['month_income'] = hd.winsorise(df.month_income, pct=0, how='upper')
    return df


@transformer
def winsorise_month_spend(df):
    df['month_spend'] = hd.winsorise(df.month_spend, pct=0, how='upper')
    return df





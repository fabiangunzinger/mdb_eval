"""
Functions to transform variables.

"""

import src.helpers.data as hd


transformer_funcs = []


WIN_PCT = 5


def transformer(func):
    """Add func to list of transformer functions."""
    transformer_funcs.append(func)
    return func


@transformer
def winsorise(df):
    df["inflows"] = hd.winsorise(df.inflows, pct=WIN_PCT, how="upper")
    df["outflows"] = hd.winsorise(df.outflows, pct=WIN_PCT, how="upper")
    df["netflows"] = hd.winsorise(df.netflows, pct=WIN_PCT / 2, how="both")
    df["pos_netflows"] = hd.winsorise(df.pos_netflows, pct=WIN_PCT / 2, how="upper")
    df["inflows_norm"] = hd.winsorise(df.inflows_norm, pct=WIN_PCT, how="upper")
    df["outflows_norm"] = hd.winsorise(df.outflows_norm, pct=WIN_PCT, how="upper")
    df["netflows_norm"] = hd.winsorise(df.netflows_norm, pct=WIN_PCT / 2, how="both")

    df["txns_count"] = hd.winsorise(df.txns_count, pct=WIN_PCT, how="upper")
    df["txns_count"] = hd.winsorise(df.txns_volume, pct=WIN_PCT, how="upper")
    df["month_spend"] = hd.winsorise(df.month_spend, pct=WIN_PCT, how="upper")
    df["disc_spend"] = hd.winsorise(df.disc_spend, pct=WIN_PCT, how="upper")
    df["month_income"] = hd.winsorise(df.month_income, pct=WIN_PCT, how="upper")

    return df

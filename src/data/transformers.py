"""
Functions to transform variables.

"""

import src.config as config
import src.helpers.data as hd


transformers = []


def transformer(func):
    """Add func to list of transformer functions."""
    transformers.append(func)
    return func


@transformer
def winsorise(df):
    df["inflows"] = hd.winsorise(df.inflows, pct=config.WIN_PCT, how="upper")
    df["outflows"] = hd.winsorise(df.outflows, pct=config.WIN_PCT, how="upper")
    df["netflows"] = hd.winsorise(df.netflows, pct=config.WIN_PCT / 2, how="both")
    df["pos_netflows"] = hd.winsorise(
        df.pos_netflows, pct=config.WIN_PCT / 2, how="upper"
    )
    df["inflows_norm"] = hd.winsorise(df.inflows_norm, pct=config.WIN_PCT, how="upper")
    df["outflows_norm"] = hd.winsorise(
        df.outflows_norm, pct=config.WIN_PCT, how="upper"
    )
    df["netflows_norm"] = hd.winsorise(
        df.netflows_norm, pct=config.WIN_PCT / 2, how="both"
    )

    df["txns_count"] = hd.winsorise(df.txns_count, pct=config.WIN_PCT, how="upper")
    df["txns_volume"] = hd.winsorise(df.txns_volume, pct=config.WIN_PCT, how="upper")
    df["month_spend"] = hd.winsorise(df.month_spend, pct=config.WIN_PCT, how="upper")
    df["discret_spend"] = hd.winsorise(
        df.discret_spend, pct=config.WIN_PCT, how="upper"
    )
    df["month_income"] = hd.winsorise(df.month_income, pct=config.WIN_PCT, how="upper")

    return df

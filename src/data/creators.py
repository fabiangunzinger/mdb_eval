"""
Functions to create additional variables.

"""

import src.helpers.helpers as hh


creator_funcs = []


def creator(func):
    creator_funcs.append(func)
    return func


@creator
@hh.timer
def normalised_sa_inflows(df):
    """Savings account inflows normalised by month income."""
    df['sa_inflows_norm'] = df.sa_inflows.div(df.month_income)
    return df


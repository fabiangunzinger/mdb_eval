"""
Produces analysis dataset.

"""

import argparse
import functools
import sys

import pandas as pd

import src.helpers.helpers as hh
import src.helpers.io as io
import src.data.aggregators as agg
import src.data.creators as cr
import src.data.selectors as sl
import src.data.validators as vl


@hh.timer
def read(filepath, **kwargs):
    return io.read_parquet(filepath, **kwargs)


@hh.timer
def aggregate_data(df):
    return pd.concat(
        (func(df) for func in agg.aggregator_funcs), axis=1, join="inner"
    ).reset_index()


@hh.timer
def create_vars(df):
    return functools.reduce(lambda df, f: f(df), cr.creator_funcs, df)


@hh.timer
def select_sample(df):
    return functools.reduce(lambda df, f: f(df), sl.selector_funcs, df)


@hh.timer
def validate_data(df):
    return functools.reduce(lambda df, f: f(df), vl.validator_funcs, df)


def parse_args(args):
    parser = argparse.ArgumentParser()
    parser.add_argument('filepath', help='File to be processed.')
    return parser.parse_args(args)


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]
    args = parse_args(argv)
    print('Reading', args.filepath)
    df = read(args.filepath)
    print('Processing')
    df = df.pipe(aggregate_data).pipe(create_vars)
    print('Writing to disk...')
    io.write_parquet(df, 's3://3di-project-eval/eval_111.parquet')

    

if __name__ == '__main__':
    main()


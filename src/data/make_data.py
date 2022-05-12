"""
Produces analysis dataset.

"""

import argparse
import functools
import os
import re
import sys

import pandas as pd

import src.helpers.data as hd
import src.helpers.helpers as hh
import src.helpers.io as io
import src.data.aggregators as agg
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
def select_sample(df):
    return functools.reduce(lambda df, f: f(df), sl.selector_funcs, df)


@hh.timer
def validate_data(df):
    return functools.reduce(lambda df, f: f(df), vl.validator_funcs, df)


def parse_args(args):
    parser = argparse.ArgumentParser()
    parser.add_argument('inpath', help='File to be read.')
    parser.add_argument('outpath', help='File to be written')
    return parser.parse_args(args)


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]
    args = parse_args(argv)
    print('Reading', args.inpath)
    df = read(args.inpath)
    print('Processing')
    df = df.pipe(aggregate_data).pipe(select_sample)
    print('Writing', args.outpath)
    io.write_parquet(df, args.outpath)

    sample = re.search(r'[X\d]{3}', args.outpath)[0]
    selection_table = hd.make_selection_table(sl.sample_counts)
    hd.write_selection_table(selection_table, sample)
    with pd.option_context("max_colwidth", 25):
        print(selection_table)


    

if __name__ == '__main__':
    main()


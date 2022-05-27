"""
Produces analysis dataset.

"""

import argparse
import collections
import concurrent
import functools
import os
import sys

import pandas as pd

import src.config as config
import src.helpers.data as hd
import src.helpers.helpers as hh
import src.helpers.io as io
import src.data.aggregators as agg
import src.data.selectors as sl
import src.data.transformers as tf
import src.data.validators as vl


TIMER_ACTIVE = True


@hh.timer(active=TIMER_ACTIVE)
def read_piece(filepath, **kwargs):
    print('Reading', filepath)
    return io.read_parquet(filepath, **kwargs)


@hh.timer(active=TIMER_ACTIVE)
def aggregate_data(df):
    return pd.concat(
        (func(df) for func in agg.aggregator_funcs), axis=1, join="inner"
    ).reset_index()


@hh.timer(active=TIMER_ACTIVE)
def select_sample(df):
    return functools.reduce(lambda df, f: f(df), sl.selector_funcs, df)


@hh.timer(active=TIMER_ACTIVE)
def clean_piece(filepath):
    df, sample_counts = read_piece(filepath).pipe(aggregate_data).pipe(select_sample)
    return df, sample_counts


@hh.timer(active=TIMER_ACTIVE)
def transform_variables(df):
    return functools.reduce(lambda df, f: f(df), tf.transformer_funcs, df)


@hh.timer(active=TIMER_ACTIVE)
def validate_data(df):
    return functools.reduce(lambda df, f: f(df), vl.validator_funcs, df)


def get_filepath(piece):
    return os.path.join(config.AWS_PIECES, f"mdb_XX{piece}.parquet")


def parse_args(args):
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--piece", help="Piece in [0,9] to process")
    return parser.parse_args(args)


@hh.timer(active=TIMER_ACTIVE)
def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]
    args = parse_args(argv)

    pieces = args.piece if args.piece else range(5)
    filepaths = [get_filepath(piece) for piece in pieces]
    frames, total_sample_counts = [], collections.Counter()

    for fp in filepaths:
        df, sample_counts = clean_piece(fp)
        frames.append(df)
        total_sample_counts.update(sample_counts)

    data = (
        pd.concat(frames)
        .reset_index(drop=True)
        .pipe(transform_variables)
        .pipe(validate_data)
    )
    fn = f"eval_XX{args.piece}.parquet" if args.piece else "eval.parquet"
    fp = os.path.join(config.AWS_PROJECT, fn)
    io.write_parquet(data, fp)

    selection_table = hd.make_selection_table(total_sample_counts)
    fp = os.path.join(config.TABDIR, "sample_selection.tex")
    hd.write_selection_table(selection_table, fp)

    with pd.option_context("max_colwidth", 25):
        print(selection_table)


if __name__ == "__main__":
    main()

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
import src.data.validators as vl


def read_piece(filepath, **kwargs):
    return io.read_parquet(filepath, **kwargs)


def aggregate_data(df):
    return pd.concat(
        (func(df) for func in agg.aggregator_funcs), axis=1, join="inner"
    ).reset_index()


def select_sample(df):
    return functools.reduce(lambda df, f: f(df), sl.selector_funcs, df)


def validate_data(df):
    return functools.reduce(lambda df, f: f(df), vl.validator_funcs, df)


@hh.timer
def clean_piece(filepath):
    # print('Reading', filepath)
    # df = read_piece(filepath)
    # print('Aggregating', filepath)
    # df = aggregate_data(df)
    # print('Selecting', filepath)
    # df, sample_counts = select_sample(df)
    # return df, sample_counts

    df, sample_counts = read_piece(filepath).pipe(aggregate_data).pipe(select_sample)
    return df, sample_counts


def get_filepath(piece):
    return os.path.join(config.AWS_PIECES, f"mdb_XX{piece}.parquet")
    # return f's3://3di-project-eval/eval_XX{piece}.parquet'


def parse_args(args):
    parser = argparse.ArgumentParser()
    parser.add_argument('-p', '--piece', help='Piece in [0,9] to process')
    return parser.parse_args(args)

def simple_task(filepath):
    print('Reading', filepath)
    df = read_piece(filepath)
    print('Returning', filepath)
    return df[:10]

@hh.timer
def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]
    args = parse_args(argv)

    pieces = args.piece if args.piece else range(5)
    filepaths = [get_filepath(piece) for piece in pieces]
    total_sample_counts = collections.Counter()
    frames = []

    with concurrent.futures.ThreadPoolExecutor() as executor:
        results = [executor.submit(clean_piece, fp) for fp in filepaths]
        for piece in concurrent.futures.as_completed(results):
            df, sample_counts = piece
            frames.append(df)
            total_sample_counts.update(sample_counts)
            print(frames)
            print(total_sample_counts)

    
        # results = executor.map(clean_piece, filepaths)
        # print('Results', results)
        # for result in results:
        #     print('Result', result)
        #     df, sample_counts = result
        #     frames.append(df)
        #     total_sample_counts.update(sample_counts)

    print('concatenating')
    df = pd.concat(frames).reset_index(drop=True)
    fp = os.path.join(config.AWS_PROJECT, "eval.parquet")
    io.write_parquet(df, fp)

    selection_table = hd.make_selection_table(total_sample_counts)
    fp = os.path.join(config.TABDIR, "sample_selection.tex")
    hd.write_selection_table(selection_table, fp)

    with pd.option_context("max_colwidth", 25):
        print(selection_table)


if __name__ == "__main__":
    main()

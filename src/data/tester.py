import asyncio
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



async def read_piece(filepath, **kwargs):
    print('Reading', filepath)
    await io.read_parquet(filepath, **kwargs)


async def main():
    fp = 's3://3di-data-mdb/clean/mdb_000.parquet'
    await asyncio.gather(read_piece(fp), read_piece(fp))


if __name__ == '__main__':
    import time
    s = time.perf_counter()
    asyncio.run(main())
    e = time.perf_counter() - s
    print(f'{__file__} executed in {e:.2f} seconds.')

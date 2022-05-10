

.PHONY: test
test:
	@python -m src.data.make_data s3://3di-data-mdb/clean/mdb_clean_111.parquet

XX1:
	@python -m src.data.make_data s3://3di-data-mdb/clean/pieces/mdb_clean_XX1.parquet




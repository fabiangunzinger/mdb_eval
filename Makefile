MDB_BUCKET := s3://3di-data-mdb
EVAL_BUCKET := s3://3di-project-eval


.PHONY: test
test:
	@python -m src.data.make_data \
		$(MDB_BUCKET)/clean/mdb_111.parquet \
		$(EVAL_BUCKET)/eval_111.parquet

XX1:
	@python -m src.data.make_data \
		$(MDB_BUCKET)/clean/pieces/mdb_XX1.parquet \
		$(EVAL_BUCKET)/eval_XX1.parquet




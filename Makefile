MDB_BUCKET := s3://3di-data-mdb
EVAL_BUCKET := s3://3di-project-eval


.PHONY: test
test:
	@printf '\n Producing project data from 111 sample...'
	@python -m src.data.make_data \
		$(MDB_BUCKET)/clean/mdb_111.parquet \
		$(EVAL_BUCKET)/eval_111.parquet

XX1:
	@printf '\n Producing project data from XX1 sample...'
	@python -m src.data.make_data \
		$(MDB_BUCKET)/clean/pieces/mdb_XX1.parquet \
		$(EVAL_BUCKET)/eval_XX1.parquet




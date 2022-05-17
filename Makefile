MDB_BUCKET := s3://3di-data-mdb
EVAL_BUCKET := s3://3di-project-eval

PIECES := XX0 XX1 XX2 XX3 XX4 XX5 XX6 XX7 XX8 XX9


.PHONY: pieces
pieces: $(PIECES)

$(PIECES):
	@printf '\nProducing project data from piece $@...\n'
	@python -m src.data.make_data \
		$(MDB_BUCKET)/clean/pieces/mdb_$@.parquet \
		$(EVAL_BUCKET)/eval_$@.parquet

.PHONY: test
test:
	@printf '\n Producing project data from 111 sample...\n'
	@python -m src.data.make_data \
		$(MDB_BUCKET)/clean/mdb_111.parquet \
		$(EVAL_BUCKET)/eval_111.parquet


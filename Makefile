MDB_BUCKET := s3://3di-data-mdb
EVAL_BUCKET := s3://3di-project-eval

PIECES := XX0 XX1 XX2 XX3 XX4 XX5 XX6 XX7 XX8 XX9



.PHONY: data
data:
	@printf '\nProducing analysis data...\n'
	@python -m src.data.make_data


.PHONY: test
test:
	@printf '\nProducing test analysis data...\n'
	@python -m src.data.make_data --piece 0


.PHONY: figures
figures:
	@Rscript src/figures/sample_description.R



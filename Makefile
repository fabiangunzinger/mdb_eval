

.PHONY: all
all: sumstats figures msg


.PHONY: sumstats
sumstats:
	@printf '\n Updating sumstats table...\n'
	@Rscript src/analysis/sumstats.R


.PHONY: figures sampdesc treathist

figures: sampdesc treathist

sampdesc:
	@printf '\n Updating sample description plots...\n'
	@Rscript src/figures/sample_description.R

treathist:
	@printf '\n Updating treatment histories plot...\n'
	@Rscript src/figures/treat_histories.R

msg:
	@printf '\n All done.\n'


.PHONY: data testdata
data:
	@printf '\nProducing analysis data...\n'
	@python -m src.data.make_data

testdata:
	@printf '\nProducing test analysis data...\n'
	@python -m src.data.make_data --piece 0


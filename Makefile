R := R_LIBS_USER=$(CURDIR)/.R/library Rscript

.PHONY: all deps run replicate audit report test lint format clean

all: run test lint

run: replicate audit report

replicate:
	$(R) src/prepare.R
	$(R) src/replicate.R
	$(R) src/compare_published.R

audit:
	$(R) src/audit_inference.R
	$(R) src/audit_functional_form.R
	$(R) src/responder_quality.R
	$(R) src/headline_numbers.R

report:
	$(R) src/figures.R
	$(R) -e 'knitr::knit("README.Rmd", output = "README.md", quiet = TRUE)'
	cd ms && $(R) -e 'knitr::knit("interpretation.Rmd", output = "interpretation.md", quiet = TRUE)'

test:
	$(R) tests/run_tests.R

lint:
	$(R) -e 'x <- lintr::lint_dir("src"); y <- lintr::lint_dir("tests"); print(c(x, y)); stopifnot(length(x) + length(y) == 0L)'

format:
	$(R) -e 'styler::cache_deactivate(); styler::style_dir("src"); styler::style_dir("tests")'

deps:
	@mkdir -p .R/library
	$(R) -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv", repos = "https://cloud.r-project.org"); renv::restore(library = ".R/library", prompt = FALSE)'

clean:
	rm -f output/* figs/* data/derived/*

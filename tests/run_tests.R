suppressPackageStartupMessages(library(testthat))
Sys.setenv(PROJECT_ROOT = getwd())
test_dir("tests", reporter = "summary", stop_on_failure = TRUE)

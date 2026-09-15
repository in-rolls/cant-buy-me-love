setwd(Sys.getenv("PROJECT_ROOT", unset = ".."))

# Every blockquote line in ms/interpretation.Rmd must occur verbatim in one of
# the two paper drafts, after normalising whitespace, curly quotes and
# end-of-line hyphenation.
normalise <- function(x) {
  x <- paste(x, collapse = "\n")
  x <- gsub("[‘’]", "'", x)
  x <- gsub("[“”]", "\"", x)
  x <- gsub("-\n", "-", x)
  x <- gsub("\\s+", " ", x)
  trimws(x)
}
sources <- vapply(
  c("sources/paper_2010_12_final_draft.txt", "sources/paper_2008_05_draft.txt"),
  function(f) normalise(readLines(f, warn = FALSE)),
  character(1)
)
draft <- readLines("ms/interpretation.Rmd", warn = FALSE)
quotes <- sub("^> ", "", grep("^> ", draft, value = TRUE))
quotes <- quotes[nzchar(trimws(quotes))]

test_that("interpretation.Rmd has quotes to check", {
  expect_gt(length(quotes), 10)
})

test_that("every quoted line appears verbatim in a paper draft", {
  for (q in quotes) {
    found <- any(vapply(sources, function(s) grepl(normalise(q), s, fixed = TRUE), logical(1)))
    expect_true(found, label = paste("quote found:", substr(q, 1, 60)))
  }
})

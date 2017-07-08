#' Import a single subject's R&A choice data from a text file exported by E-Prime.
#'
#' @param filename A full file path to a .txt file exported by E-Prime
#' @return A clean R&A data frame
#' @export
importFromEprime <- function(filename) {
  x <- read.delim(filename, skip = 1)
  x
}

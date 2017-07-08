# library(tidyverse)
# library(R.matlab)

#' Import a single subject's R&A choice data from a raw .mat file.
#'
#' Take the location of any Matlab file with information that
#' was saved by PTB-based R&A tasks prior to PsychTaskFramework
#' and returns a clean output that can be analyzed.
#' @param filename A full file path to a .mat file
#' @param substituteColor Replace the numeric reference to the
#' color of the winning probability with information about the actual color?
#' @return A clean R&A data frame
#' @import R.matlab
#' @import tidyverse
#' @export
importFromRawMat <- function(filename, substituteColor = FALSE) {
  requireNamespace('R.matlab', quietly = TRUE)
  requireNamespace('tidyverse', quietly = TRUE)
  # Usable on:
  # - Data_fMRI/MDM_Imaging/Behavior/(ID)/MDM_(domain)_(ID).mat
  # - Data_fMRI/VA_fMRI_PTB/Behavior/subj(ID)/RA_(domain)_(ID).mat

  # TODO: Extract info from filename / filepath?
  print(filename)
  x <- R.matlab::readMat(filename)
  x <- x[[1]]
  n <- length(x[,,]$vals)
  result <- data.frame(ID = rep(as.vector(x[,,]$observer), n),
                       choice = makeNA(as.vector(x[,,]$choice), n),
                       refSide = rep(as.vector(x[,,]$refSide), n),
                       winColor = as.vector(x[,,]$colors),
                       payoff = as.vector(x[,,]$vals),
                       winProb = as.vector(x[,,]$probs),
                       ambiguity = as.vector(x[,,]$ambigs),
                       # blockNum = makeNA(as.vector(x[,,]$block, n)),
                       dataSource = rep(as.vector(x[,,]$filename), n)
                       )
  if (substituteColor) {
    # grab colorKey & switch out the content of 'color'
    result <- result %>% dplyr::mutate(winColor = unlist(x[,,]$colorKey[winColor]))
  }
  return(result)
}

makeNA <- function(x, n) {
  if (length(x) == 0) {
    return(rep(NA, n))
  } else if (length(x) < n) {
    return(c(x, rep(NA, n - length(x))))
  } else {
    return(x)
  }
}

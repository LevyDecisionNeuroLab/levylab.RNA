#' Create the data directory and subdirectories
#'
#' Creates 'data/', 'data/raw', 'data/clean' and 'data/results' in the
#' directory provided or, by default, in the current working directory.
#'
#' @param directory The directory in which the data directories should be created
#' @export
#' @return Outcome of dir.create
setupDataDirectory <- function(directory = NULL) {
  if (is.null(directory)) {
    directory <- getwd()
  }
  dir.create('data')
  dir.create('data/raw')
  dir.create('data/clean')
  dir.create('data/results')
}

#' Copy the RMarkdown analysis templates into a directory
#'
#' Copy the analysis templates that were installed with the package to
#' a targetDirectory which is, by default, the analysis/ folder in the
#' current working directory. (It will be created if it does not exist
#' already.) If includeOnly is provided, then only those scripts will
#' be copied.
#'
#' @param includeOnly A vector of RMarkdown filenames
#' @param targetDirectory A subdirectory in the current working
#' directory to which the analysis files will be copied
#' @export
#' @return Outcome of file.copy
setupAnalysisTemplates <- function(targetDirectory = 'analysis/', includeOnly = NULL) {
  dir.create(targetDirectory)
  analysisDirectory <- system.file('analysis', package = "levylab.RNA")
  print(analysisDirectory)
  if (is.character(includeOnly)) {
    # copy only those in the argument
    file.copy(from = file.path(analysisDirectory, includeOnly), to = file.path(targetDirectory, includeOnly))
  } else {
    # copy all from directory
    file.copy(from = Sys.glob(file.path(analysisDirectory, '*')), to = targetDirectory)
  }
}

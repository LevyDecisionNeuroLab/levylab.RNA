% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/importFromPTF.R
\name{importFromPTF}
\alias{importFromPTF}
\title{Import R&A choice data from a CSV file generated by PsychTaskFramework}
\usage{
importFromPTF(filename, save = FALSE)
}
\arguments{
\item{filename}{A full file path to a .csv file created by PsychTaskFramework}

\item{save}{Should the function, as a side effect, save the processed file into a "clean/" directory?}
}
\value{
A clean R&A data frame
}
\description{
Import R&A choice data from a CSV file generated by PsychTaskFramework
}

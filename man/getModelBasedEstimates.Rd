% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/extractDecisionFeatures.R
\name{getModelBasedEstimates}
\alias{getModelBasedEstimates}
\title{Estimates risk and ambiguity aversion based on an MLE/subjective-value approach}
\usage{
getModelBasedEstimates(decision_data, initial_parameters = NULL)
}
\arguments{
\item{decision_data}{A clean decision data frame}

\item{initial_parameters}{3-column data frame in which each row is a
different set of initial parameters for the optimizer}
}
\value{
A data frame with alpha, beta, and gamma parameters for each subject in decision_data
}
\description{
Estimates risk and ambiguity aversion based on an MLE/subjective-value approach
}

# source('import/importFromRawMat.R')
library(levylab.RNA)
library(tidyverse)
importVA_fMRI_PTB <- function(BehaviorDirLocation = 'Z:/Levy_Lab/Data_fMRI/VA_fMRI_PTB/Behavior', outFile = 'VA_fMRI_PTB.csv') {
  files <- list.files(BehaviorDirLocation, pattern = "RA_(GAINS|LOSS)_[[:digit:]]+\\.mat", recursive = TRUE)
  files <- paste0(BehaviorDirLocation, '/', files[grep('^subj\\d+/RA', files)])

  RA <- Reduce(rbind, lapply(files, importFromRawMat))
  RA <- RA %>% mutate(payoffKind = 'monetary',
                      domain = ifelse(grepl('GAINS', dataSource), 'gains', 'loss'),
                      payoff = ifelse(grepl('GAINS', dataSource), 1, -1) * payoff)
  return(RA)
}

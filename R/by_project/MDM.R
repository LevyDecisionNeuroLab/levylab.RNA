# source('import/importFromRawMat.R')
library(levylab.RNA)
library(tidyverse)
importMDM <- function(BehaviorDirLocation = 'Z:/Levy_Lab/Data_fMRI/MDM_imaging/Behavior', outFile = 'MDM.csv') {
  files <- Sys.glob(paste0(BehaviorDirLocation, '/[0-9]*/*.mat'))
  MDM <- Reduce(rbind, lapply(files, importFromRawMat))
  MDM <- MDM %>% mutate(payoffKind = ifelse(grepl('MON', dataSource), 'monetary', 'medical'),
                        domain = ifelse(grepl('MON', dataSource), 'gains', NA))
  return(MDM)
}

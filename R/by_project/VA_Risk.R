library(stringr)
library(tidyverse)
# NOTE: There's an ID conversion going on here, right?
importRiskVA <- function(BehaviorDirLocation = 'Z:/Levy_Lab/Data_behavior/Risk_VA/Data',
                         outFile = 'RiskVA.csv', discardOriginalColumns = FALSE) {
  files <- paste0(BehaviorDirLocation, '/',
                  list.files(BehaviorDirLocation, pattern = "*.txt", recursive = FALSE))

  RiskVA <- Reduce(rbind, lapply(files, function(x) {
    out <- importRiskVAFile(x, discardOriginalColumns)
    out$dataSource <- x
    return(out)
  }))
  RiskVA <- RiskVA %>% mutate(payoffKind = 'monetary',
                      domain = ifelse(payoff > 0, 'gains', 'loss'))
  return(RiskVA)
}

importRiskVAFile <- function(filename, discardOriginalColumns = FALSE) {
  x <- read.delim(filename, skip = 1, stringsAsFactors = FALSE)
  x <- mutate(x, payoff = ifelse(BlueValue == 0, RedValue, BlueValue),
              refSide = ifelse(LotterySide == 'Left', 2, 1)) %>%
    rename(choice = choice.RESP)
  standard_cols <- getLevelsFromLotteryName(x$RiskAmbigLevel)
  ID <- as.numeric(str_match(filename, '\\d+'))
  standard_cols$ID <- ID
  x <- cbind(x, standard_cols)

  if (discardOriginalColumns) {
    x <- select(x, -Block, -TrialNum, -BagNo, -BlueValue, -RedValue, -choice.RT, -LotterySide, -RiskAmbigLevel)
  }
  return(x)
}

getLevelsFromLotteryName <- function(name) {
  level <- as.numeric(str_match(name, '\\d+$'))
  kind <- as.character(str_match(name, '^[a-z]+'))
  winColor <- gsub('_', '', as.character(str_match(name, '_[a-z]+_')))

  ambig_trials <- kind == "ambig"
  p = level / 100
  a = 0 * level

  p[ambig_trials] = 0.5
  a[ambig_trials] = level[ambig_trials] / 100

  return(data.frame(winProb = p, ambiguity = a, winColor = winColor))
}

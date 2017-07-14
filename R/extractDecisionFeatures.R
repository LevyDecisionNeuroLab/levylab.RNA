# library(dplyr)
# library(tidyr)
# library(broom)
# library(nloptr)

#' Extracts both model-free and model-based features from the decision data
#'
#' @param decision_data A clean decision data frame
#' @return A data frame which merges both model-free and model-based parameter estimates
#' @export
extractDecisionFeatures <- function (decision_data) {
    # intended to have the decision subfield of pilot data passed to it
    modelFree <- getModelFreeEstimates(decision_data)
    modelBased <- getModelBasedEstimates(decision_data)
    return(merge(modelFree, modelBased))
}

#' Estimates risk and ambiguity aversion based on an MLE/subjective-value approach
#'
#' @param decision_data A clean decision data frame
#' @param initial_parameters 3-column data frame in which each row is a
#'     different set of initial parameters for the optimizer
#' @return A data frame with alpha, beta, and gamma parameters for each subject in decision_data
#' @import nloptr
#' @import tidyverse
#' @import broom
#' @export
getModelBasedEstimates <- function(decision_data, initial_parameters = NULL) {
    # Initial parameters
    if (is.null(initial_parameters)) {
      x0 = expand.grid(seq(-5, 5, 1.5), seq(-3, 3, 1), seq(0.5, 3.5, 1))
    } else {
      x0 = initial_parameters
    }
    value_loss = 0
    # TODO: preallocate for subject number
    all_subjects <- sort(unique(decision_data$ID))
    mb_results = data.frame(ID = integer(), alpha = double(), beta = double(),
                            gamma = double(), LL = double(), iterations = integer(),
                            status = integer(), message = character(), LL = double(),
                            stringsAsFactors = FALSE)
    for (subj in all_subjects) {
        subj_choices <- decision_data[decision_data$ID == subj, ] %>%
            filter(!is.na(choice), val > 4)

        value_reference = seq(5, 5, length.out = nrow(subj_choices))
        prob_reference = seq(1, 1, length.out = nrow(subj_choices))

        subj_solution = fit_parameters(subj_choices$choice, value_reference, subj_choices$val, value_loss,
                                       prob_reference, subj_choices$p, subj_choices$al, x0) %>%
          rename(alpha = par3, beta = par2, gamma = par1, LL = value, iterations = iter, status = convergence) %>%
          mutate(ID = subj)
        mb_results <- rbind(mb_results, subj_solution)
    }
    return(mb_results)
}

#' Estimates risk and ambiguity aversion based on a model-free comparison-based approach
#'
#' @param decision_data A clean decision data frame
#' @param na.rm Should the mean measures exclude NAs (and thus return non-NA results?)
#' @return A data frame with risk_proportion, ambiguity_proportion and relative_ambiguity_proportion
#'     parameters for each subject in decision_data.
#' @import tidyverse
#' @export
getModelFreeEstimates <- function(decision_data, na.rm = TRUE) {
    # Proportion of lottery choices per subject + per probability/value combination
    mf_risk_by.level.reward <- decision_data %>%
      filter(al == 0) %>% group_by(ID, p, val) %>%
      summarize(n = n(), proportion = mean(choice, na.rm = na.rm))
    head(mf_risk_by.level.reward)

    # Proportion of lottery choices per subject per probability level (without respect to value)
    mf_risk_by.level <- mf_risk_by.level.reward %>%
      summarize(prop_p = mean(proportion, na.rm = na.rm))
    head(mf_risk_by.level)

    # Proportion of risky choices per subject (without respect to probability level)
    mf_risk_all.levels <- mf_risk_by.level %>%
      summarize(risk_prop = mean(prop_p, na.rm = na.rm))
    mf_risk_all.levels

    # Proportion of lottery choices per subject + per ambiguity/value combination
    mf_ambig_by.level.reward <- decision_data %>% filter(al > 0) %>%
      group_by(ID, al, val) %>%
      summarize(n = n(), proportion = mean(choice, na.rm = na.rm))
    head(mf_ambig_by.level.reward)

    # Proportion of ambiguous choices per subject (without respect to value)
    mf_ambig_by.level <- mf_ambig_by.level.reward %>%
      summarize(proportion = mean(proportion, na.rm = na.rm))
    head(mf_ambig_by.level)

    # What proportion of all ambiguous choices did each subject select?
    mf_ambig_all.levels <-  mf_ambig_by.level %>%
      summarize(ambig_prop = mean(proportion, na.rm = na.rm))
    mf_ambig_all.levels

    # Now, looking at proportion of choices made at different ambiguity level *relative to* choices made at p = .5
    # 1. per-subject proportion of choices at p = .5
    p05 <- filter(mf_risk_by.level, p == .5) %>% rename(p0.5 = prop_p) %>% select(-p)
    mf_relative.ambig_by.level <- merge(mf_ambig_by.level, p05, by = "ID") %>%
        mutate(diff = proportion - p0.5) %>%
        select(-proportion, -p0.5)
    head(mf_relative.ambig_by.level)

    # and without regard to ambiguity level
    mf_relative.ambig_all.levels <- group_by(mf_relative.ambig_by.level, ID) %>%
        summarize(ambig_prop_relative = mean(diff, na.rm = na.rm))
    mf_relative.ambig_all.levels

    # Pulling it together per subject
    mf_results <- merge(mf_risk_all.levels, mf_ambig_all.levels, by = "ID")
    mf_results <- merge(mf_results, mf_relative.ambig_all.levels, by = "ID")
    return(mf_results)
}


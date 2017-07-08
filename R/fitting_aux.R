library(nloptr)

fit_parameters <- function(choice, value_reference, value_win, value_loss, prob_reference, prob_win, ambigs, initial_parameters) {
  # Current status: works splendidly for gains, doesn't work at all for losses
  # TODO: Re-formulate to use general nloptr() call, try a different algorithm
  # TODO: Try IPOPT
  if (is.data.frame(initial_parameters)) {
    results <- initial_parameters %>% rowwise() %>% do({
      fit_parameters(choice, value_reference, value_win, value_loss, prob_reference,
                     prob_win, ambigs, c(.[[1]], .[[2]], .[[3]]))
      }) #%>%
    results <- results %>% ungroup() %>% filter(value == min(value)) %>% slice(1)
    return(results)
  } else {
    solution = lbfgs(initial_parameters, neg_LL,
                     lower = c(-Inf, -3.67, .0894), upper = c(Inf, 4, 4.34),
                     nl.info = FALSE, control = list("xtol_rel" = 0, "ftol_rel" = 0, "ftol_abs" = 0),
                     prob_reference = prob_reference, value_reference = value_reference, value_win = value_win,
                     value_loss = value_loss, prob_win = prob_win, ambigs = ambigs, choice = choice)
    pars = Reduce(data.frame, solution$par)
    names(pars) <- paste0('par', 1:3)
    solution$par <- NULL
    return(cbind(pars, as.data.frame(solution)))
  }
}

# Negative likelihood function
neg_LL <- function(params, choice, value_reference, value_win, prob_reference, prob_win, ambigs, value_loss) {
  predicted_p = logit_choice_prob(value_loss, value_reference, value_win, prob_reference, prob_win, ambigs, params)

#   cat("params", params, "\r\n")
#   cat("choice", choice, "\r\n")
#   cat("value_reference", value_reference, "\r\n")
#   cat("value_win", value_win, "\r\n")
#   cat("prob_reference", prob_reference, "\r\n")
#   cat("prob_win", prob_win, "\r\n")
#   cat("ambigs", ambigs, "\r\n")
#   cat("value_loss", value_loss, "\r\n")
#   cat(predicted_p, "\r\n")

  # Prevent undefined
  ind = predicted_p == 1
  predicted_p[ind] = .9999
  ind = predicted_p == 0
  predicted_p[ind] = .0001

  # Log likelihood
  errors = (choice == 1) * log(predicted_p) + (1 - (choice == 1)) * log(1 - predicted_p)
  return(-sum(errors))
}

logit_choice_prob <- function(value_loss, value_reference, value_win, prob_reference, prob_win, ambigs, params) {
  alpha = params[3]
  beta = params[2]
  gamma = params[1]

  uF = getSV(value_loss, value_reference, prob_reference,
             seq(0, 0, length.out = length(value_reference)),
             alpha, beta)
  uA = getSV(value_loss, value_win, prob_win,
             ambigs,
             alpha, beta)

  return(1 / (1 + exp(gamma * (uA - uF))))
}

getSV <- function(value_loss, values, probs, ambigs, alpha, beta) {
  SV = (probs - beta * (ambigs / 2)) * values ^ alpha +
    ((1 - probs) - beta * (ambigs / 2)) * value_loss ^ alpha
  # + ((1 - p) - beta .* (AL ./ 2)) .* base .^ alpha;
  return(SV)
}

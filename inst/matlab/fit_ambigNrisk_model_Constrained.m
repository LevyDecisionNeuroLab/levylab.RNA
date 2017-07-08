% FIT_AMBIGNRISK_MODEL      Fit a variety of probabilistic ambiguity models
% 
%     [info, p] = fit_ambigNrisk_model(choice, vF, vA, pF, pA, AL, model, b0, base, constrain);
%
%     Fits a binary logit model by maximum likelihood. For constrained fits,
%     the MATLAB optimization package is required.
%
%     INPUTS
%     choice      - Dependent variable. The data should be *ungrouped*,
%                   such that CHOICE is a column of 0s and 1s, where 1 indicates 
%                   a choice of the FIXED option.
%     vF          - value of fixed lottery
%     vA          - value of ambiguous lottery
%     pF          - probability of fixed lottery
%     pA          - probability of ambiguous lottery
%     AL          - ambiguity level
%     model       - String indicating which SV model to fit; currently valid are:
%                   'ambigNrisk' - power with subjective probability, estimates 
%                                  both risk and ambiguity coefficients 
%
%                   Multiple models can be fit by passing in a cell array
%                   of strings. 
%     b0          - Initial values to begin minimization search
%     base        - loss value of lottery (typically 0), passed onto minimized functions
%     constrain   - binary (0/1) choice of whether to use constraining minimizer or not
%                    
%     OUTPUTS
%     info       - data structure with following fields:
%                     .nobs      - number of observations
%                     .nb        - number of parameters
%                     .optimizer - function minimizer used
%                     .exitflag  - see FMINSEARCH
%                     .b         - fitted parameters; note that for all the
%                                  available models, the first element of B
%                                  is a noise term for the logistic
%                                  function, the remaining elements are
%                                  parameters for the selected discount
%                                  functions. eg., for model='exp', B(2) is
%                                  the time constant of the exponential
%                                  decay.
%                     .LL        - log-likelihood evaluated at maximum
%                     .LL0       - restricted (minimal model) log-likelihood
%                     .AIC       - Akaike's Information Criterion 
%                     .BIC       - Schwartz's Bayesian Information Criterion 
%                     .r2        - pseudo r-squared
%                   This is a struct array if multiple models are fit.
%     p           - Estimated choice probabilities evaluated at the values
%                   delays specified by the inputs vS, vR, dS, dL. This is
%                   a cell array if multiple models are fit.
%
%     EXAMPLES
%     see TEST_FAKE_DATA_AMBIGUITTY, TEST_FAKE_DATA, TEST_JOE_DATA, and TEST_KENWAY_DATA
%
%
%     REVISION HISTORY:
%     brian 03.10.06 written
%     brian 03.14.06 added fallback to FMINSEARCH, multiple fit capability
%     ifat  12.01.06 adapted for ambiguity and risk + CI
%     Simon 2016/3/9 re-documented and added logic for constrained coefficients

function [info, p] = fit_ambigNrisk_model_Constrained(choice, vF, vA, pF, pA, AL, model, b0, base, constrain)
% If multiple model fits requested, loop and pack
if iscell(model)
   for i = 1:length(model)
      [info(i), p{i}] = fit_ambigNrisk_model(choice, vF, vA, pF, pA, AL, model{i}, b0, base, constrain);
   end
   return;
end

thresh = 0.05;
nobs = length(choice);

% Compute coefficients without constraint, using `fminunc` or `fminsearch`
if ~constrain
  % Fit model, attempting to use FMINUNC first, then falling back to FMINSEARCH
  if exist('fminunc', 'file')
    try
      optimizer = 'fminunc';
      OPTIONS = optimset('Display', 'off', 'LargeScale', 'off', ...
        'TolCon', 1e-7, 'TolFun', 1e-7, 'TolX', 1e-7, 'DiffMinChange', 1e-7, ...
        'Maxiter', 100000, 'MaxFunEvals', 80000);
      [b, negLL, exitflag, convg, g, H] = ...
        fminunc(@local_negLL, b0, OPTIONS, choice, vF, vA, pF, pA, AL, model, base);
      % TODO: Why doesn't fminunc converge, ever?

      if exitflag ~= 1 % trap occasional linesearch failures
        optimizer = 'fminsearch';
        fprintf('Unconstrained (FMINUNC): FAILED to converge, switching to FMINSEARCH; #iterations = %g, flag %d\n', convg.iterations, exitflag);
      else
        fprintf('Unconstrained (FMINUNC): Optimization CONVERGED, #iterations = %g\n', ...
          convg.iterations);
      end
    catch
       optimizer = 'fminsearch';
       fprintf('Unconstrained: Problem using FMINUNC, switching to FMINSEARCH\n');
    end
  else
     optimizer = 'fminsearch';
  end

  if strcmp(optimizer,'fminsearch')
    optimizer = 'fminsearch';
    OPTIONS = optimset('Display', 'off', 'TolCon', 1e-6, 'TolFun', 1e-5, ...
      'TolX', 1e-8, 'DiffMinChange', 1e-8, 'MaxIter', 100000, 'MaxFunEvals', 20000);
    [b, negLL, exitflag, convg] = ...
      fminsearch(@local_negLL, b0, OPTIONS, ...
      choice, vF, vA, pF, pA, AL, model, base);

    if exitflag ~= 1
      fprintf('Unconstrained (FMINSEARCH): Optimization FAILED, #iterations = %g\n', convg.iterations);
    else
      fprintf('Unconstrained (FMINSEARCH): Optimization CONVERGED, #iterations = %g\n', convg.iterations);
    end
  end
else % Constrain coefficients
  % TODO: Allow fmincon parameters to be changed via parameter in function call
  optimizer = 'fmincon';
  OPTIONS = optimset('Display', 'off', 'TolCon', 1e-6, 'TolFun', 1e-5, ...
  'TolX', 1e-8, 'DiffMinChange', 1e-8, 'MaxIter', 100000, 'MaxFunEvals', 20000);

  % Constraint 1: A * x <= B (set to [] if no inequality exists)
  A = [];
  B = [];

  % Constraint 2: Aeq * x = Beq (set either to [] if no equality exists)
  Aeq = [];
  Beq = [];

  % Constraint 3: lb < x < ub (i.e. lower bound < x < upper bound). 
  % Where unbounded, set to Inf.
  lb = [-inf -3.67 .0894];
  ub = [inf 4 4.34];
  % NOTE: gamma varies unboundedly, beta between -3.67 and 4, 
  %  alpha between .0894 and 4.34

  % Constraint 4: non-linear constraint function returning c(x) and ceq(x)
  % s.t. c(x) <= 0 and ceq(x) = 0 for all x. Set to string fn name or fn handle.
  nonlcon = [];

  [b, negLL, exitflag, convg] = ...
    fmincon(@local_negLL, b0, A, B, Aeq, Beq, lb, ub, nonlcon, OPTIONS, ...
      choice, vF, vA, pF, pA, AL, model, base);
  if exitflag ~= 1
     fprintf('Constrained:   Optimization FAILED, #iterations = %g, flag %d\n', convg.iterations, exitflag);
  else
     fprintf('Constrained:   Optimization CONVERGED, #iterations = %g\n', convg.iterations);
  end
end

% Choice probabilities (for VARIED)
p = logit_choice_prob(base, vF, vA, pF, pA, AL, b, model);

% Unrestricted log-likelihood
LL = -negLL;
% Restricted log-likelihood
LL0 = sum((choice==1).*log(0.5) + (1 - (choice==1)).*log(0.5));

% Confidence interval, requires Hessian from FMINUNC
try
    invH = inv(-H);
    se = sqrt(diag(-invH));
catch
end

%% Save in output variable
info.nobs = nobs;
info.nb = length(b);
info.model = model;
info.optimizer = optimizer;
info.exitflag = exitflag;
info.b = b;

try
    info.se = se;
    info.ci = [b-se*norminv(1-thresh/2) b+se*norminv(1-thresh/2)]; % Wald confidence
    info.tstat = b./se;
catch
end

info.LL = LL;
info.LL0 = LL0;
info.AIC = -2*LL + 2*length(b);
info.BIC = -2*LL + length(b)*log(nobs);
info.r2 = 1 - LL/LL0;
end

%----- LOCAL FUNCTIONS
% Negative log-likelihood of logistic choice probability function
function sumerr = local_negLL(beta, choice, vF, vA, pF, pA, AL, model, base)
p = logit_choice_prob(base, vF, vA, pF, pA, AL, beta, model);

% Trap log(0)
ind = p == 1;
p(ind) = 0.9999;
ind = p == 0;
p(ind) = 0.0001;
% Log-likelihood
err = (choice==1).*log(p) + (1 - (choice==1)).*log(1-p);
% Sum of -log-likelihood
sumerr = -sum(err);
end

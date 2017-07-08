function y = getSubjValue(base,v,p,AL,alpha,beta,model);
% Calculates a subjective value for given value, its risk + ambiguity, the
% subject's aversions (alpha + beta), using specified model
%
% base = payoff if subject loses lottery
% v = payoff if subject wins lottery
% p = probability of winning the lottery
% AL = ambiguity in the lottery
% alpha = "risk aversion" coefficient
% beta  = "ambiguity aversion" coefficient
% model = which SV functio to use

% the model we are using
if (strcmp(model,'ambiguity') || ...
        strcmp(model,'ambigNrisk')) || ...
        strcmp(model,'ambigNriskFixSlope')
    
    % U(x) = -U(-x) for x < 0
    negs = v < 0;
    v(negs) = -v(negs);
    v_alpha = v .^ alpha;
    v_alpha(negs) = -v_alpha(negs);

    y = (p - beta .* (AL ./ 2)) .* v_alpha ...
        + ((1 - p) - beta .* (AL ./ 2)) .* base .^ alpha;
elseif strcmp(model,'ambigPower')
    y = p .^ (1+beta.*AL) .* v .^alpha; % change that
elseif strcmp(model,'discounting')
    %y = v ./ (1 + alpha.*log(1+(1-p+beta.*AL./2)./(p-beta.*AL./2)));
    y = v ./ (1 + alpha.*(1-p+beta.*AL./2)./(p-beta.*AL./2));
    %y = v ./ (1 + alpha.*(1-p)./p);
end



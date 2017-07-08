% NOTE: Requires MATLAB optim library

%% Set up loading + subject selection
% root = 'Z:\Levy_Lab\Data_fMRI\VA_fMRI_PTB\';
% root = 'C:\Users\sp576\Desktop\VA_RA_PTB\';
root = '~/Box Sync/VA_RA_PTB/';
data_path = fullfile(root, 'Behavior'); % root of folders is sufficient
fitpar_out_path = fullfile(root, 'Behavior_fitpar');

addpath(genpath(data_path));

% Load subjects
exclude = [77:81 95]; % TEMPORARY: subjects incomplete data (that the script is not ready for)
subjects = getSubjectsInDir(data_path, 'subj');
subjects = subjects(~ismember(subjects, exclude));

% Parameters: Calculate constrained, unconstrained, or both?
parameterType = {'constrained', 'unconstrained'};

% Loss domain computation: pass negative reference + lottery values?
passNegValues = 0; % set to 1 if loss domain flips arguments to SV computation

%%
for subj_idx = 1:length(subjects)
  domains = {'GAINS', 'LOSS'};

  for domain_idx = 1:length(domains)
    subjectNum = subjects(subj_idx);
    domain = domains{domain_idx};
    is_loss = strcmp(domain, 'LOSS');
    
    fname = sprintf('RA_%s_%d.mat', domain, subjectNum);
    load(fname) % produces variable `Data`
    
    %% Refine variables
    choseLottery = Data.choice;
    
    % Mark non-responses as NaN
    choseLottery(choseLottery == 0) = NaN;
    
    % Side with lottery is counterbalanced across subjects 
    % -> code 0 as reference choice, 1 as lottery choice
    if Data.refSide == 2
      choseLottery(choseLottery == 1) = 1;
      choseLottery(choseLottery == 2) = 0;
    elseif Data.refSide == 1
      choseLottery(choseLottery == 1) = 0;
      choseLottery(choseLottery == 2) = 1;
    else
      error('refSide not defined or not within acceptable range')
    end
      
    % For aversion calculations, exclude non-responses and test questions 
    % (where stochastic dominance occurs)
    include_indices = and(Data.choice ~= 0, Data.vals' ~= 4);

    choice = choseLottery(include_indices);
    values = Data.vals(include_indices);
    ambigs = Data.ambigs(include_indices);
    probs  = Data.probs(include_indices);
    
    %% Prepare variables for model fitting & fit the model
    fixed_valueP = 5; % Value of fixed reward
    fixed_prob = 1;   % Probability of receiving the fixed reward
    ambig = unique(ambigs(ambigs > 0)); % All non-zero ambiguity levels 
    prob = unique(probs); % All probability levels
    base = 0; % Value of lottery loss

    model = 'ambigNrisk';
    b0 = [-1 .5 .5]'; % Initial point of logit fn evaluation: gamma alpha beta
    refVal = fixed_valueP * ones(length(choice), 1);
    refProb = fixed_prob  * ones(length(choice), 1);

    % TODO: If we skip this, how does this translate alpha? Alternatively,
    % can we do this *after* fitting?
    if is_loss && passNegValues
      values = -1 * values;
      refVal = -1 * refVal;
    end
    
    % Get fits into MLE struct with field for each parameterType
    for parameter_idx = 1:length(parameterType)
      parameterStr = parameterType{parameter_idx};
      isConstrained = strcmp(parameterStr, 'constrained');
      [MLE.(parameterStr), p] = fit_ambigNrisk_model_Constrained(choice, ...
        refVal', ...
        values', ...
        refProb', ...
        probs', ...
        ambigs', ...
        model, ...
        b0, ...
        base, ...
        isConstrained);
    
      MLE.(parameterStr).alpha = MLE.(parameterStr).b(3);
      MLE.(parameterStr).beta  = MLE.(parameterStr).b(2);
      MLE.(parameterStr).gamma = MLE.(parameterStr).b(1);

      % Save SV for calculated coefficients
      % Grabbing directly from Data object because SV does not rely on subject choice
      SV.(parameterStr) = getSubjValue(base, Data.vals, Data.probs, Data.ambigs, ...
        MLE.(parameterStr).alpha, MLE.(parameterStr).beta, 'ambigNrisk');

      % Flip value
      if is_loss
        SV.(parameterStr) = -1 * SV.(parameterStr);
      end
    end
    
    %% Create choice matrices

    % One matrix per condition. Matrix values are binary (0 for sure
    % choice, 1 for lottery). Matrix dimensions are prob/ambig-level
    % x payoff values. Used for graphing and some Excel exports.

    % Inputs: 
    %  Data
    %   .values, .ambigs, .probs, .choices (filtered by include_indices and transformed)
    %  ambig, prob (which are subsets of ambigs and probs, ran through `unique`)
    %
    % Outputs:
    %  ambigChoicesP
    %  riskyChoicesP
    %
    % Side-effects:
    %  one graph generated per-subject-domain
    %  .ambigChoicesP and .riskyChoicesP saved into `fitpar` file

    % Ambiguity levels by payoff values
    valueP = unique(values(ambigs > 0)); % each lottery payoff value under ambiguity
    ambigChoicesP = zeros(length(ambig), length(valueP)); % each row an ambiguity level
    for i = 1:length(ambig)
        for j = 1:length(valueP)
            selection = find(ambigs == ambig(i) & values == valueP(j));
            if ~isempty(selection)
                ambigChoicesP(i, j) = choice(selection);
            else
                ambigChoicesP(i, j) = NaN;
            end
        end
    end
    
    %% Create riskyChoicesP
    % Risk levels by payoff values
    valueP = unique(values(ambigs == 0));
    riskyChoicesP = zeros(length(prob), length(valueP));
    for i = 1:length(prob)
        for j = 1:length(valueP)
            selection = find(probs == prob(i) & values == valueP(j) & ambigs == 0);
            if ~isempty(selection)
                riskyChoicesP(i, j) = choice(selection);
            else
                riskyChoicesP(i, j) = NaN;
            end
        end
    end
    
    %% Save generated values
    Data.riskyChoices = riskyChoicesP;
    Data.ambigChoices = ambigChoicesP;
    
    Data.choseLottery = choseLottery; % normalized choices
    
    Data.MLE = MLE;
    Data.SV = SV;
    
    % TODO: Remove reliance on Data.(coeff) in follow-up scripts
    Data.alpha = MLE.(parameterType{1}).b(3);
    Data.beta = MLE.(parameterType{1}).b(2);
    Data.gamma = MLE.(parameterType{1}).b(1);

    save(fullfile(fitpar_out_path, ['RA_' domain '_' num2str(subjectNum) '_fitpar.mat']), 'Data')
  end
end

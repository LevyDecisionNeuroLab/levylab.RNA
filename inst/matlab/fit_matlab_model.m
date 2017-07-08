processed_data = 'data\processed\decision.csv';
results = 'data\processed\decision_matlab.csv';
[ id, choice, probs, ambigs, rewards ] = read_processed_data(processed_data);

refVals = 5 * (ones(length(id), 1));
refProb = ones(length(id), 1);
base = 0;

SV_model = 'ambigNrisk';
constrained = true;

alpha_init = 0.5;
beta_init = 0.5;
gamma_init = -1;
initial_evaluation_point = [gamma_init, alpha_init, beta_init];

% for loop;
subjects = unique(id)';
for s = subjects
    select_indices = id == s;
    [MLE, p] = fit_ambigNrisk_model_Constrained(...
        choice(select_indices), ...
        refVals(select_indices), ...
        rewards(select_indices), ...
        refProb(select_indices), ...
        probs(select_indices), ...
        ambigs(select_indices), ...
        SV_model, ...
        initial_evaluation_point, ...
        base, ...
        constrained);
   MLE.id = s;
   MLE.alpha = MLE.b(3);
   MLE.beta  = MLE.b(2);
   MLE.gamma = MLE.b(1);
   if exist('MLEs', 'var')
       MLEs = [MLEs; MLE];
   else
       MLEs = MLE;
   end
end

%% Save
writetable(struct2table(MLEs), results);

%% Auxilliary
function [ id, choice, probs, ambigs, reward ] = read_processed_data(filename)
x = readtable(filename)
id = x.ID(:);
choice = x.choice(:);
probs = x.p(:);
ambigs = x.al(:);
reward = x.val(:);
end
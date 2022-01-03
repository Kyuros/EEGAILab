function perf = train_svm(x,labels,pval,cv1,fold,repeat,out_dir,unitag,feature_sel,save_result)
%% Train an SVM model
% PURPOSE: Training a LIBSVM model with optional feature selection.
%
%   Kyle See 7/1/2021
%   Smart Medical Informatics Learning and Evaluation (SMILE)
%   Biomedical Engineering, University of Florida
%
%   Input:
%       x             - 2D matrix of features. Rows must be subjects and
%                       columns must be features.
%       labels        - 1D vector of labels. Must be a vector of 1 and -1.
%       pval          - Positive number for p-value.
%       cv1           - Cross-validation partition. [cvpartition]
%       fold          - Positive integer for number of folds.
%       repeat        - Positive integer for number of iterations.
%       out_dir       - Output path for saving the SVM model.
%       unitag        - Date string for when the model ran. [datestr]
%       feature_sel   - ['N'|'Y'] 'N' indicates to not use feature
%                       selection. 'Y' indicates to use feature selection.
%       save_result   - ['N'|'Y'] 'N' indicates to not save the model. 'Y'
%                       indicates to save the model results.
%
%   Output:
%       perf          - Model output including the following:
%                           - x_sel: data after feature selection
%                           - labels: same as input, labels
%                           - model: SVM model with optimal C
%                           - weights: weights from SVM model
%                           - testIdx: testing indices
%                           - y_test: labels for testing
%                           - acc_train: accuracy from training
%                           - ypred_test: predicted test labels
%                           - train_score: SVM score for training
%                           - test_score: SVM score for testing
%                           - acc_test: accuracy from testing
%                           - C: optimal C used in SVM
%
%   Dependencies:
%       LIBSVM-3.24
%
%---------------------------------------------
% Last Updated: 7/1/21
% - 7/1 Created

%% Code - SVM Model
% Create directories for each fold
if save_result == 'Y'
    spmDir = fullfile(out_dir,['outerfold_' num2str(repeat)],['innerfold_' num2str(fold)]);
    if ~exist(spmDir,'dir')
        mkdir(spmDir) % Create Output Save Folders
    end
end

% Train/Test indices
train_ind = cv1.training(fold);
test_ind = cv1.test(fold);

% Normalize data using training mean and standard deviation
scale_mean = mean(x(train_ind,:),1);
scale_std = std(x(train_ind,:),0,1);
x(train_ind,:) = (x(train_ind,:) - scale_mean) ./ scale_std;
x(test_ind,:) = (x(test_ind,:) - scale_mean) ./ scale_std;

% x(train_ind,:) = normalize(x(train_ind,:),1,'range',[-1 1]);
% x(test_ind,:) = normalize(x(test_ind,:),1,'range',[-1 1]);

% Feature selection with t-test
if feature_sel == 1
    [~,p] = ttest2(x(labels(train_ind) == 1,:), x(labels(train_ind) == 0,:));
    features = (p < pval);
    x_sel = x(:,features==1);
else
    x_sel = x;
end

% C parameter in SVM
C = [0.001 0.01 0.1 1 10 100];
C_val = zeros(2,length(C))';

% Iterate through each C
for ii = 1:length(C)
    % Train model
    model = svmtrain(labels,x_sel,['-t 0 -h 0 -q -c ' num2str(C(ii))]);
    
    % Training performance
    [ypred_train, tempacc, train_score] = svmpredict(labels(train_ind), x_sel(train_ind,:),model,['-q']);
    
    % Test performance
    [ypred_test,~,test_score] = svmpredict(labels(test_ind), x_sel(test_ind,:),model,['-q']);
    
    % Save performance for best C
    C_val(ii,1) = C(ii);
    C_val(ii,2) = tempacc(1);
end

% Determine optimal C
[~,c_idx] = max(C_val(:,2));
C_optimal = C(c_idx);

% Train model with optimal C
model = svmtrain(labels,x_sel,['-t 0 -h 0 -q -c ' num2str(C_optimal)]);
[ypred_train,~,train_score] = svmpredict(labels(train_ind), x_sel(train_ind,:),model,['-q']);
[ypred_test,accuracy,test_score] = svmpredict(labels(test_ind), x_sel(test_ind,:),model,['-q']);

%% Saving output
perf.x_sel = x_sel;
perf.labels = labels;
perf.model = model;
perf.weights = (model.sv_coef' * full(model.SVs));
perf.testIdx = test_ind;
perf.y_test = labels(test_ind);
perf.acc_train = mean(labels(~test_ind) == ypred_train);
perf.ypred_test = ypred_test;
perf.train_score = train_score;
perf.test_score = test_score;
perf.acc_test = accuracy(1)/100;
perf.C = C_optimal;

if save_result == 'Y'
    saveDir = fullfile(out_dir,['outerfold_' num2str(repeat)],['innerfold_' num2str(fold)]);
    save(fullfile(saveDir,['model.mat']),'perf')
end
end
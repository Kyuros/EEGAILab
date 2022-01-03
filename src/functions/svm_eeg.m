function [] = svm_eeg(input_path,output_path,labels,N,n_fold,feature_sel,pval,overwrite)
%% SVM EEG Channel Classification (Stage2 -> Stage3)
% PURPOSE: Perform n-fold nested cross validation with LIBSVM on EEG
% frequencies across every powerband (All: 1-100Hz, Delta: 1-4Hz, Theta:
% 4-8Hz, Alpha: 8-13Hz, Beta: 13-30Hz, Gamma: 30-100Hz). Creates a final
% model using All data to extract weights for specific frequencies. RNG is
% fixed to default.
%
%   Kyle See 7/1/2021
%   Smart Medical Informatics Learning and Evaluation (SMILE)
%   Biomedical Engineering, University of Florida
%
%   Input:
%       input_path   - Path containing .xlsx file of features.
%       output_path  - Path to save model results.
%       labels       - 1D vector of labels to be used in binary
%                      classification. Must be a vector of 1 and -1.
%
%       Optional Arguments
%       N            - Positive integer for number of iterations. Default
%                      is 10.
%       n_fold       - Positive integer for number of folds. Default is 3.
%       feature_sel  - ['N'|'Y'] 'N' indicates to not use feature
%                      feature selection. 'Y' indicates to use feature
%                      selection t-test. Requires a p-value to use.
%                      Default is 'N'.
%       pval         - Positive number for p-value. Default is 1.
%       overwrite   - ['N'|'Y'] 'N' indicates do not overwrite. 'Y'
%                     indicates to overwrite if output file exists. Default
%                     is 'N'.
%
%   Output:
%       Folder structure containing the entire training process:
%       [] - Indicates folders
%       \\ - Indicates a file
%       -------------------------------------
%       [output_path]
%           [outerfold_x]*
%               [innerfold_y]**
%                   \model.mat\
%           \acc.mat\
%           \final_model.mat\
%       -------------------------------------
%       model.mat: contains various model results. Descriptions for each
%                variable is in the train_svm.m file.
%       acc.mat: gives the accuracy and confidence intervals for training
%                and testing.
%       final_model.mat: the final trained SVM model.
%
%       *outerfold has N many folders numbered with x
%       **innerfold has n_fold many folders numbered with y
%
%   Dependencies:
%       LIBSVM-3.24
%
%---------------------------------------------
% Last Updated: 7/1/21
% - 7/1 Created
% - 7/21 Removed band preference. Now performs SVM using every band.

%% Checking inputs and initializing variables
% Check for iterations
if ~exist('N','var')
    N = 10;
elseif  N <= 0 && floor(N) ~= N
    error("N is not a positive integer. N is %d",N)
end

% Check for number of folds
if ~exist('n_fold','var')
    n_fold = 3;
elseif n_fold <= 0 && floor(n_fold) ~= n_fold
    error("n_fold is not a positive integer")
end

% Check for feature selection
if ~exist('feature_sel','var')
    feature_sel = 'N';
elseif feature_sel ~= 'Y' && feature_sel ~= 'N'
    error("Expecting feature_sel to be 'N' or 'Y'")
end

% Check p-value
if ~exist('pval','var') || strcmp(feature_sel,'N')
    pval = 1;
elseif pval < 0
    error("pval is not a positive number")
end

% Save the results
if ~exist('overwrite','var')
    overwrite = 'N';
elseif overwrite ~= 'N' && overwrite ~= 'Y'
    error("Expected save_result to be 'N' or 'Y'")
end

% Initialize variables
acc_train = zeros(N, n_fold); % Training accuracy
acc_test = zeros(N, n_fold); % Testing accuracy
C = zeros(N, n_fold); % C variable in LIBSVM
unitag = datestr(now,30); % Unitag
bands = ["All", "Delta", "Theta", "Alpha", "Beta" ,"Gamma"];

%% Selecting powerband
% Extract x
folder_data = dir(input_path);
file = folder_data(3).name;
data = readtable(fullfile(input_path,file));
x = data{:,2:end};

% Changes to column vector
if isrow(labels)
    labels = labels';
end

% Repeat for each band
for i = 1:6
    % Band selection
    if strcmp(bands(i),'Delta')
        X = x(:,1:4);
    elseif strcmp(bands(i),'Theta')
        X = x(:,4:8);
    elseif strcmp(bands(i),'Alpha')
        X = x(:,8:13);
    elseif strcmp(bands(i),'Beta')
        X = x(:,13:30);
    elseif strcmp(bands(i),'Gamma')
        X = x(:,30:end);
    else
        X = x;
    end
    
    % Expected Band output path
    output_path_band = fullfile(output_path,bands(i));
    
    % Create folder if it does not exist
    if ~exist(output_path_band,'dir')
        mkdir(output_path_band)
    end
    
%% Machine learning model
    rng default
    % Repeat for N iterations
    for repeat = 1:N
        cv1 = cvpartition(labels,'Kfold',n_fold,'Stratify',true); % Redefines CV per iteration
        
        % Repeat for n_folds
        for fold = 1:n_fold
            
            % Train SVM
            perf = train_svm(X,labels,pval,cv1,fold,repeat,output_path_band,unitag,feature_sel,overwrite);
            
            % Collect results
            acc_train(repeat,fold) = perf.acc_train;
            acc_test(repeat,fold) = perf.acc_test;
            C(repeat,fold) = perf.C;
            
            if fold == 1
                targs = perf.labels(perf.testIdx);
                preds = perf.ypred_test;
            else
                targs = [targs; perf.labels(perf.testIdx)];
                preds = [preds; perf.ypred_test];
            end
        end
        
        % Metrics
        TP(repeat) = sum(targs == 1 & preds == 1); % True Positive
        FP(repeat) = sum(targs == -1 & preds == 1); % False Positive
        TN(repeat) = sum(targs == -1 & preds == -1); % True Negative
        FN(repeat) = sum(targs == 1 & preds == -1); % False Negative
    end
    
    % Save Output
    output.acc_train = acc_train;
    output.avg_acc_train = mean(mean(acc_train));
    output.acc_test = acc_test;
    output.avg_acc_test = mean(mean(acc_test));
    
    % Average Accuracy + 95% Conf Interval
    ACC_train = reshape(acc_train, [(N*n_fold) 1]);
    ACC_test = reshape(acc_test, [(N*n_fold) 1]);
    cip_train = mean(ACC_train) + (1.96*(std(ACC_train)/sqrt(length(ACC_train))));
    cin_train = mean(ACC_train) - (1.96*(std(ACC_train)/sqrt(length(ACC_train))));
    cip_test = mean(ACC_test) + (1.96*(std(ACC_test)/sqrt(length(ACC_test))));
    cin_test = mean(ACC_test) - (1.96*(std(ACC_test)/sqrt(length(ACC_test))));
    
    % Save + Print Results
    Accuracy_train = mean(ACC_train);
    Accuracy_test = mean(ACC_test);
    Acc = mean(acc_test,2)';
    C_optimal = mode(mode(C));
    
    if overwrite == 'Y'
        save(fullfile(output_path_band,['acc.mat']),'cin_train','cip_train','Accuracy_train','cin_test','cip_test','Accuracy_test','acc_train','acc_test')
    end
    
    fprintf('Repeated Nested Cross-Validation Results\n')
    fprintf('Train Accuracy CI: [%.2f%% - %.2f%%]\n', cin_train*100, cip_train*100);
    fprintf('Train Accuracy: %.2f\n', Accuracy_train*100);
    fprintf('Test Accuracy CI: [%.2f%% - %.2f%%]\n', cin_test*100, cip_test*100);
    fprintf('Test Accuracy: %.2f\n\n', Accuracy_test*100);
    
%% Final Model
    % Feature Selection
    if feature_sel == 1
        [~,p] = ttest2(X(labels == 1,:), X(labels == 0,:));
        features = (p < pval)';
        X = X(:,features==1);
    end
    
    % Normalize data
    X = (X - mean(X,1)) ./ std(X,0,1);
    model = svmtrain(labels,X,['-t 0 -h 1 -q -c ', num2str(C_optimal)]);
 
%% Saving Results
    if overwrite == 'Y'
        if feature_sel == 1
            save(fullfile(output_path_band,'final_model.mat'),'model','feature_sel')
        else
            save(fullfile(output_path_band,'final_model.mat'),'model')
        end
    end
end
%% Find component weights from CV
band_path = dir(output_path);

% Iterate through each Powerband Folder
for ii = 3:length(band_path)
    
    % Create directory for iterations
    Outer_name = strcat(output_path,band_path(ii).name); % Name for powerband folder
    Outer_storage = dir(Outer_name); % Directory for powerband folder
    
    % Reset weight vector before new band
    weight = [];
    
    % Iterate through each iteration
    for jj = 6:length(Outer_storage) % Assumes acc,cross_val,and final are in the folder
        
        % Create directory for cv folds
        Inner_name = strcat(Outer_name,'\',Outer_storage(jj).name);
        Inner_storage = dir(Inner_name);
        
        % Iterate through each cv fold
        for kk = 3:length(Inner_storage)
            
            % Load model for a single fold
            Model_name = strcat(Inner_name,'\',Inner_storage(kk).name,'\model.mat');
            load(Model_name)
            
            % Create or append existing weight
            if strcmp(band_path(ii).name,'All')
                if jj == 6 && kk == 3
                    % Initialize weight
                    weight = perf.weights;
                else
                    % Take average of weights
                    weight = (weight+perf.weights)/2;
                end
            elseif strcmp(band_path(ii).name,'Alpha')
                if jj == 6 && kk == 3
                    weight = perf.weights;
                else
                    weight = (weight+perf.weights)/2;
                end
            elseif strcmp(band_path(ii).name,'Beta')
                if jj == 6 && kk == 3
                    weight = perf.weights;
                else
                    weight = (weight+perf.weights)/2;
                end
            elseif strcmp(band_path(ii).name,'Delta')
                if jj == 6 && kk == 3
                    weight = perf.weights;
                else
                    weight = (weight+perf.weights)/2;
                end
            elseif strcmp(band_path(ii).name,'Gamma')
                if jj == 6 && kk == 3
                    weight = perf.weights;
                else
                    weight = (weight+perf.weights)/2;
                end
            elseif strcmp(band_path(ii).name,'Theta')
                if jj == 6 && kk == 3
                    weight = perf.weights;
                else
                    weight = (weight+perf.weights)/2;
                end
            end
        end
    end
    save(fullfile(Outer_name,'cross_val.mat'),'weight')
end

end
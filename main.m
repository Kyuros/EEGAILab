clc;clear;
%% Description
% The current use of the code is to classify between high- and
% moderate-responders of spinal cord stimulation using linear SVM. EEGLAB
% is also used to provide power and dipole visualizations to distinguish 
% differences between responders. All results including intermediate data
% are saved in the same folder under processed_data. For different use,
% modify the variables below.
% 
%   Kyle See 7/1/2021
%   Smart Medical Informatics Learning and Evaluation (SMILE)
%   Biomedical Engineering
% 
% INSTRUCTIONS
% - Place data in the data folder and run this script.
% - Adjust variables if needed
tic
%% Adjustable Variables
% SUBJECT IDS
% - Unique ID for each subject
% - Ex. [1,2,3,4,5,6,7]
subj = [1,2,4,5,7,8,9];

% BINARY CLASS LABELS
% - Vector must be same size as subject ID
% - Use 1 and -1 for labels
% - Ex. [1,-1,-1,1,1,-1,1]
labels = [1,1,-1,-1,1,-1,-1];

% OVERWRITE
% ['Y'/'N'] Default is 'Y'. 'Y' overwrites data in stages 1-3.
overwrite = 'Y';

% TOP NUMBER OF COMPONENTS
% Set the number of top ranking components to consider in a power
% comparison. Default is 3.
top = 3;

% SVM PARAMETERS
N = 10; % Number of iterations to repeat cross-validation. Default is 10.
n_fold = 3; % Number of folds for cross-validation. Default is 3.
feature_sel = 'N'; % Use feature selection ['N'/'Y'].
pval = 1; % P-value for feature selection.
weight = 'final'; % Type of weights to use for ranking ['final'/'cv'].

%% Initialize directory and call functions
% Make folders for stages 1-5 in the processed data folder.
if(~isdeployed)
  cd(fileparts(which('main.m')));
end

% Directory for processed data
path_inter = 'processed_data';
mkdir(path_inter);

for i = 1:5
    folder = fullfile(path_inter, ['stage',num2str(i)]);
    if ~exist(folder,'dir')
        mkdir(folder)
    end
end

% Set paths
path_eeg = 'data'; % EEGLAB data (.set and .fdt)
path_mat = fullfile(path_inter,'stage1'); % MATLAB data (.mat)
path_freq = fullfile(path_inter,'stage2'); % PSD Frequencies (.xlsx)
path_ML = fullfile(path_inter,'stage3'); % Machine learning models
path_comp = fullfile(path_inter,'stage4'); % Component sheets (.xlsx)
path_vis = fullfile(path_inter,'stage5'); % Component visualization (.svg and .xlsx)

% ---------------------------------------------------------------------
% Calling functions
addpath('src/functions')
addpath('src/references')

% 1. Convert EEGLAB data to power spectrum density as .mat file
eeglab2mat(path_eeg,path_mat,overwrite);

% 2. Saving .mat file as machine learning readable excel file
mat2excel(path_mat,path_freq,subj,'freq_features.xlsx',overwrite);

% 3. Perform SVM machine learning
svm_eeg(path_freq,path_ML,labels,N,n_fold,feature_sel,pval,overwrite);

% 4. Get component information and save as an excel file
eeglab2comp(path_eeg,path_ML,path_comp,subj,weight);

% 5a. Visualize and obtain power of components
comp2pwr(path_comp,path_vis,labels,subj,top)

% 5b. Visualize components across axial, coronal, and sagittal views
comp2vis(path_comp,path_vis,labels,subj)
toc
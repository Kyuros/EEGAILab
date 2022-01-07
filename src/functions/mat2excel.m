function [] = mat2excel(input_path,output_path,subj,filename,overwrite)
%% Save EEG into machine learning-ready format (Stage1 -> Stage2)
% PURPOSE: Takes .mat EEG files and saves into a .xlsx file using given
% filename. Each row is a subject and each column is a feature. A feature
% represents a single frequency from the power spectrum density (PSD) from
% 1-100Hz.
%
%   Kyle See 7/1/2021
%   Smart Medical Informatics Learning and Evaluation (SMILE)
%   Biomedical Engineering, University of Florida
%
%   Input:
%       input_path  - Path containing EEG .mat files. Expects a single PSD
%                     per subject.
%       output_path - Path to save .xlsx file.
%
%       Optional Arguments
%       subj        - 1D vector of IDs for each subject. Defaults to 1 
%                     to N IDs (1, 2, 3, 4, 5, ..., N).
%       filename    - Filename for the output .xlsx file. Name needs .xlsx 
%                     extension, otherwise saved as .xls. Default name is
%                     'EEG_features.xlsx'.
%       overwrite   - ['N'|'Y'] 'N' indicates do not overwrite. 'Y'
%                     indicates to overwrite if output file exists. Default
%                     is 'N'.
%
%   Output:
%                   - Generates .xlsx file of PSDs per subject. Each row is
%                     a subject. Each column is a single frequency.
%
%---------------------------------------------
% Last Updated: 7/1/21
% - 7/1 Created
% 
%% Checking inputs and initializing variables
% Retrieving inputs
folder_data = dir(input_path);
dir_data = dir(fullfile(input_path,'*.mat'));

% Check that subj variable and actual files are correct shape
N = length(dir_data); % Number of subjects based on directory
if ~exist('subj','var')
    subj = (1:N)'; % Generates a column vector of unique IDs if not present
elseif length(subj) ~= N
    error('Error. \nThe subj var (n=%d) does not match number of files (n=%d).',length(subj),N)
else
    % Transform to column vector
    if isrow(subj)
        subj = subj';
    end
end

% Checks for filename. Creates one if missing
if ~exist('filename','var')
    filename = 'EEG_features.xlsx';
end

% Checks if need to overwrite
if ~exist('overwrite','var')
    overwrite = 'N';
elseif overwrite ~= 'Y' && overwrite ~= 'N'
    error("Error. \nExpecting overwrite to be 'N' or 'Y'")
end

% Initialize matrix
matrix = [];

%% Convert .mat to .xlsx
% Constructs expected path output
path_output = fullfile(output_path,filename);

% Creates file if it doesn't exist or needs to be overwritten
if isfile(path_output) == 1 && overwrite == 'Y' || isfile(path_output) == 0
    
    % Iterate through input folder path
    for i = 1:length(dir_data)
        
        % Loads .mat file
        file_path = fullfile(input_path,dir_data(i).name);
        data = load(file_path);
        
        % Appends data to matrix
        matrix = [matrix; data.eegData];
    end
    
    % Appends subject ID as first column
    matrix = [subj,matrix];
    
    % Adding headers
    colNames = ["Subject","Hz_" + (1:length(data.eegData))];
    matrix = array2table(matrix,'VariableNames',colNames);
    
    % Function output
    if isfile(path_output) == 1 && overwrite == 'Y'
        writetable(matrix,path_output)
        fprintf("Existing excel file is overwritten.\n")
    elseif isfile(path_output) == 1 && overwrite == 'N'
        fprintf("Current excel file has not been updated.\n")
    elseif isfile(path_output) == 0
        writetable(matrix,path_output)
        fprintf("New excel file is created.\n\n")
    end
end
end
function [] = eeglab2mat(input_path,output_path,overwrite)
%% Save EEG into MATLAB format (Data -> Stage1)
% PURPOSE: Takes EEG data and saves into a .mat file using the same
% file name. The .mat file has size of CHANNEL x TIME x EPOCH matrix.
%
%   Kyle See 7/1/2021
%   Smart Medical Informatics Learning and Evaluation (SMILE)
%   Biomedical Engineering, University of Florida
%
%   Input:
%       input_path  - Path containing EEG .set and .fdt file pairs.
%       output_path - Path to save .mat files. Does not save if file is
%                     already found. Saves variable as "eegData".
%
%       Optional Argument
%       overwrite   - ['N'|'Y'] 'N' indicates do not overwrite. 'Y'
%                     indicates to overwrite if output file exists. Default
%                     is 'N'.
%
%   Output:
%                   - Generates .mat file versions of the EEG .set and .fdt
%                     file pairs. Uses the name of .set and .fdt pair.
%
%---------------------------------------------
% Last Updated: 7/1/21
% - 7/1 Created

%% Checking inputs and intializing variables
% Checks if need to overwrite
if ~exist('overwrite','var')
    overwrite = 'N';
elseif overwrite ~= 'Y' && overwrite ~= 'N'
    error("Expecting overwrite to be 'N' or 'Y'")
end

% Retrieving inputs
folder_data = dir(input_path);

% Tracking how many changes
fileCount = 0; % Tracks number of total processed files
newCount = 0; % Tracks new files made
owCount = 0; % Tracks overwritten files

%% Converting .set/.fdt to .mat
% Iterate through input folder path
for i = 3:length(folder_data)
    
    % Set up file names
    file = folder_data(i).name; % Grabs .set file name of current iteration
    output_name = strcat(extractBefore(file,'.'),'.mat'); % Create .mat file name
    path_output = fullfile(output_path,output_name); % Expected path for saving file
    
    % Perform task by calling .set data AND only if output file does not already exist
    if contains(file,'set') && isfile(path_output) == 0 || contains(file,'set') && isfile(path_output) == 1 && overwrite == 'Y'
        
        % Loading subject with EEGLAB
        EEG = pop_loadset('filename',file,'filepath',input_path,'loadmode','all');
        
        % Extract power spectrum as spectra
        [spectra,~] = spectopo(EEG.data, EEG.pnts, EEG.srate, 'plot','off','verbose','off');
        eegData = mean(spectra,1); % Take mean of spectras across channels
        eegData = eegData(:,1:100); % Keep 1-100Hz frequencies
        fileCount = fileCount + 1;
        
        % Determine overwriting
        if isfile(path_output) == 1 && overwrite == 'Y'
            save(path_output,"eegData")
            owCount = owCount + 1;
        else
            save(path_output,"eegData")
            newCount = newCount + 1;
        end
    elseif contains(file,'set') && isfile(path_output) == 0 || contains(file,'set') && isfile(path_output) == 1 && overwrite == 'N'
        fileCount = fileCount + 1;
    end
end
clc;
fprintf("Detected %d files.\n",fileCount)
fprintf("%d new file(s) created and %d file(s) overwritten.\n\n",newCount,owCount)
end
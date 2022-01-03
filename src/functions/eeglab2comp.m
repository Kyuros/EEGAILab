function [] = eeglab2comp(input_path,ML_path,output_path,subj,weight_type)
%% Extracts information from EEGLAB IC components (Data+Stage3 -> Stage4)
% PURPOSE: Organizes all information about components into a single excel
% sheet. This information includes descriptors (coordinates, brain
% locations, and residual variances) and calculated rankings (raw power, 
% rank score, and rank). These rankings useed machine learning weights and
% the power spectra to "rank" components with the most influence.
%
%   Kyle See 7/1/2021
%   Smart Medical Informatics Learning and Evaluation (SMILE)
%   Biomedical Engineering, University of Florida
%
%   Input:
%       input_path    - Path containing EEG .set and .fdt file pairs.
%       ML_path       - Path containing ML files. Expects all powerbands to
%                       use the 'band' argument. Default 'all'.
%       output_path   - Path to save .xlsx file.
%
%       Optional Arguments
%       subj          - 1D vector of IDs for each subject. Defaults to 1
%                       to N IDs (1, 2, 3, 4, 5, ..., N).
%       weight_type   - ['final'|'cv'] 'final' uses weights from the final
%                       model trained by all the data. 'cv' uses weights
%                       averaged from each cross-validation fold. Default
%                       is 'final'.
%
%   Output:
%                     - Gathers information and ranking of components into
%                       a .xlsx file. The following information is included:
%                           - posXYZ: Coordinates of dipoles in MNI space
%                           - Brain regions:
%                               - Hemisphere
%                               - Lobe
%                               - Gyrus
%                           - rv: Residual variance of the component
%                           - Band_power: Power from the spectra
%                           - Band_score: Component's score from ranking
%                           - Band_rank: Rank from ranking
%
%---------------------------------------------
% Last Updated: 7/1/21
% - 7/1  Created
% - 7/21 Added folder parsing. Now parses all files in input folder using
%        folder name as prefix.

%% Initializing variables and checking inputs
input_data = dir(input_path); % Directory for EEG inputs
ML_folder = dir(ML_path); % Directory for machine learning inputs
N = (length(input_data)-2)/2; % Number of unique subjects

% Checks subject numbering and if correct size
if ~exist('subj','var')
    subj = (1:N)';
elseif length(subj) ~= N
    error("subj has an incorrect size")
else
    % Transform to column vector
    if isrow(subj)
        subj = subj';
    end
end

% Checks for weight preference
if ~exist('weight_type')
    % Do nothing
else
    % Check for correct input
    if weight_type ~= "final" && weight_type ~= "cv"
        error("Expecting weight to be 'final' or 'cv'")
    end
    
end

%% Data organization
for ii = 3:length(ML_folder)
    
    % Creates directory for machine learning inputs
    ML_data_path = fullfile(ML_path,ML_folder(ii).name);
    ML_data = dir(ML_data_path);
    
    % Variables to reset each folder
    comp_info = []; % Information for components
    comp_final = []; % Holds finalized information
    fileCount = 1; % Counter to iterate through each label
    firstPass = 0; % Flag for initialization
    [~,folder_name] = fileparts(ML_data_path); % Takes folder name to use as prefix for output file
    
    % Loads final or cv weights
    if strcmp(weight_type,'final')
        % Load final model
        load(fullfile(ML_data_path, 'final_model.mat')) % Assumes "model" is the only variable loaded
        
        % Calculate SVM weights
        weight = (model.sv_coef' * full(model.SVs))'; % SVM weights
        [unique_freq,~] = size(weight);
    else
        % Load cross validation model
        load(fullfile(ML_data_path, 'cross_val.mat')) % Assumes "model" is the only variable loaded
        
        % Calculate SVM weights
        if isrow(weight)
            weight = weight';
        end
        [unique_freq,~] = size(weight);
    end
    
    % Check for labels and if correct size
    if ~exist('labels','var')
        subj = (1:N)';
    elseif length(subj) ~= N
        error('labels has an incorrect size')
    else
        % Transform to column vector
        if isrow(subj)
            subj = subj';
        end
    end
    
    % This portion is hard-coded and uses values from 1-100Hz. It auto-detects
    % bands based on the number of frequencies as each band has a unique number of
    % frequencies. Any adjustment has to be done here.
    if unique_freq == 4 || unique_freq == 100 % Delta 1-4Hz, All 1-100Hz
        shift = 1;
    elseif unique_freq == 5 % Theta 4-8Hz
        shift = 4;
    elseif unique_freq == 6 % Alpha 8-13Hz
        shift = 8;
    elseif unique_freq == 18 % Beta 13-30Hz
        shift = 13;
    elseif unique_freq == 71 % Gamma 30-100Hz
        shift = 30;
    end
    
    % Adds actual frequency numbers
    loc = linspace(1,unique_freq,unique_freq)'; % Generates freq. numbers starting from 1. (Ex. Gamma 1-70)
    loc = loc + (shift-1); % Shifts freq. numbers based on freq. (Ex. Gamma shifts 1-70 to 30-100)
    weight = [weight,loc];
    
    %% EEG Component Ranking
    % Iterate through each file (includes .set and .fdt files)
    for i = 3:length(input_data)
        
        % Grabbing current file name
        file = input_data(i).name;
        
        % Iterate through each subject (.set only)
        if contains(file,'set')
            EEG = pop_loadset('filename',file,'filepath',input_path,'loadmode','all');
            comp_num = length(EEG.dipfit.model);
            
            % Initializing component coordinates
            data = zeros(comp_num,4);
            data(:,1) = linspace(1,comp_num,comp_num);
            
            % Reading regions using list
            ref = tdfread('regionRef.txt',',');
            label = cellstr(ref.label);
            
            % Initializing for component information
            info = {};
            comp_psd = [];
            
            % PART 1 - Obtain Component Information
            % Iterate through components obtain info
            for j = 1:comp_num
                
                % Append current component coordinates
                data(j,2:4) = EEG.dipfit.model(j).posxyz(1:3);
                name = EEG.dipfit.model(j).areadk;
                if sum(contains(label,name)) == 1
                    hemisphereL = strtrim(ref.hemisphere(contains(label,name),:));
                    lobeL = strtrim(ref.lobe(contains(label,name),:));
                    gyrusL = strtrim(ref.gyrus(contains(label,name),:));
                elseif length(name) == 7 && name(1) == 'n'
                    hemisphereL = 'none';
                    lobeL = 'none';
                    gyrusL = 'none';
                else
                    fprintf('''%s'' not found\n',name)
                end
                
                % Compiling information into a structure
                info = struct('subject',subj(fileCount),...
                    'posX',EEG.dipfit.model(j).posxyz(1),...
                    'posY',EEG.dipfit.model(j).posxyz(2),...
                    'posZ',EEG.dipfit.model(j).posxyz(3),...
                    'hemisphere',hemisphereL,...
                    'lobe',lobeL,...
                    'gyrus',gyrusL,...
                    'rv',EEG.dipfit.model(j).rv);
                
                % Append components together
                comp_info = [comp_info,info];
            end
            
            % PART 2 - Component Ranking
            % Iterate through components obtain PSDs
            for comp = 1:comp_num
                icaacttmp = (EEG.icaweights(comp,:)*EEG.icasphere)*reshape(EEG.data(EEG.icachansind,:,:), length(EEG.icachansind), EEG.trials*EEG.pnts);
                [spectra,~] = spectopo(icaacttmp, EEG.pnts, EEG.srate, 'mapnorm', EEG.icawinv(:,comp),'verbose','off','plot','off');
                comp_psd = [comp_psd, spectra(1:100)'];
            end
            
            % Shorten PSD to desired powerband
            comp_psd = comp_psd([min(loc):max(loc)],:);
            comp_psd = 10.^(comp_psd./10);
            
            % Component frequencies * ML weight to obtain a score
            comp_score = comp_psd.*abs(weight(:,1));
            
            % Averaging with frequency band
            comp_score = mean(comp_score,1)';
            
            % Organizing with ranks
            [val,idx] = sortrows(comp_score,1,'descend');
            componentWeight = [val,idx];
            for k = 1:comp_num
                comp_score(componentWeight(k,2),2) = k;
            end
            
            % Appending to comp_info
            for u = 1:comp_num
                comp_info(u).(strcat(folder_name,'_power')) = mean(comp_psd(:,u));
                comp_info(u).(strcat(folder_name,'_score')) = comp_score(u,1);
                comp_info(u).(strcat(folder_name,'_rank')) = comp_score(u,2);
            end
            
            % Adds to a final component info list
            if firstPass == 0 && ~exist('comp_final','var')
                comp_final = comp_info;
                firstPass = 1;
            else
                comp_final = [comp_final, comp_info];
            end
            
            comp_info = [];
            fileCount = fileCount + 1;
        end
    end
    
    filename = strcat(output_path,folder_name,'_components.xlsx');
    writetable(struct2table(comp_final),filename);
    
end

end
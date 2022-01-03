function [] = comp2pwr(input_path,output_path,labels,subj,N)
%% Extracts power from IC components based on rank (Stage4 -> Stage5)
% PURPOSE: Take the N number of top ranking components and averages
% component power across subjects within-group. Power is separated between
% high and moderate responders.
%
%   Kyle See 7/1/2021
%   Smart Medical Informatics Learning and Evaluation (SMILE)
%   Biomedical Engineering, University of Florida
%
%   Input:
%       input_path       - Path containing excel component sheets.
%       output_path      - Path to save excel power information.
%       labels           - 1D vector of labels to separate high and
%                          moderate responders. High responders are 1 and
%                          moderate responders are -1.
%
%       Optional Arguments
%       subj             - 1D vector of IDs for each subject. Defaults to 1
%                          to N IDs (1, 2, 3, 4, 5, ..., N).
%       N                - Number of top ranking components to consider
%                          from each subject. Default is 3.
%   Output:
%                        - Generates .xlsx file containing average power
%                          from the top N ranked components. Average power
%                          is found from each powerband, between high and
%                          moderate responders, and between frontal and
%                          parietal lobes.
%
%---------------------------------------------
% Last Updated: 7/1/21
% - 7/1 Created

%% Initializing variables and checking inputs
high_responders = subj(labels == 1); % Separating subjects into groups
moderate_responders = subj(labels == -1); % Separating subjects into groups
input_data = dir(input_path); % Grab directory for .xlsx component sheets (Stage 4)
power_info = []; % Initialize power information

% Check subject numbering and if correct size
if ~exist('subj','var')
    subj = (1:N)';
else
    % Transform to column vector
    if ~isrow(subj)
        subj = subj';
    end
end

% Number of components
if ~exist('N','var')
    total_count = 3;
else
    total_count = N;
end

%% Code
% Loop through each powerband sheet
for ii = 3:length(input_data)
    
    % Grab name of file ("BAND_components.xlsx")
    filename = input_data(ii).name;
    name = extractBefore(filename,'_');
    
    % Entire contents of the component sheet here
    data = readtable(fullfile(input_path,filename));
    
    % Separating frontal and parietal data
    data_frontal = data(strcmp(data.lobe,'Frontal'),:);
    data_parietal = data(strcmp(data.lobe,'Parietal'),:);
    
    
    subject_list = unique(data.subject);
    
    % Finding top 3 ranked dipoles
    for i = 1:length(subject_list)
        
        % Find how many frontal components
        comp_num_frontal = length(find(data_frontal.subject == subject_list(i) ));
        
        % Reduces dipoles based on rank if total number per subject exceeds 3
        if comp_num_frontal > total_count
            for j = 1:comp_num_frontal - total_count
                [M,I] = max(data_frontal.(strcat(name,'_rank'))(data_frontal.subject == subject_list(i)));
                data_frontal(I+((i-1)*total_count),:) = [];
            end
        end
        
        % Find how many parietal components
        comp_num_parietal = length(find(data_parietal.subject == subject_list(i) ));
        
        % Reduces dipoles based on rank if total number per subject exceeds 3
        if comp_num_parietal > total_count
            for j = 1:comp_num_parietal - total_count
                [M,I] = max(data_parietal.(strcat(name,'_rank'))(data_parietal.subject == subject_list(i)));
                data_parietal(I+((i-1)*total_count),:) = [];
            end
        end
    end
    
    % Average powers between high and moderate responders separated by
    % frontal and parietal.
    high_res_frontal = [];
    high_res_parietal = [];
    mod_res_frontal = [];
    mod_res_parietal = [];
    
    % Collect all powers from every top ranked component
    for k = 1:length(high_responders)
        high_res_frontal = [high_res_frontal; data_frontal.(strcat(name,'_power'))(find(data_frontal.subject == high_responders(k)))];
        high_res_parietal = [high_res_parietal; data_parietal.(strcat(name,'_power'))(find(data_parietal.subject == high_responders(k)))];
    end
    
    for y = 1:length(moderate_responders)
        mod_res_frontal = [mod_res_frontal; data_frontal.(strcat(name,'_power'))(find(data_frontal.subject == moderate_responders(y)))];
        mod_res_parietal = [mod_res_parietal; data_parietal.(strcat(name,'_power'))(find(data_parietal.subject == moderate_responders(y)))];
    end
    
    % Average power and place into a table
    info = struct('band',name,...
        'moderate_frontal',mean(mod_res_frontal),...
        'high_frontal',mean(high_res_frontal),...
        'moderate_parietal',mean(mod_res_parietal),...
        'high_parietal',mean(high_res_parietal));
    
    power_info = [power_info,info];
    
end

filename_new = fullfile(output_path,'Component_power.xlsx');
writetable(struct2table(power_info),filename_new);

end
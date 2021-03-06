function [] = comp2vis(input_path,output_path,labels,subj)
%% Visualizes IC components (Stage4 -> Stage5)
% PURPOSE: Takes the top 10 ranking components from each subject and
% visualizes location on a standard MRI brain.
%
%   Kyle See 7/1/2021
%   Smart Medical Informatics Learning and Evaluation (SMILE)
%   Biomedical Engineering, University of Florida
%
%   Input:
%       input_path       - Path containing excel component sheets.
%       output_path      - Path to save figures.
%       labels           - 1D vector of labels to separate high and
%                          moderate responders. High responders are 1 and
%                          moderate responders are -1.
% 
%       Optional Arguments
%       subj             - 1D vector of IDs for each subject. Defaults to 1
%                          to N IDs (1, 2, 3, 4, 5, ..., N).
%   Output:
%                        - Generates .svg files showing component locations
%                          with axial, sagittal, and coronal views. There
%                          are figures for each powerband and group.
%
%---------------------------------------------
% Last Updated: 7/1/21
% - 7/1 Created

%% Checking inputs and loading data
high_responders = subj(labels == 1); % Separating subjects into groups
moderate_responders = subj(labels == -1); % Separating subjects into groups
dir_xlsx = dir(fullfile(input_path,'*.xlsx')); % Directory for excel inputs
load('standard_mri.mat') % Load standard MRI for background
N = 10; % Top ranking components

% Check subject numbering and if correct size
if ~exist('subj','var')
    subj = (1:N)';
else
    % Transform to column vector
    if ~isrow(subj)
        subj = subj';
    end
end

%% Code
% Loop through each powerband sheet
for ii = 1:length(dir_xlsx)
    
    % Grab name of file ("BAND_components.xlsx")
    filename = dir_xlsx(ii).name;
    name = extractBefore(filename,'_');
    
    % Entire contents of the component sheet here
    data = readtable(fullfile(input_path,filename));

    % Separates tables into high and moderate responders
    data_high = data(find(ismember(data.subject,high_responders)),:);
    data_mod = data(find(ismember(data.subject,moderate_responders)),:);
    
    % Sets MRI background image for each view
    xy = (squeeze(mri.anatomy(:,:,90))); % Axial
    xz = (squeeze(mri.anatomy(:,109,:))); % Coronal
    yz = (squeeze(mri.anatomy(90,:,:))); % Sagittal
    
    % Initializes all responder views
    figure(11); hold on; imshow(xy); axis off; % High responder - Axial view
    figure(12); imshow(xz); axis off; % High responder - Coronal view
    figure(13); imshow(yz); axis off; % High responder - Sagittal view 
    figure(43); imshow(xy); axis off; % Moderate responder - Axial view
    figure(44); imshow(xz); axis off; % Moderate responder - Coronal view
    figure(45); imshow(yz); axis off; % Moderate responder - Sagittal view
    
    % Finds indexes of all top dipoles
    dp_hr = find(data_high.([name,'_rank']) <= N); % Finds all top 10 dipoles
    dp_mr = find(data_mod.([name,'_rank']) <= N); % CHANGE DIPOLE COLUMN

    % Dipole Rank Column
    ranking_r = data_high.([name,'_rank']); % CHANGE DIPOLE COLUMN HERE
    ranking_nr = data_mod.([name,'_rank']); % CHANGE DIPOLE COLUMN HERE
    
    % High Responders
    for i = 1:length(dp_hr)
        if data_high.lobe(dp_hr(i)) == "Frontal"
            
            % Plots a dipole on Axial slice
            figure(11);
            hold on
            scatter(data_high.posY(dp_hr(i))+126,...
                data_high.posX(dp_hr(i))+91,...
                550-(ranking_r(dp_hr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','red',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
            
            % Plots a dipole on Coronal slice
            figure(12);
            hold on
            scatter(data_high.posZ(dp_hr(i))+73,...
                data_high.posX(dp_hr(i))+91,...
                550-(ranking_r(dp_hr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','red',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
            
            % Plots a dipole on Sagittal slice
            figure(13);
            hold on
            scatter(data_high.posZ(dp_hr(i))+73,...
                data_high.posY(dp_hr(i))+126,...
                550-(ranking_r(dp_hr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','red',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
            
        elseif data_high.lobe(dp_hr(i)) == "Parietal"
            % Plots a dipole on Axial slice
            figure(11);
            hold on
            scatter(data_high.posY(dp_hr(i))+126,...
                data_high.posX(dp_hr(i))+91,...
                550-(ranking_r(dp_hr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','blue',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
            
            % Plots a dipole on Coronal slice
            figure(12);
            hold on
            scatter(data_high.posZ(dp_hr(i))+73,...
                data_high.posX(dp_hr(i))+91,...
                550-(ranking_r(dp_hr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','blue',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
            
            % Plots a dipole on Sagittal slice
            figure(13);
            hold on
            scatter(data_high.posZ(dp_hr(i))+73,...
                data_high.posY(dp_hr(i))+126,...
                550-(ranking_r(dp_hr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','blue',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
        else
            % Plots a dipole on Axial slice
            figure(11);
            hold on
            scatter(data_high.posY(dp_hr(i))+126,...
                data_high.posX(dp_hr(i))+91,...
                550-(ranking_r(dp_hr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','green',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
            
            % Plots a dipole on Coronal slice
            figure(12);
            hold on
            scatter(data_high.posZ(dp_hr(i))+73,...
                data_high.posX(dp_hr(i))+91,...
                550-(ranking_r(dp_hr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','green',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
            
            % Plots a dipole on Sagittal slice
            figure(13);
            hold on
            scatter(data_high.posZ(dp_hr(i))+73,...
                data_high.posY(dp_hr(i))+126,...
                550-(ranking_r(dp_hr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','green',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
        end
    end
    
    % Moderate Responders
    for i = 1:length(dp_mr)
        if data_mod.lobe(dp_mr(i)) == "Frontal"
            % Plots a dipole on Axial slice
            figure(43);
            hold on
            scatter(data_mod.posY(dp_mr(i))+126,...
                data_mod.posX(dp_mr(i))+91,...
                550-(ranking_nr(dp_mr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','red',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
            
            % Plots a dipole on Coronal slice
            figure(44);
            hold on
            scatter(data_mod.posZ(dp_mr(i))+73,...
                data_mod.posX(dp_mr(i))+91,...
                550-(ranking_nr(dp_mr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','red',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
            
            % Plots a dipole on Sagittal slice
            figure(45);
            hold on
            scatter(data_mod.posZ(dp_mr(i))+73,...
                data_mod.posY(dp_mr(i))+126,...
                550-(ranking_nr(dp_mr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','red',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
            
        elseif data_mod.lobe(dp_mr(i)) == "Parietal"
            % Plots a dipole on Axial slice
            figure(43);
            hold on
            scatter(data_mod.posY(dp_mr(i))+126,...
                data_mod.posX(dp_mr(i))+91,...
                550-(ranking_nr(dp_mr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','blue',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
            
            % Plots a dipole on Coronal slice
            figure(44);
            hold on
            scatter(data_mod.posZ(dp_mr(i))+73,...
                data_mod.posX(dp_mr(i))+91,...
                550-(ranking_nr(dp_mr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','blue',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
            
            % Plots a dipole on Sagittal slice
            figure(45);
            hold on
            scatter(data_mod.posZ(dp_mr(i))+73,...
                data_mod.posY(dp_mr(i))+126,...
                550-(ranking_nr(dp_mr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','blue',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
        else
            % Plots a dipole on Axial slice
            figure(43);
            hold on
            scatter(data_mod.posY(dp_mr(i))+126,...
                data_mod.posX(dp_mr(i))+91,...
                550-(ranking_nr(dp_mr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','green',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
            
            % Plots a dipole on Coronal slice
            figure(44);
            hold on
            scatter(data_mod.posZ(dp_mr(i))+73,...
                data_mod.posX(dp_mr(i))+91,...
                550-(ranking_nr(dp_mr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','green',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
            
            % Plots a dipole on Sagittal slice
            figure(45);
            hold on
            scatter(data_mod.posZ(dp_mr(i))+73,...
                data_mod.posY(dp_mr(i))+126,...
                550-(ranking_nr(dp_mr(i))*50),...
                'MarkerFaceAlpha',0.3,...
                'MarkerFaceColor','green',...
                'MarkerEdgeColor','none',...
                'LineWidth',0.0001)
        end
    end
    
    % Output path for the pictures
    output_path_comp = fullfile(output_path,name);
    
    % Creates folder if it does not exist
    if ~exist(output_path_comp,'dir')
        mkdir(output_path_comp)
    end
    
    % Saving as .svg
    name11 = [name,'_HIGH_axial.svg'];
    name12 = [name,'_HIGH_coronal.svg'];
    name13 = [name,'_HIGH_sagittal.svg'];
    saveas(figure(11),fullfile(output_path_comp,name11))
    saveas(figure(12),fullfile(output_path_comp,name12))
    saveas(figure(13),fullfile(output_path_comp,name13))
    
    name43 = [name,'_MOD_axial.svg'];
    name44 = [name,'_MOD_coronal.svg'];
    name45 = [name,'_MOD_sagittal.svg'];
    saveas(figure(43),fullfile(output_path_comp,name43))
    saveas(figure(44),fullfile(output_path_comp,name44))
    saveas(figure(45),fullfile(output_path_comp,name45))
    
    % Close all figures
    close all
end
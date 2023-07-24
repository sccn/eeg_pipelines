% This script is part of the code used to generate the results presented in:
% Delorme A. EEG is better left alone. Sci Rep. 2023 Feb 9;13(1):2372. doi: 10.1038/s41598-023-27528-0. PMID: 36759667; PMCID: PMC9911389.
% https://pubmed.ncbi.nlm.nih.gov/36759667/
%
% This contains the code for the optimal EEGLAB pipeline in the paper above. 
% An example dataset is provided in the data folder.
% Simple plotting for one channel for the two conditions is provided at the end of the script.
%
% Requires to have EEGLAB installed and to install the Picard plugin
% Tested successfuly with EEGLAB 2023.0
%
% Arnaud Delorme, 2022

% Difference with the version show on YOUTUBE at https://www.youtube.com/watch?v=yaA1wq2nSIc
% - removed plotting
% - removed STUDY section and perform simpler plotting of one channel 

% beginning of parameters ************

% You may select your own file and conditions below
clear
fileName    = fullfile('..', 'data', 'sub-001_task-P300_run-2_eeg.set'); % data file
conditions  = { 'oddball_with_reponse' 'standard' }; % conditions to extract
removeChans = {'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp' }; % channels to ignore

% end of parameters ************

% load data
if ~exist('pop_loadset'), eeglab; end
EEG = pop_loadset('filename',fileName);

% filter data
EEG = pop_eegfiltnew(EEG, 'locutoff',0.5);
EEG = pop_select( EEG, 'nochannel',removeChans); % list here channels to ignore
chanlocs = EEG.chanlocs;

% remove bad channels and bad portions of data
EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',4,'ChannelCriterion',0.85,'LineNoiseCriterion',4,'Highpass','off',...
    'BurstCriterion',20,'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );

% Run ICA and IC Label
EEG = pop_runica(EEG, 'icatype', 'picard', 'maxiter', 500, 'mode', 'standard'); % mode standard made default 07/2023
EEG = pop_iclabel(EEG, 'default');
EEG = pop_icflag(EEG, [NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
EEG = pop_subcomp( EEG, [], 0);

% Interpolate removed channels 
EEG = pop_interp(EEG, chanlocs);

% epoch extraction and saving of datasets
[~,fileBase] = fileparts(EEG.filename);
EEGcond1 = pop_epoch( EEG, {  conditions{1} }, [-0.3 0.7], 'newname', 'Cond1', 'epochinfo', 'yes');
EEGcond1 = pop_saveset( EEGcond1, 'filename',[fileBase '_cond1_eeglab.set'],'filepath',EEG.filepath);

EEGcond2 = pop_epoch( EEG, {  conditions{2}  }, [-0.3 0.7], 'newname', 'Cond2', 'epochinfo', 'yes');
EEGcond2 = pop_saveset( EEGcond2, 'filename',[fileBase '_cond2_eeglab.set'],'filepath',EEG.filepath);

% plot difference between conditions for channel 2
figure; 
plot(mean(EEGcond1.data(2,:,:),3)); hold on; 
plot(mean(EEGcond2.data(2,:,:),3),'r');
title('ERP for each condition for channel 2');
h = legend(conditions{:}); set (h, 'Interpreter', 'none')

% Difference with Youtube script
% - removed plotting
% - add input filename
% - added reinterpolation and rereferencing

% Arnaud Delorme, Aug 9th, 2022
clear
fileName    = fullfile('..', 'data', 'sub-001_task-P300_run-2_eeg.set');
conditions  = { 'oddball_with_reponse' 'standard' };
removeChans = {'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp' };

% load data
if ~exist('pop_loadset'), eeglab; end
EEG = pop_loadset('filename',fileName);

% filter data
EEG = pop_eegfiltnew(EEG, 'locutoff',0.5);
EEG = pop_select( EEG, 'nochannel',removeChans); % list here channels to ignore

% rereference data
chanlocs = EEG.chanlocs;
EEG = pop_reref(EEG, []);

% remove bad channels and bad portions of data
EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',4,'ChannelCriterion',0.9,'LineNoiseCriterion',4,'Highpass','off','BurstCriterion',20,...
    'WindowCriterion',0.25,'BurstRejection','on','Distance','Euclidian','WindowCriterionTolerances',[-Inf 7] );

% Run ICA and IC Label
EEG = pop_runica(EEG, 'icatype', 'picard', 'maxiter',500);
EEG = pop_iclabel(EEG, 'default');
EEG = pop_icflag(EEG, [NaN NaN;0.9 1;0.9 1;NaN NaN;NaN NaN;NaN NaN;NaN NaN]);
EEG = pop_subcomp( EEG, [], 0);

% Interpolate removed channels 
EEG = pop_interp(EEG, chanlocs);
EEG = pop_reref(EEG, []);

% epoch extraction and saving of datasets
[~,fileBase] = fileparts(EEG.filename);
EEGcond1 = pop_epoch( EEG, {  conditions{1} }, [-0.3 0.7], 'newname', 'Cond1', 'epochinfo', 'yes');
EEGcond1 = pop_rmbase( EEGcond1, [-300 0] ,[]);
EEGcond1 = pop_saveset( EEGcond1, 'filename',[fileBase '_cond1_eeglab.set'],'filepath',EEG.filepath);

EEGcond2 = pop_epoch( EEG, {  conditions{2}  }, [-0.3 0.7], 'newname', 'Cond2', 'epochinfo', 'yes');
EEGcond2 = pop_rmbase( EEGcond2, [-300 0] ,[]);
EEGcond2 = pop_saveset( EEGcond2, 'filename',[fileBase '_cond2_eeglab.set'],'filepath',EEG.filepath);

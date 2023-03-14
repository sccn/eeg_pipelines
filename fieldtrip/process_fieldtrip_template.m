% This script is part of the code used to generate the results presented in:
% Delorme A. EEG is better left alone. Sci Rep. 2023 Feb 9;13(1):2372. doi: 10.1038/s41598-023-27528-0. PMID: 36759667; PMCID: PMC9911389.
% https://pubmed.ncbi.nlm.nih.gov/36759667/
%
% This contains the code for the optimal Fieldtrip pipeline in the paper above.
% An example dataset is provided in the data folder.
% Simple plotting for one channel for the two conditions is provided at the end of the script.
%
% Requires to have Fieldtrip installed
% Tested successfuly with Fieldtrip version of Dec 6, 2023

% Arnaud Delorme, 2022

% beginning of parameters ************

% You may select your own file and conditions below, and change other parameters as well
clear
fileName = fullfile('..', 'data', 'sub-001_task-P300_run-2_eeg.set');
conditions  = { 'oddball_with_reponse' 'standard' };
triggers    = { 'trigger' 'stimulus' };
removeChans = {'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp' }; % channels to ignore
frontalChannelsLowFreq = { 'AF7' 'AF3' 'Fp1' 'Fp2' 'Fpz' }; % for artifact rejection
temporalChannelsHiFreq = { 'T7' 'T8' 'TP7' 'TP8' 'P9' 'P10' }; % for artifact rejection

% end of paramters ************

% filtering
cfg           = [];
cfg.dataset   = fileName;
cfg.hpfreq    = 0.5;
cfg.hpfilter  = 'yes';
data_clean = ft_preprocessing(cfg);

% select channels
cfg = [];
cfg.channel = setdiff(data_clean.elec.label, removeChans); % keep only selected channels
data_clean = ft_preprocessing(cfg,data_clean);

% redefine trials
cfg                         = [];
cfg.dataset                 = fileName;
cfg.trialfun                = 'ft_trialfun_withevents';
cfg.trialdef.eventtype      = triggers; % the values of the stimulus trigger for the conditions
cfg.trialdef.eventvalue     = conditions; % the values of the stimulus trigger for the conditions
cfg.trialdef.prestim        = 0.3; % in seconds
cfg.trialdef.poststim       = 0.7; % in seconds
cfg = ft_definetrial(cfg);
data2 = ft_redefinetrial(cfg, data_clean);

% check that all trials have the same length (Fieldtrip occasionally crashes otherwise)
tlen = cellfun(@length, data2.time');
if length(unique(tlen)) > 1
    error('Wrong size');
end

% round values to avoid ft_artifact_zvalue crash
if isfield(data2, 'sampleinfo')
    data2.sampleinfo = round(data2.sampleinfo);
end

% Low-frequency data rejection
cfg = [];
cfg.artfctdef.zvalue.channel     = frontalChannelsLowFreq;
cfg.artfctdef.zvalue.cutoff      = 4;
cfg.artfctdef.zvalue.trlpadding  = 0;
cfg.artfctdef.zvalue.artpadding  = 0.1;
cfg.artfctdef.zvalue.fltpadding  = 0;
cfg.artfctdef.zvalue.bpfilter    = 'yes';
cfg.artfctdef.zvalue.bpfilttype  = 'but';
cfg.artfctdef.zvalue.bpfreq      = [0.5 2];
cfg.artfctdef.zvalue.bpfiltord   = 4;
cfg.artfctdef.zvalue.hilbert     = 'yes';
cfg.artfctdef.zvalue.interactive = 'no';
[~, artifact_EOG] = ft_artifact_zvalue(cfg, data2);

% High-frequency data rejection
cfg = [];
cfg.artfctdef.zvalue.channel      = temporalChannelsHiFreq;
cfg.artfctdef.zvalue.cutoff       = 4;
cfg.artfctdef.zvalue.trlpadding   = 0;
cfg.artfctdef.zvalue.fltpadding   = 0;
cfg.artfctdef.zvalue.artpadding   = 0.1;
cfg.artfctdef.zvalue.bpfilter     = 'yes';
cfg.artfctdef.zvalue.bpfreq       = [100 110];
cfg.artfctdef.zvalue.bpfiltord    = 9;
cfg.artfctdef.zvalue.bpfilttype   = 'but';
cfg.artfctdef.zvalue.hilbert      = 'yes';
cfg.artfctdef.zvalue.boxcar       = 0.2;
cfg.artfctdef.zvalue.interactive = 'no';
[~,artifact_muscle] = ft_artifact_zvalue(cfg, data2);

% this rejects complete trials, use 'partial' if you want to do partial artifact rejection
cfg=[];
cfg.artfctdef.reject = 'complete';
cfg.artfctdef.eog.artifact = artifact_EOG; %
cfg.artfctdef.muscle.artifact = artifact_muscle;
data_no_artifacts = ft_rejectartifact(cfg,data2);

% plot difference between conditions for channel 2
dataCond1 = [ data_no_artifacts.trial{data_no_artifacts.trialinfo == 1} ];
dataCond2 = [ data_no_artifacts.trial{data_no_artifacts.trialinfo == 2} ];
dataCond1 = reshape(dataCond1, size(data_no_artifacts.trial{1}, 1), size(data_no_artifacts.trial{2},2), []);
dataCond2 = reshape(dataCond2, size(data_no_artifacts.trial{1}, 1), size(data_no_artifacts.trial{2},2), []);
figure;
plot(mean(dataCond1(2,:,:),3)); hold on;
plot(mean(dataCond2(2,:,:),3),'r');
title('ERP for each condition for channel 2');
h = legend(conditions{:}); set (h, 'Interpreter', 'none')

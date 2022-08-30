% Difference with version of the script for YOUTUBE 
% - Use a different file location (so it could be included with the code)
% - Remove plotting
% - Added high pass filtering
% - add removing channe
% - add input filename
% - removed detrending
% - changed channel for rejection
% - fixed HP bug (forgot to set it)

% Arnaud Delorme, Aug 9th, 2022

% CHANGE THRESHOLDS
clear
fileName = fullfile('..', 'data', 'sub-001_task-P300_run-2_eeg.set');
conditions  = { 'oddball_with_reponse' 'standard' };
removeChans = {'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp' };
frontalChannelsLowFreq = { 'AF7' 'AF3' 'Fp1' 'Fp2' 'Fpz' 'AFz' };
temporalChannelsHiFreq = { 'T7' 'T8' 'TP7' 'TP8' 'P9' 'P10' };

cfg                         = [];
cfg.dataset                 = fileName;
cfg.trialfun                = 'ft_trialfun_eeglabdemo'; % this is the default
cfg.trialdef.eventtype      = 'stimulus';
cfg.trialdef.eventvalue     = conditions; % the values of the stimulus trigger for the three conditions
cfg.trialdef.prestim        = 1; % in seconds
cfg.trialdef.poststim       = 2; % in seconds
cfg = ft_definetrial(cfg);
cfg.hpfreq = 0.5;
cfg.hpfilter = 'on';
data = ft_preprocessing(cfg);

% select channels
cfg = [];
cfg.channel = setdiff(data.elec.label, removeChans);
data2 = ft_preprocessing(cfg,data);

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

% export data to EEGLAB
EEG = fieldtrip2eeglab(data_no_artifacts);
EEGcond1 = pop_select(EEG, 'trial', find(data_no_artifacts.trialinfo == 1));
EEGcond2 = pop_select(EEG, 'trial', find(data_no_artifacts.trialinfo == 2));
pop_saveset(EEGcond1, 'filename', [ fileName(1:end-4) '_cond1_fieldtrip.set' ]);
pop_saveset(EEGcond2, 'filename', [ fileName(1:end-4) '_cond2_fieldtrip.set' ]);

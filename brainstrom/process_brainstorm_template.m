% This script is part of the code used to generate the results presented in:
% Delorme A. EEG is better left alone. Sci Rep. 2023 Feb 9;13(1):2372. doi: 10.1038/s41598-023-27528-0. PMID: 36759667; PMCID: PMC9911389.
% https://pubmed.ncbi.nlm.nih.gov/36759667/
%
% This contains the code for the optimal Brainstorm pipeline in the paper above.
% An example dataset is provided in the data folder.
% Simple plotting for one channel for the two conditions is provided at the end of the script.
%
% Requires to have Brainstorm installed
% Tested successfully with Brainstorm version of 05-Aug-2022
% Brainstorm is being used in server mode so the GUI will not pop up
% Note: Brainstorm is primarily a GUI software. Most of the code below
%       is undocumented so use at your own risk. If you encounter problems,
%       start Brainstorm at least once and create a protocol manually.
%
% Arnaud Delorme, 2022

% Difference with version of the script shown on YOUTUBE
% - reworked code to import epoched data trials
% - remove some plotting and added custom code to plot one channel (could not remove all)
% - removed code for DC offset
% - added code to handle occasional crash

% beginning of parameters ************

% You may select your own file and conditions below
clear
fileName = fullfile('..', 'data', 'sub-001_task-P300_run-2_eeg.set'); % file name to process
conditions  = { 'oddball_with_reponse' 'standard' }; % conditions
badChans = {'EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7','EXG8','GSR1','GSR2','Erg1','Erg2','Resp','Plet','Temp'}; % list of channels to ignore if any
epochLimits = [-0.3 0.7];

% end of parameters ************

if ~brainstorm('status')
    brainstorm server
end

% Delete protocol if it exist and re-create it
protocol   = 'TestPipeline'; 
brainstorm_path = bst_get('BrainstormDbDir');
iProtocol = bst_get('Protocol', protocol);
if ~isempty(iProtocol)
    gui_brainstorm('DeleteProtocol', protocol);
end
try
    gui_brainstorm('CreateProtocol', protocol, 1, 1);
catch
    % to handle occasional crash
    rmdir(fullfile(brainstorm_path, protocol), 's');
    gui_brainstorm('CreateProtocol', protocol, 1, 1);
end

% These default options might reduce questions that prompt users
ImportOptions = db_template('ImportOptions'); 
ImportOptions.ChannelAlign = 0;
ImportOptions.DisplayMessages = 0;
OutputFile = import_raw(fullfile(pwd, fileName), 'EEG-EEGLAB', [], ImportOptions); % need absolute path

% Input file
posNewSubject = strfind( OutputFile{1}, 'NewSubject');
sFiles = { OutputFile{1}(posNewSubject:end) };

% In case there are bad channels 
if ~isempty(badChans)
    sFiles = bst_process('CallProcess', 'process_channel_setbad', sFiles, [], 'sensortypes', badChans);
end

% Process: High-pass
sFiles = bst_process('CallProcess', 'process_bandpass', sFiles, [], ...
    'sensortypes', 'MEG, EEG', ...
    'highpass',    0.5, ...
    'lowpass',     0, ...
    'tranband',    0, ...
    'attenuation', 'strict', ...  % 60dB
    'ver',         '2019', ...  % 2019
    'mirror',      0, ...
    'read_all',    0);

sFiles = bst_process('CallProcess', 'process_evt_detect_badsegment', sFiles, [], ...
     'timewindow',  [], ...
     'sensortypes', 'EEG', ...
     'threshold',   5, ...  % 5 is conservative
     'isLowFreq',   1, ...
     'isHighFreq',  1);

% Process: Rename events so they are rejected (prefix bad)
sFiles = bst_process('CallProcess', 'process_evt_rename', sFiles, [], ...
    'src',   '40-240Hz', ...
    'dest',  'bad_40-240Hz');

% Process: Rename events so they are rejected (prefix bad)
sFiles = bst_process('CallProcess', 'process_evt_rename', sFiles, [], ...
    'src',   '1-7Hz', ...
    'dest',  'bad_1-7Hz');

% Process: Re-reference EEG not advised because it decreases the number of signficant electrodes
% as indicated in the paper referenced at the beginning
if 0 
    sFiles = bst_process('CallProcess', 'process_eegref', sFiles, [], ...
        'eegref',      'AVERAGE', ...
        'sensortypes', 'EEG');
end

% extract epochs
sFilesEpochs1 = bst_process('CallProcess', 'process_import_data_event', sFiles, [], ...
    'subjectname', 'NewSubject', ...
    'condition',   '', ...
    'eventname',   strcat(conditions{1}, ',', conditions{2}), ...
    'timewindow',  [], ...
    'epochtime',   epochLimits, ...
    'createcond',  1, ...
    'ignoreshort', 1, ...
    'usectfcomp',  1, ...
    'usessp',      1, ...
    'freq',        [], ...
    'baseline',    []);

% last rejection of bad epochs
sFilesEpochs1 = bst_process('CallProcess', 'process_detectbad', sFilesEpochs1, [], ...
    'timewindow', [], ...
    'eeg',        [-200, 200], ...
    'ieeg',       [0, 0], ...
    'eog',        [0, 0], ...
    'ecg',        [0, 0], ...
    'rejectmode', 2);  % Reject the entire trial

close;

% Read data and plot one channel
prot = bst_get('ProtocolInfo');
brainstorm_path = bst_get('BrainstormDbDir');
cond1Data = {};
cond2Data = {};
for iEpoch = 1:length(sFilesEpochs1)
    epochStruct = load('-mat', fullfile(brainstorm_path, protocol, 'data', sFilesEpochs1(iEpoch).FileName));
    if     contains(epochStruct.Comment, conditions{1})  cond1Data{end+1} = epochStruct.F;
    elseif contains(epochStruct.Comment, conditions{2})  cond2Data{end+1} = epochStruct.F;
    end
end
cond1Data = reshape([ cond1Data{:} ], size(cond1Data{1},1), size(cond1Data{1},2), []);
cond2Data = reshape([ cond2Data{:} ], size(cond2Data{1},1), size(cond2Data{1},2), []);
figure;
plot(mean(cond1Data(2,:,:),3)); hold on;
plot(mean(cond2Data(2,:,:),3),'r');
title('ERP for each condition for channel 2');
h = legend(conditions{:}); set (h, 'Interpreter', 'none')

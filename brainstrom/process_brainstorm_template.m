% Difference with Youtube script
% - change location of the file
% - remove commented text
% - remove plotting (could not remove all)
% - reworked code to import epoched data trials
% - add input filename
% - removed code for DC offset

% Arnaud Delorme, Aug 9th, 2022

clear
fileName = fullfile('..', 'data', 'sub-001_task-P300_run-2_eeg.set'); % file name to process
conditions  = { 'oddball_with_reponse' 'standard' }; % conditions
badChans = {}; % list of bad channels
epochLimits = [-0.3 0.7];

if ~brainstorm('status')
    brainstorm server
end

% Delete protocol if it exist and re-create it
protocol   = 'TestEEGLAB';
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
    sFiles = bst_process('CallProcess', 'process_channel_setbad', sFiles, [], 'sensortypes', removeChans);
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

% Process: Re-reference EEG
if 0 % not advised because it decreases the number of signficant electrodes
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

% export data to EEGLAB
if 0
    % save epochs as EEGLAB format, requires to have EEGLAB 2022.1 or later installed
    EEGcond1 = brainstorm2eeglab(sFilesEpochs1, conditions{1});
    EEGcond2 = brainstorm2eeglab(sFilesEpochs1, conditions{2});
    pop_saveset(EEGcond1, 'filename', [ fileName(1:end-4) '_cond1.set' ]);
    pop_saveset(EEGcond2, 'filename', [ fileName(1:end-4) '_cond2.set' ]);
end
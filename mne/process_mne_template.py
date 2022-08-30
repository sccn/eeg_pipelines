#!/usr/bin/env python

# Difference with YOUTUBE version
# - read EEGLAB file directly instead of using BIDS (so the local file to the BIDS repo can be used)
# - removed montage (this was not necessary)
# - removing ICA (did nothing)
# - remove average and plotting
# - export two files, one for oddball and one for standard
# - added notch
# - remove jupyter notebook sections

# This is the best MNE automated EEG pipeline parameters based on processing data
# from 3 EEG experiments

# Arnaud Delorme, Aug 9th, 2022

# -----------------
# Parameters
# -----------------

filename = '../data/sub-001_task-P300_run-2_eeg.set'
rmChans  = ['EXG1', 'EXG2', 'EXG3', 'EXG4', 'EXG5', 'EXG6', 'EXG7', 'EXG8', 'GSR1', 'GSR2', 'Erg1', 'Erg2', 'Resp', 'Plet', 'Temp']
cond1    = 'oddball_with_reponse'
cond2    = 'standard'
epochLowLim = -0.3;
epochHiLim  = 0.7;

# -----------------
# End of parameters (no edits below)
# -----------------

import mne
import os
import sys
from mne.datasets import sample
import autoreject

# Import, channel removal, reference and filtering
raw = mne.io.read_raw_eeglab(filename)

# Remove channels which are not needed
raw.drop_channels(rmChans)

# Filter teh data
raw.filter(l_freq=0.5, h_freq=None)

# Extract epochs
events_from_annot, event_dict = mne.events_from_annotations(raw)
epochs_all = mne.Epochs(raw, events_from_annot, tmin=epochLowLim, tmax=epochHiLim, event_id=event_dict, preload=True, event_repeated='drop')
epochs = epochs_all[cond1, cond2]

# Automated epoch rejection
ar = autoreject.AutoReject(n_interpolate=[1, 2, 3, 4], random_state=11,n_jobs=1, verbose=True)
ar.fit(epochs[:20])  # fit on a few epochs to save time
epochs_ar, reject_log = ar.transform(epochs, return_log=True)

# Export to EEGLAB format
fileout = os.path.splitext(filename)[0];
fileout_cond1 = fileout + '_cond1_mne.set'
fileout_cond2 = fileout + '_cond2_mne.set'
epochs_ar[cond1].export(fileout_cond1, overwrite=True)
epochs_ar[cond2].export(fileout_cond2, overwrite=True)


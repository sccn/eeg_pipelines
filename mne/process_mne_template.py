#!/usr/bin/env python

# This script is part of the code used to generate the results presented in:
# Delorme A. EEG is better left alone. Sci Rep. 2023 Feb 9;13(1):2372. doi: 10.1038/s41598-023-27528-0. PMID: 36759667; PMCID: PMC9911389.
# https://pubmed.ncbi.nlm.nih.gov/36759667/
#
# This contains the code for the optimal MNE pipeline in the paper above. 
# An example dataset is provided in the data folder.
# Simple plotting for one channel for the two conditions is provided at the end of the script.
#
# Requires to have Python installed, with mne, autoreject libraries
# Tested successfuly with Python 3.8 and MNE 1.1.0, and autoreject 0.3.1
#
# Arnaud Delorme, 2022

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
import matplotlib.pyplot as plt
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
    
# Export to EEGLAB format if needed
fileout = os.path.splitext(filename)[0];
fileout_cond1 = fileout + '_cond1_mne.set'
fileout_cond2 = fileout + '_cond2_mne.set'
epochs_ar[cond1].export(fileout_cond1, overwrite=True)
epochs_ar[cond2].export(fileout_cond2, overwrite=True)

# Plot one of the channels
plt.plot(epochs_ar[0].times, epochs_ar[0].get_data()[0,1,:].transpose())
plt.plot(epochs_ar[1].times, epochs_ar[1].get_data()[0,1,:].transpose())
plt.legend([cond1,cond2])
plt.show()

![Screen Shot 2023-03-13 at 8 14 04 PM](https://user-images.githubusercontent.com/1872705/224911989-4e8f2971-5f6a-469f-9022-b8eac2953346.png)

# Why is EEG better left alone?

The best is to read the article. In short, for standard, relatively clean EEG, removing artifacts cannot compensate for the loss of statistical power due to the reduced number of data trials. 

https://www.nature.com/articles/s41598-023-27528-0

# Content of this repository

This repository contains 4 stand-alone pipelines (along with one test dataset), in EEGLAB, Fieldtrip, Brainstorm, and MNE. The pipelines have been optimized to process event-related potential and are described in the manuscript above. The pipelines run on the sample data provided here. They do require a separate installation of the corresponding software packages.

Based on our scanning of the parameter space for artifact rejection and preprocessing, these are the **best EEG pipelines** for EEGLAB, Fieldtrip, Brainstorm, and MNE to process ERP. Test them yourself by plugging in your data.

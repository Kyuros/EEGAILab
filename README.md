<p align="center">
  <img src="images/logo.png">
</p>

## About The Project
EEGAILab is a novel machine learning framework designed to predict long-term treatment outcomes of spinal cord stimulation for patients with chronic lower back pain. The framework analyzes resting-state electroencephalography (EEG) signals at baseline. This spectrum analysis uses a machine learning algorithm, support vector machines, to capture key frequencies and dipole sources in the brain that contribute to treatment outcome prediction. This framework provides clinicians with a non-invasive technique to predict which patients respond the best to spinal cord stimulation. Below is a figure showing the multi-stage framework.

<p align="center">
  <img src="images/framework.png">
</p>

Each stage (1-5) has an intermediate output in the `processed_data` folder. The details and input/output of each stage is listed below.
- **<u>EEG Data</u>:** The data provided is 10 minutes of resting-EEG which has been: preprocessed, bandpass filtered from 1-100Hz, and truncated into 6 second epochs. Independent component analysis was used to unmix the EEG signals into independent components. Dipole locations were fit for each component and manually screened for noise.

- **<u>Stage 1</u>:** EEG data is first converted to the power spectral density (PSD) with a fourier transform using EEGLAB. Each frequency will be used as a feature in the machine learning algorithm. Data is then saved as a .mat file to speed up computations.

- **<u>Stage 2</u>:** The PSD is organized into an excel sheet where rows are subjects and columns are single frequencies to make it readable for machine learning. Each data point is the power at that frequency.

- **<u>Stage 3</u>:** SVM models are generated using the frequencies as features. A total of 6 models are made according to the powerbands: `All: 1-100Hz`, `Delta: 1-4Hz`, `Theta: 4-8Hz`, `Alpha: 8-13Hz`, `Beta: 13-30Hz`, and `Gamma: 30-100Hz`. For example, the beta powerband model will only have frequencies 13 to 30Hz. SVM models are trained with a default of 10 iterations of 3-fold cross-validation.

- **<u>Stage 4</u>:** A detailed spreadsheet is compiled about each component's XYZ coordinates in MNI space, location in brain region (hemisphere, lobe, and gyrus), and residual variance. A ranking system was used to rank components based on feature weight and related power. The power, score, and rank of each component is also included.

- **<u>Stage 5</u>:** Power and dipole visuals are generated based on the top 10 ranked components from each subject. The components are the most important dipoles based on the SVM models. A power comparison between the groups is calculated onto an excel spreadsheet while the same dipoles are plotted on a standard MRI brain.

 

## Getting Started
### Prerequisites
The following is a list of items and links with how to install them. The framework will work the best with the specific version numbers. Plugins are installed with EEGLAB.
* [MATLAB 2019b](https://www.mathworks.com/products/matlab.html)
* [LIBSVM v3.24](https://github.com/cjlin1/libsvm/tree/v324)
* [EEGLAB v2021.1](https://github.com/sccn/eeglab/tree/eeglab2021.1)
* ICLabel v1.3.*
* dipfit v4.3.*
* SASICA v1.3.8.*

**EEGLAB Plugin*

### LIBSVM Installation
1. Navigate to the LIBSVM GitHub (v324) [link](https://github.com/cjlin1/libsvm/tree/v324).
2. **Download the ZIP** from the **Code** dropdown menu.
3. Open MATLAB and navigate to the following LIBSVM folder as the current directory.
```matlab
 libsvm/matlab/
```
4. Type and run `>> make` in the Command Prompt. If it does not work, try `>> mex -setup` to choose a compiler for mex, then type `>> make` for installation. If problems persist refer to the README in the same folder.
5. Mex files `'libsvmread.mex'`, `'libsvmwrite.mex'`, `'svmtrain.mex'`, and `'svmpredict.mex'` should be built after a successful installation.

### EEGLAB (+Plugins) Installation
1. Navigate to the EEGLAB toolbox from the GitHub (eeglab2021.1) [link](https://github.com/sccn/eeglab/tree/eeglab2021.1).
2. **Download the ZIP** from the **Code** dropdown menu.
3. Open MATLAB and navigate to the EEGLAB folder as the current directory.
4. Type and run `>> eeglab` in the Command Prompt to add necessary paths and open EEGLAB.
5. To install plugins go to `File > Manage EEGLAB extensions`
6. Select a plugin and click the **Install/Update** button.
<p align="center">
  <img src="images/plugins.png">
</p>

## Usage
1. Start MATLAB
2. Navigate to the EEGAILab folder
3. Open and run `main.m`

The code can be run as is and can be adjusted to accomodate different EEG data. All current data in the `data` folder is already preprocessed. There are several adjustable variables in the main file which are listed below.

* **Subject IDs**: A vector of unique IDs for each subject. Ex. `[1,2,3,4,5]`
* **Binary Class Labels**: A vector of associated class labels as 1 and -1. Ex. `[1,-1,1,-1,1]`
* **Overwrite**: Overwrite data in stages 1-3 with 'Y' and keep data with 'N' when rerunning code. Ex. `'Y'`
* **Top Number of Components**: The number of components used per subject in a power comparison. Ex. `3`
* **SVM Parameters**
  * **N**: The number of iterations for cross-validation. *Default = `10`*
  * **n_fold**: The number of folds in cross-validation repeated *N* times. *Default = `3`*
  * **feature_sel**: Use feature selection `['N'/'Y']`. *Default = `'N'`*
  * **pval**: P-value for when feature selection is used. *Default = `1`*
  * **weight**: Type of weight used in ranking `['final'/'cv']`. *Default = `'final'`*


## Roadmap
- [ ] Add Changelog
- [ ] Add Component Selection via EEGLAB
- [ ] Revise Language
- [ ] Test Run Installation

## Contact
Useful resources
* [ICLabel Component Labeling Practice](https://labeling.ucsd.edu/tutorial)

## Last Updated
January 3rd, 2022
## [0.0.2] - 2022-06-20
### Changed
- `train_svm.m` now uses separate training and testing variables, x_train and x_test, instead of referencing with training and testing indices, train_ind and test_ind.

## [0.0.1] - 2022-01-06
### Added
- `changelog.md`
- `main.m` now creates the *"processed_data"* folder in addition to the *"stage"* subfolders.
- `README.md` now accounts for Windows and Mac differences.
- `README.md` now lists plugins in the EEGLAB (+Plugin) Installation section.
- `README.md` now lists subdirectories and their functions.
- `README.md` now has expected outputs.
- `README.md` now has contact details and references.
### Changed
- `/src` has improved directory reading which now only reads necessary files.
- `main.m` now adds relevant paths needed from `/src`.
- `README.md` descriptions have been updated.
### Fixed
- `strcat` replaced with `fullfile` in `src` for Mac-compatibility when creating and referencing directories.

## [0.0.0] - 2022-01-03
### Added
- EEGAILab code and tools.
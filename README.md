# RNA-Analysis-Toolbox
This repository provides the boilerplate for the analysis of risk &amp; ambiguity task, as developed by the Levy Lab.

## How to use this toolbox
For now, fork it and re-name it for use with your particular dataset. In the future, hopefully, import it as an R library.

## Expected input
The analysis scripts in this repository expect a tidy CSV file with particular columns. Here's how you can get it from our current projects:

### Any task based on PsychTaskFramework
1. From the root folder of PsychTaskFramework, run `exportTaskData(nameOfYourTask, outputFile)`. The script expects that your data are saved in `tasks/nameOfYourTask/data/`; if they aren't, put them there.
2. Place the output file in `data/` in your copy of this repository.
2. Run `preprocess/PsychTaskFramework.R` from this repository on the output file.

### PsychToolbox-based study of veterans (VA Risk, VA_fMRI_PTB)
1. Assuming that you run the analysis of created new `fitpar` data files, run `coeffs2csv.m` as `coeffs2csv(pathToFitpars, outputDirectory)`.
2. Place `choices.csv` in `data/` in your copy of this repository.
3. Run `preprocess/PTBTask.R` from this repository on the output file.

### Tasks based on E-Prime
1. Merge all the .edat2 files in the task folder with E-Merge. (This will require a prior installation of E-Prime, even though you should be able to do this without an activated license.)
2. Open the newly created merged file with E-DataAid and Save as/Export as "SPSS and StatView".
3. Read in the exported file with R: `read.table('file.txt', header = TRUE, sep = '\t', as.is = TRUE, fileEncoding = 'UTF-16LE')`. 
4. Drop the columns that you don't need.
5. Use or export to CSV as needed.

## Functionality
### Extract model-free features

### Compute model-based fits in R with nloptr
### Compute model-based fits in Matlab with fmincon


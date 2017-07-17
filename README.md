# levylab.RNA
This package provides reusable code for the analysis of risk &amp; ambiguity task data, as developed by the Yale Decision Neuroscience Lab.

## How to use this toolbox
Simple invoke `library(levylab.RNA)` in your R session or your R code.

### Installation
1. `install.package('devtools')` 
2. `library(devtools)`
3. `devtools::install_github('YaleDecisionNeuro/levylab.RNA')`

**For extracting model-based features, you will also need to install [nlopt](http://ab-initio.mit.edu/wiki/index.php/NLopt).**

## Expected input
The analysis scripts in this repository expect a tidy CSV file with particular columns. Here's how you can get it from our current projects:

### Any task based on PsychTaskFramework
1. From the root folder of PsychTaskFramework, run `exportTaskData(nameOfYourTask, outputFile)`. The script expects that your data are saved in `tasks/nameOfYourTask/data/`; if they aren't, put them there.
2. Run `importFromPTF(outputFile)`.

### PsychToolbox-based study of veterans (VA Risk, VA_fMRI_PTB)
1. Get all the raw `.mat` files together in a single directory - let's call it `originDirectory`.
2. Run `importFromRawMat(file)` on each `.mat` file in the repository.

### Tasks based on E-Prime
1. Merge all the .edat2 files in the task folder with E-Merge. (This will require a prior installation of E-Prime, even though you should be able to do this without an activated license.)
2. Open the newly created merged file with E-DataAid and Save as/Export as "SPSS and StatView".
3. Read in the exported file with R: `importFromEprimeSPSSExport(filename, choiceColumnName = "choice", discardOriginalColumns = FALSE)`.
4. Drop the columns that you don't need manually, or import with `discardOriginalColumns = FALSE`.
5. Use or export to CSV as needed.

## Functionality
### Extract model-free features
Run `getModelFreeEstimates(decision_data)` on a clean R&A data frame.

### Compute model-based fits in R with nloptr
Run `getModelBasedEstimates(decision_data)` on a clean R&A data frame.

### Compute model-based fits in Matlab with fmincon
1. Save the clean R&A data frame as CSV with `write.csv(clean.df, paste0('clean/', filename), row.names = FALSE)`. 
2. Locate the matlab files with `system.file("matlab", "fit_matlab_model.m", package = "levylab.RNA")`.
3. Change the clean choice file location in that file accordingly and run in Matlab.

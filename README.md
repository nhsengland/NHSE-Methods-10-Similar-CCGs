## NHSEI Methods: 10 Similar CCGs


### About this method

The CCG similar 10 method provides a list of 10 other CCGs for each CCG that are “similar” to them in terms of a set of variables including elements such as size, demographics, deprivation, and ethnicity. 
The peers are used in RightCare data products, the Model Health System and Viewpoint (including PCN Dashboard). They are used in these products/ platforms to provide an appropriate benchmarking group for indicators that are dependent on demographic factors such as deprivation and ethnicity.  
For more information about the method, including how is being used, when and by who, please refer to the Methods toolbox documentation on our [FutureNHS workspace](https://future.nhs.uk/DataMeth/grouphome).


### Requirements

It is required that the input file is in the same working directory as where the R code is being executed. 
It is important that the same number of variables (as listed in data sources) are used in the input file and the header names in the input file remain the same
The following packages are required to be installed in R:
•	readxl
•	writexl
•	dplyr
•	tidyr
•	propagate
•	reshape2


### Usage
The R file takes as input one Excel file which has two worksheets:
•	Variable Data: variable data on CCG level
•	Variable Descriptions: descriptions of the variables and the weights associated with each
And produces one output Excel file which has 4 worksheets: 
•	CCG similar matrix: This is a matrix of all CCGs similarity values.
•	Top 10 CCG similarity values: This is a table for the top 10 CCGs similarity values for each CCG.
•	Top 10 CCG names: This is a table of the top 10 CCGs names for each CCG.
•	Top 10 CCG codes: This is a table of the top 10 CCGs codes for each CCG.
Each year, the input file is modified with the latest data and the filepaths are changed in the code to reflect the latest year – line 37, lines 41-42 and line 203. The file is then saved with the same version number and we change the date in the filename to reflect the updated save date.
No other modifications are usually made to the code.
If there are more variables that are required as input, then the code would need updating. 


### Summary of the code

A 2-stage approach is used:
1. Each variable is validated and standardised by:
   a) Capping each variable value at 5 standard deviations over the mean – to avoid 
       outlier effects.
   b) Taking square root of all values – to reduce skew 
   c) Subtract mean and divide by the standard deviation (of square-rooted values)
2. A calculation of similarity (Euclidean distance) is then completed - this uses the standardised variables for two CCGs in each pair from the first stage of this approach and the weights associated with each variable. 
This produces a distance matrix, ranking the similarity distance between each CCG. The similar CCGs are those with the lowest value in this matrix. 
10 steps in R code:
There are overall 10 steps in the code which use the 2-stage approach as mentioned above. The steps are as follows:
1.	R libraries are loaded
2.	Working directory is set. And input files and sheets are loaded.
3.	Summary statistics table created for each variable. This has the median, average, standard deviation, 10th percentile, 90th percentile, skew, maximum and 5 standard deviations over the mean.
4.	Summary statistics table combined with the original data input, to perform a calculation to reduce skew.
5.	Another summary statistics table created for each variable, using the reduce skew value. This has the median, average, standard deviation, 10th percentile, 90th percentile, skew, maximum and 5 standard deviations over the mean.
6.	Variables are standardised
7.	Columns are selected from the standardised table
8.	Similarity calculated between every pair of CCGs
9.	Final outputs created for the different worksheets in the output file.
10.	Written as output to Excel file. 


### Data sources

1. The average Index of Multiple Deprivation (2019) score in the LSOAs where CCGs' registered patients lived in April 2020 - Department of Communities and Local Government (DCLG), Fingertips
2. The total population registered with CCGs' practices (April 2020) - NHS Digital
3. % of population age 18 to 39 (April 2020) -	NHS Digital
4. % of population age 65 to 84 (April 2020) -	NHS Digital
5. % of population age 85+  (April 2020) -	NHS Digital
6. % of population who live in areas defined by the ONS Rural Urban  Classification as "Rural town and fringe in a sparse setting", "Rural village and dispersed" or "Rural village and dispersed in a sparse setting" (April 2018)	- NHS Digital
7. The percentage of people who said they are of white (non-British) ethnic origin (GP Patient Surveys 2017, 2018 and 2019) - GPPS
8. The percentage of people who said they are of Mixed ethnic origin (GP Patient Surveys 2017, 2018 and 2019) - GPPS
9. The percentage of people who said they are of Asian ethnic origin (GP Patient Surveys 2017, 2018 and 2019) - GPPS
10. The percentage of people who said they are of Black ethnic origin (GP Patient Surveys 2017, 2018 and 2019) - GPPS
11. The percentage of people who said they are of Arab or Other ethnic origin (GP Patient Surveys 2017, 2018 and 2019)  - GPPS


### Authors

Sadia Javed, Analyst (RightCare & Population Health) - sadia.javed@nhs.net
Rob Shaw, Head of Forecasting (Data and Analytics) - robert.shaw4@nhs.net


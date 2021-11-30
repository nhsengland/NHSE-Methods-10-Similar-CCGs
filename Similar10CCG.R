## R script to apply Similar 10 CCGs method

StartTime = Sys.time()

#1: load libraries ###############################################################################################################
library(readxl) ##needed to read the file in from excel
library(writexl) ##needed to write to an excel file
library(dplyr) ##needed for general data manipulation, like the %>% 
library(tidyr) ##needed for tidying data, e.g. gather, spread
library(propagate) #needed for the skewness function
library(reshape2) #used for the dcast function, to manipulate tables

#2: set working directory, input files and load sheets #############################################################################################
#Set working directory
WorkingDirectory="//ims.gov.uk/NHS_England/NW098/NHS CB/RightCare_Analysis/Adhoc/Tasks/Similar CCGs/April 2021/R/"  
setwd(WorkingDirectory) 

#Read in the CCG data Excel file and both sheets from it.
DataInput = read_excel("April2021_Similar10CCG_InputData_HD.xlsx", sheet = "Variable Data")
VarDesc = read_excel("April2021_Similar10CCG_InputData_HD.xlsx", sheet = "Variable Descriptions")

#3. create summary statistics table for each variable #############################################################################################
#Do the following calculations- the average, median, stdev, p10, p90, skew, 5sd over mean and max for each variable (column) onn the DataInput variable columns
#Put this into a data frame, ready for manipulation
SummaryStats_Table <- as.data.frame(sapply(DataInput[,3:13]
                                   , function(x) c(median = median(x), avg = mean(x), stdev = 	sd(x)*((length(x)-1)/length(x))^0.5, quantile(x, c(.10, .90)), skew = skewness(x), max = max(x))))

#Add a column for each calculation type and remove the rownames (which showed the same (calcuation type), but weren't actually a column in the data frame)
SummaryStats_Table <- cbind(Calculation = rownames(SummaryStats_Table), SummaryStats_Table)
rownames(SummaryStats_Table) <- NULL

#Gather the CCG summary statistics table, into key-value pairs (long form), the variables then become key (Variable) and the variable values are then the value (Value)
SummaryStats_Table_Long <- gather(SummaryStats_Table, "ID", "Value", 2:12 )

#Spread the CCG summary statistics long table form, so that the Variable types are in the left-most 1st column and the Calculation types are row headings after this column,
#representing a calculation type for each variable.
#Add a column to calculate the 5 standard deviations over the mean and add a repeat column to show Variable as factor.
SummaryCalcs <- spread(SummaryStats_Table_Long, "Calculation", "Value") %>%
                        mutate(five_sd_over_mean = 5*stdev+avg) %>%
                        mutate(Variable = as.factor(ID))

#Put the SummaryCalcs table back into long form (now with the additional new column). This table is used later in the code on a join. 
SummaryCalcs_Long <- gather(SummaryCalcs, key = "ID", value = "Value", 2:9) %>%
                         rename(Calculation = ID)

#4. combine summary statistics table with the original data input, to perform a calculation to reduce skew #############################################################################################
#Gather the DataInput (CCG data) into key-value pairs (long form), the variables then become key (ID) and the variable values are then the value (Value).
DataInput_Long <- gather(DataInput, "Variable", "Value", 3:13) 

#Join onto the long format of the original data input table, by joining on the Variable columns. 
#This outputs every CCG, variable, it's value, calculation type and the value of the calculation.
#These columns are then used to produce another column to calculate square root of the minimum value from the Value of the variable and the 5 standard deviations over the mean,
# this is done to reduce skew.
Calc_ReduceSkew <- mutate(DataInput_Long, Variable = as.factor(Variable)) %>%
                                 left_join(y = SummaryCalcs_Long, by = c("Variable" = "Variable")) %>% 
                                 spread("Calculation", "Value.y") %>%
                                 rename(Value = Value.x) %>%
                                 mutate(reduce_skew = sqrt(pmin(Value, five_sd_over_mean))) %>%
                                 dplyr::select(CCGcode, name, Variable, reduce_skew) %>%
                                 rename(Value = reduce_skew)

#5. create summary statistics table for each variable, using the reduce skew value #############################################################################################
#Spread the Variable column using the Calc_ReduceSkew into separate columns for each type of variable, this is shown by CCG and the values are the reduce skew values.
#Do the following calculations- the average, median, stdev, p10, p90, skew, 5sd over mean and max for each variable (column) on the reduce skew data.
#Put this into a data frame, ready for manipulation
SummaryStats_Table_ReduceSkewValues <- spread(Calc_ReduceSkew,"Variable", "Value")
SummaryStats_Table_ReduceSkewValues <- as.data.frame(sapply(SummaryStats_Table_ReduceSkewValues[,3:13]
                                , function(x) c(median = median(x), avg = mean(x), stdev = 	sd(x)*((length(x)-1)/length(x))^0.5, quantile(x, c(.10, .90)), skew = skewness(x), max = max(x))))

#Add a column for each calculation type and remove the rownames (which showed the same (calcuation type), but weren't actually a column in the data frame)
SummaryStats_Table_ReduceSkewValues <- cbind(Calculation = rownames(SummaryStats_Table_ReduceSkewValues), SummaryStats_Table_ReduceSkewValues)
rownames(SummaryStats_Table_ReduceSkewValues) <- NULL

#Gather the CCG summary statistics table, into key-value pairs (long form), the variables then become key (Variable) and the variable reduce skew values are then the value (Value)
SummaryStats_Table_ReduceSkewValues_Long <- gather(SummaryStats_Table_ReduceSkewValues, "ID", "Value", 2:12 )

#Spread the CCG summary statistics for the reduce skew values into long table form, so that the Variable types are in the left-most 1st column and the Calculation types 
#are row headings after this column, representing a calculation type for each variable.
#Add a column to calculate the 5 standard deviations over the mean and add a repeat column to show Variable as factor.
#Join onto the variable descriptions sheet by the variable names.
SummaryCalcs_ReduceSkew <- spread(SummaryStats_Table_ReduceSkewValues_Long, "Calculation", "Value") %>%
                               mutate(five_sd_over_mean = 5*stdev+avg) %>%
                               mutate(Variable = as.factor(ID)) %>%
                               left_join(y = VarDesc, by = c("ID" = "Variable name"))

#Put the SummaryCalcs_ReduceSkew table back into long form (now with the additional new column). This table is used later in the code on a join. 
SummaryCalcs_ReduceSkew_Long <- gather(SummaryCalcs_ReduceSkew, key = "ID", value = "Value", 2:9,11)

#6. final stage of standardising variables #############################################################################################
#This outputs every CCG, variable, it's value, calculation type and the value of the calculation.
#These columns are then used to produce another column to which subtracts the mean and divides by the standard deviation (of the square-rooted values),
# this final stage is done to complete the standardisation of the variables.
standardised_variables <- left_join(x= Calc_ReduceSkew, y = SummaryCalcs_ReduceSkew_Long, by = c("Variable" = "Variable")) %>% 
                          spread("ID", "Value.y") %>%
                          rename(Value = Value.x) %>%
                          mutate(standardised = (Value - avg)/ stdev)

#7. columns are selected from the standardised table #############################################################################################
#table is spread so each CCG has a standardised value for each of the different variables
CCG_standardised <- dplyr::select(standardised_variables, CCGcode, name, Variable, standardised) %>%
                    spread("Variable", "standardised")

#8. calculate similarity between every pair of CCGs #############################################################################################
#create a function which takes the difference between two values and squares it
difference_squared <- function(x,y){
  (x - y)^2
}

#Create emtpy vectors to store CCG codes in and assign a variable for the number of unique CCGs
CCGa <- vector()
CCGb <- vector()
NumOfCCGs <- length(CCG_standardised$CCGcode)
#Stores unique CCG codes which repeat the full list of CCG codes NumOfCCGs times, after the last code e.g. A, B, C, A, B, C
CCGa <- rep(CCG_standardised$CCGcode, each = NumOfCCGs)
#Stores unique CCG codes which repeat each CCG code NumOfCCGs times and then moves onto the next code and repeats that NumOfCCGs times e.g. A, A, A, B, B, B, C, C, C
CCGb <- rep(CCG_standardised$CCGcode, times = NumOfCCGs)

#This function is created to help apply the difference squared function to all CCG combinations and for all the variables and create a data frame from it 
#i.e. A, A then A, B, then A, C etc.
combo_difference_squared <- function(X, fun){
                                f <- function(x, fun = myfunc){
                                  y <- lapply(seq_along(x), function(i){
                                    fun(x[i], x[-(NumOfCCGs+1)])
                                    })
                                  unlist(y)
                                  }
                                fun <- match.fun(fun)
                                res <- sapply(X, f, fun = fun)
                                as.data.frame(res)
                              }
#Uses the difference squared function on each CCG combo, for each of the variable columns using the standardised values in these columns,
#this data frame output doesn't have the CCG columns in 
combo_difference_squared <- combo_difference_squared(CCG_standardised[3:13], difference_squared)

#Adds on the CCG columns, and puts it into a long format so the variable types are in one column
#Variable column is then joined onto the variable description table to get the weights of each of the variables
#The weight of the variable is then multiplied by the difference squared value, this gives a weighted difference square values for 
#the CCGs for each CCG combo and for each of the variables.
#The variable types are then spread into a table with these as the row headings, the CCG A and CCG B codes in the first 2 columns and 
#the weighted difference square values within the table.
CCG_weighted_difference_squared <- as.data.frame(cbind(CCGa, CCGb, combo_difference_squared)) %>%
         gather(key = "Variable", value = "Value", 3:13) %>%
         left_join(y = VarDesc, by = c("Variable" = "Variable name")) %>%
         transform(Value = as.numeric(Value), Weights = as.numeric(Weights)) %>%
         mutate(weighted_diff_squared = Value*Weights) %>%
         dplyr::select(CCGa, CCGb, Variable, weighted_diff_squared) %>%
         spread("Variable", "weighted_diff_squared") 

#Adds a similarity column to the table above (which is a total and this sums the weighted difference squared values for all the variables, for each CCG combo) 
#and gives the similarity value for that CCG combo
CCG_similarity <- cbind(CCG_weighted_difference_squared, similarity = rowSums(CCG_weighted_difference_squared[3:13])) %>%
                  dplyr::select(CCGa, CCGb, similarity)

#9. create the final outputs #############################################################################################
#Produces a matrix, which has a first column of CCG codes, the column headings after this are CCG codes and below the column headings are the similarity values
CCGsimilar_matrix <- spread(CCG_similarity, "CCGb", "similarity") %>%
                     rename("CCG Code" = CCGa)

#Filters on those that don't have a similarity value of 0 and gets the top 10 CCGs for each CCG code (lowest similarity value)
top50<- CCG_similarity[order(CCG_similarity$CCGa, CCG_similarity$similarity),] %>%
        filter(similarity != 0) %>% 
        group_by(CCGa) %>% top_n(-10)

#Repeats numbers 1-10, 191 times and then adds this as a column onto the the top 50 table
Rank <- rep(c(1:10), times = NumOfCCGs)
rankedCCG <- cbind(Rank = Rank, top50) 

#Create a table which uses the Rank column as the first column, with the CCG codes as headings for the rest of the columns and the similarity values beneath these
top10_similarity_values <- dcast(rankedCCG, Rank ~ CCGa, value.var = "similarity")

#Joins onto the original data input table to get the CCG names, it produces a table which uses the Rank as the first column, with the CCG codes as headings for
#the rest of the columns and the name of the similar CCG beneath these.
top10_CCG_names <- inner_join(rankedCCG, DataInput, by = c("CCGb" = "CCGcode" )) %>%
                   dcast(Rank ~ CCGa, value.var = "name")

#Produces a table which uses the Rank as the first column, with the CCG codes as headings for the rest of the columns and the code of the similar CCG beneath these.
top10_CCG_codes <- dcast(rankedCCG, Rank ~ CCGa, value.var = "CCGb")


#8. write to an excel file, and for each sheet choose which data to present there #############################################################################################
write_xlsx(list("CCG similar matrix" = CCGsimilar_matrix, "Top 10 CCG similarity values" = top10_similarity_values, "Top 10 CCG names" = top10_CCG_names, "Top 10 CCG codes" = top10_CCG_codes), "April2021_Similar10CCG_OutputData_HD.xlsx")

EndTime = Sys.time()
EndTime - StartTime
#Time difference of 53.02597 secs



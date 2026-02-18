/*
Student Names: Dhairya Patankar & Li Ping Yu Zeng
*/

clear

*import data for the housing price indices of Manhattan, Queens, and Brooklyn over a 13 year period
import delimited "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\priceIndex_All.csv"

*format the date and get it ready to merge with other dataset
gen date = date(month, "YMD")
replace date = mofd(date)
format date %tm
tsset date

*keep only data after Jan 2012 inclusive*
keep in 85/242

*remove uncessessary variables*
drop month nyc

*create dummy variable for covid and set it equal to 1 after March 2020*
gen covid = 0
replace covid = 1 if date > 721

*save data in main working file*
save "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\Term_Paper_Unrestricted.dta", replace

*clear cache*
clear 

*import data for the average 30 year fixed mortgage rate across the USA from 2012 January to 2025 February
import delimited "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\MORTGAGE30US.csv"

*format the date to observe the data monthly
gen date = date(observation_date, "MDY")
format date %td
gen month = mofd(date)
format month %tm

*since the data is in weekly observations, generate the monthly average mortgage rate by taking the average of the weeks in the month
foreach x in observation_date{

	egen mortgage_rate = mean(mortgage30us), by(month)
	
}

*collapse the data to only have each month's average mortgage rate
collapse mortgage_rate, by(month)

rename month date

*merge the data sets*
merge 1:1 date using "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\Term_Paper_Unrestricted.dta"
drop _merge

*save merged data in main working file*
save "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\Term_Paper_Unrestricted.dta", replace

*clear the cache*
clear

*import data for the average unemployment rate in New York State from 2012 January to 2025 January
import delimited "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\NYUR.csv"

*format the date to observe the data monthly
gen date = date(observation_date, "MDY")
replace date = mofd(date)
format date %tm
drop observation_date

*merge the data sets*
merge 1:1 date using "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\Term_Paper_Unrestricted.dta"
drop _merge

*save merged data in main working file*
save "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\Term_Paper_Unrestricted.dta", replace

*clear cache*
clear

*import data for the state minimum wage in New York State*
import delimited "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\STTMINWGNY.csv"

*repeat the data for each year 12 times to simulate monthly data*
expand 12

*format the data in terms of dates*
gen year = date(observation_date, "YMD")
replace year = year(year)

*create the month variable assigned to each month's minimum wage*
bysort observation_date: gen month = _n
gen date = ym(year, month)
format date %tm

*drop the last 10 observations as the other data only goes until Feb 2025*
drop in 160/168

*remove the unecessary variables*
drop year month observation_date

rename sttminwgny min_wage

*merge data into main working file*
merge 1:1 date using "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\Term_Paper_Unrestricted.dta"
drop _merge

*drop feb 2025 data*
drop in 158/159

*standardize the minimum wage in terms of 2016 dollars in order to deflate them to match the units of the housing price index*
gen std_min_wage = min_wage/min_wage[49]

*show the summary statistics of the unrestricted dataset*
summarize

*save merged data in main working file*
save "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\Term_Paper_Unrestricted.dta", replace

*reduce dataset size to restricted version*
keep in 55/157

*show summary statistics of the restricted dataset 
summarize

save "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\Term_Paper_Restricted.dta", replace

*clear cache*
clear

*import the housing market characteristics data*
import delimited "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\RDC_Inventory_Core_Metrics_State_History.csv"

*remove non-New York Data*
drop if state_id != "NY"

*only keep the metrics that are needed*
collapse new_listing_count median_square_feet, by(month_date_yyyymm)

*convert the observation date variable into string type*
tostring month_date_yyyymm, generate(observation_date)
drop month_date_yyyymm

*convert observation date to proper date type to be able to merge with restricted data set*
gen date = date(observation_date, "YM")
replace date = mofd(date)
format date %tm
drop observation_date

*merge new variables with the restricted data set and create a new dataset for comparison*
merge 1:1 date using "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\Term_Paper_Restricted.dta"
drop _merge

*drop Feb 2025 observation*
drop in 104/104

*save the working file*
save "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\Term_Paper_Restricted_Variables.dta", replace

*show summary statistics of the restricted dataset with the addition of the new control variables*
summarize

*generate graphs showing the housing market indexes in each borough over time*
twoway (line manhattan date)
twoway (line brooklyn date)
twoway (line queens date)

*test for unit roots in all variables*
dfuller manhattan
dfuller L.manhattan
dfuller L2.manhattan
dfuller L3.manhattan
dfuller L4.manhattan
dfuller brooklyn
dfuller L.brooklyn
dfuller L2.brooklyn
dfuller L3.brooklyn
dfuller L4.brooklyn
dfuller queens
dfuller L.queens
dfuller L2.queens
dfuller L3.queens
dfuller L4.queens
dfuller covid
dfuller nyur
dfuller std_min_wage
dfuller mortgage_rate
dfuller new_listing_count
dfuller median_square_feet

*create a time variable to account for time trends in the data*
gen t = _n

*use the Engle-Granger test to see whether Manhattan and Brooklyn models are cointegrated as they follow a unit root process*
reg manhattan covid L.manhattan L2.manhattan L3.manhattan L4.manhattan nyur std_min_wage mortgage_rate median_square_feet new_listing_count t

predict mres, residuals
dfuller mres

reg brooklyn covid L.brooklyn L2.brooklyn L3.brooklyn L4.brooklyn nyur std_min_wage mortgage_rate median_square_feet new_listing_count t

predict bres, residuals
dfuller bres

*test whether the residuals are stationary by testing for cointegration*
gen lagmres = L.mres
gen deltamres = mres - lagmres
reg deltamres lagmres

gen lagbres = L.bres
gen deltabres = bres - L.bres
reg deltabres lagbres

*generate graphs of the residuals for the unit root processes to visually ensure they are stationary*
twoway (line mres date)
twoway (line bres date)

*as the residuals are stationary for the unit root processes, and the unit root processes cointegrate, we can run the OLS regression using HAC-Robust Standard Errors to estimate the long term effect of COVID-19 regulations on the monthly housing price index for each borough*
newey manhattan covid L.manhattan L2.manhattan L3.manhattan L4.manhattan nyur std_min_wage mortgage_rate median_square_feet new_listing_count t, lag(4)

newey brooklyn covid L.brooklyn L2.brooklyn L3.brooklyn L4.brooklyn nyur std_min_wage mortgage_rate median_square_feet new_listing_count t, lag(4)

newey queens covid L.queens L2.queens L3.queens L4.queens nyur std_min_wage mortgage_rate median_square_feet new_listing_count t, lag(4)

*save the working file*

save "C:\Users\dhair\OneDrive - University of Toronto\YEAR 3\SEMESTER 2\ECO475\Term Paper\Term_Paper_Restricted_Variables.dta", replace

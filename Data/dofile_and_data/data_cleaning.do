/*******************************************************************************
	
Effect of corruption perception on firm innovation

Author:Yuou Wu
Email: yw375@georgetown.edu
Created on: Feb.23th.2019

*******************************************************************************/
clear all
set more off

*Set file path
cd "/Users/yuouwu/Documents/Undergraduate/GUsenior/Thesis/Data"

global home "Users/yuouwu/Documents/Undergraduate/GUsenior/Thesis/Data"
*Create output folder
*if no existing output folder*
*mkdir Output
global OutputFolder "Output"
 
/*******************************************************************************
	Generating Data Files / Data Cleaning
*******************************************************************************/

 use "2006-2019.dta", replace

rename country countryyear2
rename stra_sector industry2
rename a3ax city2
rename a0 surveytype
rename a7 largefirm
rename a3 citysize
rename b2a domesticshare
rename b2b foreignshare
rename b2c govtshare
rename b5 startyear
rename b6b regyear
rename d2 annualsale
rename d3c directexport
rename e11 informal
rename n3 priorannualsale
rename j5 giftexpected
rename j6 govtcontract
rename j7a bribe
rename j30f corruption
rename l1 employee
rename l2 employeeprior
rename m1a corruptionrank1
rename h1 product
rename h5 process
rename e2 competitor
label var domesticshare "Domestic Private Share"
label var foreignshare "Foreign Share"
label var govtshare "Government Share"
label var size "Firm Size"
label var annualsale "Annual Sale Last Year"
label var process "Process"
label var product "Product"
label var largefirm "Part of a Large Firm"
label var bribe "Bribe Share"
label var competitor "Competition"

keep country industry2 size city2 citysize domesticshare foreignshare govtshare ///
startyear regyear annualsale govtcontract corruption bribe corruptionrank1 ///
largefirm informal region product process surveytype competitor strata wt wt_rs idstd

gen year=substr(country,-4,.)
gen country2=substr(country, 1, strpos(country,"2")-1)
destring year, replace
encode industry2, gen(industry)
encode city2, gen(city)
encode country2, gen(country)
encode countryyear2, gen(countryyear)
drop industry2 country2 city2 countryyear2


foreach var of varlist _all {
replace `var'=. if `var'==-9
replace `var'=. if `var'==-7
replace `var'=. if `var'==-8
replace `var'=. if `var'==-4
}
replace corruption=. if corruption<0
replace startyear=. if startyear<100 | startyear > 2018
replace largefirm=. if largefirm!= 1 & largefirm!= 2

*generate new variables*
gen age=year-startyear if startyear!=.
sum startyear
replace age=. if age<0
sum age
sort city 
by city : egen rcorruptsum = sum(corruption)
by city : egen rcount=count(corruption) if corruption!=.
by city : gen rleaveoutmean=(rcorruptsum-corruption)/(rcount-1)
sort  industry
by  industry: egen icorruptsum = sum(corruption)
by  industry: egen icount=count(corruption) if corruption!=.
by  industry: gen ileaveoutmean=(icorruptsum-corruption)/(icount-1)
sort city 
by city : egen rbribe = sum(bribe)
by city : egen rbcount=count(bribe) if bribe!=.
by city : gen rbleaveoutmean=(rbribe-corruption)/(rbcount-1)

gen lnsale=log(annualsale)
label var lnsale "Annual Sale (log)"

label var rleaveoutmean "Leave-out-mean Corruption (city)"
label var corruption "Corruption"
label var age "Firm Age"
label var industry "Industry"
label var informal "Competition from Informal Sector"
label var city "City"
gen competitor2=competitor-1 if competitor<5
replace competitor2=. if competitor2<0 | competitor2>3 
label var competitor2 "Competition"

*standardize dummy*
replace product=product-1
replace process=process-1
replace largefirm=largefirm-1
drop if surveytype==6

*competitor outlier*
/* gen competitor2=competitor
replace competitor2=. if competitor<0
replace competitor2=. if competitor>200
egen IQRcompetitor=iqr(competitor2)
egen P25competitor=pctile(competitor2), p(25) 
egen P75competitor=pctile(competitor2), p(75)
gen competitoroutlier=(competitor2>P75competitor+3*IQRcompetitor | competitor2<P25competitor-3*IQRcompetitor) if ///
competitor<. & IQRcompetitor <. & P25competitor<. & P75competitor<. 
gen competitorI= competitor if Icompetitor!=1
drop IQRcompetitor P25competitor P75competitor */

save clean_data.dta,replace

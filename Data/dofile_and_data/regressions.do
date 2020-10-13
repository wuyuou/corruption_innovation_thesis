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
	2020 update analysis by income groups
*******************************************************************************/

use "/Users/yuouwu/Documents/Undergraduate/GUsenior/Thesis/Data/clean_data.dta"
decode country,gen(cname)
replace cname="Burkina Faso" if cname=="BurkinaFaso"
replace cname="Costa Rica" if cname=="Costarica"
replace cname="Congo, Democratic Republic of the" if cname=="DRC"
replace cname="Dominican Republic" if cname=="DominicanRepublic"
replace cname="El Salvador" if cname=="ElSalvador"
replace cname="North Macedonia" if cname=="Fyr Macedonia"
replace cname="Gambia, The" if cname=="Gambia"
replace cname="Gambia, The" if cname=="Gambia "
replace cname="Guinea-Bissau" if cname=="GuineaBissau"
replace cname="Lao P.D.R." if cname=="LaoPDR"
replace cname="Montenegro, Rep. of" if cname=="Montenegro"
replace cname="Papua New Guinea" if cname=="PapuaNewGuinea"
replace cname="Sierra Leone" if cname=="SierraLeone"
replace cname="South Africa" if cname=="SouthAfrica"
replace cname="South Sudan" if cname=="Southsudan"
replace cname="Sri Lanka" if cname=="SriLanka"

merge m:1 cname using "/Users/yuouwu/Documents/Undergraduate/GUsenior/Thesis/Data/dofile and data/ccode_with_iso.dta",keep (3) nogen

***WEO Income Groups - 2 tiers***
gen is_advanced = inlist(ccode, 193, 122, 124, 156, 423, 935, 128, 939, 172, 132, 134, 174, 532, 176, 178, 436, 136, 158, 542, 941, 946, 137, 546, 181, 138, 196, 142, 182, 359, 135, 576, 936, 961, 184, 144, 146, 528, 112, 111)~=0
label var is_advanced "1=Advanced Economies"
gen is_edeconomy = inlist(ccode, 512, 914, 612, 614, 311, 213, 911, 314, 912, 313, 419, 513, 316, 913, 339, 638, 514, 218, 963, 616, 223, 516, 918, 748, 618, 624, 522, 622, 626, 628, 228, 924, 233, 632, 636, 634, 238, 662, 960, 611, 321, 243, 248, 469, 253, 642, 643, 734, 644, 819, 646, 648, 915, 652, 328, 258, 656, 654, 336, 263, 268, 944, 534, 536, 429, 433, 343, 439, 916, 664, 826, 967, 443, 917, 544, 446, 666, 668, 672, 962, 674, 676, 548, 556, 678, 867, 682, 684, 273, 868, 921, 948, 943, 686, 688, 518, 728, 836, 558, 278, 692, 694, 449, 564, 565, 283, 853, 288, 293, 566, 964, 453, 968, 922, 714, 862, 716, 456, 722, 942, 718, 724, 813, 726, 199, 733, 524, 361, 362, 364, 732, 366, 463, 923, 738, 578, 537, 742, 866, 369, 744, 186, 925, 869, 746, 926, 466, 298, 927, 846, 299, 582, 474, 754, 698)~=0
label var is_edeconomy "1=Emerging and Developing Economies"

gen group=""
replace group="Advanced Economies" if is_advanced==1
replace group="Emerging and Developing Economies" if is_edeconomy==1
drop is*
save "clean_data_2020.dta",replace

/*******************************************************************************
	Summary stats and Regressions
*******************************************************************************/

*descriptive stat*
svyset idstd [pweight=wt_rs], strata(strata)
global controls1 size age largefirm domesticshare govtshare foreignshare lnsale
global factorvar i.industry i.country i.year 

	eststo count: estpost tab surveytype region
		esttab count using $OutputFolder/count.tex, cell(colpct(fmt(2))) collabels(none) ///
		nonumber unstack eqlabels(, lhs("Region")) mtitle("Region and Survey type") replace

	eststo clear
	eststo: estpost corr product corruption  [pweight=wt_rs]
	eststo: estpost corr process corruption [pweight=wt_rs]
	esttab using $OutputFolder/Correlations.tex, label replace
	
	eststo clear
	eststo region: estpost sum product corruption competitor2 rleaveoutmean size age ///
	domesticshare govtshare lnsale largefirm, listwise 
	esttab region using $OutputFolder/summarystat.tex, cells("mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") ///
		mtitle("Summary Statistics") nonumber label replace
		
	eststo clear
	eststo: estpost corr corruption rleaveoutmean
	eststo: estpost reg corruption rleaveoutmean $controls1 $factorvar 
	esttab using $OutputFolder/relevance.tex, label replace
	
*regression result* 
set matsize 800
	
*linear regression*

eststo: ivreg2 product $controls1 $factorvar ///
		(corruption =ileaveoutmean),  robust
predict yhat1, xb
egen count1=count(yhat1) if yhat1>1 & yhat1<.
egen total1=total(yhat1) if yhat1!=.
gen over1=count1/total1
sum over1
egen th1=pctile(yhat1), p(95)
sum th1
local vline1=r(mean)
di `vline1'
hist yhat1, bgcolor(white) graphregion(color(white)) addplot(pci 0 .94004756 2 .94004756) leg(off)
graph export $OutputFolder/distribution1.png, replace

reg product bribe competitor2 c.bribe#c.competitor2 $controls1 $factorvar , robust
predict yhat2, xb
egen count2=count(yhat2) if yhat2>1 & yhat2<.
egen total2=total(yhat2) if yhat2!=.
gen over2=count2/total2
sum over2
egen th2=pctile(yhat2), p(95)
sum th2
local vline2=r(mean)
di `vline2'
hist yhat2, addplot(pci 0 .92876214 2 .92876214) leg(off)
graph export $OutputFolder/distribution2.png, replace

*basic model*
eststo clear
	eststo: reg product corruption $controls1 $factorvar, robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
	eststo: reg product corruption $controls1 $factorvar [pweight=wt], robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
	eststo: ivreg2 product $controls1 $factorvar ///
		(corruption =rleaveoutmean),  robust 
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"
	eststo: ivreg2 product $controls1 $factorvar ///
		(corruption =rleaveoutmean) [pweight=wt], robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
		
esttab using $OutputFolder/basicmodel.tex, drop (*.country *.year *.industry) b(4) p(3) ///
		nogaps label replace mlabels("OLS" "Weighted-OLS" "IV" "Weighted-IV") ///
		s(N industry country year, label("N" "Industry FE" "Country FE" "Year FE"))
	
*interaction term*
eststo clear
	eststo: reg product corruption competitor2 c.corruption#c.competitor2 $controls1 $factorvar , robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
		margins, at (competitor2=(0(1)3) corruption=(0 2 4))
		marginsplot, bgcolor(white) graphregion(color(white)) recast(line) legend(c(3)) title("Probability of Product Innovation 95% CIs") ytitle("") ///
			xtitle("Corruption Level") legend(size(small)) ///
			xlabel(0 "None" 1 "One" 2 "Two to Five" 3 "More than five", labsize(medsmall) angle(15))
		margins, at (corruption=(0(2)4) competitor2=(0 2 4))
		marginsplot, bgcolor(white) graphregion(color(white)) recast(line) legend(c(3)) title("Probability of Product Innovation 95% CIs") ytitle("") ///
			xtitle("Competition level") legend(size(small)) ///
			xlabel(0 "No Obstacle" 2 "Moderate Obstacle" 4 "Severe obstacle", labsize(medsmall) angle(60))
		graph export $OutputFolder/interactiongraph.png, replace
	eststo: reg product corruption competitor2 c.corruption#c.competitor2 $controls1 $factorvar [pweight=wt_rs] , robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
	eststo: ivreg2 product competitor2 $controls1 $factorvar ///
		(corruption c.corruption#c.competitor2 =rleaveoutmean c.rleaveoutmean#c.competitor2), robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
	eststo: ivreg2 product competitor2 $controls1 $factorvar ///
		(corruption c.corruption#c.competitor2 =rleaveoutmean c.rleaveoutmean#c.competitor2) [pweight=wt_rs], robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
	esttab using $OutputFolder/interactionmodel.tex, drop (*.country *.year *.industry) b(4) p(3) ///
		nogaps label replace mlabels("OLS" "Weighted-OLS") star(+ 0.10 * 0.05 ** 0.01 *** 0.001) ///
		s(N industry country year, label("N" "Industry FE" "Country FE" "Year FE"))
	esttab using $OutputFolder/interactionmodel.tex, drop (*.country *.year *.industry) b(4) p(3) ///
		nogaps label replace mlabels("OLS" "Weighted-OLS" "IV" "Weighted-IV") star(+ 0.10 * 0.05 ** 0.01 *** 0.001) ///
		s(N industry country year, label("N" "Industry FE" "Country FE" "Year FE"))

*robustness*
eststo clear
	eststo: reg product bribe $controls1 $factorvar, robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
	eststo: ivreg2 product $controls1 $factorvar ///
		(bribe =rbleaveoutmean),  robust 
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"
	eststo: reg product bribe competitor2 c.bribe#c.competitor2 $controls1 $factorvar , robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
	eststo: ivreg2 product competitor2 $controls1 $factorvar ///
		(bribe c.bribe#c.competitor2 =rleaveoutmean c.rbleaveoutmean#c.competitor2), robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
		
esttab using $OutputFolder/robust.tex, drop (*.country *.year *.industry) b(4) p(3) ///
		nogaps label replace mlabels("OLS" "IV" "Interaction" "IV Interaction") ///
		s(N industry country year, label("N" "Industry FE" "Country FE" "Year FE"))


*probit regression*
eststo clear
	probit product corruption $controls1 $factorvar , vce(robust)
		estpost margins, dydx(corruption $controls1)
		eststo a
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
	probit product corruption competitor2 $controls1 $factorvar c.corruption#c.competitor2, vce(robust)
		estpost margins, dydx(corruption $controls1 competitor2 c.corruption#c.competitor2)
		eststo b
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
	
	esttab a b using $OutputFolder/probitmodel.tex, b(4) p(3) ///
		nogaps label replace mlabels("Probit" "Probit-interaction") ///
		s(N industry country year, label("N" "Industry" "Country" "Year"))
		
*	ivprobit product $controls1 $factorvar (corruption=rleaveoutmean), vce(robust)
*		margins, dydx(corruption $controls1) pred(pr) nose

use "clean_data_2020.dta",clear
/*
encode group,gen(group1)
drop group
rename group1 group
*/
svyset idstd [pweight=wt_rs], strata(strata)
global controls1 size age largefirm domesticshare govtshare foreignshare lnsale
global factorvar i.industry i.country i.year

bysort group: reg product corruption $controls1 $factorvar, robust
bysort group: ivreg2 product $controls1 $factorvar (corruption =rleaveoutmean),  robust 
bysort group: reg product corruption competitor2 c.corruption#c.competitor2 $controls1 $factorvar , robust
bysort group: ivreg2 product competitor2 $controls1 $factorvar (corruption c.corruption#c.competitor2 =rleaveoutmean c.rleaveoutmean#c.competitor2), robust

*basic model*
eststo clear
	eststo by group: reg product corruption $controls1 $factorvar, robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
	eststo: reg product corruption $controls1 $factorvar [pweight=wt], robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
	eststo: ivreg2 product $controls1 $factorvar ///
		(corruption =rleaveoutmean),  robust 
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"
	eststo: ivreg2 product $controls1 $factorvar ///
		(corruption =rleaveoutmean) [pweight=wt], robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
		
esttab using $OutputFolder/basicmodel_group.tex, drop (*.country *.year *.industry) b(4) p(3) ///
		nogaps label replace mlabels("OLS" "Weighted-OLS" "IV" "Weighted-IV") ///
		s(N industry country year, label("N" "Industry FE" "Country FE" "Year FE"))
	
*interaction term*
eststo clear
	eststo: reg product corruption competitor2 c.corruption#c.competitor2 $controls1 $factorvar , robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
		margins, at (competitor2=(0(1)3) corruption=(0 2 4))
		marginsplot, bgcolor(white) graphregion(color(white)) recast(line) legend(c(3)) title("Probability of Product Innovation 95% CIs") ytitle("") ///
			xtitle("Corruption Level") legend(size(small)) ///
			xlabel(0 "None" 1 "One" 2 "Two to Five" 3 "More than five", labsize(medsmall) angle(15))
		margins, at (corruption=(0(2)4) competitor2=(0 2 4))
		marginsplot, bgcolor(white) graphregion(color(white)) recast(line) legend(c(3)) title("Probability of Product Innovation 95% CIs") ytitle("") ///
			xtitle("Competition level") legend(size(small)) ///
			xlabel(0 "No Obstacle" 2 "Moderate Obstacle" 4 "Severe obstacle", labsize(medsmall) angle(60))
		graph export $OutputFolder/interactiongraph.png, replace
	eststo: reg product corruption competitor2 c.corruption#c.competitor2 $controls1 $factorvar [pweight=wt_rs] , robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
	eststo: ivreg2 product competitor2 $controls1 $factorvar ///
		(corruption c.corruption#c.competitor2 =rleaveoutmean c.rleaveoutmean#c.competitor2), robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
	eststo: ivreg2 product competitor2 $controls1 $factorvar ///
		(corruption c.corruption#c.competitor2 =rleaveoutmean c.rleaveoutmean#c.competitor2) [pweight=wt_rs], robust
		estadd local industry "Yes"
		estadd local country "Yes"
		estadd local year "Yes"	
	esttab using $OutputFolder/interactionmodel_group.tex, drop (*.country *.year *.industry) b(4) p(3) ///
		nogaps label replace mlabels("OLS" "Weighted-OLS") star(+ 0.10 * 0.05 ** 0.01 *** 0.001) ///
		s(N industry country year, label("N" "Industry FE" "Country FE" "Year FE"))
	esttab using $OutputFolder/interactionmodel_group.tex, drop (*.country *.year *.industry) b(4) p(3) ///
		nogaps label replace mlabels("OLS" "Weighted-OLS" "IV" "Weighted-IV") star(+ 0.10 * 0.05 ** 0.01 *** 0.001) ///
		s(N industry country year, label("N" "Industry FE" "Country FE" "Year FE"))



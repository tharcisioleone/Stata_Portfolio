/* CLARIFICATIONS
This Stata do-file refers to the working in progress "Remote learning under stress: Uneven reactions to income shocks during the COVID-19 pandemic in Brazil" 
and provides an overview of the commands used in this paper.
Working paper in progress. Please do not cite, circulate or quote this Do.file.
*/



* ==================================================================================================== *
                                          // REPORTING VARIABLES //
* ==================================================================================================== *


global DROPBOX "D:\Data\Dropbox\PROMOTION\Projects\"

global TABLES "D:\Data\Dropbox\PROMOTION\Projects\Homeschooling-Brazil\TABLES\\"
global GRAPHS "D:\Data\Dropbox\PROMOTION\Projects\Homeschooling-Brazil\GRAPHS\\"
global DATA "D:\Data\Dropbox\PROMOTION\Projects\Homeschooling-Brazil\DATA\DTA-Files\\"

cd "D:\Data\Dropbox\PROMOTION\Projects\Homeschooling-Brazil\DO-FILES\"
/*
global TABLES "C:\Users\tharc\Dropbox\Homeschooling-Brazil\TABLES\\"
global GRAPHS "C:\Users\tharc\Dropbox\Homeschooling-Brazil\GRAPHS\\"
global DATA "C:\Users\tharc\Dropbox\Homeschooling-Brazil\DATA\DTA-Files\\"
*/

*do 0_read_panel

use "$DATA\Sample.dta" , clear

* Data preparation
do 1_data_prep

saveold "$DATA\Final_Sample.dta", replace version(12)

use "$DATA\Final_Sample.dta" , clear

* inverse hyperbolic sine transformation of income
*replace Per_Ca_Inc2 = asinh(Per_Ca_Inc2+1)
* check: https://onlinelibrary.wiley.com/doi/abs/10.1111/obes.12325
*https://www.statalist.org/forums/forum/general-stata-discussion/general/1553489-inverse-hyperbolic-sinc-transformation
*https://worthwhile.typepad.com/worthwhile_canadian_initi/2011/07/a-rant-on-inverse-hyperbolic-sine-transformations.html

/* Creating Macro */ 
global childrenCV age i.female i.race i.UF i.SinglePar i.LevelEduc i.rural c.NumbChild017 i.V1013

global parentsCV i.BolsaFa  i.educ_parents i.EAP_HH i.Formal_HH i.Home_HH i.DumSocDist_HH 
global parentsCV2 i.edu_Head i.edu_Part i.EAP_Head i.EAP_Part i.Formal_Head i.Formal_Part i.Home_Head i.Home_Part i.OffPand_Head i.OffPand_Part i.DumSocDist_Head i.DumSocDist_Part i.DumSocDist_AHH
*describe $parentsCV
*sum $parentsCV

global parentsHealth i.covid19 i.medicare i.hospital  i.Covid_MemHH i.SyntCov_HH i.MediCa_HH i.Hosp_HH c.Covid19_deathrate
global parentsHealth2 SyntCov_Head SyntCov_Part Covid_Head Covid_Part Covid_MemHH MediCa_Head MediCa_Part Hosp_Head Hosp_Part

global cluster ", vce(cluster ID)" 

global HomeSch_lab "Probability to do some homeschooling"
global HoursHomesch_lab "Weekly hours of homeschooling"
global HomeSch2_lab "Probability to do some homeschooling (only with option)"
global HoursHomesch2_lab "Weekly hours of homeschooling (only with option)"

global outcomes "HomeSch HoursHomesch HomeSch2 HoursHomesch2 HoursHomesch3"

***** DESCRIPTIVE ANALYSIS
/*
******************
ssc install binscatter
binscatter HomeSch IncDecile2 [weight=V1032] , line(connect) xlabel(1(1)10)  by(LevelEduc) 

binscatter HoursHomesch IncDecile2 [weight=V1032] , line(connect) xlabel(1(1)10)  discrete by(LevelEduc)
******************

******************
binscatter HomeSch IncDecile2 [weight=V1032] , line(connect) xlabel(1(1)10) discrete by(IncSho10)

binscatter HoursHomesch IncDecile2 [weight=V1032] , line(connect) xlabel(1(1)10)  discrete by(IncSho10)
******************

*** NOTE: CHECK CFDs
twoway (kdensity Y if IncDecile2==1) (kdensity Y if IncDecile2==10)

*** KEEP ONLY THOSE IN PRIMARY OR SECONDARY
*drop if LevelEduc > 2
*/
********** BASELINE

* Creating table 1 with summary statistics
estpost summarize age race female rural LevelEduc SinglePar Workers BolsaFa SocDist COVID_Aid COVIDSym covid19 medicare hospital ///
A007 A008 A009 HomeSch DaysHomesch HoursHomesch ///
female_head educ_parents EAP_HH Formal_Head Formal_Part Home_Head Home_Part OffPand_Head OffPand_Part DumSocDist_Head DumSocDist_Part ///
DumSocDist_AHH SyntCov_HH Covid_MemHH MediCa_HH Hosp_HH if A006==1
esttab using "$TABLES\\DESCRIPTIVES.rtf", cells("count mean(fmt(3)) sd (fmt(3)) min max") main(mean %12.0fc) not nostar unstack nomtitle nonumber nonote noobs nolabel varwidth(17) replace



/* LATEX: Still in progress
eststo clear
estpost sum age race female rural LevelEduc SinglePar Workers BolsaFa SocDist COVID_Aid COVIDSym covid19 medicare hospital ///
female_head educ_parents EAP_HH Formal_Head Formal_Part Home_Head Home_Part OffPand_Head OffPand_Part DumSocDist_Head DumSocDist_Part ///
DumSocDist_AHH SyntCov_HH Covid_MemHH MediCa_HH Hosp_HH if A006==1
est store table1

esttab table1 using table.tex, replace ///
title(Descriptive Statistics)       ///
addnote("Notes: This table provides descriptive statistics for panel data structure in which each student i was accompanied during the five sample waves. " "Source: PNAD COVID-19.") ///
refcat(age "\textbf{\emph{Student}}" female_head "\emph{Parents}" SyntCov_HH "\emph{Household}", nolabel) ///
varlabels (age "Age" ///
		   race_1 "White" race_2 "Black" race_3 "Yellow" race_4 "Brown" race_5 "Indigenous" race_6 "Ignored" ///
		   female "Female" ///
		   rural "Rural" ///
		   LevelEduc_1 "Primary" LevelEduc_2 "Secondary" LevelEduc_3 "Tertiary" ///
		   SinglePar "Single parent " ///
		   Workers "Employed" ///
		   BolsaFa "Beneficiary of Bolsa Familia" ///
		   SocDist_1 "No restriction" SocDist_2 "Small restriction" SocDist_3 "Strong restriction" SocDist_4 "Stay only at home" ///
		   COVID_Aid "Beneficiary of COVID19-Aid" ///
		   COVIDSym_0 "No Symptoms" COVIDSym_1 "Mild Symptoms" COVIDSym_2 "Moderate Symptoms" COVIDSym_3 "Severe Symptoms" ///
		   covid19 "Positive test" ///
		   medicare "Seek medical care" ///
		   hospital "Need Hospitalization" ///
		   female_head "Head is female" ///
		   educ_parents_1 "No Schooling" educ_parents_2 "Primary Incomplete" educ_parents_3 "Primary Complete" educ_parents_4 "Secondary Incomplete" educ_parents_5 "Secondary Complete" educ_parents_6 "Tertiary Incomplete" educ_parents_7 "Tertiary Complete" educ_parents_8 "Post-graduate Complete" ///
  		   EAP_HH_0 "No one" EAP_HH_1 "One (Head or Partner)" EAP_HH_2 "Two (Head and Partner)" ///
		   Formal_Head "Head working formal" ///
		   Formal_Part "partner working formal" ///
		   Home_Head "Head in homeoffice" ///
		   Home_Part "Partner in homeoffice" ///
		   OffPand_Head "Head in work absenteeism" ///
		   OffPand_Part "Partner in work absenteeism" ///
		   DumSocDist_Head "Head in social distancing" ///
		   DumSocDist_Part "Partner in social distancing" ///
		   DumSocDist_AHH "Other adult in social distancing" ///
		   SyntCov_HH "Symptoms of COVID19" ///
		   Covid_MemHH "Positive test" ///
		   MediCa_HH "Seek medical care" ///
		   Hosp_HH "Need hospitalization") ///
		   collabels(\multicolumn{1}{c}{{Mean}} \multicolumn{1}{l}{{Std.Dev.}}) ///
cells("count mean(fmt(3)) sd (fmt(3)) min max") main(mean %12.0fc) not nostar unstack nomtitle nonumber nonote noobs nolabel
*/
eststo clear

*** SOCIOECONOMIC GRADIENT
foreach outcome in $outcomes {

replace Y = `outcome'

reg Y Per_Ca_Inc2 [pweight=V1032] $cluster
eststo
reg Y Per_Ca_Inc2 $childrenCV [pweight=V1032] $cluster
eststo
reg Y Per_Ca_Inc2 $childrenCV $parentsCV [pweight=V1032] $cluster
eststo
reg Y Per_Ca_Inc2 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster
eststo
*areg Y Per_Ca_Inc2 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster absorb(ID)
*eststo

esttab using "$TABLES\\REG_`outcome'" ,  ar2 nonotes nomti label nogaps compress nobase ///
indicate("Federal State FE = *UF") se nocons star(* 0.10 ** 0.05 *** 0.01) rtf replace dropped(" ")

eststo clear

reg Y i.IncDecile2 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster
margins, at(IncDecile2=(1(1)10)) 
marginsplot , name(`outcome', replace) level(90) recast(connected) recastci(rarea) xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") 
graph export "$GRAPHS\gradient_`outcome'.png" , hei(800) replace

}

*** EFFECT OF INCOME SHOCKS
foreach outcome in $outcomes {

replace Y = `outcome'

reg Y i.IncDecile2##i.IncSho10 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster

margins, at(IncDecile2=(1(1)10)) over(IncSho10) 
marginsplot , name(`outcome'_shock, replace) level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") ///
legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\incomeshock_`outcome'.png" , hei(800) replace

}

*** EFFECT OF INCOME SHOCKS: ROBUSTNESS CHECK WITH PRE PANDEMIC WORK INCOME (EXCLUDING INCOME FROM ALL OTHER SOURCES)
foreach outcome in HoursHomesch {

replace Y = `outcome'

reg Y i.IncDecile3##i.IncSho10 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster

margins, at(IncDecile3=(2(1)10)) over(IncSho10) 
marginsplot , name(`outcome'_shock, replace) level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") ///
legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\incomeshock_IncDecile3_`outcome'.png" , hei(800) replace

}


*** EFFECT OF INCOME SHOCKS
foreach outcome in  $outcomes  ProvHoSch  {

replace Y = `outcome'

eststo: reg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster

eststo: reg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if female ==0 [pweight=V1032] $cluster

eststo: reg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if female ==1 [pweight=V1032] $cluster

eststo: reg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if educ_parents>=5 [pweight=V1032] $cluster

eststo: reg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if educ_parents<5 [pweight=V1032] $cluster

eststo: reg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if IncDecile2>=5 [pweight=V1032] $cluster

eststo: reg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if IncDecile2<5 [pweight=V1032] $cluster

esttab using "$TABLES\\REG_incshock_`outcome'" ,  ar2 nonotes mti("All" "Male" "Female" "Parents High Educ" "Parents Low Educ" "Higher income" "Lower income") label nogaps compress nobase ///
indicate("Federal State FE = *UF") se nocons star(* 0.10 ** 0.05 *** 0.01) rtf replace dropped(" ")

eststo clear
}

foreach outcome in  $outcomes  ProvHoSch  {

replace Y = `outcome'

eststo: xtreg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth [pweight=V1032b] $cluster fe

eststo: xtreg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if female ==0 [pweight=V1032b] $cluster fe

eststo: xtreg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if female ==1 [pweight=V1032b] $cluster fe

eststo: xtreg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if educ_parents>=5 [pweight=V1032b] $cluster fe

eststo: xtreg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if educ_parents<5 [pweight=V1032b] $cluster fe

eststo: xtreg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if IncDecile2>=5 [pweight=V1032b] $cluster fe
 
eststo: xtreg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if IncDecile2<5 [pweight=V1032b] $cluster fe

esttab using "$TABLES\\REG_incshock_FE_`outcome'" ,  ar2 nonotes mti("All" "Male" "Female" "Parents High Educ" "Parents Low Educ" "Higher income" "Lower income") label nogaps compress nobase ///
indicate("Federal State FE = *UF") se nocons star(* 0.10 ** 0.05 *** 0.01) rtf replace dropped(" ")

eststo clear
}


*** EFFECT OF INCOME SHOCKS
foreach outcome in  private   {

replace Y = `outcome'

eststo: reg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster

eststo: reg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if female ==0 [pweight=V1032] $cluster

eststo: reg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if female ==1 [pweight=V1032] $cluster

eststo: reg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if educ_parents>=5 [pweight=V1032] $cluster

eststo: reg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if educ_parents<5 [pweight=V1032] $cluster

eststo: reg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if IncDecile2>=5 [pweight=V1032] $cluster

eststo: reg Y Per_Ca_Inc2 i.IncSho10 $childrenCV $parentsCV $parentsHealth if IncDecile2<5 [pweight=V1032] $cluster

esttab using "$TABLES\\REG_incshock_`outcome'" ,  ar2 nonotes mti("All" "Male" "Female" "Parents High Educ" "Parents Low Educ" "Higher income" "Lower income") label nogaps compress nobase ///
indicate("Federal State FE = *UF") se nocons star(* 0.10 ** 0.05 *** 0.01) rtf replace dropped(" ")

eststo clear
}


* BY levels of education
foreach outcome in HomeSch HoursHomesch {
forvalues i = 1/3 {
preserve
keep if LevelEduc==`i'
replace Y = `outcome'

reg Y i.IncDecile2 age i.female i.race i.UF i.SinglePar i.rural i.BolsaFa i.SocDist i.COVID_Aid i.COVIDSym i.covid19 i.medicare i.hospital i.V1013 $parentsCV $parentsHealth [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10)) 
marginsplot , level(90) recast(connected) recastci(rarea) xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") 
graph export "$GRAPHS\gradient_`outcome'_educ`i'.png" , hei(800) replace


reg Y i.IncDecile2##i.IncSho10 age i.female i.race i.UF i.SinglePar i.rural i.BolsaFa i.SocDist i.COVID_Aid i.COVIDSym i.covid19 i.medicare i.hospital i.V1013 $parentsCV $parentsHealth [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10)) over(IncSho10) 
marginsplot ,  level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") ///
legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\incomeshock_`outcome'_educ`i'.png" , hei(800) replace
restore
}
}

* BY sex
foreach outcome in HomeSch HoursHomesch {
replace Y = `outcome'

reg Y i.IncDecile2##i.female age i.race i.UF i.SinglePar i.LevelEduc i.rural i.BolsaFa i.SocDist i.COVID_Aid i.COVIDSym i.covid19 i.medicare i.hospital i.V1013  $parentsCV $parentsHealth [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10))  over(female)
marginsplot , level(90) recast(connected) recastci(rarea) xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") ///
legend(order(3 "Male" 4 "Female"))
graph export "$GRAPHS\gradient_`outcome'_female.png" , hei(800) replace

forvalues i = 0/1 {
preserve

keep if female==`i'

reg Y i.IncDecile2##i.IncSho10 age i.race i.UF i.SinglePar i.LevelEduc i.rural i.BolsaFa i.SocDist i.COVID_Aid i.COVIDSym i.covid19 i.medicare i.hospital i.V1013 $parentsCV $parentsHealth [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10)) over(IncSho10) 
marginsplot ,  level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") ///
legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\incomeshock_`outcome'_female`i'.png" , hei(800) replace
restore
}
}

*** EFFECT OF WORK INCOME SHOCK by 100% (=Job Loss by one of the parents)
* --> Please note that JobLoss_HH refers only to people that did not work in the reference week (no homeworkers or people that reduce the number of work hours)
gen incomeloss_100 = (incomeloss == 1)
replace incomeloss_100 = . if incomeloss==.

foreach outcome in HoursHomesch {

replace Y = `outcome'

reg Y i.IncDecile2##i.IncSho10##i.JobLoss_HH $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster
margins IncSho10, at(IncDecile=(1(1)10)) over(JobLoss_HH)  
marginsplot , name(`outcome'_shock, replace) level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") 
///
*legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\incomeshock_`outcome'_jobloss.png" , hei(800) replace

reg Y i.IncDecile2##i.incomeloss_100 c.incomeloss $childrenCV $parentsCV $parentsHealth if incomeloss>=0.1 [pweight=V1032] $cluster
margins , at(IncDecile=(1(1)10)) over(incomeloss_100)  
marginsplot , name(`outcome'_shock, replace) level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") 
///
*legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\incomeshock_`outcome'_incomeloss100.png" , hei(800) replace

}



*** COVID-aid recipients
graph bar Transfers_d [pweight=V1032], over(IncDecile2)
*graph bar COVID_Aid [pweight=V1032], over(IncDecile2) over(IncSho10)
graph export "$GRAPHS\Transfers.png" , hei(800) replace

foreach outcome in HomeSch HoursHomesch ProvHoSch {
replace Y = `outcome'

reg Y i.IncDecile2##i.Transfers_d $childrenCV $parentsCV $parentsHealth if IncSho==1 [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10)) over(Transfers_d)
marginsplot , name(`outcome'_shock, replace) level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") ///
legend(order(3 "No Transfers" 4 "Receives Transfers"))
graph export "$GRAPHS\transfers_`outcome'.png" , hei(800) replace

reg Y i.IncDecile2##i.Transfers_d c.incomeloss $childrenCV $parentsCV $parentsHealth if IncSho==1 [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10)) over(Transfers_d)
marginsplot , name(`outcome'_shock, replace) level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") ///
legend(order(3 "No Transfers" 4 "Receives Transfers"))
graph export "$GRAPHS\transfers_incomeloss_`outcome'.png" , hei(800) replace

reg Y i.IncDecile2##i.Transfers_d  $childrenCV $parentsCV $parentsHealth if incomeloss==1 [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10)) over(Transfers_d)
marginsplot , name(`outcome'_shock, replace) level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") ///
legend(order(3 "No Transfers" 4 "Receives Transfers"))
graph export "$GRAPHS\transfers_incomeloss100_`outcome'.png" , hei(800) replace

}

*** WEALTH AS INSURANCE?
graph bar Homeowner [pweight=V1032], over(IncDecile2)
*graph bar COVID_Aid [pweight=V1032], over(IncDecile2) over(IncSho10)
graph export "$GRAPHS\Homeowner.png" , hei(800) replace

foreach outcome in HomeSch HoursHomesch ProvHoSch {
replace Y = `outcome'

reg Y i.IncDecile2##i.Homeowner c.incomeloss $childrenCV $parentsCV $parentsHealth if IncSho==1 [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10)) over(Homeowner)
marginsplot , name(`outcome', replace) level(90) recast(connected) recastci(rarea) xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") 
///
*legend(order(3 "Children whose parents have less than completed secondary" 4 "Children whose parents have at least completed secondary") rows(2))
graph export "$GRAPHS\homeowner_incomeloss_`outcome'.png" , hei(800) replace

reg Y i.IncDecile2 i.IncSho10##i.Homeowner c.incomeloss $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster

reg Y i.IncDecile2##i.IncSho10##i.Homeowner c.incomeloss $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster
margins Homeowner , at(IncDecile=(1(1)10)) over(IncSho10) 
marginsplot , level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") 
///
*legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\shock_`outcome'_homeowner.png" , hei(800) replace

}

*** LOAN AS INSURANCE?
tab E001 , gen(loan) 
graph bar loan1 loan2  [pweight=V1032], over(IncDecile2) stack legend(title("Loan") order(1 "Yes" 2 "Applied but didn't get it" - "remaining share did not apply") size(vsmall) rows(1) )
*graph bar COVID_Aid [pweight=V1032], over(IncDecile2) over(IncSho10)
graph export "$GRAPHS\Loan.png" , hei(800) replace

foreach outcome in HomeSch HoursHomesch ProvHoSch {
replace Y = `outcome'

reg Y i.IncDecile2##i.E001 c.incomeloss $childrenCV $parentsCV $parentsHealth if IncSho==1 [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10)) over(E001)
marginsplot , name(`outcome', replace) level(90) recast(connected) recastci(rarea) xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") 
///
*legend(order(3 "Children whose parents have less than completed secondary" 4 "Children whose parents have at least completed secondary") rows(2))
graph export "$GRAPHS\loan_incomeloss_`outcome'.png" , hei(800) replace

reg Y i.IncDecile2 i.IncSho10##b3.E001 c.incomeloss $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster

reg Y i.IncDecile2##i.IncSho10##i.E001 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster
margins E001 , at(IncDecile=(1(1)10)) over(IncSho10) 
marginsplot , level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") 
///
*legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\shock_`outcome'_loan.png" , hei(800) replace

}


*** MECHANISM: PROVISION OF HOMESCHOOLING BY SCHOOL
graph bar ProvHoSch [pweight=V1032], over(IncDecile2) title("Share of children in schools that provide homeschooling") ytitle("")
graph export "$GRAPHS\gradient_prov.png" , hei(800) replace

foreach outcome in HomeSch HoursHomesch {
preserve
keep if ProvHoSch==1
replace Y = `outcome'

reg Y i.IncDecile2 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10)) 
marginsplot , name(`outcome'_prov, replace) level(90) recast(connected) recastci(rarea)   xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") 
graph export "$GRAPHS\gradient_`outcome'_prov.png" , hei(800) replace

reg Y i.IncDecile2##i.IncSho10 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10)) over(IncSho10) 
marginsplot , name(`outcome'_prov_shock, replace) level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") ///
legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\incomeshock_`outcome'_prov.png" , hei(800) replace

restore
}

*** Note: Question is whether income shocks reduce homeschooling due to economic reasons (less money for private school, tutors etc) or stress factors related to job/income loss.
* if looking only at those for whome homeschooling is provided (by schools) the effect is only visible at the very bottom of the distribution (1th decile).
* Ergo: evidence points at economic reasons to explain the effect of shocks at the other points of the distribution
* however, we also have to check this for different education levels (primary, secondary, tertiary)
* Further check: is the likelihood to be in an institution that provides homeschooling affected by Income loss?

// ATTENTION //
* --> Income shock also can have a positive impact on homeschooling, because parents remain at home and can control the homeschooling of their children. 
* --> See the coefficients for Home_Part and Home_Head.

reg ProvHoSch i.IncDecile2##i.IncSho10 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10)) over(IncSho10) 
marginsplot , name(prov_shock, replace) level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("Likelihood to be in a school" "that provides homeschooling") ///
legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\shock_prov.png" , hei(800) replace



*** EXTENSION: Impact of COVID-19 Aid given the children makes any homeschooling
* --> We look only for the children that had the option of homeschooling (school provides it) and they make (at least part of) the homeschooling

tab HoursHomesch2 A007, missing
*gen HoursHomesch3 = HoursHomesch2
*replace HoursHomesch3=. if A007==2 // Homeschooling was provided, but I made no one (for any reason).   ********** WHY IS THIS SET TO MISSING??
*replace HoursHomesch3=. if IncSho10==0

reg HoursHomesch i.IncDecile2##i.COVID_Aid $childrenCV $parentsCV $parentsHealth if IncSho==1 [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10)) over(COVID_Aid) 
marginsplot , name(`outcome'_COVID_Aid, replace) level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") ///
legend(order(3 "No Covid-Aid" 4 "Received Covid-Aid"))
graph export "$GRAPHS\covidaid_HoursHomesch.png" , hei(800) replace




mean ProvHoSch [pweight=V1032], over(private)

graph bar private [pweight=V1032], over(IncDecile2) title("Share of children in private schools") ytitle("")
graph export "$GRAPHS\gradient_private.png" , hei(800) replace


reg private i.IncDecile2 i.IncSho10 age i.female i.race i.UF i.SinglePar i.LevelEduc i.rural i.BolsaFa i.SocDist i.COVID_Aid i.COVIDSym i.covid19 i.medicare i.hospital  $parentsCV $parentsHealth [pweight=V1032] $cluster

reg private i.IncDecile2##i.IncSho10 age i.female i.race i.UF i.SinglePar i.LevelEduc i.rural i.BolsaFa i.SocDist i.COVID_Aid i.COVIDSym i.covid19 i.medicare i.hospital $parentsCV $parentsHealth [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10)) over(IncSho10) 
marginsplot , name(private_shock, replace) level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("Likelihood to be in a private school") ///
legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\shock_private.png" , hei(800) replace


*** probability of drop-out due to income shock

preserve

*keep if IncDecile<5

reg student i.IncDecile2 i.IncSho10#i.age i.female i.race i.UF i.SinglePar i.rural i.BolsaFa i.SocDist i.COVID_Aid i.COVIDSym i.covid19 i.medicare i.hospital i.V1013 female_head i.educ_parents i.EAP_HH Formal_Head Formal_Part Home_Head Home_Part OffPand_Head OffPand_Part SyntCov_HH Covid_MemHH MediCa_HH Hosp_HH [pweight=V1032] $cluster
margins, at(age=(6(1)29)) over(IncSho10) 
marginsplot ,  level(90) recast(connected)  xtitle("age", size(small)) title("Likelihood to be enrolled in school") ///
legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\shock_student_age.png" , hei(800) replace

reg student i.IncDecile2 i.IncSho10#i.age i.female i.race i.UF i.SinglePar i.rural i.BolsaFa i.SocDist i.COVID_Aid i.COVIDSym i.covid19 i.medicare i.hospital i.V1013 female_head i.educ_parents i.EAP_HH Formal_Head Formal_Part Home_Head Home_Part OffPand_Head OffPand_Part SyntCov_HH Covid_MemHH MediCa_HH Hosp_HH if age<17 [pweight=V1032] $cluster
margins, at(age=(6(1)16)) over(IncSho10) 
marginsplot ,  level(90) recast(connected)  xtitle("age", size(small)) title("Likelihood to be enrolled in school") ///
legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\shock_student_age6.png" , hei(800) replace

reg student i.IncDecile2 i.IncSho10#i.age i.female i.race i.UF i.SinglePar i.rural i.BolsaFa i.SocDist i.COVID_Aid i.COVIDSym i.covid19 i.medicare i.hospital i.V1013 female_head i.educ_parents i.EAP_HH Formal_Head Formal_Part Home_Head Home_Part OffPand_Head OffPand_Part SyntCov_HH Covid_MemHH MediCa_HH Hosp_HH if age>16 [pweight=V1032] $cluster
margins, at(age=(17(1)29)) over(IncSho10) 
marginsplot ,  level(90) recast(connected)  xtitle("age", size(small)) title("Likelihood to be enrolled in school") ///
legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\shock_student_age17.png" , hei(800) replace

restore



*** PARENTAL INCOME # EDUCATION (Human capital as insurance mechanism?)
gen educ_parents_high = (educ_parents>=5)
graph bar educ_parents_high [pweight=V1032], over(IncDecile2)

foreach outcome in HomeSch HoursHomesch HomeSch2 HoursHomesch2 ProvHoSch {
replace Y = `outcome'

reg Y i.IncDecile2##i.educ_parents_high $childrenCV i.BolsaFa i.EAP_HH i.Formal_HH i.Home_HH i.DumSocDist_HH  $parentsHealth [pweight=V1032] $cluster
margins, at(IncDecile=(1(1)10)) over(educ_parents_high)
marginsplot , name(`outcome', replace) level(90) recast(connected) recastci(rarea) xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") legend(order(3 "Children whose parents have less than completed secondary" 4 "Children whose parents have at least completed secondary") rows(2))
graph export "$GRAPHS\gradient_`outcome'_educparents.png" , hei(800) replace


reg Y i.IncDecile2##i.IncSho10 $childrenCV i.BolsaFa i.EAP_HH i.Formal_HH i.Home_HH i.DumSocDist_HH $parentsHealth if educ_parents_high==0 [pweight=V1032] $cluster
margins , at(IncDecile=(1(1)10)) over(IncSho10) 
marginsplot , level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") ///
legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\shock_`outcome'_educparents0.png" , hei(800) replace

reg Y i.IncDecile2##i.IncSho10 $childrenCV i.BolsaFa i.EAP_HH i.Formal_HH i.Home_HH i.DumSocDist_HH $parentsHealth if educ_parents_high==1 [pweight=V1032] $cluster
margins , at(IncDecile=(1(1)10)) over(IncSho10) 
marginsplot , level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") ///
legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\shock_`outcome'_educparents1.png" , hei(800) replace

reg Y i.IncDecile2##i.IncSho10##i.educ_parents_high $childrenCV i.BolsaFa i.EAP_HH i.Formal_HH i.Home_HH i.DumSocDist_HH $parentsHealth [pweight=V1032] $cluster
margins educ_parents_high , at(IncDecile=(1(1)10)) over(IncSho10) 
marginsplot , level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("$`outcome'_lab") 
///
*legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\shock_`outcome'_educparents.png" , hei(800) replace

}

/*
reg ProvHoSch i.IncDecile2##i.IncSho10 $childrenCV i.BolsaFa i.EAP_HH i.Formal_HH i.Home_HH i.DumSocDist_HH $parentsHealth if educ_parents_high==0 [pweight=V1032] $cluster
margins , at(IncDecile=(1(1)10)) over(IncSho10) 
marginsplot , level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("Likelihood to be in a school" "that provides homeschooling") ///
legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\shock_prov_educparents0.png" , hei(800) replace

reg ProvHoSch i.IncDecile2##i.IncSho10 $childrenCV i.BolsaFa i.EAP_HH i.Formal_HH i.Home_HH i.DumSocDist_HH $parentsHealth if educ_parents_high==1 [pweight=V1032] $cluster
margins , at(IncDecile=(1(1)10)) over(IncSho10) 
marginsplot , level(90) recast(connected)  xtitle("Decile of pre-pandemic income distribution", size(small)) title("Likelihood to be in a school" "that provides homeschooling") ///
legend(order(3 "No income shock" 4 "Income shock of at least 10%"))
graph export "$GRAPHS\shock_prov_educparents1.png" , hei(800) replace
*/

*** REASON FOR NOT DOING ANY REMOTE LEARNING
tab A007A , gen(A)
graph bar A1-A6 ,  over(IncDecile2) stack ///
legend(pos(12) order(1 "No computer, tablet or smartphone" 2 "No or bad internet" 3 "Health problems" 4 "Obligation with household tasks" 5 "Lack of concentration" 6 "Other reasons") size(vsmall) rows(2)) ///
 bar(1, color(cranberry) fintensity(inten100))  bar(2, color(cranberry) fintensity(inten30)) bar(3, color(dknavy) fintensity(inten70)) bar(4, color(dknavy) fintensity(inten100)) bar(5, color(dknavy) fintensity(inten30)) bar(6, color(black) fintensity(inten100)) ///
 subtitle("Decile of pre-pandemic income distribution", size(small) ring(12) pos(6)) title("Reason for not doing any remote learning")
graph export "$GRAPHS\reason_no_homesch.png" , hei(800) replace
drop A1-A6

*** Size of Income Loss
graph bar IncSho10 , over(IncDecile2)
graph export "$GRAPHS\IncSho10.png" , hei(800) replace

histogram incomeloss if incomeloss>0 , xtitle("Loss of income by..") 
graph export "$GRAPHS\incomeloss.png" , hei(800) replace

reg HomeSch incomeloss i.IncDecile2 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster

reg HoursHomesch incomeloss i.IncDecile2 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster

reg ProvHoSch incomeloss i.IncDecile2 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster

reg private incomeloss i.IncDecile2 $childrenCV $parentsCV $parentsHealth [pweight=V1032] $cluster

xtreg HomeSch incomeloss $childrenCV $parentsCV $parentsHealth [pweight=V1032b] $cluster fe

xtreg HoursHomesch incomeloss $childrenCV $parentsCV $parentsHealth [pweight=V1032b] $cluster fe

xtreg ProvHoSch incomeloss $childrenCV $parentsCV $parentsHealth [pweight=V1032b] $cluster fe

foreach outcome in HomeSch HoursHomesch ProvHoSch {

replace Y = `outcome'

xtreg Y i.incomeloss_cat age i.female i.race i.SinglePar i.LevelEduc i.BolsaFa i.covid19 i.medicare i.hospital i.V1013 $parentsCV $parentsHealth [pweight=V1032b] $cluster fe

margins, at(incomeloss_cat=(0(1)5))  
marginsplot , name(`outcome'_shock, replace) level(90) recast(connected)  xtitle(" " "Loss of income by..", size(norm)) title("$`outcome'_lab") ///
legend(off) xlabel(0(1)5 , valuelabels)
graph export "$GRAPHS\incomeloss_cat_`outcome'.png" , hei(800) replace

}

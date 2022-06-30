/* CLARIFICATIONS
(1) This Stata do-file refers to the working paper "Does a productivity bonus pay off? The effects of teacher incentive pay on student achievement in Brazilian schools" 
and provides a complete overview of the commands used in this paper.
Should you have any queries, please contact the author.

(2) The GERES database is not publicly accessible. Permission requests should be submitted by the members of the project via GERES-homepage. 
See https://laedpucrio.wordpress.com/projetos/o-projeto-geres/ 
*/


* ==================================================================================================== *
                                          // Import GERES-Data //
* ==================================================================================================== *


* Importing Data from CD-ROM.
ssc d usespss
net from http://radyakin.org/transfer/usespss/beta
usespss "C:\Users\...\Data\CD_Dados_GERES\BANCO_DADOS_GERES\Alunos\Informações e Proficiência\Informações_Gerais_GERES.sav", clear
save "C:\Users\...\Data\CD_Dados_GERES\BANCO_DADOS_GERES\Alunos\Informações e Proficiência\DTA\Informações_Gerais_GERES.dta"

** Making the same for the other 5 single samples **
* Informações_Gerais_GERES	--> General information about students
* questionário_alunos(o5)		--> Proxies for learning motivation of students	
* Questionário_escolas			--> Proxies for infrastructure of schools
* Base_QuestProfessores			--> Proxies for (1) teacher´s skills, (2) infrastructure of class rooms, and (3) team work between teachers within the school
* Questionario_turma			--> Proxies for infrastructure of class rooms

clear
* ==================================================================================================== *
                                          // Creating a panel data //
* ==================================================================================================== *

* Reset maximum number of allowed variables
tsset, clear
clear matrix
clear mata
set matsize 10000
set maxvar 32000
use "C:\Users\...\Data\CD_Dados_GERES\DTA.Files\Informações_Gerais_GERES.dta", clear


* Data focus: Students from Campinas
tab Munic_pio, missing
keep if Munic_pio==2 // Working only with schools from Campinas
unique IDaluno


* Normalisation of test scores
* --> Z-score: Test Scores have been rescaled to have a mean of zero and a standard deviation of one.
* Math
egen float Zprofic_mat1 = std(profic_mat1), mean(0) std(1)
egen float Zprofic_mat2 = std(profic_mat2), mean(0) std(1)
egen float Zprofic_mat3 = std(profic_mat3), mean(0) std(1)
egen float Zprofic_mat4 = std(profic_mat4), mean(0) std(1)
egen float Zprofic_mat5 = std(profic_mat5), mean(0) std(1)
* Portuguese
egen float Zprofic_por1 = std(profic_por1), mean(0) std(1)
egen float Zprofic_por2 = std(profic_por2), mean(0) std(1)
egen float Zprofic_por3 = std(profic_por3), mean(0) std(1)
egen float Zprofic_por4 = std(profic_por4), mean(0) std(1)
egen float Zprofic_por5 = std(profic_por5), mean(0) std(1)


* Creating a panel data --> Transpose Data: From wide to long 
tab Onda1, missing
rename Onda1e2 CoOnda1e2 // Rename to avoid overlapping the variable "onda" (wave)
rename Onda1e2e3 CoOnda1e2e3
rename Onda1e2e3e4 CoOnda1e2e3e4
rename Onda1e2e3e4e5 CoOnda1e2e3e4e5
*help reshape
reshape long IDturma s_rie IDescola rede profic_mat profic_por Zprofic_mat Zprofic_por cad_mat cad_por Onda Inf, i(IDaluno) j(wave) 
order GERES_2005 profic Escola Rede  mudou, last
order profic_mat profic_por, after(wave)
mdesc profic_mat profic_por if wave==4


* Declair a panel data structure. "IDaluno" represents the entities or panels (i) and "wave" represents the time variable (t).
xtset IDaluno wave, yearly // strongly balanced
unique IDaluno, by(rede)



* ==================================================================================================== *
                                          // Merging Data //
* ==================================================================================================== *

* Excluding values with missing for both math and portuguese
tab wave if profic_mat==. & profic_por==.
drop if profic_mat==. & profic_por==. // If the student did not take the test, there is missing by IDschool and IDturma

** Reduzing the number of Missing **
* --> Some questions have been asked by bith children and parents. Example education of parents
tab escomaep escomae, missing
generate EducMoth=escomaep
replace EducMoth=escomae if escomaep==.a // 1,213 observations were missing became information (based on infos of children qustionary)
tab EducMoth escomaep, missing

tab escopaip escopai, missing
generate EduFath=escopaip
replace EduFath=escopai if escopaip==.a // 1,305 observations were missing became information (based on infos of children qustionary)
tab EduFath escopaip, missing

* Importing proxies of students' learning motivation * 
rename Munic_pio CityStud
merge m:1 IDaluno using "C:\Users\...\Data\CD_Dados_GERES\DTA.Files\questionário_alunos-merged.dta", keepusing(gender race o5_q26 o5_q25 o5_q02) 
drop if _merge==2 // Only students from Campinas are relevant
label variable _merge "Informacoes Gerais + Questionario Alunos"
rename _merge merge1 
tab CityStud merge1, missing
mdesc gender race o5_q26 o5_q25 o5_q02 nse Renda EduFath EducMoth

* Importing proxies for the infrastructure of schools * 
tab IDescola if IDescola==.a
merge m:1 IDescola using "C:\Users\...\Data\CD_Dados_GERES\DTA.Files\Questionário_escolas.dta", keepusing(e029 e025 e024 e027 e023) // 251 schools are not from Campinas
drop if _merge==2 // Only schools from Campinas are relevant
rename _merge merge2
mdesc e029 e025 e024 e027 e023

* Importing proxies for (1) teacher´s skills, (2) infrastructure of class rooms, and (3) team work between teachers within the school
merge m:1 IDturma using "C:\Users\...\Data\CD_Dados_GERES\DTA.Files\Base_QuestProfessores.dta", keepusing(q111 q100 q110 q108 q106 q105 q104 q036 q038 q037 q039 q044 q045 q046)
drop if _merge==2 // Only IDturmas from Campinas are relevant
label variable _merge "Base_Questionario Professores into Base-GERES"
rename _merge merge3
mdesc q111 q100 q110 q108 q106 q105 q104 q036 q038 q037 q039 q044 q045 q046


* Clearing the data
tab e023, missing // a. means missing values.
 foreach var of varlist o5_q26 o5_q25 Renda EduFath EducMoth q111 q100 q110 q108 q106 q105 q104 q036 q038 q037 q039 q044 q045 q046 e029 e025 e024 e027 e023 { // "Dado ausente" or "não respondeu" = missing
replace `var'=. if `var'==.a
}


* ==================================================================================================== *
                                          //  Summary Statistics  //
* ==================================================================================================== *

// Creation of table with the descriptive Statistics //
* --> Dummy Coding for the categorical variable (education, ocupation and income of parents) 

** Students/Schools/Teachers **
eststo clear
estpost sum Du_o5_q01 o5_q02_1 o5_q02_2 o5_q02_3 o5_q02_4 o5_q02_5 ///
nse Renda_1 Renda_2 Renda_3 Renda_4 Renda_5 escomaep_1 escomaep_2 escomaep_3 escomaep_4 escomaep_5 escopaip_1 escopaip_2 escopaip_3 escopaip_4 escopaip_5 ///
Du_q111 educaTeach_1 educaTeach_2 educaTeach_3 educaTeach_4 educaTeach_5 educaTeach_6 q110_1 q110_2 q110_3 q110_4 q110_5 q110_6 ///
q108_1 q108_2 q108_3 q108_4 q108_5 q108_6 q106_1 q106_2 q106_3 q106_4 q106_5 q105_1 q105_2 q105_3 q104_3 q104_1 q104_2 ///
Du_e029 Du_e025 Du_e024 Du_e027 Du_e023 ///
Du_q036 Du_q038 Du_q037 Du_q039 Du_q044 Du_q045 Du_q046 ///
if Rede==2
est store state
estpost sum Du_o5_q01 o5_q02_1 o5_q02_2 o5_q02_3 o5_q02_4 o5_q02_5 ///
nse Renda_1 Renda_2 Renda_3 Renda_4 Renda_5 escomaep_1 escomaep_2 escomaep_3 escomaep_4 escomaep_5 escopaip_1 escopaip_2 escopaip_3 escopaip_4 escopaip_5 ///
Du_q111 educaTeach_1 educaTeach_2 educaTeach_3 educaTeach_4 educaTeach_5 educaTeach_6 q110_1 q110_2 q110_3 q110_4 q110_5 q110_6 ///
q108_1 q108_2 q108_3 q108_4 q108_5 q108_6 q106_1 q106_2 q106_3 q106_4 q106_5 q105_1 q105_2 q105_3 q104_3 q104_1 q104_2 ///
Du_e029 Du_e025 Du_e024 Du_e027 Du_e023 ///
Du_q036 Du_q038 Du_q037 Du_q039 Du_q044 Du_q045 Du_q046 ///
if Rede==3
est store municipal
estpost sum Du_o5_q01 o5_q02_1 o5_q02_2 o5_q02_3 o5_q02_4 o5_q02_5 ///
nse Renda_1 Renda_2 Renda_3 Renda_4 Renda_5 escomaep_1 escomaep_2 escomaep_3 escomaep_4 escomaep_5 escopaip_1 escopaip_2 escopaip_3 escopaip_4 escopaip_5 ///
Du_q111 educaTeach_1 educaTeach_2 educaTeach_3 educaTeach_4 educaTeach_5 educaTeach_6 q110_1 q110_2 q110_3 q110_4 q110_5 q110_6 ///
q108_1 q108_2 q108_3 q108_4 q108_5 q108_6 q106_1 q106_2 q106_3 q106_4 q106_5 q105_1 q105_2 q105_3 q104_3 q104_1 q104_2 ///
Du_e029 Du_e025 Du_e024 Du_e027 Du_e023 ///
Du_q036 Du_q038 Du_q037 Du_q039 Du_q044 Du_q045 Du_q046 ///
if Rede==4
est store private

esttab state municipal private using desc.tex, replace ///
title(Descriptive Statistics)       ///
addnote("Notes: This table provides descriptive statistics for panel data structure in which each student i was accompanied during the five sample waves. " "Source: GERES database (2005-2008).") ///
mtitles("\textbf{\emph{State}}" "\textbf{\emph{Municipal}}" "\textbf{\emph{Private}}") ///
refcat(Du_o5_q01 "\textbf{\emph{Student}}" o5_q02_1 "\emph{Race}" escomaep_1 "\emph{Education Mother}" escopaip_1 "\emph{Education Father}" Renda_1 "\emph{Household Income}" ///
Du_e029 "\textbf{\emph{School}}" Du_q111 "\textbf{\emph{Teacher}}" educaTeach_1 "\emph{Education Level}" q110_1 "\emph{Age}" q104_3 "\emph{Other Job}" q105_1 "\emph{Schools that work}" q106_1 "\emph{Weekly teaching hours}" q108_1 "\emph{Years of Experience}", nolabel) ///
varlabels (Du_o5_q01 "Male" ///
		   o5_q02_1 "White" o5_q02_2 "Mixed" o5_q02_3 "Black" o5_q02_4 "Asian" o5_q02_5 "Indigenous" ///
		   nse "Socio-economic Status" ///
		   Renda_1 "Very Low" Renda_2 "Low" Renda_3 "Medium" Renda_4 "High" Renda_5 "Very High" ///
		   escomaep_1 "Less then 4 years" escomaep_2 "4 years" escomaep_3 "8 years" escomaep_4 "Secondary" escomaep_5 "Tertiary" ///
		   escopaip_1 "Less then 4 years" escopaip_2 "4 years" escopaip_3 "8 years" escopaip_4 "Secondary" escopaip_5 "Tertiary" ///
		   Du_q111 "Male" ///
		   educaTeach_1 "Less than secondary" educaTeach_2 "Secondary" educaTeach_3 "Vocational" educaTeach_4 "Tertiary" educaTeach_5 "Master" educaTeach_6 "Doctorate" ///
		   q110_1 "Up to 24" q110_2 "25 - 29" q110_3 "30 - 39" q110_4 "40 - 49" q110_5 "50 - 54" q110_6 "More than 55" ///
		   q108_1 "Less than 1" q108_2 "1 - 2" q108_3 "3 - 4" q108_4 "5 - 10" q108_5 "11 - 15" q108_6 "More than 15" ///
		   q106_1 "Up to 20" q106_2 "21 - 25" q106_3 "26 - 30" q106_4 "31 - 40" q106_5 "More than 41" ///
		   q105_1 "Only One" q105_2 "Two" q105_3 "Three or more" ///
  		   q104_3 "No" q104_1 "Yes, in education system" q104_2 "Yes, outside education system" ///
		   Du_e029 "Library" ///
		   Du_e025 "Computer lab" ///
		   Du_e024 "Science lab" ///
		   Du_e027 "Sports court" ///
		   Du_e023 "Art room" ///
		   Du_q036 "Intimidation of students" ///
		   Du_q038 "Intimidation of staffs" ///
		   Du_q037 "Violence against students" ///
		   Du_q039 "Violence against staffs " ///
		   Du_q044 "Depredation" ///
		   Du_q045 "Drug use" ///
		   Du_q046 "Interference of drug trafficking") ///
		   collabels(\multicolumn{1}{c}{{Mean}} \multicolumn{1}{l}{{Std.Dev.}}) ///
cells("mean(fmt(4)) sd(fmt(2))") label nonumber ///
booktabs scalars("sum Students" "k Classes" "r Schools" "t Waves") 




* ==================================================================================================== *
                                          //  Difference in differences (DiD) //
* ==================================================================================================== *

* Creating Difference in difference
tab wave, missing
generate time = (wave==5) & !missing(wave) // Creating time: Treatment started in 2008, this means scores from wave 5 --> Waves 1, 2, 3 and 4 are Zero.
tab rede, missing
generate treated = (rede==2) & !missing(rede) // Creating group exposed to the treatment: Students from (public) state schools --> Schools from public municipal schools are the control group
replace treated=. if rede==4 // private schoools are missings
replace treated=. if rede==.a // "Dado ausente" = missing
generate DiD = time*treated




* ==================================================================================================== *
                                          //  Static Panel //
* ==================================================================================================== *

* Creating lagged variables
generate ZMat_L1 = L1.Zprofic_mat
generate ZPot_L1 = L1.Zprofic_por
generate ZMat_D2 = D2.Zprofic_mat
generate ZPot_D2 = D2.Zprofic_por
list IDaluno wave Zprofic_mat ZMat_L1 in 1/20, sep(5)

/* Creating Macro */ global controlvar q111 q100 q110 q108 q106 q105 q104 e029 e025 e024 e027 e023 q036 q038 q037 q039 q044 q045 q046 
describe $controlvar
mdesc $controlvar

foreach var of varlist wave IDescola { // Creating dummies for fixed effects
tabulate `var', generate(`var'_)
} 


// Math //
eststo clear
/*(LSDV)*/ xtreg Zprofic_mat DiD time treated wave_* IDescola_*, fe nonest i(IDaluno) vce(cluster IDturma)
estadd local FE "Yes"
estadd local controlVa "No"
estadd local dynamic "No"
estadd local lagged "No"
eststo LSDV_M1

/*(LSDV)*/ xtreg Zprofic_mat DiD time treated $controlvar wave_* IDescola_*, fe nonest i(IDaluno) vce(cluster IDturma)
estadd local FE "Yes"
estadd local controlVa "Yes"
estadd local dynamic "No"
estadd local lagged "No"
eststo LSDV_M2

/*(LSDV)*/ xtreg Zprofic_mat DiD time treated wave_* IDescola_* if ZMat_L1!=., fe nonest i(IDaluno) vce(cluster IDturma)
estadd local FE "Yes"
estadd local controlVa "No"
estadd local dynamic "Yes"
estadd local lagged "No"
eststo LSDV_M3

/*(LSDV)*/ xtreg Zprofic_mat DiD time treated $controlvar wave_* IDescola_* if ZMat_L1!=., fe nonest i(IDaluno) vce(cluster IDturma)
estadd local FE "Yes"
estadd local controlVa "Yes"
estadd local dynamic "Yes"
estadd local lagged "No"
eststo LSDV_M4


// Portuguese //
/*(LSDV)*/ xtreg Zprofic_por DiD time treated wave_* IDescola_*, fe nonest i(IDaluno) vce(cluster IDturma)
estadd local FE "Yes"
estadd local controlVa "No"
estadd local dynamic "No"
estadd local lagged "No"
eststo LSDV_P1

/*(LSDV)*/ xtreg Zprofic_por DiD time treated $controlvar wave_* IDescola_*, fe nonest i(IDaluno) vce(cluster IDturma)
estadd local FE "Yes"
estadd local controlVa "Yes"
estadd local dynamic "No"
estadd local lagged "No"
eststo LSDV_P2

/*(LSDV)*/ xtreg Zprofic_por DiD time treated wave_* IDescola_* if ZPot_L1!=., fe nonest i(IDaluno) vce(cluster IDturma)
estadd local FE "Yes"
estadd local controlVa "No"
estadd local dynamic "Yes"
estadd local lagged "No"
eststo LSDV_P3

/*(LSDV)*/ xtreg Zprofic_por DiD time treated $controlvar wave_* IDescola_* if ZPot_L1!=., fe nonest i(IDaluno) vce(cluster IDturma)
estadd local FE "Yes"
estadd local controlVa "Yes"
estadd local dynamic "Yes"
estadd local lagged "No"
eststo LSDV_P4


// Insert table for Static linear panel data models //
#delimit ; 
esttab  LSDV_M1
		LSDV_M2 
		LSDV_M3 
		LSDV_M4 
		LSDV_P1 
		LSDV_P2 
		LSDV_P3 
		LSDV_P4
		using "StaticModel.tex",  
       style(tex)
	   cells(b(star fmt(3)) se(par fmt(3)))
       label 
       stats(N
             N_g
			 r2
			 FE
			 controlVa
			 dynamic
			 lagged,
			 fmt(%9.0f 3)
             labels	("Observations"
					 "N Students"
					 "R-square"
					 "\hline Fixed effects"
					 "Control variables"
					 "Dynamic sample"
					 "Lagged value"))
					 mlabels("(1)" "(2)" "(3)" "(4)" "(1)" "(2)" "(3)" "(4)") nonumbers
			 collabels(none)
			 varlabels(DiD "DiD" 
                 time "Post" 
                 treated "Treated")
				 starl(* 0.1 ** 0.05 *** 0.01)   
       keep(DiD)              
       prehead( 
           \begin{table}[h]
           \refstepcounter{table}            
           \label{table:StaticModel}            
           \centering
           \textbf{Table \ref{table:StaticModel}. Static linear models} \\
           \textbf{Dependent Variable: Student Performance (Test Scores) } 
		   \begin{tabular}{@{\extracolsep{4pt}}l*{@M}{c}@{}} 
           \toprule
		   & \multicolumn{4}{c}{\textbf{Mathematics}} &
           \multicolumn{4}{c}{\textbf{Portuguese}} \\
           \cline{2-5}  
           \cline{6-9}
		   & \multicolumn{1}{c}{LSDV} &
		   \multicolumn{1}{c}{LSDV} &
		   \multicolumn{1}{c}{LSDV} &
           \multicolumn{1}{c}{LSDV} &
		   \multicolumn{1}{c}{LSDV} &
		   \multicolumn{1}{c}{LSDV} &
		   \multicolumn{1}{c}{LSDV} &
           \multicolumn{1}{c}{LSDV} \\
           \cline{2-2}
		   \cline{3-3}
		   \cline{4-4}
           \cline{5-5}
		   \cline{6-6}
		   \cline{7-7}
		   \cline{8-8}
           \cline{9-9} 
       ) 	   
       posthead(\hline) 
       prefoot() 
       postfoot(
           \noalign{\smallskip} \bottomrule
           \end{tabular}
           \medskip
           \begin{minipage}{1\textwidth}
           \footnotesize Notes: Dependent variable is student performance (test scores), which are normalized to mean 0 and standard deviation 1. All models control for individual, school and time fixed effects. Data are not nested within schools. Standard errors in parentheses are robust to heteroskedasticity and clustered at class level. Control variables include the set of explanatory variables presented in table \ref{tab:DescStat}. Dynamic sample refers to the observations in table \ref{table:DynamicModel}. \( @starlegend \). \\
		   Source: GERES database (2005-2008), own estimates.
            \end{minipage}        
       \end{table}
       )
       replace;
#delimit cr





* ==================================================================================================== *
                                          //  Dynamic linear models //
* ==================================================================================================== *

* --> Models with no explanatory variables. For the table with CV, I include $controlvar.  
eststo clear

// Math //
/*(OLS)*/ regress Zprofic_mat ZMat_L1 DiD time treated wave_* IDescola_*, vce(cluster IDturma)
estadd local FE "No"
estadd local controlVa "No"
estadd local lagged "Yes" 
eststo OLS_M
abar, lags(2)

/*(LSDV)*/ xtreg Zprofic_mat ZMat_L1 DiD time treated wave_* IDescola_*, fe nonest i(IDaluno) vce(cluster IDturma)
estadd local FE "Yes"
estadd local controlVa "No"
estadd local lagged "Yes" 
eststo LSDV_M
xtqptest, order(1)
xtqptest, order(2)

/*(GMM)*/ xtabond2 L(0/1).Zprofic_mat DiD time treated wave_* IDescola_*, ///
gmmstyle(L1.Zprofic_mat, equation(diff)) ///
ivstyle(DiD time treated wave_* IDescola_*, eq(level)) ///
cluster(IDturma) twostep small
estadd local FE "Yes"
estadd local controlVa "No"
estadd local lagged "Yes" 
eststo GMM_M


// Portuguese //
/*(OLS)*/ regress Zprofic_por ZPot_L1 DiD time treated wave_* IDescola_*, vce(cluster IDturma)
estadd local FE "No"
estadd local controlVa "No"
estadd local lagged "Yes"  
eststo OLS_P
abar, lags(2)

/*(LSDV)*/ xtreg Zprofic_por ZPot_L1 DiD time treated wave_* IDescola_*, fe nonest i(IDaluno) vce(cluster IDturma)
estadd local FE "Yes"
estadd local controlVa "No"
estadd local lagged "Yes"
eststo LSDV_P
xtqptest, order(1)
xtqptest, order(2)


/*(GMM)*/ xtabond2 L(0/1).Zprofic_por DiD time treated wave_* IDescola_*, ///
gmmstyle(L1.Zprofic_por, equation(diff)) ///
ivstyle(DiD time treated wave_* IDescola_*, eq(level)) ///
cluster(IDturma) twostep small
estadd local FE "Yes"
estadd local controlVa "No"
estadd local lagged "Yes"
eststo GMM_P

// Inserting the table: Dynamic linear models
#delimit ; 
estout OLS_M
       LSDV_M
	   GMM_M
       OLS_P
       LSDV_P
	   GMM_P
	   using "dynamic.tex",  
       style(tex) 
       cells(b(star fmt(3)) t(par fmt(3))) 
       label 
       stats(N
             N_g
			 r2
             AR1
			 AR2
			 Sargan
			 Instruments
			 FE
			 controlVa
			 lagged,
             fmt(0 0 3 3)
             labels("\hline AR(1)"
					"AR(2)"
					"Sargan test"
					"\hline Instruments"
					"\hline N Observations"
					"N Students"
					"R-square"
					"\hline Fixed Effects"
					"Control variables"
				    "Lagged value"))
       mlabels("(1)" "(2)" "(3)" "(1)" "(2)" "(3)") nonumbers
       collabels(none)
	   varlabels(DiD "DiD" ZMat_L1 "Lagged y-1" )
       starl(* 0.1 ** 0.05 *** 0.01)   
       keep(DiD ZMat_L1)              
       order(DiD ZMat_L1) 
       prehead( 
           \begin{table}[h]
           \refstepcounter{table}            
           \label{table:GMMResults}            
           \centering
           \textbf{Table \ref{table:GMMResults}. Dynamic linear models} \\
            \begin{tabular}{@{\extracolsep{4pt}}l*{@M}{c}@{}} 
           \toprule 
           & \multicolumn{3}{c}{\textbf{Mathematics}} &
           \multicolumn{3}{c}{\textbf{Portuguese}} \\
           \cline{2-4}  
           \cline{5-7}
		   & \multicolumn{1}{c}{OLS} &
		   \multicolumn{1}{c}{LSDV} &
		   \multicolumn{1}{c}{GMM} &
		   \multicolumn{1}{c}{OLS} &
		   \multicolumn{1}{c}{LSDV} &
           \multicolumn{1}{c}{GMM} \\
           \cline{2-2}
		   \cline{3-3}
		   \cline{4-4}
           \cline{5-5}
		   \cline{6-6}
		   \cline{7-7}
       )
       posthead(\hline) 
       prefoot() 
       postfoot(
           \noalign{\smallskip} \bottomrule 
           \end{tabular}
           \medskip
           \begin{minipage}{1\textwidth}
           \scriptsize Notes: Dependent variable is student performance (test scores), which are normalized to mean 0 and standard deviation 1. Year and school dummies included in all models. Data are not nested within schools. Standard errors in parentheses are robust to heteroskedasticity and clustered at class level. $\text{\emph{p}}$-values are reported in square brackets. Estimations based on two-step GMM. The zero hypothesis of the Sargan test is H0: overidentifying restrictions are valid. For the Arellano-Bond test, AR(1) and AR(2) are respectively tests for first and second-order correlation in the first-differenced residuals under the null hypothesis of H0: no autocorrelation.  \( @starlegend \).\\
   		   Source: GERES database (2005-2008), own estimates.
           \end{minipage}        
       \end{table}
       )
       replace;
#delimit cr




* ==================================================================================================== *
                                         /*  Robusteness Checks */
* ==================================================================================================== *

* --> Models with no explanatory variables. For the table with CV, I include $controlvar. 
eststo clear

// Math //
/*(OLS)*/ regress Zprofic_mat ZMat_L1 DiD time treated wave_* IDescola_* if ZMat_D2!=., vce(cluster IDturma)
estadd local FE "No"
estadd local controlVa "No"
eststo OLS_M
abar, lags(2)

/*(LSDV)*/ xtreg Zprofic_mat ZMat_L1 DiD time treated wave_* IDescola_* if ZMat_D2!=., vce(cluster IDturma) fe nonest i(IDaluno)
estadd local FE "Yes"
estadd local controlVa "No"
eststo LSDV_M
xtqptest, order(1)
xtqptest, order(2)

/*(2SLS)*/ ivreg2 Zprofic_mat DiD time treated wave_* IDescola_* IDaluno_* (ZMat_L1=ZMat_D2), cluster (IDturma)
estadd local FE "Yes"
estadd local controlVa "No" 
eststo TSLS_M


/*(GMM)*/ xtabond2 L(0/1).Zprofic_mat DiD time treated wave_* IDescola_* if ZMat_D2!=., ///
gmmstyle(L1.Zprofic_mat, equation(diff)) ///
ivstyle(DiD time treated wave_* IDescola_*, eq(level)) ///
cluster(IDturma) twostep small
estadd local FE "Yes"
estadd local controlVa "No"
eststo GMM_M

// Portuguese //
/*(OLS)*/ regress Zprofic_por ZPot_L1 DiD time treated wave_* if ZPot_D2!=., vce(cluster IDturma)
estadd local FE "No"
estadd local controlVa "No" 
eststo OLS_P
abar, lags(2)

/*(LSDV)*/ xtreg Zprofic_por ZPot_L1 DiD time treated wave_* IDescola_* if ZPot_D2!=., vce(cluster IDturma) fe nonest i(IDaluno)
estadd local FE "Yes"
estadd local controlVa "No"
eststo LSDV_P
xtqptest, order(1)
xtqptest, order(2)

/*(2SLS)*/ ivreg2 Zprofic_por DiD time treated wave_* IDescola_* IDaluno_* (ZPot_L1=ZPot_D2), cluster (IDturma)
estadd local FE "Yes"
estadd local controlVa "No"
eststo TSLS_P
abar, lags(2)

/*(GMM)*/ xtabond2 L(0/1).Zprofic_por DiD time treated wave_* IDescola_* if ZPot_D2!=., ///
gmmstyle(L1.Zprofic_por, equation(diff)) ///
ivstyle(DiD time treated wave_* IDescola_*, eq(level)) ///
cluster(IDturma) twostep small
estadd local FE "Yes"
estadd local controlVa "No"
eststo GMM_P



// Inserting the table: Robustness checks
#delimit ; 
estout OLS_M
       LSDV_M
	   TSLS_M
       GMM_M
       OLS_P
	   LSDV_P
	   TSLS_P
	   GMM_P
	   using "robustness.tex",  
       style(tex) 
       cells(b(star fmt(3)) t(par fmt(3))) 
       label 
       stats(N
             N_g
			 r2
             AR1
			 AR2
			 Sargan
			 Instruments
			 FE
			 controlVa,
			 fmt(0 0 3 3)
             labels("\hline AR(1)"
					"AR(2)"
					"Sargan test"
					"\hline Instruments"
					"\hline N Observations"
					"N Students"
					"R-square"
					"\hline Fixed Effects"
					"Control variables"))
	   mlabels("(1)" "(2)" "(3)" "(4)" "(1)" "(2)" "(3)" "(4)") nonumbers
       collabels(none)
	   varlabels(DiD "DiD" ZMat_L1 "Lagged y-1" )
       starl(* 0.1 ** 0.05 *** 0.01)   
       keep(DiD ZMat_L1)              
       order(DiD ZMat_L1) 
       prehead( 
           \begin{table}[h]
           \refstepcounter{table}            
           \label{table:Robustness}            
           \centering
           \textbf{Table \ref{table:Robustness}. Robustbess checks} \\
            \begin{tabular}{@{\extracolsep{4pt}}l*{@M}{c}@{}} 
           \toprule 
           & \multicolumn{4}{c}{\textbf{Mathematics}} &
           \multicolumn{4}{c}{\textbf{Portuguese}} \\
           \cline{2-5}  
           \cline{6-9}
		   & \multicolumn{1}{c}{OLS} &
		   \multicolumn{1}{c}{LSDV} &
		   \multicolumn{1}{c}{2SLS} &
		   \multicolumn{1}{c}{GMM} &
		   \multicolumn{1}{c}{OLS} &
		   \multicolumn{1}{c}{LSDV} &
		   \multicolumn{1}{c}{2SLS} &
           \multicolumn{1}{c}{GMM} \\
           \cline{2-2}
		   \cline{3-3}
		   \cline{4-4}
           \cline{5-5}
		   \cline{6-6}
		   \cline{7-7}
		   \cline{8-8}
		   \cline{9-9}
       )
       posthead(\hline) 
       prefoot() 
       postfoot(
           \noalign{\smallskip} \bottomrule 
           \end{tabular}
           \medskip
           \begin{minipage}{1\textwidth}
           \scriptsize Notes: Dependent variable is student performance (test scores), which are normalized to mean 0 and standard deviation 1. Year and school dummies included in all models. Data are not nested within schools. Standard errors in parentheses are robust to heteroskedasticity and clustered at class level. $\text{\emph{p}}$-values are reported in square brackets. Estimations based on two-step GMM. The zero hypothesis of the Sargan test is H0: overidentifying restrictions are valid. For the Arellano-Bond test, AR(1) and AR(2) are respectively tests for first and second-order correlation in the first-differenced residuals under the null hypothesis of H0: no autocorrelation.  \( @starlegend \).\\
   		   Source: GERES database (2005-2008), own estimates.
           \end{minipage}        
       \end{table}
       )
       replace;
#delimit cr



* ==================================================================================================== *
                                          //  Placebo Test //
* ==================================================================================================== *

/* --> For this test, I perform an additional difference-in-differences estimation using a "fake" implementation data of bonus (2006) --> Teacher bonus program was introduced on 15 October 2007 */

	 * Creating Difference in difference
generate time1 = (wave==3) & !missing(wave) // Creating time: Treatment started in 2006, this means scores from wave 3 --> Waves 1, 2 are Zero --> Waves 4 and 5 are missing
replace time1=. if wave==5
replace time1=. if wave==4
generate treated1 = (rede==2) & !missing(rede) // Creating group exposed to the treatment: Students from (public) state schools --> Schools from public municipal schools are the control group
replace treated1=. if rede==4 // private schoools are missings
replace treated1=. if rede==.a // "Dado ausente" = missing
generate DiD1 = time1*treated1

eststo clear

// Math //
/*(LSDV)*/ xtreg Zprofic_mat DiD1 time1 treated1 wave_* IDescola_*, fe nonest i(IDaluno) vce(cluster IDturma)
estadd local FE "Yes"
estadd local controlVa "No"
estadd local lagged "No" 
eststo LSDV_M

/*(GMM)*/ xtabond2 L(0/1).Zprofic_mat DiD1 time1 treated1 wave_* IDescola_*, ///
gmmstyle(L1.Zprofic_mat, equation(diff)) ///
ivstyle(DiD1 time1 treated1 wave_* IDescola_*, eq(level)) ///
cluster(IDturma) twostep small
estadd local FE "Yes"
estadd local controlVa "No"
estadd local lagged "Yes" 
eststo GMM_M

/*(LSDV)*/ xtreg Zprofic_mat DiD1 time1 treated1 wave_* IDescola_* if ZMat_L1!=., fe nonest i(IDaluno) vce(cluster IDturma)
estadd local FE "Yes"
estadd local controlVa "No"
estadd local lagged "No" 
eststo LSDV_M2


// Portuguese //
/*(LSDV)*/ xtreg Zprofic_por DiD1 time1 treated1 wave_* IDescola_*, fe nonest i(IDaluno) vce(cluster IDturma)
estadd local FE "Yes"
estadd local controlVa "No"
estadd local lagged "No" 
eststo LSDV_P

/*(GMM)*/ xtabond2 L(0/1).Zprofic_por DiD1 time1 treated1 wave_* IDescola_*, ///
gmmstyle(L1.Zprofic_por, equation(diff)) ///
ivstyle(DiD1 time1 treated1 wave_* IDescola_*, eq(level)) ///
cluster(IDturma) twostep small
estadd local FE "Yes"
estadd local controlVa "No"
estadd local lagged "Yes"
eststo GMM_P

/*(LSDV)*/ xtreg Zprofic_por DiD1 time1 treated1 wave_* IDescola_* if ZPot_L1!=., fe nonest i(IDaluno) vce(cluster IDturma)
estadd local FE "Yes"
estadd local controlVa "No"
estadd local lagged "No" 
eststo LSDV_P2


// Inserting the table: Placebo Tests
#delimit ; 
estout LSDV_M
       GMM_M
	   LSDV_M2
       LSDV_P
       GMM_P
	   LSDV_P2
	   using "placebo.tex",  
       style(tex) 
       cells(b(star fmt(3)) t(par fmt(3))) 
       label 
       stats(N
             N_g
			 r2
             FE
			 controlVa
			 lagged,
			 fmt(0 0 3 3)
             labels("\hline N Observations"
					"N Students"
					"R-square"
					"Fixed Effects"
					"Control variables"
					"Lagged value"))
	   mlabels("(1)" "(2)" "(3)" "(1)" "(2)" "(3)") nonumbers
       collabels(none)
	   varlabels(DiD1 "DiD" ZMat_L1 "Lagged y-1" )
       starl(* 0.1 ** 0.05 *** 0.01)   
       keep(DiD1 ZMat_L1)              
       order(DiD1 ZMat_L1) 
       prehead( 
           \begin{table}[h]
           \refstepcounter{table}            
           \label{table:placebo}            
           \centering
           \textbf{Table \ref{table:placebo}. Placebo tests} \\
            \begin{tabular}{@{\extracolsep{4pt}}l*{@M}{c}@{}} 
           \toprule 
           & \multicolumn{3}{c}{\textbf{Mathematics}} &
           \multicolumn{3}{c}{\textbf{Portuguese}} \\
           \cline{2-4}  
           \cline{5-7}
		   & \multicolumn{1}{c}{LSDV} &
		   \multicolumn{1}{c}{GMM} &
		   \multicolumn{1}{c}{LSDV} &
		   \multicolumn{1}{c}{LSDV} &
		   \multicolumn{1}{c}{GMM} &
		   \multicolumn{1}{c}{LSDV} \\
           \cline{2-2}
		   \cline{3-3}
		   \cline{4-4}
           \cline{5-5}
		   \cline{6-6}
		   \cline{7-7}
	   )
       posthead(\hline) 
       prefoot() 
       postfoot(
           \noalign{\smallskip} \bottomrule 
           \end{tabular}
           \medskip
           \begin{minipage}{1\textwidth}
           \scriptsize Notes: Dependent variable is student performance (test scores), which are normalized to mean 0 and standard deviation 1. Placebo tests refer to the year of 2006 in which the teacher bonus was still not implemented. Models with fixed effects control for individual, school and time fixed effects. Data are not nested within schools. Standard errors in parentheses are robust to heteroskedasticity and clustered at class level. Estimations based on two-step GMM. \( @starlegend \).\\
   		   Source: GERES database (2005-2008), own estimates.
           \end{minipage}        
       \end{table}
       )
       replace;
#delimit cr




* ==================================================================================================== *
                                          //  Figures //
* ==================================================================================================== *


// Boxplot with the student performance in Math and Portugueses (figure A2) //
tab rede, missing
graph box profic_mat profic_por, over(wave) over(rede) ///
ylabel(#10) ytitle("Test Scores") ///
legend( label(1 "Mathematics") label(2 "Portuguese"))


// Student performance in Math and Portugueses per school typ //
// Math (figure 3)//
preserve
collapse (mean) profic_mat, by (rede wave)
reshape wide profic_mat, i(wave) j(rede)
graph twoway connected profic_mat2 profic_mat3 profic_mat4 wave, xaxis(1 2) sort ///
xline(0.95 2.05 3.05 4.05 5.05, lstyle(grid) lpattern(shortdash) lcolor(red)) ///
ytitle("Test Scores") xtitle("GERES-Waves") ylabel(0(50)300,format(%9.0f))  ///
xlabel(3.9 "Law nº1017", axis(2)) xtitle("", axis(2)) ///
legend(label(3 "Private") label(2 "Municipal")label(1 "State")) ///
msymbol(triangle square circle) legend(col(3)) ///
text(297 1.3 "2005" 297 2.4 "2006" 297 3.4 "2007" 297 4.4 "2008", ///
place(se) box just(center) lpattern(shortdash) color(red) lcolor(red) bcolor(none) width(10))

// Portuguese (figure 4)//
preserve
collapse (mean) profic_por, by (rede wave)
reshape wide profic_por, i(wave) j(rede)
graph twoway connected profic_por2 profic_por3 profic_por4 wave, xaxis(1 2) sort ///
xline(0.95 2.05 3.05 4.05 5.05, lstyle(grid) lpattern(shortdash) lcolor(red)) ///
ytitle("Test Scores") xtitle("GERES-Waves") ylabel(0(30)180,format(%9.0f))  ///
xlabel(3.9 "Law nº1017", axis(2)) xtitle("", axis(2)) ///
legend(label(3 "Private") label(2 "Municipal")label(1 "State")) ///
msymbol(triangle square circle) legend(col(3)) ///
text(297 1.3 "2005" 297 2.4 "2006" 297 3.4 "2007" 297 4.4 "2008", ///
place(se) box just(center) lpattern(shortdash) color(red) lcolor(red) bcolor(none) width(10))







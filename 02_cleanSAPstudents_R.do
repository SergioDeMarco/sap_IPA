/* **********************************************************************************************
Program name: 02_cleanSAPstudents
Previous file: N/A
Author: Sergio De Marco
Date created: 3-Mar-2016
Date last modified: 
Project: Returns to postprimary education

Purpose: Clean SAP student rural survey V1 and V2

Files used:
                " ... "
				
Files created:
               
Note on missing values based on Cuanto coding:
•	-9 blank (.a),
•	-8 can't be read (.b),
•	-7 error (.c),
•	-6 no aplica (.d),
•	-3 I don't know (.e).

*************************************************************************************************/

***************************
******Preparing Stata******
***************************

	clear all
	set more off

set dp period // Fix period as decimal separation
program drop _all
file close _all
log close _all

cap cd "X:\Dropbox\educ_peru\07_Questionnaires & Data\01_Data\Baseline 2015\Dofiles\Clean\SAP IPA", clear

* Analysis with Urban data
use "..\..\..\Data\Clean\SAPruralstudentsV1_160302.dta", clear

* Based on Note on missing value above I would replace them respectively as -9=.a, ..., or -value with one missing ".".
** Replace "-9" as missing value, coded as .a ("blank"), "-8" as 
	
	ds, has(type numeric)
qui foreach var in `r(varlist)' {
	recode `var' (-9=.a) (-8=.b) (-7=.c) (-6=.d) (-6=.e)
}
	
************************************
* PERSONAL IDENTIFYING INFORMATION *
************************************
* create one name
gen name=A_NOM //we take the preprint name (only pre-print info should be in A_NOM)
	replace name=C_NOM if B_A1==2 | (A_NOM=="" & C_NOM!="") // when preprint info is wrong or when no preprint and there is selfreported info
gen lastname1=A_APEPAT 
	replace lastname1=C_APEPAT if B_A2==2 | (A_APEPAT=="" & C_APEPAT!="")
gen lastname2=A_APEMAT
	replace lastname2=C_APEMAT if B_A3==2 | (A_APEMAT=="" & C_APEMAT!="")
	
gen name_source=1 if name==A_NOM
	replace name_source=2 if B_A1==2
	replace name_source=3 if A_NOM=="" & C_NOM!=""
gen lastname1_source=1 if lastname1==A_APEPAT
	replace lastname1_source=2 if B_A2==2
	replace lastname1_source=3 if A_APEPAT=="" & C_APEPAT!=""
gen lastname2_source=1 if lastname2==A_APEMAT
	replace lastname2_source=2 if B_A3==2
	replace lastname2_source=3 if A_APEMAT=="" & C_APEMAT!=""
	
gen sex=G_SEXO
	replace sex=I_SEXO if H_A1==2
	replace sex=I_SEXO if G_SEXO==. & I_SEXO!=.
label define sex 1 "Hombre" 2 "Mujer"
label values sex sex

gen sex_source=1 if sex==G_SEXO
	replace sex_source=2 if H_A1==2
	replace sex_source=3 if G_SEXO==. & I_SEXO!=.
	
gen dateofbirth=mdy(D_MM,D_DD,D_AA)
	replace dateofbirth=mdy(F_MM,F_DD,F_AA) if E_A1==2
	replace dateofbirth=mdy(F_MM,F_DD,F_AA) if (F_MM!=. & F_DD!=. & F_AA!=.) & (D_MM==. & D_DD==. & D_AA==.)
gen dateofbirth_source=1 if E_A1!=2
	replace dateofbirth_source=2 if E_A1==2 & (F_MM!=. & F_DD!=. & F_AA!=.)
	replace dateofbirth_source=3 if (F_MM!=. & F_DD!=. & F_AA!=.) & (D_MM==. & D_DD==. & D_AA==.)
gen dateofsurvey=mdy(MM1_ENC,DD1_ENC,AA1_ENC)

gen ageatsurvey=round((dateofsurvey-dateofbirth)/365,1)

gen DNI=J_DNI
	replace DNI=L_DNI if K_A1==2 // preprint is incorrect
	replace DNI=L_DNI if L_DNI!=. & J_DNI==. //mostly missing values

gen DNI_source=1
	replace DNI_source=2 if K_A1==2 
	replace DNI_source=3 if DNI==L_DNI & L_DNI!=. & J_DNI==. 
	
label define source 1 "Pre-print" 2 "Pre-print, corrected by student" 3 "No pre-print"
label values *_source source

compress

***************************************************************************************************************************************************
* OTHER INFORMATION (NON NUMERICAL VARIABLES)*
**********************************************

// Elegimos la primera rpta. JLFT: I'm considering a different rule here: For most answers, I'm taking the max value in the answer, trying to interpret what kids might have meant.
* P2A: Mother Tongue (P2A*)
* Quechua & Aymara are the most popular 2nd answers. We presume kids are embarrassed of confessing them as their mother tongue and so we consider the first non-Spanish mother tongue as the real one.
gen P2A=P2A_1
foreach i in 2 3 4 {
	replace P2A=P2A_`i' if P2A_`i'!=1 & P2A_`i'!=. & P2A_1==1
}
local x: var label P2A_1 
label var P2A "`x'"
label values P2A P2A_1
drop P2A_1 P2A_2 P2A_3 P2A_4

* P3*: Educational achievement of household members (mother, father, sibling, and others)
qui foreach r in A B C D { //across relatives
	cap drop p3_`r'
	recode P3`r'* (5=-2) (6=-3) //temporal change so that -rowmax- below doesn't get the don't-knows and the don't-haves.
	egen P3_`r'=rowmax(P3`r'_1 P3`r'_2 P3`r'_3 P3`r'_4 P3`r'_5 P3`r'_6)
	recode P3`r'*(-2=5) (-3=6)
	replace P3_`r'=0 if P3`r'_1==5 | P3`r'_2==5 | P3`r'_3==5 | P3`r'_4==5 | P3`r'_5==5 | P3`r'_6==5 //doesn't know
	replace P3_`r'=.f if P3`r'_1==6 | P3`r'_2==6 | P3`r'_3==6 | P3`r'_4==6 | P3`r'_5==6 | P3`r'_6==6 //doesn't have this relative
}
ren (P3_A P3_B P3_C P3_D) (P3_mother P3_father P3_sibling P3_other)

label define P3A_1 0 "No sé", add
label values P3_* P3A_1	

* P5: Self-reported effort in school: we take the max value reported, as kids who gave weird answers usually marked all options up to a certain one (as opposed to marking ALL options)
egen P5=rowmax(P5_1 P5_2 P5_3 P5_4 P5_5)
local x: var label P5_1 
label var P5 "`x'" 
drop P5_1 P5_2 P5_3 P5_4 P5_5
label values P5 P5_1

* P6: Self perception of RENDIMIENTO ACADEMICO in Math and Comm (6A 6B)
* P8: Self perception of HABILIDAD in Math and Comm (8A 8B)
foreach i in 6A 6B 8A 8B { 
	egen P`i'=rowmax(P`i'_1-P`i'_5)
	local x: var label P`i'_1 
	label var P`i' "`x'" 
	drop P`i'_*
	label values P`i' P`i'_1
}

* P7: Subject in which they perceive to have the most ability 
recode P7_1 (6=.f) //Subject is not on list
egen P7=rowmax(P7_1 P7_2 P7_3 P7_4 P7_5 P7_6) //note: highest value in P7_* is now 5, i.e. "All subjects"-
local x: var label P7_1 
label var P7 "`x'" 
drop P7_*
label values P7 P7_1

* PLANS
* P10: How much have you thought on the education you would like to achieve?
* P11: What level of education you would to achieve?
foreach q in P10 P11 {
	egen `q'=rowmax(`q'_1 `q'_2 `q'_3 `q'_4)
	local x: var label `q'_1
	label var `q' "`x'"
	drop `q'_*
	label values `q' `q'_1
}

* PROBABILITIES
* P9: Prob of increasing ability
* P18: Considering obstacles, Prob of getting scholarship and educ.(A) credit (B)
* P19: Considering obstacles, Prob of accessing higher ed: technical(A) & university(B)
* P20: Conditional on high effort and highest possible ability, Prob of accessing higher ed: technical(A) & university(B)
foreach t in 9A 9B 18A 18B 19A 19B 20A 20B {
	egen P`t'=rowmax(P`t'_01-P`t'_11)
	local x: var label P`t'_01 
	label var P`t' "`x'" 
	drop P`t'_*
	label values P`t' P`t'_01
}

* P13: What obstacles you think you would face?: Students were told to report only 3 obstacles. In case they declared more than 4 obstacles we are considering 	.b=wrong answer (yes/no: yes & no)
egen aux_rownonmissp13=rownonmiss(P13_1-P13_7)
foreach i in 1 2 3 4 5 6 7 {
	replace P13_`i'=.b if aux_rownonmissp13>4
}
drop P13_4-P13_7 // Drop all answers beyond the 3rd.

* P14: How do most peruvians finance their higher ed? We only asked for 1 answer, so we keep the first. In case they reported more than 2 answers we consider .b=wrong answer.
egen aux_rownonmissp14=rownonmiss(P14_1-P14_5)
replace P14_1=.b if aux_rownonmissp14>2
ren P14_1 P14
drop P14_2-P14_5

* P15: Knows about Beca 18
replace P15A=1 if P15B!="" & (P15B!="-9" & P15B!="-8" & P15B!="-7")
gen KnowsBeca18=(strmatch(lower(P15B),"*beca*") | strmatch(lower(P15B),"*veca*")) |  strmatch(lower(P15B),"*18*")

* P16: Do you know which institutions give scholarships?
egen aux_rownonmissp16=rownonmiss(P16_1-P16_4)
gen aux_p16nose=4 if (P16_1==4 | P16_2==4 | P16_3==4 | P16_4==4) & aux_rownonmissp16!=4 //they marked they do not know and are not botching the survey
foreach i in 1 2 3 4 {
	replace P16_`i'=.b if aux_rownonmissp16==4 //survey botchers
	replace P16_`i'=.b if aux_p16nose==4 //those who don't know.
}
replace P16_1=1 if aux_p16nose==4 //if they don't know, then that should be their first answer.

* P23: If no obstacle and fee=zero, what level of education would you like to achieve? 
egen P23=rowmax(P23_1 P23_2 P23_3 P23_4)
local x: var label P23_1
label var P23 "`x'"
drop P23_*
label values P23 P23_1

* P25: What's the most important factor behind your major choice? - Max: 2 answers. If more than 3 answers, then .b for all.
egen aux_rownonmissp25=rownonmiss(P25_1-P25_5)
replace P25_1=.b if aux_rownonmissp25>3
replace P25_2=.b if aux_rownonmissp25>3
drop P25_3 P25_4 P25_5

drop aux*
compress

***************************************************************************************************************************************************

**************************************
* OTHER INFORMATION (NUMERICAL DATA) *
**************************************

* : HOURS
****************************

* : W(E), Expecteed incomes at different educational levels
***********************************************************

* DROP variables que ya tiene info (son -9 en las rptas)

/// Fixing the continuous variable: pregunta 21 parte 1

 * CASOS ESPECIALES 

replace P21_1_A_3 = subinstr(P21_1_A_3, ",", "",.) // we eiliminate commas but for dots we should apply the same rules as in urban

/*replace P21_1_A_3="7000" if P21_1_A_3=="00,7000" 
replace P21_1_A_3="1000" if P21_1_A_3=="1,000" 
replace P21_1_A_3="1500" if P21_1_A_3=="1'500"
replace P21_1_A_3="10810" if P21_1_A_3=="1'0810"
replace P21_1_A_4="2090" if P21_1_A_4=="2'090"
replace P21_1_A_4="10000" if P21_1_A_4=="10'000" 
replace P21_1_A_4="2200" if P21_1_A_4=="2'200.0"
replace P21_1_A_4="4000" if P21_1_A_4=="4'000"


foreach i in 1 2 3 4 {
	replace P21_1_A_`i'=".a" if  P21_1_A_`i'=="-9"
	replace P21_1_A_`i'=".b" if  P21_1_A_`i'=="-8"
	replace P21_1_A_`i'=".c" if  P21_1_A_`i'=="-7"
	split P21_1_A_`i', parse("," "." ".." " " "  " ";" ":" "Â´") 
} 
		
****************************************************
// Establecemos una regla para limpiar los numeros 
 
// Solo hacemos concat cuando el lenght del string es mayor igual a 3.
// No son puntuacion

foreach i in 1 2 3 4 {
	replace P21_1_A_`i'2="" if (length(P21_1_A_`i'2)==2 & length(P21_1_A_`i'1)>=2)
	replace P21_1_A_`i'2="" if (length(P21_1_A_`i'2)==1 & length(P21_1_A_`i'1)>=2)
	replace P21_1_A_`i'3="" if length(P21_1_A_`i'3)==2 
egen P21_1_A_`i'_new=concat(  P21_1_A_`i'1 P21_1_A_`i'2 P21_1_A_`i'3)
destring P21_1_A_`i'_new, replace
	} 

drop P21_1_A_11 P21_1_A_12 P21_1_A_13 P21_1_A_21 P21_1_A_22 P21_1_A_23 ///
P21_1_A_31 P21_1_A_32 P21_1_A_33 P21_1_A_41 P21_1_A_42 P21_1_A_43 P21_1_A_44

/// Fixing the continuous variable: pregunta 21 parte 2

replace P21_2_A_1="1000" if P21_2_A_1=="1,0,00"
replace P21_2_A_1="40" if P21_2_A_1=="4.0"
replace P21_2_A_1="80" if P21_2_A_1=="8.0"
replace P21_2_A_1="800" if P21_2_A_1=="8.00.00"
replace P21_2_A_1="400" if P21_2_A_1=="4.0.0"
replace P21_2_A_1="4000" if P21_2_A_1=="4.0.00"
replace P21_2_A_3="1000" if P21_2_A_3=="1'000"
replace P21_2_A_3="1800" if P21_2_A_3=="1'800"
replace P21_2_A_3="2550" if P21_2_A_3=="2'550"
replace P21_2_A_4="2460" if P21_2_A_4=="2,4,60 "
replace P21_2_A_4="25000" if P21_2_A_4=="2,5,000" 
replace P21_2_A_3="4300" if P21_2_A_3=="4'300"
replace P21_2_A_4="4300" if P21_2_A_4=="4'300"
replace P21_2_A_4="10000" if P21_2_A_4=="10'000" 
replace P21_2_A_4="1010" if P21_2_A_4=="10..1.0" 
replace P21_2_A_4="2200" if P21_2_A_4=="2'200.0"
replace P21_2_A_4="2070" if P21_2_A_4=="2'070"
replace P21_2_A_4="5000" if P21_2_A_4=="5'000"
replace P21_2_A_4="6500" if P21_2_A_4=="6.5.000"
replace P21_2_A_4="600" if P21_2_A_4=="6.00.00"
replace P21_2_A_4="950" if P21_2_A_4=="9.50.00"

foreach i in 1 2 3 4 {
	replace P21_2_A_`i'=".a" if  P21_2_A_`i'=="-9"
	replace P21_2_A_`i'=".b" if  P21_2_A_`i'=="-8"
	replace P21_2_A_`i'=".c" if  P21_2_A_`i'=="-7"
	split P21_2_A_`i', parse("," "." " " ";" ":" "Â´") 
	} 
	
foreach i in 1 2 3 4 {
	replace P21_2_A_`i'2="" if (length(P21_2_A_`i'2)==2 & length(P21_2_A_`i'1)>=2)
	replace P21_2_A_`i'2="" if (length(P21_2_A_`i'2)==1 & length(P21_2_A_`i'1)>=2)
	replace P21_2_A_`i'3="" if length(P21_2_A_`i'3)==2 
egen P21_2_A_`i'_new=concat(  P21_2_A_`i'1 P21_2_A_`i'2 P21_2_A_`i'3)
destring P21_2_A_`i'_new, replace
	} 

drop P21_2_A_11 P21_2_A_12 P21_2_A_13 P21_2_A_21 P21_2_A_22 P21_2_A_23 ///
P21_2_A_31 P21_2_A_32 P21_2_A_33 P21_2_A_41 P21_2_A_42 P21_2_A_43 P21_2_A_44
 
/// using the opcion "same as average"

foreach i in 1 2 3 4 {
	replace P21_2_A_`i'_new= P21_1_A_`i'_new if P21_2_B_`i'==-4 & P21_2_A_`i'_new==-9
	replace P21_2_A_`i'_new=. if P21_2_A_`i'_new==-9
} 
*/
*******************************************************************************
* CLEANING part 3: W(E) by areas of study

* DROP variables que ya tiene info (son -9 en las rptas)

/// Fixing the continuous variable: pregunta 21 parte 1

 * CASOS ESPECIALES 

 replace P22_1_A_1 = subinstr(P22_1_A_1, ",", "",.) // we eiliminate commas but for dots we should apply the same rules as in urban

/* 
 replace P22_1_A_1="1000" if P22_1_A_1=="1'000"
 replace P22_1_A_1="3000" if P22_1_A_1=="3'000"
 replace P22_1_A_1="2500" if P22_1_A_1=="2'500"
 replace P22_1_A_1="850" if P22_1_A_1=="8.50.00"
 replace P22_1_A_1="800" if P22_1_A_1=="8.00.00"
 replace P22_1_A_1="800" if P22_1_A_1=="8,00" 
 
 replace P22_1_A_2="1000" if P22_1_A_2=="1'000"
 replace P22_1_A_2="3000" if P22_1_A_2=="3'000"
 replace P22_1_A_2="4000" if P22_1_A_2=="4'000"
 replace P22_1_A_2="5000" if P22_1_A_2=="5.0.00"
 replace P22_1_A_2="500" if P22_1_A_2=="5.00"
 replace P22_1_A_2="509" if P22_1_A_2=="5.09"
 replace P22_1_A_2="530" if P22_1_A_2=="5.30"

 replace P22_1_A_3="2500" if P22_1_A_3=="2'500"
 replace P22_1_A_3="1300" if P22_1_A_3=="1'300"
 replace P22_1_A_3="3000" if P22_1_A_3=="3'000.00"
 replace P22_1_A_3="500" if P22_1_A_3=="5'000"
 
 replace P22_1_A_4="1500" if P22_1_A_4=="1'500"
 replace P22_1_A_4="4300" if P22_1_A_4=="4'300"
 replace P22_1_A_4="4000" if P22_1_A_4=="4'000"
 replace P22_1_A_4="6000" if P22_1_A_4=="6'000"
 replace P22_1_A_4="100000" if P22_1_A_4=="100'000"
 
 replace P22_1_A_5="1500" if  P22_1_A_5=="1'500"
 replace P22_1_A_5="1500" if  P22_1_A_5=="1'930"
 replace P22_1_A_5="2700" if  P22_1_A_5=="2'700"
 replace P22_1_A_5="4000" if P22_1_A_5=="4'000"
 replace P22_1_A_5="5000" if P22_1_A_5=="5'000"
  
 replace P22_1_A_6="2700" if  P22_1_A_6=="2'700"
 replace P22_1_A_6="2500" if  P22_1_A_6=="2'500"
 replace P22_1_A_6="200000" if  P22_1_A_6=="200'000"
 replace P22_1_A_6="19999" if  P22_1_A_6=="1´9999" //jlft
 
foreach i in 1 2 3 4 5 6 {
	replace P22_1_A_`i'=".a" if  P22_1_A_`i'=="-9"
	replace P22_1_A_`i'=".b" if  P22_1_A_`i'=="-8"
	replace P22_1_A_`i'=".c" if  P22_1_A_`i'=="-7"
	split P22_1_A_`i', parse("," "." ".." " " ";" ":" "Â´") 
	} 

****************************************************
// Establecemos una regla para limpiar los numeros 
 
// Solo hacemos concat cuando el lenght del string es mayor igual a 3.
// No son puntuacion

foreach i in 1 2 3 4 5 6 {
	replace P22_1_A_`i'2="" if (length(P22_1_A_`i'2)==2 & length(P22_1_A_`i'1)>=2)
	replace P22_1_A_`i'2="" if (length(P22_1_A_`i'2)==1 & length(P22_1_A_`i'1)>=2)
	replace P22_1_A_`i'3="" if length(P22_1_A_`i'3)==2 
egen P22_1_A_`i'_new=concat( P22_1_A_`i'1 P22_1_A_`i'2 P22_1_A_`i'3)
destring P22_1_A_`i'_new, replace
	} 

drop P22_1_A_11 P22_1_A_12 P22_1_A_13 P22_1_A_21 P22_1_A_22 P22_1_A_23 ///
P22_1_A_31 P22_1_A_32 P22_1_A_33 P22_1_A_41 P22_1_A_42 P22_1_A_43 P22_1_A_51 ///
 P22_1_A_52 P22_1_A_53 P22_1_A_61 P22_1_A_62 P22_1_A_63 P22_1_A_64

 
******************************************************************************

/// Fixing the continuous variable: pregunta 22 parte 2
/// casos especiales


replace P22_2_A_2="5000" if P22_2_A_2=="5.0.0.0"
replace P22_2_A_2="20000" if P22_2_A_2=="2.00.00.0"

replace P22_2_A_4="100000" if P22_2_A_4=="100'000"
replace P22_1_A_4="4300" if P22_1_A_4=="4'300"
 

foreach i in 1 2 3 4 5 6{
	replace P22_2_A_`i'=".a" if  P22_2_A_`i'=="-9"
	replace P22_2_A_`i'=".b" if  P22_2_A_`i'=="-8"
	replace P22_2_A_`i'=".c" if  P22_2_A_`i'=="-7"
	split P22_2_A_`i', parse("," "." ".." " " "  " ";" ":" "Â´") 
} 
	
foreach i in 1 2 3 4 5 6 {
	replace P22_2_A_`i'2="" if (length(P22_2_A_`i'2)==2 & length(P22_2_A_`i'1)>=2)
	replace P22_2_A_`i'2="" if (length(P22_2_A_`i'2)==1 & length(P22_2_A_`i'1)>=2)
	replace P22_2_A_`i'3="" if length(P22_2_A_`i'3)==2 
	egen P22_2_A_`i'_new=concat( P22_2_A_`i'1 P22_2_A_`i'2 P22_2_A_`i'3)
	destring P22_2_A_`i'_new, replace force
} 
 
 drop P22_2_A_11 P22_2_A_12 P22_2_A_13 P22_2_A_21 P22_2_A_22 P22_2_A_23 ///
 P22_2_A_31 P22_2_A_32 P22_2_A_33 P22_2_A_41 P22_2_A_42 P22_2_A_43 P22_2_A_51 ///
 P22_2_A_52 P22_2_A_53 P22_2_A_61 P22_2_A_62 P22_2_A_63 P22_2_A_64

 /// using the opcion "same as average"

foreach i in 1 2 3 4 5 6{
	replace P22_2_A_`i'_new=P22_1_A_`i'_new if (P22_2_B_`i'==-4 & P22_2_A_`i'_new==-9)
	replace P22_2_A_`i'_new=. if P22_2_A_`i'_new==-9
} 
*/

save "..\..\..\Data\Clean\SAPruralstudentsV1_clean.dta", replace

****************
*** Rural V2 ***
****************

*******************
* Preparing Stata *
*******************

clear all
	set more off

set dp period // Fix period as decimal separation
program drop _all
file close _all
log close _all

cap cd "X:\Dropbox\educ_peru\07_Questionnaires & Data\01_Data\Baseline 2015\Dofiles\Clean\SAP IPA", clear

* Analysis with Urban data
use "..\..\..\Data\Clean\SAPruralstudentsV2_160302.dta", clear

* Based on Note on missing value above I would replace them respectively as -9=.a, ..., or -value with one missing ".".
** Replace "-9" as missing value, coded as .a ("blank"), "-8" as 
	
	ds, has(type numeric)
qui foreach var in `r(varlist)' {
	recode `var' (-9=.a) (-8=.b) (-7=.c) (-6=.d) (-6=.e)
}
	
************************************
* PERSONAL IDENTIFYING INFORMATION *
************************************
* create one name
gen name=A_NOM //we take the preprint name (only pre-print info should be in A_NOM)
	replace name=C_NOM if B_A1==2 | (A_NOM=="" & C_NOM!="") // when preprint info is wrong or when no preprint and there is selfreported info
gen lastname1=A_APEPAT 
	replace lastname1=C_APEPAT if B_A2==2 | (A_APEPAT=="" & C_APEPAT!="")
gen lastname2=A_APEMAT
	replace lastname2=C_APEMAT if B_A3==2 | (A_APEMAT=="" & C_APEMAT!="")
	
gen name_source=1 if name==A_NOM
	replace name_source=2 if B_A1==2
	replace name_source=3 if A_NOM=="" & C_NOM!=""
gen lastname1_source=1 if lastname1==A_APEPAT
	replace lastname1_source=2 if B_A2==2
	replace lastname1_source=3 if A_APEPAT=="" & C_APEPAT!=""
gen lastname2_source=1 if lastname2==A_APEMAT
	replace lastname2_source=2 if B_A3==2
	replace lastname2_source=3 if A_APEMAT=="" & C_APEMAT!=""
	
gen sex=G_SEXO
	replace sex=I_SEXO if H_A1==2
	replace sex=I_SEXO if G_SEXO==. & I_SEXO!=.
label define sex 1 "Hombre" 2 "Mujer"
label values sex sex

gen sex_source=1 if sex==G_SEXO
	replace sex_source=2 if H_A1==2
	replace sex_source=3 if G_SEXO==. & I_SEXO!=.
	
gen dateofbirth=mdy(D_MM,D_DD,D_AA)
	replace dateofbirth=mdy(F_MM,F_DD,F_AA) if E_A1==2
	replace dateofbirth=mdy(F_MM,F_DD,F_AA) if (F_MM!=. & F_DD!=. & F_AA!=.) & (D_MM==. & D_DD==. & D_AA==.)
gen dateofbirth_source=1 if E_A1!=2
	replace dateofbirth_source=2 if E_A1==2 & (F_MM!=. & F_DD!=. & F_AA!=.)
	replace dateofbirth_source=3 if (F_MM!=. & F_DD!=. & F_AA!=.) & (D_MM==. & D_DD==. & D_AA==.)
gen dateofsurvey=mdy(MM1_ENC,DD1_ENC,AA1_ENC)

gen ageatsurvey=round((dateofsurvey-dateofbirth)/365,1)

gen DNI=J_DNI
	replace DNI=L_DNI if K_A1==2 // preprint is incorrect
	replace DNI=L_DNI if L_DNI!=. & J_DNI==. //mostly missing values

gen DNI_source=1
	replace DNI_source=2 if K_A1==2 
	replace DNI_source=3 if DNI==L_DNI & L_DNI!=. & J_DNI==. 
	
label define source 1 "Pre-print" 2 "Pre-print, corrected by student" 3 "No pre-print"
label values *_source source

compress

**********************************************
* OTHER INFORMATION (NON NUMERICAL VARIABLES)*
**********************************************

// Elegimos la primera rpta. JLFT: I'm considering a different rule here: For most answers, I'm taking the max value in the answer, trying to interpret what kids might have meant.
* P2A: Mother Tongue (P2A*)
* Quechua & Aymara are the most popular 2nd answers. We presume kids are embarrassed of confessing them as their mother tongue and so we consider the first non-Spanish mother tongue as the real one.
gen P2A=P2A_1
foreach i in 2 3 4 {
	replace P2A=P2A_`i' if P2A_`i'!=1 & P2A_`i'!=. & P2A_1==1
}
local x: var label P2A_1 
label var P2A "`x'"
label values P2A P2A_1
drop P2A_1 P2A_2 P2A_3 P2A_4  //* work with V2

* P3*-P5*: Educational achievement of household members (mother, father, sibling, and others) // QUESTIONS IN V2 ARE DIFFERENT: it has been changed accordingly

recode P3_1-P3_5 (5=-2) 
egen P3=rowmax(P3_1 P3_2 P3_3 P3_4 P3_5)
recode P3_1-P3_5 (-2=5)
local x: var label P3_1 
label var P3 "`x'" 
drop P3_1 P3_2 P3_3 P3_4 P3_5
label values P3 P3_1

recode P4_1-P4_5 (5=-2) 
egen P4=rowmax(P4_1 P4_2 P4_3 P4_4 P4_5)
recode P4_1-P4_5 (-2=5)
local x: var label P4_1 
label var P4 "`x'" 
drop P4_1 P4_2 P4_3 P4_4 P4_5
label values P4 P4_1

recode P5_1-P5_6 (5=-2) (6=-3)
egen P5=rowmax(P5_1 P5_2 P5_3 P5_4 P5_5 P5_6)
recode P5_1-P5_6 (-2=5) (-3=6)
local x: var label P5_1 
label var P5 "`x'" 
drop P5_1 P5_2 P5_3 P5_4 P5_5 P5_6
label values P5 P5_1

ren (P3 P4 P5) (P3_mother P3_father P3_brother)

* P10: Self-reported effort in school: we take the max value reported, as kids who gave weird answers usually marked all options up to a certain one (as opposed to marking ALL options). 
* Same question but different order in the questionaire (ie V1: P5)
egen P10=rowmax(P10_1 P10_2 P10_3 P10_4 P10_5)
local x: var label P10_1 
label var P10 "`x'" 
drop P10_1 P10_2 P10_3 P10_4 P10_5
label values P10 P10_1

* Self perception are structurally different from V1.
* P11: Self perception of RENDIMIENTO ACADEMICO in Math and Ciencias y Ambiente (in V1 was P6) with the rest of the country
egen P11=rowmax(P11_1 P11_2 P11_3 P11_4 P11_5)
local x: var label P11_1 
label var P11 "`x'" 
drop P11_1 P11_2 P11_3 P11_4 P11_5
label values P11 P11_1

* P12: Self perception of RENDIMIENTO ACADEMICO in Comun y Ciencias Sociales (in V1 was P6) with the rest of the country
egen P12=rowmax(P12_1 P12_2 P12_3 P12_4 P12_5)
local x: var label P12_1 
label var P12 "`x'" 
drop P12_1 P12_2 P12_3 P12_4 P12_5
label values P12 P12_1

* P13: Subject in which they perceive to have the most ability (V1 is P7)
recode P13_1 (6=.f) //Subject is not on list
egen P13=rowmax(P13_1 P13_2 P13_3 P13_4 P13_5 P13_6) //note: highest value in P13_* is now 5, i.e. "All subjects"-
local x: var label P13_1 
label var P13 "`x'" 
drop P13_*
label values P13 P13_1

* P14: Self perception of HABILIDAD in Math and Ciencias (in V1 is P8)
egen P14=rowmax(P14_1 P14_2 P14_3 P14_4 P14_5)
local x: var label P14_1 
label var P14 "`x'" 
drop P14_1 P14_2 P14_3 P14_4 P14_5
label values P14 P14_1

* P15: Prob of increasing the ability in Math and Ciencias y Ambiente (in V1 is P9)

foreach t in 15 {
	egen P`t'=rowmax(P`t'_01-P`t'_11)
	local x: var label P`t'_01 
	label var P`t' "`x'" 
	drop P`t'_*
	label values P`t' P`t'_01
}

* P16: Prob of ability in Comm and Ciencias sociales (in V1 is P9)

egen P16=rowmax(P16_1 P16_2 P16_3 P16_4 P16_5)
local x: var label P16_1 
label var P16 "`x'" 
drop P16_1 P16_2 P16_3 P16_4 P16_5
label values P16 P16_1

* P17: Prob of increasing the ability in Comm and Ciencias Sociales (in V1 is P9)

foreach t in 17 {
	egen P`t'=rowmax(P`t'_01-P`t'_11)
	local x: var label P`t'_01 
	label var P`t' "`x'" 
	drop P`t'_*
	label values P`t' P`t'_01
}

* PLANS
* P18: How much have you thought on the education you would like to achieve? (V1 is P10)
* P19: What level of education you would to achieve? (V1 is P11)

foreach q in P18 P19 {
	egen `q'=rowmax(`q'_1 `q'_2 `q'_3 `q'_4)
	local x: var label `q'_1
	label var `q' "`x'"
	drop `q'_*
	label values `q' `q'_1
}

* P20: if university, which area of study you would like to achieve (V1 is P12)
foreach q in P20 {
	egen `q'=rowmax(`q'_1 `q'_2 `q'_3 `q'_4 `q'_5 `q'_6 `q'_7 `q'_8)
	local x: var label `q'_1
	label var `q' "`x'"
	drop `q'_*
	label values `q' `q'_1
}

* P21: What obstacles you think you would face?: Students were told to report ALL obstacles (not 3 as in V1). 
* To be consistent we will apply the same rule as V1: In case they declared more than 4 obstacles we are considering .c=error (yes/no: yes & no) IS THIS WHAT WE WANT?

egen aux_rownonmissp21=rownonmiss(P21_1-P21_7)
foreach i in 1 2 3 4 5 6 7 {
	replace P21_`i'=.c if aux_rownonmissp21>4
}
drop P21_4-P21_7 // Drop all answers beyond the 3rd.

* P22: How do most peruvians finance their higher ed? In V1 we only asked for 1 answer (V2 does not specify that), so we keep the first. In case they reported more than 2 answers we consider .c=error.
egen aux_rownonmissp22=rownonmiss(P22_1-P22_5)
replace P22_1=.c if aux_rownonmissp22>2
ren P22_1 P22
drop P22_2-P22_5

* P23: Knows about Beca 18 (V1 is P15)
replace P23A=1 if P23B!="" & (P23B!="-9" & P23B!="-8" & P23B!="-7")
gen KnowsBeca18=(strmatch(lower(P23B),"*beca*") | strmatch(lower(P23B),"*veca*")) |  strmatch(lower(P23B),"*18*")

* P24: Do you know which institutions give scholarships? (V1 is 16)
egen aux_rownonmissp24=rownonmiss(P24_1-P24_4)
gen aux_p24nose=4 if (P24_1==4 | P24_2==4 | P24_3==4 | P24_4==4) & aux_rownonmissp24!=4 //they marked they do not know and are not botching the survey
foreach i in 1 2 3 4 {
	replace P24_`i'=.b if aux_rownonmissp24==4 //survey botchers
	replace P24_`i'=.b if aux_p24nose==4 //those who don't know.
}
replace P24_1=1 if aux_p24nose==4 //if they don't know, then that should be their first answer.

* P26-P27: Considering obstacles, Prob of getting scholarship and educ and credit.

foreach t in 26 27  {
	egen P`t'=rowmax(P`t'_01-P`t'_11)
	local x: var label P`t'_01 
	label var P`t' "`x'" 
	drop P`t'_*
	label values P`t' P`t'_01
}
 
* P28-P29: Considering obstacles, Prob of accessing higher ed: technical and university 

foreach t in 28 29  {
	egen P`t'=rowmax(P`t'_01-P`t'_11)
	local x: var label P`t'_01 
	label var P`t' "`x'" 
	drop P`t'_*
	label values P`t' P`t'_01
}

* P30-P31: Conditional on high effort and highest possible ability, Prob of accessing higher ed: technical and university

foreach t in 30 31  {
	egen P`t'=rowmax(P`t'_01-P`t'_11)
	local x: var label P`t'_01 
	label var P`t' "`x'" 
	drop P`t'_*
	label values P`t' P`t'_01
}

* P35: If no obstacle and fee=zero, what level of education would you like to achieve? 
egen P35=rowmax(P35_1 P35_2 P35_3 P35_4)
local x: var label P35_1
label var P35 "`x'"
drop P35_*
label values P35 P35_1

* P37: What's the most important factor behind your major choice? - Max: 2 answers. If more than 3 answers, then .b for all.
egen aux_rownonmissp37=rownonmiss(P37_1-P37_5)
replace P37_1=.b if aux_rownonmissp37>3
replace P37_2=.b if aux_rownonmissp37>3
drop P37_3 P37_4 P37_5

drop aux*
compress

***************************************************************************************************************************************************

**************************************
* OTHER INFORMATION (NUMERICAL DATA) *
**************************************

* : HOURS
****************************

* : W(E), Expecteed incomes at different educational levels
***********************************************************

/// Fixing the continuous variable: pregunta 32 parte 1

 * CASOS ESPECIALES 
 
* P32: deleting commas, DOTS NEED TO BE FIXED!

foreach r in 1 2 3 4 {
    replace P32_A_`r' = subinstr(P32_A_`r', ",", "",.) // this might be useful to avoid changing each value: at least for commas. Dots should be consistent
	// with urban rules.
} 
		
****************************************************
// Establecemos una regla para limpiar los numeros 
 
// Solo hacemos concat cuando el lenght del string es mayor igual a 3.
/* No son puntuacion

foreach i in 1 2 3 4 {
	replace P32_A_`i'2="" if (length(P32_A_`i'2)==2 & length(P32_A_`i'1)>=2)
	replace P32_A_`i'2="" if (length(P32_A_`i'2)==1 & length(P32_A_`i'1)>=2)
	replace P32_A_`i'3="" if length(P32_A_`i'3)==2 
egen P32_A_`i'_new=concat(  P32_A_`i'1 P32_A_`i'2 P32_A_`i'3)
destring P32_A_`i'_new, replace
	} 

drop P21_1_A_11 P21_1_A_12 P21_1_A_13 P21_1_A_21 P21_1_A_22 P21_1_A_23 ///
P21_1_A_31 P21_1_A_32 P21_1_A_33 P21_1_A_41 P21_1_A_42 P21_1_A_43 P21_1_A_44
 
/// Fixing the continuous variable: Commas should be fine, we should apply a role for dots...BELOW IS THE ONE YOU HAVE USED FOR URBAN...

replace P21_2_A_1="40" if P21_2_A_1=="4.0"
replace P21_2_A_1="80" if P21_2_A_1=="8.0"
replace P21_2_A_1="800" if P21_2_A_1=="8.00.00"
replace P21_2_A_1="400" if P21_2_A_1=="4.0.0"
replace P21_2_A_1="4000" if P21_2_A_1=="4.0.00"
replace P21_2_A_3="1000" if P21_2_A_3=="1'000"
replace P21_2_A_3="1800" if P21_2_A_3=="1'800"
replace P21_2_A_3="2550" if P21_2_A_3=="2'550"
replace P21_2_A_4="2460" if P21_2_A_4=="2,4,60 "
replace P21_2_A_4="25000" if P21_2_A_4=="2,5,000" 
replace P21_2_A_3="4300" if P21_2_A_3=="4'300"
replace P21_2_A_4="4300" if P21_2_A_4=="4'300"
replace P21_2_A_4="10000" if P21_2_A_4=="10'000" 
replace P21_2_A_4="1010" if P21_2_A_4=="10..1.0" 
replace P21_2_A_4="2200" if P21_2_A_4=="2'200.0"
replace P21_2_A_4="2070" if P21_2_A_4=="2'070"
replace P21_2_A_4="5000" if P21_2_A_4=="5'000"
replace P21_2_A_4="6500" if P21_2_A_4=="6.5.000"
replace P21_2_A_4="600" if P21_2_A_4=="6.00.00"
replace P21_2_A_4="950" if P21_2_A_4=="9.50.00"

foreach i in 1 2 3 4 {
	*replace P21_2_A_`i'="." if  P21_2_A_`i'=="-9"
	replace P21_2_A_`i'="." if  P21_2_A_`i'=="-8"
	replace P21_2_A_`i'="." if  P21_2_A_`i'=="-7"
	split P21_2_A_`i', parse("," "." " " ";" ":" "Â´") 
	} 
	
foreach i in 1 2 3 4 {
	replace P21_2_A_`i'2="" if (length(P21_2_A_`i'2)==2 & length(P21_2_A_`i'1)>=2)
	replace P21_2_A_`i'2="" if (length(P21_2_A_`i'2)==1 & length(P21_2_A_`i'1)>=2)
	replace P21_2_A_`i'3="" if length(P21_2_A_`i'3)==2 
egen P21_2_A_`i'_new=concat(  P21_2_A_`i'1 P21_2_A_`i'2 P21_2_A_`i'3)
destring P21_2_A_`i'_new, replace
	} 

drop P21_2_A_11 P21_2_A_12 P21_2_A_13 P21_2_A_21 P21_2_A_22 P21_2_A_23 ///
P21_2_A_31 P21_2_A_32 P21_2_A_33 P21_2_A_41 P21_2_A_42 P21_2_A_43 P21_2_A_44
 
/// using the opcion "same as average"

foreach i in 1 2 3 4 {
	replace P21_2_A_`i'_new= P21_1_A_`i'_new if P21_2_B_`i'==-4 & P21_2_A_`i'_new==-9
	replace P21_2_A_`i'_new=. if P21_2_A_`i'_new==-9
} 
*/

* P33: deleting commas, DOTS NEED TO BE FIXED!

foreach r in 1 2 3 4 {
    replace P33_A_`r' = subinstr(P33_A_`r', ",", "",.) // this might be useful to avoid changing each value: at least for commas. Dots should be consistent
	// with urban rules.
}

* P36B: max possible response is 22: approx 96% respond within that limit, 4% are errors: SHOULD WE JUST CUT THAT 4% FROM THE ANALYSIS? 
// that means we are assuming 96% understand the question. Too optimistic?

replace P36B=.c if P36B > 22

* P38: Parents reaction if bad in school subjects

foreach i in 38A 38B { 
	egen P`i'=rowmax(P`i'_1-P`i'_4)
	local x: var label P`i'_1 
	label var P`i' "`x'" 
	drop P`i'_*
	label values P`i' P`i'_1
}

/*******************************************************************************
* CLEANING part 3: W(E) by areas of study

* DROP variables que ya tiene info (son -9 en las rptas)

/// Fixing the continuous variable: pregunta 21 parte 1

 * CASOS ESPECIALES 

 replace P22_1_A_1="1000" if P22_1_A_1=="1'000"
 replace P22_1_A_1="3000" if P22_1_A_1=="3'000"
 replace P22_1_A_1="2500" if P22_1_A_1=="2'500"
 replace P22_1_A_1="850" if P22_1_A_1=="8.50.00"
 replace P22_1_A_1="800" if P22_1_A_1=="8.00.00"
 replace P22_1_A_1="800" if P22_1_A_1=="8,00" 
 
 replace P22_1_A_2="1000" if P22_1_A_2=="1'000"
 replace P22_1_A_2="3000" if P22_1_A_2=="3'000"
 replace P22_1_A_2="4000" if P22_1_A_2=="4'000"
 replace P22_1_A_2="5000" if P22_1_A_2=="5.0.00"
 replace P22_1_A_2="500" if P22_1_A_2=="5.00"
 replace P22_1_A_2="509" if P22_1_A_2=="5.09"
 replace P22_1_A_2="530" if P22_1_A_2=="5.30"

 replace P22_1_A_3="2500" if P22_1_A_3=="2'500"
 replace P22_1_A_3="1300" if P22_1_A_3=="1'300"
 replace P22_1_A_3="3000" if P22_1_A_3=="3'000.00"
 replace P22_1_A_3="500" if P22_1_A_3=="5'000"
 
 replace P22_1_A_4="1500" if P22_1_A_4=="1'500"
 replace P22_1_A_4="4300" if P22_1_A_4=="4'300"
 replace P22_1_A_4="4000" if P22_1_A_4=="4'000"
 replace P22_1_A_4="6000" if P22_1_A_4=="6'000"
 replace P22_1_A_4="100000" if P22_1_A_4=="100'000"
 
 replace P22_1_A_5="1500" if  P22_1_A_5=="1'500"
 replace P22_1_A_5="1500" if  P22_1_A_5=="1'930"
 replace P22_1_A_5="2700" if  P22_1_A_5=="2'700"
 replace P22_1_A_5="4000" if P22_1_A_5=="4'000"
 replace P22_1_A_5="5000" if P22_1_A_5=="5'000"
  
 replace P22_1_A_6="2700" if  P22_1_A_6=="2'700"
 replace P22_1_A_6="2500" if  P22_1_A_6=="2'500"
 replace P22_1_A_6="200000" if  P22_1_A_6=="200'000"
 replace P22_1_A_6="19999" if  P22_1_A_6=="1´9999" //jlft
 
foreach i in 1 2 3 4 5 6 {
	replace P22_1_A_`i'="." if  P22_1_A_`i'=="-9"
	replace P22_1_A_`i'="." if  P22_1_A_`i'=="-8"
	replace P22_1_A_`i'="." if  P22_1_A_`i'=="-7"
	split P22_1_A_`i', parse("," "." ".." " " ";" ":" "Â´") 
	} 

****************************************************
// Establecemos una regla para limpiar los numeros 
 
// Solo hacemos concat cuando el lenght del string es mayor igual a 3.
// No son puntuacion

foreach i in 1 2 3 4 5 6 {
	replace P22_1_A_`i'2="" if (length(P22_1_A_`i'2)==2 & length(P22_1_A_`i'1)>=2)
	replace P22_1_A_`i'2="" if (length(P22_1_A_`i'2)==1 & length(P22_1_A_`i'1)>=2)
	replace P22_1_A_`i'3="" if length(P22_1_A_`i'3)==2 
egen P22_1_A_`i'_new=concat( P22_1_A_`i'1 P22_1_A_`i'2 P22_1_A_`i'3)
destring P22_1_A_`i'_new, replace
	} 

drop P22_1_A_11 P22_1_A_12 P22_1_A_13 P22_1_A_21 P22_1_A_22 P22_1_A_23 ///
P22_1_A_31 P22_1_A_32 P22_1_A_33 P22_1_A_41 P22_1_A_42 P22_1_A_43 P22_1_A_51 ///
 P22_1_A_52 P22_1_A_53 P22_1_A_61 P22_1_A_62 P22_1_A_63 P22_1_A_64

 
******************************************************************************

/// Fixing the continuous variable: pregunta 22 parte 2
/// casos especiales


replace P22_2_A_2="5000" if P22_2_A_2=="5.0.0.0"
replace P22_2_A_2="20000" if P22_2_A_2=="2.00.00.0"

replace P22_2_A_4="100000" if P22_2_A_4=="100'000"
replace P22_1_A_4="4300" if P22_1_A_4=="4'300"
 

foreach i in 1 2 3 4 5 6{
	*replace P22_2_A_`i'="." if  P22_2_A_`i'=="-9"
	replace P22_2_A_`i'="." if  P22_2_A_`i'=="-8"
	replace P22_2_A_`i'="." if  P22_2_A_`i'=="-7"
	split P22_2_A_`i', parse("," "." ".." " " "  " ";" ":" "Â´") 
} 
	
foreach i in 1 2 3 4 5 6 {
	replace P22_2_A_`i'2="" if (length(P22_2_A_`i'2)==2 & length(P22_2_A_`i'1)>=2)
	replace P22_2_A_`i'2="" if (length(P22_2_A_`i'2)==1 & length(P22_2_A_`i'1)>=2)
	replace P22_2_A_`i'3="" if length(P22_2_A_`i'3)==2 
	egen P22_2_A_`i'_new=concat( P22_2_A_`i'1 P22_2_A_`i'2 P22_2_A_`i'3)
	destring P22_2_A_`i'_new, replace force
} 
 
 drop P22_2_A_11 P22_2_A_12 P22_2_A_13 P22_2_A_21 P22_2_A_22 P22_2_A_23 ///
 P22_2_A_31 P22_2_A_32 P22_2_A_33 P22_2_A_41 P22_2_A_42 P22_2_A_43 P22_2_A_51 ///
 P22_2_A_52 P22_2_A_53 P22_2_A_61 P22_2_A_62 P22_2_A_63 P22_2_A_64

 /// using the opcion "same as average"

foreach i in 1 2 3 4 5 6{
	replace P22_2_A_`i'_new=P22_1_A_`i'_new if (P22_2_B_`i'==-4 & P22_2_A_`i'_new==-9)
	replace P22_2_A_`i'_new=. if P22_2_A_`i'_new==-9

	*/
save "..\..\..\Data\Clean\SAPruralstudentsV2_clean.dta", replace

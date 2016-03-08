/* **********************************************************************************************
Program name: 01_MergeSAPStudents_R_toPrePrint
Previous file: N/A
Author: Sergio De Marco
Date created: 3-Mar-2016
Date last modified: 
Project: Returns to postprimary education

Purpose: Marge SAP student rural survey with SIAGIE preprint data

Files used:
                "../data preprint 2015 total_clean.dta"
				"../BD_IPA_Alu_Rur_V1.dta"
				"../BD_IPA_Alu_Rur_V2.dta"
Files created:
                "clean/SAPruralstudentsV1_$date.dta"
                "clean/SAPruralstudentsV2_$date.dta"

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

cap cd "X:\Dropbox\educ_peru\07_Questionnaires & Data\01_Data\Data administrativa\Data\Clean\Preprint baseline 2015" 
*adding a line
*another change.
*****************
* RURAL DATA V1 *
*****************

use "data preprint 2015 total_clean.dta", clear
ren * *_SIAGIE
ren id_alumno ID
merge 1:1 ID using "..\..\..\..\Baseline 2015\Data\Raw\SAP IPA\BD_IPA_Alu_Rur_V1.dta", keep(match using) //merge with pre-print data.
replace FILEST=2 if _merge==2 //all students without pre-print data in our SIAGIE data are supposed to be "No preimpreso" in FILEST. There should not be any obs with FILEST==1 & _merge==2.

* Now, we replace values for pre-print variables if merge with said pre-print data was succesful.

*codlocal: code for each school venue
replace CODLOC=codlocal_SIAGIE 	if _merge==3
replace CODMOD=cod_mod_SIAGIE 	if _merge==3

*cod_mod: code for each school administrative unit
replace NIVESC="PRIMARIA" if nivel_SIAGIE==1 & _merge==3
gen 	NIVEL=1 if NIVESC=="PRIMARIA"

*Grade
label values GRADO
replace GRADO=id_grado_SIAGIE-3 if _merge==3

*Class
replace SECCION=dsc_seccion_SIAGIE if _merge==3

ds, has(type string)
qui foreach var in `r(varlist)' {
	replace `var'=trim(`var')
}

*Names
*for students without preprint info, we move info from "A_" variables to "C_" variables, where they were supposed to fill it out.
replace C_NOM=A_NOM if C_NOM=="" & A_NOM!="" 
replace A_NOM="" if _merge==2 
replace C_APEPAT=A_APEPAT if C_APEPAT=="" & A_APEPAT!=""
replace A_APEPAT="" if _merge==2 
replace C_APEMAT=A_APEMAT if C_APEMAT=="" & A_APEMAT!=""
replace A_APEMAT="" if _merge==2

*for students with pre-print info
replace A_NOM=nombres_SIAGIE if _merge==3 
replace A_APEPAT=apellido_paterno_SIAGIE if _merge==3
replace A_APEMAT=apellido_materno_SIAGIE if _merge==3 
foreach var of varlist A_NOM C_NOM A_APEPAT C_APEPAT A_APEMAT C_APEMAT { 
	replace `var'=trim(`var')
}
*Date of Birth
replace D_DD=real(substr(fecha_nacimiento_SIAGIE,9,2)) if _merge==3 //update blanks with SIAGIE data
replace D_MM=real(substr(fecha_nacimiento_SIAGIE,6,2)) if _merge==3
replace D_AA=real(substr(fecha_nacimiento_SIAGIE,1,4)) if _merge==3
replace F_DD=D_DD if _merge==2 & F_DD==. //move data from D_ variables to F_ variables if no preprint
replace F_MM=D_MM if _merge==2 & F_MM==.
replace F_AA=D_AA if _merge==2 & F_AA==.
replace D_DD=. if _merge==2 //clear variables which were meant to have only preprint data for those with no preprint
replace D_MM=. if _merge==2
replace D_AA=. if _merge==2

*Sex
replace G_SEXO=1 if genero_SIAGIE==1 & _merge==3
replace G_SEXO=2 if genero_SIAGIE==2 & _merge==3
replace I_SEXO=G_SEXO if _merge==2 & I_SEXO==. //move data from D_ variables to F_ variables if no preprint
replace G_SEXO=. if _merge==2 //clear variables which were meant to have only preprint data for those with no preprint

*DNI (national official ID)
label values J_DNI
replace J_DNI=dni_SIAGIE if _merge==3
replace L_DNI=J_DNI if _merge==2 & L_DNI==.
replace J_DNI=. if _merge==2

ren _merge _mergePrePrint
order ID, last
drop codlocal_SIAGIE-id_grados_SIAGIE
qui compress
save "../../../../Baseline 2015/Data/Clean/SAPruralstudentsV1_$date.dta", replace

*****************
* RURAL DATA V2 *
*****************

clear all
cap cd "X:\Dropbox\educ_peru\07_Questionnaires & Data\01_Data\Data administrativa\Data\Clean\Preprint baseline 2015" 

use "data preprint 2015 total_clean.dta", clear
ren * *_SIAGIE
ren id_alumno ID
merge 1:1 ID using "..\..\..\..\Baseline 2015\Data\Raw\SAP IPA\BD_IPA_Alu_Rur_V2.dta", keep(match using) //merge with pre-print data.
replace FILEST=2 if _merge==2 //all students without pre-print data in our SIAGIE data are supposed to be "No preimpreso" in FILEST. There should not be any obs with FILEST==1 & _merge==2.

* Now, we replace values for pre-print variables if merge with said pre-print data was succesful.

*codlocal: code for each school venue
replace CODLOC=codlocal_SIAGIE 	if _merge==3
replace CODMOD=cod_mod_SIAGIE 	if _merge==3

*cod_mod: code for each school administrative unit
replace NIVESC="PRIMARIA" if nivel_SIAGIE==1 & _merge==3
gen 	NIVEL=1 if NIVESC=="PRIMARIA"

*Grade
label values GRADO
replace GRADO=id_grado_SIAGIE-3 if _merge==3

*Class
replace SECCION=dsc_seccion_SIAGIE if _merge==3

ds, has(type string)
qui foreach var in `r(varlist)' {
	replace `var'=trim(`var')
}

*Names
*for students without preprint info, we move info from "A_" variables to "C_" variables, where they were supposed to fill it out.
replace C_NOM=A_NOM if C_NOM=="" & A_NOM!="" 
replace A_NOM="" if _merge==2 
replace C_APEPAT=A_APEPAT if C_APEPAT=="" & A_APEPAT!=""
replace A_APEPAT="" if _merge==2 
replace C_APEMAT=A_APEMAT if C_APEMAT=="" & A_APEMAT!=""
replace A_APEMAT="" if _merge==2

*for students with pre-print info
replace A_NOM=nombres_SIAGIE if _merge==3 
replace A_APEPAT=apellido_paterno_SIAGIE if _merge==3
replace A_APEMAT=apellido_materno_SIAGIE if _merge==3 
foreach var of varlist A_NOM C_NOM A_APEPAT C_APEPAT A_APEMAT C_APEMAT { 
	replace `var'=trim(`var')
}
*Date of Birth
replace D_DD=real(substr(fecha_nacimiento_SIAGIE,9,2)) if _merge==3 //update blanks with SIAGIE data
replace D_MM=real(substr(fecha_nacimiento_SIAGIE,6,2)) if _merge==3
replace D_AA=real(substr(fecha_nacimiento_SIAGIE,1,4)) if _merge==3
replace F_DD=D_DD if _merge==2 & F_DD==. //move data from D_ variables to F_ variables if no preprint
replace F_MM=D_MM if _merge==2 & F_MM==.
replace F_AA=D_AA if _merge==2 & F_AA==.
replace D_DD=. if _merge==2 //clear variables which were meant to have only preprint data for those with no preprint
replace D_MM=. if _merge==2
replace D_AA=. if _merge==2

*Sex
replace G_SEXO=1 if genero_SIAGIE==1 & _merge==3
replace G_SEXO=2 if genero_SIAGIE==2 & _merge==3
replace I_SEXO=G_SEXO if _merge==2 & I_SEXO==. //move data from D_ variables to F_ variables if no preprint
replace G_SEXO=. if _merge==2 //clear variables which were meant to have only preprint data for those with no preprint

*DNI (national official ID)
label values J_DNI
replace J_DNI=dni_SIAGIE if _merge==3
replace L_DNI=J_DNI if _merge==2 & L_DNI==.
replace J_DNI=. if _merge==2

ren _merge _mergePrePrint
order ID, last
drop codlocal_SIAGIE-id_grados_SIAGIE
qui compress
save "../../../../Baseline 2015/Data/Clean/SAPruralstudentsV2_$date.dta", replace

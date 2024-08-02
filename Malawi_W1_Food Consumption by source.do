/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Malawi Integrated Household Survey (IHS) (2010-11)

*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Malawi Integrated Household Survey was collected by the National Statistical Office (NSO) 
*and the World Bank's Living Standards Measurement Study - Integrated Surveys on Agriculture(LSMS - ISA)
*The data was collected over the period March 2010 - March 2011.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://microdata.worldbank.org/index.php/catalog/1003


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Malawi IHS dataset.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, rural location indicator, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Malawi_IHS_W1_hhids.dta
*Food Consumption by source			Malawi_IHS_W1_food_consumption_value_by_source.dta

*/

    
	
clear
clear mata
clear matrix
program drop _all
set more off
set maxvar 10000

*Set location of raw data and output
global directory			"\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\335 - Ag Team Data Support\Waves"

//set directories
*Malawi IHS Wave 1
global Malawi_IHS_W1_raw_data 		"$directory/Malawi IHS/malawi-wave1-2010-11/raw_data/Household"
global Malawi_IHS_W1_created_data  "//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"



********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN USD
********************************************************************************
global Malawi_IHS_W1_exchange_rate 156.5158	// https://www.bloomberg.com/quote/USDETB:CUR
global Malawi_IHS_W1_gdp_ppp_dollar 251.0742		// https://data.worldbank.org/indicator/PA.NUS.PPP
global Malawi_IHS_W1_cons_ppp_dollar 241.9305		// https://data.worldbank.org/indicator/PA.NUS.PRVT.P
global Malawi_IHS_W1_inflation 2.161431				// inflation rate 2011-2017. Data was collected during 2010-2011. 

********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Malawi_IHS_W1_pop_tot 15146094
global Malawi_IHS_W1_pop_rur 12772398
global Malawi_IHS_W1_pop_urb 2373696


************************
*HOUSEHOLD IDS
************************
use "${Malawi_IHS_W1_raw_data}\hh_mod_b.dta", clear
ren hh_b05a age
ren hh_b03 gender
gen fhh=(hh_b04==1 & gender==2)  
lab var fhh "1= Female-headed household"
gen hh_members = 1 
lab var hh_members "Number of household members"
gen adulteq=.
replace adulteq=0.4 if (age<3 & age>=0)				
replace adulteq=0.48 if (age<5 & age>2)
replace adulteq=0.56 if (age<7 & age>4)
replace adulteq=0.64 if (age<9 & age>6)
replace adulteq=0.76 if (age<11 & age>8)
replace adulteq=0.80 if (age<=12 & age>10) & gender==1		
replace adulteq=0.88 if (age<=12 & age>10) & gender==2      
replace adulteq=1 if (age<15 & age>12)
replace adulteq=1.2 if (age<19 & age>14) & gender==1
replace adulteq=1 if (age<19 & age>14) & gender==2
replace adulteq=1 if (age<60 & age>18) & gender==1
replace adulteq=0.88 if (age<60 & age>18) & gender==2
replace adulteq=0.8 if (age>59 & age!=.) & gender==1
replace adulteq=0.72 if (age>59 & age!=.) & gender==2
lab var adulteq "Adult-Equivalent"
collapse (sum) hh_members adulteq (max) fhh, by (case_id)

merge 1:1 case_id using "${Malawi_IHS_W1_raw_data}\hh_mod_a_filt.dta", nogen keep (1 3)
rename hh_a01 district
rename hh_a02 ta 
rename ea_id ea
rename hh_wgt weight
rename case_id hhid
gen rural = (reside==2)
lab var rural "1=Household lives in a rural area"
codebook district, tab(100)
gen region=.
replace region=1 if inrange(district, 101,107)
replace region=2 if inrange(district,201,210)
replace region=3 if inrange(district,301,315)
lab var region "1=North, 2=Central, 3=South"

gen stratum=.
replace stratum=1 if region== 1 | rural==0
replace stratum=2 if region== 1 | rural==1
replace stratum=3 if region== 2 | rural==0
replace stratum=4 if region== 2 | rural==1
replace stratum=5 if region== 3 | rural==0
replace stratum=6 if region== 3 | rural==1
keep hhid stratum district ta ea rural region weight fhh hh_members adulteq

*Generating the variable that indicate the level of representativness of the survey (to use for reporting summary stats)
gen level_representativness=.
replace level_representativness=11 if region==1 & rural==1
replace level_representativness=12 if region==1 & rural==0
replace level_representativness=21 if region==2 & rural==1
replace level_representativness=22 if region==2 & rural==0
replace level_representativness=31 if region==3 & rural==1
replace level_representativness=32 if region==3 & rural==0

lab define lrep 11 "North  - Rural"  ///
                12 "North  - Urban"  ///
                21 "Central - Rural"   ///
                22 "Central - Urban"  ///
                31 "South - Rural"  ///
                32 "South - Urban"  ///
						
lab value level_representativness	lrep							

****Currency Conversion Factors****
gen ccf_loc = (1 + $Malawi_IHS_W1_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $MWK"
*gen ccf_usd = (1 + $Malawi_IHS_W1_inflation)/$Malawi_IHS_W1_exchange_rate 
*lab var ccf_usd "currency conversion factor - 2017 $USD"
gen ccf_1ppp = (1 + $Malawi_IHS_W1_inflation)/ $Malawi_IHS_W1_cons_ppp_dollar
lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Malawi_IHS_W1_inflation)/ $Malawi_IHS_W1_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"

save "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_hhids.dta", replace

 
********************************************************************************
*CONSUMPTION
******************************************************************************** 
use "${Malawi_IHS_W1_raw_data}/hh_mod_g1.dta", clear
rename case_id hhid
rename ea_id ea
merge m:1 hhid using "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_hhids.dta", nogen keep (1 3)
label list HH_G02
ren hh_g02 item_code
gen crop_category1=""					
replace crop_category1=	"Other Cereals"		if  item_code==	100
replace crop_category1=	"Maize"		if  item_code==	101
replace crop_category1=	"Maize"		if  item_code==	102
replace crop_category1=	"Maize"		if  item_code==	103
replace crop_category1=	"Maize"		if  item_code==	104
replace crop_category1=	"Maize"		if  item_code==	105
replace crop_category1=	"Maize"		if  item_code==	106
replace crop_category1=	"Millet and Sorghum"		if  item_code==	107
replace crop_category1=	"Millet and Sorghum"		if  item_code==	108
replace crop_category1=	"Millet and Sorghum"		if  item_code==	109
replace crop_category1=	"Wheat"		if  item_code==	110
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	111
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	112
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	113
replace crop_category1=	"Wheat"		if  item_code==	114
replace crop_category1=	"Other Cereals"		if  item_code==	115
replace crop_category1=	"Other Cereals"		if  item_code==	116
replace crop_category1=	"Other Food"		if  item_code==	117
replace crop_category1=	"Bananas and Plantains"		if  item_code==	200
replace crop_category1=	"Cassava"		if  item_code==	201
replace crop_category1=	"Cassava"		if  item_code==	202
replace crop_category1=	"Sweet Potato"		if  item_code==	203
replace crop_category1=	"Sweet Potato"		if  item_code==	204
replace crop_category1=	"Potato"		if  item_code==	205
replace crop_category1=	"Potato"		if  item_code==	206
replace crop_category1=	"Bananas and Plantains"		if  item_code==	207
replace crop_category1=	"Yams"		if  item_code==	208
replace crop_category1=	"Other Food"		if  item_code==	209
replace crop_category1=	"Pulses"		if  item_code==	300
replace crop_category1=	"Pulses"		if  item_code==	301
replace crop_category1=	"Pulses"		if  item_code==	302
replace crop_category1=	"Pulses"		if  item_code==	303
replace crop_category1=	"Nuts and Seeds"		if  item_code==	304
replace crop_category1=	"Nuts and Seeds"		if  item_code==	305
replace crop_category1=	"Pulses"		if  item_code==	306
replace crop_category1=	"Pulses"		if  item_code==	307
replace crop_category1=	"Pulses"		if  item_code==	308
replace crop_category1=	"Nuts and Seeds"		if  item_code==	309
replace crop_category1=	"Other Food"		if  item_code==	310
replace crop_category1=	"Vegetables"		if  item_code==	400
replace crop_category1=	"Vegetables"		if  item_code==	401
replace crop_category1=	"Vegetables"		if  item_code==	402
replace crop_category1=	"Vegetables"		if  item_code==	403
replace crop_category1=	"Vegetables"		if  item_code==	404
replace crop_category1=	"Vegetables"		if  item_code==	405
replace crop_category1=	"Vegetables"		if  item_code==	406
replace crop_category1=	"Vegetables"		if  item_code==	407
replace crop_category1=	"Vegetables"		if  item_code==	408
replace crop_category1=	"Vegetables"		if  item_code==	409
replace crop_category1=	"Vegetables"		if  item_code==	410
replace crop_category1=	"Vegetables"		if  item_code==	411
replace crop_category1=	"Vegetables"		if  item_code==	412
replace crop_category1=	"Vegetables"		if  item_code==	413
replace crop_category1=	"Vegetables"		if  item_code==	414
replace crop_category1=	"Other Meat"		if  item_code==	500
replace crop_category1=	"Eggs"		if  item_code==	501
replace crop_category1=	"Fish and Seafood"		if  item_code==	502
replace crop_category1=	"Fish and Seafood"		if  item_code==	503
replace crop_category1=	"Beef Meat"		if  item_code==	504
replace crop_category1=	"Lamb and Goat Meat"		if  item_code==	505
replace crop_category1=	"Pork Meat"		if  item_code==	506
replace crop_category1=	"Lamb and Goat Meat"		if  item_code==	507
replace crop_category1=	"Poultry Meat"		if  item_code==	508
replace crop_category1=	"Poultry Meat"		if  item_code==	509
replace crop_category1=	"Other Meat"		if  item_code==	510
replace crop_category1=	"Other Meat"		if  item_code==	511
replace crop_category1=	"Other Meat"		if  item_code==	512
replace crop_category1=	"Fish and Seafood"		if  item_code==	513
replace crop_category1=	"Fish and Seafood"		if  item_code==	514
replace crop_category1=	"Other Food"		if  item_code==	515
replace crop_category1=	"Fruits"		if  item_code==	600
replace crop_category1=	"Fruits"		if  item_code==	601
replace crop_category1=	"Fruits"		if  item_code==	602
replace crop_category1=	"Fruits"		if  item_code==	603
replace crop_category1=	"Fruits"		if  item_code==	604
replace crop_category1=	"Fruits"		if  item_code==	605
replace crop_category1=	"Fruits"		if  item_code==	606
replace crop_category1=	"Fruits"		if  item_code==	607
replace crop_category1=	"Fruits"		if  item_code==	608
replace crop_category1=	"Fruits"		if  item_code==	609
replace crop_category1=	"Fruits"		if  item_code==	610
replace crop_category1=	"Dairy"		if  item_code==	700
replace crop_category1=	"Dairy"		if  item_code==	701
replace crop_category1=	"Dairy"		if  item_code==	702
replace crop_category1=	"Oils, Fats"		if  item_code==	703
replace crop_category1=	"Oils, Fats"		if  item_code==	704
replace crop_category1=	"Dairy"		if  item_code==	705
replace crop_category1=	"Dairy"		if  item_code==	706
replace crop_category1=	"Dairy"		if  item_code==	707
replace crop_category1=	"Dairy"		if  item_code==	708
replace crop_category1=	"Dairy"		if  item_code==	709
replace crop_category1=	"Oils, Fats"		if  item_code==	800
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	801
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	802
replace crop_category1=	"Oils, Fats"		if  item_code==	803
replace crop_category1=	"Vegetables"		if  item_code==	804
replace crop_category1=	"Spices"		if  item_code==	809
replace crop_category1=	"Spices"		if  item_code==	810
replace crop_category1=	"Spices"		if  item_code==	811
replace crop_category1=	"Spices"		if  item_code==	812
replace crop_category1=	"Spices"		if  item_code==	813
replace crop_category1=	"Spices"		if  item_code==	814
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	815
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	816
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	817
replace crop_category1=	"Spices"		if  item_code==	818
replace crop_category1=	"Other Food"		if  item_code==	819
replace crop_category1=	"Maize"		if  item_code==	820
replace crop_category1=	"Potato"		if  item_code==	821
replace crop_category1=	"Cassava"		if  item_code==	822
replace crop_category1=	"Eggs"		if  item_code==	823
replace crop_category1=	"Poultry Meat"		if  item_code==	824
replace crop_category1=	"Other Meat"		if  item_code==	825
replace crop_category1=	"Fish and Seafood"		if  item_code==	826
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	827
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	828
replace crop_category1=	"Other Food"		if  item_code==	829
replace crop_category1=	"Other Food"		if  item_code==	830
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	900
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	901
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	902
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	903
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	904
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	905
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	906
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	907
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	908
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	909
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	910
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	911
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	912
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	913
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	914
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	915
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	916


* Getting the list of all non-standard units used
foreach t in hh_g03b hh_g04b  hh_g06b hh_g07b {
	preserve
	gen temp=1
	collapse (mean) temp, by(`t')
	ren `t' unit
	tempfile `t'
	save ``t''
	restore
}

preserve
use `hh_g03b', clear
append using `hh_g04b'
append using `hh_g06b'
append using `hh_g07b'
collapse (mean) temp, by(unit)
restore

* Getting the list of all non-standard units used in the other options
foreach t in hh_g03b_os hh_g04b_os  hh_g06b_os hh_g07b_os {
	preserve
	gen temp=1
	collapse (mean) temp, by(`t')
	ren `t' unit_other
	tempfile `t'
	save ``t''
	restore
}

preserve
use `hh_g03b_os', clear
append using `hh_g04b_os'
append using `hh_g06b_os'
append using `hh_g07b_os'
collapse (mean) temp, by(unit_other)
restore


ren hh_g01 food_consu_yesno
ren hh_g03b food_consu_unit
ren hh_g03a food_consu_qty
ren hh_g04b food_purch_unit
ren hh_g04a food_purch_qty
ren hh_g05 food_purch_value
ren hh_g06a food_prod_qty
ren hh_g06b food_prod_unit
ren hh_g07a food_gift_qty
ren hh_g07b food_gift_unit
ren hh_g03b_os food_consu_unit_others
ren hh_g04b_os food_purch_unit_others
ren hh_g06b_os food_prod_unit_others
ren hh_g07b_os food_gift_unit_others


foreach t in consu purch prod gift {
	gen food_`t'_unit_new="."
	replace food_`t'_unit_new=	"."	if food_`t'_unit==	"0"
	replace food_`t'_unit_new=	"Kg"	if food_`t'_unit==	"1"
	replace food_`t'_unit_new=	"Heap"	if food_`t'_unit==	"10"
	replace food_`t'_unit_new=	"Heap"	if food_`t'_unit==	"101"
	replace food_`t'_unit_new=	"Heap"	if food_`t'_unit==	"109"
	replace food_`t'_unit_new=	"Heap small"	if food_`t'_unit==	"10A"
	replace food_`t'_unit_new=	"Heap medium"	if food_`t'_unit==	"10B"
	replace food_`t'_unit_new=	"Heap large"	if food_`t'_unit==	"10C"
	replace food_`t'_unit_new=	"Heap small"	if food_`t'_unit==	"10D"
	replace food_`t'_unit_new=	"Heap medium"	if food_`t'_unit==	"10E"
	replace food_`t'_unit_new=	"Heap large"	if food_`t'_unit==	"10F"
	replace food_`t'_unit_new=	"Bale"	if food_`t'_unit==	"11"
	replace food_`t'_unit_new=	"Basket shelled"	if food_`t'_unit==	"12"
	replace food_`t'_unit_new=	"Basket shelled flat"	if food_`t'_unit==	"12A"
	replace food_`t'_unit_new=	"Basket shelled heaped"	if food_`t'_unit==	"12B"
	replace food_`t'_unit_new=	"Basket unshelled"	if food_`t'_unit==	"13"
	replace food_`t'_unit_new=	"Ox-cart unshelled"	if food_`t'_unit==	"14"
	replace food_`t'_unit_new=	"Litre"	if food_`t'_unit==	"15"
	replace food_`t'_unit_new=	"Cup"	if food_`t'_unit==	"16"
	replace food_`t'_unit_new=	"Cup"	if food_`t'_unit==	"16A"
	replace food_`t'_unit_new=	"Cup"	if food_`t'_unit==	"16B"
	replace food_`t'_unit_new=	"Tin"	if food_`t'_unit==	"17"
	replace food_`t'_unit_new=	"Gram"	if food_`t'_unit==	"18"
	replace food_`t'_unit_new=	"Gram"	if food_`t'_unit==	"18B"
	replace food_`t'_unit_new=	"Gram"	if food_`t'_unit==	"18C"
	replace food_`t'_unit_new=	"Mililitre"	if food_`t'_unit==	"19"
	replace food_`t'_unit_new=	"Kg"	if food_`t'_unit==	"1A"
	replace food_`t'_unit_new=	"Kg"	if food_`t'_unit==	"1B"
	replace food_`t'_unit_new=	"Kg"	if food_`t'_unit==	"1C"
	replace food_`t'_unit_new=	"50 kg bag"	if food_`t'_unit==	"2"
	replace food_`t'_unit_new=	"Teaspoon"	if food_`t'_unit==	"20"
	replace food_`t'_unit_new=	"Teaspoon"	if food_`t'_unit==	"20A"
	replace food_`t'_unit_new=	"Teaspoon"	if food_`t'_unit==	"20B"
	replace food_`t'_unit_new=	"Basin  "	if food_`t'_unit==	"21"
	replace food_`t'_unit_new=	"Basin  "	if food_`t'_unit==	"21B"
	replace food_`t'_unit_new=	"Satchet/tube"	if food_`t'_unit==	"22"
	replace food_`t'_unit_new=	"Satchet/tube small"	if food_`t'_unit==	"22A"
	replace food_`t'_unit_new=	"Satchet/tube medium"	if food_`t'_unit==	"22B"
	replace food_`t'_unit_new=	"Satchet/tube large"	if food_`t'_unit==	"22C"
	replace food_`t'_unit_new=	"Satchet/tube"	if food_`t'_unit==	"22D"
	replace food_`t'_unit_new=	"Other"	if food_`t'_unit==	"23"
	replace food_`t'_unit_new=	"50 kg bag"	if food_`t'_unit==	"25"
	replace food_`t'_unit_new=	"50 kg bag"	if food_`t'_unit==	"2A"
	replace food_`t'_unit_new=	"50 kg bag"	if food_`t'_unit==	"2B"
	replace food_`t'_unit_new=	"50 kg bag"	if food_`t'_unit==	"2C"
	replace food_`t'_unit_new=	"90 kg bag"	if food_`t'_unit==	"3"
	replace food_`t'_unit_new=	"90 kg bag"	if food_`t'_unit==	"3A"
	replace food_`t'_unit_new=	"Pail small"	if food_`t'_unit==	"4"
	replace food_`t'_unit_new=	"Pail small"	if food_`t'_unit==	"41"
	replace food_`t'_unit_new=	"Pail small"	if food_`t'_unit==	"42"
	replace food_`t'_unit_new=	"Pail small"	if food_`t'_unit==	"49"
	replace food_`t'_unit_new=	"Pail small"	if food_`t'_unit==	"4A"
	replace food_`t'_unit_new=	"Pail small"	if food_`t'_unit==	"4B"
	replace food_`t'_unit_new=	"Pail small"	if food_`t'_unit==	"4C"
	replace food_`t'_unit_new=	"Pail small"	if food_`t'_unit==	"4D"
	replace food_`t'_unit_new=	"Pail small"	if food_`t'_unit==	"4E"
	replace food_`t'_unit_new=	"Pail large"	if food_`t'_unit==	"5"
	replace food_`t'_unit_new=	"Pail large"	if food_`t'_unit==	"500"
	replace food_`t'_unit_new=	"Pail large"	if food_`t'_unit==	"5A"
	replace food_`t'_unit_new=	"Pail large"	if food_`t'_unit==	"5B"
	replace food_`t'_unit_new=	"Pail large"	if food_`t'_unit==	"5C"
	replace food_`t'_unit_new=	"Pail large"	if food_`t'_unit==	"5D"
	replace food_`t'_unit_new=	"No. 10 Plate"	if food_`t'_unit==	"6"
	replace food_`t'_unit_new=	"No. 10 Plate"	if food_`t'_unit==	"69"
	replace food_`t'_unit_new=	"No. 10 Plate"	if food_`t'_unit==	"6A"
	replace food_`t'_unit_new=	"No. 10 Plate"	if food_`t'_unit==	"6B"
	replace food_`t'_unit_new=	"No. 10 Plate"	if food_`t'_unit==	"6C"
	replace food_`t'_unit_new=	"No. 10 Plate"	if food_`t'_unit==	"6D"
	replace food_`t'_unit_new=	"No. 12 Plate"	if food_`t'_unit==	"7"
	replace food_`t'_unit_new=	"No. 12 Plate"	if food_`t'_unit==	"79"
	replace food_`t'_unit_new=	"No. 12 Plate"	if food_`t'_unit==	"7A"
	replace food_`t'_unit_new=	"No. 12 Plate"	if food_`t'_unit==	"7B"
	replace food_`t'_unit_new=	"No. 12 Plate"	if food_`t'_unit==	"7C"
	replace food_`t'_unit_new=	"Bunch"	if food_`t'_unit==	"8"
	replace food_`t'_unit_new=	"Bunch"	if food_`t'_unit==	"80"
	replace food_`t'_unit_new=	"Bunch small"	if food_`t'_unit==	"8A"
	replace food_`t'_unit_new=	"Bunch medium"	if food_`t'_unit==	"8B"
	replace food_`t'_unit_new=	"Bunch large"	if food_`t'_unit==	"8C"
	replace food_`t'_unit_new=	"Bunch medium"	if food_`t'_unit==	"8E"
	replace food_`t'_unit_new=	"Bunch large"	if food_`t'_unit==	"8F"
	replace food_`t'_unit_new=	"Piece"	if food_`t'_unit==	"9"
	replace food_`t'_unit_new=	"Piece"	if food_`t'_unit==	"99"
	replace food_`t'_unit_new=	"Piece small"	if food_`t'_unit==	"9A"
	replace food_`t'_unit_new=	"Piece medium"	if food_`t'_unit==	"9B"
	replace food_`t'_unit_new=	"Piece large"	if food_`t'_unit==	"9C"
	replace food_`t'_unit_new=	"Piece medium"	if food_`t'_unit==	"9E"
	replace food_`t'_unit_new=	"Piece large"	if food_`t'_unit==	"9F"

	replace food_`t'_unit_new=	"15 Litre"	if food_`t'_unit_others==	"1 5 LITER CONTAINER"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Basket shelled"	if food_`t'_unit_others==	"1 BASKET"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"1 LAREGE PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"1 LOAF3.00"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"1 NSIMA PLATE (PHAZI)"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"1 PLATE CHINGOWE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"1 PLATE MAIZE NOT GRAIN"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"1 PLATE MZAMA"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"1 PLATE NDIWO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"1 PLATE NDIWO SIZE1"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"1 PLATE OF NDIWO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"1 PLATE OF NSIMA"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"1 PLATE OF NSIMA WITH BEEF"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"1 PLATE SMALL NDIWO SIZE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"1 RICE MEAL"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Basin"	if food_`t'_unit_others==	"1 SMALL BASIN"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Pot"	if food_`t'_unit_others==	"1 SMALL POT"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"10"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"10 UNITS"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"100 Mililitre"	if food_`t'_unit_others==	"100ML"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"115(2 PACKETS)"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"15 Litre"	if food_`t'_unit_others==	"15 LITRE PALE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Kg"	if food_`t'_unit_others==	"1KG PACKET"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"2 LOAFS"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"2"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"20G PACKETS"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"23 DOZEN"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"24 DAYS"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"3 CUPS OF TEA"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"3 LOAFS"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"300 Mililitre"	if food_`t'_unit_others==	"300 ML BOTTLES"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"4 BOTTLES"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"4 BOTTLES OF COCO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"4 MEALS AT 150"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Packet"	if food_`t'_unit_others==	"40 PACKET"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"5 Litre"	if food_`t'_unit_others==	"5 LITRE AS A CONTAINER FOR CHISOSO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"5 Litre"	if food_`t'_unit_others==	"5 LITRE CONTAINER"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"BAR"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Basin"	if food_`t'_unit_others==	"BASIN"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"BIG LICHERO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Bottle"	if food_`t'_unit_others==	"BOTTLES"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Bowl"	if food_`t'_unit_others==	"BOWL"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"5 Litre "	if food_`t'_unit_others==	"BUCKET 5 LITRE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"5 Litre"	if food_`t'_unit_others==	"BUCKET 5LITRE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Bottle"	if food_`t'_unit_others==	"CARLSEBERG BEER"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"CHICKEMEAT0"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Chicken"	if food_`t'_unit_others==	"CHICKEN"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"CHOCOLATE BAR"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"COOKED MANGOES"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"CRETE1"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"CUP OF TEA & TWO SCONES"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"DISH OF NSIMA AND BEEF"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Dove"	if food_`t'_unit_others==	"DOVE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"DOZEN"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Heap"	if food_`t'_unit_others==	"FRESH BEANS (HEAPS)"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"FULL CHICKEN +  KHUNDA"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"HALF CHICKEN"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"HALF LICHERO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"HEAD"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"JIGGIES"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Jumbo"	if food_`t'_unit_others==	"JUMBO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"KAMPAO BIG"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"KHOFI PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"LAOVES OF BREAD"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"LICHERO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"LICHERO SMALL"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"LIPOKO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Litre"	if food_`t'_unit_others==	"LITRE CONTAINER"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"MAIZE PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"MBALE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"MEALS"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"MEALS EATEN AT RESTAURANT"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"MEDIUM PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Mililitre"	if food_`t'_unit_others==	"MILLIGRAM"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"MITANDA"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"MLAMBA"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"MTSUKO SMALL"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"MUSHROOM PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"NDOWA"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"NDOWA PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"NKOKO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"No. 10 Plate"	if food_`t'_unit_others==	"NO. 10 PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"NSIMA AND BEEF"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"NSIMA AND MEAT"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"NSIMA AND NDIWO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"NSIMA PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"NSIMA WITH CHICKEN"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Cup"	if food_`t'_unit_others==	"ONE CUP"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Piece"	if food_`t'_unit_others==	"ONE PIECE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Rabbit"	if food_`t'_unit_others==	"ONE WHOLE KALULU (RABBIT)"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Packet"	if food_`t'_unit_others==	"PACKET"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"PHAZI PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"PIECES OF CHICKEN"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"PLASTIC"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"PLATE CHICKEN AND CHIPS"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"PLATE OF FRIED MAIZE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"POTO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"RAIDER"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"RELISH PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"RICE PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Satchet/tube"	if food_`t'_unit_others==	"SACHET"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Basin"	if food_`t'_unit_others==	"SMALL BASIN"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"SMALL CHIPS"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Jumbo"	if food_`t'_unit_others==	"SMALL JUMBO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"SMALL LICHERO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Plate"	if food_`t'_unit_others==	"SMALL NDIWO PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Packet"	if food_`t'_unit_others==	"SMALL PACKET"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Piece"	if food_`t'_unit_others==	"SMALL PIECES"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Jumbo"	if food_`t'_unit_others==	"SMALL PLASTIC JUMBO"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"SMALL PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"SOYA PIECES"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"SPOON"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Tablespoon"	if food_`t'_unit_others==	"TABLESPOON"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"TEA & BUNS"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"TEA AND BREAD"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Teabag"	if food_`t'_unit_others==	"TEABAGS"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Teaspoon"	if food_`t'_unit_others==	"TEASPOON"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"THUNGWA"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Tin"	if food_`t'_unit_others==	"TINA PLATE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"TRAY"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Satchet/tube"	if food_`t'_unit_others==	"TUBE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"TUSSELS(NGALA)"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"TWO PLATES OF NSIMA AND BEEF"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Satchet/tube"	if food_`t'_unit_others==	"TWO TUBES"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"UNIT"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"WHOLE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"WHOLE CABBAGE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Chicken"	if food_`t'_unit_others==	"WHOLE CHICKEN"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"WHOLE DOVE"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Dove"	if food_`t'_unit_others==	"WHOLE DOVES"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Duck"	if food_`t'_unit_others==	"WHOLE DUCK"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"WHOLE LOAF OF BREAD"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	"Rabbit"	if food_`t'_unit_others==	"WHOLE RABBIT"	& food_`t'_unit_new=="Other"
	replace food_`t'_unit_new=	""	if food_`t'_unit_others==	"WINNOWING BASKET"	& food_`t'_unit_new=="Other"
	
	replace food_`t'_qty=food_`t'_qty*50 if food_`t'_unit_new=="50 kg bag"    //50kg bag to kg
	replace food_`t'_unit_new="Kg" if food_`t'_unit_new=="50 kg bag"
	replace food_`t'_qty=food_`t'_qty*90 if food_`t'_unit_new=="90 kg bag"    //90kg bag to kg
	replace food_`t'_unit_new="Kg" if food_`t'_unit_new=="90 kg bag"
	
	replace food_`t'_qty=food_`t'_qty/1000 if food_`t'_unit_new=="Gram"       //Grams to kg
	replace food_`t'_unit_new="Kg" if food_`t'_unit_new=="Gram"
	
	replace food_`t'_qty=food_`t'_qty*300 if food_`t'_unit_new=="300 Mililitre"  //300 Mililitre to Mililitre
	replace food_`t'_unit_new="Mililitre" if food_`t'_unit_new=="300 Mililitre"
	
	replace food_`t'_qty=food_`t'_qty/10 if food_`t'_unit_new=="100 Mililitre"  //100 Mililitre to Litre
	replace food_`t'_unit_new="Litre" if food_`t'_unit_new=="100 Mililitre"
	
	replace food_`t'_qty=food_`t'_qty/1000 if food_`t'_unit_new=="Mililitre"  //Mililitre to Litre
	replace food_`t'_unit_new="Litre" if food_`t'_unit_new=="Mililitre"
	
	replace food_`t'_qty=food_`t'_qty*20 if food_`t'_unit_new=="20 Litre"  //20 Litre to Litre
	replace food_`t'_unit_new="Litre" if food_`t'_unit_new=="20 Litre"

	replace food_`t'_qty=food_`t'_qty*2 if food_`t'_unit_new=="2 Litre"  //2 Litre to Litre
	replace food_`t'_unit_new="Litre" if food_`t'_unit_new=="2 Litre"
	
	replace food_`t'_qty=food_`t'_qty*15 if food_`t'_unit_new=="15 Litre"  //15 Litre to Litre
	replace food_`t'_unit_new="Litre" if food_`t'_unit_new=="15 Litre"

	replace food_`t'_qty=food_`t'_qty*5 if food_`t'_unit_new=="5 Litre"  //5 Litre to Litre
	replace food_`t'_unit_new="Litre" if food_`t'_unit_new=="5 Litre"
}

keep if food_consu_yesno==1
drop if food_consu_qty==0  | food_consu_qty==.
*Impute the value of consumption using prices infered from the quantity of purchase and the value of pruchases.
gen price_unit= food_purch_value/food_purch_qty
recode price_unit (0=.)
save "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_consumption_purchase.dta", replace
 
 

use "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region district ta ea rural item_code food_purch_unit_new: egen obs_ea = count(observation)
collapse (median) price_unit [aw=weight], by (region district ta ea item_code food_purch_unit_new obs_ea)
ren price_unit price_unit_median_ea
lab var price_unit_median_ea "Median price per kg for this crop in the enumeration area"
lab var obs_ea "Number of observations for this crop in the enumeration area"
save "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_item_prices_ea.dta", replace


use "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region district ta item_code food_purch_unit_new: egen obs_ta = count(observation)
collapse (median) price_unit [aw=weight], by (region district ta item_code food_purch_unit_new obs_ta)
ren price_unit price_unit_median_ta
lab var price_unit_median_ta "Median price per kg for this crop in the Traditional authority area"
lab var obs_ta "Number of observations for this crop in the enumeration area"
save "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_item_prices_ta.dta", replace


use "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region district item_code food_purch_unit_new: egen obs_district = count(observation)
collapse (median) price_unit [aw=weight], by (region district item_code food_purch_unit_new obs_district)
ren price_unit price_unit_median_district
lab var price_unit_median_district "Median price per kg for this crop in the district"
lab var obs_district "Number of observations for this crop in the enumeration area"
save "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_item_prices_district.dta", replace


use "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region item_code food_purch_unit_new: egen obs_region = count(observation)
collapse (median) price_unit [aw=weight], by (region item_code food_purch_unit_new obs_region)
ren price_unit price_unit_median_region
lab var price_unit_median_region "Median price per kg for this crop in the region"
lab var obs_region "Number of observations for this crop in the enumeration area"
save "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_item_prices_region.dta", replace


use "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys item_code food_purch_unit_new: egen obs_country = count(observation)
collapse (median) price_unit [aw=weight], by (item_code food_purch_unit_new obs_country)
ren price_unit price_unit_median_country
lab var price_unit_median_country "Median price per kg for this crop in the country"
lab var obs_country "Number of observations for this crop in the country"
save "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_item_prices_country.dta", replace


*Pull prices into consumption estimates
use "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_consumption_purchase.dta", clear
merge m:1 hhid using "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_hhids.dta", nogen keep(1 3)
gen food_purch_unit_old=food_purch_unit_new

* Value Food consumption, production, and gift when the units does not match the units of purchased
foreach f in consu prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit_new==food_purch_unit_new


*- using EA medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 region district ta ea item_code food_purch_unit_new using "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_item_prices_ea.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_ea if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_ea>10 & obs_ea!=.

*- using TA medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 region district ta item_code food_purch_unit_new using "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_item_prices_ta.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_ta if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_ta>10 & obs_ta!=.

*- using district medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 region district item_code food_purch_unit_new using "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_item_prices_district.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_district if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_district>10 & obs_district!=.

*- using region medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 region item_code food_purch_unit_new using "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_item_prices_region.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_region if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_region>10 & obs_region!=.

*- using country medians
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 item_code food_purch_unit_new using "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_item_prices_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid item_code crop_category1 food_`f'_value
save "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_consumption_purchase_`f'.dta", replace
restore
}

merge 1:1  hhid item_code crop_category1  using "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_consumption_purchase_consu.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_consumption_purchase_prod.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_consumption_purchase_gift.dta", nogen

collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid crop_category1)
recode  food_consu_value food_purch_value food_prod_value food_gift_value (.=0)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_food_home_consumption_value.dta", replace


*Food away from home
use "${Malawi_IHS_W1_raw_data}/hh_mod_i1.dta", clear
egen food_purch_value=rowtotal(hh_i03)
gen  food_consu_value=food_purch_value
rename case_id hhid
rename ea_id ea
collapse (sum) food_consu_value food_purch_value, by(hhid)
gen crop_category1="Meals away from home"
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
save "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_food_away_consumption_value.dta", replace

use "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_food_home_consumption_value.dta", clear
append using "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_food_away_consumption_value.dta"
merge m:1 hhid using "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_hhids.dta", nogen keep(1 3)

*convert to annual value by multiplying with 52
replace food_consu_value=food_consu_value*52
replace food_purch_value=food_purch_value*52 
replace food_prod_value=food_prod_value*52 
replace food_gift_value=food_gift_value*52 

label var food_consu_value "Annual value of food consumed, nominal"
label var food_purch_value "Annual value of food purchased, nominal"
label var food_prod_value "Annual value of food produced, nominal"
label var food_gift_value "Annual value of food received, nominal"
lab var fhh "1= Female-headed household"
lab var hh_members "Number of household members"
lab var adulteq "Adult-Equivalent"
lab var crop_category1 "Food items"
lab var hhid "Household ID"

save "${Malawi_IHS_W1_created_data}/Malawi_IHS_W1_food_consumption_value.dta", replace


*RESCALING the components of consumption such that the sum always match
** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value {
	_pctile `v' [aw=weight] if `v'!=0 , p($wins_upper_thres) 
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
}

ren district adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province"
ren ta adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"
gen adm3=.
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="Malawi"
lab var Countr "Country name"
qui gen Instrument="Malawi LSMS-ISA/IHS W1"
lab var Instrument "Survey name"
qui gen Year="2010/11"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

*generate GID_1 code to match codes in the Malawi shapefile
gen GID_1=""
replace GID_1="MWI.1_1"  if adm1==312
replace GID_1="MWI.2_1"  if adm1==305
replace GID_1="MWI.3_1"  if adm1==310
replace GID_1="MWI.4_1"  if adm1==304
replace GID_1="MWI.5_1"  if adm1==101
replace GID_1="MWI.6_1"  if adm1==208
replace GID_1="MWI.7_1"  if adm1==204
replace GID_1="MWI.8_1"  if adm1==102
replace GID_1="MWI.9_1"  if adm1==201
*replace GID_1="MWI.10_1"  if adm1== //The IHS doesn't specify an option for Likoma
replace GID_1="MWI.11_1"  if adm1==206
replace GID_1="MWI.12_1"  if adm1==302
replace GID_1="MWI.13_1"  if adm1==301
replace GID_1="MWI.14_1"  if adm1==207
replace GID_1="MWI.15_1"  if adm1==308
replace GID_1="MWI.16_1"  if adm1==306
replace GID_1="MWI.17_1"  if adm1==105
replace GID_1="MWI.18_1"  if adm1==313
replace GID_1="MWI.19_1"  if adm1==103
replace GID_1="MWI.20_1"  if adm1==202
replace GID_1="MWI.21_1"  if adm1==311
replace GID_1="MWI.22_1"  if adm1==209
replace GID_1="MWI.23_1"  if adm1==203
replace GID_1="MWI.24_1"  if adm1==309
replace GID_1="MWI.25_1"  if adm1==104
replace GID_1="MWI.26_1"  if adm1==205
replace GID_1="MWI.27_1"  if adm1==307
replace GID_1="MWI.28_1"  if adm1==303
lab var GID_1 "Adm1 code from the GADM shapefile"

*Additional aggregation of commodities
gen  crop_category2=""		
replace  crop_category2=	"Cereals"	if crop_category1==	" Rice"	
replace  crop_category2=	"Cereals"	if crop_category1==	"Rice"
replace  crop_category2=	"Roots and Tubers"	if crop_category1==	"Bananas and Plantains"
replace  crop_category2=	"Livestock Products"	if crop_category1==	"Beef Meat"
replace  crop_category2=	"Roots and Tubers"	if crop_category1==	"Cassava"
replace  crop_category2=	"Dairy"	if crop_category1==	"Dairy"
replace  crop_category2=	"Dairy"	if crop_category1==	"Eggs"
replace  crop_category2=	"Fish and Seafood"	if crop_category1==	"Fish and Seafood"
replace  crop_category2=	"Fruits and Vegetables"	if crop_category1==	"Fruits"
replace  crop_category2=	"Pulses, Legumes and Nuts"	if crop_category1==	"Groundnuts"
replace  crop_category2=	"Livestock Products"	if crop_category1==	"Lamb and Goat Meat"
replace  crop_category2=	"Cereals"	if crop_category1==	"Maize"
replace  crop_category2=	"Meals away from home"	if crop_category1==	"Meals away from home"
replace  crop_category2=	"Cereals"	if crop_category1==	"Millet and Sorghum"
replace  crop_category2=	"Non-Dairy Beverages"	if crop_category1==	"Non-Dairy Beverages"
replace  crop_category2=	"Pulses, Legumes and Nuts"	if crop_category1==	"Nuts and Seeds"
replace  crop_category2=	"Oils, Fats"	if crop_category1==	"Oils, Fats"
replace  crop_category2=	"Cereals"	if crop_category1==	"Other Cereals"
replace  crop_category2=	"Other Food"	if crop_category1==	"Other Food"
replace  crop_category2=	"Livestock Products"	if crop_category1==	"Other Meat"
replace  crop_category2=	"Roots and Tubers"	if crop_category1==	"Other Roots and Tubers"
replace  crop_category2=	"Livestock Products"	if crop_category1==	"Pork Meat"
replace  crop_category2=	"Roots and Tubers"	if crop_category1==	"Potato"
replace  crop_category2=	"Livestock Products"	if crop_category1==	"Poultry Meat"
replace  crop_category2=	"Pulses, Legumes and Nuts"	if crop_category1==	"Pulses"
replace  crop_category2=	"Cereals"	if crop_category1==	"Rice"
replace  crop_category2=	"Fruits and Vegetables"	if crop_category1==	"Spices"
replace  crop_category2=	"Processed Food"	if crop_category1==	"Sugar, Sweets, Pastries"
replace  crop_category2=	"Roots and Tubers"	if crop_category1==	"Sweet Potato"
replace  crop_category2=	"Cereals"	if crop_category1==	"Teff"
replace  crop_category2=	"Tobacco"	if crop_category1==	"Tobacco"
replace  crop_category2=	"Fruits and Vegetables"	if crop_category1==	"Vegetables"
replace  crop_category2=	"Cereals"	if crop_category1==	"Wheat"
replace  crop_category2=	"Roots and Tubers"	if crop_category1==	"Yams"
ta crop_category2 
lab var crop_category2 "Aggregated Food items"

*Convert nominal consumption value to 2017 PPP
gen conv_lcu_ppp=.
lab var conv_lcu_ppp "Conversion Factor"		
replace conv_lcu_ppp=	0.014063629	if Instrument==	"Malawi LSMS-ISA/IHS W1"

foreach x of varlist food_consu_value food_purch_value food_prod_value food_gift_value w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value   {
	gen `x'_ppp=`x'*conv_lcu_ppp
	local l`x': var lab `x' 
	clonevar `x'_lcu=`x'
	local temp1 = subinstr("`l`x''", "nominal", "2017 PPP", 1)
	lab var `x'_ppp "`temp1'"
	
	local temp2 = subinstr("`l`x''", "nominal", "nominal LCU", 1)
	lab var `x'_lcu "`temp2'"
	
	drop `x'
}


compress
save "${final_data}/Malawi_IHS_W1_food_consumption_value_by_source.dta", replace


*****End of Do File*****
  	



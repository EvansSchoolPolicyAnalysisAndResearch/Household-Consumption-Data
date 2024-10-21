/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Nigeria General Household Survey (GHS) LSMS-ISA Wave 1 (2010-11)

*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Nigeria General Household Survey was collected by the Nigerian National Bureau of Statistics (NBS) 
*and the World Bank's Living Standards Measurement Study - Integrated Surveys on Agriculture(LSMS - ISA)
*The data were collected over the period August - October 2010, February - April 2011.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://microdata.worldbank.org/index.php/catalog/1002


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Nigeria GHS dataset.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, rural location indicator, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Nigeria_GHS_W1_hhids.dta
*Food Consumption by source			Nigeria_GHS_W1_food_consumption_value_by_source.dta

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
*Nigeria General HH survey (NG LSMS)  Wave 1
global Nigeria_GHS_W1_raw_data 		"$directory/Nigeria GHS/Nigeria GHS Wave 1/Raw DTA Files/NGA_2010_GHSP-W1_v03_M_STATA"
global Nigeria_GHS_W1_created_data  "//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"

********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN USD
********************************************************************************
global Nigeria_GHS_W1_exchange_rate 153.8625  		// https://data.worldbank.org/indicator/PA.NUS.FCRF?locations=NG
global Nigeria_GHS_W1_gdp_ppp_dollar 93.915			// https://data.worldbank.org/indicator/PA.NUS.PRVT.P
global Nigeria_GHS_W1_cons_ppp_dollar 115.9778			// https://data.worldbank.org/indicator/PA.NUS.PRVT.P
global Nigeria_GHS_W1_inflation 0.932805				// inflation rate 2011-2017. Data was collected during 2010-2011. We want to adjust value to 2017


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Nigeria_GHS_W1_pop_tot 165463745
global Nigeria_GHS_W1_pop_rur 92054100
global Nigeria_GHS_W1_pop_urb 73409645


********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables

 
********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${Nigeria_GHS_W1_raw_data}/sect1_plantingw1.dta", clear
ren s1q4 age
ren s1q2 gender
gen fhh = (s1q3==1 & gender==2)
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
replace adulteq=. if age==999
lab var adulteq "Adult-Equivalent"
collapse (sum) hh_members adulteq (max) fhh, by (hhid)

merge 1:1 hhid using "${Nigeria_GHS_W1_raw_data}/secta_plantingw1.dta", nogen keep (1 3)
gen rural = (sector==2)
lab var rural "1= Rural"
keep hhid zone state lga ea fhh hh_members adulteq rural wt_wave1
ren wt_wave1 weight

*Generating the variable that indicate the level of representativness of the survey (to use for reporting summary stats)
gen level_representativness=.
replace level_representativness=11 if zone==1 & rural==1
replace level_representativness=12 if zone==1 & rural==0
replace level_representativness=21 if zone==2 & rural==1
replace level_representativness=22 if zone==2 & rural==0
replace level_representativness=31 if zone==3 & rural==1
replace level_representativness=32 if zone==3 & rural==0
replace level_representativness=41 if zone==4 & rural==1
replace level_representativness=42 if zone==4 & rural==0
replace level_representativness=51 if zone==5 & rural==1
replace level_representativness=52 if zone==5 & rural==0
replace level_representativness=61 if zone==6 & rural==1
replace level_representativness=62 if zone==6 & rural==0

lab define lrep 11 "North central - Rural"  ///
                12 "North central - Urban"  ///
                21 "North east - Rural"   ///
                22 "North east - Urban"  ///
                31 "North west - Rural"  ///
                32 "North west - Urban"  ///
				41 "South east - Rural"  ///
                42 "South east - Urban"  ///
                51 "South south - Rural" ///
                52 "South south - Urban" ///
                61 "South west - Rural"  ///
                62 "South west - Urban"    
						
lab value level_representativness	lrep	
tab level_representativness

****Currency Conversion Factors****
gen ccf_loc = (1 + $Nigeria_GHS_W1_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $SHL"
gen ccf_usd = (1 + $Nigeria_GHS_W1_inflation)/$Nigeria_GHS_W1_exchange_rate 
lab var ccf_usd "currency conversion factor - 2017 $USD"
gen ccf_1ppp = (1 + $Nigeria_GHS_W1_inflation)/ $Nigeria_GHS_W1_cons_ppp_dollar
lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Nigeria_GHS_W1_inflation)/ $Nigeria_GHS_W1_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"
						
save  "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hhids.dta", replace


 
********************************************************************************
*CONSUMPTION
******************************************************************************** 
*PLANTING
use "${Nigeria_GHS_W1_raw_data}/sect7b_plantingw1.dta", clear
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hhids.dta", nogen keep (1 3)
label list item_cd
ren item_cd item_code
gen crop_category1=""					
replace crop_category1=	"Millet and Sorghum"			if  item_code==	10
replace crop_category1=	"Millet and Sorghum"			if  item_code==	11
replace crop_category1=	"Maize"			if  item_code==	12
replace crop_category1=	"Rice"			if  item_code==	13
replace crop_category1=	"Rice"			if  item_code==	14
replace crop_category1=	"Wheat"			if  item_code==	15
replace crop_category1=	"Maize"			if  item_code==	16
replace crop_category1=	"Yams"			if  item_code==	17
replace crop_category1=	"Cassava"			if  item_code==	18
replace crop_category1=	"Wheat"			if  item_code==	19
replace crop_category1=	"Other Cereals"			if  item_code==	20
replace crop_category1=	"Cassava"			if  item_code==	30
replace crop_category1=	"Yams"			if  item_code==	31
replace crop_category1=	"Cassava"			if  item_code==	32
replace crop_category1=	"Cassava"			if  item_code==	33
replace crop_category1=	"Yams"			if  item_code==	34
replace crop_category1=	"Bananas and Plantains"			if  item_code==	35
replace crop_category1=	"Sweet Potato"			if  item_code==	36
replace crop_category1=	"Potato"			if  item_code==	37
replace crop_category1=	"Other Roots and Tubers"			if  item_code==	38
replace crop_category1=	"Pulses"			if  item_code==	40
replace crop_category1=	"Pulses"			if  item_code==	41
replace crop_category1=	"Pulses"			if  item_code==	42
replace crop_category1=	"Groundnuts"			if  item_code==	43
replace crop_category1=	"Nuts and Seeds"			if  item_code==	44
replace crop_category1=	"Oils, Fats"			if  item_code==	50
replace crop_category1=	"Oils, Fats"			if  item_code==	51
replace crop_category1=	"Oils, Fats"			if  item_code==	52
replace crop_category1=	"Oils, Fats"			if  item_code==	53
replace crop_category1=	"Bananas and Plantains"			if  item_code==	60
replace crop_category1=	"Fruits"			if  item_code==	61
replace crop_category1=	"Fruits"			if  item_code==	62
replace crop_category1=	"Fruits"			if  item_code==	63
replace crop_category1=	"Fruits"			if  item_code==	64
replace crop_category1=	"Fruits"			if  item_code==	65
replace crop_category1=	"Fruits"			if  item_code==	66
replace crop_category1=	"Vegetables"			if  item_code==	70
replace crop_category1=	"Vegetables"			if  item_code==	71
replace crop_category1=	"Vegetables"			if  item_code==	72
replace crop_category1=	"Vegetables"			if  item_code==	73
replace crop_category1=	"Vegetables"			if  item_code==	74
replace crop_category1=	"Vegetables"			if  item_code==	75
replace crop_category1=	"Vegetables"			if  item_code==	76
replace crop_category1=	"Vegetables"			if  item_code==	77
replace crop_category1=	"Vegetables"			if  item_code==	78
replace crop_category1=	"Poultry Meat"			if  item_code==	80
replace crop_category1=	"Poultry Meat"			if  item_code==	81
replace crop_category1=	"Poultry Meat"			if  item_code==	82
replace crop_category1=	"Eggs"			if  item_code==	83
replace crop_category1=	"Eggs"			if  item_code==	84
replace crop_category1=	"Eggs"			if  item_code==	85
replace crop_category1=	"Beef Meat"			if  item_code==	90
replace crop_category1=	"Lamb and Goat Meat"			if  item_code==	91
replace crop_category1=	"Pork Meat"			if  item_code==	92
replace crop_category1=	"Lamb and Goat Meat"			if  item_code==	93
replace crop_category1=	"Other Meat"			if  item_code==	94
replace crop_category1=	"Other Meat"			if  item_code==	95
replace crop_category1=	"Other Meat"			if  item_code==	96
replace crop_category1=	"Fish and Seafood"			if  item_code==	100
replace crop_category1=	"Fish and Seafood"			if  item_code==	101
replace crop_category1=	"Fish and Seafood"			if  item_code==	102
replace crop_category1=	"Fish and Seafood"			if  item_code==	103
replace crop_category1=	"Fish and Seafood"			if  item_code==	104
replace crop_category1=	"Fish and Seafood"			if  item_code==	105
replace crop_category1=	"Fish and Seafood"			if  item_code==	106
replace crop_category1=	"Fish and Seafood"			if  item_code==	107
replace crop_category1=	"Dairy"			if  item_code==	110
replace crop_category1=	"Dairy"			if  item_code==	111
replace crop_category1=	"Dairy"			if  item_code==	112
replace crop_category1=	"Dairy"			if  item_code==	113
replace crop_category1=	"Dairy"			if  item_code==	114
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	120
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	121
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	122
replace crop_category1=	"Sugar, Sweets, Pastries"			if  item_code==	130
replace crop_category1=	"Sugar, Sweets, Pastries"			if  item_code==	131
replace crop_category1=	"Sugar, Sweets, Pastries"			if  item_code==	132
replace crop_category1=	"Sugar, Sweets, Pastries"			if  item_code==	133
replace crop_category1=	"Spices"			if  item_code==	140
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	150
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	151
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	152
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	153
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	154
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	155
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	160
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	161
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	162
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	163
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	164



ren s7bq1 food_consu_yesno
ren s7bq2b food_consu_unit
ren s7bq2a food_consu_qty
ren s7bq3b food_purch_unit
ren s7bq3a food_purch_qty
ren s7bq4 food_purch_value
ren s7bq5a food_prod_qty
ren s7bq5b food_prod_unit
ren s7bq6a food_gift_qty
ren s7bq6b food_gift_unit
ren s7bq2c food_consu_unit_others
ren s7bq3c food_purch_unit_others
ren s7bq5c food_prod_unit_others
ren s7bq6c food_gift_unit_others

foreach unit in food_consu food_purch food_prod food_gift {
gen `unit'_unit_new="Kg" if `unit'_unit==1
replace `unit'_unit_new="Liter" if `unit'_unit==3
replace `unit'_unit_new="Piece" if `unit'_unit==5
replace `unit'_unit_new="Piece" if `unit'_unit==5
replace `unit'_unit_new=	"Kg"	if `unit'_unit_others==	"1"
replace `unit'_unit_new=	"Kg"	if `unit'_unit_others==	"10"
replace `unit'_unit_new=	"Bag"	if `unit'_unit_others==	"BAG"
replace `unit'_unit_new=	"Bag"	if `unit'_unit_others==	"BAG/SACK"
replace `unit'_unit_new=	"Ball"	if `unit'_unit_others==	"BALL"
replace `unit'_unit_new=	"Other"	if `unit'_unit_others==	"BASIC"
replace `unit'_unit_new=	"Basin"	if `unit'_unit_others==	"BASIN"
replace `unit'_unit_new=	"Basket"	if `unit'_unit_others==	"BASKET"
replace `unit'_unit_new=	"Bottle"	if `unit'_unit_others==	"BEER"
replace `unit'_unit_new=	"Bottle"	if `unit'_unit_others==	"BEER BOTTLE"
replace `unit'_unit_new=	"Mudu"	if `unit'_unit_others==	"BIG MUDU"
replace `unit'_unit_new=	"Tin"	if `unit'_unit_others==	"BONVITA"
replace `unit'_unit_new=	"Tin"	if `unit'_unit_others==	"BONVITA TIN"
replace `unit'_unit_new=	"Bottle"	if `unit'_unit_others==	"BOTTLE"
replace `unit'_unit_new=	"Bottle"	if `unit'_unit_others==	"BOTTLE 35CL"
replace `unit'_unit_new=	"Bottle"	if `unit'_unit_others==	"BOTTLE 75CL"
replace `unit'_unit_new=	"Bow"	if `unit'_unit_others==	"BOWL"
replace `unit'_unit_new=	"Bow"	if `unit'_unit_others==	"BOWL/BUCKET"
replace `unit'_unit_new=	"Other"	if `unit'_unit_others==	"BULBS"
replace `unit'_unit_new=	"Bunch"	if `unit'_unit_others==	"BUNCH"
replace `unit'_unit_new=	"Bundle"	if `unit'_unit_others==	"BUNDLE"
replace `unit'_unit_new=	"Can"	if `unit'_unit_others==	"CAN"
replace `unit'_unit_new=	"Liter"	if `unit'_unit_others==	"CL"
replace `unit'_unit_new=	"Bottle"	if `unit'_unit_others==	"COKE BOTTLE"
replace `unit'_unit_new=	"Other"	if `unit'_unit_others==	"CRATE"
replace `unit'_unit_new=	"Cube"	if `unit'_unit_others==	"CUBE"
replace `unit'_unit_new=	"Cube"	if `unit'_unit_others==	"CUBS"
replace `unit'_unit_new=	"Cup"	if `unit'_unit_others==	"CUP"
replace `unit'_unit_new=	"Other"	if `unit'_unit_others==	"GROUP"
replace `unit'_unit_new=	"Heap"	if `unit'_unit_others==	"HEAP"
replace `unit'_unit_new=	"Kongo"	if `unit'_unit_others==	"KONGO"
replace `unit'_unit_new=	"Loaf"	if `unit'_unit_others==	"LEAF"
replace `unit'_unit_new=	"Loaf"	if `unit'_unit_others==	"LIVE"
replace `unit'_unit_new=	"Loaf"	if `unit'_unit_others==	"LOAF"
replace `unit'_unit_new=	"Bottle"	if `unit'_unit_others==	"LOCOZADE BOTTLE"
replace `unit'_unit_new=	"Bottle"	if `unit'_unit_others==	"LUCOZADE"
replace `unit'_unit_new=	"Bottle"	if `unit'_unit_others==	"LUCOZADE BOTTLE"
replace `unit'_unit_new=	"Cup"	if `unit'_unit_others==	"MILK CUP"
replace `unit'_unit_new=	"Tin"	if `unit'_unit_others==	"MILK TIN"
replace `unit'_unit_new=	"Mudu"	if `unit'_unit_others==	"MUDU"
replace `unit'_unit_new=	"Pack"	if `unit'_unit_others==	"PACK"
replace `unit'_unit_new=	"Pack"	if `unit'_unit_others==	"PACKAGE"
replace `unit'_unit_new=	"Pack"	if `unit'_unit_others==	"PACKET"
replace `unit'_unit_new=	"Paint"	if `unit'_unit_others==	"PAINT"
replace `unit'_unit_new=	"Paint"	if `unit'_unit_others==	"PAINT RUBBER"
replace `unit'_unit_new=	"Pickup"	if `unit'_unit_others==	"PICK-UP"
replace `unit'_unit_new=	"Piece"	if `unit'_unit_others==	"PIECE"
replace `unit'_unit_new=	"Plate"	if `unit'_unit_others==	"PLATE"
replace `unit'_unit_new=	"Pack"	if `unit'_unit_others==	"POCKET"
replace `unit'_unit_new=	"Portion"	if `unit'_unit_others==	"PORTION"
replace `unit'_unit_new=	"Other"	if `unit'_unit_others==	"RAP"
replace `unit'_unit_new=	"Paint"	if `unit'_unit_others==	"RUBBER"
replace `unit'_unit_new=	"Paint"	if `unit'_unit_others==	"RUBBER PAINT"
replace `unit'_unit_new=	"Bag"	if `unit'_unit_others==	"SACKS"
replace `unit'_unit_new=	"Satchet"	if `unit'_unit_others==	"SATCHET"
replace `unit'_unit_new=	"Other"	if `unit'_unit_others==	"SHOT"
replace `unit'_unit_new=	"Other"	if `unit'_unit_others==	"SHUT"
replace `unit'_unit_new=	"Basin"	if `unit'_unit_others==	"SMALL BASIN"
replace `unit'_unit_new=	"Basket"	if `unit'_unit_others==	"SMALL BASKET"
replace `unit'_unit_new=	"Other"	if `unit'_unit_others==	"SPOON"
replace `unit'_unit_new=	"Other"	if `unit'_unit_others==	"TIED"
replace `unit'_unit_new=	"Tin"	if `unit'_unit_others==	"TIN"
replace `unit'_unit_new=	"Tin"	if `unit'_unit_others==	"TIN MILK"
replace `unit'_unit_new=	"Tuber"	if `unit'_unit_others==	"TUBER"
replace `unit'_unit_new=	"Wrap"	if `unit'_unit_others==	"WRAP"
replace `unit'_unit_new=	"Other"	if `unit'_unit_others==	"charging"
replace `unit'_unit_new=	"Other" if `unit'_unit_new=="" & `unit'_unit==6
}

replace food_consu_qty=food_consu_qty/1000 if food_consu_unit==2
replace food_purch_qty=food_purch_qty/1000 if food_purch_unit==2 // AYW 4.15.20
replace food_prod_qty=food_prod_qty/1000 if food_prod_unit==2
replace food_gift_qty=food_gift_qty/1000 if food_gift_unit==2

replace food_purch_qty=food_purch_qty/100 if food_purch_unit==4 
replace food_consu_qty=food_consu_qty/100 if food_consu_unit==4
replace food_prod_qty=food_prod_qty/100 if food_prod_unit==4
replace food_gift_qty=food_gift_qty/100 if food_gift_unit==4

replace food_consu_qty=food_consu_qty/100 if food_consu_unit_others=="CL"
replace food_purch_qty=food_purch_qty/100 if food_purch_unit_others=="CL"
replace food_prod_qty=food_prod_qty/100 if food_prod_unit_others=="CL"
replace food_gift_qty=food_gift_qty/100 if food_gift_unit_others=="CL"

*Dealing the other unit categories
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (2 =1 ) (4=3)  // gramns in kg and mili in liter  // AYW 4.15.20 moved this here.

keep if food_consu_yesno==1
drop if food_consu_qty==0  | food_consu_qty==.
*Input the value of consumption using prices infered from the quantity of purchase and the value of pruchases.
gen price_unit= food_purch_value/food_purch_qty
recode price_unit (0=.)
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PP.dta", replace
 
 
use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PP.dta", clear
drop if price_unit==.
gen observation = 1
bys zone state lga ea item_code food_purch_unit_new: egen obs_ea = count(observation)
collapse (median) price_unit [aw=weight], by (zone state lga ea item_code food_purch_unit_new obs_ea)
ren price_unit price_unit_median_ea
lab var price_unit_median_ea "Median price per kg for this crop in the enumeration area"
lab var obs_ea "Number of observations for this crop in the enumeration area"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_ea_PP.dta", replace

use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PP.dta", clear
drop if price_unit==.
gen observation = 1
bys zone state lga item_code food_purch_unit_new: egen obs_lga = count(observation)
collapse (median) price_unit [aw=weight], by (zone state lga item_code food_purch_unit_new obs_lga)
ren price_unit price_unit_median_lga
lab var price_unit_median_lga "Median price per kg for this crop in the lga"
lab var obs_lga "Number of observations for this crop in the lga"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_lga_PP.dta", replace

use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PP.dta", clear
drop if price_unit==.
gen observation = 1
bys zone state item_code food_purch_unit_new: egen obs_state = count(observation) 
collapse (median) price_unit [aw=weight], by (zone state item_code food_purch_unit_new obs_state)
ren price_unit price_unit_median_state
lab var price_unit_median_state "Median price per kg for this crop in the state"
lab var obs_state "Number of observations for this crop in the state"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_state_PP.dta", replace

use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PP.dta", clear
drop if price_unit==.
gen observation = 1
bys zone item_code food_purch_unit_new: egen obs_zone = count(observation)
collapse (median) price_unit [aw=weight], by (zone item_code food_purch_unit_new obs_zone)
ren price_unit price_unit_median_zone
lab var price_unit_median_zone "Median price per kg for this crop in the zone"
lab var obs_zone "Number of observations for this crop in the zone"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_zone_PP.dta", replace

use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PP.dta", clear
drop if price_unit==.
gen observation = 1
bys item_code food_purch_unit_new: egen obs_country = count(observation)
collapse (median) price_unit [aw=weight], by (item_code food_purch_unit_new obs_country)
ren price_unit price_unit_median_country
lab var price_unit_median_country "Median price per kg for this crop in the country"
lab var obs_country "Number of observations for this crop in the country"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_country_PP.dta", replace


*Pull prices into consumption estimates
use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PP.dta", clear
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hhids.dta", nogen keep(1 3)
gen food_purch_unit_old=food_purch_unit_new

* Value Food consumption, production, and gift when the units does not match the units of purchased
foreach f in consu prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_consu_unit_new==food_purch_unit_new

*- using EA medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_consu_unit_new 
merge m:1 zone state lga ea item_code food_purch_unit_new using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_ea_PP.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_ea if food_consu_unit_new==food_purch_unit_new & food_`f'_value==. & obs_ea>10 & obs_ea!=.

*- using LGA medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_consu_unit_new 
merge m:1 zone state lga item_code food_purch_unit_new using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_lga_PP.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_lga if food_consu_unit_new==food_purch_unit_new & food_`f'_value==. & obs_lga>10 & obs_lga!=.

*- using state medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_consu_unit_new 
merge m:1 zone state item_code food_purch_unit_new using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_state_PP.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_state if food_consu_unit_new==food_purch_unit_new & food_`f'_value==. & obs_state>10 & obs_state!=.

*- using zone medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_consu_unit_new 
merge m:1 zone item_code food_purch_unit_new using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_zone_PP.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_zone if food_consu_unit_new==food_purch_unit_new & food_`f'_value==. & obs_zone>10 & obs_zone!=.

*- using country medians
drop food_purch_unit_new 
gen food_purch_unit_new=food_consu_unit_new 
merge m:1 item_code food_purch_unit_new using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_country_PP.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_consu_unit_new==food_purch_unit_new & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid item_code crop_category1 food_`f'_value
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PP_`f'.dta", replace
restore
}

merge 1:1  hhid item_code crop_category1  using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PP_consu.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PP_prod.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PP_gift.dta", nogen

collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid crop_category1)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_food_home_consumption_value_PP.dta", replace


*Food away from home
use "${Nigeria_GHS_W1_raw_data}/sect7a_plantingw1.dta", clear
* I am not sure we can confidently categorised FAH. So coding this as a separate category of food
egen food_purch_value=rowtotal(s7q2)
gen  food_consu_value=food_purch_value
collapse (sum) food_consu_value food_purch_value, by(hhid)
gen crop_category1="Meals away from home"
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_food_away_consumption_value_PP.dta", replace


use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_food_home_consumption_value_PP.dta", clear
append using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_food_away_consumption_value_PP.dta"
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hhids.dta", nogen keep(1 3)

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

gen visit="PP"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_food_consumption_value_PP.dta", replace


*HARVEST  
use "${Nigeria_GHS_W1_raw_data}/sect10b_harvestw1.dta", clear
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hhids.dta", nogen keep (1 3)
label list ITEM_CD
ren item_cd item_code
gen crop_category1=""					
replace crop_category1=	"Millet and Sorghum"			if  item_code==	10
replace crop_category1=	"Millet and Sorghum"			if  item_code==	11
replace crop_category1=	"Maize"			if  item_code==	12
replace crop_category1=	"Rice"			if  item_code==	13
replace crop_category1=	"Rice"			if  item_code==	14
replace crop_category1=	"Wheat"			if  item_code==	15
replace crop_category1=	"Maize"			if  item_code==	16
replace crop_category1=	"Yams"			if  item_code==	17
replace crop_category1=	"Cassava"			if  item_code==	18
replace crop_category1=	"Wheat"			if  item_code==	19
replace crop_category1=	"Other Cereals"			if  item_code==	20
replace crop_category1=	"Cassava"			if  item_code==	30
replace crop_category1=	"Yams"			if  item_code==	31
replace crop_category1=	"Cassava"			if  item_code==	32
replace crop_category1=	"Cassava"			if  item_code==	33
replace crop_category1=	"Yams"			if  item_code==	34
replace crop_category1=	"Bananas and Plantains"			if  item_code==	35
replace crop_category1=	"Sweet Potato"			if  item_code==	36
replace crop_category1=	"Potato"			if  item_code==	37
replace crop_category1=	"Other Roots and Tubers"			if  item_code==	38
replace crop_category1=	"Pulses"			if  item_code==	40
replace crop_category1=	"Pulses"			if  item_code==	41
replace crop_category1=	"Pulses"			if  item_code==	42
replace crop_category1=	"Groundnuts"			if  item_code==	43
replace crop_category1=	"Nuts and Seeds"			if  item_code==	44
replace crop_category1=	"Oils, Fats"			if  item_code==	50
replace crop_category1=	"Oils, Fats"			if  item_code==	51
replace crop_category1=	"Oils, Fats"			if  item_code==	52
replace crop_category1=	"Oils, Fats"			if  item_code==	53
replace crop_category1=	"Bananas and Plantains"			if  item_code==	60
replace crop_category1=	"Fruits"			if  item_code==	61
replace crop_category1=	"Fruits"			if  item_code==	62
replace crop_category1=	"Fruits"			if  item_code==	63
replace crop_category1=	"Fruits"			if  item_code==	64
replace crop_category1=	"Fruits"			if  item_code==	65
replace crop_category1=	"Fruits"			if  item_code==	66
replace crop_category1=	"Vegetables"			if  item_code==	70
replace crop_category1=	"Vegetables"			if  item_code==	71
replace crop_category1=	"Vegetables"			if  item_code==	72
replace crop_category1=	"Vegetables"			if  item_code==	73
replace crop_category1=	"Vegetables"			if  item_code==	74
replace crop_category1=	"Vegetables"			if  item_code==	75
replace crop_category1=	"Vegetables"			if  item_code==	76
replace crop_category1=	"Vegetables"			if  item_code==	77
replace crop_category1=	"Vegetables"			if  item_code==	78
replace crop_category1=	"Poultry Meat"			if  item_code==	80
replace crop_category1=	"Poultry Meat"			if  item_code==	81
replace crop_category1=	"Poultry Meat"			if  item_code==	82
replace crop_category1=	"Eggs"			if  item_code==	83
replace crop_category1=	"Eggs"			if  item_code==	84
replace crop_category1=	"Eggs"			if  item_code==	85
replace crop_category1=	"Beef Meat"			if  item_code==	90
replace crop_category1=	"Lamb and Goat Meat"			if  item_code==	91
replace crop_category1=	"Pork Meat"			if  item_code==	92
replace crop_category1=	"Lamb and Goat Meat"			if  item_code==	93
replace crop_category1=	"Other Meat"			if  item_code==	94
replace crop_category1=	"Other Meat"			if  item_code==	95
replace crop_category1=	"Other Meat"			if  item_code==	96
replace crop_category1=	"Fish and Seafood"			if  item_code==	100
replace crop_category1=	"Fish and Seafood"			if  item_code==	101
replace crop_category1=	"Fish and Seafood"			if  item_code==	102
replace crop_category1=	"Fish and Seafood"			if  item_code==	103
replace crop_category1=	"Fish and Seafood"			if  item_code==	104
replace crop_category1=	"Fish and Seafood"			if  item_code==	105
replace crop_category1=	"Fish and Seafood"			if  item_code==	106
replace crop_category1=	"Fish and Seafood"			if  item_code==	107
replace crop_category1=	"Dairy"			if  item_code==	110
replace crop_category1=	"Dairy"			if  item_code==	111
replace crop_category1=	"Dairy"			if  item_code==	112
replace crop_category1=	"Dairy"			if  item_code==	113
replace crop_category1=	"Dairy"			if  item_code==	114
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	120
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	121
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	122
replace crop_category1=	"Sugar, Sweets, Pastries"			if  item_code==	130
replace crop_category1=	"Sugar, Sweets, Pastries"			if  item_code==	131
replace crop_category1=	"Sugar, Sweets, Pastries"			if  item_code==	132
replace crop_category1=	"Sugar, Sweets, Pastries"			if  item_code==	133
replace crop_category1=	"Spices"			if  item_code==	140
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	150
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	151
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	152
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	153
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	154
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	155
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	160
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	161
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	162
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	163
replace crop_category1=	"Non-Dairy Beverages"			if  item_code==	164


ren s10bq1 food_consu_yesno
ren s10bq2b food_consu_unit
ren s10bq2a food_consu_qty
ren s10bq3b food_purch_unit
ren s10bq3a food_purch_qty
ren s10bq4 food_purch_value
ren s10bq5a food_prod_qty
ren s10bq5b food_prod_unit
ren s10bq6a food_gift_qty
ren s10bq6b food_gift_unit


replace food_consu_qty=food_consu_qty/1000 if food_consu_unit==2
replace food_purch_qty=food_purch_qty/1000 if food_purch_unit==2 // AYW 4.15.20
replace food_prod_qty=food_prod_qty/1000 if food_prod_unit==2
replace food_gift_qty=food_gift_qty/1000 if food_gift_unit==2

replace food_purch_qty=food_purch_qty/100 if food_purch_unit==4 
replace food_consu_qty=food_consu_qty/100 if food_consu_unit==4
replace food_prod_qty=food_prod_qty/100 if food_prod_unit==4
replace food_gift_qty=food_gift_qty/100 if food_gift_unit==4

recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (2 =1 ) (4=3)  // gramns in kg and mili in liter
keep if food_consu_yesno==1
drop if food_consu_qty==0  | food_consu_qty==.
*Imput the value of consumption using prices infered from the quantity of purchase and the value of pruchases.
gen price_unit= food_purch_value/food_purch_qty
recode price_unit (0=.)
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PH.dta", replace
 
 
use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PH.dta", clear
drop if price_unit==.
gen observation = 1
bys zone state lga ea item_code food_purch_unit: egen obs_ea = count(observation)
collapse (median) price_unit [aw=weight], by (zone state lga ea item_code food_purch_unit obs_ea)
ren price_unit price_unit_median_ea
lab var price_unit_median_ea "Median price per kg for this crop in the enumeration area"
lab var obs_ea "Number of observations for this crop in the enumeration area"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_ea_PH.dta", replace

use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PH.dta", clear
drop if price_unit==.
gen observation = 1
bys zone state lga item_code food_purch_unit: egen obs_lga = count(observation)
collapse (median) price_unit [aw=weight], by (zone state lga item_code food_purch_unit obs_lga)
ren price_unit price_unit_median_lga
lab var price_unit_median_lga "Median price per kg for this crop in the lga"
lab var obs_lga "Number of observations for this crop in the lga"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_lga_PH.dta", replace

use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PH.dta", clear
drop if price_unit==.
gen observation = 1
bys zone state item_code food_purch_unit: egen obs_state = count(observation) 
collapse (median) price_unit [aw=weight], by (zone state item_code food_purch_unit obs_state)
ren price_unit price_unit_median_state
lab var price_unit_median_state "Median price per kg for this crop in the state"
lab var obs_state "Number of observations for this crop in the state"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_state_PH.dta", replace

use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PH.dta", clear
drop if price_unit==.
gen observation = 1
bys zone item_code food_purch_unit: egen obs_zone = count(observation)
collapse (median) price_unit [aw=weight], by (zone item_code food_purch_unit obs_zone)
ren price_unit price_unit_median_zone
lab var price_unit_median_zone "Median price per kg for this crop in the zone"
lab var obs_zone "Number of observations for this crop in the zone"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_zone_PH.dta", replace

use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PH.dta", clear
drop if price_unit==.
gen observation = 1
bys item_code food_purch_unit: egen obs_country = count(observation)
collapse (median) price_unit [aw=weight], by (item_code food_purch_unit obs_country)
ren price_unit price_unit_median_country
lab var price_unit_median_country "Median price per kg for this crop in the country"
lab var obs_country "Number of observations for this crop in the country"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_country_PH.dta", replace


*Pull prices into consumption estimates
use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PH.dta", clear
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hhids.dta", nogen keep(1 3)
*gen food_purch_unit_old=food_purch_unit_new

* Value Food consumption, production, and gift when the units does not match the units of purchased
foreach f in consu prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit==food_purch_unit


*- using EA medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 zone state lga ea item_code food_purch_unit using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_ea_PH.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_ea if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_ea>10 & obs_ea!=.

*- using LGA medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 zone state lga item_code food_purch_unit using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_lga_PH.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_lga if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_lga>10 & obs_lga!=.

*- using state medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 zone state item_code food_purch_unit using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_state_PH.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_state if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_state>10 & obs_state!=.

*- using zone medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 zone item_code food_purch_unit using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_zone_PH.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_zone if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_zone>10 & obs_zone!=.

*- using country medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 item_code food_purch_unit using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_item_prices_country_PH.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid item_code crop_category1 food_`f'_value
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PH_`f'.dta", replace
restore
}

merge 1:1  hhid item_code crop_category1  using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PH_consu.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PH_prod.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_consumption_purchase_PH_gift.dta", nogen


collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid crop_category1)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_food_home_consumption_value_PH.dta", replace


*Food away from home
use "${Nigeria_GHS_W1_raw_data}/sect10a_harvestw1.dta", clear
* I am not sure we can confidently categorised FAH. So coding this as a separate category of food
egen food_purch_value=rowtotal(s10aq2)
gen  food_consu_value=food_purch_value
collapse (sum) food_consu_value food_purch_value, by(hhid)
gen crop_category1="Meals away from home"
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_food_away_consumption_value_PH.dta", replace

use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_food_home_consumption_value_PH.dta", clear
append using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_food_away_consumption_value_PH.dta"
merge m:1 hhid using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_hhids.dta", nogen keep(1 3)

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

gen visit="PH"
save "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_food_consumption_value_PH.dta", replace

 
 *Average PP and PH
use "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_food_consumption_value_PP.dta", clear
append using "${Nigeria_GHS_W1_created_data}/Nigeria_GHS_W1_food_consumption_value_PH.dta"

foreach v of varlist * {
		local l`v': var label `v'
}

collapse (mean) food_consu_value food_purch_value food_prod_value food_gift_value ,by(hhid zone state lga ea fhh hh_members adulteq rural weight crop_category1 ccf_loc ccf_usd ccf_1ppp ccf_2ppp)

foreach v of varlist * {
	label var `v' "`l`v''" 
}

*RESCALING the components of consumption such that the sum always match
** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value  {
	_pctile `v' [aw=weight] if `v'!=0 , p($wins_upper_thres)  
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
}


ren state adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province"
ren lga adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"
gen adm3=.
lab var adm3 "Adminstrative subdivision 3 - county"
drop zone
qui gen Country="Nigeria"
lab var Countr "Country name"
qui gen Instrument="Nigeria LSMS-ISA/GHS W1"
lab var Instrument "Survey name"
qui gen Year="2010/11"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

*generate GID_1 code to match codes in the Nigeria shapefile
gen GID_1=""
replace GID_1="NGA.1_1"  if adm1==1
replace GID_1="NGA.2_1"  if adm1==2
replace GID_1="NGA.3_1"  if adm1==3
replace GID_1="NGA.4_1"  if adm1==4
replace GID_1="NGA.5_1"  if adm1==5
replace GID_1="NGA.6_1"  if adm1==6
replace GID_1="NGA.7_1"  if adm1==7
replace GID_1="NGA.8_1"  if adm1==8
replace GID_1="NGA.9_1"  if adm1==9
replace GID_1="NGA.10_1"  if adm1==10
replace GID_1="NGA.11_1"  if adm1==11
replace GID_1="NGA.12_1"  if adm1==12
replace GID_1="NGA.13_1"  if adm1==13
replace GID_1="NGA.14_1"  if adm1==14
replace GID_1="NGA.15_1"  if adm1==37
replace GID_1="NGA.16_1"  if adm1==15
replace GID_1="NGA.17_1"  if adm1==16
replace GID_1="NGA.18_1"  if adm1==17
replace GID_1="NGA.19_1"  if adm1==18
replace GID_1="NGA.20_1"  if adm1==19
replace GID_1="NGA.21_1"  if adm1==20
replace GID_1="NGA.22_1"  if adm1==21
replace GID_1="NGA.23_1"  if adm1==22
replace GID_1="NGA.24_1"  if adm1==23
replace GID_1="NGA.25_1"  if adm1==24
replace GID_1="NGA.26_1"  if adm1==25
replace GID_1="NGA.27_1"  if adm1==26
replace GID_1="NGA.28_1"  if adm1==27
replace GID_1="NGA.29_1"  if adm1==28
replace GID_1="NGA.30_1"  if adm1==29
replace GID_1="NGA.31_1"  if adm1==30
replace GID_1="NGA.32_1"  if adm1==31
replace GID_1="NGA.33_1"  if adm1==32
replace GID_1="NGA.34_1"  if adm1==33
replace GID_1="NGA.35_1"  if adm1==34
replace GID_1="NGA.36_1"  if adm1==35
replace GID_1="NGA.37_1"  if adm1==36
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
replace conv_lcu_ppp=	0.019110663	if Instrument==	"Nigeria LSMS-ISA/GHS W1"

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

ren hhid old_hhid
gen hhid=string(old_hhid)
drop old_hhid

compress
save "${final_data}/Nigeria_GHS_W1_food_consumption_value_by_source.dta", replace


*****End of Do File*****
  
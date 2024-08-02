/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Tanzania National Panel Survey (NPS) LSMS-ISA Wave 4 (2014-15)

*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Tanzania National Panel Survey was collected by the Tanzania National Bureau of Statistics
*and the World Bank's Living Standards Measurement Study - Integrated Surveys on Agriculture(LSMS - ISA)
*The data were collected over the period October 2014 - October 2015.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://microdata.worldbank.org/index.php/catalog/2862


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Tanzania NPS dataset.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, rural location indicator, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Tanzania_NPS_W4_hhids.dta
*Food Consumption by source			Tanzania_NPS_W4_food_consumption_value_by_source.dta

*/



clear	
set more off
clear matrix	
clear mata	
set maxvar 10000	
ssc install findname  // need this user-written ado file for some commands to work

*Set location of raw data and output
global directory			    "//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/335 - Ag Team Data Support/Waves"

//set directories: These paths correspond to the folders where the raw data files are located and where the created data and final data will be stored.
global Tanzania_NPS_W4_raw_data 			"$directory/Tanzania NPS/Tanzania NPS Wave 4/Raw DTA files/TZA_2014_NPS-R4_v03_M_STATA11"
global Tanzania_NPS_W4_created_data 		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"



********************************************************************************
*EXCHANGE RATE AND INFLTION FOR CONVERSION IN SUD IDS
********************************************************************************
global Tanzania_NPS_W4_exchange_rate 1991.391			// https://data.worldbank.org/indicator/PA.NUS.FCRF?locations=TZ
global Tanzania_NPS_W4_gdp_ppp_dollar 885.0829  		// https://data.worldbank.org/indicator/PA.NUS.PPP
global Tanzania_NPS_W4_cons_ppp_dollar 754.6215 		// https://data.worldbank.org/indicator/PA.NUS.PRVT.PP
global Tanzania_NPS_W4_inflation 0.107687   		// inflation rate 2015-2017. Data was collected during October 2014-2015. We have adjusted values to 2017. https://data.worldbank.org/indicator/FP.CPI.TOTL?locations=TZ

********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Tanzania_NPS_W4_pop_tot 52542823
global Tanzania_NPS_W4_pop_rur 35930359
global Tanzania_NPS_W4_pop_urb 16612464


************************
*HOUSEHOLD IDS 
************************
use "${Tanzania_NPS_W4_raw_data}/hh_sec_b.dta", clear
ren hh_b04  age
ren hh_b02 gender
gen fhh = (hh_b05==1 & gender==2)
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
collapse (sum) hh_members adulteq (max) fhh, by (y4_hhid)

merge 1:1 y4_hhid using "${Tanzania_NPS_W4_raw_data}/hh_sec_a.dta", nogen keep (1 3)
ren hh_a01_1 region 
ren hh_a01_2 region_name
ren hh_a02_1 district
ren hh_a02_2 district_name
ren hh_a03_1 ward 
ren hh_a03_2 ward_name
ren hh_a03_3a village 
ren hh_a03_3b village_name
ren hh_a04_1 ea
ren y4_weights weight
gen rural = (clustertype==1)
keep y4_hhid region district ward village region_name district_name ward_name village_name ea rural weight strataid clusterid fhh hh_members adulteq
lab var rural "1=Household lives in a rural area"

*Generating the variable that indicate the level of representativness of the survey (to use for reporting summary stats)
gen level_representativness=.
replace level_representativness=1 if region==7 
replace level_representativness=2 if region==53 
replace level_representativness=3 if !inlist(region,7,53) & rural==1
replace level_representativness=4 if !inlist(region,7,53) & rural==0

*replace level_representativness=4 if region==2 & rural==0

lab define lrep 1 "Dar es Salaam"  ///
                2 "Zanzibar"  ///
                3 "Other urban areas in Tanzania"   ///
                4 "Rural mainland Tanzania"  ///
                						
lab var level_representativness "Level of representivness of the survey"						
lab value level_representativness	lrep
tab level_representativness

****Currency Conversion Factors***
gen ccf_loc = (1 + $Tanzania_NPS_W4_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $TZS"
*gen ccf_usd = (1 + $Malawi_IHS_W1_inflation)/$Tanzania_NPS_W4_exchange_rate 
*lab var ccf_usd "currency conversion factor - 2017 $USD"
gen ccf_1ppp = (1 + $Tanzania_NPS_W4_inflation)/ $Tanzania_NPS_W4_cons_ppp_dollar
lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Tanzania_NPS_W4_inflation)/ $Tanzania_NPS_W4_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"
 
save "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_hhids.dta", replace


********************************************************************************
*CONSUMPTION
******************************************************************************** 
use "${Tanzania_NPS_W4_raw_data}/hh_sec_j1.dta", clear
merge m:1 y4_hhid using "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_hhids.dta", nogen keep (1 3)
*label list HH_J00
ren itemcode item_code
* recode food categories
gen crop_category1=""				
replace crop_category1=	"Rice"		if  item_code==	101
replace crop_category1=	"Rice"		if  item_code==	102
replace crop_category1=	"Maize"		if  item_code==	103
replace crop_category1=	"Maize"		if  item_code==	104
replace crop_category1=	"Maize"		if  item_code==	105
replace crop_category1=	"Millet and Sorghum"		if  item_code==	106
replace crop_category1=	"Millet and Sorghum"		if  item_code==	107
replace crop_category1=	"Wheat"		if  item_code==	109
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	110
replace crop_category1=	"Wheat"		if  item_code==	111
replace crop_category1=	"Other Cereals"		if  item_code==	112
replace crop_category1=	"Cassava"		if  item_code==	201
replace crop_category1=	"Cassava"		if  item_code==	202
replace crop_category1=	"Sweet Potato"		if  item_code==	203
replace crop_category1=	"Yams"		if  item_code==	204
replace crop_category1=	"Potato"		if  item_code==	205
replace crop_category1=	"Bananas and Plantains"		if  item_code==	206
replace crop_category1=	"Other Roots and Tubers"		if  item_code==	207
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	301
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	302
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	303
replace crop_category1=	"Pulses"		if  item_code==	401
replace crop_category1=	"Groundnuts"		if  item_code==	501
replace crop_category1=	"Fruits"		if  item_code==	502
replace crop_category1=	"Nuts and Seeds"		if  item_code==	503
replace crop_category1=	"Nuts and Seeds"		if  item_code==	504
replace crop_category1=	"Vegetables"		if  item_code==	601
replace crop_category1=	"Vegetables"		if  item_code==	602
replace crop_category1=	"Vegetables"		if  item_code==	603
replace crop_category1=	"Bananas and Plantains"		if  item_code==	701
replace crop_category1=	"Fruits"		if  item_code==	702
replace crop_category1=	"Fruits"		if  item_code==	703
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	704
replace crop_category1=	"Lamb and Goat Meat"		if  item_code==	801
replace crop_category1=	"Beef Meat"		if  item_code==	802
replace crop_category1=	"Pork Meat"		if  item_code==	803
replace crop_category1=	"Poultry Meat"		if  item_code==	804
replace crop_category1=	"Other Meat"		if  item_code==	805
replace crop_category1=	"Other Meat"		if  item_code==	806
replace crop_category1=	"Eggs"		if  item_code==	807
replace crop_category1=	"Fish and Seafood"		if  item_code==	808
replace crop_category1=	"Fish and Seafood"		if  item_code==	809
replace crop_category1=	"Fish and Seafood"		if  item_code==	810
replace crop_category1=	"Dairy"		if  item_code==	901
replace crop_category1=	"Dairy"		if  item_code==	902
replace crop_category1=	"Dairy"		if  item_code==	903
replace crop_category1=	"Oils, Fats"		if  item_code==	1001
replace crop_category1=	"Oils, Fats"		if  item_code==	1002
replace crop_category1=	"Spices"		if  item_code==	1003
replace crop_category1=	"Spices"		if  item_code==	1004
replace crop_category1=	"Wheat"		if  item_code==	1081
replace crop_category1=	"Other Cereals"		if  item_code==	1082
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	1101
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	1102
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	1103
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	1104
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	1105
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	1106
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	1107
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	1108


ren hh_j01 food_consu_yesno
ren hh_j02_1 food_consu_unit
ren hh_j02_2 food_consu_qty
ren hh_j03_1 food_purch_unit
ren hh_j03_2 food_purch_qty
ren hh_j04 food_purch_value
ren hh_j05_1 food_prod_unit
ren hh_j05_2 food_prod_qty
ren hh_j06_1 food_gift_unit
ren hh_j06_2 food_gift_qty

replace food_consu_qty=food_consu_qty/1000 if food_consu_unit==2 | food_consu_unit==4  
replace food_purch_qty=food_purch_qty/1000 if food_purch_unit==2 | food_purch_unit==4
replace food_prod_qty=food_prod_qty/1000 if food_prod_unit==2 | food_prod_unit==4
replace food_gift_qty=food_gift_qty/1000 if food_gift_unit==2 | food_gift_unit==4
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (7=.) (2 =1 ) (4=3)  // grams in kg and milliliters in liter // AYW: I moved this line below the lines above. It seems the same should be done for the other countries.

keep if food_consu_yesno==1
drop if food_consu_qty==0  | food_consu_qty==.

*Impute the value of consumption using prices inferred from the quantity of purchase and the value of purchases.
gen price_unit= food_purch_value/food_purch_qty
recode price_unit (0=.)
save "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_consumption_purchase.dta", replace
 
 
gen country=1 
save "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_consumption_purchase.dta", replace
 
*Valuation using price_per_unit
global pgeo_vars country region district ward ea
local len : word count $pgeo_vars
while `len'!=0 {
	local g : word  `len' of $pgeo_vars
	di "`g'"
	use "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_consumption_purchase.dta", clear
	qui drop if price_unit==.
	qui gen observation = 1
	qui bys $pgeo_vars item_code food_purch_unit: egen obs_`g' = count(observation)
	collapse (median) price_unit [aw=weight], by ($pgeo_vars item_code food_purch_unit obs_`g')
	ren price_unit price_unit_median_`g'
	lab var price_unit_median_`g' "Median price per unit for this crop - `g'"
	lab var obs_`g' "Number of observations for this crop - `g'"
	qui save "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_item_prices_`g'.dta", replace
	global pgeo_vars=subinstr("$pgeo_vars","`g'","",1)
	local len=`len'-1

}


*Pull prices into consumption estimates
use "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_consumption_purchase.dta", clear
merge m:1 y4_hhid using "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_hhids.dta", nogen keep(1 3) 

* Value consumption, production, and given when the units does not match the units of purchased
foreach f in consu prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit==food_purch_unit


*- using EA medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region district ward ea item_code food_purch_unit using "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_item_prices_ea.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_ea if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_ea>10 & obs_ea!=.

*- using ward medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region district ward item_code food_purch_unit using "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_item_prices_ward.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_ward if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_ward>10 & obs_ward!=.

*- using disrict medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region district item_code food_purch_unit using "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_item_prices_district.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_district if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_district>10 & obs_district!=.

*- using region medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region item_code food_purch_unit using "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_item_prices_region.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_region if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_region>10 & obs_region!=.

*- using country medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 item_code food_purch_unit using "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_item_prices_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_country>10 & obs_country!=.

keep y4_hhid item_code crop_category1 food_`f'_value
save "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_consumption_purchase_`f'.dta", replace
restore
}

merge 1:1  y4_hhid item_code crop_category1  using "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_consumption_purchase_consu.dta", nogen
merge 1:1  y4_hhid item_code crop_category1  using "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_consumption_purchase_prod.dta", nogen
merge 1:1  y4_hhid item_code crop_category1  using "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_consumption_purchase_gift.dta", nogen

collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(y4_hhid crop_category1)
recode  food_consu_value food_purch_value food_prod_value food_gift_value (.=0)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_food_home_consumption_value.dta", replace


*Food away from home
use "${Tanzania_NPS_W4_raw_data}/hh_sec_f.dta", clear
egen food_purch_value=rowtotal(hh_f03 hh_f05 hh_f07 hh_f09 hh_f11 hh_f13 hh_f15)
gen  food_consu_value=food_purch_value
collapse (sum) food_consu_value food_purch_value, by(y4_hhid)
gen crop_category1="Meals away from home"
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
save "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_food_away_consumption_value.dta", replace

use "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_food_home_consumption_value.dta", clear
append using "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_food_away_consumption_value.dta"
merge m:1 y4_hhid using "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_hhids.dta", nogen keep(1 3)
ren y4_hhid hhid

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

*RESCALING the components of consumption such that the sum always match
** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value {
	_pctile `v' [aw=weight] if `v'!=0 , p($wins_upper_thres)  
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
}

save "${Tanzania_NPS_W4_created_data}/Tanzania_NPS_W4_food_consumption_value.dta", replace

ren region adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province"
ren district adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"
ren ward adm3 
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="Tanzania"
lab var Countr "Country name"
qui gen Instrument="Tanzania LSMS-ISA/NPS W4"
lab var Instrument "Survey name"
qui gen Year="2014/15"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

*generate GID_1 code to match codes in the Benin shapefile
gen GID_1=""
*replace GID_1="TZA.1_1"  if adm1==
replace GID_1="TZA.2_1"  if adm1==7
replace GID_1="TZA.3_1"  if adm1==1
replace GID_1="TZA.4_1"  if adm1==25
replace GID_1="TZA.5_1"  if adm1==11
replace GID_1="TZA.6_1"  if adm1==18
replace GID_1="TZA.18_1"  if adm1==54
replace GID_1="TZA.28_1"  if adm1==51
replace GID_1="TZA.7_1"  if adm1==23
replace GID_1="TZA.8_1"  if adm1==16
replace GID_1="TZA.9_1"  if adm1==3
replace GID_1="TZA.19_1"  if adm1==55
replace GID_1="TZA.29_1"  if adm1==52
replace GID_1="TZA.10_1"  if adm1==8
replace GID_1="TZA.11_1"  if adm1==21
replace GID_1="TZA.12_1"  if adm1==20
replace GID_1="TZA.13_1"  if adm1==12
replace GID_1="TZA.30_1"  if adm1==53
replace GID_1="TZA.14_1"  if adm1==5
replace GID_1="TZA.15_1"  if adm1==9
replace GID_1="TZA.16_1"  if adm1==19
replace GID_1="TZA.17_1"  if adm1==22
replace GID_1="TZA.20_1"  if adm1==6
replace GID_1="TZA.21_1"  if adm1==15
replace GID_1="TZA.22_1"  if adm1==10
replace GID_1="TZA.23_1"  if adm1==17
replace GID_1="TZA.24_1"  if adm1==24
replace GID_1="TZA.25_1"  if adm1==13
*replace GID_1="TZA.31_1"  if adm1==
replace GID_1="TZA.26_1"  if adm1==14
replace GID_1="TZA.27_1"  if adm1==4
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
replace conv_lcu_ppp=	0.001549898	if Instrument==	"Tanzania LSMS-ISA/NPS W4"

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
save "${final_data}/Tanzania_NPS_W4_food_consumption_value_by_source.dta", replace


*****End of Do File*****
  	



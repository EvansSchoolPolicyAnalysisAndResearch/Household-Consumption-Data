/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Pakistan Household Integrated Economic Survey (HIES) (2007-08)
				 
*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Pakistan Household Integrated Economic Survey was collected by the Government of Pakistan
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://www.pbs.gov.pk/publication/household-integrated-economic-survey-hies-2007-08


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Pakistan HIES dataset.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, rural location indicator, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Pakistan_HIES_W3_hhids.dta
*Food Consumption by source			Pakistan_HIES_W3_food_consumption_value_by_source.dta

*/



clear	
set more off
clear matrix	
clear mata	
set maxvar 10000

*Set location of raw data and output
global directory			    "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Non-LSMS Datasets"

//set directories: These paths correspond to the folders where the raw data files are located and where the created data and final data will be stored.
global Pakistan_HIES_W3_raw_data 			"$directory\Pakistan HIES\Pakistan HIES 2007-2008\data_in_stata"
global Pakistan_HIES_W3_created_data 		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"


********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN SUD IDS
********************************************************************************
global Pakistan_HIES_W3_exchange_rate 70.41			// https://data.worldbank.org/indicator/PA.NUS.FCRF?locations=PK
global Pakistan_HIES_W3_gdp_ppp_dollar 16.22 		// https://data.worldbank.org/indicator/PA.NUS.PPP?locations=PK
global Pakistan_HIES_W3_cons_ppp_dolar 18.54 		// https://data.worldbank.org/indicator/PA.NUS.PRVT.PP?locations=PK
global Pakistan_HIES_W3_inflation 1.014   		// inflation rate 2013-2017. Data was collected during October 2018-2019. We have adjusted values to 2017. https://data.worldbank.org/indicator/FP.CPI.TOTL?locations=PK  


********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Pakistan_HIES_W3_pop_tot 185931955
global Pakistan_HIES_W3_pop_rur 121618092
global Pakistan_HIES_W3_pop_urb 64313863

 
************************
*HOUSEHOLD IDS 
************************
use "${Pakistan_HIES_W3_raw_data}\plist.dta", clear   
ren s1aq03 gender
codebook s1aq02, tab(100)
gen fhh = gender==2 & s1aq02==1
lab var fhh "1= Female-headed Household"
gen hh_members = 1 if s1aq10==1
keep if hh_members==1  
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
replace adulteq=. if age==998
replace adulteq=. if age==999
lab var adulteq "Adult-Equivalent"
gen rural = (region==2)
lab var rural "1=Household lives in a rural area"
*egen hhid=concat(hhcode idc)

*Generating the variable that indicate the level of representativness of the survey (to use for reporting summary stats)
*Representative at the county level.
gen level_representativness=.
replace level_representativness=11 if province==1 & rural==1
replace level_representativness=12 if province==1 & rural==0
replace level_representativness=21 if province==2 & rural==1
replace level_representativness=22 if province==2 & rural==0
replace level_representativness=31 if province==3 & rural==1
replace level_representativness=32 if province==3 & rural==0
replace level_representativness=41 if province==4 & rural==1
replace level_representativness=42 if province==4 & rural==0

lab define lrep 11 "Punjab - Rural"  ///
                12 "Punjab - Urban"  ///
			    21 "Sindh - Rural"   ///
                22 "Sindh - Urban"  ///
                31 "Kp - Rural"  ///
                32 "Kp - Urban"  ///
				41 "Balochistan - Rural"  ///
                42 "Balochistan - Urban"  ///
           
lab value level_representativness	lrep
tab level_representativness
sort hhcode idc 
collapse (max) fhh rural level_representativness province weight (sum) hh_members adulteq, by(psu hhcode)


****Currency Conversion Factors***
gen ccf_loc = (1 + $Pakistan_HIES_W3_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $PKR"
*gen ccf_usd = (1 + $Pakistan_HIES_W3_inflation)/$Pakistan_HIES_W3_exchange_rate 
*lab var ccf_usd "currency conversion factor - 2017 $USD"
*gen ccf_1ppp = (1 + $Pakistan_HIES_W3_inflation)/ $Pakistan_HIES_W3_cons_ppp_dolar
*lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Pakistan_HIES_W3_inflation)/ $Pakistan_HIES_W3_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"

save "${Pakistan_HIES_W3_created_data}/Pakistan_HIES_W3_hhids.dta", replace


********************************************************************************
*CONSUMPTION 
******************************************************************************** 
use "${Pakistan_HIES_W3_raw_data}\sec 6abcde.dta", clear
merge m:1 hhcode using "${Pakistan_HIES_W3_created_data}/Pakistan_HIES_W3_hhids.dta", nogen keep (1 3)

label list itc
gen eaten_out = inrange(itc, 2101, 2504)
gen at_home = inrange(itc, 1101, 1901)

drop if at_home == 0 & eaten_out==0

egen purchased_qty= rowtotal(q1 q2)
egen purchased_value= rowtotal(v1 v2)
gen produced_qty= q3
gen produced_value= v3
gen gift_qty= q4
gen gift_value= v4

egen qty = rowtotal(q1 q2 q3 q4)
egen val = rowtotal(v1 v2 v3 v4)
gen price = val/qty

replace qty = qty/10 if itc==11108 //jawar is roughly 30 rupees a kilo, some mixed units here.
replace purchased_qty = purchased_qty/10 if itc==11108 //jawar is roughly 30 rupees a kilo, some mixed units here.
replace produced_qty = produced_qty/10 if itc==11108 //jawar is roughly 30 rupees a kilo, some mixed units here.
replace gift_qty = gift_qty/10 if itc==11108 //jawar is roughly 30 rupees a kilo, some mixed units here.


* recode food categories
ren itc item_code
gen crop_category1=""			
replace crop_category1=	"Dairy"	if  item_code==	1101
replace crop_category1=	"Dairy"	if  item_code==	1102
replace crop_category1=	"Dairy"	if  item_code==	1103
replace crop_category1=	"Dairy"	if  item_code==	1104
replace crop_category1=	"Oils, Fats"	if  item_code==	1105
replace crop_category1=	"Dairy"	if  item_code==	1106
replace crop_category1=	"Beef Meat"	if  item_code==	1201
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	1202
replace crop_category1=	"Poultry Meat"	if  item_code==	1203
replace crop_category1=	"Eggs"	if  item_code==	1204
replace crop_category1=	"Fish and Seafood"	if  item_code==	1205
replace crop_category1=	"Fruits"	if  item_code==	1301
replace crop_category1=	"Fruits"	if  item_code==	1302
replace crop_category1=	"Fruits"	if  item_code==	1303
replace crop_category1=	"Fruits"	if  item_code==	1304
replace crop_category1=	"Fruits"	if  item_code==	1305
replace crop_category1=	"Fruits"	if  item_code==	1306
replace crop_category1=	"Fruits"	if  item_code==	1307
replace crop_category1=	"Fruits"	if  item_code==	1308
replace crop_category1=	"Fruits"	if  item_code==	1401
replace crop_category1=	"Potato"	if  item_code==	1501
replace crop_category1=	"Vegetables"	if  item_code==	1502
replace crop_category1=	"Vegetables"	if  item_code==	1503
replace crop_category1=	"Vegetables"	if  item_code==	1504
replace crop_category1=	"Vegetables"	if  item_code==	1505
replace crop_category1=	"Vegetables"	if  item_code==	1506
replace crop_category1=	"Vegetables"	if  item_code==	1507
replace crop_category1=	"Vegetables"	if  item_code==	1508
replace crop_category1=	"Vegetables"	if  item_code==	1509
replace crop_category1=	"Vegetables"	if  item_code==	1510
replace crop_category1=	"Spices"	if  item_code==	1601
replace crop_category1=	"Spices"	if  item_code==	1602
replace crop_category1=	"Spices"	if  item_code==	1603
replace crop_category1=	"Spices"	if  item_code==	1604
replace crop_category1=	"Spices"	if  item_code==	1605
replace crop_category1=	"Spices"	if  item_code==	1606
replace crop_category1=	"Spices"	if  item_code==	1607
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	1701
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	1702
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	1703
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	1704
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	1705
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	1706
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1801
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1802
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1803
replace crop_category1=	"Other Food"	if  item_code==	1901
replace crop_category1=	"Wheat"	if  item_code==	2101
replace crop_category1=	"Rice"	if  item_code==	2102
replace crop_category1=	"Maize"	if  item_code==	2103
replace crop_category1=	"Wheat"	if  item_code==	2104
replace crop_category1=	"Other Cereals"	if  item_code==	2105
replace crop_category1=	"Pulses"	if  item_code==	2201
replace crop_category1=	"Pulses"	if  item_code==	2202
replace crop_category1=	"Pulses"	if  item_code==	2203
replace crop_category1=	"Pulses"	if  item_code==	2204
replace crop_category1=	"Pulses"	if  item_code==	2205
replace crop_category1=	"Pulses"	if  item_code==	2206
replace crop_category1=	"Oils, Fats"	if  item_code==	2301
replace crop_category1=	"Oils, Fats"	if  item_code==	2302
replace crop_category1=	"Oils, Fats"	if  item_code==	2303
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	2401
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	2402
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	2501
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	2502
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	2503
replace crop_category1=	"Other Food"	if  item_code==	2504
replace crop_category1=	"Tobacco"	if  item_code==	4101
replace crop_category1=	"Tobacco"	if  item_code==	4102
replace crop_category1=	"Tobacco"	if  item_code==	4103
replace crop_category1=	"Tobacco"	if  item_code==	4104


*convert Two-week household consumption recall to annual value by multiplying with 12
foreach x of varlist val purchased_value produced_value gift_value {
	replace `x'=`x' *26 //to annualize
	local l`x' : var lab `x'
	local nl`x'=subinstr("`l`x''","over the past 14 days","",1)
	lab var `x' "Annual `nl`x''"
}

recode val purchased_value produced_value gift_value (.=0)
ren val food_consu_value
ren purchased_value food_purch_value 
ren produced_value food_prod_value 
ren gift_value food_gift_value 
save "${Pakistan_HIES_W3_created_data}/Pakistan_HIES_W3_all_consumption_value_winsorized.dta",replace

use "${Pakistan_HIES_W3_created_data}/Pakistan_HIES_W3_all_consumption_value_winsorized.dta",clear

label var food_consu_value "Annual value of food consumed, nominal"
label var food_purch_value "Annual value of food purchased, nominal"
label var food_prod_value "Annual value of food produced, nominal"
label var food_gift_value "Annual value of food received, nominal"
lab var fhh "1= Female-headed household"
lab var hh_members "Number of household members"
lab var adulteq "Adult-Equivalent"
lab var crop_category1 "Food items"
lab var hhcode "Household ID"

foreach v of varlist * {
		local l`v': var label `v'
}

collapse (mean) food_consu_value food_purch_value food_prod_value food_gift_value ,by(hhcode province psu fhh hh_members adulteq rural weight crop_category1)
merge m:1 hhcode using "${Pakistan_HIES_W3_created_data}/Pakistan_HIES_W3_hhids.dta", nogen keep (1 3)

foreach v of varlist * {
	label var `v' "`l`v''" 
}

*Winsorisation
ren hhcode hhid
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value  {
	_pctile `v' [aw=weight] if `v'!=0 , p($wins_upper_thres)  
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
}


ren province adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province"
ren psu adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"
gen adm3=.
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="Pakistan"
lab var Countr "Country name"
qui gen Instrument="Pakistan HIES W3"
lab var Instrument "Survey name"
qui gen Year="2007/08"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

*generate GID_1 code to match codes in the Pakistan shapefile
gen GID_1=""
*replace GID_1="Z06.1_1"  if adm1==
replace GID_1="PAK.2_1"  if adm1==4
*replace GID_1="PAK.3_1"  if adm1==
*replace GID_1="Z06.6_1"  if adm1==
*replace GID_1="PAK.4_1"  if adm1==
replace GID_1="PAK.5_1"  if adm1==3
replace GID_1="PAK.7_1"  if adm1==1
replace GID_1="PAK.8_1"  if adm1==2

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
replace conv_lcu_ppp=	0.0728573	if Instrument==	"Pakistan HIES W3"

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
save "${final_data}/Pakistan_HIES_W3_food_consumption_value_by_source.dta", replace


*****End of Do File*****
  
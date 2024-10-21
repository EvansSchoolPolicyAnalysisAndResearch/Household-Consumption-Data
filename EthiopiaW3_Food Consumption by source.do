/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Ethiopia Socioeconomic Survey (ESS) LSMS-ISA Wave 3 (2015-16)

*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Ethiopia Socioeconomic Survey was collected by the Ethiopia Central Statistical Agency (CSA) 
*and the World Bank's Living Standards Measurement Study - Integrated Surveys on Agriculture(LSMS - ISA)
*The data were collected over the period September - October 2015, November - December 2015, February - April 2016.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://microdata.worldbank.org/index.php/catalog/2783


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Ethiopia ESS data set.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, rural location indicator, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Ethiopia_ESS_W3_hhids.dta
*Food Consumption by source			Ethiopia_ESS_W3_food_consumption_value_by_source.dta

*/



clear
clear matrix
clear mata
set more off
set maxvar 10000		
ssc install findname  // need this user-written ado file for some commands to work	

*Set location of raw data and output
global directory 					"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/335 - Ag Team Data Support/Waves"
*global directory					"/Volumes/wfs/Project/EPAR/Working Files/335 - Ag Team Data Support/Waves"

*Set directories
global Ethiopia_ESS_W3_raw_data			"$directory/Ethiopia ESS/Ethiopia ESS Wave 3/Raw DTA Files/ETH_2015_ESS_v02_M_STATA8"
global Ethiopia_ESS_W3_created_data		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"


********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN USD IDS
********************************************************************************
global Ethiopia_ESS_W3_exchange_rate 21.73155	// https://www.bloomberg.com/quote/USDETB:CUR
global Ethiopia_ESS_W3_gdp_ppp_dollar 8.5209 	// https://data.worldbank.org/indicator/PA.NUS.PPP
global Ethiopia_ESS_W3_cons_ppp_dollar 8.4964	// https://data.worldbank.org/indicator/PA.NUS.PRVT.PP
global Ethiopia_ESS_W3_inflation 0.293172


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Ethiopia_ESS_W3_pop_tot 105293228
global Ethiopia_ESS_W3_pop_rur 84375675
global Ethiopia_ESS_W3_pop_urb 20917553


********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables


********************************************************************************
*HOUSEHOLD IDS
********************************************************************************
use "$Ethiopia_ESS_W3_raw_data/sect1_hh_W3.dta", clear
ren hh_s1q04a age
ren hh_s1q03 gender
gen fhh = gender==2 if hh_s1q02==1	 
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
collapse (sum) hh_members adulteq (max) fhh, by (household_id2)

merge 1:1 household_id2 using "$Ethiopia_ESS_W3_raw_data/sect_cover_hh_w3.dta", nogen keep (1 3)
ren saq01 region
ren saq02 zone
ren saq03 woreda
ren saq04 town
ren saq05 subcity
ren saq06 kebele
ren saq07 ea
ren saq08 household
ren pw_w3 weight
ren rural rural2
gen rural = (rural2==1)
lab var rural "1=Rural"
keep region zone woreda town subcity kebele ea household rural household_id2 weight fhh hh_members adulteq

*Generating the variable that indicate the level of representativness of the survey (to use for reporting summary stats)
gen level_representativness=.
replace level_representativness=1 if region==1
replace level_representativness=2 if region==3 
replace level_representativness=3 if region==4 
replace level_representativness=4 if region==7 
replace level_representativness=5 if region==2
replace level_representativness=5 if region==5 
replace level_representativness=5 if region==6 
replace level_representativness=5 if region==12 
replace level_representativness=5 if region==13
replace level_representativness=5 if region==15 
replace level_representativness=6 if region==14 

lab define lrep 1 "Tigray"  ///
                2 "Amhara"  ///
                3 "Oromia"  ///
                4 "SNNP"    ///
                5 "Other regions" ///
                6 "Addis Ababa" ///
						
lab var level_representativness "Level of representivness of the survey"						
lab value level_representativness	lrep
tab level_representativness

****Currency Conversion Factors****
gen ccf_loc = (1 + $Ethiopia_ESS_W3_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $SHL"
gen ccf_usd = (1 + $Ethiopia_ESS_W3_inflation)/$Ethiopia_ESS_W3_exchange_rate 
lab var ccf_usd "currency conversion factor - 2017 $USD"
gen ccf_1ppp = (1 + $Ethiopia_ESS_W3_inflation)/ $Ethiopia_ESS_W3_cons_ppp_dollar
lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Ethiopia_ESS_W3_inflation)/ $Ethiopia_ESS_W3_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"					
save "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_hhids.dta", replace

********************************************************************************
*CONSUMPTION
******************************************************************************** 
use "${Ethiopia_ESS_W3_raw_data}/sect5a_hh_w3.dta", clear
merge m:1 household_id2 using "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_hhids.dta", nogen keep (1 3)
*label list HH_J00
ren item_cd item_code
gen crop_category1=""					
replace crop_category1=	"Teff"		if  item_code==	1
replace crop_category1=	"Wheat"		if  item_code==	2
replace crop_category1=	"Other Cereals"		if  item_code==	3
replace crop_category1=	"Maize"		if  item_code==	4
replace crop_category1=	"Millet and Sorghum"		if  item_code==	5
replace crop_category1=	"Millet and Sorghum"		if  item_code==	6
replace crop_category1=	"Pulses"		if  item_code==	7
replace crop_category1=	"Pulses"		if  item_code==	8
replace crop_category1=	"Pulses"		if  item_code==	9
replace crop_category1=	"Pulses"		if  item_code==	10
replace crop_category1=	"Pulses"		if  item_code==	11
replace crop_category1=	"Nuts and Seeds"		if  item_code==	12
replace crop_category1=	"Nuts and Seeds"		if  item_code==	13
replace crop_category1=	"Vegetables"		if  item_code==	14
replace crop_category1=	"Bananas and Plantains"		if  item_code==	15
replace crop_category1=	"Potato"		if  item_code==	16
replace crop_category1=	"Bananas and Plantains"		if  item_code==	17
replace crop_category1=	"Dairy"		if  item_code==	19
replace crop_category1=	"Dairy"		if  item_code==	20
replace crop_category1=	"Eggs"		if  item_code==	21
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	22
replace crop_category1=	"Spices"		if  item_code==	23
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	24
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	25
replace crop_category1=	"Bananas and Plantains"		if  item_code==	26
replace crop_category1=	"Other Cereals"		if  item_code==	60
replace crop_category1=	"Groundnuts"		if  item_code==	110
replace crop_category1=	"Pulses"		if  item_code==	111
replace crop_category1=	"Nuts and Seeds"		if  item_code==	131
replace crop_category1=	"Vegetables"		if  item_code==	141
replace crop_category1=	"Vegetables"		if  item_code==	142
replace crop_category1=	"Vegetables"		if  item_code==	143
replace crop_category1=	"Vegetables"		if  item_code==	144
replace crop_category1=	"Vegetables"		if  item_code==	145
replace crop_category1=	"Fruits"		if  item_code==	151
replace crop_category1=	"Fruits"		if  item_code==	152
replace crop_category1=	"Sweet Potato"		if  item_code==	170
replace crop_category1=	"Yams"		if  item_code==	171
replace crop_category1=	"Cassava"		if  item_code==	172
replace crop_category1=	"Yams"		if  item_code==	173
replace crop_category1=	"Other Roots and Tubers"		if  item_code==	174
replace crop_category1=	"Lamb and Goat Meat"		if  item_code==	180
replace crop_category1=	"Beef Meat"		if  item_code==	181
replace crop_category1=	"Poultry Meat"		if  item_code==	182
replace crop_category1=	"Fish and Seafood"		if  item_code==	183
replace crop_category1=	"Teff"		if  item_code==	195
replace crop_category1=	"Wheat"		if  item_code==	196
replace crop_category1=	"Wheat"		if  item_code==	197
replace crop_category1=	"Other Food"		if  item_code==	198
replace crop_category1=	"Oils, Fats"		if  item_code==	201
replace crop_category1=	"Oils, Fats"		if  item_code==	202
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	203
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	204
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	205
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	206
replace crop_category1=	"Other Cereals"		if  item_code==	901
replace crop_category1=	"Pulses"		if  item_code==	902
replace crop_category1=	"Nuts and Seeds"		if  item_code==	903
replace crop_category1=	"Oils, Fats"		if  item_code==	904
replace crop_category1=	"Pulses"		if  item_code==	905
replace crop_category1=	"Fruits"		if  item_code==	906
replace crop_category1=	"Fruits"		if  item_code==	907
replace crop_category1=	"Vegetables"		if  item_code==	908
replace crop_category1=	"Vegetables"		if  item_code==	909
replace crop_category1=	"Vegetables"		if  item_code==	910
replace crop_category1=	"Vegetables"		if  item_code==	911
replace crop_category1=	"Vegetables"		if  item_code==	912
replace crop_category1=	"Vegetables"		if  item_code==	913
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	914
replace crop_category1=	"Fruits"		if  item_code==	915




ren hh_s5aq01 food_consu_yesno
ren hh_s5aq02_b food_consu_unit
ren hh_s5aq02_a food_consu_qty
ren hh_s5aq03_b food_purch_unit
ren hh_s5aq03_a food_purch_qty
ren hh_s5aq04 food_purch_value
ren hh_s5aq05_a food_prod_qty
ren hh_s5aq05_b food_prod_unit
ren hh_s5aq06_a food_gift_qty
ren hh_s5aq06_b food_gift_unit

replace food_consu_qty=food_consu_qty/1000 if food_consu_unit==2 | food_consu_unit==5
replace food_purch_qty=food_purch_qty/1000 if food_purch_unit==2 | food_purch_unit==5
replace food_prod_qty=food_prod_qty/1000 if food_prod_unit==2 | food_prod_unit==5
replace food_gift_qty=food_gift_qty/1000 if food_gift_unit==2 | food_gift_unit==5

replace food_consu_qty=food_consu_qty*100 if food_consu_unit==3
replace food_purch_qty=food_purch_qty*100 if food_purch_unit==3
replace food_prod_qty=food_prod_qty*100 if food_prod_unit==3
replace food_gift_qty=food_gift_qty*100 if food_gift_unit==3
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (2 3 =1 ) (5 =4)  // grams and quintal in kg and mili in liter


keep if food_consu_yesno==1
drop if food_consu_qty==0  | food_consu_qty==.
*Imput the value of consumption using prices infered from the quantity of purchase and the value of pruchases.
gen price_unit= food_purch_value/food_purch_qty
recode price_unit (0=.)

save "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_consumption_purchase.dta", replace
 

use "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region zone woreda town subcity kebele ea item_code food_purch_unit: egen obs_ea = count(observation)
collapse (median) price_unit [aw=weight], by (region zone woreda town subcity kebele ea item_code food_purch_unit obs_ea)
ren price_unit price_unit_median_ea
lab var price_unit_median_ea "Median price per kg for this crop in the enumeration area"
lab var obs_ea "Number of observations for this crop in the enumeration area"
save "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_ea.dta", replace

use "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region zone woreda town subcity kebele item_code food_purch_unit: egen obs_kebele = count(observation)
collapse (median) price_unit [aw=weight], by (region zone woreda town subcity kebele item_code food_purch_unit obs_kebele)
ren price_unit price_unit_median_kebele
lab var price_unit_median_kebele "Median price per kg for this crop in the kebele"
lab var obs_kebele "Number of observations for this crop in the kebele"
save "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_kebele.dta", replace

use "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region zone woreda town subcity item_code food_purch_unit: egen obs_subcity = count(observation)
collapse (median) price_unit [aw=weight], by (region zone woreda town subcity  item_code food_purch_unit obs_subcity)
ren price_unit price_unit_median_subcity
lab var price_unit_median_subcity "Median price per kg for this crop in the subcity"
lab var obs_subcity "Number of observations for this crop in the subcity"
save "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_subcity.dta", replace


use "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region zone woreda town item_code food_purch_unit: egen obs_town = count(observation)
collapse (median) price_unit [aw=weight], by (region zone woreda town item_code food_purch_unit obs_town)
ren price_unit price_unit_median_town
lab var price_unit_median_town "Median price per kg for this crop in the town"
lab var obs_town "Number of observations for this crop in the town"
save "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_town.dta", replace

use "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region zone woreda item_code food_purch_unit: egen obs_woreda = count(observation)
collapse (median) price_unit [aw=weight], by (region zone woreda item_code food_purch_unit obs_woreda)
ren price_unit price_unit_median_woreda
lab var price_unit_median_woreda "Median price per kg for this crop in the woreda"
lab var obs_woreda "Number of observations for this crop in the woreda"
save "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_woreda.dta", replace

 
use "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region zone item_code food_purch_unit: egen obs_zone = count(observation)
collapse (median) price_unit [aw=weight], by (region zone item_code food_purch_unit obs_zone)
ren price_unit price_unit_median_zone
lab var price_unit_median_zone "Median price per kg for this crop in the zone"
lab var obs_zone "Number of observations for this crop in the zone"
save "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_zone.dta", replace

use "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region item_code food_purch_unit: egen obs_region = count(observation)
collapse (median) price_unit [aw=weight], by (region item_code food_purch_unit obs_region)
ren price_unit price_unit_median_region
lab var price_unit_median_region "Median price per kg for this crop in the region"
lab var obs_region "Number of observations for this crop in the region"
save "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_region.dta", replace

use "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys item_code food_purch_unit: egen obs_country = count(observation)
collapse (median) price_unit [aw=weight], by (item_code food_purch_unit obs_country)
ren price_unit price_unit_median_country
lab var price_unit_median_country "Median price per kg for this crop in the country"
lab var obs_country "Number of observations for this crop in the country"
save "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_country.dta", replace


*Pull prices into consumption estimates
use "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_consumption_purchase.dta", clear
merge m:1 household_id2 using "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_hhids.dta", nogen keep(1 3)
recode food_consu_unit (7=.)  

* Value consumption, production, and given when the units does not match the units of purchased
foreach f in consu prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit==food_purch_unit


*- using EA medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region zone woreda town subcity kebele ea item_code food_purch_unit using "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_ea.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_ea if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_ea>10 & obs_ea!=.

*- using Kebele medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region zone woreda town subcity kebele item_code food_purch_unit using "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_kebele.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_kebele if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_kebele>10 & obs_kebele!=.

*- using Subcity medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region zone woreda town subcity item_code food_purch_unit using "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_subcity.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_subcity if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_subcity>10 & obs_subcity!=.

*- using Town medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region zone woreda town item_code food_purch_unit using "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_town.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_town if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_town>10 & obs_town!=.

*- using Woreda medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region zone woreda item_code food_purch_unit using "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_woreda.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_woreda if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_woreda>10 & obs_woreda!=.

*- using Zone medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region zone item_code food_purch_unit using "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_zone.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_zone if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_zone>10 & obs_zone!=.

*- using Region medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region item_code food_purch_unit using "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_region.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_region if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_region>10 & obs_region!=.

*- using Country medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 item_code food_purch_unit using "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_item_prices_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_country>10 & obs_country!=.

keep household_id2 item_code crop_category1 food_`f'_value
save "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_consumption_purchase_`f'.dta", replace
restore
}

merge 1:1  household_id2 item_code crop_category1  using "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_consumption_purchase_consu.dta", nogen
merge 1:1  household_id2 item_code crop_category1  using "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_consumption_purchase_prod.dta", nogen
merge 1:1  household_id2 item_code crop_category1  using "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_consumption_purchase_gift.dta", nogen

collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(household_id2 crop_category1)
recode  food_consu_value food_purch_value food_prod_value food_gift_value (.=0)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_food_home_consumption_value.dta", replace


use "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_food_home_consumption_value.dta", clear
merge m:1 household_id2 using "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_hhids.dta", nogen keep(1 3)
ren household_id2 hhid

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


save "${Ethiopia_ESS_W3_created_data}/Ethiopia_ESS_W3_food_consumption_value.dta", replace  



*RESCALING the components of consumption such that the sum always match
** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value {
	_pctile `v' [aw=weight] if `v'!=0 , p($wins_upper_thres)  
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
}

ren region adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province"
ren zone adm2
lab var adm2 "Adminstrative subdivision 2 - lga/zone/district/municipality"
ren woreda adm3
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="Ethiopia"
lab var Country "Country name"
qui gen Instrument="Ethiopia LSMS-ISA/ESS W3"
lab var Instrument "Survey name"
qui gen Year="2015/16"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

*generate GID_1 code to match codes in the Ethiopia shapefile
gen GID_1=""
replace GID_1="ETH.1_1"  if adm1==14
replace GID_1="ETH.2_1"  if adm1==2
replace GID_1="ETH.3_1"  if adm1==3
replace GID_1="ETH.4_1"  if adm1==6
replace GID_1="ETH.5_1"  if adm1==15
replace GID_1="ETH.6_1"  if adm1==12
replace GID_1="ETH.7_1"  if adm1==13
replace GID_1="ETH.8_1"  if adm1==4
replace GID_1="ETH.9_1"  if adm1==5
replace GID_1="ETH.10_1"  if adm1==7
replace GID_1="ETH.11_1"  if adm1==1
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
replace conv_lcu_ppp=	0.138909853	if Instrument==	"Ethiopia LSMS-ISA/ESS W3"

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
save "${final_data}/Ethiopia_ESS_W3_food_consumption_value_by_source.dta", replace


*****End of Do File*****



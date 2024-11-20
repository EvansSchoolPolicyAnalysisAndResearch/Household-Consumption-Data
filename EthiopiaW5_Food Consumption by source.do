/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Ethiopia Socioeconomic Survey (ESS) LSMS-ISA Wave 5 (2021-22)

*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Ethiopia Socioeconomic Survey was collected by the Ethiopia Central Statistical Agency (CSA) 
*and the World Bank's Living Standards Measurement Study - Integrated Surveys on Agriculture(LSMS - ISA)
*The data were collected over the period September 2021 - January 2022, April - June 2022.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://microdata.worldbank.org/index.php/catalog/6161


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Ethiopia ESS dataset.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, rural location indicator, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Ethiopia_ESS_W5_hhids.dta
*Food Consumption by source			Ethiopia_ESS_W5_food_consumption_value_by_source.dta

*/



clear
clear matrix
clear mata
set more off
set maxvar 10000		
ssc install findname 

*Set location of raw data and output
global directory 					"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/335 - Ag Team Data Support/Waves"

*Set directories
global Ethiopia_ESS_W5_raw_data			"$directory/Ethiopia ESS/Ethiopia ESS Wave 5/Raw DTA Files"
global Ethiopia_ESS_W5_created_data		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"



********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN USD IDS
********************************************************************************
global Ethiopia_ESS_W5_exchange_rate 23.87 // 2017 - updated SRK 7.3.24 // https://data.worldbank.org/indicator/PA.NUS.FCRF?end=2023&locations=ET&skipRedirection=true&start=2007&year=2017 
global Ethiopia_ESS_W5_gdp_ppp_dollar 8.34 	// 2017 - updated SRK 7.3.24 // https://data.worldbank.org/indicator/PA.NUS.PPP?end=2023&locations=ET&skipRedirection=true&start=2010&view=chart&year=2017
global Ethiopia_ESS_W5_cons_ppp_dollar 8.21	 // 2017 - updated SRK 7.3.24 // https://data.worldbank.org/indicator/PA.NUS.PRVT.PP?end=2017&locations=ET&start=2011
global Ethiopia_ESS_W5_inflation -0.62894417 // (CPI_2017-CPI_SURVEY_YEAR/CPI_SURVEY_YEAR) -> (CPI_2017-CPI_2022/CPI_2022) - updated SRK 7.3.24 // https://data.worldbank.org/indicator/FP.CPI.TOTL?end=2023&locations=ET&start=2009


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Ethiopia_ESS_W5_pop_tot 123379924 //2022
global Ethiopia_ESS_W5_pop_rur 95420799 // 2022
global Ethiopia_ESS_W5_pop_urb 27959125 // 2022


********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables


********************************************************************************
*HOUSEHOLD IDS
********************************************************************************
use "$Ethiopia_ESS_W5_raw_data/sect1_hh_W5.dta", clear

ren s1q03a age
ren s1q02 gender
gen fhh = gender==2 if s1q01==1	 
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

gen age_hh= age if s1q01==1
lab var age_hh "Age of household head"
gen nadultworking=1 if age>=18 & age<65
lab var nadultworking "Number of working age adults"
gen nadultworking_female=1 if age>=18 & age<65 & gender==2 
lab var nadultworking_female "Number of working age female adults"
gen nadultworking_male=1 if age>=18 & age<65 & gender==1 
lab var nadultworking_male "Number of working age male adults"
gen nchildren=1 if age<=17
lab var nchildren "Number of children"
gen nelders=1 if age>=65
lab var nelders "Number of elders"
ren pw_w5 weight

collapse (sum) hh_members adulteq nadultworking nadultworking_female nadultworking_male nchildren nelders (max) fhh weight age_hh, by (household_id)

merge 1:1 household_id using "$Ethiopia_ESS_W5_raw_data/sect_cover_hh_W5.dta", nogen keep (1 3)
ren saq01 region
ren saq02 zone
ren saq03 woreda
ren saq04 city
ren saq05 subcity
ren saq06 kebele
ren saq07 ea
ren saq08 household
gen rural=(saq14==1)
lab var rural "1= Rural"
/*
ren InterviewStart first_interview_date
gen interview_year=substr(first_interview_date ,1,4)
gen interview_month=substr(first_interview_date,6,2)
gen interview_day=substr(first_interview_date,9,2)
lab var interview_day "Survey interview day"
lab var interview_month "Survey interview month"
lab var interview_year "Survey interview year"
*/
keep region zone woreda city subcity kebele ea household weight rural household_id fhh hh_members adulteq age_hh nadultworking nadultworking_female nadultworking_male nchildren nelders
destring region zone woreda, replace

*Generating the variable that indicate the level of representativness of the survey (to use for reporting summary stats)
gen level_representativness=.
replace level_representativness=11 if region==1 & rural==1
replace level_representativness=12 if region==1 & rural==0
replace level_representativness=21 if region==2 & rural==1
replace level_representativness=22 if region==2 & rural==0
replace level_representativness=31 if region==3 & rural==1
replace level_representativness=32 if region==3 & rural==0
replace level_representativness=41 if region==4 & rural==1
replace level_representativness=42 if region==4 & rural==0
replace level_representativness=51 if region==5 & rural==1
replace level_representativness=52 if region==5 & rural==0
replace level_representativness=61 if region==6 & rural==1
replace level_representativness=62 if region==6 & rural==0
replace level_representativness=71 if region==7 & rural==1
replace level_representativness=72 if region==7 & rural==0
replace level_representativness=121 if region==12 & rural==1
replace level_representativness=122 if region==12 & rural==0
replace level_representativness=131 if region==13 & rural==1
replace level_representativness=132 if region==13 & rural==0
replace level_representativness=141 if region==14 & rural==1
replace level_representativness=142 if region==14 & rural==0
replace level_representativness=151 if region==15 & rural==1
replace level_representativness=152 if region==15 & rural==0

lab define lrep 11 "Tigray - Rural"  ///
                12 "Tigray - Urban"  ///
                21 "Afar - Rural"   ///
                22 "Afar - Urban"  ///
                31 "Amhara - Rural"  ///
                32 "Amhara - Urban"  ///
				41 "Oromia - Rural"  ///
                42 "Oromia - Urban"  ///
                51 "Somali - Rural" ///
                52 "Somali - Urban" ///
                61 "Benishangul Gumuz - Rural"  ///
                62 "Benishangul Gumuz - Urban"  ///  
                71 "SNNP - Rural" ///
                72 "SNNP - Urban" ///
                121 "Gambela - Rural" ///
                122 "Gambela - Urban" ///
                131 "Hareri - Rural" ///
                132 "Hareri - Urban" ///
                141 "Addis Ababa - Rural" ///
                142 "Addis Ababa - Urban" ///
                151 "Dire Dawa - Rural" ///
                152 "Dire Dawa - Urban" ///
						
lab var level_representativness "Level of representivness of the survey"						
lab value level_representativness	lrep
tab level_representativness

****Currency Conversion Factors****
gen ccf_loc = (1 + $Ethiopia_ESS_W5_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $SHL"
gen ccf_usd = (1 + $Ethiopia_ESS_W5_inflation)/$Ethiopia_ESS_W5_exchange_rate 
lab var ccf_usd "currency conversion factor - 2017 $USD"
gen ccf_1ppp = (1 + $Ethiopia_ESS_W5_inflation)/ $Ethiopia_ESS_W5_cons_ppp_dollar
lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Ethiopia_ESS_W5_inflation)/ $Ethiopia_ESS_W5_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"
ren household_id hhid					
save "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_hhids.dta", replace

********************************************************************************
*CONSUMPTION
******************************************************************************** 
use "${Ethiopia_ESS_W5_raw_data}/sect6a_hh_w5.dta", clear
ren household_id hhid
merge m:1 hhid using "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_hhids.dta", nogen keep (1 3)

*label list HH_J00
ren item_cd item_code
gen crop_category1=""				
replace crop_category1=	"Teff"		if  item_code==	101
replace crop_category1=	"Wheat"		if  item_code==	102
replace crop_category1=	"Other Cereals"		if  item_code==	103
replace crop_category1=	"Maize"		if  item_code==	104
replace crop_category1=	"Millet and Sorghum"		if  item_code==	105
replace crop_category1=	"Millet and Sorghum"		if  item_code==	106
replace crop_category1=	"Rice"		if  item_code==	107
replace crop_category1=	"Other Cereals"		if  item_code==	108
replace crop_category1=	"Other Cereals"		if  item_code==	109
replace crop_category1=	"Pulses"		if  item_code==	201
replace crop_category1=	"Pulses"		if  item_code==	202
replace crop_category1=	"Pulses"		if  item_code==	203
replace crop_category1=	"Pulses"		if  item_code==	204
replace crop_category1=	"Pulses"		if  item_code==	205
replace crop_category1=	"Groundnuts"		if  item_code==	206
replace crop_category1=	"Pulses"		if  item_code==	207
replace crop_category1=	"Pulses"		if  item_code==	208
replace crop_category1=	"Pulses"		if  item_code==	209
replace crop_category1=	"Pulses"		if  item_code==	210
replace crop_category1=	"Pulses"		if  item_code==	211
replace crop_category1=	"Nuts and Seeds"		if  item_code==	301
replace crop_category1=	"Nuts and Seeds"		if  item_code==	302
replace crop_category1=	"Nuts and Seeds"		if  item_code==	303
replace crop_category1=	"Oils, Fats"		if  item_code==	304
replace crop_category1=	"Nuts and Seeds"		if  item_code==	305
replace crop_category1=	"Vegetables"		if  item_code==	401
replace crop_category1=	"Vegetables"		if  item_code==	402
replace crop_category1=	"Vegetables"		if  item_code==	403
replace crop_category1=	"Vegetables"		if  item_code==	404
replace crop_category1=	"Vegetables"		if  item_code==	405
replace crop_category1=	"Vegetables"		if  item_code==	406
replace crop_category1=	"Vegetables"		if  item_code==	407
replace crop_category1=	"Vegetables"		if  item_code==	408
replace crop_category1=	"Bananas and Plantains"		if  item_code==	501
replace crop_category1=	"Fruits"		if  item_code==	502
replace crop_category1=	"Fruits"		if  item_code==	503
replace crop_category1=	"Fruits"		if  item_code==	504
replace crop_category1=	"Fruits"		if  item_code==	505
replace crop_category1=	"Fruits"		if  item_code==	506
replace crop_category1=	"Potato"		if  item_code==	601
replace crop_category1=	"Bananas and Plantains"		if  item_code==	602
replace crop_category1=	"Bananas and Plantains"		if  item_code==	603
replace crop_category1=	"Sweet Potato"		if  item_code==	604
replace crop_category1=	"Yams"		if  item_code==	605
replace crop_category1=	"Cassava"		if  item_code==	606
replace crop_category1=	"Yams"		if  item_code==	607
replace crop_category1=	"Vegetables"		if  item_code==	608
replace crop_category1=	"Vegetables"		if  item_code==	609
replace crop_category1=	"Other Roots and Tubers"		if  item_code==	610
replace crop_category1=	"Lamb and Goat Meat"		if  item_code==	701
replace crop_category1=	"Beef Meat"		if  item_code==	702
replace crop_category1=	"Poultry Meat"		if  item_code==	703
replace crop_category1=	"Fish and Seafood"		if  item_code==	704
replace crop_category1=	"Dairy"		if  item_code==	705
replace crop_category1=	"Dairy"		if  item_code==	706
replace crop_category1=	"Oils, Fats"		if  item_code==	707
replace crop_category1=	"Oils, Fats"		if  item_code==	708
replace crop_category1=	"Eggs"		if  item_code==	709
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	710
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	711
replace crop_category1=	"Spices"		if  item_code==	712
replace crop_category1=	"Spices"		if  item_code==	713
replace crop_category1=	"Other Meat"		if  item_code==	714
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	801
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	802
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	803
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	804
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	805
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	806
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	807
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	808
replace crop_category1=	"Teff"		if  item_code==	901
replace crop_category1=	"Wheat"		if  item_code==	902
replace crop_category1=	"Wheat"		if  item_code==	903
replace crop_category1=	"Other Food"		if  item_code==	904

ren s6aq01 food_consu_yesno
ren s6aq02b food_consu_unit
ren s6aq02a food_consu_qty
ren s6aq03b food_purch_unit
ren s6aq03a food_purch_qty
ren s6aq04 food_purch_value
ren s6aq05a food_prod_qty
ren s6aq05b food_prod_unit
ren s6aq06a food_gift_qty
ren s6aq06b food_gift_unit

replace food_consu_qty=food_consu_qty/1000 if food_consu_unit==2 | food_consu_unit==5
replace food_purch_qty=food_purch_qty/1000 if food_purch_unit==2 | food_purch_unit==5
replace food_prod_qty=food_prod_qty/1000 if food_prod_unit==2 | food_prod_unit==5
replace food_gift_qty=food_gift_qty/1000 if food_gift_unit==2 | food_gift_unit==5

replace food_consu_qty=food_consu_qty*100 if food_consu_unit==3
replace food_purch_qty=food_purch_qty*100 if food_purch_unit==3
replace food_prod_qty=food_prod_qty*100 if food_prod_unit==3
replace food_gift_qty=food_gift_qty*100 if food_gift_unit==3
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (2=1 ) (5=4)  // gramns and quintal in kg and mili in liter


keep if food_consu_yesno==1
drop if food_consu_qty==0  | food_consu_qty==.
*Input the value of consumption using prices infered from the quantity of purchase and the value of pruchases.
gen price_unit= food_purch_value/food_purch_qty
recode price_unit (0=.)

save "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_consumption_purchase.dta", replace
 

use "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region zone woreda subcity kebele ea item_code food_purch_unit: egen obs_ea = count(observation)
collapse (median) price_unit [aw=weight], by (region zone woreda subcity kebele ea item_code food_purch_unit obs_ea)
ren price_unit price_unit_median_ea
lab var price_unit_median_ea "Median price per kg for this crop in the enumeration area"
lab var obs_ea "Number of observations for this crop in the enumeration area"
save "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_item_prices_ea.dta", replace

use "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region zone woreda subcity kebele item_code food_purch_unit: egen obs_kebele = count(observation)
collapse (median) price_unit [aw=weight], by (region zone woreda subcity kebele item_code food_purch_unit obs_kebele)
ren price_unit price_unit_median_kebele
lab var price_unit_median_kebele "Median price per kg for this crop in the kebele"
lab var obs_kebele "Number of observations for this crop in the kebele"
save "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_item_prices_kebele.dta", replace

use "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region zone woreda subcity item_code food_purch_unit: egen obs_subcity = count(observation)
collapse (median) price_unit [aw=weight], by (region zone woreda subcity  item_code food_purch_unit obs_subcity)
ren price_unit price_unit_median_subcity
lab var price_unit_median_subcity "Median price per kg for this crop in the subcity"
lab var obs_subcity "Number of observations for this crop in the subcity"
save "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_item_prices_subcity.dta", replace


use "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region zone woreda item_code food_purch_unit: egen obs_woreda = count(observation)
collapse (median) price_unit [aw=weight], by (region zone woreda item_code food_purch_unit obs_woreda)
ren price_unit price_unit_median_woreda
lab var price_unit_median_woreda "Median price per kg for this crop in the woreda"
lab var obs_woreda "Number of observations for this crop in the woreda"
save "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_item_prices_woreda.dta", replace

 
use "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region zone item_code food_purch_unit: egen obs_zone = count(observation)
collapse (median) price_unit [aw=weight], by (region zone item_code food_purch_unit obs_zone)
ren price_unit price_unit_median_zone
lab var price_unit_median_zone "Median price per kg for this crop in the zone"
lab var obs_zone "Number of observations for this crop in the zone"
save "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_item_prices_zone.dta", replace

use "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region item_code food_purch_unit: egen obs_region = count(observation)
collapse (median) price_unit [aw=weight], by (region item_code food_purch_unit obs_region)
ren price_unit price_unit_median_region
lab var price_unit_median_region "Median price per kg for this crop in the region"
lab var obs_region "Number of observations for this crop in the region"
save "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_item_prices_region.dta", replace

use "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys item_code food_purch_unit: egen obs_country = count(observation)
collapse (median) price_unit [aw=weight], by (item_code food_purch_unit obs_country)
ren price_unit price_unit_median_country
lab var price_unit_median_country "Median price per kg for this crop in the country"
lab var obs_country "Number of observations for this crop in the country"
save "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_item_prices_country.dta", replace


*Pull prices into consumption estimates
use "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_consumption_purchase.dta", clear
merge m:1 hhid using "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_hhids.dta", nogen keep(1 3)
recode food_consu_unit (7=.)  

* Value consumption, production, and given when the units does not match the units of purchased

foreach f in consu prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit==food_purch_unit


*- using EA medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region zone woreda subcity kebele ea item_code food_purch_unit using "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_item_prices_ea.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_ea if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_ea>10 & obs_ea!=.

*- using Kebele medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region zone woreda subcity kebele item_code food_purch_unit using "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_item_prices_kebele.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_kebele if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_kebele>10 & obs_kebele!=.

*- using Subcity medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region zone woreda subcity item_code food_purch_unit using "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_item_prices_subcity.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_subcity if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_subcity>10 & obs_subcity!=.


*- using Woreda medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region zone woreda item_code food_purch_unit using "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_item_prices_woreda.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_woreda if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_woreda>10 & obs_woreda!=.

*- using Zone medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region zone item_code food_purch_unit using "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_item_prices_zone.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_zone if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_zone>10 & obs_zone!=.

*- using Region medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region item_code food_purch_unit using "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_item_prices_region.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_region if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_region>10 & obs_region!=.

*- using Country medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 item_code food_purch_unit using "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_item_prices_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid item_code crop_category1 food_`f'_value 
save "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_consumption_purchase_`f'.dta", replace
restore
}

merge 1:1  hhid item_code crop_category1  using "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_consumption_purchase_consu.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_consumption_purchase_prod.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_consumption_purchase_gift.dta", nogen


collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid crop_category1)
recode  food_consu_value food_purch_value food_prod_value food_gift_value (.=0)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_food_home_consumption_value.dta", replace

sum food_consu_value food_purch_value food_prod_value food_gift_value


use "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_food_home_consumption_value.dta", clear
merge m:1 hhid using "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_hhids.dta", nogen keep(1 3)

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

save "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_food_consumption_value.dta", replace  



*RESCALING the components of consumption such that the sum always match
** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value /*food_consu_valueR food_purch_valueR food_prod_valueR  food_gift_valueR */{
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
qui gen Instrument="Ethiopia LSMS-ISA/ESS W5"
lab var Instrument "Survey name"
qui gen Year="2021/22"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq age_hh nadultworking nadultworking_female nadultworking_male nchildren nelders fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

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
merge m:1 hhid using "${Ethiopia_ESS_W5_created_data}/Ethiopia_ESS_W5_hhids.dta", nogen keepusing(ccf_1ppp ccf_2ppp)
gen conv_lcu_ppp=.
lab var conv_lcu_ppp "Conversion Factor"		
replace conv_lcu_ppp=	ccf_2ppp	if Instrument==	"Ethiopia LSMS-ISA/ESS W5" // SRK update. Prior value = 0.058482723

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
save "${final_data}/Ethiopia_ESS_W5_food_consumption_value_by_source.dta", replace


*****End of Do File*****



/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Ghana Socioeconomic Panel Survey 2009/10

*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Ghana Socioeconomic Panel Survey was collected by the Economic Growth Centre at Yale University and the Institute of Statistical, Social and Economic Research (ISSER), at the University of Ghana (Legon, Ghana). 
*The data were collected over the period November 2009 - April 2010.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://microdata.worldbank.org/index.php/catalog/2534


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Ghana SPS dataset.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, rural location indicator, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Ghana_SPS_W1_hhids.dta
*Food Consumption by source			Ghana_SPS_W1_food_consumption_value_by_source.dta

*/



clear
clear matrix
clear mata
program drop _all
set more off
set maxvar 10000


*Set location of raw data and output
global directory			    "//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Non-LSMS Datasets"

//set directories
*Nigeria General HH survey (NG LSMS)  Wave 3

global Ghana_SPS_W1_raw_data 			"$directory/Ghana SPS/Ghana SPS 2009-10/Raw DTA Files"
global Ghana_SPS_W1_created_data 		"$directory/Ghana SPS/Ghana SPS 2009-10/Final DTA Files/created_data"
*global final_data  		"$directory/Ghana SPS/Ghana SPS 2009-10/Final DTA Files/final_data"

global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"

********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN USD
********************************************************************************
global Ghana_SPS_W1_exchange_rate 4.35		// https://data.worldbank.org/indicator/PA.NUS.FCRF?locations=GH
global Ghana_SPS_W1_gdp_ppp_dollar 1.76		// https://data.worldbank.org/indicator/PA.NUS.PPP
global Ghana_SPS_W1_cons_ppp_dollar 1.75		// https://data.worldbank.org/indicator/PA.NUS.PRVT.PP?locations=GH
global Ghana_SPS_W1_inflation 1.67		// inflation rate 2009-2017. Data was collected during 2012-2013. We want to ajhust value to 2017 https://data.worldbank.org/indicator/FP.CPI.TOTL?locations=GH


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Ghana_SPS_W1_pop_tot 30222262
global Ghana_SPS_W1_pop_rur 13477013
global Ghana_SPS_W1_pop_urb 16745249


********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables


********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${Ghana_SPS_W1_raw_data}/S1D.dta", clear
ren s1d_4i age
ren s1d_1 gender
codebook s1d_2, tab(100)
gen fhh = gender==2 & s1d_2==1
lab var fhh "1= Female-headed Household"
gen hh_members = 1 
keep if hh_members==1
lab var hh_members "Number of household members"
gen adulteq=.
replace adulteq=0.4 if (age<3 & age>=0)				//1=male, 2=female
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

gen age_hh= age if s1d_2==1
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

collapse (max) fhh age_hh (sum) hh_members (sum) adulteq nadultworking nadultworking_female nadultworking_male nchildren nelders, by(hhno)

merge 1:m hhno using "${Ghana_SPS_W1_raw_data}/key_hhld_info.dta", nogen keep (1 3)

ren hhno hhid
ren id1 region
ren id2 district
ren id3 ea
ren  hhweight3 weight
gen rural = (urbrur==2)
lab var rural "1= Rural"

keep hhid region district ea weight rural fhh hh_members adulteq age_hh nadultworking nadultworking_female nadultworking_male nchildren nelders

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
replace level_representativness=81 if region==8 & rural==1
replace level_representativness=82 if region==8 & rural==0
replace level_representativness=91 if region==9 & rural==1
replace level_representativness=92 if region==9 & rural==0
replace level_representativness=101 if region==10 & rural==1
replace level_representativness=102 if region==10 & rural==0

lab define lrep 11 "Western - Rural"  ///
                12 "Western - Urban"  ///
                21 "Central - Rural"   ///
                22 "Central - Urban"  ///
                31 "Greater Accra - Rural"  ///
                32 "Greater Accra - Urban"  ///
				41 "Volta - Rural"  ///
                42 "Volta - Urban"  ///
                51 "Eastern - Rural" ///
                52 "Eastern - Urban" ///
                61 "Ashanti - Rural"  ///
                62 "Ashanti - Urban"   /// 
                71 "Brong Ahafo - Rural"  ///
                72 "Brong Ahafo - Urban" ///   
                81 "Northern - Rural"  ///
                82 "Northern - Urban"   /// 
                91 "Upper East - Rural"  ///
                92 "Upper East - Urban"  ///  
                101 "Upper West - Rural"  ///
                102 "Upper West - Urban"  ///  
						
lab value level_representativness	lrep
tab level_representativness

****Currency Conversion Factors****
gen ccf_loc = (1 + $Ghana_SPS_W1_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $SHL"
gen ccf_usd = (1 + $Ghana_SPS_W1_inflation)/$Ghana_SPS_W1_exchange_rate 
lab var ccf_usd "currency conversion factor - 2017 $USD"
gen ccf_1ppp = (1 + $Ghana_SPS_W1_inflation)/ $Ghana_SPS_W1_cons_ppp_dollar
lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Ghana_SPS_W1_inflation)/ $Ghana_SPS_W1_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"
							
save  "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_hhids.dta", replace


********************************************************************************
*CONSUMPTION
******************************************************************************** 
*planting
use "${Ghana_SPS_W1_raw_data}/consumption_expenditure.dta", clear
ren hhno hhid
merge m:1 hhid using "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_hhids.dta", nogen keep (1 3)

*label list item_cd
ren itname item_code

gen crop_category1=""				
				
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	"ALCHOHOLIC BEVERAGES"
replace crop_category1=	"Fruits"		if  item_code==	"APPLE"
replace crop_category1=	"Fruits"		if  item_code==	"AVOCADO PEAR"
replace crop_category1=	"Dairy"		if  item_code==	"BABY FOOD"
replace crop_category1=	"Dairy"		if  item_code==	"BABY MILK"
replace crop_category1=	"Bananas and Plantains"		if  item_code==	"BANANA"
replace crop_category1=	"Beef Meat"		if  item_code==	"BEEF"
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	"BISCUITS"
replace crop_category1=	"Spices"		if  item_code==	"BLACK PEPPER"
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	"BOTTLED WATER, SOFT DRINK & JU"
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	"BREAD"
replace crop_category1=	"Other Meat"		if  item_code==	"BUSH MEAT/WILD GAME"
replace crop_category1=	"Vegetables"		if  item_code==	"CABBAGE"
replace crop_category1=	"Fish and Seafood"		if  item_code==	"CANNED/TIN FISH"
replace crop_category1=	"Vegetables"		if  item_code==	"CARROTS"
replace crop_category1=	"Cassava"		if  item_code==	"CASSAVA"
replace crop_category1=	"Cassava"		if  item_code==	"CASSAVA DOUGH"
replace crop_category1=	"Poultry Meat"		if  item_code==	"CHICKEN/GUINEA FOWL"
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	"CHOCOLATE"
replace crop_category1=	"Fruits"		if  item_code==	"COCONUT"
replace crop_category1=	"Oils, Fats"		if  item_code==	"COCONUT OIL"
replace crop_category1=	"Other Roots and Tubers"		if  item_code==	"COCOYAM"
replace crop_category1=	"Vegetables"		if  item_code==	"COCOYAM LEAVES"
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	"COFFEE, TEA COCOA, ETC"
replace crop_category1=	"Nuts and Seeds"		if  item_code==	"COLA NUTS"
replace crop_category1=	"Other Food"		if  item_code==	"COOKED MEALS $(AS WAGES)"
replace crop_category1=	"Other Food"		if  item_code==	"CORNED BEEF"
replace crop_category1=	"Pulses"		if  item_code==	"COWPEA BEANS"
replace crop_category1=	"Eggs"		if  item_code==	"EGGS"
replace crop_category1=	"Fish and Seafood"		if  item_code==	"FISH"
replace crop_category1=	"Wheat"		if  item_code==	"FLOUR $(WHEAT)"
replace crop_category1=	"Other Meat"		if  item_code==	"GAME BIRDS"
replace crop_category1=	"Vegetables"		if  item_code==	"GARDEN EGGS"
replace crop_category1=	"Cassava"		if  item_code==	"GARI"
replace crop_category1=	"Vegetables"		if  item_code==	"GINGER"
replace crop_category1=	"Lamb and Goat Meat"		if  item_code==	"GOAT MEAT"
replace crop_category1=	"Oils, Fats"		if  item_code==	"GROUNDNUT OIL"
replace crop_category1=	"Groundnuts"		if  item_code==	"GROUNDNUTS"
replace crop_category1=	"Millet and Sorghum"		if  item_code==	"GUINEA CORN/SORGHUM"
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	"HONEY"
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	"ICE CREAM, ICE LOLLIES"
replace crop_category1=	"Maize"		if  item_code==	"KENKEY/BANKU $(WITHOUT SAUCE)"
replace crop_category1=	"Maize"		if  item_code==	"MAIZE"
replace crop_category1=	"Maize"		if  item_code==	"MAIZE GROUND/ CORN DOUGH"
replace crop_category1=	"Fruits"		if  item_code==	"MANGO"
replace crop_category1=	"Oils, Fats"		if  item_code==	"MARGARINE/BUTTER"
replace crop_category1=	"Dairy"		if  item_code==	"MILK $(FRESH)"
replace crop_category1=	"Dairy"		if  item_code==	"MILK $(POWDER)"
replace crop_category1=	"Millet and Sorghum"		if  item_code==	"MILLET"
replace crop_category1=	"Lamb and Goat Meat"		if  item_code==	"MUTTON"
replace crop_category1=	"Vegetables"		if  item_code==	"OKRO $(FRESH/DRIED)"
replace crop_category1=	"Vegetables"		if  item_code==	"ONIONS $(LARGE/SMALL)"
replace crop_category1=	"Fruits"		if  item_code==	"ORANGE/TANGERINE"
replace crop_category1=	"Pulses"		if  item_code==	"OTHER BEANS"
replace crop_category1=	"Non-Dairy Beverages"		if  item_code==	"OTHER BEVERAGES"
replace crop_category1=	"Other Cereals"		if  item_code==	"OTHER CEREALS"
replace crop_category1=	"Spices"		if  item_code==	"OTHER CONDIMENTS/SPICES"
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	"OTHER CONFECTIONARIES"
replace crop_category1=	"Dairy"		if  item_code==	"OTHER MILK PRODUCTS"
replace crop_category1=	"Nuts and Seeds"		if  item_code==	"OTHER PULSES AND NUTS"
replace crop_category1=	"Other Roots and Tubers"		if  item_code==	"OTHER STARCHY STAPLES"
replace crop_category1=	"Oils, Fats"		if  item_code==	"OTHER VEGETABLE OILS"
replace crop_category1=	"Vegetables"		if  item_code==	"OTHER VEGETABLES"
replace crop_category1=	"Oils, Fats"		if  item_code==	"PALM KERNEL OIL"
replace crop_category1=	"Oils, Fats"		if  item_code==	"PALM NUTS"
replace crop_category1=	"Oils, Fats"		if  item_code==	"PALM OIL"
replace crop_category1=	"Fruits"		if  item_code==	"PAWPAW"
replace crop_category1=	"Spices"		if  item_code==	"PEPPER $(FRESH OR DRIED)"
replace crop_category1=	"Fruits"		if  item_code==	"PINEAPPLE"
replace crop_category1=	"Bananas and Plantains"		if  item_code==	"PLANTAIN"
replace crop_category1=	"Pork Meat"		if  item_code==	"PORK"
replace crop_category1=	"Other Food"		if  item_code==	"RESTAURANTS, CAFES, CANTEENS,"
replace crop_category1=	"Rice"		if  item_code==	"RICE-IMPORTED"
replace crop_category1=	"Rice"		if  item_code==	"RICE-LOCAL"
replace crop_category1=	"Spices"		if  item_code==	"SALT"
replace crop_category1=	"Oils, Fats"		if  item_code==	"SHEA BUTTER"
replace crop_category1=	"Pulses"		if  item_code==	"SOYA BEANS"
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	"SUGAR $(CUBE, GRANULATED"
replace crop_category1=	"Sugar, Sweets, Pastries"		if  item_code==	"SUGARCANE"
replace crop_category1=	"Dairy"		if  item_code==	"TINNED MILK"
replace crop_category1=	"Tobacco"		if  item_code==	"TOBACCO"
replace crop_category1=	"Vegetables"		if  item_code==	"TOMATO PUREE $(CANNED)"
replace crop_category1=	"Vegetables"		if  item_code==	"TOMATOES $(FRESH)"
replace crop_category1=	"Fruits"		if  item_code==	"WATER MELON"
replace crop_category1=	"Yams"		if  item_code==	"YAM"



gen food_consu_unit=unit 
gen food_purch_unit = unit  
ren Qci food_purch_qty
ren s11ac food_purch_value   
*ren s11ab food_prod_value   
ren Qbi food_prod_qty
gen food_prod_unit =unit    
*ren s11ad food_gift_value   
ren Qdi food_gift_qty
gen food_gift_unit=unit 
gen food_consu_qty=food_purch_qty+food_prod_qty+food_gift_qty
gen food_consu_yesno=(food_consu_qty>0)


replace food_purch_qty=food_purch_qty*3.79 if food_purch_unit==4 		//APN: changing gallon to kg
replace food_consu_qty=food_consu_qty*3.79 if food_consu_unit==4
replace food_prod_qty=food_prod_qty*3.79 if food_prod_unit==4
replace food_gift_qty=food_gift_qty*3.79 if food_gift_unit==4


recode food_consu_unit food_purch_unit (13=14) // gallon to kg

keep if food_consu_yesno==1
*drop if food_consu_qty==0  | food_consu_qty==.

*Impute the value of consumption using prices inferred from the quantity of purchase and the value of pruchases.
gen price_unit= food_purch_value/food_purch_qty
recode price_unit (0=.)
gen country=1 

//Drop diplicates
duplicates report hhid item_code crop_category1 food_prod_qty food_purch_qty food_gift_qty food_consu_qty
bysort hhid item_code crop_category1 food_prod_qty food_purch_qty food_gift_qty food_consu_qty: gen dup=cond(_N==1,0,_n)
tab dup 
list hhid item_code crop_category1 food_prod_qty food_purch_qty food_gift_qty food_consu_qty if dup>=1
drop if dup>=1

save "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_consumption_purchase.dta", replace
 
 
*Valuation using price_per_unit
global pgeo_vars country region district ea
local len : word count $pgeo_vars
while `len'!=0 {
	local g : word  `len' of $pgeo_vars
	di "`g'"
	use "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_consumption_purchase.dta", clear
	qui drop if price_unit==.
	qui gen observation = 1
	qui bys $pgeo_vars item_code food_purch_unit: egen obs_`g' = count(observation)
	collapse (median) price_unit [aw=weight], by ($pgeo_vars item_code food_purch_unit obs_`g')
	ren price_unit price_unit_median_`g'
	lab var price_unit_median_`g' "Median price per unit for this crop - `g'"
	lab var obs_`g' "Number of observations for this crop - `g'"
	qui save "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_item_prices_`g'.dta", replace
	global pgeo_vars=subinstr("$pgeo_vars","`g'","",1)
	local len=`len'-1
}
 
 

*Pull prices into consumption estimates
use "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_consumption_purchase.dta", clear
merge m:1 hhid using "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_hhids.dta", nogen keep(1 3)


* Value Food consumption, production, and gift when the units does not match the units of purchased
foreach f in consu prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit==food_purch_unit

*- using ea medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region district ea item_code food_purch_unit using "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_item_prices_ea.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_ea if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_ea>10 & obs_ea!=.

*- using department medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region district item_code food_purch_unit using "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_item_prices_district.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_district if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_district>10 & obs_district!=.

*- using region medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region item_code food_purch_unit using "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_item_prices_region.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_region if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_region>10 & obs_region!=.

*- using Country medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 item_code food_purch_unit using "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_item_prices_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid  item_code crop_category1 food_`f'_value
save "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_consumption_purchase_`f'.dta", replace
restore
}

merge 1:1 hhid item_code crop_category1  using "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_consumption_purchase_consu.dta", nogen
merge 1:1 hhid item_code crop_category1  using "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_consumption_purchase_prod.dta", nogen
merge 1:1 hhid item_code crop_category1  using "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_consumption_purchase_gift.dta", nogen


collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid crop_category1)
recode  food_consu_value food_purch_value (.=0)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_food_home_consumption_value.dta", replace

 
********

use "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_food_home_consumption_value.dta", clear
merge m:1 hhid using "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_hhids.dta", nogen keep(1 3)

*convert to annual value by multiplying with 12 (30-day recall)
replace food_consu_value=food_consu_value*12
replace food_purch_value=food_purch_value*12 
replace food_prod_value=food_prod_value*12 
replace food_gift_value=food_gift_value*12

label var food_consu_value "Annual value of food consumed, nominal"
label var food_purch_value "Annual value of food purchased, nominal"
label var food_prod_value "Annual value of food produced, nominal"
label var food_gift_value "Annual value of food received, nominal"
 
lab var fhh "1= Female-headed household"
lab var hh_members "Number of household members"
lab var adulteq "Adult-Equivalent"
lab var crop_category1 "Food items"
lab var hhid "Household ID"

save "${Ghana_SPS_W1_created_data}/Ghana_SPS_W1_food_consumption_value.dta", replace

** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value {
	_pctile `v' [aw=weight] , p($wins_upper_thres)  
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
}


ren region adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province"
ren district adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"
gen adm3=.
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="Ghana"
lab var Country "Country name"
qui gen Instrument="Ghana SPS W1"
lab var Instrument "Survey name"
qui gen Year="2009/10"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq age_hh nadultworking nadultworking_female nadultworking_male nchildren nelders fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

*generate GID_1 code to match codes in the Ghana shapefile 
*Regrouped using the new regions https://en.wikipedia.org/wiki/Regions_of_Ghana
gen GID_1=""			
replace GID_1=	"GHA15_2"	if adm2==	1
replace GID_1=	"GHA16_2"	if adm2==	2
replace GID_1=	"GHA16_2"	if adm2==	3
replace GID_1=	"GHA16_2"	if adm2==	4
replace GID_1=	"GHA15_2"	if adm2==	5
replace GID_1=	"GHA15_2"	if adm2==	6
replace GID_1=	"GHA16_2"	if adm2==	7
replace GID_1=	"GHA15_2"	if adm2==	8
replace GID_1=	"GHA15_2"	if adm2==	9
replace GID_1=	"GHA15_2"	if adm2==	10
replace GID_1=	"GHA16_2"	if adm2==	11
replace GID_1=	"GHA16_2"	if adm2==	12
replace GID_1=	"GHA15_2"	if adm2==	13
replace GID_1=	"GHA15_2"	if adm2==	14
replace GID_1=	"GHA15_2"	if adm2==	15
replace GID_1=	"GHA15_2"	if adm2==	16
replace GID_1=	"GHA15_2"	if adm2==	17
replace GID_1=	"GHA5_2"	if adm2==	18
replace GID_1=	"GHA5_2"	if adm2==	19
replace GID_1=	"GHA5_2"	if adm2==	20
replace GID_1=	"GHA5_2"	if adm2==	21
replace GID_1=	"GHA5_2"	if adm2==	22
replace GID_1=	"GHA5_2"	if adm2==	23
replace GID_1=	"GHA5_2"	if adm2==	24
replace GID_1=	"GHA5_2"	if adm2==	25
replace GID_1=	"GHA5_2"	if adm2==	26
replace GID_1=	"GHA5_2"	if adm2==	27
replace GID_1=	"GHA5_2"	if adm2==	28
replace GID_1=	"GHA5_2"	if adm2==	29
replace GID_1=	"GHA5_2"	if adm2==	30
replace GID_1=	"GHA5_2"	if adm2==	31
replace GID_1=	"GHA5_2"	if adm2==	32
replace GID_1=	"GHA5_2"	if adm2==	33
replace GID_1=	"GHA5_2"	if adm2==	34
replace GID_1=	"GHA7_2"	if adm2==	35
replace GID_1=	"GHA7_2"	if adm2==	36
replace GID_1=	"GHA7_2"	if adm2==	37
replace GID_1=	"GHA7_2"	if adm2==	38
replace GID_1=	"GHA7_2"	if adm2==	39
replace GID_1=	"GHA7_2"	if adm2==	40
replace GID_1=	"GHA7_2"	if adm2==	41
replace GID_1=	"GHA7_2"	if adm2==	42
replace GID_1=	"GHA7_2"	if adm2==	43
replace GID_1=	"GHA7_2"	if adm2==	44
replace GID_1=	"GHA14_2"	if adm2==	45
replace GID_1=	"GHA14_2"	if adm2==	46
replace GID_1=	"GHA10_2"	if adm2==	47
replace GID_1=	"GHA14_2"	if adm2==	48
replace GID_1=	"GHA14_2"	if adm2==	49
replace GID_1=	"GHA10_2"	if adm2==	50
replace GID_1=	"GHA10_2"	if adm2==	51
replace GID_1=	"GHA10_2"	if adm2==	52
replace GID_1=	"GHA14_2"	if adm2==	53
replace GID_1=	"GHA14_2"	if adm2==	54
replace GID_1=	"GHA14_2"	if adm2==	55
replace GID_1=	"GHA10_2"	if adm2==	56
replace GID_1=	"GHA10_2"	if adm2==	57
replace GID_1=	"GHA10_2"	if adm2==	58
replace GID_1=	"GHA10_2"	if adm2==	59
replace GID_1=	"GHA14_2"	if adm2==	60
replace GID_1=	"GHA14_2"	if adm2==	61
replace GID_1=	"GHA6_2"	if adm2==	62
replace GID_1=	"GHA6_2"	if adm2==	63
replace GID_1=	"GHA6_2"	if adm2==	64
replace GID_1=	"GHA6_2"	if adm2==	65
replace GID_1=	"GHA6_2"	if adm2==	66
replace GID_1=	"GHA6_2"	if adm2==	67
replace GID_1=	"GHA6_2"	if adm2==	68
replace GID_1=	"GHA6_2"	if adm2==	69
replace GID_1=	"GHA6_2"	if adm2==	70
replace GID_1=	"GHA6_2"	if adm2==	71
replace GID_1=	"GHA6_2"	if adm2==	72
replace GID_1=	"GHA6_2"	if adm2==	73
replace GID_1=	"GHA6_2"	if adm2==	74
replace GID_1=	"GHA6_2"	if adm2==	75
replace GID_1=	"GHA6_2"	if adm2==	76
replace GID_1=	"GHA6_2"	if adm2==	77
replace GID_1=	"GHA6_2"	if adm2==	78
replace GID_1=	"GHA6_2"	if adm2==	79
replace GID_1=	"GHA6_2"	if adm2==	80
replace GID_1=	"GHA6_2"	if adm2==	81
replace GID_1=	"GHA6_2"	if adm2==	82
replace GID_1=	"GHA6_2"	if adm2==	83
replace GID_1=	"GHA2_2"	if adm2==	84
replace GID_1=	"GHA2_2"	if adm2==	85
replace GID_1=	"GHA2_2"	if adm2==	86
replace GID_1=	"GHA2_2"	if adm2==	87
replace GID_1=	"GHA2_2"	if adm2==	88
replace GID_1=	"GHA2_2"	if adm2==	89
replace GID_1=	"GHA2_2"	if adm2==	90
replace GID_1=	"GHA2_2"	if adm2==	91
replace GID_1=	"GHA2_2"	if adm2==	92
replace GID_1=	"GHA2_2"	if adm2==	93
replace GID_1=	"GHA2_2"	if adm2==	94
replace GID_1=	"GHA2_2"	if adm2==	95
replace GID_1=	"GHA2_2"	if adm2==	96
replace GID_1=	"GHA2_2"	if adm2==	97
replace GID_1=	"GHA2_2"	if adm2==	98
replace GID_1=	"GHA2_2"	if adm2==	99
replace GID_1=	"GHA2_2"	if adm2==	100
replace GID_1=	"GHA2_2"	if adm2==	101
replace GID_1=	"GHA2_2"	if adm2==	102
replace GID_1=	"GHA2_2"	if adm2==	103
replace GID_1=	"GHA2_2"	if adm2==	104
replace GID_1=	"GHA2_2"	if adm2==	105
replace GID_1=	"GHA2_2"	if adm2==	106
replace GID_1=	"GHA2_2"	if adm2==	107
replace GID_1=	"GHA2_2"	if adm2==	108
replace GID_1=	"GHA2_2"	if adm2==	109
replace GID_1=	"GHA2_2"	if adm2==	110
replace GID_1=	"GHA2_2"	if adm2==	111
replace GID_1=	"GHA1_2"	if adm2==	112
replace GID_1=	"GHA1_2"	if adm2==	113
replace GID_1=	"GHA1_2"	if adm2==	114
replace GID_1=	"GHA4_2"	if adm2==	115
replace GID_1=	"GHA1_2"	if adm2==	116
replace GID_1=	"GHA1_2"	if adm2==	117
replace GID_1=	"GHA1_2"	if adm2==	118
replace GID_1=	"GHA1_2"	if adm2==	119
replace GID_1=	"GHA1_2"	if adm2==	120
replace GID_1=	"GHA4_2"	if adm2==	121
replace GID_1=	"GHA4_2"	if adm2==	122
replace GID_1=	"GHA4_2"	if adm2==	123
replace GID_1=	"GHA4_2"	if adm2==	124
replace GID_1=	"GHA4_2"	if adm2==	125
replace GID_1=	"GHA4_2"	if adm2==	126
replace GID_1=	"GHA3_2"	if adm2==	127
replace GID_1=	"GHA3_2"	if adm2==	128
replace GID_1=	"GHA3_2"	if adm2==	129
replace GID_1=	"GHA1_2"	if adm2==	130
replace GID_1=	"GHA1_2"	if adm2==	131
replace GID_1=	"GHA4_2"	if adm2==	132
replace GID_1=	"GHA1_2"	if adm2==	133
replace GID_1=	"GHA11_2"	if adm2==	134
replace GID_1=	"GHA8_2"	if adm2==	135
replace GID_1=	"GHA11_2"	if adm2==	136
replace GID_1=	"GHA8_2"	if adm2==	137
replace GID_1=	"GHA11_2"	if adm2==	138
replace GID_1=	"GHA8_2"	if adm2==	139
replace GID_1=	"GHA9_2"	if adm2==	140
replace GID_1=	"GHA9_2"	if adm2==	141
replace GID_1=	"GHA9_2"	if adm2==	142
replace GID_1=	"GHA9_2"	if adm2==	143
replace GID_1=	"GHA9_2"	if adm2==	144
replace GID_1=	"GHA9_2"	if adm2==	145
replace GID_1=	"GHA9_2"	if adm2==	146
replace GID_1=	"GHA11_2"	if adm2==	147
replace GID_1=	"GHA9_2"	if adm2==	148
replace GID_1=	"GHA9_2"	if adm2==	149
replace GID_1=	"GHA11_2"	if adm2==	150
replace GID_1=	"GHA8_2"	if adm2==	151
replace GID_1=	"GHA9_2"	if adm2==	152
replace GID_1=	"GHA9_2"	if adm2==	153
replace GID_1=	"GHA12_2"	if adm2==	154
replace GID_1=	"GHA12_2"	if adm2==	155
replace GID_1=	"GHA12_2"	if adm2==	156
replace GID_1=	"GHA12_2"	if adm2==	157
replace GID_1=	"GHA12_2"	if adm2==	158
replace GID_1=	"GHA12_2"	if adm2==	159
replace GID_1=	"GHA12_2"	if adm2==	160
replace GID_1=	"GHA12_2"	if adm2==	161
replace GID_1=	"GHA12_2"	if adm2==	162
replace GID_1=	"GHA13_2"	if adm2==	163
replace GID_1=	"GHA13_2"	if adm2==	164
replace GID_1=	"GHA13_2"	if adm2==	165
replace GID_1=	"GHA13_2"	if adm2==	166
replace GID_1=	"GHA13_2"	if adm2==	167
replace GID_1=	"GHA13_2"	if adm2==	168
replace GID_1=	"GHA13_2"	if adm2==	169
replace GID_1=	"GHA13_2"	if adm2==	170
replace GID_1=	"GHA13_2"	if adm2==	171

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
replace conv_lcu_ppp=	1.524487444	if Instrument==	"Ghana SPS W1"

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
tostring old_hhid, gen(hhid)
drop old_hhid

compress
save "${final_data}/Ghana_SPS_W1_food_consumption_value_by_source.dta", replace



















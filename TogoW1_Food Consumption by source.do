/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Togo Enquête Harmonisée sur le Conditions de Vie des Ménages (EHCVM) (2018-19)
				 
*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Benin Enquête Harmonisée sur le Conditions de Vie des Ménages Panel Survey was collected by the Togo National Institute of Statistics and Economic and Demographic Studies.
*and the World Bank's Living Standards Measurement Study - Integrated Surveys on Agriculture(LSMS - ISA)
*The data were collected over the period September 2018 - December 2018, April - June 2019.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://microdata.worldbank.org/index.php/catalog/4298


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Togo EHCVM dataset.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, rural location indicator, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Togo_EHCVM_W1_hhids.dta
*Food Consumption by source			Togo_EHCVM_W1_food_consumption_value_by_source.dta

*/



clear
clear mata
clear matrix
program drop _all
set more off
set maxvar 10000

*Set location of raw data and output
global directory			"\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Non-LSMS Datasets/Enquête Harmonisée sur le Conditions de Vie des Ménages 2018-2019"

//set directories
global Togo_EHCVM_W1_raw_data 		"$directory\Togo\TGO_2018_EHCVM_v02_M_Stata"
global Togo_EHCVM_W1_created_data  "//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"


********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN USD
********************************************************************************
global Togo_EHCVM_W1_exchange_rate 585.91  		// https://data.worldbank.org/indicator/PA.NUS.FCRF?locations=TG
global Togo_EHCVM_W1_gdp_ppp_dollar 229.99			// https://data.worldbank.org/indicator/PA.NUS.PPP?locations=TG
global Togo_EHCVM_W1_cons_ppp_dollar 240.24			// https://data.worldbank.org/indicator/PA.NUS.PRVT.PP?locations=TG
global Togo_EHCVM_W1_inflation -0.0159				// inflation rate 2011-2017. Data was collected during 2010-2011. We want to adjust value to 2017 https://data.worldbank.org/indicator/FP.CPI.TOTL?locations=TG


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Togo_EHCVM_W1_pop_tot 8243094
global Togo_EHCVM_W1_pop_rur 4760552
global Togo_EHCVM_W1_pop_urb 3482542


********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables

 
********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${Togo_EHCVM_W1_raw_data}/ehcvm_ponderations_tgo2018.dta", clear
merge 1:m grappe using "${Togo_EHCVM_W1_raw_data}/s01_me_tgo2018.dta", nogen keep (1 3)
ren hhweight weight
ren s01q03c year_birth
replace year_birth=. if year_birth==9999.00
gen age=2019-year_birth
replace age=. if age==-1 
replace age =s01q04a if age==.

ren s01q04a age2
replace age=age2 if age==. 
replace age=0 if age<0
ren s01q01 gender
codebook s01q02, tab(100)
gen fhh = gender==2 & s01q02==1
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

gen age_hh= age if s01q02==1
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

collapse (max) fhh weight age_hh (sum) hh_members adulteq nadultworking nadultworking_female nadultworking_male nchildren nelders, by(grappe menage)

merge 1:m grappe menage using "${Togo_EHCVM_W1_raw_data}/s00_me_tgo2018.dta", nogen keep (1 3)
ren s00q01 region 
ren s00q02 department

gen rural = (s00q04 ==2)
lab var rural "1= Rural"

ren s00q23a first_interview_date
gen interview_year=substr(first_interview_date ,1,4)
gen interview_month=substr(first_interview_date,6,2)
gen interview_day=substr(first_interview_date,9,2)
destring interview_day interview_month interview_year, replace

lab var interview_day "Survey interview day"
lab var interview_month "Survey interview month"
lab var interview_year "Survey interview year"

****Currency Conversion Factors****
gen ccf_loc = (1 + $Togo_EHCVM_W1_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $SHL"
gen ccf_usd = (1 + $Togo_EHCVM_W1_inflation)/$Togo_EHCVM_W1_exchange_rate 
lab var ccf_usd "currency conversion factor - 2017 $USD"
gen ccf_1ppp = (1 + $Togo_EHCVM_W1_inflation)/ $Togo_EHCVM_W1_cons_ppp_dollar
lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Togo_EHCVM_W1_inflation)/ $Togo_EHCVM_W1_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"

keep grappe menage region department fhh weight hh_members adulteq age_hh nadultworking nadultworking_female nadultworking_male nchildren nelders interview_day interview_month interview_year rural
save  "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_hhids.dta", replace


 
********************************************************************************
*CONSUMPTION
******************************************************************************** 
*Visit 1
use "${Togo_EHCVM_W1_raw_data}/s07b_me_tgo2018.dta", clear
merge m:1 grappe menage using "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_hhids.dta", nogen keep (1 3)
label list S07BQ01
ren s07bq01 item_code
gen crop_category1=""			
replace crop_category1=	"Rice"	if  item_code==	1
replace crop_category1=	"Rice"	if  item_code==	2
replace crop_category1=	"Rice"	if  item_code==	3
replace crop_category1=	"Rice"	if  item_code==	4
replace crop_category1=	"Maize"	if  item_code==	5
replace crop_category1=	"Maize"	if  item_code==	6
replace crop_category1=	"Millet and Sorghum"	if  item_code==	7
replace crop_category1=	"Millet and Sorghum"	if  item_code==	8
replace crop_category1=	"Wheat"	if  item_code==	9
replace crop_category1=	"Millet and Sorghum"	if  item_code==	10
replace crop_category1=	"Maize"	if  item_code==	12
replace crop_category1=	"Millet and Sorghum"	if  item_code==	13
replace crop_category1=	"Wheat"	if  item_code==	14
replace crop_category1=	"Wheat"	if  item_code==	16
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	17
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	18
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	19
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	20
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	21
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	22
replace crop_category1=	"Beef Meat"	if  item_code==	23
replace crop_category1=	"Other Meat"	if  item_code==	24
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	25
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	26
replace crop_category1=	"Other Meat"	if  item_code==	27
replace crop_category1=	"Pork Meat"	if  item_code==	28
replace crop_category1=	"Poultry Meat"	if  item_code==	29
replace crop_category1=	"Poultry Meat"	if  item_code==	30
replace crop_category1=	"Poultry Meat"	if  item_code==	31
replace crop_category1=	"Other Meat"	if  item_code==	32
replace crop_category1=	"Other Meat"	if  item_code==	33
replace crop_category1=	"Other Meat"	if  item_code==	34
replace crop_category1=	"Fish and Seafood"	if  item_code==	35
replace crop_category1=	"Fish and Seafood"	if  item_code==	36
replace crop_category1=	"Fish and Seafood"	if  item_code==	37
replace crop_category1=	"Fish and Seafood"	if  item_code==	38
replace crop_category1=	"Fish and Seafood"	if  item_code==	39
replace crop_category1=	"Fish and Seafood"	if  item_code==	40
replace crop_category1=	"Fish and Seafood"	if  item_code==	41
replace crop_category1=	"Fish and Seafood"	if  item_code==	42
replace crop_category1=	"Fish and Seafood"	if  item_code==	43
replace crop_category1=	"Dairy"	if  item_code==	44
replace crop_category1=	"Dairy"	if  item_code==	45
replace crop_category1=	"Dairy"	if  item_code==	46
replace crop_category1=	"Dairy"	if  item_code==	47
replace crop_category1=	"Dairy"	if  item_code==	48
replace crop_category1=	"Dairy"	if  item_code==	49
replace crop_category1=	"Dairy"	if  item_code==	50
replace crop_category1=	"Dairy"	if  item_code==	51
replace crop_category1=	"Eggs"	if  item_code==	52
replace crop_category1=	"Oils, Fats"	if  item_code==	53
replace crop_category1=	"Oils, Fats"	if  item_code==	54
replace crop_category1=	"Oils, Fats"	if  item_code==	55
replace crop_category1=	"Oils, Fats"	if  item_code==	56
replace crop_category1=	"Oils, Fats"	if  item_code==	57
replace crop_category1=	"Oils, Fats"	if  item_code==	58
replace crop_category1=	"Oils, Fats"	if  item_code==	59
replace crop_category1=	"Fruits"	if  item_code==	60
replace crop_category1=	"Fruits"	if  item_code==	61
replace crop_category1=	"Fruits"	if  item_code==	62
replace crop_category1=	"Bananas and Plantains"	if  item_code==	63
replace crop_category1=	"Fruits"	if  item_code==	64
replace crop_category1=	"Fruits"	if  item_code==	65
replace crop_category1=	"Fruits"	if  item_code==	66
replace crop_category1=	"Fruits"	if  item_code==	67
replace crop_category1=	"Fruits"	if  item_code==	68
replace crop_category1=	"Fruits"	if  item_code==	69
replace crop_category1=	"Fruits"	if  item_code==	70
replace crop_category1=	"Fruits"	if  item_code==	71
replace crop_category1=	"Vegetables"	if  item_code==	72
replace crop_category1=	"Vegetables"	if  item_code==	73
replace crop_category1=	"Vegetables"	if  item_code==	74
replace crop_category1=	"Vegetables"	if  item_code==	75
replace crop_category1=	"Vegetables"	if  item_code==	76
replace crop_category1=	"Vegetables"	if  item_code==	77
replace crop_category1=	"Vegetables"	if  item_code==	78
replace crop_category1=	"Vegetables"	if  item_code==	79
replace crop_category1=	"Vegetables"	if  item_code==	80
replace crop_category1=	"Vegetables"	if  item_code==	81
replace crop_category1=	"Vegetables"	if  item_code==	82
replace crop_category1=	"Vegetables"	if  item_code==	83
replace crop_category1=	"Spices"	if  item_code==	84
replace crop_category1=	"Vegetables"	if  item_code==	85
replace crop_category1=	"Vegetables"	if  item_code==	86
replace crop_category1=	"Vegetables"	if  item_code==	87
replace crop_category1=	"Vegetables"	if  item_code==	88
replace crop_category1=	"Vegetables"	if  item_code==	89
replace crop_category1=	"Vegetables"	if  item_code==	90
replace crop_category1=	"Vegetables"	if  item_code==	91
replace crop_category1=	"Vegetables"	if  item_code==	92
replace crop_category1=	"Vegetables"	if  item_code==	93
replace crop_category1=	"Vegetables"	if  item_code==	94
replace crop_category1=	"Pulses"	if  item_code==	95
replace crop_category1=	"Groundnuts"	if  item_code==	96
replace crop_category1=	"Groundnuts"	if  item_code==	97
replace crop_category1=	"Groundnuts"	if  item_code==	98
replace crop_category1=	"Groundnuts"	if  item_code==	99
replace crop_category1=	"Groundnuts"	if  item_code==	100
replace crop_category1=	"Nuts and Seeds"	if  item_code==	101
replace crop_category1=	"Nuts and Seeds"	if  item_code==	102
replace crop_category1=	"Nuts and Seeds"	if  item_code==	103
replace crop_category1=	"Cassava"	if  item_code==	104
replace crop_category1=	"Yams"	if  item_code==	105
replace crop_category1=	"Bananas and Plantains"	if  item_code==	106
replace crop_category1=	"Potato"	if  item_code==	107
replace crop_category1=	"Other Roots and Tubers"	if  item_code==	108
replace crop_category1=	"Yams"	if  item_code==	109
replace crop_category1=	"Other Roots and Tubers"	if  item_code==	110
replace crop_category1=	"Cassava"	if  item_code==	111
replace crop_category1=	"Cassava"	if  item_code==	112
replace crop_category1=	"Cassava"	if  item_code==	113
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	114
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	115
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	116
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	117
replace crop_category1=	"Spices"	if  item_code==	118
replace crop_category1=	"Spices"	if  item_code==	119
replace crop_category1=	"Spices"	if  item_code==	120
replace crop_category1=	"Spices"	if  item_code==	121
replace crop_category1=	"Spices"	if  item_code==	122
replace crop_category1=	"Spices"	if  item_code==	123
replace crop_category1=	"Spices"	if  item_code==	124
replace crop_category1=	"Spices"	if  item_code==	125
replace crop_category1=	"Spices"	if  item_code==	126
replace crop_category1=	"Nuts and Seeds"	if  item_code==	127
replace crop_category1=	"Other Food"	if  item_code==	128
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	129
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	130
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	131
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	132
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	133
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	134
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	135
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	136
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	137
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	138
drop if item_code==11  //No label
drop if item_code==15  //No label



ren s07bq02 food_consu_yesno
ren s07bq03b food_consu_unit
ren s07bq03a food_consu_qty
ren s07bq07b food_purch_unit
ren s07bq07a food_purch_qty
ren s07bq08  food_purch_value
ren s07bq04  food_prod_qty
ren s07bq05  food_gift_qty
gen food_gift_unit=food_consu_unit
gen food_prod_unit=food_consu_unit


keep if food_consu_yesno==1
drop if food_consu_qty==0  | food_consu_qty==.
*Input the value of consumption using prices infered from the quantity of purchase and the value of pruchases.
gen price_unit= food_purch_value/food_purch_qty
recode price_unit (0=.)

gen country=1 
save "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_consumption_purchase.dta", replace
 
 
*Valuation using price_per_unit
global pgeo_vars country region department grappe
local len : word count $pgeo_vars
while `len'!=0 {
	local g : word  `len' of $pgeo_vars
	di "`g'"
	use "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_consumption_purchase.dta", clear
	qui drop if price_unit==.
	qui gen observation = 1
	qui bys $pgeo_vars item_code food_purch_unit: egen obs_`g' = count(observation)
	collapse (median) price_unit [aw=weight], by ($pgeo_vars item_code food_purch_unit obs_`g')
	ren price_unit price_unit_median_`g'
	lab var price_unit_median_`g' "Median price per unit for this crop - `g'"
	lab var obs_`g' "Number of observations for this crop - `g'"
	qui save "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_item_prices_`g'.dta", replace
	global pgeo_vars=subinstr("$pgeo_vars","`g'","",1)
	local len=`len'-1
}
 
 


*Pull prices into consumption estimates
use "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_consumption_purchase.dta", clear
merge m:1 grappe menage using "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_hhids.dta", nogen keep(1 3)

* Value Food consumption, production, and gift when the units does not match the units of purchased
foreach f in consu prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit==food_purch_unit

*- using grappe medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region department grappe item_code food_purch_unit using "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_item_prices_grappe.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_grappe if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_grappe>10 & obs_grappe!=.

*- using department medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region department item_code food_purch_unit using "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_item_prices_department.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_department if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_department>10 & obs_department!=.

*- using region medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region item_code food_purch_unit using "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_item_prices_region.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_region if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_region>10 & obs_region!=.

*- using Country medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 item_code food_purch_unit using "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_item_prices_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_country>10 & obs_country!=.

keep grappe menage  item_code crop_category1 food_`f'_value
save "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_consumption_purchase_`f'.dta", replace
restore
}

merge 1:1 grappe menage item_code crop_category1  using "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_consumption_purchase_consu.dta", nogen
merge 1:1 grappe menage item_code crop_category1  using "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_consumption_purchase_prod.dta", nogen
merge 1:1 grappe menage item_code crop_category1  using "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_consumption_purchase_gift.dta", nogen



collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(grappe menage crop_category1)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_food_home_consumption_value.dta", replace

*Food away from home
use "${Togo_EHCVM_W1_raw_data}/s07a2_me_tgo2018.dta", clear
* I am not sure we can confidently categorised FAH. So coding this as a separate category of food
egen food_purch_value=rowtotal(s07aq02 s07aq03 s07aq05 s07aq06 s07aq08 s07aq09 s07aq11 s07aq12 s07aq14 s07aq15 s07aq17 s07aq18)
gen  food_consu_value=food_purch_value
collapse (sum) food_consu_value food_purch_value, by(grappe menage)
gen crop_category1="Meals away from home"
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
save "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_food_away_consumption_value.dta", replace


use "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_food_home_consumption_value.dta", clear
append using "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_food_away_consumption_value.dta"
merge m:1 grappe menage using "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_hhids.dta", nogen keep(1 3)

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
gen hhid=string(grappe)+"."+string(menage)
lab var hhid "Household ID"
save "${Togo_EHCVM_W1_created_data}/Togo_EHCVM_W1_food_consumption_value_combined.dta", replace


** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value  {
	_pctile `v' [aw=weight] , p($wins_upper_thres)  
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
}


gen ea=grappe
ren region adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province"
ren department adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"
gen adm3=.
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="Togo"
lab var Country "Country name"
qui gen Instrument="Togo EHCVM W1"
lab var Instrument "Survey name"
qui gen Year="2018/19"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq age_hh nadultworking nadultworking_female nadultworking_male nchildren nelders interview_day interview_month interview_year fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

*generate GID_1 code to match codes in the Togo shapefile
gen GID_1=""
replace GID_1="TGO.1_1"  if adm1==3
replace GID_1="TGO.2_1"  if adm1==4
replace GID_1="TGO.3_1"  if adm1==1
replace GID_1="TGO.4_1"  if adm1==2
replace GID_1="TGO.5_1"  if adm1==5


/*generate GID_2 code to match codes in the Togo shapefile
gen GID_2=""
replace GID_2="TGO.1.1_2"  if adm1==304
replace GID_2="TGO.1.2_2"  if adm1==305
replace GID_2="TGO.1.3_2"  if adm1==303
replace GID_2="TGO.1.4_2"  if adm1==302
replace GID_2="TGO.1.5_2"  if adm1==301
replace GID_2="TGO.2.1_1"  if adm1==407
replace GID_2="TGO.2.2_1"  if adm1==406
replace GID_2="TGO.2.3_1"  if adm1==402
replace GID_2="TGO.2.7_1"  if adm1==405
replace GID_2="TGO.2.4_1"  if adm1==403
replace GID_2="TGO.2.5_1"  if adm1==404
replace GID_2="TGO.2.6_1"  if adm1==401
*replace GID_2="TGO.3.1_2"  if adm1==
replace GID_2="TGO.3.2_2"  if adm1==107
replace GID_2="TGO.3.3_2"  if adm1==103
replace GID_2="TGO.3.4_2"  if adm1==101
replace GID_2="TGO.3.5_2"  if adm1==102
*replace GID_2="TGO.3.6_2"  if adm1==
replace GID_2="TGO.3.7_2"  if adm1==104
replace GID_2="TGO.3.8_2"  if adm1==105
replace GID_2="TGO.3.9_2"  if adm1==106
replace GID_2="TGO.4.1_2"  if adm1==210
replace GID_2="TGO.4.2_2"  if adm1==204
replace GID_2="TGO.4.3_2"  if adm1==206
replace GID_2="TGO.4.4_2"  if adm1==202
replace GID_2="TGO.4.5_2"  if adm1==207
replace GID_2="TGO.4.6_2"  if adm1==203
replace GID_2="TGO.4.7_2"  if adm1==211
replace GID_2="TGO.4.8_2"  if adm1==209
replace GID_2="TGO.4.9_2"  if adm1==208
replace GID_2="TGO.4.10_2"  if adm1==212
replace GID_2="TGO.4.11_2"  if adm1==201
replace GID_2="TGO.4.12_2"  if adm1==205
replace GID_2="TGO.5.1_2"  if adm1==502
replace GID_2="TGO.5.2_2"  if adm1==503
*replace GID_2="TGO.5.3_2"  if adm1==
replace GID_2="TGO.5.4_2"  if adm1==504
*replace GID_2="TGO.5.5_2"  if adm1==
replace GID_2="TGO.5.6_2"  if adm1==505
replace GID_2="TGO.5.7_2"  if adm1==501
lab var GID_2 "Adm2 code from the GADM shapefile"
*/
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
replace conv_lcu_ppp=	0.004017931	if Instrument==	"Togo EHCVM W1"

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

save "${final_data}/Togo_EHCVM_W1_food_consumption_value_by_source.dta", replace


*****End of Do File*****
  

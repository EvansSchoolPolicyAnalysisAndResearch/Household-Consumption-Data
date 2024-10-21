/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Gambia Integrated Household Survey 2015/16

*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Gambia Integrated Household Survey was collected by the Gambia Bureau of Statistics 
*The data were collected over the period April 2015 - March 2016.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://microdata.worldbank.org/index.php/catalog/3323


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Gambia IHS dataset.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, rural location indicator, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Gambia_IHS_W3_hhids.dta
*Food Consumption by source			Gambia_IHS_W3_food_consumption_value_by_source.dta

*/



clear
clear mata
clear matrix
program drop _all
set more off
set maxvar 10000

*Set location of raw data and output
global directory			"\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Non-LSMS Datasets"

//set directories
global Gambia_IHS_W3_raw_data 		"$directory/Gambia IHS\Gambia IHS 2015\GMB_2015_IHS_v01_M_Stata8"
global Gambia_IHS_W3_created_data  "//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"


********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN USD
********************************************************************************
global Gambia_IHS_W3_exchange_rate 43.37  		// https://data.worldbank.org/indicator/PA.NUS.FCRF?locations=GM
global Gambia_IHS_W3_gdp_ppp_dollar 14.48			// https://data.worldbank.org/indicator/PA.NUS.PPP?locations=GM
global Gambia_IHS_W3_cons_ppp_dollar 14.25			// https://data.worldbank.org/indicator/PA.NUS.PRVT.PP?locations=GM
global Gambia_IHS_W3_inflation 0.08				// inflation rate 2011-2017. Data was collected during 2010-2011. We want to adjust value to 2017 https://data.worldbank.org/indicator/FP.CPI.TOTL?locations=GM


*DYA.11.1.2020 Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Gambia_IHS_W3_pop_tot 2317296
global Gambia_IHS_W3_pop_rur 928783
global Gambia_IHS_W3_pop_urb 1388423


********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables

 
********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${Gambia_IHS_W3_raw_data}/Part A Section 1-6 Individual-level.dta", clear
merge m:1 eanum using "${Gambia_IHS_W3_raw_data}/Household adjusted_weight.dta", nogen keep (1 3)
ren hhweight weight
ren eanum ea
ren s1q4a age
ren s1q5 gender
codebook s1q6, tab(100)
gen fhh = gender==2 & s1q6==1
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
collapse (max) fhh weight (sum) hh_members adulteq, by(hid)

merge 1:m hid using "${Gambia_IHS_W3_raw_data}/Part A Section 0-HH particulars.dta", nogen keep (1 3)
ren hid hhid
gen rural = (area==2)
lab var rural "1= Rural"


****Currency Conversion Factors****
gen ccf_loc = (1 + $Gambia_IHS_W3_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $SHL"
gen ccf_usd = (1 + $Gambia_IHS_W3_inflation)/$Gambia_IHS_W3_exchange_rate 
lab var ccf_usd "currency conversion factor - 2017 $USD"
gen ccf_1ppp = (1 + $Gambia_IHS_W3_inflation)/ $Gambia_IHS_W3_cons_ppp_dollar
lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Gambia_IHS_W3_inflation)/ $Gambia_IHS_W3_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"
	
		
keep hhid ea lga district settlement area weight rural adulteq fhh hh_members
		
save  "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_hhids.dta", replace

 
*******************************************************************************
*CONSUMPTION
******************************************************************************** 
use "${Gambia_IHS_W3_raw_data}/Part B Section 1A-Food_consumption expenditure1.dta", clear
ren hid hhid
merge m:1 hhid using "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_hhids.dta", nogen keep (1 3)
label list s1aq1
ren s1aq1 item_code
gen crop_category1=""			
replace crop_category1=	"Rice"	if  item_code==	101
replace crop_category1=	"Rice"	if  item_code==	102
replace crop_category1=	"Rice"	if  item_code==	103
replace crop_category1=	"Rice"	if  item_code==	104
replace crop_category1=	"Rice"	if  item_code==	105
replace crop_category1=	"Rice"	if  item_code==	106
replace crop_category1=	"Maize"	if  item_code==	107
replace crop_category1=	"Millet and Sorghum"	if  item_code==	108
replace crop_category1=	"Millet and Sorghum"	if  item_code==	109
replace crop_category1=	"Millet and Sorghum"	if  item_code==	110
replace crop_category1=	"Maize"	if  item_code==	111
replace crop_category1=	"Millet and Sorghum"	if  item_code==	112
replace crop_category1=	"Millet and Sorghum"	if  item_code==	113
replace crop_category1=	"Wheat"	if  item_code==	114
replace crop_category1=	"Cassava"	if  item_code==	115
replace crop_category1=	"Other Food"	if  item_code==	116
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	117
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	118
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	119
replace crop_category1=	"Wheat"	if  item_code==	120
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	121
replace crop_category1=	"Other Cereals"	if  item_code==	122
replace crop_category1=	"Poultry Meat"	if  item_code==	123
replace crop_category1=	"Poultry Meat"	if  item_code==	124
replace crop_category1=	"Eggs"	if  item_code==	125
replace crop_category1=	"Eggs"	if  item_code==	126
replace crop_category1=	"Poultry Meat"	if  item_code==	127
replace crop_category1=	"Beef Meat"	if  item_code==	128
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	129
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	130
replace crop_category1=	"Pork Meat"	if  item_code==	131
replace crop_category1=	"Other Meat"	if  item_code==	132
replace crop_category1=	"Other Meat"	if  item_code==	133
replace crop_category1=	"Fish and Seafood"	if  item_code==	134
replace crop_category1=	"Fish and Seafood"	if  item_code==	135
replace crop_category1=	"Fish and Seafood"	if  item_code==	136
replace crop_category1=	"Fish and Seafood"	if  item_code==	137
replace crop_category1=	"Fish and Seafood"	if  item_code==	138
replace crop_category1=	"Fish and Seafood"	if  item_code==	139
replace crop_category1=	"Fish and Seafood"	if  item_code==	140
replace crop_category1=	"Fish and Seafood"	if  item_code==	141
replace crop_category1=	"Fish and Seafood"	if  item_code==	142
replace crop_category1=	"Fish and Seafood"	if  item_code==	143
replace crop_category1=	"Fish and Seafood"	if  item_code==	144
replace crop_category1=	"Fish and Seafood"	if  item_code==	145
replace crop_category1=	"Fish and Seafood"	if  item_code==	146
replace crop_category1=	"Fish and Seafood"	if  item_code==	147
replace crop_category1=	"Fish and Seafood"	if  item_code==	148
replace crop_category1=	"Fish and Seafood"	if  item_code==	149
replace crop_category1=	"Fish and Seafood"	if  item_code==	150
replace crop_category1=	"Fish and Seafood"	if  item_code==	151
replace crop_category1=	"Dairy"	if  item_code==	152
replace crop_category1=	"Dairy"	if  item_code==	153
replace crop_category1=	"Dairy"	if  item_code==	154
replace crop_category1=	"Dairy"	if  item_code==	155
replace crop_category1=	"Dairy"	if  item_code==	156
replace crop_category1=	"Dairy"	if  item_code==	157
replace crop_category1=	"Dairy"	if  item_code==	158
replace crop_category1=	"Dairy"	if  item_code==	159
replace crop_category1=	"Dairy"	if  item_code==	160
replace crop_category1=	"Dairy"	if  item_code==	161
replace crop_category1=	"Oils, Fats"	if  item_code==	162
replace crop_category1=	"Oils, Fats"	if  item_code==	163
replace crop_category1=	"Oils, Fats"	if  item_code==	164
replace crop_category1=	"Oils, Fats"	if  item_code==	165
replace crop_category1=	"Oils, Fats"	if  item_code==	166
replace crop_category1=	"Oils, Fats"	if  item_code==	167
replace crop_category1=	"Oils, Fats"	if  item_code==	168
replace crop_category1=	"Oils, Fats"	if  item_code==	169
replace crop_category1=	"Oils, Fats"	if  item_code==	170
replace crop_category1=	"Groundnuts"	if  item_code==	171
replace crop_category1=	"Groundnuts"	if  item_code==	172
replace crop_category1=	"Nuts and Seeds"	if  item_code==	173
replace crop_category1=	"Fruits"	if  item_code==	174
replace crop_category1=	"Bananas and Plantains"	if  item_code==	175
replace crop_category1=	"Fruits"	if  item_code==	176
replace crop_category1=	"Fruits"	if  item_code==	177
replace crop_category1=	"Fruits"	if  item_code==	178
replace crop_category1=	"Fruits"	if  item_code==	179
replace crop_category1=	"Fruits"	if  item_code==	180
replace crop_category1=	"Fruits"	if  item_code==	181
replace crop_category1=	"Fruits"	if  item_code==	182
replace crop_category1=	"Fruits"	if  item_code==	183
replace crop_category1=	"Fruits"	if  item_code==	184
replace crop_category1=	"Fruits"	if  item_code==	185
replace crop_category1=	"Fruits"	if  item_code==	186
replace crop_category1=	"Fruits"	if  item_code==	187
replace crop_category1=	"Fruits"	if  item_code==	188
replace crop_category1=	"Nuts and Seeds"	if  item_code==	189
replace crop_category1=	"Groundnuts"	if  item_code==	190
replace crop_category1=	"Groundnuts"	if  item_code==	191
replace crop_category1=	"Groundnuts"	if  item_code==	192
replace crop_category1=	"Fruits"	if  item_code==	193
replace crop_category1=	"Fruits"	if  item_code==	194
replace crop_category1=	"Fruits"	if  item_code==	195
replace crop_category1=	"Fruits"	if  item_code==	196
replace crop_category1=	"Potato"	if  item_code==	197
replace crop_category1=	"Sweet Potato"	if  item_code==	198
replace crop_category1=	"Potato"	if  item_code==	199
replace crop_category1=	"Bananas and Plantains"	if  item_code==	200
replace crop_category1=	"Other Roots and Tubers"	if  item_code==	201
replace crop_category1=	"Pulses"	if  item_code==	202
replace crop_category1=	"Pulses"	if  item_code==	203
replace crop_category1=	"Vegetables"	if  item_code==	204
replace crop_category1=	"Vegetables"	if  item_code==	205
replace crop_category1=	"Vegetables"	if  item_code==	206
replace crop_category1=	"Vegetables"	if  item_code==	207
replace crop_category1=	"Vegetables"	if  item_code==	208
replace crop_category1=	"Vegetables"	if  item_code==	209
replace crop_category1=	"Vegetables"	if  item_code==	210
replace crop_category1=	"Vegetables"	if  item_code==	211
replace crop_category1=	"Vegetables"	if  item_code==	212
replace crop_category1=	"Vegetables"	if  item_code==	213
replace crop_category1=	"Vegetables"	if  item_code==	214
replace crop_category1=	"Vegetables"	if  item_code==	215
replace crop_category1=	"Vegetables"	if  item_code==	216
replace crop_category1=	"Vegetables"	if  item_code==	217
replace crop_category1=	"Vegetables"	if  item_code==	218
replace crop_category1=	"Vegetables"	if  item_code==	219
replace crop_category1=	"Vegetables"	if  item_code==	220
replace crop_category1=	"Vegetables"	if  item_code==	221
replace crop_category1=	"Vegetables"	if  item_code==	222
replace crop_category1=	"Vegetables"	if  item_code==	223
replace crop_category1=	"Vegetables"	if  item_code==	224
replace crop_category1=	"Vegetables"	if  item_code==	225
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	226
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	227
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	228
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	229
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	230
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	231
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	232
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	233
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	234
replace crop_category1=	"Spices"	if  item_code==	235
replace crop_category1=	"Spices"	if  item_code==	236
replace crop_category1=	"Spices"	if  item_code==	237
replace crop_category1=	"Spices"	if  item_code==	238
replace crop_category1=	"Spices"	if  item_code==	239
replace crop_category1=	"Spices"	if  item_code==	240
replace crop_category1=	"Spices"	if  item_code==	241
replace crop_category1=	"Spices"	if  item_code==	242
replace crop_category1=	"Spices"	if  item_code==	243
replace crop_category1=	"Spices"	if  item_code==	244
replace crop_category1=	"Spices"	if  item_code==	245
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	246
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	247
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	248
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	249
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	250
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	251
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	252
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	253
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	254
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	255
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	256
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	257
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	258
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	259
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	260
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	261
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	262
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	263
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	264
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	265
drop if item_code ==.a

ren s1aq2 food_consu_yesno
*ren s1aq3a food_consu_value
ren s1aq3b food_consu_unit
ren s1aq3a food_consu_qty
ren s1aq6b food_purch_unit
ren s1aq6a food_purch_qty
ren s1aq4a food_purch_qty2
ren s1aq4b food_purch_unit2
ren s1aq5 food_purch_value2
ren s1aq7a food_prod_qty
ren s1aq7b food_prod_unit
ren s1aq8a food_gift_qty
ren s1aq8b food_gift_unit


replace food_consu_qty=food_consu_qty/1000 if food_consu_unit==2
replace food_purch_qty=food_purch_qty/1000 if food_purch_unit==2 // grams to kg
replace food_purch_qty2=food_purch_qty2/1000 if food_purch_unit2==2 // grams to kg
replace food_prod_qty=food_prod_qty/1000 if food_prod_unit==2
replace food_gift_qty=food_gift_qty/1000 if food_gift_unit==2

replace food_purch_qty=food_purch_qty/1000 if food_purch_unit==4 
replace food_purch_qty2=food_purch_qty2/1000 if food_purch_unit2==4 
replace food_consu_qty=food_consu_qty/1000 if food_consu_unit==4	//milliter to litre
replace food_prod_qty=food_prod_qty/1000 if food_prod_unit==4
replace food_gift_qty=food_gift_qty/1000 if food_gift_unit==4


*Dealing with the other unit categories
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (2 =1 ) (4=3)  // grams in kg and mili in liter 

keep if food_consu_yesno==1
drop if food_consu_qty==0  | food_consu_qty==.
*Input the value of consumption using prices infered from the quantity of purchase and the value of pruchases.
gen price_unit= food_purch_value2/food_purch_qty2
recode price_unit (0=.)
gen country=1 
save "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_consumption_purchase.dta", replace
 
 
*Valuation using price_per_unit
global pgeo_vars country lga district ea
local len : word count $pgeo_vars
while `len'!=0 {
	local g : word  `len' of $pgeo_vars
	di "`g'"
	use "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_consumption_purchase.dta", clear
	qui drop if price_unit==.
	qui gen observation = 1
	qui bys $pgeo_vars item_code food_purch_unit2: egen obs_`g' = count(observation)
	collapse (median) price_unit [aw=weight], by ($pgeo_vars item_code food_purch_unit2 obs_`g')
	ren price_unit price_unit_median_`g'
	lab var price_unit_median_`g' "Median price per unit for this crop - `g'"
	lab var obs_`g' "Number of observations for this crop - `g'"
	qui save "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_item_prices_`g'.dta", replace
	global pgeo_vars=subinstr("$pgeo_vars","`g'","",1)
	local len=`len'-1
}
 
 
*Pull prices into consumption estimates
use "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_consumption_purchase.dta", clear
merge m:1 hhid using "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_hhids.dta", nogen keep(1 3)

*Removing duplicates
bysort hhid settlement item_code crop_category1: gen dup=cond(_N==1,0,_n)
tab dup 
list item_code crop_category1 hhid if dup>=1
drop if dup>=1


* Value Food consumption, production, and gift when the units does not match the units of purchased
foreach f in consu purch prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit==food_purch_unit2

*- using EA medians with at least 10 observations
drop food_purch_unit2 
gen food_purch_unit2=food_`f'_unit 



merge m:1 lga district ea item_code food_purch_unit2 using "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_item_prices_ea.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_ea if food_`f'_unit==food_purch_unit2 & food_`f'_value==. & obs_ea>10 & obs_ea!=.

*- using District medians with at least 10 observations
drop food_purch_unit2 
gen food_purch_unit2=food_`f'_unit 
merge m:1 lga district item_code food_purch_unit2 using "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_item_prices_district.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_district if food_`f'_unit==food_purch_unit2 & food_`f'_value==. & obs_district>10 & obs_district!=.

*- using Lga medians with at least 10 observations
drop food_purch_unit2 
gen food_purch_unit2=food_`f'_unit 
merge m:1 lga item_code food_purch_unit2 using "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_item_prices_lga.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_lga if food_`f'_unit==food_purch_unit2 & food_`f'_value==. & obs_lga>10 & obs_lga!=.



*- using Country medians
drop food_purch_unit2 
gen food_purch_unit2=food_`f'_unit 
merge m:1 item_code food_purch_unit2 using "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_item_prices_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit==food_purch_unit2 & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid ea item_code crop_category1 food_`f'_value
save "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_consumption_purchase_`f'.dta", replace
restore
}

merge 1:1  hhid item_code crop_category1  using "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_consumption_purchase_consu.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_consumption_purchase_purch.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_consumption_purchase_prod.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_consumption_purchase_gift.dta", nogen



collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid crop_category1)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_food_home_consumption_value.dta", replace


*Food away from home
use "${Gambia_IHS_W3_raw_data}/Part B Section 1B-Food_outside.dta", clear
ren hid hhid
gen food_purch_value=s1bq3
gen  food_consu_value=food_purch_value
collapse (sum) food_consu_value food_purch_value, by(hhid)
gen crop_category1="Meals away from home"
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
save "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_food_away_consumption_value.dta", replace


use "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_food_home_consumption_value.dta", clear
append using "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_food_away_consumption_value.dta"
merge m:1 hhid using "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_hhids.dta", nogen keep(1 3)

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

** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value {
	_pctile `v' [aw=weight] , p($wins_upper_thres)  
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
}

save "${Gambia_IHS_W3_created_data}/Gambia_IHS_W3_food_consumption_value_combined.dta", replace


ren lga adm1   //In Gambia, lga is the first administrative level, followed by district.
lab var adm1 "Adminstrative subdivision 1 - state/region/province"  
ren district adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"  
gen adm3=.
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="Gambia"
lab var Countr "Country name"
qui gen Instrument="Gambia IHS W3"
lab var Instrument "Survey name"
qui gen Year="2015"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year


*generate GID_1 code to match codes in the Gambia shapefile
gen GID_1=""
replace GID_1="GMB.1_1"  if adm1==1
replace GID_1="GMB.1_1"  if adm1==2	//I merged Banjul and Kanifing - To fform the Greater Banjul https://en.wikipedia.org/wiki/Subdivisions_of_the_Gambia 
replace GID_1="GMB.2_1"  if adm1==4
replace GID_1="GMB.3_1"  if adm1==7
replace GID_1="GMB.4_1"  if adm1==5
replace GID_1="GMB.5_1"  if adm1==8
replace GID_1="GMB.6_1"  if adm1==6
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
replace conv_lcu_ppp=	0.076645398	if Instrument==	"Gambia IHS W3"

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
save "${final_data}/Gambia_IHS_W3_food_consumption_value_by_source.dta", replace


*****End of Do File*****
  
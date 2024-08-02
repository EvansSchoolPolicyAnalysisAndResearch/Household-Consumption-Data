/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the India Household Consumer Expenditure (HCE) 2011/12
				 
*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available, Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The India Household Consumer Expenditure was collected by the Ministry of Statistics and Programme Implementation 
*The data were collected over the period July 2011 - June 2012.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://microdata.gov.in/nada43/index.php/catalog/1


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the India HCE dataset.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				India_HCE_W1_hhids.dta
*Food Consumption by source			India_HCE_W1_food_consumption_value_by_source.dta

*/



clear	
set more off
clear matrix	
clear mata	
set maxvar 10000

***********************
*GENERAL INFORMATION 
***********************
*Survey was divided in two visits. Visit 1 covers July 2012 to December 2012 and Visit 2 cover January 2013 to June 2013. Raw data is divided in these two visits.  


*Set location of raw data and output
global directory			    "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Non-LSMS Datasets"

//set directories: These paths correspond to the folders where the raw data files are located and where the created data and final data will be stored.
global India_HCE_W1_raw_data 			"$directory/India - NSSO\HCE\Stata\raw_data"
global created_data 		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"


********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN SUD IDS
********************************************************************************
global India_HCE_W1_exchange_rate 58.6			// https://data.worldbank.org/indicator/PA.NUS.FCRF?locations=IN
global India_HCE_W1_gdp_ppp_dollar 17.34  		// https://data.worldbank.org/indicator/PA.NUS.PPP?locations=IN
global India_HCE_W1_cons_ppp_dolar 16.94 		// https://data.worldbank.org/indicator/PA.NUS.PRVT.PP?locations=IN
global India_HCE_W1_inflation 0.2134   		// inflation rate 2013-2017. Data was collected during October 2018-2019. We have adjusted values to 2017. https://data.worldbank.org/indicator/FP.CPI.TOTL?locations=BD  //https://www.worlddata.info/asia/bangladesh/inflation-rates.php


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global India_HCE_W1_pop_tot 1290000000 
global India_HCE_W1_pop_rur 877931069
global India_HCE_W1_pop_urb 413200994

********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables


************************
*HOUSEHOLD IDS 
************************
use "${India_HCE_W1_raw_data}\Type 1\Demographic and other particulars of household members - Block 4  - Level 4 - 68.dta", clear
ren Sex gender
gen fhh = (gender=="2"  & Relation=="1")
lab var fhh "1= Female-headed Household"
ren Age age
gen adulteq=.
replace adulteq=0.4 if (age<3 & age>=0)
replace adulteq=0.48 if (age<5 & age>2)
replace adulteq=0.56 if (age<7 & age>4)
replace adulteq=0.64 if (age<9 & age>6)
replace adulteq=0.76 if (age<11 & age>8)
replace adulteq=0.80 if (age<=12 & age>10) & gender=="1"		//1=male, 2=female
replace adulteq=0.88 if (age<=12 & age>10) & gender=="2"      
replace adulteq=1 if (age<15 & age>12)
replace adulteq=1.2 if (age<19 & age>14) & gender=="1"
replace adulteq=1 if (age<19 & age>14) & gender=="2"
replace adulteq=1 if (age<60 & age>18) & gender=="1"
replace adulteq=0.88 if (age<60 & age>18) & gender=="2"
replace adulteq=0.8 if (age>59 & age!=.) & gender=="1"
replace adulteq=0.72 if (age>59 & age!=.) & gender=="2"
replace adulteq=. if age==999
lab var adulteq "Adult-Equivalent"
gen hh_members=1
collapse (max) fhh (sum) hh_members adulteq, by(HHID)
merge 1:m HHID using "${India_HCE_W1_raw_data}/Type 1/Identification of Sample Household - Block 1 and 2 - Level 1 -  68.dta", nogen keep (1 3)

****Currency Conversion Factors***
gen ccf_loc = (1 + $India_HCE_W1_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $TZS"
*gen ccf_usd = (1 + $India_HCE_W1_inflation)/$India_HCE_W1_exchange_rate 
*lab var ccf_usd "currency conversion factor - 2017 $USD"
*gen ccf_1ppp = (1 + $India_HCE_W1_inflation)/ $India_HCE_W1_cons_ppp_dolar
*lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $India_HCE_W1_inflation)/ $India_HCE_W1_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"

ren Combined_multiplier weight
ren District district 
ren Stratum stratum
ren State_region state
gen rural = (Sector=="1") 
lab var rural "1=Household lives in a rural area"
ren HHID hhid
keep hhid state district stratum rural weight fhh hh_members adulteq State_code

save "${created_data}/India_HCE_W1_hhids.dta", replace


********************************************************************************
*CONSUMPTION - Type 1
******************************************************************************** 
use "${India_HCE_W1_raw_data}\Type 1\Consumption of cereals-pulses- milk and milk products  during the last 30 days  - Block 5.1- 5.2- 6 - Level 5 - 68.dta", clear
ren HHID hhid
merge m:1 hhid using "${created_data}/India_HCE_W1_hhids.dta", nogen keep (1 3)

destring Item_Code, gen(item_code)
tab item_code

* recode food categories
gen crop_category1=""			
replace crop_category1=	"Rice"	if  item_code==	101
replace crop_category1=	"Rice"	if  item_code==	102
replace crop_category1=	"Rice"	if  item_code==	103
replace crop_category1=	"Rice"	if  item_code==	104
replace crop_category1=	"Rice"	if  item_code==	105
replace crop_category1=	"Rice"	if  item_code==	106
replace crop_category1=	"Wheat"	if  item_code==	107
replace crop_category1=	"Wheat"	if  item_code==	108
replace crop_category1=	"Wheat"	if  item_code==	110
replace crop_category1=	"Wheat"	if  item_code==	111
replace crop_category1=	"Rice"	if  item_code==	112
replace crop_category1=	"Wheat"	if  item_code==	113
replace crop_category1=	"Wheat"	if  item_code==	114
replace crop_category1=	"Millet and Sorghum"	if  item_code==	115
replace crop_category1=	"Millet and Sorghum"	if  item_code==	116
replace crop_category1=	"Maize"	if  item_code==	117
replace crop_category1=	"Other Cereals"	if  item_code==	118
replace crop_category1=	"Millet and Sorghum"	if  item_code==	120
replace crop_category1=	"Millet and Sorghum"	if  item_code==	121
replace crop_category1=	"Other Cereals"	if  item_code==	122
replace crop_category1=	"Other Cereals"	if  item_code==	129
replace crop_category1=	"Cassava"	if  item_code==	139
replace crop_category1=	"Pulses"	if  item_code==	140
replace crop_category1=	"Pulses"	if  item_code==	141
replace crop_category1=	"Pulses"	if  item_code==	142
replace crop_category1=	"Pulses"	if  item_code==	143
replace crop_category1=	"Pulses"	if  item_code==	144
replace crop_category1=	"Pulses"	if  item_code==	145
replace crop_category1=	"Pulses"	if  item_code==	146
replace crop_category1=	"Pulses"	if  item_code==	147
replace crop_category1=	"Pulses"	if  item_code==	148
replace crop_category1=	"Pulses"	if  item_code==	150
replace crop_category1=	"Pulses"	if  item_code==	151
replace crop_category1=	"Pulses"	if  item_code==	152
replace crop_category1=	"Pulses"	if  item_code==	159
replace crop_category1=	"Dairy"	if  item_code==	160
replace crop_category1=	"Dairy"	if  item_code==	161
replace crop_category1=	"Dairy"	if  item_code==	162
replace crop_category1=	"Dairy"	if  item_code==	163
replace crop_category1=	"Oils, Fats"	if  item_code==	164
replace crop_category1=	"Oils, Fats"	if  item_code==	165
replace crop_category1=	"Dairy"	if  item_code==	166
replace crop_category1=	"Dairy"	if  item_code==	167
replace crop_category1=	"Dairy"	if  item_code==	169
replace crop_category1=	"Spices"	if  item_code==	170
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	171
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	172
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	173
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	174
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	175
replace crop_category1=	"Spices"	if  item_code==	179
replace crop_category1=	"Oils, Fats"	if  item_code==	180
replace crop_category1=	"Oils, Fats"	if  item_code==	181
replace crop_category1=	"Oils, Fats"	if  item_code==	182
replace crop_category1=	"Oils, Fats"	if  item_code==	183
replace crop_category1=	"Oils, Fats"	if  item_code==	184
replace crop_category1=	"Oils, Fats"	if  item_code==	185
replace crop_category1=	"Oils, Fats"	if  item_code==	189
replace crop_category1=	"Eggs"	if  item_code==	190
replace crop_category1=	"Fish and Seafood" 	if  item_code==	191
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	192
replace crop_category1=	"Beef Meat"	if  item_code==	193
replace crop_category1=	"Pork Meat"	if  item_code==	194
replace crop_category1=	"Poultry Meat"	if  item_code==	195
replace crop_category1=	"Other Meat"	if  item_code==	196
replace crop_category1=	"Other Meat"	if  item_code==	199
replace crop_category1=	"Potato"	if  item_code==	200
replace crop_category1=	"Vegetables"	if  item_code==	201
replace crop_category1=	"Vegetables"	if  item_code==	202
replace crop_category1=	"Vegetables"	if  item_code==	203
replace crop_category1=	"Vegetables"	if  item_code==	204
replace crop_category1=	"Vegetables"	if  item_code==	205
replace crop_category1=	"Vegetables"	if  item_code==	206
replace crop_category1=	"Vegetables"	if  item_code==	207
replace crop_category1=	"Vegetables"	if  item_code==	208
replace crop_category1=	"Vegetables"	if  item_code==	210
replace crop_category1=	"Vegetables"	if  item_code==	211
replace crop_category1=	"Vegetables"	if  item_code==	212
replace crop_category1=	"Vegetables"	if  item_code==	213
replace crop_category1=	"Vegetables"	if  item_code==	214
replace crop_category1=	"Pulses"	if  item_code==	215
replace crop_category1=	"Fruits"	if  item_code==	216
replace crop_category1=	"Vegetables"	if  item_code==	217
replace crop_category1=	"Vegetables"	if  item_code==	219
replace crop_category1=	"Fruits"	if  item_code==	220
replace crop_category1=	"Fruits"	if  item_code==	221
replace crop_category1=	"Fruits"	if  item_code==	222
replace crop_category1=	"Fruits"	if  item_code==	223
replace crop_category1=	"Fruits"	if  item_code==	224
replace crop_category1=	"Fruits"	if  item_code==	225
replace crop_category1=	"Fruits"	if  item_code==	226
replace crop_category1=	"Fruits"	if  item_code==	227
replace crop_category1=	"Fruits"	if  item_code==	228
replace crop_category1=	"Fruits"	if  item_code==	230
replace crop_category1=	"Fruits"	if  item_code==	231
replace crop_category1=	"Fruits"	if  item_code==	232
replace crop_category1=	"Fruits"	if  item_code==	233
replace crop_category1=	"Fruits"	if  item_code==	234
replace crop_category1=	"Fruits"	if  item_code==	235
replace crop_category1=	"Fruits"	if  item_code==	236
replace crop_category1=	"Fruits"	if  item_code==	237
replace crop_category1=	"Fruits"	if  item_code==	238
replace crop_category1=	"Fruits"	if  item_code==	239
replace crop_category1=	"Fruits"	if  item_code==	240
replace crop_category1=	"Nuts and Seeds"	if  item_code==	241
replace crop_category1=	"Fruits"	if  item_code==	242
replace crop_category1=	"Nuts and Seeds"	if  item_code==	243
replace crop_category1=	"Nuts and Seeds"	if  item_code==	244
replace crop_category1=	"Nuts and Seeds"	if  item_code==	245
replace crop_category1=	"Fruits"	if  item_code==	246
replace crop_category1=	"Fruits"	if  item_code==	247
replace crop_category1=	"Fruits"	if  item_code==	249
replace crop_category1=	"Spices"	if  item_code==	250
replace crop_category1=	"Spices"	if  item_code==	251
replace crop_category1=	"Spices"	if  item_code==	252
replace crop_category1=	"Spices"	if  item_code==	253
replace crop_category1=	"Spices"	if  item_code==	254
replace crop_category1=	"Spices"	if  item_code==	255
replace crop_category1=	"Spices"	if  item_code==	256
replace crop_category1=	"Spices"	if  item_code==	257
replace crop_category1=	"Spices"	if  item_code==	258
replace crop_category1=	"Spices"	if  item_code==	260
replace crop_category1=	"Spices"	if  item_code==	261
replace crop_category1=	"Spices"	if  item_code==	269
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	270
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	271
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	272
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	273
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	274
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	275
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	276
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	277
replace crop_category1=	"Other Food"	if  item_code==	279
replace crop_category1=	"Other Food"	if  item_code==	280
replace crop_category1=	"Other Food"	if  item_code==	281
replace crop_category1=	"Other Food"	if  item_code==	282
replace crop_category1=	"Other Food"	if  item_code==	283
replace crop_category1=	"Other Food"	if  item_code==	284
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	289
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	290
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	291
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	292
replace crop_category1=	"Potato"	if  item_code==	293
replace crop_category1=	"Vegetables"	if  item_code==	294
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	295
replace crop_category1=	"Other Food"	if  item_code==	296
replace crop_category1=	"Other Food"	if  item_code==	299
replace crop_category1=	"Vegetables"	if  item_code==	300
replace crop_category1=	"Vegetables"	if  item_code==	301
replace crop_category1=	"Vegetables"	if  item_code==	302
replace crop_category1=	"Vegetables"	if  item_code==	309
replace crop_category1=	"Tobacco"	if  item_code==	310
replace crop_category1=	"Tobacco"	if  item_code==	311
replace crop_category1=	"Tobacco"	if  item_code==	312
replace crop_category1=	"Tobacco"	if  item_code==	313
replace crop_category1=	"Tobacco"	if  item_code==	314
replace crop_category1=	"Tobacco"	if  item_code==	315
replace crop_category1=	"Tobacco"	if  item_code==	316
replace crop_category1=	"Tobacco"	if  item_code==	317
replace crop_category1=	"Tobacco"	if  item_code==	319
replace crop_category1=	"Tobacco"	if  item_code==	320
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	321
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	322
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	323
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	324
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	325
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	329
drop if inlist(item_code, 330,331,332,333,334,335,336,337,338,340,340,341,342,343,344,345,349) //Dropping non-food consumption items - 

destring Source_Code, gen(source_code)
label define source 1"only purchase" 2"only home-grown stock" 3"both purchase and home-grown stock" 4"only free collection" 5"only exchange of goods and services" 6"only gifts" 9"Others", replace 
label values source_code source
tab source_code

ren Total_Consumption_Quantity food_consu_qty
ren Total_Consumption_Value food_consu_value
ren Home_Produce_Value food_prod_value
ren Home_Produce_Quantity food_prod_qty
gen food_purch_qty_only=food_consu_qty if source_code==1
gen food_purch_qty_other1=food_consu_qty-food_prod_qty if source_code==3
gen food_purch_qty_other2=food_consu_qty if source_code==5
egen food_purch_qty=rowtotal(food_purch_qty_only food_purch_qty_other1 food_purch_qty_other2)
gen food_gift_qty=food_consu_qty if inlist(source_code, 4,6,9)


//Unit is in Kilogram unless otherwise specified.
gen food_consu_unit=1
replace food_consu_unit=2 if inlist(item_code, 250,251,252,253,254,255,256,257,258,260,261,271,272,293,294,295,302,312,313,314,316,320)
replace food_consu_unit=3 if inlist(item_code, 160,273,274,275,276,321,322,323,324)
replace food_consu_unit=4 if inlist(item_code, 190,216,220,223,224,225,228,270,279,280,281,300,301,310,311,315)
label define unit 1"Kg" 2"Grams" 3"Liter" 4"Number"
label values food_consu_unit unit
tab food_consu_unit

gen food_purch_unit = food_consu_unit
gen food_prod_unit = food_consu_unit
gen food_gift_unit = food_consu_unit


recode food_consu_qty (.=0)

*Impute the value of consumption using prices inferred from the quantity and value of total consumption and home produce.
gen price_unit=food_consu_value/food_consu_qty
gen price_unitx=food_prod_value/food_prod_qty
replace price_unit=price_unitx if source_code==2   // APN: Valuing own-production consumption using the home produce value and quantity.
recode price_unit (0=.)

gen country=1 
save "${created_data}/India_HCE_W1_consumption_purchase_Type1.dta", replace
 
*Valuation using price_per_unit
global pgeo_vars country state district stratum
local len : word count $pgeo_vars
while `len'!=0 {
	local g : word  `len' of $pgeo_vars
	di "`g'"
	use "${created_data}/India_HCE_W1_consumption_purchase_Type1.dta", clear
	qui drop if price_unit==.
	qui gen observation = 1
	qui bys $pgeo_vars item_code food_purch_unit: egen obs_`g' = count(observation)
	collapse (median) price_unit [aw=weight], by ($pgeo_vars item_code food_purch_unit obs_`g')
	ren price_unit price_unit_median_`g'
	lab var price_unit_median_`g' "Median price per unit for this crop - `g'"
	lab var obs_`g' "Number of observations for this crop - `g'"
	qui save "${created_data}/India_HCE_W1_item_prices_Type1_`g'.dta", replace
	global pgeo_vars=subinstr("$pgeo_vars","`g'","",1)
	local len=`len'-1
}
 


*Pull prices into consumption estimates
use "${created_data}/India_HCE_W1_consumption_purchase_Type1.dta", clear
merge m:1 hhid using "${created_data}/India_HCE_W1_hhids.dta", nogen keep(1 3) 
*gen food_purch_unit_old=food_purch_unit_new


** Value consumption, production, and given when the units does not match the units of purchased
foreach f in consu prod gift {
preserve
drop food_consu_value food_prod_value
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit==food_purch_unit

 *- using stratum medians with at least 10 observations   
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 state district stratum item_code food_purch_unit using "${created_data}/India_HCE_W1_item_prices_Type1_stratum.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_stratum if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_stratum>10 & obs_stratum!=.

*- using district medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 state district item_code food_purch_unit using "${created_data}/India_HCE_W1_item_prices_Type1_district.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_district if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_district>10 & obs_district!=.

*- using state medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 state item_code food_purch_unit using "${created_data}/India_HCE_W1_item_prices_Type1_state.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_state if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_state>10 & obs_state!=.

*- using country medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 item_code food_purch_unit using "${created_data}/India_HCE_W1_item_prices_Type1_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid item_code crop_category1 food_`f'_value
save "${created_data}/India_HCE_W1_consumption_purchase_Type1_`f'.dta", replace
restore
}



merge 1:1  hhid item_code crop_category1  using "${created_data}/India_HCE_W1_consumption_purchase_Type1_consu.dta", nogen
*merge 1:1  hhid item_code crop_category1  using "${created_data}/India_HCE_W1_consumption_purchase_Type1_purch.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${created_data}/India_HCE_W1_consumption_purchase_Type1_prod.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${created_data}/India_HCE_W1_consumption_purchase_Type1_gift.dta", nogen

gen food_purch_value=food_purch_qty*price_unit

collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid crop_category1)
recode  food_consu_value food_purch_value food_prod_value food_gift_value (.=0)
*replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${created_data}/India_HCE_W1_food_home_consumption_value_Type1.dta", replace

*convert to biannual value by multiplying with 26
replace food_consu_value=food_consu_value*26
replace food_purch_value=food_purch_value*26 
replace food_prod_value=food_prod_value*26 
replace food_gift_value=food_gift_value*26 

*merge survey weight and household head variables
merge m:1 hhid using "${created_data}/India_HCE_W1_hhids.dta", nogen keep(1 3)

label var food_consu_value "Annual value of food consumed, nominal"
label var food_purch_value "Annual value of food purchased, nominal"
label var food_prod_value "Annual value of food produced, nominal"
label var food_gift_value "Annual value of food received, nominal"
lab var fhh "1= Female-headed household"
lab var hh_members "Number of household members"
lab var adulteq "Adult-Equivalent"
lab var crop_category1 "Food items"
lab var hhid "Household ID"

gen visit="Type 1"
save "${created_data}/India_HCE_W1_food_consumption_value_Type1.dta", replace



********************************************************************************
*CONSUMPTION - Type 2
******************************************************************************** 
use "${India_HCE_W1_raw_data}\Type 2\Consumption of cereals-pulses- milk and milk products  during the last 30 days   - Block 5.1- 5.2- 6 - Level 5 - type 2 -  68.dta", clear
ren HHID hhid
merge m:1 hhid using "${created_data}/India_HCE_W1_hhids.dta", nogen keep (1 3)

destring Item_Code, gen(item_code)
tab item_code

* recode food categories
gen crop_category1=""			
replace crop_category1=	"Rice"	if  item_code==	101
replace crop_category1=	"Rice"	if  item_code==	102
replace crop_category1=	"Rice"	if  item_code==	103
replace crop_category1=	"Rice"	if  item_code==	104
replace crop_category1=	"Rice"	if  item_code==	105
replace crop_category1=	"Rice"	if  item_code==	106
replace crop_category1=	"Wheat"	if  item_code==	107
replace crop_category1=	"Wheat"	if  item_code==	108
replace crop_category1=	"Wheat"	if  item_code==	110
replace crop_category1=	"Wheat"	if  item_code==	111
replace crop_category1=	"Rice"	if  item_code==	112
replace crop_category1=	"Wheat"	if  item_code==	113
replace crop_category1=	"Wheat"	if  item_code==	114
replace crop_category1=	"Millet and Sorghum"	if  item_code==	115
replace crop_category1=	"Millet and Sorghum"	if  item_code==	116
replace crop_category1=	"Maize"	if  item_code==	117
replace crop_category1=	"Other Cereals"	if  item_code==	118
replace crop_category1=	"Millet and Sorghum"	if  item_code==	120
replace crop_category1=	"Millet and Sorghum"	if  item_code==	121
replace crop_category1=	"Other Cereals"	if  item_code==	122
replace crop_category1=	"Other Cereals"	if  item_code==	129
replace crop_category1=	"Cassava"	if  item_code==	139
replace crop_category1=	"Pulses"	if  item_code==	140
replace crop_category1=	"Pulses"	if  item_code==	141
replace crop_category1=	"Pulses"	if  item_code==	142
replace crop_category1=	"Pulses"	if  item_code==	143
replace crop_category1=	"Pulses"	if  item_code==	144
replace crop_category1=	"Pulses"	if  item_code==	145
replace crop_category1=	"Pulses"	if  item_code==	146
replace crop_category1=	"Pulses"	if  item_code==	147
replace crop_category1=	"Pulses"	if  item_code==	148
replace crop_category1=	"Pulses"	if  item_code==	150
replace crop_category1=	"Pulses"	if  item_code==	151
replace crop_category1=	"Pulses"	if  item_code==	152
replace crop_category1=	"Pulses"	if  item_code==	159
replace crop_category1=	"Dairy"	if  item_code==	160
replace crop_category1=	"Dairy"	if  item_code==	161
replace crop_category1=	"Dairy"	if  item_code==	162
replace crop_category1=	"Dairy"	if  item_code==	163
replace crop_category1=	"Oils, Fats"	if  item_code==	164
replace crop_category1=	"Oils, Fats"	if  item_code==	165
replace crop_category1=	"Dairy"	if  item_code==	166
replace crop_category1=	"Dairy"	if  item_code==	167
replace crop_category1=	"Dairy"	if  item_code==	169
replace crop_category1=	"Spices"	if  item_code==	170
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	171
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	172
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	173
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	174
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	175
replace crop_category1=	"Spices"	if  item_code==	179
replace crop_category1=	"Oils, Fats"	if  item_code==	180
replace crop_category1=	"Oils, Fats"	if  item_code==	181
replace crop_category1=	"Oils, Fats"	if  item_code==	182
replace crop_category1=	"Oils, Fats"	if  item_code==	183
replace crop_category1=	"Oils, Fats"	if  item_code==	184
replace crop_category1=	"Oils, Fats"	if  item_code==	185
replace crop_category1=	"Oils, Fats"	if  item_code==	189
replace crop_category1=	"Eggs"	if  item_code==	190
replace crop_category1=	"Fish and Seafood" 	if  item_code==	191
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	192
replace crop_category1=	"Beef Meat"	if  item_code==	193
replace crop_category1=	"Pork Meat"	if  item_code==	194
replace crop_category1=	"Poultry Meat"	if  item_code==	195
replace crop_category1=	"Other Meat"	if  item_code==	196
replace crop_category1=	"Other Meat"	if  item_code==	199
replace crop_category1=	"Potato"	if  item_code==	200
replace crop_category1=	"Vegetables"	if  item_code==	201
replace crop_category1=	"Vegetables"	if  item_code==	202
replace crop_category1=	"Vegetables"	if  item_code==	203
replace crop_category1=	"Vegetables"	if  item_code==	204
replace crop_category1=	"Vegetables"	if  item_code==	205
replace crop_category1=	"Vegetables"	if  item_code==	206
replace crop_category1=	"Vegetables"	if  item_code==	207
replace crop_category1=	"Vegetables"	if  item_code==	208
replace crop_category1=	"Vegetables"	if  item_code==	210
replace crop_category1=	"Vegetables"	if  item_code==	211
replace crop_category1=	"Vegetables"	if  item_code==	212
replace crop_category1=	"Vegetables"	if  item_code==	213
replace crop_category1=	"Vegetables"	if  item_code==	214
replace crop_category1=	"Pulses"	if  item_code==	215
replace crop_category1=	"Fruits"	if  item_code==	216
replace crop_category1=	"Vegetables"	if  item_code==	217
replace crop_category1=	"Vegetables"	if  item_code==	219
replace crop_category1=	"Fruits"	if  item_code==	220
replace crop_category1=	"Fruits"	if  item_code==	221
replace crop_category1=	"Fruits"	if  item_code==	222
replace crop_category1=	"Fruits"	if  item_code==	223
replace crop_category1=	"Fruits"	if  item_code==	224
replace crop_category1=	"Fruits"	if  item_code==	225
replace crop_category1=	"Fruits"	if  item_code==	226
replace crop_category1=	"Fruits"	if  item_code==	227
replace crop_category1=	"Fruits"	if  item_code==	228
replace crop_category1=	"Fruits"	if  item_code==	230
replace crop_category1=	"Fruits"	if  item_code==	231
replace crop_category1=	"Fruits"	if  item_code==	232
replace crop_category1=	"Fruits"	if  item_code==	233
replace crop_category1=	"Fruits"	if  item_code==	234
replace crop_category1=	"Fruits"	if  item_code==	235
replace crop_category1=	"Fruits"	if  item_code==	236
replace crop_category1=	"Fruits"	if  item_code==	237
replace crop_category1=	"Fruits"	if  item_code==	238
replace crop_category1=	"Fruits"	if  item_code==	239
replace crop_category1=	"Fruits"	if  item_code==	240
replace crop_category1=	"Nuts and Seeds"	if  item_code==	241
replace crop_category1=	"Fruits"	if  item_code==	242
replace crop_category1=	"Nuts and Seeds"	if  item_code==	243
replace crop_category1=	"Nuts and Seeds"	if  item_code==	244
replace crop_category1=	"Nuts and Seeds"	if  item_code==	245
replace crop_category1=	"Fruits"	if  item_code==	246
replace crop_category1=	"Fruits"	if  item_code==	247
replace crop_category1=	"Fruits"	if  item_code==	249
replace crop_category1=	"Spices"	if  item_code==	250
replace crop_category1=	"Spices"	if  item_code==	251
replace crop_category1=	"Spices"	if  item_code==	252
replace crop_category1=	"Spices"	if  item_code==	253
replace crop_category1=	"Spices"	if  item_code==	254
replace crop_category1=	"Spices"	if  item_code==	255
replace crop_category1=	"Spices"	if  item_code==	256
replace crop_category1=	"Spices"	if  item_code==	257
replace crop_category1=	"Spices"	if  item_code==	258
replace crop_category1=	"Spices"	if  item_code==	260
replace crop_category1=	"Spices"	if  item_code==	261
replace crop_category1=	"Spices"	if  item_code==	269
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	270
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	271
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	272
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	273
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	274
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	275
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	276
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	277
replace crop_category1=	"Other Food"	if  item_code==	279
replace crop_category1=	"Other Food"	if  item_code==	280
replace crop_category1=	"Other Food"	if  item_code==	281
replace crop_category1=	"Other Food"	if  item_code==	282
replace crop_category1=	"Other Food"	if  item_code==	283
replace crop_category1=	"Other Food"	if  item_code==	284
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	289
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	290
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	291
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	292
replace crop_category1=	"Potato"	if  item_code==	293
replace crop_category1=	"Vegetables"	if  item_code==	294
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	295
replace crop_category1=	"Other Food"	if  item_code==	296
replace crop_category1=	"Other Food"	if  item_code==	299
replace crop_category1=	"Vegetables"	if  item_code==	300
replace crop_category1=	"Vegetables"	if  item_code==	301
replace crop_category1=	"Vegetables"	if  item_code==	302
replace crop_category1=	"Vegetables"	if  item_code==	309
replace crop_category1=	"Tobacco"	if  item_code==	310
replace crop_category1=	"Tobacco"	if  item_code==	311
replace crop_category1=	"Tobacco"	if  item_code==	312
replace crop_category1=	"Tobacco"	if  item_code==	313
replace crop_category1=	"Tobacco"	if  item_code==	314
replace crop_category1=	"Tobacco"	if  item_code==	315
replace crop_category1=	"Tobacco"	if  item_code==	316
replace crop_category1=	"Tobacco"	if  item_code==	317
replace crop_category1=	"Tobacco"	if  item_code==	319
replace crop_category1=	"Tobacco"	if  item_code==	320
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	321
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	322
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	323
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	324
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	325
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	329
drop if inlist(item_code, 330,331,332,333,334,335,336,337,338,340,340,341,342,343,344,345,349) //Dropping non-food consumption items - 

destring Source_Code, gen(source_code)
label define source 1"only purchase" 2"only home-grown stock" 3"both purchase and home-grown stock" 4"only free collection" 5"only exchange of goods and services" 6"Only gifts" 9"Others", replace 
label values source_code source
tab source_code

ren Total_Consumption_Quantity food_consu_qty
ren Total_Consumption_Value food_consu_value
ren Home_Produce_Value food_prod_value
ren Home_Produce_Quantity food_prod_qty
gen food_purch_qty_only=food_consu_qty if source_code==1
gen food_purch_qty_other1=food_consu_qty-food_prod_qty if source_code==3
gen food_purch_qty_other2=food_consu_qty if source_code==5
egen food_purch_qty=rowtotal(food_purch_qty_only food_purch_qty_other1 food_purch_qty_other2)
gen food_gift_qty=food_consu_qty if inlist(source_code, 4,6,9)

//Unit is in Kilogram unless otherwise specified.
gen food_consu_unit=1
replace food_consu_unit=2 if inlist(item_code, 250,251,252,253,254,255,256,257,258,260,261,271,272,293,294,295,302,312,313,314,316,320)
replace food_consu_unit=3 if inlist(item_code, 160,273,274,275,276,321,322,323,324)
replace food_consu_unit=4 if inlist(item_code, 190,216,220,223,224,225,228,270,279,280,281,300,301,310,311,315)
label define unit 1"Kg" 2"Grams" 3"Liter" 4"Number"
label values food_consu_unit unit
tab food_consu_unit

gen food_purch_unit = food_consu_unit
gen food_prod_unit = food_consu_unit
gen food_gift_unit = food_consu_unit


recode food_consu_qty (.=0)

*Impute the value of consumption using prices inferred from the quantity and value of total consumption and home produce.
gen price_unit=food_consu_value/food_consu_qty
gen price_unitx=food_prod_value/food_prod_qty
replace price_unit=price_unitx if source_code==2   // APN: Valuing own-production consumption using the home produce value and quantity.
recode price_unit (0=.)

gen country=1 
save "${created_data}/India_HCE_W1_consumption_purchase_Type2.dta", replace
 
*Valuation using price_per_unit
global pgeo_vars country state district stratum
local len : word count $pgeo_vars
while `len'!=0 {
	local g : word  `len' of $pgeo_vars
	di "`g'"
	use "${created_data}/India_HCE_W1_consumption_purchase_Type2.dta", clear
	qui drop if price_unit==.
	qui gen observation = 1
	qui bys $pgeo_vars item_code food_purch_unit: egen obs_`g' = count(observation)
	collapse (median) price_unit [aw=weight], by ($pgeo_vars item_code food_purch_unit obs_`g')
	ren price_unit price_unit_median_`g'
	lab var price_unit_median_`g' "Median price per unit for this crop - `g'"
	lab var obs_`g' "Number of observations for this crop - `g'"
	qui save "${created_data}/India_HCE_W1_item_prices_Type2_`g'.dta", replace
	global pgeo_vars=subinstr("$pgeo_vars","`g'","",1)
	local len=`len'-1
}
 


*Pull prices into consumption estimates
use "${created_data}/India_HCE_W1_consumption_purchase_Type2.dta", clear
merge m:1 hhid using "${created_data}/India_HCE_W1_hhids.dta", nogen keep(1 3) 

* Value consumption, production, and given when the units does not match the units of purchased

foreach f in consu prod gift {
preserve
drop food_consu_value food_prod_value
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit==food_purch_unit  //same unit of measurement for purchased, production and gifts

 
*- using stratum medians with at least 10 observations   
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 state district stratum item_code food_purch_unit using "${created_data}/India_HCE_W1_item_prices_Type2_stratum.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_stratum if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_stratum>10 & obs_stratum!=.

*- using district medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 state district item_code food_purch_unit using "${created_data}/India_HCE_W1_item_prices_Type2_district.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_district if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_district>10 & obs_district!=.

*- using state medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 state item_code food_purch_unit using "${created_data}/India_HCE_W1_item_prices_Type2_state.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_state if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_state>10 & obs_state!=.

*- using country medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 item_code food_purch_unit using "${created_data}/India_HCE_W1_item_prices_Type2_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid item_code crop_category1 food_`f'_value
save "${created_data}/India_HCE_W1_consumption_purchase_Type2_`f'.dta", replace
restore
}

merge 1:1  hhid item_code crop_category1  using "${created_data}/India_HCE_W1_consumption_purchase_Type2_consu.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${created_data}/India_HCE_W1_consumption_purchase_Type2_prod.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${created_data}/India_HCE_W1_consumption_purchase_Type2_gift.dta", nogen

gen food_purch_value=food_purch_qty*price_unit

save "${created_data}/India_HCE_W1_food_home_consumption_value_Type2.dta", replace

collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid crop_category1)
recode  food_consu_value food_purch_value food_prod_value food_gift_value (.=0)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${created_data}/India_HCE_W1_food_home_consumption_value_Type2.dta", replace


use "${created_data}/India_HCE_W1_food_home_consumption_value_Type2.dta", clear

*convert to biannual value by multiplying with 26
replace food_consu_value=food_consu_value*26
replace food_purch_value=food_purch_value*26 
replace food_prod_value=food_prod_value*26 
replace food_gift_value=food_gift_value*26 

*merge survey weight and household head variables
merge m:1 hhid using "${created_data}/India_HCE_W1_hhids.dta", nogen keep(1 3)

label var food_consu_value "Annual value of food consumed, nominal"
label var food_purch_value "Annual value of food purchased, nominal"
label var food_prod_value "Annual value of food produced, nominal"
label var food_gift_value "Annual value of food received, nominal"
lab var fhh "1= Female-headed household"
lab var hh_members "Number of household members"
lab var adulteq "Adult-Equivalent"
lab var crop_category1 "Food items"
lab var hhid "Household ID"

gen visit="Type 2"
save "${created_data}/India_HCE_W1_food_consumption_value_Type2.dta", replace


**Average of Type 1 and Type 2
use "${created_data}/India_HCE_W1_food_home_consumption_value_Type1.dta", clear
append using "${created_data}/India_HCE_W1_food_home_consumption_value_Type2.dta"
merge m:1 hhid using "${created_data}/India_HCE_W1_hhids.dta", nogen keep(1 3)

foreach v of varlist * {
		local l`v': var label `v'
}

collapse (mean) food_consu_value food_purch_value food_prod_value food_gift_value  ,by(hhid state district stratum fhh hh_members adulteq rural weight crop_category1)

foreach v of varlist * {
	label var `v' "`l`v''" 
}


save "${created_data}/India_HCE_W1_food_consumption_value_combined.dta", replace


*RESCALING the components of consumption such that the sum always match
** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value  {
	_pctile `v' [aw=weight] if `v'!=0 , p($wins_upper_thres)  
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
}
lab var crop_category1 "Food items"
save "${created_data}/India_HCE_W1_food_consumption_value_combined.dta", replace


ren state adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province"
ren district adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"
ren stratum adm3
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="India"
lab var Countr "Country name"
qui gen Instrument="India HCE W1"
lab var Instrument "Survey name"
qui gen Year="2012"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

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
replace conv_lcu_ppp=	0.004290282	if Instrument==	"India HCE W1"

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
save "${final_data}/India_HCE_W1_food_consumption_value_by_source.dta", replace


*****End of Do File*****
  
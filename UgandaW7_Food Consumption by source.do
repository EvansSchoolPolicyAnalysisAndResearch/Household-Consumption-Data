/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Uganda National Panel Survey (UNPS) LSMS-ISA Wave 7 (2018-19)

*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Uganda National Panel Survey was collected by the Uganda Bureau of Statistics
*and the World Bank's Living Standards Measurement Study - Integrated Surveys on Agriculture(LSMS - ISA)
*The data were collected over the period February 2018 - February 2019.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://microdata.worldbank.org/index.php/catalog/3795


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Uganda NPS dataset.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, rural location indicator, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Uganda_UNPS_W7_hhids.dta
*Food Consumption by source			Uganda_UNPS_W7_food_consumption_value_by_source.dta

*/



clear	
set more off
clear matrix	
clear mata	
set maxvar 8000	
ssc install findname  // need this user-written ado file for some commands to work

*Set location of raw data and output
global directory			    "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\335 - Ag Team Data Support\Waves\Uganda NPS"

//set directories: 
global Uganda_UNPS_W7_raw_data 			"$directory\uganda-wave7-2018-19\raw_data\HH"
global Uganda_UNPS_W7_created_data 		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"


********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN SUD IDS
********************************************************************************
global Uganda_UNPS_W7_exchange_rate 3704.049			// https://data.worldbank.org/indicator/PA.NUS.FCRF?locations=UG // average of 2019/2020
global Uganda_UNPS_W7_gdp_ppp_dollar 1270.6080   	// https://data.worldbank.org/indicator/PA.NUS.PPP // average of 2019/2020
global Uganda_UNPS_W7_cons_ppp_dollar 1221.0876		// https://data.worldbank.org/indicator/PA.NUS.PRVT.PP // average of 2019/2020
global Uganda_UNPS_W7_inflation -0.052659  	        	// https://data.worldbank.org/indicator/FP.CPI.TOTL.ZG?locations=UG inflation rate 2019-2020. Data was collected during 2019-2020. We want to adjust the monetary values to 2017


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Uganda_UNPS_W7_pop_tot 42949080
global Uganda_UNPS_W7_pop_rur 32486255
global Uganda_UNPS_W7_pop_urb 10462825


********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    			//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99				//  Threshold for winzorization at the top of the distribution of continous variables

****Limit crop names in variables to 6 characters or the variable names will be too long! 
global topcropname_area "maize rice wheat sorgum millet cowpea grdnt yam swtptt cassav banana cocoa soy" 
global comma_topcrop_area "1080, 1110, 2280, 1070, 1100, 1010, 1060, 1120, 2181, 1020, 2030, 3040, 2220"
global topcrop_area = subinstr("$comma_topcrop_area",","," ",.) //removing commas from the list above
global nb_topcrops : list sizeof global(topcropname_area) // Gets the current length of the global macro list "topcropname_area" 


************************
*HOUSEHOLD IDS
************************
use "${Uganda_UNPS_W7_raw_data}\gsec2.dta", clear
ren h2q8 age
ren h2q3 gender
gen fhh=(h2q4==1 & gender==2)  
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

gen age_hh= age if h2q4==1
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

collapse (max) fhh age_hh (sum) hh_members adulteq nadultworking nadultworking_female nadultworking_male nchildren nelders, by(hhid)

merge 1:1 hhid using "${Uganda_UNPS_W7_raw_data}\GSEC1.dta", nogen keep(1 3)
ren wgt weight 
ren distirct_name district_name
ren subcounty_name scounty_name
ren subcounty_code scounty_code
gen rural = (urban==0)
lab var rural "1=Household lives in a rural area"

*Generating the variable that indicate the level of representativness of the survey (to use for reporting summary stats)
gen level_representativness=.
replace level_representativness=1 if subreg==1 & rural==0
replace level_representativness=2 if subreg!=1 & rural==0
replace level_representativness=3 if region==1 & rural==1
replace level_representativness=4 if region==2 & rural==1
replace level_representativness=5 if region==4 & rural==1
replace level_representativness=6 if region==3 & rural==1

lab define lrep 1 "Kampala City"  ///
                2 "Other Urban Areas"  ///
                3 "Central Rural"   ///
                4 "Eastern Rural"  ///
                5 "Western Rural"  ///
                6 "Northern Rural"  ///
						
lab var level_representativness "Level of representivness of the survey"						
lab value level_representativness	lrep
tab level_representativness

ren day interview_day
ren month interview_month
ren year interview_year
lab var interview_day "Survey interview day"
lab var interview_month "Survey interview month"
lab var interview_year "Survey interview year"


keep hhid region regurb district_name district_code county_name county_code scounty_name scounty_code parish_name parish_code   rural weight region batch fhh hh_members adulteq age_hh nadultworking nadultworking_female nadultworking_male nchildren nelders interview_day interview_month interview_year


****Currency Conversion Factors****
gen ccf_loc = (1 + $Uganda_UNPS_W7_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $SHL"
gen ccf_usd = (1 + $Uganda_UNPS_W7_inflation)/$Uganda_UNPS_W7_exchange_rate 
lab var ccf_usd "currency conversion factor - 2017 $USD"
gen ccf_1ppp = (1 + $Uganda_UNPS_W7_inflation)/ $Uganda_UNPS_W7_cons_ppp_dollar
lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Uganda_UNPS_W7_inflation)/ $Uganda_UNPS_W7_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"

save "${Uganda_UNPS_W7_created_data}\Uganda_UNPS_W7_hhids.dta", replace

 
 
********************************************************************************
*CONSUMPTION
******************************************************************************** 
use "${Uganda_UNPS_W7_raw_data}\GSEC15A.dta", clear
keep if CEA01==1
gen str strhhid = hhid
replace hhid = ""


compress hhid
replace hhid = strhhid
drop strhhid
tempfile hh1 hh2 
save `hh1'

use "${Uganda_UNPS_W7_raw_data}\GSEC15B.dta", clear
*keep if CEB03==1
gen str strhhid = hhid
replace hhid = ""
compress hhid
replace hhid = strhhid
drop strhhid
save `hh2'

use `hh1', clear
merge 1:m hhid using `hh2', nogen keep (1 3)

*label list HH_J00
ren CEB01 item_code
label list itmcd
* recode food categories

gen crop_category1=""				
replace crop_category1=	"Bananas and Plantains"	if  item_code==	100
replace crop_category1=	"Bananas and Plantains"	if  item_code==	101
replace crop_category1=	"Bananas and Plantains"	if  item_code==	102
replace crop_category1=	"Bananas and Plantains"	if  item_code==	103
replace crop_category1=	"Bananas and Plantains"	if  item_code==	104
replace crop_category1=	"Sweet Potato"	if  item_code==	105
replace crop_category1=	"Sweet Potato"	if  item_code==	106
replace crop_category1=	"Cassava"	if  item_code==	107
replace crop_category1=	"Cassava"	if  item_code==	108
replace crop_category1=	"Potato"	if  item_code==	109
replace crop_category1=	"Rice"	if  item_code==	110
replace crop_category1=	"Maize"	if  item_code==	111
replace crop_category1=	"Maize"	if  item_code==	112
replace crop_category1=	"Maize"	if  item_code==	113
replace crop_category1=	"Wheat"	if  item_code==	114
replace crop_category1=	"Millet and Sorghum"	if  item_code==	116
replace crop_category1=	"Beef Meat"	if  item_code==	117
replace crop_category1=	"Pork Meat"	if  item_code==	118
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	119
replace crop_category1=	"Other Meat"	if  item_code==	120
replace crop_category1=	"Poultry Meat"	if  item_code==	121
replace crop_category1=	"Fish and Seafood"	if  item_code==	122
replace crop_category1=	"Fish and Seafood"	if  item_code==	123
replace crop_category1=	"Eggs"	if  item_code==	124
replace crop_category1=	"Dairy"	if  item_code==	125
replace crop_category1=	"Dairy"	if  item_code==	126
replace crop_category1=	"Oils, Fats"	if  item_code==	127
replace crop_category1=	"Oils, Fats"	if  item_code==	128
replace crop_category1=	"Oils, Fats"	if  item_code==	129
replace crop_category1=	"Fruits"	if  item_code==	130
replace crop_category1=	"Bananas and Plantains"	if  item_code==	131
replace crop_category1=	"Fruits"	if  item_code==	132
replace crop_category1=	"Fruits"	if  item_code==	133
replace crop_category1=	"Fruits"	if  item_code==	134
replace crop_category1=	"Vegetables"	if  item_code==	135
replace crop_category1=	"Vegetables"	if  item_code==	136
replace crop_category1=	"Vegetables"	if  item_code==	137
replace crop_category1=	"Vegetables"	if  item_code==	138
replace crop_category1=	"Vegetables"	if  item_code==	139
replace crop_category1=	"Pulses"	if  item_code==	140
replace crop_category1=	"Pulses"	if  item_code==	141
replace crop_category1=	"Groundnuts"	if  item_code==	142
replace crop_category1=	"Groundnuts"	if  item_code==	143
replace crop_category1=	"Groundnuts"	if  item_code==	144
replace crop_category1=	"Pulses"	if  item_code==	145
replace crop_category1=	"Nuts and Seeds"	if  item_code==	146
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	147
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	148
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	149
replace crop_category1=	"Spices"	if  item_code==	150
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	151
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	152
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	153
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	154
replace crop_category1=	"Tobacco"	if  item_code==	155
replace crop_category1=	"Tobacco"	if  item_code==	156
replace crop_category1=	"Other food"	if  item_code==	157
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	158
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	159
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	160
replace crop_category1=	"Other food"	if  item_code==	161
replace crop_category1=	"Pulses"	if  item_code==	162
replace crop_category1=	"Groundnuts"	if  item_code==	163
replace crop_category1=	"Vegetables"	if  item_code==	164
replace crop_category1=	"Vegetables"	if  item_code==	165
replace crop_category1=	"Vegetables"	if  item_code==	166
replace crop_category1=	"Vegetables"	if  item_code==	167
replace crop_category1=	"Vegetables"	if  item_code==	168
replace crop_category1=	"Fruits"	if  item_code==	169
replace crop_category1=	"Fruits"	if  item_code==	170
replace crop_category1=	"Fruits"	if  item_code==	171
replace crop_category1=	"Wheat"	if  item_code==	172
replace crop_category1=	"Wheat"	if  item_code==	173
replace crop_category1=	"Fruits"	if  item_code==	174
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	175
replace crop_category1=	"Pulses"	if  item_code==	176
replace crop_category1=	"Bananas and Plantains"	if  item_code==	1041
replace crop_category1=	"Bananas and Plantains"	if  item_code==	1042
replace crop_category1=	"Bananas and Plantains"	if  item_code==	1043
replace crop_category1=	"Sweet Potato"	if  item_code==	1051
replace crop_category1=	"Sweet Potato"	if  item_code==	1052
replace crop_category1=	"Sweet Potato"	if  item_code==	1061
replace crop_category1=	"Sweet Potato"	if  item_code==	1062
replace crop_category1=	"Sweet Potato"	if  item_code==	1063
replace crop_category1=	"Sweet Potato"	if  item_code==	1064
replace crop_category1=	"Cassava"	if  item_code==	1081
replace crop_category1=	"Cassava"	if  item_code==	1082
replace crop_category1=	"Wheat"	if  item_code==	1083
replace crop_category1=	"Rice"	if  item_code==	1101
replace crop_category1=	"Rice"	if  item_code==	1102
replace crop_category1=	"Rice"	if  item_code==	1103
replace crop_category1=	"Maize"	if  item_code==	1111
replace crop_category1=	"Maize"	if  item_code==	1112
replace crop_category1=	"Maize"	if  item_code==	1121
replace crop_category1=	"Maize"	if  item_code==	1122
replace crop_category1=	"Maize"	if  item_code==	1131
replace crop_category1=	"Maize"	if  item_code==	1132
replace crop_category1=	"Millet and Sorghum"	if  item_code==	1151
replace crop_category1=	"Beef Meat"	if  item_code==	1171
replace crop_category1=	"Beef Meat"	if  item_code==	1172
replace crop_category1=	"Beef Meat"	if  item_code==	1173
replace crop_category1=	"Other Meat"	if  item_code==	1174
replace crop_category1=	"Pork Meat"	if  item_code==	1181
replace crop_category1=	"Pork Meat"	if  item_code==	1182
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	1191
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	1192
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	1193
replace crop_category1=	"Other Meat"	if  item_code==	1201
replace crop_category1=	"Poultry Meat"	if  item_code==	1211
replace crop_category1=	"Poultry Meat"	if  item_code==	1212
replace crop_category1=	"Poultry Meat"	if  item_code==	1213
replace crop_category1=	"Poultry Meat"	if  item_code==	1214
replace crop_category1=	"Poultry Meat"	if  item_code==	1215
replace crop_category1=	"Fish and Seafood"	if  item_code==	1221
replace crop_category1=	"Fish and Seafood"	if  item_code==	1222
replace crop_category1=	"Fish and Seafood"	if  item_code==	1231
replace crop_category1=	"Fish and Seafood"	if  item_code==	1232
replace crop_category1=	"Fish and Seafood"	if  item_code==	1234
replace crop_category1=	"Fish and Seafood"	if  item_code==	1235
replace crop_category1=	"Fish and Seafood"	if  item_code==	1236
replace crop_category1=	"Fish and Seafood"	if  item_code==	1237
replace crop_category1=	"Eggs"	if  item_code==	1241
replace crop_category1=	"Eggs"	if  item_code==	1242
replace crop_category1=	"Eggs"	if  item_code==	1243
replace crop_category1=	"Dairy"	if  item_code==	1251
replace crop_category1=	"Dairy"	if  item_code==	1252
replace crop_category1=	"Dairy"	if  item_code==	1253
replace crop_category1=	"Dairy"	if  item_code==	1254
replace crop_category1=	"Oils, Fats"	if  item_code==	1271
replace crop_category1=	"Oils, Fats"	if  item_code==	1272
replace crop_category1=	"Dairy"	if  item_code==	1281
replace crop_category1=	"Oils, Fats"	if  item_code==	1291
replace crop_category1=	"Bananas and Plantains"	if  item_code==	1311
replace crop_category1=	"Bananas and Plantains"	if  item_code==	1312
replace crop_category1=	"Bananas and Plantains"	if  item_code==	1313
replace crop_category1=	"Spices"	if  item_code==	1351
replace crop_category1=	"Spices"	if  item_code==	1352
replace crop_category1=	"Spices"	if  item_code==	1353
replace crop_category1=	"Vegetables"	if  item_code==	1371
replace crop_category1=	"Vegetables"	if  item_code==	1372
replace crop_category1=	"Spices"	if  item_code==	1391
replace crop_category1=	"Nuts and Seeds"	if  item_code==	1461
replace crop_category1=	"Nuts and Seeds"	if  item_code==	1462
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	1471
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	1472
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1481
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1482
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1491
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1492
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1493
replace crop_category1=	"Spices"	if  item_code==	1501
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1601
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1602
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1603
replace crop_category1=	"Vegetables"	if  item_code==	1651
replace crop_category1=	"Vegetables"	if  item_code==	1652
replace crop_category1=	"Vegetables"	if  item_code==	1653
replace crop_category1=	"Vegetables"	if  item_code==	1654
replace crop_category1=	"Wheat"	if  item_code==	1721
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	1731
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	1732
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	1733
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	1734
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	1735
replace crop_category1=	"Yams"	if  item_code==	1741
replace crop_category1=	"Fruits"	if  item_code==	1742
replace crop_category1=	"Fruits"	if  item_code==	1743
replace crop_category1=	"Pulses"	if  item_code==	1761
replace crop_category1=	"Pulses"	if  item_code==	1762
drop if item_code==.
drop if item_code==115  //Drop items not captured in the instrument
drop if item_code==1531 //Drop items not captured in the instrument


ren CEB03 food_consu_yesno
ren CEB03C food_consu_unit
egen food_consu_qty=rowtotal(CEB06 CEB10 CEB012) if CEB06!=. | CEB10!=. | CEB012!=. // I'm removing CEB08 because it is consumption away from home

gen food_purch_unit=food_consu_unit
ren CEB06 food_purch_qty
ren CEB07 food_purch_value

ren CEB10 food_prod_qty
gen food_prod_unit=food_consu_unit
ren CEB11 food_prod_value_x
 
ren CEB012 food_gift_qty
gen food_gift_unit=food_consu_unit
ren CEB013 food_gift_value_x

label list untcds

foreach unit in food_consu food_purch food_prod food_gift {
gen `unit'_unit_new="Kg" if `unit'_unit==1
replace `unit'_unit_new=	"Kg"	if `unit'_unit==	1
replace `unit'_unit_new=	"Gram"	if `unit'_unit==	2
replace `unit'_unit_new=	"Litre"	if `unit'_unit==	3
replace `unit'_unit_new=	"Small cup wuth handle(Akendo)"	if `unit'_unit==	4
replace `unit'_unit_new=	"Metre"	if `unit'_unit==	5
replace `unit'_unit_new=	"Square metre"	if `unit'_unit==	6
replace `unit'_unit_new=	"Yard"	if `unit'_unit==	7
replace `unit'_unit_new=	"Millilitre"	if `unit'_unit==	8
replace `unit'_unit_new=	"Sack (120 kgs)"	if `unit'_unit==	9
replace `unit'_unit_new=	"Sack (100 kgs)"	if `unit'_unit==	10
replace `unit'_unit_new=	"Sack (80 kgs)"	if `unit'_unit==	11
replace `unit'_unit_new=	"Sack (50 kgs)"	if `unit'_unit==	12
replace `unit'_unit_new=	"Jerrican (20 lts)"	if `unit'_unit==	14
replace `unit'_unit_new=	"Jerrican (10 lts)"	if `unit'_unit==	15
replace `unit'_unit_new=	"Jerrican (5 lts)"	if `unit'_unit==	16
replace `unit'_unit_new=	"Jerrican (3 lts)"	if `unit'_unit==	17
replace `unit'_unit_new=	"Jerrican (2 lts)"	if `unit'_unit==	18
replace `unit'_unit_new=	"Jerrican (1 lt)"	if `unit'_unit==	19
replace `unit'_unit_new=	"Tin (Debe) - 20 lts"	if `unit'_unit==	20
replace `unit'_unit_new=	"Tin (5 lts)"	if `unit'_unit==	21
replace `unit'_unit_new=	"Plastic Basin (15 lts)"	if `unit'_unit==	22
replace `unit'_unit_new=	"Bottle(750ml)"	if `unit'_unit==	23
replace `unit'_unit_new=	"Bottle(500ml)"	if `unit'_unit==	24
replace `unit'_unit_new=	"Bottle(350ml)"	if `unit'_unit==	25
replace `unit'_unit_new=	"Bottle(300ml)"	if `unit'_unit==	26
replace `unit'_unit_new=	"Bottle(250ml)"	if `unit'_unit==	27
replace `unit'_unit_new=	"Bottle(150ml)"	if `unit'_unit==	28
replace `unit'_unit_new=	"Kimbo/Cowboy/Blueband Tin (2kg)"	if `unit'_unit==	29
replace `unit'_unit_new=	"Kimbo/Cowboy/Blueband Tin (1kg)"	if `unit'_unit==	30
replace `unit'_unit_new=	"Kimbo/Cowboy/Blueband Tin (0.5kg)"	if `unit'_unit==	31
replace `unit'_unit_new=	"Cup/Mug(0.5lt)"	if `unit'_unit==	32
replace `unit'_unit_new=	"Glass(0.25lt)"	if `unit'_unit==	33
replace `unit'_unit_new=	"Ladle(100g)"	if `unit'_unit==	34
replace `unit'_unit_new=	"Table spoon "	if `unit'_unit==	35
replace `unit'_unit_new=	"Tea spoon"	if `unit'_unit==	36
replace `unit'_unit_new=	"Basket (20 kg)"	if `unit'_unit==	37
replace `unit'_unit_new=	"Basket (10 kg)"	if `unit'_unit==	38
replace `unit'_unit_new=	"Basket (5 kg)"	if `unit'_unit==	39
replace `unit'_unit_new=	"Basket (2 kg)"	if `unit'_unit==	40
replace `unit'_unit_new=	"Buns (200 g)"	if `unit'_unit==	43
replace `unit'_unit_new=	"Buns (100 g)"	if `unit'_unit==	44
replace `unit'_unit_new=	"Buns (50 g)"	if `unit'_unit==	45
replace `unit'_unit_new=	"Bathing soap (Tablet)"	if `unit'_unit==	46
replace `unit'_unit_new=	"Washing soap (Bar)"	if `unit'_unit==	47
replace `unit'_unit_new=	"Washing soap (Tablet)"	if `unit'_unit==	48
replace `unit'_unit_new=	"Packet (2 kg)"	if `unit'_unit==	49
replace `unit'_unit_new=	"Packet (1 kg)"	if `unit'_unit==	50
replace `unit'_unit_new=	"Packet (500 g)"	if `unit'_unit==	51
replace `unit'_unit_new=	"Packet (250 g)"	if `unit'_unit==	52
replace `unit'_unit_new=	"Packet (100 g)"	if `unit'_unit==	53
replace `unit'_unit_new=	"Packet(125g)"	if `unit'_unit==	54
replace `unit'_unit_new=	"Fish Whole(small)"	if `unit'_unit==	55
replace `unit'_unit_new=	"Fish  Whole (medium)"	if `unit'_unit==	56
replace `unit'_unit_new=	"Fish   Whole  (large)"	if `unit'_unit==	57
replace `unit'_unit_new=	"Fish   Cut piece (up to 1kg)"	if `unit'_unit==	58
replace `unit'_unit_new=	"Fish   Cut piece (1 - 2 kg)"	if `unit'_unit==	59
replace `unit'_unit_new=	"Fish   Cut piece(Above 2  kg)"	if `unit'_unit==	60
replace `unit'_unit_new=	"Tray of 30 eggs"	if `unit'_unit==	61
replace `unit'_unit_new=	"Ream"	if `unit'_unit==	62
replace `unit'_unit_new=	"Crate"	if `unit'_unit==	63
replace `unit'_unit_new=	"Heap(unspecified)"	if `unit'_unit==	64
replace `unit'_unit_new=	"Dozen"	if `unit'_unit==	65
replace `unit'_unit_new=	"Bundle (Unspecified)"	if `unit'_unit==	66
replace `unit'_unit_new=	"Bunch- Big"	if `unit'_unit==	67
replace `unit'_unit_new=	"Bunch- medium"	if `unit'_unit==	68
replace `unit'_unit_new=	"Bunch- small"	if `unit'_unit==	69
replace `unit'_unit_new=	"Bunch(Big)"	if `unit'_unit==	70
replace `unit'_unit_new=	"Bunch(Medium)"	if `unit'_unit==	71
replace `unit'_unit_new=	"Bunch(Small)"	if `unit'_unit==	72
replace `unit'_unit_new=	"Cluster(Unspecified)"	if `unit'_unit==	73
replace `unit'_unit_new=	"Gourd(1-5lts)"	if `unit'_unit==	74
replace `unit'_unit_new=	"Gourd(5-10lts)"	if `unit'_unit==	75
replace `unit'_unit_new=	"Gourd (Above 10 lts)"	if `unit'_unit==	76
replace `unit'_unit_new=	"Jug (2 lts)"	if `unit'_unit==	77
replace `unit'_unit_new=	"Jug (1.5 lts)"	if `unit'_unit==	78
replace `unit'_unit_new=	"Jug (1 lt)"	if `unit'_unit==	79
replace `unit'_unit_new=	"Tot (50 ml)"	if `unit'_unit==	80
replace `unit'_unit_new=	"Tot (sachet)"	if `unit'_unit==	81
replace `unit'_unit_new=	"Tot (Unspecified)"	if `unit'_unit==	82
replace `unit'_unit_new=	"Tobacco leaf (Number)"	if `unit'_unit==	83
replace `unit'_unit_new=	"Pair"	if `unit'_unit==	84
replace `unit'_unit_new=	"Number of Units (General)"	if `unit'_unit==	85
replace `unit'_unit_new=	"Acre"	if `unit'_unit==	86			//Remove?
replace `unit'_unit_new=	"Piece-Big"	if `unit'_unit==	87
replace `unit'_unit_new=	"Piece-Medium"	if `unit'_unit==	88
replace `unit'_unit_new=	"Piece-Small"	if `unit'_unit==	89
replace `unit'_unit_new=	"Heap - Big"	if `unit'_unit==	90
replace `unit'_unit_new=	"Heap - medium"	if `unit'_unit==	91
replace `unit'_unit_new=	"Heap - small"	if `unit'_unit==	92
replace `unit'_unit_new=	"Cluster - big"	if `unit'_unit==	93
replace `unit'_unit_new=	"Cluster - medium"	if `unit'_unit==	94
replace `unit'_unit_new=	"Cluster - Small"	if `unit'_unit==	95
replace `unit'_unit_new=	"Bundle-Big"	if `unit'_unit==	96
replace `unit'_unit_new=	"Bundle-Medium"	if `unit'_unit==	97
replace `unit'_unit_new=	"Bundle-Small"	if `unit'_unit==	98
replace `unit'_unit_new=	"Others specify"	if `unit'_unit==	99
replace `unit'_unit_new=	"Fish Whole-Large"	if `unit'_unit==	100
replace `unit'_unit_new=	"Fish Whole-Medium"	if `unit'_unit==	101
replace `unit'_unit_new=	"Fish Whole-Small"	if `unit'_unit==	102
replace `unit'_unit_new=	"Plastinbasin(5ltrs)"	if `unit'_unit==	103
replace `unit'_unit_new=	"Glass(0.5ltrs)"	if `unit'_unit==	104
replace `unit'_unit_new=	"Glass(0.125ltrs)"	if `unit'_unit==	105
replace `unit'_unit_new=	"Jug(2.5ltrs)"	if `unit'_unit==	106
replace `unit'_unit_new=	"Nice cup(100g)- Large"	if `unit'_unit==	107
replace `unit'_unit_new=	"Nice cup(60g)-Medium"	if `unit'_unit==	108
replace `unit'_unit_new=	"Nice cup(50g)-Small"	if `unit'_unit==	109
replace `unit'_unit_new=	"Metallic tumbler(100g)- Big"	if `unit'_unit==	110
replace `unit'_unit_new=	"Metallic tumbler(50g)- Small"	if `unit'_unit==	111
replace `unit'_unit_new=	"Plastic tumbler(50g)- Big"	if `unit'_unit==	112
replace `unit'_unit_new=	"Plastic tumbler(30g)-Small"	if `unit'_unit==	113
replace `unit'_unit_new=	"Plastic plate(60g)-Large"	if `unit'_unit==	114
replace `unit'_unit_new=	"Plastic plate(30g)-Small"	if `unit'_unit==	115
replace `unit'_unit_new=	"Metallic plate(100g)-Large"	if `unit'_unit==	116
replace `unit'_unit_new=	"Metallic plate(80g)- Small"	if `unit'_unit==	117
replace `unit'_unit_new=	"Plastic bowl(40g)"	if `unit'_unit==	118
replace `unit'_unit_new=	"Nomi Tin(1kg)"	if `unit'_unit==	119
replace `unit'_unit_new=	"Nomi Tin(500g)"	if `unit'_unit==	120
replace `unit'_unit_new=	"Nomi Tin(250g)"	if `unit'_unit==	121
replace `unit'_unit_new=	"Nido Tin(400g)"	if `unit'_unit==	122
replace `unit'_unit_new=	"Akendo-Big"	if `unit'_unit==	123
replace `unit'_unit_new=	"Akendo-Medium"	if `unit'_unit==	124
replace `unit'_unit_new=	"Akendo-Small"	if `unit'_unit==	125
replace `unit'_unit_new=	"Jerrican(0.5ltrs)"	if `unit'_unit==	126
replace `unit'_unit_new=	"Container- Big"	if `unit'_unit==	127
replace `unit'_unit_new=	"Container-Medium"	if `unit'_unit==	128
replace `unit'_unit_new=	"Container-Small"	if `unit'_unit==	129
replace `unit'_unit_new=	"Container- Smallest"	if `unit'_unit==	130
replace `unit'_unit_new=	"Bottle(500g)"	if `unit'_unit==	131
replace `unit'_unit_new=	"Bottle(350g)"	if `unit'_unit==	132
replace `unit'_unit_new=	"Sadolin Tin- 3ltrs"	if `unit'_unit==	133
replace `unit'_unit_new=	"Loaf (Kg)"	if `unit'_unit==	134
replace `unit'_unit_new=	"Loaf (0.5kg)"	if `unit'_unit==	135
replace `unit'_unit_new=	"Bottle (1tr"	if `unit'_unit==	137
replace `unit'_unit_new=	"Bottle (1.5ltr)"	if `unit'_unit==	138
replace `unit'_unit_new=	"Bottle (2ltr)"	if `unit'_unit==	139
replace `unit'_unit_new=	"sacket (10g)"	if `unit'_unit==	140
replace `unit'_unit_new=	"Sacket (15g)"	if `unit'_unit==	141
replace `unit'_unit_new=	"Sacket (20g)"	if `unit'_unit==	142
replace `unit'_unit_new=	"Sacket (25g)"	if `unit'_unit==	143
replace `unit'_unit_new=	"Sacket (30g)"	if `unit'_unit==	144
replace `unit'_unit_new=	"Sacket (50g)"	if `unit'_unit==	145
replace `unit'_unit_new=	"Sacket (100g)"	if `unit'_unit==	146
replace `unit'_unit_new=	"Sacket (150g)"	if `unit'_unit==	147
replace `unit'_unit_new=	"Whole chicken -Big"	if `unit'_unit==	996
replace `unit'_unit_new=	"Whole chicken-Medium"	if `unit'_unit==	997
replace `unit'_unit_new=	"Whole chicken -Small"	if `unit'_unit==	998
replace `unit'_unit_new=	"Other" if `unit'_unit==99 | `unit'_unit==999

replace `unit'_qty= `unit'_qty/1000 if `unit'_unit_new=="Gram"   			//Gram to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Gram"
replace `unit'_qty= `unit'_qty*120 if `unit'_unit_new=="Sack (120 kgs)"   	// 120kg Sack to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Sack (120 kgs)"
replace `unit'_qty= `unit'_qty*100 if `unit'_unit_new=="Sack (100 kgs)"   	// 100kg Sack to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Sack (100 kgs)"
replace `unit'_qty= `unit'_qty*80 if `unit'_unit_new=="Sack (80 kgs)"   	// 80kg Sack to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Sack (80 kgs)"
replace `unit'_qty= `unit'_qty*50 if `unit'_unit_new=="Sack (50 kgs)"   	// 50kg Sack to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Sack (50 kgs)"
replace `unit'_qty= `unit'_qty*20 if `unit'_unit_new=="Jerrican (10 lts)"   // 20 lts Jerrican to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Jerrican (20 lts)"
replace `unit'_qty= `unit'_qty*10 if `unit'_unit_new=="Jerrican (10 lts)"   // 10 lts Jerrican to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Jerrican (10 lts)"
replace `unit'_qty= `unit'_qty*5 if `unit'_unit_new=="Jerrican (5 lts)"		// 5 lts Jerrican to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Jerrican (5 lts)"
replace `unit'_qty= `unit'_qty*3 if `unit'_unit_new=="Jerrican (3 lts)"		// 3 lts Jerrican to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Jerrican (3 lts)"
replace `unit'_qty= `unit'_qty*2 if `unit'_unit_new=="Jerrican (2 lts)"		// 2 lts Jerrican to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Jerrican (2 lts)"
replace `unit'_qty= `unit'_qty*1 if `unit'_unit_new=="Jerrican (1 lts)"		// 1 lt Jerrican to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Jerrican (1 lts)"

replace `unit'_qty= `unit'_qty*20 if `unit'_unit_new=="Tin (Debe) - 20 lts"	// 20 lts Tin (Debe) to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Tin (Debe) - 20 lts"
replace `unit'_qty= `unit'_qty*5 if `unit'_unit_new=="Tin (5 lts)"			// 5 lts Tin to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Tin (5 lts)"
replace `unit'_qty= `unit'_qty*15 if `unit'_unit_new=="Plastic Basin (15 lts)"	// 15 lts Plastic Basin to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Plastic Basin (15 lts)"

replace `unit'_qty= `unit'_qty/0.75 if `unit'_unit_new=="Bottle(750ml)"			// 750 ml bottle to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Bottle(750ml)"
replace `unit'_qty= `unit'_qty/0.5 if `unit'_unit_new=="Bottle(500ml)"			// 500 ml bottle  to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Bottle(500ml)"
replace `unit'_qty= `unit'_qty/0.35 if `unit'_unit_new=="Bottle(350ml)"			// 350 ml bottle to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Bottle(350ml)"
replace `unit'_qty= `unit'_qty/0.3 if `unit'_unit_new=="Bottle(300ml)"			// 300 ml bottle to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Bottle(300ml)"
replace `unit'_qty= `unit'_qty/0.15 if `unit'_unit_new=="Bottle(150ml)"			// 150 ml bottle to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Bottle(150ml)"

replace `unit'_qty= `unit'_qty*2 if `unit'_unit_new=="Kimbo/Cowboy/Blueband Tin (2kg)"			// 2 Kg Kimbo/Cowboy/Blueband Tin  to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Kimbo/Cowboy/Blueband Tin (2kg)"
replace `unit'_qty= `unit'_qty*1 if `unit'_unit_new=="Kimbo/Cowboy/Blueband Tin (1kg)"			// 1 Kg Kimbo/Cowboy/Blueband Tin  to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Kimbo/Cowboy/Blueband Tin (1kg)"
replace `unit'_qty= `unit'_qty/0.5 if `unit'_unit_new=="Kimbo/Cowboy/Blueband Tin (0.5kg)"			// 0.5 Kg Kimbo/Cowboy/Blueband Tin  to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Kimbo/Cowboy/Blueband Tin (0.5kg)"
replace `unit'_qty= `unit'_qty/0.5 if `unit'_unit_new=="Cup/Mug(0.5lt)"				// 0.5 lt Cup/Mug to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Cup/Mug(0.5lt)"
replace `unit'_qty= `unit'_qty/0.25 if `unit'_unit_new=="Glass(0.25lt)"				// 0.25 lt Glass to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Glass(0.25lt)"	

replace `unit'_qty= `unit'_qty/0.1 if `unit'_unit_new=="Ladle(100g)"				// 100g Ladle to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Ladle(100g)"	

replace `unit'_qty= `unit'_qty*20 if `unit'_unit_new=="Basket (20 kg)"				// 20 Kg Basket to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Basket (20 kg)"	
replace `unit'_qty= `unit'_qty*10 if `unit'_unit_new=="Basket (10 kg)"				// 10 Kg Basket to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Basket (10 kg)"	
replace `unit'_qty= `unit'_qty*5 if `unit'_unit_new=="Basket (5 kg)"				// 5 Kg Basket to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Basket (5 kg)"	
replace `unit'_qty= `unit'_qty*2 if `unit'_unit_new=="Basket (2 kg)"				// 2 Kg Basket to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Basket (2 kg)"	

replace `unit'_qty= `unit'_qty/0.2 if `unit'_unit_new=="Buns (200 g)"				// 200g Buns to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Buns (200 g)"	
replace `unit'_qty= `unit'_qty/0.1 if `unit'_unit_new=="Buns (100 g)"				// 100g Buns to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Buns (100 g)"	
replace `unit'_qty= `unit'_qty/0.05 if `unit'_unit_new=="Buns (50 g)"				// 50g Buns to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Buns (50 g)"	

replace `unit'_qty= `unit'_qty*2 if `unit'_unit_new=="Packet (2 kg)"				// 2 Kg Packet to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Packet (2 kg)"	
replace `unit'_qty= `unit'_qty*1 if `unit'_unit_new=="Packet (1 kg)"				// 1 Kg Packet to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Packet (1 kg)"	
replace `unit'_qty= `unit'_qty/0.5 if `unit'_unit_new=="Packet (500 g)"				// 500 Packet to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Packet (500 g)"	
replace `unit'_qty= `unit'_qty/0.25 if `unit'_unit_new=="Packet (250 g)"			// 250 Packet to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Packet (250 g)"	
replace `unit'_qty= `unit'_qty/0.1 if `unit'_unit_new=="Packet (100 g)"				// 100 Packet to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Packet (100 g)"	
replace `unit'_qty= `unit'_qty/0.125 if `unit'_unit_new=="Packet (125 g)"			// 125 Packet to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Packet (125 g)"	

replace `unit'_qty= `unit'_qty*2.5 if `unit'_unit_new=="Jug (2.5 lts)"				// 2.5 lts Jug to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Jug (2.5 lts)"
replace `unit'_qty= `unit'_qty*2 if `unit'_unit_new=="Jug (2 lts)"					// 2 lts Jug to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Jug (2 lts)"
replace `unit'_qty= `unit'_qty*1.5 if `unit'_unit_new=="Jug (1.5 lts)"				// 1.5 lts Jug to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Jug (1.5 lts)"
replace `unit'_qty= `unit'_qty*1 if `unit'_unit_new=="Jug (1 lts)"					// 1 lts Jug to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Jug (1 lts)"

replace `unit'_qty= `unit'_qty/0.05 if `unit'_unit_new=="Tot (50 ml)" 				// 50 ml Tot to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Tot (50 ml)" 
replace `unit'_qty= `unit'_qty*5 if `unit'_unit_new=="Plastinbasin(5ltrs)" 			// 5 lts Plastinbasin to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Plastinbasin(5ltrs)" 
replace `unit'_qty= `unit'_qty/0.5 if `unit'_unit_new=="Glass(0.5lt)"				// 0.5 lt Glass to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Glass(0.5lt)"	
replace `unit'_qty= `unit'_qty/0.125 if `unit'_unit_new=="Glass(0.125lt)"			// 0.125 lt Glass to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Glass(0.125lt)"	

replace `unit'_qty= `unit'_qty/0.1 if `unit'_unit_new=="Nice cup(100g)- Large"		// 100g Nomi Tin to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Nice cup(100g)- Large"	
replace `unit'_qty= `unit'_qty/0.06 if `unit'_unit_new=="Nice cup(60g)- Medium"		// 60g Nomi Tin to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Nice cup(60g)- Medium"	
replace `unit'_qty= `unit'_qty/0.05 if `unit'_unit_new=="Nice cup(50g)- Small"		// 50g Nomi Tin to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Nice cup(50g)- Small"	

replace `unit'_qty= `unit'_qty/0.1 if `unit'_unit_new=="Metallic tumbler(100g)- Big"	// 100g Metallic tumbler to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Metallic tumbler(100g)- Big"	
replace `unit'_qty= `unit'_qty/0.05 if `unit'_unit_new=="Metallic tumbler(50g)- Big"	// 50g Metallic tumbler to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Metallic tumbler(50g)- Big"	
replace `unit'_qty= `unit'_qty/0.05 if `unit'_unit_new=="Plastic tumbler(50g)- Big"		// 50g Plastic tumbler to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Plastic tumbler(50g)- Big"	
replace `unit'_qty= `unit'_qty/0.06 if `unit'_unit_new=="Plastic plate(60g)-Large"		// 60g Plastic plate to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Plastic plate(60g)-Large"	
replace `unit'_qty= `unit'_qty/0.03 if `unit'_unit_new=="Plastic plate(30g)-Small"		// 30g Plastic plate to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Plastic plate(30g)-Small"	
replace `unit'_qty= `unit'_qty/0.1 if `unit'_unit_new=="Metallic plate(100g)-Large"		// 100g Metallic plate to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Metallic plate(100g)-Large"	
replace `unit'_qty= `unit'_qty/0.08 if `unit'_unit_new=="Metallic plate(80g)-Small"		// 80g Metallic plate to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Metallic plate(80g)-Small"	
replace `unit'_qty= `unit'_qty/0.04 if `unit'_unit_new=="Plastic bowl(40g)"				// 40g Plastic bowl to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Plastic bowl(40g)"	

replace `unit'_qty= `unit'_qty*1 if `unit'_unit_new=="Nomi Tin(1kg)"			// 1 Kg Nomi Tin to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Nomi Tin(1kg)"	
replace `unit'_qty= `unit'_qty/0.5 if `unit'_unit_new=="Nomi Tin(500g)"			// 500g Nomi Tin to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Nomi Tin(500g)"	
replace `unit'_qty= `unit'_qty/0.25 if `unit'_unit_new=="Nomi Tin(250g)"		// 250g Nomi Tin to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Nomi Tin(250g)"	
replace `unit'_qty= `unit'_qty/0.4 if `unit'_unit_new=="Nomi Tin(400g)"			// 400g Nido Tin to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Nomi Tin(400g)"	

replace `unit'_qty= `unit'_qty/0.5 if `unit'_unit_new=="Bottle(500g)"			// 500g Bottle to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Bottle(500g)"	
replace `unit'_qty= `unit'_qty/0.35 if `unit'_unit_new=="Bottle(350g)"			// 350g Bottle to 1 Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Bottle(350g)"	
replace `unit'_qty= `unit'_qty*3 if `unit'_unit_new=="Sadolin Tin- 3ltrs"		// 3 lt Sadolin Tin to Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Sadolin Tin- 3ltrs"	

replace `unit'_qty= `unit'_qty/0.5 if `unit'_unit_new=="Jerrican(0.5ltrs)"		// 0.5 lts Jerrican to Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Jerrican(0.5ltrs)"	
replace `unit'_qty= `unit'_qty/0.5 if `unit'_unit_new=="Loaf (0.5 Kg)"				// 0.5 Kg Loaf to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Loaf (0.5 Kg)"	

replace `unit'_qty= `unit'_qty*2 if `unit'_unit_new=="Bottle (2ltr)"				// 2 ltr Bottle to Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Bottle (2ltr)"	
replace `unit'_qty= `unit'_qty*1.5 if `unit'_unit_new=="Bottle (1.5ltr)"			// 1.5 ltr Bottle to Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Bottle (1.5ltr)"	

replace `unit'_qty= `unit'_qty/0.01 if `unit'_unit_new=="sacket (10g)"				// 10g sacket to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="sacket (10g)"	
replace `unit'_qty= `unit'_qty/0.015 if `unit'_unit_new=="sacket (15g)"				// 15g sacket to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="sacket (15g)"	
replace `unit'_qty= `unit'_qty/0.02 if `unit'_unit_new=="sacket (20g)"				// 20g sacket to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="sacket (20g)"	
replace `unit'_qty= `unit'_qty/0.025 if `unit'_unit_new=="sacket (25g)"				// 25g sacket to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="sacket (25g)"	
replace `unit'_qty= `unit'_qty/0.03 if `unit'_unit_new=="sacket (30g)"				// 30g sacket to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="sacket (30g)"	
replace `unit'_qty= `unit'_qty/0.05 if `unit'_unit_new=="sacket (50g)"				// 50g sacket to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="sacket (50g)"	
replace `unit'_qty= `unit'_qty/0.1 if `unit'_unit_new=="sacket (100g)"				// 100g sacket to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="sacket (100g)"	
replace `unit'_qty= `unit'_qty/0.15 if `unit'_unit_new=="sacket (150g)"				// 150g sacket to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="sacket (150g)"	

replace `unit'_qty= `unit'_qty/0.125 if `unit'_unit_new=="Cowboy/BlueBand Tin (0.125Kg)"	// 125g Cowboy/BlueBand Tin to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Cowboy/BlueBand Tin (0.125Kg)"	
replace `unit'_qty= `unit'_qty/0.025 if `unit'_unit_new=="Sackets (25ml)" 			// 25 ml Sacket to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Sackets (25ml)" 
replace `unit'_qty= `unit'_qty/0.05 if `unit'_unit_new=="Sackets (50ml)" 			// 50 ml Sacket to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Sackets (50ml)" 
replace `unit'_qty= `unit'_qty/0.1 if `unit'_unit_new=="Sackets (100ml)" 			// 100 ml Sacket to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Sackets (100ml)" 


}


*Dealing the other unit categories
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (2 =1 )  // grams to kg  

keep if food_consu_yesno==1
drop if food_consu_qty==0  | food_consu_qty==.
*Input the value of consumption using prices infered from the quantity of purchase and the value of pruchases.
gen price_unit= food_purch_value/food_purch_qty
recode price_unit (0=.)

merge m:1 hhid using "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_hhids.dta", nogen keep (1 3)

save "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_consumption_purchase.dta", replace
 

* parish
use "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys parish_code item_code food_purch_unit_new: egen obs_parish = count(observation)
collapse (median) price_unit [aw=weight], by (parish_code item_code food_purch_unit_new obs_parish)
ren price_unit price_unit_median_parish
lab var price_unit_median_parish "Median price per kg for this crop in the parish"
lab var obs_parish "Number of observations for this crop in the parish"
save "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_item_prices_parish.dta", replace

* sub county 
use "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys scounty_code item_code food_purch_unit_new: egen obs_scounty = count(observation)
collapse (median) price_unit [aw=weight], by (scounty_code item_code food_purch_unit_new obs_scounty)
ren price_unit price_unit_median_scounty
lab var price_unit_median_scounty "Median price per kg for this crop in the scounty"
lab var obs_scounty "Number of observations for this crop in the scounty"
save "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_item_prices_scounty.dta", replace

* county 
use "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys county_code item_code food_purch_unit_new: egen obs_county = count(observation)
collapse (median) price_unit [aw=weight], by (county_code item_code food_purch_unit_new obs_county)
ren price_unit price_unit_median_county
lab var price_unit_median_county "Median price per kg for this crop in the county"
lab var obs_county "Number of observations for this crop in the county"
save "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_item_prices_county.dta", replace

* district
use "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys district_code item_code food_purch_unit_new: egen obs_district = count(observation) 
collapse (median) price_unit [aw=weight], by (district_code item_code food_purch_unit_new obs_district)
ren price_unit price_unit_median_district
lab var price_unit_median_district "Median price per kg for this crop in the district"
lab var obs_district "Number of observations for this crop in the district"
save "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_item_prices_district.dta", replace

* region
use "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region item_code food_purch_unit_new: egen obs_region = count(observation)
collapse (median) price_unit [aw=weight], by (region item_code food_purch_unit_new obs_region)
ren price_unit price_unit_median_region
lab var price_unit_median_region "Median price per kg for this crop in the region"
lab var obs_region "Number of observations for this crop in the region"
save "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_item_prices_region.dta", replace


use "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys item_code food_purch_unit_new: egen obs_country = count(observation)
collapse (median) price_unit [aw=weight], by (item_code food_purch_unit_new obs_country)
ren price_unit price_unit_median_country
lab var price_unit_median_country "Median price per kg for this crop in the country"
lab var obs_country "Number of observations for this crop in the country"
save "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_item_prices_country.dta", replace


*Pull prices into consumption estimates
use "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_consumption_purchase.dta", clear


merge m:1 hhid using "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_hhids.dta", nogen keep (1 3)
gen food_purch_unit_old=food_purch_unit_new

drop food_prod_value food_gift_value

* Value Food consumption, production, and gift when the units does not match the units of purchased
foreach f in consu prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit_new==food_purch_unit_new


*- using parish medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 parish_code item_code food_purch_unit_new using "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_item_prices_parish.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_parish if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_parish>10 & obs_parish!=.

*- using scounty medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 scounty_code item_code food_purch_unit_new using "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_item_prices_scounty.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_scounty if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_scounty>10 & obs_scounty!=.

*- using county medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 county_code item_code food_purch_unit_new using "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_item_prices_county.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_county if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_county>10 & obs_county!=.

*- using district medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 district_code item_code food_purch_unit_new using "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_item_prices_district.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_district if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_district>10 & obs_district!=.

*- using region medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 region item_code food_purch_unit_new using "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_item_prices_region.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_region if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_region>10 & obs_region!=.

*- using country medians
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 item_code food_purch_unit_new using "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_item_prices_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid item_code crop_category1 food_`f'_value
save "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_consumption_purchase_`f'.dta", replace
restore
}

merge 1:1  hhid item_code crop_category1  using "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_consumption_purchase_consu.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_consumption_purchase_prod.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_consumption_purchase_gift.dta", nogen

collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid crop_category1)
recode  food_consu_value food_purch_value food_prod_value food_gift_value (.=0)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_food_home_consumption_value.dta", replace


*Food away from home
use "${Uganda_UNPS_W7_raw_data}\GSEC15B.dta", clear
keep if CEB03==1
gen str strhhid = hhid
replace hhid = ""
compress hhid
replace hhid = strhhid
drop strhhid
* I am not sure we can confidently categorised FAH. So coding this as a separate category of food
ren CEB09 food_purch_value
ren CEB08 food_purch_qty
gen price_unit=food_purch_value/food_purch_qty
gen  food_consu_value=food_purch_value
collapse (sum) food_consu_value food_purch_value, by(hhid)
gen crop_category1="Meals away from home"
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
save "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_food_away_consumption_value.dta", replace


use "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_food_home_consumption_value.dta", clear
append using "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_food_away_consumption_value.dta"
merge m:1 hhid using "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_hhids.dta", nogen keep(1 3)

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

save "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_food_consumption_value.dta", replace


*RESCALING the components of consumption such that the sum always match
** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value {
	_pctile `v' [aw=weight] if `v'!=0 , p($wins_upper_thres)  
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
}

save "${Uganda_UNPS_W7_created_data}/Uganda_UNPS_W7_food_consumption_value_combined.dta", replace


ren district_name adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province"
ren county_name adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"
gen adm3=.
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="Uganda"
lab var Countr "Country name"
qui gen Instrument="Uganda LSMS-ISA/UNPS W7"
lab var Instrument "Survey name"
qui gen Year="2018"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq age_hh nadultworking nadultworking_female nadultworking_male nchildren nelders interview_day interview_month interview_year fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

*generate GID_1 code to match codes in the Benin shapefile
gen GID_1=""
replace GID_1="UGA.1_1"  if adm1=="ADJUMANI"
replace GID_1="UGA.2_1"  if adm1=="APAC"
replace GID_1="UGA.3_1"  if adm1=="ARUA"
replace GID_1="UGA.4_1"  if adm1=="BUGIRI"
replace GID_1="UGA.5_1"  if adm1=="BUNDIBUGYO"
replace GID_1="UGA.6_1"  if adm1=="BUSHENYI"
replace GID_1="UGA.7_1"  if adm1=="BUSIA"
replace GID_1="UGA.8_1"  if adm1=="GULU"
replace GID_1="UGA.9_1"  if adm1=="HOIMA"
replace GID_1="UGA.10_1"  if adm1=="IGANGA"
replace GID_1="UGA.10_1"  if adm1=="iganga"
replace GID_1="UGA.11_1"  if adm1=="JINJA"
replace GID_1="UGA.12_1"  if adm1=="KABALE"
replace GID_1="UGA.13_1"  if adm1=="KABAROLE"
*replace GID_1="UGA.14_1"  if adm1==""
replace GID_1="UGA.15_1"  if adm1=="KALANGALA"
replace GID_1="UGA.16_1"  if adm1=="KAMPALA"
replace GID_1="UGA.16_1"  if adm1=="kampala"
replace GID_1="UGA.17_1"  if adm1=="KAMULI"
replace GID_1="UGA.18_1"  if adm1=="KAMWENGE"
replace GID_1="UGA.19_1"  if adm1=="KANUNGU"
replace GID_1="UGA.20_1"  if adm1=="KAPCHORWA"
replace GID_1="UGA.21_1"  if adm1=="KASESE"
replace GID_1="UGA.22_1"  if adm1=="KATAKWI"
replace GID_1="UGA.23_1"  if adm1=="KAYUNGA"
replace GID_1="UGA.24_1"  if adm1=="KIBAALE"
replace GID_1="UGA.25_1"  if adm1=="KIBOGA"
replace GID_1="UGA.26_1"  if adm1=="KISORO"
replace GID_1="UGA.27_1"  if adm1=="KITGUM"
replace GID_1="UGA.28_1"  if adm1=="KOTIDO"
replace GID_1="UGA.29_1"  if adm1=="KUMI"
replace GID_1="UGA.30_1"  if adm1=="KYENJOJO"
*replace GID_1="UGA.31_1"  if adm1==""
*replace GID_1="UGA.32_1"  if adm1==""
replace GID_1="UGA.33_1"  if adm1=="LIRA"
replace GID_1="UGA.34_1"  if adm1=="LUWEERO"
replace GID_1="UGA.35_1"  if adm1=="MASAKA"
replace GID_1="UGA.36_1"  if adm1=="MASINDI"
replace GID_1="UGA.37_1"  if adm1=="MAYUGE"
replace GID_1="UGA.38_1"  if adm1=="MBALE"
replace GID_1="UGA.39_1"  if adm1=="MBARARA"
replace GID_1="UGA.39_1"  if adm1=="mbarara"
replace GID_1="UGA.40_1"  if adm1=="MOROTO"
replace GID_1="UGA.41_1"  if adm1=="MOYO"
replace GID_1="UGA.42_1"  if adm1=="MPIGI"
replace GID_1="UGA.43_1"  if adm1=="MUBENDE"
replace GID_1="UGA.44_1"  if adm1=="MUKONO"
replace GID_1="UGA.45_1"  if adm1=="NAKAPIRIPIRIT"
replace GID_1="UGA.46_1"  if adm1=="NAKASONGOLA"
replace GID_1="UGA.47_1"  if adm1=="NEBBI"
replace GID_1="UGA.48_1"  if adm1=="NTUNGAMO"
*replace GID_1="UGA.49_1"  if adm1==""
replace GID_1="UGA.50_1"  if adm1=="PALLISA"
replace GID_1="UGA.51_1"  if adm1=="RAKAI"
replace GID_1="UGA.52_1"  if adm1=="RUKUNGIRI"
replace GID_1="UGA.53_1"  if adm1=="SSEMBABULE"
*replace GID_1="UGA.54_1"  if adm1==""
*replace GID_1="UGA.55_1"  if adm1==""
replace GID_1="UGA.56_1"  if adm1=="TORORO"
replace GID_1="UGA.57_1"  if adm1=="WAKISO"
replace GID_1="UGA.58_1"  if adm1=="YUMBE"
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
replace conv_lcu_ppp=	0.000798065	if Instrument==	"Uganda LSMS-ISA/UNPS W7"

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

save "${final_data}/Uganda_UNPS_W7_food_consumption_value_by_source.dta", replace


*****End of Do File*****
  	



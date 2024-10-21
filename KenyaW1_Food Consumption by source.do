/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Kenya Integrated Household Budget Survey (KIHBS) 2015/16
				 
*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available, Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Kenya Integrated Household Budget Survey was collected by the International Food Policy Research Institute (IFPRI) 
*The data were collected over the period September 2015 - August 2016.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://statistics.knbs.or.ke/nada/index.php/catalog/13/study-description


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Kenya IHS data set.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Kenya_IHS_W1_hhids.dta
*Food Consumption by source			Kenya_IHS_W1_food_consumption_value_by_source.dta

*/



clear	
set more off
clear matrix	
clear mata	
set maxvar 10000

*Set location of raw data and output
global directory			    "//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Non-LSMS Datasets"

//set directories: These paths correspond to the folders where the raw data files are located and where the created data and final data will be stored.
global Kenya_IHS_W1_raw_data 			"$directory/Kenya IHS/Kenya IHS 2015-2016"
global Kenya_IHS_W1_created_data 		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"


********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN SUD IDS
********************************************************************************
global Kenya_IHS_W1_exchange_rate 101.5044			// https://data.worldbank.org/indicator/PA.NUS.FCRF?locations=KE
global Kenya_IHS_W1_gdp_ppp_dollar 39.38 		// https://data.worldbank.org/indicator/PA.NUS.PPP?locations=KE
global Kenya_IHS_W1_cons_ppp_dolar 39.95 		// https://data.worldbank.org/indicator/PA.NUS.PRVT.PP?locations=KE
global Kenya_IHS_W1_inflation 0.080057   		// inflation rate 2013-2017. Data was collected during October 2015-2016. We have adjusted values to 2017. https://data.worldbank.org/indicator/FP.CPI.TOTL?locations=KE 


********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Kenya_IHS_W1_pop_tot 47894670
global Kenya_IHS_W1_pop_rur 35391766
global Kenya_IHS_W1_pop_urb 12502904

 
************************
*HOUSEHOLD IDS 
************************
use "${Kenya_IHS_W1_raw_data}/HH_Members_Information.dta", clear
ren b04 gender
codebook b03, tab(100)
gen fhh = gender==2 & b03==1
lab var fhh "1= Female-headed Household"
gen hh_members = 1 
keep if hh_members==1
lab var hh_members "Number of household members"
ren b05_yy age
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
egen HHID=concat(clid hhid)
collapse (max) fhh (sum) hh_members adulteq, by(clid hhid)

merge 1:m clid hhid using "${Kenya_IHS_W1_raw_data}/HH_Information.dta", nogen keep (1 3)
ren strat strata
gen rural = (resid==1)
lab var rural "1=Household lives in a rural area"
gen HHID=string(clid)+"."+string(hhid)

*Generating the variable that indicate the level of representativness of the survey (to use for reporting summary stats)
*Representative at the county level.
gen level_representativness=county


****Currency Conversion Factors***
gen ccf_loc = (1 + $Kenya_IHS_W1_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $KES"
*gen ccf_usd = (1 + $Kenya_IHS_W1_inflation)/$Kenya_IHS_W1_exchange_rate 
*lab var ccf_usd "currency conversion factor - 2017 $USD"
*gen ccf_1ppp = (1 + $Kenya_IHS_W1_inflation)/ $Kenya_IHS_W1_cons_ppp_dolar
*lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Kenya_IHS_W1_inflation)/ $Kenya_IHS_W1_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"


keep HHID county strata clid hhid rural weight fhh hh_members adulteq level_representativness
save "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_hhids.dta", replace


********************************************************************************
*CONSUMPTION
******************************************************************************** 
use "${Kenya_IHS_W1_raw_data}/food.dta", clear
gen HHID=string(clid)+"."+string(hhid)
merge m:1 clid hhid using "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_hhids.dta", nogen keep (1 3)

label list item_code

* recode food categories
gen crop_category1=""			
replace crop_category1=	"Rice"	if  item_code==	101
replace crop_category1=	"Rice"	if  item_code==	102
replace crop_category1=	"Rice"	if  item_code==	103
replace crop_category1=	"Rice"	if  item_code==	104
replace crop_category1=	"Maize"	if  item_code==	105
replace crop_category1=	"Maize"	if  item_code==	106
replace crop_category1=	"Maize"	if  item_code==	107
replace crop_category1=	"Maize"	if  item_code==	108
replace crop_category1=	"Maize"	if  item_code==	109
replace crop_category1=	"Maize"	if  item_code==	110
replace crop_category1=	"Maize"	if  item_code==	111
drop if item_code==	112
replace crop_category1=	"Wheat"	if  item_code==	113
replace crop_category1=	"Wheat"	if  item_code==	114
replace crop_category1=	"Wheat"	if  item_code==	115
replace crop_category1=	"Wheat"	if  item_code==	116
replace crop_category1=	"Millet and Sorghum"	if  item_code==	117
replace crop_category1=	"Millet and Sorghum"	if  item_code==	118
replace crop_category1=	"Cassava"	if  item_code==	119
replace crop_category1=	"Millet and Sorghum"	if  item_code==	120
replace crop_category1=	"Millet and Sorghum"	if  item_code==	121
replace crop_category1=	"Nuts and Seeds"	if  item_code==	122
replace crop_category1=	"Wheat"	if  item_code==	123
replace crop_category1=	"Wheat"	if  item_code==	124
replace crop_category1=	"Pulses"	if  item_code==	125
replace crop_category1=	"Other Cereals"	if  item_code==	126
replace crop_category1=	"Other Cereals"	if  item_code==	127
replace crop_category1=	"Other Cereals"	if  item_code==	128
replace crop_category1=	"Pulses"	if  item_code==	129
replace crop_category1=	"Pulses"	if  item_code==	130
replace crop_category1=	"Pulses"	if  item_code==	131
replace crop_category1=	"Pulses"	if  item_code==	132
replace crop_category1=	"Pulses"	if  item_code==	133
replace crop_category1=	"Groundnuts"	if  item_code==	134
replace crop_category1=	"Nuts and Seeds"	if  item_code==	135
replace crop_category1=	"Nuts and Seeds"	if  item_code==	136
replace crop_category1=	"Pulses"	if  item_code==	137
replace crop_category1=	"Pulses"	if  item_code==	138
replace crop_category1=	"Pulses"	if  item_code==	139
replace crop_category1=	"Other Cereals"	if  item_code==	140
replace crop_category1=	"Pulses"	if  item_code==	141
replace crop_category1=	"Pulses"	if  item_code==	142
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	143
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	144
replace crop_category1=	"Wheat"	if  item_code==	145
replace crop_category1=	"Wheat"	if  item_code==	146
replace crop_category1=	"Wheat"	if  item_code==	147
replace crop_category1=	"Wheat"	if  item_code==	148
replace crop_category1=	"Wheat"	if  item_code==	149
replace crop_category1=	"Beef Meat"	if  item_code==	201
replace crop_category1=	"Beef Meat"	if  item_code==	202
replace crop_category1=	"Other Meat"	if  item_code==	203
replace crop_category1=	"Pork Meat"	if  item_code==	204
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	205
replace crop_category1=	"Other Meat"	if  item_code==	206
replace crop_category1=	"Other Meat"	if  item_code==	207
replace crop_category1=	"Other Meat"	if  item_code==	208
replace crop_category1=	"Other Meat"	if  item_code==	209
replace crop_category1=	"Other Meat"	if  item_code==	210
replace crop_category1=	"Other Meat"	if  item_code==	211
replace crop_category1=	"Other Meat"	if  item_code==	212
replace crop_category1=	"Beef Meat"	if  item_code==	213
replace crop_category1=	"Pork Meat"	if  item_code==	214
replace crop_category1=	"Beef Meat"	if  item_code==	215
replace crop_category1=	"Beef Meat"	if  item_code==	216
replace crop_category1=	"Other Meat"	if  item_code==	217
replace crop_category1=	"Fish and Seafood"	if  item_code==	301
replace crop_category1=	"Fish and Seafood"	if  item_code==	302
replace crop_category1=	"Fish and Seafood"	if  item_code==	303
replace crop_category1=	"Fish and Seafood"	if  item_code==	304
replace crop_category1=	"Fish and Seafood"	if  item_code==	305
replace crop_category1=	"Fish and Seafood"	if  item_code==	306
replace crop_category1=	"Fish and Seafood"	if  item_code==	307
replace crop_category1=	"Dairy"	if  item_code==	401
replace crop_category1=	"Dairy"	if  item_code==	402
replace crop_category1=	"Dairy"	if  item_code==	403
replace crop_category1=	"Dairy"	if  item_code==	404
replace crop_category1=	"Dairy"	if  item_code==	405
replace crop_category1=	"Dairy"	if  item_code==	406
replace crop_category1=	"Dairy"	if  item_code==	407
replace crop_category1=	"Dairy"	if  item_code==	408
replace crop_category1=	"Dairy"	if  item_code==	409
replace crop_category1=	"Dairy"	if  item_code==	410
replace crop_category1=	"Dairy"	if  item_code==	411
replace crop_category1=	"Dairy"	if  item_code==	412
replace crop_category1=	"Eggs"	if  item_code==	413
replace crop_category1=	"Other Food"	if  item_code==	414
replace crop_category1=	"Oils, Fats"	if  item_code==	501
replace crop_category1=	"Oils, Fats"	if  item_code==	502
replace crop_category1=	"Oils, Fats"	if  item_code==	503
replace crop_category1=	"Oils, Fats"	if  item_code==	504
replace crop_category1=	"Oils, Fats"	if  item_code==	505
replace crop_category1=	"Oils, Fats"	if  item_code==	506
replace crop_category1=	"Oils, Fats"	if  item_code==	507
replace crop_category1=	"Oils, Fats"	if  item_code==	508
replace crop_category1=	"Oils, Fats"	if  item_code==	509
replace crop_category1=	"Oils, Fats"	if  item_code==	510
replace crop_category1=	"Fruits"	if  item_code==	601
replace crop_category1=	"Fruits"	if  item_code==	602
replace crop_category1=	"Fruits"	if  item_code==	603
replace crop_category1=	"Fruits"	if  item_code==	604
replace crop_category1=	"Fruits"	if  item_code==	605
replace crop_category1=	"Fruits"	if  item_code==	606
replace crop_category1=	"Fruits"	if  item_code==	607
replace crop_category1=	"Fruits"	if  item_code==	608
replace crop_category1=	"Fruits"	if  item_code==	609
replace crop_category1=	"Fruits"	if  item_code==	610
replace crop_category1=	"Fruits"	if  item_code==	611
replace crop_category1=	"Fruits"	if  item_code==	612
replace crop_category1=	"Fruits"	if  item_code==	613
replace crop_category1=	"Fruits"	if  item_code==	614
replace crop_category1=	"Fruits"	if  item_code==	615
replace crop_category1=	"Fruits"	if  item_code==	616
replace crop_category1=	"Fruits"	if  item_code==	617
replace crop_category1=	"Fruits"	if  item_code==	618
replace crop_category1=	"Fruits"	if  item_code==	619
replace crop_category1=	"Fruits"	if  item_code==	620
replace crop_category1=	"Fruits"	if  item_code==	621
replace crop_category1=	"Fruits"	if  item_code==	622
replace crop_category1=	"Fruits"	if  item_code==	623
replace crop_category1=	"Vegetables"	if  item_code==	701
replace crop_category1=	"Vegetables"	if  item_code==	702
replace crop_category1=	"Vegetables"	if  item_code==	703
replace crop_category1=	"Vegetables"	if  item_code==	704
replace crop_category1=	"Vegetables"	if  item_code==	705
replace crop_category1=	"Vegetables"	if  item_code==	706
replace crop_category1=	"Vegetables"	if  item_code==	707
replace crop_category1=	"Vegetables"	if  item_code==	708
replace crop_category1=	"Vegetables"	if  item_code==	709
replace crop_category1=	"Vegetables"	if  item_code==	710
replace crop_category1=	"Vegetables"	if  item_code==	711
replace crop_category1=	"Vegetables"	if  item_code==	712
replace crop_category1=	"Vegetables"	if  item_code==	713
replace crop_category1=	"Vegetables"	if  item_code==	714
replace crop_category1=	"Vegetables"	if  item_code==	715
replace crop_category1=	"Vegetables"	if  item_code==	716
replace crop_category1=	"Vegetables"	if  item_code==	717
replace crop_category1=	"Vegetables"	if  item_code==	718
replace crop_category1=	"Vegetables"	if  item_code==	719
replace crop_category1=	"Vegetables"	if  item_code==	720
replace crop_category1=	"Vegetables"	if  item_code==	721
replace crop_category1=	"Vegetables"	if  item_code==	722
replace crop_category1=	"Vegetables"	if  item_code==	723
replace crop_category1=	"Vegetables"	if  item_code==	724
replace crop_category1=	"Fruits"	if  item_code==	725
replace crop_category1=	"Vegetables"	if  item_code==	726
replace crop_category1=	"Vegetables"	if  item_code==	727
replace crop_category1=	"Potato"	if  item_code==	801
replace crop_category1=	"Sweet Potato"	if  item_code==	802
replace crop_category1=	"Other Roots and Tubers"	if  item_code==	803
replace crop_category1=	"Cassava"	if  item_code==	804
replace crop_category1=	"Cassava"	if  item_code==	805
replace crop_category1=	"Yams"	if  item_code==	806
replace crop_category1=	"Other Roots and Tubers"	if  item_code==	807
replace crop_category1=	"Fruits"	if  item_code==	901
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	902
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	903
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	904
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	905
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	906
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	907
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	908
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	909
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	910
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	911
replace crop_category1=	"Spices"	if  item_code==	1001
replace crop_category1=	"Spices"	if  item_code==	1002
replace crop_category1=	"Spices"	if  item_code==	1003
replace crop_category1=	"Spices"	if  item_code==	1004
replace crop_category1=	"Spices"	if  item_code==	1005
replace crop_category1=	"Spices"	if  item_code==	1006
replace crop_category1=	"Spices"	if  item_code==	1007
replace crop_category1=	"Spices"	if  item_code==	1008
replace crop_category1=	"Spices"	if  item_code==	1009
replace crop_category1=	"Spices"	if  item_code==	1010
replace crop_category1=	"Potato"	if  item_code==	1011
replace crop_category1=	"Spices"	if  item_code==	1012
replace crop_category1=	"Spices"	if  item_code==	1013
replace crop_category1=	"Spices"	if  item_code==	1014
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1101
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1102
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1103
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1104
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1105
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1201
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1202
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1203
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1204
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1205
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1206
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1207
replace crop_category1=	"Other Food"	if  item_code==	1301
replace crop_category1=	"Other Food"	if  item_code==	1302
replace crop_category1=	"Other Food"	if  item_code==	1303
replace crop_category1=	"Other Food"	if  item_code==	1304
replace crop_category1=	"Other Food"	if  item_code==	1305
replace crop_category1=	"Other Food"	if  item_code==	1401
replace crop_category1=	"Other Food"	if  item_code==	1402
replace crop_category1=	"Other Food"	if  item_code==	1403
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1501
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1502
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1503
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1504
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1505
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1506
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1601
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1602
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1603
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1701
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1702
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	1703
replace crop_category1=	"Tobacco"	if  item_code==	1800
replace crop_category1=	"Tobacco"	if  item_code==	1801
replace crop_category1=	"Tobacco"	if  item_code==	1802
replace crop_category1=	"Tobacco"	if  item_code==	1803
replace crop_category1=	"Tobacco"	if  item_code==	1901
replace crop_category1=	"Tobacco"	if  item_code==	1904
replace crop_category1=	"Tobacco"	if  item_code==	1905


ren t03 food_consu_yesno

ren t06_qy food_purch_qty	//Consumption from purchases
ren t06_su food_purch_unit
gen food_purch_value=cpurc_val/52.142857
ren t07_qy  food_stock_qty	//Consumption from own stock
ren t07_su food_stock_unit
ren t08_qy food_prod_qty	//Consumption from own production
ren t08_su food_prod_unit
ren t09_qy food_gift_qty	//Consumption from gifts and other sources
ren t09_su food_gift_unit
ren t10_qy food_consu_qty
ren t10_su food_consu_unit


replace food_consu_qty=food_consu_qty/1000 if food_consu_unit==1  //changing grams to kg
replace food_purch_qty=food_purch_qty/1000 if food_purch_unit==1 
replace food_stock_qty=food_stock_qty/1000 if food_stock_unit==1 
replace food_prod_qty=food_prod_qty/1000 if food_prod_unit==1 
replace food_gift_qty=food_gift_qty/1000 if food_gift_unit==1 
replace food_consu_qty=food_consu_qty/1000 if food_consu_unit==3  //changing mililiter to liter
replace food_purch_qty=food_purch_qty/1000 if food_purch_unit==3 
replace food_stock_qty=food_stock_qty/1000 if food_stock_unit==3 
replace food_prod_qty=food_prod_qty/1000 if food_prod_unit==3 
replace food_gift_qty=food_gift_qty/1000 if food_gift_unit==3 
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (1=2 ) (3=4) // grams to kg & mililiter to liter

recode food_consu_qty (.=0) 

*Impute the value of consumption using prices inferred from the quantity of purchase and the value of purchases.
gen price_unit= food_purch_value/food_purch_qty
recode price_unit (0=.)
gen country=1
save "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_consumption_purchase.dta", replace
 
 
*Valuation using price_per_unit
global pgeo_vars country county strata clid
local len : word count $pgeo_vars
while `len'!=0 {
	local g : word  `len' of $pgeo_vars
	di "`g'"
	use "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_consumption_purchase.dta", clear
	qui drop if price_unit==.
	qui gen observation = 1
	qui bys $pgeo_vars item_code food_purch_unit: egen obs_`g' = count(observation)
	collapse (median) price_unit [aw=weight], by ($pgeo_vars item_code food_purch_unit obs_`g')
	ren price_unit price_unit_median_`g'
	lab var price_unit_median_`g' "Median price per unit for this crop - `g'"
	lab var obs_`g' "Number of observations for this crop - `g'"
	qui save "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_item_prices_`g'.dta", replace
	global pgeo_vars=subinstr("$pgeo_vars","`g'","",1)
	local len=`len'-1
}


*Pull prices into consumption estimates
use "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_consumption_purchase.dta", clear
merge m:1 clid hhid using "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_hhids.dta", nogen keep(1 3) 
*gen food_purch_unit_old=food_purch_unit_new

* Value consumption, production, and given when the units does not match the units of purchased

foreach f in consu stock prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit==food_purch_unit


*- using clid medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 county strata clid item_code food_purch_unit using "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_item_prices_clid.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_clid if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_clid>10 & obs_clid!=.

*- using strata medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 county strata item_code food_purch_unit using "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_item_prices_strata.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_strata if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_strata>10 & obs_strata!=.

*- using county medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 county item_code food_purch_unit using "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_item_prices_county.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_county if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_county>10 & obs_county!=.

*- using country medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 item_code food_purch_unit using "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_item_prices_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_country>10 & obs_country!=.

keep clid hhid item_code crop_category1 food_`f'_value 
save "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_consumption_purchase_`f'.dta", replace
restore
}

merge 1:1 clid hhid item_code crop_category1  using "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_consumption_purchase_consu.dta", nogen
merge 1:1 clid hhid item_code crop_category1  using "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_consumption_purchase_stock.dta", nogen
merge 1:1 clid hhid item_code crop_category1  using "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_consumption_purchase_prod.dta", nogen
merge 1:1 clid hhid item_code crop_category1  using "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_consumption_purchase_gift.dta", nogen


collapse (sum) food_consu_value food_purch_value food_stock_value food_prod_value food_gift_value, by(clid hhid crop_category1)
recode  food_consu_value food_purch_value food_stock_value food_prod_value food_gift_value (.=0)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
save "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_food_home_consumption_value.dta", replace

 

use "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_food_home_consumption_value.dta", clear
merge m:1 clid hhid using "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_hhids.dta", nogen keep(1 3)

*convert to annual value by multiplying with 52
foreach x of varlist food_* {
	replace `x'=`x' *52 //to annualize
	local l`x' : var lab `x'
	local nl`x'=subinstr("`l`x''","over the past 7 days","",1)
	lab var `x' "Annual `nl`x''"
}

//Merging consumption from stock with consumtion from own production
egen food_prod_value2=rowtotal(food_prod_value food_stock_value)

//replace value for consumption from own production (stock+production)
rename food_prod_value food_prod_valuex
gen food_prod_value=food_prod_value2

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

recode food_* w_food_* (.=0)

merge m:1 clid hhid using "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_hhids.dta", nogen keep(1 3)
save "${Kenya_IHS_W1_created_data}/Kenya_IHS_W1_all_consumption_value_winsorized.dta",replace

ren hhid hhid2
ren HHID hhid
lab var hhid "Household ID"


ren county adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province/county"
ren strata adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"
gen adm3=.
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="Kenya"
lab var Country "Country name"
qui gen Instrument="Kenya IHS W1"
lab var Instrument "Survey name"
qui gen Year="2015/16"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year


*generate GID_1 code to match codes in the Benin shapefile
gen GID_1=""
replace GID_1="KEN.1_1"  if adm1==30
replace GID_1="KEN.2_1"  if adm1==36
replace GID_1="KEN.3_1"  if adm1==39
replace GID_1="KEN.4_1"  if adm1==40
replace GID_1="KEN.5_1"  if adm1==28
replace GID_1="KEN.6_1"  if adm1==14
replace GID_1="KEN.7_1"  if adm1==7
replace GID_1="KEN.8_1"  if adm1==43
replace GID_1="KEN.9_1"  if adm1==11
replace GID_1="KEN.10_1"  if adm1==34
replace GID_1="KEN.11_1"  if adm1==37
replace GID_1="KEN.12_1"  if adm1==35
replace GID_1="KEN.13_1"  if adm1==22
replace GID_1="KEN.14_1"  if adm1==3
replace GID_1="KEN.15_1"  if adm1==20
replace GID_1="KEN.16_1"  if adm1==45
replace GID_1="KEN.17_1"  if adm1==42
replace GID_1="KEN.18_1"  if adm1==15
replace GID_1="KEN.19_1"  if adm1==2
replace GID_1="KEN.20_1"  if adm1==31
replace GID_1="KEN.21_1"  if adm1==5
replace GID_1="KEN.22_1"  if adm1==16
replace GID_1="KEN.23_1"  if adm1==17
replace GID_1="KEN.24_1"  if adm1==9
replace GID_1="KEN.25_1"  if adm1==10
replace GID_1="KEN.26_1"  if adm1==12
replace GID_1="KEN.27_1"  if adm1==44
replace GID_1="KEN.28_1"  if adm1==1
replace GID_1="KEN.29_1"  if adm1==21
replace GID_1="KEN.30_1"  if adm1==47
replace GID_1="KEN.31_1"  if adm1==32
replace GID_1="KEN.32_1"  if adm1==29
replace GID_1="KEN.33_1"  if adm1==33
replace GID_1="KEN.34_1"  if adm1==46
replace GID_1="KEN.35_1"  if adm1==18
replace GID_1="KEN.36_1"  if adm1==19
replace GID_1="KEN.37_1"  if adm1==25
replace GID_1="KEN.38_1"  if adm1==41
replace GID_1="KEN.39_1"  if adm1==6
replace GID_1="KEN.40_1"  if adm1==4
replace GID_1="KEN.41_1"  if adm1==13
replace GID_1="KEN.42_1"  if adm1==26
replace GID_1="KEN.43_1"  if adm1==23
replace GID_1="KEN.44_1"  if adm1==27
replace GID_1="KEN.45_1"  if adm1==38
replace GID_1="KEN.46_1"  if adm1==8
replace GID_1="KEN.47_1"  if adm1==24
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
replace conv_lcu_ppp=	0.027574783	if Instrument==	"Kenya IHS W1"

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
save "${final_data}/Kenya_IHS_W1_food_consumption_value_by_source.dta", replace


*****End of Do File*****
  
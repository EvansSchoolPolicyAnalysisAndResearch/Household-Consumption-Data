/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Bangladesh Integrated Household Survey (BIHS) 2015
				 
*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available, Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Bangladesh Integrated Household Survey was collected by the International Food Policy Research Institute (IFPRI) 
*The data were collected over the period January 2015 - June 2015.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/BXSYEL


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Bangladesh IHS data set.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Bangladesh_IHS_W2_hhids.dta
*Food Consumption by source			Bangladesh_IHS_W2_food_consumption_value_by_source.dta

*/



clear	
set more off
clear matrix	
clear mata	
set maxvar 8000	

*Set location of raw data and output
global directory			    "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Non-LSMS Datasets"

//set directories
global Bangladesh_IHS_W2_raw_data 			"$directory/Bangladesh IHS\Bangladesh IHS 2015-2016"
global Bangladesh_IHS_W2_created_data 		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"


********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN SUD IDS
********************************************************************************
global Bangladesh_IHS_W2_exchange_rate 80.44	// https://data.worldbank.org/indicator/PA.NUS.FCRF?locations=BD
global Bangladesh_IHS_W2_gdp_ppp_dollar 29.74  	// https://data.worldbank.org/indicator/PA.NUS.PPP?locations=BDP
global Bangladesh_IHS_W2_cons_ppp_dolar 29.51 	// https://data.worldbank.org/indicator/PA.NUS.PRVT.PP?locations=BD
global Bangladesh_IHS_W2_inflation 0.17   		// inflation rate 2013-2017. Data was collected during October 2018-2019. We have adjusted values to 2017. https://data.worldbank.org/indicator/FP.CPI.TOTL?locations=BD  //https://www.worlddata.info/asia/bangladesh/inflation-rates.php

********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Bangladesh_IHS_W2_pop_tot 159784568
global Bangladesh_IHS_W2_pop_rur 103727348
global Bangladesh_IHS_W2_pop_urb 56057220

 
************************
*HOUSEHOLD IDS 
************************
use "${Bangladesh_IHS_W2_raw_data}\003_r2_male_mod_b1.dta", clear
merge m:1 a01 using "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Non-LSMS Datasets\Bangladesh IHS\Bangladesh IHS 2015-2016/BIHS FTF 2015 survey sampling weights.dta", nogen keep (1 3)
ren b1_02 age
ren b1_01 gender
codebook b1_03, tab(100)
gen fhh = gender==2 & b1_03==1
lab var fhh "1= Female-headed Household"
gen hh_members = 1 
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
replace adulteq=. if age==999
lab var adulteq "Adult-Equivalent"
ren hhweight weight
collapse (max) fhh weight (sum) hh_members adulteq, by(a01)

merge 1:m a01 using "${Bangladesh_IHS_W2_raw_data}/002_r2_mod_a_female.dta", nogen keep (1 3)
ren div_name division 
ren District_Name district
ren Upazila_Name upazila
ren Union_Name union
ren mouzacode mouza
ren Village village

*Generating the variable that indicate the level of representativness of the survey (to use for reporting summary stats)
gen level_representativness=.
replace level_representativness=1 if division=="Barisal" 
replace level_representativness=2 if division=="Chittagong" 
replace level_representativness=3 if division=="Dhaka"
replace level_representativness=4 if division=="Khulna"
replace level_representativness=5 if division=="Rajshahi"
replace level_representativness=6 if division=="Rangpur"
replace level_representativness=7 if division=="Sylhet"


lab define lrep 1 "Barisal"  ///
                2 "Chittagong"  ///
                3 "Dhaka"   ///
                4 "Khulna"  ///
                5 "Rajshahi"  ///
                6 "Rangpur"   ///
                7 "Sylhet"  ///
                						
lab value level_representativness	lrep							

****Currency Conversion Factors***
gen ccf_loc = (1 + $Bangladesh_IHS_W2_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $TZS"
*gen ccf_usd = (1 + $Bangladesh_IHS_W2_inflation)/$Bangladesh_IHS_W2_exchange_rate 
*lab var ccf_usd "currency conversion factor - 2017 $USD"
*gen ccf_1ppp = (1 + $Bangladesh_IHS_W2_inflation)/ $Bangladesh_IHS_W2_cons_ppp_dolar
*lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Bangladesh_IHS_W2_inflation)/ $Bangladesh_IHS_W2_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"

ren a01 hhid 

keep hhid division district upazila union mouza village weight fhh hh_members adulteq
save "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_hhids.dta", replace


********************************************************************************
*CONSUMPTION
******************************************************************************** 
use "${Bangladesh_IHS_W2_raw_data}\042_r2_mod_o1_female.dta", clear
ren a01 hhid
merge m:1 hhid using "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_hhids.dta", nogen keep (1 3)

label list o1_01
ren o1_01 item_code 

* recode food categories
gen crop_category1=""				
replace crop_category1=	"Rice"	if  item_code==	1
replace crop_category1=	"Rice"	if  item_code==	2
replace crop_category1=	"Rice"	if  item_code==	3
replace crop_category1=	"Rice"	if  item_code==	4
replace crop_category1=	"Wheat"	if  item_code==	5
replace crop_category1=	"Wheat"	if  item_code==	6
replace crop_category1=	"Wheat"	if  item_code==	7
replace crop_category1=	"Wheat"	if  item_code==	8
replace crop_category1=	"Wheat"	if  item_code==	9
replace crop_category1=	"Other Cereals"	if  item_code==	10
replace crop_category1=	"Rice"	if  item_code==	11
replace crop_category1=	"Rice"	if  item_code==	12
replace crop_category1=	"Other Cereals"	if  item_code==	13
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	14
replace crop_category1=	"Maize"	if  item_code==	15
replace crop_category1=	"Other Cereals"	if  item_code==	16
replace crop_category1=	"Pulses"	if  item_code==	21
replace crop_category1=	"Pulses"	if  item_code==	22
replace crop_category1=	"Pulses"	if  item_code==	23
replace crop_category1=	"Pulses"	if  item_code==	24
replace crop_category1=	"Pulses"	if  item_code==	25
replace crop_category1=	"Pulses"	if  item_code==	26
replace crop_category1=	"Pulses"	if  item_code==	27
replace crop_category1=	"Pulses"	if  item_code==	28
replace crop_category1=	"Pulses"	if  item_code==	31
replace crop_category1=	"Oils, Fats"	if  item_code==	32
replace crop_category1=	"Oils, Fats"	if  item_code==	33
replace crop_category1=	"Oils, Fats"	if  item_code==	34
replace crop_category1=	"Oils, Fats"	if  item_code==	35
replace crop_category1=	"Oils, Fats"	if  item_code==	36
replace crop_category1=	"Vegetables"	if  item_code==	41
replace crop_category1=	"Vegetables"	if  item_code==	42
replace crop_category1=	"Vegetables"	if  item_code==	43
replace crop_category1=	"Vegetables"	if  item_code==	44
replace crop_category1=	"Vegetables"	if  item_code==	45
replace crop_category1=	"Vegetables"	if  item_code==	46
replace crop_category1=	"Vegetables"	if  item_code==	47
replace crop_category1=	"Vegetables"	if  item_code==	48
replace crop_category1=	"Vegetables"	if  item_code==	49
replace crop_category1=	"Vegetables"	if  item_code==	50
replace crop_category1=	"Vegetables"	if  item_code==	51
replace crop_category1=	"Vegetables"	if  item_code==	52
replace crop_category1=	"Vegetables"	if  item_code==	53
replace crop_category1=	"Vegetables"	if  item_code==	54
replace crop_category1=	"Fruits"	if  item_code==	55
replace crop_category1=	"Fruits"	if  item_code==	56
replace crop_category1=	"Fruits"	if  item_code==	57
replace crop_category1=	"Fruits"	if  item_code==	58
replace crop_category1=	"Vegetables"	if  item_code==	59
replace crop_category1=	"Vegetables"	if  item_code==	60
replace crop_category1=	"Potato"	if  item_code==	61
replace crop_category1=	"Fruits"	if  item_code==	63
replace crop_category1=	"Vegetables"	if  item_code==	64
replace crop_category1=	"Spices"	if  item_code==	65
replace crop_category1=	"Vegetables"	if  item_code==	66
replace crop_category1=	"Vegetables"	if  item_code==	67
replace crop_category1=	"Vegetables"	if  item_code==	68
replace crop_category1=	"Vegetables"	if  item_code==	69
replace crop_category1=	"Vegetables"	if  item_code==	70
replace crop_category1=	"Fruits"	if  item_code==	71
replace crop_category1=	"Vegetables"	if  item_code==	72
replace crop_category1=	"Vegetables"	if  item_code==	73
replace crop_category1=	"Fruits"	if  item_code==	74
replace crop_category1=	"Vegetables"	if  item_code==	75
replace crop_category1=	"Potato"	if  item_code==	76
replace crop_category1=	"Other Food"	if  item_code==	77
replace crop_category1=	"Pulses"	if  item_code==	78
replace crop_category1=	"Fruits"	if  item_code==	79
replace crop_category1=	"Vegetables"	if  item_code==	80
replace crop_category1=	"Vegetables"	if  item_code==	81
replace crop_category1=	"Vegetables"	if  item_code==	82
replace crop_category1=	"Vegetables"	if  item_code==	86
replace crop_category1=	"Vegetables"	if  item_code==	87
replace crop_category1=	"Vegetables"	if  item_code==	88
replace crop_category1=	"Vegetables"	if  item_code==	89
replace crop_category1=	"Vegetables"	if  item_code==	90
replace crop_category1=	"Vegetables"	if  item_code==	91
replace crop_category1=	"Vegetables"	if  item_code==	92
replace crop_category1=	"Vegetables"	if  item_code==	93
replace crop_category1=	"Vegetables"	if  item_code==	94
replace crop_category1=	"Vegetables"	if  item_code==	95
replace crop_category1=	"Vegetables"	if  item_code==	96
replace crop_category1=	"Vegetables"	if  item_code==	97
replace crop_category1=	"Vegetables"	if  item_code==	98
replace crop_category1=	"Vegetables"	if  item_code==	99
replace crop_category1=	"Vegetables"	if  item_code==	100
replace crop_category1=	"Vegetables"	if  item_code==	101
replace crop_category1=	"Vegetables"	if  item_code==	102
replace crop_category1=	"Vegetables"	if  item_code==	103
replace crop_category1=	"Vegetables"	if  item_code==	104
replace crop_category1=	"Vegetables"	if  item_code==	105
replace crop_category1=	"Vegetables"	if  item_code==	106
replace crop_category1=	"Vegetables"	if  item_code==	107
replace crop_category1=	"Vegetables"	if  item_code==	108
replace crop_category1=	"Vegetables"	if  item_code==	109
replace crop_category1=	"Vegetables"	if  item_code==	110
replace crop_category1=	"Vegetables"	if  item_code==	111
replace crop_category1=	"Vegetables"	if  item_code==	112
replace crop_category1=	"Vegetables"	if  item_code==	113
replace crop_category1=	"Vegetables"	if  item_code==	114
replace crop_category1=	"Vegetables"	if  item_code==	115
replace crop_category1=	"Beef Meat"	if  item_code==	121
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	122
replace crop_category1=	"Poultry Meat"	if  item_code==	123
replace crop_category1=	"Poultry Meat"	if  item_code==	124
replace crop_category1=	"Poultry Meat"	if  item_code==	125
replace crop_category1=	"Poultry Meat"	if  item_code==	126
replace crop_category1=	"Other Meat"	if  item_code==	127
replace crop_category1=	"Other Meat"	if  item_code==	128
replace crop_category1=	"Other Meat"	if  item_code==	129
replace crop_category1=	"Eggs"	if  item_code==	130
replace crop_category1=	"Fish and Seafood"	if  item_code==	131
replace crop_category1=	"Dairy"	if  item_code==	132
replace crop_category1=	"Dairy"	if  item_code==	133
replace crop_category1=	"Dairy"	if  item_code==	134
replace crop_category1=	"Oils, Fats"	if  item_code==	135
replace crop_category1=	"Fruits"	if  item_code==	141
replace crop_category1=	"Fruits"	if  item_code==	142
replace crop_category1=	"Fruits"	if  item_code==	143
replace crop_category1=	"Fruits"	if  item_code==	144
replace crop_category1=	"Fruits"	if  item_code==	145
replace crop_category1=	"Fruits"	if  item_code==	146
replace crop_category1=	"Fruits"	if  item_code==	147
replace crop_category1=	"Fruits"	if  item_code==	148
replace crop_category1=	"Fruits"	if  item_code==	149
replace crop_category1=	"Fruits"	if  item_code==	150
replace crop_category1=	"Fruits"	if  item_code==	151
replace crop_category1=	"Fruits"	if  item_code==	152
replace crop_category1=	"Fruits"	if  item_code==	153
replace crop_category1=	"Fruits"	if  item_code==	154
replace crop_category1=	"Fruits"	if  item_code==	155
replace crop_category1=	"Fruits"	if  item_code==	156
replace crop_category1=	"Fruits"	if  item_code==	157
replace crop_category1=	"Spices"	if  item_code==	158
replace crop_category1=	"Fruits"	if  item_code==	159
replace crop_category1=	"Fruits"	if  item_code==	160
replace crop_category1=	"Fruits"	if  item_code==	161
replace crop_category1=	"Fruits"	if  item_code==	162
replace crop_category1=	"Fruits"	if  item_code==	163
replace crop_category1=	"Fruits"	if  item_code==	164
replace crop_category1=	"Fruits"	if  item_code==	165
replace crop_category1=	"Fruits"	if  item_code==	166
replace crop_category1=	"Fruits"	if  item_code==	167
replace crop_category1=	"Fruits"	if  item_code==	168
replace crop_category1=	"Fruits"	if  item_code==	169
replace crop_category1=	"Fruits"	if  item_code==	170
replace crop_category1=	"Fish and Seafood"	if  item_code==	176
replace crop_category1=	"Fish and Seafood"	if  item_code==	177
replace crop_category1=	"Fish and Seafood"	if  item_code==	178
replace crop_category1=	"Fish and Seafood"	if  item_code==	179
replace crop_category1=	"Fish and Seafood"	if  item_code==	180
replace crop_category1=	"Fish and Seafood"	if  item_code==	181
replace crop_category1=	"Fish and Seafood"	if  item_code==	182
replace crop_category1=	"Fish and Seafood"	if  item_code==	183
replace crop_category1=	"Fish and Seafood"	if  item_code==	184
replace crop_category1=	"Fish and Seafood"	if  item_code==	185
replace crop_category1=	"Fish and Seafood"	if  item_code==	186
replace crop_category1=	"Fish and Seafood"	if  item_code==	187
replace crop_category1=	"Fish and Seafood"	if  item_code==	188
replace crop_category1=	"Fish and Seafood"	if  item_code==	189
replace crop_category1=	"Fish and Seafood"	if  item_code==	190
replace crop_category1=	"Fish and Seafood"	if  item_code==	191
replace crop_category1=	"Fish and Seafood"	if  item_code==	192
replace crop_category1=	"Fish and Seafood"	if  item_code==	193
replace crop_category1=	"Fish and Seafood"	if  item_code==	194
replace crop_category1=	"Fish and Seafood"	if  item_code==	195
replace crop_category1=	"Fish and Seafood"	if  item_code==	196
replace crop_category1=	"Fish and Seafood"	if  item_code==	197
replace crop_category1=	"Fish and Seafood"	if  item_code==	198
replace crop_category1=	"Fish and Seafood"	if  item_code==	199
replace crop_category1=	"Fish and Seafood"	if  item_code==	200
replace crop_category1=	"Fish and Seafood"	if  item_code==	201
replace crop_category1=	"Fish and Seafood"	if  item_code==	202
replace crop_category1=	"Other Meat"	if  item_code==	203
replace crop_category1=	"Fish and Seafood"	if  item_code==	204
replace crop_category1=	"Fish and Seafood"	if  item_code==	205
replace crop_category1=	"Fish and Seafood"	if  item_code==	211
replace crop_category1=	"Fish and Seafood"	if  item_code==	212
replace crop_category1=	"Fish and Seafood"	if  item_code==	213
replace crop_category1=	"Fish and Seafood"	if  item_code==	214
replace crop_category1=	"Fish and Seafood"	if  item_code==	215
replace crop_category1=	"Fish and Seafood"	if  item_code==	216
replace crop_category1=	"Fish and Seafood"	if  item_code==	217
replace crop_category1=	"Fish and Seafood"	if  item_code==	218
replace crop_category1=	"Fish and Seafood"	if  item_code==	219
replace crop_category1=	"Fish and Seafood"	if  item_code==	220
replace crop_category1=	"Fish and Seafood"	if  item_code==	221
replace crop_category1=	"Fish and Seafood"	if  item_code==	222
replace crop_category1=	"Fish and Seafood"	if  item_code==	223
replace crop_category1=	"Fish and Seafood"	if  item_code==	224
replace crop_category1=	"Fish and Seafood"	if  item_code==	225
replace crop_category1=	"Fish and Seafood"	if  item_code==	226
replace crop_category1=	"Fish and Seafood"	if  item_code==	227
replace crop_category1=	"Fish and Seafood"	if  item_code==	228
replace crop_category1=	"Fish and Seafood"	if  item_code==	229
replace crop_category1=	"Fish and Seafood"	if  item_code==	230
replace crop_category1=	"Fish and Seafood"	if  item_code==	231
replace crop_category1=	"Fish and Seafood"	if  item_code==	232
replace crop_category1=	"Fish and Seafood"	if  item_code==	233
replace crop_category1=	"Fish and Seafood"	if  item_code==	234
replace crop_category1=	"Fish and Seafood"	if  item_code==	235
replace crop_category1=	"Fish and Seafood"	if  item_code==	236
replace crop_category1=	"Fish and Seafood"	if  item_code==	237
replace crop_category1=	"Fish and Seafood"	if  item_code==	238
replace crop_category1=	"Fish and Seafood"	if  item_code==	239
replace crop_category1=	"Fish and Seafood"	if  item_code==	240
replace crop_category1=	"Fish and Seafood"	if  item_code==	241
replace crop_category1=	"Fish and Seafood"	if  item_code==	242
replace crop_category1=	"Fish and Seafood"	if  item_code==	243
replace crop_category1=	"Spices"	if  item_code==	246
replace crop_category1=	"Spices"	if  item_code==	247
replace crop_category1=	"Spices"	if  item_code==	248
replace crop_category1=	"Spices"	if  item_code==	249
replace crop_category1=	"Spices"	if  item_code==	250
replace crop_category1=	"Spices"	if  item_code==	251
replace crop_category1=	"Spices"	if  item_code==	253
replace crop_category1=	"Spices"	if  item_code==	254
replace crop_category1=	"Spices"	if  item_code==	255
replace crop_category1=	"Spices"	if  item_code==	256
replace crop_category1=	"Spices"	if  item_code==	257
replace crop_category1=	"Spices"	if  item_code==	258
replace crop_category1=	"Nuts and Seeds"	if  item_code==	259
replace crop_category1=	"Nuts and Seeds"	if  item_code==	260
replace crop_category1=	"Spices"	if  item_code==	261
replace crop_category1=	"Nuts and Seeds"	if  item_code==	262
replace crop_category1=	"Spices"	if  item_code==	263
replace crop_category1=	"Spices"	if  item_code==	264
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	266
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	267
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	268
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	269
replace crop_category1=	"Nuts and Seeds"	if  item_code==	270
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	271
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	272
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	273
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	274
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	275
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	276
replace crop_category1=	"Rice"	if  item_code==	277
replace crop_category1=	"Rice"	if  item_code==	278
replace crop_category1=	"Rice"	if  item_code==	279
replace crop_category1=	"Rice"	if  item_code==	280
replace crop_category1=	"Wheat"	if  item_code==	281
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	282
replace crop_category1=	"Other Food"	if  item_code==	283
replace crop_category1=	"Rice"	if  item_code==	284
replace crop_category1=	"Rice"	if  item_code==	285
replace crop_category1=	"Eggs"	if  item_code==	286
replace crop_category1=	"Vegetables"	if  item_code==	287
replace crop_category1=	"Potato"	if  item_code==	288
replace crop_category1=	"Poultry Meat"	if  item_code==	289
replace crop_category1=	"Beef Meat"	if  item_code==	290
replace crop_category1=	"Pulses"	if  item_code==	291
replace crop_category1=	"Vegetables"	if  item_code==	292
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	293
replace crop_category1=	"Dairy"	if  item_code==	294
replace crop_category1=	"Potato"	if  item_code==	295
replace crop_category1=	"Potato"	if  item_code==	296
replace crop_category1=	"Wheat"	if  item_code==	297
replace crop_category1=	"Pulses"	if  item_code==	298
replace crop_category1=	"Pulses"	if  item_code==	299
replace crop_category1=	"Spices"	if  item_code==	300
replace crop_category1=	"Potato"	if  item_code==	301
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	302
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	303
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	304
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	305
replace crop_category1=	"Potato"	if  item_code==	306
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	307
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	308
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	309
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	310
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	311
replace crop_category1=	"Other Food"	if  item_code==	312
replace crop_category1=	"Other Food"	if  item_code==	313
replace crop_category1=	"Tobacco"	if  item_code==	314
replace crop_category1=	"Vegetables"	if  item_code==	315
replace crop_category1=	"Nuts and Seeds"	if  item_code==	316
replace crop_category1=	"Fruits"	if  item_code==	317
replace crop_category1=	"Fruits"	if  item_code==	318
replace crop_category1=	"Nuts and Seeds"	if  item_code==	319
replace crop_category1=	"Fruits"	if  item_code==	320
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	321
replace crop_category1=	"Pork Meat"	if  item_code==	322
replace crop_category1=	"Rice"	if  item_code==	323
replace crop_category1=	"Vegetables"	if  item_code==	441
replace crop_category1=	"Potato"	if  item_code==	621
replace crop_category1=	"Potato"	if  item_code==	622
replace crop_category1=	"Other Food"	if  item_code==	901
replace crop_category1=	"Pulses"	if  item_code==	902
replace crop_category1=	"Oils, Fats"	if  item_code==	903
replace crop_category1=	"Other Food"	if  item_code==	904
replace crop_category1=	"Vegetables"	if  item_code==	905
replace crop_category1=	"Other Meat"	if  item_code==	906
replace crop_category1=	"Fruits"	if  item_code==	907
replace crop_category1=	"Fish and Seafood"	if  item_code==	908
replace crop_category1=	"Fish and Seafood"	if  item_code==	909
replace crop_category1=	"Other Food"	if  item_code==	910
replace crop_category1=	"Spices"	if  item_code==	2521
replace crop_category1=	"Spices"	if  item_code==	2522
replace crop_category1=	"Spices"	if  item_code==	3231
drop if item_code==.

ren o1_02 food_consu_yesno
ren o1_04  food_consu_unit
ren o1_03 food_consu_qty
gen food_purch_unit = food_consu_unit
ren o1_07 food_purch_unit_price
ren o1_06 food_purch_qty
ren o1_08 food_purch_value
gen food_prod_unit = food_consu_unit
ren o1_10 food_prod_qty
gen food_gift_unit = food_consu_unit
gen food_gift_qty=0
replace food_gift_qty=o1_11  if o1_12==2


//APN Recoding the different sources of food consumed to just purchased, production and gifts
codebook o1_12,tab(100)
replace food_purch_qty=o1_11 if o1_12==1 
replace food_purch_qty=o1_11 if o1_12==3
replace food_prod_qty=o1_11 if o1_12==8 
replace food_gift_qty=o1_11 if o1_12==4
replace food_gift_qty=o1_11 if o1_12==5
replace food_gift_qty=o1_11 if o1_12==6
replace food_gift_qty=o1_11 if o1_12==7


replace food_consu_qty=o1_05*food_consu_qty if o1_05!=. // changing consumption quantity to it's estimated weight in grams if it was captured as a number.
replace food_purch_qty=o1_05*food_purch_qty if o1_05!=.
replace food_prod_qty=o1_05*food_prod_qty if o1_05!=.
replace food_gift_qty=o1_05*food_gift_qty if o1_05!=.

replace food_consu_unit=2 if food_consu_unit==4 //changing the unit measure from number to grams
replace food_purch_unit=2 if food_purch_unit==4
replace food_prod_unit=2 if food_prod_unit==4
replace food_gift_unit=2 if food_gift_unit==4
*/
replace food_consu_qty=food_consu_qty/1000 if food_consu_unit==2  //changing grams to kg
replace food_purch_qty=food_purch_qty/1000 if food_purch_unit==2 
replace food_prod_qty=food_prod_qty/1000 if food_prod_unit==2 
replace food_gift_qty=food_gift_qty/1000 if food_gift_unit==2 
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (2=1 ) // grams to kg 

drop food_purch_value
gen food_purch_value=food_purch_unit_price*food_purch_qty


recode food_consu_qty (.=0)

*Impute the value of consumption using prices inferred from the quantity of purchase and the value of purchases.
gen price_unit=food_purch_unit_price
recode price_unit (0=.)
gen country=1 

save "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_consumption_purchase.dta", replace
 

 *Valuation using price_per_unit
global pgeo_vars country division district upazila union mouza
local len : word count $pgeo_vars
while `len'!=0 {
	local g : word  `len' of $pgeo_vars
	di "`g'"
	use "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_consumption_purchase.dta", clear
	qui drop if price_unit==.
	qui gen observation = 1
	qui bys $pgeo_vars item_code food_purch_unit: egen obs_`g' = count(observation)
	collapse (median) price_unit [aw=weight], by ($pgeo_vars item_code food_purch_unit obs_`g')
	ren price_unit price_unit_median_`g'
	lab var price_unit_median_`g' "Median price per unit for this crop - `g'"
	lab var obs_`g' "Number of observations for this crop - `g'"
	qui save "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_item_prices_`g'.dta", replace
	global pgeo_vars=subinstr("$pgeo_vars","`g'","",1)
	local len=`len'-1

}


*Pull prices into consumption estimates
use "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_consumption_purchase.dta", clear
merge m:1 hhid using "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_hhids.dta", nogen keep(1 3) 
*gen food_purch_unit_old=food_purch_unit_new

* Value consumption, production, and given when the units does not match the units of purchased

foreach f in consu prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit==food_purch_unit


*- using mouza medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 division district upazila union mouza item_code food_purch_unit using "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_item_prices_mouza.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_mouza if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_mouza>10 & obs_mouza!=.

*- using union medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 division district upazila union item_code food_purch_unit using "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_item_prices_union.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_union if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_union>10 & obs_union!=.

*- using upazila medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 division district upazila item_code food_purch_unit using "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_item_prices_upazila.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_upazila if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_upazila>10 & obs_upazila!=.

*- using district medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 division district item_code food_purch_unit using "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_item_prices_district.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_district if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_district>10 & obs_district!=.

*- using division medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 division item_code food_purch_unit using "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_item_prices_division.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_division if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_division>10 & obs_division!=.

*- using country medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 item_code food_purch_unit using "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_item_prices_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid item_code crop_category1 food_`f'_value
save "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_consumption_purchase_`f'.dta", replace
restore
}

merge 1:1  hhid item_code crop_category1  using "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_consumption_purchase_consu.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_consumption_purchase_prod.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_consumption_purchase_gift.dta", nogen

collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid crop_category1)
recode  food_consu_value food_purch_value food_prod_value food_gift_value (.=0)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_food_home_consumption_value.dta", replace

*merge survey weight and household head variables
use "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_food_home_consumption_value.dta",clear
merge m:1 hhid using "${Bangladesh_IHS_W2_created_data}/Bangladesh_IHS_W2_hhids.dta", nogen keep(1 3)

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
gen rural=1
lab var rural "1=Household lives in a rural area"


*RESCALING the components of consumption such that the sum always match
** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value  {
	_pctile `v' [aw=weight] if `v'!=0 , p($wins_upper_thres)  
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
}


ren division adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province"
ren district adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"
ren upazila adm3 
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="Bangladesh"
lab var Countr "Country name"
qui gen Instrument="Bangladesh IHS W2"
lab var Instrument "Survey name"
qui gen Year="2015"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

*generate GID_1 code to match codes in the Benin shapefile
gen GID_1=""
replace GID_1="BGD.1_1"  if adm1=="Barisal"
replace GID_1="BGD.2_1"  if adm1=="Chittagong"
replace GID_1="BGD.3_1"  if adm1=="Dhaka"
*replace GID_1="BGD.8_1"  if adm1==""
replace GID_1="BGD.5_1"  if adm1=="Rajshahi"
replace GID_1="BGD.6_1"  if adm1=="Rangpur"
replace GID_1="BGD.7_1"  if adm1=="Sylhet"

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
replace conv_lcu_ppp=	0.0377887	if Instrument==	"Bangladesh IHS W2"

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
save "${final_data}/Bangladesh_IHS_W2_food_consumption_value_by_source.dta", replace


*****End of Do File*****
  
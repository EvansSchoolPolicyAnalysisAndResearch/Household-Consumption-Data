/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Sierra Leone Integrated Household Survey (IHS) (2018)
				 
*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Benin Enquête Harmonisée sur le Conditions de Vie des Ménages Panel Survey was collected by Statistics Sierra Leone (Stats SL)
*The data were collected over the period January 2018, December 2018.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://catalog.ihsn.org/catalog/9246/study-description


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Sierra Leone IHS dataset.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, rural location indicator, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				SierraLeone_IHS_W3_hhids.dta
*Food Consumption by source			SierraLeone_IHS_W3_food_consumption_value_by_source.dta

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

global SierraLeone_IHS_W3_raw_data 			"$directory/Sierra Leone IHS/IHS 2018"
global SierraLeone_IHS_W3_created_data 		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"


********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN USD
********************************************************************************
global SierraLeone_IHS_W3_exchange_rate 7.93		// https://data.worldbank.org/indicator/PA.NUS.FCRF?locations=SL
global SierraLeone_IHS_W3_gdp_ppp_dol 2.5		// https://data.worldbank.org/indicator/PA.NUS.PPP?locations=SL
global SierraLeone_IHS_W3_cons_ppp_dol 2.41		// https://data.worldbank.org/indicator/PA.NUS.PRVT.PP?locations=SL
global SierraLeone_IHS_W3_inflation -0.138		// inflation rate 2018. Data was collected during 2018. We want to adjust value to 2017 https://data.worldbank.org/indicator/FP.CPI.TOTL?locations=GH


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global SierraLeone_IHS_W3_pop_tot 7861281
global SierraLeone_IHS_W3_pop_rur 4555219
global SierraLeone_IHS_W3_pop_urb 3306062


********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    						//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99							//  Threshold for winzorization at the top of the distribution of continous variables


********************************************************************************
* HOUSEHOLD IDS *
********************************************************************************
use "${SierraLeone_IHS_W3_raw_data}/slihs2018_ind.dta", clear
ren a4 age
ren a2 gender
codebook a1, tab(100)
gen fhh = gender==2 & a1==1
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
collapse (max) fhh (sum) hh_members (sum) adulteq, by(_cluster _hhno)

merge 1:m _cluster _hhno using "${SierraLeone_IHS_W3_raw_data}/slihs2018_consexp.dta", nogen keep (1 3)
ren _hhno hhid
ren _cluster ea
ren  wta_hh weight
gen rural = (rururb==1)
lab var rural "1= Rural"
keep hhid ea region province district stratum weight rural foodexp foodown foodgift consexp adulteq fhh hh_members

*Generating the variable that indicate the level of representativness of the survey (to use for reporting summary stats)
gen level_representativness=.
replace level_representativness=1 if district==11 & rural==1
replace level_representativness=2 if district==11 & rural==0
replace level_representativness=3 if district==12 & rural==1
replace level_representativness=4 if district==12 & rural==0
replace level_representativness=5 if district==13 & rural==1
replace level_representativness=6 if district==13 & rural==0
replace level_representativness=7 if district==21 & rural==1
replace level_representativness=8 if district==21 & rural==0
replace level_representativness=9 if district==22 & rural==1
replace level_representativness=10 if district==22 & rural==0
replace level_representativness=11 if district==23 & rural==1
replace level_representativness=12 if district==23 & rural==0
replace level_representativness=13 if district==24 & rural==1
replace level_representativness=14 if district==24 & rural==0
replace level_representativness=15 if district==25 & rural==1
replace level_representativness=16 if district==25 & rural==0
replace level_representativness=17 if district==31 & rural==1
replace level_representativness=18 if district==31 & rural==0
replace level_representativness=19 if district==32 & rural==1
replace level_representativness=20 if district==32 & rural==0
replace level_representativness=21 if district==33 & rural==1
replace level_representativness=22 if district==33 & rural==0
replace level_representativness=23 if district==34 & rural==1
replace level_representativness=24 if district==34 & rural==0
replace level_representativness=25 if district==41 & rural==1
replace level_representativness=26 if district==41 & rural==0
replace level_representativness=27 if district==42 & rural==0

lab define lrep 1 "Kailahun - Rural"  ///
                2 "Kailahun - Urban"  ///
                3 "Kenema - Rural"   ///
                4 "Kenema - Urban"  ///
                5 "Kono - Rural"  ///
                6 "Kono - Urban"  ///
				7 "Bombali - Rural"  ///
                8 "Bombali - Urban"  ///
                9 "Kambia - Rural" ///
                10 "Kambia - Urban" ///
                11 "Koinadugu - Rural"  ///
                12 "Koinadugu - Urban"   /// 
                13 "Port Loko - Rural"  ///
                14 "Port Loko - Urban" ///   
                15 "Tonkolili - Rural"  ///
                16 "Tonkolili - Urban"   /// 
                17 "Bo - Rural"  ///
                18 "Bo - Urban"  ///  
                19 "Bonthe - Rural"  ///
                20 "Bonthe - Urban"  ///  
                21 "Moyamba - Rural"  ///
                22 "Moyamba - Urban"  ///  
                23 "Pujehun - Rural"  ///
                24 "Pujehun - Urban"  ///  
                25 "Western Rural - Rural"  ///
                26 "Western Rural - Urban"  ///  
                27 "Western Urban - Urban"  ///
						
lab value level_representativness	lrep
tab level_representativness

****Currency Conversion Factors****
gen ccf_loc = (1 + $SierraLeone_IHS_W3_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $SHL"
gen ccf_usd = (1 + $SierraLeone_IHS_W3_inflation)/$SierraLeone_IHS_W3_exchange_rate 
lab var ccf_usd "currency conversion factor - 2017 $USD"
gen ccf_1ppp = (1 + $SierraLeone_IHS_W3_inflation)/ $SierraLeone_IHS_W3_cons_ppp_dol
lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $SierraLeone_IHS_W3_inflation)/ $SierraLeone_IHS_W3_gdp_ppp_dol
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"
						
save  "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_hhids.dta", replace


********************************************************************************
*CONSUMPTION
******************************************************************************** 
use "${SierraLeone_IHS_W3_raw_data}/slihs2018_x.dta", clear
ren _hhno hhid
ren _cluster ea
merge m:1 hhid ea using "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_hhids.dta", nogen keep (1 3)
codebook x2,ta(1000)
label list X01B_02
ren x2 item_code
gen crop_category1=""			
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	11
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	12
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	13
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	14
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	15
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	21
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	22
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	23
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	24
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	25
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	26
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	27
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	31
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	32
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	33
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	41
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	42
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	43
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	51
replace crop_category1=	"Tobacco"	if  item_code==	61
replace crop_category1=	"Tobacco"	if  item_code==	62
replace crop_category1=	"Nuts and Seeds"	if  item_code==	71
replace crop_category1=	"Nuts and Seeds"	if  item_code==	72
replace crop_category1=	"Rice"	if  item_code==	81
replace crop_category1=	"Cassava"	if  item_code==	82
replace crop_category1=	"Other Food"	if  item_code==	83
replace crop_category1=	"Other Food"	if  item_code==	84
replace crop_category1=	"Other Food"	if  item_code==	85
replace crop_category1=	"Other Food"	if  item_code==	86
replace crop_category1=	"Other Food"	if  item_code==	87
replace crop_category1=	"Other Food"	if  item_code==	88
replace crop_category1=	"Yams"	if  item_code==	89
replace crop_category1=	"Other Food"	if  item_code==	90
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	91
replace crop_category1=	"Rice"	if  item_code==	101
replace crop_category1=	"Rice"	if  item_code==	102
replace crop_category1=	"Wheat"	if  item_code==	103
replace crop_category1=	"Other Food"	if  item_code==	104
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	105
replace crop_category1=	"Maize"	if  item_code==	106
replace crop_category1=	"Maize"	if  item_code==	107
replace crop_category1=	"Millet and Sorghum"	if  item_code==	108
replace crop_category1=	"Millet and Sorghum"	if  item_code==	109
replace crop_category1=	"Other Cereals"	if  item_code==	110
replace crop_category1=	"Wheat"	if  item_code==	111
replace crop_category1=	"Wheat"	if  item_code==	112
replace crop_category1=	"Wheat"	if  item_code==	113
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	114
replace crop_category1=	"Maize"	if  item_code==	115
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	116
replace crop_category1=	"Maize"	if  item_code==	117
replace crop_category1=	"Other Food"	if  item_code==	118
replace crop_category1=	"Other Cereals"	if  item_code==	119
replace crop_category1=	"Other Cereals"	if  item_code==	120
replace crop_category1=	"Maize"	if  item_code==	121
replace crop_category1=	"Poultry Meat"	if  item_code==	201
replace crop_category1=	"Poultry Meat"	if  item_code==	202
replace crop_category1=	"Poultry Meat"	if  item_code==	203
replace crop_category1=	"Poultry Meat"	if  item_code==	204
replace crop_category1=	"Poultry Meat"	if  item_code==	205
replace crop_category1=	"Poultry Meat"	if  item_code==	206
replace crop_category1=	"Beef Meat"	if  item_code==	207
replace crop_category1=	"Beef Meat"	if  item_code==	208
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	209
replace crop_category1=	"Pork Meat"	if  item_code==	210
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	211
replace crop_category1=	"Other Meat"	if  item_code==	212
replace crop_category1=	"Other Meat"	if  item_code==	213
replace crop_category1=	"Other Meat"	if  item_code==	214
replace crop_category1=	"Fish and Seafood"	if  item_code==	301
replace crop_category1=	"Fish and Seafood"	if  item_code==	302
replace crop_category1=	"Fish and Seafood"	if  item_code==	303
replace crop_category1=	"Fish and Seafood"	if  item_code==	304
replace crop_category1=	"Fish and Seafood"	if  item_code==	305
replace crop_category1=	"Fish and Seafood"	if  item_code==	306
replace crop_category1=	"Fish and Seafood"	if  item_code==	307
replace crop_category1=	"Fish and Seafood"	if  item_code==	308
replace crop_category1=	"Fish and Seafood"	if  item_code==	309
replace crop_category1=	"Fish and Seafood"	if  item_code==	310
replace crop_category1=	"Fish and Seafood"	if  item_code==	311
replace crop_category1=	"Fish and Seafood"	if  item_code==	312
replace crop_category1=	"Fish and Seafood"	if  item_code==	313
replace crop_category1=	"Fish and Seafood"	if  item_code==	314
replace crop_category1=	"Fish and Seafood"	if  item_code==	315
replace crop_category1=	"Fish and Seafood"	if  item_code==	316
replace crop_category1=	"Fish and Seafood"	if  item_code==	317
replace crop_category1=	"Fish and Seafood"	if  item_code==	318
replace crop_category1=	"Fish and Seafood"	if  item_code==	319
replace crop_category1=	"Fish and Seafood"	if  item_code==	320
replace crop_category1=	"Fish and Seafood"	if  item_code==	321
replace crop_category1=	"Fish and Seafood"	if  item_code==	328
replace crop_category1=	"Fish and Seafood"	if  item_code==	329
replace crop_category1=	"Fish and Seafood"	if  item_code==	330
replace crop_category1=	"Fish and Seafood"	if  item_code==	331
replace crop_category1=	"Fish and Seafood"	if  item_code==	332
replace crop_category1=	"Fish and Seafood"	if  item_code==	333
replace crop_category1=	"Fish and Seafood"	if  item_code==	334
replace crop_category1=	"Fish and Seafood"	if  item_code==	335
replace crop_category1=	"Fish and Seafood"	if  item_code==	336
replace crop_category1=	"Fish and Seafood"	if  item_code==	337
replace crop_category1=	"Dairy"	if  item_code==	401
replace crop_category1=	"Dairy"	if  item_code==	402
replace crop_category1=	"Dairy"	if  item_code==	403
replace crop_category1=	"Dairy"	if  item_code==	404
replace crop_category1=	"Dairy"	if  item_code==	405
replace crop_category1=	"Dairy"	if  item_code==	406
replace crop_category1=	"Dairy"	if  item_code==	407
replace crop_category1=	"Dairy"	if  item_code==	408
replace crop_category1=	"Eggs"	if  item_code==	409
replace crop_category1=	"Eggs"	if  item_code==	410
replace crop_category1=	"Oils, Fats"	if  item_code==	501
replace crop_category1=	"Oils, Fats"	if  item_code==	502
replace crop_category1=	"Oils, Fats"	if  item_code==	503
replace crop_category1=	"Oils, Fats"	if  item_code==	504
replace crop_category1=	"Oils, Fats"	if  item_code==	505
replace crop_category1=	"Oils, Fats"	if  item_code==	506
replace crop_category1=	"Oils, Fats"	if  item_code==	507
replace crop_category1=	"Groundnuts"	if  item_code==	508
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
replace crop_category1=	"Cassava"	if  item_code==	731
replace crop_category1=	"Cassava"	if  item_code==	732
replace crop_category1=	"Bananas and Plantains"	if  item_code==	733
replace crop_category1=	"Sweet Potato"	if  item_code==	734
replace crop_category1=	"Sweet Potato"	if  item_code==	735
replace crop_category1=	"Yams"	if  item_code==	736
replace crop_category1=	"Potato"	if  item_code==	737
replace crop_category1=	"Yams"	if  item_code==	738
replace crop_category1=	"Other Roots and Tubers"	if  item_code==	739
replace crop_category1=	"Cassava"	if  item_code==	740
replace crop_category1=	"Other Roots and Tubers"	if  item_code==	741
replace crop_category1=	"Bananas and Plantains"	if  item_code==	742
replace crop_category1=	"Groundnuts"	if  item_code==	751
replace crop_category1=	"Groundnuts"	if  item_code==	752
replace crop_category1=	"Groundnuts"	if  item_code==	753
replace crop_category1=	"Groundnuts"	if  item_code==	754
replace crop_category1=	"Pulses"	if  item_code==	755
replace crop_category1=	"Pulses"	if  item_code==	756
replace crop_category1=	"Pulses"	if  item_code==	757
replace crop_category1=	"Pulses"	if  item_code==	758
replace crop_category1=	"Fruits"	if  item_code==	759
replace crop_category1=	"Pulses"	if  item_code==	760
replace crop_category1=	"Pulses"	if  item_code==	761
replace crop_category1=	"Nuts and Seeds"	if  item_code==	762
replace crop_category1=	"Pulses"	if  item_code==	763
replace crop_category1=	"Nuts and Seeds"	if  item_code==	764
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	801
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	802
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	803
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	804
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	805
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	806
replace crop_category1=	"Spices"	if  item_code==	901
replace crop_category1=	"Spices"	if  item_code==	902
replace crop_category1=	"Spices"	if  item_code==	903
replace crop_category1=	"Spices"	if  item_code==	904
replace crop_category1=	"Spices"	if  item_code==	905
replace crop_category1=	"Spices"	if  item_code==	906
replace crop_category1=	"Spices"	if  item_code==	907
replace crop_category1=	"Spices"	if  item_code==	908
replace crop_category1=	"Spices"	if  item_code==	909
replace crop_category1=	"Spices"	if  item_code==	910
replace crop_category1=	"Vegetables"	if  item_code==	911
replace crop_category1=	"Spices"	if  item_code==	912
replace crop_category1=	"Spices"	if  item_code==.b
replace crop_category1=	"Rice"	if  item_code==	.c
replace crop_category1=	"Vegetables"	if  item_code==.d
replace crop_category1=	"Fish and Seafood"	if  item_code==.e
replace crop_category1=	"Groundnuts"	if  item_code==.f
replace crop_category1=	"Oils, Fats"	if  item_code==.g
drop if item_code==.a

*ren s8hq1 food_consu_yesno

gen food_consu_qty=x3
gen food_consu_unit=x4
gen food_purch_qty=x3 if x5==1
replace food_purch_qty=x3 if x5==3
gen food_purch_unit=x4 if x5==1
replace food_purch_unit=x4 if x5==3
gen food_prod_qty=x3 if x5==2
gen food_prod_unit=x4 if x5==2
gen food_gift_qty=x3 if x5==4
gen food_gift_unit=x4 if x5==4
ren x7 food_purch_value    
ren x9 price_unit_prod 

*Input the value of consumption using prices inferred from the quantity of purchase and the value of pruchases.
gen price_unit= food_purch_value/food_purch_qty if x5==1&3
recode price_unit (0=.)
 

gen country=1 
save "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_consumption_purchase.dta", replace
 
*Valuation using price_per_unit
global pgeo_vars country region province district ea
local len : word count $pgeo_vars
while `len'!=0 {
	local g : word  `len' of $pgeo_vars
	di "`g'"
	use "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_consumption_purchase.dta", clear
	qui drop if price_unit==.
	qui gen observation = 1
	qui bys $pgeo_vars item_code food_purch_unit: egen obs_`g' = count(observation)
	collapse (median) price_unit [aw=weight], by ($pgeo_vars item_code food_purch_unit obs_`g')
	ren price_unit price_unit_median_`g'
	lab var price_unit_median_`g' "Median price per unit for this crop - `g'"
	lab var obs_`g' "Number of observations for this crop - `g'"
	qui save "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_item_prices_`g'.dta", replace
	global pgeo_vars=subinstr("$pgeo_vars","`g'","",1)
	local len=`len'-1
}
 

 
 *Pull prices into consumption estimates
use "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_consumption_purchase.dta", clear
merge m:1 hhid ea using "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_hhids.dta", nogen keep(1 3)


* Value Food consumption, production, and gift when the units does not match the units of purchased
foreach f in consu prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit==food_purch_unit

*- using EA medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region province district ea item_code food_purch_unit using "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_item_prices_ea.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_ea if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_ea>10 & obs_ea!=.

*- using District medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region province district item_code food_purch_unit using "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_item_prices_district.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_district if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_district>10 & obs_district!=.

*- using Province medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region province item_code food_purch_unit using "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_item_prices_province.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_province if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_province>10 & obs_province!=.

*- using Region medians with at least 10 observations
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 region item_code food_purch_unit using "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_item_prices_region.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_region if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_region>10 & obs_region!=.

*- using Country medians
drop food_purch_unit 
gen food_purch_unit=food_`f'_unit 
merge m:1 item_code food_purch_unit using "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_item_prices_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit==food_purch_unit & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid ea _day _line item_code crop_category1 food_`f'_value
save "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_consumption_purchase_`f'.dta", replace
restore
}
      
merge m:1  hhid ea _day _line item_code crop_category1 using "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_consumption_purchase_consu.dta", nogen
merge 1:1  hhid ea _day _line item_code crop_category1 using "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_consumption_purchase_prod.dta", nogen
merge 1:1  hhid ea _day _line item_code crop_category1 using "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_consumption_purchase_gift.dta", nogen


collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(ea hhid crop_category1)
recode  food_consu_value food_purch_value (.=0)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 20 days"
label var food_purch_value "Value of food purchased over the past 20 days"
label var food_prod_value "Value of food produced by household over the past 20 days"
label var food_gift_value "Value of food received as a gift over the past 20 days"
save "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_food_home_consumption_value.dta", replace


*convert to annual value by multiplying with 18.25 (20 days consumption recall)
use "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_food_home_consumption_value.dta",clear
merge m:1 hhid ea using "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_hhids.dta", nogen keep(1 3)

replace food_consu_value=food_consu_value*18.25
replace food_purch_value=food_purch_value*18.25 
replace food_prod_value=food_prod_value*18.25 
replace food_gift_value=food_gift_value*18.25

label var food_consu_value "Annual value of food consumed, nominal"
label var food_purch_value "Annual value of food purchased, nominal"
label var food_prod_value "Annual value of food produced, nominal"
label var food_gift_value "Annual value of food received, nominal"
lab var fhh "1= Female-headed household"
lab var hh_members "Number of household members"
lab var adulteq "Adult-Equivalent"
lab var crop_category1 "Food items"
ren hhid hhid2
gen hhid=string(hhid2)+"."+string(ea)
lab var hhid "Household ID"

save "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_food_consumption_value.dta", replace


 *RESCALING the components of consumption such that the sum always match
** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value {
	_pctile `v' [aw=weight] if `v'!=0 , p($wins_upper_thres)  
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
}

save "${SierraLeone_IHS_W3_created_data}/SierraLeone_IHS_W3_food_consumption_value_combined.dta", replace


ren region adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province"
ren district adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"
ren stratum adm3
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="Sierra Leone"
lab var Country "Country name"
qui gen Instrument="Sierra Leone IHS W3"
lab var Instrument "Survey name"
qui gen Year="2018"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

*generate GID_1 code to match codes in the SL shapefile
gen GID_1=""
replace GID_1="SLE.1_1"  if adm1==1
replace GID_1="SLE.2_1"  if adm1==2
replace GID_1="SLE.3_1"  if adm1==3
replace GID_1="SLE.4_1"  if adm1==4


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
replace conv_lcu_ppp=	0.404905729	if Instrument==	"Sierra Leone IHS W3"

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
save "${final_data}/SierraLeone_IHS_W3_food_consumption_value_by_source.dta", replace


*****End of Do File*****
  
/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Burkina Faso Enquête Multisectorielle Continue 2014
				 
*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Burkina Faso Enquête Multisectorielle Continue Survey was collected by the Institut National de la Statistique et de la Démographie
*The data were collected over the period January to December 2015. The first round was administered in January to March 2014, the second round in April to June 2014, the third round in July to September 2014, and the fourth round in October to December 2014.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://microdata.worldbank.org/index.php/catalog/2538


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Burkina Faso EMC data set.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, rural location indicator, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Burkina_EMC_W1_hhids.dta
*Food Consumption by source			Burkina_EMC_W1_food_consumption_value_by_source.dta

*/



clear	
set more off
clear matrix	
clear mata	
set maxvar 10000


*Set location of raw data and output
global directory			    "//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/335 - Ag Team Data Support/Waves/Burkina EMC"

//set directories
global Burkina_EMC_W1_raw_data 			"$directory/Burkina EMC Wave 1/Raw DTA Files"
global Burkina_EMC_W1_created_data 		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"




********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN SUD IDS
********************************************************************************
global Burkina_EMC_W1_exchange_rate 591.2117		// https://data.worldbank.org/indicator/PA.NUS.FCRF?locations=BF // average of 2015
global Burkina_EMC_W1_gdp_ppp_dollar 208.7572   	// https://data.worldbank.org/indicator/PA.NUS.PPP // 2017
global Burkina_EMC_W1_cons_ppp_dollar 199.7414		// https://data.worldbank.org/indicator/PA.NUS.PRVT.PP // 2017
global Burkina_EMC_W1_inflation 0.019306
  	        	// https://data.worldbank.org/indicator/FP.CPI.TOTL.ZG?locations=BF inflation rate 2015. Data was collected during 2014-2015. We want to adjust the monetary values to 2017


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Burkina_EMC_W1_pop_tot 18718019
global Burkina_EMC_W1_pop_rur 13564948
global Burkina_EMC_W1_pop_urb 5153071


********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    			//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99				//  Threshold for winzorization at the top of the distribution of continous variables


************************
*HOUSEHOLD IDS
use "${Burkina_EMC_W1_raw_data}/emc2014_p1_individu_27022015", clear	
drop if ! inrange(B5,1,9) 	
ren B4  age
ren B2 gender
gen fhh=(B5==1 & gender==2)
lab var fhh "1=Female-headed household"
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
collapse (sum) hh_members adulteq (max) fhh, by (region province zd menage)

merge 1:m region province zd menage using "${Burkina_EMC_W1_raw_data}//emc2014_p2_conso7jours_16032015", nogen keep(3) 
ren hhweight weight
gen rural=.
replace rural=milieu==2
duplicates drop region province zd menage, force		
lab var rural "1=Household lives in a rural area"

*Generating the variable that indicate the level of representativness of the survey (to use for reporting summary stats)
codebook region, tab(100)
gen level_representativness=.
replace level_representativness=1 if region==1 | rural==0
replace level_representativness=2 if region==1 | rural==1
replace level_representativness=3 if region==2 | rural==0
replace level_representativness=4 if region==2 | rural==1 
replace level_representativness=5 if region==3 | rural==0
replace level_representativness=6 if region==3 | rural==1 
replace level_representativness=7 if region==4 | rural==0
replace level_representativness=8 if region==4 | rural==1
replace level_representativness=9 if region==5 | rural==0
replace level_representativness=10 if region==5 | rural==1 
replace level_representativness=11 if region==6 | rural==0
replace level_representativness=12 if region==6 | rural==1 
replace level_representativness=13 if region==7 | rural==0
replace level_representativness=14 if region==7 | rural==1 
replace level_representativness=15 if region==8 | rural==0
replace level_representativness=16 if region==8 | rural==1 
replace level_representativness=17 if region==9 | rural==0
replace level_representativness=18 if region==9 | rural==1 
replace level_representativness=19 if region==10 | rural==0
replace level_representativness=20 if region==10 | rural==1 
replace level_representativness=21 if region==11 | rural==0
replace level_representativness=22 if region==11 | rural==1 
replace level_representativness=23 if region==12 | rural==0
replace level_representativness=24 if region==12 | rural==1 
replace level_representativness=25 if region==13 | rural==0
replace level_representativness=26 if region==13 | rural==1 

lab define lrep 1 "Hauts-Bassins - Urban"  ///
                2 "Hauts-Bassins - Rural"  ///
                3 "Boucle Du Mouhoun - Urban"   ///
                4 "Boucle Du Mouhoun - Rural"  ///
                5 "Sahel - Urban"  ///
				6 "Sahel - Rural"  ///
                7 "Est - Urban"  ///
				8 "Est - Rural"  ///
                9 "Sud-Ouest - Urban"  ///
				10 "Sud-Ouest - Rural"  ///
                11 "Centre-Nord - Urban"  ///
				12 "Centre-Nord - Rural"  ///
                13 "Centre-Ouest - Urban"  ///
                14 "Centre-Ouest - Rural"  ///
				15 "Plateau Central - Urban"  ///
                16 "Plateau Central - Rural"  ///
				17 "Nord - Urban"  ///
                18 "Nord - Rural"  ///
				19 "Centre-Est - Urban"  ///
                20 "Centre-Est - Rural"  ///
				21 "Centre - Urban"  ///
                22 "Centre - Rural"  ///
				23 "Cascades - Urban"  ///
                24 "Cascades - Rural"  ///
				25 "Centre-Sud - Urban"  ///
                26 "Centre-Sud - Rural"  ///
												
lab value level_representativness	lrep							
tab level_representativness

****Currency Conversion Factors****
gen ccf_loc = (1 + $Burkina_EMC_W1_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $SHL"
gen ccf_usd = (1 + $Burkina_EMC_W1_inflation)/$Burkina_EMC_W1_exchange_rate 
lab var ccf_usd "currency conversion factor - 2017 $USD"
gen ccf_1ppp = (1 + $Burkina_EMC_W1_inflation)/ $Burkina_EMC_W1_cons_ppp_dollar
lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Burkina_EMC_W1_inflation)/ $Burkina_EMC_W1_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"

keep hhid region province zd menage province strate fhh hh_members adulteq rural weight fhh 
 
save "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_hhids.dta", replace

 
 
********************************************************************************
*CONSUMPTION
******************************************************************************** 
use "${Burkina_EMC_W1_raw_data}/emc2014_p1_conso7jours_16032015", clear


label list product
ren product item_code

* recode food categories
gen crop_category1=""				
replace crop_category1=	"Rice"	if  item_code==	1	
replace crop_category1=	"Maize"	if  item_code==	2	
replace crop_category1=	"Millet and Sorghum"	if  item_code==	3	
replace crop_category1=	"Rice"	if  item_code==	4	
replace crop_category1=	"Millet and Sorghum"	if  item_code==	5	
replace crop_category1=	"Maize"	if  item_code==	6	
replace crop_category1=	"Millet and Sorghum"	if  item_code==	7	
replace crop_category1=	"Millet and Sorghum"	if  item_code==	8	
replace crop_category1=	"Wheat"	if  item_code==	9	
replace crop_category1=	"Wheat"	if  item_code==	10	
replace crop_category1=	"Wheat"	if  item_code==	11	
replace crop_category1=	"Other Cereals"	if  item_code==	12	
replace crop_category1=	"Other Cereals"	if  item_code==	13	
replace crop_category1=	"Beef Meat"	if  item_code==	14	
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	15	
replace crop_category1=	"Pork Meat"	if  item_code==	16	
replace crop_category1=	"Poultry Meat"	if  item_code==	17	
replace crop_category1=	"Fish and Seafood"	if  item_code==	18	
replace crop_category1=	"Fish and Seafood"	if  item_code==	19	
replace crop_category1=	"Fish and Seafood"	if  item_code==	20	
replace crop_category1=	"Fish and Seafood"	if  item_code==	21	
replace crop_category1=	"Fish and Seafood"	if  item_code==	22	
replace crop_category1=	"Dairy"	if  item_code==	23	
replace crop_category1=	"Dairy"	if  item_code==	24	
replace crop_category1=	"Eggs"	if  item_code==	25	
replace crop_category1=	"Oils, Fats"	if  item_code==	26	
replace crop_category1=	"Oils, Fats"	if  item_code==	27	
replace crop_category1=	"Groundnuts"	if  item_code==	28	
replace crop_category1=	"Oils, Fats"	if  item_code==	29	
replace crop_category1=	"Yams"	if  item_code==	30	
replace crop_category1=	"Potato"	if  item_code==	31	
replace crop_category1=	"Potato"	if  item_code==	32	
replace crop_category1=	"Cassava"	if  item_code==	33	
replace crop_category1=	"Vegetables"	if  item_code==	34	
replace crop_category1=	"Fruits"	if  item_code==	35	
replace crop_category1=	"Vegetables"	if  item_code==	36	
replace crop_category1=	"Vegetables"	if  item_code==	37	
replace crop_category1=	"Vegetables"	if  item_code==	38	
replace crop_category1=	"Vegetables"	if  item_code==	39	
replace crop_category1=	"Fruits"	if  item_code==	40	
replace crop_category1=	"Pulses"	if  item_code==	41	
replace crop_category1=	"Pulses"	if  item_code==	42	
replace crop_category1=	"Pulses"	if  item_code==	43	
replace crop_category1=	"Groundnuts"	if  item_code==	44	
replace crop_category1=	"Vegetables"	if  item_code==	45	
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	46	
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	47	
replace crop_category1=	"Spices"	if  item_code==	48	
replace crop_category1=	"Spices"	if  item_code==	49	
replace crop_category1=	"Spices"	if  item_code==	50	
replace crop_category1=	"Spices"	if  item_code==	51	
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	52	
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	53	
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	54	
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	55	
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	56	
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	57	
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	58	
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	59	
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	60	
replace crop_category1=	"Tobacco"	if  item_code==	61	
replace crop_category1=	"Tobacco"	if  item_code==	62	
replace crop_category1=	"Tobacco"	if  item_code==	63	
replace crop_category1=	"Tobacco"	if  item_code==	64	
replace crop_category1=	"Other Food"	if  item_code==	65	


ren mtt_dep food_purch_value
ren qachat food_purch_qty
ren uachat food_purch_unit
ren achat  food_consu_value_cfa

ren qautocons food_prod_qty
ren uautocons food_prod_unit
ren autocons food_prod_value_cfa

ren qcadeau food_gift_qty
ren ucadeau food_gift_unit
ren cadeau food_gift_value_cfa

egen food_consu_qty = rowtotal(food_purch_qty food_prod_qty food_gift_qty)
gen food_consu_yesno = 0
replace food_consu_yesno=1 if food_consu_qty!=. | food_consu_qty!=0

gen food_consu_unit = food_purch_unit

label list uachat

foreach unit in food_consu food_purch food_prod food_gift {
gen `unit'_unit_new=	"unit"	if `unit'_unit==	1
replace `unit'_unit_new=	"25kg bag"	if `unit'_unit==	2
replace `unit'_unit_new=	"50kg bag"	if `unit'_unit==	3
replace `unit'_unit_new=	"Kg"	if `unit'_unit==	4
replace `unit'_unit_new=	"500g"	if `unit'_unit==	5
replace `unit'_unit_new=	"250g"	if `unit'_unit==	6
replace `unit'_unit_new=	"yoruba"	if `unit'_unit==	7
replace `unit'_unit_new=	"Half yoruba"	if `unit'_unit==	8
replace `unit'_unit_new=	"big box of tomatoes"	if `unit'_unit==	9
replace `unit'_unit_new=	"Tin"	if `unit'_unit==	10
replace `unit'_unit_new=	"baguette (bread)"	if `unit'_unit==	11
replace `unit'_unit_new=	"Half baguette"	if `unit'_unit==	12
replace `unit'_unit_new=	"Heap"	if `unit'_unit==	13
replace `unit'_unit_new=	"Bowl, Plate"	if `unit'_unit==	14
replace `unit'_unit_new=	"Piece"	if `unit'_unit==	15
replace `unit'_unit_new=	"Liter"	if `unit'_unit==	16
replace `unit'_unit_new=	"500ml"	if `unit'_unit==	17
replace `unit'_unit_new=	"250ml"	if `unit'_unit==	18
replace `unit'_unit_new=	"5 liter container"	if `unit'_unit==	19
replace `unit'_unit_new=	"20 liter container"	if `unit'_unit==	20
replace `unit'_unit_new=	"200 liter container"	if `unit'_unit==	21
replace `unit'_unit_new=	"Calabash"	if `unit'_unit==	22
replace `unit'_unit_new=	"Bag"	if `unit'_unit==	23
replace `unit'_unit_new=	"Glass"	if `unit'_unit==	24
replace `unit'_unit_new=	"Other unit"	if `unit'_unit==	25
replace `unit'_unit_new=	"Gram"	if `unit'_unit==	26
replace `unit'_unit_new=	"."	if `unit'_unit==	99

replace `unit'_qty= `unit'_qty*25 if `unit'_unit_new=="25kg bag"   		//25kg bag to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="25kg bag"
replace `unit'_qty= `unit'_qty*50 if `unit'_unit_new=="50kg bag"   		//50kg bag to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="50kg bag"

replace `unit'_qty= `unit'_qty/1000 if `unit'_unit_new=="Gram"   		//Gram to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Gram"
replace `unit'_qty= `unit'_qty/0.5 if `unit'_unit_new=="500g"   		//500 Gram to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="500g"
replace `unit'_qty= `unit'_qty/0.25 if `unit'_unit_new=="250g"   		//250 Gram to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="250g"


replace `unit'_qty= `unit'_qty/0.50 if `unit'_unit_new=="500ml"			// 500 ml to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="500ml"
replace `unit'_qty= `unit'_qty/0.25 if `unit'_unit_new=="250ml"			// 250 ml to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="250ml"

replace `unit'_qty= `unit'_qty*5 if `unit'_unit_new=="5 liter container"		// 5 liter container to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="5 liter container"
replace `unit'_qty= `unit'_qty*20 if `unit'_unit_new=="20 liter container"		// 20 liter container to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="20 liter container"
replace `unit'_qty= `unit'_qty*200 if `unit'_unit_new=="200 liter container"		// 200 liter container to 1 Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="200 liter container"

}


*Dealing the other unit categories
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (2 = 4 )  // 25kg bag to kg  
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (3 = 4 )  // 50kg bag to kg  
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (26 = 4 )  // grams to kg  
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (5 = 4 )  // 500g to kg  
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (6 = 4 )  // 250g to kg  
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (17 = 16 )  // 500ml to kg  
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (18 = 16 )  // 250ml to kg  
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (19 = 16 )  // 5 liter container to 1 Liter  
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (20 = 16 )  // 20 liter container to 1 Liter  
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (21 = 16 )  // 200 liter container to 1 Liter  

keep if food_consu_yesno==1
drop if food_consu_qty==0  | food_consu_qty==.
*Input the value of consumption using prices inferred from the quantity of purchase and the value of pruchases.
gen price_unit= food_purch_value/food_purch_qty
recode price_unit (0=.)

merge m:1 hhid using "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_hhids.dta", nogen keep (1 3)

save "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_consumption_purchase.dta", replace

 
* Province
use "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys province item_code food_purch_unit_new: egen obs_province = count(observation)
collapse (median) price_unit [aw=weight], by (province item_code food_purch_unit_new obs_province)
ren price_unit price_unit_median_province
lab var price_unit_median_province "Median price per kg for this crop in the province"
lab var obs_province "Number of observations for this crop in the province"
save "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_item_prices_province.dta", replace

* Strate
use "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys strate item_code food_purch_unit_new: egen obs_strate = count(observation)
collapse (median) price_unit [aw=weight], by (strate item_code food_purch_unit_new obs_strate)
ren price_unit price_unit_median_strate
lab var price_unit_median_strate "Median price per kg for this crop in the strate"
lab var obs_strate "Number of observations for this crop in the strate"
save "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_item_prices_strate.dta", replace

* Region
use "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region item_code food_purch_unit_new: egen obs_region = count(observation)
collapse (median) price_unit [aw=weight], by (region item_code food_purch_unit_new obs_region)
ren price_unit price_unit_median_region
lab var price_unit_median_region "Median price per kg for this crop in the region"
lab var obs_region "Number of observations for this crop in the region"
save "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_item_prices_region.dta", replace


use "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys item_code food_purch_unit_new: egen obs_country = count(observation)
collapse (median) price_unit [aw=weight], by (item_code food_purch_unit_new obs_country)
ren price_unit price_unit_median_country
lab var price_unit_median_country "Median price per kg for this crop in the country"
lab var obs_country "Number of observations for this crop in the country"
save "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_item_prices_country.dta", replace


*Pull prices into consumption estimates
use "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_consumption_purchase.dta", clear
merge m:1 hhid using "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_hhids.dta", nogen keep (1 3)
gen food_purch_unit_old=food_purch_unit_new

duplicates drop hhid item_code crop_category1, force


* Value Food consumption, production, and gift when the units does not match the units of purchased
foreach f in consu prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit_new==food_purch_unit_new

*- using Province medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 province item_code food_purch_unit_new using "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_item_prices_province.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_province if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_province>10 & obs_province!=.

*- using Strate medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 strate item_code food_purch_unit_new using "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_item_prices_strate.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_strate if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_strate>10 & obs_strate!=. 

*- using region medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 region item_code food_purch_unit_new using "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_item_prices_region.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_region if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_region>10 & obs_region!=.

*- using country medians
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 item_code food_purch_unit_new using "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_item_prices_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid item_code crop_category1 food_`f'_value
save "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_consumption_purchase_`f'.dta", replace
restore
}

duplicates drop hhid item_code crop_category1, force

merge 1:1  hhid item_code crop_category1  using "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_consumption_purchase_consu.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_consumption_purchase_prod.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_consumption_purchase_gift.dta", nogen

collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid crop_category1)
recode  food_consu_value food_purch_value food_prod_value food_gift_value (.=0)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_food_home_consumption_value.dta", replace


use "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_food_home_consumption_value.dta", clear
merge m:1 hhid using "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_hhids.dta", nogen keep(1 3)

*convert to annual value by multiplying with 52
replace food_consu_value=food_consu_value*52
replace food_purch_value=food_purch_value*52 
replace food_prod_value=food_prod_value* 52 
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

save "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_food_consumption_value.dta", replace


*RESCALING the components of consumption such that the sum always match
** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value  {
	_pctile `v' [aw=weight] if `v'!=0 , p($wins_upper_thres)  
	
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
	}

save "${Burkina_EMC_W1_created_data}/Burkina_EMC_W1_food_consumption_value_combined.dta", replace


ren region adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province"
ren province adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"
ren strate adm3
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="Burkina"
lab var Countr "Country name"
qui gen Instrument="Burkina LSMS-ISA/EMC W1"
lab var Instrument "Survey name"
qui gen Year="2014"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

*generate GID_1 code to match codes in the BF shapefile
gen GID_1=""
replace GID_1="BFA.1_1"  if adm1==2
replace GID_1="BFA.2_1"  if adm1==12
replace GID_1="BFA.7_1"  if adm1==11
replace GID_1="BFA.3_1"  if adm1==10
replace GID_1="BFA.4_1"  if adm1==6
replace GID_1="BFA.5_1"  if adm1==7
replace GID_1="BFA.6_1"  if adm1==13
replace GID_1="BFA.8_1"  if adm1==4
replace GID_1="BFA.9_1"  if adm1==1
replace GID_1="BFA.10_1"  if adm1==9
replace GID_1="BFA.11_1"  if adm1==8
replace GID_1="BFA.12_1"  if adm1==3
replace GID_1="BFA.13_1"  if adm1==5


/*generate GID_2 code to match codes in the BF shapefile
gen GID_2=""
replace GID_2="BFA.1.1_1"  if adm1==31
replace GID_2="BFA.1.2_1"  if adm1==32
replace GID_2="BFA.1.3_1"  if adm1==13
replace GID_2="BFA.1.4_1"  if adm1==15
replace GID_2="BFA.1.5_1"  if adm1==40
replace GID_2="BFA.1.6_1"  if adm1==27
replace GID_2="BFA.2.1_1"  if adm1==6
replace GID_2="BFA.2.2_1"  if adm1==38
replace GID_2="BFA.7.1_1"  if adm1==11
replace GID_2="BFA.3.1_1"  if adm1==4
replace GID_2="BFA.3.2_1"  if adm1==36
replace GID_2="BFA.3.3_1"  if adm1==14
replace GID_2="BFA.4.1_1"  if adm1==1
replace GID_2="BFA.4.2_1"  if adm1==17
replace GID_2="BFA.4.3_1"  if adm1==23
replace GID_2="BFA.5.1_1"  if adm1==5
replace GID_2="BFA.5.2_1"  if adm1==22
replace GID_2="BFA.5.3_1"  if adm1==25
replace GID_2="BFA.5.4_1"  if adm1==44
replace GID_2="BFA.6.1_1"  if adm1==2
replace GID_2="BFA.6.2_1"  if adm1==16
replace GID_2="BFA.6.3_1"  if adm1==30
replace GID_2="BFA.8.1_1"  if adm1==8
replace GID_2="BFA.8.2_1"  if adm1==9
replace GID_2="BFA.8.3_1"  if adm1==34
replace GID_2="BFA.8.4_1"  if adm1==35
replace GID_2="BFA.8.5_1"  if adm1==28
replace GID_2="BFA.9.1_1"  if adm1==10
replace GID_2="BFA.9.2_1"  if adm1==12
replace GID_2="BFA.9.3_1"  if adm1==42
replace GID_2="BFA.10.1_1"  if adm1==39
replace GID_2="BFA.10.2_1"  if adm1==20
replace GID_2="BFA.10.3_1"  if adm1==29
replace GID_2="BFA.10.4_1"  if adm1==45
replace GID_2="BFA.11.1_1"  if adm1==7
replace GID_2="BFA.11.2_1"  if adm1==37
replace GID_2="BFA.11.3_1"  if adm1==18
replace GID_2="BFA.12.1_1"  if adm1==19
replace GID_2="BFA.12.2_1"  if adm1==24
replace GID_2="BFA.12.3_1"  if adm1==26
replace GID_2="BFA.12.4_1"  if adm1==43
replace GID_2="BFA.13.1_1"  if adm1==3
replace GID_2="BFA.13.2_1"  if adm1==33
replace GID_2="BFA.13.3_1"  if adm1==41
replace GID_2="BFA.13.4_1"  if adm1==21

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
replace conv_lcu_ppp=	0.004805094	if Instrument==	"Burkina LSMS-ISA/EMC W1"

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
save "${final_data}/Burkina_EMC_W1_food_consumption_value_by_source.dta", replace


*****End of Do File*****
  
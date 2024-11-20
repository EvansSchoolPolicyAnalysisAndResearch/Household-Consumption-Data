/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Mali Enquête Agricole de Conjoncture Intégrée (EACI) 2014

*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Ethiopia Socioeconomic Survey was collected by the Mali National Institute of Statistics
*The data were collected over the period July 2014 - August 2014; December - October 2014.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://microdata.worldbank.org/index.php/catalog/2583


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Mali EACI dataset.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, rural location indicator, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Mali_EACI_W1_hhids.dta
*Food Consumption by source			Mali_EACI_W1_food_consumption_value_by_source.dta

*/



clear	
set more off
clear matrix	
clear mata	
set maxvar 8000	

*Set location of raw data and output
global directory			    "\\netid.washington.edu\wfs\EvansEPAR\Project\EPAR\Working Files\335 - Ag Team Data Support\Waves\Mali EACI"

//set directories: These paths correspond to the folders where the raw data files are located and where the created data and final data will be stored.
global Mali_EACI_W1_raw_data 			"$directory\Mali EACI Wave 1\Raw DTA Files\MLI_2014_EACI_v02_M_STATA8"
global Mali_EACI_W1_created_data 		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"




********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN SUD IDS
********************************************************************************
global Mali_EACI_W1_exchange_rate 591.2117		// https://data.worldbank.org/indicator/PA.NUS.FCRF?locations=ML // average of 2015
global Mali_EACI_W1_gdp_ppp_dollar 214.5087   	// https://data.worldbank.org/indicator/PA.NUS.PPP // average of 2019/2020
global Mali_EACI_W1_cons_ppp_dollar 205.2734	// https://data.worldbank.org/indicator/PA.NUS.PRVT.PP // average of 2019/2020
global Mali_EACI_W1_inflation -0.000714			// https://data.worldbank.org/indicator/FP.CPI.TOTL.ZG?locations=UG inflation rate 2019-2020. Data was collected during 2019-2020. We want to adjust the monetary values to 2017



*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Mali_EACI_W1_pop_tot 18112907
global Mali_EACI_W1_pop_rur 10869374
global Mali_EACI_W1_pop_urb 7243533


********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    			//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99				//  Threshold for winzorization at the top of the distribution of continous variables


************************
*HOUSEHOLD IDS
************************
use "${Mali_EACI_W1_raw_data}\Household\EACIIND_p1", clear
egen hhid=concat(grappe menage)
order hhid, after(menage)
drop if ! inrange(s01q02,1,15) 	
ren s01q01 gender
gen fhh=(s01q02==1 & gender==2)  
lab var fhh "1=Female-headed household"
ren s01q04a  age
replace age=. if age>=98

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

collapse (max) fhh age_hh (sum) hh_members adulteq nadultworking nadultworking_female nadultworking_male nchildren nelders, by(grappe menage)

merge 1:1 grappe menage using "${Mali_EACI_W1_raw_data}\Household\EACICONTROLE_p1", nogen
merge 1:1 grappe menage using "${Mali_EACI_W1_raw_data}\EACIPOIDS", nogen

ren s00q22j interview_day
ren s00q22m interview_month
ren s00q22y interview_year
lab var interview_day "Survey interview day"
lab var interview_month "Survey interview month"
lab var interview_year "Survey interview year"

gen hhid=string(grappe)+"."+string(menage)
order hhid, after(menage)
lab var grappe "enumeration area (EA)"
lab var menage "household number in EA"
lab var hhid "Unique household ID Wave 1"
ren s00q01 region 
ren s00q02 cercle
ren s00q03 arrondissement //RH flag - same variable as w2, should names be made to match?
ren poids_menage weight
label var weight "household weight"
gen rural = (s00q04==2)
lab var rural "1 = Household lives in a rural area"

*Generating the variable that indicate the level of representativness of the survey (to use for reporting summary stats)
gen level_representativness=.
replace level_representativness=1 if region==9 
replace level_representativness=2 if region==1 | rural==0
replace level_representativness=3 if region==1 | rural==1 
replace level_representativness=4 if region==2 | rural==0
replace level_representativness=5 if region==2 | rural==1 
replace level_representativness=6 if region==3 | rural==0
replace level_representativness=7 if region==3 | rural==1 
replace level_representativness=8 if region==4 | rural==0
replace level_representativness=9 if region==4 | rural==1 
replace level_representativness=10 if region==5 | rural==0
replace level_representativness=11 if region==5 | rural==1 
replace level_representativness=12 if region==6 | rural==0
replace level_representativness=13 if region==6 | rural==1 
replace level_representativness=14 if region==7 | rural==0
replace level_representativness=15 if region==7 | rural==1 

lab define lrep 1 "Bamako"  ///
                2 "Kayes - Urban"  ///
                3 "Kayes - Rural"   ///
                4 "Koulikoro - Urban"  ///
                5 "Koulikoro - Rural"  ///
                6 "Sikasso - Urban"  ///
				7 "Sikasso - Rural"  ///
                8 "Segou - Urban"  ///
				9 "Segou - Rural"  ///
                10 "Mopti - Urban"  ///
				11 "Mopti - Rural"  ///
                12 "Tombouctou - Urban"  ///
				13 "Tombouctou - Rural"  ///
                14 "Gao - Urban"  ///
				15 "Gaou - Rural"  ///
												
lab value level_representativness	lrep							
tab level_representativness

****Currency Conversion Factors****
gen ccf_loc = (1 + $Mali_EACI_W1_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $SHL"
gen ccf_usd = (1 + $Mali_EACI_W1_inflation)/$Mali_EACI_W1_exchange_rate 
lab var ccf_usd "currency conversion factor - 2017 $USD"
gen ccf_1ppp = (1 + $Mali_EACI_W1_inflation)/ $Mali_EACI_W1_cons_ppp_dollar
lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Mali_EACI_W1_inflation)/ $Mali_EACI_W1_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"
 
keep hhid grappe menage fhh hh_members adulteq age_hh nadultworking nadultworking_female nadultworking_male nchildren nelders interview_day interview_month interview_year region cercle arrondissement grappe menage rural weight
save "${Mali_EACI_W1_created_data}\Mali_EACI_W1_hhids.dta", replace

 
********************************************************************************
*CONSUMPTION
******************************************************************************** 
use "${Mali_EACI_W1_raw_data}\Household\EACIALI_p1.dta", clear
gen hhid=string(grappe)+"."+string(menage)
order hhid, after(menage)
lab var hhid "Unique household ID Wave 1"

ren s13q01 item_code
label list s13q01

**Drop duplicates
duplicates drop hhid item_code, force

* recode food categories
gen crop_category1=""				
replace crop_category1=	"Rice"	if  item_code==	501
replace crop_category1=	"Maize"	if  item_code==	502
replace crop_category1=	"Millet and Sorghum"	if  item_code==	503
replace crop_category1=	"Millet and Sorghum"	if  item_code==	504
replace crop_category1=	"Rice"	if  item_code==	505
replace crop_category1=	"Wheat"	if  item_code==	506
replace crop_category1=	"Other Cereals"	if  item_code==	507
replace crop_category1=	"Maize"	if  item_code==	508
replace crop_category1=	"Millet and Sorghum"	if  item_code==	509
replace crop_category1=	"Wheat"	if  item_code==	510
replace crop_category1=	"Wheat"	if  item_code==	511
replace crop_category1=	"Other Cereals"	if  item_code==	512
replace crop_category1=	"Potato"	if  item_code==	513
replace crop_category1=	"Bananas and Plantains"	if  item_code==	514
replace crop_category1=	"Yams"	if  item_code==	515
replace crop_category1=	"Cassava"	if  item_code==	516
replace crop_category1=	"Yams"	if  item_code==	517
replace crop_category1=	"Yams"	if  item_code==	518
replace crop_category1=	"Other Roots and Tubers"	if  item_code==	519
replace crop_category1=	"Cassava"	if  item_code==	520
replace crop_category1=	"Wheat"	if  item_code==	521
replace crop_category1=	"Wheat"	if  item_code==	522
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	523
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	524
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	525
replace crop_category1=	"Vegetables"	if  item_code==	526
replace crop_category1=	"Vegetables"	if  item_code==	527
replace crop_category1=	"Vegetables"	if  item_code==	528
replace crop_category1=	"Vegetables"	if  item_code==	529
replace crop_category1=	"Vegetables"	if  item_code==	530
replace crop_category1=	"Vegetables"	if  item_code==	531
replace crop_category1=	"Vegetables"	if  item_code==	532
replace crop_category1=	"Vegetables"	if  item_code==	533
replace crop_category1=	"Vegetables"	if  item_code==	534
replace crop_category1=	"Vegetables"	if  item_code==	535
replace crop_category1=	"Vegetables"	if  item_code==	536
replace crop_category1=	"Vegetables"	if  item_code==	537
replace crop_category1=	"Vegetables"	if  item_code==	538
replace crop_category1=	"Vegetables"	if  item_code==	539
replace crop_category1=	"Pulses"	if  item_code==	540
replace crop_category1=	"Pulses"	if  item_code==	541
replace crop_category1=	"Pulses"	if  item_code==	542
replace crop_category1=	"Spices"	if  item_code==	543
replace crop_category1=	"Spices"	if  item_code==	544
replace crop_category1=	"Spices"	if  item_code==	545
replace crop_category1=	"Groundnuts"	if  item_code==	546
replace crop_category1=	"Groundnuts"	if  item_code==	547
replace crop_category1=	"Vegetables"	if  item_code==	548
replace crop_category1=	"Vegetables"	if  item_code==	549
replace crop_category1=	"Vegetables"	if  item_code==	550
replace crop_category1=	"Vegetables"	if  item_code==	551
replace crop_category1=	"Spices"	if  item_code==	552
replace crop_category1=	"Spices"	if  item_code==	553
replace crop_category1=	"Spices"	if  item_code==	554
replace crop_category1=	"Fruits"	if  item_code==	555
replace crop_category1=	"Fruits"	if  item_code==	556
replace crop_category1=	"Fruits"	if  item_code==	557
replace crop_category1=	"Fruits"	if  item_code==	558
replace crop_category1=	"Fruits"	if  item_code==	559
replace crop_category1=	"Fruits"	if  item_code==	560
replace crop_category1=	"Fruits"	if  item_code==	561
replace crop_category1=	"Fruits"	if  item_code==	562
replace crop_category1=	"Fruits"	if  item_code==	563
replace crop_category1=	"Fruits"	if  item_code==	564
replace crop_category1=	"Fruits"	if  item_code==	565
replace crop_category1=	"Fruits"	if  item_code==	566
replace crop_category1=	"Fruits"	if  item_code==	567
replace crop_category1=	"Fruits"	if  item_code==	568
replace crop_category1=	"Fruits"	if  item_code==	569
replace crop_category1=	"Beef Meat"	if  item_code==	570
replace crop_category1=	"Other Meat"	if  item_code==	571
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	572
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	573
replace crop_category1=	"Poultry Meat"	if  item_code==	574
replace crop_category1=	"Poultry Meat"	if  item_code==	575
replace crop_category1=	"Other Meat"	if  item_code==	576
replace crop_category1=	"Other Meat"	if  item_code==	577
replace crop_category1=	"Other Meat"	if  item_code==	578
replace crop_category1=	"Other Meat"	if  item_code==	579
replace crop_category1=	"Other Meat"	if  item_code==	580
replace crop_category1=	"Fish and Seafood"	if  item_code==	581
replace crop_category1=	"Fish and Seafood"	if  item_code==	582
replace crop_category1=	"Fish and Seafood"	if  item_code==	583
replace crop_category1=	"Fish and Seafood"	if  item_code==	584
replace crop_category1=	"Fish and Seafood"	if  item_code==	585
replace crop_category1=	"Groundnuts"	if  item_code==	586
replace crop_category1=	"Oils, Fats"	if  item_code==	587
replace crop_category1=	"Oils, Fats"	if  item_code==	588
replace crop_category1=	"Oils, Fats"	if  item_code==	589
replace crop_category1=	"Oils, Fats"	if  item_code==	590
replace crop_category1=	"Oils, Fats"	if  item_code==	591
replace crop_category1=	"Oils, Fats"	if  item_code==	592
replace crop_category1=	"Eggs"	if  item_code==	593
replace crop_category1=	"Dairy"	if  item_code==	594
replace crop_category1=	"Dairy"	if  item_code==	595
replace crop_category1=	"Dairy"	if  item_code==	596
replace crop_category1=	"Dairy"	if  item_code==	597
replace crop_category1=	"Dairy"	if  item_code==	598
replace crop_category1=	"Dairy"	if  item_code==	599
replace crop_category1=	"Oils, Fats"	if  item_code==	600
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	601
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	602
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	603
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	604
replace crop_category1=	"Nuts and Seeds"	if  item_code==	605
replace crop_category1=	"Nuts and Seeds"	if  item_code==	606
replace crop_category1=	"Nuts and Seeds"	if  item_code==	607
replace crop_category1=	"Other Food"	if  item_code==	608
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	609
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	610
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	611
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	612
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	613
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	614
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	615
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	616
replace crop_category1=	"Tobacco"	if  item_code==	617
replace crop_category1=	"Tobacco"	if  item_code==	618
replace crop_category1=	"Other Food"	if  item_code==	619
replace crop_category1=	"Other Food"	if  item_code==	620
replace crop_category1=	"Other Food"	if  item_code==	621
replace crop_category1=	"Other Food"	if  item_code==	622
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	623
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	624
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	625
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	626


ren s13q02 food_consu_yesno

ren s13q03a food_purch_qty
ren s13q03b  food_purch_unit
ren s13q03c  food_purch_value

ren s13q04a  food_prod_qty
ren s13q04b  food_prod_unit
 
ren s13q05a food_gift_qty
ren s13q05b  food_gift_unit

label list s13q03b

foreach unit in /*food_consu*/ food_purch food_prod food_gift {
gen `unit'_unit_new="Kg" if `unit'_unit==1
replace `unit'_unit_new=	"Kg"	if `unit'_unit==	1
replace `unit'_unit_new=	"Gramme"	if `unit'_unit==	2
replace `unit'_unit_new=	"Litre"	if `unit'_unit==	3
replace `unit'_unit_new=	"Centiliter"	if `unit'_unit==	4
replace `unit'_unit_new=	"Unit�"	if `unit'_unit==	5
replace `unit'_unit_new=	"Sachet"	if `unit'_unit==	6
replace `unit'_unit_new=	"Paquet"	if `unit'_unit==	7
replace `unit'_unit_new=	"Bo�te"	if `unit'_unit==	8
replace `unit'_unit_new=	"Sac large"	if `unit'_unit==	9
replace `unit'_unit_new=	"Sac moyen"	if `unit'_unit==	10
replace `unit'_unit_new=	"Sac petit"	if `unit'_unit==	11
replace `unit'_unit_new=	"Verre"	if `unit'_unit==	12
replace `unit'_unit_new=	"Bidon"	if `unit'_unit==	13
replace `unit'_unit_new=	"Tas"	if `unit'_unit==	14
replace `unit'_unit_new=	"Autre"	if `unit'_unit==	15

replace `unit'_qty= `unit'_qty/1000 if `unit'_unit_new=="Gramme"   		//Gram to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Gramme"

replace `unit'_qty= `unit'_qty/0.01 if `unit'_unit_new=="Centiliter" 	//Centilitre to Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Centiliter" 

}


*Dealing the other unit categories
recode /*food_consu_unit*/ food_purch_unit food_prod_unit food_gift_unit (2 = 1 )  // grams to kg  
recode /*food_consu_unit*/ food_purch_unit food_prod_unit food_gift_unit (4 = 3 )  // Centilitre to Liter  

keep if food_consu_yesno==1
*drop if food_consu_qty==0  | food_consu_qty==.
recode food_purch_qty food_prod_qty food_gift_qty (.=0)
drop if food_purch_qty==0 & food_prod_qty==0 & food_gift_qty==0

*Input the value of consumption using prices infered from the quantity of purchase and the value of pruchases.
gen price_unit= food_purch_value/food_purch_qty
recode price_unit (0=.)

merge m:1 hhid using "${Mali_EACI_W1_created_data}/Mali_EACI_W1_hhids.dta", nogen keep (1 3)

save "${Mali_EACI_W1_created_data}/Mali_EACI_W1_consumption_purchase.dta", replace
 
  
 
*  Grappe
use "${Mali_EACI_W1_created_data}/Mali_EACI_W1_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys grappe item_code food_purch_unit_new: egen obs_grappe = count(observation)
collapse (median) price_unit [aw=weight], by (grappe item_code food_purch_unit_new obs_grappe)
ren price_unit price_unit_median_grappe
lab var price_unit_median_grappe "Median price per kg for this crop in the enumeration area - grappe"
lab var obs_grappe "Number of observations for this crop in the enumeration area - grappe"
save "${Mali_EACI_W1_created_data}/Mali_EACI_W1_item_prices_grappe.dta", replace


* Cercle
use "${Mali_EACI_W1_created_data}/Mali_EACI_W1_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys cercle item_code food_purch_unit_new: egen obs_cercle = count(observation)
collapse (median) price_unit [aw=weight], by (cercle item_code food_purch_unit_new obs_cercle)
ren price_unit price_unit_median_cercle
lab var price_unit_median_cercle "Median price per kg for this crop in the cercle"
lab var obs_cercle "Number of observations for this crop in the cercle"
save "${Mali_EACI_W1_created_data}/Mali_EACI_W1_item_prices_cercle.dta", replace

* Arrondissement 
use "${Mali_EACI_W1_created_data}/Mali_EACI_W1_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys arrondissement item_code food_purch_unit_new: egen obs_arrondissement = count(observation)
collapse (median) price_unit [aw=weight], by (arrondissement item_code food_purch_unit_new obs_arrondissement)
ren price_unit price_unit_median_arrondissement
lab var price_unit_median_arrondissement "Median price per kg for this crop in the arrondissement"
lab var obs_arrondissement "Number of observations for this crop in the arrondissement"
save "${Mali_EACI_W1_created_data}/Mali_EACI_W1_item_prices_arrondissement.dta", replace

* region
use "${Mali_EACI_W1_created_data}/Mali_EACI_W1_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys region item_code food_purch_unit_new: egen obs_region = count(observation)
collapse (median) price_unit [aw=weight], by (region item_code food_purch_unit_new obs_region)
ren price_unit price_unit_median_region
lab var price_unit_median_region "Median price per kg for this crop in the region"
lab var obs_region "Number of observations for this crop in the region"
save "${Mali_EACI_W1_created_data}/Mali_EACI_W1_item_prices_region.dta", replace


use "${Mali_EACI_W1_created_data}/Mali_EACI_W1_consumption_purchase.dta", clear
drop if price_unit==.
gen observation = 1
bys item_code food_purch_unit_new: egen obs_country = count(observation)
collapse (median) price_unit [aw=weight], by (item_code food_purch_unit_new obs_country)
ren price_unit price_unit_median_country
lab var price_unit_median_country "Median price per kg for this crop in the country"
lab var obs_country "Number of observations for this crop in the country"
save "${Mali_EACI_W1_created_data}/Mali_EACI_W1_item_prices_country.dta", replace


*Pull prices into consumption estimates
use "${Mali_EACI_W1_created_data}/Mali_EACI_W1_consumption_purchase.dta", clear


merge m:1 hhid using "${Mali_EACI_W1_created_data}/Mali_EACI_W1_hhids.dta", nogen keep (1 3)
gen food_purch_unit_old=food_purch_unit_new


* Value Food consumption, production, and gift when the units does not match the units of purchased
foreach f in /*consu*/ prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit_new==food_purch_unit_new


*- using grappe medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 grappe item_code food_purch_unit_new using "${Mali_EACI_W1_created_data}/Mali_EACI_W1_item_prices_grappe.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_grappe if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_grappe>10 & obs_grappe!=.


*- using Cercle medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 cercle item_code food_purch_unit_new using "${Mali_EACI_W1_created_data}/Mali_EACI_W1_item_prices_cercle.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_cercle if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_cercle>10 & obs_cercle!=.

*- using Arrondissement medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 arrondissement item_code food_purch_unit_new using "${Mali_EACI_W1_created_data}/Mali_EACI_W1_item_prices_arrondissement.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_arrondissement if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_arrondissement>10 & obs_arrondissement!=. 

*- using region medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 region item_code food_purch_unit_new using "${Mali_EACI_W1_created_data}/Mali_EACI_W1_item_prices_region.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_region if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_region>10 & obs_region!=.

*- using country medians
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 item_code food_purch_unit_new using "${Mali_EACI_W1_created_data}/Mali_EACI_W1_item_prices_country.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid item_code crop_category1 food_`f'_value
save "${Mali_EACI_W1_created_data}/Mali_EACI_W1_consumption_purchase_`f'.dta", replace
restore
}

*merge 1:1  hhid item_code crop_category1  using "${Mali_EACI_W1_created_data}/Mali_EACI_W1_consumption_purchase_consu.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Mali_EACI_W1_created_data}/Mali_EACI_W1_consumption_purchase_prod.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Mali_EACI_W1_created_data}/Mali_EACI_W1_consumption_purchase_gift.dta", nogen
egen food_consu_value=rowtotal(food_purch_value food_prod_value food_gift_value)
collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid crop_category1)
recode  food_consu_value food_purch_value food_prod_value food_gift_value (.=0)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Mali_EACI_W1_created_data}/Mali_EACI_W1_food_home_consumption_value.dta", replace


use "${Mali_EACI_W1_created_data}/Mali_EACI_W1_food_home_consumption_value.dta", clear
merge m:1 hhid using "${Mali_EACI_W1_created_data}/Mali_EACI_W1_hhids.dta", nogen keep(1 3)

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

save "${Mali_EACI_W1_created_data}/Mali_EACI_W1_food_consumption_value.dta", replace


** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value  {
	_pctile `v' [aw=weight] if `v'!=0 , p($wins_upper_thres)  // Edit this line in the other do-files
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
}


save "${Mali_EACI_W1_created_data}/Mali_EACI_W1_food_consumption_value_combined.dta", replace

ren region adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province"
ren arrondissement adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"
ren cercle adm3
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="Mali"
lab var Country 
lab var Country "Country name"
qui gen Instrument="Mali EACI W1"
lab var Instrument "Survey name"
qui gen Year="2014"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq age_hh nadultworking nadultworking_female nadultworking_male nchildren nelders interview_day interview_month interview_year fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

*generate GID_1 code to match codes in the Mali shapefile
gen GID_1=""
replace GID_1="MLI.1_1"  if adm1==9
replace GID_1="MLI.2_1"  if adm1==7
replace GID_1="MLI.3_1"  if adm1==1
*replace GID_1="MLI.4_1"  if adm1==  // Kidal is missing
replace GID_1="MLI.5_1"  if adm1==2
replace GID_1="MLI.6_1"  if adm1==5
replace GID_1="MLI.7_1"  if adm1==4
replace GID_1="MLI.8_1"  if adm1==3
replace GID_1="MLI.9_1"  if adm1==6
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
replace conv_lcu_ppp=	0.004938691	if Instrument==	"Mali EACI W1"

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
save "${final_data}/Mali_EACI_W1_food_consumption_value_by_source.dta", replace


*****End of Do File*****
  
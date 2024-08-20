/*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household fod consumption by food categories and source
				 (purchased, own production and gifts) indicators using the Niger Enquête Nationale sur les Conditions de Vie des Ménages et l'Agriculture (ECVMA) (2011-12)
				 
*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/

*Data source
*-----------
*The Niger Enquête Nationale sur les Conditions de Vie des Ménages et l'Agriculture Survey was collected by the National Institute of Statistics
*The data were collected over the period September 2014 - November 2014, January 2015 - March 2015.
*All the raw data, questionnaires, and basic information documents are available for downloading free of charge at the following link
*https://microdata.worldbank.org/index.php/catalog/2676


*Summary of executing the do.file
*-----------
*This do.file constructs household consumption by source (purchased, own production and gifts) indicators at the crop and household level using the Niger ECVMA dataset.
*Using data files from within the "Raw DTA files" folder within the working directory folder, 
*the do.file first constructs common and intermediate variables, saving dta files when appropriate 
*in the folder "created_data" within the "Final DTA files" folder. And finally saving the final dataset in the "final_data" folder.
*The processed files include all households, and crop categories in the sample.


*Key variables constructed
*-----------
*Crop_category1, crop_category2, female-headed household indicator, household survey weight, number of household members, adult-equivalent, administrative subdivision 1, administrative subdivision 2, administrative subdivision 3, rural location indicator, household ID, Country name, Survey name, Survey year, Adm1 code from GADM shapefile, 2017 Purchasing Power Parity (PPP) Conversion factor, Annual food consumption value in 2017 PPP, Annual food consumption value in 2017 Local Currency unit (LCU), Annual food consumption value from purchases in 2017 PPP, Annual food consumption value from purchases in 2017 LCU, Annual food consumption value from own production in 2017 PPP, Annual food consumption value from own production in 2017 LCU, Annual food consumption value from gifts in 2017 PPP, Annual food consumption value from gifts in 2017 LCU.



/*Final datafiles created
*-----------
*Household ID variables				Niger_ECVMA_W2_hhids.dta
*Food Consumption by source			Niger_ECVMA_W2_food_consumption_value_by_source.dta

*/


clear	
set more off
clear matrix	
clear mata	
set maxvar 10000

*Set location of raw data and output
global directory			    "//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/335 - Ag Team Data Support/Waves/Niger ECVMA"

//set directories
global Niger_ECVMA_W2_raw_data 			"$directory/Niger ECVMA Wave 2/Raw DTA Files/NER_2014_ECVMA-II_v02_M_STATA8"
global Niger_ECVMA_W2_created_data  "//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/created_data"
global final_data  		"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation/final_data"


********************************************************************************
*EXCHANGE RATE AND INFLATION FOR CONVERSION IN SUD IDS
********************************************************************************
global Niger_ECVMA_W2_exchange_rate 591.2117		// https://data.worldbank.org/indicator/PA.NUS.FCRF?locations=NE // average of 2015
global Niger_ECVMA_W2_gdp_ppp_dollar 258.4601   	// https://data.worldbank.org/indicator/PA.NUS.PPP // 2017
global Niger_ECVMA_W2_cons_ppp_dollar 245.1597		// https://data.worldbank.org/indicator/PA.NUS.PRVT.PP // 2017
global Niger_ECVMA_W2_inflation 0.044965
  	        	// https://data.worldbank.org/indicator/FP.CPI.TOTL.ZG?locations=BF inflation rate 2015. Data was collected during 2011-2012. We want to adjust the monetary values to 2017


*Re-scaling survey weights to match population estimates
*https://databank.worldbank.org/source/world-development-indicators#
global Niger_ECVMA_W2_pop_tot 20128124
global Niger_ECVMA_W2_pop_rur 16857908
global Niger_ECVMA_W2_pop_urb 3270216


********************************************************************************
*THRESHOLDS FOR WINSORIZATION
********************************************************************************
global wins_lower_thres 1    			//  Threshold for winzorization at the bottom of the distribution of continous variables
global wins_upper_thres 99				//  Threshold for winzorization at the top of the distribution of continous variables


************************
*HOUSEHOLD IDS
************************
use "${Niger_ECVMA_W2_raw_data}/ECVMA2_MS01P1.dta", clear
egen hhid=concat(GRAPPE MENAGE EXTENSION)
drop if ! inrange(MS01Q02,1,15) 	
gen fhh=(MS01Q02==1 & MS01Q01==2)
ren MS01Q01 gender
lab var fhh "1=Female-headed household"
ren MS01Q06A age
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
collapse (max) fhh (sum) hh_members adulteq, by(GRAPPE MENAGE EXTENSION)
egen hhid=concat(GRAPPE MENAGE EXTENSION)

merge m:1  GRAPPE MENAGE EXTENSION using "${Niger_ECVMA_W2_raw_data}/ECVMA2_MS00P1.dta", nogen
ren MS00Q10 region
ren MS00Q11 department 
ren MS00Q12 commune
ren MS00Q14 ea
ren PASSAGE wave
merge m:1  GRAPPE MENAGE EXTENSION using "$Niger_ECVMA_W2_raw_data/ECVMA2014_P1P2_ConsoMen.dta"
duplicates report hhid GRAPPE MENAGE EXTENSION
gen rural = . 
replace rural=0 if urbrur==1
replace rural=1 if urbrur==2
ren urbrur old_rural2
lab var rural "1=Household lives in a rural area"
rename hhweight weight

keep hhid commune department ea GRAPPE MENAGE EXTENSION hhid region rural wave zae weight fhh hh_members adulteq
destring department, replace

*Generating the variable that indicates the level of representativness of the survey (to use for reporting summary stats)
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
replace level_representativness=15 if region==8 

lab define lrep 1 "Agadez - Urban"  ///
                2 "Agadez - Rural"  ///
                3 "Diffa - Urban"   ///
                4 "Diffa - Rural"  ///
                5 "Dosso - Urban"  ///
				6 "Dosso - Rural"  ///
                7 "Maradi - Urban"  ///
				8 "Maradi - Rural"  ///
                9 "Tahoua - Urban"  ///
				10 "Tahoua - Rural"  ///
                11 "Tillaberi - Urban"  ///
				12 "Tillaberi - Rural"  ///
                13 "Zinder - Urban"  ///
                14 "Zinder - Rural"  ///
				15 "Niamey"  ///
												
lab value level_representativness	lrep							
tab level_representativness

****Currency Conversion Factors****
gen ccf_loc = (1 + $Niger_ECVMA_W2_inflation) 
lab var ccf_loc "currency conversion factor - 2017 $SHL"
gen ccf_usd = (1 + $Niger_ECVMA_W2_inflation)/$Niger_ECVMA_W2_exchange_rate 
lab var ccf_usd "currency conversion factor - 2017 $USD"
gen ccf_1ppp = (1 + $Niger_ECVMA_W2_inflation)/ $Niger_ECVMA_W2_cons_ppp_dollar
lab var ccf_1ppp "currency conversion factor - 2017 $Private Consumption PPP"
gen ccf_2ppp = (1 + $Niger_ECVMA_W2_inflation)/ $Niger_ECVMA_W2_gdp_ppp_dollar
lab var ccf_2ppp "currency conversion factor - 2017 $GDP PPP"
 
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_hhids.dta", replace

 
 
********************************************************************************
*CONSUMPTION
******************************************************************************** 
use "${Niger_ECVMA_W2_raw_data}/ECVMA2_MS12P1", clear
egen hhid=concat(GRAPPE MENAGE EXTENSION)
ren MS12Q01 item_code
label list MS12Q01

gen crop_category1=""			
replace crop_category1=	"Maize"	if  item_code==	701
replace crop_category1=	"Millet and Sorghum"	if  item_code==	702
replace crop_category1=	"Rice"	if  item_code==	703
replace crop_category1=	"Wheat"	if  item_code==	704
replace crop_category1=	"Millet and Sorghum"	if  item_code==	705
replace crop_category1=	"Rice"	if  item_code==	706
replace crop_category1=	"Other Cereals"	if  item_code==	707
replace crop_category1=	"Maize"	if  item_code==	708
replace crop_category1=	"Cassava"	if  item_code==	709
replace crop_category1=	"Wheat"	if  item_code==	710
replace crop_category1=	"Wheat"	if  item_code==	711
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	712
replace crop_category1=	"Pulses"	if  item_code==	713
replace crop_category1=	"Wheat"	if  item_code==	714
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	715
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	716
replace crop_category1=	"Vegetables"	if  item_code==	717
replace crop_category1=	"Vegetables"	if  item_code==	718
replace crop_category1=	"Vegetables"	if  item_code==	719
replace crop_category1=	"Vegetables"	if  item_code==	720
replace crop_category1=	"Vegetables"	if  item_code==	721
replace crop_category1=	"Vegetables"	if  item_code==	722
replace crop_category1=	"Vegetables"	if  item_code==	723
replace crop_category1=	"Vegetables"	if  item_code==	724
replace crop_category1=	"Vegetables"	if  item_code==	725
replace crop_category1=	"Vegetables"	if  item_code==	726
replace crop_category1=	"Vegetables"	if  item_code==	727
replace crop_category1=	"Vegetables"	if  item_code==	728
replace crop_category1=	"Vegetables"	if  item_code==	729
replace crop_category1=	"Vegetables"	if  item_code==	730
replace crop_category1=	"Pulses"	if  item_code==	731
replace crop_category1=	"Pulses"	if  item_code==	732
replace crop_category1=	"Pulses"	if  item_code==	733
replace crop_category1=	"Pulses"	if  item_code==	734
replace crop_category1=	"Spices"	if  item_code==	735
replace crop_category1=	"Spices"	if  item_code==	736
replace crop_category1=	"Groundnuts"	if  item_code==	737
replace crop_category1=	"Groundnuts"	if  item_code==	738
replace crop_category1=	"Groundnuts"	if  item_code==	739
replace crop_category1=	"Spices"	if  item_code==	740
replace crop_category1=	"Vegetables"	if  item_code==	741
replace crop_category1=	"Vegetables"	if  item_code==	742
replace crop_category1=	"Vegetables"	if  item_code==	743
replace crop_category1=	"Vegetables"	if  item_code==	744
replace crop_category1=	"Spices"	if  item_code==	745
replace crop_category1=	"Spices"	if  item_code==	746
replace crop_category1=	"Spices"	if  item_code==	747
replace crop_category1=	"Cassava"	if  item_code==	748
replace crop_category1=	"Yams"	if  item_code==	749
replace crop_category1=	"Potato"	if  item_code==	750
replace crop_category1=	"Yams"	if  item_code==	751
replace crop_category1=	"Yams"	if  item_code==	752
replace crop_category1=	"Other Roots and Tubers"	if  item_code==	753
replace crop_category1=	"Fruits"	if  item_code==	754
replace crop_category1=	"Fruits"	if  item_code==	755
replace crop_category1=	"Fruits"	if  item_code==	756
replace crop_category1=	"Fruits"	if  item_code==	757
replace crop_category1=	"Fruits"	if  item_code==	758
replace crop_category1=	"Fruits"	if  item_code==	759
replace crop_category1=	"Fruits"	if  item_code==	760
replace crop_category1=	"Fruits"	if  item_code==	761
replace crop_category1=	"Fruits"	if  item_code==	762
replace crop_category1=	"Fruits"	if  item_code==	763
replace crop_category1=	"Fruits"	if  item_code==	764
replace crop_category1=	"Fruits"	if  item_code==	765
replace crop_category1=	"Beef Meat"	if  item_code==	766
replace crop_category1=	"Other Meat"	if  item_code==	767
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	768
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	769
replace crop_category1=	"Poultry Meat"	if  item_code==	770
replace crop_category1=	"Other Meat"	if  item_code==	771
replace crop_category1=	"Other Meat"	if  item_code==	772
replace crop_category1=	"Other Meat"	if  item_code==	773
replace crop_category1=	"Fish and Seafood"	if  item_code==	774
replace crop_category1=	"Fish and Seafood"	if  item_code==	775
replace crop_category1=	"Fish and Seafood"	if  item_code==	776
replace crop_category1=	"Fish and Seafood"	if  item_code==	777
replace crop_category1=	"Fish and Seafood"	if  item_code==	778
replace crop_category1=	"Oils, Fats"	if  item_code==	779
replace crop_category1=	"Oils, Fats"	if  item_code==	780
replace crop_category1=	"Oils, Fats"	if  item_code==	781
replace crop_category1=	"Oils, Fats"	if  item_code==	782
replace crop_category1=	"Oils, Fats"	if  item_code==	783
replace crop_category1=	"Groundnuts"	if  item_code==	784
replace crop_category1=	"Eggs"	if  item_code==	785
replace crop_category1=	"Dairy"	if  item_code==	786
replace crop_category1=	"Dairy"	if  item_code==	787
replace crop_category1=	"Dairy"	if  item_code==	788
replace crop_category1=	"Dairy"	if  item_code==	789
replace crop_category1=	"Dairy"	if  item_code==	790
replace crop_category1=	"Dairy"	if  item_code==	791
replace crop_category1=	"Dairy"	if  item_code==	792
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	793
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	794
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	795
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	796
replace crop_category1=	"Other Food"	if  item_code==	797
replace crop_category1=	"Tobacco"	if  item_code==	798
replace crop_category1=	"Tobacco"	if  item_code==	799
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	800
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	801
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	802
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	803
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	804
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	805
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	806
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	807
replace crop_category1=	"Millet and Sorghum"	if  item_code==	808
replace crop_category1=	"Millet and Sorghum"	if  item_code==	809
replace crop_category1=	"Millet and Sorghum"	if  item_code==	810
replace crop_category1=	"Millet and Sorghum"	if  item_code==	811
replace crop_category1=	"Millet and Sorghum"	if  item_code==	812
replace crop_category1=	"Millet and Sorghum"	if  item_code==	813
replace crop_category1=	"Pulses"	if  item_code==	814
replace crop_category1=	"Pulses"	if  item_code==	815
replace crop_category1=	"Other Food"	if  item_code==	816
replace crop_category1=	"Other Food"	if  item_code==	817
replace crop_category1=	"Other Food"	if  item_code==	818
replace crop_category1=	"Other Food"	if  item_code==	819
replace crop_category1=	"Other Cereals"	if  item_code==	820
replace crop_category1=	"Other Food"	if  item_code==	821
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	822
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	823
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	824
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	825


ren MS12Q02 food_consu_yesno

ren MS12Q03A food_purch_qty
ren MS12Q03B food_purch_unit
ren MS12Q03C food_purch_value

ren MS12Q04A food_prod_qty
ren MS12Q04B food_prod_unit
ren MS12Q04C food_prod_value

ren MS12Q05A food_gift_qty
ren MS12Q05B  food_gift_unit
ren MS12Q05C food_gift_value

egen food_consu_qty = rowtotal(food_purch_qty food_prod_qty food_gift_qty)
gen food_consu_unit = food_purch_unit

label list MS12Q03B 

foreach unit in food_consu food_purch food_prod food_gift {
gen `unit'_unit_new=""			
replace `unit'_unit_new=	"Bottle"	if `unit'_unit==	1
replace `unit'_unit_new=	"Tia"	if `unit'_unit==	2
replace `unit'_unit_new=	"Basket"	if `unit'_unit==	3
replace `unit'_unit_new=	"Tongolo"	if `unit'_unit==	4
replace `unit'_unit_new=	"Kg"	if `unit'_unit==	5
replace `unit'_unit_new=	"Gram"	if `unit'_unit==	6
replace `unit'_unit_new=	"Unit"	if `unit'_unit==	7
replace `unit'_unit_new=	"Liter"	if `unit'_unit==	8
replace `unit'_unit_new=	"Centiliter"	if `unit'_unit==	9
replace `unit'_unit_new=	"Sachet"	if `unit'_unit==	10
replace `unit'_unit_new=	"Heap"	if `unit'_unit==	11
replace `unit'_unit_new=	"Other"	if `unit'_unit==	12
replace `unit'_unit_new=	"20 Liter Bucket"	if `unit'_unit==	13
replace `unit'_unit_new=	"10 Liter Bucket"	if `unit'_unit==	14
replace `unit'_unit_new=	"5  Liter Bucket"	if `unit'_unit==	15
replace `unit'_unit_new=	"Large Can"	if `unit'_unit==	16
replace `unit'_unit_new=	"Medium Can"	if `unit'_unit==	17
replace `unit'_unit_new=	"Small Can"	if `unit'_unit==	18
replace `unit'_unit_new=	"Large basket"	if `unit'_unit==	19
replace `unit'_unit_new=	"Medium basket"	if `unit'_unit==	20
replace `unit'_unit_new=	"Small basket"	if `unit'_unit==	21
replace `unit'_unit_new=	"1/2 tiya (en cup)"	if `unit'_unit==	22
replace `unit'_unit_new=	"1/4 tiya (en cup)"	if `unit'_unit==	23
replace `unit'_unit_new=	"Waygouiz "	if `unit'_unit==	24
replace `unit'_unit_new=	"Moudou"	if `unit'_unit==	25
replace `unit'_unit_new=	"Large can of condensed milk"	if `unit'_unit==	26
replace `unit'_unit_new=	"Tarzan bottle"	if `unit'_unit==	27
replace `unit'_unit_new=	"large ladle"	if `unit'_unit==	28
replace `unit'_unit_new=	"Medium ladle"	if `unit'_unit==	29
replace `unit'_unit_new=	"Small ladle"	if `unit'_unit==	30
replace `unit'_unit_new=	"Large calabash"	if `unit'_unit==	31
replace `unit'_unit_new=	"Medium gourd"	if `unit'_unit==	32
replace `unit'_unit_new=	"Small calabash"	if `unit'_unit==	33
replace `unit'_unit_new=	"."	if `unit'_unit==	99
			

replace `unit'_qty= `unit'_qty/1000 if `unit'_unit_new=="Gram"   		//Gram to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Gram"

replace `unit'_qty= `unit'_qty/0.01 if `unit'_unit_new=="Centiliter" 	//Centiliter to Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Centiliter" 

replace `unit'_qty= `unit'_qty*20 if `unit'_unit_new=="20 Liter Bucket"   		//20 Liters to Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="20 Liter Bucket"
replace `unit'_qty= `unit'_qty*10 if `unit'_unit_new=="10 Liter Bucket"   	//10 Liters to Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="10 Liter Bucket"
replace `unit'_qty= `unit'_qty*5 if `unit'_unit_new=="5  Liter Bucket"   	//5 Liters to Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="5  Liter Bucket"

}


*Dealing the other unit categories
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (6 = 5 )  // Gram to Kg 
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (9 = 8 )  // Centiliter to Liter
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (13 = 8 )  // 20 Liters to Liter  
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (14 = 8 )  // 10 Liters to Liter  
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (15 = 8 )  // 5 Liters to Liter  

keep if food_consu_yesno==1
drop if food_consu_qty==0  | food_consu_qty==.
*Input the value of consumption using prices infered from the quantity of purchase and the value of pruchases.
gen price_unit= food_purch_value/food_purch_qty
recode price_unit (0=.)

merge m:1 hhid GRAPPE MENAGE EXTENSION using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_hhids.dta", nogen keep (1 3)

save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PP.dta", replace

 
*  Grappe
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PP.dta", clear
drop if price_unit==.
gen observation = 1
bys GRAPPE item_code food_purch_unit_new: egen obs_GRAPPE = count(observation)
collapse (median) price_unit [aw=weight], by (GRAPPE item_code food_purch_unit_new obs_GRAPPE)
ren price_unit price_unit_median_GRAPPE
lab var price_unit_median_GRAPPE "Median price per kg for this crop in the enumeration area - GRAPPE"
lab var obs_GRAPPE "Number of observations for this crop in the enumeration area - GRAPPE"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_GRAPPE_PP.dta", replace


* EA
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PP.dta", clear
drop if price_unit==.
gen observation = 1
bys ea item_code food_purch_unit_new: egen obs_ea = count(observation)
collapse (median) price_unit [aw=weight], by (ea item_code food_purch_unit_new obs_ea)
ren price_unit price_unit_median_ea
lab var price_unit_median_ea "Median price per kg for this crop in the ea"
lab var obs_ea "Number of observations for this crop in the ea"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_ea_PP.dta", replace

* Commune
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PP.dta", clear
drop if price_unit==.
gen observation = 1
bys commune item_code food_purch_unit_new: egen obs_commune = count(observation)
collapse (median) price_unit [aw=weight], by (commune item_code food_purch_unit_new obs_commune)
ren price_unit price_unit_median_commune
lab var price_unit_median_commune "Median price per kg for this crop in the commune"
lab var obs_commune "Number of observations for this crop in the commune"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_commune_PP.dta", replace

* Department
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PP.dta", clear
drop if price_unit==.
gen observation = 1
bys department item_code food_purch_unit_new: egen obs_department = count(observation)
collapse (median) price_unit [aw=weight], by (department item_code food_purch_unit_new obs_department)
ren price_unit price_unit_median_department
lab var price_unit_median_department "Median price per kg for this crop in the department"
lab var obs_department "Number of observations for this crop in the department"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_department_PP.dta", replace


* region
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PP.dta", clear
drop if price_unit==.
gen observation = 1
bys region item_code food_purch_unit_new: egen obs_region = count(observation)
collapse (median) price_unit [aw=weight], by (region item_code food_purch_unit_new obs_region)
ren price_unit price_unit_median_region
lab var price_unit_median_region "Median price per kg for this crop in the region"
lab var obs_region "Number of observations for this crop in the region"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_region_PP.dta", replace

*Country
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PP.dta", clear
drop if price_unit==.
gen observation = 1
bys item_code food_purch_unit_new: egen obs_country = count(observation)
collapse (median) price_unit [aw=weight], by (item_code food_purch_unit_new obs_country)
ren price_unit price_unit_median_country
lab var price_unit_median_country "Median price per kg for this crop in the country"
lab var obs_country "Number of observations for this crop in the country"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_country_PP.dta", replace


*Pull prices into consumption estimates
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PP.dta", clear
merge m:1 hhid GRAPPE MENAGE EXTENSION using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_hhids.dta", nogen keep (1 3)
gen food_purch_unit_old=food_purch_unit_new

duplicates drop hhid item_code crop_category1, force

drop food_prod_value food_gift_value

* Value Food consumption, production, and gift when the units does not match the units of purchased
foreach f in consu prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit_new==food_purch_unit_new


*- using grappe medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 GRAPPE item_code food_purch_unit_new using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_GRAPPE_PP.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_GRAPPE if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_GRAPPE>10 & obs_GRAPPE!=.


*- using ea medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 ea item_code food_purch_unit_new using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_ea_PP.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_ea if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_ea>10 & obs_ea!=.

*- using commune medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 commune item_code food_purch_unit_new using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_commune_PP.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_commune if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_commune>10 & obs_commune!=. 

*- using department medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 department item_code food_purch_unit_new using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_department_PP.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_department if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_department>10 & obs_department!=. 


*- using region medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 region item_code food_purch_unit_new using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_region_PP.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_region if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_region>10 & obs_region!=.

*- using country medians
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 item_code food_purch_unit_new using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_country_PP.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid item_code crop_category1 food_`f'_value
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PP_`f'.dta", replace
restore
}

duplicates drop hhid item_code crop_category1, force

merge 1:1  hhid item_code crop_category1  using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PP_consu.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PP_prod.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PP_gift.dta", nogen

collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid crop_category1 GRAPPE MENAGE EXTENSION)
recode  food_consu_value food_purch_value food_prod_value food_gift_value (.=0)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_food_home_consumption_value_PP.dta", replace


use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_food_home_consumption_value_PP.dta", clear
merge m:1 hhid GRAPPE MENAGE EXTENSION using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_hhids.dta", nogen keep(1 3)

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

gen visit="PP"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_food_consumption_value_PP.dta", replace


*HARVEST 
use "${Niger_ECVMA_W2_raw_data}/ECVMA2_MS12P2", clear
egen hhid=concat(GRAPPE MENAGE EXTENSION)
ren MS12Q01 item_code
label list MS12Q01

gen crop_category1=""			
replace crop_category1=	"Maize"	if  item_code==	701
replace crop_category1=	"Millet and Sorghum"	if  item_code==	702
replace crop_category1=	"Rice"	if  item_code==	703
replace crop_category1=	"Wheat"	if  item_code==	704
replace crop_category1=	"Millet and Sorghum"	if  item_code==	705
replace crop_category1=	"Rice"	if  item_code==	706
replace crop_category1=	"Other Cereals"	if  item_code==	707
replace crop_category1=	"Maize"	if  item_code==	708
replace crop_category1=	"Cassava"	if  item_code==	709
replace crop_category1=	"Wheat"	if  item_code==	710
replace crop_category1=	"Wheat"	if  item_code==	711
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	712
replace crop_category1=	"Pulses"	if  item_code==	713
replace crop_category1=	"Wheat"	if  item_code==	714
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	715
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	716
replace crop_category1=	"Vegetables"	if  item_code==	717
replace crop_category1=	"Vegetables"	if  item_code==	718
replace crop_category1=	"Vegetables"	if  item_code==	719
replace crop_category1=	"Vegetables"	if  item_code==	720
replace crop_category1=	"Vegetables"	if  item_code==	721
replace crop_category1=	"Vegetables"	if  item_code==	722
replace crop_category1=	"Vegetables"	if  item_code==	723
replace crop_category1=	"Vegetables"	if  item_code==	724
replace crop_category1=	"Vegetables"	if  item_code==	725
replace crop_category1=	"Vegetables"	if  item_code==	726
replace crop_category1=	"Vegetables"	if  item_code==	727
replace crop_category1=	"Vegetables"	if  item_code==	728
replace crop_category1=	"Vegetables"	if  item_code==	729
replace crop_category1=	"Vegetables"	if  item_code==	730
replace crop_category1=	"Pulses"	if  item_code==	731
replace crop_category1=	"Pulses"	if  item_code==	732
replace crop_category1=	"Pulses"	if  item_code==	733
replace crop_category1=	"Pulses"	if  item_code==	734
replace crop_category1=	"Spices"	if  item_code==	735
replace crop_category1=	"Spices"	if  item_code==	736
replace crop_category1=	"Groundnuts"	if  item_code==	737
replace crop_category1=	"Groundnuts"	if  item_code==	738
replace crop_category1=	"Groundnuts"	if  item_code==	739
replace crop_category1=	"Spices"	if  item_code==	740
replace crop_category1=	"Vegetables"	if  item_code==	741
replace crop_category1=	"Vegetables"	if  item_code==	742
replace crop_category1=	"Vegetables"	if  item_code==	743
replace crop_category1=	"Vegetables"	if  item_code==	744
replace crop_category1=	"Spices"	if  item_code==	745
replace crop_category1=	"Spices"	if  item_code==	746
replace crop_category1=	"Spices"	if  item_code==	747
replace crop_category1=	"Cassava"	if  item_code==	748
replace crop_category1=	"Yams"	if  item_code==	749
replace crop_category1=	"Potato"	if  item_code==	750
replace crop_category1=	"Yams"	if  item_code==	751
replace crop_category1=	"Yams"	if  item_code==	752
replace crop_category1=	"Other Roots and Tubers"	if  item_code==	753
replace crop_category1=	"Fruits"	if  item_code==	754
replace crop_category1=	"Fruits"	if  item_code==	755
replace crop_category1=	"Fruits"	if  item_code==	756
replace crop_category1=	"Fruits"	if  item_code==	757
replace crop_category1=	"Fruits"	if  item_code==	758
replace crop_category1=	"Fruits"	if  item_code==	759
replace crop_category1=	"Fruits"	if  item_code==	760
replace crop_category1=	"Fruits"	if  item_code==	761
replace crop_category1=	"Fruits"	if  item_code==	762
replace crop_category1=	"Fruits"	if  item_code==	763
replace crop_category1=	"Fruits"	if  item_code==	764
replace crop_category1=	"Fruits"	if  item_code==	765
replace crop_category1=	"Beef Meat"	if  item_code==	766
replace crop_category1=	"Other Meat"	if  item_code==	767
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	768
replace crop_category1=	"Lamb and Goat Meat"	if  item_code==	769
replace crop_category1=	"Poultry Meat"	if  item_code==	770
replace crop_category1=	"Other Meat"	if  item_code==	771
replace crop_category1=	"Other Meat"	if  item_code==	772
replace crop_category1=	"Other Meat"	if  item_code==	773
replace crop_category1=	"Fish and Seafood"	if  item_code==	774
replace crop_category1=	"Fish and Seafood"	if  item_code==	775
replace crop_category1=	"Fish and Seafood"	if  item_code==	776
replace crop_category1=	"Fish and Seafood"	if  item_code==	777
replace crop_category1=	"Fish and Seafood"	if  item_code==	778
replace crop_category1=	"Oils, Fats"	if  item_code==	779
replace crop_category1=	"Oils, Fats"	if  item_code==	780
replace crop_category1=	"Oils, Fats"	if  item_code==	781
replace crop_category1=	"Oils, Fats"	if  item_code==	782
replace crop_category1=	"Oils, Fats"	if  item_code==	783
replace crop_category1=	"Groundnuts"	if  item_code==	784
replace crop_category1=	"Eggs"	if  item_code==	785
replace crop_category1=	"Dairy"	if  item_code==	786
replace crop_category1=	"Dairy"	if  item_code==	787
replace crop_category1=	"Dairy"	if  item_code==	788
replace crop_category1=	"Dairy"	if  item_code==	789
replace crop_category1=	"Dairy"	if  item_code==	790
replace crop_category1=	"Dairy"	if  item_code==	791
replace crop_category1=	"Dairy"	if  item_code==	792
replace crop_category1=	"Sugar, Sweets, Pastries"	if  item_code==	793
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	794
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	795
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	796
replace crop_category1=	"Other Food"	if  item_code==	797
replace crop_category1=	"Tobacco"	if  item_code==	798
replace crop_category1=	"Tobacco"	if  item_code==	799
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	800
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	801
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	802
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	803
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	804
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	805
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	806
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	807
replace crop_category1=	"Millet and Sorghum"	if  item_code==	808
replace crop_category1=	"Millet and Sorghum"	if  item_code==	809
replace crop_category1=	"Millet and Sorghum"	if  item_code==	810
replace crop_category1=	"Millet and Sorghum"	if  item_code==	811
replace crop_category1=	"Millet and Sorghum"	if  item_code==	812
replace crop_category1=	"Millet and Sorghum"	if  item_code==	813
replace crop_category1=	"Pulses"	if  item_code==	814
replace crop_category1=	"Pulses"	if  item_code==	815
replace crop_category1=	"Other Food"	if  item_code==	816
replace crop_category1=	"Other Food"	if  item_code==	817
replace crop_category1=	"Other Food"	if  item_code==	818
replace crop_category1=	"Other Food"	if  item_code==	819
replace crop_category1=	"Other Cereals"	if  item_code==	820
replace crop_category1=	"Other Food"	if  item_code==	821
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	822
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	823
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	824
replace crop_category1=	"Non-Dairy Beverages"	if  item_code==	825


ren MS12Q02 food_consu_yesno

ren MS12Q03A food_purch_qty
ren MS12Q03B food_purch_unit
ren MS12Q03C food_purch_value

ren MS12Q04A food_prod_qty
ren MS12Q04B food_prod_unit
ren MS12Q04C food_prod_value

ren MS12Q05A food_gift_qty
ren MS12Q05B  food_gift_unit
ren MS12Q05C food_gift_value

egen food_consu_qty = rowtotal(food_purch_qty food_prod_qty food_gift_qty)
gen food_consu_unit = food_purch_unit

label list MS12Q03B 

foreach unit in food_consu food_purch food_prod food_gift {
gen `unit'_unit_new=""			
replace `unit'_unit_new=	"Bottle"	if `unit'_unit==	1
replace `unit'_unit_new=	"Tia"	if `unit'_unit==	2
replace `unit'_unit_new=	"Basket"	if `unit'_unit==	3
replace `unit'_unit_new=	"Tongolo"	if `unit'_unit==	4
replace `unit'_unit_new=	"Kg"	if `unit'_unit==	5
replace `unit'_unit_new=	"Gram"	if `unit'_unit==	6
replace `unit'_unit_new=	"Unit"	if `unit'_unit==	7
replace `unit'_unit_new=	"Liter"	if `unit'_unit==	8
replace `unit'_unit_new=	"Centiliter"	if `unit'_unit==	9
replace `unit'_unit_new=	"Sachet"	if `unit'_unit==	10
replace `unit'_unit_new=	"Heap"	if `unit'_unit==	11
replace `unit'_unit_new=	"Other"	if `unit'_unit==	12
replace `unit'_unit_new=	"20 Liter Bucket"	if `unit'_unit==	13
replace `unit'_unit_new=	"10 Liter Bucket"	if `unit'_unit==	14
replace `unit'_unit_new=	"5  Liter Bucket"	if `unit'_unit==	15
replace `unit'_unit_new=	"Large Can"	if `unit'_unit==	16
replace `unit'_unit_new=	"Medium Can"	if `unit'_unit==	17
replace `unit'_unit_new=	"Small Can"	if `unit'_unit==	18
replace `unit'_unit_new=	"Large basket"	if `unit'_unit==	19
replace `unit'_unit_new=	"Medium basket"	if `unit'_unit==	20
replace `unit'_unit_new=	"Small basket"	if `unit'_unit==	21
replace `unit'_unit_new=	"1/2 tiya (en cup)"	if `unit'_unit==	22
replace `unit'_unit_new=	"1/4 tiya (en cup)"	if `unit'_unit==	23
replace `unit'_unit_new=	"Waygouiz "	if `unit'_unit==	24
replace `unit'_unit_new=	"Moudou"	if `unit'_unit==	25
replace `unit'_unit_new=	"Large can of condensed milk"	if `unit'_unit==	26
replace `unit'_unit_new=	"Tarzan bottle"	if `unit'_unit==	27
replace `unit'_unit_new=	"large ladle"	if `unit'_unit==	28
replace `unit'_unit_new=	"Medium ladle"	if `unit'_unit==	29
replace `unit'_unit_new=	"Small ladle"	if `unit'_unit==	30
replace `unit'_unit_new=	"Large calabash"	if `unit'_unit==	31
replace `unit'_unit_new=	"Medium gourd"	if `unit'_unit==	32
replace `unit'_unit_new=	"Small calabash"	if `unit'_unit==	33
replace `unit'_unit_new=	"."	if `unit'_unit==	99
			

replace `unit'_qty= `unit'_qty/1000 if `unit'_unit_new=="Gram"   		//Gram to Kg
replace `unit'_unit_new="Kg" if `unit'_unit_new=="Gram"

replace `unit'_qty= `unit'_qty/0.01 if `unit'_unit_new=="Centiliter" 	//Centiliter to Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="Centiliter" 

replace `unit'_qty= `unit'_qty*20 if `unit'_unit_new=="20 Liter Bucket"   		//20 Liters to Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="20 Liter Bucket"
replace `unit'_qty= `unit'_qty*10 if `unit'_unit_new=="10 Liter Bucket"   	//10 Liters to Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="10 Liter Bucket"
replace `unit'_qty= `unit'_qty*5 if `unit'_unit_new=="5  Liter Bucket"   	//5 Liters to Liter
replace `unit'_unit_new="Liter" if `unit'_unit_new=="5  Liter Bucket"

}


*Dealing the other unit categories
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (6 = 5 )  // Gram to Kg 
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (9 = 8 )  // Centiliter to Liter
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (13 = 8 )  // 20 Liters to Liter  
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (14 = 8 )  // 10 Liters to Liter  
recode food_consu_unit food_purch_unit food_prod_unit food_gift_unit (15 = 8 )  // 5 Liters to Liter  

keep if food_consu_yesno==1
drop if food_consu_qty==0  | food_consu_qty==.
*Input the value of consumption using prices infered from the quantity of purchase and the value of pruchases.
gen price_unit= food_purch_value/food_purch_qty
recode price_unit (0=.)

merge m:1 hhid GRAPPE MENAGE EXTENSION using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_hhids.dta", nogen keep (1 3)

save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PH.dta", replace

 
*  Grappe
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PH.dta", clear
drop if price_unit==.
gen observation = 1
bys GRAPPE item_code food_purch_unit_new: egen obs_GRAPPE = count(observation)
collapse (median) price_unit [aw=weight], by (GRAPPE item_code food_purch_unit_new obs_GRAPPE)
ren price_unit price_unit_median_GRAPPE
lab var price_unit_median_GRAPPE "Median price per kg for this crop in the enumeration area - GRAPPE"
lab var obs_GRAPPE "Number of observations for this crop in the enumeration area - GRAPPE"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_GRAPPE_PH.dta", replace


* EA
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PH.dta", clear
drop if price_unit==.
gen observation = 1
bys ea item_code food_purch_unit_new: egen obs_ea = count(observation)
collapse (median) price_unit [aw=weight], by (ea item_code food_purch_unit_new obs_ea)
ren price_unit price_unit_median_ea
lab var price_unit_median_ea "Median price per kg for this crop in the ea"
lab var obs_ea "Number of observations for this crop in the ea"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_ea_PH.dta", replace

* Commune
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PH.dta", clear
drop if price_unit==.
gen observation = 1
bys commune item_code food_purch_unit_new: egen obs_commune = count(observation)
collapse (median) price_unit [aw=weight], by (commune item_code food_purch_unit_new obs_commune)
ren price_unit price_unit_median_commune
lab var price_unit_median_commune "Median price per kg for this crop in the commune"
lab var obs_commune "Number of observations for this crop in the commune"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_commune_PH.dta", replace

* Department
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PH.dta", clear
drop if price_unit==.
gen observation = 1
bys department item_code food_purch_unit_new: egen obs_department = count(observation)
collapse (median) price_unit [aw=weight], by (department item_code food_purch_unit_new obs_department)
ren price_unit price_unit_median_department
lab var price_unit_median_department "Median price per kg for this crop in the department"
lab var obs_department "Number of observations for this crop in the department"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_department_PH.dta", replace

* region
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PH.dta", clear
drop if price_unit==.
gen observation = 1
bys region item_code food_purch_unit_new: egen obs_region = count(observation)
collapse (median) price_unit [aw=weight], by (region item_code food_purch_unit_new obs_region)
ren price_unit price_unit_median_region
lab var price_unit_median_region "Median price per kg for this crop in the region"
lab var obs_region "Number of observations for this crop in the region"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_region_PH.dta", replace

*Country
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PH.dta", clear
drop if price_unit==.
gen observation = 1
bys item_code food_purch_unit_new: egen obs_country = count(observation)
collapse (median) price_unit [aw=weight], by (item_code food_purch_unit_new obs_country)
ren price_unit price_unit_median_country
lab var price_unit_median_country "Median price per kg for this crop in the country"
lab var obs_country "Number of observations for this crop in the country"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_country_PH.dta", replace


*Pull prices into consumption estimates
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PH.dta", clear


merge m:1 hhid GRAPPE MENAGE EXTENSION using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_hhids.dta", nogen keep (1 3)
gen food_purch_unit_old=food_purch_unit_new

duplicates drop hhid item_code crop_category1, force

drop food_prod_value food_gift_value

* Value Food consumption, production, and gift when the units does not match the units of purchased
foreach f in consu prod gift {
preserve
gen food_`f'_value=food_`f'_qty*price_unit if food_`f'_unit_new==food_purch_unit_new


*- using grappe medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 GRAPPE item_code food_purch_unit_new using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_GRAPPE_PH.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_GRAPPE if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_GRAPPE>10 & obs_GRAPPE!=.


*- using ea medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 ea item_code food_purch_unit_new using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_ea_PH.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_ea if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_ea>10 & obs_ea!=.

*- using commune medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 commune item_code food_purch_unit_new using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_commune_PH.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_commune if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_commune>10 & obs_commune!=. 

*- using department medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 department item_code food_purch_unit_new using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_department_PH.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_department if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_department>10 & obs_department!=. 


*- using region medians with at least 10 observations
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 region item_code food_purch_unit_new using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_region_PH.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_region if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_region>10 & obs_region!=.

*- using country medians
drop food_purch_unit_new 
gen food_purch_unit_new=food_`f'_unit_new 
merge m:1 item_code food_purch_unit_new using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_item_prices_country_PH.dta", nogen keep(1 3)
replace food_`f'_value=food_`f'_qty*price_unit_median_country if food_`f'_unit_new==food_purch_unit_new & food_`f'_value==. & obs_country>10 & obs_country!=.

keep hhid item_code crop_category1 food_`f'_value
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PH_`f'.dta", replace
restore
}

duplicates drop hhid item_code crop_category1, force

merge 1:1  hhid item_code crop_category1  using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PH_consu.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PH_prod.dta", nogen
merge 1:1  hhid item_code crop_category1  using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_consumption_purchase_PH_gift.dta", nogen

collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid crop_category1 GRAPPE MENAGE EXTENSION)
recode  food_consu_value food_purch_value food_prod_value food_gift_value (.=0)
replace food_consu_value=food_purch_value if food_consu_value<food_purch_value  // recode consumption to purchase if smaller
label var food_consu_value "Value of food consumed over the past 7 days"
label var food_purch_value "Value of food purchased over the past 7 days"
label var food_prod_value "Value of food produced by household over the past 7 days"
label var food_gift_value "Value of food received as a gift over the past 7 days"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_food_home_consumption_value_PH.dta", replace


use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_food_home_consumption_value_PH.dta", clear
merge m:1 hhid GRAPPE MENAGE EXTENSION using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_hhids.dta", nogen keep(1 3)

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

gen visit="PH"
save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_food_consumption_value_PH.dta", replace


 *Average PP and PH
use "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_food_consumption_value_PP.dta", clear
append using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_food_consumption_value_PH.dta"
merge m:1 hhid GRAPPE MENAGE EXTENSION using "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_hhids.dta", nogen keep(1 3)

foreach v of varlist * {
		local l`v': var label `v'
}

collapse (sum) food_consu_value food_purch_value food_prod_value food_gift_value, by(hhid GRAPPE MENAGE EXTENSION region department commune fhh hh_members adulteq rural weight crop_category1)

foreach v of varlist * {
	label var `v' "`l`v''" 
}


*RESCALING the components of consumption such that the sum always match
** winsorize top 1%
foreach v in food_consu_value food_purch_value food_prod_value food_gift_value {
	_pctile `v' [aw=weight] if `v'!=0 , p($wins_upper_thres)  
	gen w_`v'=`v'
	replace  w_`v' = r(r1) if  w_`v' > r(r1) &  w_`v'!=.
	local l`v' : var lab `v'
	lab var  w_`v'  "`l`v'' - Winzorized top 1%"
}

drop hhid 
egen hhid=concat(GRAPPE MENAGE EXTENSION)
lab var hhid "Household ID"

save "${Niger_ECVMA_W2_created_data}/Niger_ECVMA_W2_food_consumption_value_combined.dta", replace


ren region adm1
lab var adm1 "Adminstrative subdivision 1 - state/region/province"
ren department adm2
lab var adm2 "Adminstrative subdivision 2 - lga/district/municipality"
ren commune adm3
lab var adm3 "Adminstrative subdivision 3 - county"
qui gen Country="Niger"
lab var Country "Country name"
qui gen Instrument="Niger ECVMA W2"
lab var Instrument "Survey name"
qui gen Year="2014"
lab var Year "Survey year"

keep hhid crop_category1 food_consu_value food_purch_value food_prod_value food_gift_value hh_members adulteq fhh adm1 adm2 adm3 weight rural w_food_consu_value w_food_purch_value w_food_prod_value w_food_gift_value Country Instrument Year

*generate GID_1 code to match codes in the Benin shapefile
gen GID_1=""
replace GID_1="NER.1_1"  if adm1==1
replace GID_1="NER.2_1"  if adm1==2
replace GID_1="NER.3_1"  if adm1==3
replace GID_1="NER.4_1"  if adm1==4
replace GID_1="NER.5_1"  if adm1==8
replace GID_1="NER.6_1"  if adm1==5
replace GID_1="NER.7_1"  if adm1==6
replace GID_1="NER.8_1"  if adm1==7
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
replace conv_lcu_ppp=	0.004237831	if Instrument==	"Niger ECVMA W2"

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
save "${final_data}/Niger_ECVMA_W2_food_consumption_value_by_source.dta", replace


*****End of Do File*****
  
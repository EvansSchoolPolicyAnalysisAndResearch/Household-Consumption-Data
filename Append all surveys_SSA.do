
clear
clear matrix
clear mata
program drop _all
set more off
set maxvar 10000


*Set location of raw data and output
global directory	"//netid.washington.edu/wfs/EvansEPAR/Project/EPAR/Working Files/439 - Household Food Consumption by Source/Food consumption by source/Consumption Data Curation"

global final_data  	"$directory/final_data"

global list_surveys "Nigeria_GHS_W4 Nigeria_GHS_W3 Nigeria_GHS_W2 Nigeria_GHS_W1 Ethiopia_ESS_W5 Ethiopia_ESS_W4 Ethiopia_ESS_W3 Tanzania_NPS_W5 Tanzania_NPS_W4 Tanzania_NPS_W3 Tanzania_NPS_W2 Tanzania_NPS_W1 Malawi_IHS_W4 Malawi_IHS_W3 Malawi_IHS_W2 Malawi_IHS_W1 Uganda_UNPS_W8 Uganda_UNPS_W7 Uganda_UNPS_W5 Uganda_UNPS_W4 Uganda_UNPS_W3 Uganda_UNPS_W2 Uganda_UNPS_W1 Burkina_EHCVM_W1 Burkina_EHCVM_W2 Benin_EHCVM_W1 CI_EHCVM_W1 GB_EHCVM_W1 Senegal_EHCVM_W1 Mali_EHCVM_W1 Mali_EACI_W1 Niger_EHCVM_W1 Togo_EHCVM_W1 SierraLeone_IHS_W3 Kenya_IHS_W1 Ghana_SPS_W1" 


use "${final_data}/Nigeria_GHS_W4_food_consumption_value_by_source.dta", clear
foreach s of global list_surveys {
	di 
	append using "${final_data}/`s'_food_consumption_value_by_source.dta",force
}
duplicates drop
compress

count
codebook, c
tab Instrument

save "${final_data}/ALL_SURVEYS_food_consumption_value_by_source.dta", replace


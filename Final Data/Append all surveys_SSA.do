 /*-------------------------------------------------------------------------------------------------------------------------
*Title/Purpose 	: This do.file was developed by the Evans School Policy Analysis & Research Group (EPAR) 
				 for the construction of a set of household food consumption by food categories and source
				 (purchased, own production, and gifts) indicators
				 
*Author(s)		: Amaka Nnaji, Didier Alia & C. Leigh Anderson

*Acknowledgments: We acknowledge the helpful contributions of EPAR Research Assistants, Post-docs, and Research Scientists who provided helpful comments during the process of developing these codes. We are also grateful to the World Bank's LSMS-ISA team, IFPRI, and National Bureaus of Statistics in the countries included in the analysis for collecting the raw data and making them publicly available. Finally, we acknowledge the support of the Bill & Melinda Gates Foundation Agricultural Development Division. 
				  All coding errors remain ours alone.
				  
*Date			: August 2024
-------------------------------------------------------------------------------------------------------------------------*/


clear
clear matrix
clear mata
program drop _all
set more off
set maxvar 10000

global list_surveys "Nigeria_GHS_W4 Nigeria_GHS_W3 Nigeria_GHS_W2 Nigeria_GHS_W1 Ethiopia_ESS_W5 Ethiopia_ESS_W4 Ethiopia_ESS_W3 Tanzania_NPS_W5 Tanzania_NPS_W4 Tanzania_NPS_W3 Tanzania_NPS_W2 Tanzania_NPS_W1 Malawi_IHS_W4 Malawi_IHS_W3 Malawi_IHS_W2 Malawi_IHS_W1 Uganda_UNPS_W8 Uganda_UNPS_W7 Uganda_UNPS_W5 Uganda_UNPS_W4 Uganda_UNPS_W3 Uganda_UNPS_W2 Uganda_UNPS_W1 Burkina_EHCVM_W1 Burkina_EHCVM_W2 Benin_EHCVM_W1 CI_EHCVM_W1 GB_EHCVM_W1 Senegal_EHCVM_W1 Mali_EHCVM_W1 Mali_EACI_W1 Niger_EHCVM_W1 Togo_EHCVM_W1 SierraLeone_IHS_W3 Kenya_IHS_W1 Ghana_SPS_W1" 


use "Nigeria_GHS_W4_food_consumption_value_by_source.dta", clear
foreach s of global list_surveys {
	di 
	append using "`s'_food_consumption_value_by_source.dta",force
}
duplicates drop
compress

lab var hhid "Household ID"
drop adm3 ccf_1ppp ccf_2ppp 

count
codebook, c
tab Instrument

drop if crop_category1==""
drop adm1x 

save "ALL_SURVEYS_food_consumption_value_by_source.dta", replace


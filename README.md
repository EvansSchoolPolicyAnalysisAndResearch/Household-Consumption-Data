# Household-Consumption-Data
* This repository includes codes for constructing the value of household food consumption from different sources by crop and documentation for construction decisions across instruments.
* Countries captured include Bangladesh, Benin, Burkina Faso, Cote d'Ivoire, Ethiopia, Gambia, Ghana, Guinea Bissau, Kenya, India, Malawi, Mali, Niger, Nigeria, Pakistan, Senegal, Tanzania, Togo, and Uganda.
* The raw data was downloaded from various secondary sources including:
    * Burkina Faso Continuous Multisectoral Survey (EMC) 2014
    * Ethiopia Socioeconomic Survey (ESS) LSMS-ISA Wave 3 & 4 (2015/16 and 2018/19)
    * Malawi Integrated Household Survey (IHS) LSMS-ISA Wave 1 & 2 (2010/11 and 2013)
    * Mali Enquête Agricole de Conjoncture Intégrée (EACI) 2014
    * Niger Enquête Nationale sur les Conditions de Vie des Ménages et l’Agriculture (ECVMA) LSMS-ISA Waves 1 & 2 (2011 and 2014)
    * Nigeria General Household Survey (GHS) LSMS-ISA Wave 1, 2, 3 & 4 (2010/22, 2012/13, 2015/16 and 2018/19)
    * Tanzania National Panel Survey (NPS) LSMS-ISA Waves 1, 2, 3, 4 & 5 (2008/09, 2010/11, 2012/13, 2014/15, 2019/20)
    * Uganda National Panel Survey (UNPS) LSMS-ISA Waves 1, 2, 3, 4, 5, 6, 7 (2009/10, 2010/11, 2011/12, 2013/14, 2015/16, 2018/19, 2019/20)
    * Bangladesh Integrated Household Survey (BIHS) (2011/12, 2015/16, 2018/19)
    * India Household Consumer Expenditure (HCE) 2011/12
    * Pakistan Household Integrated Economic Survey (HIES) 2005/06, 2008/09, 2011/12, 2012/13, 2016/17, 2018/19
    * Kenya Integrated Household Budget Survey (KIHBS) 2015/16
    * Gambia Integrated Household Survey (IHS) 2015/16
    * Ghana Socioeconomic Panel Survey (SPS) 2009/10
    * Sierra Leone Integrated Household Survey (IHS) 2018
    * Enquête Harmonisée sur le Conditions de Vie des Ménages 2018-2019 (Senegal, Benin, Togo, Cote d'Ivoire, Guinea Bissau, Mali, Burkina Faso, and Niger)
    * Burkina Faso Enquête Harmonisée sur le Conditions de Vie des Ménages 2021/22 


## Prerequisites
* Download the raw data from [https://microdata.worldbank.org/index.php/catalog/3557](https://microdata.worldbank.org/index.php/catalog/6161)
* Extract the files to the "Raw DTA Files" folder in the cloned directory
* Create sub-folders in the 'Raw DTA Files" (if desired) to align with current referenced file paths throughout the code (e.g. Household vs. Post Planting, etc.)
* Update the directories with the correct paths to the raw data, created data and final data files

## Table of Contents
### Globals 
* This section sets global variables for use later in the script, including
  * **Exchange Rates**
  * **Poverty Thresholds**
  * **Population:** We reference true rural and urban population estimates from the World Bank to re-weight households.
  * **Thresholds for Winsorization:** the smallest (below the 1 percentile) and largest (above the 99 percentile) are replaced with the observations closest to them
 

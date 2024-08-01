<table>
  <tr>
    <th>Company</th>
    <th>Contact</th>
    <th>Country</th>
  </tr>
  <tr>
    <td>Alfreds Futterkiste</td>
    <td>Maria Anders</td>
    <td>Germany</td>
  </tr>
  <tr>
    <td>Centro comercial Moctezuma</td>
    <td>Francisco Chang</td>
    <td>Mexico</td>
  </tr>
</table>

# Household-Consumption-By-Source
* This repository includes codes for constructing the value of household food consumption from different sources by crop and documentation for construction decisions across instruments.
* Countries captured include Bangladesh, Benin, Burkina Faso, Cote d'Ivoire, Ethiopia, Gambia, Ghana, Guinea Bissau, Kenya, India, Malawi, Mali, Niger, Nigeria, Pakistan, Senegal, Tanzania, Togo, and Uganda.

## Table of Contents
### Globals 
* This section sets global variables for use later in the script, including
  * **Exchange Rates and Inflation Conversions**
  * **Population:** We reference true rural and urban population estimates from the World Bank to re-weight households.
  * **Thresholds for Winsorization:** the smallest (below the 1 percentile) and largest (above the 99 percentile) are replaced with the observations closest to them
 
### Household IDs
- **Description:** This dataset includes hhid/grappe menage/hhcode as a unique identifier, along with its location identifiers (e.g. rural, region, zone, department, province, ea, etc.). Other variables created here include: 
    * Female-headed household indicator
    * Household survey weight
    * Number of household members
    * Adult-equivalent
    * Rural location indicator

### Consumption
- **Description:** This dataset includes hhid/grappe menage/hhcode as a unique identifier and constructs food consumption at the crop level by the different sources (from purchases, own production, and gifts). 
- **Data Construction Notes:**
    *  Food items are aggregated into major crop categories.
    *  The value of food consumption from purchases was constructed using reported food prices in the surveys.
    *  The value of food consumption from own production and gifts are computed using the mean purchase price of the food items at various administrative levels. For instance, when the purchase price of a food item is reported by more than 10 observations in an enumeration area, the value of food consumed by the food item from production and gifts is derived by multiplying the food quantity with the median purchase price in that enumeration area. Depending on observations, the mean purchase price for each unit of food item was constructed at the different levels of disaggregation (enumeration area, local government area, woreda, district, state, and country).
    *  The average was calculated for surveys that collected food consumption data in two visits (post-planting and post-harvest visit).
    *  Most surveys capture food consumption over the past 7 days before the visits. The annualized value of food consumption was derived by multiplying by 52 (the number of 7 days in a year).
    *  Household food consumption from purchases is inclusive of food consumed away from home.
    *  To remove outliers, the value of food consumption was winsorized at the top 1% threshold.
    *  The average value of food consumption can be calculated using survey weights to be representative of the country and location levels.
    *  Food consumption values in Local Currency Units are converted to 2017 Purchasing Power Parity (PPP). 

### Data sources
* The raw data was downloaded from various secondary sources including:
    * Bangladesh Integrated Household Survey (BIHS) (2011/12, 2015/16, 2018/19)
    * Benin Enquête Harmonisée sur le Conditions de Vie des Ménages 2021/22 
    * Burkina Faso Continuous Multisectoral Survey (EMC) 2014
    * Ethiopia Socioeconomic Survey (ESS) LSMS-ISA Wave 3 & 4 (2015/16 and 2018/19)
    * Malawi Integrated Household Survey (IHS) LSMS-ISA Wave 1 & 2 (2010/11 and 2013)
    * Mali Enquête Agricole de Conjoncture Intégrée (EACI) 2014.
    * Niger Enquête Nationale sur les Conditions de Vie des Ménages et l’Agriculture (ECVMA) LSMS-ISA Waves 1 & 2 (2011 and 2014)
    * Nigeria General Household Survey (GHS) LSMS-ISA Wave 1, 2, 3 & 4 (2010/22, 2012/13, 2015/16 and 2018/19)
    * Tanzania National Panel Survey (NPS) LSMS-ISA Waves 1, 2, 3, 4 & 5 (2008/09, 2010/11, 2012/13, 2014/15, 2019/20)
    * Uganda National Panel Survey (UNPS) LSMS-ISA Waves 1, 2, 3, 4, 5, 6, 7 (2009/10, 2010/11, 2011/12, 2013/14, 2015/16, 2018/19, 2019/20)
    
    * India Household Consumer Expenditure (HCE) 2011/12
    * Pakistan Household Integrated Economic Survey (HIES) 2005/06, 2008/09, 2011/12, 2012/13, 2016/17, 2018/19
    * Kenya Integrated Household Budget Survey (KIHBS) 2015/16
    * Gambia Integrated Household Survey (IHS) 2015/16
    * Ghana Socioeconomic Panel Survey (SPS) 2009/10
    * Sierra Leone Integrated Household Survey (IHS) 2018
    * Enquête Harmonisée sur le Conditions de Vie des Ménages 2018-2019 (Senegal, Benin, Togo, Cote d'Ivoire, Guinea Bissau, Mali, Burkina Faso, and Niger)
    * Burkina Faso Enquête Harmonisée sur le Conditions de Vie des Ménages 2021/22 

### Prerequisites
* Download the raw data from the different sources.
* For each country, extract the raw data files to a folder and update the global directory named "Country_Survey_raw_data" with the appropriate folder path.
* Next create a folder where to store intermediary data files created and update the global directory named "Country_Survey_created_data".
* Also, create a folder to store all final data files created and update the global directory named "final_data".





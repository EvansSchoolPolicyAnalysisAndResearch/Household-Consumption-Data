

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
    * Age of household head
    * Number of household members
    * Number of working-age adults
    * Number of working-age female adults
    * Number of working-age male adults
    * Number of elders
    * Number of children
    * Adult-equivalent
    * Rural location indicator
    * survey interview day, month, and year.

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

## Data sources
* The raw data was downloaded from various secondary sources including:
<table>
 <tr>
    <th>Country</th>
    <th>Survey</th>
    <th>Years</th>
 </tr>
   <tr>
    <td>Bénin</td>
    <td>Enquête Harmonisée sur les Conditions de Vie des Ménages (EHCVM)</td>
    <td>2018/19</td>
  </tr>
  <tr>
    <td> Burkina Faso</td>
    <td>Enquête Harmonisée sur les Conditions de Vie des Ménages (EHCVM)</td>
    <td>2018/19, 2021/21</td>
  </tr>
  <tr>
    <td>Cote d'Ivoire</td>
    <td>Enquête Harmonisée sur les Conditions de Vie des Ménages (EHCVM)</td>
    <td>2018/19</td>
  </tr>
  <tr>
    <td>Ethiopia</td>
    <td>Socioeconomic Panel Survey (ESS)</td>
    <td>2015/16, 2018/19, 2012/22</td>
  </tr>
  <tr>
    <td>Ghana</td>
    <td>Socioeconomic Panel Survey (SPS)</td>
    <td>2009/10</td>
  </tr>
   <tr>
    <td>Guinea Bissau</td>
    <td>Enquête Harmonisée sur les Conditions de Vie des Ménages (EHCVM)</td>
    <td>2018/19</td>
  </tr>
  <tr>
    <td>Kenya</td>
    <td>Integrated Household Budget Survey (KIHBS)</td>
    <td>2015/16</td>
  </tr>
  <tr>
    <td>Malawi</td>
    <td>Integrated Household Survey (IHS)</td>
    <td>2010/11, 2013, 2016/17, 2019/2020</td>
  </tr>
<tr>
    <td>Mali</td>
    <td>Enquête Agricole de Conjoncture Intégrée (EACI)</td>
    <td>2014</td>
  </tr>
  <tr>
    <td></td>
    <td>Enquête Harmonisée sur les Conditions de Vie des Ménages (EHCVM)</td>
    <td>2018/19</td>
  </tr>
 <tr>
    <td>Niger</td>
    <td>Enquête Harmonisée sur les Conditions de Vie des Ménages (EHCVM)</td>
    <td>2018/19</td>
  </tr>
 <tr>
    <td>Nigeria</td>
    <td>General Household Survey (GHS)</td>
    <td>2010/22, 2012/13, 2015/16 and 2018/19</td>
  </tr>
 <tr>
    <td>Senegal</td>
    <td>Enquête Harmonisée sur les Conditions de Vie des Ménages (EHCVM)</td>
    <td>2018/19</td>
  </tr>
 <tr>
    <td>Sierra Leone</td>
    <td>Integrated Household Survey (IHS)</td>
    <td>2018</td>
  </tr>
 <tr>
    <td>Tanzania</td>
    <td>National Panel Survey (NPS)</td>
    <td>2008/09, 2010/11, 2012/13, 2014/15, 2019/20</td>
  </tr>
 <tr>
    <td>Togo</td>
    <td>Enquête Harmonisée sur les Conditions de Vie des Ménages (EHCVM)</td>
    <td>2018/19</td>
  </tr>
  <tr>
    <td>Uganda</td>
    <td>National Panel Survey (UNPS)</td>
    <td>2009/10, 2010/11, 2011/12, 2013/14, 2015/16, 2018/19, 2019/20</td>
  </tr>
</table>


## Prerequisites
* Download the raw data from the different sources.
* For each country, extract the raw data files to a folder and update the global directory named "Country_Survey_raw_data" with the appropriate folder path.
* Next create a folder where to store intermediary data files created and update the global directory named "Country_Survey_created_data".
* Also, create a folder to store all final data files created and update the global directory named "final_data".





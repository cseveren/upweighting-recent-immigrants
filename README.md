# Upweighting Recent Immigrants in the CPS
Project to provide a weighting scheme to upweight just-arrived and recent immigrants in the CPS to better reflect contemporaneous immigration levels.

Research Brief published here XXXX.

## Structure
This repo provides code and crosswalks intended to recreate the Research Brief. The code, detailed below, is written as a collection of Stata do files called from a primary script, `main.do`. The primary data using for the project are too large to post in this repo, but are readily available from [IPUMS](https://www.ipums.org/). See details in [Data](#data) below.

Interested users are welcome to adapt this code or idea to their use; translations to other programming frameworks are welcome.

## Code

This repo contains a file, , `main.do`, which declares relevant global variables (including directory names) and points to rest of the scripts that perform data assmembly, processing, and analysis. 

The primary variables that need to be set are in the first fifteen lines of code. Note that path names should match paths on your computer (I detail data paths below), and that abstract names should also match your data abstracts.
```
** Set relative paths **
global locgit "your path here"
global locdta "your path here"
global git "${locgit}/upweighting-recent-immigrants"
global dta "${locdta}/UpweightingRecentImmigrants"

** Set data abstract names **
global cps "cps_00016" // must match your abstract name
global acs "usa_00046" // must match your abstract name
global nonresp "SeriesReport-20240911113044_c733bd.xlsx" // these will changed if updated
global cpsces "SeriesReport-20240911122828_9936a0.xlsx" // these will changed if updated
global maxyear = 2024
```

### Interpolation Quality Check

The main file  `main.do` also contains the following lines that should be checked after every new CPS abstract pull. IPUMS CPS bins of the `yrimmig` variable are inconsistent, and could be changed in future releases. The crosswalk discussed in [Data](#data) provides correct mappings for the interpolations for recent IPUMS CPS data. To ensure that the crosswalk works correctly, run the code below and ensure that none of the cells output by the `tab` commands contain zeros.

```
// CHECK THIS EVERY TIME! ENSURE THAT IPUMS HAS NOT CHANGED
// None of the output values should be 0
use $dta/tmp/cps_imm_base.dta
tab time_in_US year 
tab time_in_US year [aw=awt0] 
tab time_in_US year [aw=awtC] 
```


## Data

### Inputs Provided in Repo

The repo includes `$git/inputs/crosswalk_to_year.xlsx`, which is the crosswalk referenced in the Research Brief. Importantly, this **MUST BE** updated to add additional years if data from 2025 or later is used. You should feel free to do so. 

### Inputs from Other Sources

The structure of data assumed is as follows:
- `$dta/final/` Use for final data creation
- `$dta/inputs/`
  - `./ACS/$acs.dta` ACS data abstract in dta foramt
  - `./Adj_CPS/$cpsces` CPS employment adjustmented to CES frame (see [Data](#data) below)
  - `./CBO/cbo_immig.xlsx` CBO immigration estimates (see [Data](#data) below)
  - `./CPS_Basic/$cps.dta` CPS data abstract in dta format
  - `./CPS_NonResponse/$nonresp` Non-Response data from CPS (see [Data](#data) below)
- `$dta/tmp/` Used for intermediate data processing


#### IPUMS (CPS and ACS)

The CPS abstract used to create this Research Brief covers January 1994 through July 2024 and is taken from [IPUMS CPS](https://cps.ipums.org/cps/). The variables included are:
- YEAR
- SERIAL
- MONTH
- HWTFINL
- CPSID
- ASECFLAG
- PERNUM
- WTFINL
- CPSIDV
- CPSIDP
- AGE
- SEX
- POPSTAT
- BPL
- YRIMMIG
- CITIZEN
- EMPSTAT
- LABFORCE
- IND1990
- CLASSWKR
- MULTJOB
- NUMJOB
- EDUC
- UH_PAYABS_B2


The ACS abstract covers 2000 through 2022 and is taken from [IPUMS USA](https://usa.ipums.org/usa/). The variable included are:

- YEAR
- SAMPLE
- SERIAL
- CBSERIAL
- HHWT
- CLUSTER
- STRATA
- GQ
- PERNUM
- PERWT
- RELATE (general)
- RELATED (detailed)
- MARST
- BPL (general)
- BPLD (detailed)
- CITIZEN
- YRIMMIG
- YRSUSA1
- HINSCAID
- HINSCARE
- HINSVA
- EDUC (general)
- EDUCD (detailed)
- EMPSTAT (general)
- EMPSTATD (detailed)
- LABFORCE
- CLASSWKR (general)
- CLASSWKRD (detailed)
- OCC1990
- INCSS
- INCSUPP
- MIGRATE1 (general)
- MIGRATE1D (detailed)
- VETSTAT (general)
- VETSTATD (detailed)

#### Other Data

To recreate the data, it is also necessary to pull data from the following sources:

- CPS Non-Response rates: these can be found [here](https://data.bls.gov/timeseries/LNU09300000&years_option=all_years).
- CPS Adjusted employment (CPS employment adjusted to CES concepts): this can be found [here](https://data.bls.gov/timeseries/LNS16000000&years_option=all_years).
- Data from CBO’s January 2024 report The Demographic Outlook: 2024 to 2054: these can be found [here](www.cbo.gov/publication/59697) (specifically, Figure 6).
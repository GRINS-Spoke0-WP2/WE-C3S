# WE-C3S/v.1.0.0

The following section illustrates the operations to reproduce the WE-C3S v.1.0.0 dataset:

1. [Download](#C3S-1-Download)
2. [Daily](#C3S-2-Daily)

### C3S 1: Download

The first script is [`C3S_Download.R`](script/C3S_Download.R). This script makes the request about weather variables to the [Climate Change Service](https://cds.climate.copernicus.eu) ([download link](https://eeadmz1-cws-wp-air02-dev.azurewebsites.net/download-data/)) managed by the Copernicus EU programme. The following table summarises the variables requested and the datasets accessed.

| **variable**          | **period** | **dataset**                  |
|-----------------------|------------|------------------------------|
| Temperature           | 2013-2023  | ERA5-Land/ERA5 Single Level  |
| Wind speed and angle  | 2013-2023  | ERA5-Land/ERA5 Single Level  |
| Surface pressure      | 2013-2023  | ERA5-Land/ERA5 Single Level  |
| Precipitation         | 2013-2023  | ERA5-Land/ERA5 Single Level  |
| Vegetation index      | 2013-2023  | ERA5-Land/ERA5 Single Level  |
| Solar radiation       | 2013-2023  | EERA5-Land/ERA5 Single Level |
| Relative humidity     | 2013-2023  | ERA5-Land/ERA5 Single Level  |
| Boundary Layer Height | 2013-2023  | ERA5 Single Level            |

The [ERA5-Land](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-land?tab=overview) has a spatial resolution of 0.1° x 0.1° while [ERA5 Single Level](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=overview) of 0.25° x 0.25°. Request are made for a boundary box for Italy (i.e. 48, 6, 35, 19). Both datasets are hourly.

### C3S 2: Daily

In the second script, [`C3S_HtoD.R`](script/C3S_HtoD.R), the netcdfs downloaded at the previous step are opened, extracted the data, and convert them from hourly to daily using different approaches (e.g. mean, max, median) depending on the peculiarities of the variable considered. All these steps are made using speicifical functions imported from the [`functions.R`](script/functions.R) script. Outputs are Rdata files corresponding to one variable for the entire spatio-temporal domain (Italy, from 2013 to 2023)

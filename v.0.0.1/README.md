# WE-C3S/v.1.0.0

! WARNING ! 6/10/2024: The update of the services provided by the Copernicus programme has affected the download process. Data have to be considered valid.

The following section illustrates the operations to reproduce the WE-C3S v.0.0.1 dataset:

1. [Download](#C3S-1-Download)
2. [Managing](#C3S-2-Preprocessing)

### C3S 1: Download

The first script are [`C3S_Download.R`](script/C3S_Download.R). This script makes the request about weather variables to the [Climate Change Service](https://cds.climate.copernicus.eu) ([download link](https://eeadmz1-cws-wp-air02-dev.azurewebsites.net/download-data/)) managed by the Copernicus EU programme. The following table summarises the variables requested and the datasets accessed.

| **variable**          | **period** | **dataset**       |
|-----------------------|------------|-------------------|
| Temperature           | 2013-2023  | ERA5-Land         |
| Wind speed and angle  | 2013-2023  | ERA5-Land         |
| Surface pressure      | 2013-2023  | ERA5-Land         |
| Precipitation         | 2013-2023  | ERA5-Land         |
| Vegetation index      | 2013-2023  | ERA5-Land         |
| Solar radiation       | 2013-2023  | ERA5-Land         |
| Relative humidity     | 2013-2023  | ERA5-Land         |
| Boundary Layer Height | 2013-2023  | ERA5 Single Level |

The [ERA5-Land](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-land?tab=overview) has a spatial resolution of 0.1° x 0.1° while [ERA5 Single Level](https://cds.climate.copernicus.eu/datasets/reanalysis-era5-single-levels?tab=overview) of 0.25° x 0.25°. Request are made for a boundary box for Italy (i.e. 48, 6, 35, 19). Both datasets are hourly.

### C3S 2: Managing

In the second script, [`C3S_Managing.R`](script/C3S_Managing.R), the netcdfs downloaded at the previous step are opened, extracted the data, and convert them from hourly to daily using different approaches (e.g. mean, max, median) depending on the peculiarities of the variable considered. All these steps are made using speicifical functions imported from the [`functions.R`](script/functions.R) script.

### C3S 3: Extract  

In the third script, [`C3S_Export.R`](script/C3S_Export.R), weather data are saved in a external netcdf file.


# WE-C3S/v.1.0.0

The following section illustrates the operations to reproduce the WE-C3S v.1.0.0 dataset:

1. [Download](#C3S-1-Download)
2. [Preprocess](#C3S-2-Preprocessing)
3. [Change of temporal resolution](#C3S-3-Change-of-temporal-resolution)

### C3S 1: Download

The first script are [`ERA5Land_download.R`](script/ERA5Land_download.R) and [`ERA5SL_download.R`](script/ERA5SL_download.R). These scripts make the request about weather variables to the [Climate Change Service](https://cds.climate.copernicus.eu) ([download link](https://eeadmz1-cws-wp-air02-dev.azurewebsites.net/download-data/)) managed by the European Environmental Agency (EEA). The request is made for the following pollutants:


#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug 15 16:04:49 2025

@author: alessandrofusta
"""


import xarray as xr
import os
import numpy as np
import pandas as pd

input_folder = '/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/WE-C3S/v.1.0.0/data/VHR_REA_IT/processed'
output_folder = input_folder.replace('processed','upscaled')

os.makedirs(output_folder, exist_ok=True)

files = [f for f in os.listdir(input_folder) if f.endswith('.nc') and not f.startswith('._')]
files_2019 = [f for f in files if '2019' in f]

datasets = []

# filename=files[1]
for filename in files_2019:
    path_in = os.path.join(input_folder, filename)
    ds = xr.open_dataset(path_in)
    ds2 = ds.coarsen(rlat=2, rlon=2, boundary='trim').mean()
    for var in ds2.data_vars:
        if np.issubdtype(ds2[var].dtype, np.floating):
            ds2[var] = ds2[var].astype('float32')
            
    # comp = dict(zlib=True, complevel=9)
    # encoding = {var: comp for var in ds2.data_vars}
    
    # output_file = path_in.replace("raw", "processed")

    # ds2.to_netcdf(output_file, encoding=encoding)
    parts = filename.split('_')  # ['vhr', 'rea', '2019', '12', '30.nc']
    date_str = '-'.join(parts[2:5]).replace('.nc','')  # '2019-12-30'

    # converti in datetime
    date = pd.to_datetime(date_str, format='%Y-%m-%d')

    if 'time' not in ds2.dims:
        ds2 = ds2.expand_dims('time')
        # opzionale: mettere un valore per il tempo
        ds2 = ds2.assign_coords(time=[date])  # qui puoi usare la data dal nome del file
    
    datasets.append(ds2)
    
ds_all = xr.concat(datasets, dim='time')

comp = dict(zlib=True, complevel=9)
encoding = {var: comp for var in ds_all.data_vars}

output_file = os.path.join(output_folder, "VHR_REA_up_2019.nc")
ds_all.to_netcdf(output_file, encoding=encoding)

# %%

from pyproj import CRS, Transformer

lat_min, lat_max = 35, 48
lon_min, lon_max = 6, 19
res = 0.05

# 1D
new_lats = np.arange(lat_min, lat_max + res, res)
new_lons = np.arange(lon_min, lon_max + res, res)

# griglia 2D
lon_grid, lat_grid = np.meshgrid(new_lons, new_lats)

# Coordinate CRS
rotated_crs = CRS.from_cf({
    "grid_mapping_name": "rotated_latitude_longitude",
    "grid_north_pole_latitude": 47.0,
    "grid_north_pole_longitude": -168.0,
    "north_pole_grid_longitude": 0.0
})
wgs84_crs = CRS.from_epsg(4326)

transformer = Transformer.from_crs(wgs84_crs, rotated_crs, always_xy=True)
# transformer = Transformer.from_crs(rotated_crs, wgs84_crs, always_xy=True)

# Trasformazione griglia
rlon_new, rlat_new = transformer.transform(lon_grid, lat_grid)

# Interpolazione
ds_interp = ds_all.interp(rlat=(["y", "x"], rlat_new), rlon=(["y", "x"], rlon_new), method='linear',
                          kwargs={"fill_value": None})


ds_interp = ds_interp.rename({'lat': 'old_lat', 'lon': 'old_lon'})
ds_interp = ds_interp.rename({'rlat': 'lat', 'rlon': 'lon'})
ds_interp = ds_interp.assign_coords({'lat': (["y", "x"], lat_grid),
                                     'lon': (["y", "x"], lon_grid)})

comp = dict(zlib=True, complevel=5)
encoding = {var: comp for var in ds_interp.data_vars}

output_file = os.path.join(output_folder, "VHR_REA_up_2019_rotated.nc")
ds_interp.to_netcdf(output_file, encoding=encoding)




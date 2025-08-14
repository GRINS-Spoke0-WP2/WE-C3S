#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Aug 12 17:17:37 2025

@author: alessandrofusta
"""

# %%

def mean_wind_dir(directions_deg):
    radians = np.deg2rad(directions_deg)
    sin_mean = np.mean(np.sin(radians))
    cos_mean = np.mean(np.cos(radians))
    mean_dir_rad = np.arctan2(sin_mean, cos_mean)
    mean_dir_deg = np.rad2deg(mean_dir_rad)
    return mean_dir_deg % 360

def process_data0(path_in,output_folder):
    print(f"Apro {filename} ...")
    ds = xr.open_dataset(path_in)
    
    # ds = ds.sortby('valid_time')
    # ds = ds.assign_coords(valid_time=pd.to_datetime(ds['valid_time'].values))
    
    ds['sin_wdir10'] = np.sin(np.deg2rad(ds['wdir10']))
    ds['cos_wdir10'] = np.cos(np.deg2rad(ds['wdir10']))
    
    ds_daily = xr.Dataset({
        'T_2M_min': ds['t2m'].resample(valid_time='1D').min(),
        'T_2M_mean': ds['t2m'].resample(valid_time='1D').mean(),
        'T_2M_max': ds['t2m'].resample(valid_time='1D').max(),
        
        'RH_min': ds['r2'].resample(valid_time='1D').min(),
        'RH_mean': ds['r2'].resample(valid_time='1D').mean(),
        'RH_max': ds['r2'].resample(valid_time='1D').max(),
        
        'wind_speed_10m_mean': ds['si10'].resample(valid_time='1D').mean(),
        'wind_speed_10m_max': ds['si10'].resample(valid_time='1D').max(),
        
        'wind_dir_10m_mean_sin': ds['sin_wdir10'].resample(valid_time='1D').mean(),
        'wind_dir_10m_mean_cos': ds['cos_wdir10'].resample(valid_time='1D').mean(),
        
    })
    
    ds_daily['wind_dir_10m_mean'] = np.rad2deg(np.arctan2(ds_daily['wind_dir_10m_mean_sin'],
                                                          ds_daily['wind_dir_10m_mean_cos'])) % 360
    ds_daily = ds_daily.drop(['wind_dir_10m_mean_sin', 'wind_dir_10m_mean_cos'])    
    
    for var in ds_daily.data_vars:
        if np.issubdtype(ds_daily[var].dtype, np.floating):
            ds_daily[var] = ds_daily[var].astype('float32')
            
    comp = dict(zlib=True, complevel=9)
    encoding = {var: comp for var in ds_daily.data_vars}
    
    basename, ext = os.path.splitext(filename)
    filename_out = f"{basename}_daily_data{ext}"
    path_out = os.path.join(output_folder, filename_out)
    ds_daily.to_netcdf(path_out,encoding=encoding)
    
    print(f"Salvato compresso in {path_out}")
    
def process_data1(path_in,output_folder):
    print(f"Apro {filename} ...")
    ds = xr.open_dataset(path_in)
    
    ds['sin_wdir10'] = np.sin(np.deg2rad(ds['wdir10']))
    ds['cos_wdir10'] = np.cos(np.deg2rad(ds['wdir10']))
    
    ds_unc = xr.Dataset({
        't2m': ds['t2m'].var(dim='number'),
        'r2': ds['r2'].var(dim='number'),
        'si10': ds['si10'].var(dim='number'),
        'sin_wdir10': ds['sin_wdir10'].var(dim='number'),
        'cos_wdir10': ds['cos_wdir10'].var(dim='number')
    })
    
    ds_daily = xr.Dataset({
        'T_2M_uncertainty': np.sqrt(ds_unc['t2m'].resample(valid_time='1D').sum()*(1/16)),
        'RH_uncertainty': np.sqrt(ds_unc['r2'].resample(valid_time='1D').sum()*(1/16)),
        'wind_speed_10m_uncertainty': np.sqrt(ds_unc['si10'].resample(valid_time='1D').sum()*(1/16)),
        'wind_dir_10m_uncertainty_sin': np.sqrt(ds_unc['sin_wdir10'].resample(valid_time='1D').sum()*(1/16)),
        'wind_dir_10m_uncertainty_cos': np.sqrt(ds_unc['cos_wdir10'].resample(valid_time='1D').sum()*(1/16))
    })
    
    ds_daily['wind_dir_10m_uncertainty'] = np.rad2deg(np.arctan2(ds_daily['wind_dir_10m_uncertainty_sin'],
                                                                 ds_daily['wind_dir_10m_uncertainty_cos'])) % 360
    
    ds_daily = ds_daily.drop_vars(['wind_dir_10m_uncertainty_sin', 'wind_dir_10m_uncertainty_cos'])
    
    for var in ds_daily.data_vars:
        if np.issubdtype(ds_daily[var].dtype, np.floating):
            ds_daily[var] = ds_daily[var].astype('float32')
            
    comp = dict(zlib=True, complevel=9)
    encoding = {var: comp for var in ds_daily.data_vars}
    
    basename, ext = os.path.splitext(filename)
    filename_out = f"{basename}_daily_uncertainty{ext}"
    path_out = os.path.join(output_folder, filename_out)
    ds_daily.to_netcdf(path_out,encoding=encoding)
    
    print(f"Salvato compresso in {path_out}")
    

# %%

import xarray as xr
import os
import numpy as np

input_folder = "/home/afustamolo/GitHub/GRINS-Spoke0-WP2/WE-C3S/v.1.0.0/data/CERRA/processed"
output_folder = "/home/afustamolo/GitHub/GRINS-Spoke0-WP2/WE-C3S/v.1.0.0/data/CERRA/processed_light"

os.makedirs(output_folder, exist_ok=True)

files = [f for f in os.listdir(input_folder) if f.endswith('.nc')]
# filename=files[1]
for filename in files:
    path_in = os.path.join(input_folder, filename)
    ds = xr.open_dataset(path_in)
    if 'number' in ds.dims:
        process_data1(path_in,output_folder)
    else:
        process_data0(path_in,output_folder)
        

# input_folder = "/Users/alessandrofusta/Library/Mobile Documents/com~apple~CloudDocs/Lavoro/PhD Bergamo/GRINS/GitHub/GRINS-Spoke0-WP2/WE-C3S/v.1.0.0/data/CERRA/processed"
# output_folder = input_folder

# io ho 2019_01_data_0.nc e 2019_01_data_1.nc per svariati giorni. Vorrei
# %%

# import matplotlib.pyplot as plt

# # var = 'RH_min'
# var = 'T_2M_uncertainty'
# time_idx = 0
# # number_idx = 0


# # data_to_plot = ds_daily[var].isel(valid_time=time_idx, number=number_idx)
# data_to_plot = ds_daily[var].isel(valid_time=time_idx)

# plt.figure(figsize=(8,6))
# plt.pcolormesh(ds_daily['longitude'], ds_daily['latitude'], data_to_plot, shading='auto')
# plt.colorbar(label=var)
# plt.xlabel('Longitude (rlon)')
# plt.ylabel('Latitude (rlat)')
# plt.title(f'{var} at time index {time_idx}')
# plt.show()

# var = 't2m'
# data_to_plot = ds_unc[var].isel(valid_time=time_idx)

# plt.figure(figsize=(8,6))
# plt.pcolormesh(ds_unc['longitude'], ds_unc['latitude'], data_to_plot, shading='auto')
# plt.colorbar(label=var)
# plt.xlabel('Longitude (rlon)')
# plt.ylabel('Latitude (rlat)')
# plt.title(f'{var} at time index {time_idx}')
# plt.show()

# %%



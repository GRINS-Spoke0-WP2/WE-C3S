#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 13 13:32:36 2025

@author: alessandrofusta
"""

# %% pakages

import ddsapi
import xarray as xr
import numpy as np
import os
# from pyproj import CRS, Transformer

# %% functions

def download_and_convert(year, month, day):
    download_vhr_rea_it(year, month, day)
    filename = f"vhr_rea_{year}_{month}_{day}.nc"
    fromHtoD(filename)
    
def mean_wind_dir(directions_deg):
    radians = np.deg2rad(directions_deg)
    sin_mean = np.mean(np.sin(radians))
    cos_mean = np.mean(np.cos(radians))
    mean_dir_rad = np.arctan2(sin_mean, cos_mean)
    mean_dir_deg = np.rad2deg(mean_dir_rad)
    return mean_dir_deg % 360

def download_vhr_rea_it(year: str, month: str, day: str):
    output_path  = "/home/afustamolo/GitHub/GRINS-Spoke0-WP2/WE-C3S/v.1.0.0/data/VHR_REA_IT/raw"
    name_file = f"vhr_rea_{year}_{month}_{day}.nc"
    output_file = os.path.join(output_path, name_file)
    c = ddsapi.Client()
    c.retrieve("era5-downscaled-over-italy", "hourly",
    {
        "area": {
            "north": 48.1,
            "south": 34.9,
            "east": 19.1,
            "west": 5.9
        },
        "vertical": [
            0.004999999888241291
        ],
        "time": {
            "hour": [
                "00",
                "01",
                "02",
                "03",
                "04",
                "05",
                "06",
                "07",
                "08",
                "09",
                "10",
                "11",
                "12",
                "13",
                "14",
                "15",
                "16",
                "17",
                "18",
                "19",
                "20",
                "21",
                "22",
                "23"
            ],
            "year": [
                year
            ],
            "month": [
                month
            ],
            "day": [
                day
            ]
        },
        "variable": [
            "surface_net_downward_shortwave_flux",
            "precipitation_amount",
            "air_temperature",
            "grid_northward_wind",
            "grid_eastward_wind",
            "dew_point_temperature"
        ],
        "format": "netcdf"
    },
    output_file)
    
    # with open(os.path.join(output_path, "request_ids.txt"), "a") as f:
    #     f.write(req.id + "\n")

def fromHtoD(filename,input_path=None):
    if input_path==None:    
        input_path  = "/home/afustamolo/GitHub/GRINS-Spoke0-WP2/WE-C3S/v.1.0.0/data/VHR_REA_IT/raw"
    input_file = os.path.join(input_path, filename)
    ds = xr.open_dataset(input_file)
    T_c = ds['T_2M'] - 273.15
    TD_c = ds['TD_2M'] - 273.15
    e_temp = 6.112 * np.exp((17.67 * T_c) / (T_c + 243.5))
    e_dew = 6.112 * np.exp((17.67 * TD_c) / (TD_c + 243.5))
    RH = 100 * (e_dew / e_temp)
    ds['RH'] = RH.clip(0, 100)  
    ds['wind_speed_10m'] = np.sqrt(ds['U_10M']**2 + ds['V_10M']**2)
    ds['wind_dir_10m'] = (np.arctan2(-ds['U_10M'], -ds['V_10M']) * 180 / np.pi) % 360
    ds['sin_wdir10'] = np.sin(np.deg2rad(ds['wind_dir_10m']))
    ds['cos_wdir10'] = np.cos(np.deg2rad(ds['wind_dir_10m']))
    ds_daily = xr.Dataset({
        'ASOB_S_mean': ds['ASOB_S'].resample(time='1D').mean(),
        'ASOB_S_max': ds['ASOB_S'].resample(time='1D').max(),
        'TOT_PREC_min': ds['TOT_PREC'].resample(time='1D').min(),
        'TOT_PREC_mean': ds['TOT_PREC'].resample(time='1D').mean(),
        'TOT_PREC_max': ds['TOT_PREC'].resample(time='1D').max(),
        'T_2M_min': ds['T_2M'].resample(time='1D').min(),
        'T_2M_mean': ds['T_2M'].resample(time='1D').mean(),
        'T_2M_max': ds['T_2M'].resample(time='1D').max(),
        'wind_speed_10m_mean': ds['wind_speed_10m'].resample(time='1D').mean(),
        'wind_speed_10m_max': ds['wind_speed_10m'].resample(time='1D').max(),
        'wind_dir_10m_mean_sin': ds['sin_wdir10'].resample(time='1D').mean(),
        'wind_dir_10m_mean_cos': ds['cos_wdir10'].resample(time='1D').mean(),
        'RH_min': ds['RH'].resample(time='1D').min(),
        'RH_mean': ds['RH'].resample(time='1D').mean(),
        'RH_max': ds['RH'].resample(time='1D').max(),
    })
    ds_daily['wind_dir_10m_mean'] = np.rad2deg(np.arctan2(ds_daily['wind_dir_10m_mean_sin'],
                                                          ds_daily['wind_dir_10m_mean_cos'])) % 360
    ds_daily = ds_daily.drop_vars(['wind_dir_10m_mean_sin', 'wind_dir_10m_mean_cos'])    

    for var in ds_daily.data_vars:
        if np.issubdtype(ds_daily[var].dtype, np.floating):
            ds_daily[var] = ds_daily[var].astype('float32')
            
    comp = dict(zlib=True, complevel=9)
    encoding = {var: comp for var in ds_daily.data_vars}
    
    output_file = input_file.replace("raw", "processed")

    ds_daily.to_netcdf(output_file, encoding=encoding)
    
    check_and_delete(output_file,input_file)
    
    # interp_01(ds_daily,output_file)


# def interp_01(ds_input,output_file):
    
#     output_file = output_file.replace('/processed/', '/processed/interp/')
    
#     lat_min, lat_max = 35.1, 47.89
#     lon_min, lon_max = 6.1, 18.89
#     res = 0.01
#     new_lats = np.arange(lat_min, lat_max + res, res)
#     new_lons = np.arange(lon_min, lon_max + res, res)

#     rotated_crs = CRS.from_cf({
#         "grid_mapping_name": "rotated_latitude_longitude",
#         "grid_north_pole_latitude": 47.0,
#         "grid_north_pole_longitude": -168.0,
#         "north_pole_grid_longitude": 0.0  # spesso 0.0, verifica se nel file c'è un attributo specifico
#     })
#     wgs84_crs = CRS.from_epsg(4326)
#     # transformer = Transformer.from_crs(rotated_crs, wgs84_crs, always_xy=True)
#     transformer = Transformer.from_crs(wgs84_crs, rotated_crs, always_xy=True)

#     rlon_new, rlat_new = transformer.transform(new_lons, new_lats)

#     ds_interp = ds_input.interp(rlat=rlat_new, rlon=rlon_new, method='linear')
    
#     comp = dict(zlib=True, complevel=9)
#     encoding = {var: comp for var in ds_interp.data_vars}
    
#     ds_input.to_netcdf(output_file, encoding=encoding)


def check_and_delete(file_check, file_delete):
    if os.path.isfile(file_check) and os.path.getsize(file_check) > 0:
        if os.path.isfile(file_delete):
            os.remove(file_delete)
            print(f"File '{file_delete}' eliminato perché '{file_check}' esiste ed è > 0 byte.")
        else:
            print(f"File da eliminare '{file_delete}' non trovato.")
    else:
        print(f"File da controllare '{file_check}' non esiste o è vuoto.")

def download_vhr_rea_it_noCROP(year: str, month: str, day: str):
    output_path  = "/home/afustamolo/GitHub/GRINS-Spoke0-WP2/WE-C3S/v.1.0.0/data/VHR_REA_IT/raw"
    name_file = f"vhr_rea_{year}_{month}_{day}.nc"
    output_file = os.path.join(output_path, name_file)
    c = ddsapi.Client()
    c.retrieve("era5-downscaled-over-italy", "hourly",
    {
        "vertical": [
            0.004999999888241291
        ],
        "time": {
            "hour": [
                "00",
                "01",
                "02",
                "03",
                "04",
                "05",
                "06",
                "07",
                "08",
                "09",
                "10",
                "11",
                "12",
                "13",
                "14",
                "15",
                "16",
                "17",
                "18",
                "19",
                "20",
                "21",
                "22",
                "23"
            ],
            "year": [
                year
            ],
            "month": [
                month
            ],
            "day": [
                day
            ]
        },
        "variable": [
            "surface_net_downward_shortwave_flux",
            "precipitation_amount",
            "air_temperature",
            "grid_northward_wind",
            "grid_eastward_wind",
            "dew_point_temperature"
        ],
        "format": "netcdf"
    },
    output_file)

def download_and_convert_noCROP(year, month, day):
    download_vhr_rea_it_noCROP(year, month, day)
    filename = f"vhr_rea_{year}_{month}_{day}.nc"
    fromHtoD(filename)


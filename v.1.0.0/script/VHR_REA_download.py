#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Aug 12 13:30:12 2025

@author: alessandrofusta
"""

# %%

from joblib import Parallel, delayed
import VHR_REA_functions as vr
import pandas as pd

# %% cycle

# day = pd.date_range(start="2013-02-23", end="2013-02-23") # MANCA!
# vr.download_and_convert_noCROP(str(day.year), str(day.month), str(day.day)) # NON VA

days = pd.date_range(start="2013-03-26", end="2023-12-31")
Parallel(n_jobs=30)(
    delayed(vr.download_and_convert)(str(day.year), str(day.month), str(day.day))
    for day in days
)

# years = [str(y) for y in range(2013, 2024)]
# months = [str(m) for m in range(3, 13)]
# days = [str(d) for d in range(1, 3)]

# for year in range(2013, 2024):
#     for month in range(1, 13):
# year=years[0]
# month=months[0]
# day=days[0]
# for year in years:
#     for month in months:
#         for day in days:
#             download_vhr_rea_it(year, month, day)
#             filename = f"vhr_rea_{year}_{month}_{day}.nc"
#             fromHtoD(filename)
            
# for year in years:
#     for month in months:
#         delayed(vr.download_and_convert)(year, month, day) for day in days
#         )
            
# for year in years:
#     for month in months:
#         Parallel(n_jobs=31)(delayed(download_vhr_rea_it)(year, month, day) for day in days)
#         # vorrei aggiungere anche fromHtoD
#         for day in days:
#             download_vhr_rea_it(year, month, day)
#             filename = f"vhr_rea_{year}_{month}_{day}.nc"
#             fromHtoD(filename)
            
            
# Parallel(n_jobs=10)(delayed(process_day)(day) for day in days)

# year=years[0]
# month=months[0]
# day=days[0]

# %% functions


# %% Coarsing the df

# ds_coarse = ds_daily.coarsen(rlat=3, rlon=3, boundary='trim').mean()

# %% plot

# import matplotlib.pyplot as plt

# var = 'RH_min'
# time_idx = 0

# data_to_plot = ds_interp[var].isel(time=time_idx)

# plt.figure(figsize=(8,6))
# plt.pcolormesh(ds_interp['rlon'], ds_interp['rlat'], data_to_plot, shading='auto')
# plt.colorbar(label=var)
# plt.xlabel('Rotated Longitude (rlon)')
# plt.ylabel('Rotated Latitude (rlat)')
# plt.title(f'{var} at time index {time_idx}')
# plt.show()

# %%

# var = 'RH_min'
# time_idx = 0

# data_to_plot = ds_coarse[var].isel(time=time_idx)

# plt.figure(figsize=(8,6))
# plt.pcolormesh(ds_coarse['rlon'], ds_coarse['rlat'], data_to_plot, shading='auto')
# plt.colorbar(label=var)
# plt.xlabel('Rotated Longitude (rlon)')
# plt.ylabel('Rotated Latitude (rlat)')
# plt.title(f'{var} at time index {time_idx}')
# plt.show()

# %% export


# Ora salva con compressione e float16

# %% Municipal indicators


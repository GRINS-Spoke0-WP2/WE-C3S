#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 13 14:09:40 2025

@author: alessandrofusta
"""

import os
import VHR_REA_functions as vr
import xarray as xr
import pandas as pd

# %% to daily 

input_folder = '/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/WE-C3S/v.1.0.0/data/VHR_REA_IT/raw'

files = [f for f in os.listdir(input_folder) if f.startswith('era5') and f.endswith('.nc')]

for filename in files:
    vr.fromHtoD(filename,input_folder)

# %% give name

def assign_name(filename,input_folder):
    input_file = os.path.join(input_folder, filename)
    ds = xr.open_dataset(input_file)
    day = pd.Timestamp(ds.time.values[0])
    year, month, day_num = day.year, day.month, day.day
    new_name = f"vhr_rea_{year}_{month}_{day_num}.nc"
    new_file = os.path.join(input_folder, new_name)
    ds.to_netcdf(new_file)
    if os.path.isfile(new_file) and os.path.getsize(new_file) > 0:
        if os.path.isfile(input_file):
            os.remove(input_file)
            print(f"File '{input_file}' eliminato perché '{new_file}' esiste ed è > 0 byte.")
        else:
            print(f"File da eliminare '{input_file}' non trovato.")
    else:
        print(f"File da controllare '{new_file}' non esiste o è vuoto.")


# %%

input_folder = '/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/WE-C3S/v.1.0.0/data/VHR_REA_IT/processed'

files = [f for f in os.listdir(input_folder) if f.startswith('era5') and f.endswith('.nc')]
# filename=files[0]
for filename in files:
    assign_name(filename,input_folder)


    
    
    
    
    
    
    
    
    

    

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Aug  9 21:10:50 2025

@author: alessandrofusta
"""

# %%

# collect functions and packages from CERRA_download

import cdsapi
import os
from pathlib import Path
import xarray as xr
import numpy as np

# %%

def subset_spaziale(anno: str = None, mese: str = None, lat_min=35, lat_max=48, lon_min=6, lon_max=19, 
                    input_path=None,
                    output_path=None,
                    file_name=None):
    
    if input_path is None:
        input_path = "/home/afustamolo/GitHub/GRINS-Spoke0-WP2/WE-C3S/v.1.0.0/data/raw"
    if file_name is None:
        file_name = f"cerra_{anno}_{mese}.nc"
    input_loc = input_path + "/" + file_name
    ds = xr.open_dataset(input_loc)

    lat = ds['latitude']
    lon = ds['longitude']

    # Crea una maschera booleana per i punti nel bounding box
    mask = (
        (lat >= lat_min) & (lat <= lat_max) &
        (lon >= lon_min) & (lon <= lon_max)
    )

    # Trova gli indici y, x dove la maschera è vera
    y_idx, x_idx = np.where(mask)

    if len(y_idx) == 0 or len(x_idx) == 0:
        print("Nessun punto trovato nel bounding box.")
        return

    # Determina il bounding box minimo in termini di indici
    y_min, y_max = y_idx.min(), y_idx.max()
    x_min, x_max = x_idx.min(), x_idx.max()

    print(f"Subset da y={y_min}:{y_max}, x={x_min}:{x_max}")

    # Applica il subset al dataset originale
    ds_subset = ds.isel(y=slice(y_min, y_max + 1), x=slice(x_min, x_max + 1))

    # Percorso di salvataggio
    if output_path is None:
        output_path = input_path.replace("raw", "processed")
    
    output_loc = output_path + "/" + file_name

    # Salva
    ds_subset.to_netcdf(output_loc)
    print(f"File salvato: {output_path}")
    # check_and_delete(file_name, output_path, input_path)

def check_and_delete(filename, folder_check, folder_delete):
    path_check = os.path.join(folder_check, filename)
    path_delete = os.path.join(folder_delete, filename)

    # Controlla se il file da controllare esiste e ha dimensione > 0
    if os.path.isfile(path_check) and os.path.getsize(path_check) > 0:
        # Se il file da eliminare esiste, lo elimina
        if os.path.isfile(path_delete):
            os.remove(path_delete)
            print(f"File '{path_delete}' eliminato perché '{path_check}' esiste ed è > 0 byte.")
        else:
            print(f"File da eliminare '{path_delete}' non trovato.")
    else:
        print(f"File da controllare '{path_check}' non esiste o è vuoto.")
        
# %% temperature all 2023

input_path = '/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/WE-C3S/v.1.0.0/data/CERRA/raw/t2m_2023'
file_name = 't2m_2023_data_0.nc' #ensemble
file_name = 't2m_2023_data_1.nc' #reanalysis
# DONE subset manually

input_path = '/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/WE-C3S/v.1.0.0/data/CERRA/processed/t2m_2023'
file_name = 't2m_2023_data_0.nc' #ensemble
file_name = 't2m_2023_data_1.nc' #reanalysis
input_loc = input_path + "/" + file_name
ds = xr.open_dataset(input_loc)

import matplotlib.pyplot as plt
membro = 0
tempo = "2023-06-15T00:00"
da_sel = ds.sel(number=membro, valid_time=tempo) #for data0
da_sel = ds.sel(valid_time=tempo) #for data1
print(da_sel['t2m'].dims)  
# dovrebbe stampare ('y', 'x')
da_sel['t2m'].plot(
    x="longitude",
    y="latitude",
    cmap="coolwarm",
    robust=True
)
plt.show()


uncertainty = ds['t2m'].std(dim='number')
uncertainty_sel = uncertainty.sel(valid_time=tempo)
uncertainty_sel.plot(
    x="longitude",
    y="latitude",
    cmap="viridis",
    robust=True,
    cbar_kwargs={'label': 'Uncertainty in t2m (°C)'}
)
plt.title(f'Uncertainty in t2m for {tempo}')
plt.show()


# %%

input_path = '/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/WE-C3S/v.1.0.0/data/CERRA/raw'
folder_names = os.listdir(input_path)
for ff in folder_names:
    file_names = os.listdir(input_path+'/'+ff)
    file_names = [f for f in file_names if not f.startswith('._')]
    # data_0.nc #ensemble
    # data_1.nc #reanalysis
    for f in file_names:
        subset_spaziale(input_path=input_path+'/'+ff, file_name=f)

import zipfile
zip_path = '/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/WE-C3S/v.1.0.0/data/CERRA/raw/cerra_2013_06.zip'

# Cartella dove estrarre
extract_folder = '/Volumes/Extreme SSD/Lavoro/GRINS/GitHub/WE-C3S/v.1.0.0/data/CERRA/raw'

with zipfile.ZipFile(zip_path, 'r') as zip_ref:
    zip_ref.extractall(extract_folder)

print("Estrazione completata!")



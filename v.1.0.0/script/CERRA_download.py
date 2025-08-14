#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug  8 13:27:17 2025

@author: alessandrofusta
"""
# da far girare il 2023 senza la temperatura

# %%

import cdsapi
import os
# from pathlib import Path
import xarray as xr
import numpy as np
# from joblib import Parallel, delayed
import zipfile


# %%

def scarica_cerra(anno: str, mese: str, output_folder: str = "/home/afustamolo/GitHub/GRINS-Spoke0-WP2/WE-C3S/v.1.0.0/data/CERRA/raw"):
    
    client = cdsapi.Client()

    request = {
        "variable": [
            "10m_wind_direction",
            "10m_wind_speed",
            "2m_relative_humidity",
            "2m_temperature"
        ],
        "level_type": "surface_or_atmosphere",
        "data_type": ["ensemble_members", "reanalysis"],
        "product_type": "analysis",
        "year": [anno],
        "month": [mese],
        "day": [f"{d:02d}" for d in range(1, 32)],
        "time": [
            "00:00", "03:00", "06:00",
            "09:00", "12:00", "15:00",
            "18:00", "21:00"
        ],
        "data_format": "netcdf"
    }
    output_file = output_folder + "/" + f"cerra_{anno}_{mese}.zip"
    
    print(f"Scarico CERRA {anno}-{mese} in {output_file}...")
    try:
        client.retrieve("reanalysis-cerra-single-levels", request).download(str(output_file))
        print(f"Dati salvati in: {output_file}\n")
    except Exception as e:
        print(f"Errore durante il download di {anno}-{mese}: {e}\n")
        
        
        
def extract_zip(zip_path=None):
    
    if zip_path is None:
        zip_path='/home/afustamolo/GitHub/GRINS-Spoke0-WP2/WE-C3S/v.1.0.0/data/CERRA/raw'
    name_file = os.listdir(zip_path)
    name_file = name_file[0]
    file_path = os.path.join(zip_path, name_file)
    try:
        with zipfile.ZipFile(file_path, 'r') as zip_ref:
            zip_ref.extractall(zip_path)
        os.remove(file_path)
    except Exception as e:
        print(f"Errore durante l'estrazione di zip_file: {e}")


def subset_spaziale(anno: str = None, mese: str = None,
                    lat_min=35, lat_max=48, lon_min=6, lon_max=19, 
                    input_path=None,
                    output_path=None):
    
    if input_path is None:
        input_path = "/home/afustamolo/GitHub/GRINS-Spoke0-WP2/WE-C3S/v.1.0.0/data/CERRA/raw"
        
    file_names = os.listdir(input_path)
    # ff = file_names[0]
    for ff in file_names:
        input_loc = input_path + "/" + ff
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
        
        os.makedirs(output_path, exist_ok=True)
        
        if anno is None:
            output_loc = f"{output_path}/{ff}"
        else:
            output_loc = f"{output_path}/{anno}_{mese}_{ff}"

    
        # Salva
        ds_subset.to_netcdf(output_loc)
        print(f"File salvato: {output_path}")
        check_and_delete(ff, output_path, input_path)



def check_and_delete(filename, folder_check, folder_delete):
    path_check = os.path.join(folder_check, f"{anno}_{mese}_{filename}")
    path_delete = os.path.join(folder_delete, filename)
    if os.path.isfile(path_check) and os.path.getsize(path_check) > 0:
        if os.path.isfile(path_delete):
            os.remove(path_delete)
            print(f"File '{path_delete}' eliminato perché '{path_check}' esiste ed è > 0 byte.")
        else:
            print(f"File da eliminare '{path_delete}' non trovato.")
    else:
        print(f"File da controllare '{path_check}' non esiste o è vuoto.")
        
# def process_cerra(anno: str, mese: str):
#     scarica_cerra(anno,mese)
#     subset_spaziale(anno,mese)
    

# %%

anni = [str(y) for y in range(2013, 2024)]
mesi = [f"{m:02d}" for m in range(1, 13)]

# combinazioni già fatte: (anno, mese)
# gia_fatti = {
#     ("2013", "01"), ("2013", "02"), ("2013", "03"), ("2013", "04"), ("2013", "05"),
#     ("2013", "06"), ("2013", "07"), ("2013", "08"), ("2013", "12"),
#     ("2014", "03"), ("2014", "08"), ("2014", "10"),
#     ("2015", "04"), ("2015", "07"), ("2015", "10"), ("2015", "11"),
#     ("2016", "10"),
#     ("2017", "04"),
# }

for anno in anni:
    for mese in mesi:
        scarica_cerra(anno, mese)
        extract_zip()
        subset_spaziale(anno,mese)
        
# /Volumes/Extreme SSD/Lavoro/GRINS/GitHub/WE-C3S/v.1.0.0/data/CERRA/raw

# for anno in anni:
#     for mese in mesi:
#         scarica_cerra(anno, mese)
#         subset_spaziale(anno, mese)       
        
        
# %%
    
# Parallel(n_jobs=10)(
#     delayed(process_cerra)(anno, mese) 
#     for anno in anni 
#     for mese in mesi
# )

# from concurrent.futures import ProcessPoolExecutor

# def task(anno_mese):
#     anno, mese = anno_mese
#     scarica_cerra(anno, mese)
#     subset_spaziale(anno, mese)

# # Lista di tuple (anno, mese)
# anni_mesi = [(anno, mese) for anno in anni for mese in mesi]

# with ProcessPoolExecutor() as executor:
#     executor.map(task, anni_mesi)

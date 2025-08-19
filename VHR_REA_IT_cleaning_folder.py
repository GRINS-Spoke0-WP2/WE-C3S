#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Aug 15 16:23:30 2025

@author: alessandrofusta
"""

import os

input_folder = "percorso/della/cartella"  # sostituisci con la tua cartella

for f in os.listdir(input_folder):
    if f.startswith('._'):
        file_path = os.path.join(input_folder, f)
        os.remove(file_path)
        print(f"Eliminato: {file_path}")

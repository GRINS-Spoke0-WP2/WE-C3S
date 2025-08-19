#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 13 14:58:25 2025

@author: alessandrofusta
"""

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Aug 13 14:09:40 2025

@author: alessandrofusta
"""

import os
import VHR_REA_functions as vr

input_folder  = "/home/afustamolo/GitHub/GRINS-Spoke0-WP2/WE-C3S/v.1.0.0/data/VHR_REA_IT/raw"
files = [f for f in os.listdir(input_folder) if f.startswith('vhr') and f.endswith('.nc')]

for filename in files:
    vr.fromHtoD(filename,input_folder)

    
    
    
# ds_coarse = ds_daily.coarsen(rlat=3, rlon=3, boundary='trim').mean()
    
    
    
    
    

    

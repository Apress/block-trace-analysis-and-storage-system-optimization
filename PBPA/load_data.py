# -*- coding: utf-8 -*-
"""
load the data for analysis and reporting
"""
import os
import scipy
import numpy as np
from scipy.io import loadmat
from report_plugins import *
    
filename='.\\Data\\RAID.mat'

mat_dict={}
mat_dict.update(loadmat(filename))
lists_action=mat_dict['lists_action']  
if lists_action.shape[1]==7:
    lists_action=lists_action[:,5:7]
lists_cmd=mat_dict['lists_cmd']

options=options_class()
options.access_type=0
traces=lists_cmd

## generate trace analysis result
#os.system("python batch_analysis.py")
#
## create powerpoint report
#os.system("python batch_generate_ppt.py")

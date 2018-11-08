# PBPA
Python-based Block-trace Parser, Analyser and Reporter

Author: Jun Xu (jun.xu99@gmail.com)

# Background

IO event trace analysis is one of the most common techniques for storage system performance analysis. In particular, block-level trace analysis is essential for storage system optimization and design, as most underlying storage devices are in block-level, even the upper-level system to users are in object- or file-level. However, there are very few tools dedicated to this topic. This tool intends to fill this gap and provide a self-inclusive contents for block-level trace analysis techniques, as well as trace parsing and result reporting techniques, based on MATLAB platform.

# Installation

Run directly from this folder. 

# Howto

0. pip install python_pptx DateTime pickle inspect dill scipy matplotlib
1. load the data by run "load_data.py"; Please refer to MBPA for the data files
2. run the corresponding trace analysis functions based your need; by default, all workload metrics will be analyzed in "batch_analysis.py"
3. run "batch_generator_ppt.py" to create a PowerPoint slide; 

for more information, please refer to manual


# TD list
1. add more functions on locality analysis
2. add flexibility in report generator


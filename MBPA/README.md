# MBPA
Matlab-based Block-trace Parser, Analyser and Reporter

Author: Jun Xu (jun.xu99@gmail.com)

# Background

IO event trace analysis is one of the most common techniques for storage system performance analysis. In particular, block-level trace analysis is essential for storage system optimization and design, as most underlying storage devices are in block-level, even the upper-level system to users are in object- or file-level. However, there are very few tools dedicated to this topic. This tool intends to fill this gap and provide a self-inclusive contents for block-level trace analysis techniques, as well as trace parsing and result reporting techniques, based on MATLAB platform.

# Installation

Put all source files into a folder, e.g., MBPA, and then add the path in Matlab to this folder. 

# structure

"Trace Analysis": the main functions to analyzing the trace with given format. tens of properties are presented
  lists_cmd: Nx3 matrix; the first column is starting LBA, the second column is the request size, and the third column is access type (0/write, 1/read)
  lists_action: Nx2 matrix with the first column as arrival time, and the second column as completion time

"Blktrace Parser": parse the ascii file into trace matrix
  raw data file with blkparse: use "blktrace_parser.m" with specified filename (e.g., "sample data\blkparse\310.blktrace.txt")
  parsed data file with btt: many different cases

"Report generator": powerpoint report generator

"Data": some sample trace data

"Tools" two tools to generate ppt reports

# Howto

1. run the "blktrace_parser.m" first to get the trace matrices "lists_cmd" and "lists_action" from blktrace file; 
2. run the corresponding trace analysis functions based your need; by default, all workload metrics will be analyzed in "batch_analysis.m"
3. run "batch_generator_ppt.m" to create a powerpoint slide; 

batch_analysis.m & batch_generate_ppt.m provide a demo.
for more information, please refer to manual


# TD list
1. add more functions on locality analysis
2. add flexibility in report generator


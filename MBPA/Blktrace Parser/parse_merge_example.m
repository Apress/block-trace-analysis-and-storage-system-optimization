% filelists contains the one of "Per-IO Data file" and two files (R/W) of "--dump-blocknos"

filename='310s.blktrace.p';
IO_time=parse_per_IO_data(filename,options);

filename='310s.blktrace.B_8,0_r.dat';
IO_r=parse_dump_blocknos(filename);

filename='310s.blktrace.B_8,0_w.dat';
IO_w=parse_dump_blocknos(filename);

options.window=1000;
IO_list=parse_merge_IO(IO_time,IO_r, IO_w, options);

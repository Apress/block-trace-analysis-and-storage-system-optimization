% parse a blktrace file
blktrace_parser('Data\blktrace.txt')

% generate trace analysis result
batch_analysis;

% create powerpoint report
batch_generate_ppt;
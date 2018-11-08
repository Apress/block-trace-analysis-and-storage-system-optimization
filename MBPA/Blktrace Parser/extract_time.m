%Useful time extraction function for log files
%Time expressed in milliseconds

function time0=extract_time(tline);
tt=sscanf(tline,'%d-%d-%d %d:%d:%d,%d');
time0=(tt(4)*60^2+tt(5)*60+tt(6)/1000) + tt(7);

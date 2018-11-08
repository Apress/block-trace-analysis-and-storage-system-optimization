function [q_list,c_list]=analysis_q2c(filename)
%clear;
%filename='sdb.result.q2c_008,016_q2c.dat';

fid=fopen(filename);
tline=fgetl(fid);
lines=50000;
q2c=zeros(lines,2);

con0=0;
while ischar(tline)
    con0=con0+1;
    q2c(con0,:)=sscanf(tline,'%f %f');
    tline=fgetl(fid);
    if con0>lines
       q2c=[q2c;zeros(5000,2)];
       lines=lines+5000;
    end
end

figure;
plot(q2c(1:con0,1),q2c(1:con0,2))
xlabel('time (s)')
ylabel('latency (s)')
title('Q2C Latency')

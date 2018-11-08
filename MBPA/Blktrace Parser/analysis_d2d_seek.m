%%@JUN, it doesn't look like you use q_list or c_list in this function, 
%% can this function call be deleted?
function [q_list,c_list]=analysis_q2c(filename)
% filename='sdb.all.seek_008,016_d2d_r.dat';

fid=fopen(filename);
tline=fgetl(fid);
lines=100000;
d2d=zeros(lines,2);
cont_zero=0;
th_almost_zero=64;
th_almost_zero2=256;
cont_almost_zero=0;
cont_almost_zero2=0;

con0=0;
while ischar(tline)
    con0=con0+1;
    d2d(con0,:)=sscanf(tline,'%f %f %*s');
    tline=fgetl(fid);
    if con0>lines
        d2d=[d2d;zeros(5000,2)];
        lines=lines+5000;
    end
    if d2d(con0,2)==0
        cont_zero=cont_zero+1;
    elseif abs(d2d(con0,2))<th_almost_zero
        cont_almost_zero=cont_almost_zero+1;
    elseif abs(d2d(con0,2))<th_almost_zero2
        cont_almost_zero2=cont_almost_zero2+1;
    end
end

con0
cont_zero
cont_almost_zero
cont_almost_zero2

% figure;
% plot(d2d(1:con0,1),d2d(1:con0,2))
% xlabel('time (s)')
% ylabel('latency (s)')
% title('Q2C Latency')
